# Week7：C++ 多线程同步 + 可关闭的 BlockingQueue

> 定位：Week5 已经从 OS 视角理解 thread、scheduler、race、mutex、sleep/wakeup 和 condition variable；Week6 已经建立阻塞式网络与 application framing。Week7 不重新讲一遍线程入门，而是把已有机制落到 C++17 的生命周期、共享状态契约和可复用并发组件上。
>
> 本周主线：thread 生命周期与工作归属 -> mutex 保护共享不变量 -> condition_variable 与 backpressure -> BlockingQueue -> graceful shutdown -> atomic/CAS -> contention 与 false sharing。
>
> 本周核心产出：一个经过多线程测试、能够 `close()` 并正确退出的 bounded `BlockingQueue<T>`，供 Week8 `ThreadPool V1` 直接复用。

当前状态说明：

```text
Week6 Day7 教程已经生成，但尚未检阅和正式验收。
Week7 周计划可以提前生成，以节省等待时间。
这不代表 Week6 已通过，也不代表 Week7 已正式开始。
```

进入 Week7 Day1 前，仍应先完成 Week6 Day7 的代码、note 与验收。

---

## 1. 规划依据

### 1.1 总规划要求

`plan_strengthened.md` 对 Week7 的定位是：

```text
C++ 多线程和同步
-> 为 BlockingQueue、ThreadPool 和高性能服务端做准备
```

要求覆盖：

```text
std::thread
join / detach
mutex
lock_guard
unique_lock
condition_variable
producer-consumer
BlockingQueue
atomic 基础
CAS 初步
false sharing 了解即可
```

本周不会把这些词平均拆成七份 API 课，而是围绕一个组件逐步增加工程约束：

```text
先能正确创建和回收 execution flows
-> 再保护 shared invariant
-> 再让等待者在条件不满足时阻塞
-> 再封装成 bounded BlockingQueue
-> 再解决 shutdown
-> 最后比较 mutex、atomic 与 cache contention
```

---

### 1.2 当前真实起点

Week5 已经完成并验收：

```text
race_counter.cpp / mutex_counter.cpp
ThreadSanitizer 第一轮
std::thread 创建、std::ref 传参和 join
thread identity、PID/TID、共享 heap/global 与独立 stack
mutex + lock_guard
condition_variable wait/notify
predicate、lost wakeup、spurious wakeup
RUNNING -> SLEEPING -> RUNNABLE -> RUNNING
xv6 sleep/wakeup 与 C++ condition_variable 的第一层对应
```

因此 Week7 不重新安排：

```text
只创建两个 threads 打印 hello
重新证明多个 threads 共享 process address space
重新做一次“counter++ 偶尔不正确”的完整入门实验
重新手推 xv6 scheduler / swtch
重新解释为什么 wait 要重新检查 predicate
重新抄一份 Week5 race/lock note
```

这些知识会作为前置条件使用；只有当新组件暴露理解缺口时才定向回看。

Week6 还提供了一个重要项目背景：

```text
当前 blocking TCP server 只能由一个 execution flow 顺序处理工作。
未来 ThreadPool 会需要一个安全的 task queue，
而 BlockingQueue 正是 Week7 到 Week8 的桥。
```

本周不直接把 Week6 server 改成 thread-per-connection，也不提前写 ThreadPool。

---

### 1.3 结合实际学习速度

你对单个 C++ API 和基础语法掌握较快，重复接口练习收益低；真正需要投入的是：

```text
共享状态到底由谁拥有
mutex 保护的 invariant 是什么
什么时候必须等待
等待条件由谁修改
close 后 blocked threads 怎样全部退出
析构时怎样保证没有 thread 仍访问已经死亡的对象
测试怎样证明程序不是“刚好这次没卡住”
```

所以本周采用：

```text
Day1~Day3：快速补齐 C++ 工程语义
Day4~Day5：集中实现和打磨 BlockingQueue
Day6：建立 atomic / CAS 的正确边界
Day7：观察 contention / false sharing，完成出口验收
```

每天只新增一个主要复杂度：

```text
Day1：thread lifecycle 与 work/result ownership
Day2：shared invariant 与 mutex scope
Day3：condition_variable、两个 predicates 与 backpressure
Day4：bounded BlockingQueue<T> V1
Day5：close、drain 与 graceful shutdown
Day6：atomic counter、CAS 和适用边界
Day7：contention、false sharing 与 Week7 integration
```

---

## 2. 本周核心问题

本周结束时，应能用自己的话回答：

```text
1. std::thread object 与真正运行的 execution flow 是同一个对象吗？
2. joinable 表示什么？为什么 joinable thread object 析构会触发 std::terminate？
3. join、detach 分别改变谁的生命周期关系？项目代码为什么默认不用 detach？
4. thread callable 和 arguments 默认发生 copy 还是 move？什么时候需要 std::ref？
5. data race、race condition 和普通的 nondeterministic order 有什么区别？
6. mutex 保护的是哪组 shared state 和 invariant，而不只是哪些代码行？
7. lock scope 太大或太小分别会产生什么问题？
8. condition_variable 为什么使用 unique_lock，而不是普通 lock_guard？
9. producer 修改 predicate 与 consumer 检查 predicate 为什么必须使用同一 mutex？
10. bounded queue 的 not_empty 与 not_full 分别由谁等待、由谁使其成立？
11. BlockingQueue close 后，已有 elements、blocked producers 和 blocked consumers 分别怎样处理？
12. 为什么 close 后要 notify_all，而不是只唤醒一个 waiter？
13. atomic read-modify-write 与 mutex critical section 的能力边界有什么不同？
14. compare_exchange 的 expected 为什么可能被改写？CAS loop 为什么要重新计算？
15. atomic 是否能自动维护多个 variables 之间的 invariant？
16. false sharing 中没有 data race，为什么仍可能很慢？
17. 如何用 TSan、重复压力测试和可检查 invariant 提供并发正确性证据？
```

---

## 3. 本周目标深度

### 3.1 std::thread：学生命周期，不重复“会创建线程”

本周结束时做到：

```text
区分 std::thread object、native thread 和 application task
知道 default-constructed、joinable、joined/detached 三类状态
知道 join 是等待 execution flow 结束并回收 thread handle
知道 detach 会解除 std::thread object 与 execution flow 的 join 关系
知道 join/detach 不是“停止 thread”
知道同一个 thread object 不能 join 两次
知道 joinable thread object 析构会 std::terminate
能保证所有成功创建的 workers 在所有正常/异常退出路径上被 join
```

参数和结果只学项目需要的部分：

```text
callable 和普通 arguments 默认保存副本或移动所得对象
std::ref / std::cref 表达“保留引用语义”
move-only argument 通过 std::move 转移给 worker
多个 workers 可以写各自独立的 result slot
main 必须在 join 后再汇总 results
```

不在本周深挖：

```text
native_handle 平台细节
pthread API 全套
thread affinity 调优
实时调度策略
C++20 std::jthread / stop_token
```

---

### 3.2 mutex：从“给代码上锁”升级为“保护 invariant”

必须做到：

```text
先列出 shared state
再写出 state invariant
再决定哪个 mutex 保护它们
所有读取和修改 invariant 的路径遵守同一 locking discipline
用 RAII lock object 管理 unlock
把 I/O、sleep、耗时计算尽量移出 critical section
```

本周使用：

```text
std::lock_guard<std::mutex>
std::unique_lock<std::mutex>
std::scoped_lock（多 mutex 场景只建立第一层直觉）
```

需要知道但不扩展：

```text
deadlock 的基本形成条件
固定 lock order 的意义
多个 mutex 组合时不要手工写容易互锁的相反顺序
```

不实现：

```text
spinlock
recursive_mutex 使用练习
读写锁专题
lock-free data structure
```

---

### 3.3 condition_variable：从 OS 机制升级为组件 contract

Week5 已经解释“为什么能睡眠和唤醒”。Week7 重点变为：

```text
predicate 属于哪个 object
predicate 由哪些 state fields 决定
谁在同一 mutex 下修改这些 fields
哪些 execution flows 等待哪一个 predicate
notify_one 与 notify_all 的选择依据
醒来后怎样在锁内重新检查
shutdown 怎样让永远等不到业务数据的 waiter 退出
```

必须保持：

```text
wait(lock, predicate)
```

等价理解为：

```text
while predicate is false
-> atomic-like release mutex and sleep
-> wake later
-> reacquire mutex
-> recheck predicate
```

这里的 `atomic-like` 只描述“释放 mutex 与进入等待之间不能留下 lost-wakeup window”，不表示整个 `wait` 是 `std::atomic` operation。

---

### 3.4 producer-consumer 与 backpressure

`producer-consumer`：生产者-消费者模型。

```text
producer 创建 elements 并 push
consumer pop elements 并处理
queue 在两类 execution flows 之间传递 ownership
```

本周使用 bounded queue，是为了引入 `backpressure`：背压。

```text
queue empty
-> consumer 不能继续 pop，等待 not_empty

queue full
-> producer 不能继续 push，等待 not_full
```

背压不是“程序变慢了”的同义词，而是：

```text
下游处理能力不足时，系统明确限制上游继续积累 work
```

这会直接连接 Week8 ThreadPool task queue 和 AsyncLogger log queue。

---

### 3.5 BlockingQueue 的本周 contract

最终 `BlockingQueue<T>` 至少具备：

```text
bounded capacity，capacity > 0
多个 producers 可以并发 push
多个 consumers 可以并发 pop
empty 时 pop 阻塞
full 时 push 阻塞
close 可以被调用并唤醒所有 waiters
close 后拒绝新 push
close 前已经入队的 elements 仍允许被 consumers drain
closed 且 empty 后，pop 返回“不会再有数据”
析构前所有使用 queue 的 workers 已退出并 join
```

推荐生命周期状态：

```text
OPEN
  -> push/pop 正常工作
  -> close()

CLOSED_WITH_DATA
  -> push 失败
  -> pop 继续 drain

CLOSED_EMPTY
  -> push 失败
  -> pop 返回结束状态，不再等待
```

本周核心不是把代码写得短，而是保证这三个状态的转移没有线程永久睡眠。

接口具体签名在 Day4 daily 中根据当时进度给出；周计划阶段不提前泄露完整实现或函数排列。

---

### 3.6 atomic 与 CAS 的第一层深度

`atomic`：原子的。当前范围内，某个 atomic operation 不会被其他 threads 观察成“只执行了一半”。

本周做到：

```text
会使用 std::atomic<int> / std::atomic<std::size_t>
会使用 load / store / fetch_add
知道 ++atomic_counter 是 atomic read-modify-write
能写一个受控的 compare_exchange loop
知道 compare_exchange 成功和失败分别发生什么
知道默认 sequential consistency 足够本周使用
知道 atomic 不会自动保护多个普通 fields 的组合 invariant
```

本周只使用默认 memory order：

```text
std::memory_order_seq_cst
```

代码通常不需要显式写出它。以下内容后置：

```text
acquire / release 细节
relaxed ordering 深入
memory fence
ABA problem
hazard pointer / epoch reclamation
lock-free queue
```

---

### 3.7 contention 与 false sharing

`contention`：竞争。多个 execution flows 同时争用同一个同步资源。

需要建立：

```text
程序正确不代表扩展性好
critical section 越长，等待同一 mutex 的时间可能越长
增加 threads 不保证更快
```

`false sharing`：伪共享。

第一层理解：

```text
两个 threads 修改不同 variables
-> 没有对同一 object 的 data race
-> 但 variables 恰好位于同一 cache line
-> 多个 CPU cores 仍可能反复争夺该 cache line 的 ownership
-> performance 下降
```

本周只观察趋势，不背 cache coherence protocol，不承诺每台机器都出现固定倍数差距。

---

## 4. MIT 6.S081 使用方式

### 4.1 本周不新增必读 lecture

总规划要求 Week7 穿插 locks / scheduling，并把 sleep/wakeup 与 C++ condition_variable 联系起来。

这部分已经在 Week5 完成：

```text
Week5 Day5：Lec10 10.1~10.5，locks / race / deadlock / performance
Week5 Day6：Lec09 9.2 + Lec11，thread / scheduler / context switch
Week5 Day7：Lec13 13.1~13.5，sleep / wakeup / lost wakeup / pipe
```

因此 Week7 不要求重新听一遍，也不要求重复抄课程笔记。

### 4.2 本周只做定向映射

遇到 C++ 组件问题时，按需连接旧知识：

```text
std::mutex critical section
<-> Lec10：lock 保护 shared invariant

condition_variable wait
<-> Lec13：检查 condition、sleep、wakeup、重新检查

blocked producer / consumer
<-> Lec11/Lec13：execution flow 不占 CPU，之后变为 runnable

join 等待 worker 结束
<-> scheduler 负责决定 worker 和 waiter 何时真正运行
```

必须保留边界：

```text
C++ condition_variable 的业务代码通常只有保护 predicate 的一把 mutex
不能把 xv6 sleep 实现中的内部 locks 机械翻译成“业务层必须写两把 mutex”
```

如果用户在某个机制上重新卡住，daily 只定向回看相关小节，不把 Week5 课程整段搬回来。

### 4.3 15-445

```text
本周不开。
```

BlockingQueue 和 ThreadPool 是当前 C++ 主线，不通过 15-445 增加数据库并发内容。

---

## 5. 七天总览

| Day | 核心问题 | 新增复杂度 | 主要产出 |
|---|---|---|---|
| Day1 | thread 执行完了，谁保证它被等待、结果还能安全读取？ | lifecycle + ownership | `parallel_sum.cpp` |
| Day2 | 一把 mutex 到底保护什么，而不是“把哪几行包起来”？ | shared invariant + lock scope | `shared_invariant.cpp` |
| Day3 | queue empty/full 时，producer 与 consumer 怎样等待正确条件？ | condition_variable + backpressure | `producer_consumer.cpp` |
| Day4 | 怎样把控制流封装成可复用 bounded queue？ | class invariant + MPMC | `blocking_queue.hpp`、`blocking_queue_test.cpp` V1 |
| Day5 | queue 不再接收 work 时，所有 blocked threads 怎样退出？ | close + drain + graceful shutdown | 升级同一份 BlockingQueue V2 |
| Day6 | 简单 counter 为什么可以不用 mutex，复杂 invariant 为什么不行？ | atomic + CAS | `atomic_counter.cpp`、`cas_max.cpp` |
| Day7 | 正确程序为什么仍可能因锁或 cache line 竞争变慢？ | measurement + integration | `contention_false_sharing.cpp`、`week7_note.md` |

Day4 与 Day5 是同一组件的连续版本，不重复新建两个内容几乎相同的 queue 项目。

---

# Day1：thread object 退出前，谁负责等待 execution flow

## 今日目标

```text
把“会创建 std::thread”升级为明确的 lifecycle ownership
区分 thread object、task、execution flow
掌握 joinable / join / detach 的状态变化
理解 callable 和 arguments 的 copy/move/reference 语义
安全汇总多个 workers 的独立 results
```

## 与 Week5 的区别

Week5 的 `thread_identity.cpp` 重点是：

```text
多个 threads 共享哪些 process resources
每个 thread 有哪些独立执行状态
```

Day1 不再打印 PID/TID 和地址。新增问题是：

```text
main 提前离开怎么办？
某个 thread 创建失败怎么办？
result 什么时候可以读取？
为什么不应该用 detach 逃避 join？
```

## 计划产出

独立实现 `parallel_sum.cpp`：

```text
输入一组 integers 和 worker count
按不重叠 ranges 分配工作
每个 worker 只写自己的 result slot
main join 所有成功创建的 workers
join 后汇总 partial results
与单线程 sum 对照
```

核心不是追求加速，而是验证：

```text
work range ownership 明确
result slot ownership 明确
main 不在 join 前读取尚未完成的 result
所有 joinable threads 都被处理
```

今天解释 `detach`，但项目产出不使用它。

---

# Day2：mutex 保护的是 shared invariant，不是一个变量名

## 今日目标

```text
区分 data race、race condition 与 nondeterministic order
从 shared state 写出 invariant
用一个明确 mutex 保护 invariant 的所有读写路径
比较 lock_guard 与 unique_lock 的职责
理解 critical section 太大或太小的后果
复习 deadlock，但不重复 Week5 的入门实验
```

## 计划产出

独立实现 `shared_invariant.cpp`，场景在 daily 中选择一个：

```text
bank ledger：多个 accounts 转账，总余额保持不变
或
inventory：items、count、total_value 必须保持一致
```

要求程序能检查一个跨多个 fields 的 invariant，而不是只看最后一个 counter。

至少比较：

```text
错误版：组合状态更新没有统一 synchronization contract
正确版：所有 invariant access 使用同一 mutex
```

错误版仅作为受控实验并用 TSan；不把 undefined behavior 程序当 benchmark。

今天可以介绍 `std::scoped_lock` 的用途，但多 mutex transfer 只作为可选增强，不把复杂 deadlock 调试设为核心阻塞项。

---

# Day3：queue empty 或 full 时，为什么不能只 notify

## 今日目标

```text
把 Week5 的 condition_variable 机制用于 producer-consumer
明确 queue、capacity、closed flag 由哪一把 mutex 保护
写出 not_empty 与 not_full 两个 predicates
理解 bounded queue 的 backpressure
区分 wait、notify_one 与 notify_all 的业务含义
```

## 今天的状态关系

```text
not_empty = !queue.empty()
not_full  = queue.size() < capacity
```

本日初版还不加入 `close`，只先看正常工作：

```text
producer 等待 not_full
-> push one element
-> 让 not_empty 可能成立
-> 通知 consumer

consumer 等待 not_empty
-> pop one element
-> 让 not_full 可能成立
-> 通知 producer
```

## 计划产出

独立实现 `producer_consumer.cpp`：

```text
固定 capacity
至少一个 producer 和一个 consumer
生产一组可验证的 integer IDs
每个 ID 正好消费一次
程序能够正常结束并 join
```

本日重点是写出 predicates 和状态转移，不追求封装成通用 template。

---

# Day4：把 producer-consumer 封装成 bounded BlockingQueue<T>

## 今日目标

```text
把 Day3 的共享变量和控制流收进一个 class
明确 queue ownership、capacity 和 synchronization ownership
支持多个 producers / consumers
定义 push/pop 的 blocking contract
保证 public methods 维持 class invariant
```

## 计划产出

```text
blocking_queue.hpp
blocking_queue_test.cpp
```

V1 核心范围：

```text
template<class T>
bounded capacity
blocking push
blocking pop
size/empty 若提供，必须说明它们只是瞬时 snapshot
禁止 copying queue object
支持普通 movable/copyable values
```

测试至少覆盖：

```text
capacity = 1
多个 producers
多个 consumers
总 produced count == total consumed count
每个 integer ID 正好出现一次
小容量制造真实 blocking
ThreadSanitizer 无 data race report
```

Day4 不加入 shutdown，以免一次同时解决两个最难问题。

由于没有 close，测试程序必须使用明确数量的 elements 或受控 termination tokens 结束。这个限制会在 Day5 被正式替换。

Daily 在用户实现前只提供 program purpose、接口 contract、状态图、测试和验收，不给完整 queue 实现。

---

# Day5：BlockingQueue 不再接收 work 时，blocked threads 怎样退出

## 今日目标

```text
理解 shutdown 是 queue lifecycle 的一部分
加入 OPEN / CLOSED_WITH_DATA / CLOSED_EMPTY 状态
定义 close 的幂等语义
让 blocked producers 与 consumers 都能退出
允许 close 前入队的数据被 drain
形成 Week8 ThreadPool 可复用的 graceful shutdown contract
```

## close 后的核心语义

```text
push：不再接受新 element，返回失败

pop：
    queue 仍有数据 -> 继续返回 element
    queue closed 且 empty -> 返回结束状态

close：
    修改 closed state
    唤醒所有可能永远等不到原 predicate 的 waiters
```

为什么通常需要 `notify_all`：

```text
close 不是只新增一个 element；
它改变的是“所有 waiters 是否还应该继续等待”的全局 lifecycle predicate。
```

## 计划产出

继续升级 Day4 的同一份：

```text
blocking_queue.hpp
blocking_queue_test.cpp
```

不要复制成 `blocking_queue_v2_copy.hpp` 制造重复源文件；使用 Git 记录演进。

核心测试：

```text
close empty queue，blocked consumer 能退出
close full queue，blocked producer 能退出
close with remaining elements，consumer 先 drain 再退出
多个 consumers 同时 blocked，close 后全部退出
重复 close 不破坏状态
close 后 push 明确失败
所有 workers 最终 join，程序不靠 sleep 猜时序
```

今天不写 ThreadPool。只要 queue 的 lifecycle 还解释不清，就不能把它藏到 pool 里面。

---

# Day6：atomic 能替代哪类 mutex，不能替代哪类 mutex

## 今日目标

```text
理解 atomic operation 的最小保证
使用 atomic counter
区分 load/store 与 read-modify-write
理解 compare_exchange 的 success/failure contract
手写一个小型 CAS loop
知道 atomic 不能自动维护复合 invariant
```

## 计划产出一：`atomic_counter.cpp`

比较：

```text
mutex-protected counter
std::atomic counter
```

正确性检查：

```text
多个 workers 各递增固定次数
最终结果必须精确等于 worker_count * iterations
```

这不是为了宣布 atomic 永远更快；Day7 才讨论 measurement。

## 计划产出二：`cas_max.cpp`

实现一个受控目标：

```text
多个 workers 提交 candidate value
shared atomic 保存目前见过的最大值
使用 compare_exchange loop 更新
最终结果与单线程 max 对照
```

必须能解释：

```text
expected 是输入，也是 compare_exchange failure 时的输出
CAS 失败表示 shared value 已变化
loop 必须基于新的 observed value 重新判断
```

本日所有代码保持默认 sequential consistency，不比较 relaxed/acquire/release。

---

# Day7：正确之后，再观察 contention 与 false sharing

## 今日目标

```text
区分 correctness test 与 performance experiment
观察 shared mutex contention
理解 thread count 增加不保证吞吐线性增加
建立 cache line 与 false sharing 第一层直觉
复检 BlockingQueue 的 lifecycle 和测试证据
完成 Week7 出口验收
```

## 计划产出

```text
contention_false_sharing.cpp
week7_note.md
```

实验至少比较：

```text
shared mutex counter
per-thread local counters，join 后汇总
相邻 per-thread atomic counters
做 padding/alignment 后的 per-thread counters
```

结果记录必须包含：

```text
CPU / VM 环境
compiler options
worker count
iteration count
多次运行结果
哪些是稳定趋势，哪些只是噪声
```

不要把一次运行的微秒差异写成普遍结论。

Day7 还要复检：

```text
BlockingQueue normal producer-consumer path
close while empty/full/with-data
all workers join
TSan result
核心验收问题
```

如果 false sharing 在当前 VM 中没有稳定差异，只要能解释原因、保留真实结果并说明实验限制，不阻塞 Week7 通过。

---

## 6. 本周建议目录

Windows 学习资料：

```text
C:\Users\FxorG\Desktop\gpt_infra\week7\
├── week7.md
├── day1\
│   ├── day1.md
│   └── day1_note.md
├── day2\
│   ├── day2.md
│   └── day2_note.md
...
└── day7\
    ├── day7.md
    └── day7_note.md
```

Ubuntu 代码：

```text
~/code/system-learning/cpp/week7/
├── day1/
│   └── parallel_sum.cpp
├── day2/
│   └── shared_invariant.cpp
├── day3/
│   └── producer_consumer.cpp
├── day4/
│   ├── blocking_queue.hpp
│   └── blocking_queue_test.cpp
├── day5/
│   ├── blocking_queue.hpp
│   └── blocking_queue_test.cpp
├── day6/
│   ├── atomic_counter.cpp
│   └── cas_max.cpp
└── day7/
    └── contention_false_sharing.cpp
```

Day4 到 Day5 是同一组件的演进。若实际开发希望保留一个目录，可以继续在 Day4 目录修改并用 Git 查看差异，不强制复制文件。

现在只生成 `week7.md`，不提前创建七份 daily 或空代码文件。

---

## 7. Daily 教程生成约定

Week7 每一份 `dayN.md` 继续固定三个 Part：

```text
Part 1：前情提要与必要术语
Part 2：教程主体
Part 3：收尾、练习、测试与验收
```

Part 2 开头必须明确标出：

```text
教程开始：从当天的具体 concurrency 问题出发
```

---

### 7.1 避免重复 Week5

Week7 daily 不应重新大篇幅解释：

```text
thread 是什么
context switch 是什么
scheduler 怎样选择 runnable thread
data race 最基础定义
lost wakeup 的 xv6 完整流程
condition_variable 为什么醒来后检查 predicate
```

这些作为一句前情提要连接即可。

新增讲解必须落到：

```text
C++ object state
ownership
class invariant
method contract
shutdown state transition
test evidence
```

---

### 7.2 术语与 API

首次出现的英文术语仍要说明：

```text
英文全称或词源
中文含义
当前组件里的具体作用
它不是什么
```

Week7 特别注意：

```text
joinable
critical section
invariant
predicate
producer / consumer
backpressure
graceful shutdown
atomic read-modify-write
compare-and-swap / compare_exchange
contention
cache line
false sharing
```

每个非简单 API 至少包含：

```text
header
signature
parameters
return value
它改变的 object state
一个独立最小例子
```

API 例子只证明该 API 怎样使用，不能拼起来直接变成当天练习答案。

---

### 7.3 完整流程与明确主体

并发讲解不能只写：

```text
线程被唤醒
队列关闭了
获得锁后继续
```

必须主动说明：

```text
哪个 producer / consumer 当前运行
它持有哪一把 mutex
它检查哪个 predicate
它修改哪些 queue fields
谁调用 notify
waiter 醒来后为什么还不能假设条件成立
close 改变了哪个 lifecycle state
哪个 thread 最终负责 join workers
```

复杂路径优先使用 Mermaid flowchart。例如 BlockingQueue close 应至少串一次：

```text
consumer waits for not_empty-or-closed
-> owner calls close under mutex
-> closed becomes true
-> notify_all
-> consumer reacquires mutex
-> queue empty and closed
-> pop returns end-of-stream state
-> worker exits
-> owner joins worker
-> queue can be destroyed
```

流程图负责顺序和分支，正文仍要解释每个状态属于谁。

---

### 7.4 练习必须保留独立实现空间

Week7 是组件练习周。daily 在用户编码前只给：

```text
程序解决什么问题
输入、输出与生命周期
public interface contract
shared state 与 invariant
允许使用的标准库 API
关键错误路径
测试矩阵
验收标准
```

不能提前提供：

```text
完整 BlockingQueue implementation
可以直接拼成答案的 push/pop/close 控制流
完整 CAS loop 答案
完整多线程测试 harness
```

必要的参考实现拆解放到用户独立完成之后的 review，不回写已经冻结的 daily。

---

### 7.5 每个 `.cpp` 先讲用途，再列 contract

在列大量接口要求前，daily 必须先写清：

```text
这个程序整体实现什么
输入从哪里来
输出和成功标准是什么
有哪些 threads，各自负责什么
程序怎样正常结束
本日明确不实现什么
```

避免用户只看到十几条 contract，却不知道整个程序要解决什么问题。

---

## 8. 编译、工具与验证要求

### 8.1 默认正确性编译

本周所有使用 `std::thread` 的 C++ 默认：

```bash
g++ -std=c++17 -Wall -Wextra -g -pthread source.cpp -o program
```

`-pthread` 同时影响 thread support 所需的编译和链接设置。

### 8.2 ThreadSanitizer

正确版本至少运行一次：

```bash
g++ -std=c++17 -Wall -Wextra -g -O1 -pthread \
  -fsanitize=thread \
  -fno-omit-frame-pointer \
  source.cpp -o program_tsan

./program_tsan
```

解释边界：

```text
TSan 没报告 data race
!=
证明没有 deadlock、lost task、duplicate consume 或 shutdown bug
```

所以还需要 invariant 和 lifecycle tests。

### 8.3 性能观察单独编译

Day7 benchmark 可另外使用：

```bash
g++ -std=c++17 -Wall -Wextra -g -O2 -DNDEBUG -pthread \
  contention_false_sharing.cpp -o contention_false_sharing
```

不能把 debug/TSan timing 与 optimized timing 混在一张表里直接比较。

### 8.4 Linux 观察工具

核心：

```text
ps -L -p <pid>
/proc/<pid>/task
nproc
lscpu
/usr/bin/time
```

可选：

```text
perf stat
taskset
```

`perf` 或 CPU affinity 只用于减少 benchmark 噪声，不作为 Week7 核心要求。工具缺失时不为安装工具中断主线。

---

## 9. 本周测试纪律

并发程序“运行一次没卡住”不算通过。

每个核心组件至少提供：

```text
normal path
boundary state
shutdown path
repeated stress run
可计算的最终 invariant
all threads joined
TSan run
```

不要依赖：

```text
sleep 固定几秒来保证某个 thread 先运行
cout 输出顺序判断同步正确
一次运行的结果
程序没崩溃就认为没有 race
```

允许使用短暂 sleep 扩大观察窗口，但必须明确：

```text
sleep 只用于观察或增加交错概率
正确性仍由 mutex/predicate/state contract 保证
```

日志输出如果由多个 threads 共享，需单独同步，避免测试日志本身产生混乱；同时不要在 queue mutex 的 critical section 内做大量输出。

---

## 10. 本周核心验收问题

1. `std::thread` object 与 OS execution flow 的生命周期怎样关联？
2. 为什么 joinable thread object 析构不能悄悄让 worker 继续运行？
3. 什么情况下使用 `std::ref`？它改变的是 argument 的什么语义？
4. mutex 保护 shared invariant 是什么意思？请用本周代码举例。
5. `lock_guard` 与 `unique_lock` 在本周分别用在哪里？
6. bounded queue 为什么需要 `not_empty` 和 `not_full` 两个 predicates？
7. consumer 从 `wait` 返回后，为什么仍必须在同一 mutex 下重新判断 queue state？
8. `notify_one` 本身为什么不保存一条 element 或一个业务事件？
9. BlockingQueue 的 `close` 应怎样影响 blocked producer？
10. BlockingQueue closed 但仍有 elements 时，consumer 应该直接退出还是继续 drain？为什么？
11. 为什么 `close` 通常需要唤醒所有 waiters？
12. queue object 析构前，owner 必须先完成哪些 thread lifecycle 动作？
13. `fetch_add` 和普通的 load-add-store 有什么区别？
14. compare_exchange 失败后，`expected` 发生什么变化？
15. 为什么两个 atomic variables 不能自动组成一个原子 invariant？
16. false sharing 与 data race 有什么区别？
17. 为什么 threads 更多不一定更快？
18. TSan、stress test 和 invariant check 分别能证明什么、不能证明什么？

---

## 11. Week7 最终完成标准

### 11.1 核心通过

以下项目全部达到，Week7 即可通过：

```text
能解释 std::thread lifecycle、joinable、join 与 detach
所有练习程序在退出前处理全部 joinable workers
能区分 data race、race condition 和不确定执行顺序
能说明 mutex 保护的 shared state 与 invariant
能正确使用 lock_guard 和 condition_variable + unique_lock
能画出 producer wait / producer push / consumer wake 的完整流程
独立实现 bounded BlockingQueue<T>
BlockingQueue 支持多 producer / 多 consumer
BlockingQueue close、drain 和退出语义明确
empty/full/close 等核心测试通过，无永久阻塞
能使用 atomic counter 和解释 CAS loop
知道 atomic 不能替代复合状态的 mutex
能解释 contention 与 false sharing 第一层机制
规定编译选项零 warning
正确版本通过 TSan 基本检查
```

### 11.2 工程增强，不阻塞 Week7

```text
move-only T 支持
timed push/pop
try_push/try_pop
exception safety 强保证
精确 benchmark statistics
perf hardware counters
CPU affinity
cache-line padding 的跨平台封装
```

### 11.3 Week7 不通过的真正原因

```text
仍用 sleep 和输出顺序代替 synchronization
不能说清 mutex 保护哪些 state
condition_variable predicate 不在同一 mutex 下修改和检查
push/pop 在错误时机读写 queue，存在 data race
close 后仍有 blocked thread 永久等待
queue 析构时仍有 workers 访问它
把 atomic 当成所有并发问题的通用替代品
BlockingQueue 只有 happy path，没有 empty/full/close 测试
只说“跑通了”，没有 invariant、重复测试或 TSan 证据
```

不会因为以下原因阻塞：

```text
没有实现 lock-free queue
没有学习复杂 memory ordering
没有精确解释 CPU cache coherence protocol
false sharing benchmark 没出现固定倍数差距
没有使用 perf
没有提前写 ThreadPool
```

---

## 12. 与 Week8 的连接

Week7 最终得到：

```text
worker lifecycle discipline
shared invariant + mutex
condition_variable wait/notify
bounded BlockingQueue
close + graceful shutdown
atomic/CAS 第一层
contention measurement 第一层
```

Week8 在此基础上增加：

```text
task abstraction
worker loop
ThreadPool V1
future / packaged_task 初步
AsyncLogger V1
test / benchmark 工程化
```

ThreadPool 的核心关系将是：

```text
submitter
-> push task into BlockingQueue
-> worker pop task
-> execute task
-> shutdown closes queue
-> workers observe closed-and-empty
-> workers exit
-> ThreadPool joins workers
```

所以 Week7 的出口不是“会背几个并发 API”，而是：

```text
我能设计一个有明确 ownership、predicate、backpressure 和 shutdown contract 的并发组件，
并能用测试证明它在多个 execution flows 下不会只靠运气工作。
```
