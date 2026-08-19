# Week8：ThreadPool + AsyncLogger + 测试与 benchmark 初步

> 本周定位：把 Week7 已经掌握的 thread lifecycle、mutex、condition_variable、BlockingQueue、atomic 和 benchmark 纪律，组合成第一组真正可复用的 C++ 基础组件。
>
> 本周不是继续背并发 API，也不是追求“高性能框架”名头；重点是 ownership、lifecycle、错误边界、测试证据和可解释的设计取舍。
> 本文件只负责周规划。每天的详细教程在进入对应 Day 时，再结合前一天代码和 note 单独生成。

---

## 1. Week8 在总路线中的位置

已经正式完成：

```text
Week1：C++ 对象、指针、资源管理基础
Week2：拷贝控制、移动语义、智能指针、异常安全
Week3：STL 与工程数据结构
Week4：Linux fd、process、pipe、mmap 与 6.S081 第一轮
Week5：virtual memory、trap、thread、lock、sleep/wakeup
Week6：网络原理、TCP/UDP、socket、HTTP parser
Week7：std::thread、mutex、condition_variable、BlockingQueue、atomic、false sharing
```

Week7 的真正出口不是“见过并发 API”，而是已经能处理：

```text
worker lifecycle
shared invariant + mutex
predicate + condition_variable
bounded BlockingQueue
close / drain / graceful shutdown
atomic RMW / CAS
correctness、TSan 与 benchmark 证据边界
```

Week8 在此基础上增加：

```text
task abstraction
ThreadPool worker loop
future / packaged_task result channel
component-level shutdown ownership
AsyncLogger producer/writer split
GoogleTest 初步
可解释的 benchmark
README / interview.md / integration evidence
```

它直接服务后续路线：

```text
Week9 epoll / Reactor
Week10 HTTP Server
Week11~12 Mini Redis
后续 AI Infra serving 中的 task scheduling、queue、batching、backpressure 和 observability
```

---

## 2. 本周总目标

### 2.1 核心目标

本周结束时，应当能够独立回答并用代码证明：

```text
ThreadPool 拥有哪些 objects，谁负责销毁它们？
submitter 怎样把 callable 变成 queue 中的 task？
worker 为什么可以等待 task，又能在 shutdown 后退出？
queued tasks 在 shutdown 时是丢弃还是 drain？
task 的 return value 和 exception 怎样回到 submitter？
AsyncLogger 为什么需要 producer/consumer split？
logger shutdown 时怎样保证已经接受的 logs 写完？
哪些测试证明 correctness，哪些工具只能提供有限证据？
benchmark 测到的是 submit latency、task completion，还是 end-to-end drain？
```

### 2.2 本周核心产出

```text
ThreadPool V1
ThreadPool result-returning submit
AsyncLogger V1
ThreadPool unit tests
AsyncLogger unit tests
TSan / repeated stress evidence
ThreadPool 与 AsyncLogger 的简单 benchmark
一个使用两个组件的 integration demo
README.md
interview.md
```

### 2.3 本周不是简单堆功能

组件的最低工程标准：

```text
public contract 清楚
ownership 清楚
shared state 与 invariant 清楚
shutdown state transition 清楚
错误和 exception 路径明确
对象析构时没有仍在访问它的 worker
测试失败会影响 test result / process exit status
规定参数零 warning
有 sanitizer 和重复运行证据
README 能让别人构建、运行和理解边界
```

---

## 3. 本周范围与停止边界

### 3.1 本周必须掌握

```text
task 与 callable 的关系
std::function<void()> 作为 C++17 task type erasure 的一种选择
固定数量 worker threads
worker loop
BlockingQueue 复用
submit / shutdown contract
drain-before-exit graceful shutdown
std::future
std::packaged_task
task return value 与 exception propagation
AsyncLogger 单 writer execution flow
bounded queue backpressure
close / flush / join 顺序
GoogleTest 的 TEST、EXPECT、ASSERT 第一层使用
correctness build、TSan build、optimized benchmark 分离
```

### 3.2 本周明确不做

```text
dynamic resize
work stealing
task priority
task cancellation
timed submit
lock-free queue
复杂 memory_order
coroutine thread pool
sender/receiver framework
完整日志等级、格式化库和 source location
log rotation
按日期切文件
跨进程日志
崩溃时绝对不丢日志
spdlog 源码
Google Benchmark 深入
复杂 CMake 工程模板
```

这些不是不重要，而是会掩盖本周真正要学的两条主线：

```text
task lifecycle
log lifecycle
```

### 3.3 MIT 6.S081 / CMU 15-445

MIT 6.S081：

```text
本周不新增 lecture 压力。
只在需要时回扣 scheduler、sleep/wakeup、lock 和 execution flow。
不重新抄 xv6 流程，不做 lab。
```

CMU 15-445：

```text
本周不开。
数据库伴随线继续等待 Mini Redis / MySQL 阶段。
```

---

## 4. 七天主线概览

| Day | 核心问题 | 主要产出 |
|---|---|---|
| Day1 | queue 里放的 task 到底是什么，worker 在循环什么？ | `task_dispatch_demo.cpp` + ThreadPool 设计草图 |
| Day2 | ThreadPool 怎样接受 tasks、drain queue 并安全退出？ | `thread_pool.hpp` + `thread_pool_test.cpp` V1 |
| Day3 | task 的 return value 和 exception 怎样回到 submitter？ | result-returning `submit` + future tests |
| Day4 | 怎样证明 ThreadPool 不只是 happy path 跑通？ | GoogleTest、TSan、stress tests、最小 CMake |
| Day5 | 日志 I/O 为什么要和业务 execution flow 分开？ | `async_logger.hpp/.cpp` + basic test V1 |
| Day6 | AsyncLogger 怎样处理 backpressure、drain、flush 和 benchmark？ | lifecycle tests + sync/async benchmark |
| Day7 | 两个组件怎样组合，并成为能展示、能解释的小项目？ | integration demo + README + interview.md + Week8 验收 |

七天不是七套互不相关的 demo。演进关系是：

```text
Week7 BlockingQueue
    |
    +--> ThreadPool task queue
    |       |
    |       +--> future / exception result channel
    |       +--> gtest / TSan / stress evidence
    |
    +--> AsyncLogger log-record queue
            |
            +--> single writer + file ownership
            +--> drain / flush / benchmark evidence

ThreadPool + AsyncLogger
    -> integration demo
    -> README / interview.md
```

---

## 5. 每日详细规划

# Day1：queue 里放的 task 到底是什么

## 今日目标

```text
从“worker 不可能提前知道将来要执行哪个函数”出发
区分 callable、task object、task queue 和 worker execution flow
理解 std::function<void()> 解决的当前问题和限制
写出 worker loop 的状态与退出条件
先验证 task dispatch，再封装 ThreadPool
```

## 前置连接

Week7 的 BlockingQueue 存过普通 values。ThreadPool 要复用同一个 lifecycle model，但 element 变为：

```text
一项将来可以被某个 worker 调用的 work
```

Day1 必须先讲清：

```text
callable 是“能被调用的 C++ object/function”
task 是 ThreadPool 接受的一项工作
std::function<void()> 是把不同 callable 包装成统一 void() 接口的一种 type erasure
queue 保存 task objects，不保存正在运行的 threads
worker pop task 后，在 queue lock 外执行 task
```

## 计划产出

独立完成 `task_dispatch_demo.cpp`：

```text
创建一个 BlockingQueue<std::function<void()>>
创建固定数量 workers
main push 多种 callable tasks
每项 task 更新可验证的独立结果或受保护结果
main close queue
workers drain queued tasks 后退出
main join 所有 workers
最终检查 accepted task count == executed task count
```

该文件只验证 task abstraction 与 worker loop，不在 Day1 提前完成整个 ThreadPool class。

## 必须形成的设计草图

```text
ThreadPool owns:
    task queue
    worker thread objects
    lifecycle state

submitter:
    builds task
    submits task

worker:
    waits/pops task
    executes outside queue critical section
    exits after closed-and-empty

owner:
    initiates shutdown
    joins workers
    destroys pool only after join
```

## 今日停止边界

```text
不讲 packaged_task
不返回 future
不追求 generic submit template
不 benchmark
不复制一份新的 BlockingQueue implementation
```

---

# Day2：ThreadPool 怎样安全接受、执行和停止 work

## 今日目标

```text
把 Day1 的 objects 和 flow 封装进 ThreadPool V1
固定 worker count
定义 submit 与 shutdown 的 public contract
复用 BlockingQueue close/drain 语义
保证 destructor 返回时所有 workers 已退出并 join
隔离 task exception，避免一个异常直接终止 worker execution flow
```

## ThreadPool V1 的程序目的

ThreadPool V1 解决：

```text
application 不为每个小任务反复创建和销毁 thread
固定 workers 重复从 queue 获取 work
owner 能明确停止接收新 work
已经接受的 work 在退出前被 drain
所有 worker lifecycle 由 ThreadPool object 统一管理
```

## 计划产出

```text
thread_pool.hpp
thread_pool_test.cpp
```

V1 public behavior 至少包含：

```text
construct(worker_count)
submit(std::function<void()> task) -> 明确成功/失败
shutdown()
destructor
copying disabled
```

具体命名在 daily 中结合代码习惯确定，不要求机械照抄上述签名。

## 必须先决定的 contract

```text
worker_count == 0：reject 还是 normalize？
submit after shutdown：返回 false、抛异常还是其他明确结果？
shutdown 是否幂等？
shutdown 是否 drain 已接受 tasks？
task 抛异常时由谁观察？
destructor 是否自动 shutdown + join？
谁允许调用 shutdown？
```

本周建议 V1：

```text
0 workers 明确拒绝
submit after shutdown 明确失败
shutdown 幂等
已经接受的 tasks 全部 drain
destructor 负责最终 shutdown + join
shutdown 由 owner/control execution flow 调用
不支持 worker task 内部销毁 pool 或 join 自己
```

## 核心测试方向

```text
0 tasks
1 worker / 1 task
多个 workers / 多个 tasks
task 数量大于 worker 数量
每项 accepted task exactly once
shutdown with queued tasks
repeated shutdown
submit after shutdown
destructor path
```

## 今日停止边界

```text
V1 task 先统一为 void()
不在同一天加入 future template
不做 dynamic resize
不使用 detach
```

---

# Day3：task 的 return value 和 exception 怎样回到 submitter

## 今日目标

```text
区分 task execution 与 result observation
理解 std::future 是一次性结果通道，不是 worker thread
理解 std::packaged_task 把 callable execution 与 future state 连接起来
让 task return value 和 exception 回到 submitter
把 result-returning submit 接入 ThreadPool
```

## 今天要解决的具体问题

Day2 只能做到：

```text
submit work
-> 某个 worker 执行
```

Day3 继续解决：

```text
submit f(args...)
-> 立刻得到 future<R>
-> worker 将来执行 f(args...)
-> return value 或 exception 写入 shared state
-> submitter 调用 future.get() 取得结果或重新观察 exception
```

## 必要 C++17 范围

daily 需要适量补齐，而不是假设用户熟悉：

```text
function template 的 parameter pack 第一层
std::invoke_result_t
perfect forwarding 当前用途
std::packaged_task<R()>
std::future<R>
move-only packaged_task 与 copyable std::function 的边界
```

本日不扩展：

```text
复杂模板元编程
SFINAE
concepts
continuation / then
shared_future 深入
promise 的复杂组合
```

## 计划产出

升级同一份 `thread_pool.hpp`，不复制 `thread_pool_v2_final_new.hpp`。

至少验证：

```text
task 返回 int/string
task 返回 void
task 接收 value argument
task 接收显式 reference wrapper
task 抛出 exception，worker 不崩溃，future.get() 观察到 exception
多个 futures 可以按不同于提交顺序的顺序 get
submit after shutdown 不产生永远无法 ready 的 future
```

## 关键边界

```text
future.get() 可能 blocking
future.get() 通常只能成功取一次
future ready 不等于 task 按提交顺序完成
worker 数量固定不代表 task completion order 固定
submit 成功与 task 执行成功是两个不同阶段
```

---

# Day4：怎样证明 ThreadPool 不只是 happy path 能跑

## 今日目标

```text
学习 GoogleTest 最小使用方式
把 ThreadPool contract 变成 executable tests
区分 deterministic unit test、concurrency stress 和 TSan
让 failure 真实影响 test result / exit code
建立最小 CMake build/test 入口
```

## GoogleTest 当前范围

只学习足够完成组件测试的内容：

```text
TEST
EXPECT_EQ / EXPECT_TRUE / EXPECT_FALSE
ASSERT_* 与 EXPECT_* 的当前差异
EXPECT_THROW / ASSERT_THROW
test executable
ctest 或直接运行 test binary
```

若 Ubuntu 尚未安装 GoogleTest，在生成 Day4 daily 时再检查环境和给出最小配置；Week8 计划阶段不提前折腾。

## 计划产出

```text
tests/thread_pool_test.cpp
CMakeLists.txt
test evidence in day4_note.md
```

核心测试矩阵：

```text
construct boundary
zero task shutdown
single task
many tasks exactly once
return value
void result
task exception -> future exception
queued tasks drained during shutdown
repeated shutdown
submit rejected after shutdown
multiple concurrent submitters
destructor leaves no joinable worker
```

## 三类证据必须分开

```text
GoogleTest：某个具体 contract 是否满足
stress repeat：在更多 scheduling interleavings 下重复寻找错误
TSan：已执行路径是否观察到 data race
```

不能写成：

```text
TSan clean -> shutdown 一定正确
tests PASS -> 不可能 deadlock
运行 100 次 -> 已证明没有 race
```

## Day4 通过标准

```text
test name 能说清场景和 expected behavior
错误会让 test binary non-zero
测试不依赖固定 sleep 猜调度顺序
规定参数零 warning
TSan 没有 data-race report
```

---

# Day5：日志 I/O 为什么要和业务 execution flow 分开

## 今日目标

```text
从 synchronous logging 对 caller latency 的影响出发
建立 producer -> log queue -> writer execution flow
明确 log record、queue、file stream 和 writer 的 ownership
实现 AsyncLogger V1
复用 BlockingQueue close/drain，不重写同步协议
```

## AsyncLogger V1 的程序目的

```text
多个 producer execution flows 提交 log records
producer 不直接竞争写同一个 file stream
一个 background writer 按 queue 取出顺序写文件
shutdown 停止接收新 records
已经接受的 records 在退出前 drain
writer flush、退出并被 owner join
```

这里的 `async` 只表示：

```text
caller 提交 log record
与 background writer 执行 file I/O
由不同 execution flows 完成
```

它不自动意味着：

```text
每次 log 都更快
日志绝不丢失
磁盘已经持久化
全局业务事件顺序等于 wall-clock 真相
```

## 计划产出

```text
async_logger.hpp
async_logger.cpp
async_logger_test.cpp
```

V1 范围：

```text
bounded queue
std::string 或简单 LogRecord
single writer thread
single output file
blocking backpressure policy
log() 明确成功/失败
idempotent shutdown
close -> drain -> flush -> writer exit -> join
```

## 必须明确的 ownership

```text
producers own input message before successful submit
logger owns accepted LogRecord
queue owns queued records
writer is the only execution flow that writes the stream
AsyncLogger object owns queue、stream state 和 writer thread object
owner ensures logger outlives all producers that may call log()
```

## 当前不做

```text
log level filtering
timestamp formatter 深入
rotation
drop-oldest / drop-newest policy
lock-free ring buffer
crash recovery
```

---

# Day6：AsyncLogger 怎样处理 backpressure、drain、flush 与 benchmark

## 今日目标

```text
把 AsyncLogger lifecycle contract 变成测试
区分 accepted、written、flushed 和 durable
验证多个 producers 与 shutdown 交错
观察 bounded queue backpressure
设计不撒谎的 sync/async logging benchmark
```

## 计划测试

```text
empty logger shutdown
one producer / one record
multiple producers / unique record IDs
small capacity 制造 backpressure
shutdown with queued records -> 全部 drain
repeated shutdown
log after shutdown -> 明确失败
output file open failure
final line count 与 accepted count 一致
每个 accepted ID exactly once
writer thread 最终 join
```

并发 producers 的顺序只要求到合理范围：

```text
同一 producer 顺序提交的 records 应保留其 queue submission order
不同 producers 谁先成功进入 queue 由实际 synchronization order 决定
不能用打印顺序反推真实 wall-clock 总顺序
```

## benchmark 计划

至少区分两类时间：

```text
producer-visible submit time
end-to-end time：最后一个 accepted record 真正写完并完成 shutdown/join
```

比较候选：

```text
synchronous single-thread file write
AsyncLogger one producer
AsyncLogger multiple producers
不同 queue capacities
```

记录：

```text
CPU / VM
compiler flags
record count
record size
producer count
queue capacity
flush policy
repeat results
median/range
文件最终大小或 line count
```

必须避免的错误结论：

```text
只测 submit 返回就宣称日志已经写完
sync 每条 flush、async 最后 flush，却说两者条件完全相同
把 TSan build timing 与 -O2 timing 比较
只运行一次就宣布固定倍数
忽略最终文件 correctness
```

## 今日停止边界

如果当前 filesystem/VM 噪声很大，只要数据真实、方法说清、结论限定范围，不因“没测出 async 更快”而不通过。

---

# Day7：把组件变成能运行、能解释、能展示的小项目

## 今日目标

```text
组合 ThreadPool 与 AsyncLogger
验证两个独立 lifecycle 的正确关闭顺序
完成 README 与 interview.md
整理测试、sanitizer 和 benchmark 证据
完成 Week8 出口验收
```

## 计划产出一：integration demo

实现一个受控的 `component_demo.cpp`：

```text
main 创建 AsyncLogger
main 创建 ThreadPool
submit 多项可验证 tasks
tasks 完成业务计算并提交 log records
main 通过 futures / counters 确认 tasks 完成
main shutdown ThreadPool 并 join workers
确认不会再有 task 调用 logger
main shutdown AsyncLogger，drain logs 并 join writer
检查结果与日志记录
```

关键关闭顺序：

```text
stop accepting work
-> drain ThreadPool tasks
-> join pool workers
-> 此后不会再产生新 logs
-> close logger queue
-> drain logs
-> flush and join writer
-> destroy components
```

如果反过来先销毁 logger，而 queued tasks 后续仍调用它，就会形成明确 lifetime bug。Day7 必须能解释这个依赖关系。

## 计划产出二：README.md

至少包含：

```text
项目目的
目录结构
ThreadPool architecture
AsyncLogger architecture
public interface 与 lifecycle
构建方式
最小使用示例
测试方式
TSan 方式
benchmark 方法与结果
已知限制
后续演进方向
```

## 计划产出三：interview.md

至少回答：

```text
为什么不用每个 task 创建一个 thread？
为什么 task queue 需要 close/drain？
为什么 worker 在 queue lock 外执行 task？
future 与 packaged_task 分别负责什么？
task exception 怎样传播？
ThreadPool destructor 为什么必须 join？
AsyncLogger 的 single writer 解决什么问题？
backpressure policy 是什么？
shutdown 为什么先 pool 后 logger？
你的 benchmark 测量了什么，不能证明什么？
```

## Week8 出口动作

```text
运行完整 unit tests
重复 stress tests
运行 TSan
运行 optimized benchmark
保存代表性证据
检查 -Wall -Wextra
检查 README 命令能否从干净目录执行
检查 git diff / status
```

---

## 6. 建议目录

Windows 学习资料：

```text
C:\Users\FxorG\Desktop\gpt_infra\week8\
├── week8.md
├── day1\
│   ├── day1.md
│   └── day1_note.md
...
└── day7\
    ├── day7.md
    └── day7_note.md
```

Ubuntu 代码建议使用一份持续演进的 canonical source，不按 Day 复制七套组件：

```text
~/code/system-learning/cpp/week8/
├── CMakeLists.txt
├── demos/
│   ├── task_dispatch_demo.cpp
│   └── component_demo.cpp
├── include/
│   ├── blocking_queue.hpp
│   ├── thread_pool.hpp
│   └── async_logger.hpp
├── src/
│   └── async_logger.cpp
├── tests/
│   ├── thread_pool_test.cpp
│   └── async_logger_test.cpp
├── benchmark/
│   ├── thread_pool_bench.cpp
│   └── async_logger_bench.cpp
├── README.md
└── interview.md
```

说明：

```text
BlockingQueue 从 Week7 复制/迁入一次作为 Week8 canonical dependency
后续只维护这一份 Week8 component source
Day2~Day4 通过 Git 观察 ThreadPool 演进
Day5~Day6 通过 Git 观察 AsyncLogger 演进
不创建 final_v2_new_copy 之类重复源文件
```

现在只创建 `week8.md`，不提前生成 daily、note、C++ source 或空目录树。

---

## 7. Daily 教程生成约定

每份 `dayN.md` 继续固定三个 Part，顺序不变：

```text
Part 1：前情提要与必要术语
Part 2：教程主体
Part 3：收尾、练习、测试与验收
```

Part 2 开头必须明确写：

```text
教程开始：从“当天的具体工程问题”出发
```

### 7.1 先把主线讲完整

不能在用户尚未理解 ThreadPool/AsyncLogger 主流程前，就分散追问：

```text
为什么不用 work stealing？
为什么不用 lock-free？
为什么不是无界 queue？
为什么 benchmark 不是线性加速？
```

每个新组件先完整串起：

```text
谁创建 object
谁提交 element
谁等待
谁取出并执行/写入
谁发起 close
谁 drain
谁 join
谁最后销毁资源
```

然后再解释设计问题和替代方案。

### 7.2 术语首次出现必须解释

Week8 特别注意：

```text
callable
task
type erasure
worker loop
submit
future
shared state
packaged_task
exception propagation
thread pool
asynchronous logging
log record
backpressure
flush
throughput
latency
end-to-end
unit test
fixture
stress test
benchmark
```

首次出现至少说明：

```text
英文全称或词源
中文含义
在当前组件里的具体作用
它不是什么
```

### 7.3 API 讲解要求

非简单 API 至少包含：

```text
header
signature
parameters
return value
它改变或关联的 object state
一个与当天完整练习分离的最小使用例子
```

Week8 特别是：

```text
std::function
std::future::get
std::packaged_task
std::invoke_result_t
std::forward
GoogleTest assertions
ofstream open/write/flush
```

不能只贴签名后让用户自己猜怎样使用。

### 7.4 练习保留独立实现空间

Week8 是组件项目周。用户编码前，daily 只给：

```text
程序整体目的
objects 与 execution flows
public contract
ownership
shared state / invariant
lifecycle state transition
错误与 exception 路径
测试矩阵
验收标准
允许查阅的 API
```

不能提前给：

```text
完整 worker loop
完整 submit template
完整 packaged_task wrapping 答案
完整 AsyncLogger writer loop
可以直接复制的完整 test harness
```

必要参考实现只在用户独立完成后的 review 中讲，不回写已冻结 daily。

### 7.5 每份代码先说明“它是干什么的”

在任何大段 contract 前，先明确：

```text
程序解决什么问题
输入/调用从哪里来
输出和成功标准是什么
有哪些 execution flows
程序怎样正常结束
本日不实现什么
```

避免只列十几条接口约束，让用户不知道最终要构建什么。

---

## 8. 编译、测试与工具要求

### 8.1 默认编译

不用 CMake 时：

```bash
g++ -std=c++17 -Wall -Wextra -g -pthread source.cpp -o program
```

多文件时列出所有 translation units，不隐藏链接过程。

### 8.2 TSan

```bash
g++ -std=c++17 -Wall -Wextra -g -O1 -pthread \
  -fsanitize=thread -fno-omit-frame-pointer \
  source.cpp -o program_tsan
```

本周仍要明确：

```text
TSan clean
!=
没有 deadlock、lost task、double execution、lifecycle bug 或业务错误
```

### 8.3 GoogleTest

Day4 开始建立最小测试入口：

```text
test binary 能独立运行
每个 contract 有对应 scenario
failure 影响 exit code
必要时由 CTest 统一调用
```

不要求本周学习复杂 fixture、parameterized test、mock framework。

### 8.4 Benchmark

optimized benchmark 单独构建：

```bash
g++ -std=c++17 -Wall -Wextra -g -O2 -DNDEBUG -pthread \
  benchmark.cpp -o benchmark
```

不把以下结果直接混合：

```text
debug
TSan
-O2 optimized
```

每个 benchmark 必须说明：

```text
计时区间
单位
repeat 次数
median/range 算法
correctness check
是否包含 queue drain / flush / join
```

### 8.5 可选工具

```text
/usr/bin/time
strace -f
gdb
valgrind（若环境合适）
```

工具只在能回答具体问题时使用，不为了工具清单中出现过就全部跑一遍。

---

## 9. 本周测试纪律

### 9.1 不用 sleep 证明顺序

可以短暂 sleep 扩大观察窗口，但正确性必须来自：

```text
mutex/predicate
queue state
future readiness
explicit counters/latches built from current tools
join
file content verification
```

### 9.2 task / record identity

多线程测试使用 unique IDs，验证：

```text
accepted count
executed/written count
missing IDs
duplicate IDs
unexpected IDs
```

只检查总和有时会让重复和遗漏互相抵消。

### 9.3 生命周期测试必须建立真实状态

不能只给测试起名 `shutdown_with_pending_tasks`。测试必须真的证明：

```text
某些 tasks/records 已 accepted 但尚未完成
shutdown 与它们发生目标交错
最终全部 drain 或按 contract 处理
all workers/writer joined
```

### 9.4 失败必须可见

```text
assertion failure -> test fails
unexpected exception -> test fails
timeout/deadlock -> 有受控超时和诊断
main 不应在打印 FAIL 后仍返回 0
```

### 9.5 不重复 Week7 无变化测试

BlockingQueue source 未变化时，Week8 不重新写一套独立 queue tests。真正有价值的验证是：

```text
ThreadPool 怎样使用 queue close/drain
AsyncLogger 怎样使用 queue backpressure/close
component owner 怎样安排 join/destroy
```

若 Week8 为支持 move-only value 修改 BlockingQueue，才针对变更面补回归测试。

---

## 10. 本周核心验收问题

1. callable、task、worker 和 thread object 分别是什么？
2. 为什么 ThreadPool queue 中可以统一保存 `std::function<void()>`？代价和限制是什么？
3. worker 为什么必须在 queue critical section 外执行 task？
4. ThreadPool object 拥有哪些资源？谁负责发起 shutdown 和 join？
5. graceful shutdown 时，已经 accepted 的 tasks 怎样处理？
6. submit after shutdown 应怎样表现？为什么必须明确 contract？
7. 为什么 destructor 不能在 workers 仍访问 pool members 时直接返回？
8. `future` 是 thread 吗？它和 result shared state 是什么关系？
9. `packaged_task` 怎样把 callable 的 return value/exception 连接到 future？
10. C++17 中 move-only packaged task 与 copyable `std::function` 有什么边界？
11. task 抛异常时，怎样避免 worker execution flow 被意外终止？
12. GoogleTest、stress run 和 TSan 分别提供什么证据？
13. AsyncLogger 的 producers、queue、writer 和 output stream 分别由谁拥有？
14. bounded logger queue 满时，V1 的 backpressure policy 是什么？
15. accepted、written、flushed、durable 为什么不是同一状态？
16. AsyncLogger shutdown 为什么需要 drain 和 join？
17. 多个 producers 的 log records 是否有天然的全局业务顺序？
18. integration demo 为什么先停止 ThreadPool，再停止 AsyncLogger？
19. 只测 `log()`/`submit()` 返回时间，为什么不能代表 end-to-end throughput？
20. 本周组件离 production ThreadPool/logger 还有哪些明确差距？

验收时不要求机械抄写二十段。如果代码、主动补充、测试和口述已经覆盖某些问题，可直接引用证据；只追问仍无法从产出判断的关键边界。

---

## 11. Week8 最终完成标准

### 11.1 核心通过

```text
能解释 task abstraction 与 worker loop
独立实现固定 worker 数量的 ThreadPool
ThreadPool 明确拥有和 join 所有 workers
submit/shutdown contract 清楚
shutdown 能 drain accepted tasks
submit after shutdown 有明确结果
task return value 和 exception 可通过 future 观察
独立实现 single-writer AsyncLogger V1
logger 使用 bounded queue 和明确 backpressure policy
logger shutdown 能 drain accepted records、flush 并 join
integration demo 使用正确的 pool/logger 关闭顺序
ThreadPool 与 AsyncLogger 都有 contract-driven tests
核心并发路径有 repeated stress 与 TSan 证据
benchmark 区分 producer-visible 与 end-to-end timing
代码在规定参数下零 warning
README 命令可运行，已知限制诚实
能用 interview.md 解释关键设计取舍
```

### 11.2 工程增强，不阻塞 Week8

```text
move-only arbitrary callable 完整支持
timed submit
task cancellation
dynamic worker resize
work stealing
priority queue
logger severity/filter
timestamp/source location formatter
log rotation
drop policy
fsync durability
Google Benchmark library
完整 install/package CMake
代码覆盖率
```

### 11.3 Week8 不通过的真正原因

```text
ThreadPool destructor 时仍有 joinable workers
worker 在 queue mutex 内执行 task
shutdown 后仍接受 task，却没有定义其命运
close 后 queued tasks 被意外丢弃且 contract 未说明
task exception 直接导致 std::terminate 或悄悄消失
future 永远不 ready
AsyncLogger object 销毁后仍有 producer/writer 访问它
logger shutdown 丢失已经 accepted 的 records
多个 threads 无同步地写同一 stream
测试只跑 happy path，失败仍返回 0
用 sleep/cout 顺序代替 synchronization evidence
benchmark 不说明单位、计时范围、优化参数或 correctness
README 无法让别人构建运行
```

不会因为以下原因阻塞：

```text
没有 work stealing
没有 lock-free queue
没有动态线程数
没有完整 logger ecosystem
没有每条日志 fsync
没有测出 async logger 固定更快
没有新增 6.S081 lecture
没有开始 CUDA / Triton
```

---

## 12. 本周面经雷达

Week8 结束时再抽 5~10 篇 C++ Infra / AI Infra 相邻岗位面经，限时 30~60 分钟。

只记录与当前组件直接相关的内容：

```text
线程池 worker 数量怎样选择
线程池 shutdown 怎样设计
future / promise / packaged_task 区别
任务异常怎样处理
阻塞队列与 backpressure
异步日志为什么快/为什么可能不快
日志丢失与 flush policy
如何测试多线程组件
如何定位 race/deadlock
如何做 benchmark
```

不因面经出现以下词就临时改主线：

```text
work stealing production scheduler
lock-free MPMC queue
folly executor
io_uring executor
CUDA stream scheduler
distributed tracing platform
```

输出仍使用：

```markdown
## 本周面经雷达

### 高频但我不会的

### 和当前项目相关的

### 下周要补的

### 暂时不碰的
```

---

## 13. 与 Week9 的连接

Week9 将进入 epoll / Reactor 第一轮。Week8 组件会这样被复用：

```text
EventLoop 负责 readiness events
ThreadPool 可承接不应长时间阻塞 EventLoop 的受控 work
AsyncLogger 让网络 execution flow 不直接承担 file I/O
BlockingQueue 提供跨 execution-flow handoff 与 backpressure
shutdown contract 决定 server 怎样 graceful exit
```

但 Week9 必须继续保持边界：

```text
不是把每个 socket event 随便扔进 pool 就自动成为 Reactor
不是加了 AsyncLogger 就自动得到高性能 server
EventLoop ownership、fd state 与 callback lifetime 仍需单独学习
```

Week8 最终应能用自己的话表达：

```text
“我已经不只是会创建 threads。

我能把 work 封装成 tasks，让固定 workers 从 bounded queue 中获取并执行，
能定义 submit、future、exception 和 graceful shutdown 的完整生命周期。

我也能把多个 producers 的日志交给单 writer，处理 backpressure、drain、flush 和 join，
并用 unit tests、stress、TSan 与 benchmark 分别提供边界清楚的证据。

这两个组件还不是 production framework，
但它们已经有明确接口、错误边界、测试、文档和可继续演进的结构。”
```
