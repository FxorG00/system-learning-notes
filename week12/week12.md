# Week12：RESP2 Incremental Parser 与 Mini Redis V1

> 版本：2026-10-01，基于 Week11 HTTP Server V1 正式通过后的真实进度生成
> 系统主线：Week1~Week11 已完成，进入 Milestone D
> AI Theory：T1~T3 已通过，下一项是 T4
> 本周核心产出：一个真正跑在现有 Reactor 上、能被多个 TCP clients 使用的 Mini Redis V1

---

## 1. 这一周从什么问题出发

Week11 已经解决了一个完整问题：

```text
TCP 只交付任意分片的 bytes
-> Connection 把 bytes 累积进 input Buffer
-> HTTP parser 从 prefix 中证明一条 request 是否完整
-> application route 产生 response
-> Connection 把 response flush 到 socket
```

Week12 不再重写 socket、epoll、Channel、EventLoop、Acceptor、Connection 或 Buffer。

今天开始换掉的是 application protocol 与 application state：

```text
HTTP request / response
-> RESP command / reply

固定 HTTP routes
-> 可变化的 key-value state
```

本周要回答的主问题是：

> **怎样把任意分片的 TCP bytes 还原成一条条 RESP commands，再让多个 clients 通过同一个 Reactor 读写同一份 KV store？**

这不是“再写一遍大模拟”。Week11 已经证明你能处理复杂 framing；本周真正新增的是：

```text
长度前缀协议怎样增量解析
binary-safe data 怎样跨 parser / store / encoder 保持原样
protocol error 与 command error 为什么必须采用不同连接策略
多个 client session 怎样共享 application state，又不共享 transport state
```

---

## 2. 本周在总规划中的位置

主线位置：

```text
Week9  Epoll Echo Server
-> Week10 Reactor V1
-> Week11 HTTP Server V1
-> Week12 RESP + KV，也就是 Mini Redis V1
-> Week13 TTL / expiration lifecycle
-> Week14 AOF / restart recovery
-> Week15 tests / sanitizer / fault / benchmark
-> Week16 README / architecture / resume expression
```

Week12 是 Mini Redis 主项目真正开始形成产品语义的一周。

Week10/11 的代码不是两个需要丢掉的练习，而是 Mini Redis 的底座：

| 已有 component | Week12 继续承担的职责 |
|---|---|
| `EventLoop` | 等待 ready events，并 dispatch 当前一轮 records |
| `Channel` | 把 epoll event bits 转成 callbacks |
| `Acceptor` | 创建 non-blocking connected socket |
| `Connection` | 拥有 connected fd、input/output Buffer 与 transport state |
| `Buffer` | 累积任意分片的 bytes，并逻辑消费已处理 prefix |
| deferred cleanup | callback 中只提交 close request，安全点统一 erase owner |

本周新增：

| 新 component | 职责 |
|---|---|
| RESP encoder | 把 reply object 编码成 exact wire bytes |
| RESP request parser | 从 input Buffer 的 prefix 解析一条 command |
| command dispatcher | 检查 command name / arity，并执行对应语义 |
| KV store | 拥有 keys 与 values |
| Mini Redis application | 把 Connection、parser、dispatcher、store 和 close policy 组合起来 |

---

## 3. Week12 结束时要拥有的东西

本周最终程序暂定名：

```text
mini_redis_server
```

它至少支持：

```text
PING
PING message
ECHO message
SET key value
GET key
DEL key [key ...]
EXISTS key [key ...]
```

最小使用结果：

```text
client A: SET name FxorG
server:   OK

client B: GET name
server:   FxorG

client A: DEL name
server:   1

client B: GET name
server:   nil
```

这里故意使用两个 clients：它证明 store 属于 server application，而不是某一条 Connection。

本周出口需要形成四类 evidence：

```text
1. 纯内存 RESP encoder exact-byte tests
2. RESP incremental parser split/coalesced/binary/error tests
3. command/store semantics tests
4. process-external multi-client / pipelining / failure-isolation tests
```

---

## 4. 最终架构主线

先只记住这一条完整链：

```text
client TCP bytes
-> Connection input Buffer
-> RESP parser
-> command arguments
-> command dispatcher
-> shared KV store
-> reply object
-> RESP encoder
-> Connection output Buffer
-> client TCP bytes
```

一条 `SET name FxorG` 在本项目中的执行主体：

```text
Connection
    只负责收到 bytes、保存 bytes、发送 bytes

RESP parser
    只负责证明一条 command frame 是否完整，并解析参数边界

command dispatcher
    只负责识别 SET、检查参数数量、调用 store

KV store
    只负责保存 name -> FxorG

RESP encoder
    只负责把成功结果编码为 +OK\r\n
```

不要把这些职责重新揉回一个巨大的 MessageCallback。组合入口可以串联它们，但每个 component 必须能被纯内存测试。

---

## 5. 本周采用的 RESP2 范围

### 5.1 RESP 是什么

RESP 是 **Redis Serialization Protocol（Redis 序列化协议）**。

它解决的不是“怎样执行 SET”，而是：

> client 和 server 怎样在 TCP byte stream 中表达 command、argument 和 reply 的边界与类型。

RESP2 中，本周会遇到五种 wire forms：

| 首字节 | 类型 | 最小例子 | 本周用途 |
|---|---|---|---|
| `+` | Simple String，简单字符串 | `+OK\r\n` | `SET`、`PING` 成功回复 |
| `-` | Error，错误 | `-ERR unknown command\r\n` | protocol/command error reply |
| `:` | Integer，整数 | `:1\r\n` | `DEL`、`EXISTS` |
| `$` | Bulk String，长度前缀字符串 | `$5\r\nhello\r\n` | key、value、`GET`、`ECHO` |
| `*` | Array，数组 | `*2\r\n$3\r\nGET\r\n$4\r\nname\r\n` | client request |

官方 RESP model 是：client request 通常是一组 strings，第一个 element 是 command name，后面是 arguments。

### 5.2 本项目只接受的 request shape

本周 client request 只接受：

```text
top-level non-null RESP Array
-> 每个 element 都是 non-null Bulk String
-> element 0 是 command name
-> elements 1..N 是 command arguments
```

例如：

```text
SET name FxorG
```

wire bytes：

```text
*3\r\n
$3\r\n
SET\r\n
$4\r\n
name\r\n
$5\r\n
FxorG\r\n
```

本周不接受：

```text
inline command protocol
RESP3 types
nested arrays
null top-level array
null command arguments
arbitrary generic RESP trees
```

这是产品边界，不是 parser 能力不足的遮掩。当前 commands 根本不需要递归 value tree，直接产出一组 binary-safe arguments 更符合项目用途。

### 5.3 binary-safe 的含义

Bulk String 的边界由声明的 byte length 决定，不由 `\0`、空格或换行决定。

因此：

```text
key/value 可以含 '\0'
std::string 可以保存这些 bytes
C-string API 不能决定 frame 边界
command name 才做 ASCII case-insensitive 比较
key/value bytes 不做 lowercase、trim 或字符编码转换
```

Week11 的 `Content-Length` 经验会直接迁移到这里：**长度字段描述 bytes，而不是“看起来有几个字符”。**

---

## 6. Commands 的 V1 contract

### 6.1 `PING`

```text
PING
-> +PONG\r\n

PING hello
-> $5\r\nhello\r\n
```

只允许 0 或 1 个 argument。

### 6.2 `ECHO`

```text
ECHO hello
-> $5\r\nhello\r\n
```

必须恰好 1 个 argument；reply 保留 argument 的全部 bytes。

### 6.3 `SET`

```text
SET key value
-> +OK\r\n
```

V1 只支持恰好两个 arguments。重复 `SET` 同一个 key 会覆盖旧 value。

本周不支持：

```text
NX / XX
EX / PX / EXAT / PXAT
GET option
KEEPTTL
```

这些不是漏实现。TTL 和 expiration lifecycle 属于 Week13。

### 6.4 `GET`

存在：

```text
GET key
-> Bulk String
```

不存在：

```text
GET missing
-> $-1\r\n
```

`$-1\r\n` 是 RESP2 null bulk string，不是长度为 `-1` 的真实 payload。

### 6.5 `DEL`

```text
DEL key [key ...]
-> Integer reply
```

返回真正删除的 keys 数量。重复列出同一 key 时，第一次删除后，后续同名 argument 不会再次增加计数。

### 6.6 `EXISTS`

```text
EXISTS key [key ...]
-> Integer reply
```

按照 Redis command semantics，重复 key 会重复计数：

```text
store 中存在 a
EXISTS a a missing
-> :2\r\n
```

### 6.7 command name 与 argument

```text
set / SET / SeT
```

都识别为同一个 command。

只对 command name 做 ASCII case-insensitive normalization。不能把整个 arguments vector 转小写，否则 binary key/value 会被改变。

---

## 7. 三类失败必须分开

### 7.1 incomplete frame

当前 bytes 还不够证明 command 完整：

```text
parser -> NeedMore
input Buffer -> 不消费当前 frame prefix
connection -> 保持打开，等待下一次 readable event
```

### 7.2 malformed protocol

例如 length token 非法、CRLF 错误、声明超限、top-level 不是允许的 request array：

```text
parser -> Error
application -> 编码 protocol error reply
connection -> close after flush
```

原因很直接：当前 byte stream 已经失去可靠 frame boundary，继续复用连接会让后续 bytes 的解释产生歧义。

### 7.3 valid frame，但 command semantics 错误

例如：

```text
未知 command
SET 少一个 argument
GET 多一个 argument
DEL 没有 key
```

这时 framing 没坏：

```text
dispatcher -> Error reply
connection -> 保持打开
下一条 command -> 继续解析
```

本项目不追求逐字复制某个 Redis release 的全部 error text，但同一错误必须有稳定的 project message，tests 不能模糊匹配“只要以 - 开头就算对”。

建议统一采用：

```text
-ERR Protocol error: <reason>\r\n
-ERR unknown command\r\n
-ERR wrong number of arguments for '<command>' command\r\n
```

daily 在真正写 tests 前会冻结 exact strings。

---

## 8. 所有权与执行模型

### 8.1 谁拥有什么

| 对象/状态 | owner | lifetime |
|---|---|---|
| connected fd | `Connection` 内部 `UniqueFd` | 从 accept 到 Connection 析构 |
| unread bytes | 每个 `Connection::input_` | 直到 parser 确认并消费 frame |
| pending reply bytes | 每个 `Connection::output_` | 直到全部写入 kernel 或连接终止 |
| parser 临时结果 | 当前 MessageCallback / session flow | 一次 parse attempt 或一条 command |
| active Connection objects | Mini Redis application 的 owner map | accept 到 deferred erase |
| KV store | Mini Redis application | server process lifetime |
| command arguments | parser result / dispatch call | 当前 command 执行期间 |

### 8.2 为什么 store 不属于 Connection

如果每条 Connection 各自拥有一个 map：

```text
client A SET name FxorG
client B GET name
```

client B 会看不到 client A 的写入，这不符合 server-level keyspace。

所以本周只有一份 application-owned store，所有 active clients 通过 dispatcher 访问它。

### 8.3 为什么当前 store 不需要 mutex

Week12 的 EventLoop 仍是单线程：

```text
一次 event callback 执行到返回
-> EventLoop 才 dispatch 下一项工作
```

所以当前 commands 在同一 event-loop thread 中串行执行，`std::unordered_map` 不发生并发读写。

准确说法是：

> 当前 architecture 通过单线程串行执行避免 data race；`KvStore` 本身不是一个可以被任意 threads 并发调用的 thread-safe class。

本周不为了“以后可能多线程”提前加 mutex，也不把 ThreadPool 接进 command path。

---

## 9. Parser 的资源限制

长度前缀协议不能只验证语法，还必须限制资源申请。

Week12 daily 在 Day2 前冻结三个 exact constants，初始建议为：

```text
max_bulk_bytes = 1 MiB
max_command_elements = 1024
max_request_frame_bytes = 2 MiB
```

三个限制分别回答：

```text
单个 key/value 最多多大？
一条 command 最多多少 arguments？
一条尚未消费的 request frame 最多占多少 input bytes？
```

parser 在看到超限 declaration 时就应返回 Error，不应等攻击者把对应 payload 全部发完。

数字未来可以配置，但 V1 tests 必须针对固定值建立 boundary evidence：

```text
limit - 1
limit
limit + 1
numeric overflow
negative length 的允许分支与拒绝分支
```

---

## 10. 七天总览

| Day | 主问题 | 当日新增产出 |
|---|---|---|
| Day1 | RESP reply 怎样变成 exact bytes？ | RESP model + encoder |
| Day2 | 怎样从 Buffer prefix 解析一条 command？ | incremental request parser V1 |
| Day3 | fragmentation、coalescing、binary 与 limits 是否真的正确？ | parser hardening + deterministic matrix |
| Day4 | command 怎样改变共享 KV state？ | `KvStore` + command dispatcher |
| Day5 | 怎样接入现有 Reactor？ | 可运行 `mini_redis_server` |
| Day6 | 多 clients、pipelining 和坏 client 是否互不破坏？ | process-external integration evidence |
| Day7 | 怎样证明 Mini Redis V1 完成，并看懂它与真实 Redis 的边界？ | architecture/evidence review + 真实 Redis 地图 |

每一天仍按主线 daily 的三 Part、R1/R2/R3 规则生成；本文件只规定周目标，不提前把未来每天的完整答案摊开。

---

# Day1：RESP reply model 与 encoder

## 11. 今日问题

```text
command 执行结果怎样变成 client 可以准确拆分的 wire bytes？
```

今天先从输出方向开始，因为 encoder 是纯函数，能先把 RESP 的 exact byte contract 站稳。

## 11.1 Round1

独立完成一个最小 RESP encoder，建议文件：

```text
include/resp/resp_encoder.hpp
src/resp_encoder.cpp
tests/resp_encoder_test.cpp
```

R1 必须能编码：

```text
Simple String
Error
Integer
Bulk String
Null Bulk String
```

daily 会明确每个接口的用途、输入、输出、错误 contract 和一条最小调用样例，但不会在闸门前提供完整实现。

## 11.2 Round2

R1 正式通过后，只围绕真实 representation 解释：

```text
为什么 bulk string 先写 byte length
为什么 std::string 可以保存 embedded NUL
为什么 simple string/error 需要限制 CR/LF
integer 转 decimal text 时的边界
reply object 与 encoded bytes 的 lifetime
```

## 11.3 Round3

只补 exact-byte matrix：

```text
empty bulk
bulk with '\0'
positive / zero / negative integer
simple string OK/PONG
stable error text
null bulk
```

Day1 不接 socket，不实现 parser，不写 KV store。

---

# Day2：RESP request parser V1

## 12. 今日问题

```text
input Buffer 中可能只有半个 frame，也可能已有两条 commands；
parser 怎样只判断并消费第一条？
```

## 12.1 Round1

建议文件：

```text
include/resp/resp_request_parser.hpp
src/resp_request_parser.cpp
tests/resp_request_parser_test.cpp
```

R1 从完整使用目的出发：

```text
输入：一段当前累计的 unread bytes
输出：NeedMore / Complete / Error
Complete：同时给出一组 command arguments 与 exact consumed_bytes
NeedMore：不得提交半成品 command，也不得让 caller 消费当前 frame
Error：给出稳定的 protocol error reason
```

支持的 request shape 只是一层 Array + Bulk Strings，不要求先设计通用递归 `RespValue` class hierarchy。

## 12.2 Round2

R1 正式通过后，根据真实 code 串清：

```text
怎样从 prefix byte 判断下一段 grammar
怎样区分数字尚未结束与数字已经非法
为什么 CRLF 是 protocol bytes，不是普通 whitespace
为什么 declaration 到齐不等于 payload 到齐
为什么 Complete 的 consumed_bytes 只到当前 frame 末尾
```

## 12.3 Round3

先做最小确定性 cases：

```text
PING complete frame
SET complete frame
frame 末尾缺一个 byte -> NeedMore
top-level marker 错误 -> Error
array element 不是 bulk string -> Error
Complete 后 suffix 保留
```

Day2 先获得一个能工作的 parser V1；全 split points、limits 和 binary matrix 放到 Day3 集中处理。

---

# Day3：incremental framing、binary safety 与 limits

## 13. 今日问题

```text
Day2 在几个手写例子上能 parse，是否足以证明它能处理 TCP 的任意分片？
```

不够。Day3 不是再写一份 parser，而是让同一份 parser 经历真正区分正确性的输入。

## 13.1 Round1

保持 Day2 public contract，在同一 implementation 上处理：

```text
每个 byte split point
一次收到两条 commands
第一条 complete + 第二条 partial
bulk payload 含 '\0'、CR、LF 与空格
length declaration overflow
bulk / element-count / total-frame limits
```

用户负责 parser 状态模型与修复。机械性的 parameterized GoogleTest loop 可以由 Codex 协助，但用户必须能说明每类 case 的 oracle。

## 13.2 Round2

基于真实失败和修复解释：

```text
prefix proof：什么时候证据足够返回 Complete
transactional output：NeedMore/Error 为什么不能污染 public result
declared length 与 available bytes 的关系
frame limit 为什么不等于 Buffer capacity
coalesced input 为什么需要 consumed_bytes
```

## 13.3 Round3

固定 parser matrix：

```text
all split points for one SET frame
embedded NUL key/value
empty key/value
two complete frames coalesced
complete + partial suffix
invalid decimal token
numeric overflow
forbidden negative lengths
null bulk argument rejected
limit - 1 / limit / limit + 1
```

parser tests 是本日主课，不全部归类为 dirty work；重复 case scaffold 可以委托，状态判定与 oracle 不能委托掉。

---

# Day4：KV store 与 command dispatcher

## 14. 今日问题

```text
parser 已经交付 ["SET", "name", "FxorG"]；
谁检查 command semantics，谁真正拥有 name -> FxorG？
```

## 14.0 Part1 先补 Redis 第一层

Day1、Day2 已经能直接学习 RESP，因为它们解决的是 byte framing；不需要倒回去先学完整 Redis。Day4 开始写共享 state 前，daily 必须先把下面这条主线讲清楚：

```text
client 发送 command
-> Redis server 解释 command
-> command 读取或修改 server-lifetime state
-> server 编码 reply
-> client 收到结果
```

从一个具体问题出发：

> 多个 clients 都执行 `SET name FxorG` 和 `GET name` 时，`name -> FxorG` 究竟存在哪里，为什么换一条 connection 仍然能够读到？

Day4 Part1 必须顺着这个问题讲清：

```text
database：有组织地保存和查询 data 的系统
cache：为了更快访问而保存的一份临时/可替代数据；不是所有 Redis 用法都只是 cache
KV store：通过 unique key 查找 value 的存储模型
in-memory：主要 working state 在 memory 中；不等于永远不能持久化
keyspace：当前 database 中全部 keys 构成的名字空间
command：client 请求 server 执行的操作
reply：server 对一条 command 返回的协议结果
```

随后用一份最小 state trace 建立直觉：

```text
初始 store = {}
SET name FxorG  -> store = {name: FxorG}，reply = success
GET name        -> store 不变，reply = "FxorG"
EXISTS name     -> store 不变，reply = 1
DEL name        -> store = {}，reply = 1
GET name        -> store 不变，reply = null
```

必须明确当前产品边界：真实 Redis 是 data structure server，支持 Strings、Hashes、Lists、Sets 等多种 data types；本周 Mini Redis 只实现 **binary-safe string key -> binary-safe string value**。`PING`/`ECHO` 不访问 store；`SET` 修改 state；`GET`/`EXISTS` 观察 state；`DEL` 删除 state。TTL、eviction、AOF/RDB 与 transaction 仍留给后续周。

教程正文负责把这条链讲完整，不把“去看 Redis 官网”当讲解。官方资料只作查证：[Redis data types](https://redis.io/docs/latest/develop/data-types/)、[Redis keyspace](https://redis.io/docs/latest/develop/using-commands/keyspace/)、[Redis Strings](https://redis.io/docs/latest/develop/data-types/strings/)。

## 14.1 Round1

纯内存完成：

```text
KvStore
CommandDispatcher 或等价 command layer
```

建议文件：

```text
include/mini_redis/kv_store.hpp
src/kv_store.cpp
include/mini_redis/command_dispatcher.hpp
src/command_dispatcher.cpp
tests/command_dispatcher_test.cpp
```

R1 必须实现本周六个 commands 的语义，并返回可以交给 RESP encoder 的结构化结果或等价 representation。

daily 会给出最小调用样例，让你知道 component 最终怎样组合；不会在 R1 前规定 `unordered_map` 包装、variant、enum 或 callback 的唯一内部写法。

## 14.2 Round2

R1 通过后，根据真实 code 解释：

```text
store ownership 与 server lifetime
command name normalization 与 binary arguments 的边界
GET missing 为什么是 null bulk，不是 error
DEL 与 EXISTS 的计数语义
unknown / wrong arity 为什么不破坏 framing
single-thread EventLoop 如何串行化当前 commands
```

## 14.3 Round3

代表性 semantics matrix：

```text
SET new / overwrite
GET hit / miss / embedded NUL
DEL existing / missing / duplicates
EXISTS hit / miss / repeated keys
PING zero/one argument
ECHO exact bytes
case-insensitive command name
wrong arity / unknown command 后下一条 valid command 仍可执行
```

重复的 test body 可以由 helper/table 驱动；用户需要独立完成 command/store 核心代码。

---

# Day5：接入 Reactor，跑起 Mini Redis Server

## 15. 今日问题

```text
纯内存 parser、dispatcher 和 store 都成立后，怎样把它们接进现有 Connection，而不让 transport 层认识 Redis？
```

## 15.1 Round1

新增：

```text
apps/mini_redis_server.cpp
```

目标：

```text
accept client
-> Connection 收到 bytes
-> application parse loop 处理所有 complete commands
-> dispatcher 访问 shared store
-> encoder 产生 replies
-> Connection::send
-> NeedMore 时保留 unread suffix
```

R1 必须配一条最小 process-external smoke，例如：

```text
PING
SET name FxorG
GET name
```

默认监听端口建议使用 `6380`，避免与本机真实 Redis 默认端口 `6379` 冲突。

## 15.2 Round2

R1 正式通过后，按真实代码定向串清：

```text
MessageCallback 何时被调用
为什么局部无状态 parser 也能增量解析
为什么 partial frame 真正存放在 Connection input Buffer
store 怎样被所有 client callbacks 安全引用
一轮 callback 为什么可能产生多个 replies
protocol Error 为什么 close-after-flush
command Error 为什么保持 connection
```

## 15.3 Round3

最小 integration evidence：

```text
raw client split-send 一条 SET
server 正确保留 partial prefix
GET 得到 exact value
同一 socket 连续执行多条 commands
unknown command 后 PING 仍成功
malformed protocol 得到 error 后 EOF
```

Day5 不新增线程、TTL、AOF 或 benchmark。

---

# Day6：multiple clients、pipelining 与 failure isolation

## 16. 今日问题

```text
一个 client 的 partial frame、坏协议或慢读取，是否会污染其他 clients 的 state？
```

## 16.1 Round1

在同一 server 上建立 process-external scenarios：

```text
client A SET，client B GET
client A 保留 partial command 时，client B 正常 PING/GET
一个 send coalesce 多条 commands，replies 顺序一致
一个 bad client protocol error + close，不影响 good client
binary key/value round trip
repeated connect/close 后 fd count 回落
```

本日重点不是让用户手写大量 Python boilerplate。用户要先定义 scenario、状态与 oracle；机械 client harness 可以由 Codex 协助实现。

## 16.2 Round2

围绕实际 observation 解释：

```text
每 Connection 独立 input/output 的 isolation
server-level store 的共享
pipelining 的 request/reply order
一个 callback 连续 parse 到 NeedMore 为止
close request 为什么仍要 deferred erase
backpressure 仍由 Connection output + dynamic EPOLLOUT 承担
```

## 16.3 Round3

本日收集 evidence：

```text
fresh Debug build，零 warning
完整 CTest
normal process-external matrix
ASan/UBSan 覆盖 parser、store、integration paths
可选 redis-cli compatibility smoke
```

如果项目仍没有新增 user threads，TSan 不是 Week12 默认必跑项。不要为了工具清单重复证明 Week10 已有的单线程 Reactor lifetime。

---

# Day7：Mini Redis V1 出口与 storage 第一层

## 17. 今日问题

```text
怎样证明这是一套分层清楚、可被多个 clients 使用的 KV server，
而不是几个 command 恰好打印出了正确字符串？
```

## 17.1 Round1：恢复项目主链

不新写 feature。根据真实代码独立画出：

```text
accept
-> Connection input
-> RESP parser
-> command dispatcher
-> shared KvStore
-> reply encoder
-> Connection output
-> EPOLLOUT drain
-> deferred cleanup
```

再填写 ownership/state table：

```text
connected fd
per-client unread bytes
per-client pending replies
parsed command
shared KV store
active Connection owner map
pending close requests
```

## 17.2 Round2：和真实 Redis 对照

这不是用户第一次接触 Redis 概念。Day4 已经建立 KV state 与六条命令的第一层；这里负责把自己的实现放回真实 Redis 地图中，确认哪些思想相同、哪些能力没有实现。

只读一条主路径，不读完整源码：

```text
event loop
-> client readable
-> read query bytes
-> parse request
-> process command
-> append reply
-> writable flush
```

本周需要能准确说：

```text
我们的 Reactor 与 Redis ae event loop 有同类事件驱动思想，但不是 Redis 源码复刻
我们的 store 只有 unordered_map<string,string>
真实 Redis 支持多种 data types、encoding 与复杂 lifecycle
经典 command execution mental model 以 event loop 串行为核心
现代 Redis 还包含 I/O threads 与后台任务，不能粗暴说“Redis 完全单线程”
```

## 17.3 Round3：claim-to-evidence ledger

只保留能够支撑结论的代表证据：

| Claim | Evidence |
|---|---|
| encoder wire format 正确 | exact-byte unit tests |
| parser 支持 arbitrary fragmentation | all-split tests |
| parser 不吞下一帧 | coalesced/suffix tests |
| key/value binary-safe | embedded NUL round trip |
| command semantics 正确 | dispatcher/store matrix |
| 多 clients 共享 store | A SET / B GET process test |
| bad client 不杀 server | failure-isolation process test |
| lifetime 没有 covered memory bug | ASan/UBSan covered paths |
| build graph 完整 | fresh build + CTest |

代码、tests、口述和图已经证明的内容，不机械抄成二十道验收答案。

---

## 18. MySQL 放到正确的入口再学

用户当前只知道 MySQL 的大致用途，没有稳定的关系数据库模型。直接从 clustered index、covering index 和 `EXPLAIN` 开始，会把数据库入门写成术语清单。因此 Week12 不再要求 Day7 硬塞 30~60 分钟 MySQL 实验。

Day7 只建立一条连接：

```text
Mini Redis V1：key -> value 的内存 KV 模型
MySQL：table / row / column 构成的关系模型
```

Week13 开头再安排独立的 database foundation 小节，顺序固定为：

```text
1. table / row / column / schema / primary key
2. SELECT / WHERE 的最小语义
3. index 为什么存在
4. B+ tree 适合 page-oriented storage 与 range scan 的直觉
5. clustered / secondary / covering index 与回表
6. EXPLAIN 怎样展示 optimizer 选择的 execution plan
7. 同一小表上的三组 plan 对照
```

三组 plan 仍保留：

```text
unindexed predicate -> full table scan candidate
secondary-index predicate + 非覆盖列 -> index lookup + row lookup
secondary-index predicate + 只读取 index 中已有列 -> covering index candidate
```

观察字段仍只取：

```text
type
possible_keys
key
rows
Extra
```

`EXPLAIN` 展示 query execution plan，不等于严格 benchmark；很小的数据表也可能让 optimizer 合理选择 full scan。参考入口：[MySQL EXPLAIN](https://dev.mysql.com/doc/refman/8.4/en/explain.html) 与 [EXPLAIN output](https://dev.mysql.com/doc/refman/8.4/en/explain-output.html)。

Week13 的 database foundation 是伴随补缺，不是第二个数据库项目，也不要求实现 B+ tree。transaction、isolation、MVCC 与 lock 放在概念真正出现的后续阶段，不和 Week12 Mini Redis V1 抢注意力。

---

## 19. Canonical code 与目录决定

Ubuntu 当前真实工程：

```text
~/code/system-learning/cpp/week10/
├── include/reactor/
├── include/http/
├── src/
├── apps/
├── tests/
└── CMakeLists.txt
```

Week12 继续在这一份 canonical project 上新增 RESP/Mini Redis modules：

```text
~/code/system-learning/cpp/week10/
├── include/reactor/       # 不复制
├── include/http/          # 保留 HTTP regression targets
├── include/resp/          # 新增
├── include/mini_redis/    # 新增
├── src/                   # Reactor + HTTP + RESP + KV implementations
├── apps/
│   ├── reactor_echo_server.cpp
│   ├── http_server_v1.cpp
│   └── mini_redis_server.cpp
└── tests/
```

本周不因为目录还叫 `week10` 就搬家。原因：

```text
一份 canonical implementation 比漂亮目录名重要
中途 move 容易制造 include/CMake/script 噪音
当前学习增量应该集中在 RESP 与 KV
```

Week12 出口后可以决定是否一次性重命名为长期项目目录，例如 `mini_redis/`；这属于 housekeeping，不是 Week12 correctness gate，也不能复制出第二份 source tree。

---

## 20. Daily 生成与 R1 后定向润色规则

Week12 所有 daily 继续遵守系统主线规则：

```text
Part 1：前情提要与必要术语
Part 2：明确标出的教程主体
Part 3：证据、验收与收尾
```

每份初始 daily 完整生成 R1/R2/R3，但按闸门阅读：

```text
R1
-> 先明确程序用途、文件名、public contract、必要 API、错误 contract、最小 smoke
-> 用户独立设计并实现可运行 V1

R2
-> R1 正式通过后读取真实 source / note / tests / 对话
-> 按用户真实 representation 串清机制和责任边界

R3
-> 只加入真正增加区分力的 tests、tool evidence 与工程收口
```

R1 通过后的修改纪律：

```text
先看 git status / git diff
以用户当前磁盘版本为基线
保留用户阅读期间加入的解释、注释和问题答案
不能从提前稿或旧 commit 覆盖回来
把“如果你这样写”改成针对真实实现的明确升级动作
```

代码边界：

```text
用户的 production code 默认只读
未经用户明确授权，不修改任何用户代码文件
机械 GoogleTest/Python checker/CMake glue 可以在用户明确授权后补充
Codex 写的 scaffold 必须与用户亲自写的核心实现分开说明
```

---

## 21. 编译、测试与工具证据

### 21.1 Build

继续使用：

```text
C++17
-Wall -Wextra -g
CMake
CTest
```

固定 CTest 入口：

```bash
cmake -E chdir build ctest --output-on-failure
```

新增 targets 后至少做一次 fresh configure/build，不能让旧 object 冒充成功。

### 21.2 Unit tests

```text
RESP encoder exact bytes
RESP parser state / split / limits
command dispatcher/store semantics
```

### 21.3 Process-external integration

优先保留一个 raw Python checker，因为它能精确控制：

```text
fragmentation
coalescing
pipelining
embedded NUL
multiple simultaneous clients
malformed protocol
EOF / close
```

Python socket API 只做短注释，不扩成 Python 入门课。

如果 Ubuntu 已安装 `redis-cli`，再加一条 compatibility smoke：

```bash
redis-cli -p 6380 PING
redis-cli -p 6380 SET name FxorG
redis-cli -p 6380 GET name
```

`redis-cli` 能工作证明最小协议兼容；它不能替代 malformed/split/binary tests。

### 21.4 Sanitizer

```text
ASan/UBSan：必做代表路径
TSan：只有 Week12 新增 user threads 才进入默认矩阵
```

本周不新增 user threads，因此不要把 TSan 当成形式打卡。

---

## 22. 权威资料与源码对照

daily 必须先给自足中文讲解，再在对应位置用官方资料核验，不让用户先独自啃完整 specification。

本周入口：

- [Redis Serialization Protocol specification](https://redis.io/docs/latest/reference/protocol-spec/)
- [Redis command reference](https://redis.io/docs/latest/commands/)
- [SET](https://redis.io/docs/latest/commands/set/)
- [GET](https://redis.io/docs/latest/commands/get/)
- [DEL](https://redis.io/docs/latest/commands/del/)
- [EXISTS](https://redis.io/docs/latest/commands/exists/)
- [PING](https://redis.io/docs/latest/commands/ping/)
- [ECHO](https://redis.io/docs/latest/commands/echo/)
- [Redis `ae.c` event loop](https://github.com/redis/redis/blob/unstable/src/ae.c)
- [Redis `networking.c`](https://github.com/redis/redis/blob/unstable/src/networking.c)
- [Redis `iothread.c`](https://github.com/redis/redis/blob/unstable/src/iothread.c)
- [MySQL 8.4 EXPLAIN statement](https://dev.mysql.com/doc/refman/8.4/en/explain.html)
- [MySQL 8.4 EXPLAIN output](https://dev.mysql.com/doc/refman/8.4/en/explain-output.html)

源码阅读范围严格受限：

```text
只沿 event loop -> read client -> parse -> command -> reply 主路径
只确认现代 Redis 还存在 I/O threads / background work
不展开完整 Redis source
不把真实 Redis 内部结构硬塞进本周 V1
```

---

## 23. AI Theory 伴随线

真实进度：

```text
T1~T3 已正式通过
T4 是下一模块
ML 自学已到多变量线性回归
Ex1 尚未提交 executable evidence
```

旧时间表希望 Week12 到 T8，但当前真实进度已经落后。处理方式不是一周硬塞 T4~T8，而是公开记录并继续稳定推进：

```text
Week12 必达：正式学习并完成 T4
有余力：进入 T5
暂不假装：T6/T7/T8 已完成
```

投入保持：

```text
系统主线：每天 3 小时以上
AI Theory：每天 30~60 分钟
```

去重边界：

```text
ML.md 负责第一次学懂传统 ML 主线
经典 Ex1 负责真实数据 linear-regression evidence
T4 负责 computation graph / chain rule / finite-difference independent oracle
Ex1 与 T7 的同类 training loop 只实现一次
```

Mini Redis 的正确性不依赖 T4 完成，两条线分别验收；也不能因为 Mini Redis 忙就把理论线静默记成“以后再说”。

---

## 24. Week12 核心验收问题

不要求逐题手抄。代码、tests、图或口述已经证明的内容直接引用 evidence。

1. RESP 为什么能在 TCP byte stream 上表达 frame boundary？
2. Array 和 Bulk String 的 length 各自数什么？
3. 为什么 Bulk String 可以包含 `\0`、CR 和 LF？
4. `NeedMore`、protocol `Error`、command `Error` 为什么采用不同动作？
5. `Complete` 为什么必须返回 exact `consumed_bytes`？
6. 为什么 command name 可大小写不敏感，而 key/value 不能统一 lowercase？
7. 为什么 store 属于 server application，而不是 Connection？
8. 当前 `KvStore` 为什么不用 mutex？这能否证明它一般意义上 thread-safe？
9. 一个 callback 为什么可能连续产生多条 replies？
10. malformed client 为什么不能让 exception 终止整个 server？
11. protocol error 为什么通常 close-after-flush，而 wrong arity 可以继续连接？
12. client A 的 partial frame 为什么不会污染 client B？
13. 本项目和真实 Redis 在 event loop、data model、threading 上分别有哪些相同与不同？
14. database、cache、in-memory KV store 与 persistence 的边界分别是什么？

---

## 25. Week12 最终通过标准

### 25.1 核心通过

```text
RESP2 V1 request/reply contract 写清
encoder exact-byte tests 通过
parser 支持 top-level Array of Bulk Strings
NeedMore 不消费、不提交半成品
Complete 只消费当前 frame
arbitrary byte split 下结果正确
coalesced commands 的 suffix 不丢失
embedded NUL key/value round trip 正确
numeric/CRLF/marker/limit malformed cases 有稳定 Error
PING/ECHO/SET/GET/DEL/EXISTS semantics 正确
GET missing 返回 null bulk
wrong arity / unknown command 返回 error 且连接可继续
protocol error 在 reply flush 后关闭连接
多个 clients 共享同一 store
一个 bad client 不影响其他 clients
pipelined replies 保持 command order
transport / protocol / command / store ownership 分层清楚
fresh build 零 warning
CTest 全部通过
normal process-external scenarios 通过
ASan/UBSan covered paths 无 report
能口述本项目与真实 Redis 的准确边界
```

### 25.2 不阻塞 Week12

```text
没有 RESP3
没有 inline command protocol
没有 nested RESP arrays
没有 Redis 全部 commands
没有 Hash/List/Set/ZSet data types
没有 TTL/EXPIRE
没有 eviction
没有 AOF/RDB
没有 transaction/Lua/pub-sub
没有 replication/cluster
没有 authentication/TLS
没有 multi-thread command execution
没有 production benchmark
没有完整 README/interview 文档
MySQL foundation 与三组 EXPLAIN 已明确排到 Week13 开头
AI Theory 尚未追到 T8
```

### 25.3 真正不能通过

```text
把一次 recv 当成一条 RESP command
使用 strlen/查找 '\0' 决定 bulk boundary
NeedMore 时消费了当前 frame prefix
Complete 时吞掉下一条 command
length declaration 未做 overflow/limit 检查
command error 与 protocol framing error 混成同一种 close policy
每个 client 各有一份独立 store
所有 clients 共享同一个 input/parser mutable state
把 Redis fields 塞进通用 Connection
protocol exception 逃出 callback 并终止 server
send 后立即 erase Connection，丢掉 pending reply
只做一次 PING，没有 split/binary/multi-client evidence
```

---

## 26. 与 Week13 的连接

Week12 得到的是：

```text
一个 server-lifetime 的 string KV store
```

Week13 会给 value 增加时间维度：

```text
SET key value
-> value 存在

SET / EXPIRE
-> value 只在某个 deadline 前存在
```

下一周真正新增的问题是：

```text
谁拥有 expiration metadata？
GET 时怎样 lazy expiration？
周期清理是否需要 TimerQueue？
怎样注入 clock，避免 tests 长时间 sleep？
expiration 与 eviction 有什么区别？
```

所以 Week12 不提前偷偷实现 TTL。先让 protocol、command、store 与 multiple-client sharing 站稳，Week13 才能只增加 lifecycle，而不是同时修 framing。

Week13 开始 TTL 前还会先完成一个窄的 database foundation：只补 table/row/index/`EXPLAIN` 到可理解实验的程度，不展开完整 MySQL 课程。它与 TTL 分开成两个清晰小节，避免数据库术语和 expiration lifecycle 混成一团。

---

## 27. 本周一句话

```text
Connection 保存每个 client 的 transport bytes；
RESP parser 从 prefix 中证明一条 command；
dispatcher 执行 command semantics；
server-owned KV store 保存跨 client 共享的 state；
encoder 把结果变成 exact reply bytes；
protocol error 结束坏连接，但不能结束整个 server。
```
