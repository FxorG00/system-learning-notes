# Week14 Day1：把状态变化变成可重放的 RESP 记录

> 版本：2026-11-02，R1 已以 98/100 正式通过；下一步进入 R2
> 前置：Week13 整周已通过，Mini Redis V2 已有 RESP parser、dispatcher、KvStore 与 TTL
> 今日产出：不打开文件、不接服务器；只把已经确认的状态变化编码成独立、按字节保存的 RESP 记录
> 学习方式：R1 独立实现记录编码；R2 让 reply 与可持久化事实一起返回；R3 再统一相对期限与失败边界

[TOC]

---

# Part 1：前情提要

## 1. 今天只干一件事

**把一条已经确认的状态变化，变成以后可以重新执行的 bytes。**

先看你现在已经能完成的调用：

```text
客户端发送：SET code 1234
parser 得到：{"SET", "code", "1234"}
dispatcher 修改：KvStore["code"] = "1234"
server 回复：+OK\r\n
```

只要进程还活着，后面的 `GET code` 就能读到 `1234`。

但进程结束以后，`KvStore` 对象也消失。新进程只知道自己启动了，并不知道旧进程曾经执行过这次 `SET`。

今天先留下这样一段记录：

```text
*3\r\n
$3\r\n
SET\r\n
$4\r\n
code\r\n
$4\r\n
1234\r\n
```

真实内存里，它是一段连续 bytes。后面新进程把它交给现有 RESP parser，就能重新得到：

```text
{"SET", "code", "1234"}
```

Day3 才会真的执行这次恢复。今天只负责把记录造对。

## 2. 为什么不是把所有 request 都保存下来

连续发生四件事：

```text
SET code old
GET code
PTTL code
SET code new
```

退出前需要恢复的逻辑状态是：

```text
code -> new
并且没有 TTL
```

`GET` 和 `PTTL` 只观察状态。重启时再执行它们，不会帮助新 `KvStore` 长回旧状态。

因此今天先分成两类：

| 动作 | 是否需要恢复 | 今天怎样处理 |
|---|---:|---|
| 成功 `SET` | 是 | 留下 `SET key value` 记录 |
| 实际删除了有效 key 的 `DEL` | 是 | 留下原 key 顺序的 `DEL` 记录 |
| 成功设置期限的 `EXPIRE` | 是 | 后面转换成绝对到期时刻再记录 |
| `PING/ECHO/GET/EXISTS/PTTL` | 否 | 不产生记录 |

这张表先回答“哪些事实要带进新进程”。至于一次 `DEL` 或 `EXPIRE` 到底有没有生效，R2 会接着处理。

## 3. 三条时间线决定记录必须表达什么

### 3.1 两次覆盖必须保持顺序

```text
SET k old
SET k new
```

如果新进程按原顺序重做：

```text
空 store
-> k = old
-> k = new
```

最终状态正确。

如果记录顺序颠倒，最后会错误地得到 `old`。所以记录不只是保存参数，还要保留状态变化发生的顺序。

### 3.2 删除也必须留下

```text
SET k value
DEL k
```

只保存 `SET`，新进程会让已经删除的 key 重新出现。

因此有效的删除也是一条需要重做的状态变化。

### 3.3 相对期限不能原样留下

假设 12:00:00 执行：

```text
SET code 1234
EXPIRE code 120
```

原期限是 12:02:00。

如果 12:01:00 重启以后再执行一次 `EXPIRE code 120`，期限会被错误地延长到 12:03:00。

所以日志里不能把相对的“再活 120 秒”原样保存。它要写成类似：

```text
PEXPIREAT code 绝对的 Unix 毫秒时刻
```

`PEXPIREAT` 在这里表示“让 key 在某个绝对毫秒时刻到期”。

Unix 毫秒时刻是从 1970-01-01 00:00:00 UTC 起累计的毫秒数。它不随某个 Mini Redis 进程重新启动而归零。

R1 不计算这个时刻。R1 只提供一个明确入口：**给我已经算好的绝对到期时刻，我把它编码成记录。**

真正的双时钟转换留在 Week14 Day4。

## 4. 现在再给这两个动作命名

**AOF（Append-Only File，追加式文件）**：不断在文件末尾记录写操作；新进程启动时按顺序重新执行这些记录。

**Replay（重放）**：新进程读取旧记录，并把其中的状态变化重新应用到空 `KvStore`。

今天还没有 file，也没有 replay loop。我们只造 replay 将来要消费的一条记录。

[小林 Coding 的 AOF 讲解](https://xiaolincoding.com/redis/storage/aof.html#aof-%E6%97%A5%E5%BF%97)可以帮助建立“记录写操作，启动时再执行”的第一层直觉。

[Redis 官方持久化说明](https://redis.io/docs/latest/management/persistence/)用于校准边界：真实 Redis 用协议格式记录写操作，并提供本周不实现的同步策略、重写与多文件机制。

## 5. 四个主问题，贯穿今天

1. 一条记录为什么要保存命令名、参数数量和每个参数的 byte length？
2. key/value 里含 `\0` 或 `\r\n` 时，怎样保证恢复后一个 byte 都不变？
3. `DEL b a b` 为什么不能在编码时排序或去重？
4. 为什么今天只接收绝对期限，不在 encoder 里读取时钟？

R1 完成这四点的编码主链。R2/R3 再把它接到命令执行结果。

---

# Part 2：教程开始

## 6. 这个组件处在现有服务器的哪里

你当前的请求链是：

```text
Connection input bytes
-> RespRequestParser
-> vector<string> arguments
-> execute_command
-> KvStore 改变或保持
-> RESP reply bytes
-> Connection output
```

今天在“状态已经确认改变”之后增加一个纯函数组件：

```mermaid
flowchart LR
    A["完整 command arguments"] --> B["dispatcher 执行"]
    B --> C["KvStore 状态改变"]
    C --> D["AOF record encoder"]
    D --> E["独立的 RESP record bytes"]
    E --> F["Day2 才交给 file writer"]
    B --> G["原 RESP reply"]
```

图里的 encoder 不拥有 `KvStore`，也不拥有文件描述符。

它借用 key/value，返回自己拥有的 `std::string`。调用结束后，即使原 arguments 被销毁，返回的记录 bytes 仍然存在。

它运行在服务器进程的用户态。今天没有 system call，也没有 kernel page cache（内核页缓存）参与。

## 7. 为什么继续使用 RESP Array of Bulk Strings

客户端请求本来就是：

```text
Array
├─ Bulk String：command name
├─ Bulk String：argument 1
└─ Bulk String：argument 2 ...
```

例如 `SET code 1234`：

```text
*3\r\n              # 一共有 3 个元素
$3\r\nSET\r\n        # 第 1 项有 3 bytes
$4\r\ncode\r\n       # 第 2 项有 4 bytes
$4\r\n1234\r\n       # 第 3 项有 4 bytes
```

`$<length>` 的 length 数的是 bytes。parser 因此不需要在 payload（实际数据段）里寻找分隔符。

这正好适合已经支持的二进制 key/value：

```cpp
const std::string key{"k\0x", 3};
const std::string value{"v\r\nz", 4};
```

`\0` 和 payload 里的 CRLF 都只是数据。真正边界由前面的长度决定。

[Redis RESP 规范](https://redis.io/docs/latest/develop/reference/protocol-spec/)明确把客户端命令表示为 Bulk String 数组，并用长度前缀保持 binary-safe（按字节安全）。

## 8. Round1：新增独立的记录编码组件

### 8.1 文件与职责

Ubuntu 工程仍是：

```text
/home/xgf/code/system-learning/cpp/week10
```

本轮新增：

| 文件 | 只负责什么 |
|---|---|
| `include/mini_redis/aof_record.hpp` | 声明三种允许进入日志的记录入口 |
| `src/aof_record.cpp` | 把记录编码成 RESP Array of Bulk Strings |
| `tests/aof_record_test.cpp` | exact bytes 与 parser round-trip（编码后再解析回原参数）证据 |
| `CMakeLists.txt` | 新增 library 与测试 target |

保持不动：

- `command_dispatcher.cpp`
- `kv_store.cpp`
- `mini_redis_server.cpp`
- 原 parser、Connection 与 EventLoop

Day1 没有 AOF 文件路径，也不打开文件。文件 owner 从 Day2 才出现。

### 8.2 Public contract（公开接口约定）

`aof_record.hpp` 的公开接口固定为：

```cpp
#pragma once

#include <cstdint>
#include <string>
#include <string_view>
#include <vector>

std::string encode_aof_set(
    std::string_view key,
    std::string_view value);

std::string encode_aof_del(
    const std::vector<std::string>& keys);

std::string encode_aof_pexpireat(
    std::string_view key,
    std::int64_t unix_deadline_ms);
```

三个函数回答同一个问题：**如果上层已经确认发生了这类状态变化，写进日志的一条完整记录是什么？**

| 函数 | 输入 | 返回 | 不负责 |
|---|---|---|---|
| `encode_aof_set` | exact key/value bytes | `SET key value` 的独立 RESP bytes | 不修改 store，不判断 SET 是否成功 |
| `encode_aof_del` | 一个或多个 key，保持原顺序 | `DEL key...` 的独立 RESP bytes | 不查询哪些 key 当前存在 |
| `encode_aof_pexpireat` | key 与非负 Unix 毫秒时刻 | `PEXPIREAT key timestamp` 的独立 RESP bytes | 不读取时钟，不计算相对 TTL |

这里故意没有 `encode_aof_get`、`encode_aof_ping` 或 `encode_aof_pttl`。这些命令不创造需要恢复的状态。

这里也故意没有 `encode_aof_expire(key, seconds)`。相对秒数不能直接成为跨重启记录。

### 8.3 输入的所有权与返回值寿命

`std::string_view` 表示函数只在调用期间借用 key/value 的 byte range。

`const std::vector<std::string>&` 表示函数只在调用期间观察 DEL 的 keys，不复制或重排调用者的 vector。

返回类型是 `std::string`。它拥有完整记录：

```cpp
std::string make_record() {
    const std::string key{"k\0x", 3};
    const std::string value{"v\r\nz", 4};
    return encode_aof_set(key, value);
}

const std::string record = make_record();
// key 和 value 已销毁，record 仍拥有完整 bytes。
```

encoder 不能把 `string_view.data()` 保存到成员中，也不能返回指向输入的 pointer。

### 8.4 R1 的合法输入边界

R1 先完成合法路径：

- SET 接收任意 byte 内容的 key/value，包括空字符串、`\0` 和 CRLF。
- DEL 至少有一个 key，并保持数量、顺序和重复项。
- PEXPIREAT 接收非负 `std::int64_t` 绝对毫秒时刻。
- 输出必须是现有 `RespRequestParser` 能完整解析的一条记录。

空 DEL、负绝对时刻和超出 parser 上限的记录属于最终错误边界。R3 再统一补齐，不要求 R1 开始前同时处理。

## 9. 从三个具体调用读懂结果

### 9.1 SET：payload 里的特殊字节不能改变边界

```cpp
const std::string key{"k\0x", 3};
const std::string value{"v\r\nz", 4};

const std::string record = encode_aof_set(key, value);
```

预期 bytes 可以这样构造：

```cpp
const std::string expected =
    "*3\r\n"
    "$3\r\nSET\r\n"
    "$3\r\n" + key + "\r\n" +
    "$4\r\n" + value + "\r\n";
```

重点不是肉眼打印它。`\0` 可能让普通 C 字符串输出看起来提前结束。

真正证据是：

```text
record.size() 与 expected.size() 相等
record 每个 byte 与 expected 相等
parser 重新得到原 key/value
consumed_bytes == record.size()
```

### 9.2 DEL：顺序和重复项都属于原命令

```cpp
const std::vector<std::string> keys{"b", "a", "b"};
const std::string record = encode_aof_del(keys);
```

它表示：

```text
{"DEL", "b", "a", "b"}
```

数组元素数是 4，不是 3。command name 也占一个元素。

encoder 不排序，不去重。是否有 key 真被删除，由执行命令的上层决定；记录层只保存已经选定的状态变化及其原参数顺序。

### 9.3 PEXPIREAT：输入已经是绝对时刻

```cpp
const std::string record =
    encode_aof_pexpireat("code", 1'800'000'000'000LL);
```

parser 应重新得到：

```text
{"PEXPIREAT", "code", "1800000000000"}
```

encoder 做的是整数转十进制文本和 RESP 编码。

它没有权限自行调用 `steady_clock` 或 `system_clock`。否则同一输入可能因为调用时间不同而得到不同记录，组件也会同时混入时间策略。

[Redis EXPIRE 文档](https://redis.io/docs/latest/commands/expire/)说明过期信息以绝对 Unix 时间保存。我们的 Day4 会在自己的时钟模型里实现对应转换，不把真实 Redis 的全部实现直接搬进来。

## 10. R1 最小实现路线

先不要写 dispatcher 接线。按下面顺序完成组件：

1. 写出三个公开函数的声明。
2. 先让 `encode_aof_set("code", "1234")` 产生 exact bytes。
3. 把“命令名 + operands”收进同一个内部编码路径，避免三份长度逻辑。
4. 用同一路径完成 DEL，确认顺序和重复项保留。
5. 把绝对毫秒整数转成十进制 argument，完成 PEXPIREAT。
6. 用现有 parser 做一次 round-trip，确认输出真能成为未来的输入。

内部 helper、局部容器和拼接方式由你决定。

可以复用已有 `encode_resp_bulk_string()`。但最终数组元素数要由本条记录的实际参数数决定，不能把 payload 当 C 字符串，也不能用 `strlen` 计算 `std::string_view` 的长度。

## 11. R1 测试要证明什么

下面三项是核心 oracle（判定依据）。测试代码是机械脚手架；你需要能解释每项为什么成立。

### 11.1 SET exact bytes 与 round-trip

初始输入：

```cpp
key   = std::string{"k\0x", 3}
value = std::string{"v\r\nz", 4}
```

必须同时证明：

- exact record bytes 相等；
- parser 返回 `Complete`；
- arguments 精确等于 `SET`、原 key、原 value；
- `consumed_bytes == record.size()`。

这证明长度前缀决定边界，payload 中的 `\0` 和 CRLF 没有被误当作终止符。

### 11.2 DEL 保留参数序列

输入：

```text
b, a, b
```

解析后必须仍是：

```text
DEL, b, a, b
```

这证明 encoder 没有替命令层排序、去重或判断存在性。

### 11.3 PEXPIREAT 不保存相对秒数

输入绝对时刻 `1800000000000`。

解析后 command name 必须是 `PEXPIREAT`，最后一个 argument 必须是同一个十进制绝对毫秒值。

这个测试不能证明 wall clock 转换正确。它只证明 encoder 没有把接口悄悄退回相对 `EXPIRE`。

## 12. CMake 接入

在现有 `CMakeLists.txt` 的 Mini Redis 组件区域追加：

```cmake
add_library(aof_record
    src/aof_record.cpp
)

target_include_directories(aof_record PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include/mini_redis
)

target_compile_options(aof_record PRIVATE
    -Wall
    -Wextra
    -g
)

target_link_libraries(aof_record PRIVATE
    resp_encoder
)

add_executable(aof_record_test
    tests/aof_record_test.cpp
)

target_compile_options(aof_record_test PRIVATE
    -Wall
    -Wextra
    -g
)

target_link_libraries(aof_record_test PRIVATE
    aof_record
    resp_request_parser
    GTest::gtest_main
    GTest::gtest
)

gtest_discover_tests(aof_record_test PROPERTIES TIMEOUT 5)
```

`aof_record` 的 public header 只暴露自己的三项函数，所以对 `resp_encoder` 使用 `PRIVATE` 即可。测试额外链接 parser，只为了验证 round-trip。

今天不把 `aof_record` 链进 `command_dispatcher` 或 `mini_redis_server`。R1 的独立边界因此仍然可见。

## 13. Round1 Reading Gate

完成 R1 后先停，不继续接文件或 server。

你应能回答：

1. 为什么 `SET k same` 即使 value 与旧值相同，将来仍可能需要记录？
2. 为什么 `GET/PTTL` 不应产生 AOF 记录？
3. 为什么 `DEL b a b` 的 encoder 不能排序或去重？
4. `encode_aof_pexpireat` 为什么只接收绝对时刻，而不读取 clock？
5. exact-byte 比较与 parser round-trip 分别证明什么？

R1 的 PASS 条件：

- 三个公开入口均能生成一条完整记录；
- SET 对 `\0` 与 CRLF 保持 exact bytes；
- DEL 保持参数序列；
- PEXPIREAT 明确保存绝对毫秒文本；
- 三类记录均被现有 parser 完整解析；
- 没有打开文件，没有修改 store，没有接网络。

---

## 14. Round2：上层需要同时拿到 reply 和持久化事实

R1 只处理合法输入：上层已经选定一种状态变化，encoder 负责把它编码正确。这个结论已经通过，不重做。

现在开始接回 handler，才会遇到一个 R1 不需要处理的新问题：encoder 也可能失败。R2/R3 要补的是命令结果的表示和最终接入顺序，不修改 R1 的三个函数与既有测试。

R1 已经把一件事情做完整了：上层给出已经选定的命令和参数，encoder 就返回一条自己拥有的 RESP record。

你的实际实现沿着同一条路径工作：

```text
SET / DEL / PEXPIREAT 的参数
-> 组成本次调用的局部 vector<string>
-> .cpp 内部 helper 编码 Array of Bulk Strings
-> 返回独立 std::string
```

helper 已放进 `aof_record.cpp` 的匿名命名空间。public header 只保留三个业务入口。这个边界说明 R1 只负责“怎样编码”，没有决定“本次命令是否值得记录”。

### 14.1 R2 最终要补出的结果是什么

你现在的 `execute_command()` 只返回 reply bytes：

```cpp
std::string execute_command(
    KvStore& store,
    const std::vector<std::string>& arguments);
```

客户端能收到回复，但 application owner（应用层拥有者）拿不到“这次成功命令是否还要留下恢复记录”。R2 要让一次调用产生两个彼此独立的结果：

```text
CommandOutcome
├─ reply
│  └─ 准备发给客户端的 RESP bytes
└─ persistence
   ├─ none：这次没有需要恢复的写操作
   └─ change：这次成功写操作需要留下什么
```

可以把它想成下面这个形状。它是结构示意，不是要求直接复制的可编译接口：

```text
CommandOutcome {
    reply: std::string
    persistence: none 或一份 PersistenceChange
}
```

`PersistenceChange` 只是“这次要留下什么”的占位名字，不要求照抄。先把两份结果交给调用者，再根据当前代码选择最小表示；R2 不要求设计通用命令层级或事件系统。

R2 的硬要求只有一个：**reply 和持久化事实不能再混成一条协议字符串。**

先看四次具体调用：

| 调用 | `reply` | `persistence` |
|---|---|---|
| `SET code 1234` | `+OK` | `SET code 1234` |
| `DEL missing`，删除数为 0 | `:0` | `none` |
| `DEL code missing`，`code` 被删 | `:1` | 原顺序的 `DEL code missing` |
| `GET code` | bulk string 或 null | `none` |

`reply` 不能替代右边的信息。`:1` 既可能来自 `DEL`，也可能来自 `EXPIRE`；它没有 key，也没有原参数。把 reply 再 parse 一遍，仍然还原不出待恢复的写操作。

### 14.2 为什么 `SET code 1234` 即使 value 相同也要记录

先准备：

```text
value = 1234
deadline = 12:01:00
```

现在执行：

```text
SET code 1234
```

执行后：

```text
value = 1234
deadline = none
```

value bytes 没变，但旧 TTL 被清除了。若不记录这次 `SET`，重放后 `code` 仍会在旧期限到达时消失。

因此本项目采用明确规则：**合法 `SET` 成功后总是产生 SET 持久化事实，不比较新旧 value 是否相同。** 这不是说每次 value bytes 都变化，而是说成功 SET 建立了“这个 value，并且没有旧 TTL”的状态。

这个场景的最小测试要观察四件事：

```text
操作前：value=1234，存在 TTL
执行：SET code 1234
reply：+OK
操作后：value=1234，TTL 已清除
persistence：存在，并能 parse 回 SET code 1234
```

### 14.3 DEL、EXPIRE 和只读命令分别怎样判断

沿 handler 已经得到的真实结果判断，不从 reply 倒推：

| 命令 | handler 已知的事实 | R2 应交给 owner 的结果 |
|---|---|---|
| 合法 `SET k v` | SET 成功 | `reply=+OK`，持久化 SET |
| `DEL a b` 返回大于 0 | 至少一个有效 key 被删除 | 整条原顺序 DEL |
| `DEL a b` 返回 0 | 没有 key 被删除 | `none` |
| `EXPIRE k n` 返回 1 | 期限真的改变，或 key 被立即删除 | 交给 R3 规范化 |
| `EXPIRE k n` 返回 0 | 缺失或已失效 key 没有改变 | `none` |
| `GET/PTTL/PING` | 只读取或生成回复 | `none` |
| 参数、范围或协议错误 | 没有进入成功写路径 | 错误 reply，`none` |

R2 可以先用三组测试闭合信息传递：

1. 相同 value 但带旧 TTL 的 SET：仍有持久化事实。
2. `DEL missing`：reply 为 0，持久化事实为空。
3. `GET code`：能返回 value，但持久化事实为空。

R2 仍不打开文件。它只保证 application owner 不再丢失“该不该记录、记录什么”这份内部事实。

## 15. Round3：逐个收紧不能进入日志的情况

R3 不再学习另一个大组件。它只把 R2 的成功路径放到五个具体反例下检查。

最终顺序必须是：

```text
验证命令与记录能否表示
-> 在局部变量里准备完整候选 record
-> 准备成功后才修改 store
-> 根据真实执行结果保留或丢弃候选 record
-> 返回 reply + 可选持久化信息
```

这条顺序在 Day1 可以完整用于 SET、DEL 和已经拿到绝对时刻的 PEXPIREAT。正数 `EXPIRE` 目前只保留“期限修改成功、等待绝对时刻”的事实；Day4 补出绝对时刻后，才闭合它的候选 record。

“准备完整”不表示写入文件。Day1 还没有 fd；它只保证 encoder 失败时，内存状态与成功回复都尚未提交。

### 15.1 正数 `EXPIRE` 不能原样写进日志

假设 12:00:00 执行：

```text
EXPIRE code 120
```

它表达的实际期限是 12:02:00。若日志保存原文字，12:01:00 重启后会重新得到 120 秒，错误延期到 12:03:00。

所以成功的正数 `EXPIRE` 必须经过：

```text
EXPIRE code 120
-> 得到原本的绝对日历到期时刻
-> PEXPIREAT code <absolute_wall_deadline_ms>
```

Day1 已经能验证最后一步：

```cpp
const auto record = encode_aof_pexpireat("code", 1'800'000'000'000LL);
const auto parsed = parse_one(record);

EXPECT_EQ(parsed.arguments[0], "PEXPIREAT");
EXPECT_EQ(parsed.arguments[1], "code");
EXPECT_EQ(parsed.arguments[2], "1800000000000");
```

这里的 `parse_one` 表示复用现有 parser 取得一条 Complete request，名称按你的测试 helper 调整。

这个 test 证明 encoder 的入口是绝对时刻，**不能证明 120 秒怎样换成该时刻**。真正的日历时钟与单调时钟转换仍由 Day4 使用固定时钟测试。

在 Day4 提供绝对时刻以前，R2 可以保留“这次期限修改成功、还需要规范化”的内部事实，但不能为了提前得到 bytes 而退回 `EXPIRE code 120`。

### 15.2 非正 `EXPIRE` 在本项目中规范化成 DEL

先有：

```text
code -> 1234
```

再执行：

```text
EXPIRE code 0
```

当前项目的 TTL 规则会立即删除有效 key，并返回 1。Day1 选定的日志表示是：

```text
DEL code
```

重放 DEL 后，key 同样不存在，不需要伪造一个已经过去的绝对时刻。

最小测试：

```text
初始：code 存在
执行：EXPIRE code 0
预期 reply：:1
预期 store：code 不存在
预期 record parse 结果：{"DEL", "code"}
```

若 key 原本不存在，`EXPIRE code 0` 返回 0，store 不变，也不产生 DEL record。
[Redis EXPIRE 文档](https://redis.io/docs/latest/commands/expire/)确认非正期限会删除 key。
把本项目的日志表示选成 DEL，则是 Mini Redis 自己的 contract，不宣称真实 Redis 内部一定用同一种日志命令。

现在再给这两个动作取共同名字：**command normalization（命令规范化）**。它不是把客户端文字原样保存，而是根据已经发生的状态变化，选出重放时语义明确的内部命令：正期限最终变成 PEXPIREAT，非正期限导致的立即删除变成 DEL。

### 15.3 空 DEL 与负绝对时刻怎样稳定失败

这两个输入都不能描述一条合法的可重放状态变化：

```text
DEL            // 没有任何 key
PEXPIREAT k -1 // 绝对 Unix 毫秒时刻为负
```

本项目把它们定义为 `std::invalid_argument`：

```cpp
EXPECT_THROW(
    encode_aof_del(std::vector<std::string>{}),
    std::invalid_argument);

EXPECT_THROW(
    encode_aof_pexpireat("code", -1),
    std::invalid_argument);
```

“稳定”在这里指异常类型属于公开 contract。除非你把 message 也写进公开约定，否则测试不必绑定整段英文文案。

### 15.4 每个 payload 合法，不代表整条 record 一定合法

现有 parser 同时限制：

```text
单个 Bulk String 最大长度
整条 request frame 最大长度
Array element count
```

例如 key 和 value 各为 1 MiB。两项各自没有超过单 Bulk 上限，但加上 RESP 长度行、CRLF、命令名和 Array header 后，完整 SET record 是 2,097,189 bytes，比 2 MiB frame 上限多 37 bytes。

```cpp
const std::string key(1024U * 1024U, 'k');
const std::string value(1024U * 1024U, 'v');

EXPECT_THROW(
    encode_aof_set(key, value),
    std::length_error);
```

网络请求通常会先被 parser 拒绝；这个 test 仍有意义，因为 public encoder 也能被内部代码直接调用。它不能生成一条未来连自己的 replay parser 都拒绝的 record。

实现时应以 parser 的现行三个上限为同一 contract 来源，不能在 encoder 里悄悄发明另一组数字。若常量当前不可共享，再决定最小的共享位置；本节不要求重构整个 parser。

### 15.5 encoder 抛异常时，调用者不能拿到半条 record

encoder 应先在局部 `std::string` 中构造并检查完整结果，成功后才按值返回。下面的 test 把调用者原有内容设成 `previous`：

```cpp
std::string committed_record = "previous";
const std::string key(1024U * 1024U, 'k');
const std::string value(1024U * 1024U, 'v');

EXPECT_THROW(
    committed_record = encode_aof_set(key, value),
    std::length_error);
EXPECT_EQ(committed_record, "previous");
```

右侧函数在赋值前失败，因此调用者仍只有旧内容，没有可见的半条新 record。

这个 test 只证明**内存返回值**的完整性。文件只写进半条是 Day2 的 `write_all` 与 Day6 的坏尾部问题，不能拿这项测试冒充文件原子写入。

### 15.6 record 准备失败时，store 与成功 reply 都不能先提交

最后把组件错误放回命令路径。先准备：

```text
store[code] = old
code 仍有 TTL
```

然后让一次 SET 的候选 record 因 frame 超限而失败。如果控制流先 `store.set()`、后调用 encoder，就会得到：

```text
store 已变成新值
record 不存在
重启后无法恢复这次变化
```

正确 test 应同时检查三件事：

```text
调用结果：抛出约定异常，或返回明确 Error；不能得到 +OK
store value：仍为 old
store TTL：仍为调用前的期限
```

若你把 R2 入口实现为返回 `CommandOutcome`，测试形状可以是：

```cpp
const auto before_value = store.get("code");
const auto before_ttl = store.pttl("code");

EXPECT_THROW(
    run_command_with_persistence(store, oversized_set),
    std::length_error);

EXPECT_EQ(store.get("code"), before_value);
EXPECT_EQ(store.pttl("code"), before_ttl);
```

`run_command_with_persistence`、`oversized_set` 和 `store.pttl` 都是占位名字，不要求照抄。它们分别代表你最终选定的 R2 入口、输入与查询方法。

关键 oracle（判定依据）是：**失败发生在 store 修改与成功 outcome 产生之前。** 若你选择把内部异常转换成 RESP Error，则断言 Error 且不是 `+OK`。两种接口风格只能选定一种，不能一边改 store、一边返回成功。

### 15.7 Round3 最后要留下哪些测试

Round3 不是五个新功能。它用五个小场景攻击同一条边界：record 准备失败时，store 与成功 reply 都不能提前提交；命令实际没有改变状态时，已经准备的候选 record 可以丢弃。

```text
正数 EXPIRE：最终记录不能仍叫 EXPIRE
非正 EXPIRE：有效 key 立即删除，并规范化成 DEL
空 DEL / 负绝对时刻：invalid_argument
整帧超限：length_error
encoder 失败：无半条返回值、store 不变、无成功 reply
```

Day1 仍然不解决：

- record 怎样完整写入 fd；
- `write()` 短写与 `EINTR`；
- `fsync/fdatasync`；
- 启动时怎样读取整个文件；
- 日历时钟与单调时钟怎样换算。

这些分别属于 Day2～Day4。

---

# Part 3：验证、记录与停止点

## 16. 构建与测试

在 Ubuntu 工程根目录：

```bash
cd /home/xgf/code/system-learning/cpp/week10
cmake -S . -B build
cmake --build build --target aof_record_test -j
cmake -E chdir build ctest --output-on-failure
```

最终仍使用约定的完整 CTest 命令。不要只运行新 executable 后就宣布全工程通过。

## 17. 本轮需要保存的证据

在 `week14/day1/day1_note.md` 记录：

1. 三类记录各自代表哪种已经发生的状态变化。
2. 一条 binary SET 的 key/value byte length，以及 round-trip 后的 arguments。
3. 为什么 read-only command 不产生记录。
4. 为什么相对 EXPIRE 不能原样重放。
5. 你的内部 helper 怎样保证 DEL 顺序和 owning output。
6. CTest 的实际结果；失败时保留第一条有效诊断。
7. 为什么相同 value 的成功 SET 仍可能清除旧 TTL，因此仍要持久化。
8. 本项目为什么把成功的非正 EXPIRE 规范化成 DEL。
9. 任选一条 encoder 失败路径，记录调用前后的 value、TTL、reply 与 record 是否变化。

今天的 note 重点是你对“什么值得恢复”和“记录怎样保持 exact bytes”的理解，不要求抄整篇教程。

## 18. 今天的停止边界

R1 已经闭合下面这条链：

```text
已确认的状态变化
-> AOF record encoder
-> 一条独立 RESP record
-> exact bytes 正确
-> 现有 parser 能完整还原 arguments
```

今天还没有证明：

- 命令执行后一定会调用 encoder；
- 记录已经进入文件；
- 回复客户端前已经满足同步边界；
- 新进程已经能恢复；
- TTL 能跨停机保持原到期时刻；
- 真实 Redis 的 AOF 行为已经被复刻。

接下来进入 R2：让当前 handler 在生成 reply 的同时，把“是否发生了可持久化状态变化”交给 application owner。文件追加仍然留给 Day2。
