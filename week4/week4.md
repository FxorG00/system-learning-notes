# Week4：Linux 系统编程第一轮 + 6.S081 正式穿插

> 定位：Week3 已经完成 STL 行为、RingBuffer V1 和 LRU Cache V1。Week4 开始离开“只在 C++ 语言内部思考”的阶段，进入 Linux 用户态程序与内核交互的真实环境。  
> 本周主线是 Linux 系统编程，6.S081 只负责解释系统调用、进程和文件描述符背后的 OS 机制，占比控制在 20% 以内。

---

## 本周 6.S081 资料和使用方式

本周配套资料：

- [MIT6.S081 中文文字版](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081)
- [MIT 6.S081 Fall 2020 官方课程表](https://pdos.csail.mit.edu/6.828/2020/schedule.html)

中文站把每个 Lecture 拆成了若干小节，Week4 不要求一次听完一整讲，而是让小节与当天 Linux 代码一一对应：

```text
先写 / 观察 Linux 用户态程序
-> 再读或听对应 lecture 小节
-> 用 OS 视角解释刚才发生的现象
```

课程编号从 Lec01 跳到 Lec03 不是路线缺失。官方 Lec02 是 C 和 gdb；你已经有 C/C++ 指针、编译和 gdb 基础，本周不重复安排。中文站也没有把 Lec02 列入正文。

还要区分：

```text
xv6：课程使用的教学操作系统
Linux：本周真正编写和运行代码的环境

接口思想可以对应
具体头文件、flag、函数细节和实现不能直接当成完全相同
```

本周听课标准不是“看完了”，而是：

```text
能把 lecture 中的一个概念指回当天代码
能用自己的话解释接口解决了什么问题
能区分已经观察到的 Linux 行为和暂未学习的内核实现
```

---

## 本周起点

已经通过：

```text
C++ 对象生命周期与 RAII
拷贝 / 移动 / 智能指针 / 异常安全
STL 容器行为和迭代器失效
vector / string / map / unordered_map
RingBuffer V1
LRU Cache V1
ASan / UBSan 初步使用
```

这些内容会直接迁移到 Linux 系统编程：

```text
RAII                 -> 自动 close 文件描述符
资源所有权           -> 谁负责关闭 fd
迭代器失效意识       -> fd 关闭后不能继续使用
RingBuffer           -> 后续网络收发缓冲区
unordered_map        -> 后续 fd 到 Connection 的映射
异常安全与错误路径   -> 系统调用失败后仍要正确释放资源
```

---

## 本周核心问题

```text
一个 C++ 程序怎样请求 Linux 内核读取文件？
为什么 open() 返回一个 int，却能代表一个打开的文件？
read() / write() 为什么不能想当然地认为一次就处理完？
fork() 后为什么会出现两个执行流？
pipe 为什么也是 fd？
dup2() 怎样让程序的输出进入文件或管道？
exec() 为什么会替换当前进程，而不是创建新进程？
mmap() 为什么能把文件映射进进程地址空间？
strace 怎样证明程序实际调用了哪些系统调用？
```

---

## 本周目标

```text
1. 建立用户态、内核态和系统调用的第一层直觉
2. 理解 file descriptor 是进程访问内核资源的句柄
3. 会使用 open / read / write / close 完成文件读写
4. 会检查返回值，并使用 errno / perror 定位失败原因
5. 理解 short read / short write，能写可靠的写入循环
6. 理解 stat / fstat / lseek 和文件偏移
7. 理解 dup / dup2、重定向和共享文件偏移
8. 理解 fork / wait / waitpid 的基本进程模型
9. 理解 exec 与 fork 的配合方式
10. 能用 pipe 完成父子进程通信，并正确关闭不用的 fd
11. 初步理解 mmap 和 signal，不在本周深挖
12. 会用 strace / lsof / ps / top 观察真实程序
13. 把 C++ RAII 用到 fd 管理，明确 owning fd 与 non-owning fd
```

---

## 本周不追求什么

```text
不进入 socket / TCP / UDP
不进入 select / poll / epoll
不讨论 Reactor
不深入非阻塞 IO
不深挖 signal 的异步信号安全规则
不深挖 mmap 缺页和页缓存实现
不逐行阅读 xv6 内核源码
不强刷完整 6.S081 lab
不提前进入多线程
不正式开启 15-445
```

Week4 的边界是：

```text
会调用 Linux API
能处理常见错误和边界
能通过工具观察系统调用
能解释用户程序与内核的第一层关系
```

---

## 学到什么程度

本周结束时，你应该能做到：

```text
1. 能区分 C++ 库函数和 Linux 系统调用
2. 能解释 fd 是进程文件描述符表中的索引，而不是文件本身
3. 能解释 open file description 和文件偏移的第一层关系
4. 能写 mycat 和 copyfile，并处理 read/write 返回值
5. 能解释 read 返回 0、-1、正数分别表示什么
6. 能解释 errno 只有在调用失败后才有意义
7. 能解释 lseek 为什么不适用于 pipe
8. 能解释 dup 后两个 fd 为什么可能共享文件偏移
9. 能解释 fork 返回两次以及父子进程如何区分
10. 能解释 exec 成功后为什么不会返回
11. 能解释 pipe 读端何时看到 EOF
12. 能解释为什么父子进程必须关闭不用的 pipe 端
13. 能用 wait/waitpid 回收子进程并读取退出状态
14. 能用 strace 验证 openat/read/write/close 等调用
15. 能写一个最小 RAII fd 封装，并禁止错误拷贝
```

---

## 工程映射

```text
fd：文件、pipe、socket、eventfd 等内核资源的统一访问入口
read/write：后续 TCP Server、日志、协议解析的基础
errno：系统项目错误传播和日志诊断的基础
dup2：shell 重定向、子进程标准输入输出重定向
pipe：进程间通信、shell pipeline、日志采集
fork/exec/wait：进程管理、任务执行器、shell 的基础
mmap：文件映射、共享内存、后续虚拟内存理解
strace：排查“程序到底卡在哪个系统调用”
lsof：观察进程打开了哪些 fd
ps/top/htop：观察进程状态和资源使用
```

本周逐渐建立这条思考链：

```text
需求
-> 选择系统调用
-> 明确 fd 所有权
-> 检查返回值
-> 处理错误和部分完成
-> 保证所有路径释放资源
-> 用 strace/lsof 验证真实行为
```

---

## 本周代码和笔记产出

Ubuntu 建议目录：

```bash
~/code/system-learning/linux/week4
```

建议结构：

```text
week4/
├── day1/
│   ├── mycat.cpp
│   └── syscall_trace_note.md
├── day2/
│   ├── copyfile.cpp
│   └── unique_fd.cpp
├── day3/
│   ├── stat_info.cpp
│   └── offset_dup.cpp
├── day4/
│   ├── redirect_stdout.cpp
│   └── fd_table_note.md
├── day5/
│   ├── fork_wait.cpp
│   └── fork_memory.cpp
├── day6/
│   ├── pipe_parent_child.cpp
│   └── fork_exec_pipe.cpp
└── day7/
    ├── mmap_basic.cpp
    └── day7_note.md
```

文件名会在生成每日教程时根据实际进度调整，不要求机械照搬。

所有 C++ demo 默认：

```bash
g++ -std=c++17 -Wall -Wextra -g 文件名.cpp -o 输出名
```

系统调用 demo 的验收标准：

```text
能编译
能运行
成功路径正确
失败路径可观察
每个系统调用都检查关键返回值
fd 在所有路径正确关闭
能解释输出
至少使用一次 strace 验证
```

---

# Day1：从普通 C++ 程序走进内核

## 今日目标

```text
理解用户态 / 内核态的分工
理解 system call 是用户程序请求内核服务的接口
建立 fd 的第一层模型
使用 open / read / write / close 编写 mycat
第一次使用 errno / perror 和 strace
```

## 计划产出

```text
day1/mycat.cpp
day1/day1_note.md
一份 mycat 的 strace 观察记录
```

## 实现边界

```text
接收一个文件路径
打开文件并输出到标准输出
循环读取，不能假设一次 read 读完整个文件
检查 open/read/write/close 的关键返回值
文件不存在时给出可理解的错误
不使用 std::ifstream 完成核心读取
```

## 验收重点

```text
fd 0 / 1 / 2 分别是什么
read 返回 0 表示什么
为什么系统调用失败通常返回 -1
errno 和 perror 分别承担什么角色
strace 中为什么可能看到 openat 而不是 open
```

## 6.S081 关联

**今日 Lecture：Lec01 Introduction and Examples（第一部分）**

必读 / 必听：

- [1.1 课程内容简介](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/lec01-introduction-and-examples/1.1-ke-cheng-jian-jie)：快速读，知道 OS 的目标包括抽象、复用、隔离、共享和性能。
- [1.2 操作系统结构](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/lec01-introduction-and-examples/1.2-cao-zuo-xi-tong-jie-gou)：重点读 user space、kernel、system call、file descriptor。
- [1.5 read, write, exit 系统调用](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/lec01-introduction-and-examples/1.5-some-systemcalls)：重点读 `read/write` 参数和返回值、fd 0/1、EOF 与错误。
- [1.6 open 系统调用](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/lec01-introduction-and-examples/1.6-open-xi-tong-tiao-yong)：重点读 `open` 如何得到 fd，以及每个进程有独立 fd 空间。

建议投入：

```text
中文文字版 40~60 分钟
有精力再看视频对应片段，不要求整段 80 分钟一次看完
```

听到这个程度即可：

```text
能画 user program -> system call interface -> kernel
能解释为什么 fd 是 handle，不是文件本身
能解释 read 为什么需要 buffer、最大长度和返回值
能把课程的 copy/open 例子映射到自己的 mycat
```

今天跳过：

```text
1.3 / 1.4 的课程管理性内容可快速浏览
fork / exec / wait / I/O redirect 留到 Day4~Day6
ECALL、trap 汇编和 xv6 内核代码留到后面
```

---

# Day2：可靠文件复制 + fd 的 RAII 所有权

## 今日目标

```text
写出 copyfile
理解 short read / short write
理解 EINTR 的第一层含义
把 Week1/Week2 的 RAII 迁移到 fd
区分 owning fd 和只是借用 fd
```

## 计划产出

```text
day2/copyfile.cpp
day2/unique_fd.cpp
day2/day2_note.md
```

## 实现边界

```text
从源文件复制到目标文件
目标文件不存在时创建，存在时截断
正确处理一次 write 没写完全部字节的情况
避免源文件和目标文件打开失败时泄漏 fd
最小 UniqueFd/FdGuard 只负责独占一个 fd
禁止拷贝，允许移动，析构时 close
```

## 验收重点

```text
为什么 write(buffer, n) 可能返回小于 n
为什么不能把 errno 当作全局错误状态随时读取
fd 包装类为什么应该是 move-only
移动后旧对象应该持有什么 fd 值
close 失败时析构函数为什么不能随意抛异常
```

## 6.S081 关联

**今日 Lecture：Lec03 OS Organization and System Calls（第一部分）**

必读 / 必听：

- [3.1 上一节课回顾](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/lec03-os-organization-and-system-calls/3.1-shang-jie-ke-hui-gu)：快速复习 system call interface。
- [3.2 操作系统隔离性](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/lec03-os-organization-and-system-calls/3.2-cao-zuo-xi-tong-ge-li-xing-isolation)：重点理解进程、文件等抽象为什么能支持隔离和资源复用。
- [3.3 操作系统防御性](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/lec03-os-organization-and-system-calls/3.3-cao-zuo-xi-tong-fang-yu-xing-defensive)：重点理解内核不能信任用户传入的 fd、地址和长度。

建议投入：`25~35` 分钟。

听到这个程度即可：

```text
能解释为什么坏参数应该让当前调用失败，而不是让内核崩溃
能把“内核防御性”联系到检查返回值和 errno
知道 file 是磁盘资源的抽象，进程是 CPU/内存资源的抽象
```

今天不听 `3.4~3.9`，硬件隔离和 xv6 启动留到 Day7 或 Week5。

## 不提前深挖

```text
不设计通用 POSIX 库
不做复杂错误类型体系
不使用异常包装所有系统调用
```

---

# Day3：文件元数据、偏移和共享打开状态

## 今日目标

```text
使用 stat / fstat 查看文件元数据
理解 lseek 和当前文件偏移
理解 fd 与内核打开文件状态不是一回事
观察 dup 后共享文件偏移的现象
```

## 计划产出

```text
day3/stat_info.cpp
day3/offset_dup.cpp
day3/day3_note.md
```

## 验收重点

```text
stat 和 fstat 的输入有什么区别
文件大小、类型、权限来自哪里
lseek 改变的是哪个状态
为什么两个 dup 出来的 fd 会影响同一个偏移
为什么 pipe 不能像普通文件一样 lseek
```

## 可选观察

```text
创建一个很小但逻辑文件大小很大的 sparse file
比较 ls -l 与 du 的结果
```

可选内容不影响当天通过。

## 6.S081 关联

**今日 Lecture：不新增整讲，定向复听 Lec01 `1.5 + 1.6`。**

今天只回看两个点：

```text
1.5：read 把 fd 看作连续字节流，并通过返回值推进读取
1.6：每个进程有自己的 fd 表；相同数字在不同进程中可代表不同资源
```

建议投入：`15~20` 分钟。课程只负责建立 fd 表的第一层直觉；`file offset`、`dup` 和 Linux open file description 由当天 Linux demo 补充，不要求从 xv6 文字里硬找标准答案。

通过标准：

```text
能区分 fd 数字、进程 fd 表项和被打开资源
能解释为什么连续 read 会从后续位置继续
能说明 dup 后共享偏移是今天在 Linux 上观察出的更精确行为
```

---

# Day4：dup / dup2 与重定向

## 今日目标

```text
理解进程文件描述符表
掌握 dup / dup2 的基本行为
把标准输出重定向到文件
理解 shell 的 > 为什么能工作
```

## 计划产出

```text
day4/redirect_stdout.cpp
day4/fd_table_note.md
```

## 验收重点

```text
STDOUT_FILENO 为什么等于 1
dup2(new_fd, STDOUT_FILENO) 改变了什么
重定向后 std::cout / printf / write 的去向
原 fd 什么时候应该关闭
fd、进程 fd 表项、open file description 三者怎样对应
```

## 工具观察

```text
用 lsof -p PID 观察进程打开的文件
用 strace 观察 dup2 / write / close
```

## 6.S081 关联

**今日 Lecture：继续 Lec01，学习 Shell 与 I/O Redirect。**

必读 / 必听：

- [1.7 Shell](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/lec01-introduction-and-examples/1.7-shell)：重点理解 shell 负责启动程序，以及 `>` 改变程序标准输出的去向。
- [1.10 I/O Redirect](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/lec01-introduction-and-examples/1.10-io-redirect)：重点理解重定向依赖 fd 约定，而应用程序本身不需要知道输出接到终端还是文件。

建议投入：`25~35` 分钟。

听到这个程度即可：

```text
能解释 shell 做重定向，ls/echo 仍然只向 fd 1 写
能解释为什么“先改 fd，再运行程序”能组合 Unix 工具
能把 xv6 的 close/open 重定向思路与 Linux dup2 做法联系起来
```

不要照抄 xv6 的具体常量和接口细节；当天实现以 Linux man page 为准。

---

# Day5：fork / wait / exit 与进程执行流

## 今日目标

```text
理解 process 的第一层模型
理解 fork 为什么在父子进程中分别返回
使用 wait / waitpid 回收子进程
读取子进程退出状态
理解 exit 与 _exit 的表面区别
```

## 计划产出

```text
day5/fork_wait.cpp
day5/fork_memory.cpp
day5/day5_note.md
```

## 验收重点

```text
fork 成功后有几个执行流
父子进程怎样通过返回值区分
父子进程修改普通变量为什么互不影响
父进程为什么要 wait
什么是 zombie process 的第一层直觉
fork 前未刷新输出缓冲区为什么可能造成重复输出
exit 和 _exit 对用户态缓冲区有什么不同
```

## 6.S081 关联

**今日 Lecture：Lec01 `fork`，并初看 `wait`。**

必读 / 必听：

- [1.8 fork 系统调用](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/lec01-introduction-and-examples/1.8-fork)：完整学习。
- [1.9 exec, wait 系统调用](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/lec01-introduction-and-examples/1.9-exec-and-wait-systemcall)：今天只重点看 `wait`、退出状态和父进程等待，`exec` 组合留到 Day6。

建议投入：`30~40` 分钟。

听到这个程度即可：

```text
能解释 fork 为什么在父子进程中返回不同值
能解释父子进程拥有独立地址空间，但继承 fd 关系
能解释执行顺序为什么不能靠输出先后猜
能解释父进程为什么调用 wait
```

课程为了建立直觉会说“复制内存”；Linux 实际常借助 COW 优化。今天只知道有这个优化，不展开页表和缺页机制。

---

# Day6：pipe + exec + 最小进程管道

## 今日目标

```text
理解 pipe 是内核中的字节流
理解 pipe 返回的两个 fd
完成父子进程单向通信
理解 exec 替换当前进程映像
组合 fork / dup2 / exec / wait
```

## 计划产出

```text
day6/pipe_parent_child.cpp
day6/fork_exec_pipe.cpp
day6/day6_note.md
```

## 练习日规则

Day6 属于独立组合练习。生成 day6.md 时，在你实现完成前只给：

```text
问题背景
公开需求
进程和 fd 的初始条件
成功 / 失败契约
必须覆盖的测试
```

不会提前给出 fork/pipe/dup2/exec 的标准组合代码。

## 验收重点

```text
pipefd[0] / pipefd[1] 分别负责什么
为什么 pipe 没有 writer 后 read 才返回 EOF
父子进程为什么都要关闭自己不用的端
exec 成功后原程序后面的代码为什么不执行
exec 失败后子进程应该怎样退出
父进程如何等待并判断子进程结果
```

## 6.S081 关联

**今日 Lecture：Lec01 `1.9` 第二遍，配合 `1.10`。**

必读 / 必听：

- [1.9 exec, wait 系统调用](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/lec01-introduction-and-examples/1.9-exec-and-wait-systemcall)：重点看 exec 替换当前进程、成功不返回、失败才返回，以及 shell 的 fork-exec-wait 模式。
- [1.10 I/O Redirect](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/lec01-introduction-and-examples/1.10-io-redirect)：复习子进程执行程序前先安排 fd 的思路。

建议投入：`25~35` 分钟。

听到这个程度即可：

```text
能画 shell -> fork -> child exec / parent wait
能解释 exec 没有创建新进程，而是替换当前进程映像
能解释 exec 失败后的代码为什么必须处理并退出
能解释 fd 继承与 dup2 为什么能在 exec 前后保持重定向
```

课程并不替代 pipe 的 Linux API 教程。`pipe()` 的两个端点、EOF 和关闭纪律仍以当天练习为主。

## 不提前深挖

```text
不实现完整 shell
不实现多级 pipeline
不处理 job control
不处理复杂 signal 转发
```

---

# Day7：mmap / signal 初步 + Week4 出口验收

## 今日目标

```text
理解 mmap 是把文件或匿名内存映射进虚拟地址空间
完成一个最小文件映射观察 demo
知道 munmap 的资源释放责任
建立 signal 是异步事件通知的第一层直觉
复盘本周 fd / file / process / pipe / exec 主线
检查是否可以进入 Week5 OS 第一轮
```

## 计划产出

```text
day7/mmap_basic.cpp
day7/day7_note.md
Week4 工具观察记录
```

## mmap 验收边界

```text
打开并获取文件大小
建立只读或可写映射
正确判断 mmap 失败
不越过映射长度访问
使用 munmap 解除映射
解释映射、fd 和文件之间的生命周期关系
```

## signal 学习边界

```text
知道 SIGINT / SIGTERM 的用途
会观察默认行为
知道 signal handler 不是普通函数调用
正式 sigaction 用法和异步信号安全留到后续
```

## 工具复盘

至少能独立完成：

```text
strace 跟踪一个自己的程序
lsof -p 查看一个进程的 fd
ps 查看父子进程关系
top 或 htop 观察进程
```

## 6.S081 关联

**今日 Lecture：Lec03 OS Organization and System Calls（第二部分）。**

必读 / 必听：

- [3.4 硬件对于强隔离的支持](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/lec03-os-organization-and-system-calls/3.4-ying-jian-dui-yu-qiang-ge-li-de-zhi-chi)：重点理解 privileged instruction 与 user/kernel mode。
- [3.5 User/Kernel mode 切换](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/lec03-os-organization-and-system-calls/3.5-user-kernel-mode-switch)：重点理解 ECALL 让控制权受控地进入内核，内核检查系统调用号和参数。
- [3.6 宏内核 vs 微内核](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/lec03-os-organization-and-system-calls/3.6-monolithic-kernel-vs-micro-kernel)：可选，只需知道 Linux/xv6 属于宏内核直觉，不背优缺点表。

建议投入：必读部分 `30~45` 分钟，可选部分不超过 `15` 分钟。

听到这个程度即可：

```text
能解释用户程序不能直接执行特权指令
能画 user mode -> ECALL/syscall -> kernel mode -> return
知道内核必须验证来自用户态的 fd、指针和长度
知道 ECALL 是 xv6/RISC-V 语境，Linux x86-64 的具体指令可能不同
```

今天不要听 Lec04 Page Tables、Lec06 完整 trap 流程、Lec08 Page Faults 或 Lec09 Interrupts。Day7 的 `mmap` 和 signal 只学习 Linux API 表面行为；相关内核机制进入 Week5 后再补。

---

## 6.S081 本周安排

本周正式穿插，但主次必须清楚：

```text
Linux 系统编程主线：80% 以上
6.S081：20% 以内
15-445：0%
```

本周逐日安排：

| Day | Lecture / 小节 | 目标程度 |
|---|---|---|
| Day1 | Lec01：1.1、1.2、1.5、1.6 | OS 总图、system call、fd、read/write/open |
| Day2 | Lec03：3.1、3.2、3.3 | isolation、defensive、为什么内核必须检查用户参数 |
| Day3 | Lec01：定向复听 1.5、1.6 | 把字节流和 per-process fd table 对应到 stat/lseek/dup 实验 |
| Day4 | Lec01：1.7、1.10 | Shell、标准 fd、I/O redirect |
| Day5 | Lec01：1.8，1.9 的 wait 部分 | fork 返回值、地址空间直觉、fd 继承、wait |
| Day6 | Lec01：1.9，复习 1.10 | exec、fork-exec-wait、exec 前安排 fd |
| Day7 | Lec03：3.4、3.5；3.6 可选 | 特权级、ECALL、受控进入内核；不展开 trap 实现 |

总量大约是 Lec01 的核心接口部分加 Lec03 的前半部分。中文文字版可以作为主材料，视频只看对应片段；本周不以“刷完两个完整 Lecture 视频”为目标。

本周不要求：

```text
完整 xv6 源码阅读
完整 util lab
完整 syscall lab
trap 汇编细节
RISC-V 特权级细节
Lec04 Page Tables
Lec06 完整 system call entry/exit 代码路径
Lec08 Page Faults / COW / mmap 内核实现
Lec09 Interrupts；signal 与硬件 interrupt 不是同一个概念
```

---

## 本周笔记原则

继续遵循你的实际习惯：

```text
已经掌握的 API 不重复抄
只记陌生机制、踩过的错误和关键状态变化
代码能说明的内容不用写成长篇总结
系统调用必须记录返回值语义和失败条件
遇到 bug 记录“现象 -> 原因 -> 修法 -> 验证”
```

建议本周至少画三张小图：

```text
进程 fd 表 -> open file description -> 文件
fork 前后父子进程与地址空间
pipe 两端在父子进程中的关闭关系
```

---

## 本周总验收问题

```text
1. 什么是系统调用？为什么普通程序不能直接随意访问硬件？
2. fd 是文件本身吗？它属于谁？
3. open/read/write/close 各自返回什么，失败怎样判断？
4. read 返回 0 与返回 -1 有什么区别？
5. 为什么 write 需要循环处理 short write？
6. errno 应该在什么时候读取？
7. stat、fstat 和 lseek 分别解决什么问题？
8. dup/dup2 复制的究竟是什么？
9. fork 为什么会“返回两次”？
10. 父进程不 wait 可能发生什么？
11. exec 成功后为什么不会返回？
12. pipe 为什么能用于父子进程通信？
13. pipe 的读端什么时候读到 EOF？
14. 为什么不用的 pipe 端必须尽早关闭？
15. mmap 和普通 read 在使用方式上有什么直觉区别？
16. RAII 应该怎样管理 fd？
17. strace、lsof、ps 分别能观察什么？
18. 用户程序通过系统调用进入内核，大致经历什么边界？
```

---

## Week4 最终完成标准

```text
mycat 能正确读取普通文件并处理不存在的文件
copyfile 能处理 short write，且错误路径不泄漏 fd
能用 RAII 管理独占 fd
stat/lseek/dup/dup2 demo 能解释输出
fork/wait demo 能正确回收子进程
pipe demo 不因未关闭端点而一直阻塞
fork/exec demo 能判断 exec 失败和子进程退出状态
mmap demo 能正确映射和解除映射
至少一次 strace 和一次 lsof 观察有笔记
代码使用 -std=c++17 -Wall -Wextra -g 且无警告
能回答本周总验收问题中的核心问题
确认进入 Week5：OS 第一轮 + 6.S081 核心 lecture
```

---

## 每日教程生成约定

后续生成 Week4 的 daily.md 时，继续严格使用：

```text
Part 1：前情提要与必要术语
Part 2：从一个明确问题出发的教程主体
Part 3：收尾、验收、笔记和下一天衔接
```

教学日：

```text
先直觉，再术语，再机制，再用小 demo 验证
代码必须能独立编译运行
不堆大段超出当前理解范围的实现
```

练习日：

```text
实现前只给需求、契约、边界、复杂度和测试
不提前给核心算法、成员设计或参考实现
完成后再读取 Ubuntu 真实代码，编译、运行、sanitizer 和 review
```

---

## 下周衔接

Week5 进入：

```text
用户态 / 内核态进一步解释
process / thread
context switch / scheduler
virtual memory / page table
fork / COW
blocking IO
6.S081 traps / page tables / scheduling / locks 核心 lecture
```

Week4 不要求把这些 OS 机制一次讲透，只需要先通过真实 Linux 程序获得可观察的接口经验。
