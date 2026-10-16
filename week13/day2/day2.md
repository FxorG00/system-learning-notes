# Week13 Day2：让 KvStore 的 key 按时失效

> 版本：2026-10-14，状态模型先行版；依据当前 KvStore 与网页建议调整知识次序
> 今日产出：升级原 KvStore 的时间语义，用可控时间验证有效期；今天不接新网络命令
> 阅读顺序：Part 1 -> Round1 -> 停下独立实现 -> Round2 -> Round3

[TOC]

---

# Part 1：前情提要与必要术语

## 1. 今天只解决一件事

**让同一份 key/value 在到期前还能读，时间一到便按不存在处理。**

你已经能保存验证码：

```text
key   = "code:alice"
value = "483921"
```

但原来的 KvStore 只判断 key 是否在 map 里。只要没人删除，这份验证码就一直可以取出来。

今天给它增加一个有效期。先用一个很短的教学时间线：在当前时间 1000ms 时，规定它再有效 2000ms。

```text
当前时间 1000ms：设置有效期 2000ms
当前时间 2999ms：仍能读到 "483921"，剩余 1ms
当前时间 3000ms：已经到期，GET 按不存在处理
当前时间 3001ms：仍按不存在处理
```

**测试必须能直接把时间推进到这些位置，而不是让程序真的睡两秒。**

这就是今天的完整目标：数据有时间上的有效性，测试能精确控制判断发生的时刻。

### 1.1 先看一条带有效期的记录

设置以后，这份数据在逻辑上包含：

~~~text
key      = "code:alice"
value    = "483921"
deadline = 3000ms，从这个时刻开始失效
~~~

这里的 record（记录）是一份 key 对应的数据；deadline（到期时刻）是它失效的时间位置。没有设置有效期的记录，就没有这条时间限制。**这只是对外语义的模型，怎样用 C++ 成员保存它，仍由你设计。**

现在分别看两个时刻：

~~~mermaid
graph LR
    R["同一份记录：code:alice / 483921 / 到期位置 3000ms"]
    R --> A["现在 2999ms：记录在，可读，剩余 1ms"]
    R --> B["现在 3000ms：记录在，已经不可读"]
~~~

图里的两条线表示同一份记录在两个时刻的观察，不是两份数据。时间推进到 3000ms，并没有自动替你执行删除；它先改变了“这份验证码现在还能不能交给调用者”。

因此要分开两件事：

- **Physical existence（物理存在）：组件里还保存着这份记录。**
- **Logical existence（逻辑存在）：按当前时刻判断，调用者仍能把它当成有效数据使用。**

一份记录当前有效，需要同时满足：

$$
\text{有效}
=
\text{保存着记录}
\land
\left(\text{没有期限}\lor\text{now}<\text{deadline}\right)
$$

**恰好相等时已经失效。** 过期判定与删除记录是两个动作；今天先建立判定，后续 Day4 再安排有限回收。

### 1.2 这些接口是在观察同一份状态

只考虑组件里这一条记录：

| 当前状态 | `get` 取内容 | `exists` 问是否有效 | `pttl` 查询剩余毫秒 | `size` 数物理记录 |
|---|---|---|---|---|
| 记录在，没有期限 | value | true | -1 | 1 |
| 记录在，到期位置 3000，当前 2999 | value | true | 1 | 1 |
| 记录在，到期位置 3000，当前 3000 | nullopt | false | -2 | 1 |
| 记录已被删除 | nullopt | false | -2 | 0 |

`pttl` 的 -1 表示有效但没有期限，-2 表示没有有效 key。这些是状态结果，不是异常。

所以 `get/exists/pttl` 先回答“当前是否有效”，再交付各自的结果；`size` 只回答“还保存几条记录”。`erase` 则真的删除记录，返回值计的是这次删掉的有效 key，详细约定见 §8。

后面增加接口时，都围绕这份状态展开，不需要把它们记成互不相关的几套规则。

## 2. 接着你已经写好的东西继续

Week13 Day1 已正式通过 `98/100`。你现在能区分：同一个索引定位候选，查询需要的字段不同，后面的取数路径也可能不同。MySQL 入口先收住，今天回自己的 Mini Redis。

生成时只读检查的实际代码仍在：

```text
/home/xgf/code/system-learning/cpp/week10
```

你的 KvStore 当前使用 `std::map<std::string, std::string>`；`get/exists` 是 const，`get` 返回独立拥有内容的 `std::optional<std::string>`，`size()` 返回物理保存的条目数。

当前主要动作是：

| 原接口 | 你已经实现的行为 | 今天新增的关系 |
|---|---|---|
| `set` | 保存或覆盖 value | 普通覆盖还要清除旧有效期 |
| `get` | 找到 key 就复制 value 返回 | 返回前还要确认这份数据仍有效 |
| `exists` | 判断容器里有没有 key | 判断当前时刻是否存在有效 key |
| `erase` | 删除并返回是否成功 | 过期 key 不计入成功删除的有效 key |
| `size` | 返回 map 的条目数 | 继续保持物理数量口径 |

Week12 你已经正确解释了：**SET 先修改共享 store，再生成回复；回复是否送达，是 Connection 的后续工作。** 今天给 store 增加时间判断，原 bytes 传输链继续复用。

今天不是继续写一坨 parser。RESP parser、reply encoder、Connection、EventLoop 和 main owner 都先保留。

## 3. 带着四个问题进入正文

1. 存在于容器里的 key，为什么可能已经不能读取？
2. 怎样让同一份 store 在真实运行和测试中使用不同的时间来源？
3. 恰好到期、普通 SET 覆盖、删除后重建，各自应该得到什么结果？
4. 时间有单位和范围，怎样拒绝无效设置并保留原状态？

接口约定回答“今天怎样算对”；后半教程再把这些约定与实际机制串起来。

## 4. 先给时间线上这几个对象命名

### 4.1 TTL：还允许存活多久

`TTL = Time To Live`，生存时间。**它是一段长度，例如从现在起再有效 2000ms。**

这里的 `ms = millisecond`，毫秒。1000ms 等于一秒。本日组件统一使用整数毫秒。

网络里的 IP TTL 表示转发跳数预算；此处是 key 的时间长度。同名术语在不同场景承担不同职责。

### 4.2 deadline：从哪个时刻开始失效

`deadline`，到期时刻。**它是时间线上的一个位置，例如 3000ms。**

当前时间是 1000ms，允许再有效 2000ms，到期位置便是 3000ms。

本项目约定：**当前时间达到 deadline，就已经失效。** 到期前与恰好到期必须分开测。

### 4.3 clock：给组件提供当前时刻

`clock`，时钟，今天具体指“能告诉 KvStore 当前是多少毫秒”的时间来源。

真实运行时，时间来源读取单调时钟。测试时，时间来源可以读取你自己控制的整数变量。

这样的可控时间来源叫 `fake clock（测试时钟）`。它不要求等待现实中的时间流逝。

`clock injection（时钟注入）` 指：**创建组件时，把获取当前时间的能力传进去。** 组件照样判断有效性；测试可以替换时间来源。

具体调用语法在 Round1 的 API 小例子里讲，不要求先建立继承体系。

---

# Part 2：教程主体

**教程开始。**

## Round1：先在原 KvStore 上独立完成第一版

## 5. 先看今天这个组件到底干什么

今天升级的仍是一个普通 C++ 内存组件 `KvStore`。

它接收 key/value、调用者指定的有效长度以及当前时间来源。它负责保存数据，并回答：**在这次操作观察到的时刻，这份数据是否仍然有效？**

返回结果继续交给 caller，调用者。将来 command dispatcher，命令分发器，会把结果交给已有 encoder 编成 RESP 回复。

```text
今天的输入：key/value + 有效长度 + 时间来源
          |
          v
       KvStore
          |
          +--> 返回拥有自己内容的 value，或者不存在
          +--> 返回有效 key 是否存在/是否删除
          +--> 返回剩余毫秒数或状态标记
```

这是 application/storage 层，即应用协议背后的数据状态。它位于服务器进程的 user space，用户空间。

在整体服务中的位置是：

```text
Application 层：RESP request -> dispatcher -> KvStore -> reply encoder
Transport 层：TCP 提供有序 byte stream
Internet 层：IP 负责跨网络传递 packet
Link 层：Ethernet 等负责当前链路上的 frame
```

今天单测 KvStore，不经过下面三层。这样的拆分让你能把时间固定到 2999ms 或 3000ms，不必同时处理 socket 调度和网络延迟。

Day3 才把两条命令接进 dispatcher，Day5 再做真实 TCP 有效期检查。当前阶段**key 到期不会要求关闭 Connection**；客户端仍能在原连接上继续发送其他命令。

### 5.1 为什么时间必须成为可替换的输入

到期位置已经明确了，判断还需要“现在”。如果组件内部固定读取真实时钟，测试就不能稳定指定“这一次恰好是 2999ms，下一次恰好是 3000ms”。

因此让 KvStore 依赖一项能力：**调用它，得到当前毫秒数。** 真实运行提供真实时钟，测试提供读取整数变量的能力。创建组件时传入这种能力，就是前面命名的 clock injection。

测试的完整调用关系是：

~~~text
fake_now = 1000
-> 用“读取 fake_now 的能力”创建 store
-> SET 保存内容；expire_ms 设置再有效 2000ms
-> 到期位置成为 3000ms

fake_now = 2999
-> caller 调用 get
-> KvStore 调用传入的取时间能力，得到 2999
-> 当前记录有效，交付 value

fake_now = 3000
-> caller 再调用 get
-> 同一能力读取变量的新值 3000
-> 当前记录失效，返回 nullopt；记录仍保留
~~~

**传入的是以后还能调用的能力，不是创建时的一个固定时间数值。** 这就是下一节需要 callable（可调用对象）的原因。`std::function` 只负责表达这项能力，语法小例子见 §10。

## 6. 本次维护哪些文件

继续使用原工程，不创建另一份 week13 服务器：

```text
include/mini_redis/kv_store.hpp  -> 原 KvStore 的声明与 private representation
src/kv_store.cpp               -> 原 KvStore 的实现
tests/kv_store_ttl_test.cpp     -> 今天新增的组件检查
CMakeLists.txt                 -> 只追加新 test target，原 targets 保留
```

`private representation（内部表示）` 指组件用来保存和组织数据的成员与结构。这部分由你决定。教程只规定对外行为，不先替你选第二张 map、Entry 类型或清理算法。

下面的小 checker 已给出，你可以直接放进新 test 文件。重复 GTest 语法不是今天重点；你需要知道每个时间点为何应该得到那个结果。

## 7. Public API：调用者能用什么

保留原五个接口，再增加可替换时间来源、设置有效期和查询剩余时间：

```cpp
#pragma once
#include <cstddef>
#include <cstdint>
#include <functional>
#include <optional>
#include <string>

class KvStore {
public:
    using TimeMs = std::int64_t;
    using Now = std::function<TimeMs()>;

    KvStore();
    explicit KvStore(Now now);

    void set(std::string key, std::string value);
    std::optional<std::string> get(const std::string& key) const;
    bool erase(const std::string& key);
    bool exists(const std::string& key) const;
    std::size_t size() const noexcept;

    bool expire_ms(const std::string& key, TimeMs ttl_ms);
    TimeMs pttl(const std::string& key) const;

private:
    // 由你设计内部存储与时间来源的保存方式。
};
```

这是 public declaration，公开声明，不是让你把原 private 内容全部删除。修改原 header，保留适合你的内部实现与注释；上面只列出本日要对齐的公开接口。

`using TimeMs = std::int64_t` 给有符号 64 位整数起一个单位明确的名字。使用有符号类型也让 `pttl` 能返回 -1/-2。

`Now = std::function<TimeMs()>` 的含义是：**一个不接收参数、调用后返回当前毫秒数的 callable（可调用对象）**。例如一个 lambda 就可以成为 Now。

这不是“把一个固定时间传进去”。**传进去的是获取时间的能力**，组件以后每次需要判断时间时再调用它。

本日不用虚基类来实现 clock。虚函数的独立补缺仍按 Week13 Day7 安排，不抢到 TTL 开工前。

## 8. 从状态模型推出接口的功能

先创建时间来源、保存内容，再设置期限、查询状态；最后看真正删除与物理计数。下面规定的是调用者能观察到什么，内部组织仍由你决定。

### 8.1 两个 constructor：怎样创建 store

```cpp
KvStore store;
```

默认构造使用 `std::chrono::steady_clock` 提供进程内的非负、单调毫秒读数。可选择创建 store 时刻等固定起点，从此计算经过的时间；同一 store 的所有读数必须采用同一个起点。

```cpp
KvStore store(read_now);
```

显式构造接收 Now，组件保存一份 callable，之后使用它获取当前时刻。`explicit` 的意思是这次构造需要明确调用，不让一个函数对象隐式变成 KvStore。

传入空的 `std::function` 时抛 `std::invalid_argument`。测试时间必须由 caller 保证不倒退；相同时间连续调用是允许的。

### 8.2 `set`：保存新内容，同时取消旧有效期

```cpp
store.set("code:alice", "483921");
```

普通 SET 的结果是：这个 key 保存给定 value，当前没有有效期。若之前有旧 value 或旧有效期，本次成功覆盖后都以新状态为准。

key 已经过期但仍物理保存在组件里时，SET 也能建立新的有效数据。新值从这次 SET 起没有有效期。

空 key、空 value、含 `\0` 的 string 继续按长度保存。原来的 binary-safe，二进制安全，保证不改变。

### 8.3 `get`：取当前仍有效的 value

```cpp
auto value = store.get("code:alice");
if (value) {
    // *value 是调用者独立拥有的一份 string。
}
```

物理没有 key，或者当前已经到期，都返回 `std::nullopt`。没有设置有效期、或尚未到期，返回 value 的 owning copy，独立拥有的副本。

保留原 `const` 声明。**今天的 get 不擦除内部记录，也不修改其有效期。** 它可以读取时间来源并据此决定是否交付 value。

### 8.4 `exists`：判断此时是否存在有效 key

```cpp
bool present = store.exists("code:alice");
```

无 key 或已到期返回 false；永久有效或尚未到期返回 true。保留 const，并与 get 采用相同的到期边界。

### 8.5 `expire_ms`：给有效 key 设置从现在起的生存长度

```cpp
bool applied = store.expire_ms("code:alice", 2000);
```

这里的 2000 单位是**毫秒**，不是到期时刻、秒数或字符串长度。当前时刻为 1000ms，本次设置把到期位置定为 3000ms：

$$
\text{deadline}=\text{now}+\text{ttl}=1000+2000=3000\text{ms}
$$

没有设置期限时，记录一直有效；成功设置后，后续查询按这个到期位置判断。

| 输入与当前状态 | 返回/状态 |
|---|---|
| key 有效，正 ttl 可表示 | 返回 true；替换为本次设置的有效期 |
| key 有效，ttl 为 0 或负数 | 返回 true；立即删除该 key 及有效期 |
| key 无有效数据 | 返回 false；不把失效数据重新变有效 |
| 正 ttl 与当前时间组合越界 | 抛 `std::overflow_error`；保留原状态 |

已经设置过有效期时，再设置会替换旧有效期，不要求只能缩短。结果以**本次设置的时刻**为起点。

本日只做 C++ 组件方法；`expire_ms` 不是新加的 RESP wire command，线上协议命令。Day3 的 EXPIRE 参数使用秒，转换工作到时在 dispatcher 中完成。

### 8.6 `pttl`：查询当前状态或剩余毫秒

```cpp
KvStore::TimeMs remaining = store.pttl("code:alice");
```

`PTTL` 是 Redis 中以毫秒查询剩余 TTL 的命令名。这里先实现同名组件能力，尚未增加命令分支。

| 返回值 | 明确含义 |
|---|---|
| 正数 | 当前仍有效，返回剩余毫秒数 |
| `-1` | key 有效，但没有设置有效期 |
| `-2` | 不存在有效 key，包括已到期 |

在本项目整数毫秒、达到 deadline 即失效的约定下，带期限且仍有效时至少剩余 1ms，恰好到期返回 -2。**本项目不把 0 当作“永久”。**

pttl 保留 const，不擦除记录。不要把合法状态 -1/-2 当成异常；稍后 encoder 会把它们编成普通 RESP Integer reply。

这组状态标记与 Redis 2.8 以来的基本约定对齐，精确相等边界按本周项目 contract 执行。[PTTL 官方说明](https://redis.io/docs/latest/commands/pttl/)

### 8.7 `erase`：删记录，但返回有效 key 的删除结果

```cpp
bool removed_live_key = store.erase("code:alice");
```

物理有这个 key 时，本次调用删除它及其有效期信息。返回 true 表示调用观察时它仍是有效 key；已过期的记录即使被顺手回收，也返回 false。

物理没有 key 时返回 false。这样将来 DEL 的计数表示“删除了多少有效 key”，不会把已经失效的记录重新计成一个存在的数据。

### 8.8 `size`：仍是物理保存的条目数

```cpp
std::size_t stored_entries = store.size();
```

它继续返回内部保存的 key/value 记录数量，不读取 clock、不清理、不统计当前有效 key 数。

因此，某 key 已到期后，get 可以返回不存在，而 size 暂时仍是 1。这个口径是本日刻意保留的观测，Day4 用它区分有效性判断与实际回收。

## 9. 主线跑通后，再补最终范围与错误约定

下面的 error contract（错误约定）提前列清，避免后半验收突然增加未声明的要求。**首版先使用有效的时间来源、非负单调读数和可表示的到期位置，完成 §11 的时间线；这里的异常路径可留到 R2/R3 补齐。** 整日最终验收仍会核对它们。

### 9.1 本日支持范围

TimeMs 使用 `std::int64_t`。当前时刻与保存的到期时刻都必须在非负可表示范围内：

```cpp
std::numeric_limits<KvStore::TimeMs>::max()
```

上面第二行来自 `<limits>`，返回这个整数类型的最大值。不要另外手写一个可能位数不对的长常量。

`ttl_ms` 本身可以是 TimeMs 的任意值；非正值按立即删除处理。正值还需要满足“从当前时刻开始设置后的到期位置能表示”。整日完成前需要正确处理范围失败；首版可以先运行范围内的时间线，范围保护在后半打磨。检查表达式与计算顺序由你设计。

**一次需要观察时间的 store 调用，使用一个当前时间快照完成该次判断。** 时钟可以在两次不同调用之间推进；同一次操作的有效性与剩余长度不能混用两个读数。

错误优先级也定清楚：expire_ms 先验证本次 clock 读数与正 ttl 的可表示范围；验证失败就抛异常，即使 key 原本不存在。验证通过后才按有效 key 是否存在返回 true/false。

### 9.2 哪些情况抛什么

| 情况 | 行为 | 参考英文 error message |
|---|---|---|
| 显式构造传入空 Now | `std::invalid_argument` | `clock callback must not be empty` |
| 时间来源返回负毫秒数 | `std::invalid_argument` | `clock must return non-negative milliseconds` |
| 正 ttl 造成 deadline 超出 TimeMs 范围 | `std::overflow_error` | `TTL deadline out of range` |
| 用户提供的 Now 调用时抛异常 | 原异常继续传播；本次操作不改 store 状态 | 保留时间来源的诊断 |
| key 不存在/已过期 | 使用 nullopt、false 或 -2 的正常结果 | 不需要报错 |

异常类型是约定，英文句子提供参考，不把措辞差异变成通过条件。使用对应异常需要 `<stdexcept>`。

上述输入/时间失败都必须发生在修改当前状态之前。这里要求的是这些**明确列出的错误路径**保留状态；不新增全容器内存分配失败注入工程。

测试 clock 的负值会被拒绝；“非负但倒退”的时间来源违反本日前置约定，由 caller 保证单调，不要求组件新增历史读数检测器。

## 10. 开工前只补这些 API 用法

### 10.1 `steady_clock`、`time_point`、`duration`

`steady_clock（单调时钟）` 的读数不会随时间前进而减小，适合测量进程内经过多久。普通日历时间会受校时影响；本项目 TTL V2 选择前者。[C++ steady_clock 定义](https://eel.is/c++draft/time.clock.steady)

在 `<chrono>` 中：

```cpp
using Clock = std::chrono::steady_clock;
Clock::time_point start = Clock::now();
```

`now()` 返回 `time_point（时间点）`，即这只时钟时间线上的位置。两个时间点相减得到 `duration（时长）`。

```cpp
auto elapsed = later - start;
auto elapsed_ms =
    std::chrono::duration_cast<std::chrono::milliseconds>(elapsed);
auto number = elapsed_ms.count();
```

`duration_cast` 负责时长单位转换；`count()` 才取出数值。源时长转成整数毫秒时，会舍去不足一毫秒的部分。它没有让线程等待，也没有设置定时任务。[duration_cast 标准定义](https://eel.is/c++draft/time.duration.cast)

### 10.2 一段可以单独跑的最小例子

这段只验证 chrono 和 Now 的调用形态，不实现 KvStore。你可以在临时文件运行，不必作为另一份今日产出保存。

```cpp
// chrono/callable 语法小例子：单位换算，以及同一函数对象读取变化的时间。
#include <chrono>
#include <cstdint>
#include <functional>
#include <iostream>

int main() {
    using Clock = std::chrono::steady_clock;
    const auto start = Clock::now();
    const auto later = start + std::chrono::milliseconds{1500};
    const auto elapsed =
        std::chrono::duration_cast<std::chrono::milliseconds>(later - start);
    std::cout << "elapsed_ms=" << elapsed.count() << '\n';

    std::int64_t fake_now = 1000;
    std::function<std::int64_t()> read_now = [&fake_now] {
        return fake_now;
    };
    std::cout << "now_ms=" << read_now() << '\n';
    fake_now = 2999;
    std::cout << "now_ms=" << read_now() << '\n';
}
```

假设临时文件叫 `chrono_clock_demo.cpp`：

```bash
g++ -std=c++17 -Wall -Wextra -g chrono_clock_demo.cpp -o chrono_clock_demo
./chrono_clock_demo
```

输出：

```text
elapsed_ms=1500
now_ms=1000
now_ms=2999
```

这里没有真的等 1500ms。第二个时间点是从第一个位置向后构造出来的；这个例子测试单位，不测试机器调度。

`[&fake_now]` 表示 lambda 借用这个变量。函数对象被复制后，仍读取同一个 fake_now，所以修改变量会影响之后的调用。fake_now 必须比使用它的 store 活得久。

真实时钟接法由你放进默认 constructor；测试 constructor 则接收这种 callable。组件保存自己的 Now 对象，而不是借用 constructor 参数对象的地址。

无论传入的是哪种时钟的 callable，对我们类内部写法没有任何影响，都是 callable 在内部视角。

## 11. 给你一个最小 KvStore checker

把下面内容放进新文件 `tests/kv_store_ttl_test.cpp`。它只通过公开 API 使用你的组件，不规定内部成员。

```cpp
// 一个受控时间线：验证同一份数据在到期前存在，恰好到期时失效。
#include "kv_store.hpp"
#include <gtest/gtest.h>
#include <string>

TEST(KvStoreTtl, ExactDeadline) {
    KvStore::TimeMs fake_now = 1000;
    KvStore store([&fake_now] { return fake_now; });
    store.set("code:alice", "483921");
    EXPECT_EQ(store.pttl("code:alice"), -1);
    ASSERT_TRUE(store.expire_ms("code:alice", 2000));
    EXPECT_EQ(store.pttl("code:alice"), 2000);

    // 当前读数由测试指定，component 不需要 sleep。
    fake_now = 2999;
    const KvStore& view = store;
    const auto value = view.get("code:alice");
    ASSERT_TRUE(value.has_value());
    EXPECT_EQ(*value, std::string("483921"));
    EXPECT_TRUE(view.exists("code:alice"));
    EXPECT_EQ(view.pttl("code:alice"), 1);

    fake_now = 3000;
    EXPECT_FALSE(view.get("code:alice").has_value());
    EXPECT_FALSE(view.exists("code:alice"));
    EXPECT_EQ(view.pttl("code:alice"), -2);
    EXPECT_EQ(view.size(), 1u);

    fake_now = 3001;
    EXPECT_FALSE(view.get("code:alice").has_value());
    EXPECT_EQ(view.pttl("code:alice"), -2);

    // 普通 SET 建立无期限的新状态，旧到期位置不能继续约束新值。
    store.set("code:alice", "new-code");
    EXPECT_EQ(view.get("code:alice"), std::optional<std::string>("new-code"));
    EXPECT_EQ(view.pttl("code:alice"), -1);
}
```

这个 checker 的 oracle，预期结果依据，来自第 1 节时间线与 public contract。它没有调用你的 private helper，也不复用你的到期判断公式来算预期。

`const KvStore& view` 验证查询可以经 const 接口调用；`size()==1` 验证这些查询没有物理删除记录。

GTest 的 EXPECT/ASSERT 失败会让这个测试 executable 非零退出，CTest 也会标成失败。**不要另外打印 PASS 来替代断言结果。** 通过后的测试摘要会包含：

```text
[  PASSED  ] 1 test.
```

这是实现完成后应观察到的结果，不表示你当前源码已经通过。现有 V1 尚没有这些新接口。

## 12. CMake 与第一次编译运行

原工程已经有 `kv_store` library、GoogleTest 和 `gtest_discover_tests`。保留原构建内容，只追加：

```cmake
# TTL 组件检查复用原 kv_store library 和原 GoogleTest 配置。
add_executable(kv_store_ttl_test tests/kv_store_ttl_test.cpp)
target_compile_options(kv_store_ttl_test PRIVATE -Wall -Wextra -g)
target_link_libraries(kv_store_ttl_test PRIVATE
    kv_store
    GTest::gtest_main
    GTest::gtest
)
gtest_discover_tests(kv_store_ttl_test PROPERTIES TIMEOUT 5)
```

`kv_store` 的 PUBLIC include 路径会传播给这个 test，所以它继续用 `#include "kv_store.hpp"`，不用绝对路径。

在 Ubuntu 原工程运行：

```bash
cd /home/xgf/code/system-learning/cpp/week10
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build --target kv_store_ttl_test
cmake -E chdir build ctest --output-on-failure -R '^KvStoreTtl\.'
```

第三行构建新增的测试 executable；第四行仍是约定的 CTest 入口，只用 `-R` 正则筛选当前测试名。它不会要求启动 Mini Redis server 或 MySQL。

你升级 header/implementation 后，最终还要 build 整个原工程，确认原 server 与 dispatcher 的调用继续兼容；这一步在 Round3 收口。

## 13. 到这里停止阅读，独立实现 R1

现在你已看懂“记录 + 到期位置 + 当前时刻”的状态模型，也有用途、准确文件名、接口、最小 checker 与真实 build/run 入口。

**先独立完成一条能运行的 TTL 主线，再继续读 Round2：**

~~~text
fake clock 提供当前毫秒
-> SET 保存内容
-> expire_ms 设置期限
-> get/exists/pttl 在到期前、恰好到期、到期后给出一致结果
-> const 查询保留物理记录，size 仍能观察它
-> 普通 SET 覆盖后清掉旧 TTL
~~~

内部怎样组织 value/期限、怎样保存并使用时间能力，由你自己决定。原五个接口继续保留，不能为了新主线破坏已有正常调用。

R1 提交时先给：

- 升级后的原 header/source。
- 上述小 checker 的真实运行结果。
- 一句解释：你的当前时间来自哪里，如何在测试中推进它。

本轮要求分三层，不把所有边界都压进第一次 coding：

| 阶段 | 完成什么 | 验收位置 |
|---|---|---|
| R1 主线 | 可控时间、§11 精确边界、get/exists/pttl 一致、普通 SET 清旧 TTL | 先按这一范围检阅首版 |
| 状态稳固 | 过期记录的 erase 返回值、期限替换、删除重建、非正长度 | R2/R3 结合真实代码打磨 |
| 范围与异常 | 空 Now、负时间、deadline 越界、异常传播和失败保留状态 | R2/R3 补齐，整日收口核对 |

如果后两层还没写，提交时注明即可；它们是已声明的后续升级，不是首版偷偷漏做的任务。额外机械 tests 可以在 review 时授权我补，不要求今天独立手写几十个 cases。

读到这里先停。下面是机制对照，会在你的 R1 正式通过时按真实实现逐节定向润色，保留你学习中新增的内容。

---

## Round2：顺着你的 node、now_ 和真实修复继续

> 后半定向校准：2026-10-16；R1 正文与学习中增补保留。

**你的 R1 已正式通过，100/100。** 本轮当前源码完整构建零 warning，原工程 CTest `75/75 PASS`；同一组私有检查 `14/15 PASS`，两个时间快照检查均已通过。剩下的一项是本来就安排在后半的错误优先级，不把它追溯成 R1 扣分。

接下来保留你的 `map<string, node>`，只完善三个真实位置：**缺失/过期 key 的校验顺序、非正 TTL 分支的二次取时、默认时钟捕获 this 的生命周期。** 已经正确的状态判断不重写。

下一步重点读 §15 的非正长度分支、§18、§19.2，再按 §21 动手。§14/16/17 是对你已写机制的对照，可以快读。

## 14. 你的记录现在怎样表示三种状态

你的 `node` 已把 value 和 deadline 放在一起：

| 你的实际数据 | 对外含义 | 查询怎样处理 |
|---|---|---|
| `data_.find(key) == data_.end()` | 没有物理记录 | get/exists/pttl 返回各自的缺失结果 |
| `node.deadline == -1` | 记录有效，没有期限 | 可以交付 value；pttl 返回 -1 |
| `node.deadline >= 0` | 记录有到期位置 | 结合本次时刻判断，达到该位置就失效 |

这里的 -1 是你选定的 sentinel（哨兵值）：**用一个专门的数值表示“没有期限”。** 本项目合法到期位置是非负数，因此它与真实 deadline 不冲突。可以保留，不需要为了教程换成 optional。

你现在的 get 已沿这条链执行：

~~~mermaid
graph TD
    A["caller 调用 get"] --> B["data_.find 找到 node"]
    B --> C{"是否找到记录？"}
    C -->|否| D["返回 nullopt"]
    C -->|是| E["调用 now_ 并检查读数"]
    E --> F{"deadline 为负一，或 now 小于 deadline？"}
    F -->|是| G["复制 it->second.value 返回"]
    F -->|否| D
~~~

图里的返回缺失没有经过 `data_.erase`。这正是你用 const 查询兑现“逻辑失效、物理保留”的位置；`size()` 因而仍可以是 1。

## 15. 你的 clock 已接通：这轮修复究竟修了什么

默认 constructor 先保存 `start = Clock::now()`，再把一个 lambda 放入 `now_`。每次调用它，计算：

~~~text
Clock::now() - start
-> duration_cast<milliseconds>
-> count()
-> 本次当前毫秒数
~~~

注入 constructor 则把传来的 Now 保存到 `now_`。你在正文补充“内部都作为 callable 使用”，理解正确：store 通过同一个接口读取当前时刻。

### 从“能取时间”到“同一次操作用同一份时间”

你最初在 pttl 中先调用 exists，再调用 now_。它们得到的可以是两个时刻：

~~~text
exists 内：now = 2999，deadline = 3000，判断有效
pttl 内：now = 3000，用另一个读数计算剩余长度
-> 得到 0
~~~

这里没有新线程，也没有 data race；**真实时间本来就在推进**。测试中每次取时递增的 fake clock，只是把这个关系稳定地暴露出来。

你最后的修法已经正确：pttl 在外层取得一次 `now_ms`，有效性判断和 `deadline - now_ms` 共用它。中间那次复检还发现内层同名声明；这叫 shadowing（变量遮蔽），内层变量会暂时盖住外层同名变量。最终你已移除内层的重复取时。

本轮相同检查确认：PTTL 只取时一次、返回 1；expire_ms 的正 TTL 路径也只取时一次，新期限以同一个读数为起点。**这两个修复已经完成，后半不再让你重做。**

### 非正 TTL 分支还有一次间接取时

你的 expire_ms 在 `ttl_ms <= 0` 时调用公开的 erase。erase 自己还会调用 now_，于是这条路径仍然有两次取时：

~~~text
expire_ms 取得 now_ms，确认当前 key 有效
-> ttl_ms <= 0
-> 调用 erase
-> erase 再取得另一个当前时刻
~~~

固定 fake_now 时结果可以正确，所以现有零/负 TTL 私有检查已通过；它没有证明调用次数也是一次。

**这里的升级动作很小：使用本次已经找到的记录和时间判断完成删除，让这一分支不再经公开 erase 重新取时。** 非正长度是 R1 明确允许后置的路径，因此现在补，不追扣首版。

两次独立 API 调用仍可以观察到不同时间。Day3 再处理一条多 key 命令的一致时间观测，今天的方法快照不等于整条命令快照已经完成。

## 16. 你的 const 查询为什么可以“读到过期”

get/exists/pttl 都保留 const；它们没有修改 `data_` 中的 node。改变的是 now_ 下一次提供的时间读数。

例如同一个 `node{"483921", 3000}`：

~~~text
2999ms：查询交付 value
3000ms：查询交付缺失结果
两次查询之后：node 仍保存在 data_ 中
~~~

const 约束当前对象的数据修改，不会把外部时间冻结。你现在用 find 而不是 operator[] 做查询，也保持了“读取不插入记录”的边界。

`lazy expiration（访问时判定过期）` 的第一层已经在你的查询中成立。真实 Redis 的访问时过期路径还会删除记录；你本日选择 const 查询只判定，物理删除由 erase 或 Day4 维护完成。

这就是 Day4 需要独立证据的原因：**当前读不到，只证明失效规则成立；物理条目减少，才证明某次回收发生过。**

## 17. 你的状态替换已经正确，按需对照即可

### 17.1 SET 一次替换 value 与期限

你写的是 `data_[key] = node{value, -1}`。它整体建立新状态，所以普通 SET 不只改 value，也清掉旧期限。

本轮独立检查已验证：1000ms 设置到 3000ms，2000ms SET 新值，到 3000ms 仍能取新值，pttl 为 -1。保留这条实现。[普通 SET 清旧 TTL 的官方语义](https://redis.io/docs/latest/commands/set/)

### 17.2 重新设置以本次时刻为起点

你修后的正 TTL 路径用本次 `now_ms` 计算新 deadline，再写回当前 node，没有把新时长接到旧 deadline 后面。

本轮检查已验证：1000ms 设置 2000ms，2000ms 改为 5000ms；3000ms 剩 4000ms，7000ms 失效。无需另造期限结构。

### 17.3 erase 的计数与物理动作分开

你已经做到：删有效记录返回 true；删已过期记录仍回收 node，但返回 false；物理没有记录也返回 false。

这样将来 DEL 统计有效 key 的删除数，size 则观察物理条目。删除后 SET 同名 key 又会得到 `deadline=-1`，旧期限不会继续约束新值。这些关系已有代码和检查支持，后半只复用证据。

## 18. key 不存在时，expire_ms 为什么还可能抛异常？

你可能会先问：**“key 都不存在了，直接返回 false 不就好了吗？为什么还要检查 TTL？”**

这个想法是说得通的。要看懂这里的测试，先把两件事分开：**key 当前有没有有效数据，以及这次调用读到的时间、要求设置的期限是否合法。** 测试故意让这两件事同时影响一次调用。

### 18.1 先看正常调用：缺失 key 就返回 false

假设当前时间是 1000ms，store 中有有效的 `alice`，没有 `missing`。分别看这两次调用：

~~~cpp
store.expire_ms("alice", 2000);
store.expire_ms("missing", 2000);
~~~

第一条给 alice 设置从现在起的 2000ms 有效期，到期位置是 3000ms，返回 true。第二条的时间和 TTL 同样合法，但没有可设置的 key，所以返回 false。

到这里，你对缺失 key 的处理没有问题。接下来只改变第二条调用的 TTL。

### 18.2 缺失 key 加上一个无法形成到期位置的 TTL

仍然让当前时间为 1000ms，key 仍是不存在的 `missing`，把 TTL 换成 TimeMs 能保存的最大整数：

~~~cpp
store.expire_ms("missing", std::numeric_limits<KvStore::TimeMs>::max());
~~~

把这个最大整数记为 $M$。**TTL 参数本身能放进 TimeMs，但它与当前时间的和放不进去：**

$$
\text{要求的到期位置}=1000+M>M
$$

这是数学上的范围判断；实现中继续用安全的溢出检查，不能先执行一次会溢出的有符号加法。

现在同一次调用里有两个事实：

- `missing` 不存在，按普通缺失结果应该返回 false。
- 正 TTL 与当前时间组合后超出范围，按范围错误应该抛 `std::overflow_error`。

**到底先报告哪一个？这需要接口明确选择。** 这里的 contract（接口约定），具体就是规定这两种情况同时出现时，调用者会观察到什么结果。

本项目在 §9.1 选择的是：**先验证本次时间和正 TTL 的范围，再根据 key 是否有效返回 true/false。** 这样，同一组非法时间输入会得到明确的错误，而不会因为 store 中恰好有没有这个 key，表现成两种结果。

所以这次调用应当抛 overflow_error。选择“缺失优先”也可以形成另一套合理接口；当前采用的顺序是我们项目的设计约定，不能从 Redis 的 TTL 基本机制中直接推出。

检查范围也不会创建 missing、保存新期限或改写其他记录。**它只是先判断这次设置请求能否被合法表达。**

### 18.3 第二个测试：缺失 key，但 clock 返回了负数

这次把 TTL 换回普通的 2000ms，却让注入的测试时钟返回 -1：

~~~text
now_() 返回 -1
key 是不存在的 missing
ttl_ms 是 2000
~~~

本项目用非负毫秒数表示当前时刻，因此这个 clock 读数违反了 §9 的输入约定。这里要拒绝的是**负的当前时刻**；TTL 为负则有自己的立即删除语义，稍后分开讲。

你当前的 expire_ms 已经调用 now_ 得到 -1，但随后发现 key 不存在，就返回 false；后面的负时间检查没有执行。按照刚才选定的顺序，应先检查这个读数，抛 `std::invalid_argument`，再谈 key 的正常缺失结果。

把正常对照和两次异常调用放在一起：

| 当前时刻 | key 状态 | TTL | 本项目约定的结果 |
|---|---|---|---|
| 1000 | 缺失 | 2000 | false：输入合法，没有可设置的 key |
| 1000 | 缺失 | TimeMs 最大值 | overflow_error：要求的到期位置超出范围 |
| -1 | 缺失 | 2000 | invalid_argument：已读到的当前时刻非法 |

**这组测试检查的是“输入非法与 key 缺失同时出现时，先报告什么”。** 普通到期判断和已有 key 的加法保护，是另外两件已经通过的事情。

### 18.4 对照你的实现：保留溢出算法，调整检查位置

你在已有 key 上使用 GCC 的 `__builtin_add_overflow`，越界时抛异常，并保留旧 value 和期限；这些检查本轮均已通过。**这个方案正确，继续保留。** GCC 为它的加法与溢出判断提供了有定义的行为。[GCC 10.5 官方说明](https://gcc.gnu.org/onlinedocs/gcc-10.5.0/gcc/Integer-Overflow-Builtins.html)

当前差别在这里：

~~~text
你的当前路径：读 now -> 发现缺失就返回 false -> 没机会验证时间和正 TTL
本项目的约定：读 now -> 验证时间和正 TTL -> 再交付 key 的有效/缺失结果
~~~

**具体升级：读出本次 now_ms 后先确认非负；ttl_ms 为正时，先确认它与 now_ms 能组成合法 deadline，再允许缺失/过期分支返回 false。** 查找记录可以提前进行，关键是正常返回前已经完成约定的检查。验证成功且 key 有效时，才把新 deadline 写入 node。

若用一般数学关系表达，非负时刻 $t$、正 TTL $\tau$ 与类型最大值 $M$ 应满足：

$$
\tau \le M-t
$$

这和你的 builtin 在判断同一个范围，不要求你换一种算法。已过期 key 也按相同的检查顺序处理；范围失败时保留原记录。

### 18.5 pttl 为什么也提到了时间检查？

你的 pttl 目前也会先读 now_ms，再查缺失结果。假设它已经读到 -1，却因为 key 不存在而直接返回 -2，非法时间同样被正常缺失结果盖过去了。

**按本项目约定，pttl 已经取得的当前时刻也应先验证。** 读数合法之后，缺失才返回 -2；有效且无期限返回 -1；有效且带期限，再用同一个读数计算剩余毫秒。

你现有的 get/exists/erase 则有所不同：找不到物理记录时，它们直接返回，完全没有调用 now_。因此没有本次已经读出的非法时间要检查，这条路径可以保留。

两者的区别是：**一次调用是否真的读取了时钟；读取之后，是否按约定处理了它给出的结果。**

### 18.6 非正 TTL 与剩余时间，分别走自己的分支

`expire_ms("alice", 0)` 或 TTL 为负时，含义是立即删除当前有效的 key。这条分支直接判断长度是否非正，无需构造未来 deadline，也无需取负数的绝对值；最小负整数同样按这个规则处理。删除时如何复用本次时间，继续按 §15 升级。[EXPIRE 非正时长说明](https://redis.io/docs/latest/commands/expire/)

pttl 的剩余时间则是在确认记录仍有效、并且有期限之后计算：

$$
r=d-t
$$

其中 $d$ 是记录里的 deadline，$t$ 是本次唯一的 now_ms。此时 $0\le t<d\le M$，所以 $r$ 是可表示的正整数；-1/-2 由前面的状态分支返回。

**先弄清调用里同时发生了什么，再按公开约定决定结果，最后才对照代码的检查顺序。**

## 19. value 已经独立，默认 clock 还依赖谁

### 19.1 你的 get 已交付独立副本

`return it->second.value` 构造的是返回 optional 内的一份 string。调用者先拿到它，之后原 key 到期、删除或覆盖，都不会改写这个副本。

这条拥有关系和 binary 内容，本轮私有检查已验证。将来 reply encoder 和 Connection output 继续各自拥有已生成的 bytes，TTL 不会反过来改写它们。

### 19.2 复制函数对象，不会自动改掉它捕获的 this

默认 constructor 的 lambda 当前捕获 `this`，通过这个指针访问 `start`。KvStore 还保留隐式复制/移动能力。

下面是从当前源码推导的生命周期关系，现有 R1 测试没有执行这条路径：

~~~text
store A 创建默认 clock，lambda 捕获 A 的 this
-> 复制/移动得到 store B，函数对象仍保存指向 A 的指针
-> A 生命周期结束
-> B 调用 get
-> clock 尝试经旧指针读取 A.start
~~~

data_ 中的 value 被复制或移动，并不让 lambda 自动改成指向 B。这是 clock 的借用关系，不是 map 的复制问题。

**这次明确的升级是：让默认 clock 按值保存构造时的时间起点，之后直接使用这个副本算经过时长，不再通过 this 读取起点。** 这样复制 store 时，clock 的起点也随函数对象一起复制，原有 deadline 与时间轴保持一致。保留你的 node、Now 接口和毫秒表示，不引入新的时钟框架。

测试中按引用捕获 fake_now 的方案仍然成立：让 fake_now 的生命周期覆盖所有使用它的 store。接口统一，捕获对象的拥有/借用关系仍要分别明确。

## 20. 对着你的 node 再读图解 Redis

**现在选读《图解 Redis》的[过期删除与内存淘汰文章](https://www.xiaolincoding.com/redis/module/strategy.html)：看“如何判定 key 已过期了？”及“惰性删除”部分。**

带着两个具体对照读：你的期限与 value 同放在 node 中；文章展示真实 Redis 的过期信息组织。你的 const 查询保留物理记录；访问时删除会同时执行回收。比较行为和对象关系，不要求改成文章的容器表示。

看到定期删除先停，有限维护留给 Day4，内存淘汰留给 Day6。今天已经验证的是按时失效，不是无人访问时也会自动回收。

另一个区别会连接 Week14：你的默认时钟从进程内 start 计算经过时长；真实 Redis 的过期信息使用绝对 Unix 时间戳，也就是相对于统一日历起点的时间读数，用于保存与恢复。[Redis 时间表示与持久化](https://redis.io/docs/latest/commands/expire/)

重启后重新生成 start，同一个相对整数不再代表旧的日历时刻。Week14 再设计如何保存这层信息，今天先保留进程内单调时钟。

---

# Part 3：收尾、验证与验收

## Round3：保留已通过的实现，只完成明确升级

## 21. 现在只改这三处

继续维护原 header/source，按下面顺序完成：

1. **补齐 expire_ms/pttl 的校验早退顺序。** 立即验证已读取的时间；expire_ms 的正 TTL 越界在缺失/已过期早退前拒绝，失败不修改 node。
2. **收住 expire_ms 的非正长度分支。** 本次已经判断有效，就按这次判断完成删除，不经公开 erase 再取时间。
3. **让默认 clock 按值保存时间起点。** 复制/移动函数对象后不再借用原 store 的 this；时间轴起点不能因为复制又重置。

这三个动作不要求改容器、重写 parser/server 或重复已经通过的 get/exists/SET 主线。pttl 的第二次取时已经修复，重复的负值判断只是可选整理，不新增一次重构任务。

## 22. 复用已通过的证据，只补新增关系

你当前永久测试是 `KvStoreTtl.ExactDeadline`；原工程本轮是 `75/75 PASS`。下面的私有检查由本次验收提供，不写成你已另行手写或已落进原 tests。

| 关系 | 当前证据 | 接下来做什么 |
|---|---|---|
| 到期边界、const 查询、物理 size、SET 清期限 | 原 checker 和私有检查已通过 | 保留原测试 |
| SET 在旧期限前覆盖、期限替换、过期删除计数、binary/owning 副本 | 本轮私有检查已通过 | 复用，不再手写同一组 |
| 正 TTL 与 pttl 的单次时间快照 | 两个原失败 case 现均通过 | 保留修复，不重复实现 |
| 缺失/已过期 key 加非法时间或越界正 TTL | 旧私有组中缺失 key 的优先级仍失败 | 修后检查指定异常；已有记录的旧状态保持 |
| pttl 对缺失 key 已实际读到负时间 | 当前源码会早退忽略，未单独运行这项 | 修后验证 invalid_argument |
| 非正 TTL 的单次取时 | 固定时间删除结果已通过，调用次数未覆盖 | 用计数 clock 验证一次取时、true 且物理 size 归零 |
| 默认 clock 的复制/移动后使用 | 本轮只有源码生命周期分析，未做 sanitizer 复现 | 原对象结束后，新对象仍能用自己的 clock 正常 get |

最后四行是新增证据，不必铺成几十个组合。异常检查必须确认类型；没有抛异常也应判失败。负 clock 后恢复到之前的合法读数或更大读数，再检查状态保持。

测试语法与 fixtures 可以委托补全；你需要能说明每条检查建立什么状态、为什么得到这个结果。本轮没有擅自向原 test 文件追加私有 cases。

## 23. 最终构建与工具各证明什么

### 23.1 保持同一 CTest 入口

在原工程执行：

~~~bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build
cmake -E chdir build ctest --output-on-failure
~~~

本轮正常构建与原 75 项已经真实通过。完成 §21 的修改后再验证；新增测试后的总数以实际结果为准。已有 server/dispatcher 的编译兼容性继续由完整 build 检查。

EXPIRE/PTTL 命令尚未接入，不重复 Week12 的完整慢读/多客户端矩阵。Day5 再验证新增的网络关系。

### 23.2 ASan/UBSan：这次重点看 clock 捕获对象

用另一个 build 目录：

~~~bash
cmake -S . -B build-w13-day2-san \
  -DCMAKE_BUILD_TYPE=Debug \
  -DCMAKE_CXX_FLAGS="-fsanitize=address,undefined -fno-omit-frame-pointer" \
  -DCMAKE_EXE_LINKER_FLAGS="-fsanitize=address,undefined"
cmake --build build-w13-day2-san --target kv_store_ttl_test
cmake -E chdir build-w13-day2-san ctest --output-on-failure -R '^KvStoreTtl\.'
~~~

ASan（AddressSanitizer，地址错误检查器）关注越界、失效后访问等已执行的内存路径；UBSan（UndefinedBehaviorSanitizer，未定义行为检查器）关注已执行路径中的许多未定义操作。

**要观察 §19 的 clock 生命周期，测试必须真的执行复制/移动、结束原对象、再调用新对象。** 只运行原 ExactDeadline，即使工具没有报告，也没有覆盖这条路径。

本轮 R1 没有运行 sanitizer，不声称该路径已经验证安全。完成捕获升级后，把对应小 case 放进本目标再检查。时间快照、错误优先级仍由精确断言验证，工具不能替代它们。

当前仍是单线程 store，不新增 TSan 任务。

### 23.3 证据边界保持

当前 R1 证明指定时间上的有效性、两条已修的快照和已有组件兼容性。它不证明主动清理、真实 TCP 有效期集成、性能提升或重启恢复。

私有 `14/15` 里的一项已明确安排到最终升级；不能把它写成全通过，也不能因此撤销已满足本轮范围的 R1 成绩。

## 24. 整日完成时怎样收口

R1 成绩保持 100/100。整日最终验收再核对：

- §21 三处升级已落地：校验顺序、非正长度单次取时、默认 clock 起点拥有关系。
- 本轮已通过的 TTL/SET/const/owning 行为没有回归。
- 少量新增检查覆盖具体修复；完整 build/CTest 与相关 sanitizer 路径有真实结果。

note 的 R1 已讲清你为何采用 node、如何注入取时间能力；这部分保留。后半只记录真正新增的理解或一次修复，不再抄接口清单。

## 25. 五道收口题

可以口述，也可以由代码与已解释的测试共同支撑，不另填长答卷：

1. 3000ms 时 get 返回不存在，size 却仍是 1，各自说明什么事实？
2. fake_now 从 2999 改成 3000 后，哪个调用真正读取新时间，哪个对象仍没被删除？
3. 普通 SET 与再次 expire_ms，对旧有效期分别产生什么变化？
4. 一个无效的大 TTL 设置失败，怎样用独立结果证明旧 value 和有效期保持？为什么不能先加再判断？
5. 为什么本日相对单调时间能用于进程内 TTL，却不能直接当作 Week14 重启恢复的时间表示？

## 26. 三处收住后，下一天接命令

你已经把 Week12 的 `map<string,string>` 升级成 `map<string,node>`，在原组件内建立了时间语义。完成后半三个动作就收住，不另外写一份 store。

Day3 沿你的真实 expire_ms/pttl 接入 `EXPIRE key seconds` 与 `PTTL key`，增加命令参数校验、秒到毫秒转换和多 key 命令的一致时间观测；Day4 再处理有限回收。

**当前时间决定这次调用看到什么；记录与 clock 各自的拥有关系，决定之后还能安全使用什么。**
