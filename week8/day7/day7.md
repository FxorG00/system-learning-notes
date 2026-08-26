# Week8 Day7：把 ThreadPool 与 AsyncLogger 组合成一个小项目

> 今日定位：Week8 出口日。
>
> 今日唯一主问题：当 ThreadPool 中的 tasks 会调用 AsyncLogger 时，两个原本各自正确的 components 应怎样组合、怎样结束，并怎样整理成一个别人能运行、你自己能解释的小项目？
>
> 今日产出：
>
> ~~~text
> demos/component_demo.cpp
> README.md
> interview.md
> week8/day7/day7_note.md
> ~~~
>
> 今天不再给两个 components 添加新功能，也不提前进入 Reactor。

---

# Part 1：前情提要与必要术语

## 1. Week8 前六天留下了什么

你现在已经有三层可以复用的 canonical code：

~~~text
BlockingQueue
    bounded queue、wait/notify、close、drain

ThreadPool
    fixed workers、submit、future result/exception
    close task queue -> drain accepted tasks -> join workers

AsyncLogger
    producer/writer split、bounded log queue、single writer
    close log queue -> drain records -> flush/close -> join writer
~~~

Day4 已经给 ThreadPool 建立 tests、repeat 与 TSan 证据；Day5、Day6 已经给 AsyncLogger 建立 correctness tests、运行期 I/O failure test、submit/shutdown accounting test 和经过 output validation 的 benchmark。

今天不复制 components，也不重复旧测试。今天只解决跨 component 的问题。

---

## 2. 今天从哪个问题出发

假设 pool 中的一项 task：

~~~text
计算业务结果
-> 调用 logger.log 记录结果
~~~

此时出现一条新关系：

~~~text
pool task 正确完成 logging
依赖 AsyncLogger 仍然可用
~~~

因此今天要回答：

1. main、ThreadPool、task、AsyncLogger 分别拥有什么？
2. 哪个 object 必须活得更久，正常 shutdown 顺序是什么？
3. 怎样同时证明业务结果正确、日志也没有缺失或重复？

只让两个 class names 出现在同一个 main 中，还不等于完成 integration。

---

## 3. 必要术语

### 3.1 component

**component**：组件。

今天指有明确职责、public interface、owned resources、lifecycle contract 和 tests 的可组合代码单元。

~~~text
ThreadPool：task execution component
AsyncLogger：asynchronous file logging component
~~~

### 3.2 integration

**integration**：集成、组合。

它关注 components 接起来后才出现的问题：

~~~text
谁调用谁
谁依赖谁
谁先构造
谁先停止
错误怎样影响整体结果
~~~

两个 components 单独正确，不自动证明组合后的 lifetime 正确。

### 3.3 dependency

**dependency**：依赖。

若 A 正确工作需要 B 仍可用，就说 A depends on B。今天 tasks 会调用 logger，因此 task execution depends on logger availability。

dependency 描述“工作需要谁”，不等于 ownership。

### 3.4 ownership 与 borrow

**ownership**：所有权。Owner 负责 object 的最终 lifecycle。

**borrow**：借用。Borrower 可以访问 object，但不拥有或销毁它。

今天预期：

~~~text
main owns ThreadPool and AsyncLogger
ThreadPool owns workers and task queue
AsyncLogger owns writer, log queue and output stream
tasks only borrow AsyncLogger
~~~

task 捕获 AsyncLogger 引用只保存 non-owning access path，不会延长 logger lifetime。

### 3.5 lifetime

**lifetime**：生命周期。

核心关系：

~~~text
AsyncLogger lifetime
必须覆盖所有仍可能调用 logger.log 的 tasks
~~~

这里还要求 logger 尚未关闭 acceptance，不只是 object 内存仍存在。

### 3.6 composition root

**composition**：组合；**root**：根。

composition root 集中创建 components、连接 dependency、控制整体 lifecycle。今天 main 就是 composition root：

~~~text
create -> connect -> shutdown -> validate
~~~

ThreadPool 不必拥有 logger，logger 也不必知道 pool 存在。

### 3.7 self-validating demo

**self-validating**：自验证。

demo 要自己检查结果，并用 process exit status 表达：

~~~text
all checks pass -> return 0
any check fails -> return non-zero
~~~

不能只打印看起来合理的内容，让人眼判断。

### 3.8 reproducible 与 evidence

**reproducible**：可复现。别人能按文档重新 build、run、test。

**evidence**：证据。每个 claim 应能指向真实 test、TSan run、benchmark 或 demo。

~~~text
TSan clean：当前执行路径未观察到 data race
validated benchmark：当前环境下的性能观察
deterministic test：特定 contract 的 correctness evidence
~~~

三者不能互相替代。

---

## 4. 今天继承的 contracts

ThreadPool：

~~~text
submit accepted callable -> future<R>
accepted task -> future eventually ready
shutdown -> stop acceptance, drain tasks, join workers
~~~

AsyncLogger：

~~~text
log true -> accepted
log false -> rejected
shutdown -> stop acceptance, drain, flush/close, join writer
shutdown bool -> final output status
~~~

边界：

~~~text
log true != record 已写入
flush success != physical durability
~~~

Day7 复用这些 contracts，不另造 V2。

---

## 5. 今天不做什么

~~~text
不做 dynamic resize / work stealing / cancellation
不做 logger level / rotation / fsync
不创建 ThreadPoolFinal、AsyncLoggerV2
不使用 shared_ptr 掩盖 owner
不重新手写全部旧 tests 或重复大量 benchmark
不声称 production-ready 或“异步一定更快”
不提前实现 epoll / Reactor
~~~

---

# Part 2：教程主体

# 教程开始：先独立组合，再回头审查

# Round 1：独立完成 integration V1

> 阅读闸门：先只读到 Round1 结束。component_demo 能 build/run，并有 README、interview 初稿后，再看 Round2。

## 6. Round1 要造什么

### 6.1 文件名与用途

新建：

~~~text
~/code/system-learning/cpp/week8/demos/component_demo.cpp
~~~

文件开头先写程序用途：

~~~text
This demo composes the canonical ThreadPool and AsyncLogger.
It submits deterministic tasks, checks task results and final log records,
and returns non-zero when the integration result is invalid.
~~~

中文也可以。先说明“程序干什么”，再开始设计。

### 6.2 输入与输出

Round1 使用稳定常量，不做 command-line parser：

~~~text
worker_count = 4
task_queue_capacity = 16
logger_queue_capacity = 8
task_count = 100
output_path = component_demo.log
~~~

输入是固定 task IDs 及其可预测计算。输出包括：

~~~text
future results
每项 task 的 unique log record
简短 PASS / FAIL summary
process exit status
~~~

这些参数用于 correctness，不是 performance conclusion。

### 6.3 最小功能 contract

V1 必须完成：

~~~text
使用真实 ThreadPool 与 AsyncLogger
submit 多项 deterministic tasks
每项 task 计算可预测结果，并尝试记录 unique ID
caller 最终观察所有 task outcomes
程序退出前结束两个 components 的 lifecycle
检查每个业务结果
检查每个 expected log ID 恰好一次
缺失、重复、unexpected ID、log rejection 或 shutdown failure
均使程序返回 non-zero
~~~

Round1 故意不告诉你：

~~~text
两个 objects 的声明顺序
先 shutdown 哪个
先 get futures 还是先 shutdown
task outcome 设计成什么类型
cleanup control flow 怎样组织
~~~

这些是你要独立设计、Round2 再复盘的部分。

### 6.4 可观察 summary

格式可以不同，但至少表达：

~~~text
tasks submitted: 100
future results checked: 100
logs accepted: 100
unique log IDs: 100
integration result: PASS
~~~

不要把不同 workers 的输出顺序当 oracle。

### 6.5 build/run 入口

在 project-root CMakeLists.txt 增加：

~~~cmake
add_executable(component_demo
    demos/component_demo.cpp
)

target_link_libraries(component_demo
    PRIVATE
        async_logger
        Threads::Threads
)

target_compile_options(component_demo
    PRIVATE
        -Wall
        -Wextra
)
~~~

ThreadPool 若是 header-only，就沿用现有 include path，不复制 implementation。

~~~bash
cd ~/code/system-learning/cpp/week8
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build --target component_demo -j
./build/component_demo
echo $?
~~~

成功时 exit status 为 0。

### 6.6 README 与 interview 初稿

README.md 初稿只回答：

~~~text
项目做什么
主要 components
怎样 build/run
当前明确不支持什么
~~~

interview.md 初稿只回答：

~~~text
为什么做 ThreadPool
为什么做 AsyncLogger
当前怎样组合二者
你认为关键 shutdown 顺序是什么，为什么
~~~

先写真实判断，不必提前迎合后文。

### 6.7 Round1 自检

~~~text
[ ] component_demo.cpp 有用途注释
[ ] 使用 canonical components
[ ] -Wall -Wextra 无 warning
[ ] 成功路径 return 0
[ ] 人为改错 expected result 时 return non-zero
[ ] README build/run command 实际执行过
[ ] 记录自己最不确定的 ownership/shutdown 问题
~~~

做到这里就停下，让 Codex 检阅 R1。

R1 正式通过后，Codex 会根据你的声明顺序、captures、shutdown、future 处理、output oracle、note 与对话，定向润色 Round2/Round3，而不是继续套通用模板。

---

# Round 2：用 V1 复盘 dependency、lifetime 与 shutdown

> 下面不是要重抄的答案。始终拿自己的 R1 code 对照。

## 7. 从你的 R1 读出四种关系

~~~text
ownership：谁负责销毁 object
dependency：谁正确工作需要谁
borrowing：谁保存 non-owning reference
data flow：result/log record 往哪里走
~~~

你的 R1 已经形成：

~~~text
work owns local AsyncLogger logger
work owns local ThreadPool pool
pool owns workers and task queue
logger owns writer, log queue and output stream
task lambda captures &logger and i
    &logger：borrow
    i：copy by value
futures vector owns future<size_t> handles
validate observes futures and final file
~~~

对应图：

~~~mermaid
flowchart LR
    M[main / composition root] -->|owns| P[ThreadPool]
    M -->|owns| L[AsyncLogger]
    P -->|executes| T[tasks]
    T -->|borrows and calls log| L
    T -->|value or exception| R[futures]
    L -->|single writer| F[output file]
    M -->|observes| R
~~~

核心句：

> main owns both；tasks only borrow logger；因此所有 log producers 结束后，logger 才能结束。

你的代码没有让 ThreadPool 持有 logger，也没有让 AsyncLogger 反向依赖 pool。这个 ownership graph 是清楚的。

---

## 8. 构造与析构顺序

C++ 同一 scope 的 local objects 按声明逆序析构：

~~~cpp
AsyncLogger logger(...);
ThreadPool pool(...);
~~~

正常离开 scope：

~~~text
pool destructor
-> logger destructor
~~~

这与 dependency 相匹配，因为 tasks 借用 logger。

声明顺序只是异常路径和遗漏显式 shutdown 时的 backup。正常路径仍应显式 shutdown，因为 caller 需要检查 logger 的最终 bool status，而 destructor 不能返回失败。

当前 owner 明确、scope 固定，不需要 shared_ptr 自动续命。

你第一版曾写成：

~~~text
ThreadPool pool
AsyncLogger logger
~~~

正常显式 shutdown 没暴露问题，但异常离开时会先析构 logger。复检后你已改成 logger first、pool second，并在代码旁写明 reverse destruction 的原因。这一处现在通过。

---

## 9. 你当前 R1 的完整 lifecycle

~~~text
main constructs AsyncLogger
    |
    v
main constructs ThreadPool
    |
    v
main submits deterministic tasks
    |
    v
workers execute tasks
    |
    +--> compute result
    +--> logger.log(unique record)
    +--> publish outcome through future shared state
    |
    v
main calls pool.shutdown
    |
    +--> stop task acceptance
    +--> drain accepted tasks
    +--> join all workers
    |
    v
no pool task can call logger again
    |
    v
main calls logger.shutdown
    |
    +--> stop log acceptance
    +--> drain accepted records
    +--> flush/close output
    +--> join writer
    |
    v
validate:
    +--> future[i].get() == i
    +--> read every output line into map<string, count>
    +--> map has task_count unique keys
    +--> every expected "task: i" count == 1
    |
    v
all checks pass -> return 0
~~~

一句话：

> 先停止 log producers，再停止 logger consumer。

你的顺序不是“先 get futures，再 shutdown logger”，而是先让两个 background lifecycles 都结束，再统一 validate。对当前 deterministic tasks，这是合理设计。

---

## 10. 两种错误顺序的不同后果

logger object 还活着，但先 shutdown：

~~~text
logger closes acceptance
-> pool still has tasks
-> later log returns false
~~~

这是 lifecycle order 导致的 rejection。

logger object 已被销毁，但 task 仍可能调用：

~~~text
task keeps borrowed reference
-> logger lifetime ends
-> task calls logger.log
-> dangling reference / undefined behavior
~~~

这是 object lifetime bug。不要把二者只写成“可能有问题”。

---

## 11. 你把 future.get 放在 logger.shutdown 之后意味着什么

当前顺序：

~~~text
pool.shutdown
-> logger.shutdown
-> validate calls future.get
~~~

优点：

~~~text
进入 validate 前，pool workers 和 logger writer 都已 join
最终 file 已 flush/close
future.get 即使将来抛 exception，也不会跳过 component cleanup
~~~

当前不足只是 diagnostics：

~~~text
validate 遇到第一个 mismatched future 就 return false
future.get 若抛 exception，会直接离开 work
logger.shutdown false 时会提前 return，不再检查 futures/file
~~~

这些不会让当前 normal V1 泄漏 threads，因为 cleanup 已经完成。Round3 若想让一次失败报告更多信息，可以逐项记录 failure 再统一返回；它不是要求你推翻现有顺序。

---

## 12. 组合后的 backpressure chain

~~~text
external submitter
-> bounded task queue
-> pool workers
-> bounded log queue
-> logger writer
-> file
~~~

writer 慢时：

~~~text
log queue full
-> workers may wait in logger.log
-> task queue may fill
-> external submitter may wait
~~~

backpressure 会跨 component 传播。

当前没有必然 deadlock cycle，因为 logger writer 有独立 thread，不反向等待 ThreadPool。若 file operation 永久不返回，V1 仍可能长期阻塞，这是 limitation，不在今天扩展 cancellation。

---

## 13. 你的 two-channel oracle 是否完整

~~~mermaid
flowchart LR
    T[task] -->|value or exception| S[future shared state]
    T -->|accepted or rejected| Q[log queue]
    Q --> W[writer]
    W --> F[final file]
~~~

future channel 的实际 oracle：

~~~text
for i in [0, task_count):
    futures[i].get() == i
~~~

file channel 的实际 oracle：

~~~text
read all lines into map<string, count>
map.size() == task_count
for every expected "task: i":
    count == 1
~~~

这组条件可以同时挡住：

~~~text
missing expected ID
duplicate expected ID
unexpected ID
wrong future result
final stream failure
~~~

task 当前忽略 logger.log 的 bool 返回，但 missing/rejected record 最终会使 file oracle 失败；writer failure 由 logger.shutdown false 暴露。对当前没有 concurrent logger shutdown 的 demo，这个间接 oracle 足够，不强制改成新的 TaskResult struct。

不验证 worker identity、跨 workers 的完成顺序或 ID 全局递增。调度顺序不稳定，但最终 multiset 可以精确检查。

---

## 14. README 与 interview.md

README 负责：

~~~text
这是什么
怎样 build/run/test
architecture 与 lifecycle
evidence 与 limitations
~~~

interview.md 负责：

~~~text
为什么这样设计
付出什么代价
哪条证据支持
下一步怎样演进
~~~

同一个 shutdown：

~~~text
README：给正常顺序和运行方式
interview.md：解释为何 pool first/logger second，
              错序后果和对应证据
~~~

不必复制同一篇长文。

---

## 15. 项目故事

~~~text
Problem：
    bounded task execution + multi-producer file logging

Design：
    BlockingQueue + fixed ThreadPool + future
    + single-writer AsyncLogger

Hard parts：
    close/drain/join、move-only task bridge、
    backpressure、cross-component lifetime

Evidence：
    deterministic tests、repeat、TSan、
    validated benchmark、integration demo

Limits：
    fixed workers、blocking queues、no cancellation/work stealing、
    no rotation/fsync durability
~~~

准确说成“C++17 并发组件练习项目”比“工业级高性能框架”更可信。

---

## 16. Round2 对照检查

~~~text
[x] work owns logger and pool
[x] task captures &logger and copies i
[x] logger first, pool second
[x] pool shutdown before logger shutdown
[x] both components end before validate
[x] future results are exact
[x] final file IDs are exactly once
[x] normal failure becomes non-zero exit
[ ] component_demo joins the ENABLE_TSAN target graph
[ ] canonical README/interview are completed in Round3
~~~

R1 component code 不需要重写。Round2 后真正剩下的是 CMake sanitizer 接线与项目文档，而不是再造一版 integration algorithm。

---

# Part 3：收尾、工程化与 Week8 验收

# Round 3：把 V1 整理成可复现的小项目

## 17. 最终产出

~~~text
Ubuntu：
    demos/component_demo.cpp
    README.md
    interview.md
    CMakeLists.txt

Windows：
    week8/day7/day7_note.md
~~~

Round3 不加核心 feature，只落实 Round2 发现的问题并保存证据。

你选择把 README/interview 的 canonical project 版本留到后面完成，这是允许的：它们本来就是 Round3 工作，不再反过来卡已经正确的 R1 component code。Windows 中的短 README 和 note 可以作为素材，但最终可执行 commands 应放到 Ubuntu project-root README.md。

---

## 18. component_demo 最终 contract

~~~text
configuration：
    4 workers
    bounded task/log queues
    100 deterministic tasks
    one unique record per task

lifecycle：
    submit
    pool shutdown/drain/join
    logger shutdown/drain/flush/join
    validate futures and final output

oracle：
    all values exact
    logger shutdown true
    expected IDs exactly once
    zero unexpected IDs
    any failure -> non-zero
~~~

你当前 R1 已满足这条 lifecycle 和 final oracle。logger.log 的 bool 没有单独保存，但 file exactly-once 加 shutdown status 已覆盖当前 normal integration scenario，不要求为了 Round3 重写 task return type。

可选增强是让 validate 捕获 future exception、检查 input.is_open，并打印具体 stage/ID；它改善 diagnostics，不是当前 correctness blocker。

---

## 19. CMake 与 smoke test

你的 CMake 已经完成：

~~~text
component_demo target
real async_logger link
Threads::Threads link
project include path
-Wall -Wextra
~~~

当前只剩两个明确 delta：

### 19.1 注册 smoke test

~~~cmake
add_test(NAME component_demo_smoke COMMAND component_demo)
set_tests_properties(component_demo_smoke PROPERTIES TIMEOUT 20)
~~~

**smoke test**：冒烟测试。它只确认主要组合路径能 build、run、validate、exit，不替代已有 unit tests。

component_demo 使用 component_demo.log。若以后让多个 demo tests 并行运行，要给它独立 output path；今天只有一个 smoke target 时不用先设计复杂 temporary-directory helper。

---

这是把一个**普通可执行程序**注册给 CTest，让 CTest 也能运行它、判断它有没有成功结束。

```cmake
add_test(NAME component_demo_smoke COMMAND component_demo)
```

意思是：

```text
当你执行 ctest 时，
除了 Google Test 生成的那些测试，
再额外运行一次 ./component_demo。
```

而：

```cmake
set_tests_properties(component_demo_smoke PROPERTIES TIMEOUT 20)
```

表示它最多运行 20 秒；超时通常说明卡死或死锁，CTest 判失败。

三者关系可以这样记：

```text
Google Test
-> C++ 测试框架
-> 提供 TEST、ASSERT_EQ、EXPECT_TRUE 等断言
-> 适合测一个函数、一个边界、一个模块行为

CTest
-> 测试运行与汇总工具
-> 负责运行已注册的测试程序，统计 PASS/FAIL/TIMEOUT
-> 不在乎测试程序内部是否使用 Google Test

smoke test
-> 一类测试目的
-> 用一个真实 executable 走一遍主要组合路径
-> 只确认“能启动、能完成、结果基本对、正常退出”
```

比如：

```text
AsyncLogger 的 Google Test：
-> 测 repeated shutdown
-> 测 concurrent logging
-> 测 /dev/full
-> 每条行为分别断言

component_demo smoke test：
-> 创建组件
-> 调几个 public API
-> 写 component_demo.log
-> 自己验证文件内容
-> return 0
```

CTest 对 smoke test 的判断很简单：

```text
component_demo 返回 0       -> PASS
返回非 0                    -> FAIL
20 秒还没结束               -> TIMEOUT / FAIL
```

它不替代 Google Test；它测的是“这些组件拼起来后，最主要的一条实际使用路径还活着吗”。

`component_demo.log` 那句话是在说：如果将来两个测试同时写同一个文件，可能互相覆盖、读到对方输出。所以并行时要给每个测试独立路径。今天只有一个 smoke test，暂时不用为了这个写一套临时目录工具。

### 19.2 把 component_demo 接入 ENABLE_TSAN

Codex 已用你的当前 CMake fresh configure：

~~~text
-DENABLE_TSAN=ON
-> async_logger static library is instrumented
-> component_demo is not linked with TSan runtime
-> link fails with undefined reference to __tsan_*
~~~

因此把 component_demo 加入现有 branch：

~~~cmake
if(ENABLE_TSAN)
    target_compile_options(component_demo PRIVATE
        -O1 -fsanitize=thread -fno-omit-frame-pointer
    )
    target_link_options(component_demo PRIVATE
        -fsanitize=thread
    )
endif()
~~~

这不是 source data race report，也不是性能测试。它是 target graph 不完整导致的 link-stage failure。

---

## 20. README 最小结构

~~~markdown
# ThreadPool + AsyncLogger

## Project Goal
## Architecture
## Ownership and Lifecycle
## Directory Layout
## Build and Run
## Tests and TSan
## Benchmark Method and Results
## Known Limitations
~~~

Architecture 图应对应真实 source：

~~~mermaid
flowchart LR
    U[main] --> TQ[bounded task queue]
    TQ --> W[pool workers]
    W --> R[future results]
    W --> LQ[bounded log queue]
    LQ --> LW[single writer]
    LW --> F[buffered file]
~~~

Build commands 从 project root 执行，不依赖 absolute path：

~~~bash
cmake -S . -B build-readme -DCMAKE_BUILD_TYPE=Debug
cmake --build build-readme -j
./build-readme/component_demo
cmake -E chdir build-readme ctest --output-on-failure --timeout 30
~~~

Benchmark 使用 Day6 的真实 environment、parameters、samples 和结论，不复制假想数字，也不重做不同 definition 的 comparison。

你的 Windows README 草稿已经写出 project purpose、components 和 build/run。迁移到 Ubuntu project root 后，再补 architecture/lifecycle、tests/TSan、Day6 benchmark summary 和 limitations；不要求在 R1 阶段完成。

Known Limitations 只写 source 真实边界：

~~~text
fixed workers
bounded blocking submission
no cancellation / timeout / work stealing
single file writer
no drop policy / rotation
flush is not fsync durability
one-owner sequential shutdown
~~~

---

## 21. interview.md 最小问题集

不写十五篇长作文，先说清八题：

1. ThreadPool 和 AsyncLogger 分别解决什么问题？
2. packaged_task、shared state、future 怎样传递 result/exception？
3. worker 为什么在 task queue lock 外执行 task？
4. 两个 components 各自的 graceful shutdown 是什么？
5. 为什么 integration 必须先停 pool，再停 logger？
6. 两个 bounded queues 怎样传播 backpressure？
7. tests、TSan、benchmark 分别证明什么，不能证明什么？
8. V1 最大 limitations 是什么，进入 Reactor 后哪些 blocking boundaries 要重新考虑？

答案可按：

~~~text
结论 -> 机制 -> 取舍 -> 证据 -> 限制
~~~

不必机械写五个标题，但必须能指回 source、test 或 benchmark。

---

## 22. Week8 最终验证

Normal：

~~~bash
cmake -S . -B build-final -DCMAKE_BUILD_TYPE=Debug
cmake --build build-final -j
cmake -E chdir build-final ctest --output-on-failure --timeout 30
~~~

TSan：

~~~bash
cmake -S . -B build-final-tsan \
    -DCMAKE_BUILD_TYPE=Debug \
    -DENABLE_TSAN=ON
cmake --build build-final-tsan -j
cmake -E chdir build-final-tsan ctest --output-on-failure --timeout 60
~~~

README smoke：严格复制 README commands，在 fresh build directory 执行。

Benchmark：若 Day6 对同一 canonical source 已保存完整 evidence，Day7 只 smoke-run README 中的 Release command，不重复大量 samples。

当前已经保存的 R1 evidence 可以直接写进 note：

~~~text
fresh Debug component_demo build：PASS，零 warning
normal run：PASS，exit 0
final output：100 lines，all unique counts == 1
fresh binary repeat：100/100 PASS
~~~

不要为了 Round3 再重复这 100 次；新增 CMake/TSan 接线后只验证新的 delta。

Git：

~~~bash
git status --short
git diff --check
git diff --stat
~~~

不要提交 build directories、temporary logs、binaries、passwords 或 private absolute paths。

---

## 23. day7_note.md

保留高信号内容即可：

~~~markdown
# Week8 Day7 Note

## 1. My R1 design
## 2. Ownership and shutdown flow
## 3. Problems found after Round2
## 4. Component demo result
## 5. Normal CTest and TSan
## 6. README fresh-build result
## 7. Benchmark summary reused from Day6
## 8. Current limitations
## 9. My project explanation
## 10. Questions
~~~

代码、README、interview 已表达的内容不重复抄。命令结果保留 summary，不堆终端截图。

---

## 24. 今日验收

验收看现有产出，不强制重写问答：

1. main、pool、tasks、logger 的 ownership/borrow 关系是什么？
2. 为什么先 pool shutdown/drain/join，再 logger shutdown/drain/join？
3. demo 怎样分别验证 future results 与 final log IDs？
4. 为什么你把 validate 放在两个 shutdown 之后？它对 cleanup 有什么好处？
5. README、tests、TSan、benchmark 各提供什么证据？

如果 code、README、interview 或 note 已清楚覆盖，就不另抄五遍。

---

## 25. Week8 通过标准

必须完成：

~~~text
使用 canonical components
component_demo 自验证，failure 返回 non-zero
task borrow lifetime 正确
pool producers 先结束，logger consumer 后结束
future results exact
final log IDs exactly once
fresh normal build/CTest 通过
TSan 对执行路径无 report
README commands fresh-run 成功
README benchmark 使用 Day6 真实数据与有限结论
interview 能解释设计、证据、限制
~~~

不阻塞 Week8：

~~~text
不重新手写所有旧 tests
不重复大量已保存 stress/benchmark
不加入 cancellation、work stealing、rotation、fsync
不要求 async 一定胜过 sync
不要求把验收题再抄进 note
~~~

真正阻塞项：

~~~text
logger 在 tasks 仍可能访问时关闭或销毁
accepted task/log 在 shutdown 中丢失
demo 发现错误仍 exit 0
README commands 不能执行
项目 claim 超出 evidence
~~~

---

## 26. 今天停止在哪里

你应能不看教程串出：

~~~text
main owns logger and pool
-> pool workers execute tasks
-> tasks borrow logger
-> logger writer owns file I/O

shutdown:
pool close/drain/join
-> no task can produce logs
-> logger close/drain/flush/join
-> validate futures and final file
~~~

并拿出：

~~~text
self-validating component demo
可执行 README
project-specific interview.md
诚实 limitations
~~~

到这里，Week8 才从“分别写过两个 components”升级为“能组合、验证、测量和解释它们”。

Week9 再进入 epoll/Reactor。

---

## 27. 今日压缩记忆

~~~text
Dependency：pool tasks -> AsyncLogger
Ownership：main owns both；tasks borrow logger
Construction：logger first，pool second
Shutdown：pool close/drain/join -> logger close/drain/flush/join
Oracle：future exact + log accepted + IDs exactly once + failure non-zero
README 负责复现；interview 负责解释
tests、TSan、benchmark 各自只支持有限 claim
~~~

---

## 28. 今日参考资料

- [CMake 3.16 command-line manual](https://cmake.org/cmake/help/v3.16/manual/cmake.1.html)
- [CTest 3.16 command-line manual](https://cmake.org/cmake/help/v3.16/manual/ctest.1.html)
- [GoogleTest Primer](https://google.github.io/googletest/primer.html)
- [Clang ThreadSanitizer documentation](https://clang.llvm.org/docs/ThreadSanitizer.html)

资料只用于核对工具入口与能力边界。Day7 的 ownership、shutdown、benchmark conclusion 和 project story 必须来自真实 source 与 evidence。
