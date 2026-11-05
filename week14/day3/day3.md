# Week14 Day3：让空的 KvStore 按日志顺序重新长回 SET/DEL 状态

> 版本：2026-11-05，R1 已以 96/100、R2 已以 98/100 正式通过；下一步 R3
> 前置：Week14 Day1、Day2 已整日通过；Day2 最终 97/100
> 今日产出：一个独立的 AOF replay（AOF 重放）组件，能从完整日志逐条恢复 SET/DEL
> 今日主线：找到第一条完整记录 -> 应用状态变化 -> 按 `consumed_bytes` 前进 -> 直到文件结束

[TOC]

---

# Part 1：文件里已经有记录，为什么新进程仍然是空的

## 1. Day2 把什么交到了这里

Day1 已经把成功的状态变化编码成完整 RESP record（RESP 记录）。

Day2 又把每条 record 完整追加到了文件末尾。

现在文件可能是：

```text
[SET name old][SET name new][SET temp x][DEL temp]
```

但是新进程刚创建出来的 `KvStore` 仍然是空的：

```cpp
KvStore store;
EXPECT_EQ(store.size(), 0U);
```

文件不会自动修改这个对象。

新进程必须主动完成下面的动作：

```text
读出第一条记录
-> 把 SET name old 应用到空 store

读出第二条记录
-> 用 new 覆盖 old

读出第三条记录
-> 放入 temp

读出第四条记录
-> 删除 temp
```

最终状态才是：

```text
name -> new
temp -> 不存在
```

把日志中的状态变化按原顺序再做一次，叫
**replay（重放）**。

重放不是把旧进程的内存原样复制回来。

它是在一个新的空 `KvStore` 上，重新执行日志已经保存的状态变化。

## 2. 先跟完一条完整记录

第一条记录是：

```text
*3\r\n
$3\r\nSET\r\n
$4\r\nname\r\n
$3\r\nold\r\n
```

它一共占 32 bytes。

把整个 AOF 文件交给你现有的 parser：

```cpp
const auto parsed = parser.parse(aof.data(), aof.size());
```

parser 不会一次返回文件里的所有命令。

它只解析最前面的一条完整 RESP frame（RESP 帧）：

```text
parsed.status
-> Complete

parsed.arguments
-> ["SET", "name", "old"]

parsed.consumed_bytes
-> 32
```

`consumed_bytes` 的意思是：

```text
aof[0, 32)
-> 已经属于第一条完整记录

aof[32, aof.size())
-> 还没有处理
```

所以完成第一条以后，下一次不能再从 `aof.data()` 开始。

它必须从：

```cpp
aof.data() + 32
```

继续解析。

## 3. 四条记录怎样连续前进

继续使用开头的四条记录。它们的区间是：

```text
[0, 32)    SET name old
[32, 64)   SET name new
[64, 94)   SET temp x
[94, 117)  DEL temp
```

replayer（重放器）只需要保存一个当前位置：

```cpp
std::size_t offset = 0;
```

每次都把尚未处理的后缀交给 parser：

```text
第 1 次：data + 0，剩余 117 bytes
parser 消费 32
offset 变成 32

第 2 次：data + 32，剩余 85 bytes
parser 消费 32
offset 变成 64

第 3 次：data + 64，剩余 53 bytes
parser 消费 30
offset 变成 94

第 4 次：data + 94，剩余 23 bytes
parser 消费 23
offset 变成 117
```

此时：

```text
offset == aof.size()
```

说明所有完整 bytes 都已经处理完。

这就是今天整堂课的主干。

## 4. 为什么不直接调用现有 `execute_command()`

parser 已经给出了：

```cpp
{"SET", "name", "old"}
```

看起来可以直接调用：

```cpp
execute_command(store, parsed.arguments);
```

但你当前的 `execute_command()` 负责的是客户端命令路径。

一次成功 SET 会同时产生：

```text
reply
-> +OK\r\n

aof_record
-> 又一条 SET record
```

重放时不需要给客户端回复，也不能把同一条记录再次追加回 AOF。

否则每启动一次，日志都可能把自己复制一遍。

所以今天使用一条明确的 replay path（重放路径）：

```text
客户端路径
request -> parser -> execute_command
        -> 修改 KvStore
        -> reply
        -> 新 AOF record

启动重放路径
AOF bytes -> parser -> apply_replay_command
          -> 只修改新的 KvStore
          -> 不生成 reply
          -> 不生成新 record
```

两条路径最终都复用 `KvStore::set()` 和 `KvStore::erase()`。

它们不同的是外层职责。

---

# Part 2：从完整 bytes 走到启动前恢复

# Round 1：先把完整 SET/DEL 日志重放到空 store

## 5. R1 到底要造什么

新增三个文件：

```text
include/mini_redis/aof_replay.hpp
src/aof_replay.cpp
tests/aof_replay_test.cpp
```

R1 暂时不打开文件。

它直接接收一段已经读到内存里的完整 AOF bytes。

这样可以先把真正的新问题单独验证：

```text
怎样逐条解析
怎样按顺序应用
怎样前进到下一条
```

第一版 public contract（公开约定）可以是：

```cpp
#pragma once

#include "kv_store.hpp"

#include <cstddef>
#include <string_view>

struct AofReplayResult {
    std::size_t records_applied{0};
    std::size_t bytes_consumed{0};
};

AofReplayResult replay_aof_bytes(
    KvStore& store,
    std::string_view aof_bytes);
```

这个函数完成一件事：

```text
输入
-> 一个尚未对外服务的 KvStore
-> 一段完整 AOF bytes

动作
-> 按顺序应用其中的 SET/DEL

返回
-> 成功应用了多少条记录
-> 成功消费了多少 bytes
```

它会修改 `store`。

它只借用 `aof_bytes`，不会保存这个 `string_view`，也不会修改原 bytes。

它不返回 RESP reply，也不返回新的 AOF record。

## 6. 一条解析结果怎样变成状态变化

先写一个只在 `.cpp` 内使用的 helper：

```cpp
void apply_replay_command(
    KvStore& store,
    const std::vector<std::string>& arguments);
```

R1 只接受两种规范记录。

### 6.1 SET

合法形状是：

```text
["SET", key, value]
```

动作是：

```cpp
store.set(arguments[1], arguments[2]);
```

这会覆盖旧 value，也会沿用你当前 `KvStore::set()` 的规则清除旧 TTL。

Day3 暂时还没有 TTL record。

这里只复用已经存在的 SET 状态变化。

### 6.2 DEL

合法形状是：

```text
["DEL", key1, key2, ...]
```

动作是按记录中的顺序逐个删除。你当前实现让同一条 DEL record 共用一个时刻：

```cpp
const auto now_ms = store.read_time_ms();
for (std::size_t i = 1; i < arguments.size(); ++i) {
    store.erase_at(arguments[i], now_ms);
}
```

这样 `DEL a b` 不会因为读取两次时钟，把同一条记录拆成两个观察时刻。

重放不需要计算客户端看到的删除数量。

它只需要让最终状态与原执行顺序一致。

重复 key 也不用提前去重：

```text
DEL a a
-> 第一次删除 a
-> 第二次发现 a 已不存在
-> 最终状态仍然正确
```

## 7. 主循环只维护 `offset`

完整 Day3 的主循环最终要兑现下面这些动作。

R1 先只用完整、合法的 SET/DEL 日志走通 `Complete` 分支；
R3 再把同一个循环里的失败分支补成最终 contract。

```cpp
offset = 0
records_applied = 0

while (offset < aof_bytes.size()) {
    remaining = aof_bytes.size() - offset

    parsed = parser.parse(
        aof_bytes.data() + offset,
        remaining)

    if parsed is Complete:
        validate and apply parsed.arguments
        offset += parsed.consumed_bytes
        records_applied += 1

    if parsed is NeedMore:
        fail: EOF 前最后一条不完整

    if parsed is Error:
        fail: 当前 offset 的 RESP 记录非法
}

return {records_applied, offset}
```

这里的 EOF 是 end of file（文件结束位置）。

R1 的通过输入已经是完整日志。

如果以后在 EOF 前得到 `NeedMore`，它不是“再等网络后缀”。

文件不会自己继续长出缺失 bytes。

Day3 的最终版本必须把它当作启动失败；当前 R1 还不能声称已经兑现这条边界，
R3 会对照真实 `break` 分支补上。

Day6 再专门区分可处理的不完整文件尾与中间损坏。

还有一个小保护：

```text
Complete
-> consumed_bytes 必须大于 0
-> consumed_bytes 不能大于 remaining
```

你当前 parser 的正常结果已经满足它。

replayer 仍可以检查一次，避免未来 parser contract 改动后循环不前进。

## 8. R1 的核心测试

测试从一个空 store 开始。

日志按顺序放入五条记录：

```text
SET name old
SET name new
SET <binary-key> <binary-value>
SET temp x
DEL temp
```

其中 binary bytes 使用明确长度构造：

```cpp
const std::string binary_key{"k\0x", 3};
const std::string binary_value{"v\r\nz", 4};
```

测试输入可以直接复用 Day1 encoder：

```cpp
std::string aof;
aof += encode_aof_set("name", "old");
aof += encode_aof_set("name", "new");
aof += encode_aof_set(binary_key, binary_value);
aof += encode_aof_set("temp", "x");
aof += encode_aof_del({"temp"});
```

重放以后至少断言：

```cpp
EXPECT_EQ(result.records_applied, 5U);
EXPECT_EQ(result.bytes_consumed, aof.size());

EXPECT_EQ(store.get("name"),
          std::optional<std::string>("new"));
EXPECT_EQ(store.get(binary_key),
          std::optional<std::string>(binary_value));
EXPECT_FALSE(store.exists("temp"));
EXPECT_EQ(store.size(), 2U);
```

这一个场景同时证明：

```text
记录按顺序执行
-> 后来的 SET 覆盖先前值

parser 每次只消费第一条
-> offset 能连续走到文件末尾

binary payload 按长度恢复
-> NUL 与 CRLF 没有改变记录边界

DEL 在 SET 之后生效
-> temp 最终不存在
```

## 9. Round 1 Reading Gate

先停在这里，不继续读 R2。

你应该能用自己的话回答：

1. 为什么 `parser.parse(aof.data(), aof.size())` 只处理第一条记录？
2. 第一条返回 `consumed_bytes = 32` 后，第二次为什么从 `data + 32` 开始？
3. 为什么重放路径不直接消费 `CommandOutcome`？
4. `SET name old`、`SET name new`、`DEL temp` 的顺序怎样决定最终状态？
5. `replay_aof_bytes()` 修改了什么，又明确不产生什么？

能回答并跑通 R1 测试，再进入 R2。

> **R1 实际验收（2026-11-05）：96/100，正式通过。** 当前实现已经完成完整
> SET/DEL 日志的顺序重放；focused CTest 2/2、完整 CTest 148/148 通过。
> `NeedMore`、parser `Error`、错误参数和不前进保护仍是本日 R3 的明确目标，
> 不把这些后置边界倒算成 R1 未完成。

---

# Round 2：把真实文件 bytes 交给同一个重放核心

## 10. R1 已经会重放，为什么还要 R2

R1 的输入是一段 `string_view`。

你当前的 `replay_aof_bytes()` 已经通过完整日志路径。

R2 不回头重写这个循环，也不顺手处理 R3 的错误分支。

真实启动时，bytes 还在 AOF 文件中。

所以 R2 只补一座桥：

```text
path
-> 只读打开
-> 读到 EOF
-> 得到完整 bytes
-> 调用已经通过的 replay_aof_bytes()
```

R2 不重写 parser loop，也不新增第二套 SET/DEL 逻辑。

## 11. 文件入口要解决什么

可以增加：

```cpp
#include <string>

AofReplayResult replay_aof_file(
    KvStore& store,
    const std::string& path);
```

它的用途是：

```text
启动代码只提供 AOF path 和空 store
-> 函数读完整文件
-> 复用 replay_aof_bytes
-> 返回同一份统计结果
```

R2 采用学习版的 whole-file loading（整文件读入）：

```text
文件全部读进一个 std::string
-> 再逐条解析
```

这样能把文件读取与重放顺序看清。

它不代表生产级大 AOF 的最佳内存方案。

流式读取、重写和恢复速度留在完整基线之后讨论。

## 12. 读取循环复用你已经会的规则

只读打开使用：

```text
O_RDONLY
-> 只读取文件

O_CLOEXEC
-> 以后若进程执行别的程序，不把这个 fd 意外带过去
```

打开成功后的只读 fd 继续交给 `UniqueFd` 拥有。

`replay_aof_file()` 只借用 path；函数返回或抛异常时，
`UniqueFd` 都会关闭本次打开的 fd。

`read()` 的返回值按下面处理：

```text
count > 0
-> 只有 buffer[0, count) 有效
-> 按明确长度 append 到 std::string

count == 0
-> 到达 EOF
-> 文件读取完成

count == -1 且 errno == EINTR
-> 本次没有取得 bytes
-> 原位置重试

其他 -1
-> 保存 errno
-> 抛出 system_error
```

这就是你 Day2 note 中 `copy_file()` 的 read 一侧。

区别只是今天不把 bytes 写到另一个文件，而是放入内存交给 replayer。

Linux `read(2)` 的精确返回规则可查：
[read(2) Linux manual](https://www.man7.org/linux/man-pages/man2/read.2.html)。

本日 contract（约定）要求 path 已存在。

一个存在但长度为 0 的文件表示没有旧状态，重放成功并返回 `{0, 0}`。

路径不存在或读取失败时，不静默伪装成空数据库。

Day5 接入真实启动流程时，再明确首次启动怎样创建文件。

## 13. R2 用一条端到端场景证明

测试先用 Day1 和 Day2 的组件生成真实文件：

```text
encode_aof_set / encode_aof_del
-> AofWriter.append
-> AofWriter.sync
-> writer 析构关闭 fd
```

然后创建一个全新的 `KvStore`：

```text
new empty store
-> replay_aof_file(path)
-> 检查最终 key/value
```

这里必须是新对象。

如果继续检查原来的 store，就无法证明状态来自文件恢复。

R2 至少保留两个场景：

1. 空文件返回 0 条、0 bytes，store 仍为空。
2. 真实文件含覆盖、binary SET 与 DEL，新 store 得到与 R1 相同的最终状态。

这两个场景证明的是：

```text
Day1 record
-> Day2 file
-> Day3 fresh KvStore
```

而不是只证明一个内存字符串能够解析。

## 14. Round 2 停止点

R2 通过时，你应该已经有两层清楚分工：

```text
replay_aof_file
-> 负责从 path 得到 bytes

replay_aof_bytes
-> 负责逐条 parse 与 apply
```

文件读取完成以后，所有状态恢复规则只存在一份。

不要在 `replay_aof_file()` 里再手写第二个 parser loop。

> **R2 实际验收（2026-11-05）：98/100，正式通过。** 当前实现已经完成
> `path -> O_RDONLY | O_CLOEXEC -> read 到 EOF -> replay_aof_bytes()` 的唯一文件桥。
> focused R1/R2 CTest 4/4、完整 CTest 150/150，以及 fresh `-Werror` focused 4/4
> 全部通过。空文件保持空 store；超过 4096 bytes 的真实文件也能把 binary SET、覆盖与 DEL
> 恢复到一个全新的 `KvStore`。唯一后置项是 `open()` 失败尚未立即检查：缺失路径目前会在
> 随后的 `read(-1)` 处变成 `EBADF`，R3 要保留原始 `ENOENT` 诊断。

---

# Round 3：完整 RESP 不等于合法 AOF 状态记录

## 15. parser 成功以后，为什么仍可能拒绝

看这条记录：

```text
*2\r\n$3\r\nGET\r\n$1\r\nk\r\n
```

对 RESP parser 来说，它是完整合法的：

```text
status
-> Complete

arguments
-> ["GET", "k"]
```

但 GET 是只读命令。

Day1 已经规定，它不应该进入 AOF。

所以这里有两个不同问题：

```text
parser
-> bytes 是不是一条完整 RESP command？

replayer
-> 这条 command 是不是本版本允许恢复的状态记录？
```

R3 要把第二层检查补完整。

当前允许集合只有：

```text
SET key value
DEL key [key ...]
```

命令名按 Day1 encoder 生成的规范大写形式检查。

`GET`、`PING`、未知命令以及参数数量错误，都应让启动失败。

`PEXPIREAT` 虽然是未来合法的内部记录，但它的双时钟恢复语义留到 Day4。

今天不提前伪装成已经支持。

## 16. 三种失败分别表示什么

先对照 R1 当前代码，不把下面三项读成新的知识地图：

```text
NeedMore
-> 当前是 break 后返回部分统计
-> R3 改成明确的 incomplete failure

Error
-> 当前读取 errno 并抛 system_error
-> 但 parser Error 不是系统调用失败，errno 可能是 0 或旧值
-> R3 改用 parser 的 error_message，并附上当前 offset

Complete
-> 当前在访问 arguments[1]/arguments[2] 前没有验证命令与参数数量
-> R3 先验证，再修改 store 和增加 records_applied
```

R3 还要检查 `consumed_bytes` 大于 0 且不超过 `remaining`。
这只是保护 R1 已经会走的 offset，不是另一套重放算法。

### 16.1 `NeedMore`

含义是：

```text
EOF 到了
-> 当前记录还缺 bytes
```

Day3 先停止启动。

Day6 再决定怎样确认它只是不完整尾部，以及能否截断到上一条完整记录。

### 16.2 `Error`

含义是：

```text
当前 offset 的 bytes
-> 已经违反 RESP 格式或 parser limit
```

错误信息应保留 parser 给出的原因，并附上当前 byte offset（字节偏移）。

这样你能知道坏记录从哪里开始。

### 16.3 `Complete`，但命令不允许

含义是：

```text
RESP 语法正确
-> 但不是本版本允许重放的状态变化
```

例如 `GET k` 或 `SET only_key`。

这时同样停止启动，不能跳过后继续。

跳过一条未知写操作，可能让后续 store 与原进程状态不同。

## 17. 失败前已经应用的记录怎么办

假设文件是：

```text
[合法 SET a 1][不允许的 GET a]
```

replayer 可能已经把 `a` 写入这个新 store，随后才在第二条失败。

Day3 不把整份日志包装成一次内存事务，也不复制整张 map 做回滚。

安全边界来自启动顺序：

```text
创建新的、尚未对外可见的 KvStore
-> 重放
-> 任一错误：记录诊断并终止启动
-> 全部成功：才创建对外服务入口
```

失败时，这个半恢复 store 不会交给客户端。

这也是“重放必须发生在 listen 之前”的真正含义。

这里的 `listen` 指服务器开始接受新连接的入口。

Day5 才把顺序接进真实 `mini_redis_server`。

## 18. R3 的证据

R3 不再增加新的恢复功能。

它只攻击刚才的边界：

| 输入 | 预期 | 证明什么 |
|---|---|---|
| 完整 `GET k` record | 抛错并停止 | RESP 合法不等于 AOF 合法 |
| 完整 `SET k` record | 抛错并停止 | SET 参数数量必须精确 |
| 完整但无 key 的 `DEL` | 抛错并停止 | DEL 至少需要一个 key |
| 最后一条缺一个 byte | 当前版本抛 incomplete error | Day3 不静默接受残缺尾部 |
| 非 RESP 顶层 bytes | 保留 parser error 与 offset | 格式错误可定位 |
| 不存在的 AOF path | 抛出的 `system_error` 保留 `ENOENT` | `open()` 失败不会被后续 `read(-1)` 伪装成 `EBADF` |

这些测试没有要求你实现 Day6 的截断策略。

它们只证明当前版本会拒绝无法确定地恢复的日志。

### 18.1 不再次记日志怎样证明

`replay_aof_bytes()` 的参数只有：

```text
KvStore&
std::string_view
```

它没有 `AofWriter`，也不返回 `CommandOutcome`。

内部只调用 `apply_replay_command()` 与 `KvStore` 状态 API。

这是明确的 replay path，不是“刚好忘了调用 writer”。

Day5 接线时仍要保持：

```text
startup replay
-> 不走 live append

client write after startup
-> 才走 append + sync
```

## 19. Round 3 停止点

今天的完整行为已经闭合：

```text
完整日志
-> 顺序恢复 SET/DEL
-> 成功后得到新的 KvStore

不完整、非法或不允许的记录
-> 启动失败
-> 不开始 listen

重放本身
-> 不生成 reply
-> 不再次写 AOF
```

Day4 才加入 `PEXPIREAT` 与跨重启 TTL。

Day6 才把“不完整尾部”和“中间损坏”分开处理。

---

# Part 3：构建、笔记与今天能声称什么

## 20. CMake 接入

新增 library：

```cmake
add_library(aof_replay
    src/aof_replay.cpp
)

target_include_directories(aof_replay PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include/mini_redis
    ${CMAKE_CURRENT_SOURCE_DIR}/include/resp
    ${CMAKE_CURRENT_SOURCE_DIR}/include/reactor
)

target_compile_options(aof_replay PRIVATE
    -Wall
    -Wextra
    -g
)

target_link_libraries(aof_replay PUBLIC
    kv_store
    resp_request_parser
)
```

测试 target：

```cmake
add_executable(aof_replay_test
    tests/aof_replay_test.cpp
)

target_compile_options(aof_replay_test PRIVATE
    -Wall
    -Wextra
    -g
)

target_link_libraries(aof_replay_test PRIVATE
    aof_replay
    aof_record
    GTest::gtest_main
    GTest::gtest
)

gtest_discover_tests(aof_replay_test PROPERTIES TIMEOUT 5)
```

如果 R1 尚未实现文件入口，测试暂时不需要链接 `aof_writer`。

到 R2 增加真实文件场景时再补上，不为未来代码提前制造依赖。

## 21. 构建与测试

在 Ubuntu 工程根目录：

```bash
cd /home/xgf/code/system-learning/cpp/week10

cmake -S . -B build
cmake --build build --target aof_replay_test -j

cmake -E chdir build \
  ctest --output-on-failure \
  -R '^AofReplay'
```

局部测试通过后，再运行完整回归：

```bash
cmake -E chdir build ctest --output-on-failure
```

不要提前写死测试总数。

以本次 CTest 的真实输出为准。

## 22. 今天的 note 只留下这一条链

在 `week14/day3/day3_note.md` 由你自己记录：

1. replay 与“复制旧内存”有什么不同。
2. 第一条记录的 `consumed_bytes` 怎样决定下一次 parser 起点。
3. 为什么顺序不能改变，后 SET 和 DEL 分别怎样影响最终状态。
4. 为什么重放路径不产生 reply 和新的 AOF record。
5. `Complete`、`NeedMore`、`Error` 在文件 EOF 语境下分别意味着什么。
6. 为什么完整 RESP `GET k` 仍不是合法 AOF 状态记录。
7. 为什么任一重放失败都必须发生在 listen 之前。
8. 实际 focused CTest 与完整 CTest 结果；没有运行的证据不要写成通过。

不需要抄完整代码。

重点画清：

```text
file offset
-> one parsed record
-> one state transition
-> next offset
```

## 23. 今天正式完成时，你能声称什么

可以声称：

```text
一个新建的空 KvStore
能够从完整单文件 AOF 中
按顺序恢复 SET/DEL 最终状态

binary key/value 按 byte length 恢复

空文件恢复为空状态

不完整、非法或当前不支持的记录
不会被静默跳过

重放不会再次生成 AOF record
```

今天仍不能声称：

```text
TTL 已经跨重启保持原到期时刻
服务器已经在真实 listen 前调用重放
不完整文件尾已经能自动截断
中间损坏已经能修复
大 AOF 已经用流式方式低内存恢复
日志已经支持重写、RDB 或多文件 manifest（清单文件）
恢复速度或内存峰值已经测量
```

Redis 官方文档说明，AOF 会在启动时重放写操作来重建数据；
Redis 7 及以后实际使用多文件 AOF 机制。
这些真实系统能力只用于校准方向，不改成本日的单文件 SET/DEL 任务：
[Redis persistence](https://redis.io/docs/latest/management/persistence/)。

## 24. Day4 从哪里继续

Day3 结束后，下面这份日志已经能恢复：

```text
SET code 1234
DEL old
```

但这一条仍未支持：

```text
PEXPIREAT code 1800000000000
```

新进程不能把旧进程的 `steady_clock` 数字拿回来继续使用。

Day4 要解决：

```text
日志里的绝对日历到期时刻
-> 减去重启时的当前日历时刻
-> 得到还剩多久
-> 再写入新进程自己的单调时钟期限
```

今天先把记录顺序恢复正确。

下一天再让 TTL 在停机期间继续流逝。
