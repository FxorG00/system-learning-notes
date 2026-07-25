# Week4 Day7：`mmap` / signal 初步 + Week4 出口复盘

> 今日定位：教学日与 Week4 收尾日。
>
> 主线只有三件事：理解 `mmap` 建立文件到虚拟地址空间的映射；建立 signal 的第一层直觉；把本周 fd / process / pipe / exec 串成一张完整状态图。
>
> 今天不提前深入页表、page fault 内核实现、完整 `sigaction`、异步信号安全或多线程信号处理。

---

# Part 1：前情提要与必要术语

## 1. 从 Day6 接到 Day7

Day6 已经掌握：

```text
pipe() 在内核创建 pipe buffer，并返回 read/write 两个新 fd
fork() 让 child 继承调用时已经存在的 fd 关系
父子分别关闭不用的 pipe 端
所有 write end 关闭后，reader 才能在读空后看到 EOF
dup2 + exec 可以让新程序继续使用事先安排好的 fd 1
parent 在读取 pipe 后 wait child
```

你已经看到了两类“通过 fd 访问内核资源”的方式：

```text
普通文件：read(fd, buffer, size) 把字节复制进用户缓冲区
pipe：write/read 在用户缓冲区与 kernel pipe buffer 之间复制字节
```

今天从一个新问题出发：

```text
能不能不反复调用 read 把文件复制到自建 char 数组，
而是让文件内容直接出现在进程可访问的一段虚拟地址中？
```

这就是 `mmap` 的第一层用途。

---

## 2. 今日真正需要的英文术语

### 2.1 `mmap`

`mmap` 可以按 **memory map / memory mapping** 理解：内存映射。

它在调用进程的虚拟地址空间中创建一段 mapping，让一段虚拟地址关联到文件或匿名内存。

记忆钩子：

```text
read：把文件字节复制到我的 buffer
mmap：给我的地址空间增加一段“通过地址访问文件内容”的映射
```

### 2.2 mapping

**mapping：映射关系。**

今天只需理解：

```text
一段虚拟地址范围 <-> 文件中的一段内容
```

`mmap` 不是返回一个 C 字符串，也不保证末尾存在 `\0`。

### 2.3 `munmap`

`munmap` 可以按 **memory unmap** 理解：解除内存映射。

成功解除后，原来的地址范围不再属于这段 mapping，继续解引用原指针就是错误。

### 2.4 virtual address space

**virtual address space：虚拟地址空间。**

每个进程看到的是自己的虚拟地址视图。相同的虚拟地址数字，在不同进程中可以映射到不同物理内存。

今天只建立这个直觉；页表结构、TLB 和 page fault 的完整机制进入 Week5。

### 2.5 protection 与 `PROT_READ`

**protection：访问保护。** `prot` 是 protection 的缩写。

```text
PROT_READ  -> 允许读取映射
PROT_WRITE -> 允许写入映射
PROT_EXEC  -> 允许执行映射中的指令
PROT_NONE  -> 不允许访问
```

今天只使用 `PROT_READ`。

### 2.6 `MAP_PRIVATE` 与 `MAP_SHARED`

- `private`：私有。
- `shared`：共享。

第一层区别：

```text
MAP_PRIVATE：对映射的修改不写回原文件，按 copy-on-write 语义理解
MAP_SHARED ：修改可以对其他共享映射可见，并可反映到底层文件
```

今天建立只读 `MAP_PRIVATE` mapping，不做文件写回实验。

### 2.7 signal

**signal：信号。** 这里不是缩写。

signal 是内核向进程或线程递送的一种异步事件通知。它可以改变进程的控制流，但不是普通代码中的函数调用。

### 2.8 `SIGINT` 与 `SIGTERM`

- `SIG`：signal。
- `INT`：interrupt，打断。
- `TERM`：terminate，终止。

```text
SIGINT  -> 常由终端 Ctrl-C 发给前台进程组，默认终止进程
SIGTERM -> 通常表示请求进程终止，默认终止进程
```

`kill` 命令的核心作用是发送 signal，不是无条件“杀死”。例如 `kill -TERM PID` 发送的是 `SIGTERM`。

### 2.9 privileged instruction

**privileged instruction：特权指令。**

只有处于足够高权限模式的 CPU 才允许执行，例如修改页表相关控制状态、控制中断等。用户程序不能随意执行这些指令。

### 2.10 ECALL

`ECALL`：**Environment Call**，RISC-V 的受控环境调用指令。

MIT 6.S081 使用 RISC-V/xv6，所以课程用 ECALL 解释用户态怎样受控进入内核。你的 Ubuntu 很可能运行在 x86-64 上，具体机器指令通常是 `syscall`，但“不能直接跳进内核，必须经过受控入口”的思想相同。

### 2.11 TCB

`TCB`：**Trusted Computing Base，可信计算基。**

课程在 `3.6` 中用它描述必须被信任、必须尽量正确的内核部分。今天只需要认识，不背安全理论。

---

## 3. 今日边界

### 核心完成线

```text
理解 mmap 创建的是当前进程虚拟地址空间中的 mapping
会使用 open / fstat / mmap / munmap 完成只读文件映射
知道 mmap 失败返回 MAP_FAILED，而不是 nullptr
知道长度为 0 不能建立今天这种文件 mapping
知道 mmap 成功后 close(fd) 不会让 mapping 失效
知道 munmap 后地址不能继续使用
观察 SIGINT / SIGTERM 的默认行为
理解 user mode 通过受控 system call 入口请求 kernel 服务
```

### 工程增强项，不阻塞 Day7

```text
为 mapping 再写一个完整 RAII 类
处理超大文件分段映射
MAP_SHARED 写回与 msync
匿名映射
安装 sigaction handler
异步信号安全函数清单
多线程 signal mask
```

---

# Part 2：教程主体

# 教程开始：不用 `read` 自建数组，怎样通过地址访问文件？

## 4. 先把 `read` 与 `mmap` 放在同一张图里

### 4.1 `read` 路径

```text
文件
  |
  | read(fd, user_buffer, size)
  v
由你申请和管理的 char buffer
```

程序需要循环 `read`，每次系统调用把一部分字节复制到用户缓冲区。

### 4.2 `mmap` 路径

```text
当前进程虚拟地址空间

普通代码 / heap / stack / ... / 新 mapping
                                |
                                v
                         文件中的对应内容
```

`mmap` 成功后返回 mapping 的起始地址。程序可以像访问一段内存一样，通过这个地址读取文件内容。

但不要误解成：

```text
mmap 一调用，内核就一定立即把整个文件读入物理内存。
```

更准确的第一层表述是：`mmap` 先建立虚拟地址映射关系；真正访问页面时可能再由 page fault 等机制准备数据。详细过程留到 Week5。

---

## 5. `mmap` API：参数到底在描述什么

头文件：

```cpp
#include <sys/mman.h>
```

签名按今天使用方式理解：

```cpp
void* mmap(
    void* address,
    std::size_t length,
    int protection,
    int flags,
    int fd,
    off_t offset
);
```

参数：

```text
address    -> 希望映射放在哪里；今天传 nullptr，让内核选择地址
length     -> 映射多少字节；必须大于 0
protection -> 允许怎样访问；今天使用 PROT_READ
flags      -> private 还是 shared；今天使用 MAP_PRIVATE
fd         -> 哪个已打开文件作为映射来源
offset     -> 从文件哪个偏移开始；今天使用 0
```

今天的独立调用形式：

```cpp
void* address = ::mmap(
    nullptr,
    length,
    PROT_READ,
    MAP_PRIVATE,
    fd,
    0
);
```

返回值：

```text
成功 -> mapping 的起始地址
失败 -> MAP_FAILED，并设置 errno
```

必须这样判断：

```cpp
if (address == MAP_FAILED) {
    ::perror("mmap");
}
```

不能写成 `address == nullptr`。`nullptr` 在这里是传入参数，表示“请内核选择地址”；失败标记是另一个值 `MAP_FAILED`。

Linux `mmap(2)` 还规定：文件 offset 需要满足页对齐要求。今天固定使用 `0`，不做部分文件映射。

资料：[Linux mmap(2) manual](https://man7.org/linux/man-pages/man2/mmap.2.html)。

---

## 6. `munmap`：mapping 也有生命周期

签名：

```cpp
int munmap(void* address, std::size_t length);
```

参数必须对应需要解除的地址范围：

```text
address -> mmap 成功返回的起始地址
length  -> 要解除的映射长度
```

返回值：

```text
0  -> 成功
-1 -> 失败，errno 说明原因
```

成功之后：

```text
address 不再代表可用 mapping
不能继续读取 address[i]
不能让指向这段区域的指针或 view 继续被使用
```

这和前面学过的资源生命周期是一致的：

```text
new       <-> delete
new[]     <-> delete[]
open      <-> close
mmap      <-> munmap
```

当前 demo 手动调用 `munmap`，先把系统调用状态看清楚；今天不要求再封装 `MappedRegion`。

---

## 7. mapping 和 fd 谁依赖谁？

这是今天最重要的生命周期问题。

调用 `mmap` 前：

```text
fd -> 打开的文件状态 -> 文件
```

`mmap` 成功后，当前进程多了一段独立存在的 mapping：

```text
当前进程 fd 表                 当前进程虚拟地址空间
fd -> 打开的文件状态           address...address+length -> file mapping
```

这时可以关闭 fd：

```text
close(fd)

fd 入口消失
mapping 仍然有效
```

原因不是 mapping “拥有这个 fd”，而是 `mmap` 成功时内核已经建立了 mapping 所需的内核关系。关闭原 fd 不会自动调用 `munmap`。

最终：

```text
munmap(address, length)
-> 删除 mapping
-> 原地址失效
```

所以今天的资源顺序是：

```text
open -> fstat -> mmap -> close(fd) -> 使用 mapping -> munmap
```

这是机制顺序，不是要求所有工程代码永远使用同一种包装方式。

---

## 8. 教学 demo：`mmap_basic.cpp`

### 8.1 程序解决什么问题

程序接收一个小型普通文件路径：

```bash
./mmap_basic note.txt
```

它会：

```text
open 文件
fstat 取得文件长度
空文件直接结束，不调用 length=0 的 mmap
mmap 建立只读 private mapping
close 原 fd，验证 mapping 生命周期独立于 fd
按 [0, length) 访问映射字节并输出
munmap 解除映射
```

### 8.2 完整代码

```cpp
/*
目标：把一个小型普通文件只读映射到当前进程的虚拟地址空间，
      关闭原 fd 后通过 mapping 输出文件内容，最后解除映射。
验证：非空文件输出应与原内容一致；空文件正常退出；不存在文件报告错误。
*/
#include <cstddef>
#include <cstdio>
#include <fcntl.h>
#include <iostream>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::fprintf(stderr, "usage: %s <file>\n", argv[0]);
        return 1;
    }

    const int fd = ::open(argv[1], O_RDONLY);
    if (fd == -1) {
        ::perror("open");
        return 1;
    }

    struct stat file_info {};
    if (::fstat(fd, &file_info) == -1) {
        ::perror("fstat");
        ::close(fd);
        return 1;
    }

    // mmap 的 length 必须大于 0；空文件没有字节需要映射。
    if (file_info.st_size == 0) {
        if (::close(fd) == -1) {
            ::perror("close");
            return 1;
        }
        return 0;
    }

    if (file_info.st_size < 0) {
        std::fprintf(stderr, "invalid negative file size\n");
        ::close(fd);
        return 1;
    }

    const std::size_t length =
        static_cast<std::size_t>(file_info.st_size);

    // 创建当前进程的只读私有文件映射，让内核选择起始地址。
    void* const address = ::mmap(
        nullptr,
        length,
        PROT_READ,
        MAP_PRIVATE,
        fd,
        0
    );

    if (address == MAP_FAILED) {
        ::perror("mmap");
        ::close(fd);
        return 1;
    }

    // mmap 成功后，关闭 fd 不会使已经建立的 mapping 失效。
    if (::close(fd) == -1) {
        ::perror("close");
        ::munmap(address, length);
        return 1;
    }

    const auto* const bytes = static_cast<const char*>(address);

    // mapping 不是 C 字符串，只能访问 [0, length)，不能寻找 '\0'。
    for (std::size_t i = 0; i < length; ++i) {
        std::cout.put(bytes[i]);
    }

    if (!std::cout) {
        std::fprintf(stderr, "stdout write failed\n");
        ::munmap(address, length);
        return 1;
    }

    // 解除成功后，bytes/address 都不能再用于访问这段区域。
    if (::munmap(address, length) == -1) {
        ::perror("munmap");
        return 1;
    }

    return 0;
}
```

### 8.3 为什么 mapping 不能按字符串处理

`mmap` 给你的是：

```text
起始地址 + 明确长度
```

不是：

```text
保证以 '\0' 结尾的 C 字符串
```

这和 Day6 的 pipe 一样：系统调用处理的是字节范围，业务代码必须自己维护长度边界。

---

## 9. `MAP_PRIVATE` 今天到底 private 在哪里

今天的 mapping 是只读的，所以不会真正观察到写时复制。但仍要知道标志语义：

```text
MAP_PRIVATE + PROT_READ
-> 当前进程只读访问文件映射
-> demo 不会通过 mapping 修改原文件
```

以后若使用：

```text
MAP_PRIVATE + PROT_WRITE
```

对 mapping 的写入按 private copy-on-write 处理，不写回底层文件。

`MAP_SHARED` 才是研究共享可见性和文件写回的方向。`msync`、一致性边界和多个进程共同映射留到后续，不在 Day7 展开。

---

## 10. signal：为什么说它不是普通函数调用

普通函数调用由当前代码主动决定：

```text
main -> foo() -> foo return -> main 继续
```

signal 的来源可能在当前执行流之外：

```text
终端 Ctrl-C
另一个进程发送 signal
内核检测到某些事件
```

递送 signal 后，进程按该 signal 当前的 disposition 行动。

**disposition：处置方式。** 第一层有三类：

```text
default -> 执行该信号默认动作
ignore  -> 忽略
handler -> 执行程序注册的处理函数
```

今天只观察 default，不注册 handler。

为什么不急着写 handler？因为 handler 可能在普通代码执行到任意位置时介入。很多平时能调用的库函数不能在异步 handler 中安全使用，正式写法应从 `sigaction`、signal mask 和 async-signal-safe 规则一起学。

资料：[Linux signal(7) overview](https://man7.org/linux/man-pages/man7/signal.7.html)。

---

## 11. 最小 signal 默认行为观察

### 11.1 观察程序

下面的程序只打印 PID，然后通过 `pause()` 等待 signal。它没有安装 handler，所以 `SIGINT` 和 `SIGTERM` 会执行默认终止动作。

```cpp
/*
目标：观察 SIGINT 和 SIGTERM 的默认行为，不安装 signal handler。
验证：运行后用 Ctrl-C 或 kill -TERM PID，进程应被对应 signal 终止。
*/
#include <iostream>
#include <unistd.h>

int main() {
    std::cout << "pid=" << ::getpid() << '\n'
              << "waiting for SIGINT or SIGTERM...\n"
              << std::flush;

    while (true) {
        // pause 让当前进程睡眠，直到 signal 被递送。
        // 今天使用默认处置，因此 SIGINT/SIGTERM 会直接终止进程。
        ::pause();
    }
}
```

文件名可用：

```text
signal_observe.cpp
```

`pause()`：暂停当前进程或线程，直到 signal 导致进程终止，或者某个已安装 handler 执行后返回。今天没有 handler，因此重点只看终止现象。

资料：[Linux pause(2) manual](https://man7.org/linux/man-pages/man2/pause.2.html)。

### 11.2 观察 `SIGINT`

```bash
g++ -std=c++17 -Wall -Wextra -g signal_observe.cpp -o signal_observe
./signal_observe
```

在同一个终端按 `Ctrl-C`。

状态关系：

```text
终端驱动把 SIGINT 发给前台进程组
-> signal_observe 收到 SIGINT
-> 没有自定义 handler
-> 执行 SIGINT 默认动作：终止
```

Shell 中常见的 `$? == 130` 是 Shell 用 `128 + signal number` 表示“进程被 SIGINT 终止”的约定，不是程序从 `main` 主动 `return 130`。

### 11.3 观察 `SIGTERM`

终端一：

```bash
./signal_observe
```

记下它打印的 PID。

终端二：

```bash
kill -TERM <PID>
```

状态关系：

```text
kill 命令请求内核向 PID 发送 SIGTERM
-> signal_observe 收到 SIGTERM
-> 执行默认终止动作
```

不要把 signal 和硬件 interrupt 当成同一个层次。signal 是内核递送给进程/线程的机制；硬件 interrupt 是 CPU/设备与内核控制流相关的机制。两者可能在完整系统中发生联系，但不能直接画等号。

---

## 12. MIT 6.S081：今天听到哪里

**Lecture：Lec03 OS Organization and System Calls，第二部分。**

### 必读

1. [3.4 硬件对于强隔离的支持](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/lec03-os-organization-and-system-calls/3.4-ying-jian-dui-yu-qiang-ge-li-de-zhi-chi)
2. [3.5 User/Kernel mode 切换](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/lec03-os-organization-and-system-calls/3.5-user-kernel-mode-switch)

### 可选

3. [3.6 宏内核 vs 微内核](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/lec03-os-organization-and-system-calls/3.6-monolithic-kernel-vs-micro-kernel)

建议投入：

```text
3.4：15~20 分钟
3.5：15~20 分钟
3.6：可选 10~15 分钟
```

### 停止位置

读完 `3.5` 的课堂问答即可完成必读。`3.6` 只需要读完宏内核与微内核的第一层取舍。

今天不要继续进入：

```text
3.7 编译运行 kernel
3.8 QEMU
3.9 xv6 启动过程
Lec04 Page Tables
Lec06 完整 trap entry/exit
Lec08 Page Faults
Lec09 Interrupts
```

---

## 13. 顺着课程讲解 `3.4`：隔离为什么需要硬件支持

课程先提出：如果只靠大家“自觉不碰别人的资源”，隔离就不可靠。因此硬件至少提供两类重要支持。

### 13.1 user mode 与 kernel mode

```text
user mode
-> 可以执行普通计算、跳转、访存等非特权指令
-> 不能直接执行操纵关键硬件和保护状态的特权指令

kernel mode
-> 内核可以执行特权指令
-> 负责配置和保护系统资源
```

CPU 会根据当前 privilege mode 检查指令是否合法。用户程序不能通过普通指令把自己随意改成 kernel mode，否则隔离就失去意义。

课程在 RISC-V 语境中还提到 machine mode。Day7 只保留两层主图：用户代码受限，内核拥有受控特权；RISC-V 具体三级权限以后再补。

### 13.2 每个进程的虚拟内存视图

课程接着用 page table 建立第二层隔离直觉：

```text
process A virtual address 0 -> physical region A
process B virtual address 0 -> physical region B
```

两个进程可以都看到虚拟地址 `0`，但操作系统通过各自的 page table 让它们对应不同物理内存。进程不能仅靠编造地址就访问另一个进程没有映射给它的内存。

这正好解释今天 `mmap` 的位置：`mmap` 请求内核修改的是**当前进程的虚拟地址空间映射**。但页表如何建立、第一次访问为何可能 page fault，留到 Week5。

---

## 14. 顺着课程讲解 `3.5`：不能直接进内核，system call 怎么发生？

课程发现一个看似矛盾的问题：

```text
用户程序不能执行特权指令，也不能直接调用内核内部函数；
但 open/read/fork/mmap 又必须请求内核服务。
```

你的理解方向是对的：

```text
用户程序提出 mmap 请求
-> 进入 kernel
-> kernel 检查并执行
-> 返回 user mode
```

现在缺少的是：用户程序到底怎样“进入 kernel”，以及“CPU 把控制权转给内核”究竟是什么意思。

### 14.1 先分清三样东西

#### `mmap()`：用户代码看到的函数接口

你写：

```cpp
void* address = ::mmap(nullptr, length, PROT_READ, MAP_PRIVATE, fd, 0);
```

这里的 `mmap()` 首先是用户空间里可以调用的函数接口。在 Linux 上，通常由 C 标准库实现一层很薄的包装；你的程序不能用普通 C++ 函数调用直接跳到内核中的 `mmap` 实现。

#### system call wrapper：系统调用包装函数

`wrapper` 是“包装层”的意思。

包装函数主要负责：

```text
把 system call number 放进约定的寄存器
把 fd / length / flags 等参数放进约定的寄存器
执行进入内核所需的特殊 CPU 指令
拿到内核返回值，并转换成用户代码看到的返回形式
```

所以，“用户程序调用系统调用包装函数”确实是在描述 system call 过程的第一步，但**调用包装函数本身仍然只是 user mode 中的普通函数调用**。真正跨过 user/kernel 边界的是后面的特殊指令。

#### `ECALL`：让 CPU 受控进入内核的指令

`ECALL` 是 **Environment Call，环境调用**。

它是 RISC-V 的一条 CPU 指令，不是 C++ 函数，也不是一个新的进程。它表达的请求是：

```text
“当前用户程序需要更高权限的软件环境提供服务。”
```

在 xv6/RISC-V 中，包装代码会先把系统调用编号和参数准备好，再执行 `ecall`。例如：

```text
system call number：我请求的是 mmap、read 还是 fork
arguments：这次请求使用的 fd、地址、长度、flags 等数据
ECALL：现在按照硬件规定的入口进入内核
```

你的 Ubuntu 很可能是 x86-64，它通常使用名为 `syscall` 的 CPU 指令完成类似动作。课程讲 `ECALL`，是因为 xv6 使用 RISC-V；两者的核心思想相同。

### 14.2 “CPU 把控制权转到内核”是什么意思？

这里的“控制权”不是传递了一个 C++ 对象，而是：

```text
CPU 接下来执行谁的指令？
CPU 当前使用 user mode 还是 kernel mode？
```

执行 `ECALL` 后，CPU 硬件会完成一段受保护的切换：

```text
1. 记住用户程序应该从哪里继续执行
2. 从 user mode 切换到 kernel mode
3. 跳到一个由内核提前设置好的固定入口
4. 从这个入口开始执行内核代码
```

这时仍然是**同一个进程中的同一个执行流**，没有发生 `fork`，也没有变成另一个程序。只是 CPU 暂时代表这个进程执行内核代码。

用户程序不能决定跳到哪一段内核代码。入口地址由内核提前配置，因此这叫 **controlled entry，受控入口**。

### 14.3 进入内核后，怎么知道要执行哪个 system call？

所有系统调用可以先进入同一个内核入口。内核再读取包装函数准备好的 system call number：

```text
number 表示 read  -> 分派到内核的 read 实现
number 表示 fork  -> 分派到内核的 fork 实现
number 表示 mmap  -> 分派到内核的 mmap 实现
```

`dispatch` 的意思是“分派”：根据编号选择具体处理函数。

因此完整主干是：

```text
用户代码调用 mmap() 包装函数
-> 包装函数准备 system call number 和参数
-> 包装函数执行 ECALL（RISC-V）或 syscall（x86-64）指令
-> CPU 切换到 kernel mode，并跳到内核规定的统一入口
-> 内核根据 number 分派到具体系统调用实现
-> 内核检查参数、权限和当前进程状态
-> 内核执行请求
-> 内核放好返回值
-> CPU 恢复 user mode，从特殊指令之后继续执行
-> 包装函数把结果返回给你的 C++ 代码
```

### 14.4 用今天的 `mmap()` 完整走一遍

```text
你的 C++ 代码：
    mmap(nullptr, length, PROT_READ, MAP_PRIVATE, fd, 0)

用户空间包装函数：
    准备 mmap 的编号和六个参数
    执行进入内核的特殊指令

CPU 硬件：
    保存返回用户程序所需的状态
    user mode -> kernel mode
    跳到内核规定的入口

内核：
    识别这是 mmap 请求
    检查 fd、length、protection、flags、offset
    成功时给当前进程增加一段 virtual memory mapping
    准备返回 mapping 起始地址；失败则准备错误信息

CPU 与包装函数：
    kernel mode -> user mode
    回到特殊指令后面
    包装函数最终向你的代码返回地址，失败时返回 MAP_FAILED
```

所以你原来的理解可以补成一句完整的话：

```text
mmap() 先在 user mode 调用包装函数；
包装函数通过 ECALL/syscall 指令让 CPU 从受控入口进入 kernel；
kernel 检查并修改当前进程的虚拟地址空间；
随后 CPU 回到 user mode，mmap() 把结果交给用户代码。
```

关键不是“用户可以选择任意内核地址跳进去”，而是：

```text
入口由内核控制
请求编号由内核解释
参数由内核验证
最终是否允许、怎样执行由内核决定
```

今天只需要理解这条主干。CPU 具体保存哪些寄存器、trap entry 怎样保存现场、返回指令怎样恢复状态，会在后面的 trap 课程中展开。

课程学生还问：恶意程序如果一直死循环，内核怎么重新获得 CPU？课程给出定时器让控制权回到内核并进行调度的第一层答案。调度和 context switch 是 Week5 主线，今天到此为止。

---

## 15. `3.6` 可选：宏内核与微内核只记一层

课程先引入 TCB：内核属于必须被信任的部分，内核 bug 可能破坏整个系统隔离。

### monolithic kernel

**monolithic：整体式的。**

```text
更多 OS 服务运行在 kernel mode
模块之间集成紧密，通常有利于性能
内核代码量和可信范围更大，bug 影响可能更严重
```

Linux 与 xv6 按课程当前分类属于宏内核设计。

### microkernel

**microkernel：微内核。**

```text
kernel mode 中只保留较少核心机制
文件系统等服务可以放到 user mode
隔离边界更细，内核可信代码更少
服务之间常需要更多 IPC 与 user/kernel 切换，性能设计更困难
```

今天不背“谁一定更好”。只理解这是可信范围、隔离、模块组织和性能之间的设计取舍。

---

## 16. Week4 的完整主线终于可以连起来了

| 接口/机制 | 当前进程发生了什么 | 内核对象或状态 |
|---|---|---|
| `open` | fd 表增加一个整数入口 | 打开的文件状态与文件 |
| `read/write` | 在用户 buffer 与内核资源之间传递字节 | 文件、pipe 等 |
| `dup/dup2` | 新增或改写 fd 表项 | 多个 fd 可引用同一打开状态 |
| `fork` | 创建 child，并继承调用时的 fd 关系 | 两个执行流、独立地址空间 |
| `pipe` | fd 表增加 read/write 两个新入口 | kernel pipe buffer |
| `exec` | 替换当前进程映像，PID 不变 | 未关闭 fd 默认继续存在 |
| `waitpid` | parent 等待并回收指定 child | child 退出状态 |
| `mmap` | 虚拟地址空间增加 mapping | 文件映射关系 |
| `munmap` | 删除指定 mapping | 地址范围失效 |
| signal | 进程可能异步改变控制流或状态 | 内核递送事件通知 |

这张表比死记函数签名更重要。Week5 会开始解释这些可观察行为背后的 OS 机制。

---

# Part 3：收尾、验证与验收

## 17. 今日产出

核心：

```text
week4/day7/mmap_basic.cpp
week4/day7/day7_note.md
```

建议保留的小观察程序：

```text
week4/day7/signal_observe.cpp
```

不要求新写 RAII mapping 类，也不要求复制 Week4 全部旧笔记。

---

## 18. 编译与运行

### 18.1 `mmap_basic`

```bash
printf 'hello mmap\nsecond line\n' > note.txt
g++ -std=c++17 -Wall -Wextra -g mmap_basic.cpp -o mmap_basic
./mmap_basic note.txt
echo $?
```

再覆盖两个必要边界：

```bash
: > empty.txt
./mmap_basic empty.txt
./mmap_basic definitely_not_exists.txt
```

观察：

```text
普通文件：输出与文件字节一致，退出 0
空文件：不调用 length=0 的 mmap，正常退出 0
不存在文件：open 报错，程序非 0 退出
```

### 18.2 `signal_observe`

```bash
g++ -std=c++17 -Wall -Wextra -g signal_observe.cpp -o signal_observe
./signal_observe
```

分别观察一次：

```text
Ctrl-C -> SIGINT 默认终止
kill -TERM PID -> SIGTERM 默认终止
```

---

## 19. 工具观察

### 核心观察：`strace`

```bash
strace -e trace=openat,newfstatat,mmap,munmap,close \
  ./mmap_basic note.txt
```

注意：程序启动和动态库加载本身也会产生很多 `mmap`，不要看到数量多就认为代码重复调用了很多次。重点寻找与你的 `note.txt`、文件大小查询、最终 mapping 和 `munmap` 对应的调用。

### 快速复盘：`ps` / `lsof` / `top`

让 `signal_observe` 保持运行，然后在另一终端使用：

```bash
ps -o pid,ppid,stat,cmd -p <PID>
lsof -p <PID>
top -p <PID>
```

今天只要能说出：

```text
ps   -> 进程身份、父子关系和状态
lsof -> 进程当前打开的 fd/文件等资源
top  -> 运行中的 CPU、内存等动态状态
strace -> 程序实际发起的系统调用及返回值
```

不要求抄长输出。

---

## 20. 最小 note 要求

`day7_note.md` 只保留今天新增内容与真实问题：

```markdown
## mmap
- 我怎样理解 mapping
- mmap 成功后 fd 与 mapping 的生命周期
- MAP_FAILED / length == 0 / munmap 后失效

## signal
- SIGINT 与 SIGTERM 的实际观察
- 为什么 signal 不是普通函数调用

## MIT 6.S081
- user mode 为什么不能执行特权指令
- system call 为什么必须经过受控入口

## 今日真实问题
- 只写确实卡住或容易混淆的点；没有就写“无”
```

不用重新抄 Week4 的 fd、fork、pipe、exec 教程，也不用写二十道验收回答。

---

## 21. 今日 6 个验收问题

1. `read` 文件与 `mmap` 文件在程序使用方式上的核心区别是什么？
2. 为什么 `mmap` 失败要比较 `MAP_FAILED`，而且空文件不能直接按 length 0 映射？
3. `mmap` 成功后为什么可以关闭 fd？`munmap` 后原地址又为什么不能继续使用？
4. `MAP_PRIVATE` 与 `MAP_SHARED` 的第一层区别是什么？
5. `SIGINT`、`SIGTERM` 分别表达什么？为什么 signal handler 不能简单当作普通函数调用理解？
6. 用户程序不能直接执行特权指令时，system call 怎样把请求受控地交给内核？

这些问题只检查 Day7 新机制。Week4 旧内容能从你的代码和已有 note 证明，不要求重复默写。

---

## 22. Day7 通过标准

### 核心通过

```text
mmap_basic 使用规定参数零 warning 编译
普通文件、空文件和不存在文件三个场景符合预期
能够解释 fd、mapping、munmap 三者生命周期
观察到 SIGINT 与 SIGTERM 的默认行为
能够画出 user mode -> system call entry -> kernel -> return 的第一层流程
能够回答上面的 6 个新问题
```

### 可选加分，不影响进入 Week5

```text
用 strace 找到自己 mmap_basic 对应的关键系统调用
用 ps/lsof/top 观察 signal_observe
阅读 3.6 并能说出宏内核与微内核的一组取舍
```

---

## 23. Week4 出口与下一步

完成 Day7 后，Week4 的接口经验形成：

```text
文件与 fd
字节流读写
文件状态与偏移
dup/dup2 与重定向
fork/wait 与进程生命周期
pipe/exec 与进程组合
mmap 与虚拟地址空间入口
signal 的异步通知直觉
strace/lsof/ps/top 的第一层观察能力
```

Week5 将从“会调用并能观察”进入“解释为什么”：

```text
user mode / kernel mode
system call 与 trap
virtual memory / page table
process / thread
context switch / scheduler
fork / COW
blocking IO
```

Day7 不提前展开这些实现细节。先把今天的 mapping 与系统调用边界真正跑通。
