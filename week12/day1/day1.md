# Week12 Day1：把 command result 编码成 RESP2 reply bytes

> 日期：2026-10-01
>
> 主线：HTTP Server V1 -> RESP2 encoder -> RESP parser -> Mini Redis V1
>
> 今日定位：只做纯内存 reply encoder，不接 socket、不写 parser、不写 KV store
>
> 今日主要产出：`resp_encoder.hpp/.cpp`、`resp_encoder_test.cpp`

**今天只干一件事：把“成功、错误、整数、普通 bytes、空值”编码成 client 能准确拆开的 RESP2 wire bytes。**

完成 R1 后，你应该能让下面五个调用得到 exact output：

```text
simple string "OK"       -> +OK\r\n
error "ERR bad command"  -> -ERR bad command\r\n
integer 2                 -> :2\r\n
bulk string "hello"      -> $5\r\nhello\r\n
null bulk string          -> $-1\r\n
```

---

# Part 1：前情提要与必要术语

## 1. 今天接在 Week11 的哪里

Week11 已经完成一条完整的 HTTP response 路径：

```text
application 产生 HttpResponse
-> HTTP encoder 生成 status line、headers、body
-> Connection::send 保存 bytes
-> handle_send 把 output Buffer flush 到 socket
```

Mini Redis 仍然复用后半段：

```text
encoded bytes
-> Connection::send
-> output Buffer
-> non-blocking send
```

今天只替换最前面的 application protocol：

```text
HttpResponse
-> RESP reply

HTTP response encoder
-> RESP encoder
```

所以今天不需要碰下面这些已经通过的代码：

```text
Buffer
Channel
EventLoop
Acceptor
Connection
http_server_v1
```

先把一个纯内存 encoder 做对，Day5 才把它接进 Reactor。

---

## 2. 先看一个 client 到底会收到什么

假设未来 `SET name FxorG` 成功，server 想告诉 client：

```text
OK
```

如果只发送两个 bytes：

```text
OK
```

client 不知道：

```text
这是一条成功 reply，还是普通 value？
reply 到 K 结束，还是后面还有 bytes？
```

RESP2 给它加上两个边界：

```text
+OK\r\n
^  ^^^^
|   当前 short text 的结束位置
reply type：Simple String
```

client 先读第一个 byte `+`，就知道该按 Simple String 解释；再读到结尾的 `\r\n`，就知道这一条 reply 到哪里结束。

如果 `DEL` 删除了两个 keys，server 发送：

```text
:2\r\n
```

第一个 byte `:` 告诉 client：payload `2` 不是普通 text，而是 Integer reply。

**RESP 的第一层直觉就是：第一个 byte 说明类型，后面的规则说明边界。**

---

## 3. 为什么 value 不能也只用一行

短状态文本可以用：

```text
+OK\r\n
```

但 Redis value 可能是任意 bytes：

```text
A\0B
hello\r\nworld
一段图片或压缩数据
```

如果 encoder 靠 `\r\n` 查找 value 的终点，payload 自己含 `\r\n` 时就会产生歧义。

RESP2 因此把任意 bytes 写成：

```text
$<byte-count>\r\n<payload bytes>\r\n
```

`A\0B` 的 payload length 是 3，wire bytes 是：

```text
$3\r\nA\0B\r\n
```

client 的动作变成：

```text
先读取 decimal length 3
-> 精确读取后面 3 bytes
-> 再检查结尾 CRLF
```

它不需要扫描 payload，也不在 `\0` 或 payload 内部的 CRLF 提前停止。

**长度前缀让 arbitrary bytes 拥有明确边界。**

---

## 4. 今天要核销的四个问题

带着这四个问题完成 R1，后文会逐项回答：

1. client 怎样只看第一个 byte 就知道 reply type？
2. short text、integer 和 arbitrary bytes 分别怎样找到结束位置？
3. Bulk String 含 `\0` 时，encoder 怎样仍然得到正确 length？
4. caller 传进来的 bytes 与 encoder 返回的 bytes 分别由谁拥有？

---

## 5. 必要术语

### 5.1 `RESP`

`RESP`：Redis Serialization Protocol，Redis 序列化协议。

**RESP 规定 client 与 server 怎样把 command 和 reply 表达成一段可传输的 bytes。**

本周只实现 RESP2 的受限子集；不因为当前 Redis 还支持 RESP3 就扩大第一版范围。

### 5.2 `serialization`

`serialization`：序列化。

它把程序里的结果：

```text
success("OK")
integer(2)
value("hello")
```

转换成协议规定的 byte sequence：

```text
+OK\r\n
:2\r\n
$5\r\nhello\r\n
```

今天实现的是 serialization 的输出方向。

### 5.3 `encoder`

`encoder`：编码器。

**今天的 encoder 接收一个明确类型的 result，返回一段 owning RESP wire bytes。**

它不调用 `send`，不拥有 socket，也不执行 `SET/GET` 语义。

### 5.4 `wire bytes`

`wire bytes`：线上字节，也就是按 protocol format 准备好、可以交给 transport 发送的 bytes。

今天返回 `std::string`，只是因为它能拥有一段明确长度的 bytes；这里的 `string` 不等于“人类可读文本”。

### 5.5 `CRLF`

`CRLF` 是两个 protocol bytes：

```text
CR：Carriage Return，回车，'\r'，0x0D
LF：Line Feed，换行，'\n'，0x0A
```

RESP 各部分用连续的 `\r\n` 分隔或结束。

### 5.6 `reply`

`reply`：回复。

它是 server 对一条 command 给出的 protocol result。不同 command 可以返回不同 reply types：

```text
SET    -> Simple String
GET    -> Bulk String 或 Null Bulk String
DEL    -> Integer
错误   -> Error
```

---

## 6. 今天的范围和停止边界

今天实现：

```text
Simple String
Error
Integer
Bulk String
Null Bulk String
```

今天不实现：

```text
Array encoder
RESP request parser
command dispatcher
KV store
socket server
RESP3
TTL / AOF
```

Array 会先出现在 client request parser 中；当前六个 V1 commands 的 replies 不需要 Array，所以 Day1 不为“以后可能用到”提前扩展。

---

# Part 2：教程主体

# 教程开始：先把 result 变成 exact reply bytes

# Round 1：只根据外部 contract 独立实现 V1

## 7. 先明确今天要造什么

### 7.1 组件用途

你要实现一个普通的纯内存 C++ component：

```text
名称：RESP encoder

输入：
    已经知道类型的一段 payload，或一个 signed integer

内部职责：
    按 RESP2 规则加入 type marker、decimal length 和 CRLF

输出：
    owning std::string，里面是完整的一条 RESP reply

错误：
    caller 要求编码 Simple String / Error，
    但 payload 含会破坏 line boundary 的 CR 或 LF
```

### 7.2 以后谁会调用它

Day4 的 command layer 会产生结果，Day5 的 application flow 会编码并发送：

```text
SET 成功
-> encode_resp_simple_string("OK")
-> "+OK\r\n"
-> Connection::send(...)

GET 命中 value
-> encode_resp_bulk_string(value)
-> "$<len>\r\n<value>\r\n"
-> Connection::send(...)

GET miss
-> encode_resp_null_bulk_string()
-> "$-1\r\n"
-> Connection::send(...)
```

今天只实现箭头中间的 encoder，不写两边的 command 与 network flow。

---

## 8. Round1 文件位置与职责

在 Ubuntu 当前 canonical project：

```text
~/code/system-learning/cpp/week10/
```

新增三个文件：

```text
include/resp/resp_encoder.hpp
src/resp_encoder.cpp
tests/resp_encoder_test.cpp
```

职责：

| 文件 | 职责 |
|---|---|
| `resp_encoder.hpp` | 声明五个 public encoder functions |
| `resp_encoder.cpp` | 实现 RESP2 exact byte encoding 与输入校验 |
| `resp_encoder_test.cpp` | 用 byte-exact assertions 验证 observable contract |

继续修改现有唯一一份 `CMakeLists.txt`，不要新建第二套工程，也不要复制 Reactor/HTTP source。

---

## 9. 为什么 public input 使用 `std::string_view`

今天的 text/binary payload API 使用：

```cpp
std::string_view
```

`string_view`：字符串视图。它只保存一段现有 byte range 的 pointer 与 length，不拥有底层 bytes。

调用形态：

```cpp
#include <string_view>

std::string_view view = "hello";
```

当前最重要的语义：

```text
view.data()  -> 起点
view.size()  -> 明确 byte count
```

它可以查看含 `\0` 的 bytes，只要创建时给出了正确 length：

```cpp
const char raw[] = {'A', '\0', 'B'};
const std::string_view bytes(raw, sizeof(raw));
```

这里：

```text
bytes.size() == 3
```

**encoder 只在函数调用期间读取 `string_view`，绝不能把它保存到未来。返回的 `std::string` 必须自己拥有 encoded bytes。**

---

## 10. Round1 public API

`include/resp/resp_encoder.hpp` 的 public surface 固定为：

```cpp
#pragma once

#include <cstdint>
#include <string>
#include <string_view>

std::string encode_resp_simple_string(std::string_view value);
std::string encode_resp_error(std::string_view message);
std::string encode_resp_integer(std::int64_t value);
std::string encode_resp_bulk_string(std::string_view value);
std::string encode_resp_null_bulk_string();
```

今天不要求 `RespEncoder` class，也不要求通用 `RespValue` variant。五个函数已经能准确表达 V1 的五类 replies。

内部 representation、helper、拼接顺序与数字转换方式由你独立设计。

---

## 11. 五个接口分别干什么

### 11.1 `encode_resp_simple_string`

用途：编码短小、非 binary 的成功状态文本。

最小调用：

```cpp
const std::string wire = encode_resp_simple_string("OK");
```

必须得到：

```text
+OK\r\n
```

encoder 自动添加 `+` 与末尾 CRLF；caller 只传 payload `OK`。

### 11.2 `encode_resp_error`

用途：编码一条 error reply。

最小调用：

```cpp
const std::string wire =
    encode_resp_error("ERR unknown command");
```

必须得到：

```text
-ERR unknown command\r\n
```

caller 传入完整 error payload，包括 `ERR` 这种 error type word；encoder 只添加 `-` 与 CRLF，不自动猜 error category。

### 11.3 `encode_resp_integer`

用途：编码 signed 64-bit integer reply。

最小调用：

```cpp
const std::string wire = encode_resp_integer(-12);
```

必须得到：

```text
:-12\r\n
```

整数转换成 base-10 decimal text；负号是 number 的一部分。

### 11.4 `encode_resp_bulk_string`

用途：编码任意 byte string。

最小调用：

```cpp
const std::string wire = encode_resp_bulk_string("hello");
```

必须得到：

```text
$5\r\nhello\r\n
```

这里的 `5` 来自 `value.size()`，不是 `strlen(value.data())`。

binary 调用形态：

```cpp
const char raw[] = {'A', '\0', 'B'};
const std::string wire =
    encode_resp_bulk_string(std::string_view(raw, sizeof(raw)));
```

logical wire bytes 是：

```text
$3\r\nA\0B\r\n
```

### 11.5 `encode_resp_null_bulk_string`

用途：编码“value 不存在”。

最小调用：

```cpp
const std::string wire = encode_resp_null_bulk_string();
```

必须得到：

```text
$-1\r\n
```

它没有 payload，也没有结尾的第二组 payload CRLF。

---

## 12. Round1 error contract

Simple String 和 Error 都依赖 CRLF 寻找结束位置，所以它们的 payload 不能包含 CR 或 LF。

错误契约固定为：

| 调用 | 条件 | exception type | `what()` exact text |
|---|---|---|---|
| `encode_resp_simple_string` | payload 含 `\r` 或 `\n` | `std::invalid_argument` | `RESP simple string must not contain CR or LF` |
| `encode_resp_error` | message 含 `\r` 或 `\n` | `std::invalid_argument` | `RESP error must not contain CR or LF` |

其余三个接口没有本日自定义 domain error：

```text
integer：所有 int64_t values 都合法
bulk string：任意 std::string_view bytes 都合法
null bulk：没有输入
```

像所有返回 `std::string` 的函数一样，内存分配失败可能抛 `std::bad_alloc`；今天不捕获并改写这类标准 allocation failure。

不要给 simple string/error 自动做 escaping。遇到 CR/LF 时稳定拒绝，比悄悄改变 caller payload 更容易证明。

---

## 13. Round1 observable contract

### 13.1 Simple String

```text
input  = "OK"
output = "+OK\r\n"
```

### 13.2 Error

```text
input  = "ERR bad command"
output = "-ERR bad command\r\n"
```

### 13.3 Integer

```text
input  = -12
output = ":-12\r\n"
```

### 13.4 Bulk String

```text
input bytes = {'A', '\0', 'B'}
input size  = 3

output prefix  = "$3\r\n"
output payload = {'A', '\0', 'B'}
output suffix  = "\r\n"
```

### 13.5 Null Bulk String

```text
output = "$-1\r\n"
```

### 13.6 Ownership

```text
input string_view：caller-owned，encoder 不保存
returned string：caller-owned，完整拥有 encoded bytes
```

调用返回后，caller 可以销毁原 payload；returned `std::string` 仍必须保持完整。

---

## 14. 一个很小的使用样例

这个例子只展示 public API 怎样被调用，不给 encoder 实现：

```cpp
#include "resp_encoder.hpp"

#include <iostream>
#include <string>

int main() {
    const std::string wire = encode_resp_bulk_string("hello");
    std::cout.write(wire.data(), static_cast<std::streamsize>(wire.size()));
}
```

输出到 terminal 时看起来像：

```text
$5
hello
```

但实际 bytes 是：

```text
$5\r\nhello\r\n
```

因此正式 tests 必须比较 `std::string` exact bytes，不能只靠肉眼看 terminal 换行。

编译器需要看到：

```text
resp_encoder.hpp
resp_encoder.cpp
调用者 source
```

今天通过 CMake target 组织它们，不手工写一条越来越长的 `g++` command。

---

## 15. Round1 核心 tests

R1 不需要先写大矩阵，只需要三组 tests 证明五类 public results 与两条错误规则真的成立。

### Test A：line-based replies

至少检查：

```text
encode_resp_simple_string("OK")
    == "+OK\r\n"

encode_resp_error("ERR unknown command")
    == "-ERR unknown command\r\n"

encode_resp_integer(-12)
    == ":-12\r\n"
```

### Test B：binary Bulk String

输入：

```text
{'A', '\0', 'B'}
```

oracle：

```text
output size == 9
output exact bytes == "$3\r\nA\0B\r\n"
```

构造 expected string 时必须带 explicit length，不能让 C-string constructor 在 `\0` 处停止。

### Test C：null 与 invalid line payload

至少检查：

```text
null bulk exact bytes
simple string 含 '\r' 时 exact exception type/message
error 含 '\n' 时 exact exception type/message
```

这三组 tests 是 encoder 的核心，不是额外项目包装；它们分别证明 type marker、binary length 与 framing rejection。

---

## 16. Round1 CMake integration

现有根 `CMakeLists.txt` 已经有：

```cmake
enable_testing()
find_package(GTest REQUIRED)
include(GoogleTest)
```

在文件后面新增：

```cmake
# RESP reply encoder
add_library(resp_encoder
    src/resp_encoder.cpp
)

target_include_directories(resp_encoder PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include/resp
)

target_compile_options(resp_encoder PRIVATE
    -Wall
    -Wextra
    -g
)

add_executable(resp_encoder_test
    tests/resp_encoder_test.cpp
)

target_compile_options(resp_encoder_test PRIVATE
    -Wall
    -Wextra
    -g
)

target_link_libraries(resp_encoder_test PRIVATE
    resp_encoder
    GTest::gtest_main
    GTest::gtest
)

gtest_discover_tests(resp_encoder_test)
```

这是 mechanical build glue，不是今天要求你重新设计 CMake。

---

## 17. Round1 编译与运行

从 canonical project root 执行：

```bash
cmake -S . -B build
cmake --build build -j2
```

先直接运行 focused executable：

```bash
./build/resp_encoder_test
```

再运行固定全量入口：

```bash
cmake -E chdir build ctest --output-on-failure
```

本次新增 target 与旧 Reactor/HTTP targets 都必须：

```text
compile success
零 warning
CTest PASS
```

若只 build `resp_encoder_test`，不要直接把随后全量 CTest 的 `NOT_BUILT` 当作旧功能回归；正式验收前 build 全项目。

---

## 18. Round1 允许的独立设计空间

以下内容由你自己决定：

```text
是否写一个 private/internal CRLF validation helper
使用 operator+=、append、reserve 或其他 std::string API
integer 使用 std::to_string 还是其他 C++17 conversion
每个 function 直接构造结果，还是复用小 helper
tests 怎样分组命名
```

只要 public behavior、exception contract、ownership 与 exact bytes 满足本教程即可。

R1 不要求：

```text
一次分配完成所有 output
手写 integer conversion
通用 serializer hierarchy
zero-copy reply chain
microbenchmark
```

---

## 19. Round1 成功标准

```text
[ ] 三个文件创建在规定目录
[ ] 五个 public functions 与 header 一致
[ ] Simple String / Error / Integer exact bytes 正确
[ ] Bulk String 使用 explicit byte length，embedded NUL 不截断
[ ] Null Bulk String 与 empty Bulk String 没有混淆
[ ] Simple String / Error 的 CR/LF 输入按 exact contract 抛错
[ ] returned std::string 独立拥有 encoded bytes
[ ] CMake target 进入现有 build graph
[ ] -Wall -Wextra -g 零 warning
[ ] focused test PASS
[ ] 全量 CTest PASS
```

---

## 20. Round1 阅读闸门

**现在停在这里。**

先完成：

```text
resp_encoder.hpp
resp_encoder.cpp
resp_encoder_test.cpp
CMake integration
```

然后把 R1 source、tests、运行结果和你的 note 交给我检阅。

R1 正式通过后，我会以你的真实实现为基线：

```text
保留你在 daily 中增加的内容
逐节检查 R2/R3 与你的 representation 是否一致
明确指出需要升级的真实边界
删除已经被你的实现证明、继续阅读只会重复的部分
```

不要在实现前继续阅读 Round2/3。下面开始解释完整机制与最终复检。

---

# Round 2：从 wire bytes 反推五类 reply 的设计

## 21. 第一个 byte 为什么足以区分类型

RESP payload 的第一个 byte 是 `type marker（类型标记）`：

```text
'+' -> Simple String
'-' -> Error
':' -> Integer
'$' -> Bulk String 或 Null Bulk String
'*' -> Array，今天不编码
```

client 收到 bytes 时不需要先猜 command：

```text
读取第一个 byte
-> 选择对应 decoding rule
-> 按该规则找到当前 reply 结束位置
```

这解释了第一个问题：**reply type 是 wire format 自己携带的信息。**

command 决定 server 应该选择哪一种 reply；marker 让 client 知道 server 实际发送的是哪一种。

---

## 22. Simple String：低开销的短状态文本

Simple String 的形状：

```text
+<text>\r\n
```

`SET` 成功通常只需要表达一个短状态：

```text
+OK\r\n
```

它不需要额外 length field，overhead 很小。代价是 payload 自己不能含 CR 或 LF，因为 client 正是靠 CRLF 找结束位置。

所以 encoder 的工作不是“给任意 string 加 `+`”：

```text
先证明 payload 不含 CR/LF
-> 添加 '+'
-> 添加 payload
-> 添加 CRLF
```

这里的验证属于 encoder contract，因为只有 encoder 知道 caller 正在选择 line-based wire form。

---

## 23. Error：wire shape 相似，client action 不同

Error 的形状：

```text
-<message>\r\n
```

它和 Simple String 都以 CRLF 结束，所以有相同的 CR/LF payload restriction。

区别是第一个 byte：

```text
'+' -> client 把结果当成功值
'-' -> client 把结果当 error
```

例如：

```text
-ERR unknown command\r\n
```

按 convention，message 的第一个 space-delimited word 表示 error category，例如 `ERR`。今天 encoder 不替 caller决定 category；未来 command layer 负责传入稳定完整的 message。

这保持了责任边界：

```text
command layer：决定为什么失败、message 是什么
encoder：决定 error message 怎样变成 RESP bytes
```

---

## 24. Integer：decimal text 也是明确的 protocol representation

Integer reply 的形状：

```text
:<signed decimal integer>\r\n
```

例如：

```text
:0\r\n
:2\r\n
:-12\r\n
```

虽然 wire 上仍然是 ASCII decimal bytes，client 解码后会把它当 integer，而不是 string。

本日 API 使用：

```cpp
std::int64_t
```

所以 V1 的完整 input domain 是：

```text
INT64_MIN ... INT64_MAX
```

不要给负数添加业务限制。未来 `DEL/EXISTS` 正常只产生非负结果，但 encoder 是 protocol component，应正确表示整个 signed integer domain。

---

## 25. Bulk String：length prefix 让 payload 保持原样

Bulk String 的形状：

```text
$<N>\r\n<payload of exactly N bytes>\r\n
```

`N` 来自：

```cpp
value.size()
```

不是：

```cpp
std::strlen(value.data())
```

对 payload `A\0B`：

```text
value.size() == 3
```

encoded layout：

```text
offset 0      '$'
offset 1      '3'
offset 2..3   '\r' '\n'
offset 4..6   'A' '\0' 'B'
offset 7..8   '\r' '\n'
```

总长度为：

$$1 + \operatorname{digits}(N) + 2 + N + 2$$

当 $N=3$ 时，总长度是 9 bytes。

这里 `\0` 只是 payload 中普通的一个 byte。因为 `std::string_view` 保存 explicit size，encoder 不需要也不应该寻找 null terminator。

这解释了第二、三个问题：

```text
line-based reply -> CRLF 定界
bulk reply       -> length 定界 payload，再检查 final CRLF
binary-safe      -> payload 不参与 boundary search
```

---

## 26. Empty Bulk 与 Null Bulk 为什么不是一回事

empty value：

```text
$0\r\n\r\n
```

含义：

```text
value 存在
value length == 0
```

null value：

```text
$-1\r\n
```

含义：

```text
没有 value
```

未来：

```text
SET empty ""
GET empty
-> $0\r\n\r\n

GET missing
-> $-1\r\n
```

如果 encoder 把两者都返回 empty `std::string`，command layer 与 client 就无法区分“存在但为空”和“不存在”。

这也是为什么 Day1 使用两个 public functions：

```text
encode_resp_bulk_string("")
encode_resp_null_bulk_string()
```

---

## 27. `std::string_view` 与 returned `std::string` 的 ownership

调用：

```cpp
const std::string input = "hello";
const std::string wire = encode_resp_bulk_string(input);
```

对象关系：

```text
input
    owns "hello"

function parameter string_view
    temporarily observes input bytes
    does not own them

wire
    owns "$5\r\nhello\r\n"
```

函数返回后，parameter `string_view` 消失。`wire` 不能依赖 `input` 继续存活，因为之后它会被保存进 Connection output Buffer。

这解释了第四个问题：

> **input range 由 caller 拥有；encoder 在调用期间读取；returned string 独立拥有 wire bytes。**

因此这些函数不能标 `noexcept`：构造 returned `std::string` 需要分配 memory，allocation 可能失败。

---

## 28. 为什么 Day1 不先造通用 `RespValue`

可以设计一个通用 object：

```text
RespValue
    type
    string payload
    integer payload
    array payload
    nested values
```

但今天的 V1 replies 只需要五个明确操作，当前 request parser 也只接受一层 Array of Bulk Strings。

现在引入递归 variant/class hierarchy 会同时增加：

```text
invalid object state
visitor/dispatch syntax
nested allocation
与本周 commands 无关的 Array reply design
```

所以 Day1 采用五个 functions，把 protocol behavior 先做成可执行证据。未来真正出现 Array reply 或统一 reply object 的需求，再根据调用方压力升级。

这是保守设计，不是拒绝 abstraction：**先让 abstraction 对应真实变化轴。**

---

## 29. 今天的 encoder 怎样接入后续 days

Day2/3：

```text
只做 request parser
不会修改 Day1 encoder
```

Day4：

```text
dispatcher 执行 command
-> 根据语义选择 encoder function

SET success  -> simple string
GET hit      -> bulk string
GET miss     -> null bulk
DEL/EXISTS   -> integer
wrong arity  -> error
```

Day5：

```text
encoded std::string
-> Connection::send(wire.data(), wire.size())
-> output Buffer 拷贝并拥有 pending bytes
```

所以 Day1 的 returned owning string 是 application 与 transport 之间的一段稳定交接物。

---

## 30. 当前复杂度边界

设 Bulk String payload length 为 $N$。

encoder 至少需要把 $N$ 个 payload bytes 放进 returned result，所以时间和 output storage 都是：

$$O(N)$$

今天不做：

```text
scatter/gather write
iovec
zero-copy reply fragments
small-string optimization benchmark
custom allocator
```

`reserve()` 可以减少中间 reallocations，但它不是 correctness 条件。先用 tests 证明 exact bytes，再谈 allocation behavior。

---

# Part 3：收尾、Round3 与验收

## 31. Round3：从“几个例子正确”升级成稳定 component

R1 通过后，不重写 encoder。只在同一 test file 补齐能够暴露边界的 matrix。

### 31.1 Simple String matrix

```text
"OK"       -> "+OK\r\n"
"PONG"     -> "+PONG\r\n"
""         -> "+\r\n"
"A\rB"     -> exact invalid_argument
"A\nB"     -> exact invalid_argument
```

### 31.2 Error matrix

```text
"ERR bad"  -> "-ERR bad\r\n"
"WRONGTYPE Operation against a key" -> exact bytes
message 含 CR/LF -> exact invalid_argument
```

### 31.3 Integer matrix

```text
0
1
-1
INT64_MAX
INT64_MIN
```

这里只验证 decimal encoding，不把未来 command 的业务 range 塞进 encoder。

### 31.4 Bulk String matrix

```text
empty payload
ordinary ASCII
embedded NUL
payload 内含 CRLF
non-ASCII UTF-8 bytes
```

Bulk String 的 oracle 是 exact bytes 和 exact total size，不是 terminal 显示。

### 31.5 Null Bulk

```text
exact "$-1\r\n"
与 empty bulk "$0\r\n\r\n" 明确不同
```

---

## 32. Tests 分别证明什么

| Test | 能证明 | 不能单独证明 |
|---|---|---|
| exact string compare | marker、decimal text、CRLF 与 payload 顺序正确 | socket 能发送完整 reply |
| embedded NUL case | encoder 按 explicit length 复制 bytes | parser 能读取 binary request |
| exception type/message | invalid line payload 被稳定拒绝 | 整个 server 的 error policy |
| INT64 boundary | protocol integer conversion 覆盖完整 API domain | DEL/EXISTS 业务计数一定正确 |
| full CTest | 新 target 没破坏已有 test graph | 未覆盖输入全部正确 |

不要把“ASan 没报错”当成 wire format 正确；也不要把 exact-byte test 通过当成 network integration 已完成。

---

## 33. Sanitizer 边界

Day1 component 只有 pure memory transformation，normal build + exact tests 是第一证据。

R1/Round3 完成后，可以用独立 build 运行：

```text
ASan：观察 covered paths 是否有越界/use-after-free
UBSan：观察 covered paths 是否有 undefined behavior report
```

TSan 不属于今天：

```text
没有新 thread
没有 shared mutable state
没有 synchronization contract
```

sanitizer clean 只说明实际执行路径没有观察到对应报告；protocol correctness 仍由 exact-byte tests 证明。

---

## 34. 今日验收问题

这些问题可以用代码、tests 或口述回答，不要求机械抄写。

1. 为什么 `+OK\r\n` 的第一个 byte 和最后两个 bytes 都不能省？
2. Simple String 与 Bulk String 分别怎样找到 payload boundary？
3. 为什么 `A\0B` 的 Bulk String length 是 3？
4. `$0\r\n\r\n` 与 `$-1\r\n` 分别表达什么？
5. 为什么 Error 与 Simple String wire shape 相似，但 client behavior 不同？
6. 为什么 encoder parameter 可以是 `string_view`，返回值却应是 owning `string`？
7. 为什么今天不需要通用递归 `RespValue`？
8. exact-byte tests、full CTest 与 ASan 各自能证明什么？

---

## 35. 今日完成标准

### R1 必须完成

```text
五个 encoder functions
三组核心 tests
CMake/CTest integration
零 warning build
full CTest PASS
```

### R1 正式通过后完成

```text
按真实实现定向阅读 Round2
补 Round3 高价值 edge matrix
必要时运行 ASan/UBSan focused evidence
```

### 今天明确不做

```text
RESP Array encoder
request parser
command execution
KV store
socket integration
性能 benchmark
README / interview answer
```

---

## 36. Note 只记录真正的新东西

不要求复制本教程。建议只留下：

```text
我最终采用的 implementation shape
一个我原先会混淆的 wire boundary
binary Bulk test 的 expected/actual
Questions
```

如果代码与 tests 已经精确证明五类输出，不再把每个 case 抄写一遍。

---

## 37. 明天怎样接上

今天解决输出方向：

```text
typed result
-> exact RESP reply bytes
```

Day2 转向输入方向：

```text
arbitrary TCP bytes
-> NeedMore / Complete / Error
-> command arguments + consumed_bytes
```

真正的新问题会是：

```text
Array 声明有几个 elements
Bulk String 声明每个 argument 有多少 bytes
当前 bytes 不足时为什么只能 NeedMore
一条 command 后已有下一条 suffix 时为什么不能多消费
```

Day1 encoder 保持纯函数，不因为 Day2 parser 到来而重新设计。

---

## 38. 今日压缩记忆

```text
RESP reply 的第一个 byte 标识 type。
Simple String 和 Error 用 CRLF 结束，所以 payload 不含 CR/LF。
Integer 用 signed decimal text。
Bulk String 用 explicit byte length，所以可以保存任意 bytes。
Empty Bulk 表示存在但为空；Null Bulk 表示不存在。
string_view 只借用 input；returned string 独立拥有 wire bytes。
```

---

## 39. 本日资料

主资料：

- [Redis Serialization Protocol specification](https://redis.io/docs/latest/develop/reference/protocol-spec/)

定向阅读范围：

```text
RESP protocol description
Simple strings
Simple errors
Integers
Bulk strings
Null bulk strings
```

看到 Arrays 标题即可停止。Array request parsing 属于 Day2，不在 Day1 提前展开。

本教程正文已经包含 R1 所需 contract；官方资料用于核验 exact wire format，不要求先完整通读再开工。
