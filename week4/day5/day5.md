# Week4 Day5：`fork`、`wait`、退出状态与进程执行流

> 当前进度：Week4 Day1~Day4 已完成。Day4 已经知道一个进程拥有自己的 fd 表，也知道用户态输出缓冲区可能晚于 `write` 才真正写入。今天把视角从“一个进程怎样访问内核资源”推进到“一个进程怎样创建并等待另一个进程”。

---

# Part 1：前情提要与必要术语

## 1. 从 Day4 接到 Day5

Day4 的模型是：

```text
一个进程
  -> 自己的 fd 表
  -> fd 表项指向 open file description
  -> open file description 再关联文件、终端等内核对象
```

今天要问：

```text
如果这个进程调用 fork，
新出现的子进程拥有什么？
父进程和子进程从哪一行继续？
谁负责处理子进程结束后的状态？
```

需要同时记住两条线：

```text
普通变量：父子进程各自拥有独立地址空间，之后互不直接影响
已打开 fd：子进程继承 fd 表关系，父子的对应 fd 可指向同一 open file description
```

这不是矛盾。变量属于进程的用户地址空间；open file description 是内核维护的对象。

### Day4 留下的一张纠偏卡

不用重做 Day4，只把表述压准：

```text
STDIN_FILENO  = standard input  对应的文件描述符，通常为 0
STDOUT_FILENO = standard output 对应的文件描述符，通常为 1
STDERR_FILENO = standard error  对应的文件描述符，通常为 2

dup/dup2 得到新的 fd 表项；共享的是 open file description，
所以共享 file offset 和 file status flags。
```

`FILENO` 可以帮助你记成 “file number”，但代码里的准确对象仍叫 **file descriptor（文件描述符）**。

---

## 2. 今日目标与边界

今天完成：

```text
建立 process、PID、parent、child 的第一层模型
理解 fork 的一次调用、两个执行流和三种返回情况
验证父子进程的普通变量互不影响
理解 fd 继承与共享 open file description 的关系
使用 waitpid 等待并回收指定子进程
正确读取正常退出与信号终止状态
理解 zombie process 的第一层原因
理解 fork 前未刷新缓冲区为何可能造成重复输出
区分 return from main、exit 和 _exit 的当前层次语义
```

今天不进入：

```text
exec 的代码与进程映像替换
pipe 与父子进程通信
完整 shell
调度器和上下文切换实现
页表、缺页异常与 COW 内核细节
多线程程序调用 fork 的限制
signal handler 编程
```

`exec` 和 `pipe` 属于 Day6。今天提到它们时，只用于说明后续衔接。

---

## 3. 必要术语

### 3.1 process

**process：进程。**

可以先理解为：**正在运行的程序实例，以及它运行所需要的一组状态**。

状态包括但不限于：

```text
自己的虚拟地址空间
寄存器和当前执行位置
fd 表
PID、父进程关系、退出状态等内核记录
```

程序文件是磁盘上的代码；进程是这份程序的一次运行。相同程序可以同时对应多个进程。

### 3.2 PID 与 PPID

- `PID`：**Process ID**，进程标识号。
- `PPID`：**Parent Process ID**，父进程标识号。
- `getpid()`：取得当前进程 PID。
- `getppid()`：取得当前进程的父进程 PID。

`ID` 是 identifier 的常用缩写，即“标识符”。PID 只用来标识进程，不是内存地址。

### 3.3 parent process 与 child process

- `parent process`：父进程。
- `child process`：子进程。

今天的场景里，原进程调用 `fork()`；成功后，原来的执行流属于父进程，新出现的执行流属于子进程。

### 3.4 fork

`fork` 作名词可以表示“分叉”。这里的记忆画面很直接：

```text
fork 前：一条执行流
fork 后：父、子两条执行流，都从 fork 后面继续
```

`fork()` 的返回类型是 `pid_t`。成功时：

```text
父进程中：返回子进程 PID，是一个大于 0 的值
子进程中：返回 0
```

失败时：

```text
只在原进程中返回 -1
没有子进程被创建
errno 说明原因
```

所以“`fork` 返回两次”是成功时的现象，不是说一个函数在同一条执行流里普通地执行了两次 `return`。

### 3.5 wait 与 waitpid

- `wait`：等待任意一个符合条件的子进程发生状态变化。
- `waitpid`：wait for process ID，可指定等待哪个子进程。

今天优先使用：

```cpp
::waitpid(child_pid, &status, 0)
```

含义：阻塞等待 `child_pid` 指定的子进程结束，把编码后的状态写入 `status`。

### 3.6 exit status

**exit status：退出状态。**

它是父进程观察子进程结果的一种方式。习惯上：

```text
0     表示成功
非 0  表示某种失败或其他结果
```

`waitpid` 写入的 `status` 不是可以直接当退出码打印的普通整数。要先使用宏判断状态类型：

```text
WIFEXITED(status)    -> 是否正常退出
WEXITSTATUS(status)  -> 正常退出时的退出码
WIFSIGNALED(status)  -> 是否被信号终止
WTERMSIG(status)     -> 导致终止的信号编号
```

名称记忆：

```text
W  -> wait status 相关宏
IF -> if，判断是否属于某种情况
EXITED -> 已正常退出
EXITSTATUS -> 退出状态码
SIGNALED -> 被 signal 终止
TERMSIG -> terminating signal，终止信号
```

### 3.7 zombie process 与 reap

**zombie process：僵尸进程。**

子进程结束后，内核仍要暂时保留它的一小部分信息，例如 PID、退出状态和资源使用信息，等待父进程读取。此时它已经不再执行代码，却仍保留进程表记录，这种状态称为 zombie。

**reap：回收。** 原义是“收割”，进程语境中表示父进程通过 `wait`/`waitpid` 取走终止状态，使内核可以删除这条剩余记录。

第一层关系：

```text
子进程结束
  -> 内核保留终止状态
  -> 父进程尚未 wait：可能处于 zombie 状态
  -> 父进程 wait 成功：读取状态并完成回收
```

僵尸进程不是仍在运行，也不是继续占有完整用户内存；问题是未被回收的进程表记录会积累。

### 3.8 COW

`COW`：**Copy-On-Write，写时复制。**

从程序语义看，`fork` 后父子进程拥有各自独立的地址空间副本。Linux 通常不会在 `fork` 瞬间机械复制所有物理内存，而是先共享底层页面；当一方尝试写入时，再复制相关页面。

今天只记：

```text
COW 是实现 fork 语义的性能优化；
它不会让父子进程中的普通变量变成可互相修改的共享变量。
```

页表、缺页和 COW 的具体实现留到 Week5/后续 6.S081 内容。

### 3.9 `exit` 与 `_exit`

- `exit` / `std::exit`：做用户态正常终止处理，包括刷新 C `stdio` 输出流、执行已注册的退出处理等，然后终止进程。
- `_exit`：直接请求内核终止当前进程，不刷新继承来的用户态 `stdio` 缓冲区，也不运行 `atexit` 处理函数。
- `return` from `main`：先正常离开 `main`，因此 `main` 中自动对象会析构，然后进入正常程序终止流程。

当前最重要的区别：

```text
exit  会处理用户态 stdio 缓冲区
_exit 不处理用户态 stdio 缓冲区
```

两者终止进程后，内核都会处理该进程仍打开的 fd。`_exit` 前如果使用 `std::cout`/`printf` 输出，要么先显式刷新，要么直接使用 `write`；否则用户态缓冲区里的内容可能丢失。

---

## 4. MIT 6.S081 今日范围与听课任务

**Lecture：Lec01 Introduction and Examples。**

今天使用的课程原文：

1. [1.8 fork 系统调用](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/lec01-introduction-and-examples/1.8-fork)
2. [1.9 exec, wait 系统调用](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/lec01-introduction-and-examples/1.9-exec-and-wait-systemcall)

建议投入：`35~45` 分钟。先读下面的顺序讲解，再回到中文网页，课程原文会更容易跟上。

### 4.1 到底听到什么程度

#### 1.8：完整学习

沿着网页从头读到结尾，以下内容都要理解：

```text
课程中的最小 fork 示例怎样从一条执行流变成父子两条执行流
为什么父进程得到大于 0 的 child PID，子进程得到 0
为什么父子输出可能交织，输出顺序不能预测
为什么父子初始内存内容相同，却拥有独立地址空间
为什么子进程还能看到父进程原有的 fd
课程怎样从 fork 自然引出“Shell 还需要 exec”这个问题
```

#### 1.9：顺着课程读，但分主次

1.9 先讲 `exec`，再讲 `fork + exec + wait`。不能直接跳过前半段，否则会不知道父进程到底在等什么；但今天对 `exec` 只要求听懂：

```text
exec 用指定程序替换当前进程的指令和内存映像
exec 保留当前进程已经打开的 fd 关系
exec 成功通常不返回，失败才返回
```

今天真正需要掌握的是 1.9 后半段：

```text
为什么 Shell 自己不能直接 exec 用户命令
为什么常见结构是 parent fork -> child exec -> parent wait
wait 怎样让父进程等待子进程退出
exit status 怎样从子进程传给等待它的父进程
父子输出的先后为什么只是调度结果
为什么 wait 只能等待自己的子进程
有多个子进程时为什么需要多次 wait
```

读到页面最后的多个子进程提问即可。页面后半段提到的 Copy-On-Write 只记动机和名字，不学习页表、lazy copy 或实验实现。

今天不要求：

```text
背 exec 的 argv 指针数组写法
自己编写 exec 示例
实现 fork/exec/wait 组合
深入 COW 的内核实现
```

这些分别留到 Day6 和后续虚拟内存阶段。

---

### 4.2 顺着课程讲解 1.8：`fork` 系统调用

#### 4.2.1 课程先展示了什么

1.8 一开始直接展示一个最小 `fork` 程序。课程代码的结构可以抽象成：

```c
int pid = fork();

if (pid == 0) {
    // child
} else {
    // parent
}

exit(0);
```

这段结构真正要观察的不是语法，而是 `fork()` 前后进程数量的变化：

```text
调用 fork 前
只有原进程 P，正在执行 fork

fork 成功后
父进程 P：fork 返回 child PID，继续执行 if
子进程 C：fork 返回 0，也继续执行同一个 if
```

所以 `fork` 的奇怪之处是：**一次系统调用创建了第二条执行流，父子两边都从这次调用返回。**

#### 4.2.2 为什么父子拿到不同返回值

成功后，两个进程初始看到的代码和数据几乎相同。如果没有一个差异，程序便无法知道“我现在是父进程还是子进程”。

`fork` 故意制造这个分流条件：

```text
父进程：pid > 0，这个值还能告诉父进程新孩子是谁
子进程：pid == 0，只用于说明当前位于子进程分支
```

子进程自己的真实 PID 不是 `0`。在 Linux 中用 `getpid()` 获取；父进程看到的 `pid` 正好就是这个子进程 PID。

课程中的父进程打印 `parent`，子进程打印 `child`，就是利用这个返回值差异。

#### 4.2.3 课程输出为什么看起来交织在一起

课程在 QEMU 中运行示例后，父子输出出现了字符级交织。原文用这个现象强调：fork 后两个进程都能运行，模拟的多核环境甚至可能让它们同时推进。

执行流不是：

```text
固定先完整运行父进程
再完整运行子进程
```

而是：

```text
父进程可运行 ─┐
               ├─ 内核调度，先后与交替方式不固定
子进程可运行 ─┘
```

你的 Linux 程序可能每次都碰巧先显示 child，也可能先显示 parent；都不能由一次结果推出固定规律。课程看到字节交织，你的 `std::cout` 行未必发生相同现象，但“不保证顺序”这一机制相同。

#### 4.2.4 学生提问：父子进程是不是完全一样

课程回答的第一层意思是：在 xv6 的这个例子里，除了 `fork` 返回值外，父子初始的指令、数据和栈内容相同。

但是必须补上关键限定：

```text
内容初始相同 != 是同一块可互相修改的普通内存
```

父子各自拥有独立地址空间。可以画成：

```text
父进程地址空间                子进程地址空间
value = 10                    value = 10
虚拟地址 0x...                虚拟地址 0x...

父进程改 value = 20          子进程仍看到自己的 value = 10
```

Linux 常用 COW 高效实现这种语义，但那是实现优化，不改变“父子普通内存相互独立”的程序模型。

#### 4.2.5 课程接着强调 fd 表也会复制

1.8 不只讲内存。课程明确指出，父进程的文件描述符表也会复制给子进程。因此父进程在 `fork` 前打开的 fd，子进程在 `fork` 后仍能使用。

结合 Day3 的 Linux 模型，应理解为：

```text
父进程 fd 表项 --\
                  -> 同一个 open file description -> 文件/终端
子进程 fd 表项 --/
```

课程原文负责建立“子进程继承已打开 fd”的直觉；`open file description`、共享 offset 和 file status flags 是 Linux 手册层面的补充。

这里正好解释了 Day4 的重定向为什么能服务后续 Shell：如果一个进程先安排好 fd，再创建或替换执行程序，新执行环境仍能沿用这些 fd 关系。

#### 4.2.6 1.8 最后怎样引出 `exec`

课程最后回到 Shell：输入 `ls` 时，Shell 可以用 `fork` 创建子进程，但子进程此时仍在执行 Shell 的代码。

于是自然出现下一个问题：

```text
fork 只能创建“从当前进程分出来的子进程”，
怎样让这个孩子转而执行磁盘上的 ls 程序？
```

答案是 1.9 的 `exec`。这就是 1.8 到 1.9 的真实衔接，不是两个互不相关的 API。

---

### 4.3 顺着课程讲解 1.9：先认识 `exec`，再抓住 `wait`

#### 4.3.1 课程先用 `echo` 解释 `exec`

1.9 没有立刻讲 `wait`，而是先运行一个很小的 `exec` 示例。它让当前进程加载 `echo` 程序，并传入若干命令行参数。

课程想表达的状态变化是：

```text
exec 前：当前 PID 正在运行原程序
                     |
                   exec
                     |
exec 成功：仍是当前进程和当前 PID，但地址空间中的程序内容换成 echo
```

所以 `exec` **没有创建新进程**。它替换当前进程正在运行的程序映像。

今天只顺手记住两个课程结论：

1. `exec` 会保留已有 fd，因此新程序仍看到原来的 fd 0、1、2 等关系。
2. `exec` 成功后原程序没有旧地址空间可供返回，只有失败时才返回错误。

命令行参数数组末尾的空指针、Linux 中 `execve/execvp` 的选择和失败处理，Day6 再正式展开。

#### 4.3.2 为什么 Shell 不能自己直接 `exec`

假设 Shell 直接执行：

```text
Shell process -> exec(echo)
```

那么 Shell 自己就被 `echo` 替换了。`echo` 结束后，原来的 Shell 不会回来，也就无法继续显示提示符、接受下一条命令。

因此课程给出 Unix 中极常见的结构：

```text
Shell
  |
 fork
  |----------------------|
parent Shell             child
保留自己的程序           exec(echo)
wait(child)              变成 echo 并运行
  |                         |
取得退出状态 <----------- exit
继续显示提示符
```

这张图就是今天听 1.9 的主线。Day5 掌握父进程的 `wait` 一侧；Day6 再由你实现子进程的 `exec` 一侧。

#### 4.3.3 课程里的 `wait` 到底做什么

课程示例中，父进程执行 `wait(&status)`。它表达：

```text
当前没有已结束子进程 -> 父进程阻塞
某个子进程结束       -> wait 返回该子进程 PID，并取得退出状态
```

它让父进程可以等到前台命令完成，而不是立即继续打印新的 Shell 提示符。

课程把 `status` 描述为子进程向父进程传递一个整数结果的方式：子进程调用 `exit(code)`，等待它的父进程读取这个结果。Unix 惯例中 `0` 通常表示成功，非 `0` 表示失败。

#### 4.3.4 课程的 xv6 `status` 与 Linux 代码不要混用

课程示例是 xv6 接口。你今天写 Linux 代码时：

```cpp
int status = 0;
::waitpid(child_pid, &status, 0);
```

Linux 写入的 `status` 是编码后的等待状态，不能直接把它当退出码。必须：

```cpp
if (WIFEXITED(status)) {
    const int code = WEXITSTATUS(status);
}
```

如果子进程被信号终止，则使用 `WIFSIGNALED` 和 `WTERMSIG`。这部分是 Linux API 对课程直觉的精确补充。

#### 4.3.5 `exec` 失败为什么会走到后面的 `exit(1)`

课程先运行存在的 `echo`，此时 `exec` 成功，子进程原程序中 `exec` 后面的错误输出和 `exit(1)` 不会执行。

随后课程把目标改成不存在的程序：

```text
exec 找不到程序
-> 替换没有发生
-> exec 返回错误
-> 子进程仍在原来的代码中
-> 打印 exec failed
-> exit(1)
-> 父进程 wait 得到失败状态
```

今天只要能顺着这条错误路径讲清楚。Day6 才写实际 `exec` 失败处理代码。

#### 4.3.6 课程接着为什么谈到 COW

课程指出：如果 `fork` 复制大量内存后，子进程马上 `exec` 丢掉这些内容，机械复制会很浪费；后续课程和实验会用 Copy-On-Write fork 优化。

今天只形成这个因果链：

```text
fork 后常常立即 exec
-> 完整复制后马上丢弃会浪费
-> COW 延迟实际复制
-> 具体页表和 page fault 实现后学
```

不要现在扩展到页表位、缺页处理或 COW lab。

#### 4.3.7 为什么课程里先显示 `parent waiting`

课程运行时碰巧先显示了父进程的 waiting 信息，再出现子进程执行 `echo` 的输出。教授明确说明这只是一次调度结果，不是语言保证。

课程还给了一个合理解释：`exec` 需要访问文件系统、建立新程序内存等，可能比父进程打印一行更耗时。但“这次为什么碰巧如此”不等于“每次必须如此”。

唯一可以依赖的是：

```text
父进程的 wait 返回之后，所等待的子进程已经发生了对应状态变化；
wait 之前父子各自输出的顺序不固定。
```

#### 4.3.8 学生提问：子进程能不能 `wait` 父进程

课程答案是不能直接这样做。`wait` 的对象是**当前进程自己的子进程**。

如果示例中的 child 自己没有创建孩子，却调用 `wait`：

```text
当前进程没有可等待的 child
-> wait 返回 -1
```

所以“父子有亲属关系”不表示可以沿任意方向使用 `wait`。等待关系是 parent 等 child。

#### 4.3.9 学生提问：复制进程内存到底是什么意思

课程再次从机器视角解释：编译后的 C 程序最终是内存中的机器指令和数据，变量、栈内容等也都表现为内存中的字节。`fork` 建立子进程时，让子进程拥有与父进程初始内容相同的地址空间，不需要程序员在子进程里重新声明一遍变量。

对今天的 `fork_memory.cpp` 来说：

```text
fork 前定义一次 value = 10
-> child 初始自然看到 value = 10
-> parent 和 child 随后各自修改自己的副本
```

#### 4.3.10 学生提问：多个子进程只调用一次 `wait` 够吗

不够。课程最后说明：一次 `wait` 只回收一个已经结束的子进程，并返回该子进程 PID。

```text
fork 两次，创建两个 child
-> 想等待两者全部结束
-> 通常需要成功 wait 两次
```

你今天只有一个子进程，因此使用 `waitpid(child_pid, ...)` 精确等待它。

---

### 4.4 课程与今日 Linux/C++ 主线对照

| 课程中的内容 | 今日 Linux/C++ 对应 | 今天掌握程度 |
|---|---|---|
| xv6 `fork()` | Linux `::fork()` | 会写返回值三分支并处理失败 |
| 父子独立内存 | `fork_memory.cpp` | 用变量和虚拟地址验证 |
| fd 表复制 | fd 表项引用同一 open file description | 能解释继承与共享 offset |
| xv6 `wait(&status)` | `::waitpid(pid, &status, 0)` | 会指定 child、处理 EINTR |
| `exit(code)` 传递结果 | `WIFEXITED` + `WEXITSTATUS` | 不直接打印编码后的 status |
| parent waiting 输出 | 父子调度顺序不固定 | 不用一次输出推断固定顺序 |
| fork 后 child exec | Day6 的组合练习 | 今天只会画流程，不实现 |
| COW fork | 后续虚拟内存与 6.S081 lab | 今天只记动机和语义边界 |

Linux 的准确接口语义以 [`fork(2)`](https://man7.org/linux/man-pages/man2/fork.2.html)、[`wait(2)` / `waitpid(2)`](https://man7.org/linux/man-pages/man2/waitpid.2.html) 和 [`_exit`](https://pubs.opengroup.org/onlinepubs/9799919799/functions/_exit.html) 为准。

完成课程部分后，你应该能沿课程顺序讲出：

```text
最小 fork 示例为什么产生 parent 和 child 两份输出
为什么两边用不同返回值进入不同分支
为什么父子输出可能交织
父子内存和 fd 继承分别是什么关系
为什么 Shell 需要 fork 后让 child exec，而不是自己 exec
parent 的 wait 等待什么、得到什么
exec 失败时为什么会走到 exit(1)
为什么 wait 不能用来等父进程
为什么 N 个 child 通常需要 N 次成功 wait
为什么 COW 能优化 fork 后立刻 exec 的场景
```

---

# Part 2：教程主体

# 教程开始：从“一次 `fork()`，为什么后面的代码执行了两遍？”出发

## 5. 先手推最小执行流

先不看完整代码，只看结构：

```text
执行 A
pid = fork()
执行 B
```

`fork` 成功后的执行流是：

```text
原来只有父进程：执行 A
                    |
                  fork
                 /    \
父进程：pid > 0，执行 B   子进程：pid == 0，执行 B
```

注意四点：

1. `A` 在 `fork` 前，程序语句只执行过一次。
2. 父、子都从 `fork` 返回处继续，不会从 `main` 第一行重新开始。
3. 父进程中的 `pid` 和子进程中的 `pid` 值不同。
4. `B` 存在两条执行流，因此可能执行两次。

失败时没有分叉：原进程拿到 `-1`，必须处理错误。

---

## 6. 第一个完整程序：创建、区分、等待、读取状态

文件：`fork_wait.cpp`

### 6.1 整体功能

这个程序负责：

```text
创建一个子进程
父子通过 fork 返回值进入不同分支
子进程用退出码 7 结束
父进程用 waitpid 等待指定子进程
父进程正确解析子进程的终止方式和退出码
```

### 6.2 完整代码

```cpp
#include <cerrno>
#include <cstdio>
#include <iostream>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

// 等待指定子进程。
// 输入：child_pid 是要等待的子进程 PID；status 指向接收终止状态的 int。
// 输出：成功返回被回收子进程的 PID，失败返回 -1。
// waitpid 被信号打断并设置 errno=EINTR 时重试，其他错误交给调用者处理。
pid_t waitpid_retry(pid_t child_pid, int* status) {
    while (true) {
        const pid_t result = ::waitpid(child_pid, status, 0);
        if (result == -1 && errno == EINTR) {
            continue;
        }
        return result;
    }
}

int main() {
    // fork 会复制当前用户态缓冲区的状态；先刷新，避免这行被父子重复刷新。
    std::cout << "before fork: pid=" << ::getpid() << '\n' << std::flush;

    const pid_t child_pid = ::fork();
    if (child_pid == -1) {
        // fork 失败时没有子进程，errno 记录失败原因。
        std::perror("fork");
        return 1;
    }

    if (child_pid == 0) {
        // 只有子进程进入这里。子进程看到 fork 的返回值为 0，
        // 但它自己的真实 PID 要通过 getpid() 获取。
        std::cout << "child: pid=" << ::getpid()
                  << ", ppid=" << ::getppid()
                  << ", fork returned 0\n";
        return 7;
    }

    // 只有父进程进入这里。父进程拿到的是新子进程的 PID。
    std::cout << "parent: pid=" << ::getpid()
              << ", child_pid=" << child_pid
              << ", waiting...\n";

    int status = 0;
    const pid_t waited_pid = waitpid_retry(child_pid, &status);
    if (waited_pid == -1) {
        std::perror("waitpid");
        return 1;
    }

    // status 是编码后的等待状态，必须先判断终止类型，再取对应字段。
    if (WIFEXITED(status)) {
        std::cout << "parent: child " << waited_pid
                  << " exited normally, exit status="
                  << WEXITSTATUS(status) << '\n';
    } else if (WIFSIGNALED(status)) {
        std::cout << "parent: child " << waited_pid
                  << " was terminated by signal "
                  << WTERMSIG(status) << '\n';
    } else {
        std::cout << "parent: child changed state in another way\n";
    }

    return 0;
}
```

### 6.3 每个函数和关键参数

#### `fork()`

```cpp
pid_t fork();
```

无显式参数。返回值承担“错误判断 + 父子分流”两项职责：

```text
-1  -> 创建失败，只存在原进程
 0  -> 当前正在子进程中
>0  -> 当前正在父进程中，值是子进程 PID
```

#### `waitpid(child_pid, &status, 0)`

```text
child_pid -> 等待这个指定子进程
&status   -> 输出参数，内核把编码后的子进程状态写到这里
0         -> 今天使用阻塞等待，不启用 WNOHANG 等选项
返回值    -> 成功时是发生状态变化的子进程 PID，失败是 -1
```

`status` 不是资源所有权转移。父进程只是提供一块 `int` 内存让系统调用写入结果。

#### `waitpid_retry`

这是我们自己的辅助函数。`waitpid` 可能因为进程收到信号而返回 `-1`，并令 `errno == EINTR`。这表示“等待被打断”，不等于子进程失败，所以重试；其他错误返回给 `main`，由 `perror` 报告。

#### `WIFEXITED` 与 `WEXITSTATUS`

必须按顺序使用：

```cpp
if (WIFEXITED(status)) {
    const int code = WEXITSTATUS(status);
}
```

只有确定子进程正常退出后，`WEXITSTATUS(status)` 才有正确语义。

### 6.4 哪些输出顺序有保证

有保证：

```text
before fork 一定在 fork 前输出
父进程 waitpid 成功后的状态行一定在子进程已经终止之后
```

没有保证：

```text
child 行和 parent waiting 行谁先出现
```

父进程也可能先运行到 `waitpid`，然后被阻塞；子进程结束后父进程再继续。这正是 wait 的作用，不是错误。

---

## 7. 第二个完整程序：父子变量为什么互不影响

文件：`fork_memory.cpp`

### 7.1 整体功能

这个程序让父子进程分别观察并修改 `value`：

```text
fork 前 value = 10
子进程把自己的 value 改为 99
父进程等子进程结束后再打印自己的 value
预期父进程仍看到 10
```

它验证的是地址空间隔离，不是父子通信。

### 7.2 完整代码

```cpp
#include <cerrno>
#include <cstdio>
#include <iostream>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

// 等待指定子进程结束。
// 输入：child_pid 是目标子进程；没有输出参数，因为本实验不读取退出码。
// 输出：成功返回 true；除 EINTR 外的错误返回 false，并保留 errno 供 perror 使用。
bool wait_for_child(pid_t child_pid) {
    while (true) {
        const pid_t result = ::waitpid(child_pid, nullptr, 0);
        if (result == child_pid) {
            return true;
        }
        if (result == -1 && errno == EINTR) {
            continue;
        }
        return false;
    }
}

int main() {
    int value = 10;

    std::cout << "before fork: pid=" << ::getpid()
              << ", value=" << value
              << ", address=" << static_cast<const void*>(&value)
              << '\n' << std::flush;

    const pid_t child_pid = ::fork();
    if (child_pid == -1) {
        std::perror("fork");
        return 1;
    }

    if (child_pid == 0) {
        value = 99;
        std::cout << "child: pid=" << ::getpid()
                  << ", value=" << value
                  << ", address=" << static_cast<const void*>(&value)
                  << '\n' << std::flush;

        // std::flush 已把这次输出送出用户态缓冲区。
        // _exit 直接终止子进程，不执行普通的 C/C++ 用户态退出清理。
        ::_exit(0);
    }

    if (!wait_for_child(child_pid)) {
        std::perror("waitpid");
        return 1;
    }

    std::cout << "parent after wait: pid=" << ::getpid()
              << ", value=" << value
              << ", address=" << static_cast<const void*>(&value)
              << '\n';

    return 0;
}
```

### 7.3 为什么地址可能一样，变量却不是同一份

父子输出的 `&value` 很可能显示相同数值，但这个数值是**虚拟地址**。

```text
父进程虚拟地址 0x... -> 父进程地址空间里的 value
子进程虚拟地址 0x... -> 子进程地址空间里的 value
```

相同虚拟地址出现在不同进程中，不等于指向同一个可互相修改的普通变量。地址必须和“属于哪个进程的地址空间”一起理解。

### 7.4 为什么这里使用 `_exit(0)`

这个子进程已经显式 `std::flush`，然后用 `_exit(0)` 直接结束。这样顺便观察 `_exit`：

```text
它不会替你刷新 C/C++ 用户态输出缓冲区
它不会进行普通 C++ 栈展开和局部对象析构
它会让内核终止进程并留下可供父进程 wait 的状态
```

这不表示所有子进程都应该盲目使用 `_exit`。今天只是建立边界；Day6 在 `fork` 后准备 `exec` 的子进程错误路径中会再次遇到它。

---

## 8. `fork` 后 fd 到底发生了什么

结合 Day3/Day4 的模型：

```text
fork 前
父进程 fd 3 -> open file description A -> file

fork 后
父进程 fd 3 --\
                -> open file description A -> file
子进程 fd 3 --/
```

因此：

```text
fd 数字分别存在于父、子各自的 fd 表中
但对应表项引用同一个 open file description
所以普通文件的当前 offset 可以共享
一方 close 自己的 fd，不会直接删掉另一方 fd 表中的表项
只有相关引用都释放后，内核对象才不再被这些 fd 引用
```

“地址空间独立”不能推导出“所有状态都独立”。先问状态属于用户地址空间，还是属于被多个 fd 引用的内核对象。

今天不再写一个共享 offset demo，因为 Day3 的 `dup` 已经验证过同一个 open file description 共享 offset；这里只把相同模型扩展到父子进程。

---

## 9. 为什么 `fork` 前未刷新输出可能重复

Day4 已经知道：

```text
std::cout / printf 写入的内容
不一定立刻通过 write 进入内核
它可能暂存在进程的用户态缓冲区
```

如果 `fork` 发生时缓冲区里还有文字，这份用户态内存状态也会出现在子进程的初始地址空间中：

```text
fork 前：父进程缓冲区中有 "hello"
fork 后：父缓冲区有 "hello"，子缓冲区也有 "hello"
父子随后都走正常 exit：两边各刷新一次
结果：文件里可能出现两份 "hello"
```

终端上有换行时常常已经行缓冲刷新，所以不一定容易观察。重定向到文件后通常更明显。

### 9.1 独立观察实验

在 `fork_wait.cpp` 中临时把：

```cpp
std::cout << "before fork: pid=" << ::getpid() << '\n' << std::flush;
```

改成不带换行、不刷新：

```cpp
std::cout << "buffered before fork";
```

并保证父子都从 `main` 使用 `return` 正常退出，然后运行：

```bash
./fork_wait > buffered.txt
cat buffered.txt
```

观察完恢复原代码。你要解释的是“缓冲区内存被复制后，两边分别刷新”，而不是“`fork` 重新执行了 fork 前的输出语句”。输出语句只执行了一次。

---

## 10. `return`、`exit`、`_exit` 当前层次对照

这三种写法最后都会让进程终止，区别在于：**终止前，用户态的收尾工作做到了哪一步。**

先把表格中的三个词讲清楚：

```text
main 的局部对象析构：
main 里创建的 C++ 局部对象，在正常离开作用域时会调用析构函数。

用户态 stdio 刷新：
printf 的文字可能暂存在 C 标准库的用户态缓冲区中；
刷新后才会通过 write 之类的系统调用真正交给内核。

atexit 处理：
std::atexit 可以提前登记一个函数，程序正常终止时调用它做收尾。
```

再看表格：

| 写法 | `main` 中局部对象正常析构 | 用户态 stdio 刷新 | `atexit` 回调 | 进程终止 |
|---|---:|---:|---:|---:|
| `return code;` from `main` | 是 | 是 | 是 | 是 |
| `std::exit(code);` | 否，不正常退出当前调用栈 | 是 | 是 | 是 |
| `::_exit(code);` | 否 | 否 | 否 | 是 |

当前记忆方式：

```text
return from main：沿正常路径离开 main，再终止程序
std::exit：不再沿调用栈一层层返回，但仍执行进程级的用户态收尾
_exit：跳过上述用户态收尾，直接请求内核终止当前进程
```

### 10.1 先看一个具体调用场景

假设当前执行到：

```text
main
  -> 创建局部对象 local
  -> printf 写了一段还没刷新的文字
  -> 登记一个 atexit 回调
  -> 选择一种方式结束
```

三条路径分别是：

```text
return from main
  -> 正常离开 main
  -> local 析构
  -> atexit 回调
  -> 刷新 stdio
  -> 进程终止

std::exit
  -> 不再正常离开 main
  -> local 不析构
  -> atexit 回调
  -> 刷新 stdio
  -> 进程终止

_exit
  -> local 不析构
  -> 不调用 atexit
  -> 不刷新 stdio
  -> 内核直接终止进程
```

这里先不用死记 `atexit` 与 stdio 刷新的内部先后；今天需要记住的是它们是否发生。

### 10.2 可运行实验：亲眼看三种退出方式

可选文件：`exit_demo.cpp`

#### 整体功能

程序布置三种可观察状态：

```text
Tracer local        -> 析构时向 stderr 报告
atexit_handler      -> 被调用时向 stderr 报告
printf              -> 向 stdout 写入一段不主动刷新的文字
```

然后根据参数选择 `return`、`std::exit` 或 `::_exit`。这样一次实验就能观察析构、回调和缓冲区刷新。

#### 完整代码

```cpp
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <unistd.h>

// 把观察信息写到 stderr 并立即刷新。
// 输入：message 是以 '\0' 结尾的说明文字；无返回值，也不转移资源所有权。
// 这里显式刷新，是为了让实验只考察 stdout 缓冲区，而不受 stderr 缓冲影响。
void report(const char* message) {
    std::fputs(message, stderr);
    std::fflush(stderr);
}

class Tracer {
public:
    ~Tracer() {
        report("local destructor ran\n");
    }
};

// 这是交给 std::atexit 登记的进程退出回调。
// 正常终止流程会调用它，::_exit 不会调用它。
void at_exit_handler() {
    report("atexit handler ran\n");
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::fprintf(stderr, "usage: %s return|exit|_exit\n", argv[0]);
        return 2;
    }

    Tracer local;

    if (std::atexit(at_exit_handler) != 0) {
        std::fprintf(stderr, "atexit registration failed\n");
        return 1;
    }

    // 没有换行，也没有 fflush(stdout)。重定向到文件后，
    // 这段文字通常仍留在 C stdio 的用户态缓冲区中。
    std::printf("buffered stdout");

    if (std::strcmp(argv[1], "return") == 0) {
        return 11;
    }

    if (std::strcmp(argv[1], "exit") == 0) {
        std::exit(22);
    }

    if (std::strcmp(argv[1], "_exit") == 0) {
        ::_exit(33);
    }

    std::fprintf(stderr, "unknown mode: %s\n", argv[1]);
    return 2;
}
```

代码中的 `local` 看起来“没有被使用”，但它的用途就是观察生命周期：正常离开 `main` 时，析构函数会留下 `local destructor ran`。

### 10.3 编译和分别运行

```bash
g++ -std=c++17 -Wall -Wextra -g exit_demo.cpp -o exit_demo

./exit_demo return > return.txt
echo $?
cat return.txt

./exit_demo exit > exit.txt
echo $?
cat exit.txt

./exit_demo _exit > _exit.txt
echo $?
cat _exit.txt
```

`echo $?` 必须紧跟在对应程序之后，它显示上一条命令的退出码。

### 10.4 预期观察

#### `return` 模式

终端上的 `stderr`：

```text
local destructor ran
atexit handler ran
```

退出码是 `11`，`return.txt` 中有：

```text
buffered stdout
```

原因：正常离开 `main`，所以局部对象析构；随后正常终止流程调用 `atexit` 回调并刷新 stdio。

#### `exit` 模式

终端上的 `stderr` 只有：

```text
atexit handler ran
```

退出码是 `22`，`exit.txt` 中仍有：

```text
buffered stdout
```

原因：`std::exit` 不会正常返回并展开当前调用栈，所以 `local` 没有析构；但它仍执行 `atexit` 回调并刷新 stdio。

#### `_exit` 模式

终端上不会出现析构或 `atexit` 的报告。退出码是 `33`，`_exit.txt` 应为空。

原因：`::_exit` 直接请求内核终止进程。那段 `printf` 文字仍在 C 标准库管理的用户态内存中，内核并不知道那里还有待写出的字节。

### 10.5 最容易混淆的一点：关闭 fd 不等于刷新 stdio

`::_exit` 终止进程时，内核会关闭这个进程仍打开的 fd。但是：

```text
printf 缓冲区：属于用户态 C 标准库
fd：属于进程访问内核对象的编号
```

内核关闭 fd 时，只能处理它知道的内核状态；它不会替 C 标准库读取用户态缓冲区，再猜测哪些字节本来准备写入。因此：

```text
先 fflush(stdout)，再 _exit -> 已刷新的文字可以留下
直接 _exit              -> 尚在用户态缓冲区的文字会丢失
```

不要把“内核最终关闭 fd”与“用户态输出缓冲区得到刷新”混成一件事。`close(fd)` 管的是内核 fd 引用；`fflush`/流刷新管的是用户态尚未提交的数据。

---

## 11. `wait`、`waitpid` 和 zombie 的完整因果链

### 11.1 `waitpid` 不负责让子进程退出

子进程按自己的代码执行并终止。父进程的 `waitpid` 负责：

```text
若子进程尚未结束：父进程阻塞等待
若子进程已经结束：立刻取得其终止状态
成功取得状态后：完成回收
```

### 11.2 父进程暂时不 wait 会怎样

如果子进程先结束、父进程仍在运行且尚未 wait，子进程可能显示为 `Z` 状态。可以做一个短暂观察：

1. 在父进程调用 `waitpid` 前临时加 `::sleep(10);`。
2. 运行程序。
3. 另开终端执行：

```bash
ps -o pid,ppid,stat,cmd
```

`STAT` 中的 `Z` 表示 zombie。父进程随后执行 `waitpid` 后，该记录会消失。

实验结束要删掉临时的 `sleep`。不要通过制造大量未回收子进程来观察。

### 11.3 `wait()` 与 `waitpid()`

今天可以把：

```cpp
::wait(&status);
```

近似理解为：

```cpp
::waitpid(-1, &status, 0);
```

即等待任意子进程。我们已明确知道目标 PID，所以使用 `waitpid(child_pid, ...)`，意图更清楚，也为后续多个子进程做准备。

---

# Part 3：收尾、验证与验收

## 12. 今日必须产出

目录：

```text
week4/day5/
├── fork_wait.cpp
├── fork_memory.cpp
└── day5_note.md
```

今天是教学日，两份代码可以按教程实现并加入你自己的解释性注释。不要额外实现 `exec` 或 `pipe`。

---

## 13. 编译与运行

### 13.1 `fork_wait.cpp`

```bash
g++ -std=c++17 -Wall -Wextra -g fork_wait.cpp -o fork_wait
./fork_wait
./fork_wait
./fork_wait
```

至少运行三次。检查：

```text
无编译 warning
fork 前输出只有一次
父子 PID 不同
子进程看到 fork 返回 0
父进程拿到的 child_pid 与 waitpid 返回 PID 相同
最终退出码显示 7
child 行与 parent waiting 行的先后可能变化
```

### 13.2 `fork_memory.cpp`

```bash
g++ -std=c++17 -Wall -Wextra -g fork_memory.cpp -o fork_memory
./fork_memory
```

检查：

```text
子进程 value 为 99
父进程 wait 后 value 仍为 10
父子打印的虚拟地址可能相同
能够解释“相同虚拟地址”为什么不等于同一普通变量
```

---

## 14. 工具观察

### 14.1 `strace -f`

`-f` 是 follow forks，跟踪由 `fork` 产生的子进程。运行：

```bash
strace -f -e trace=process ./fork_wait
```

观察：

```text
创建子进程的系统调用
父进程等待子进程
父子分别退出
```

在 Linux/glibc 下，源码写 `fork`，跟踪中可能看到 `clone`/`clone3`；源码写 `waitpid`，底层可能显示 `wait4`；正常退出也可能显示 `exit_group`。这是库接口到底层系统调用实现的对应，不表示你的源码偷偷改成了另一个功能。

### 14.2 `ps`

完成第 11.2 节的短暂 zombie 实验后记录一行：

```text
PID / PPID / STAT 分别看到了什么
waitpid 返回后 Z 状态是否消失
```

---

## 15. 建议的 `day5_note.md`

不用抄整篇教程，只写新增机制、实验结果和真实问题：

```markdown
# Week4 Day5 Note

## 1. fork 执行流

## 2. 父子内存与 fd 的区别

## 3. waitpid、退出状态与 zombie

## 4. 用户态缓冲区实验

## 5. exit 与 _exit

## 6. strace / ps 观察

## 7. 验收问题
```

代码注释已经说清的机械步骤可以省略；下面这些结论不能省：

```text
fork 的三种返回情况
普通变量为什么互不影响
fd 为什么仍可能共享 open file description 状态
status 为什么不能直接当退出码
waitpid 如何完成等待与回收
缓冲区重复输出的真正原因
exit 与 _exit 的用户态缓冲区差别
```

---

## 16. 今日验收问题

请在 `day5_note.md` 中逐题回答。可以简洁，但不能只贴代码。

1. `process` 和磁盘上的 program file 有什么区别？
2. `PID`、`PPID` 分别是什么英文，表示什么？
3. `fork()` 成功后有几个执行流？它们从哪里继续？
4. `fork()` 在父进程、子进程、失败时分别返回什么？
5. 子进程中 `fork()` 返回 `0`，是否表示子进程 PID 是 `0`？怎样取得真实 PID？
6. 为什么不能根据一次运行中父子输出的先后，断言固定调度顺序？
7. 子进程把普通变量从 `10` 改为 `99` 后，父进程为什么仍看到 `10`？
8. 父子打印的 `&value` 数值可能一样，为什么仍不是可互相修改的同一变量？
9. COW 是什么英文？它改变“父子地址空间相互独立”的程序语义了吗？
10. `fork` 后父子对应 fd 为什么可能共享文件 offset？
11. `waitpid(child_pid, &status, 0)` 三个参数分别表示什么？成功和失败分别返回什么？
12. `status` 为什么不能直接当作退出码？正常退出时应怎样安全取得退出码？
13. `WIFSIGNALED` 和 `WTERMSIG` 分别解决什么问题？
14. zombie process 是什么？它为什么会出现？父进程怎样回收它？
15. `waitpid` 是让子进程退出，还是等待并读取子进程状态？
16. 为什么 `waitpid` 遇到 `errno == EINTR` 时通常应该重试？
17. `fork` 前未刷新的用户态输出为什么可能在重定向文件中出现两份？是输出语句执行了两次吗？
18. `return from main`、`exit`、`_exit` 对用户态收尾有什么主要区别？
19. 为什么 `_exit` 前用 `std::cout` 输出时需要显式刷新，或者改用 `write`？
20. `strace -f` 中为什么可能看到 `clone`、`wait4`、`exit_group`，而源码写的是 `fork`、`waitpid` 和 `return`？

---

## 17. 今日完成标准

满足以下条件即可进入 Day6：

```text
两份程序使用规定选项编译且无 warning
fork_wait 能回收子进程并得到退出码 7
fork_memory 能验证父子普通变量互不影响
至少观察一次不同的父子输出顺序，或明确说明其不确定性
完成一次缓冲区重复输出实验
用 ps 观察一次短暂 zombie 并在 wait 后确认消失
用 strace -f 观察一次创建、等待和退出
验收题能讲清机制，不把 PID、虚拟地址、fd 和退出码混在一起
```

---

## 18. 下一天衔接

Day5 解决的是：

```text
怎样创建子进程
怎样区分父子执行流
怎样等待并读取子进程结果
```

Day6 才继续解决：

```text
怎样用 pipe 建立父子字节流
怎样用 exec 替换子进程正在执行的程序
怎样组合 fork / pipe / dup2 / exec / wait
```

Day6 是独立组合练习日，教程前半部分不会直接给出完整组合答案。
