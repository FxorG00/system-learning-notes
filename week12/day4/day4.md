# Week12 Day4：让命令真正读写 KV 数据

**今天造两个纯内存组件：`KvStore` 保存 key/value，`execute_command()` 执行六条 Redis 命令，并返回可以直接发送的 RESP reply bytes。**

> 版本：2026-10-08，基于 Week12 Day3 正式通过后的实际进度生成
>
> 前置：Day1 encoder、Day2/Day3 parser 已通过；Day3 最终评分 `96/100`
>
> 今日产出：KV store + command dispatcher + 代表性 GoogleTest
>
> 工作工程：Ubuntu 的 `~/code/system-learning/cpp/week10`，继续使用 C++17、g++、CMake
>
> 阅读方式：完成 Round1 后停下，先提交代码检阅；Round2/3 已生成，R1 正式通过时再按你的实现定向润色

---

# Part1：从“读懂命令”走到“保存数据”

## 1. 今天终于让 SET 留下东西

前两天你的 parser 已经能把一段 RESP bytes 还原成：

~~~text
["SET", "name", "FxorG"]
~~~

现在要让这条命令真的产生效果。执行结束后，即使这一组 arguments 已经析构，`name -> FxorG` 仍然存在；下一条 `GET name` 能把它取出来。

今天的完整行为是：

| 按顺序执行 | 执行后的数据 | 返回结果 |
|---|---|---|
| 初始状态 | 空 | 无 |
| `SET name FxorG` | `name -> FxorG` | `OK` |
| `GET name` | 不变 | `FxorG` |
| `SET name new` | `name -> new` | `OK` |
| `EXISTS name` | 不变 | `1` |
| `DEL name` | 空 | `1` |
| `GET name` | 仍然为空 | null，表示这个 key 不存在 |

**今天新增的是能跨命令保留的 application state（应用状态）。** Parser 判断 bytes 的格式，store 保存数据，dispatcher 决定一条命令要做什么。

今天先在一个 C++ 进程内部调用接口，把这三件事组合正确。Day5 再把命令入口接到你已经完成的 Reactor；那时多个 TCP clients 才能操作同一份数据。

## 2. 你的现有代码已经提供了什么

Day3 的实际实现已经解决了 Array/Bulk length、数字转换、binary payload、第一帧边界与三个资源上限。最后补上的 `+2` 也让 frame limit 包含了 payload 后面的 CRLF。

当前已有两端接口：

~~~text
输入端：RespRequestParser::parse(...)
    -> Complete 时交付 owning vector<string> arguments
    -> 同时交付 consumed_bytes

输出端：Day1 的五个 encoder
    -> Simple String / Error / Integer / Bulk String / Null Bulk String
    -> 返回 owning string，里面是 exact RESP bytes
~~~

Owning 在这里指**对象自己拥有 bytes**。`arguments` 中的字符串已经从原 input range 取得自己的内容，今日 store 不需要保存一个指向 `Buffer::peek()` 的临时 pointer。

今天补上中间这一段：

~~~text
arguments
-> 执行对应命令
-> 查询或修改 store
-> 调用已有 encoder
-> 返回 reply bytes
~~~

Day3 的 normal 与 ASan/UBSan 全量 CTest 已经是 `71/71 PASS`。今天继续维护原工程和这套证据，不重写 parser，也不重新手写一遍 all-split tests。

今天可直接使用 `resp_encoder.hpp` 中已有的 `encode_resp_simple_string`、`encode_resp_error`、`encode_resp_integer`、`encode_resp_bulk_string` 和 `encode_resp_null_bulk_string`。它们分别对应上面的五种 reply，签名继续沿用你 Day1 的实现。

## 3. Redis、database、cache 与 KV：从用途建立第一层

假设你的程序有多个使用者。A 写入一个名字，B 稍后要读到它。数据必须放在一个**共同访问、持续存在的保存位置**，不能随着 A 的一次请求结束就消失。

**Database（数据库）是有组织地保存、查询和更新数据的系统。** 组织方式可以不同：MySQL 常用表、行、列（table/row/column）；我们今天采用 key/value。

**Key-value store，简称 KV store（键值存储），通过唯一的 key 找到对应的 value。** 例如 key 是 `name`，value 是 `FxorG`。同一个 key 再次 SET，会替换原 value，而不是再增加一个同名记录。

**In-memory（内存中的）描述的是主要工作数据放在哪里。** 你的 V1 会把数据保存在当前 server process 的 memory 中，所以查找不需要每次先读一个磁盘文件。此时还没有恢复机制，进程结束后这份数据就消失；真实 Redis 可以另外配置持久化能力。

**Cache（缓存）描述的是数据扮演的角色：为了更快访问，保存一份可以重新取得或重新计算的数据。** 例如原始资料在 MySQL，热门查询结果暂存在 Redis。内存 KV 也可以保存其他应用状态，是否属于 cache，要看使用方式。

**Keyspace（键空间）就是当前数据库里所有 key 构成的集合。** 今天只有一份 keyspace，value 只支持 binary-safe string（按 bytes 原样保存的字符串）。真实 Redis 还有 Hash（哈希）、List（列表）、Set（集合）等其他类型；这一周先把 string KV 做正确。[Redis keyspace](https://redis.io/docs/latest/develop/using-commands/keyspace/)、[Redis Strings](https://redis.io/docs/latest/develop/data-types/strings/) 可以用于查证。

这样，你今天的 store 就有明确位置了：

~~~text
server application 持有一份 KvStore
-> 每次 command 从这份 store 读取或修改数据
-> 一次 command 结束，store 继续存在
-> 将来 client 换一条 connection，仍访问同一份 store
~~~

## 4. 今天带着四个问题进入教程

1. `SET` 返回之后，谁继续拥有 key/value？为什么下一条命令还能读到？
2. `GET` 查不到 key，与查到一个空 value，应该给 client 什么不同结果？
3. 命令名大小写不敏感，怎样同时保证 key/value 的 bytes 原样保留？
4. 一条命令参数不对时，怎样回复错误，又让下一条合法命令继续工作？

接下来先给你独立实现所需的功能与接口。有关内部表示、查找方式和完整执行链的展开，放在 R1 闸门后。

---

# Part2：教程开始

# Round1：独立完成可调用的命令层

## 5. 它在整个服务器里干什么

你已经发现 HTTP Server 与 Mini Redis 都可以沿用同一套 Echo/Reactor 底座。差别在 application layer（应用层）：HTTP 用 request/route/response；Mini Redis 用 RESP arguments/command/store/reply。

先把它放回 TCP/IP 四层模型：

~~~mermaid
graph TD
    A["应用层: RESP parser, commands, KV state, reply encoder"]
    B["传输层: TCP 有序字节流"]
    C["网络层: IP 交付"]
    D["链路层: 当前 link 上的 frames"]
    A --> B
    B --> C
    C --> D
~~~

这张图说明**本周换的是应用层内容**。TCP 继续交付有序 bytes；IP 与 link 继续负责下面的传输。你的 C++ 应用通过 socket API 使用 TCP，今日新组件不会自己处理下面三层。

再看 server process 内部的实际串联：

~~~mermaid
graph TD
    A["Connection 收到 bytes，存入 input Buffer"]
    B["RESP parser 交付一条完整命令的 arguments"]
    C["Application 用共享 store 调用 execute_command"]
    D["KvStore 拥有 key/value"]
    E["已有 RESP encoder 生成 reply bytes"]
    F["Connection 把 reply 纳入 output 并发送"]
    A --> B
    B --> C
    C --> D
    D --> C
    C --> E
    E --> F
~~~

图中今天实现的是 C/D；E 已在 Day1 完成，A/F 已在 Reactor 中完成。`execute_command()` 会使用 encoder，所以它返回的字符串**已经是 RESP bytes**。Day5 的 caller 可以直接把它交给 `Connection::send()`，无需再编码一次。

需要读写数据的命令才访问 D；PING/ECHO 可以从 C 直接走到 E。这张图展示各组件的职责位置，不要求每条命令都查询 store。

## 6. 文件、用途与今天的交付物

在原工程新增：

| 文件 | 用途 |
|---|---|
| `include/mini_redis/kv_store.hpp` | 声明保存、查询、删除数据的接口 |
| `src/kv_store.cpp` | 实现 key/value 的持有与操作 |
| `include/mini_redis/command_dispatcher.hpp` | 声明统一的命令执行入口 |
| `src/command_dispatcher.cpp` | 执行六条命令，返回 RESP reply bytes |
| `tests/command_dispatcher_test.cpp` | 调用公开接口，检查数据变化与 exact reply |
| 原 `CMakeLists.txt` | 追加两个 libraries 和一个 test target |

**核心产出是前四个文件。** Test 不保存业务数据，也不负责执行命令；它调用你的组件，把实际结果与独立写出的预期结果对照。

内部容器和 private members 由你决定。下方固定 public contract（公开接口契约），不提前规定一套 private layout（私有成员布局）。

## 7. `KvStore`：保存数据的公开接口

默认构造一个空 store。公开接口如下；这是接口要求，不是需要照搬的完整 class definition：

~~~cpp
#include <cstddef>
#include <optional>
#include <string>

class KvStore {
public:
    void set(std::string key, std::string value);
    std::optional<std::string> get(const std::string& key) const;
    bool erase(const std::string& key);
    bool exists(const std::string& key) const;
    std::size_t size() const noexcept;

    // 保存数据所需的 private representation 由你设计。
};
~~~

| 接口 | 功能与返回值 | 对 store 的影响 |
|---|---|---|
| `set(key, value)` | 保存 key/value；已有 key 则覆盖 | 新 key 增加一项，覆盖保持项数不变 |
| `get(key)` | 找到时返回拥有自己内容的 `optional<string>`；没有时返回 `nullopt` | 不修改 |
| `erase(key)` | 实际删除了这一项返回 `true`；原本没有返回 `false` | 只删除存在项 |
| `exists(key)` | 当前存在该 key 返回 `true` | 不修改 |
| `size()` | 返回当前保存的 key 数 | 不修改 |

所有 key/value 都按完整 `std::string::size()` bytes 解释。**空 key 合法，空 value 也合法；key/value 中的 `\0`、CR、LF 和高位字节必须保留。**

### 7.1 最小用法：这个组件到底怎样被调用

~~~cpp
// 演示 store 的外部行为；这里不是 store 的实现。
KvStore store;
store.set("name", "FxorG");

auto first = store.get("name");
// first.has_value() == true，*first == "FxorG"

store.set("name", "new");
// store.size() == 1，first 中仍然是原来的 "FxorG"

const bool removed = store.erase("name");
// removed == true，随后 store.get("name") 返回 std::nullopt
~~~

`get()` 返回的是一次查询的**独立快照**。后续覆盖或删除原 key，已经返回的字符串仍能使用。这个要求决定了返回值的所有权，不强制你的内部容器选择。

`set()` 返回后，caller 的参数对象可以修改或析构。Store 必须继续拥有保存的 key/value。`get/erase/exists` 的引用参数只借用到本次调用结束。

## 8. `execute_command`：让一组参数成为一次操作

**Dispatcher（分发器，来自 dispatch：分派任务）根据 command name 找到对应操作，并产生这一次操作的回复。** 今天使用一个自由函数作为入口，保持组件简单：

~~~cpp
#include "kv_store.hpp"

#include <string>
#include <vector>

std::string execute_command(
    KvStore& store,
    const std::vector<std::string>& arguments);
~~~

它的输入与输出：

- `store`：借用 caller 持有的那一份数据；写命令可以修改它。
- `arguments`：包含命令名的完整参数组，例如 `{"SET", "name", "FxorG"}`；本函数不修改它。
- 返回值：拥有自己内容的 `std::string`，**已经包含 RESP type marker、length、payload 与 CRLF**。

最小用法：

~~~cpp
// 演示两个调用共享同一份数据，以及 reply 的编码层次。
KvStore store;
const std::string first_reply = execute_command(store, {"SET", "name", "FxorG"});
const std::string second_reply = execute_command(store, {"GET", "name"});
// first_reply  == "+OK\r\n"
// second_reply == "$5\r\nFxorG\r\n"
~~~

`execute_command()` 不操作 socket，不消费 input Buffer，不关闭 connection。今日只验证“给定 arguments 和当前 state，会产生什么新 state 与 reply”。

生产调用的 arguments 来自通过 parser 上限检查的一条 Complete frame：最多 1024 个 elements，包含 command name。今日 tests 也在这个输入规模内，不另外设计无限参数的命令执行 API。

## 9. 六条命令的冻结契约

**Command（命令）是 client 请求执行的操作；reply（回复）是 server 对这次操作返回的协议结果。** 这里的命令名只做 ASCII 大小写不敏感匹配：`SET`、`set`、`sEt` 指同一条命令。

命令名必须完整匹配。`" GET"`、`"GET "`、包含额外 NUL 的 `std::string("GET\0", 4)` 都是 unknown command。Key/value 则完全按 bytes 匹配；`Name` 与 `name` 是两个 key。

**Arity（参数数量）描述命令接受多少个 arguments；Redis 的命令元数据把 command name 本身也计入。** 因而 `GET key` 的 Redis arity 是 2，对应 `arguments.size() == 2`。本文说“name 后的参数”时只数后面的值，表中把两种数量分别列出。[Redis COMMAND：Arity](https://redis.io/docs/latest/commands/command/#arity)

| 命令 | name 后的参数数量 | `arguments.size()` | 行为与 RESP reply |
|---|---:|---:|---|
| `PING` | 0 或 1 | 1 或 2 | 无参数：`+PONG\r\n`；有 message：该 message 的 Bulk String |
| `ECHO message` | 1 | 2 | 原样返回 message 的 Bulk String |
| `SET key value` | 2 | 3 | 保存或覆盖，返回 `+OK\r\n` |
| `GET key` | 1 | 2 | 命中：value 的 Bulk String；缺失：`$-1\r\n` |
| `DEL key [key ...]` | 至少 1 | 至少 2 | 返回这次实际删除的 key 数，使用 Integer reply |
| `EXISTS key [key ...]` | 至少 1 | 至少 2 | 按输入中的每次出现计数，存在一次就贡献 1，使用 Integer reply |

`PING` 与 `ECHO` 不访问或修改 store。今天的 `SET` 只支持上述基础形式；多出来的 `NX`、`EX` 等参数按 wrong arity 处理。

两种计数的外部结果必须明确：已有 `a -> v` 时，`EXISTS a a missing` 返回 `:2\r\n`；随后 `DEL a a missing` 返回 `:1\r\n`。这是功能契约，怎样实现由你设计。

空 value 的协议表示也要冻结：

~~~text
SET empty ""       -> +OK\r\n
GET empty          -> $0\r\n\r\n
GET missing        -> $-1\r\n
~~~

这里的 `""` 是方便阅读的空参数记法；真正调用时传一个空 `std::string`，在 RESP request 中它是 `$0\r\n\r\n`。

命令语义可查：[PING](https://redis.io/docs/latest/commands/ping/)、[ECHO](https://redis.io/docs/latest/commands/echo/)、[SET](https://redis.io/docs/latest/commands/set/)、[GET](https://redis.io/docs/latest/commands/get/)、[DEL](https://redis.io/docs/latest/commands/del/)、[EXISTS](https://redis.io/docs/latest/commands/exists/)。正文已给出 V1 所需范围，暂不展开官网中的其他选项。

## 10. 错误 contract：client 收到什么，C++ caller 遇到什么

下面三类正常的命令错误，都**返回 RESP Error bytes**。Store 保持不变，caller 可以继续调用下一条命令。

| 输入问题 | English message，传给 error encoder 的内容 | 函数返回的 exact bytes |
|---|---|---|
| 空 `arguments` vector | `ERR empty command` | `-ERR empty command\r\n` |
| 未知 command name，包括空名字 | `ERR unknown command` | `-ERR unknown command\r\n` |
| 已识别命令的参数数量不对 | `ERR wrong number of arguments for '<name>' command` | 例如 SET：`-ERR wrong number of arguments for 'set' command\r\n` |

最后一行的 `<name>` 固定使用已识别命令的小写名字：`ping/echo/set/get/del/exists`。未知命令统一使用固定 message，不把 client 的 raw command name 拼进 Error 的 line 中。

举例：

~~~text
{}                         -> -ERR empty command\r\n
{""}                       -> -ERR unknown command\r\n
{"GET"}                    -> -ERR wrong number of arguments for 'get' command\r\n
{"sEt", "k"}               -> -ERR wrong number of arguments for 'set' command\r\n
{"NOPE"}                   -> -ERR unknown command\r\n
~~~

空 vector 是纯内存入口的防御性分支。你现有 parser 已经拒绝空 command Array；`{""}` 则是另一种输入：Array 中有一个长度为 0 的 command name。

**内存申请失败属于 C++ 执行失败。** `std::string`、容器或编码过程中出现的 `std::bad_alloc` 可以向上抛，`what()` 使用运行库给出的内容，不伪造一条业务成功回复。今天不承诺“修改成功后，即使 reply 编码发生 OOM 也能自动回滚 store”；OOM 是 out of memory（内存不足），这种恢复策略留到完整应用的故障设计中。

因此 `execute_command()` 与会分配内存的 store 操作不声明 `noexcept`。`size()` 的接口明确为 `noexcept`，因为它只观察项数。

## 11. R1 小 checker：先知道组件能不能用

下面完整内容可以放进 `tests/command_dispatcher_test.cpp`。你写核心实现，我提供重复的调用和断言；**expected bytes 是 literal（字面量），不通过你的 encoder 生成预期值**。

~~~cpp
#include "command_dispatcher.hpp"

#include <gtest/gtest.h>

// 验证同一个 store 跨命令保存数据，覆盖不增加 key 数，GET miss 不修改 state。
TEST(CommandDispatcherR1Test, BasicCommandsUseOneStore) {
    KvStore store;
    EXPECT_EQ(execute_command(store, {"PING"}), "+PONG\r\n");
    EXPECT_EQ(execute_command(store, {"PING", "hi"}), "$2\r\nhi\r\n");
    EXPECT_EQ(execute_command(store, {"ECHO", "hi"}), "$2\r\nhi\r\n");

    EXPECT_EQ(execute_command(store, {"SET", "name", "old"}), "+OK\r\n");
    EXPECT_EQ(execute_command(store, {"GET", "name"}), "$3\r\nold\r\n");
    EXPECT_EQ(execute_command(store, {"SET", "name", "new"}), "+OK\r\n");
    EXPECT_EQ(execute_command(store, {"GET", "name"}), "$3\r\nnew\r\n");
    EXPECT_EQ(store.size(), 1U);

    EXPECT_EQ(execute_command(store, {"GET", "missing"}), "$-1\r\n");
    EXPECT_EQ(store.size(), 1U);
}

// 相同 key 重复出现时，EXISTS 数每次命中，DEL 数实际删除。
TEST(CommandDispatcherR1Test, ExistsAndDelHaveDifferentCounts) {
    KvStore store;
    ASSERT_EQ(execute_command(store, {"SET", "a", "v"}), "+OK\r\n");

    EXPECT_EQ(execute_command(store, {"EXISTS", "a", "a", "missing"}), ":2\r\n");
    EXPECT_EQ(execute_command(store, {"DEL", "a", "a", "missing"}), ":1\r\n");
    EXPECT_EQ(execute_command(store, {"EXISTS", "a"}), ":0\r\n");
    EXPECT_EQ(store.size(), 0U);
}

// 错误命令不能污染原 value；错误之后，合法命令仍能继续执行。
TEST(CommandDispatcherR1Test, BadCommandDoesNotChangeStoredValue) {
    KvStore store;
    ASSERT_EQ(execute_command(store, {"SET", "k", "kept"}), "+OK\r\n");

    EXPECT_EQ(execute_command(store, {"SET", "k"}),
              "-ERR wrong number of arguments for 'set' command\r\n");
    EXPECT_EQ(execute_command(store, {"NOPE"}), "-ERR unknown command\r\n");
    EXPECT_EQ(execute_command(store, {"GET", "k"}), "$4\r\nkept\r\n");
    EXPECT_EQ(execute_command(store, {"PING"}), "+PONG\r\n");
}
~~~

这三个 tests 是 R1 的快速检查入口，覆盖六条命令的基本用途。Binary、空值、返回值所有权和 parser 接口组合留给 R3 的代表性补充，不要求你先写一大坨 checker 才能提交第一版。

## 12. CMake：在原工程末尾追加这一段

现有工程已经配置 C++17、GoogleTest 和 `gtest_discover_tests()`。已有 encoder target 名称是 `resp_encoder`，parser target 是 `resp_request_parser`。

~~~cmake
# KV state 是纯内存 library；公开自己的 header 搜索路径。
add_library(kv_store src/kv_store.cpp)
target_include_directories(kv_store PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include/mini_redis)
target_compile_options(kv_store PRIVATE -Wall -Wextra -g)

# 命令层使用 store 与已有 encoder，返回已经编码的 reply bytes。
add_library(command_dispatcher src/command_dispatcher.cpp)
target_include_directories(command_dispatcher PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include/mini_redis)
target_compile_options(command_dispatcher PRIVATE -Wall -Wextra -g)
target_link_libraries(command_dispatcher PUBLIC kv_store resp_encoder)

# test 额外链接 parser，方便 R3 做一条真实接口组合检查。
add_executable(command_dispatcher_test tests/command_dispatcher_test.cpp)
target_compile_options(command_dispatcher_test PRIVATE -Wall -Wextra -g)
target_link_libraries(command_dispatcher_test PRIVATE
    command_dispatcher resp_request_parser GTest::gtest_main GTest::gtest)
gtest_discover_tests(command_dispatcher_test)
~~~

Parser 只是 test 的额外依赖；`command_dispatcher` library 自己只依赖 store 与 encoder。这和它接受 `vector<string>` 的职责一致。

使用原来的固定运行方式：

~~~bash
cd ~/code/system-learning/cpp/week10
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build -j2
cmake -E chdir build ctest --output-on-failure
~~~

只想快速看今天三条 tests 的输出，也可以直接运行：

~~~bash
./build/command_dispatcher_test
~~~

GoogleTest 断言失败时程序返回 non-zero exit code（非零退出码）；CTest 会把它记录为失败。若 CTest 输出里没有今天的 `CommandDispatcherR1Test.*`，先检查新 target 是否已 configure/build/discover，不把“原来的 tests 全通过”当成本日验证。

## 13. R1 阅读闸门

**到这里停止阅读，独立实现 `KvStore` 和六条命令，再运行上面的三条 tests。**

提交时给我看 source、测试结果，以及你选择怎样保存 key/value。核心行为可以直接用代码和口述说明，不强制另外抄一遍四个问题的答案。

R1 正式通过后，我会逐节对照你的实现，定向修改后面的 R2/R3，并保留你在本文新增的解释。下面先给完整机制讲解，留待第一版完成之后阅读。

---

# Round2：顺着一次命令，讲清状态与所有权

## 14. SET 到 GET：谁接过了哪一份数据

回到你已经写好的 parser。它处理一条完整 frame 后，返回：

~~~text
result.arguments = ["SET", "name", "FxorG"]
result.consumed_bytes = 当前 frame 的完整长度
~~~

Application caller 把这一组 arguments 交给 `execute_command(store, result.arguments)`。Dispatcher 识别到 SET，确认两项参数齐全，然后请求 store 保存 `name -> FxorG`，最后用已有 Simple String encoder 生成 `+OK\r\n`。

此时出现了两种不同寿命：

~~~text
当前 parse result 中的 arguments
    -> 这一条命令执行期间使用
    -> 之后可以析构

KvStore 持有的 name -> FxorG
    -> 保留到被覆盖、删除，或 store 析构
    -> 下一条 GET 仍然能访问
~~~

**SET 真正完成的动作是把 caller 提供的内容保存成 store 自己持有的数据。** 它可以经过复制，也可以在合适的位置移动；关键是调用结束后，store 的内容不依赖 caller 参数继续存活。

下一条 GET 只查询已有内容：

~~~text
caller 交付 ["GET", "name"]
-> dispatcher 检查 GET 的参数数量
-> store.get("name") 返回拥有内容的查询结果
-> dispatcher 把 value 交给 Bulk String encoder
-> reply = "$5\r\nFxorG\r\n"
-> caller 得到独立 reply string
~~~

你熟悉的 `Buffer::retrieve(consumed_bytes)` 仍由外层 caller/session 决定。今天的命令层只接收 arguments，不需要再去计算 RESP frame 的长度。

## 15. 谁拥有 store，谁只借用它

为什么 R1 的测试一开始构造 `KvStore store;`，然后连续执行多条命令？因为**保存位置需要比单次命令活得更久**。

Day5 的 server owner 也会做同样的事：创建一份 store，让各个 connection 的 application callbacks 访问这份 store。Client A 的 SET 与 client B 的 GET，最终到达同一个保存位置。

~~~mermaid
graph TD
    A["Server application 拥有一份 KvStore"]
    B["Client A 的 callback"]
    C["Client B 的 callback"]
    D["execute_command 借用同一份 store"]
    B --> D
    C --> D
    D --> A
~~~

图中共享的是 application data。每条 Connection 仍各自拥有 fd、input/output Buffer 和 transport flags；A 留下半条 request，也只留在 A 的 input 中。

对应到今天的接口：

| 对象 | Owner 与寿命 | 本次调用的使用方式 |
|---|---|---|
| `KvStore` | R1 test；将来是 server application | dispatcher 借用引用 |
| `arguments` | parse result 或 test caller | dispatcher 只读借用 |
| 已保存的 key/value | store | 持续保存，直到覆盖/删除/析构 |
| `get()` 返回值 | 查询 caller | 独立 snapshot，不随 store 变化 |
| `execute_command()` 返回值 | application caller | 独立 reply bytes，可交给发送层 |

`get()` 的复制语义让第一版使用简单，但会复制 value。这是明确的接口取舍，后面性能分析可以测它的代价；现在先把内容和 lifetime 做对。

## 16. 缺失与空值，为什么必须分开

假设有人保存了一个空 value：

~~~text
SET empty ""
~~~

这个操作确实创建了 key，`exists("empty")` 为 true。GET 返回的内容恰好是 0 bytes，所以 Bulk String length 为 0。

相反，查询 `missing` 得到的是**没有这一项**。`std::optional<std::string>` 同时表达“有没有结果”和“结果里的 bytes”：

~~~text
get("empty")   -> optional 有值，里面的 string.size() == 0
get("missing") -> nullopt
~~~

经过 encoder 后，区别仍保留：

| 查询结果 | RESP reply | client 得到的意思 |
|---|---|---|
| 找到空 value | `$0\r\n\r\n` | 这个 key 的 value 是空字符串 |
| 没找到 key | `$-1\r\n` | 这个 key 不存在 |

因此 GET miss 应保持 store 原样。如果内部选择关联容器，检查一次缺失 key 后，`size()` 仍应不变；查询代码要选择保留这种语义的接口。

## 17. 大小写与 binary：只改变允许改变的内容

Client 可以发 `sEt`，但 `Name` 可能就是应用选择的真实 key。于是两条输入有不同职责：

~~~text
command name：按 ASCII 字母识别对应操作
key / value：按照原始 length 与 bytes 保存和比较
~~~

若选择创建一个 command name 的规范化副本，就只处理那一个字符串。ASCII 范围判断可以明确识别 `A` 到 `Z`；其他 bytes 保留为原样，最终不匹配这六个名字。

这也延续了 Day3 的经验：从网络读到的 `char` 可能带高位字节。字符分类接口有输入范围要求，**这里要识别的是一小组固定 ASCII 命令名**，无需让 key/value 经过 locale（地区语言规则）的转换。

用一个真正的 binary value 检查整条链：

~~~cpp
// 明确长度为 4 bytes：V、NUL、CR、LF。
const std::string value("V\0\r\n", 4);
const std::string key("K\0", 2);
~~~

执行 `SET key value` 后再 GET，期望 reply 的结构是：

~~~text
$4\r\n
[V][NUL][CR][LF]
\r\n
~~~

这里 payload 自己包含的 CRLF 仍属于那 4 bytes。它和 encoder 加在 payload 后面的 terminator 各有自己的位置。

**Binary-safe 的证据是 SET、store、GET 和 encoder 全程保留了同一组 bytes。** Day3 parser 已经保证按 Bulk length 提取内容，今天不能在中间改回 `strlen()` 或以 `\0` 截断的处理方式。

## 18. 格式合法的错误命令，为什么下一条还能执行

看这条 request：

~~~text
*2\r\n$3\r\nSET\r\n$1\r\nk\r\n
~~~

Array 有两个 Bulk Strings，markers、lengths、CRLF 和 frame boundary 都完整。你的 parser 能正确返回 `Complete`，arguments 是 `{"SET", "k"}`。

但 SET 还需要 value。这时 dispatcher 返回：

~~~text
-ERR wrong number of arguments for 'set' command\r\n
~~~

**Command error（命令错误）是完整命令无法按业务规则执行。** 当前 frame 已经有明确结束位置，后面的合法 frame 仍能正常解析。Day5 的 application 可以发送这条 Error reply，再继续处理下一条命令。

Protocol error（协议错误）则由 parser 判断，例如 Bulk 的长度字段或 terminator 已经非法。外层未必能可靠找到下一条 command 的边界，本周 server 会按周规划回复后关闭这条坏连接。

两者分工完整串起来：

~~~text
parser Complete
-> dispatcher 执行命令或返回 command Error reply
-> caller 消费当前 frame
-> caller 可以继续解析下一条

parser Error
-> caller 生成 protocol Error reply
-> caller 按应用策略安排 close-after-flush
~~~

今日组件不实现上述 connection policy；它只保证 command 错误有稳定 reply、数据不被修改、下一次函数调用仍然有效。

## 19. DEL 与 EXISTS：让状态变化解释计数

已有 `a -> v`，输入 `EXISTS a a missing`。EXISTS 只是观察，三次观察都面对同一份未变化的数据：

| 本次输入位置 | 查询结果 | 累计计数 |
|---|---|---:|
| 第一个 `a` | 存在 | 1 |
| 第二个 `a` | 仍然存在 | 2 |
| `missing` | 不存在 | 2 |

所以它回复 `:2\r\n`。[EXISTS 官方说明](https://redis.io/docs/latest/commands/exists/) 明确把重复出现的已有 key 计入多次。

随后执行 `DEL a a missing`，每次删除会影响后一次看到的 state：

| 本次输入位置 | 本次实际动作 | 删除后的 state | 累计删除数 |
|---|---|---|---:|
| 第一个 `a` | 删除成功 | 已无 `a` | 1 |
| 第二个 `a` | 没有可删除项 | 不变 | 1 |
| `missing` | 没有可删除项 | 不变 | 1 |

所以 DEL 回复 `:1\r\n`。**返回值描述本次命令实际删除了多少项。** R1 的 `erase()` 返回 bool，正好能够表达一次尝试有没有产生删除。[DEL 官方说明](https://redis.io/docs/latest/commands/del/) 可用于核验。

这两条命令展示了今天真正需要关注的东西：同一个 key 的多次访问之间，state 是否发生变化，会直接影响业务结果。

## 20. 单线程 EventLoop 怎样使用这份共享数据

当前 Reactor 在一个 EventLoop thread 中 dispatch callbacks。一个 callback 执行到返回，再执行下一项工作，今天没有引入并行的 command workers。

例如：

~~~text
EventLoop dispatch A
-> A 的 callback 执行 SET name FxorG
-> store 更新完成
-> A 的 callback 返回

EventLoop dispatch B
-> B 的 callback 执行 GET name
-> 读到 FxorG
-> B 的 callback 返回
~~~

**共享 store 在这个执行模型里被串行访问，因此今天不需要 mutex。** 顺序取决于 server 实际处理命令的顺序，不能仅凭两个 clients 在各自机器上“先发送/后发送”推导出全局完成顺序。

`KvStore` 没有因此变成通用的 thread-safe class（可安全并发调用的类）。以后改变 command execution model（命令执行模型）时，才需要重新设计同步与语义；今天保留单线程路径。

## 21. 保存正确，再看这条路径的成本

你之前已经注意到 HTTP parser 的反复扫描与 RESP parser 的扫描方式不同。这种“同样正确，但工作量不一样”的观察，今天也可以延续。

若你选择 hash table（哈希表），平均查找是常说的 $O(1)$，但这是随 key 数量讨论的平均容器操作次数。读取/hash/比较一个长 key 仍要处理它的 bytes；GET 的拥有型返回值与 reply 编码也会复制 value。

如果选择其他容器，就按实际 representation 说明查找、覆盖和删除的成本。**今天先保留一个内容正确、成本能解释的 baseline（基线版本）。** 不凭一次小测试宣布“高性能”，也不提前塞入 memory pool 或 lock-free 结构。

还有一个产品边界：parser 的单 Bulk/单 frame 上限控制一次请求规模，store 的总占用会随着很多次 SET 增长。V1 今天没有总 keyspace memory cap（内存总上限），后续资源管理阶段再设计这层限制。

---

# Part3：把理解变成代表性证据

# Round3：补四组关键检查，继续维护你的 V1

## 22. 已有三个 tests，再补哪些路径

R1 的三个 tests 继续保留。后续补充只围绕下面四组不同的结论，放在同一个 `command_dispatcher_test.cpp` 中即可；不用复制一套新的 store/dispatcher。

### 22.1 空值与所有权

用空 key 保存空 value，GET 必须得到 `$0\r\n\r\n`，EXISTS 必须得到 `:1\r\n`；另一个不存在的 key 得到 `$-1\r\n`。

再建立两种寿命变化：

1. Caller 用一个 arguments vector SET，随后修改原 vector 的 key/value，store 中原来的内容仍然不变。
2. 先调用 `store.get()` 保存查询结果，再覆盖、删除原 key，保存下来的结果仍能访问原内容。

这组 oracle（判断正确与否的依据）来自 public ownership contract：SET 保存内容，GET 返回独立 snapshot。不是只检查“没崩溃”。

### 22.2 大小写与 binary round trip

使用混合大小写的 `sEt/gEt`，保存带 NUL/高位字节的 key 和带 NUL/CRLF 的 value，再比较 exact reply bytes。

例如 value 是 `std::string("V\0\r\n", 4)`，期望值应明确构造为：

~~~cpp
// prefix + 4 bytes payload + final CRLF；这里构造 test 的独立 expected。
const std::string expected = std::string("$4\r\n")
                           + std::string("V\0\r\n", 4)
                           + "\r\n";
~~~

再确认截断后的 key 查不到原记录；`std::string("GET\0", 4)` 不被当成 GET；`Name` 与 `name` 可以保存不同值。

### 22.3 错误矩阵与不污染 state

六条已识别命令各有一条 wrong arity case，检查完整固定 error text；另外检查空 vector、空 command name、unknown command。

其中一条错误放在已有 `k -> kept` 之后，再 GET 验证仍是 `$4\r\nkept\r\n`。例如 `SET k changed NX` 在 V1 返回 wrong arity，原 value 仍是 `kept`。

随后 PING 仍返回 `+PONG\r\n`。这证明错误是一次命令的结果，组件没有被推进到无法继续使用的状态。

### 22.4 用你的真实 parser 接进命令层

把下面两个完整 frames 连在同一个 string 中：

~~~text
SET frame: *3\r\n$3\r\nSET\r\n$1\r\nk\r\n$1\r\nv\r\n
GET frame: *2\r\n$3\r\nGET\r\n$1\r\nk\r\n
~~~

Caller 完成这段接口组合：

~~~text
parse 当前完整 range
-> Complete，arguments 为 SET/k/v
-> consumed_bytes 恰好是 SET frame 长度
-> execute_command 返回 +OK\r\n

caller 从相应 suffix 再 parse
-> Complete，arguments 为 GET/k
-> consumed_bytes 恰好是 GET frame 长度
-> 使用同一个 store 执行，得到 $1\r\nv\r\n
~~~

今天只要这一条组合证据：parser 的实际输出能喂给 dispatcher，store 的变化能穿过 encoder 回到 exact reply。Fragmentation 已在 Day3 覆盖，这里无需重新遍历每一个 split point。

这些 correctness tests（正确性测试）的重复调用与断言可以委托我补充；你需要能说明输入怎样建立状态、expected 来自哪条语义。测试工作量的分工，不改变证据必须存在的要求。

## 23. 编译与 ASan/UBSan：看它们分别证明什么

先按 §12 运行 normal build 和全量 CTest。今天的结果要同时包含新 tests 和已有 tests，以确认新 target 的依赖没有破坏原工程。

再使用独立 sanitizer build，避免覆盖普通构建：

~~~bash
cmake -S ~/code/system-learning/cpp/week10 \
    -B /tmp/week12-day4-sanitize/build \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_FLAGS="-fsanitize=address,undefined -fno-omit-frame-pointer" \
    -DCMAKE_EXE_LINKER_FLAGS="-fsanitize=address,undefined -no-pie"

cmake --build /tmp/week12-day4-sanitize/build -j2
cd /tmp/week12-day4-sanitize
cmake -E chdir build ctest --output-on-failure
~~~

PIE 是 Position Independent Executable（位置无关可执行文件）；`-no-pie` 表示这个临时 build 的 executable 不采用 PIE 链接，沿用本机已经验证可运行的 sanitizer 配置。运行命令仍是我们约定的 `cmake -E chdir build ctest --output-on-failure`。

**GoogleTest 比较语义结果；ASan/UBSan 在实际走到的路径上检查内存错误与未定义行为。** 空值与缺失混淆、DEL 计数错了，通常需要 exact assertions 才能发现；dangling memory 或非法访问则属于 sanitizer 要观察的路径。

本日没有新增 user threads，使用 TSan 不会额外证明命令语义。若出现失败，先区分普通 test assertion、sanitizer report 与 build/link error，再检阅对应 source。

本教程发布前，独立临时参考工程已经复用你的 encoder/parser 编译验证：normal 与 ASan/UBSan 均 `78/78 PASS`，包括已有 71 项与新增 7 个代表性 tests。**这是教材接口与样例的验证，不是你的 Day4 验收结果。**

## 24. 验收时需要你能解释的内容

以下问题可以用 source、test 或口述回答，不要求另抄长篇笔记：

1. 一条 SET 结束后，保存的 key/value 与 parser arguments 各由谁拥有？
2. 空 value 与缺失 key 在 `optional` 和 RESP reply 上分别怎样表达？
3. `EXISTS a a` 与 `DEL a a` 为什么可能返回不同数值？
4. `SET k` 的 parser 结果和命令执行结果分别是什么？下一条 PING 能否继续执行？
5. 将来两条 Connection 为什么能共享数据，而各自的 partial input 仍相互隔离？

代码已经证明的基础用法不用重复写成验收题。若某处实现与口述冲突，以实际路径核对，不根据“我觉得没问题”跳过真实错误。

## 25. 今日完成线与下一步

今天通过需要：六条命令与固定错误回复正确；覆盖不增加 key 数，miss 不创建 key；缺失/空值、binary、命令名大小写和所有权有代表证据；normal build 零 warning，全量 CTest 与 sanitizer covered paths 通过。

笔记只保留本日真正新增的直觉、你自己的设计取舍和遇到的问题。没有必要重新介绍熟悉的 `vector/string`，也不用为这两个组件写一套项目 README。

**Day5 才让这套东西通过 TCP 被使用。** 那一天继续沿用你的 Connection、deferred cleanup 和 EventLoop，在 application callback 中串起 parser、同一份 store、dispatcher 与发送层；今日写好的 command code 会直接成为 server 的业务核心。

当前范围保持 string KV、单线程执行、进程内保存。TTL、持久化与正式 benchmark 已在后续周安排，不挤进今天的第一版。
