# Week11 Day4：把结构化请求变成精确 HTTP Response

> 日期：2026-09-27
> 主线位置：HTTP Server V1
> 前置：Week11 Day1~Day3 已正式通过
> 今日产出：<code>HttpResponse</code>、固定 routes、response encoder 与 exact-byte tests

今天只干一件事：

> **输入一份已经解析完成的 HttpRequest，决定该返回什么，再把 HttpResponse 精确编码成可发送的 HTTP/1.1 bytes。**

今天不接 socket，不接 EventLoop，也不修改已经通过的 parser。先把“业务决定”和“协议序列化”做成两个纯内存组件；Day5 再接进 Reactor。

---

# Part 1：前情提要与任务边界

## 1. 从一个真实请求开始

Day3 之后，下面的 bytes：

~~~~text
POST /echo HTTP/1.1\r\n
Host: localhost\r\n
Content-Length: 3\r\n
\r\n
A\0B
~~~~

已经能被 parser 证明为一条完整请求，并得到：

~~~~text
method  = POST
target  = /echo
version = HTTP/1.1
body    = ['A', '\0', 'B']
~~~~

server 接下来还缺两步：

~~~mermaid
flowchart LR
    A["HttpRequest<br/>parser 已证明边界"] --> B["route_http_request<br/>决定回什么"]
    B --> C["HttpResponse<br/>结构化响应"]
    C --> D["encode_http_response<br/>生成 wire bytes"]
    D --> E["std::string<br/>Day5 交给 Connection::send"]
~~~

例如 <code>POST /echo</code> 应得到：

~~~~text
HTTP/1.1 200 OK\r\n
Content-Type: application/octet-stream\r\n
Content-Length: 3\r\n
\r\n
A\0B
~~~~

最后三个 body bytes 是 <code>A</code>、NUL、<code>B</code>，不能用 C-string 长度猜边界。

## 1.1 先把它放回整条网络链

你现在看到的 <code>route_http_request</code> 和 encoder 都只是普通 C++ 函数，因此很容易产生一个疑问：

> 它们明明没有调用 socket，也没有处理 packet，到底算网络系统的哪一部分？

先给结论：

> **它们都属于 TCP/IP 四层模型里的应用层。Parser 负责读懂 HTTP request，route 负责决定 server 要做什么，encoder 负责把结果重新写成 HTTP response。**

### 1.1.1 从四层模型看

~~~mermaid
flowchart TD
    A["应用层<br/>HTTP parser<br/>HTTP route<br/>HTTP response encoder"]
    B["传输层<br/>TCP reliable byte stream"]
    C["网络层<br/>IP addressing and forwarding"]
    D["链路层<br/>Ethernet or WiFi frames"]
    A --> B
    B --> C
    C --> D
~~~

四层各自处理的问题不同：

| TCP/IP 层次 | 当前链路中的对象 | 它解决什么问题 |
|---|---|---|
| 应用层 | HTTP parser、route、encoder | bytes 表达什么请求，server 应做什么，response 应长什么样 |
| 传输层 | TCP、connected socket | 在两个进程之间提供可靠、有序的 byte stream |
| 网络层 | IP | packet 应跨哪些 networks 到达目标 host |
| 链路层 | Ethernet、Wi-Fi | 当前 link 上怎样把 frame 交给下一跳 |

所以 <code>route_http_request</code> 不是在决定 packet 下一跳，也不接触 IP address。

它是在 server process 内部决定：

~~~~text
这条已经读懂的 HTTP request
应该交给哪一种 application behavior
~~~~

### 1.1.2 这里有两个完全不同的 route

英文都叫 <code>route</code>，但上下文不同：

| 名称 | 所在层次 | 输入 | 决定什么 |
|---|---|---|---|
| IP route | 网络层 | destination IP | packet 下一跳走哪里 |
| HTTP route | 应用层 | method + target | request 交给哪个 application behavior |

今天写的是第二个。

例如：

~~~~text
GET  /health -> health behavior -> "OK\n"
GET  /hello  -> hello behavior  -> "Hello, World!\n"
POST /echo   -> echo behavior   -> request.body
~~~~

这里没有真正独立的 handler function 也没关系。你现在的固定 <code>if</code>、<code>switch</code> 或查表逻辑，本质上都在完成同一个动作：

> **根据 method + target，把 request 分派到正确的业务规则。**

这就是 HTTP route 的用途。

### 1.1.3 从 client 到 server，再回到 client

把前十周造出的组件和今天的组件全部接回来：

~~~mermaid
flowchart TD
    A["Client application<br/>creates HTTP request bytes"]
    B["Client kernel TCP<br/>sends byte stream"]
    C["Network<br/>IP packets and link frames"]
    D["Server kernel TCP<br/>reassembles receive stream"]
    E["EventLoop<br/>observes readable socket"]
    F["Connection<br/>recv into input Buffer"]
    G["HTTP parser<br/>bytes become HttpRequest"]
    H["HTTP route<br/>HttpRequest becomes HttpResponse"]
    I["HTTP encoder<br/>HttpResponse becomes bytes"]
    J["Connection<br/>send and drain output Buffer"]
    K["Server kernel TCP<br/>sends response stream"]
    L["Network<br/>response packets and frames"]
    M["Client kernel TCP<br/>reassembles response stream"]
    N["Client application<br/>reads HTTP response bytes"]
    A --> B
    B --> C
    C --> D
    D --> E
    E --> F
    F --> G
    G --> H
    H --> I
    I --> J
    J --> K
    K --> L
    L --> M
    M --> N
~~~

这张图里：

~~~~text
kernel TCP / IP / link
    负责把 bytes 跨机器运过来和运回去

EventLoop / Channel / Connection / Buffer
    负责在 server process 中等待 socket、收发 bytes、保存 partial I/O state

HTTP parser / route / encoder
    负责解释应用层协议并产生应用层结果
~~~~

<code>EventLoop</code>、<code>Connection</code> 和 <code>Buffer</code> 是我们在 user space 里组织网络程序的工程组件；它们不是 TCP/IP 四层模型额外长出的三层。

### 1.1.4 route 为什么不能省

Parser 只回答：

~~~~text
client 说了什么？
~~~~

例如：

~~~~text
method = POST
target = /echo
body   = A 00 B
~~~~

Encoder 只回答：

~~~~text
给定一个 HttpResponse，怎样把它写成合法 HTTP bytes？
~~~~

中间仍缺少最重要的决定：

~~~~text
server 收到这个请求后，到底要做什么？
~~~~

<code>route_http_request</code> 就填上这一步：

~~~~text
HttpRequest
-> 根据 method + target 选择 behavior
-> 执行当前固定业务规则
-> 产生 HttpResponse
~~~~

如果没有 route，parser 虽然读懂了 <code>GET /health</code>，server 却不知道该返回健康状态、hello text、echo body，还是 404。

因此完整职责是：

~~~~text
parser：client 要什么
route：server 决定做什么
encoder：怎样把结果写回 HTTP
~~~~

### 1.1.5 为什么今天看上去不像在写网络

因为今天故意把应用层逻辑从 socket 中拆出来：

~~~~text
不需要启动 server
不需要真的 recv
不需要真的 send
只给普通 object
就能验证 route decision 和 exact response bytes
~~~~

这不是它离开了网络，而是我们先把整条网络链中的一段拆下来做 component test。

Day5 才会把插头接回去：

~~~~text
Connection 收到 bytes
-> parser
-> route_http_request
-> encode_http_response
-> Connection::send
~~~~

到那时，今天的两个普通函数就会真正处于每条 connection 的 request/response path 中。

这套形状以后还会直接迁移到 Mini Redis：

~~~~text
RESP bytes
-> RESP parser
-> command dispatch
-> SET / GET behavior
-> RESP encoder
-> response bytes
~~~~

HTTP route 在当前项目中练的，正是“协议解析结果怎样进入 application command handling”这一层。

## 2. 今天必须回答的五个问题

1. route 与 encoder 在 TCP/IP 四层和 server 内部链路中分别处在哪里？
2. route 怎样区分 <code>404 Not Found</code> 和 <code>501 Not Implemented</code>？
3. encoder 怎样保证 <code>Content-Length</code> 等于 body 的 byte count？
4. body 含 <code>\0</code> 时，为什么仍能完整编码？
5. <code>Connection: close</code> 写入 response 后，为什么不能立刻销毁 Connection？

每个问题都对应 observable behavior，不要求只背定义。

## 3. 职责边界

| 对象 | 所在位置 | 今天负责什么 |
|---|---|---|
| <code>HttpRequest</code> | 应用层 HTTP model | 保存 parser 已确认的 method、target、headers 与 body |
| route | 应用层 application policy | 根据 method 和 target 选择 status、content type 与 body |
| <code>HttpResponse</code> | 应用层 HTTP model | 保存尚未序列化的结构化 response |
| encoder | 应用层 HTTP protocol | 把 response 按 HTTP/1.1 格式生成 owning bytes |
| Connection | user-space I/O component | 今天不参与；Day5 接收最终 bytes 并处理 partial write |

## 4. 必要术语

### 4.1 response

<code>response</code>：响应。它是 server 对 request 给出的结果，由 status line、headers 和可选 body 组成。

### 4.2 status line

<code>status line</code>：状态行，即 response 的第一行：

~~~~text
HTTP-version SP status-code SP reason-phrase CRLF
~~~~

今天固定输出 HTTP/1.1，例如：

~~~~text
HTTP/1.1 200 OK\r\n
~~~~

### 4.3 status code 与 reason phrase

<code>status code</code>：三位十进制状态码。<code>reason phrase</code>（原因短语）是状态码后便于人阅读的文本。

| code | reason phrase | 当前含义 |
|---:|---|---|
| 200 | OK | route 找到并正常产生结果 |
| 400 | Bad Request | parser 已证明 request 不合法 |
| 404 | Not Found | method 受支持，但没有匹配 route |
| 413 | Content Too Large | body 超过本项目 1 MiB policy |
| 501 | Not Implemented | server 没实现该 method 或 transfer coding |
| 505 | HTTP Version Not Supported | request version 不受支持 |

### 4.4 route

<code>route</code>：路由规则。它把 method + target 映射到 application behavior：

~~~~text
POST + /echo -> 把 request body 原样作为 response body
~~~~

这里不是 IP routing，而是 HTTP application 层的请求分派。

### 4.5 encoder 与 serialization

<code>encoder</code>：编码器。它接收结构化 <code>HttpResponse</code>，输出符合约定的 byte sequence。

<code>serialization</code>：序列化。当前物理动作是把 status、content type、body 和 close flag 排成 HTTP wire format。

### 4.6 wire bytes

<code>wire bytes</code>：最终准备交给网络发送的 bytes。今天不用开 socket；把 encoder 返回值与 expected bytes exact comparison，就能证明布局。

### 4.7 owing bytes

**owning bytes** 就是：这个对象**自己拥有并负责管理这段字节内存的生命周期**。

比如：

```cpp
std::vector<char> body;
body.push_back('h');
body.push_back('i');
```

这里 `body` 是 owning bytes：

- 它自己的内部内存里存着 `h`、`i`；
- 原始数据来自哪里已经不重要；
- `body` 析构时，`vector` 自动释放这块内存；
- 外部那段原始内存即使失效，`body` 的内容仍然有效。

## 5. 文件与停止边界

建议新增：

~~~~text
include/http/http_response.hpp
include/http/http_routes.hpp
src/http_response.cpp
src/http_routes.cpp
tests/http_response_test.cpp
CMakeLists.txt
~~~~

今天完成：

~~~~text
HttpRequest -> fixed route -> HttpResponse -> exact bytes
~~~~

今天不做：

~~~~text
socket / EventLoop integration
Connection::send integration
keep-alive / pipelining
dynamic router framework
HTML templates
完整 RFC response-header set
~~~~

---

# Part 2：教程开始

## 6. Round1：先独立造出 response path

程序用途：

> **给定完整 HttpRequest，返回结构化 HttpResponse；再把 response 编码成可直接交给 Connection::send 的 owning bytes。**

两层 public API：

~~~~cpp
HttpResponse route_http_request(const HttpRequest& request);

std::string encode_http_response(const HttpResponse& response);
~~~~

route 输出 object；encoder 输出 bytes。不要合成一个“大函数直接拼字符串”，否则 route、protocol layout 和 Day5 integration 会缠在一起。

它们在完整 server 中的位置是：

~~~~text
Connection input Buffer
-> parser
-> route_http_request
-> encode_http_response
-> Connection::send
~~~~

Round1 只是直接构造 <code>HttpRequest</code>，从 route 开始调用，以便暂时绕过 socket 和 Reactor，单独验证应用层 decision 与 serialization。

## 7. Round1 public model

~~~~cpp
#pragma once

#include <string>

enum class HttpStatus {
    Ok = 200,
    BadRequest = 400,
    NotFound = 404,
    ContentTooLarge = 413,
    NotImplemented = 501,
    HttpVersionNotSupported = 505
};

struct HttpResponse {
    HttpStatus status;
    std::string content_type;
    std::string body;
    bool close_connection{false};
};

std::string encode_http_response(const HttpResponse& response);
~~~~

| field | 功能 |
|---|---|
| <code>status</code> | 决定 status code 与固定 reason phrase |
| <code>content_type</code> | 描述 response body 的 media type |
| <code>body</code> | 真实 body bytes，可包含 NUL |
| <code>close_connection</code> | 是否生成 <code>Connection: close</code> |

<code>std::string body</code> 在这里是 byte container，不表示 body 必须是文本。

## 8. encoder 的完整 contract

### 8.1 输入与成功输出

encoder 只读 <code>const HttpResponse&</code>，不保存其中 pointer/reference。返回 owning <code>std::string</code>：

~~~~text
HTTP/1.1 <code> <reason>\r\n
Content-Type: <content_type>\r\n
Content-Length: <body.size()>\r\n
[Connection: close\r\n]
\r\n
<body bytes>
~~~~

方括号这一行只在 <code>close_connection == true</code> 时出现；方括号本身不输出。

### 8.2 固定 header 顺序

1. status line
2. <code>Content-Type</code>
3. <code>Content-Length</code>
4. 可选 <code>Connection: close</code>
5. empty line
6. body bytes

HTTP 语义通常不依赖这几个字段的相对顺序，但固定顺序能让测试和调试稳定。

### 8.3 错误 contract

| 错误条件 | C++ 行为 | 建议 <code>what()</code> 英文 |
|---|---|---|
| <code>status</code> 不是已声明 value | throw <code>std::invalid_argument</code> | <code>unknown HTTP status</code> |
| <code>content_type</code> 为空 | throw <code>std::invalid_argument</code> | <code>empty HTTP content type</code> |
| <code>content_type</code> 含 CR/LF | throw <code>std::invalid_argument</code> | <code>invalid HTTP content type</code> |

body 可为空，也可包含任意 byte。header value 的 CR/LF 检查用于阻止它生成额外 header line。

### 8.4 side effects

无 socket I/O、无全局状态修改。相同 input 必须得到相同 bytes。

## 9. fixed route contract

声明：

~~~~cpp
#pragma once

#include "http/http_request.hpp"
#include "http/http_response.hpp"

HttpResponse route_http_request(const HttpRequest& request);
~~~~

固定规则：

| method | target | status | content type | body |
|---|---|---:|---|---|
| GET | <code>/health</code> | 200 | <code>text/plain; charset=utf-8</code> | <code>OK\n</code> |
| GET | <code>/hello</code> | 200 | <code>text/plain; charset=utf-8</code> | <code>Hello, World!\n</code> |
| POST | <code>/echo</code> | 200 | <code>application/octet-stream</code> | request body exact bytes |
| GET/POST | 其他组合 | 404 | <code>text/plain; charset=utf-8</code> | <code>Not Found\n</code> |
| 其他 method | 任意 target | 501 | <code>text/plain; charset=utf-8</code> | <code>Not Implemented\n</code> |

判断顺序：

~~~~text
先判断 method 是否属于本 server 支持集合
-> 不支持：501
-> 支持：再查 route
-> 没匹配：404
~~~~

因此：

~~~~text
GET /missing  -> 404
PUT /health   -> 501
POST /health  -> 404
~~~~

固定 route 的 <code>close_connection</code> 默认 <code>false</code>。Day5 的 session policy 再决定是否关闭。

### 9.1 enum class 是强类型，需要 static_cast 成 int

对，`enum class` 不允许自动转成整数，所以这里就用 `static_cast`。

```cpp
HttpStatus status = HttpStatus::Ok;

int code = static_cast<int>(status);  // code == 200
```

写 HTTP response 时通常直接这样：

```cpp
response += std::to_string(static_cast<int>(status));
```

例如：

```cpp
HttpStatus status = HttpStatus::NotFound;

std::string line =
    "HTTP/1.1 " +
    std::to_string(static_cast<int>(status)) +
    " Not Found\r\n";
```

这里会得到：

```text
HTTP/1.1 404 Not Found\r\n
```

`enum class` 的特点就是“强类型”：它不会偷偷把 `HttpStatus::Ok` 当成 `200`，因此你必须明确写 `static_cast<int>(status)`。

后面如果嫌每次都写长，可以封装：

```cpp
int status_code(HttpStatus status) {
    return static_cast<int>(status);
}
```

然后：

```cpp
std::to_string(status_code(HttpStatus::ContentTooLarge))
```

结果就是 `"413"`。



## 10. 最小使用例子

### 10.1 health

~~~~cpp
HttpRequest request;
request.method = "GET";
request.target = "/health";

const HttpResponse response = route_http_request(request);
const std::string bytes = encode_http_response(response);
~~~~

预期：

~~~~text
HTTP/1.1 200 OK\r\n
Content-Type: text/plain; charset=utf-8\r\n
Content-Length: 3\r\n
\r\n
OK\n
~~~~

<code>OK\n</code> 是 3 bytes，所以 Content-Length 是 3。

### 10.2 binary echo

~~~~cpp
HttpRequest request;
request.method = "POST";
request.target = "/echo";
request.body = std::string{"A\0B", 3};

const std::string bytes =
    encode_http_response(route_http_request(request));
~~~~

预期 Content-Length 是 3，empty line 后最后三个 bytes 仍是 <code>A 00 B</code>。

### 10.3 unsupported method

~~~~cpp
HttpRequest request;
request.method = "PUT";
request.target = "/health";

const HttpResponse response = route_http_request(request);
~~~~

预期 status 501，body <code>Not Implemented\n</code>。

## 11. Round1 三个核心 tests

### 11.1 exact health response

~~~~text
GET /health
-> route fields exact
-> encoded bytes 与完整 expected string exact equality
~~~~

不要只查 <code>find("200")</code>。exact comparison 才能同时证明 status line、CRLF、empty line、Content-Length 与 body。

### 11.2 binary echo

输入 <code>std::string{"A\0B", 3}</code>，验证：

~~~~text
status == 200
Content-Type == application/octet-stream
encoded Content-Length == 3
encoded body size/bytes exact
~~~~

### 11.3 404 与 501 分界

~~~~text
GET /missing -> 404
PUT /health  -> 501
~~~~

这条证明 route missing 与 method unsupported 没混成一个判断。

## 12. CMake 与运行入口

我已经按你 Ubuntu 当前工程核对过 target 和目录。你现在的 Week11 代码仍在：

~~~~text
/home/xgf/code/system-learning/cpp/week10
~~~~

Day4 已经新建：

~~~~text
include/http/http_response.hpp
include/http/http_routes.hpp
src/http_response.cpp
src/http_routes.cpp
tests/http_response_test.cpp
~~~~

把下面整段**直接追加到现有 <code>CMakeLists.txt</code> 末尾**：

~~~~cmake
# HTTP response encoder and fixed routes
add_library(http_response
    src/http_response.cpp
    src/http_routes.cpp
)

target_include_directories(http_response PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include/http
)

target_compile_options(http_response PRIVATE
    -Wall
    -Wextra
    -g
)

add_executable(http_response_test
    tests/http_response_test.cpp
)

target_compile_options(http_response_test PRIVATE
    -Wall
    -Wextra
    -g
)

target_link_libraries(http_response_test PRIVATE
    http_response
    GTest::gtest_main
    GTest::gtest
)

gtest_discover_tests(http_response_test)
~~~~

这段 CMake 建立的依赖是：

~~~~text
src/http_response.cpp
src/http_routes.cpp
        |
        v
http_response library
        |
        v
http_response_test executable
        |
        +--> GTest::gtest_main
        +--> GTest::gtest
~~~~

几个你不需要再猜的点：

- 两个 <code>.cpp</code> 放进同一个 <code>http_response</code> library，因为 route 的结果就是 <code>HttpResponse</code>，它们共同构成今天的 component。
- <code>PUBLIC include/http</code> 会把 header 搜索路径传播给 <code>http_response_test</code>，test target 不需要再重复写一次 include directory。
- <code>HttpRequest</code> 当前是 header 中的数据类型；Day4 route 只读取这个 object，不调用 <code>http_request_parser.cpp</code> 中的函数，因此 <code>http_response</code> **不需要**链接 <code>http_request_parser</code>。
- 今天的 test 不使用 Reactor <code>Buffer</code>，也不启动 socket，因此不链接 <code>buffer</code>、<code>connection</code> 或 <code>event_loop</code>。
- 现有文件前面已经执行过 <code>include(GoogleTest)</code>，这里可以直接调用 <code>gtest_discover_tests</code>，不用再写一遍。

统一入口：

~~~~bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build -j2
cmake -E chdir build ctest --output-on-failure
~~~~

这里必须 build 全项目再跑全量 CTest。只 build <code>http_response_test</code> 后直接跑全量 CTest，会让其他已注册但尚未生成的 executable 显示 <code>NOT_BUILT</code>；这次 R1 检阅已经实际触发并纠正了这个命令问题。

第一次配置后，CMake 会记录：

~~~~text
怎样编译两个 response source
怎样生成 libhttp_response.a
怎样把 test 与 library、GoogleTest 链接起来
怎样把 GoogleTest cases 注册给 CTest
~~~~

后面你只修改 <code>.cpp</code> 时，一般重新执行 build 和 CTest 即可；如果新增 target/source 或改 CMake，再重新运行 configure。

Round1 最低证据：

~~~~text
normal build zero warnings
existing parser tests still pass
3 response-focused tests pass
process exit code 0
~~~~

测试失败必须 non-zero exit；不能打印 FAIL 后仍返回 0。

## 13. Round1 阅读闸门

现在停止阅读。

先完成：

~~~~text
HttpResponse public model
route_http_request
encode_http_response
3 个核心 tests
CMake integration
normal build + full CTest
~~~~

Round1 通过前，不继续看 encoder 因果链、Connection-close 语义和 parser error mapping。后半部分用于解释并打磨你的真实实现，不应提前变成照抄答案。

---

## 14. Round2：完整主线

有了 R1 后，再检查：

~~~~text
HttpRequest
-> route 决定 application result
-> HttpResponse 保存结构化字段
-> encoder 查 status code/reason
-> 写 status line
-> 写 Content-Type
-> 根据 body.size() 写 Content-Length
-> 按 flag 决定 Connection: close
-> 写 empty line
-> append body exact range
-> 返回 owning std::string
~~~~

### 14.1 你的 R1 已经怎样实现这条链

你当前真实代码没有引入额外 class：

~~~~text
route_http_request
    用 nested if 判断 method 和 target
    -> 直接 aggregate-initialize HttpResponse

encode_http_response
    -> status_code 做 enum class 到 int 的显式转换
    -> reason_phrase_helper 选择固定英文短语
    -> 依次追加 status line、Content-Type、Content-Length
    -> close_connection 为 true 时追加 Connection: close
    -> 追加 empty line 和 body
~~~~

这个 representation 足够直接，符合 Day4 V1。Round2/3 不要求把 route 改成 map、注册表或 handler hierarchy，也不要求为了“像框架”而增加 class。

你在教程中补充的两点也已经真实落到代码：

~~~~text
enum class 不隐式转 int
-> status_code 使用 static_cast<int>

encoder 返回 std::string
-> 返回值自己拥有 encoded bytes
-> HttpResponse 离开作用域后，返回的 bytes 仍有效
~~~~

## 15. 为什么 route 与 encoder 分开

如果所有逻辑都写成：

~~~~cpp
std::string handle(const HttpRequest& request);
~~~~

失败时很难定位：

~~~~text
route 选错 status？
reason phrase 映射错？
CRLF 少了？
Content-Length 算错？
body 被 NUL 截断？
~~~~

拆开后：

~~~~text
route test：只看 HttpResponse fields
encoder test：人工构造 response，看 exact bytes
integration test：request -> route -> encode
~~~~

Day5 中 Connection 也不需要认识 status code，只发送 encoder 产生的 bytes。

## 16. status line 与 message layout

一个 enum value 必须映射到唯一固定的 code/reason：

~~~~text
HttpStatus::Ok -> 200 -> "OK"
~~~~

unknown enum value 必须进入错误 contract，不能悄悄当成 200。

你当前的 declared values 都能正确映射，但 fallback 仍是：

~~~~cpp
return "qwq";
~~~~

同时 <code>status_code()</code> 会直接把任意强制转换得到的 enum 数值转成整数。因此：

~~~~text
static_cast<HttpStatus>(999)
-> status_code 得到 999
-> reason_phrase_helper 得到 "qwq"
-> encoder 生成 "HTTP/1.1 999 qwq"
~~~~

这不符合第 8.3 节的错误 contract。Round2 的第一个修复目标是：unknown status 稳定抛出 <code>std::invalid_argument("unknown HTTP status")</code>，不能产生伪造 wire response。

[RFC 9112 Section 4](https://www.rfc-editor.org/rfc/rfc9112#section-4) 给出 status line 结构；本项目固定 reason phrase，便于 exact test。

HTTP/1.1 message 基本布局：

~~~~text
start-line
*( field-line CRLF )
CRLF
[ message-body ]
~~~~

单独的 CRLF 表示 header section 结束。Day1~Day3 从 bytes 中证明 boundary；今天 encoder 反过来制造 boundary。参考 [RFC 9112 Section 2.1](https://www.rfc-editor.org/rfc/rfc9112#section-2.1)。

## 17. Content-Length 只有一个事实源

今天唯一来源：

~~~~cpp
response.body.size()
~~~~

~~~~text
"OK\n"         -> 3 bytes
['A','\0','B'] -> 3 bytes
empty          -> 0 bytes
~~~~

encoder 不让 caller 单独传 Content-Length，否则可能出现：

~~~~text
body.size() == 3
caller says Content-Length == 100
~~~~

从 body 自动计算，在结构上消除了双事实源。

你当前实现正是：

~~~~cpp
result += "Content-Length: "
       + std::to_string(response.body.size())
       + "\r\n";
~~~~

因此 route 不保存第二份 length，encoder 也不接受 caller 传入的 length。Health exact-wire test 已证明 <code>OK\n</code> 得到 3；新增的 404/501 test 又分别证明 <code>Not Found\n</code> 得到 10、<code>Not Implemented\n</code> 得到 16。

参考 [RFC 9110 Section 8.6](https://www.rfc-editor.org/rfc/rfc9110#section-8.6) 与 [RFC 9112 Section 6.2](https://www.rfc-editor.org/rfc/rfc9112#section-6.2)。

## 18. binary body 为什么不能用 strlen

<code>A 00 B</code> 是三个 bytes。<code>strlen</code> 在 NUL 停止，只得到 1；<code>std::string::size()</code> 返回 3。

encoder 必须按 explicit length append，或直接 append 整个 string object。不能把 <code>body.c_str()</code> 再当无长度 C-string 计算。

你当前使用：

~~~~cpp
result += response.body;
~~~~

这里追加的是整个 <code>std::string</code> object 保存的 range，不调用 <code>strlen()</code>。你的 <code>BinaryEcho</code> test 已证明 encoded suffix 仍是 <code>A</code>、NUL、<code>B</code>。

## 19. Connection: close 不等于立刻 close(fd)

<code>Connection: close</code> 表示当前 response 发完后，不再承载下一条 request。

真实顺序：

~~~~text
encoder 产生 response bytes
-> Connection::send 纳入 output ordering
-> 可能只写出 prefix
-> suffix 留在 output Buffer
-> EPOLLOUT drain suffix
-> 再 close fd / 销毁 connection
~~~~

若生成 response 后立即 close，output Buffer 中尚未交给 kernel 的 suffix 会丢失。

所以：header 表达 protocol policy，Connection lifecycle 负责安全执行完。

## 20. 404 与 501

<code>GET /missing</code>：server 认识 GET，但没找到 route，所以 404。

<code>PUT /health</code>：server 没实现 PUT 的语义，所以 501。参考 [RFC 9110 Section 15.6.2](https://www.rfc-editor.org/rfc/rfc9110#section-15.6.2)。

route 判断顺序不是内部小事，而是 observable protocol behavior。

你当前 nested <code>if</code> 的顺序正确：

~~~~text
method == GET
-> 已知 target 返回 200
-> 其他 target 返回 404

method == POST
-> /echo 返回 200
-> 其他 target 返回 404

其他 method
-> 501
~~~~

你不想继续手写的第三个 GoogleTest 已由 Codex 追加到 <code>tests/http_response_test.cpp</code>。它用一个 test 同时验证：

~~~~text
GET /missing
-> exact 404 status line / headers / body

PUT /health
-> exact 501 status line / headers / body
~~~~

这条 scaffold 属于 Codex 补测；route mechanism 和前两个 tests 属于你的实现，验收记录必须继续区分。

## 21. ownership 与 lifetime

encoder 返回 owning <code>std::string</code>：

~~~~text
HttpResponse 离开作用域
-> encoded bytes 仍有效
-> Day5 可传给 Connection::send
~~~~

encoder 不返回 local string pointer，也不保存 response body pointer。

你当前 <code>result</code> 是 local <code>std::string</code>，函数按值返回。C++17 会安全地返回一个拥有 storage 的 string object；它不是指向 local buffer 的 dangling pointer。这与教程中新增的 <code>owning bytes</code> 解释一致。

## 22. R1 通过后的定向润色

R1 已正式通过。继续保留你的 representation：

~~~~text
nested if routes
aggregate HttpResponse
status_code + reason_phrase_helper
std::string concatenation
body.size() as the only Content-Length source
~~~~

Round2 只做下面两个 correctness 修复：

1. **unknown status 必须抛异常。** 删除 <code>"qwq"</code> fallback，让非法 enum value 稳定产生 <code>std::invalid_argument("unknown HTTP status")</code>。
2. **验证 Content-Type。** 空值抛 <code>"empty HTTP content type"</code>；含 CR 或 LF 抛 <code>"invalid HTTP content type"</code>。必须在开始生成 wire response 前完成验证。

完成后补三条小测试：

~~~~text
unknown status -> exact exception type/message
empty content type -> exact exception type/message
CR/LF content type -> exact exception type/message
~~~~

这三条测试可以放在一个 table-driven test 中，不要求手抄重复 fixture。

非阻塞整理：

~~~~text
http_response.cpp 未使用 http_request.hpp，可删
status_code / reason_phrase_helper 若只供 encoder 使用，可移到 source 内部
~~~~

这两项不影响 correctness，不为了清理它们重写 public design。

---

# Part 3：Round3 收口、证据与下一步

## 23. parser error 变成 response

Round3 增加：

~~~~cpp
HttpResponse response_for_parse_error(HttpRequestError error);
~~~~

固定 policy：

| parser error | status | body |
|---|---:|---|
| <code>BadRequest</code> | 400 | <code>Bad Request\n</code> |
| <code>RequestLineTooLong</code> | 400 | <code>Bad Request\n</code> |
| <code>HeaderSectionTooLong</code> | 400 | <code>Bad Request\n</code> |
| <code>BodyTooLarge</code> | 413 | <code>Content Too Large\n</code> |
| <code>UnsupportedTransferEncoding</code> | 501 | <code>Not Implemented\n</code> |
| <code>UnsupportedHttpVersion</code> | 505 | <code>HTTP Version Not Supported\n</code> |

全部使用：

~~~~text
content_type = text/plain; charset=utf-8
close_connection = true
~~~~

当前 stream 已无法按本项目 contract 继续可靠解析，所以错误 response 发完后关闭。

传入 <code>HttpRequestError::None</code>：

| 条件 | 行为 | 建议 <code>what()</code> |
|---|---|---|
| <code>error == None</code> | throw <code>std::invalid_argument</code> | <code>HTTP parse error is none</code> |

## 24. Round3 route 与 encoder matrix

route 用 table-driven test 覆盖：

~~~~text
GET  /health   -> 200
GET  /hello    -> 200
POST /echo     -> 200 + exact body
GET  /missing  -> 404
POST /missing  -> 404
PUT  /health   -> 501
DELETE /echo   -> 501
~~~~

encoder 补齐：

1. empty body -> <code>Content-Length: 0</code>
2. embedded NUL -> byte count 与 suffix exact
3. close false -> 无 Connection header
4. close true -> exact 一行 <code>Connection: close</code>
5. empty/CRLF content type -> exact exception type/message
6. every declared status -> code/reason exact

不需要为每个 case 手抄 fixture；机械 scaffold 可以委托，但你必须能说明每个 oracle。

## 25. parser-error response matrix

对每个 public error 验证：

~~~~text
expected status/body
close_connection == true
encoded Content-Length exact
encoded Connection: close present
~~~~

这里不重新喂 malformed request。parser 分类已在 Day1~Day3 证明；今天验证“结构化 error -> response policy”。

## 26. evidence 层级

### R1 已有证据

~~~~text
Ubuntu: g++ 10.5.0 / C++17
normal full build: zero warnings
full CTest after building all targets: 48/48 PASS
response-focused tests: 3/3 PASS
fresh ASan/UBSan response-focused tests: 3/3 PASS
sanitizer reports: none
~~~~

第一次只 build <code>http_response_test</code> 后运行全量 CTest，出现 6 个 <code>NOT_BUILT</code>；这不是旧组件回归，而是测试 executable 尚未生成。改为 build 全项目后，同一全量 CTest 为 48/48 PASS。以后 evidence 必须区分“程序失败”和“根本没有构建被测试程序”。

### component

~~~~text
route fields exact
encoder bytes exact
error mapper fields exact
~~~~

### regression

~~~~text
Day1 request-line
Day2 headers
Day3 body framing
Day4 response
all pass in one CTest run
~~~~

### memory safety

normal build 后运行现有 ASan/UBSan 配置。TSan 不是今日主证据：这些组件是同步纯内存逻辑，没有新增 shared mutable state。

## 27. 验收命令

~~~~bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build -j
cmake -E chdir build ctest --output-on-failure
~~~~

记录：

~~~~text
compiler/version
normal build warning count
response-focused pass count
full CTest pass count
ASan/UBSan pass count and reports
~~~~

## 28. 验收问题

如果 source/tests/note 已有等价证据，不要求机械抄长答案。

1. 为什么 GET /missing 是 404，而 PUT /health 是 501？
2. body 是 <code>A\0B</code> 时，Content-Length 是多少？为什么？
3. 为什么 encoder 不让 caller 单独传 Content-Length？
4. 写入 <code>Connection: close</code> 后，为什么仍要等 output Buffer drain？
5. route、encoder、Connection 分别负责什么？
6. 为什么 error mapper 不重新解析 malformed bytes？

## 29. 正式通过标准

~~~~text
HttpResponse 清楚表达 status/content_type/body/close policy
fixed routes 满足 contract
404/501 分界正确
encoder 产生 exact HTTP/1.1 bytes
Content-Length 来自 body.size()
binary body 不被 NUL 截断
invalid response object 有稳定异常 contract
parser error mapping 完成
normal build zero warnings
existing parser regression 全通过
response tests 全通过
ASan/UBSan 无报告
~~~~

不要求今天启动 server、用 curl、实现 keep-alive、设计通用 router，或手抄重复 GoogleTest。

## 30. 今日压缩记忆

~~~~text
HttpRequest
-> route 决定 status/content_type/body
-> HttpResponse 保存结构化结果
-> encoder 从 body.size() 生成 Content-Length
-> 产生 exact owning wire bytes
-> Day5 再交给 Connection::send
~~~~

> **route 决定回什么，encoder 决定怎样编码，Connection 决定怎样把 bytes 安全发完。**

Day5 将接成：

~~~~text
Connection input Buffer
-> parse_request
-> route / parse-error mapping
-> encode_http_response
-> Connection::send
-> output drain
~~~~
