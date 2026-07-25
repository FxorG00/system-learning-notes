# Week4 Day6：`pipe + dup2 + exec + wait` 独立组合练习

> 今日定位：独立组合练习日，不是跟写教程。  
> 今天会把 `pipe` 和 Linux `exec` family 讲清楚，也会沿 MIT 6.S081 的真实课程顺序解释 `fork/exec/wait` 与重定向；但在你完成实现前，不提供完整组合代码、操作伪代码或可以直接拼成答案的关键片段。

---

# Part 1：前情提要与必要术语

## 1. 从 Day5 接到 Day6

Day5 已经掌握：

```text
fork 成功后产生父子两条执行流
父子普通地址空间相互独立
子进程继承父进程的 fd 表关系
父进程用 waitpid 等待并回收子进程
exec 失败时，进程映像没有替换，代码会继续向下执行
```

Day4 已经掌握：

```text
dup2(oldfd, newfd) 改写指定 fd 表项
把 fd 1 改为指向文件后，程序的标准输出就进入文件
```

今天把两条线组合起来：

```text
怎样让两个进程之间传递字节？
怎样让子进程执行另一个程序？
怎样在 exec 前给新程序安排好 stdin/stdout？
怎样关闭所有多余 fd，既不泄漏，也不让 read 永远等不到 EOF？
```

这正是后续 Shell pipeline、进程任务执行器和日志采集的基础。

---

## 2. 今日目标与边界

今天完成：

```text
理解 pipe 是内核维护的单向字节流
理解 pipefd[0] / pipefd[1] 的方向
理解 fork 后 pipe 端点引用怎样复制
理解 read 什么时候返回 EOF
独立完成父进程写、子进程读的 pipe demo
理解 Linux exec family，而不是寻找一个裸 exec() 函数
理解 exec 替换 process image，但不创建新 PID
独立组合 fork / pipe / dup2 / execlp / waitpid
正确处理 exec 成功不返回、失败才返回
正确关闭父子各自不用的 fd
```

今天不进入：

```text
完整 Shell
两个外部命令组成的多级 pipeline 实现
job control 与进程组
SIGPIPE 的信号处理
非阻塞 pipe
PIPE_BUF 原子性细节
pipe2 / O_CLOEXEC / fcntl 深入
多线程进程中的 fork/exec 限制
posix_spawn
```

---

## 3. 必要术语

### 3.1 pipe

**pipe：管道。** 英文原义就是“管子”。

在今天的 Linux 语境中，它是内核维护的一条**单向字节流通道**：

```text
writer --写入字节--> kernel pipe buffer --读取字节--> reader
```

`pipe` 不保存“第几条消息”的边界。两次 `write` 的数据，读取端可能一次读出，也可能分多次读出。今天按 byte stream（字节流）理解。

### 3.2 read end 与 write end

- `read end`：读端。
- `write end`：写端。

Linux `pipe()` 把两个 fd 写入数组：

```text
pipefd[0] -> read end
pipefd[1] -> write end
```

记忆钩子：数组下标 `0` 负责读入，`1` 负责写出。不要把它和 stdin/stdout 的 fd 数字混成同一个概念；这里只是 `pipefd` 数组的两个位置。

### 3.3 byte stream

**byte stream：字节流。**

它只承诺字节按顺序流动，不承诺：

```text
一次 write 对应一次 read
一次 read 能拿到完整业务消息
数据中自带字符串结尾 '\0'
```

所以 `read` 返回多少字节，就只处理多少字节。

### 3.4 EOF

`EOF`：**End Of File，输入结束。**

对阻塞 pipe 来说，读端 `read` 返回 `0` 的关键条件是：

```text
pipe 缓冲区已经读空
并且所有仍引用 write end 的 fd 都已关闭
```

只要还有任意进程保留一个 write end，读端在没有数据时就可能继续阻塞，因为内核认为“将来仍可能有人写”。

### 3.5 writer 与 reader

- `writer`：写入者。
- `reader`：读取者。

它们是角色，不一定固定等于父进程或子进程。今天第一个任务让 parent 当 writer；第二个任务让 exec 后的新程序当 writer。

### 3.6 exec 与 process image

`exec` 来自 **execute，执行**。

Linux 中常说 **exec family**，因为没有一个供你直接调用的裸 `exec()`；常见接口包括：

```text
execl / execlp / execle
execv / execvp / execvpe
底层 execve
```

**process image：进程映像。** 今天可以理解为当前进程正在使用的程序代码、数据、栈、堆等用户地址空间内容。

`exec` 成功时：

```text
不会创建新进程
PID 不变
当前进程映像被新程序替换
新程序从自己的入口开始运行
原程序 exec 后面的代码不再存在，因此不会继续执行
```

### 3.7 `execlp` 名称

今天允许选择 `execlp`：

- `exec`：execute，执行并替换当前进程映像。
- `l`：list，参数以可变参数列表逐个给出。
- `p`：PATH，如果程序名不含 `/`，按 `PATH` 搜索可执行文件。

参数列表中的第一个命令行参数按惯例是新程序看到的 `argv[0]`；整个列表必须以空指针结束。

### 3.8 descriptor inheritance

**descriptor inheritance：文件描述符继承。**

`fork` 让 child 得到 fd 表关系；`exec` 默认保留当前进程仍打开且未设置 close-on-exec 的 fd。

因此：

```text
child 在 exec 前用 dup2 安排 fd 1
-> exec 替换程序映像
-> 新程序仍把 fd 1 当作 stdout
-> 它不需要知道 fd 1 背后是终端、文件还是 pipe
```

### 3.9 deadlock

**deadlock：死锁。**

今天不展开锁理论，只认识进程管道中的一种互相等待：

```text
父进程 wait，等 child 退出
child 大量 write，等 parent 从满 pipe 中 read
父不读，子写不动；子不退出，父 wait 不返回
```

所以捕获 child 输出时，parent 应在 child 运行期间持续读 pipe，不能先无条件 wait 再去读全部输出。

---

## 4. 今日所需 API 速查：正文已经足够，不必先查官网

下面就是完成 Day6 两个必做任务所需要的最小接口说明。你可以直接以这里为准开始设计；`man` 和官网只放在本节末尾作为可选深入资料。

这里会把单个 API 的调用语法讲清楚，但不会替你排列 `pipe / fork / close / dup2 / exec / waitpid` 的完整组合顺序。

### 4.1 `pipe`：创建真正的内核管道

头文件：

```cpp
#include <cstddef>
#include <unistd.h>
```

签名：

```cpp
int pipe(int pipefd[2]);
```

最小独立调用形式：

```cpp
int pipefd[2];
const int result = ::pipe(pipefd);
```

这里最容易误解，所以先给出结论：

```text
pipe() 不是把现有的 stdin 和 stdout 接起来。
pipe() 会创建一个新的内核 pipe 对象，并返回两个新的 fd。
```

#### 4.1.1 `pipefd` 是输出参数，不是输入要求

调用前，`pipefd` 只是用户空间中的一个普通 `int[2]` 数组。调用成功后，内核把两个新 fd 的数字写回数组：

```text
pipefd[0] -> read end，只用于 read
pipefd[1] -> write end，只用于 write
```

这里有两套完全不同的数字：

```text
pipefd[0] / pipefd[1] 中的 0、1：数组下标
STDIN_FILENO / STDOUT_FILENO 的 0、1：fd 数字
```

例如，在 fd 0、1、2 都已经打开的普通进程中，常见结果是：

```text
调用前：pipefd[0] 和 pipefd[1] 还没有有效含义
调用后：pipefd[0] == 3，pipefd[1] == 4
```

`3`、`4` 只是常见结果，不是固定保证。内核通常选择当前进程 fd 表中最低的可用数字。

即使这样写：

```cpp
int pipefd[2] = {STDIN_FILENO, STDOUT_FILENO};
::pipe(pipefd);
```

数组中的旧值也会在成功时被覆盖。它不表示“请让 pipe 使用 fd 0 和 fd 1”。`pipe()` 的 `int` 返回值只报告成功或失败；真正的两个 fd 通过 `pipefd` 这个输出参数带回来。

#### 4.1.2 内核实际创建了什么

可以先用当前层次的模型理解为：

```text
用户空间                         内核空间

当前进程 fd 表
  fd 3 -----------------------> pipe read end
                                      |
                                kernel pipe buffer
                                      |
  fd 4 -----------------------> pipe write end
```

`kernel pipe buffer`：内核管道缓冲区。它是一块由内核管理、容量有限的字节缓冲区，不在父进程或子进程的普通用户空间里。

数据流动过程是：

```text
write(pipefd[1], user_buffer, count)
    -> 内核从用户缓冲区复制字节到 pipe buffer

read(pipefd[0], user_buffer, count)
    -> 内核从 pipe buffer 取出字节，复制到用户缓冲区
```

读走的数据会从 pipe buffer 中消费掉。pipe 是字节流，不记录“一次 write 就是一条消息”，也不能像普通文件一样用 `lseek` 随意定位。

#### 4.1.3 空、满与 EOF

阻塞 pipe 的基本行为：

```text
buffer 有数据：read 取走当前可用的一部分或全部字节
buffer 为空，但仍存在 write end：read 阻塞，等待未来数据
buffer 为空，并且所有 write end 都已关闭：read 返回 0，也就是 EOF
buffer 已满：write 可能阻塞，等待 reader 腾出空间
```

因此，“当前没有数据”和“以后再也不会有数据”是两种不同状态：

```text
还有 write end -> 以后可能再写，reader 等待
没有 write end -> 以后不可能再写，reader 得到 EOF
```

如果所有 read end 都已关闭，再向 write end 写入会失败，并可能触发 `SIGPIPE`。今天只需要知道这个边界，不展开信号处理。

#### 4.1.4 `pipe` 与进程 fd 表

假设调用 `pipe()` 前当前进程是：

```text
fd 0 -> terminal input
fd 1 -> terminal output
fd 2 -> terminal error
```

调用成功并得到 `pipefd == {3, 4}` 后：

```text
fd 0 -> terminal input
fd 1 -> terminal output
fd 2 -> terminal error
fd 3 -> pipe read end
fd 4 -> pipe write end
```

注意：fd 0 和 fd 1 完全没有自动改变。此时：

```text
read(0, ...) 仍然读 terminal input
write(1, ...) 仍然写 terminal output
read(3, ...) 才从 pipe 读取
write(4, ...) 才向 pipe 写入
```

`close(0)` 也只会删除 fd 0 这个入口，不会让 fd 3 自动移动到 fd 0，更不会自动把 stdin 接到 pipe。需要改变指定 fd 的指向时，使用的是 `dup2`。

#### 4.1.5 为什么创建 pipe 与 `fork` 的先后关系重要

`fork()` 只能让 child 继承 **fork 发生当时** parent 已经拥有的 fd 表关系。

如果 pipe 在 `fork` 之前已经存在：

```text
fork 前 parent：fd 3 -> pipe read end，fd 4 -> pipe write end

fork 后 parent：fd 3 -> 同一 pipe read end，fd 4 -> 同一 pipe write end
fork 后 child ：fd 3 -> 同一 pipe read end，fd 4 -> 同一 pipe write end
```

父子拥有各自独立的 fd 表，但这些表项引用同一个内核 pipe 对象。因此一个进程写入 pipe buffer，另一个进程才能从同一个 pipe buffer 读出。

如果 parent 在 `fork` 之后才调用 `pipe()`：

```text
parent：得到新的 pipe fd
child ：不会凭空得到 parent 后来创建的 fd
```

因为 `fork` 已经结束，parent 后续修改自己的 fd 表不会同步到 child。

#### 4.1.6 `pipe`、`close`、`dup2` 各负责什么

```text
pipe  -> 创建新的内核 pipe，并在当前进程中安装两个新 fd
fork  -> 让 child 继承调用时已经存在的 fd 关系
close -> 删除当前进程 fd 表中的一个入口
dup2  -> 让当前进程的指定 fd 改为引用另一个 fd 背后的对象
```

所以 `pipe()` 只负责“造出通道和两个端点”，不会自动决定谁是 writer、谁是 reader，也不会自动把端点安装到 stdin/stdout。角色分工与重定向是后续 fd 操作决定的。

返回值：

```text
0  -> 成功
-1 -> 失败，errno 说明原因，不能使用 pipefd 中的值
```

所有权：

```text
pipe 成功后，当前进程立刻拥有两个 fd
每个 fd 最终都必须在不再使用它的进程中 close
```

状态图：

```text
pipefd[1] --write--> kernel pipe buffer --read--> pipefd[0]
```

`pipe` 是 API，也是它创建出来的内核通信对象的名称。Shell 的 `|` 底层就会使用 pipe 一类的接口建立通道。

### 4.2 `fork`：复制当前执行流

头文件：

```cpp
#include <sys/types.h>
#include <unistd.h>
```

签名：

```cpp
pid_t fork();
```

返回值：

```text
父进程：返回 child PID，值 > 0
子进程：返回 0
失败：返回 -1，不创建 child，errno 说明原因
```

与 pipe 的关系只记状态语义：如果调用 `fork` 时当前进程已经拥有 pipe 两端，child 会继承对应 fd 表关系。父子之后各自关闭自己不需要的入口。

### 4.3 `read`：从 fd 读取实际字节

头文件：

```cpp
#include <cstddef>
#include <unistd.h>
```

签名：

```cpp
ssize_t read(int fd, void* buffer, std::size_t count);
```

参数：

```text
fd     -> 从哪个 fd 读取
buffer -> 内核把字节写到哪块用户内存
count  -> buffer 最多能接收多少字节
```

返回值：

```text
> 0 -> 实际读到的字节数，只能使用 buffer[0, result)
  0 -> EOF
 -1 -> 失败，errno 说明原因
```

pipe 上的 `read == 0` 必须同时满足：

```text
pipe 中已有数据已经读完
所有引用 write end 的 fd 都已关闭
```

`read` 不会自动补 `\0`。读到多少字节，就按返回值处理多少字节。

### 4.4 `write`：向 fd 写指定数量的字节

头文件：

```cpp
#include <cstddef>
#include <unistd.h>
```

签名：

```cpp
ssize_t write(int fd, const void* buffer, std::size_t count);
```

参数：

```text
fd     -> 写到哪个 fd
buffer -> 从哪块用户内存取字节
count  -> 请求写多少字节
```

返回值：

```text
>= 0 -> 实际写入的字节数，可能小于 count
  -1 -> 失败，errno 说明原因
```

`write` 没有 C 字符串概念。它不会自动添加 `\0`，只处理你明确传入的 `count` 个字节。可靠写入必须处理 short write 和 `EINTR`。

### 4.5 `close`：释放当前进程的一个 fd 入口

头文件：

```cpp
#include <unistd.h>
```

签名：

```cpp
int close(int fd);
```

返回值：

```text
0  -> 成功
-1 -> 失败，errno 说明原因
```

状态变化：

```text
close 只删除当前进程 fd 表中的这个入口
不会直接删除另一个进程 fd 表里的同号 fd
```

对 pipe 来说，所有 write end 引用是否都已关闭，会直接影响 reader 能否看到 EOF。

### 4.6 `dup2`：修改当前进程指定的 fd 表项

头文件：

```cpp
#include <unistd.h>
```

签名：

```cpp
int dup2(int oldfd, int newfd);
```

方向：

```text
oldfd -> source，来源
newfd -> destination，被改写的目标
```

状态变化：

```text
让当前进程的 newfd 改为引用 oldfd 所引用的内核对象
如果 newfd 原本打开，dup2 会在替换过程中关闭旧关系
```

例如这个**单独状态表达**：

```cpp
::dup2(pipefd[1], STDOUT_FILENO);
```

只表示：

```text
当前进程的 fd 1 -> pipe write end
```

它不会修改另一个进程的 fd 表，也不会自动关闭原始 `pipefd[1]`。

返回值：

```text
成功 -> 返回 newfd
失败 -> 返回 -1，errno 说明原因
```

### 4.7 `execlp`：用新程序替换当前进程映像

头文件：

```cpp
#include <unistd.h>
```

签名：

```cpp
int execlp(const char* file, const char* arg0, ...);
```

参数：

```text
file -> 要执行的程序名；不包含 / 时按 PATH 搜索
arg0 -> 新程序看到的 argv[0]，按惯例写程序名
...  -> argv[1]、argv[2] 等后续命令行参数
结尾 -> 必须是 char* 类型的 null sentinel
```

执行 `echo "hello from exec"` 的**单独接口写法**是：

```cpp
::execlp(
    "echo",
    "echo",
    "hello from exec",
    static_cast<char*>(nullptr)
);
```

这个片段只说明 `execlp` 参数，不包含 pipe、fork、dup2 或错误处理的排列答案。

返回行为：

```text
成功 -> 不返回；当前进程开始执行 echo
失败 -> 返回 -1，errno 说明原因，仍在原程序代码中
```

成功后 PID 不变。当前进程仍打开且没有 close-on-exec 的 fd 关系会被新程序继承。

### 4.8 `waitpid`：等待并读取指定 child 的状态

头文件：

```cpp
#include <sys/types.h>
#include <sys/wait.h>
```

签名：

```cpp
pid_t waitpid(pid_t pid, int* status, int options);
```

今天使用的参数语义：

```text
pid     -> 要等待的 child PID
status  -> 输出参数，接收编码后的等待状态
options -> 传 0，阻塞等待
```

返回值：

```text
成功 -> 返回发生状态变化的 child PID
失败 -> 返回 -1，errno 说明原因
```

`status` 不能直接当退出码。按顺序使用：

```text
WIFEXITED(status)   -> 是否正常退出
WEXITSTATUS(status) -> 正常退出时的退出码
WIFSIGNALED(status) -> 是否被信号终止
WTERMSIG(status)    -> 导致终止的信号编号
```

### 4.9 `errno`、`EINTR` 与 `perror`

头文件：

```cpp
#include <cerrno>
#include <cstdio>
```

```text
errno  -> 失败后记录具体错误编号
EINTR  -> Interrupted system call，系统调用被信号中断
perror -> 根据当前 errno 输出可读错误说明
```

只有接口已经通过返回值表示失败时，才读取 `errno`。今天的 `read`、`write`、`waitpid` 遇到 `EINTR` 时重试。

### 4.10 `_exit`：child 错误路径直接终止

头文件：

```cpp
#include <unistd.h>
```

签名：

```cpp
void _exit(int status);
```

今天的用途：

```text
child 中 dup2 或 execlp 失败
-> 报告错误
-> _exit(nonzero)
```

`_exit` 不返回，也不刷新继承来的用户态 stdio 缓冲区。Day6 约定 `exec` 失败使用退出码 `127`。

### 4.11 今天直接使用的 fd 常量

头文件：

```cpp
#include <unistd.h>
```

```text
STDIN_FILENO  -> fd 0
STDOUT_FILENO -> fd 1
STDERR_FILENO -> fd 2
```

它们是当前进程 fd 表中的数字入口，不是跨进程共享变量。

### 4.12 可选深入资料，不是开始练习的前置条件

只有接口边界仍有疑问时再查：

```bash
man 2 pipe
man 7 pipe
man 2 fork
man 2 dup
man 3 exec
man 2 waitpid
man 2 read
man 2 write
man 2 close
```

你不需要先读完这些页面，才能开始 Day6。

---

## 5. 这些 API 改变什么状态

### 5.1 `pipe` 创建通道，`dup2` 只改入口

```text
pipe  -> 创建新的内核 pipe 对象，并返回 read/write 两个端点
dup2  -> 不创建 pipe，只修改当前进程某个 fd 指向哪里
```

共享普通 open file description 不会自动产生“一个进程写、另一个进程读”的通道。能够排队传递字节的是 `pipe()` 创建的内核 pipe buffer。

### 5.2 `fork` 复制 fd 关系，parent 后续修改不会同步到 child

`fork` 成功后，父子各自拥有独立 fd 表。它们的表项可以引用相同内核对象，但：

```text
parent 调用 dup2/close -> 只修改 parent fd 表
child 调用 dup2/close  -> 只修改 child fd 表
```

所以每个进程都要单独安排和关闭自己的 pipe 端点。

### 5.3 `exec` 成功和失败的控制流

```text
调用前的 child 代码
       |
     execlp
      /   \
成功       失败
新程序入口  返回 -1，仍在原 child 代码
```

只有失败路径能执行 `execlp` 后面的错误处理。该路径要报告错误并 `::_exit(nonzero)`，不能继续掉进其他逻辑。

### 5.4 组合顺序仍由你独立设计

现在你已经拥有所有必要接口信息。接下来的独立任务只给目标 fd 状态、成功/失败契约和测试；具体在哪个分支调用哪个 API、什么时候关闭哪个端点，仍由你自己决定。

---

## 6. MIT 6.S081 今日听课任务

**Lecture：Lec01 Introduction and Examples。**

今天实际对应：

1. [1.9 exec, wait 系统调用](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/lec01-introduction-and-examples/1.9-exec-and-wait-systemcall)：第二遍，重点改为 `exec`。
2. [1.10 I/O Redirect](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/lec01-introduction-and-examples/1.10-io-redirect)：完整复习，并连接 Day4 的 `dup2`。

建议投入：`25~35` 分钟。

### 6.1 听到什么程度

#### 1.9 第二遍

从页面开头的 `echo` 示例读起，一直读过 `fork/exec/wait` 示例和 `exec failed` 实验。必须掌握：

```text
exec 替换当前进程映像，而不是创建新进程
exec 为什么保留已有 fd
argv 为什么是指针数组，末尾为什么需要 null pointer
exec 成功为什么不返回
exec 失败为什么会继续执行后面的错误路径
Shell 为什么是 parent 保留自己、child 执行 exec
parent 怎样通过 wait 取得 child 结果
```

页面后面的 COW 和调度问答 Day5 已经听过，今天只快速复习，不重新抄笔记。

#### 1.10 完整复习

沿着课程 `redirect` 示例完整读到本节总结。必须掌握：

```text
Shell 为什么先 fork
为什么只修改 child 的 fd 1
课程中的 close(1) + open() 怎样让 fd 1 指向 output.txt
exec 后 echo 为什么仍使用已经安排好的 fd 1
为什么 echo 完全不知道自己被重定向
fork 与 exec 分开为什么给 Shell 留出修改 fd 的窗口
```

课程最后强调的是组合能力：简单的 fd 和 process 接口，可以组合出 I/O redirect 这样的复杂行为。

### 6.2 顺着 1.9 课程讲解：从 `echo` 到 `fork/exec/wait`

课程先选择 `echo`，因为它行为简单：接收命令行参数，再把内容写到输出。这样注意力可以集中在“谁正在执行”上。

第一段 `exec` 示例的状态变化：

```text
原进程正在运行课程 exec 示例
-> 调用 exec，指定 echo 和参数
-> 内核加载 echo 的指令和数据
-> 替换当前进程映像
-> 仍是同一个 PID，但开始执行 echo
-> 实际输出来自 echo，不是旧程序继续向下打印
```

课程接着强调两点：

1. fd 表关系会保留，所以新程序继续看到 fd 0、1、2。
2. 成功后旧程序地址空间被替换，没有旧代码位置可以返回；失败才返回 `-1`。

学生问 argv 最后为什么是 `0`。课程解释：C 数组本身不携带长度，内核遍历指针数组时需要 null pointer 标出终点。Linux `execlp` 的可变参数列表也需要 null sentinel。

然后课程回到 Shell：Shell 不能自己直接 `exec echo`，否则 Shell 会被替换。于是形成：

```text
Shell
  |
 fork
  |--------------------------|
parent                     child
保留 Shell                exec(echo)
wait(child)               成功后变成 echo
  |                          |
取得退出状态 <------------- exit
继续接收下一条命令
```

课程随后故意把目标改为不存在的程序。此时替换没有发生，`exec` 返回错误，child 才能执行错误打印和 `exit(1)`；parent 的 `wait` 因而观察到失败状态。

这正是今日实现必须覆盖的错误契约，但课程使用 xv6 `exec/wait`，你的代码使用 Linux `execlp/waitpid`，接口细节不能照抄。

### 6.3 顺着 1.10 课程讲解：为什么要在 fork 和 exec 之间改 fd

课程运行的现象是：

```text
echo 的输出没有出现在终端
output.txt 中却出现了 echo 的内容
parent Shell 的后续输出仍在终端
```

课程代码先 `fork`。只在 child 中关闭 fd 1，再 `open` 输出文件。因为 xv6 的 `open` 返回最小可用 fd，fd 1 刚被释放，所以新文件获得 fd 1。

状态变化：

```text
fork 后
parent fd 1 -> console
child  fd 1 -> console

child close(1) + open(output.txt) 后
parent fd 1 -> console
child  fd 1 -> output.txt

child exec(echo) 后
parent fd 1 -> console
echo   fd 1 -> output.txt
```

`echo` 仍只向 fd 1 写。它不需要知道 fd 1 背后已经从 console 变成文件。

课程真正要你看到的是 `fork` 和 `exec` 分开的设计价值：

```text
fork 返回之后、exec 成功之前
child 仍在执行原程序代码
-> child 有机会先修改 fd、工作目录或其他运行环境
-> 然后 exec 新程序
```

### 6.4 xv6 课程与今日 Linux 实现对照

| 课程中的 xv6 | 今日 Linux/C++ | 共同结果 |
|---|---|---|
| `exec(path, argv)` | 选择 `execlp` 或其他 exec family 接口 | 替换当前进程映像 |
| `wait(&status)` | `waitpid(child_pid, &status, 0)` | parent 等待并取得 child 状态 |
| `close(1); open(file)` | `dup2(source_fd, STDOUT_FILENO)` | child 的 fd 1 改指向新目标 |
| 输出文件 | pipe write end | exec 后的新程序向 fd 1 写入 |

今天的 pipe EOF、父子关闭纪律和 short read/write 是 Linux 系统编程主线补充，不要错误归为 1.10 原文内容。

### 6.5 课程部分学完后能讲什么

```text
exec 为什么没有创建新 PID
exec 成功和失败后的控制流分别去哪
为什么 fd 安排能够跨过 exec 保留
Shell 为什么不能自己直接 exec 用户命令
为什么重定向只改 child，不改 parent
为什么 fork 和 exec 分开反而更灵活
xv6 close/open 写法与 Linux dup2 写法如何得到相同 fd 表结果
```

---

# Part 2：教程主体

# 教程开始：从“怎样不用临时文件，把一个进程的输出交给另一个进程？”出发

## 7. 先建立 pipe 状态模型

调用 `pipe` 成功、尚未 `fork` 时：

```text
当前进程 fd 表
  pipefd[0] -> pipe read end
  pipefd[1] -> pipe write end
```

随后 `fork` 成功：

```text
parent fd 表                  child fd 表
  pipefd[0] -> read end         pipefd[0] -> read end
  pipefd[1] -> write end        pipefd[1] -> write end
```

此时有四个 fd 表项引用 pipe 两端。你必须根据角色主动关闭不用的端点。`fork` 不会猜测谁想读、谁想写。

### 7.1 EOF 的状态推导

假设 reader 已把现有数据读完：

| write end 引用情况 | 阻塞 `read` 的结果 |
|---|---|
| 至少还有一个 write fd 打开 | 等待未来数据 |
| 所有 write fd 都关闭 | 返回 `0`，即 EOF |

因此，“真正写数据的人已经 close”仍可能不够。如果 reader 自己忘了关闭继承来的 write end，它也会让内核认为 writer 仍存在。

### 7.2 写端没有 reader 时

如果所有 read end 都关闭后仍执行 `write`，默认可能触发 `SIGPIPE`，或者在相应信号处理设置下令 `write` 返回 `-1`、`errno == EPIPE`。

今天不处理 `SIGPIPE`，但设计必须避免无意中留下错误端点关系。

---

## 8. 独立任务一：`pipe_parent_child.cpp`

### 8.1 公开需求

实现一个最小父子进程通信程序：

```text
parent 是唯一 writer
child 是唯一 reader
parent 写入：hello through pipe\n
child 读取到 EOF，并把收到的全部字节写到自己的 stdout
parent 回收 child，并确认 child 正常退出且退出码为 0
```

文件：

```text
week4/day6/pipe_parent_child.cpp
```

### 8.2 角色成立后的 fd 契约

你需要让运行阶段满足：

| 进程 | read end | write end | 职责 |
|---|---:|---:|---|
| parent | 已关闭 | 保留到数据写完 | 写入全部字节，随后产生 EOF 条件 |
| child | 保留到读完 | 已关闭 | 循环读取，直到 `read == 0` |

表格只描述目标状态，不提供你应该怎样排列系统调用。请自己决定每一步发生在哪个分支、何时关闭、何时等待。

### 8.3 成功契约

```text
stdout 恰好出现：hello through pipe
程序最终退出码为 0
child 不依赖 sleep 等待数据
parent 不依赖 sleep 等待 child
没有进程永久阻塞
所有 pipe fd 最终关闭
```

### 8.4 错误契约

```text
pipe 失败：报告 errno，不调用 fork
fork 失败：报告 errno，关闭已经创建的两个 pipe fd
read 遇到 EINTR：重试
read 其他失败：child 报错并非 0 退出
write 处理 short write 和 EINTR
waitpid 处理 EINTR
parent 必须检查 child 是正常退出、信号终止还是其他状态
```

child 的失败路径使用 `::_exit(nonzero)`。错误信息走 `stderr`，正常 payload 走 `stdout`。

### 8.5 独立设计题

写代码前，在纸上或 note 中填：

```text
pipe 成功后，当前进程拥有：________
fork 后，parent 立刻不需要的端：________
fork 后，child 立刻不需要的端：________
哪一个 close 让 child 最终有机会看到 EOF：________
parent 应该在什么条件满足后 wait：________
```

不要先从网上复制 parent/child pipe 模板。先让你的 fd 状态表自洽。

---

## 9. 独立任务二：`fork_exec_pipe.cpp`

### 9.1 问题背景

这次不让 child 自己写 payload。child 要把 stdout 接到 pipe，然后用 `exec` 变成另一个程序；parent 从 pipe 捕获新程序的输出。

这对应 1.10 的思想，只是把输出目标从文件替换为 pipe：

```text
课程：echo fd 1 -> output.txt
今天：echo fd 1 -> pipe write end -> parent
```

### 9.2 命令行契约

程序接收一个命令名：

```bash
./fork_exec_pipe echo
./fork_exec_pipe definitely_not_a_command
```

参数不正确时打印 usage 并返回非 0。

正常测试中，新程序应等价于执行：

```text
echo "hello from exec"
```

你可以使用 `execlp`，让命令名通过 `PATH` 查找。需要自己查清 `file`、`argv[0]`、后续参数和 null sentinel 怎样传。

### 9.3 最终 fd 状态契约

在 child 调用 `exec` 前，它必须达到：

```text
fd 1 -> pipe write end
pipe read end 已关闭
原始 pipe write fd 已关闭，不留下重复入口
fd 2 仍指向原 stderr，exec 失败信息不会混进正常 payload
```

parent 的运行状态必须达到：

```text
pipe write end 已关闭
只从 pipe read end 读取 child/new program 的 stdout
读取到 EOF 后关闭 read end
回收指定 child，并解析状态
```

这仍然只是结果契约。你需要自己把 `pipe / fork / dup2 / close / execlp / read / waitpid` 排成正确控制流。

### 9.4 成功契约

运行：

```bash
./fork_exec_pipe echo
```

要求：

```text
parent 从 pipe 得到 hello from exec\n
payload 最终写到 parent 的 stdout
child exec 后 PID 不变
parent 最终观察到 child 正常退出且退出码为 0
程序整体返回 0
```

### 9.5 `exec` 失败契约

运行：

```bash
./fork_exec_pipe definitely_not_a_command
```

要求：

```text
execlp 返回 -1
child 使用 perror 报告失败原因
child 使用 _exit(127)，不继续执行其他分支
parent 最终从 pipe 读到 EOF，不永久阻塞
parent 从 waitpid 观察到 child 的非 0 退出码
程序整体返回非 0
```

`127` 是本练习为“exec 失败”选择的约定值。今天不展开完整 Shell 的 `126/127` 规则。

### 9.6 防止“能跑小输出，但设计会死锁”

parent 捕获 child 输出时，不应先等待 child 完全退出，再开始读取 pipe。

原因：

```text
child 输出很大
-> pipe kernel buffer 写满
-> child 阻塞在 write，无法退出
-> parent 阻塞在 wait，尚未 read
-> 双方互相等待
```

你的控制流必须让 parent 在 child 运行期间排空 pipe。今天 payload 很小，但验收看设计，不只看这一次没挂。

---

## 10. 所有权与关闭清单

每次 `pipe` 成功，调用进程立刻拥有两个 fd。`fork` 后，父子各自拥有自己 fd 表中的引用。

请对每个分支逐项回答：

```text
这个进程需要读吗？
这个进程需要写吗？
dup2 后原始 fd 还需要吗？
exec 成功后哪些 fd 应该留下？
exec 失败后由谁关闭？
fork 失败时当前进程已经拥有哪些 fd？
正常 return / _exit / exec 成功分别怎样结束当前控制流？
```

今天允许直接使用 raw fd，因为目标是看清系统调用状态；但每个 fd 都必须有明确的 owner 和关闭时机。不要为了形式额外写复杂 RAII 封装。

---

## 11. 不变量

实现过程中始终保持：

```text
同一进程不使用已经 close 的 fd
每个分支只保留自己真正需要的 pipe 端
reader 不保留 write end
writer 不保留 read end
dup2 成功后关闭不再需要的原始重复 fd
exec 失败路径不会落入 parent 逻辑
parent 只 wait 自己成功创建的 child
status 先判断类型，再提取退出码或信号编号
payload 与错误诊断不混用同一个输出通道
```

---

## 12. 卡住时的提示规则

仍按练习日规则分级：

```text
Level 1：只指出违反了哪条 fd 契约或哪个返回值没处理
Level 2：指出问题属于 parent、child、read end、write end、exec 前或 exec 失败路径
Level 3：给局部修正思路，不写完整函数
Level 4：只有你明确要求时，才给完整代码或完整控制流
```

优先把你的 fd 状态图和当前代码发给我，不必先猜一个“大概模板”。

---

# Part 3：收尾、验证与验收

## 13. 今日必须产出

Ubuntu：

```text
~/code/system-learning/cpp/week4/day6/
├── pipe_parent_child.cpp
├── fork_exec_pipe.cpp
└── day6_note.md
```

今天没有参考实现可以复制。两份代码都由你独立完成。

---

## 14. 编译与运行

### 14.1 任务一

```bash
g++ -std=c++17 -Wall -Wextra -g pipe_parent_child.cpp -o pipe_parent_child
timeout 3s ./pipe_parent_child
echo $?
```

检查：

```text
零 warning
输出内容准确
正常退出码为 0
没有依赖 sleep
没有因 write end 未关闭而超时
```

`timeout` 返回 `124` 通常表示程序超过限制时间，优先检查是否仍有 write end 没关闭，或父子是否互相等待。

### 14.2 任务二成功路径

```bash
g++ -std=c++17 -Wall -Wextra -g fork_exec_pipe.cpp -o fork_exec_pipe
timeout 3s ./fork_exec_pipe echo
echo $?
```

检查：

```text
零 warning
输出包含且只包含预期 payload
parent 解析到 child 正常退出 0
程序整体退出 0
```

### 14.3 任务二失败路径

```bash
timeout 3s ./fork_exec_pipe definitely_not_a_command
echo $?
```

检查：

```text
stderr 能看到 exec 失败原因
程序不超时
parent 观察到 child 的 127
程序整体非 0 退出
没有把错误文字混进 pipe payload
```

### 14.4 资源与系统调用观察

推荐完成一次：

```bash
strace -f \
  -e trace=pipe,pipe2,clone,fork,vfork,dup2,close,read,write,execve,wait4,exit_group \
  ./fork_exec_pipe echo
```

只需观察：

```text
pipe/pipe2 创建端点
clone/fork 创建 child
child dup2 并关闭多余端点
child execve
parent read 到 0
parent wait4
```

不要求抄整段 trace。

---

## 15. 必须覆盖的测试矩阵

| 文件 | 场景 | 预期 |
|---|---|---|
| `pipe_parent_child.cpp` | 正常传输 | payload 完整，双方正常退出 |
| `pipe_parent_child.cpp` | 多次运行 | 不随机卡住，不重复输出 |
| `fork_exec_pipe.cpp` | `echo` | 捕获完整输出，child status 为 0 |
| `fork_exec_pipe.cpp` | 不存在命令 | child 以 127 退出，parent 非 0，程序不挂 |
| 两份代码 | warning | `-Wall -Wextra` 为零 warning |
| 两份代码 | fd 关闭 | 所有分支都能解释每个端点何时关闭 |

不要求今天人为制造 `pipe()` 或 `fork()` 资源耗尽，但错误路径必须在代码中正确处理。

---

## 16. 提交前自查

```text
我是否检查了 pipe 的返回值？
fork 失败时是否关闭了两个 pipe fd？
fork 后父子是否立刻关闭各自不用的端？
read 是否区分 >0、0、-1？
write 是否处理 short write 和 EINTR？
dup2 失败后 child 是否立刻走失败路径？
dup2 成功后原始 pipe fd 是否仍被错误保留？
execlp 的 argv[0] 和 null sentinel 是否正确？
exec 失败后是否 perror + _exit(127)？
parent 是否在等待前正确处理 pipe 数据，避免大输出死锁？
waitpid 是否处理 EINTR？
status 是否先用 WIF* 判断再提取？
正常 payload 和错误信息是否分开？
```

---

## 17. `day6_note.md` 建议结构

只记录你的设计和真实问题，不抄完整教程：

```markdown
# Week4 Day6 Note

## 1. MIT 6.S081：fork/exec/wait 与 redirect 主线

## 2. pipe EOF 条件

## 3. pipe_parent_child 的 fd 状态图

## 4. fork_exec_pipe 的 fd 状态图

## 5. exec 成功与失败控制流

## 6. 我遇到的阻塞、错误或边界

## 7. 测试结果

## 8. 验收问题
```

如果实现一次通过，第 6 节可以写“无实际错误”，但 fd 状态图、错误契约和测试结果不能省。

---

## 18. 今日验收问题

完成代码后，基于你自己的实现逐题回答：

1. `pipe` 的英文直觉是什么？`pipe()` 成功和失败分别返回什么？
2. `pipefd[0]` 和 `pipefd[1]` 各是什么角色？
3. 为什么 pipe 是 byte stream，而不是 message queue？
4. 阻塞 pipe 的 `read` 在什么完整条件下返回 `0`？
5. `pipe` 后立刻 `fork`，父子一共有几个引用 pipe 端点的 fd 表项？
6. reader 为什么也必须关闭自己继承到的 write end？
7. 任务一中 parent 为什么必须在等待 child 前结束自己的写入并关闭 write end？
8. 捕获大量 child 输出时，parent 为什么不能先 `waitpid` 再读取全部 pipe？
9. `exec` 是什么英文？process image 包括什么第一层内容？
10. `exec` 成功后 PID 是否变化？旧程序为什么不能继续执行下一行？
11. Linux 为什么说 exec family？`execlp` 中的 `l` 和 `p` 分别表示什么？
12. `execlp` 的 `argv[0]` 和末尾 null sentinel 分别有什么作用？
13. `execlp` 成功和失败分别怎样返回？
14. child 在 `exec` 前完成 `dup2`，为什么新程序仍能使用重定向后的 fd 1？
15. `dup2` 成功后为什么还要关闭原始 pipe write fd？
16. `exec` 失败后为什么使用 `_exit(127)`，而不是继续 `return`？
17. 任务二中为什么 parent 的 stdout 没被重定向？
18. `exec` 失败时，为什么错误信息应该走 stderr，而不是已经重定向的 stdout？
19. parent 怎样区分 child 正常退出、非 0 退出和被信号终止？
20. xv6 的 `close(1) + open()` 与 Linux 的 `dup2(..., STDOUT_FILENO)` 有什么共同结果和接口差异？
21. 分别列出任务二中 parent 和 child 最终保留的 pipe 端点。
22. 如果程序卡住，你会怎样从“哪些 write end 还开着”和“谁正在 wait/read/write”两个方向排查？

---

## 19. 今日完成标准

满足以下条件即可进入 Day7：

```text
两份代码由你独立实现
使用规定参数编译且零 warning
任务一完成 parent -> child 的可靠字节传输
任务一能够通过 close 产生 EOF，不依赖 sleep
任务二完成 child stdout -> pipe -> parent
任务二 exec 成功路径正确
任务二 exec 失败路径以 127 结束且 parent 能判断
所有分支的 pipe 端点都能解释所有权和关闭时机
不存在先 wait 后 drain 大量输出的潜在死锁设计
day6_note 包含两张 fd 状态图和实际测试结果
验收问题能基于自己的实现解释
```

---

## 20. 可选挑战：真正的两命令 pipeline

只有两个必做任务通过后，再考虑：

```text
producer child：stdout -> pipe write end -> exec producer
consumer child：stdin  <- pipe read end  -> exec consumer
parent：关闭两个 pipe 端，分别 wait 两个 child
```

例如建立等价于 `echo hello | wc -c` 的两 child pipeline。

这不是 Day6 必做项，也不提供实现提示。多级 pipeline、进程组和 job control 留到后续 Shell/OS 项目阶段。

---

## 21. 下一天衔接

Day7 将进入：

```text
mmap 第一层使用
signal 第一层直觉
Week4 fd / process / pipe / exec 总验收
```

不会在 Day7 扩写 Shell，也不会继续增加 pipeline 难度。
