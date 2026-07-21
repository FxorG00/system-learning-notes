# Week4 Day4：`dup2`、标准文件描述符与输出重定向

> 当前进度：Week4 Day1~Day3 已验收。今天沿用 Day3 建立的
> `fd → fd 表项 → open file description → 文件对象` 模型，解释 Shell 的 `>` 为什么能让程序输出进入文件。

---

# Part 1：前情提要与必要术语

## 1. 从 Day3 接到 Day4

Day3 已经验证：

```text
重新 open 同一路径
→ 得到新的 fd 表项
→ 通常指向新的 open file description
→ offset 相互独立

dup(original_fd)
→ 得到新的 fd 表项
→ 仍指向原来的 open file description
→ offset 和 file status flags 共享
```

今天不重复写 `dup` 共享 offset 实验，而是继续追问：

```text
如果新 fd 的数字不能随便选，
而是必须让“fd 1”改为指向某个文件，应该怎么办？
```

这就是 `dup2` 解决的问题。

---

## 2. 今日目标与边界

今天完成：

```text
理解标准输入、标准输出、标准错误为什么通常是 fd 0、1、2
理解 dup2(oldfd, newfd) 的复制方向
理解 dup2 修改的是进程 fd 表中的哪个表项
把标准输出重定向到文件
解释 std::cout / printf / write 为什么都会改变去向
理解重定向前为什么要注意用户态输出缓冲区
用 strace 和 lsof 观察真实 fd 变化
```

今天不进入：

```text
fork 的父子执行流
exec 替换进程映像
pipe 编程
完整 Shell 实现
多线程中的 fd 竞争
dup3 / close-on-exec 深入
```

---

## 3. 今日 MIT 6.S081 范围

**Lecture：Lec01 Introduction and Examples。**

必读或听对应片段：

1. [1.7 Shell](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/lec01-introduction-and-examples/1.7-shell)
2. [1.10 I/O Redirect](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/lec01-introduction-and-examples/1.10-io-redirect)

建议投入：`25~35` 分钟。

### 1.7 听到什么程度

只抓住：

```text
Shell 自己是一个用户程序
Shell 读取命令，并负责安排程序的运行环境
应用程序不需要自己解析命令行里的 >
重定向是 Shell 在程序运行前安排 fd 的结果
```

1.7 会涉及 Shell 创建和运行进程。今天只理解“Shell 负责安排”，`fork/exec/wait` 的具体代码留到 Day5、Day6。

### 1.10 听到什么程度

只抓住：

```text
程序仍然向标准输出写
Shell 改变了标准输出对应的内核资源
因此程序本身不需要知道输出去终端还是文件
```

课程中的 xv6 示例可能使用：

```text
close(1)
open(...)
```

其思路依赖 `open` 返回当前最小可用 fd，因此关闭 `1` 后，下一次 `open` 很可能得到 `1`。今天在 Linux 代码中使用目标更明确的 `dup2`：

```cpp
::dup2(output_fd, STDOUT_FILENO);
```

不要把 xv6 的具体接口细节直接当作 Linux 最佳写法。课程负责解释组合思想，Linux API 语义以 [`dup(2)`](https://man7.org/linux/man-pages/man2/dup.2.html) 为准。

### 1.10 课程讲解：沿着 `redirect.c` 看懂 I/O Redirect

1.10 的主线就是 `redirect.c`。它不是要求你现在掌握完整的 `fork/exec/wait`，而是用一段小程序证明：

```text
重定向不需要修改 echo 的输出代码。
只要在运行 echo 前，把它将看到的 fd 1 改成指向文件即可。
```

课程代码的核心结构如下。这里是 xv6 接口，不要直接拿头文件和常量到 Linux 编译：

```c
// redirect.c: run a command with output redirected
int main() {
    int pid;

    pid = fork();
    if (pid == 0) {
        close(1);
        open("output.txt", O_WRONLY | O_CREATE | O_TRUNC);

        char* argv[] = {
            "echo", "this", "is", "redirected", "echo", 0
        };
        exec("echo", argv);

        printf("exec failed!\n");
        exit(1);
    } else {
        wait((int*)0);
    }

    exit(0);
}
```

#### 第一步：`fork()` 给 Shell 一个可单独修改的子进程

```c
pid = fork();
```

`fork` 后出现父、子两个执行流。子进程一开始继承父进程的 fd 关系：

```text
父进程 fd 表                    子进程 fd 表

0 → terminal input             0 → terminal input
1 → terminal output            1 → terminal output
2 → terminal error             2 → terminal error
```

今天只使用这个结论；`fork` 为什么返回两次、父子内存怎样变化，留到 Day5。

为什么需要子进程？因为 Shell 自己后面还要继续显示提示符、读取命令。如果 Shell 直接永久修改自己的 fd 1，Shell 后续输出也会跑进文件。让子进程修改自己的 fd 表，就不会改变父 Shell 的 fd 表。

#### 第二步：只在子进程中关闭 fd 1

```c
if (pid == 0) {
    close(1);
```

`pid == 0` 表示当前走的是子进程分支。关闭后：

```text
子进程 fd 表

0 → terminal input
1 → 空闲
2 → terminal error
```

父进程的 fd 1 没有被关闭。

#### 第三步：`open()` 为什么恰好返回 1

```c
open("output.txt", O_WRONLY | O_CREATE | O_TRUNC);
```

`open` 会选择当前最小的可用 fd。子进程此时：

```text
fd 0：已占用
fd 1：刚刚关闭，是最小可用编号
fd 2：已占用
```

所以成功的 `open` 会得到 fd 1。虽然课程代码没有接收返回值，但 fd 表已经变成：

```text
0 → terminal input
1 → output.txt
2 → terminal error
```

**重定向真正建立在这里。** 数字 1 没变，fd 表项 1 背后引用的资源从终端变成了文件。

课程使用 xv6 的 `O_CREATE`；Linux 中对应的名字通常是 `O_CREAT`。课程 demo 为突出主线省略了一些失败检查，自己的 Linux 代码仍必须检查 `open` 返回值。

#### 第四步：`argv` 是准备交给 `echo` 的参数

```c
char* argv[] = {
    "echo", "this", "is", "redirected", "echo", 0
};
```

可以理解成准备运行：

```bash
echo this is redirected echo
```

数组含义：

```text
argv[0] = "echo"          程序名
argv[1] = "this"          第一个参数
argv[2] = "is"
argv[3] = "redirected"
argv[4] = "echo"
argv[5] = 0               参数数组结束标志
```

#### 第五步：`exec()` 换掉代码，但保留安排好的 fd

```c
exec("echo", argv);
```

`exec` 不会再创建一个新进程。它把当前子进程的程序代码和用户态内存替换为 `echo`，但在这个例子中，已经安排好的 fd 表保留下来：

```text
exec 前的 redirect 子进程       exec 后的 echo

fd 1 → output.txt      →       fd 1 → output.txt
```

`echo` 不知道 `output.txt` 的名字，也不需要认识 `>`。它只照常执行类似：

```c
write(1, ...);
```

因为 fd 1 此时指向 `output.txt`，内容自然进入文件。

完整状态链：

```text
fork 创建子进程
→ 子进程 close(1)
→ open(output.txt) 复用最小空闲编号 1
→ exec(echo) 替换程序，但保留 fd 表
→ echo 执行 write(1, ...)
→ 数据进入 output.txt
```

#### 第六步：为什么 `exec` 后面还写了错误处理

```c
exec("echo", argv);
printf("exec failed!\n");
exit(1);
```

```text
exec 成功：当前程序已被替换，不会返回到下一行
exec 失败：返回原程序，继续执行错误处理
```

课程 demo 中 `printf` 使用标准输出，而 fd 1 已经指向文件，所以这条失败信息也可能进入 `output.txt`。工程代码通常更适合把诊断写向 fd 2，也就是 `stderr`。

#### 第七步：父进程为什么 `wait()`

```c
else {
    wait((int*)0);
}
```

父进程等待子进程中的 `echo` 完成。今天先记成：

```text
child：安排 fd，然后运行 echo
parent：等待 child 结束
```

`wait` 的回收职责和退出状态留到 Day5 正式学习。

#### `redirect.c` 最重要的设计思想

```text
echo 负责：输出什么
Shell 负责：fd 1 接到哪里
```

中间的 fd 提供了一层 **indirection（间接层）**：

```text
echo → write(1, ...) → fd 表项 1 → 终端 / 文件 / 将来的 pipe
```

稳定的是程序只使用 fd 1；可替换的是 fd 1 背后的资源。这就是 Unix 工具不需要各自实现一遍重定向的原因。

#### 它和今天 Linux `dup2` 写法怎样对应

课程 xv6 写法：

```c
close(1);
open("output.txt", ...);  // 利用最小可用 fd，得到 1
```

今天的 Linux 写法：

```cpp
int output_fd = ::open("output.txt", ...);
::dup2(output_fd, STDOUT_FILENO);  // 明确指定改写 fd 1
::close(output_fd);
```

两者最终都得到：

```text
fd 1 → output.txt
```

区别在于：`close(1) + open()` 利用最小可用 fd 规则；`dup2` 直接表达“让 fd 1 成为 output_fd 的副本”。Day4 的 Linux 实现使用后者。

---

## 4. 英文术语先认清

| 名称 | 英文 | 中文直觉 | 实际作用 |
|---|---|---|---|
| `stdin` | **standard input** | 标准输入 | 程序默认读取输入的流，通常对应 fd 0 |
| `stdout` | **standard output** | 标准输出 | 程序默认输出正常结果的流，通常对应 fd 1 |
| `stderr` | **standard error** | 标准错误 | 程序默认输出错误和诊断信息的流，通常对应 fd 2 |
| `STDIN_FILENO` | standard input fd number | 标准输入的 fd 数字 | `<unistd.h>` 中值为 0 的宏 |
| `STDOUT_FILENO` | standard output fd number | 标准输出的 fd 数字 | `<unistd.h>` 中值为 1 的宏 |
| `STDERR_FILENO` | standard error fd number | 标准错误的 fd 数字 | `<unistd.h>` 中值为 2 的宏 |
| `redirect` | **re + direct** | 改变方向、重定向 | 让原本通向一个资源的 fd 表项改为通向另一个资源 |
| `dup` | **duplicate a file descriptor** | 复制 fd 表入口 | 自动选择最小可用的新 fd |
| `dup2` | `dup` 接口的第二种形式 | 复制到指定 fd 数字 | 让 `newfd` 成为 `oldfd` 的副本 |
| `oldfd` | old file descriptor | 作为复制来源的 fd | 它当前指向的 open file description 会被复用 |
| `newfd` | new file descriptor | 要被安排的目标 fd 数字 | 成功后，它改为引用 `oldfd` 的 open file description |
| `flush` | flush | 冲刷、刷新 | 把用户态缓冲区中尚未真正写出的数据送往底层 fd |
| `PID` | **process ID** | 进程编号 | 标识一个正在运行的进程 |
| `lsof` | **list open files** | 列出打开的文件 | 观察进程的 fd 当前引用哪些资源 |

### `FILENO` 怎么记

在 `STDOUT_FILENO` 中，把 `FILENO` 读成 **file number** 可以帮助记忆：

```text
STDOUT_FILENO
→ standard output 对应的 file descriptor number
→ 值为 1
```

这里最重要的不是背缩写，而是区分三层：

```cpp
std::cout       // C++ 的 std::ostream 对象
stdout          // C 标准库的 FILE* 流
STDOUT_FILENO   // POSIX/Linux 的整数 fd，通常为 1
```

它们都与“标准输出”有关，但不是同一种类型、也不在同一抽象层。

### `dup2` 中的 `2` 是什么

`2` 表示这是 `dup` 家族的另一个接口形式，不是“复制两次”。

记忆句：

```text
dup  ：系统帮我挑一个新 fd 数字。
dup2 ：我指定要改成哪个 fd 数字。
```

### 今日 open flags

```text
O_WRONLY：write only，只写
O_CREAT ：create；目标不存在时创建。CREAT 是历史接口中的拼写
O_TRUNC ：truncate；目标存在时把长度截断为 0
```

`O_` 是 `open` flags 的命名前缀，不需要为它编造额外展开。

---

## 5. 标准 fd 为什么是 0、1、2

程序通常启动时，进程 fd 表已经有：

```text
fd 0 → standard input  → 通常是终端输入
fd 1 → standard output → 通常是终端输出
fd 2 → standard error  → 通常是终端错误输出
```

对应宏：

```cpp
STDIN_FILENO   == 0
STDOUT_FILENO  == 1
STDERR_FILENO  == 2
```

这里的 `1` 不是内核中永远具有“输出到屏幕”能力的魔法数字。

更准确的说法是：

```text
Unix 约定 fd 1 是标准输出入口。
进程启动环境通常让 fd 表项 1 指向终端。
程序向 fd 1 写，因此默认看起来是在向终端写。
```

如果把 fd 表项 1 改成指向普通文件：

```text
write(1, ...)
```

自然就会写入文件。

---

# Part 2：教程主体

# 教程开始：为什么程序没改，输出位置却能变？

先看两个命令：

```bash
echo hello
echo hello > output.txt
```

`echo` 的核心输出逻辑没有因为第二条命令而改写。变化的是它启动时的 fd 表：

```text
没有重定向：fd 1 → 终端
使用 > 后 ：fd 1 → output.txt
```

今天要自己写一个程序，完成同样的 fd 表变化。

---

## 1. `dup2` 到底做了什么

函数声明：

```cpp
int dup2(int oldfd, int newfd);
```

可以读成：

```text
把 oldfd 当前引用的打开状态
复制到编号为 newfd 的 fd 表入口上
```

例如：

```cpp
::dup2(output_fd, STDOUT_FILENO);
```

翻译：

```text
来源：output_fd 当前指向的 open file description
目标：编号为 1 的 fd 表入口

结果：fd 1 改为与 output_fd 指向同一个 open file description
```

非常容易写反。下面是错误方向：

```cpp
::dup2(STDOUT_FILENO, output_fd);  // 方向反了
```

它表示让 `output_fd` 变成标准输出的副本，并没有把标准输出改到文件。

记忆句：

```text
dup2(来源 fd, 要改写的目标 fd)
```

---

## 2. 调用前后的 fd 表

假设：

```cpp
int output_fd = ::open("redirected.txt",
                       O_WRONLY | O_CREAT | O_TRUNC,
                       0644);
```

通常前三个 fd 已被标准流占用，所以 `open` 可能返回 `3`。

### `dup2` 前

```text
进程 fd 表

0 → 终端输入对应的 open file description
1 → 终端输出对应的 open file description
2 → 终端错误对应的 open file description
3 → redirected.txt 对应的 open file description
```

### 调用

```cpp
::dup2(3, 1);
```

### `dup2` 后

```text
0 → 终端输入对应的 open file description
1 ─┐
   ├→ redirected.txt 对应的 open file description
3 ─┘
2 → 终端错误对应的 open file description
```

原来 fd 1 指向的终端输出关系被替换。现在 fd 1 和 fd 3 是两个不同的 fd 表入口，但引用同一个 open file description。

因此它们共享：

```text
file offset
file status flags
```

---

## 3. `dup2` 的关键返回值和边界

### 成功

```text
返回 newfd
```

所以：

```cpp
if (::dup2(output_fd, STDOUT_FILENO) == -1) {
    // 失败
}
```

### `newfd` 原本已打开

`dup2` 会先让 `newfd` 脱离原来的资源，再让它成为 `oldfd` 的副本。这个“关闭旧关系 + 安排新关系”由 `dup2` 作为一个原子操作完成。

这里的 **atomic（原子的）** 是：

```text
从其他执行活动的角度看，中间不会暴露出一个可被抢占使用的空 fd 槽位。
```

今天不展开多线程和 signal 竞争，只要知道不要自己机械替换成：

```cpp
::close(newfd);
::dup(oldfd);
```

后者还依赖 `dup` 恰好重新拿到目标编号，并且两步之间存在窗口。

### `oldfd` 无效

如果 `oldfd` 无效，`dup2` 返回 `-1`，并且不会先把合法的 `newfd` 关闭。

### `oldfd == newfd`

如果二者相同且这个 fd 合法，`dup2` 什么也不改，直接返回该 fd。

---

## 4. 成功后为什么可以关闭原 `output_fd`

`dup2` 成功后：

```text
output_fd ─┐
           ├→ 同一个 open file description
fd 1 ──────┘
```

关闭 `output_fd` 只删除其中一个 fd 表入口：

```text
output_fd：关闭
fd 1      ：仍然有效，继续引用文件的 open file description
```

这和 Day3 “关闭一个 duplicated fd，另一个仍能使用”完全相同。

所以资源纪律是：

```text
dup2 成功
→ 如果原 output_fd 不再需要，就关闭它
→ 保留 fd 1 作为程序后续的标准输出
```

今天继续使用 `UniqueFd` 管理 `open` 返回的 owning fd。重定向完成后，通过移动赋值一个空 `UniqueFd`，让多余的原 fd 提前关闭：

```cpp
output_fd = UniqueFd{};
```

标准输出 fd 1 不由这个对象拥有；它作为进程标准 fd，在进程结束时由系统清理。

---

## 5. 为什么 `std::cout`、`printf` 和 `write` 都会进文件

三种输出大致处在不同层：

```text
std::cout
   ↓ C++ iostream 缓冲与格式化
stdout（C 的 FILE*）
   ↓ C stdio 缓冲与格式化
fd 1
   ↓ write 系统调用
内核中的打开资源
```

这张图是理解方向，不要求把每个标准库内部实现机械地看成固定函数调用链。

关键不变量是：

```text
这些“标准输出”接口最终依赖标准输出对应的底层 fd。
fd 1 被重定向后，它们的最终去向也随之改变。
```

而 `stderr` 通常使用 fd 2。今天只修改 fd 1，因此错误信息仍会显示在终端。

---

## 6. 一个容易忽略的缓冲区问题

### 6.1 缓冲区是什么

这里的缓冲区不是之前自己写的 `Buffer` 类，而是 C/C++ 输出库在**用户态内存**中维护的一块临时区域。

如果每输出一个字符都立刻进入内核：

```text
输出 H → 一次系统调用
输出 e → 一次系统调用
输出 l → 一次系统调用
……
```

系统调用有进入内核、检查参数和返回用户态的成本。输出库通常先收集一批数据，再集中写出：

```text
程序连续输出很多小片段
→ 先积累到用户态缓冲区
→ 缓冲区满、主动 flush 或满足其他条件
→ 再用较少次数的底层写入送到 fd
```

所以缓冲区的主要目的不是改变数据，而是减少频繁的小 I/O 操作。

### 6.2 今天先区分三条输出路径

为了建立直觉，可以先画成：

```text
std::cout
→ C++ iostream 的用户态缓冲与格式化
→ flush 时写向标准输出对应的底层 fd

std::printf(...)
→ C stdio 的 stdout 缓冲与格式化
→ fflush(stdout) 时写向 stdout 对应的底层 fd

::write(STDOUT_FILENO, ...)
→ 直接发起 write 系统调用
→ 不经过 std::cout 或 stdout 的用户态输出缓冲
```

真实标准库实现以及 `std::cout` 与 C `stdout` 的同步关系还有细节，今天不读源码。当前只抓住：

```text
std::cout / printf 可能先把内容留在用户态缓冲区
write 是明确地把给定字节交给内核
```

即使 `write` 已经把数据交给内核，也不代表物理磁盘立即完成写入；那还涉及内核页缓存和设备。本日只讨论**系统调用之前的用户态输出缓冲**。

### 6.3 `flush` 到底是什么意思

`flush` 的英文有“冲刷、冲走”的意思。在输出流中可以理解为：

```text
不要继续把已有内容留在用户态缓冲区，
现在就尝试把它送往底层 fd。
```

它不是：

```text
保证数据已经永久写入物理磁盘
```

今天只需要记成：

```text
flush：把输出库缓冲中的数据推到当前底层输出方向
```

### 6.4 `std::cout` 应该怎样 flush

方式一：调用成员函数。

```cpp
std::cout << "message";
std::cout.flush();
```

方式二：使用 `std::flush` 操纵符，只刷新，不自动加换行。

```cpp
std::cout << "message" << std::flush;
```

方式三：使用 `std::endl`，先写换行，再刷新。

```cpp
std::cout << "message" << std::endl;
```

关系：

```text
'\n'       ：只表示换行字符，不应把它当作无条件 flush
std::flush ：flush，不添加换行
std::endl  ：写入 '\n'，然后 flush
```

平时代码如果不需要立即显示，通常使用 `\n` 即可；不要为了换行而处处使用较昂贵的 `std::endl`。在提示用户输入、程序即将等待、改变 fd 或必须立即观察输出时，再明确 flush。

### 6.5 `printf` 应该怎样 flush

`printf` 使用的是 C 标准库的 `stdout`：

```cpp
std::printf("message");

if (std::fflush(stdout) == EOF) {
    ::perror("fflush stdout");
}
```

`fflush` 的正式用途是刷新 C 的输出流。为了记忆，可以把名字中的 `f` 联想到 `FILE`，但不把这个联想冒充成官方词源：

```text
fflush(FILE*)
→ flush 一个 C 标准库流
```

这里的参数 `stdout` 是 `FILE*`，不是整数 fd 1，也不是 `std::cout`。

因此不要把两套接口混成一句“`cout` 完要 `fflush`”。更稳妥的对应关系是：

```text
std::cout  → std::cout.flush() / std::flush / std::endl
printf     → fflush(stdout)
```

C++ 程序默认可能让标准 C++ 流与 C stdio 保持同步，但同步设置可以改变。学习和工程代码中，使用与当前输出接口匹配的 flush 方法更清楚。

### 6.6 哪些时候可能自动 flush

常见情况包括：

```text
缓冲区已经满
程序正常结束，标准库清理输出流
代码显式调用 flush
使用 std::endl
某些与终端、输入流绑定或实现有关的条件
```

但不要依赖模糊印象：

```text
“我写了 \n，所以任何环境一定立刻显示”
“程序最后总会正常退出，所以永远不需要检查 flush”
```

异常终止、崩溃以及后续会学到的 `_exit` 等场景，不一定替你刷新用户态缓冲区。Day5 学 `exit / _exit` 时会继续连接这条线。

### 6.7 为什么重定向前必须考虑缓冲区

考虑：

```cpp
std::cout << "before redirect\n";
::dup2(output_fd, STDOUT_FILENO);
```

第一行在 C++ 层面已经执行，但文字可能还没有真正写向 fd 1：

```text
执行 std::cout << ...
→ 文字暂留在用户态输出缓冲区

执行 dup2(..., 1)
→ fd 1 从终端改为指向文件

之后才 flush
→ 缓冲区数据沿“现在的 fd 1”进入文件
```

所以判断输出去向时，不能只看“哪一行代码先执行”，还要问：

```text
数据是什么时候真正 flush 到 fd 的？
flush 当时 fd 1 指向哪里？
```

所以教学代码在改变 fd 1 之前明确 flush：

```cpp
std::cout << "before redirect\n" << std::flush;
```

这条语句的时间线是：

```text
生成文字
→ 立即 flush
→ 此时 fd 1 仍指向终端
→ 然后才调用 dup2 改写 fd 1
```

如果用 `std::endl` 也可以：

```cpp
std::cout << "before redirect" << std::endl;
```

### 6.8 `write` 为什么没有这个用户态缓冲问题

如果在 `dup2` 前直接调用：

```cpp
constexpr char message[] = "before redirect\n";
::write(STDOUT_FILENO, message, sizeof(message) - 1);
```

成功的 `write` 已经在这一行把字节交给内核，并使用调用当时 fd 1 的指向。因此之后再改变 fd 1，不会让这次已经完成的 `write` 改去新文件。

但 `write` 仍可能出现 short write、`EINTR` 或其他错误，所以真正工程代码仍要检查返回值；这与 Day2 的 `write_all` 是同一原则。

### 6.9 现在应该形成的结论

```text
std::cout 和 printf 可能有用户态输出缓冲
→ 写了输出表达式，不一定代表系统调用已经发生

std::cout 用 C++ 的 flush 接口
printf/stdout 用 fflush(stdout)

dup2 改变的是 fd 表，不会自动替你处理旧的用户态缓冲
→ 改变底层 fd 前，先 flush 应该送往旧目标的数据

write 直接进行系统调用
→ 它不经过 std::cout 或 stdout 的用户态缓冲
```

---

## 7. `redirect_stdout.cpp` 完整教学实现

文件：`redirect_stdout.cpp`

```cpp
/*
功能：
1. 打开用户指定的目标文件。
2. 使用 dup2 把标准输出 fd 1 重定向到该文件。
3. 分别通过 std::cout、printf 和 write 输出，验证三者都会进入文件。
4. 保留 stderr 的原去向，用它输出诊断信息和可选的 lsof 观察提示。

用法：
    ./redirect_stdout <output-file>
    ./redirect_stdout <output-file> --pause

第二种用法会暂停等待回车，便于在另一个终端用 lsof 查看 fd 0、1、2。
*/
#include "../day2/unique_fd.hpp"

#include <cerrno>
#include <cstddef>
#include <cstdio>
#include <fcntl.h>
#include <iostream>
#include <string_view>
#include <unistd.h>

// 把 data 中的 size 个字节全部写入 fd。
// 成功返回 true；失败时打印 errno 对应信息并返回 false。
// fd 只是借用，本函数不拥有它，也不会 close(fd)。
bool write_all(int fd, const char* data, std::size_t size) {
    std::size_t written = 0;

    while (written < size) {
        const ssize_t count =
            ::write(fd, data + written, size - written);

        if (count == -1) {
            if (errno == EINTR) {
                continue;
            }
            ::perror("write");
            return false;
        }

        // 防止极少见的“没有报错但也没有前进”导致死循环。
        if (count == 0) {
            std::fprintf(stderr, "write returned 0 before completion\n");
            return false;
        }

        written += static_cast<std::size_t>(count);
    }

    return true;
}

// 从标准输入 fd 0 读取一个字符，用于让进程暂停，方便运行 lsof。
// 成功或遇到 EOF 返回 true；真实读取错误返回 false。
// STDIN_FILENO 只是借用，本函数不负责关闭它。
bool wait_for_input() {
    char ignored = '\0';

    while (true) {
        const ssize_t count = ::read(STDIN_FILENO, &ignored, 1);
        if (count >= 0) {
            return true;
        }
        if (errno == EINTR) {
            continue;
        }

        ::perror("read stdin");
        return false;
    }
}

// 程序入口：解析目标路径，完成标准输出重定向，并验证三个输出接口的去向。
int main(int argc, char* argv[]) {
    const bool pause_for_lsof =
        argc == 3 && std::string_view(argv[2]) == "--pause";

    if (argc != 2 && !pause_for_lsof) {
        std::fprintf(
            stderr,
            "usage: %s <output-file> [--pause]\n",
            argv[0]);
        return 1;
    }

    // dup2 将要改变 fd 1。先 flush，确保这行仍然进入当前终端。
    std::cout << "before redirect: this line goes to the terminal\n"
              << std::flush;

    // output_fd 是 owning fd，由 UniqueFd 管理。
    UniqueFd output_fd(
        ::open(argv[1], O_WRONLY | O_CREAT | O_TRUNC, 0644));
    if (!output_fd.valid()) {
        ::perror("open output");
        return 1;
    }

    // 复制方向：output_fd 是来源，fd 1 是要被改写的目标表项。
    if (::dup2(output_fd.get(), STDOUT_FILENO) == -1) {
        ::perror("dup2 stdout");
        return 1;
    }

    // 正常启动时 fd 1 原本已被占用，所以 open 通常返回 3 或更大。
    // dup2 成功后，fd 1 已独立保留对文件的引用，可以关闭多余的原 fd。
    // 如果程序启动时 fd 1 本来就是关闭的，open 可能直接返回 1；此时不能提前关闭它。
    if (output_fd.get() != STDOUT_FILENO) {
        output_fd = UniqueFd{};
    }

    // C++ 标准输出：现在最终进入 fd 1 指向的文件。
    std::cout << "written by std::cout\n" << std::flush;
    if (!std::cout) {
        std::fprintf(stderr, "std::cout write failed\n");
        return 1;
    }

    // C 标准输出 stdout：显式 fflush，避免内容继续停留在用户态缓冲区。
    if (std::printf("written by printf\n") < 0 ||
        std::fflush(stdout) == EOF) {
        ::perror("printf/fflush");
        return 1;
    }

    // 直接向标准输出 fd 1 写入，不经过 C/C++ 格式化流。
    constexpr char raw_message[] = "written by write\n";
    if (!write_all(
            STDOUT_FILENO,
            raw_message,
            sizeof(raw_message) - 1)) {
        return 1;
    }

    // fd 2 没有被 dup2 修改，因此这条诊断通常仍显示在终端。
    std::fprintf(
        stderr,
        "stderr: stdout now points to %s\n",
        argv[1]);

    if (pause_for_lsof) {
        std::fprintf(
            stderr,
            "pid=%ld, inspect it from another terminal, then press Enter\n",
            static_cast<long>(::getpid()));

        if (!wait_for_input()) {
            return 1;
        }
    }

    return 0;
}
```

### 为什么这里不复制 `unique_fd.hpp`

Day4 继续包含：

```cpp
#include "../day2/unique_fd.hpp"
```

它表示复用已经写好、已经验收的 fd 所有权类型。不要在 Day4 再复制一份同名类，否则后续修正需要维护多份代码。

### `output_fd = UniqueFd{};` 在做什么

这不是把 fd 1 关闭。

过程是：

```text
1. 构造一个内部 fd 为 -1 的临时 UniqueFd
2. 调用 output_fd 的移动赋值
3. 移动赋值先关闭 output_fd 原来拥有的 fd，例如 fd 3
4. output_fd 接收 -1，变为不持有资源
5. dup2 已经建立的 fd 1 不受影响
```

### `UniqueFd{}` 与 `UniqueFd()` 有区别吗

在这里，你的判断是正确的：

```cpp
output_fd = UniqueFd{};
output_fd = UniqueFd();
```

对于当前这个构造函数：

```cpp
explicit UniqueFd(int fd = -1) noexcept
    : fd_(fd) {
}
```

两种写法都会创建一个没有显式传参的 `UniqueFd`，于是使用默认实参 `-1`：

```text
UniqueFd{}  → 调用 UniqueFd(int fd = -1) → 临时对象的 fd_ 为 -1
UniqueFd()  → 调用 UniqueFd(int fd = -1) → 临时对象的 fd_ 为 -1
```

因此在这两条赋值表达式中，行为没有区别。

语法名称略有区别：

```text
UniqueFd{}：花括号初始化，属于 list-initialization
UniqueFd()：圆括号形式，在这里对临时对象进行 value-initialization
```

但真正让 `output_fd` 原来的 fd 被关闭的，不是“构造空临时对象”这一步，而是后面的**移动赋值**：

```cpp
UniqueFd& operator=(UniqueFd&& other) noexcept {
    if (this == &other) {
        return *this;
    }

    close_current();    // 关闭 output_fd 原来拥有的 fd，例如 3
    fd_ = other.fd_;    // 从空临时对象接收 -1
    other.fd_ = -1;
    return *this;
}
```

所以完整过程是：

```text
构造 fd_ == -1 的临时 UniqueFd
→ 临时对象作为右值，匹配移动赋值 operator=(UniqueFd&&)
→ 移动赋值先关闭 output_fd 原来拥有的 fd
→ output_fd 接收 -1，变成空对象
→ 临时对象析构，因为内部也是 -1，所以不关闭任何 fd
```

为什么代码常偏向写 `{}`？一个实际原因是它在声明对象时可以避开 **most vexing parse（最令人困惑的解析）**：

```cpp
UniqueFd a();  // 会被解析为：声明一个名为 a、返回 UniqueFd 的函数
UniqueFd a{};  // 明确构造一个 UniqueFd 对象
```

花括号还会拒绝某些 narrowing conversion（窄化转换），而且如果类存在 `std::initializer_list` 构造函数，花括号与圆括号可能选择不同构造函数。不过当前 `UniqueFd` 没有这些情况。

今天的结论：

```text
在 output_fd = UniqueFd{} 与 output_fd = UniqueFd() 中，两者效果相同。
使用 {} 只是更符合当前代码风格，也能避开部分初始化语法陷阱。
真正释放旧 fd 的是 UniqueFd 的移动赋值运算符。
```

这正好复用了 Week2 的移动赋值和 Week4 Day2 的 RAII。

---

## 8. 编译和第一次运行

目录：

```bash
mkdir -p ~/code/system-learning/cpp/week4/day4
cd ~/code/system-learning/cpp/week4/day4
```

编译：

```bash
g++ -std=c++17 -Wall -Wextra -g redirect_stdout.cpp -o redirect_stdout
```

运行：

```bash
./redirect_stdout redirected.txt
```

终端预期看到：

```text
before redirect: this line goes to the terminal
stderr: stdout now points to redirected.txt
```

查看目标文件：

```bash
cat redirected.txt
```

预期：

```text
written by std::cout
written by printf
written by write
```

验收重点不是逐字相同，而是：

```text
重定向前并 flush 的 stdout 内容仍在终端
重定向后的三种标准输出都进入文件
stderr 因为使用 fd 2，仍在终端
```

---

## 9. 先手推一次 fd 表

假设标准 fd 正常打开，`open` 返回 `3`。

请在 `fd_table_note.md` 画四张图：

### 图一：程序刚启动

```text
0 → terminal input
1 → terminal output
2 → terminal error
```

### 图二：`open` 后

```text
0 → terminal input
1 → terminal output
2 → terminal error
3 → redirected.txt
```

### 图三：`dup2(3, 1)` 后

```text
0 → terminal input
1 ─┐
   ├→ redirected.txt 的 open file description
3 ─┘
2 → terminal error
```

### 图四：关闭多余的 fd 3 后

```text
0 → terminal input
1 → redirected.txt 的 open file description
2 → terminal error
3 → 已关闭
```

能独立画出这四张图，比背一句“dup2 用于重定向”重要得多。

---

## 10. 用 `strace` 看真实调用

运行：

```bash
strace -o redirect_trace.txt \
    -e trace=openat,dup2,close,write \
    ./redirect_stdout redirected.txt
```

查看：

```bash
cat redirect_trace.txt
```

重点找类似顺序：

```text
openat(..., "redirected.txt", O_WRONLY|O_CREAT|O_TRUNC, 0644) = 3
dup2(3, 1) = 1
close(3) = 0
write(1, ...) = ...
write(2, ...) = ...
```

你的具体 trace 可能还有动态库、locale 和缓冲区产生的其他调用。不要要求每一行与示例完全相同，只确认：

```text
先打开文件
再 dup2 到 fd 1
再关闭多余 fd
后续输出写向 fd 1
诊断信息写向 fd 2
```

---

## 11. 用 `lsof` 看进程当前 fd

终端一：

```bash
./redirect_stdout redirected.txt --pause
```

程序会通过 `stderr` 打印 PID，并等待回车。

终端二：

```bash
lsof -p <PID> -a -d 0,1,2
```

参数：

```text
-p PID：只看指定进程
-a    ：让多个筛选条件同时成立，and
-d    ：只看指定 fd
```

重点观察：

```text
fd 0 通常连接终端输入
fd 1 指向 redirected.txt
fd 2 通常仍连接终端
```

如果系统没有安装 `lsof`，可以先用 Linux `/proc` 观察：

```bash
ls -l /proc/<PID>/fd/0 /proc/<PID>/fd/1 /proc/<PID>/fd/2
```

观察完成后，回到终端一按回车，让程序正常退出。

---

## 12. Shell 的 `>` 可以怎样理解

今天只建立概念流程，不实现 Shell：

```text
Shell 看到：command > output.txt

Shell 安排：
1. 打开 output.txt
2. 让将要运行 command 的环境中，fd 1 指向 output.txt
3. 运行 command

command 仍然只做：
write(1, ...)
```

因此 Unix 工具可以自由组合：

```text
程序负责“输出什么”
Shell 负责“标准输出接到哪里”
```

`>` 通常表示覆盖式重定向，对应目标存在时截断；`>>` 通常表示追加。今天只实现 `>` 的覆盖行为，不展开 Shell 解析和 `O_APPEND`。

---

## 13. 三个常见错误

### 错误一：参数方向写反

```cpp
::dup2(STDOUT_FILENO, output_fd);
```

结果是复制标准输出到 `output_fd` 的槽位，不是重定向标准输出。

### 错误二：`dup2` 失败后仍继续输出

```cpp
::dup2(output_fd, STDOUT_FILENO);
std::cout << "assume success\n";
```

所有系统调用都要检查返回值。失败后程序不能假设 fd 表已经改变。

### 错误三：重定向前不 flush

重定向前写入 `std::cout` 但仍留在用户态缓冲区，之后 flush 时可能进入新目标。判断文字“写在哪一行代码之前”并不足以判断最终去向，还要看它何时真正写到 fd。

---

# Part 3：收尾、验证与验收

## 1. 今日必须完成

```text
[ ] 阅读/听 6.S081 Lec01 1.7 与 1.10 指定内容
[ ] 能区分 std::cout、stdout、STDOUT_FILENO
[ ] 能说清 dup 与 dup2 的区别
[ ] 能把 dup2(oldfd, newfd) 的方向说对
[ ] 完成 redirect_stdout.cpp
[ ] 使用 -std=c++17 -Wall -Wextra -g 编译无 warning
[ ] 验证 cout / printf / write 都进入目标文件
[ ] 验证 stderr 仍进入终端
[ ] 画出四个阶段的 fd 表
[ ] 运行一次 strace
[ ] 运行一次 lsof，或在 lsof 不可用时观察 /proc/<PID>/fd
[ ] 完成 fd_table_note.md 的验收题
```

---

## 2. `fd_table_note.md` 建议结构

今天不再重复抄 Day3 的 `dup` 共享 offset 定义。只记录：

```text
1. 三个标准 fd 的英文、数字和默认用途
2. std::cout / stdout / STDOUT_FILENO 的层次区别
3. open、dup2、关闭原 fd 后的四张 fd 表图
4. 一段关键 strace
5. 一次 lsof 或 /proc 观察结果
6. 今天答错或不确定的问题
7. 下方验收题答案
```

代码中的机械步骤已经有注释，不需要逐行复制到笔记里。

---

## 3. 今日验收题

请在 `fd_table_note.md` 逐题回答：

```text
1. STDIN_FILENO、STDOUT_FILENO、STDERR_FILENO 分别是什么英文，值通常是多少？
2. fd 1 为什么默认输出到终端？数字 1 本身有“终端输出”能力吗？
3. std::cout、stdout、STDOUT_FILENO 分别是什么类型或哪一层对象？
4. dup(oldfd) 和 dup2(oldfd, newfd) 在选择新 fd 数字上有什么区别？
5. dup2(output_fd, STDOUT_FILENO) 中，谁是来源，谁是被改写的目标？
6. 如果 STDOUT_FILENO 原本已经指向终端，dup2 成功时原关系怎样了？
7. dup2 成功后，output_fd 与 fd 1 共享什么？
8. 为什么 dup2 成功后可以关闭原 output_fd，而 fd 1 仍然有效？
9. 今天的代码为什么在 dup2 前 flush std::cout？
10. fd 1 被重定向后，为什么 std::cout、printf 和 write(1, ...) 都进入文件？
11. 为什么 perror / fprintf(stderr, ...) 仍显示在终端？
12. dup2 的 oldfd 无效时会怎样？合法的 newfd 会先被关闭吗？
13. dup2(oldfd, oldfd) 在 oldfd 合法时会怎样？
14. 为什么 close(newfd) 再 dup(oldfd) 不如 dup2(oldfd, newfd) 明确可靠？
15. strace 中哪几类调用能证明重定向已经建立并被使用？
16. lsof 或 /proc/<PID>/fd 中，什么现象能证明只有 stdout 被重定向？
17. 用自己的话解释 Shell 的 command > output.txt 为什么不要求 command 修改输出代码。
```

---

## 4. 今日不提前深挖

```text
不实现 fork
不实现 exec
不实现 pipe
不实现完整 Shell
不讨论 pipeline
不展开 job control
不展开 dup3 和 FD_CLOEXEC
不深入 stdio / iostream 内部源码
不深入多线程和信号下的 fd 竞争
```

---

## 5. 下一天衔接

Day5 进入：

```text
fork
父进程与子进程
fork 的两次返回
wait / waitpid
exit / _exit 的第一层区别
```

今天先压稳：

```text
标准输出不是“屏幕”本身
→ 它首先是约定的 fd 1
→ dup2 可以改写 fd 表项 1
→ 上层输出接口不需要知道底层接的是终端还是文件
→ 这就是 I/O redirection 能组合 Unix 工具的基础
```
