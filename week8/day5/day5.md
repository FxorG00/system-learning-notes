# Week8 Day5：日志 I/O 为什么要和业务 execution flow 分开

> 今日定位：Week8 Day4 已正式通过。你已经有可返回结果的 ThreadPool、10 个 GoogleTest cases、CMake/CTest、重复运行和真实 TSan build 证据；今天进入第二个并发组件 `AsyncLogger V1`。
>
> 今天的核心产出是 logger component，不是再学一遍测试工具。只建立 `producer -> bounded queue -> single writer -> file` 的完整主线、ownership 和基本 lifecycle。Day6 再专门处理受控 backpressure、复杂 shutdown 交错、强化 lifecycle evidence 与 benchmark。

---

# Part 1：前情提要与必要术语

## 1. 从 Day4 接到今天

Week8 前四天围绕的是 task lifecycle：

```text
submitter
-> task queue
-> ThreadPool worker
-> result / exception shared state
-> future
```

Day4 又把 ThreadPool 的 written contract 变成了 GoogleTest、repeat 和 TSan 能检查的 executable evidence。你已经实际完成：

```text
10 个 ThreadPool GoogleTest cases
deterministic pending-task drain
exactly-once oracle
exception / empty-callable 后 worker survival
concurrent submitters 与 destructor lifecycle
CMake normal build + separate TSan build
CTest 10/10、50 次重复运行、TSan clean on exercised paths
```

所以今天不重新讲 `TEST`、`EXPECT_*`、`gtest_discover_tests` 或 CMake 的完整入门。它们只负责验证新的 `AsyncLogger`，不能抢走 component design 这条主线。

今天不继续给 ThreadPool 堆功能，而是复用已经掌握的并发骨架，解决另一种工作：

```text
业务 execution flow 产生 log record
-> logger 接受 record
-> background writer 将来执行 file I/O
```

两者的共同点：

```text
都有 producer
都有 bounded BlockingQueue
都有 background execution flow
都有 close / drain / join
都必须说明 accepted work 在 shutdown 时怎样处理
```

两者的区别：

```text
ThreadPool：多个 workers 执行彼此独立的 tasks
AsyncLogger：一个 writer 串行写同一个 output stream

ThreadPool result：通常由每个 future 单独观察
AsyncLogger result：通常形成一个顺序文件，并由组件级状态反映 I/O failure
```

当前真实进度是：Week8 Day1~Day4 已按顺序完成，Day4 最终评分 `94/100`。今天可以直接复用已经通过的 ThreadPool 工程结构和测试纪律，不需要补做重复性前置练习。

---

## 2. 今天从哪个问题出发

先看最直接的同步日志思路：

```cpp
void handle_request(const std::string& request) {
    do_business_work(request);
    output << "handled: " << request << '\n';
    output.flush();
}
```

如果多个 threads 都这样写，同一个业务调用可能同时承担：

```text
等待 stream mutex
格式化 record
把 bytes 交给 stream buffer
触发底层 file write
等待 flush
处理 I/O error
```

于是 caller latency 中混进了 logging latency（延迟）：

```text
业务函数何时返回
不仅取决于业务计算
还可能取决于日志锁竞争和 file I/O
```

这不是说 synchronous logging 一定错误。日志很少、程序很小、错误发生后必须立刻写出时，同步方案可能更简单。

今天要解决的是另一种需求：

> 让多个业务 execution flows 主要负责提交 records，由一个 background writer 负责串行 file I/O，同时保留 bounded memory、明确 backpressure 和可解释 shutdown。

---

## 3. 今天最终要造什么

今天的产出：

```text
include/async_logger.hpp
src/async_logger.cpp
tests/async_logger_test.cpp
更新同一个 project-root CMakeLists.txt
week8/day5/day5_note.md
```

`AsyncLogger V1` 的程序用途：

```text
输入：多个 producers 提交的 std::string log records
中转：bounded BlockingQueue<std::string>
执行：一个 logger-owned（由 logger 所有） background writer thread
输出：一个由 writer 串行写入的 text file
关闭：停止接受新 records，drain 已接受 records，flush/close stream，join writer
```

正常使用场景：

```text
main creates logger
-> business threads call log(record)
-> logger accepts records into queue
-> writer pops and writes records
-> business threads stop using logger
-> owner calls shutdown
-> logger drains and joins
-> owner reads final result / destroys logger
```

今天的成功标准不是“做出生产级日志库”，而是：

```text
所有权清楚
只有 writer 访问 output stream
log() 的 true/false 含义清楚
close/drain/flush/close-file/join 顺序清楚
accepted records 在正常 I/O 下 exactly once 出现在文件中
open failure 与 post-shutdown log 有明确结果
basic GoogleTest 与 TSan 能真实失败或报告
```

---

## 4. 必要术语

### 4.1 logging

`logging` 来自 `log`，这里指程序把运行事件记录成可供之后观察的 records。

日志不是业务数据本身，也不是自动生成的正确性证明。它主要帮助回答：

```text
哪个 execution flow 做了什么
什么时候进入某个 lifecycle stage
哪一个 operation 失败
程序退出前已经处理到哪里
```

### 4.2 log record

`record`：一条记录。

今天一个 `std::string` object 就代表一个 log record。logger 会在写出时为每个 record 追加一个 `\n`，因此测试输入使用不含换行符的单行 records。

要区分：

```text
record object：C++ 中的一项数据
record bytes：最终交给 output stream 的字符
physical line：文件中以 '\n' 分隔的一行
```

V1 不做 level、timestamp、source location 和复杂 formatter。

### 4.3 producer

`producer`：生产者。

今天指调用 `logger.log(record)` 的 execution flow。可能是 main thread，也可能是 ThreadPool workers。

producer 负责生成并提交 record，不直接写 logger 的 `std::ofstream`。

### 4.4 writer

`writer`：写入者。

今天特指 AsyncLogger 拥有的唯一 background thread。它不断从 queue `pop()` records，然后访问 output stream。

`writer` 不是文件，也不是 queue；它是执行 writer loop 的 execution flow。

### 4.5 sink

`sink`：接收日志输出的目的地。

今天唯一的 sink 是一个普通文件。以后 sink 也可能是 stderr、socket 或其他 logging backend，但当前不扩展。

### 4.6 synchronous / asynchronous

`synchronous`：同步的。今天表示 caller 自己完成主要 file-writing work 后才返回。

`asynchronous`：异步的。今天表示：

```text
producer 提交 record 的 execution flow
与 writer 执行 file I/O 的 execution flow
不是同一个
```

它不自动意味着：

```text
log() 永远立即返回
每条日志一定更快
返回时 record 已写入文件
系统崩溃后 record 一定存在
```

bounded queue 满时，blocking policy 会让 producer 等待，这正是 backpressure。

### 4.7 serialization

`serialization` 在今天不是“对象序列化格式”，而是把多个 concurrent write attempts 变成一个 writer 的顺序操作：

```text
many producers
-> one ordered queue
-> one writer
-> one stream
```

这样 output stream 不需要被多个业务 threads 同时访问。

### 4.8 backpressure

`backpressure`：背压。

当 producers 产生 records 的速度长期大于 writer 消费速度时，系统不能假装无限内存存在。bounded queue 满后，今天的 policy 是让 `log()` 阻塞等待空间，或者在 shutdown close queue 后返回 `false`。

它解决的是：

```text
不能无限积压 records
```

它带来的代价是：

```text
producer latency 仍可能因为 queue full 而上升
```

Day6 再受控观察这个现象；今天先把 contract 写准。

### 4.9 accepted / written / flushed / durable

这是今天最重要的一组边界：

```text
accepted：record 已成功进入 logger-owned queue
written：writer 已把 record 交给 output stream
flushed：stream buffer 已执行 synchronization request
durable：即使 system crash/reboot，数据仍满足所要求的持久性保证
```

四者不是同一个时刻：

```text
accepted
-> writer later pops
-> written
-> stream flush
-> possible OS/filesystem/device persistence work
```

今天的 `log() == true` 只承诺 accepted。

今天的 final `flush()` 也不承诺 durable。durability 需要更底层、明确的 persistence contract；本日不实现。

### 4.10 buffer / flush

`buffer`：缓冲区。output operations 可能先把 bytes 放进用户态 stream buffer，而不是每次 `<<` 都直接完成一次独立磁盘写入。

`flush`：冲刷/同步当前 stream buffer。`std::ostream::flush()` 会请求关联的 stream buffer 执行同步。

它不等于 Linux `fsync(fd)`。

### 4.11 truncate / append

`truncate`：截断。打开文件时清空旧内容，从新的空文件开始写。

`append`：追加。每次 write 位于文件末尾，保留旧内容。

今天选择 `std::ios::trunc`，因为 unit test 需要 deterministic output；生产日志常用 append，但那会引入历史文件、rotation 和多次进程运行等额外问题。

### 4.12 business thread

对，`business thread` 通常翻成“业务线程”，就是执行应用本身工作的线程。

在 AsyncLogger 这里，它不是专门写日志的线程，而是例如：

```text
处理一个用户请求
-> 计算 / 查数据库 / 网络通信
-> 遇到需要记录的信息，调用 logger.log(record)
-> 继续处理自己的工作
```

它只负责“产生日志 record”，不应该亲自做慢速文件 I/O。

对应关系是：

```text
business thread
    = 处理业务，同时调用 log()

writer thread
    = AsyncLogger 内部专门从 queue 取 record，写入文件

owner thread
    = 创建和最终 shutdown/destroy logger 的管理者，常常是 main thread
```

所以你那条链里：

```text
business threads stop using logger
-> owner calls shutdown
```

意思是：先保证处理业务的线程不再调用 `log()`，再由拥有 logger 的对象调用 `shutdown()`，让 writer 把队列中已接收的日志写完并退出。

---

## 5. 复用你已经验收的 BlockingQueue

Ubuntu 中的 canonical source：

```text
~/code/system-learning/cpp/week7/day5/blocking_queue.hpp
```

真实 public API 是：

```cpp
explicit BlockingQueue(std::size_t capacity);
bool push(T value);
std::optional<T> pop();
void close();
```

它已经提供：

```text
capacity > 0 invariant
bounded blocking push
blocking pop
close 后拒绝 push
closed-with-data 继续 pop/drain
closed-and-empty 返回 std::nullopt
close 唤醒 blocked producers/consumers
sequential repeated close
```

因此今天不要在 `AsyncLogger` 中再写一套：

```text
queue mutex
not_empty_cv
not_full_cv
closed flag
```

那会制造两份 shutdown protocol，并让 AsyncLogger 同时承担“日志组件”和“重写队列”的责任。

当前 queue 的 `pop()` 从 front 构造一个 `T value`。对今天的 `std::string` 能正确工作；是否进一步优化 move path 不属于 Day5 主线。

---

### 5.1 我的 blocking queue 关于 close 的一个案例

对，完全是这样。更准确地说：C 还没有被 queue 接收，`close()` 让这个“正在等空位的 push”醒来后失败。

```text
capacity = 1
worker_count = 1

A 已被 worker pop 出来
-> A 卡在 gate，worker 被占住

B 已经成功进入 queue
-> queue 满了

C 调用 push
-> 发现 queue 满
-> 在 not_full 条件上等待
-> C 此时还没有进入 queue，也没有被执行

另一个线程调用 close()
-> closed_ = true
-> notify_all(not_full)
-> 等待中的 C 被唤醒
-> C 重新拿到 mutex
-> 发现 closed_ == true
-> push 返回 false
-> C 不会入队，也不会执行
```

关键不是“C 原本已经进入 queue，后来被 close 删除”，而是：

```text
C 一直没有被 accepted；
它只是卡在“等待 queue 出现空位”的阶段；
close 让它知道：以后即使出现空位，也不再接收新任务。
```

而 B 不一样：

```text
B 在 close 前已经成功入队，属于 accepted task。
close 后仍然保留在 queue 中；
等 A 放开 gate，worker 会继续执行 B。
```

所以你的 `close()` 必须唤醒等待 `not_full` 的 C；否则 C 会永远等一个“已经不再有意义的空位”。

---

## 6. 从 Day4 继承下来的测试纪律

Day5 不应退回：

```text
运行后人工看一眼文件
打印 PASS 但 process 总是 return 0
固定 sleep 猜 writer 已写完
只检查 line count，不检查内容和重复
```

今天继续使用 Day4 建立的链：

```text
written contract
-> controlled scenario
-> observable file/result
-> GoogleTest assertion
-> test binary exit code
-> CTest / TSan evidence
```

等待 logger 完成的主要同步证据是 `shutdown()` 返回，因为它必须在 join writer 后返回。不要用 `sleep(1)` 代替 lifecycle contract。

---

# Part 2：教程主体

# 教程开始：先独立实现，再用 ownership 与 lifecycle 复盘

# Round 1：到这里停止阅读，先独立写出 AsyncLogger V1

你已经知道今天要解决的问题、复用的 BlockingQueue API，以及最终文件必须可验证。先不要看下面的 ownership map、状态机、single-writer 理由和 shutdown 算法。

Round1 只回答一个问题：

> 你能否只根据程序用途和 public contract，独立写出第一版 `AsyncLogger`，让 producer 不再直接承担 file I/O？

本轮核心实现文件：

```text
include/async_logger.hpp         声明 public interface；你自己设计 private state
src/async_logger.cpp             实现 file open、log、writer lifecycle 与 shutdown
```

先用一个很小的 public-API smoke program，或 `tests/async_logger_test.cpp` 中最小的 1~3 个 cases 验证 V1。Round1 不要求先完成最终 GoogleTest matrix，也不要求先改完 CMake；否则很容易把“测试工程能构建”误当成“logger 已设计完成”。

本轮同步记录：

```text
week8/day5/day5_note.md          只记录 V1 设计、实际报错和暂未解决的问题
```

不要复制 `blocking_queue.hpp`，继续 include canonical component。不要先阅读后面的 member checklist，再照着把答案翻译成代码。

### Round1 程序用途

三个代码文件从外部形成：

```text
test/producer 提供 output path、capacity 和 string records
-> AsyncLogger 接受或拒绝 records
-> background writer 把 accepted records 写入指定 file
-> shutdown 返回后 test 读取 file
-> exact content 正确则通过，否则 test failure
```

本轮只给最小 public contract：

```cpp
AsyncLogger(std::string output_path, std::size_t capacity);
~AsyncLogger();

bool log(std::string record);
bool shutdown();
```

### Round1 文件 API 工具箱

这些例子只教 file stream 的基本调用，不包含 AsyncLogger 的线程控制流。

打开并截断 output file：

```cpp
#include <fstream>

std::ofstream output("logger_api_demo.txt",
                     std::ios::out | std::ios::trunc);
if (!output.is_open()) {
    // open failed
}
```

写入、检查、刷新和关闭：

```cpp
output << "record-7" << '\n';
if (!output) {
    // a write operation has failed
}

output.flush();
const bool flush_ok = static_cast<bool>(output);
output.close();
```

`flush()` 只要求把 C++ stream buffer 交给下层，不等于 `fsync` durability。

shutdown 后读取最终文件：

```cpp
#include <fstream>
#include <string>

std::ifstream input("logger_api_demo.txt");
std::string line;
while (std::getline(input, line)) {
    // test records one complete line
}
```

不要在 writer 仍可能写文件时，把暂时读不到的行判成最终丢失。

### Round1 编译与最小观察入口

Round1 可以先直接用 `g++` 编译，不以 CMake 是否完成作为本轮门槛。若你先写的是 GoogleTest smoke：

```bash
cd ~/code/system-learning/cpp/week8
g++ -std=c++17 -Wall -Wextra -g -pthread \
  -Iinclude src/async_logger.cpp tests/async_logger_test.cpp \
  -lgtest_main -lgtest \
  -o build/async_logger_test
./build/async_logger_test
```

若你先写普通 `main`，只需把最后一个 source 换成自己的 smoke file，并去掉 GoogleTest libraries。最小 smoke 应能从外部观察：

```text
log A/B/C 返回 true
shutdown 返回
重新打开 output file 后恰好读到 A/B/C
shutdown 后 log("late") 返回 false
```

这只是帮助你快速判断主链是否成立，不是最终测试套件。

外部可观察需求：

```text
constructor 打开一个新的 output file；失败时报告错误
多个 producers 可以调用 log
log true 表示该 record 已被 logger 接受
后台 execution flow 把 accepted records 写成一行一条
shutdown 停止接受新 records，并在返回前处理完已接受 records
shutdown 后 log 返回 false
destructor 不留下仍访问 logger members 的 thread
```

先独立决定：

```text
哪些 objects 是 members
谁拥有 output stream
writer 从哪里退出
log 与 shutdown 共享哪些状态
怎样让 tests 在 shutdown 后检查文件
```

完成一个能通过“单 producer 顺序写入、多 producer 不丢不重、shutdown 后拒绝”三个基本场景的 V1。你可以先用少量手写检查证明它们，不必为了 Round1 立刻写完整 test matrix。若你暂时没处理 file runtime failure、queue 满时 shutdown 或 repeated shutdown，先把它们记作疑问，不要提前读答案。

**阅读闸门：`async_logger.hpp/.cpp` 的 V1 尚未编译，并且最小 smoke 尚未观察到真实 file output 前，停在这里。**

---

# Round 2：拿 V1 对照 ownership、状态机与关闭竞态

下面开始揭示完整设计问题。每节先检查你的代码已经如何处理，再决定是修 bug、补 contract，还是明确写成 V1 limitation。

## 7. 今天的 ownership map

先把 objects 放对位置：

```mermaid
flowchart LR
    P1[producer thread 1] -->|log record| L[AsyncLogger object]
    P2[producer thread 2] -->|log record| L
    L --> Q[BlockingQueue string]
    Q --> W[writer thread]
    W --> S[ofstream / file sink]
    O[owner/control thread] -->|shutdown + destruction| L
```

逐项解释：

```text
producer：调用 log 前拥有自己的 input string
log parameter：以 value 接收 record，建立本次调用自己的 object
queue：push 成功后拥有 queued string
writer：pop 成功后拥有当前 local record
ofstream：AsyncLogger member，只有 writer 访问其 write/flush/close operations
thread object：AsyncLogger member，表示并控制 background writer 的 joinable lifecycle
owner：负责保证所有 producers 不再访问 logger 后才销毁 logger
```

特别注意：

```text
AsyncLogger owns writer thread object
不等于 AsyncLogger 可以在 writer 仍运行时直接析构其他 members
```

destructor 必须先完成 close/drain/join，之后 members 才能按反向声明顺序销毁。

---

## 8. 概念状态与真实状态

可以用三个概念状态理解 V1：

```text
RUNNING：queue open，可以接受 records，writer 可能 waiting/writing
DRAINING：queue closed，不再接受 records，writer 继续消费已有 records
STOPPED：queue closed-and-empty，writer 已 flush/close stream 并退出，thread 已 join
```

V1 不一定需要额外写一个 `enum class State`。这些状态可由现有对象关系体现：

```text
queue close state
queue remaining records
writer loop 是否返回
thread object 是否已经 join
```

不要为了“看起来像状态机”复制一份与 queue 可能不一致的 `running_` flag。

---

## 9. 先看 synchronous logging 的完整路径（同步的）

假设两个 business threads 直接**共享同一个 output stream**。为了不发生 data race，至少需要一个 mutex：

```text
producer creates record
-> lock stream mutex
-> output << record << '\n'
-> maybe flush
-> unlock
-> producer continues business work
```

mutex 能保护 stream shared state，却不能消除 I/O latency：

```text
waiting for mutex
+ writing/flushing under mutex
= caller-visible logging latency
```

如果每个 producer 都持锁执行 slow I/O，其他 producers 也会排在这个 mutex 后面。

AsyncLogger 的变化不是“删除等待”，而是移动责任：

```text
producer 主要等待 queue capacity
writer 独占承担 stream I/O
```

当 writer 跟得上时，producer 往往只做 record construction + queue handoff；当 writer 跟不上时，bounded queue 用 backpressure 暴露真实容量限制。

---

## 10. AsyncLogger 的完整主线

```mermaid
flowchart TD
    A[producer builds std::string record]
    B[call logger.log by value]
    C{queue still open?}
    D{queue has capacity?}
    E[wait on queue not_full]
    F[move record into queue]
    G[log returns true: accepted]
    H[log returns false: not accepted]
    I[writer pop waits for record or close]
    J[writer owns popped record]
    K[writer writes record plus newline]
    L[owner calls shutdown]
    M[queue close and wake waiters]
    N[writer drains remaining records]
    O[closed and empty: pop returns nullopt]
    P[writer flushes and closes stream]
    Q[writer loop returns]
    R[owner joins writer]

    A --> B --> C
    C -->|no| H
    C -->|yes| D
    D -->|no| E --> C
    D -->|yes| F --> G
    F --> I
    I --> J --> K --> I
    L --> M --> N --> O --> P --> Q --> R
    M --> C
```

读图先抓五件事：

```text
1. true 表示 accepted，不是 written
2. queue full 时 producer 可以 blocking
3. writer 只有一个，所以 stream write 被串行化
4. close 不会删除已接受 records，writer 继续 drain
5. shutdown 返回前必须 join writer
```

---

## 11. normal `log()` 的对象转移

建议接口：

```cpp
bool log(std::string record);
```

对，`by value` 就是按值传参。那段真正想讲的不是“by value 是什么”，而是：

> `log` 为什么偏偏要写成 `log(std::string record)`，而不是 `log(const std::string& record)`？

核心原因就一句：

```text
logger 必须把日志字符串拿走，留到将来让 writer thread 写文件。也就是 logger 要自己拥有一份，然后 push 到 queue 里面。如果传引用的话，生命周期跟内容都无法保证。
```

所以它不能保存 caller 的引用；caller 的 `message` 可能马上改掉、离开作用域，或者被销毁。

看这个实现骨架：

```cpp
bool AsyncLogger::log(std::string record) {
    return queue_.push(std::move(record));
}
```

`record` 是 `log` 自己得到的一份字符串。之后无论 caller 那边发生什么，queue 里的日志都有自己的数据。

两种调用分别看：

```cpp
std::string message = "hello";
logger.log(message);
```

这里 caller 还想保留 `message`，因此：

```text
message
-> copy 一份给 log 的 record parameter
-> record 被 move 给 queue
-> message 仍是 "hello"
```

而：

```cpp
std::string message = "hello";
logger.log(std::move(message));
```

这里 caller 明确表示“这条字符串可以交出去”，因此：

```text
message
-> move 给 log 的 record parameter
-> record 再 move 给 queue
-> message 变成 moved-from 状态
```

这样同一个接口同时支持：

```text
log(message)              ：我还要保留原字符串，copy
log(std::move(message))   ：我不要原字符串了，move
```

这就是按值传参在这里的好处：**调用者自己决定 copy 还是 move，logger 永远最终拿到一份自己拥有的数据。**

你困惑的 `false` 场景，关键在调用顺序：

```cpp
logger.log(std::move(message));
```

会先发生：

```text
message -> move 构造出 parameter record
```

然后才进入 `log()` 函数体，才发现 queue 已经 close：

```text
record -> push 失败 -> log 返回 false
```

所以即使失败，`message` 也已经被 move 过了。失败的只是“没有进入 queue”，不是“刚才的 move 自动撤销”。

压缩成一句：

```text
by-value log = 先把 record 交给 logger 这次调用，再由 logger 尝试把它交给 queue。
queue 拒绝时，record 不会进入 logger，但 caller 若传了 std::move，原对象仍可能已经交空。
```

---

## 13. 为什么只允许一个 writer 访问 stream

只保留今天需要的结论：single writer 让 stream ownership 和输出顺序都只有一个解释。

```text
producers 只提交 record
-> one writer 按 queue 顺序执行 write / flush / close
-> owner 通过 join 等它结束
```

它的目标是简化 ownership，不是宣称“writer 越少一定越快”。

---

## 14. FIFO 能保证什么，不能保证什么

BlockingQueue 是 FIFO：先成功进入 queue 的 record 先被 writer pop。

一个 producer 连续调用：

```text
log("A")
log("B")
log("C")
```

在没有其他特殊失败时，它自己的 submission order 是 A、B、C。

多个 producers 时：

```text
P1 prepares A
P2 prepares B
```

不能只凭 wall-clock 感觉断言 A 一定先入队。真正顺序取决于两个 push operations 谁先在线性化点完成入队。

因此 V1 承诺：

```text
file order == successful queue order
同一 producer 的 sequential successful calls 保持 program order
不同 producers 的 total order 由实际 synchronization interleaving 决定
```

V1 不承诺：

```text
业务事件真实发生时间的全局排序
不同 CPU 上 timestamp 完全可比较
按 producer ID 排序
```

---

## 15. `std::ofstream` 是什么

`ofstream` 是 `output file stream`：面向文件输出的 C++ stream type。

头文件：

```cpp
#include <fstream>
```

最小独立例子：

```cpp
#include <fstream>
#include <iostream>

int main() {
    std::ofstream output("ofstream_demo.log",
                         std::ios::out | std::ios::trunc);

    if (!output.is_open()) {
        std::cerr << "open failed\n";
        return 1;
    }

    output << "first record" << '\n';
    output.flush();

    if (!output) {
        std::cerr << "write or flush failed\n";
        return 1;
    }

    output.close();
    if (!output) {
        std::cerr << "close failed\n";
        return 1;
    }

    return 0;
}
```

当前读法：

```text
open with out|trunc
-> verify is_open
-> write bytes and newline
-> flush stream buffer
-> verify stream state
-> close file
-> verify stream state again
```

### 15.1 `is_open()`

```cpp
bool is_open() const;
```

作用：询问 file stream 当前是否成功关联一个打开的 file。

重要边界：默认情况下，`std::ofstream` open failure 通常设置 stream failure state，不一定自动抛 exception。因此 constructor 不能只写 open 后就直接启动 writer，必须检查 `is_open()` 或 stream state，再把 failure 变成明确的 `std::runtime_error`。

### 15.2 `std::ios::out | std::ios::trunc`

`openmode` 是 bitmask，可以用 `|` 组合：

```text
out：打开用于 output
trunc：若文件已存在，打开时截断旧内容
```

今天用 `trunc` 让每次 test 从空文件开始。

不要混淆：

```text
app：每次 write 前定位到末尾
ate：刚打开时定位到末尾，之后仍可 seek
trunc：清空旧内容
```

### 15.3 `operator<<` 与 `write`

今天使用：

```cpp
output << record << '\n';
```

它适合当前 text records。

以后若写固定 byte count 或 binary record，可学习：

```cpp
output.write(data, count);
```

Day5 不扩展 binary format。

### 15.4 为什么用 `'\n'`，不用 `std::endl`

`std::endl` 不只输出 newline，还会 flush stream。

若每条 record 都强制 flush：

```text
writer 很难利用 buffering
I/O synchronization 次数可能增加
benchmark 条件也会改变
```

今天用：

```cpp
output << record << '\n';
```

在 shutdown drain 完成后统一 flush。

---

## 16. `flush` 为什么不等于 durability

#### C++ stream 视角：

这句话是标准库的正式说法，读起来确实很不像人话。你把它换成下面这句就行：

```text
output.flush()：
请 ofstream 把自己暂时攒着、还没交给文件系统的字符，立刻尝试交出去。
```

这里的三个词分别是：

```text
associated stream buffer
= output 内部关联的缓冲对象
= 对 ofstream 来说，通常就是管理文件读写缓冲的 filebuf

synchronization operation
= 让“C++ 这边 buffer 里记录的内容”和“下层文件”尽量同步
= 不是线程同步，不是 mutex / condition_variable 那种 synchronization

failure updates stream error state
= 如果这次交出去失败，例如磁盘满、底层 write 出错
= output 自己会记下“我出错了”
```

所以你写：

```cpp
output << "hello\n";
output.flush();

if (!output) {
    // output 记着：之前 write 或 flush 出错了
}
```

默认不会自动抛异常，而是把错误状态记在 `output` 里面；`if (!output)` 就是在检查这个状态。

整个数据路径先这样理解：

```text
output << "hello\n"
    |
    v
C++ 的 file stream buffer
    |  此时字符可能还在用户态 buffer
    v
output.flush()
    |
    v
尝试交给内核的文件系统 / page cache
    |
    v
之后文件系统再决定何时真正写到存储设备
```

所以 `flush` 不等于 `durable`：

```text
flush 成功
= C++ 自己的 buffer 已经尝试交给下层

不等于
= 断电后磁盘上一定还有这条日志
```

还有一个小边界：这里的 “sync” 是“缓冲区和文件状态同步”，不是“让两个 threads 互相等待/建立 happens-before”的同步。

#### Linux 文件路径可以先建立第一层模型：

```mermaid
flowchart LR
    A[record string] --> B[C++ stream buffer]
    B -->|flush / stream sync| C[kernel file state / page cache]
    C -->|filesystem writeback| D[storage device]
```

#### 今天只能承诺：

```text
writer 在退出前请求 stream synchronization
并检查 stream failure state
```

不能承诺：

```text
power loss 后一定存在
system crash 后目录项和文件数据一定 durable
```

Linux `fsync(fd)` 才是面向 file descriptor 的持久化 system call；它也有 metadata、directory entry 和 filesystem/device 边界。Day5 使用标准 C++17 `ofstream`，不为了 durability 重新切回 POSIX fd logger。

压缩记忆：

```text
log true != written
written != flushed
flushed != durable
```

---

## 17. Constructor 顺序为什么很关键

AsyncLogger constructor 需要完成：

```text
1. construct bounded queue
2. open output stream
3. verify file open success
4. start writer thread
```

绝不能先启动 thread，再检查 stream：

```text
writer may run immediately
-> access stream before constructor has validated it
-> constructor then reports failure
-> partially started execution flow becomes hard to clean up
```

推荐 member declaration dependency order：

```cpp
BlockingQueue<std::string> queue_;
std::ofstream output_;
bool write_failed_{false};
std::thread writer_;
```

C++ 按 member **声明顺序** 初始化，不按 initializer list 的书写顺序。

析构时反过来：

```text
writer_
write_failed_
output_
queue_
```

但 destructor body 会在 members 自动析构前执行，所以必须先 `shutdown()`，让 writer join 后，才允许后续 member destruction。

### 17.1 为什么 thread 在 constructor body 最后启动

可以先让 queue/output/bool/thread object 全部完成 construction，检查 output open 成功，再启动：

```cpp
writer_ = std::thread(&AsyncLogger::writer_loop, this);
```

这个 API 的最小独立形态：

```cpp
#include <thread>

class WorkerOwner {
public:
    WorkerOwner() {
        worker_ = std::thread(&WorkerOwner::run, this);
    }

    ~WorkerOwner() {
        if (worker_.joinable()) {
            worker_.join();
        }
    }

private:
    void run() {}
    std::thread worker_;
};
```

这只是 member-function thread API 演示，不是 AsyncLogger 完整答案。真实 logger 还需要 queue close 才能让 waiting writer 退出。

### 17.2 constructor failure boundary

```text
capacity == 0
-> BlockingQueue constructor throws invalid_argument
-> no writer started

file open fails
-> AsyncLogger checks is_open
-> throws runtime_error
-> no writer started

std::thread creation fails
-> thread constructor throws system_error
-> already constructed queue/output members are destroyed
```

关键设计是：成功启动 writer 之后，constructor 不再执行新的容易抛异常的工作。

---

## 18. 为什么 AsyncLogger 禁止 copy，也暂时禁止 move

copy 明显不成立：

```text
不能复制 mutex/CV-based queue
不能复制 std::thread ownership
不能让两个 logger objects 同时认为自己拥有同一个 writer/file lifecycle
```

move 也不能只因为 `std::thread` 可 move 就默认允许。

writer thread 的 entry 可能保存原对象的 `this`：

```cpp
std::thread(&AsyncLogger::writer_loop, this)
```

若 logger object 在 writer 运行时被 move：

```text
thread still uses old this address
members may have moved to new object
-> lifetime/address contract breaks
```

所以 V1 明确删除：

```cpp
AsyncLogger(const AsyncLogger&) = delete;
AsyncLogger& operator=(const AsyncLogger&) = delete;
AsyncLogger(AsyncLogger&&) = delete;
AsyncLogger& operator=(AsyncLogger&&) = delete;
```

以后若真要 movable component，需要稳定 shared state 或“只能在未启动状态 move”等额外设计；今天不做。

---

## 19. `log()` 与 `shutdown()` 的 public contract

建议 V1 interface：

```cpp
class AsyncLogger {
public:
    AsyncLogger(std::string output_path, std::size_t capacity);
    ~AsyncLogger();

    AsyncLogger(const AsyncLogger&) = delete;
    AsyncLogger& operator=(const AsyncLogger&) = delete;
    AsyncLogger(AsyncLogger&&) = delete;
    AsyncLogger& operator=(AsyncLogger&&) = delete;

    bool log(std::string record);
    bool shutdown();

private:
    void writer_loop();
};
```

这只是 interface，不是 implementation。

### 19.1 `log(record)`

```text
thread-safe for multiple producers
may block while bounded queue is full
returns true only when record is accepted
returns false after/while shutdown closes queue
does not promise written/flushed/durable on return
```

### 19.2 `shutdown()`

```text
called by owner/control execution flow
closes acceptance
drains accepted records
waits for writer flush/close and exit
joins writer before return
sequential repeated calls are allowed
returns true if no stream write/flush/close failure was observed
returns false if writer observed I/O failure
```

今天不要求多个 threads concurrent 调用 `shutdown()`。`std::thread` object 的 `joinable/join` coordination 仍由一个 owner 串行负责。

### 19.3 destructor

```text
if caller forgot explicit shutdown
-> destructor performs final shutdown/join
```

但 destructor 无法把 `bool` status 返回给 caller。因此：

```text
需要观察 final I/O status 的正常路径：显式调用 shutdown()
只要求 lifetime safety 的兜底路径：destructor 自动 shutdown()
```

### 19.4 `write_failed_` 的 synchronization

不是记录“失败数量”，今天只需要一个 `bool` 标记：

```cpp
bool write_failed_{false};
```

它表达的是：

```text
false：writer 到目前为止没有观察到 stream 写入/flush/close 失败
true：writer 曾经观察到至少一次失败
```

例如 writer loop 里逻辑上是：

```cpp
output_ << record << '\n';

if (!output_) {
    write_failed_ = true;
}
```

最后 `shutdown()`：

```cpp
queue_.close();
writer_.join();

return !write_failed_;
```

也就是：

```text
writer 没发现 I/O failure
-> write_failed_ == false
-> shutdown() 返回 true

writer 发现过一次 failure
-> write_failed_ == true
-> shutdown() 返回 false
```

为什么标题里要说 synchronization？因为这是两个线程共同接触同一个变量：

```text
writer thread：写 write_failed_
owner thread：读 write_failed_
```

如果 owner 在 writer 还运行时就读它：

```cpp
bool ok = !write_failed_;  // writer 可能同时正在写
```

那就是 data race，需要 mutex 或 `std::atomic<bool>`。

但今天的顺序是：

```text
writer: write_failed_ = true
-> writer thread 结束
-> owner: writer_.join() 返回
-> owner: 读取 write_failed_
```

`join()` 保证：writer 在线程结束前做的操作，对 `join()` 返回后的 owner 可见。因此此时读普通 `bool` 是安全的，不需要 atomic。

所以这节真正想说的是：

```text
不是“要统计失败几次”；
而是“writer 把最终是否失败这个结果留给 owner，
owner 只能在 join 以后读取它”。
```

以后若加：

```cpp
bool healthy() const;
```

让业务线程在 logger 还运行时随时查询健康状态，那么读取会和 writer 的写入并发发生，这时才需要重新设计同步。

---

## 20. 对你的 writer loop 做一次短复检

你的 R1 已经形成正确主线：持续 `pop()`，有 record 就写一行，`nullopt` 时结束；退出前由同一个 writer 执行 `flush()`、`close()` 并记录 stream failure。这里不再把实现步骤重新写成一份伪代码答案。

R2 只确认一个设计取舍：即使 stream 已失败，writer 仍继续 drain queue，并把最终状态交给 `shutdown()` 报告，避免 lifecycle 卡在尚未消费的 accepted records 上。

---

## 21. shutdown 的完整因果链

今天抓住这一条完整链即可：

```text
owner has stopped/joins all producer threads that may call log
    |
    v
owner calls AsyncLogger::shutdown
    |
    +--> queue.close()
    |       |
    |       +--> acceptance closes
    |       +--> blocked producers wake and return false
    |       +--> blocked writer wakes
    |
    +--> if writer thread is joinable: join()
            |
            v
writer continues pop existing records
            |
            v
queue becomes closed-and-empty
            |
            v
pop returns nullopt
            |
            v
writer flushes and closes output stream
            |
            v
writer_loop returns
            |
            v
join returns to owner
    |
    v
shutdown returns final I/O status
```

---

## 22. `close`、`drain`、`flush`、`join` 各自等待什么

| operation | 操作对象 | 主要作用 | 不代表什么 |
|---|---|---|---|
| queue `close()` | BlockingQueue | 停止新 push，唤醒 waiters | writer 已退出 |
| drain | queued records | writer 继续处理 accepted records | stream 已 flush |
| stream `flush()` | output buffer | 请求同步 buffered output | storage durable |
| stream `close()` | file stream | flush/close file association | writer thread 已 join |
| thread `join()` | writer thread | 等待 writer execution flow 结束 | 自动检查 file content 正确 |

---

## 23. `log()` 与 `shutdown()` 发生交错时

这里不重复 Week7 已经讲过的 push/close 竞态。直接复用 BlockingQueue contract：谁先在线性化点完成，决定本次 `log()` 是 accepted 并由 writer drain，还是返回 `false`。

---

## 24. Header / source split 在今天怎样落地

建议 canonical project 继续保持：

```text
include/
    blocking_queue.hpp
    thread_pool.hpp
    async_logger.hpp
src/
    async_logger.cpp
tests/
    thread_pool_test.cpp
    async_logger_test.cpp
CMakeLists.txt
```

### 24.1 header 负责什么

```text
class declaration
public API
deleted special members
private member types
writer_loop declaration
```

因为 `BlockingQueue<std::string>`、`std::ofstream` 和 `std::thread` 是 by-value members，header 必须看见它们的完整 type definitions，因此包含相应 headers。

### 24.2 source 负责什么

```text
constructor definition
destructor definition
log definition
shutdown definition
writer_loop definition
```

`BlockingQueue<T>` 自身是 class template，definition 仍应位于可被使用 translation unit 看见的 header；不要把 queue template implementation 搬进 `async_logger.cpp`。

---

## 25. CMake

你理解的主线是对的，只差把 CMake 里的“源文件列表”和“链接关系”对应上。

先纠正一个小点：

```text
.hpp：通常不单独编译
.cpp：分别编译成 .o
.o：最后一起链接
```

所以你不需要把 `.hpp` 当成“也要参与编译的第二个文件”。它的作用是让别的 `.cpp` 在编译时看见声明。

最朴素的 CMake 写法是把两个 `.cpp` 都放进同一个 target：

```cmake
add_executable(async_logger_test
    tests/async_logger_test.cpp
    src/async_logger.cpp
)

target_include_directories(async_logger_test PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)
```

它对应你以前手写的命令：

```bash
g++ -Iinclude \
    tests/async_logger_test.cpp \
    src/async_logger.cpp \
    -o async_logger_test
```

CMake 在底下会做：

```text
tests/async_logger_test.cpp
-> 编译成 tests 的 object file

src/async_logger.cpp
-> 编译成 async_logger 的 object file

两个 object file
-> 链接成 async_logger_test executable
```

而：

```cmake
target_include_directories(async_logger_test PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)
```

对应：

```bash
-Iinclude
```

它让这两份 `.cpp` 都能写：

```cpp
#include "async_logger.hpp"
```

对于你现在的项目，更推荐把 logger 单独做成 library target：

```cmake
find_package(Threads REQUIRED)

add_library(async_logger
    src/async_logger.cpp
)

target_include_directories(async_logger PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_link_libraries(async_logger PUBLIC
    Threads::Threads
)

add_executable(async_logger_test
    tests/async_logger_test.cpp
)

target_link_libraries(async_logger_test PRIVATE
    async_logger
    GTest::GTest
    GTest::Main
)
```

这条关系是：

```text
src/async_logger.cpp
-> 编译
-> async_logger library

tests/async_logger_test.cpp
-> 编译
-> async_logger_test executable

async_logger_test
-> 链接 async_logger library
-> 因此获得 async_logger.cpp 里函数的 definitions
```

`PUBLIC` 的意思是：测试程序 link `async_logger` 后，自动继承它的 `include/` 路径和 `Threads::Threads` 依赖。于是测试文件可以直接：

```cpp
#include "async_logger.hpp"
```

你不必再给 `async_logger_test` 重复写一次 `include/` 和 pthread。

压缩记忆：

```text
.hpp：提供 declaration，靠 include path 找到
.cpp：写进 add_library / add_executable，参与编译
target_link_libraries：把“函数 definition 在哪里”连接到使用它的 executable
```

---

## 26. V1 明确不做什么

今天不做：

```text
log levels
timestamp formatting
source file/line capture
rotation
append across process runs
multiple sinks
multiple writer threads
drop-oldest / drop-newest
nonblocking try_log
crash-safe durable logging
signal-handler-safe logging
fork 后继续复用 logger
spdlog source analysis
benchmark
```

这些不是“不重要”，而是会让今天从：

```text
ownership + queue + single writer + lifecycle
```

膨胀成完整 logging ecosystem。

---

# Part 3：收尾、练习、测试与验收

# Round 3：按复盘结果完成组件与基础测试

先明确这一轮相对 Round1 的 concrete delta：

```text
Round1 已有：能 open、accept、background write、shutdown 的 AsyncLogger V1

Round2 复盘后要改进 implementation：
    open-before-thread-start
    single-writer stream ownership
    close-before-join
    closed-with-data drain
    remembered I/O failure
    sequential repeated shutdown
    destructor fallback

implementation 稳定后再补 execution evidence：
    public-API GoogleTest scenarios
    CMake targets / CTest registration
    normal build、定向运行、TSan
```

今天的核心仍是第一栏的 component behavior。CMake/CTest/TSan 只运行这份 strengthened implementation 和 tests，不是另一份独立产出。

## 27. Round3 最终 AsyncLogger contract 复检

Round1 已经建立文件、程序用途、file API 和基础 scenarios。这里用 Round2 的 ownership/lifecycle 分析补齐最终 contract，不重新复制一套 logger。

### 27.1 canonical files 复检

在 canonical Week8 project 中新增：

```text
include/async_logger.hpp
src/async_logger.cpp
tests/async_logger_test.cpp
week8/day5/day5_note.md
```

并修改原有：

```text
CMakeLists.txt
```

不要复制 BlockingQueue implementation；复用 Week7 已验收的 `include/blocking_queue.hpp` canonical copy。

### 27.2 三个代码文件最终职责复检

`async_logger.hpp`：

```text
声明 AsyncLogger public contract
声明 object ownership
禁止 copy/move
声明 private writer loop
```

`async_logger.cpp`：

```text
打开 output file
启动/停止 writer
把 log records 交给 BlockingQueue
在 writer execution flow 中 drain/write/flush/close
记录最终 stream failure status
```

`async_logger_test.cpp`：

```text
只通过 public API 创建和使用真实 logger
在 shutdown/join 后读取 output file
验证 accepted records、file content、failure paths 和 lifecycle
让 assertion failure 影响 process exit code
```

### 27.3 final public contract

你需要实现与下面语义等价的 interface：

```cpp
AsyncLogger(std::string output_path, std::size_t capacity);
~AsyncLogger();

bool log(std::string record);
bool shutdown();
```

固定语义：

```text
capacity == 0：invalid_argument（由 BlockingQueue invariant 提供）
file open failure：constructor throws runtime_error
log before close：block until accepted or close; true means accepted
log after/while close wins：false
shutdown：close acceptance, drain, flush/close stream, join
shutdown return：true means no stream failure observed; false means failure observed
sequential repeated shutdown：allowed and returns same final status
destructor：final shutdown/join fallback
copy/move：disabled
```

调用者 contract：

```text
multiple threads may call log
one owner controls shutdown/destruction
concurrent shutdown calls are not supported
owner must ensure no thread accesses logger after destruction begins
record lifetime after successful log belongs to logger
```

### 27.4 private state 责任

你需要自己确定准确声明，但至少表达：

```text
one BlockingQueue<std::string>
one std::ofstream
one final write-failure flag
one std::thread writer object
```

每个 member 必须能回答：

```text
谁写
谁读
在什么 synchronization 后读取
何时销毁
为什么需要
```

### 27.5 constructor algorithm checklist

只给步骤，不给完整代码：

```text
construct queue with capacity
open output path in out|trunc mode
verify open success
on failure throw runtime_error before starting writer
start writer thread as the last constructor action
perform no new throwing setup after writer start
```

### 27.6 `log` algorithm checklist

```text
accept std::string by value
delegate ownership/close decision to queue.push
return queue result
do not access output stream
do not maintain a second closed flag
```

### 27.7 writer-loop algorithm checklist

```text
pop until nullopt
for every value, write exact record bytes plus one '\n'
if stream state fails, remember failure
do not exit early solely because stream failed; keep draining queue
after nullopt, flush and check
close file and check
return normally
```

### 27.8 shutdown algorithm checklist

```text
close queue first
if writer is joinable, join it
only after join read final failure flag
return final status
sequential repeated call must not join twice
```

### 27.9 destructor checklist

```text
call shutdown as lifecycle fallback
do not detach
do not let writer outlive members
do not attempt to report status through destructor return value
```

---

## 28. 必做 basic tests

今天使用 GoogleTest，但 test bodies 由你自己写。

下面列的是必须覆盖的 **behaviors**，不是强制要求六个一模一样的 `TEST` bodies。只要 test name 和 failure diagnosis 仍清楚，可以把相近边界合并，例如：

```text
zero capacity + output open failure          -> constructor boundaries
single-producer order + repeated shutdown
    + post-shutdown rejection                -> normal lifecycle
```

不要为了减少 test 数量，把多个互不相关的并发场景塞进一个失败后无法定位的巨型 test。

### 28.1 `RejectsZeroCapacity`

```text
construct capacity=0
EXPECT_THROW invalid_argument
test process does not hang/terminate
```

### 28.2 `RejectsOutputOpenFailure`

选择一个确定不存在且无法由单次 file open 自动创建父目录的 path，并在 test 开始前确认该 parent 不存在：

```text
missing_parent_directory/async.log
```

```text
construct logger
EXPECT_THROW runtime_error
test process does not hang/terminate
```

不要使用依赖当前用户权限偶然失败的 `/root/...` 作为唯一测试。

### 28.3 `WritesSingleProducerRecordsInOrder`

```text
construct logger
log A/B/C; each returns true
shutdown returns true
read output file
assert lines exactly [A, B, C]
```

这个 test 同时证明：

```text
normal acceptance
single-producer FIFO
shutdown waits for writer
final flush/close allows deterministic read
```

### 28.4 `AcceptsRecordsFromMultipleProducersExactlyOnce`

```text
several producer threads
each submits unique IDs such as producer-i-record-j
record every log() result
join producers
shutdown logger
read all lines
assert every successful ID appears exactly once
```

不要断言不同 producers 的全局 line order。

Day5 不要求故意把 queue 填满或让 shutdown 与 blocked producer 精确交错；那是 Day6。

### 28.5 `RejectsLogAfterShutdownAndAllowsRepeatedShutdown`

```text
construct logger
first shutdown returns true
second shutdown returns same status
log("late") returns false
file does not contain late
```

### 28.6 `DestructorDrainsBasicRecords`

```text
create logger in inner scope
submit a few accepted records
do not explicitly call shutdown
leave scope
read file after scope
assert accepted records are present
```

这个 test 证明 destructor fallback，不替代正常路径显式检查 `shutdown()` status。

---

## 31. 普通构建、定向运行与 TSan

这里只保留实际执行命令；CMake 关系已经在第 25 节讲清楚。

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build -j
cmake -E chdir build ctest --output-on-failure
```

TSan 使用独立 build tree：

```bash
cmake -S . -B build-tsan \
    -DCMAKE_BUILD_TYPE=Debug \
    -DENABLE_TSAN=ON
cmake --build build-tsan -j
cmake -E chdir build-tsan ctest -R AsyncLogger --output-on-failure
```

---

## 35. 今日验收问题

1. synchronous logger 与今天的 AsyncLogger 分别由谁执行 file I/O？异步方案把哪种等待移走了，又保留了哪种 backpressure？
2. `log(record) == true` 精确证明了什么？为什么它不能证明 record 已 written、flushed 或 durable？
3. 为什么 V1 用 single writer？它让 output stream 的 ownership、ordering 和 shutdown 分别简单在哪里？
4. 从 owner 调用 `shutdown()` 开始，按执行主体串出 `close -> drain -> flush/close stream -> writer return -> join return`。
5. `output.flush()` 与 Linux `fsync(fd)` 为什么不是同一个 durability contract？
6. 为什么 constructor 必须先验证 file open，再启动 writer？为什么 V1 还要禁止 move？
7. 多个 producers 的 records 最终顺序由什么决定？V1 能保证什么，不能保证什么？

如果你的代码、流程图和 note 已经自然覆盖这些问题，不需要为了形式重复抄写七段答案；验收时会逐项检查现有证据。

---

## 36. 今日通过标准

### 核心必须完成

```text
AsyncLogger V1 能编译运行
constructor open failure 明确
multiple producers 可以调用 log
one writer exclusively writes stream
log true/false contract 正确
shutdown close/drain/flush/close/join 顺序正确
sequential repeated shutdown 成立
destructor 不留下 joinable writer
normal I/O 下 accepted records exactly once
post-shutdown record 不进入 file
```

### 工程证据

```text
C++17
-Wall -Wextra -g
Threads::Threads / -pthread
GoogleTest failures affect exit code
CTest normal suite passes
TSan run has no sanitizer report on exercised paths
test output files are isolated and cleaned
```

### 不阻塞 Day5

```text
受控制造 full-queue backpressure timing
shutdown 与多个 blocked producers 的完整交错矩阵
运行中 disk-full/write-failure injection
sync vs async benchmark
append/rotation/levels/formatter
fsync durability
```

这些属于 Day6 或更后面的工程增强。

### Day5 不通过的真正原因

```text
producer 仍直接写 shared stream
log true 被误写成 written/durable
join before queue close 导致可能 hang
close 后直接丢弃已 accepted records
writer exception 逃出导致 terminate
destructor 时 writer 仍访问 members
file open failure 后仍启动 writer
测试只靠 sleep/人工看 output
```

---

## 37. 今日压缩记忆

```text
AsyncLogger V1 = many producers + bounded queue + one writer + one file sink。

log true 只表示 accepted；
accepted != written != flushed != durable。

single writer 独占 stream；
owner 只负责 close queue 和 join，不与活着的 writer 同时 flush stream。

shutdown 主线：
stop producers -> close acceptance -> drain records
-> flush/close stream -> writer returns -> join returns。

bounded queue 让内存有上限；
writer 跟不上时，blocking producer 就是 backpressure。
```

下一天不重写 logger。Day6 会在同一份 `AsyncLogger` 上把 backpressure、shutdown interleavings、accepted/written/flushed 边界和 benchmark 变成更强的 executable evidence。

---

## 38. 今日参考资料

- [C++ working draft：`basic_ostream::flush`](https://eel.is/c++draft/ostream.unformatted)
- [C++ working draft：file buffer open/close](https://eel.is/c++draft/filebuf.members)
- [C++ working draft：`ios_base::openmode`](https://eel.is/c++draft/ios.openmode)
- [Linux man-pages：`fsync(2)`](https://man7.org/linux/man-pages/man2/fsync.2.html)

资料边界：C++ draft 用于核对 stream/open/flush/close semantics；Linux `fsync(2)` 只用于说明 durability 与 C++ stream flush 不同。Day5 不实现 POSIX durable logger。
