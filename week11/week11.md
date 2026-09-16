# Week11 总规划：让 Reactor 承载 HTTP/1.1

> 日期：2026-09-16
>
> 主线：Reactor V1 -> incremental HTTP parser -> HTTP Server V1 -> Mini Redis
>
> 当前真实进度：Week10 Reactor V1 已正式通过；AI Theory 为 T1 已通过，T2/T3 待完成
>
> 本周定位：第一次把 application protocol 接到已经验证过的 transport/lifecycle 底座上

---

# 1. Week11 在总路线中的位置

当前主线已经走到：

```text
C++ ownership / RAII
-> Linux process / fd / syscall
-> thread / condition variable / concurrent components
-> socket / TCP / non-blocking I/O
-> epoll / partial I/O / LT 与 ET
-> Reactor V1
-> Week11 HTTP Server V1
-> Week12 Mini Redis RESP + KV
```

Week10 已经证明：

```text
EventLoop 能等待并 dispatch readiness
Channel 能保存 interest / ready mask / callbacks
Acceptor 能建立连接并移交 accepted-fd ownership
Connection 能保存跨 event 的 input/output state
Buffer 能保存当前 syscall 返回后仍然重要的 bytes
composition root 能在 poll batch 结束后 deferred cleanup
```

Week11 不重新证明这些基础机制。它要回答一个新的问题：

> TCP 只提供有序 byte stream，Reactor 怎样在 arbitrary fragmentation/coalescing 下识别 HTTP request，并让 protocol state、transport state 与 object lifetime 各自留在正确层？

本周不是为了做网页，也不是为了学习前端。HTTP Server 在路线中的作用是：

```text
把 byte stream 变成 structured request
把 structured response 编码成 bytes
让 parser state 跨多次 callback 保持正确
第一次让 Reactor 承载真实 application protocol
为 Week12 RESP parser 与 Mini Redis 分层提供直接经验
```

---

# 2. 当前真实 baseline

## 2.1 可以直接复用的代码

Ubuntu 当前 canonical implementation 位于：

```text
~/code/system-learning/cpp/week10
```

本周继续维护这一份工程，不复制一份 `reactor_http_final_v2`：

```text
Buffer
Channel
EventLoop
Acceptor
Connection
UniqueFd
reactor_echo_server
现有 probes / clients / CTest
```

Week12 真正进入 Mini Redis 时，再统一决定是否把 canonical project directory 改成更长期的项目名。本周不为了目录外观搬家。

## 2.2 已有 evidence

```text
Debug build：零 warning
CTest：15/15 PASS
normal / repeated / concurrent clients：PASS
4,194,305-byte slow client：exact PASS
half-close client：PASS
ASan/UBSan covered paths：无 report
100 次顺序连接：100/100 PASS
process fd count：6 -> 6
```

HTTP 集成后，只有受新代码影响的 evidence 才重跑。不要每天从头复制 Week10 的全部证明。

## 2.3 本周真正新增的状态

Reactor 当前保存 transport state：

```text
connected fd
input bytes
output bytes
interest mask
peer EOF / close request
```

HTTP 还需要 per-connection protocol state：

```text
当前解析到 request line / headers / body 的哪一步
已经得到哪些 fields
Content-Length 还差多少 bytes
当前 request 是否 malformed
当前连接应保持 persistent，还是 response flush 后关闭
```

这份 state 必须属于 application/session 层，不能因为方便就塞进通用 `Connection`。

---

# 3. 本周最终模型

Week11 出口时，完整数据流应当能被解释为：

```text
kernel reports connected socket readable
-> EventLoop finds Channel
-> Channel invokes Connection read callback
-> Connection recv loop appends bytes to input Buffer
-> per-connection HTTP parser advances
-> complete HttpRequest becomes available
-> route/application policy produces HttpResponse
-> response encoder produces exact HTTP bytes
-> Connection::send appends/sends transport bytes
-> output remains: enable EPOLLOUT and continue later
-> output drained: remove EPOLLOUT
-> keep alive, or close after final response is flushed
```

必须同时保持下面四条边界：

```text
Reactor：等待与 dispatch
Connection：transport state 与 socket lifetime
HTTP parser/session：protocol framing 与 per-connection parse state
route/application：request semantics 与 response policy
```

Week11 的成功标准不是 class 越多越好，而是：

```text
HTTP 不污染底层 Reactor
parser 不依赖 recv 边界
response 不依赖一次 send 完成
connection policy 不会提前丢掉 pending output
malformed bytes 有明确、可测试的结局
```

---

# 4. 本周协议 contract

## 4.1 V1 选择：受限 HTTP/1.1

本周明确选择 **受限 HTTP/1.1 server**，不同时实现 HTTP/1.0 与 HTTP/1.1 两套细节。

V1 支持：

```text
request line：METHOD SP request-target SP HTTP/1.1 CRLF
header section：若干 header fields，以 CRLF CRLF 结束
Content-Length framed request body
GET /health
GET /hello
POST /echo
404 Not Found
400 Bad Request
413 Content Too Large
501 Not Implemented
505 HTTP Version Not Supported
HTTP/1.1 persistent connection
Connection: close
Content-Length framed responses
```

本周 parser 接受的 request-target 先保留为原始文本；route 只使用简单 origin-form path。query、percent-decoding 和路径规范化不展开。

这里的“受限 HTTP/1.1”是教学子集，不声称成为完整 RFC-compliant general-purpose HTTP/1.1 server。RFC 9112 要求 HTTP/1.1 recipient 能解析 `chunked` transfer coding，而本周有意不实现它；因此 README/口述必须把该限制写清，不能只因为 status line 写了 `HTTP/1.1` 就宣称完整兼容。

## 4.2 framing 与安全边界

本周必须写清：

```text
没有 Content-Length 且没有 Transfer-Encoding 的 request：body length = 0
有效 Content-Length：按十进制 octet 数读取 exact body
invalid / overflow / conflicting Content-Length：400，然后关闭
Transfer-Encoding + Content-Length：400，然后关闭
V1 不实现 chunked request；仅有 Transfer-Encoding：501，然后关闭
body 未达到 Content-Length：NeedMore，不提前交给 application
body 超过 V1 limit：413，然后关闭
```

拒绝 unsupported framing 是 V1 contract，不是“以后可能支持”这种含糊状态。HTTP/1.1 message framing 的判断顺序以 RFC 9112 为核验基准。

## 4.3 size limits

V1 必须有显式上限，避免 peer 永远不发送终止符而让 Buffer 无限制增长。初始建议值：

```text
request line：8 KiB
整个 header section：32 KiB
body：1 MiB
```

daily 可以根据真实实现微调，但必须满足：

```text
limit 写在 contract 中
达到和超过边界的行为可测试
错误 response 与 close policy 明确
不能只依赖 std::string 最终分配失败
```

## 4.4 connection policy

本周按两步演进：

```text
Day5：先让每条 connection 完成一个 response 后关闭
Day6：升级为 HTTP/1.1 persistent by default，并支持 Connection: close
```

关闭不能跳过 pending output：

```text
application 决定 response 后关闭
-> response bytes 进入 Connection
-> 若还有 pending output，继续等待 writable
-> output 全部交给 kernel 后再提交 close request
```

这会让当前 transport 暴露一个真实的新需求：close-after-flush。是否采用 `shutdown_after_write()`、`close_after_flush()` 或其他名称，在对应 daily 的 R1 中由你先设计；Week11 只固定行为，不提前泄露 representation。

---

# 5. 本周范围与停止边界

## 5.1 必须完成

```text
HttpRequest data model
incremental HttpRequestParser
request line / headers / Content-Length body
NeedMore / Complete / Error 三类结果
明确的 consumed-bytes 或等价 leftover contract
HttpResponse encoder
固定 routes
per-connection HTTP protocol state
close-after-flush
HTTP/1.1 keep-alive 与 Connection: close
fragmented / coalesced / pipelined input tests
malformed / oversized input tests
curl -v 与 raw client integration evidence
zero-warning CMake/CTest
ASan/UBSan covered-path evidence
```

## 5.2 只到第一层

```text
header field-name case-insensitive
OWS trim
Host 对 HTTP/1.1 request 的作用
method、target、version 与 status code semantics
HTTP/1.0 与 HTTP/1.1 persistence 差别
DNS -> TCP -> TLS -> HTTP 分层
TLS 提供 confidentiality、integrity，以及通常通过 server certificate 完成的 server authentication；client authentication 是可选能力
request smuggling 为什么与 framing ambiguity 有关
```

这些概念服务于当前 parser contract，不开独立安全课程或浏览器课程。

## 5.3 明确不做

```text
chunked transfer coding
multipart/form-data
gzip / content negotiation
Range / cache / conditional request
目录遍历式 static-file server
HTML template / frontend
WebSocket
TLS implementation / certificate deployment
HTTP/2 / HTTP/3 / QUIC
完整 URI parser
production-grade generic router
multi-thread EventLoop
TimerQueue / idle timeout
QPS benchmark 与“高性能 HTTP Server”宣传
README / interview 文档包装
```

如果 curl 的默认行为触发 V1 未支持特性，应先明确 client command 与 server contract，不为了“curl 什么都能发”临时扩张协议范围。

---

# 6. 七天总览

| Day | 主问题 | 当天核心产出 | 主要 evidence |
|---|---|---|---|
| Day1 | request line 怎样跨任意 TCP 分片解析 | `HttpRequest` + request-line parser V1 | split-point table、malformed cases |
| Day2 | headers 怎样增量结束、保存并限制大小 | header parser + Host/header policy | fragmentation、case/OWS、limit tests |
| Day3 | body 到哪里结束，一次 Buffer 有多条 request 怎么办 | Content-Length framing + complete parser | byte-by-byte body、binary body、coalesced requests |
| Day4 | structured response 怎样变成 exact HTTP bytes | response encoder + fixed route policy | exact wire bytes、status/body-length checks |
| Day5 | HTTP state 怎样接到每个 Reactor Connection | HTTP Server V1，先 one-response-then-close | curl、fragmented raw client、close-after-flush |
| Day6 | persistent connection、pipelining 与 error close 怎样共存 | HTTP/1.1 keep-alive V1 | two requests/one socket、pipeline、malformed then close |
| Day7 | 哪些证据足以证明 Week11 milestone | evidence ledger + protocol/layer flow | CTest、curl/raw clients、ASan/UBSan、口述复盘 |

七天是依赖顺序，不是强制自然日。某一天出现真实 parser/state-machine blocker，可以多用一天；不能为了追表格跳过 parser evidence，也不能靠增加教程字数拖慢已经掌握的部分。

---

# 7. Day1 规划：request line 与第一次 incremental parse

## 今日问题

```text
一次 recv 可能只有 "GE"，也可能一次带来完整 request 甚至下一条 request。
parser 怎样只根据当前 bytes 推进，而不把 recv 返回次数当作 HTTP message boundary？
```

## 新知识增量

```text
HTTP request line
method / request-target / version
SP 与 CRLF
incremental parser
NeedMore / Complete / Error
protocol data model
parser 不拥有 socket
```

## Round1

当天 daily 必须先明确程序用途、文件名、public behavior 与第一条运行命令。核心产出是：

```text
HttpRequest：保存 method、target、version 等 structured fields
HttpRequestParser V1：从 caller 提供的 bytes 中识别 request line
```

R1 固定 observable contract：

```text
输入可能在任意 byte 位置切开
缺少完整 CRLF 时返回 NeedMore
完整合法 request line 时形成 structured fields
格式错误时返回 Error，不越界、不无限等待
parser 不调用 recv，不拥有 fd，不生成 response
```

闸门前不提供 parser state members、delimiter-search algorithm 或完整 source。

## Round2

R1 正式通过后，根据真实代码解释：

```text
为什么 parser input 是 byte range / Buffer，而不是“一次 recv 的字符串”
request line grammar 与三个 token 的边界
CRLF 被拆成两次输入时，真实 representation 怎样保存进度
parser result 与 exception/error-code policy
哪些 state 属于 current request，哪些属于 parser lifecycle
```

## Round3

只补能区分实现是否正确的 tests：

```text
完整 request line
在每个 byte split point 分两次 feed
缺少 CRLF
多余/缺少 SP
非法或不支持 version
刚好达到与超过 request-line limit
```

当天不解析 headers，不接 socket。

---

# 8. Day2 规划：headers、Host 与 section limit

## 今日问题

```text
header lines 数量不固定，field name 不区分大小写，整个 section 还可能跨很多次 callback。
parser 怎样知道 headers 结束，并避免无限增长？
```

## 新知识增量

```text
header field-name / field-value
case-insensitive field name
OWS：optional whitespace
CRLF CRLF
Host
duplicate field policy
header section limit
```

## Round1

继续升级 Day1 同一 parser，不创建 `parser_v2`：

```text
解析零个或多个 header fields
遇到空行后结束 header section
以统一规则查找 field name
保留当前 V1 真正需要的 values
超过 header limit 时形成明确 Error
HTTP/1.1 缺失或重复 Host 时按 V1 contract 拒绝
```

daily 会明确接口用途和最小调用样例，但不会提前列完整 private representation 或 header loop 顺序。

## Round2

围绕用户真实 V1 串清：

```text
field name 为什么 case-insensitive，value 为什么不能全部强制 lowercase
leading/trailing OWS 怎样处理
为什么 CRLF CRLF 表示 header section 结束，不表示 request body 必然为空
重复 field 怎样进入 Day3 framing policy
limit 是在 append 前、scan 时还是 parse 后检查；当前实现真正保证了什么
```

## Round3

高价值 cases：

```text
headers 被任意拆分
CRLF CRLF 被拆开
Host 大小写变化
value 两侧 OWS
malformed header line
missing / duplicate Host
header bytes limit 边界
```

当天仍不接 Reactor。

---

# 9. Day3 规划：Content-Length、body 与完整 request framing

## 今日问题

```text
headers 解析完以后，当前 request 是否已经结束？
如果 Buffer 中还跟着 body 或下一条 request，哪些 bytes 属于谁？
```

## 新知识增量

```text
message framing
Content-Length
octet / byte length
Transfer-Encoding boundary
body limit
consumed bytes
coalesced / pipelined requests
parser reset
```

## Round1

把同一个 parser 补成完整 V1：

```text
无 body request 可以完成
Content-Length body 必须等到 exact bytes 到齐
body 可以包含 '\0'，不能依赖 C-string termination
Complete 后只消费当前 request 的 bytes
同一 input 中多余 suffix 留给下一次 parse
invalid framing 进入 stable Error state 或按明确 contract reset
```

V1 对 `Transfer-Encoding` 的拒绝策略与 `Content-Length` 冲突策略必须写进 tests，不允许 silently guess。

## Round2

根据真实实现解释 RFC 9112 framing precedence 中与 V1 有关的部分：

```text
为什么 Content-Length 是 octet count
为什么 body 不由 connection close 分隔
为什么 Transfer-Encoding + Content-Length 具有 ambiguity/smuggling 风险
NeedMore 与 malformed 的差别
Complete 后 parser/session 怎样开始下一条 request
```

只解释本项目支持的分支，不把完整 RFC 复制进教程。

## Round3

当天必须有 deterministic parser matrix：

```text
Content-Length: 0
body 每个 byte split point
body 含 '\0'
两条 complete requests coalesced
一条 complete + 下一条 partial
invalid / overflow Content-Length
conflicting duplicate Content-Length
Transfer-Encoding + Content-Length
unsupported Transfer-Encoding
body limit 边界
```

这些 tests 属于 parser 主课，不是可以全部省掉的 dirty work；机械性 case scaffold 可以由 Codex 协助生成，但 state 与 oracle 必须由用户理解。

---

# 10. Day4 规划：HttpResponse 与 route policy

## 今日问题

```text
parser 已经产生 structured request；怎样生成一个 framing 自洽、可被 curl 读取的 response，同时不把 route policy 塞回 transport？
```

## 新知识增量

```text
status line
status code / reason phrase
response headers
Content-Length
Content-Type
route / handler
protocol serialization
exact wire bytes
```

## Round1

纯内存实现，不接 Reactor：

```text
HttpResponse data model 或等价 representation
response encoder
固定 route policy
```

V1 routes：

```text
GET /health -> 200 + "OK\n"
GET /hello  -> 200 + 固定 text body
POST /echo  -> 200 + request body
已支持 method 下未知 target -> 404
未实现 method -> 501
```

每个 response 都生成正确 `Content-Length`。daily 会给一条最小调用样例，说明输入对象和输出 bytes，但不在 R1 前写完整 serializer。

## Round2

围绕真实实现解释：

```text
status code 是 machine-readable result，reason phrase 不是 framing 依据
Content-Length 计算的是 encoded body bytes
route/application 决定 semantics，encoder 只负责 wire format
400/413 是 parser/framing failure；404/501 是 application/server capability result
response object、encoded bytes 与 Connection output Buffer 的 ownership
```

## Round3

只做 exact-byte tests：

```text
200 / 404 / 501
empty body
body 含非 ASCII 或 '\0' 时 length 仍按 bytes
header terminator 恰好一个 CRLF CRLF
encoded Content-Length 与 body size 相等
```

不写通用 middleware/router framework。

---

# 11. Day5 规划：HTTP session 接入 Reactor

## 今日问题

```text
parser state 必须属于某一条 connection，但通用 Connection 又不应该知道 HTTP。
谁拥有每连接协议状态，MessageCallback 怎样找到它？
```

## 新知识增量

```text
application session
per-connection parser state
transport / protocol separation
callback capture lifetime
close-after-flush
composition root integration
```

## Round1

把 Day1~Day4 components 接入现有 Reactor，形成第一个可运行 HTTP Server V1：

```text
每条 active connection 有独立 parser/session state
Connection 仍只交付 input Buffer 与发送 bytes
收到完整 request 后 route -> encode -> Connection::send
Day5 暂定一条 connection 只服务一个 response
response 明确带 Connection: close
pending output 全部 flush 后才销毁 Connection
```

daily 必须给出最终程序用途、启动方式和一个最小 `curl -v` smoke，帮助快速判断 integration 是否活着；不会提前规定 session container、callback capture 或 close-after-flush 的唯一实现。

## Round2

R1 正式通过后，以真实 code 为基线只讲：

```text
parser/session 由谁拥有
callback 捕获什么，谁保证 captured object 仍存活
为什么不能把 HttpParser 作为所有 Connection 共享的一份 mutable object
为什么 response close 不能在 send() 返回后立刻 erase owner
close-after-flush 与 peer half-close 各自在表达什么
异常从 parser/application callback 逃出时，当前 close policy 是什么
```

## Round3

代表性 integration evidence：

```text
curl -v GET /health
curl -v GET /hello
curl -v POST /echo
raw client 把 request 拆成多次 send
response exact body
Connection: close 后 client 收到完整 response 再 EOF
```

Day5 不急着支持 keep-alive；先把 per-connection state 与 flush-before-close 站稳。

---

# 12. Day6 规划：keep-alive、pipelining 与 malformed close

## 今日问题

```text
HTTP/1.1 默认允许复用 connection。
一条 connection 上出现多条 request、partial next request 或 malformed request 时，parser、response order 和 close policy 怎样共同推进？
```

## 新知识增量

```text
persistent connection
Connection: close
pipelining
request/response order
parse loop
error response then close
incomplete request at EOF
```

## Round1

在 Day5 同一 server 上升级：

```text
HTTP/1.1 默认 keep-alive
一个 MessageCallback 处理当前 Buffer 中所有 complete requests
遇到 NeedMore 保留 parser/input state
同一 Buffer 中多条 request 按顺序生成 response
request 带 Connection: close 时，当前 response 后 flush-close
malformed / oversized request 生成对应 error response 后 flush-close
peer EOF 时，complete request 可完成；incomplete request 不冒充成功
```

R1 前不提前给完整 parse-loop 伪代码。daily 只固定动作、输出顺序和结束条件。

## Round2

根据真实实现串起完整因果链：

```text
readable event
-> append input
-> parser Complete / NeedMore / Error
-> possibly repeat parse
-> queue ordered responses
-> keep alive or mark close-after-flush
-> output drained
-> continue waiting or deferred cleanup
```

并解释：

```text
HTTP/1.1 persistent 不等于无限不关闭
pipelining 是同一 connection 上按序发送多个 requests，不是 HTTP/2 multiplexing
server 必须先完整消费或关闭当前 request，才能可靠解释后续 bytes
V1 不支持 chunked 时为什么必须明确拒绝，而不是按 Content-Length 猜
```

## Round3

高价值 raw-client scenarios：

```text
同一 socket 顺序发送两条 requests
一次 send coalesce 两条 requests
第一条 complete + 第二条 partial
Connection: close 后不处理后续 request
malformed request -> error response -> EOF
oversized request -> 413 -> EOF
half-close after complete request -> response 全部返回
```

不为了这些 cases 再写一套 server；client/testing scaffold 可以由 Codex 协助。

---

# 13. Day7 规划：HTTP Server V1 出口

## 今日问题

```text
怎样证明 Week11 得到的是一个 framing 明确、可增量解析、能承载多连接的 HTTP server，而不只是 curl 偶然显示了 200？
```

## Round1

不新写 feature。先从当前真实 source 独立画出：

```text
TCP bytes
-> Connection input Buffer
-> per-connection parser/session
-> HttpRequest
-> route
-> HttpResponse
-> encoded bytes
-> Connection output Buffer
-> dynamic EPOLLOUT / keep-alive / close-after-flush
```

同时填写一张 ownership table：

```text
Connection
HTTP session/parser
HttpRequest
HttpResponse / encoded bytes
callbacks
active-connection/session container
```

## Round2

只做 milestone 口述，不重复写网络代码：

```text
HTTP/1.0 与 HTTP/1.1 persistence 第一层
HTTP 与 HTTPS 的关系
DNS -> TCP -> TLS -> HTTP 的完整路径
TLS 提供 confidentiality、integrity，以及通常的 server authentication；client certificate authentication 当前不展开
为什么本项目没有 TLS 也仍然能证明 HTTP parser / Reactor architecture
为什么 parser state 与 transport state 必须分层
```

## Round3

建立 claim-to-evidence ledger，只重跑代表性矩阵：

```text
parser unit tests
response exact-byte tests
curl -v routes
fragmented request
coalesced / pipelined requests
Content-Length body
malformed / oversized request
keep-alive / Connection: close
repeated clients 与 fd count
zero-warning build
ASan/UBSan
```

若 HTTP integration 没引入 user threads，TSan 不是 Week11 默认必做证据。Week7/8 并发组件也不在 Day7 重跑。

---

# 14. 建议目录与 canonical code 规则

Windows 教程与笔记：

```text
C:\Users\FxorG\Desktop\gpt_infra\week11\
├── week11.md
├── day1\
│   ├── day1.md
│   └── day1_note.md
...
└── day7\
    ├── day7.md
    └── day7_note.md
```

Ubuntu 继续使用现有 Week10 project，并新增 HTTP files：

```text
~/code/system-learning/cpp/week10/
├── include/reactor/        # 现有 transport/Reactor，不复制
├── include/http/           # request/parser/response/session declarations
├── src/                    # 现有 source + HTTP implementation
├── apps/
│   ├── reactor_echo_server.cpp
│   └── http_server.cpp
└── tests/
    ├── 现有 Reactor tests
    ├── http_parser_test.cpp
    ├── http_response_test.cpp
    └── http_integration clients/probes
```

目录名称是建议，真实命名以 Day1 R1 为准。必须遵守：

```text
只维护一份 HttpParser implementation
不把每个 Day 复制成 parser_v2/parser_final
保留 echo server 作为 transport regression target
HTTP tests 与 Reactor tests 进入同一 CMake/CTest graph
不修改 build artifacts 充当 source
```

---

# 15. Daily 教程生成规则

Week11 daily 继续使用系统主线规则，不受 AI Theory `Tn.md` 编排影响：

```text
Part 1：前情提要与必要术语
Part 2：教程主体，并明确标出“教程开始”
Part 3：证据、验收与下一步
```

每份初始 daily 完整生成 R1/R2/R3，但阅读顺序仍有闸门：

```text
R1：明确程序用途、文件名、public contract、必要 API、最小 smoke
-> 用户独立写出可运行 V1

R2：完整机制讲解
-> R1 正式通过后，依据真实 code/note/对话定向润色

R3：真正增加区分力的 tests、tool evidence 和工程收口
```

Week11 特别注意：

```text
R1 前可以给 wire-format example，但不能把 parser algorithm 翻译成伪代码答案
contract 要说清 callback 何时调用、输入是什么、返回结果表示什么
API 第一次出现时说明参数、返回值、error，并给最小使用例
术语第一次出现说明英文来源、中文含义、当前作用和容易混淆的边界
先串主线，再补为什么；不能在学生尚未看懂 request flow 前堆 framing 边角
错误边界集中成一张 contract 表，不反复提醒“不要犯错”
parser tests 属于主课；重复 shell 与机械 test scaffold 可以交给 Codex
Python raw client 只补少量 socket API 注释，不改成 Python 入门课
```

用户在阅读 daily 期间写入的解释、注释和问题答案必须保留。R1 正式通过后：

```text
先 git status / git diff
以磁盘当前 daily 为唯一基线
按真实 R1 representation 定向修改 R2/R3
把“如果 A/如果 B”改成针对用户实现的明确升级动作
不从旧 commit 整段覆盖
```

普通侧边提问默认只在对话中回答；只有用户明确要求写入 daily，或 R1 正式通过触发定向润色时，才修改教程文件。

Mermaid 必须兼容 Typora 当前 Mermaid 8.8.3：使用简单 node label 和 edge，不使用新版本专属语法；生成后实际检查渲染。

---

# 16. 编译、测试与证据纪律

## 16.1 编译

继续使用：

```text
C++17
-Wall -Wextra -g
CMake / CTest
```

新增 HTTP target 后必须 fresh configure/build 一次，避免旧 object 让“编译通过”成为假象。

## 16.2 Parser tests 的优先级

parser 是 Week11 主课，测试优先覆盖 state transition，而不是只测 happy path：

```text
每个 delimiter split point
NeedMore 不消费错误 bytes
Complete 只消费当前 message
Error 不继续产生 request
limits 的边界值
binary body
coalesced requests
```

使用 parameterized helper 生成 split cases 是减少体力活，不是降低要求。用户必须能解释 helper 建立了什么状态和 oracle。

## 16.3 Integration evidence

`curl -v` 用于观察真实 request/response headers 和 connection 行为，但它不是唯一 oracle。至少再保留一个 raw Python client，用于控制：

```text
fragmentation
coalescing
pipelining
malformed bytes
half-close
```

Python helper 第一次出现的 socket API 做简短注释：`create_connection`、`sendall`、`recv`、timeout、EOF 与 bytes；不扩成 Python 基础教程。

## 16.4 Sanitizer

```text
ASan/UBSan：HTTP parser、Buffer、session/callback lifetime 的 covered paths
TSan：只有引入新的并发读写后才运行
```

sanitizer clean 只说明实际覆盖路径没有观察到对应报告，不等于 parser protocol semantics 正确。protocol correctness 由 exact tests 与 raw-client scenarios 支撑。

---

# 17. 资料与课程边界

## 17.1 本周权威核验入口

不要求从头通读 RFC。daily 只在相关日引导到对应部分：

- [RFC 9112：HTTP/1.1 messaging syntax 与 framing](https://www.rfc-editor.org/rfc/rfc9112.html)
- [RFC 9110：HTTP semantics、methods 与 status codes](https://www.rfc-editor.org/rfc/rfc9110.html)
- [curl HTTP scripting](https://curl.se/docs/httpscripting.html)

使用方式：

```text
daily 先给自足中文主线
-> 指出本日对应 RFC section
-> RFC 用于核验精确 contract，不承担第一次教学
```

本地《图解网络》可选择 HTTP/HTTPS、DNS、TLS handshake 的图，帮助建立分层直觉；图片必须和本日主线直接相关，并注明来源位置，不为了“有图”塞装饰图。

## 17.2 MIT 6.S081 / CSAPP / CS144

```text
MIT 6.S081：本周不新增 lecture 压力，长期完整通关目标不变
CSAPP Chapter 11 Web Server：可选对照，不作为 parser contract 的唯一来源
CS144：不启动完整 TCP stack；本周使用 Linux TCP，不实现 transport protocol
```

Week11 的重点是 application framing，不再回头重讲三次握手、epoll 或 socket 入门。

---

# 18. AI Theory 伴随线

总规划原时间轴希望 Week11 出口到 T6，但当前真实状态是：

```text
T1 已正式通过
T2 尚未学习验收
T3 尚未学习验收
T4~T13 教程已生成，不等于已完成
```

本周不做“从 T1 一口气假装冲到 T6”。真实目标：

```text
必达：完成 T2、T3
余力：开始 T4，但不为追进度跳过 gradient-check 认知闸门
暂不要求：T5、T6
```

安排建议：

```text
每天 30~60 分钟
前半周完成 T2
后半周完成 T3
HTTP 主线顺利且精力足够时再开启 T4
```

T2/T3 需要复习的学校数学内容只列知识点名称，由用户使用自己的成套笔记复习；教程不重写粗糙线性代数课。系统主线仍每天 3 小时以上，两条线分别验收、分别记录真实进度。

这意味着 T4~T6 成为显式 schedule debt，后续按真实速度重新分配；不能把未学习文件因为“已经生成”记成完成，也不能为了还债延迟 Week12 Mini Redis 主线。

---

# 19. Week11 核心验收问题

不要求逐题抄写；代码、tests、流程图或口述已经证明的内容直接引用证据。

1. 为什么一次 `recv` 不能对应一条 HTTP request？
2. parser 的 `NeedMore`、`Complete`、`Error` 分别意味着什么？
3. request line、headers 和 body 分别怎样确定结束位置？
4. 为什么 `Content-Length` 计算 bytes，而不是字符个数？
5. 为什么 `Transfer-Encoding + Content-Length` 不能由 V1 随便选一个解释？
6. complete request 后 input Buffer 中的 suffix 应由谁处理？
7. parser state 为什么必须 per connection？
8. HTTP session 与 Connection 分别拥有或保存什么？
9. response 为什么必须带自洽的 `Content-Length`？
10. `Connection: close` 为什么不能让 owner 在 `send()` 返回后立刻销毁对象？
11. HTTP/1.1 keep-alive 下，一次 callback 为什么可能处理多条 request？
12. malformed request 为什么通常应在 error response flush 后关闭？
13. HTTP/1.0、HTTP/1.1 与 HTTP/2 的 framing/connection 模型有哪些第一层区别？
14. HTTPS 比 HTTP 多了哪一层？TLS 保护什么、不保护什么？
15. curl、raw client、parser unit test、ASan 各自能证明什么？

---

# 20. Week11 最终通过标准

## 20.1 核心通过

```text
受限 HTTP/1.1 contract 写清
request line / headers / Content-Length parser 可增量推进
arbitrary fragmentation 下结果正确
Complete 后不会吞掉下一条 request 的 bytes
malformed / oversized input 有明确结果
Transfer-Encoding unsupported boundary 明确
response encoder 的 wire bytes 与 Content-Length 自洽
固定 routes 可由 curl 访问
per-connection parser/session ownership 可解释
Connection 仍保持 transport-only
close-after-flush 正确
keep-alive / Connection: close 正确
coalesced / pipelined requests response order 正确
error response 不让 server 崩溃
zero-warning build
parser/response/integration tests 进入 CTest
ASan/UBSan covered paths 无 report
能画出 transport -> parser -> route -> response -> transport 全链
```

## 20.2 不阻塞 Week11

```text
没有 chunked request/response
没有 HTTP/1.0 compatibility implementation
没有 static-file directory server
没有 TLS
没有 HTTP/2/3
没有 production router/middleware
没有 multi-thread Reactor
没有 TimerQueue / idle timeout
没有 QPS benchmark
没有 README / interview 文档
AI Theory 尚未追到 T6
```

AI Theory T2/T3 是本周真实伴随目标；若没有完成，要记录延期，但不把一个正确 HTTP Server 判成失败。两条线不能互相伪造完成状态。

## 20.3 真正不能通过的情况

```text
把一次 recv 当成完整 request
parser 依赖 '\0' 或 C-string API 处理 binary body
partial request 被提前交给 route
Complete 时把下一条 request 的 prefix 一起消费
所有 connection 共享一份 mutable parser state
HTTP fields 被塞进通用 Connection
response body size 与 Content-Length 不一致
send 后立即 erase，pending output 被丢弃
malformed input 让 exception 直接终止整个 server
不支持 Transfer-Encoding 却 silently 按 Content-Length 猜
keep-alive 下只处理第一条 request，然后等待不会再来的 readiness
只有一次 curl 200，没有 fragmentation/framing evidence
```

---

# 21. 与 Week12 Mini Redis 的连接

Week12 不会复用 HTTP syntax，但会直接复用 Week11 的设计纪律：

```text
TCP bytes 没有 message boundary
parser 独立于 transport
每连接保存 incremental protocol state
Complete 只消费当前 frame
application command 不直接管理 fd
encoded response 仍通过 Connection output Buffer
malformed input 有协议级 error，不让 process 崩溃
```

映射关系：

```text
HttpRequestParser -> RespParser
HttpRequest       -> RespValue / Command
route policy      -> command dispatcher
HttpResponse      -> RESP encoder
HTTP session      -> Mini Redis client session
```

Week11 如果真正把 parser/transport/session 分层做好，Week12 的新增量就能集中在 RESP 与 KV semantics，而不是第三次修理 socket lifetime。

---

# 22. 本周一句话

```text
TCP 交付任意分片的 bytes；
Connection 保存 transport state；
HTTP session 保存每连接 protocol state；
parser 用 framing 把 bytes 还原为 request；
application 产生 response；
Connection 在不丢 pending output 的前提下保持或结束连接。
```
