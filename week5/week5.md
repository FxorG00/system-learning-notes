# Week5：OS 第一轮 + MIT 6.S081 核心机制

> 定位：Week4 已经从 Linux 用户态实际观察了 fd、system call、fork、exec、pipe、mmap 和 signal。Week5 不重复这些 API 的基本用法，而是进入它们背后的 OS 机制。  
> 本周主线：virtual memory / page table -> trap -> page fault / COW -> lock -> scheduler / context switch -> sleep / wakeup。  
> 本周仍然是第一轮：建立能解释、能画图、能用 Linux 小实验验证的机制模型，不逐行啃 xv6 内核源码，不强刷 lab。

---

## 1. 规划依据

### 1.1 当前真实起点

已经通过 Week4 出口验收：

```text
能解释 user mode / kernel mode 和 system call 第一层流程
知道 system call interface、一次调用请求、kernel handler 的区别
能画 fd -> open file description -> 文件对象
能写并验证 fork / wait / exec / pipe / dup2
能解释父子地址空间独立和 COW 第一层动机
能建立并释放 mmap mapping
知道 SIGINT / SIGTERM 的默认行为
会用 strace / lsof / ps 等工具观察程序
```

因此 Week5 不再安排：

```text
重新写 mycat / copyfile
重新写普通 fork / wait demo
重新练 pipe 端点关闭
重新背 mmap 参数
重新抄一遍 system call 包装函数流程
```

Week5 要回答的是：

```text
这些已经观察到的现象，OS 和硬件到底怎样共同实现？
```

### 1.2 结合你的学习特点

你推进较快，重复 API 使用价值低。本周采用：

```text
课程机制图
-> Linux/C++ 最小观察
-> 解释状态属于谁
-> 错误实验或工具证据
-> 少量验收问题
```

概念已经由 Week4 代码证明的，不要求重复默写。每日 note 只记录：

```text
当天新增机制
真正卡住的因果链
错误实验的现象、原因和修正
少量当天验收答案
```

---

## 2. 本周核心问题

```text
1. 每个进程为什么能拥有看似独立的地址空间？
2. CPU 中的虚拟地址怎样被翻译成物理地址？
3. page、page table、PTE、MMU、TLB 分别负责什么？
4. system call、exception、interrupt 为什么都可以进入 trap 流程？
5. ECALL 之后，CPU、trapframe 和内核入口分别发生了什么？
6. page fault 为什么不一定意味着程序出错？
7. COW 怎样利用 page fault 延迟复制？
8. 多个执行流同时修改共享状态为什么会产生 race condition？
9. lock 保护的是代码，还是共享状态与不变量？
10. process、thread、context switch、scheduler 是什么关系？
11. blocking IO 时执行流去了哪里，为什么不会一直占用 CPU？
12. sleep/wakeup 与 condition_variable 怎样避免 lost wakeup？
```

---

## 3. 本周目标深度

### 3.1 Virtual memory

本周结束时做到：

```text
能区分 virtual address、physical address、address space
知道地址翻译以 page 为基本粒度
能解释 page number + offset
知道 page table 存在内存中，MMU 查询它
知道 PTE 至少包含物理页信息和权限/状态位
知道 TLB 缓存近期地址翻译
能解释相同虚拟地址为何可映射到不同物理页
```

暂时不要求：

```text
手算复杂 Sv39 多级页表题
背 RISC-V 每一个 PTE bit
实现 xv6 page table lab
逐行阅读 kvminit / walk
深入 ASID、TLB shootdown 和大页优化
```

### 3.2 Trap / system call

本周结束时做到：

```text
能区分 system call、exception、interrupt
知道 trap 是控制流进入内核的总机制
能画 user -> ECALL -> trap entry -> handler -> user 的主路径
知道 CPU 必须保存足够状态，之后才能回到原用户指令流
知道 trapframe 用于保存用户寄存器状态
知道内核入口和返回路径都受内核控制
```

暂时不要求：

```text
背 trampoline.S 汇编
背全部 RISC-V CSR 寄存器
逐条解释 uservec / userret 汇编指令
实现完整 syscall/trap lab
```

### 3.3 Page fault / COW

本周结束时做到：

```text
知道 page fault 是一种 exception/trap
能说出 fault address、fault cause、faulting PC 的作用
知道内核可以修复映射后重新执行原指令
能解释 lazy allocation、zero fill、demand paging 第一层思想
能完整解释 COW 的共享、只读、写 fault、复制、重新映射
能解释 MAP_PRIVATE 写入为何不改原文件
```

暂时不要求：

```text
实现 xv6 lazy / COW / mmap lab
深入 Linux page cache 回写一致性
深入 swap、NUMA 和内存回收算法
```

### 3.4 Concurrency / scheduling

本周结束时做到：

```text
能区分 process 和 thread
知道 thread 至少有自己的执行状态与栈，并共享进程资源
能解释 race condition、critical section、mutex、deadlock
知道 context switch 保存旧执行流状态并恢复新执行流状态
知道 scheduler 决定谁获得 CPU
知道 timer interrupt 可让内核重新获得控制权
能解释 blocking、sleep、wakeup 和 lost wakeup
知道 condition_variable 必须配合 mutex 与 predicate
```

暂时不要求：

```text
实现调度器
深入 C++ memory model 和 lock-free
复杂 atomic memory order
完整线程池 / BlockingQueue
优先级反转、NUMA 调度和实时调度
```

---

## 4. 本周 6.S081 使用方式

主要资料：

- [Lec04 Page tables](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/lec04-page-tables-frans)
- [Lec06 Isolation & system call entry/exit](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/lec06-isolation-and-system-call-entry-exit-robert)
- [Lec08 Page faults](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/lec08-page-faults-frans)
- [Lec09 Interrupts](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/lec09-interrupts)
- [Lec10 Multiprocessors and locking](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/lec10-multiprocessors-and-locking)
- [Lec11 Thread switching](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/lec11-thread-switching-robert)
- [Lec13 Sleep & Wake up](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/lec13-sleep-and-wakeup-robert)

本周不要求“网页看一遍、视频再完整看一遍”。建议：

```text
先读当天 daily 中的顺课讲解，建立主干
-> 再读中文课程对应小节，补教授推导和课堂问答
-> 回到 Linux/C++ 实验验证
-> 用自己的图和一小段话收尾
```

daily 生成时仍必须实际阅读当天网页，并明确：

```text
从哪一小节开始
在哪一小节停止
课程原文讲了什么
Linux/C++ 补充了什么
哪些源码今天只看结构
哪些实现细节后置
```

本周 MIT 6.S081 占比可以提高到约 `35%~45%`，因为 OS 正是本周主线；但“理解一条机制链”仍比“刷完网页数量”重要。

---

## 5. 七天总览

| Day | OS 主线 | MIT 6.S081 范围 | Linux/C++ 观察或产出 |
|---|---|---|---|
| Day1 | address space、page、MMU、page table、TLB | Lec04：4.1~4.4 | `address_space_layout.cpp` + `/proc/<pid>/maps` |
| Day2 | trap 总图、ECALL 前后、CPU 保存状态 | Lec06：6.1~6.4 | `syscall_trap_path.md` + strace 对照 |
| Day3 | uservec/usertrap 到 usertrapret/userret | Lec06：6.5~6.8 | `trap_return_path.md`，不要求写汇编 |
| Day4 | page fault、lazy、COW、demand paging、mmap | Lec08：8.1~8.6 | `mmap_private_cow.cpp` |
| Day5 | race condition、critical section、mutex、deadlock | Lec10：10.1~10.5 | `race_counter.cpp` / `mutex_counter.cpp` |
| Day6 | process/thread、timer、context switch、scheduler | Lec09：9.2；Lec11：11.1~11.5 | `thread_identity.cpp` + `ps -L` |
| Day7 | blocking、sleep/wakeup、lost wakeup、condition variable | Lec13：13.1~13.5 | `blocking_wakeup.cpp` + Week5 出口复盘 |

---

# Day1：虚拟地址为什么不是物理地址

## 今日目标

```text
从 Week4 的 mmap mapping 接入完整 address space
理解 page 是地址翻译和权限管理的基本粒度
建立 CPU -> MMU -> page table -> physical memory 主路径
知道 TLB 为什么存在
```

## MIT 6.S081 范围

必读：

1. `4.1 课程内容简介`
2. `4.2 地址空间`
3. `4.3 页表`
4. `4.4 页表缓存 TLB`

听到这个程度：

```text
能解释虚拟内存同时服务隔离和地址抽象
能画 virtual page number + offset
知道不同进程使用不同 page table
知道 MMU 做翻译，page table 本身主要存放在内存中
知道 TLB 是地址翻译缓存，不是普通数据缓存
```

可选：

```text
4.5 Kernel Page Table 只看 xv6 内核地址空间长什么样
```

今天停止：

```text
不读 4.6~4.8 的函数实现
不手算完整 Sv39 页表
不做 page table lab
```

## 计划产出

```text
address_space_layout.cpp
address_space_note.md
一张：进程 virtual address -> MMU/TLB -> page table -> physical page
```

观察重点：

```text
代码区、全局区、heap、stack、mmap 区域的地址
/proc/<pid>/maps 中各区域的范围和权限
地址值是 virtual address，不尝试获取或猜测真实 physical address
```

---

# Day2：Trap 是 system call 的上位机制

## 今日目标

```text
区分 system call、exception、interrupt
理解 ECALL 触发 trap，而不是直接执行 mmap/read 的内核函数
理解进入内核前后必须保存哪些类别的状态
```

## MIT 6.S081 范围

必读：

1. `6.1 Trap 机制`
2. `6.2 Trap 代码执行流程`
3. `6.3 ECALL 指令之前的状态`
4. `6.4 ECALL 指令之后的状态`

听到这个程度：

```text
知道 trap 的三类常见来源
知道 stvec / sepc / scause / sstatus / stval 各自只解决哪类问题
知道 ECALL 后 CPU 只做有限的硬件动作，更多保存工作由软件入口完成
知道进入 kernel 后仍是当前进程的执行流在代表自己执行内核代码
```

今天不要求：

```text
背 CSR 名字和 bit
逐条读 trampoline.S
进入 uservec 汇编细节
```

## 计划产出

```text
syscall_trap_path.md
一张：用户代码 -> wrapper -> ECALL -> trap entry -> handler
使用 Week4 现有程序做一次 strace 对照，不重新写重复 API demo
```

---

# Day3：内核处理完后，怎样安全回到用户程序

## 今日目标

```text
补全 trap 的进入、处理和返回闭环
理解 trapframe 为什么存在
理解 trampoline 为什么需要特殊映射
区分 uservec/usertrap 与 usertrapret/userret 的方向
```

## MIT 6.S081 范围

必读：

1. `6.5 uservec 函数`
2. `6.6 usertrap 函数`
3. `6.7 usertrapret 函数`
4. `6.8 userret 函数`

听到这个程度：

```text
能按顺序说出四个阶段各自的责任
知道 trapframe 保存用户寄存器和返回所需状态
知道内核要恢复用户 page table、寄存器、PC 和 privilege mode
知道“返回用户态”不是 C++ 普通 return
```

允许略过：

```text
具体汇编寄存器搬运顺序
每条 csrrw / sret 指令编码
xv6 源码逐行记忆
```

## 计划产出

```text
trap_return_path.md
一张完整环：user -> trap -> kernel handler -> trap return -> user
一个对照表：普通函数调用 / system call / page fault / interrupt
```

Day3 是机制日，不为了凑文件强制写新的 C++ demo。

---

# Day4：Page fault 不只是“程序崩了”

## 今日目标

```text
理解 page fault 是一种可被内核处理的 exception
把 Day1 page table、Day3 trap 和 Week4 COW/mmap 连起来
观察 MAP_PRIVATE 可写 mapping 的 private COW 结果
```

## MIT 6.S081 范围

第一遍读完 Lec08 `8.1~8.6`：

```text
8.1 Page Fault Basics：重点
8.2 Lazy page allocation：理解按需分配
8.3 Zero Fill On Demand：理解零页/延迟实际分配思想
8.4 Copy On Write Fork：重点精读
8.5 Demand Paging：理解按需装入
8.6 Memory Mapped Files：重点精读
```

听到这个程度：

```text
知道 fault address、cause、faulting PC 为什么都需要
知道内核可能修复 page table 后重新执行原指令
能完整手推 COW：共享只读页 -> 写入 fault -> 复制 -> 重映射 -> 重试
能解释 MAP_PRIVATE 写入为什么只改变当前进程看到的内容
```

今天停止：

```text
不实现 xv6 lazy/COW/mmap lab
不深入 Linux page cache 和 writeback
不把所有 SIGSEGV 都误认为可恢复 COW
```

## 计划产出

```text
mmap_private_cow.cpp
page_fault_cow_note.md
```

核心验证：

```text
mapping 内修改后，当前进程看到新值
重新 read 原文件，内容保持不变
访问严格限制在 mapping 长度内
```

---

# Day5：多个执行流为什么需要锁

## 今日目标

```text
从 shared state 出发理解 race condition
理解 critical section 与 invariant
使用 std::mutex 修复一个受控的数据竞争实验
知道 deadlock 和锁性能的第一层问题
```

## MIT 6.S081 范围

必读：

1. `10.1 为什么要使用锁`
2. `10.2 锁如何避免 race condition`
3. `10.3 什么时候使用锁`
4. `10.4 锁的特性和死锁`
5. `10.5 锁与性能`

可选：

```text
10.6 只看 UART 中“锁保护什么状态”
10.7~10.8 spinlock 实现留到后续并发深化
```

听到这个程度：

```text
知道 lock 保护的是共享状态及其不变量，不只是某几行代码
能指出 read-modify-write 为什么可能被交错
能解释 mutex 的 lock/unlock 边界
能给出一个最小 deadlock 条件和避免思路
知道锁粒度影响并行度
```

## 计划产出

```text
race_counter.cpp
mutex_counter.cpp
race_lock_note.md
```

编译基线：

```bash
g++ -std=c++17 -Wall -Wextra -g -pthread ...
```

错误实验规则：

```text
race_counter 中的数据竞争属于 undefined behavior
一次“结果刚好正确”不能证明没有 race
允许用 ThreadSanitizer 作为证据
修复版优先使用 RAII 风格锁管理
```

Day5 daily 在你实现前不能直接给出完整修复代码。

---

# Day6：Thread、context switch 与 scheduler

## 今日目标

```text
区分 program / process / thread
理解 thread 的私有执行状态和共享进程资源
理解 context switch 保存谁、恢复谁
知道 scheduler 和 timer interrupt 怎样配合
```

## MIT 6.S081 范围

定向阅读：

```text
Lec09 9.2 Interrupt 硬件部分：
只理解 timer/device interrupt 可以异步让内核取得控制权

Lec11 11.1~11.5：
线程概述、xv6 调度、线程切换与示例
```

`11.6~11.9`：

```text
第一遍只顺着 yield -> sched -> switch -> scheduler 看函数责任
不背源码和汇编
```

Lec09 其余 UART/driver 内容后置到设备与网络阶段，不在 Week5 强行展开。

听到这个程度：

```text
能区分 user thread、kernel thread 和 process 第一层概念
知道 thread 需要 PC、registers、stack 等执行状态
知道 context switch 不是复制整个进程内存
知道 scheduler 选择 runnable 执行流
知道 preemption 需要内核重新获得 CPU 的机会
```

## 计划产出

```text
thread_identity.cpp
scheduler_context_switch_note.md
```

观察重点：

```text
同一进程内多个 thread 的 PID/TID
共享全局或 heap 数据
各自独立 stack 上局部变量
ps -L 或 /proc/<pid>/task
```

今天不实现调度器，不比较复杂调度算法。

---

# Day7：Blocking、sleep/wakeup 与 condition_variable

## 今日目标

```text
解释阻塞的执行流为什么不持续占用 CPU
理解 sleep/wakeup 的状态变化
理解 lost wakeup 为什么发生
把 xv6 sleep/wakeup 对应到 C++ condition_variable 第一层
完成 Week5 出口复盘
```

## MIT 6.S081 范围

必读：

1. `13.1 线程切换过程中锁的限制`
2. `13.2 Sleep & Wakeup 接口`
3. `13.3 Lost wakeup`
4. `13.4 如何避免 Lost wakeup`
5. `13.5 Pipe 中的 sleep 和 wakeup`

今天停止：

```text
13.6 exit
13.7 wait
13.8 kill
```

这些 API 已在 Week4 使用过，内核实现以后随进程生命周期专题再读，不在出口日增加负担。

听到这个程度：

```text
能画 RUNNING -> SLEEPING/BLOCKED -> RUNNABLE -> RUNNING
知道 condition/predicate 必须在锁保护下检查
知道 wait 必须允许“检查条件与进入等待”形成正确原子关系
知道 notify 不是把数据直接传给等待线程
知道醒来后仍要重新检查 predicate
```

## 计划产出

```text
blocking_wakeup.cpp
week5_note.md
Week5 总机制图
```

Day7 是小型组合练习日。daily 在你实现前只提供：

```text
需求
允许查阅的 thread/mutex/condition_variable 最小接口
状态关系
核心通过条件
少量测试
```

不会提前给完整线程函数、锁顺序或参考实现。

---

## 6. 本周建议目录

继续沿用当前实际代码目录，不为命名搬家：

```text
~/code/system-learning/cpp/week5/
├── day1/
│   ├── address_space_layout.cpp
│   └── address_space_note.md
├── day2/
│   └── syscall_trap_path.md
├── day3/
│   └── trap_return_path.md
├── day4/
│   ├── mmap_private_cow.cpp
│   └── page_fault_cow_note.md
├── day5/
│   ├── race_counter.cpp
│   ├── mutex_counter.cpp
│   └── race_lock_note.md
├── day6/
│   ├── thread_identity.cpp
│   └── scheduler_context_switch_note.md
└── day7/
    ├── blocking_wakeup.cpp
    └── week5_note.md
```

这只是预期产出。daily 生成时可根据你当天已经掌握的程度删减，不为了填目录制造重复 work。

---

## 7. 每日教程生成约定

每个 dayN.md 继续固定顺序：

```text
Part 1：前情提要与必要术语
Part 2：教程主体
Part 3：收尾、验证与验收
```

Week5 额外要求：

```text
1. 先定义状态属于 CPU、进程、线程、页表还是内核对象
2. 首次出现英文术语必须给原词、中文含义和实际作用
3. 课程讲解必须沿当天网页真实顺序，不只列链接
4. xv6 与 Linux/C++ 的共同思想和接口差异必须分开
5. 概念日不为了凑代码强制写重复 demo
6. 错误实验要明确 undefined behavior 或失败边界
7. 练习日不给可直接拼成答案的完整代码
8. 验收题只检查当天新增机制
```

默认编译：

```bash
g++ -std=c++17 -Wall -Wextra -g file.cpp -o program
```

使用 `std::thread` 的程序增加：

```bash
-pthread
```

涉及 data race 的受控错误实验按需增加 ThreadSanitizer，但 sanitizer 属于证据，不替代机制解释。

---

## 8. 本周工具要求

核心：

```text
/proc/<pid>/maps：观察进程 virtual address space
strace：观察 system call 边界与 blocking
ps -L：观察 process 中的 thread
ThreadSanitizer：观察 data race，按需使用
```

可选：

```text
gdb：观察 fault 或 thread
perf stat：只做 context-switches 第一层观察
/proc/<pid>/status：查看线程数和进程状态
```

不要求为了工具清单全部做一遍。每个工具必须回答一个真实问题，否则不占用学习时间。

---

## 9. 本周核心验收问题

只保留 10 个出口问题：

```text
1. virtual address 怎样经过 MMU/page table 变成 physical address？
2. 两个进程为什么可以拥有数值相同但彼此隔离的虚拟地址？
3. page table、PTE、TLB 分别解决什么问题？
4. system call、exception、interrupt 与 trap 是什么关系？
5. 从 ECALL 到返回 user mode，至少经历哪些阶段？
6. page fault 为什么可能被内核修复，而不一定终止进程？
7. COW 从共享页面到完成一次写入，完整状态变化是什么？
8. process、thread、context switch、scheduler 分别是什么？
9. race condition 为什么发生，mutex 应保护什么？
10. blocking、sleep/wakeup、lost wakeup、condition_variable 怎样连起来？
```

不要求在 Day7 重新长篇回答 Week4 的 fd、fork、pipe、exec 问题；用已有代码和笔记证明即可。

---

## 10. Week5 最终完成标准

### 核心通过

```text
能画虚拟地址翻译主图
能画 trap 进入与返回闭环
能解释 page fault / COW / MAP_PRIVATE 的关系
能区分 process 与 thread
能解释 context switch 和 scheduler 第一层
能从 shared state 说明 race，并用 mutex 修复
能解释 blocking、sleep/wakeup 和 lost wakeup
所有实际 C++ demo 使用规定 warning 选项零 warning
错误实验明确 UB 或失败原因，不拿一次输出当语言保证
day note 与实际代码、工具输出一致
```

### 工程增强，不阻塞 Week5

```text
perf 观察 context switches
ThreadSanitizer 保存完整报告
阅读 xv6 具体函数源码
完成某个 6.S081 lab
深入 spinlock 实现
```

### Week5 不通过的真正原因

```text
仍把虚拟地址当成物理地址
仍把 page fault 一律理解为程序崩溃
仍把 system call 当成普通函数直接跳进内核
无法区分进程和线程共享/私有状态
认为加了 mutex 就无需说明保护的不变量
condition_variable wait 没有 predicate，且无法解释 lost wakeup
```

---

## 11. 与后续主线的连接

Week5 不是孤立的 OS 理论周：

```text
page table / COW / mmap
-> 后续高性能内存管理、模型加载、共享内存

thread / context switch / scheduler
-> C++ 多线程、线程池、异步执行

race / mutex / condition_variable
-> BlockingQueue、ThreadPool、AsyncLogger

blocking / wakeup
-> socket blocking IO、epoll、Reactor
```

AI Infra 方向只做能力映射，不在本周提前开启 CUDA/PyTorch 支线。当前任务仍是把系统底座打牢。

---

## 12. 下周衔接

Week6 进入网络原理第一轮：

```text
TCP / UDP
socket / bind / listen / accept / connect
阻塞网络 IO
三次握手 / 四次挥手
TIME_WAIT / CLOSE_WAIT
HTTP / DNS 第一层
```

Week5 的直接复用关系：

```text
fd -> socket fd
blocking/sleep/wakeup -> 阻塞 recv/accept
thread/scheduler -> 多连接处理方式
mutex/condition_variable -> 后续线程池与任务队列
system call/trap -> 网络 API 进入内核
```

Week5 完成后再生成 Week6 规划，不提前实现 epoll / Reactor。
