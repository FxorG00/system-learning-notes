# Week7 Day7：代码没有 data race，为什么增加 threads 仍可能更慢

> 今日主线：correctness vs performance、contention、cache line、false sharing、可重复 measurement、Week7 integration。
>
> 今日类型：硬件直觉 + 性能观察 + 组件复检，不新写大型组件。
>
> 今日产出：`contention_false_sharing.cpp` 与 `day7_note.md`。
>
> 正确性编译：`g++ -std=c++17 -Wall -Wextra -g -pthread`。
>
> 性能观察编译：在保留 warnings 的前提下单独使用 `-O2`。

学习前置：Week7 Day6 已验收。提前生成不代表前六天已经完成。

今天不新增 MIT 6.S081 lecture，不深入 MESI、memory ordering 或 lock-free algorithm。

今天从一个反直觉现象出发：

```text
程序没有 data race
结果也完全正确
但从 1 thread 增加到 2/4/8 threads，elapsed time 反而变长
```

今天要建立的是测量和第一层硬件模型，不是背一个“多线程一定更快/更慢”的答案。

---

# Part 1：前情提要与必要术语

## 1. 从 Day1 和 Day6 的两个 counter 接过来

Day1：

```text
per-thread local result
-> join 后汇总
-> 尽量避免 shared writes
```

Day6：

```text
shared atomic counter
-> 每次 increment race-free
```

两者都可以正确，但 performance path 不同：

```text
shared mutex counter -> threads 竞争同一 mutex
shared atomic counter -> threads 竞争同一 cache line 上的 atomic value
per-thread local      -> 共享写更少，最后汇总
```

今天通过真实 measurement 比较，不靠想象直接宣布 winner。

---

## 2. 必要术语

### 2.1 benchmark

`benchmark`：基准测试。

它在明确环境、input 和 build options 下测量某个 workload。

benchmark 不是一次 `cout << duration` 就得到普遍结论。

---

### 2.2 elapsed time

`elapsed time`：经过时间，也常叫 wall-clock time。

从测量起点到终点实际过去多久。

今天使用 `std::chrono::steady_clock`，因为它是 monotonic clock，适合测 duration。

---

### 2.3 throughput

`throughput`：吞吐量。

```text
单位时间完成多少 operations
```

例如：

```text
increments per second
```

不要把 latency 与 throughput 混为一个指标。

---

### 2.4 contention

`contention`：竞争。

多个 threads 同时争用同一个 synchronization resource 或硬件资源。

例如：

```text
同一 mutex
同一 atomic counter
同一 cache line
同一 memory bandwidth
```

---

### 2.5 CPU core

`core`：处理器核心。

多个 threads 只有在获得不同 execution resources 时才可能真正并行；threads 数超过可用 cores 后，还会增加 scheduling 和 context switching 开销。

VM 中看到的 virtual CPUs 也受宿主机调度影响。

---

### 2.6 cache

`cache`：缓存。

CPU 使用比 main memory 更小、更快的 cache 保存近期访问的数据。

现代多核 CPU 通常有每 core 私有的部分 cache，也可能有共享的 last-level cache；具体结构依 CPU 而异。

---

### 2.7 cache line

`cache line`：缓存行。

CPU cache 与 memory 交换和维护一致性的基本块通常不是一个 C++ variable，而是一整块连续 bytes。

很多 x86-64 CPU 的 line size 是 64 bytes，但不能把 64 当语言标准保证。

Linux 可观察：

```bash
cat /sys/devices/system/cpu/cpu0/cache/index0/coherency_line_size
```

---

### 2.8 cache coherence

`coherence`：一致性。

多个 cores 各自缓存同一 memory line 时，hardware protocol 需要协调 writes，让不同 cores 对 line 的修改具有一致的可观察结果。

今天不背 MESI states，只记：

```text
一个 core 反复写某条 line
-> 其他 core 对同一 line 的缓存副本可能需要失效/重新取得
```

---

### 2.9 false sharing

`false sharing`：伪共享。

```text
Thread A 只写 variable A
Thread B 只写 variable B
A 和 B 是不同 memory locations，没有 data race
但 A/B 位于同一 cache line
-> cores 仍围绕整条 line 发生 coherence traffic
-> performance 可能下降
```

“false” 指 variables 在业务上没有真正共享同一 value，却因为 line granularity 产生类似共享争用。

---

### 2.10 alignment / padding

`alignment`：对齐。

`padding`：填充。

通过让热点 counters 分布到不同 cache lines，可以减少 false sharing；代价是使用更多 space。

今天使用 `alignas(...)` 建立实验，不把它当所有 struct 的默认优化。

---

### 2.11 measurement noise

`noise`：测量噪声。

来源包括：

```text
OS scheduling
VM host load
CPU frequency scaling
thread migration
background processes
cache warm/cold state
thermal throttling
```

所以需要多次运行、记录分布和环境。

---

# Part 2：教程主体

# 教程开始

## 3. correctness 与 performance 必须分开验证

正确性问题：

```text
final result 是否正确
是否 data race
是否 deadlock
是否 lost/duplicate work
是否 graceful shutdown
```

性能问题：

```text
elapsed time
throughput
scaling with thread count
contention
cache locality
```

不能用性能结果证明 correctness：

```text
racy counter 更快
```

可能只是它丢了大量 increments，实际完成的 work 更少。

也不能用 TSan timing 比较生产性能；instrumentation 会显著改变 execution。

---

## 4. shared mutex counter 的竞争链

多个 workers 每次 increment 都：

```text
lock mutex
increment
unlock mutex
```

如果 critical section 只有一个 increment：

```text
有用工作很少
同步开销相对很大
所有 workers 在同一个 serial point 排队
```

增加 threads 后，可能增加：

```text
mutex waiting
scheduler activity
cache line transfer
```

但没有增加能够并行执行的 shared increment。

这就是 contention 的一种。

---

## 5. shared atomic counter 为什么也可能竞争

atomic increment 不需要你显式写 mutex，并保证每次 RMW 正确。

但所有 cores 仍反复修改同一个 atomic object 所在 cache line：

```text
Core A wants write ownership
-> increments
Core B wants write ownership
-> line ownership/coherence state changes
-> increments
-> repeat
```

所以：

```text
lock-free or atomic
!=
contention-free
```

正确性 abstraction 与 hardware traffic 是两个层次。

---

## 6. per-thread local 为什么常更容易扩展

每个 worker 使用自己的 local counter：

```text
worker i increments local_i
```

worker 完成后：

```text
main join
-> sum all local counters once
```

共享 synchronization 从“每次 increment”降低到“最终汇总”。

这与 Day1 `parallel_sum` 是同一个设计原则：

```text
先 partition ownership
-> 批量做 local work
-> 在明确 synchronization point 合并
```

---

## 7. false sharing 的具体场景

假设 memory layout：

```text
one cache line
┌──────────┬──────────┬──────────────────────────┐
│ counter0 │ counter1 │ remaining bytes          │
└──────────┴──────────┴──────────────────────────┘
```

Thread 0 只修改 `counter0`，Thread 1 只修改 `counter1`。

C++ memory model 角度：

```text
不同 objects
-> 可以没有 data race
```

hardware cache 角度：

```text
同一 cache line
-> coherence 以整条 line 协调
-> 两个 cores 的 writes 仍相互影响
```

本地《图解系统》的示意图展示了这种 line-level 影响：

![两个核心修改同一 Cache Line 中不同变量形成 false sharing](./images/false_sharing_xiaolin.png)

图是第一层直觉，不要求背具体 coherence state 或固定 write-back 顺序；不同 CPU implementation 的协议细节可能不同。

---

## 8. `alignas` 怎样建立对照实验

C++ `alignas` 指定 object/type alignment requirement。

受控实验可以定义：

```cpp
struct alignas(64) PaddedCounter {
    std::atomic<std::uint64_t> value{0};
};
```

目的：

```text
让相邻 PaddedCounter objects 的起点至少按 64-byte alignment 排列
增加 counters 位于不同 lines 的可能性
```

重要边界：

```text
64 是实验平台常见 line size，不是跨平台永久常量
alignment 增加不代表任何 workload 都更快
padding 会占用更多 cache/memory space
```

先用 sysfs 命令观察当前 line size，再在 note 中写明假设。

C++17 标准库还定义了 `<new>` 中的 `std::hardware_destructive_interference_size`：一个 `std::size_t` compile-time constant，表示为减少 destructive interference 而推荐的最小间隔。它不是读取当前 CPU cache line 的运行时探针，而且会影响 type layout/ABI。

标准库实现支持时可以写：

```cpp
#include <atomic>
#include <cstddef>
#include <cstdint>
#include <new>

#if defined(__cpp_lib_hardware_interference_size)
constexpr std::size_t kDestructiveSize =
    std::hardware_destructive_interference_size;
#else
constexpr std::size_t kDestructiveSize = 64;
#endif

struct alignas(kDestructiveSize) PaddedCounter {
    std::atomic<std::uint64_t> value{0};
};
```

当前 Ubuntu 使用 GCC 10.5，其 libstdc++ 很可能尚未提供这个后来才在 GCC 12 实现的常量。因此本周核心实验继续使用“sysfs 观察值 + `alignas(64)` + 地址打印”，不要为了使用一个名字更标准的常量升级工具链或中断主线。上面的 conditional snippet 只是说明 C++17 标准接口与 implementation availability 的区别，不是新增验收任务。

---

## 9. 为什么 adjacent atomics 是有意设计的实验

实验组：

```text
多个 atomic counters 紧邻存放
每个 worker 只 increment 自己的 counter
```

这样：

```text
没有多个 workers 修改同一个 atomic object
final result 可验证
每次 atomic RMW 不容易被 compiler 合并掉
相邻 objects 仍可能共享 line
```

对照组：

```text
每个 counter 使用 padding/alignment 分离
```

两组算法应完成相同数量 operations；只改变 memory layout 才更接近 false-sharing 对照。

---

## 10. 为什么不能只运行一次

一次结果：

```text
adjacent = 120 ms
padded   = 80 ms
```

不能直接宣布“padding 快 50%”。

至少需要：

```text
固定 input/workload
相同 compiler options
相同 worker count
多次运行
忽略或单独记录 warm-up/outlier
报告 median 或结果范围
```

VM 中 fluctuation 可能很大。真实结论可以是：

```text
当前环境没有观察到稳定差异
```

只要实验设计和限制解释正确，这比编造漂亮数字更有价值。

---

## 11. API：`std::chrono::steady_clock`

头文件：

```cpp
#include <chrono>
```

测量形状：

```cpp
const auto begin = std::chrono::steady_clock::now();

// Run the workload.

const auto end = std::chrono::steady_clock::now();
const auto elapsed =
    std::chrono::duration_cast<std::chrono::microseconds>(end - begin);
```

`steady_clock` 不会因 wall-clock 被手工调整而倒退，适合 duration measurement。

测量区间不要包含：

```text
大量 cout
随机数据生成（除非它本身是 workload）
文件 I/O
不同 variant 不一致的 setup
```

线程创建开销如果所有 variants 都包含，可以保留并明确说明；若只想测循环，应设计统一 start gate。Day7 不强制实现复杂 benchmark framework。

---

## 12. correctness build、TSan build、benchmark build 分开

### Correctness

```bash
g++ -std=c++17 -Wall -Wextra -g -pthread \
  contention_false_sharing.cpp -o contention_false_sharing
```

### TSan

```bash
g++ -std=c++17 -Wall -Wextra -g -O1 -pthread \
  -fsanitize=thread -fno-omit-frame-pointer \
  contention_false_sharing.cpp -o contention_false_sharing_tsan
```

只用它查 race，不记录 timing 排名。

运行时仍按 Day3 的 report 阅读顺序：

```bash
TSAN_OPTIONS="halt_on_error=1" ./contention_false_sharing_tsan
echo $?
```

Day7 要特别区分三种结果：

```text
TSan reports data race
    correctness 失败；先修 shared memory access，不讨论性能排名。

TSan clean，但 expected != actual
    可能是 logical race、work partition、overflow 或测试错误；TSan 不替代结果检查。

TSan clean，expected == actual，但运行较慢
    才进入 contention / false sharing / measurement 分析。
```

false sharing 本身通常不会产生 TSan report：不同 threads 可以合法修改不同 objects，只是这些 objects 恰好落在同一 cache line，引发 coherence traffic。它是 performance 问题，不是 C++ data race。

因此 Day7 的顺序必须是：

```text
correctness build 检查结果
-> TSan build 检查执行到的 memory races
-> optimized benchmark 多轮测量 timing
-> 地址/layout 与可选硬件工具支持性能解释
```

若把 TSan timing 拿去比较 shared mutex、atomic 和 local variants，结论无效。TSan 会插入大量 bookkeeping，官方文档也明确说明它会带来显著运行时间与内存开销；该 binary 的职责只是找 race。

### Optimized benchmark

```bash
g++ -std=c++17 -Wall -Wextra -g -O2 -DNDEBUG -pthread \
  contention_false_sharing.cpp -o contention_false_sharing_bench
```

三个 binaries 的目的不同，结果不能混用。

---

## 13. thread count 怎样选择

至少测试：

```text
1
2
4
当前环境允许时的 8
```

观察：

```bash
nproc
lscpu
```

`std::thread::hardware_concurrency()` 也可提供 hint：

```cpp
const unsigned int hint = std::thread::hardware_concurrency();
```

返回 0 表示 implementation 无法提供；非 0 也只是 hint，不是“最佳 worker count”。

---

## 14. thread migration 与 affinity

scheduler 可能让同一 thread 在不同 CPU cores 上运行。migration 会改变 cache locality 和 measurement noise。

`taskset` 可以作为可选观察：

```bash
taskset -c 0-3 ./contention_false_sharing_bench
```

但 Day7 不要求 affinity tuning，也不能因为 pinning 后某次更快就立刻推广。

---

## 15. Week7 的完整工程链

```mermaid
flowchart TD
    A["owner creates worker thread objects"] --> B["workers call BlockingQueue push/pop"]
    B --> C["mutex protects queue lifecycle invariant"]
    C --> D["condition variables block on not_empty/not_full/closed"]
    D --> E["owner stops submitting and calls close"]
    E --> F["waiters wake, consumers drain, workers exit"]
    F --> G["owner joins all workers"]
    G --> H["queue and synchronization objects safely destruct"]
    H --> I["atomic counters may record simple independent statistics"]
    I --> J["benchmark observes contention and cache effects"]
```

Week7 的核心不是“mutex、cv、atomic 三种写法”，而是知道它们各自在这条链中解决什么问题。

---

### 15.1 从 core 到 memory 的数据路径

先建立简化硬件图。真实 CPU 可能有更多层级与共享方式，今天只抓机制：

```mermaid
flowchart TD
    A["Core 0"] --> B["private L1/L2 cache"]
    C["Core 1"] --> D["private L1/L2 cache"]
    B --> E["shared last-level cache"]
    D --> E
    E --> F["main memory"]
```

core 执行 load/store 时，通常希望在更近、更快的 cache 中访问数据。memory system 不是每次都直接去 RAM 读一个孤立 byte，而会以 cache line 为基本传输与 coherence 单位。

今天常用 `64 bytes` 作为实验假设，但它不是 C++ 标准保证。可以在实验报告中写：

```text
本机预期 cache line size = 64 bytes
通过 sysfs/lscpu 等观察环境
alignas(64) 用于建立本机对照
```

不要把 `alignas(64)` 说成“所有机器上都彻底消除 false sharing”的跨平台证明。

---

### 15.2 false sharing 的 ownership ping-pong 全流程

假设两个 atomics 紧邻：

```text
cache line L: [counter_A][counter_B][other bytes ...]
Core 0 repeatedly writes counter_A
Core 1 repeatedly writes counter_B
```

虽然程序层面两个 threads 没有写同一个 C++ object，但 coherence 以 line L 为单位。一个简化过程是：

```text
1. Core 0 获得 line L 的可写 ownership
2. Core 0 更新 counter_A
3. Core 1 想更新 counter_B，也需要 line L 的可写 ownership
4. coherence protocol 让 Core 0 的对应 line copy 失去可写状态
5. Core 1 获得 line L，更新 counter_B
6. Core 0 下一次更新 counter_A，又要把 line L 拿回来
7. 两个 cores 反复转移同一 line 的 ownership
```

真正来回移动的是 cache-line coherence ownership，不是两个 source-level variables 互相覆盖。结果仍然可以完全正确，但大量 coherence traffic 降低 throughput。

把两个 counters 分到不同 lines 后：

```text
Core 0 mostly owns line A
Core 1 mostly owns line B
```

它们就不再因为写不同 counters 而不断争夺同一 line。这就是 padded layout 可能更快的因果链。

---

### 15.3 true sharing、false sharing 与 no sharing

| Situation | Source-level object | Cache-line relation | Correctness tool | Main performance issue |
|---|---|---|---|---|
| true sharing | threads 操作同一个 counter | same line | atomic/mutex | serialization + coherence |
| false sharing | threads 操作不同 counters | accidentally same line | 已可 race-free | coherence ping-pong |
| no sharing/local | each thread owns its own counter | preferably separate lines or registers | join 后汇总 | final reduction cost |

`false` 的意思不是“性能问题是假的”，而是 source code 看起来没有共享同一个 variable，hardware 却因为同一 cache line 产生了共享效果。

另一个边界：两个 read-only variables 在同一 cache line 通常不构成 false sharing，因为没有 cores 反复争夺 write ownership。核心触发条件是不同 cores 对同一 line 的并发写，或读写导致的 coherence invalidation。

---

### 15.4 怎样确认实验对象真的相邻或被分开

不能只写 class 名字叫 `PaddedCounter` 就宣称布局成立。实验可以打印：

```text
sizeof(counter type)
alignof(counter type)
address of counters[i]
address % assumed_cache_line_size
相邻 addresses 的差值
```

独立观察例子：

```cpp
const auto address = reinterpret_cast<std::uintptr_t>(&counters[i]);
std::cout << "address=" << address
          << " line_offset=" << address % 64 << '\n';
```

需要头文件：

```cpp
#include <cstdint>
```

`reinterpret_cast<std::uintptr_t>` 在这里用于把 object address 转成足以保存 pointer 数值表示的 unsigned integer，方便做打印与 `% 64` 观察；它不是在访问该地址对应的数据，也不是把 virtual address 手工翻译成 physical address。

对于：

```cpp
struct alignas(64) PaddedCounter {
    std::atomic<long long> value{0};
};
```

`alignas(64)` 要求每个 object 的起始地址满足至少 64-byte alignment。array 中每个 element 还要满足其类型 alignment，所以 `sizeof(PaddedCounter)` 通常也会包含必要 padding。最终仍以本机打印和 measurement 为证据。

---

### 15.5 benchmark 怎样减少“刚好这次”的影响

最低限度的方法：

```text
1. correctness build 先验证 result
2. optimized build 才计时
3. 每个 variant 运行多轮
4. 不只报告最快一次
5. 记录 input size、thread count、build flags 和 VM 环境
```

可以使用 median：把多轮 elapsed times 排序，取中间值。median 比单次结果更不容易被一次偶发调度延迟拖走。

还要防止固定测试顺序偏向某个 variant。若永远：

```text
mutex -> atomic -> local -> adjacent -> padded
```

后面的 case 可能受 CPU frequency、cache warm-up 或系统负载变化影响。至少做两件事之一：

```text
轮换/随机化 variant 顺序
整组重复多次并报告分布
```

warm-up 可以先运行一次不计入结果，让 dynamic linking、page faults 与初次 allocation 的影响不全压在第一组上。但 warm-up 不能消除 scheduler、VM steal time 或 frequency scaling。

---

### 15.6 防止 benchmark 测到被优化掉的工作

若计算结果从未被观察，optimized compiler 可能删除部分甚至全部 work。每个 variant 都应产生一个可验证 result，例如：

```text
expected total = thread_count * increments_per_thread
measured result == expected total
```

把 result 打印或传给一个不会被优化消失的验证步骤。不要把每次 increment 都打印；I/O 会完全淹没你要测的 synchronization cost。

计时边界也要一致：

```text
start
-> create/start workers
-> perform increments
-> join workers
stop
```

或者事先创建 threads，只测 operation body。两种都可以，但不能一个 variant 包含 thread creation，另一个不包含。Day7 建议所有 variants 统一包含 create + join，因为代码更容易保持公平并解释。

---

### 15.7 `steady_clock` 的最小计时框架

接口所在头文件：

```cpp
#include <chrono>
```

独立最小例子：

```cpp
const auto start = std::chrono::steady_clock::now();

run_work();

const auto stop = std::chrono::steady_clock::now();
const auto elapsed =
    std::chrono::duration_cast<std::chrono::microseconds>(stop - start);

std::cout << elapsed.count() << " us\n";
```

`steady_clock` 的关键性质是 monotonic：它用于测 duration，不会因为 wall clock 被人工调整而倒退。`duration_cast` 把 clock 的原生 duration 转换成你要报告的 unit。

若一次 work 只有几微秒，measurement overhead 与 noise 可能占比很大。应增加每轮 iterations，使单轮持续时间足够长，而不是迷信纳秒单位会自动提高可信度。

---

### 15.8 结果能支持多强的结论

假设在当前 VM 上得到：

```text
4 threads, 10 million increments each
adjacent atomics median: 420 ms
padded atomics median:   190 ms
```

可写：

```text
在本机、当前 build flags、thread count 与 workload 下，
padded layout consistently outperformed adjacent layout；
地址观察与 cache-line coherence 机制支持 false sharing 是主要解释。
```

不要直接写：

```text
padding 永远快 2.2 倍
atomic 一定比 mutex 快
我的 CPU cache line 在所有环境都必然是 64 bytes
```

若两组接近，也不等于 false sharing 不存在。可能原因包括：

```text
threads 没有长期运行在不同 physical cores
VM scheduling noise 较大
workload 太短
objects 实际布局与假设不同
CPU/coherence implementation 差异
```

先报告观察，再给机制解释，最后标出 evidence boundary。这是 AI Infra 做 performance engineering 时比“背结论”更重要的习惯。

---

# Part 3：收尾、练习、测试与验收

## 16. 今日产出：`contention_false_sharing.cpp`

### 16.1 程序是干什么的

实现一个小型 benchmark harness，在相同 total increments 下比较：

```text
Variant A：shared mutex-protected counter
Variant B：per-thread local counters，join 后汇总
Variant C：adjacent per-thread atomic counters
Variant D：padded/aligned per-thread atomic counters
```

输入：

```text
worker count
iterations per worker
repeat count
```

输出：

```text
variant name
final total / expected total
每次 elapsed time
简单 median 或范围
PASS / FAIL
```

正常结束：

```text
每个 variant 创建 workers
workers 完成相同数量 operations
main join
验证 total
记录 duration
进入下一次 repeat
```

不实现：

```text
专业 benchmark framework
CPU performance counter parser
MESI simulator
lock-free queue
```

---

### 16.2 公平比较要求

```text
相同 worker count
相同 iterations per worker
相同 expected total
相同 build binary/configuration
measurement interval 尽量一致
measurement 内不大量输出
每个 variant 多次运行
```

Variant B 最终汇总的少量 additions 与其他 variant 的每次 shared synchronization 不同，这正是 algorithm design 差异；报告中应明确，而不是称为纯粹 mutex-vs-atomic 微基准。

Variant C/D 才是更接近 false-sharing 的 memory-layout 对照。

---

## 17. fixed tests

### Correctness

```text
workers=1, iterations=0
workers=1, iterations=100000
workers=2, iterations=1000000
workers=4, iterations=1000000
```

每个 variant：

```text
final total == workers * iterations
all workers joined
```

### Measurement

```text
至少 5 次 repeats
记录当前 CPU/VM 信息
记录 cache line size
记录 compiler command
```

如果 total 可能溢出，使用 `std::uint64_t` 并提前验证 multiplication 边界。

---

## 18. BlockingQueue 最终复检

Day7 不重写 queue，但 Week7 出口前重新运行 Day5 tests：

```text
normal MPMC
capacity=1
close empty
close full
close with remaining data
multiple blocked consumers
repeated close
push after close
100 次压力运行
TSan
```

复检只运行和记录证据，不复制新的 queue source。

---

## 19. 性能结果应该怎样写

推荐表格：

```text
Environment:
    VM / CPU hint:
    nproc:
    cache line size:
    compiler:
    build flags:

Workload:
    workers:
    iterations per worker:
    repeats:

Results:
    shared mutex:
    per-thread local:
    adjacent atomics:
    padded atomics:

Interpretation:
    stable trend:
    noise/outliers:
    what this experiment cannot prove:
```

不要写：

```text
atomic 一定比 mutex 快
padding 一定提升 X%
threads 越多越快
```

除非你的数据和适用范围真的支持，并且仍应限定到当前 workload/environment。

---

## 20. 可选工具，不阻塞 Day7

```bash
/usr/bin/time -v ./contention_false_sharing_bench
perf stat ./contention_false_sharing_bench
taskset -c 0-3 ./contention_false_sharing_bench
```

工具目的：

```text
time -> wall time、CPU time、context switches 等概览
perf stat -> 可选 hardware/software counters
taskset -> 限制 CPU set，减少部分调度变化
```

环境没有 `perf` 或权限不足时，不安装、不折腾，保留 `chrono` results 即可。

证据边界要再收紧一层：普通 `perf stat` 可以展示 cycles、cache misses、context switches 等汇总，但通常不能单独指出“正是这两个 fields 共享某条 cache line”。在受支持的 bare-metal Linux 上，`perf c2c` 可以进一步定位发生 cache-to-cache contention 的 lines；Intel VTune 的 Memory Access/False Sharing analysis 也能提供更强证据。它们都只作为未来性能分析工具入口，不是 Week7 安装任务，VM 中不可用也不影响通过。

本节资料核对入口：

```text
Linux kernel documentation: False Sharing
Intel VTune Profiler Cookbook: False Sharing
WG21 P1119R0: hardware destructive/constructive interference size 的 ABI 边界
```

---

## 21. Week7 核心验收问题

1. thread object、execution flow 和 task 的职责区别是什么？
2. 为什么所有 joinable workers 必须在 owner 退出前处理？
3. mutex 保护 shared invariant 是什么意思？
4. bounded queue 的 `not_empty/not_full` 分别由谁等待、由谁改变？
5. `close()` 为什么改变 producer 和 consumer 两边的 wait predicate？
6. closed with data 与 closed empty 的 `pop()` 结果为什么不同？
7. 为什么 queue owner 必须执行 close -> drain/worker exit -> join -> destroy？
8. atomic RMW 与 atomic load+store 的区别是什么？
9. CAS failure 为什么会修改 expected？
10. atomic 为什么不能自动维护 BlockingQueue 的复合 invariant？
11. false sharing 为什么可以没有 data race，却降低 performance？
12. shared mutex、shared atomic、per-thread local 三种 counter 的 contention path 分别是什么？
13. 为什么 TSan build 的 timing 不能作为 benchmark 结果？
14. 为什么一次运行不能证明 padding 的普遍收益？

---

## 22. Week7 完成标准

核心通过：

```text
parallel_sum 正确划分 work/result ownership
shared_invariant 能解释并维护复合 invariant
producer-consumer 正确使用 not_empty/not_full
独立实现 bounded BlockingQueue<T>
BlockingQueue close/drain/shutdown tests 通过
all threads join before dependent objects destruct
atomic counter 和 cas_max 与 trusted result 一致
能解释 atomic 与 mutex 的适用边界
能完成 contention/false-sharing observation 并诚实描述噪声
核心正确版本 warning clean，TSan 基本检查通过
```

不因以下内容阻塞：

```text
没有 lock-free queue
没有 acquire/release
没有 perf
false sharing 差异不稳定
没有提前写 ThreadPool
```

---

## 23. 推荐的 `day7_note.md` 结构

```markdown
# Week7 Day7 Note

## 1. correctness 与 performance 的证据区别

## 2. mutex / atomic / per-thread local 的 contention path

## 3. cache line 与 false sharing

## 4. benchmark environment 与方法

## 5. 真实结果、噪声和结论边界

## 6. BlockingQueue 最终复检

## 7. Week7 核心验收回答
```

---

## 24. 与 Week8 的连接

Week8 ThreadPool 将直接复用：

```text
worker lifecycle
BlockingQueue<Task>
close/drain
worker loop exit
join
atomic statistics（仅简单独立指标）
contention measurement discipline
```

Week8 才新增：

```text
task abstraction
future / packaged_task
ThreadPool V1
AsyncLogger V1
```

---

## 25. 今日压缩记忆

```text
race-free 只说明正确性底线，不说明 scalability。

mutex 会有 lock contention；
shared atomic 仍可能争用同一 cache line；
per-thread local + join 后汇总常能减少共享写。

false sharing 是不同 variables 落在同一 cache line 后产生的性能干扰，
不是 data race。

性能结论必须限定 workload、build、hardware 和多次 measurement。
```
