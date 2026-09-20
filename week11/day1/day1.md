# Week11 Day1：从 TCP bytes 中增量识别 HTTP request line

> 日期：2026-09-16
>
> 主线：Reactor V1 -> HTTP request-line parser -> HTTP Server V1 -> Mini Redis
>
> 今日定位：先做纯内存 parser，不接 socket、不改 Reactor
>
> 今日主要产出：`http_request.hpp`、`http_request_parser.hpp/.cpp`、`http_request_parser_test.cpp`

---

# Part 1：前情提要与必要术语

## 1. 今天接在 Week10 的哪里

Week10 已经完成了 transport 层的 Reactor V1：

```text
kernel connected socket readable
-> EventLoop dispatch Channel
-> Connection recv loop 取得 bytes
-> bytes append 到 Connection 的 input Buffer
-> MessageCallback 检查并消费完整 application messages
```

当时为了证明 Connection 能处理 fragmentation 和 coalescing，application policy 使用了最简单的 newline framing：

```text
hello\n
```

现在要把 newline demo 升级为真实 application protocol。HTTP request 在 TCP 上仍然只是 bytes，例如：

```text
GET /hello HTTP/1.1\r\n
Host: 127.0.0.1:9091\r\n
\r\n
```

Reactor 不应该理解其中的 `GET`、`Host` 或 `HTTP/1.1`。本周新增的 HTTP parser/session 负责把 bytes 变成 structured request。

今天只解析第一行：

```text
GET /hello HTTP/1.1\r\n
```

完整层次先固定为：

```text
Connection input Buffer：拥有尚未处理的 bytes
HttpRequestParser：观察 bytes，判断 NeedMore / Complete / Error
HttpRequest：拥有已经解析出的 method / target / version
application：以后根据 HttpRequest 选择 response
```

今天不改 `Connection`，也不启动 server。先把最容易被网络时序掩盖的 parser 单独做对。

---

## 2. `HTTP`

`HTTP`：Hypertext Transfer Protocol，超文本传输协议。

今天把它理解为一种 application-layer request/response protocol：

```text
client 发送 request bytes
-> server 解析出 request semantics
-> server 发送 response bytes
```

HTTP 不负责可靠传输。可靠、有序 byte stream 由下层 TCP 提供；HTTP 负责规定这些 bytes 怎样组成 request line、headers、body 与 response。

它不是：

```text
TCP connection
socket API
浏览器页面
HTML
```

---

## 3. `request line`

`request line`：请求行。它是 HTTP request 的 start-line，也就是第一行。

本日处理的形状是：

```text
method SP request-target SP HTTP-version CRLF
```

例子：

```text
GET /hello HTTP/1.1\r\n
```

拆开后：

```text
method         = GET
request-target = /hello
HTTP-version   = HTTP/1.1
```

request line 只描述“想对哪个 target 做什么，以及使用哪个 HTTP version”。`Host`、`Content-Length` 和 body 都不属于今天这一行。

---

## 4. `method`

`method`：方法，表示 client 希望对 target 执行哪类操作。

常见值：

```text
GET   ：获取 representation
POST  ：把 request content 交给 target 处理
```

HTTP method 是 case-sensitive，也就是区分大小写：

```text
GET != get
```

Day1 parser 的职责是验证 method 是非空合法 token 并保存原始文本；它不在今天判断某个 method 是否已经被 server 实现。`PATCH` 可以是语法合法 method，即使 Week11 的 route 最终不支持它。

---

## 5. `request-target`

`request-target`：请求目标，标识这次 request 指向的资源。

HTTP 标准存在多种 target form；Week11 教学子集只接受最常见的 `origin-form` 形状：

```text
/
/hello
/search?q=cpp
```

当前只固定：

```text
target 非空
target 第一个 byte 是 '/'
target 内不允许 SP 或其他 request-line whitespace
query 暂时作为 raw text 保留
不做 percent-decoding
```

Day1 只验证这个 bounded teaching subset，不实现完整 URI parser；因此解析成功表示“满足本项目的 raw target contract”，不表示已经完成所有 URI 语义校验。

因此：

```text
GET /hello HTTP/1.1       -> 在 V1 范围内
GET http://a.test/x HTTP/1.1 -> 标准 HTTP 有这种形式，但不在本周教学子集内
```

这意味着 Week11 V1 是明确受限的 HTTP/1.1 teaching subset，不宣称完整实现所有 request-target forms。

---

## 6. `SP`、`CRLF` 与 `octet`

### 6.1 `SP`

`SP`：space，ASCII space byte，十六进制值是 `0x20`。

今天的严格 grammar 要求 method、target、version 之间各有一个 SP：

```text
GET /hello HTTP/1.1
   ^      ^
```

Tab 不是本日允许的 separator；连续两个 spaces 也按 malformed request line 处理。

### 6.2 `CRLF`

`CRLF` 由两个 bytes 组成：

```text
CR：Carriage Return，回车，'\r'，0x0D
LF：Line Feed，换行，'\n'，0x0A
```

request line 以连续的 `\r\n` 结束。它可能被 TCP 拆开：

```text
本轮 input suffix：...HTTP/1.1\r
下一轮新 bytes ：\nHost: ...
```

所以看到最后一个 `\r` 时不能立刻判错；当前结论应是 NeedMore。

RFC 9112 允许 recipient 为 robustness 接受 bare LF，但 Week11 V1 有意选择严格 CRLF，减少不同 parser 对同一 byte stream 产生不同解释的空间。这个选择必须写在 contract 里，而不是藏在实现中。

### 6.3 `octet`

`octet`：八位组，也就是 8-bit byte。HTTP/1.1 message parsing 首先面对的是 octet sequence，不是已经解码好的 Unicode text。

在当前 Linux/x86-64 和 C++ code 中，一段 HTTP 输入仍然用：

```text
const char* + std::size_t
```

表示 pointer 和明确 byte count，不能依赖 `strlen` 或尾部 `\0`。

---

## 7. `parser`

`parser`：解析器。

它把满足某种 grammar 的原始输入转换成 structured data：

```text
raw bytes
"GET /hello HTTP/1.1\r\n"
        |
        v
HttpRequest
method="GET", target="/hello", version="HTTP/1.1"
```

今天的 parser：

```text
不调用 recv
不拥有 fd
不等待 epoll
不生成 HTTP response
不拥有 caller 的 Buffer
```

它只根据 caller 当前提供的 byte range 给出判断。

---

## 8. `incremental parsing`

`incremental`：增量式的，表示输入可以分多次到达，parser 每次基于“目前已经拥有的 bytes”推进。

TCP 提供 ordered byte stream，但不保留 application message boundary。下面两种到达方式对 HTTP parser 必须等价：

```text
方式 A：一次得到
GET /hello HTTP/1.1\r\n

方式 B：分三次得到
GE
T /hello HTTP/1.1\r
\n
```

也可能一次得到超过一条 request line 的内容：

```text
GET /hello HTTP/1.1\r\nHost: x\r\n...
```

因此 parser 不能把“一次 `recv` 返回”当成“一条 request”。今天由现有 `Buffer` 保存跨 callback 的 bytes；parser 只识别最前面的一条 request line，并报告它消费到哪里。

---

## 9. `NeedMore`、`Complete` 与 `Error`

这是今天 parser 的三个 observable results。

### 9.1 `NeedMore`

`NeedMore`：当前 bytes 可能是合法 request line 的前缀，但还不足以完成判断。

例如：

```text
GET /hello HTTP/1.1\r
```

它还差一个 `\n`。

### 9.2 `Complete`

`Complete`：已经识别出一条完整合法 request line，并产生 structured fields。

例如当前 Buffer 是：

```text
GET /hello HTTP/1.1\r\nHost: x\r\n
```

parser 只完成 request line，返回本次 consumed bytes；`Host: x\r\n` 仍然属于 suffix，不能一起丢掉。

### 9.3 `Error`

`Error`：当前输入已经违反本日 grammar，继续追加 bytes 也不能把这条 request line 修成合法结果。

例如：

```text
GET  /hello HTTP/1.1\r\n
GET /hello HTTP/1.0\r\n
GET /hello HTTP/1.1\n
```

协议输入错误通过 result 返回，不使用 C++ exception 表示；exception 留给 caller misuse、allocation failure 等 C++ execution failure。

---

# Part 2：教程主体

# 教程开始：一次 recv 不是一条 HTTP request

## 10. 先看今天到底要造什么

### 10.1 功能说明

今天构建一个普通 C++ component：

```text
名称：HttpRequestParser V1
功能：从 caller 当前拥有的 byte range 最前面识别一条 HTTP/1.1 request line
输入：pointer + length
输出一：NeedMore，当前还缺 bytes
输出二：Complete，得到 method / target / version，并报告 consumed bytes
输出三：Error，报告明确的 protocol error kind
```

它解决的具体问题是：

> Connection 的 input Buffer 可能只保存半行，也可能保存完整行加后续 headers。parser 必须准确告诉 caller“现在能不能形成 request line”和“若形成了，最前面多少 bytes 已经属于它”。

它不直接消费 Buffer，是为了让 parsing decision 和 byte ownership 分开：

```text
parser 只观察并报告 consumed_bytes
-> caller 确认 Complete
-> caller 再调用 Buffer::retrieve(consumed_bytes)
```

### 10.2 今天完成后怎样使用

下面只展示 public APIs 怎样配合，不展示 parser 内部算法：

```cpp
Buffer input;
input.append(bytes, byte_count);

HttpRequest request;
HttpRequestParser parser;

const RequestLineParseResult result =
    parser.parse_request_line(input.peek(), input.readable_bytes(), request);

if (result.status == ParseStatus::Complete) {
    input.retrieve(result.consumed_bytes);
    // request.method / target / version 现在可用；Buffer 中的 suffix 被保留。
}
```

三个状态对应 caller 的动作：

```text
NeedMore  -> 不 retrieve，等待更多 bytes append 到同一 Buffer
Complete  -> retrieve(consumed_bytes)，继续处理当前 request 的 headers
Error     -> 不再把当前 prefix 当作合法 request；以后由 HTTP session 生成 error response 并关闭
```

Day1 还没有 HTTP session，因此 test 只核对 parser result，不生成 `400` 或 `505` response。

---

# Round 1：只根据外部 contract 独立实现 V1

## 11. Round1 文件位置与职责

继续维护 Week10 的 canonical project：

```text
~/code/system-learning/cpp/week10/
├── include/
│   ├── reactor/
│   │   └── buffer.hpp
│   └── http/
│       ├── http_request.hpp
│       └── http_request_parser.hpp
├── src/
│   └── http_request_parser.cpp
└── tests/
    └── http_request_parser_test.cpp
```

文件职责：

```text
http_request.hpp
-> structured request data 与 parse result types

http_request_parser.hpp
-> parser public declaration

http_request_parser.cpp
-> request-line parsing implementation

http_request_parser_test.cpp
-> 只通过 public interface 验证 observable behavior
```

今天不把 HTTP fields 加进 `Connection`，也不新建 socket server。

---

## 12. Round1 public types

以这一组名字和行为为准；private representation 由你决定。

```cpp
#pragma once

#include <cstddef>
#include <string>

struct HttpRequest {
    std::string method;
    std::string target;
    std::string version;
};

enum class ParseStatus {
    NeedMore,
    Complete,
    Error
};

enum class RequestLineError {
    None,
    MalformedRequestLine,
    UnsupportedHttpVersion,
    RequestLineTooLong
};

struct RequestLineParseResult {
    ParseStatus status;
    std::size_t consumed_bytes;
    RequestLineError error;
};

const char* request_line_error_message(RequestLineError error) noexcept;
```

`request_line_error_message` 是 diagnostics helper，不参与 parser control flow。程序判断错误类型应比较 enum，不应匹配 message string。

参考英文 message：

| error | message |
|---|---|
| `None` | `no request-line error` |
| `MalformedRequestLine` | `malformed request line` |
| `UnsupportedHttpVersion` | `unsupported HTTP version` |
| `RequestLineTooLong` | `request line too long` |

---

### 12.1 enum class

这个是 C++ 的“枚举类型”，用来限制一个变量只能取几种预先定义好的状态。

```cpp
enum class RequestLineError {
    None,
    MalformedRequestLine,
    UnsupportedHttpVersion,
    RequestLineTooLong
};
```

它定义了一个新类型，名字叫 `RequestLineError`。这个类型的变量只能表示这四种 request-line 解析结果：

```cpp
RequestLineError error = RequestLineError::None;
```

含义是“当前没有错误”。

```cpp
error = RequestLineError::MalformedRequestLine;
```

含义是“请求行格式错误”。

这里的 `None` 不等于指针的 `nullptr`，只是这个错误类型里的一个普通状态，表示“无错误”。

在 HTTP parser 中，它很适合表达这种情况：

```cpp
if (error == RequestLineError::None) {
    // request line 目前合法
} else {
    // 根据具体错误决定返回 400、505，或关闭连接
}
```

为什么不用 `bool`？

```cpp
bool ok;
```

只能表达“成功 / 失败”，但失败后不知道具体为什么失败。这个 enum 可以保留原因：

```text
MalformedRequestLine      -> 格式错误
UnsupportedHttpVersion    -> 版本不支持
RequestLineTooLong        -> 行过长
```

`enum class` 里的 `class` 容易让人误会：它不是你之前学的那种带成员函数、构造函数的普通 class。这里它主要表示“作用域枚举、类型更安全”。

所以必须这样写：

```cpp
RequestLineError::None
```

不能只写：

```cpp
None
```

它还不会偷偷和整数混用：

```cpp
RequestLineError error = 1;  // 不允许
```

这正适合 parser：错误状态是有限集合，写错状态名、把整数误当错误码，编译器都更容易帮你拦住。

---

## 13. `HttpRequestParser` public contract

```cpp
#pragma once

#include "http_request.hpp"

class HttpRequestParser {
public:
    static constexpr std::size_t kMaxRequestLineBytes = 8192;

    RequestLineParseResult parse_request_line(
        const char* data,
        std::size_t length,
        HttpRequest& output) const;
};
```

### 13.1 这个 method 替 caller 完成什么

`parse_request_line` 检查 `data` 开始的 `length` 个 bytes，尝试从 offset 0 识别一条 request line。

它不会在 byte range 中跳过垃圾去寻找后面的合法行。当前最前面的 request line 要么 NeedMore、Complete，要么 Error。

### 13.2 谁在什么场景调用

今天由 unit test 直接调用。Week11 Day5 接入 Reactor 后，会由每条 connection 的 HTTP session 在 input Buffer 增长后调用。

它操作的是 caller 提供的只读 byte range，不拥有该 memory，也不保存 `data` pointer 供未来使用。

### 13.3 正常返回语义

#### `NeedMore`

```text
status         = NeedMore
consumed_bytes = 0
error          = None
output         = 调用前状态，不修改
```

#### `Complete`

```text
status         = Complete
consumed_bytes = 从 data[0] 到终止 CRLF 之后的 byte 数
error          = None
output         = 新的 method / target / version
```

`consumed_bytes` 包含最后的 `\r\n`。byte range 中它之后的 suffix 不解析、不修改。

#### `Error`

```text
status         = Error
consumed_bytes = 0
error          = 对应的非 None enum
output         = 调用前状态，不修改
```

今天 Error 时不尝试 recovery。Day5 接入 HTTP session 后，会根据 error kind 形成 response/close policy。

### 13.4 request-line grammar contract

R1 接受：

```text
method SP origin-form-shaped-target SP HTTP/1.1 CRLF
```

具体约束：

```text
method：非空 HTTP token，保留大小写
separator：恰好一个 ASCII SP
target：非空，首 byte 必须是 '/'
version：语法上只接受大小写精确的 HTTP/1.1
terminator：严格要求 CRLF
request-line content limit：CRLF 之前最多 8192 bytes
```

为了让 R1 能独立实现，V1 把合法 byte 集合继续写死：

```text
method token byte：
A-Z a-z 0-9 以及 ! # $ % & ' * + - . ^ _ ` | ~

target byte：
首 byte 是 '/'
其余每个 byte 必须是 visible ASCII，也就是 0x21 到 0x7E，并且不能是 '#'
```

因此 target 中不接受 SP、tab、control byte、fragment marker `#` 或未编码的 non-ASCII bytes；`?`、`=`、`&` 等 visible ASCII 可以原样保留。更完整的 URI validation 与 percent-decoding 不在本周范围。

这里的 `8192` 只计算 CRLF 之前的 bytes；终止 `\r\n` 不计入该 limit。HTTP 标准本身没有固定 request-line limit，并建议至少支持 8000 octets；`8192` 是本项目为 bounded memory behavior 选择的 V1 上限。

本日拒绝：

```text
empty method
method 中存在非 token byte
多余或缺少 SP
用 tab 代替 SP
empty target
target 不以 '/' 开始
target 中出现 whitespace
HTTP/1.0 或其他 syntactically recognizable version
错误大小写，例如 http/1.1
bare LF 或 bare CR
超过 limit
```

版本错误分类：

```text
形状是 HTTP/digit.digit，但不是 HTTP/1.1
-> UnsupportedHttpVersion

根本不是合法 HTTP-version 形状
-> MalformedRequestLine
```

### 13.5 pointer、length 与 exception contract

```text
length == 0：data 可以是 nullptr，返回 NeedMore
length > 0 且 data == nullptr：抛 std::invalid_argument
协议格式错误：不抛 exception，通过 Error result 返回
std::string allocation/storage failure：传播真实 standard exception
parser 不调用 Linux syscall，因此不产生 errno/system_error
```

`parse_request_line` 对 caller memory 只读。返回后不保留 pointer/reference/view 指向 caller bytes。

---

## 14. Round1 最小 observable scenarios

R1 不要求把 RFC 的所有边界一次写完，但下面五组必须是 executable oracle。

### Scenario A：完整 request line

输入：

```text
GET /hello HTTP/1.1\r\n
```

必须得到：

```text
Complete
method == "GET"
target == "/hello"
version == "HTTP/1.1"
consumed_bytes == 输入总 byte 数
```

### Scenario B：partial input

分两步观察同一个累计 Buffer：

```text
第一步：GET /hello HTTP/1.1\r
-> NeedMore，consumed=0，output 不变

第二步：再 append \n
-> Complete
```

注意：第二次 parse 的输入是 Buffer 中累计的完整 readable range，不是只把新来的一个 `\n` 交给 stateless parser。

### Scenario C：完整行后存在 suffix

输入：

```text
GET /hello HTTP/1.1\r\nHost: x\r\n
```

必须得到 Complete，且：

```text
consumed_bytes 只覆盖 request line
caller retrieve(consumed_bytes) 后，Buffer readable content exact 等于 "Host: x\r\n"
```

### Scenario D：malformed line

至少选择两项：

```text
GET  /hello HTTP/1.1\r\n
GET /hello HTTP/1.1\n
```

必须返回 `Error + MalformedRequestLine`，不能误判 Complete，也不能越界。

### Scenario E：unsupported version

输入：

```text
GET /hello HTTP/1.0\r\n
```

必须返回：

```text
Error
UnsupportedHttpVersion
consumed_bytes == 0
output 不变
```

---

## 15. 一个很小的 smoke test 形状

你可以先只写一个 test，快速确认 component 的基本调用关系，然后再补上面的 cases：

```cpp
TEST(HttpRequestParserTest, ParsesCompleteRequestLineAndKeepsSuffix) {
    // Arrange：准备累计 input bytes 与 parser。
    // Act：parse 最前面的 request line；Complete 后由 caller retrieve consumed bytes。
    // Assert：structured fields 正确，Buffer 中只剩 exact suffix。
}
```

这里只给 test 的意图，不给 implementation。你现有项目已经能用 GoogleTest，不需要重新手写 testing framework。

---

## 16. Round1 CMake target

在现有 `CMakeLists.txt` 末尾增加独立 target。build glue 不是今天的设计墙，可以直接参考：

```cmake
# HTTP request-line parser
add_library(http_request_parser
    src/http_request_parser.cpp
)

target_include_directories(http_request_parser PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include/http
)

target_compile_options(http_request_parser PRIVATE
    -Wall
    -Wextra
    -g
)

add_executable(http_request_parser_test
    tests/http_request_parser_test.cpp
)

target_include_directories(http_request_parser_test PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include/http
    ${CMAKE_CURRENT_SOURCE_DIR}/include/reactor
)

target_compile_options(http_request_parser_test PRIVATE
    -Wall
    -Wextra
    -g
)

target_link_libraries(http_request_parser_test PRIVATE
    http_request_parser
    buffer
    GTest::gtest_main
    GTest::gtest
)

gtest_discover_tests(http_request_parser_test)
```

重新 configure、build、运行：

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build -j
cmake -E chdir build ctest --output-on-failure
```

若只运行今天的 tests：

```bash
cmake -E chdir build ctest -R HttpRequestParser --output-on-failure
```

`gtest_discover_tests` 默认使用 suite/test name 注册测试；`-R` 是 regular-expression filter，因此实际匹配名称以 `cmake -E chdir build ctest -N` 输出为准。

---

## 17. Round1 成功标准

```text
四个新文件职责分开
没有修改 Reactor/Connection/Buffer behavior
public types 与 error contract 明确
五组 R1 scenarios 有 executable evidence
NeedMore 不消费 bytes、不修改 output
Complete 只报告 request-line consumed bytes
Error 不用 exception 表示普通 protocol failure
Debug build 零 warning
今天新增 tests 全部 PASS
```

R1 不要求：

```text
headers / Host
Content-Length / body
socket / curl
HTTP response
keep-alive
完整 RFC compatibility
benchmark
README
```

---

## 18. Round1 阅读闸门

```text
现在停止阅读。

先独立完成：
http_request.hpp
http_request_parser.hpp
http_request_parser.cpp
http_request_parser_test.cpp

提交 R1 检阅时给出：
1. 当前 source
2. 新增 tests 的运行结果
3. 你怎样区分 NeedMore、Complete、Error

R1 正式通过后，我会先读取你当时真实代码、note 与 day1.md 修改，
再按你的 representation 定向润色后面的 Round2 / Round3。
```

下面内容不是 R1 的实现提示。先让你的第一版真实落地，再回来对照。

---

# Round 2：沿你的 R1 实现复盘 request line

下面每一节都以你当前的 `parse_request_line / check_complete / check_needmore` 为基线。通用 HTTP 规则只保留到解释真实代码所需的程度；出现“当前实现”时，指的是本次 R1 验收过的 Ubuntu source，而不是教程预设版本。

## 19. HTTP message 的第一层结构

RFC 9112 给出的 HTTP/1.1 message 外形可以压缩成：

```text
start-line CRLF
zero or more field-lines CRLF
CRLF
optional message-body
```

request 的 start-line 就是 request line：

```text
request-line = method SP request-target SP HTTP-version
```

把 wire bytes 画开：

```text
GET /hello HTTP/1.1\r\nHost: x\r\n\r\n
| | |      |        |    |
| | |      |        |    +-- headers 后的 empty line
| | |      |        +------- 第一条 header field
| | |      +---------------- version
| | +----------------------- target
| +------------------------- SP separators
+--------------------------- method
```

语法定义里 `CRLF` 位于 request-line 之后；今天的 `consumed_bytes` 为了 caller 使用方便，把终止 `\r\n` 一起算入已识别 prefix。

官方核验：

- [RFC 9112 Section 2：Message](https://www.rfc-editor.org/rfc/rfc9112.html#section-2)
- [RFC 9112 Section 3：Request Line](https://www.rfc-editor.org/rfc/rfc9112.html#section-3)

正文已经包含今天需要的规则；链接用于查证，不要求从头通读 RFC。

映射到你的 R1：`HttpRequest` 目前恰好只拥有 `method / target / version`，`check_complete` 也只解析第一行。它没有保存 `Host`、其他 field-lines 或 body，这与 Day1 边界一致；不要因为已经能在 suffix 中看见 `Host: x` 就提前把 header parsing 塞进这三个字段。

---

## 20. 为什么 parser 看累计 Buffer，而不是本次 recv

考虑 client 连续发送：

```text
GET /hello HTTP/1.1\r\nHost: x\r\n\r\n
```

TCP 可以让 server 观察到：

```text
recv #1 -> "GET /he"
recv #2 -> "llo HTTP/1.1\r"
recv #3 -> "\nHost: x\r\n\r\n"
```

也可能：

```text
recv #1 -> 整个 request
```

甚至：

```text
recv #1 -> 当前 request + 下一条 request 的一部分
```

所以正确对象关系是：

```text
recv 只负责取得当前可用 bytes
        |
        v
Buffer 累积尚未消费的 bytes
        |
        v
parser 从 readable prefix 判断协议进度
```

一次 `recv` 的返回长度是 transport observation，不是 HTTP framing evidence。

你的 parser 本身是 stateless 的：每次只接收 `data + length + output`，不保存上一次 scan position。真正跨 callback 保存 bytes 的是 `Buffer`。R1 的 partial test 已经按这个关系运行：先把结尾为 `\r` 的 prefix append 到同一个 Buffer，第一次 parse 返回 NeedMore；再 append `\n`，第二次把完整 readable range 重新交给 parser。不是只把新到的一个 `\n` 传给 `check_needmore`。

---

## 21. 三种结果不是三个随意的返回值

它们代表 parser 对当前 prefix 能作出的三类证明。

### 21.1 NeedMore：证据不足

```text
GET /hello HTTP/1.1\r
```

当前还不能证明完整，也不能证明 malformed。caller 必须保留全部 bytes；如果提前 retrieve，下一次只剩 `\n`，上下文就丢了。

在你的实现中，这条路径是：

```text
parse_request_line 没有得到 Complete
-> check_needmore 统计 CR / LF / SP
-> 根据当前位于 method、target 还是 version prefix 做验证
-> 能证明“仍可能补成合法 request line”时返回 NeedMore
```

你把 `output` 从 `check_needmore` 的参数中删掉了，因此这一分支在结构上就没有机会修改 caller output；R1 sentinel test 已验证这一点。

但当前 `space_count == 1` 分支还存在具体偏移错误：`GET /hel` 本应 NeedMore，却被判为 Malformed。原因不是三态模型错误，而是交给 `check_target` 的 range 从 separator 开始了。R2 要修的是这个 range，不是推翻 `check_needmore` 的整体结构。

### 21.2 Complete：边界已被证明

```text
GET /hello HTTP/1.1\r\nHost: x\r\n
```

`\r\n` 给出了 request-line boundary。parser 同时证明三个 fields 满足本日 contract，caller 才能消费到该 boundary。

你的 `parse_request_line` 没有要求 CRLF 位于整个 Buffer 末尾，而是先找到第一组相邻的 `\r\n`，再调用：

```text
check_complete(data, first_lf_pos + 1, output)
```

因此 `check_complete` 看到的 `length` 已经只是第一条 request line 的 prefix 长度。它检查两个 SP、method、target、version 与 line limit，先构造局部 `HttpRequest result`，最后才 `output = std::move(result)`。这一点正是 suffix test 能通过的原因。

### 21.3 Error：继续等待也无济于事

```text
GET  /hello HTTP/1.1\r\n
```

完整 terminator 已经出现，而 line 中有两个相邻 SP。继续 append headers 不会改变已经结束的 request line，因此应是 Error，不是 NeedMore。

在你的实现里，Error 有两条实际路径：

```text
check_version 识别出 HTTP/digit.digit，但不是 HTTP/1.1
-> 直接返回 UnsupportedHttpVersion

check_complete / check_needmore 都无法证明当前 prefix 仍可能合法
-> parse_request_line 最后返回 MalformedRequestLine
```

R1 tests 已分别用 `HTTP/1.0` 和“双 SP / bare LF”覆盖这两条路径。`RequestLineTooLong` 目前只在已有完整 CRLF 的 `check_complete` 中生效；没有 terminator 的超长 prefix 仍是待修边界。

压缩成一句：

```text
NeedMore 是“你的 helper 还能证明它是合法前缀”；Error 是“当前 bytes 已不可能补成合法 request line”。
```

---

## 22. `consumed_bytes` 把 parser 与 Buffer 接起来

当前 input：

```text
GET /hello HTTP/1.1\r\nHost: x\r\n
```

你的 `parse_request_line` 找到第一组 CRLF 后，让 `check_complete` 只观察这一段，因此返回：

```text
Complete
consumed_bytes = 19 + 2
```

其中 request-line content `GET /hello HTTP/1.1` 是 19 bytes，CRLF 是 2 bytes。

caller 再执行：

```cpp
input.retrieve(result.consumed_bytes);
```

得到：

```text
Host: x\r\n
```

这里的责任边界是：

```text
parser：证明 prefix 的 protocol meaning 和长度
Buffer：拥有 bytes，并执行 logical consume
caller/session：决定 Complete 后何时 retrieve
```

这正是 R1 的 `ReportsOnlyRequestLineBytesAndPreservesSuffix` test 做的事：它把整段 `wire_bytes` 放进现有 `Buffer`，parser 返回 `request_line.size()`，test 再调用 `input.retrieve(result.consumed_bytes)`，最后 exact 比较剩余内容是否为 `Host: x\r\n`。

你的 parser 当前没有成员变量，也不保存 `peek()` pointer；所有 helper 都只在一次调用期间使用 `data + length`。这个 ownership 边界是正确的。将来即使为了减少重复扫描而保存 progress，也只能保存 offset/state，不能保存可能被 Buffer compact/grow 使其失效的旧 pointer。

---

## 23. method token 为什么不能只检查 A 到 Z

HTTP method grammar 使用 `token`。标准方法通常是 `GET`、`POST`，但 token 还允许 digits 和一组 punctuation。

因此：

```text
“当前 route 只实现 GET/POST”
!=
“parser 只允许 GET/POST 通过语法解析”
```

更清楚的分层是：

```text
parser：这是一个语法合法的 method token
route policy：这个 server 是否实现该 method
```

Day4 才会把 unsupported method 映射为 `501 Not Implemented`。Day1 不要提前把 syntax 和 server capability 混在一起。

你的 `check_in_method_token_byte_helper` 已经按 contract 接受字母、数字和规定的 punctuation bytes，没有把 parser 写成只认识 GET/POST 的 route checker；这一点做对了。Round3 只需补一个非 GET/POST 的合法 token case，例如 `PATCH`，证明这条分层，而不是重写 helper。

---

## 24. strict parsing 是本项目的明确选择

RFC 9112 的 request-line grammar 使用单个 SP，但也允许 recipient 为兼容性采取较宽松的 whitespace parsing。标准同时提醒，不同 recipient 的宽松规则不一致会造成 request smuggling 风险。

Week11 V1 选择：

```text
只接受精确 SP
只接受精确 CRLF
不自动修正 malformed target
```

这不是在声称“所有 HTTP server 都必须和我们一样严格”，而是在固定本项目只有一种解释。

协议 parser 最危险的状态之一是：

```text
前置 parser 认为 bytes 属于 request A
后置 parser 却认为同一 bytes 属于 request B
```

本周只建立第一层意识，不展开 proxy/request-smuggling 攻防。

你的严格策略已经落在具体代码上：`check_complete` 要求恰好两个 SP；`check_needmore` 拒绝多余 SP；`parse_request_line` 只把相邻 `\r\n` 当 terminator；target helper 拒绝 whitespace、control byte、`#` 和 non-ASCII。R2 不需要改成宽松 parser，只需用边界 matrix 证明这些实际分支。

---

## 25. request-line limit 为什么必须在找不到 terminator 时也工作

malicious 或 broken peer 可以一直发送：

```text
GET /aaaaaaaaaaaaaaaaaaaaaaaa...
```

但永远不发送 `\r\n`。如果 parser 永远返回 NeedMore，input Buffer 会持续增长。

所以 parser 的判断必须同时考虑：

```text
是否已经找到 CRLF
当前未终止 line 已经有多长
```

本项目的 `kMaxRequestLineBytes` 约束的是 CRLF 前的 content bytes：

```text
content length <= 8192 -> 仍可能合法
content length > 8192  -> RequestLineTooLong
```

如果完整 CRLF 已经出现，也要检查它前面的 content length；不能先构造超长 strings 再事后决定拒绝。

当前实现只完成了一半：`check_complete` 使用 `bytes = length - 2` 检查完整行，所以“已有 CRLF 的超长 line”会得到 `RequestLineTooLong`；但没有 CRLF 时，`parse_request_line` 会继续进入 `check_needmore`，那里没有统一的长度 guard。独立 probe 用 8193 个合法 method token bytes 得到 `NeedMore`。R2 应先修这个真实缺口，再写 8192/8193 两侧的 exact tests。

---

## 26. R1 后复盘你的实际实现

你的 R1 已经形成一版真实 parser，而不是教程预设的 skeleton：

```text
parse_request_line
-> 用 find_char_position 找第一组相邻 CRLF
-> 若找到，只把 [0, first_lf + 1) 交给 check_complete
-> 若尚未 Complete，再由 check_needmore 判断当前 prefix
-> 两者都不能证明合法时，返回 MalformedRequestLine
```

`check_complete` 再用两个 SP 划分 method、target 与 version，分别调用 helper 验证；只有全部验证成功后，才先构造局部 `HttpRequest result`，最后一次性移动给 `output`。因此 R1 的 sentinel tests 能证明 NeedMore/Error 不会留下半更新 output。

当前实现会多次线性扫描同一段 bytes，例如分别统计 SP、CR、LF，再寻找 separator position。由于 request-line 被限制在 8 KiB，这个复杂度目前可以接受；R2 不要求为了减少几次扫描引入持久 parser state，也不要保存指向 Buffer 内部的 pointer。

### 26.1 R2 必须修正的三个真实边界

这三项来自当前 source 和独立 probe，不是假设分支：

1. **一个 SP 后的 target prefix 被误判为 Error。** 当前 `check_needmore` 的 `space_count == 1` 分支把 separator 本身交给了 `check_target`。例如 `GET /hel` 当前得到 `MalformedRequestLine`，但它是合法 request line 的 incomplete prefix，应返回 NeedMore。修正时要明确第二段从 `first_space_pos + 1` 开始，并用这个位置判断 target 是否仍为空。
2. **没有 terminator 时，长度上限尚未生效。** 由 8193 个合法 method token bytes 组成的未终止 prefix 当前仍返回 NeedMore。R2 要在返回 NeedMore 前执行统一的 content-length guard：一旦 CRLF 前的 bytes 已经大于 `kMaxRequestLineBytes`，返回 `RequestLineTooLong`，不能继续让 Buffer 增长。
3. **diagnostics helper 只有 declaration。** `request_line_error_message` 已写进 public contract，但当前 object/library 中没有 definition。R2 要补齐四个 enum 到固定英文 message 的映射；control flow 仍比较 enum，不比较字符串。

顺手做一次窄清理：source 直接 include 自己实际使用的 `<cctype>`、`<stdexcept>`、`<utility>`，移除未使用的 `<iostream>` / `<system_error>`；把全局 `NEEDMORE` macro 收回普通 C++ helper 或直接返回表达式。清理不改变 parser 行为，也不要求重写现有 helper 结构。

---

# Part 3：收尾、Round3 与验收

## 27. Round3：把“任意 TCP 分片”变成可执行证据

R1 的 partial case 只试了一个 split point。Round3 的核心升级是：对同一条合法 request line，枚举每个 byte boundary。

这不是泛泛加覆盖率。它会直接经过你当前 `check_needmore` 的三组分支：

```text
split 在第一个 SP 前   -> method prefix
split 在两个 SP 之间   -> target prefix
split 在第二个 SP 后   -> version prefix / trailing CR
```

其中 target prefix 已被独立 probe 证明有 off-by-one range bug，所以这条 split-point test 是修复后的回归证据，不是重复体力活。

原始 bytes：

```text
GET /hello HTTP/1.1\r\n
```

对每个 `split`：

```text
prefix = bytes[0, split)
suffix = bytes[split, end)
```

验证：

```text
只 append prefix 后 parse
-> 若 prefix 尚未包含完整 CRLF，必须 NeedMore

再 append suffix 后 parse
-> 必须 Complete
-> fields 与 consumed_bytes 每次相同
```

这条 parameterized test 不是机械堆 case。它直接验证今天最核心的 claim：

> parser behavior 不依赖 TCP 在哪个 byte boundary 把数据交给 application。

机械性的 GoogleTest parameter scaffold 可以让我协助补，但你必须能解释 split input、累计 Buffer 和 oracle 三者的关系。

---

## 28. Round3 边界矩阵

在 split-point test 之外，只补能区分 contract 的 cases：

| 输入类别 | expected result | 你的 R1 当前状态 |
|---|---|---|
| empty range | NeedMore | source 已有分支，补 executable evidence |
| only `\r` at end | NeedMore | R1 partial test 已覆盖 |
| target prefix `GET /hel` | NeedMore | 已证实错误返回 Malformed，R2 修复 |
| bare LF | MalformedRequestLine | R1 test 已覆盖 |
| bare CR 后已有非 LF byte | MalformedRequestLine | 尚未覆盖 |
| missing SP | MalformedRequestLine | 尚未覆盖 |
| extra SP / tab separator | MalformedRequestLine | 双 SP 已覆盖，tab 尚未覆盖 |
| empty target | MalformedRequestLine | 尚未覆盖 |
| target 不以 `/` 开始 | MalformedRequestLine | 尚未覆盖 |
| `HTTP/1.0` | UnsupportedHttpVersion | R1 test 已覆盖 |
| `http/1.1` | MalformedRequestLine | 尚未覆盖 |
| content 恰好 8192 bytes 再接 CRLF | 不因长度被拒；仍按 fields 判断 | 尚未覆盖 |
| 无 CRLF 且 content 8193 bytes | RequestLineTooLong | 已证实错误返回 NeedMore，R2 修复 |
| complete line + arbitrary suffix | Complete，只消费第一行 | R1 test 已覆盖 |
| positive length + null data | 抛 `std::invalid_argument` | source 已有分支，补 executable evidence |

不用为每一行手写独立 boilerplate。可以使用 table-driven 或 parameterized test，但 expected status/error/consumed 必须 exact。

---

## 29. output unchanged 要怎样证明

不要用默认空 `HttpRequest` 验证“Error 后 output 没变”，因为实现若错误地 clear fields，测试仍可能通过。

先放入 sentinel：

```text
method  = "sentinel-method"
target  = "sentinel-target"
version = "sentinel-version"
```

再触发 NeedMore 或 Error，最后核对三个 fields 仍然 exact 相等。

你的 R1 已经使用了明确的 commit discipline：

```text
先在 temporary values 中完成识别和验证
-> 全部成功
-> 再更新 caller output
```

具体来说，`check_complete` 先构造局部 `HttpRequest result`，三个 fields 全部完成后才移动给 `output`；`check_needmore` 根本不接收 output。现有 sentinel tests 已验证 partial、malformed 和 unsupported version。Round3 不需要换 representation，只需让新增 table cases 继续复用同一个 sentinel helper。

---

## 30. sanitizer 与本日 evidence 边界

你的 parser 对 peer-controlled byte range 做了多次 pointer offset 与长度减法，例如 `first_space_pos + 1`、`second_space_pos - first_space_pos - 1`、`length - 2`。这些正是 ASan/UBSan 值得复检的真实位置，而不是因为“parser 一般很危险”就机械跑 sanitizer。

在独立 build directory：

```bash
cmake -S . -B build-asan \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_FLAGS="-fsanitize=address,undefined -fno-omit-frame-pointer"

cmake --build build-asan -j
cmake -E chdir build-asan ctest -R HttpRequestParser --output-on-failure
```

本日证据能支持：

```text
selected grammar cases 的结果正确
所有 byte split points 的行为一致
covered paths 没有被 ASan/UBSan 报告 memory/undefined-behavior 问题
```

它不能支持：

```text
完整 RFC 9112 compliance
所有恶意输入都已覆盖
HTTP server 已能处理真实 client
```

socket、curl 与 server integration 从 Day5 开始。

---

## 31. 今日验收问题

这些问题优先用于定位理解缺口，不要求在代码已经给出同等证据时机械抄长答案。

1. 你的 `parse_request_line` 为什么把 `first_lf_pos + 1` 作为 `check_complete` 的 length，而不是直接传整个 Buffer length？
2. `GET /hel` 为什么应该进入 NeedMore？当前 one-space branch 的 range 从哪里偏了一位？
3. 为什么 `check_complete` 的局部 `HttpRequest result` 能保证 Error 后 sentinel output 不变？
4. 你的 `check_version` 为什么把 `HTTP/1.0` 分类为 Unsupported，而把 `http/1.1` 分类为 Malformed？
5. 为什么 complete-line limit check 不能替代 no-terminator path 的 length guard？
6. 你的实现多次扫描累计 prefix；为什么在 8 KiB contract 下暂时接受它，而不立即保存 Buffer pointer？

---

## 32. 今日完成标准

### 必须完成

```text
R1 四个文件
五组最小 observable scenarios
Debug build 零 warning
新增 tests PASS
能够口述 NeedMore / Complete / Error
```

### R1 通过后完成

```text
修正 one-space target-prefix range
让无 CRLF 的超长 prefix 返回 RequestLineTooLong
定义 request_line_error_message，并清理 direct includes / NEEDMORE macro
所有 byte split points test
按第 28 节“当前状态”列补 limit 与 malformed boundary evidence
ASan/UBSan 跑过 parser tests
```

### 今天明确不做

```text
headers
Host
Content-Length / body
HTTP response
Reactor integration
keep-alive
benchmark
完整 RFC parser
```

---

## 33. 今日压缩记忆

```text
TCP 给 HTTP 的是 ordered byte stream，不是 request records。

你的 Buffer test 负责累计 bytes；
parse_request_line 找第一组 CRLF，并只把该 prefix 交给 check_complete；
check_needmore 证明合法 prefix，check_complete 验证后一次性 commit output；
Complete 返回 first request-line 的 exact consumed length，caller 再 retrieve，suffix 保留。

request line：method SP target SP HTTP-version CRLF。

正确性核心：
当前 R1 已做到：不依赖 recv boundary、不丢 suffix、失败不污染 output。
R2 要修：target prefix 的 off-by-one、无终止符超长输入和 diagnostics helper definition。
Round3 再用 all-split test、boundary matrix 与 sanitizer 证明这些修复。
```

下一步：Week11 Day2 在同一 parser 上增加 header fields、`Host` 与 header-section limit。
