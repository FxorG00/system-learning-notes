# Week8 Day6：AsyncLogger 的背压证据与性能比较

> 今日定位：继续使用 Day5 已通过的同一份 AsyncLogger，不重写 logger。
>
> 今日主线：用 accepted/rejected/file oracle 检查关闭交错；再公平比较 synchronous logging 与 AsyncLogger。
>
> 今日产出：扩展 tests/async_logger_test.cpp，新增 benchmark/async_logger_bench.cpp，保存真实 benchmark 数据。

---

# Part 1：前情提要与必要术语

## 1. Day5 已经完成了什么

你的 AsyncLogger 已经建立并验证：

~~~text
many producers
-> bounded BlockingQueue<std::string>
-> one writer
-> std::ofstream
-> output file
~~~

核心 contract：

~~~text
log(record) == true
-> record 已 accepted，后续必须由 writer drain

log(record) == false
-> record 没有进入 queue，不应出现在 file

shutdown()
-> close acceptance
-> drain accepted records
-> flush/close stream
-> join writer
-> 返回最终 I/O status
~~~

Day5 已有动态证据：

~~~text
normal CTest 5/5
TSan CTest 5/5
multi-producer unique records exactly once
repeated shutdown
destructor drain
/dev/full 能让 shutdown 返回 false
~~~

所以今天不重复 close、drain、flush、join 的基础实现。只追问两件新事情：

~~~text
1. shutdown 和 producers 同时发生时，怎样判断每条 record 的命运？
2. async submit 看起来更快时，怎样判断整体是否真的更快？
~~~

---

## 2. 今天从什么问题出发

假设有四个 producers 和一个 writer：

~~~text
producers 产生 record 的速度
>
writer 写 file 的速度
~~~

bounded queue 会逐渐填满，随后 log() 开始等待空位。AsyncLogger 没有消灭等待，只是把主要 file I/O 从 producer 身上移走，并用 queue capacity 限制积压。

若 owner 此时开始 shutdown()：

~~~text
close 前成功入队的 record -> accepted -> 必须写入
close 先发生的 record     -> rejected -> 不应写入
~~~

如果只测 log() 多快返回，又会漏掉 writer 后续的 drain/flush/join。今天必须把“producer 多快交完任务”和“全部日志何时真正处理完”分开测。

---

## 3. 今日产出

### 3.1 lifecycle evidence

在 tests/async_logger_test.cpp 增加两条真正的新证据：

~~~text
submit/shutdown accounting：
    attempted IDs 被分成 accepted / rejected
    file 内容必须与 accepted IDs 完全一致

runtime sink failure：
    /dev/full 上 shutdown 返回 false
    lifecycle 正常结束，不 hang
~~~

Day5 已验证过的 zero capacity、open failure、普通顺序、重复 shutdown 和 destructor drain 不重写。

### 3.2 benchmark evidence

新增 benchmark/async_logger_bench.cpp，比较：

~~~text
synchronous baseline
AsyncLogger，1 producer
AsyncLogger，multiple producers
AsyncLogger，不同 queue capacities
~~~

每个 case 同时记录：

~~~text
producer-visible submission time
end-to-end completion time
end-to-end throughput
output correctness
~~~

---

## 4. 必要术语

### 4.1 benchmark 与 baseline

**benchmark**：基准测试，在固定条件下测量性能。

**baseline**：基线，用来对照的方案。今天的 baseline 是 synchronous logger：

~~~text
producer calls log
-> mutex 保护同一个 ofstream
-> 当前 producer 完成 write
-> log returns
~~~

没有 baseline，AsyncLogger 的一个孤立耗时很难说明好坏。

### 4.2 latency 与 throughput

**latency**：延迟，一次操作从开始到结束经过多久。

**throughput**：吞吐量，单位时间完成多少 work。

今天最终吞吐使用：

~~~text
records_per_second
= valid record count / end-to-end seconds
~~~

分母若只使用 submit time，必须明确叫 submission throughput，不能当成完整处理吞吐。

### 4.3 producer-visible 与 end-to-end

**producer-visible**：producer 能直接感受到的部分。

~~~text
submission time：
统一放行 producers
-> 所有 log() calls 返回
~~~

**end-to-end**：端到端，从工作入口一直到声明的完成出口。

~~~text
end-to-end time：
统一放行 producers
-> submissions 完成
-> final flush/close 完成
-> writer joined
~~~

### 4.4 backpressure 与 saturation

**backpressure**：背压，下游跟不上时，把等待传回上游。

~~~text
writer slower
-> queue full
-> producer waits in log()
~~~

**saturation**：饱和。下游能力已经被充分占用，继续增加输入主要形成等待，而不是同比提高完成速率。

capacity 变大可以容纳更多 backlog，但不会自动提高 single writer 的长期速度。

### 4.5 sample、median、range 与 warm-up

**sample**：一次测量得到的值。

**median**：中位数，排序后位于中间的样本。

**range**：本日记录 min ~ max，用于观察波动。

**warm-up**：预热。先运行一次但不计入结果，减少第一次运行的额外影响。它不能消除 VM、page cache、CPU frequency 等全部噪声。

### 4.6 oracle

**oracle**：判断结果是否正确的依据。

今天 submit/shutdown accounting test 的 oracle：

~~~text
attempted = accepted union rejected
accepted intersect rejected = empty
file IDs = accepted IDs
每个 accepted ID exactly once
每个 rejected ID zero times
~~~

它不要求每次运行得到固定的 accepted 数量。

### 4.7 std::chrono::steady_clock

**steady**：稳定向前。steady_clock 不受系统时间校准回拨影响，适合测 elapsed time。

~~~cpp
#include <chrono>

const auto begin = std::chrono::steady_clock::now();
// 运行被测操作
const auto end = std::chrono::steady_clock::now();

const std::chrono::duration<double> elapsed = end - begin;
const double seconds = elapsed.count();
~~~

这个小例子只展示计时 API，不是今日 benchmark 的完整实现。

---

## 5. 四类证据分别回答什么

| 证据 | 今天回答的问题 |
|---|---|
| contract test | accepted/rejected/file 是否符合接口语义 |
| repeat/stress | 更多 scheduling interleavings 下是否仍成立 |
| TSan | 已执行路径是否观察到 data race |
| Release benchmark | 当前环境和 workload 下性能怎样 |

四者不能互相替代：

~~~text
TSan clean 不证明没有 lost record
stress 跑很多次不证明 timer 公平
benchmark 很快不证明 output 正确
一次 contract test 不代表覆盖所有 interleavings
~~~

---

## 6. 今日停止边界

今天不新增：

~~~text
public flush()
fsync durability
drop policy
log level / formatter / rotation
multiple writers
lock-free queue
Google Benchmark dependency
p50 / p95 / p99
CPU affinity / perf / flame graph
~~~

这些不影响今天完成“正确性先成立，再做边界清楚的基础性能比较”。

---

# Part 2：教程主体

# 教程开始：怎样证明 logger 正确，又怎样公平计时

# Round 1：先独立写第一版 test 与 benchmark

Round1 不修改 AsyncLogger public API，也不复制 logger source。

## 7. Round1 要做的程序

继续修改：

~~~text
tests/async_logger_test.cpp
~~~

新增：

~~~text
benchmark/async_logger_bench.cpp
week8/day6/day6_note.md
~~~

### 7.1 submit/shutdown accounting test 的用途（新增进去 google_test 里面，与 benchmark 无关）

这里的 **accounting test** 是“记账测试”，不是财务。

它要验证 AsyncLogger 在 `submit/log` 和 `shutdown` 交错时，**每条 record 的去向都能对上**：

```text
尝试提交总数
= 被 logger 接受的数量
+ 因为 shutdown 被拒绝的数量
```

正常写入成功时还应有：

```text
被接受的数量
= 最终文件中实际写出的记录数量
```

例如 100 条日志：

```text
log() 返回 true：73 次
log() 返回 false：27 次
文件有效行数：73 行
```

这就说明：

- 没有“返回 `true` 却丢了”的日志；
- shutdown 后被拒绝的日志没有偷偷写入；
- 没有重复写入；
- 总数能够闭合。

所以它特别适合测 `submit/log` 与 `shutdown` 并发发生时的边界，而不只是测“正常写五条日志能不能写进文件”。

---

多个 producers 生成 unique IDs，并记录每次 log() 的返回值；owner 在 producers 被统一放行后调用 shutdown()。这会制造并发竞争，但 scheduler 仍可能让所有 log() 先完成，因此本 test 不声称一定观察到实际 overlap。它最终验证：

~~~text
accepted IDs 在 file 中 exactly once
rejected IDs 不在 file 中
所有 attempted IDs 都被分类
所有 execution flows 正常结束
~~~

本轮由你决定：

~~~text
怎样保存每个 producer 的结果
怎样让 producers 大致同时开始
shutdown 在哪个 execution flow 中调用
怎样读取并比较 IDs
~~~

不要求固定 accepted/rejected 数量，也不使用固定 sleep 作为正确性条件。

### 7.2 benchmark 程序的用途

同一批 fixed-size records 分别交给 synchronous baseline 和真实 AsyncLogger：

~~~text
prepare identical records
-> run one case
-> obtain submission time
-> obtain end-to-end time
-> validate output
-> print one structured result row
~~~

第一版配置可以写成 constants：

~~~text
record count
record bytes
producer count
queue capacity
output path
~~~

每个 case 至少输出：

~~~text
mode,producers,capacity,records,record_bytes,submit_ms,end_to_end_ms,valid
~~~

数字只是输出格式，不规定预期性能。

## 8. Round1 最小 API 工具箱

读取最终文件：

~~~cpp
#include <fstream>
#include <string>

std::ifstream input(path);
std::string line;

while (std::getline(input, line)) {
    // 把 line 交给自己的 ID validation。
}
~~~

Round1 先保存原始耗时；median/range 放到 Round2 后再补。

## 9. Round1 编译入口

~~~bash
cd ~/code/system-learning/cpp/week8
mkdir -p benchmark build

g++ -std=c++17 -Wall -Wextra -g -O2 -pthread \
  -Iinclude src/async_logger.cpp benchmark/async_logger_bench.cpp \
  -o build/async_logger_bench

./build/async_logger_bench
~~~

benchmark 使用 optimized build；correctness tests 和 TSan 仍走现有 CMake build trees。

## 10. Round1 停止点

至少完成：

~~~text
一版 submit/shutdown accounting test 设计或代码
一版 synchronous baseline
一版 AsyncLogger benchmark case
两个 timer 的初始定义
一次真实运行结果
每个 case 的 output validation
~~~

在 day6_note.md 记录原始判断：

~~~text
submit timer 从哪里开始、在哪里结束？
end-to-end timer 又在哪里结束？
sync 与 async 怎样保持同样的 output policy？
capacity 变化时，你预测哪个时间更敏感？
~~~

**阅读闸门：完成 V1 代码和至少一次运行后，再进入 Round2。**

---

# Round 2：用你的 V1 对照两个核心模型

你的 Round1 已经形成真实基线：

~~~text
benchmark：去掉 ThreadPool，直接使用 std::thread producers；
             连续区间覆盖全部 records；sync 先 join 再 flush/close

accounting：unique ID + per-ID accepted 标记；
            logger shutdown 后等待 producer tasks 全部完成，再读取 oracle

dynamic evidence：normal CTest 6/6
                  AccountingTest repeated 500/500
                  TSan CTest 6/6，no report
~~~

因此 Round2 不重写 accounting test，也不重新解释基本 shutdown。它只用两个模型审查 benchmark 数据：

~~~text
model A：accepted/rejected/file oracle
model B：submission/end-to-end timer boundary
~~~

## 11. backpressure 的完整因果链

~~~text
producer rate exceeds writer rate
    |
    v
queue occupancy rises
    |
    v
queue reaches capacity
    |
    v
next log() waits for closed || not_full
    |
    +--> writer pops: producer later gets a slot
    |
    +--> owner closes: producer wakes and returns false
~~~

capacity 主要控制：

~~~text
最大 backlog(积压的工作，其实就是 queue 中待处理的元素)
producer 多早开始等待
shutdown 最多可能需要 drain 多少排队数据
~~~

它不直接改变 single writer 的 file-writing ability。Backpressure 的主要可观察结果是 producer-visible submission time 增加。

今天把它作为 benchmark observation，不写成“单次 log() 必须超过 1 ms”这样的脆弱 assertion。

你的 8-vCPU VM 已经给出一个具体样本：`3,000,000 records + 1,000 producers + capacity 1,000,000` 时，async end-to-end 从约 `0.5 s` 增至约 `10 s`。这组数据更像 high-contention stress：1000 个 producer execution flows 竞争同一 queue mutex，queue 满后又进入 backpressure；它不能单独代表常规 producer count 下的 logger 性能。

---

## 12. submit/shutdown 的 accounting oracle

你的 AccountingTest 已经实现本轮 oracle：

~~~text
每个 attempt 使用 unique producer/log ID
log() true  -> vis[id] = accepted
log() false -> vis[id] = rejected
logger.shutdown() 制造关闭边界
pool.shutdown() 等待全部 attempts 结束
file 中每个 accepted ID exactly once
file distinct-ID count == accepted_count，因此没有额外 rejected ID
~~~

普通运行、500 次重复运行和 TSan 路径均已通过，本轮不再改写它。证据边界仍然不变：它证明不同 interleaving 下 accounting 自洽，不宣称 deterministic overlap。

---

## 13. /dev/full：把 Day5 的真实 bug 留成回归证据

/dev/full 是 Linux 提供的特殊设备：

~~~text
open 通常成功
write/flush 报 no space
~~~

Day5 首次探针：

~~~text
accepted=1 shutdown_ok=1
~~~

它暴露了 final flush failure 没有进入 write_failed。修复后：

~~~text
accepted=1 shutdown_ok=0
~~~

Day6 只需把它保存成 regression test：

~~~cpp
AsyncLogger logger("/dev/full", 8);

// 此时 queue open、为空且 capacity=8，因此这次 log() 必须返回 true。
const bool accepted = logger.log("runtime-failure");
const bool shutdown_ok = logger.shutdown();
~~~

核心 oracle：

~~~text
accepted == true
shutdown_ok == false
test process 正常退出
~~~

它测试 runtime sink failure，不是 constructor open failure，也不测试 durable storage。

---

## 14. 公平比较的共同条件

synchronous 与 asynchronous case 使用相同：

~~~text
预先生成的 records
record count / bytes / unique IDs
producer count
output format：一行一条
final flush/close policy
compiler 与 Release build
output validation
~~~

两边都从同一批 lvalue records 读取输入。AsyncLogger 按值接收 record 所产生的 copy/move 是真实 handoff cost，应留在 submission timer 内，而不是为了让数字好看把它提前做掉。

你的 R1 `validate()` 已经检查每个 expected ID exactly once。Round2 再补一条 `distinct file IDs == record_count`，排除文件中额外出现 unexpected line；normal async case 同时累计 `log()` rejection，并检查最终 `shutdown()` status。

synchronous baseline：

~~~text
many producers
-> one mutex
-> one ofstream
-> write record + newline
-> final flush/close
~~~

它不做 per-record flush，否则比较会混入不同 buffering policy。

对照你的 R1 note：sync submission time 与 end-to-end time 不能严格写成相等。所有 producer 的 `sync_log()` 返回，只代表 submission phase 结束；`ofstream` 仍可能保留最后一部分用户态 buffered bytes，最终 `flush/close` 完成才是 end-to-end end。两者可能非常接近，但边界不同。

AsyncLogger 的正常 benchmark 路径：

~~~text
many producers call log()
-> join producer threads
-> shutdown logger
-> writer drains / flushes / joins
~~~

性能 benchmark 不与 shutdown 制造拒绝交错；submit/shutdown accounting 已由独立 correctness test 处理。

---

## 15. 两个 timer 的边界

你的 R1 在创建 output/logger 和 producer threads 之前启动 timer，所以当前数字准确名称是 **whole-case setup + submission time**。这不是错误，但它会让 thread creation 掩盖 logger 差异。Round2 改成下面的边界：先构造 logger/output、创建并停住 producer threads，再从同一个 start point 放行。

~~~mermaid
flowchart LR
    A[records and objects ready] --> B[open producer start gate]
    B --> C[all producer log calls return]
    C --> D[submission end]
    D --> E[final shutdown flush close join]
    E --> F[end-to-end end]
    F --> G[validate output outside timed region]
~~~

### producer-visible submission time

~~~text
start = producers 被统一放行
end   = 所有 producer execution flows 完成 log calls
~~~

如果实现是在 join 所有 producer threads 之后读取 end timestamp，那么 submission time 还包含 producer function 返回、thread 退出以及 join 的同步开销；它不包含 std::thread object 之后的析构成本。sync 与 async 使用同样的 producer-thread lifecycle 时，这仍是一项公平的粗粒度 phase measurement，但不能称为纯 log() call time。

### end-to-end completion time

~~~text
start = 同一个 start
end   = logger final shutdown 完成
~~~

synchronous baseline 的 final shutdown 也执行 stream flush/close。这样两个 end-to-end timer 都包含各自完成全部日志所需的收尾。

StartGate 已在 Day4 使用过。这里直接复用，不重新讲 mutex/CV 实现。

---

## 16. benchmark matrix

建议第一版固定：

~~~text
record_count  = 100000
record_bytes  = 128
producers     = 1, 4
capacity      = 1, 64, 1024   // async only
warm-up       = 1
measured runs = 5
~~~

VM 太慢时可以降低 record_count，但同一组 sync/async cases 使用相同输入。

当前 VM 只有 8 个 vCPUs。`100` 或 `1000` producers 可以保留为单独的 contention stress observation，但主 benchmark 先使用 `1 / 4`；不要把 1000-thread scheduling cost 当作 AsyncLogger 的常规吞吐结论。

records 在 timer 外生成，并满足：

~~~text
每条有 unique ID
大小固定
不包含 embedded newline
sync/async 使用同一份内容
~~~

每个 measured run 结束后验证 output；validation 不放进 timer。

---

## 17. 汇总结果

每个 case 保存五个 raw samples，分别对 submit_ms 和 end_to_end_ms 排序并报告：

~~~text
median
min
max
~~~

end-to-end throughput：

~~~text
records_per_second
= records / (e2e_median_ms / 1000.0)
~~~

结果行只有一个 records_per_sec 字段，所以这里统一由 end-to-end median 计算；min/max 只用于展示波动，不混入这个吞吐量字段。

结果行：

~~~text
mode,producers,capacity,records,record_bytes,
submit_median_ms,submit_min_ms,submit_max_ms,
e2e_median_ms,e2e_min_ms,e2e_max_ms,
records_per_sec,valid
~~~

---

## 18. 怎样读结果

### async submit 更快，end-to-end 接近

~~~text
当前 workload 下，AsyncLogger 减少了 producer-visible waiting；
总体完成时间与 synchronous baseline 接近。
~~~

### async submit 更快，end-to-end 更慢

可能意味着：

~~~text
queue handoff / synchronization 带来额外成本
single writer 成为 bottleneck
大量 work 留在 drain tail
~~~

准确结论是：producer 更早返回，但当前 workload 的完整处理时间没有优势。

### capacity 变大，submit 变短，end-to-end 基本不变

~~~text
更大 capacity 吸收了更多 backlog；
writer 的最终处理能力没有明显变化。
~~~

### 波动较大

记录 VM、vCPU、filesystem、compiler、case 参数和 range。数据真实、边界清楚，比硬凑一个固定倍数重要。

本实验测的是 buffered file logging in current environment，不是 durable disk throughput，因为没有 fsync contract。

---

## 19. correctness、TSan 与 benchmark

~~~text
contract tests pass
    |
    +--> repeat/stress：探索更多 scheduling interleavings
    |
    +--> TSan：检查已执行 memory accesses
    |
    v
Release benchmark
    |
    v
validate output
    |
    v
保存 raw samples 和有边界的结论
~~~

TSan 会显著改变程序成本，因此 TSan binary 只提供 race evidence，不参与性能比较。

---

## 20. 今日完整主线

~~~text
Day5 canonical AsyncLogger
    |
    +--> submit/shutdown accounting test
    |       attempted -> accepted/rejected
    |       file IDs == accepted IDs
    |
    +--> /dev/full regression
    |       shutdown returns false, lifecycle ends
    |
    v
fair sync/async benchmark
    |
    +--> same records and output policy
    +--> producer-visible timer
    +--> end-to-end timer
    +--> output validation
    |
    v
warm-up + repeated Release runs
    |
    v
median/range + bounded conclusion
~~~

---

# Part 3：收尾、测试与验收

# Round 3：把 V1 修成可复现证据

Round3 不新增 logger 版本，也不把 benchmark 重写成第二套文件。它只补 Round1 的真实缺口。

## 21. Round3 最终增量

tests/async_logger_test.cpp 只新增：

~~~text
AccountingTest                         // Round1 已完成
ReportsRuntimeWriteFailureWithoutHanging
~~~

其余 Day5 tests 继续运行，不复制 test bodies。

benchmark/async_logger_bench.cpp 最终支持：

~~~text
sync baseline
async cases
1 / multiple producers
multiple capacities
two timer boundaries
warm-up + 5 samples
median/min/max
exact output validation
non-zero exit on invalid case
~~~

---

## 22. 两个新增 tests 的 observable contract

### AccountingTest

~~~text
multiple producers attempt unique IDs
one owner calls shutdown after producer execution flows are released
scheduler may still produce all-accepted, all-rejected, or mixed outcomes
each log return classifies its ID
all producer and shutdown execution flows finish
file multiset equals accepted-ID multiset
rejected IDs do not appear
~~~

它不要求固定 accepted count、固定 rejected count、跨 producers 的固定全局顺序或固定毫秒级等待。

### ReportsRuntimeWriteFailureWithoutHanging

~~~text
output path = /dev/full
submit bounded records
shutdown returns false
test returns normally within CTest timeout
~~~

TIMEOUT 只把意外 hang 转成 test failure，不参与正常同步。

---

## 23. benchmark observable contract

### 输入

~~~text
mode
record count
record bytes
producer count
queue capacity
repetition index
output path
~~~

可以使用 source constants，不要求 command-line parser。

### 输出

~~~text
mode
producers
capacity
records
record_bytes
submit median/min/max
end-to-end median/min/max
end-to-end records/sec
valid
~~~

### failure

下面任一情况让 benchmark 最终返回 non-zero：

~~~text
construction failure
normal benchmark 中出现 rejected record
shutdown status false
file IDs 缺失、重复或意外出现
~~~

---

## 24. Round3 最小 API

### 24.1 std::sort 与奇数样本 median

~~~cpp
#include <algorithm>
#include <vector>

std::sort(samples.begin(), samples.end());
const double median = samples[samples.size() / 2];
~~~

今天固定使用五个 samples，因此中间项就是 median。调用前保证 vector 非空。

### 24.2 std::minmax_element

~~~cpp
#include <algorithm>

const auto [min_it, max_it] =
    std::minmax_element(samples.begin(), samples.end());
~~~

min_it 和 max_it 是 iterators；分别解引用得到最小、最大 sample。

---

## 25. CMake 只增加当天 target

你已经在 Day5 理解 library/link 关系。今天只增加 benchmark delta：

~~~cmake
add_executable(async_logger_bench
    benchmark/async_logger_bench.cpp
)

target_link_libraries(async_logger_bench
    PRIVATE
        async_logger
        Threads::Threads
)

target_compile_options(async_logger_bench
    PRIVATE
        -Wall
        -Wextra
)
~~~

benchmark 不注册成 CTest；correctness tests 继续由 CTest 管理。

你的当前 `ENABLE_TSAN` 会 instrument `async_logger` static library。所有链接它的 executables 都必须链接 TSan runtime，否则全量 build 会出现 `undefined reference to __tsan_*`。把 benchmark target 同步加入现有分支：

~~~cmake
if(ENABLE_TSAN)
    target_compile_options(async_logger_bench PRIVATE
        -O1 -fsanitize=thread -fno-omit-frame-pointer
    )
    target_link_options(async_logger_bench PRIVATE
        -fsanitize=thread
    )
endif()
~~~

TSan benchmark 只用于 race evidence，不用于性能数字。

---

## 26. 编译与运行

normal tests：

~~~bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build -j
cmake -E chdir build ctest -R AsyncLogger --output-on-failure
~~~

TSan tests：

~~~bash
cmake -S . -B build-tsan \
    -DCMAKE_BUILD_TYPE=Debug \
    -DENABLE_TSAN=ON
cmake --build build-tsan -j
cmake -E chdir build-tsan ctest -R AsyncLogger --output-on-failure
~~~

Release benchmark：

~~~bash
cmake -S . -B build-release -DCMAKE_BUILD_TYPE=Release
cmake --build build-release --target async_logger_bench -j
./build-release/async_logger_bench
~~~

运行前在 note 中记录：

~~~text
VM / bare metal
vCPU count
compiler version
output filesystem/path
record count/bytes
producer count
queue capacities
sample count
~~~

---

## 27. 今日验收问题

1. Backpressure 是谁把等待传给谁？capacity 变大为什么不代表 writer throughput 必然提高？
2. submit/shutdown 并发尝试中，怎样用 accepted/rejected/file IDs 判断所有 records 的命运？为什么这条 test 不能证明 overlap 必然发生？
3. /dev/full 测的是哪个 failure stage？为什么 open 可以成功而 shutdown 返回 false？
4. producer-visible submission time 与 end-to-end time 的起止点分别是什么？
5. synchronous baseline 与 AsyncLogger 必须保持哪些条件相同？
6. 如果 async submit 更快但 end-to-end 更慢，你能得出什么结论，不能得出什么结论？

代码、测试、benchmark 输出和 note 已经覆盖的问题，不需要机械誊写答案。

---

## 28. 今日通过标准

### 核心

~~~text
继续使用 Day5 canonical AsyncLogger
submit/shutdown evidence 使用 accepted/rejected/file accounting，且不宣称 deterministic overlap
/dev/full regression 得到 shutdown false 且不 hang
normal CTest 通过
相关路径 TSan 无 report
sync/async 使用相同 records 和 output policy
同时报告 submission 与 end-to-end time
每个 benchmark case 验证 output
至少 1 warm-up + 5 measured samples
报告 median 与 min/max
结论限定当前环境和 buffered policy
~~~

### 可调整

~~~text
record count / bytes
producer count
capacity matrix
output path
~~~

VM 较慢时可以缩小 workload，但同一比较组的输入必须一致。

### 不阻塞 Day6

~~~text
固定测出 async 更快
严格证明 producer 正阻塞于 queue 内部某一行
per-call percentile latency
fsync durability
Google Benchmark
perf / flame graph
production logger features
~~~

---

## 29. 今日停止在哪里

今天结束时应能说清：

~~~text
AsyncLogger 首先改变 producer 承担 I/O 的方式，
不保证所有 workload 下 end-to-end 更快。

bounded queue 用 backpressure 限制 backlog；
capacity 影响等待出现的时机，不自动提高 writer 能力。

submit/shutdown accounting 的正确性不靠固定 accepted 数量，
而靠 log() 返回值与最终 file 内容完全自洽。

性能比较同时保留 submission 和 end-to-end boundaries，
并建立在同样输入、同样 output policy、Release build、
重复样本和 output validation 之上。
~~~

Day7 再组合 ThreadPool 与 AsyncLogger，处理两个组件之间的 lifetime dependency，并完成项目文档。

---

## 30. 今日压缩记忆

~~~text
Backpressure：
writer 跟不上 -> queue full -> producer log waits。

Shutdown oracle：
attempted = accepted + rejected；
file IDs = accepted IDs。

Runtime failure：
/dev/full open succeeds，final write/flush fails；
shutdown false，lifecycle still ends。

Benchmark：
same input + same policy；
submission time + end-to-end time；
validate output；
Release repeated samples -> median/range。
~~~

---

## 31. 今日参考资料

- [C++ working draft：std::chrono::steady_clock](https://eel.is/c++draft/time.clock.steady)
- [C++ working draft：basic_ostream::flush](https://eel.is/c++draft/ostream.unformatted)
- [Linux man-pages：full(4) 与 /dev/full](https://man7.org/linux/man-pages/man4/full.4.html)

资料边界：steady_clock 用于 elapsed time；stream draft 用于 flush state；full(4) 用于 runtime no-space regression。Day6 不引入 Google Benchmark dependency。
