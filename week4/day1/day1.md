# Week4 Day1：从普通 C++ 程序走进 Linux 内核

> 今日定位：Week3 已经完成 C++ 资源管理和 STL 第一轮。今天开始进入 Linux 系统编程。  
> 教程从一个明确问题出发：**一个普通 C++ 程序不使用 `std::ifstream`，怎样请求 Linux 内核读取文件，并把内容输出到终端？**

---

# Part 1：前情提要与必要术语

## 0. 今日 6.S081 听课任务

配套中文资料：[MIT6.S081 中文文字版](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081)。

今天学习 **Lec01 Introduction and Examples** 的四个小节，不要求一次看完整个 80 分钟视频：

1. [1.1 课程内容简介](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/lec01-introduction-and-examples/1.1-ke-cheng-jian-jie)
2. [1.2 操作系统结构](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/lec01-introduction-and-examples/1.2-cao-zuo-xi-tong-jie-gou)
3. [1.5 read, write, exit 系统调用](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/lec01-introduction-and-examples/1.5-some-systemcalls)
4. [1.6 open 系统调用](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/lec01-introduction-and-examples/1.6-open-xi-tong-tiao-yong)

建议顺序：

```text
先快速读 1.1：5~10 分钟
再认真读 1.2：10~15 分钟
学习本教程的 open/read/write/close 并运行 mycat
再认真读 1.5 和 1.6：20~30 分钟
最后用 strace 把课程概念对应回 Linux 程序
```

### 每节听什么

`1.1` 只抓住操作系统的几个目标：

```text
抽象硬件
在多个程序间复用资源
隔离
在受控条件下共享
权限与性能
```

不需要记课程管理信息。

`1.2` 是今天的框架重点：

```text
应用程序位于 user space
kernel 管理文件、进程、内存和设备
system call interface 连接用户程序与 kernel
file descriptor 是应用程序访问已打开资源的 handle
```

`1.5` 要与 `mycat` 的读写循环对应：

```text
read 的 fd / buffer / max count 三个参数
read 返回正数、0、-1 的含义
fd 0 / 1 的 Unix 约定
系统调用的返回值必须检查
```

`1.6` 要与 `open()` 对应：

```text
open 创建一个 fd
fd 是小整数，但背后对应当前进程的 fd 表
不同进程可以拥有数值相同、指向不同资源的 fd
后续 read/write 使用 fd，而不是反复使用路径
```

### 今天听到什么程度算完成

不看教程，能自己说清：

```text
1. user program、system call interface、kernel 三者的位置
2. 为什么应用程序不直接操作磁盘
3. fd 为什么是 handle，不是文件本身
4. 课程中的 copy/open 例子怎样对应到自己的 mycat
5. read 返回 0 与 -1 为什么完全不同
```

### 今天明确不听

```text
1.7 Shell
1.8 fork
1.9 exec / wait
1.10 I/O Redirect
Lec03 之后的 xv6 内核实现
```

这些内容会分别在 Week4 后面的 Linux 实践日出现。今天也不要求阅读完整 xv6 Chapter 1；有余力时只把它当背景材料浏览。

### xv6 与 Linux 的对应边界

课程示例运行在 xv6，本教程代码运行在 Linux：

```text
system call / fd / byte stream 的核心思想可以对应
具体 flag、头文件、错误处理和内核实现以 Linux man page 为准
```

不要把 xv6 示例代码未经检查直接复制成 Linux 代码。

---

## 1. 从你已经会的资源管理出发

你已经处理过这些资源：

```text
new[] 得到的内存
unique_ptr 拥有的对象
vector 内部的动态数组
list 节点和 iterator
```

它们都有共同问题：

```text
资源从哪里来？
谁拥有它？
什么时候失效？
谁负责释放？
失败路径是否也能释放？
```

今天出现的新资源是：

```text
file descriptor，简称 fd
```

第一层可以先这样对应：

```text
new[]                 open()
得到 char*            得到 int 类型的 fd
delete[]               close()
释放后不能解引用指针   close 后不能继续使用旧 fd
owning pointer         owning fd
```

这个对应不是说 fd 就是指针，而是说它们都带有**所有权和生命周期**。

Day2 会把 RAII 正式迁移到 fd；今天先手动管理，亲眼看清完整流程。

---

## 2. user mode / kernel mode

Linux 不允许普通程序直接随意操作磁盘、页表、网卡等关键资源。

可以先把执行环境分成两边：

```text
用户态 user mode
    运行你的 main、循环、函数和普通计算
    权限受到限制

内核态 kernel mode
    Linux 内核运行的状态
    管理进程、文件、内存、设备等系统资源
```

你的程序想读文件，不能自己跑去控制磁盘，而是要向内核提出请求。

---

## 3. system call：系统调用

系统调用是用户程序请求内核服务的接口。

今天的主线是：

```text
你的 C++ 程序
    |
    | open / read / write / close
    v
系统调用接口
    |
    v
Linux 内核
    |
    v
文件系统 / 终端 / 设备
```

常见系统调用包括：

```text
open      打开文件
read      从 fd 读取字节
write     向 fd 写入字节
close     释放当前进程持有的 fd
fork      创建子进程
exec      替换当前进程运行的程序
mmap      建立内存映射
```

今天只处理前四个。

### 一个需要保留的精确说法

你在 C++ 中调用的 `open()`、`read()` 等通常是 C 库提供的包装函数，它们再进入内核执行相应系统调用。

现阶段可以把它理解为：

```text
程序调用 Linux API
-> 库包装层准备参数
-> 通过系统调用进入内核
-> 内核完成工作并返回结果
```

暂时不追 syscall 指令、trap frame 和寄存器传参细节，Week5 再补。

---

## 4. file descriptor：文件描述符

`open()` 成功后不会返回一个 C++ `File` 对象，而是返回一个非负整数：

```cpp
int fd = ::open("note.txt", O_RDONLY);
```

这个整数叫 file descriptor，简称 fd。

第一层模型：

```text
当前进程
  fd 表
  ┌──────────┬──────────────────────┐
  │ fd       │ 指向的内核资源       │
  ├──────────┼──────────────────────┤
  │ 0        │ 标准输入             │
  │ 1        │ 标准输出             │
  │ 2        │ 标准错误             │
  │ 3        │ 程序刚打开的文件     │
  └──────────┴──────────────────────┘
```

重要：

```text
fd 不是文件本身
fd 不是文件在磁盘上的地址
fd 是当前进程用来访问某个内核资源的编号
```

通常一个新 fd 会使用当前进程中最小的可用非负整数。因此程序原本已有 `0/1/2` 时，第一个 `open()` 经常返回 `3`。

更完整的 fd 表和 open file description 留到 Day3。

---

## 5. 标准输入、标准输出、标准错误

`<unistd.h>` 提供了三个名字：

```cpp
STDIN_FILENO   // 通常是 0
STDOUT_FILENO  // 通常是 1
STDERR_FILENO  // 通常是 2
```

所以把数据输出到终端，本质上可以写：

```cpp
::write(STDOUT_FILENO, data, size);
```

错误信息通常写到标准错误：

```cpp
::write(STDERR_FILENO, data, size);
```

为什么要分成 `stdout` 和 `stderr`，Day4 学重定向时会真正看见价值。

---

## 6. 今天会遇到的类型

### `std::size_t`

表示非负的大小或数量：

```cpp
std::size_t buffer_size = 4096;
```

### `ssize_t`

`read()` 和 `write()` 返回 `ssize_t`：

```cpp
ssize_t count = ::read(fd, buffer, sizeof(buffer));
```

它是有符号整数，因为返回值既要表示字节数，也要表示失败：

```text
正数：实际处理的字节数
0：某些调用中的特殊状态，例如 read 遇到 EOF
-1：失败
```

如果返回类型是无符号的 `size_t`，就不方便使用 `-1` 表示错误。

---

## 7. errno 与 perror

许多 Linux API 失败时：

```text
返回 -1
同时设置 errno，记录更具体的错误原因
```

例如文件不存在：

```cpp
int fd = ::open("missing.txt", O_RDONLY);
if (fd == -1) {
    ::perror("open");
}
```

可能输出：

```text
open: No such file or directory
```

这里：

```text
"open"                         是你提供的上下文
"No such file or directory"    是 perror 根据 errno 输出的解释
```

必须记住：

```text
只有在某个调用明确报告失败后，errno 才对这次失败有意义
成功时不要拿 errno 判断调用是否成功
发现失败后应尽快读取或输出 errno，避免后续调用改变它
```

---

# Part 2：教程主体

## 教程起点：不用 ifstream，怎样实现 mycat？

目标程序的使用方式：

```bash
./mycat sample.txt
```

它应该把 `sample.txt` 的全部字节写到标准输出。

先别急着看代码，先把过程拆成资源和状态：

```text
1. 从 argv 取得文件路径
2. open 路径，得到一个 owning fd
3. 循环 read(fd, buffer, capacity)
4. 每次把实际读到的字节写到 STDOUT_FILENO
5. read 返回 0，说明到达 EOF
6. close 文件 fd
7. 任意步骤失败时报告错误并返回非 0
```

这就是今天的程序骨架。

---

## 1. open：从路径得到 fd

需要包含：

```cpp
#include <fcntl.h>
```

只读打开：

```cpp
int fd = ::open(path, O_RDONLY);
```

返回值：

```text
fd >= 0：成功
fd == -1：失败，errno 说明原因
```

`O_RDONLY` 表示只读。

今天先只用这个 flag。创建文件时涉及的 `O_CREAT`、`O_TRUNC` 和权限参数留到 Day2 的 `copyfile`。

### 中途检查 1

如果 `open()` 返回 `3`，下面哪句话正确？

```text
A. 文件在磁盘地址 3
B. 文件大小是 3 字节
C. 当前进程通过编号 3 访问这次打开的资源
```

答案应当是 `C`。

---

## 2. read：按字节读取

需要包含：

```cpp
#include <unistd.h>
```

接口直觉：

```cpp
ssize_t count = ::read(fd, buffer, buffer_capacity);
```

参数分别是：

```text
fd               从哪个 fd 读取
buffer           把数据放到哪里
buffer_capacity  最多允许内核放多少字节
```

返回值：

```text
count > 0   本次读到了 count 字节
count == 0  到达 EOF
count == -1 读取失败，查看 errno
```

### 为什么必须循环

假设文件有 10000 字节，而缓冲区只有 4096 字节：

```text
第一次 read：最多 4096
第二次 read：最多 4096
第三次 read：剩余部分
第四次 read：返回 0，确认 EOF
```

更重要的是，`read()` 返回少于请求数量的字节并不一定意味着 EOF。程序必须根据返回值继续读取，直到得到 `0` 或错误。

### buffer 不是 C 字符串

`read()` 只负责写入原始字节，不保证自动补 `\0`。

所以不要这样输出：

```cpp
std::cout << buffer; // 错误思路：它要求 buffer 是以 \0 结尾的 C 字符串
```

应该严格使用 `read()` 返回的字节数：

```cpp
::write(STDOUT_FILENO, buffer, static_cast<std::size_t>(count));
```

这也意味着 `mycat` 不只能够处理文本，它的核心逻辑处理的是字节流。

### 中途检查 2

假设：

```text
buffer 容量为 4096
read 返回 37
```

本次允许输出多少字节？

```text
只能输出前 37 字节
不能输出整个 4096 字节
```

---

## 3. write：把字节写到标准输出

接口：

```cpp
ssize_t written = ::write(fd, data, count);
```

这里 `mycat` 的目标 fd 是：

```cpp
STDOUT_FILENO
```

返回值：

```text
written > 0   本次实际写出的字节数
written == -1 写入失败
```

### 一次 write 不保证全部写完

如果希望写 `count` 字节，`write()` 可能只完成前面一部分。

所以正确状态变化是：

```text
total_written = 0

while total_written < count:
    从 data + total_written 开始写
    最多写 count - total_written 字节
    把本次 written 加到 total_written
```

今天先把 short write 循环写正确；`EINTR` 等被信号打断的情况放到 Day2 进一步处理。

---

## 4. close：释放当前进程持有的 fd

接口：

```cpp
int result = ::close(fd);
```

返回值：

```text
0   成功
-1 失败
```

关闭以后：

```text
这个 fd 不再属于当前进程
不能继续 read / write / close 它
这个整数编号以后可能被新的 open 重新使用
```

这和 dangling pointer 有相似的危险直觉：

```text
变量里的整数仍然存在
但它已经不再代表原来的有效资源
```

不要因为 `fd` 只是一个 `int` 就忘记它有生命周期。

在 `mycat` 中：

```text
open 返回的文件 fd：由本程序拥有，需要 close
STDOUT_FILENO：程序只是借用，不在这里主动 close
```

这就是 owning fd 与 non-owning fd 的第一层区别。

---

## 5. 完整教学实现：mycat.cpp

建议目录：

```bash
mkdir -p ~/code/system-learning/linux/week4/day1
cd ~/code/system-learning/linux/week4/day1
```

文件：

```text
mycat.cpp
```

完整代码：

```cpp
#include <cerrno>  // errno 及相关错误码；perror 会解释当前 errno
#include <cstddef> // std::size_t
#include <cstdio>  // fprintf、perror、stderr
#include <fcntl.h> // open、O_RDONLY
#include <unistd.h> // read、write、close、STDOUT_FILENO

// write 可能只写出一部分数据，所以循环，直到 size 字节全部写完。
bool write_all(int fd, const char* data, std::size_t size) {
    std::size_t total_written = 0;

    while (total_written < size) {
        // ::write 使用全局命名空间中的 POSIX write，不是 std 里的函数。
        // 从尚未写出的第一个字节开始，尝试写出剩余部分。
        const ssize_t written = ::write(
            fd,
            data + total_written,
            size - total_written);

        if (written == -1) {
            // write 失败时会设置 errno。
            // perror 会向标准错误 stderr 输出："write: errno 对应的说明"。
            ::perror("write");
            return false;
        }

        if (written == 0) {
            // fprintf 的第一个参数决定写到哪个 C 流。
            // stderr 是标准错误流，通常对应文件描述符 2。
            // 这里防止 write 一直返回 0，导致循环无法前进。
            ::fprintf(stderr, "write returned 0 before completion\n");
            return false;
        }

        // 进入这里时 written > 0，因此可以安全地转换为无符号的 size_t。
        total_written += static_cast<std::size_t>(written);
    }

    return true;
}

// argc：命令行参数数量，包含程序名本身。
// argv：参数字符串数组。
// 运行 ./mycat test.txt 时：argc == 2，argv[0] == "./mycat"，argv[1] == "test.txt"。
int main(int argc, char* argv[]) {
    if (argc != 2) {
        // fprintf(stderr, ...) 表示把格式化文字写到标准错误，而不是正常输出。
        // %s 会被 argv[0] 替换，所以可能输出：usage: ./mycat <file>
        ::fprintf(stderr, "usage: %s <file>\n", argv[0]);
        return 1;
    }

    // argv[1] 是用户提供的文件路径。
    // O_RDONLY 表示 read only：只读打开，不创建文件，也不允许通过该 fd 写文件。
    // open 成功返回非负 fd；失败返回 -1，并设置 errno。
    const int fd = ::open(argv[1], O_RDONLY);
    if (fd == -1) {
        // 例如文件不存在时可能输出：open: No such file or directory
        ::perror("open");
        return 1;
    }

    // read 把原始字节写进这个缓冲区，不会自动在末尾添加 '\0'。
    char buffer[4096];
    bool success = true;

    while (true) {
        // 最多读取 sizeof(buffer) 字节。
        // count > 0：本次实际读取的字节数。
        // count == 0：到达 EOF。
        // count == -1：读取失败，并设置 errno。
        const ssize_t count = ::read(fd, buffer, sizeof(buffer));

        if (count > 0) {
            // STDOUT_FILENO 通常是 fd 1，也就是标准输出。
            // 只输出本次真正读到的 count 字节，不能把整个 buffer 当 C 字符串。
            if (!write_all(
                    STDOUT_FILENO,
                    buffer,
                    static_cast<std::size_t>(count))) {
                success = false;
                break;
            }
            // 本次读取成功，继续下一次 read，直到遇到 EOF。
            continue;
        }

        if (count == 0) {
            // EOF 不是错误，说明文件已经正常读完。
            break;
        }

        // 能走到这里说明 count == -1。
        ::perror("read");
        success = false;
        break;
    }

    // 只要 open 成功，这个文件 fd 就由当前程序负责关闭。
    // 即使 read/write 失败，也会离开循环并走到这里。
    if (::close(fd) == -1) {
        ::perror("close");
        success = false;
    }

    // Unix 约定：0 表示成功，非 0 表示失败。
    return success ? 0 : 1;
}
```

编译：

```bash
g++ -std=c++17 -Wall -Wextra -g mycat.cpp -o mycat
```

准备测试文件：

```bash
printf 'hello Linux\nsecond line\n' > sample.txt
```

运行：

```bash
./mycat sample.txt
```

预期输出：

```text
hello Linux
second line
```

错误路径：

```bash
./mycat missing.txt
```

预期看到类似：

```text
open: No such file or directory
```

参数错误：

```bash
./mycat
```

预期：

```text
usage: ./mycat <file>
```

---

## 6. 手推一次程序状态

假设：

```text
sample.txt 有 6000 字节
buffer 容量是 4096
open 返回 fd = 3
```

可能经历：

```text
open
    fd = 3

第一次 read
    count = 4096
    write_all 输出 4096 字节

第二次 read
    count = 1904
    write_all 输出 1904 字节

第三次 read
    count = 0
    到达 EOF，退出循环

close(3)
    释放当前进程持有的文件描述符
```

注意：这只是一个可能的分段，不要把 `4096 + 1904 + 0` 当作所有环境都固定的结果。真正的控制依据永远是每次调用的返回值。

---

## 7. 用 strace 看见系统调用

`strace` 用来观察一个进程进行了哪些系统调用。

先确认工具存在：

```bash
strace --version
```

跟踪 `mycat`：

```bash
strace -e trace=openat,read,write,close ./mycat sample.txt
```

你可能看到类似：

```text
openat(AT_FDCWD, "sample.txt", O_RDONLY) = 3
read(3, "hello Linux\nsecond line\n", 4096) = 24
write(1, "hello Linux\nsecond line\n", 24) = 24
read(3, "", 4096) = 0
close(3) = 0
```

不同机器上的前置输出可能不完全一样，因为程序启动和动态链接器也会打开共享库。

逐行解释核心部分：

```text
openat(...) = 3
    成功打开文件，当前进程拿到 fd 3

read(3, ..., 4096) = 24
    请求最多读取 4096 字节，实际得到 24 字节

write(1, ..., 24) = 24
    向标准输出 fd 1 写 24 字节，全部写完

read(3, ..., 4096) = 0
    已经到 EOF

close(3) = 0
    fd 3 关闭成功
```

### 为什么代码写 open，strace 却可能显示 openat？

你调用的是 `open()` 接口，但现代 Linux 上的 C 库包装层可能使用 `openat` 系统调用完成它。

现阶段记住：

```text
源码中的库接口名称
不保证与 strace 看到的内核系统调用名称一一相同
```

这正是 `strace` 的价值：它让你看到程序最终向内核发出了什么请求。

### 只看统计

```bash
strace -c ./mycat sample.txt
```

它会汇总各类系统调用的次数和耗时。今天只观察，不做性能结论。

---

## 8. man page：系统编程的主要说明书

以后遇到 Linux API，优先查看 man page：

```bash
man 2 open
man 2 read
man 2 write
man 2 close
man 3 perror
```

数字表示手册章节：

```text
2：系统调用
3：库函数
```

第一次看 man page 重点找：

```text
SYNOPSIS      需要包含什么头文件，函数签名是什么
DESCRIPTION   参数做什么
RETURN VALUE  成功和失败分别返回什么
ERRORS        errno 可能是什么
```

不要从头到尾背完整页面。

---

## 9. 今天容易写错的地方

### 错误 1：把 fd 当作文件本身

正确理解：

```text
fd 是当前进程访问内核资源的编号
```

### 错误 2：不检查 open 返回值

如果 `open()` 返回 `-1`，继续 `read(-1, ...)` 只会产生新的错误，还会掩盖最初原因。

### 错误 3：把 buffer 当成自动补零的字符串

`read()` 返回多少，就只处理多少字节。

### 错误 4：认为一次 read 就是整个文件

文件大小可以超过缓冲区，系统调用也可能只完成部分工作。

### 错误 5：认为一次 write 一定写完

必须根据返回值推进 `total_written`。

### 错误 6：忘记 close

只要 `open()` 成功并且你拥有这个 fd，就要考虑所有离开路径怎样关闭它。

### 错误 7：重复 close

close 后 fd 编号可能被复用。再次 close 旧整数，极端情况下可能误关后来得到的新资源。

---

# Part 3：收尾、验证与验收

## 1. 今日必须完成

```text
1. 建立 ~/code/system-learning/linux/week4/day1
2. 独立写出或重新敲一遍 mycat.cpp
3. 使用标准参数编译，做到无 warning
4. 测试正常文本文件
5. 测试空文件
6. 测试不存在的文件
7. 测试不传参数
8. 把 buffer 暂时改小，观察多次 read
9. 用 strace 跟踪一次
10. 写 day1_note.md，只记录陌生点和真实观察
```

编译命令：

```bash
g++ -std=c++17 -Wall -Wextra -g mycat.cpp -o mycat
```

建议测试：

```bash
touch empty.txt
./mycat empty.txt
./mycat sample.txt
./mycat missing.txt
./mycat
```

---

## 2. 中途检查题

先不看上文回答：

```text
1. open 成功和失败分别返回什么？
2. fd 3 是否表示“第三个文件”？
3. read 返回 0 和 -1 分别是什么？
4. read 返回 20 时，为什么不能输出整个 buffer？
5. 为什么 write 也要检查实际返回值？
6. open 成功后，哪些路径需要 close？
7. 为什么 mycat 不应该 close STDOUT_FILENO？
8. errno 应该在什么前提下读取？
```

---

## 3. 面试式追问

这些问题不要求今天讲到内核源码：

```text
1. 什么是 file descriptor？
2. 为什么 Linux 能用 fd 统一表示文件、pipe 和 socket？
3. read 为什么使用 ssize_t 而不是 size_t 作为返回类型？
4. read 一定会填满用户给出的 buffer 吗？
5. close 后继续使用原 fd 会发生什么？
6. C++ iostream 和 Linux read/write 是什么层次的接口？
7. strace 能帮你排查什么问题？
```

今天能说清第一层直觉即可，不需要背内核结构体名称。

---

## 4. 6.S081 关联点

本日对应 **Lec01 的 `1.1、1.2、1.5、1.6`**。完成代码和 `strace` 后，再回看课程材料，建立这张图：

```text
用户程序
    |
    | 调用 open/read/write/close 的包装接口
    v
系统调用边界
    |
    | CPU 转入具有更高权限的内核执行路径
    v
Linux 内核检查参数并操作资源
    |
    v
返回用户态，程序检查返回值
```

### 必须完成的课程到代码映射

```text
课程说 fd 0 默认连接 console input
    -> Linux 中对应 STDIN_FILENO

课程说 fd 1 默认连接 console output
    -> mycat 的 write_all(STDOUT_FILENO, ...)

课程说 read 最多读取第三个参数指定的字节数
    -> mycat 的 sizeof(buffer)

课程说 read 返回实际字节数、0 或 -1
    -> mycat 的三个分支

课程说 open 返回新分配的 fd
    -> strace 中 openat(...) = 3

课程说每个进程有独立 fd 空间
    -> fd 3 只在当前 mycat 进程语境中有意义
```

### 听课验收

完成后，在 `day1_note.md` 用自己的话回答：

```text
1. 操作系统为什么要提供抽象，而不是让程序直接使用硬件？
2. system call 为什么既是服务接口，也是一条隔离边界？
3. read 为什么需要用户提供 buffer 和最大长度？
4. 为什么 fd 必须放在“当前进程”的语境里理解？
5. mycat 的哪几行分别对应课程中的 open/read/write？
```

今天不要深入：

```text
RISC-V ecall
trapframe
系统调用号寄存器
内核页表切换细节
xv6 syscall.c 源码
```

Week5 学 Lec03 后半、Lec04 和 Lec06 时，再把硬件权限、页表和 trap 内部路径补上。

---

## 5. day1_note.md 建议内容

不需要复制整篇教程，只记录：

```text
1. 你怎么理解 system call
2. 你怎么理解 fd
3. read 三类返回值
4. errno / perror 的关系
5. strace 中实际看到的关键几行
6. 你今天真实写错或不确定的地方
7. 下面的验收题答案
```

如果某一点已经完全清楚，一两句话即可。

---

## 6. 今日验收题

```text
1. 用户态程序为什么需要系统调用才能访问文件？
2. fd 是什么？它为什么只是一个 int？
3. fd 0、1、2 通常分别表示什么？
4. open/read/write/close 的成功和失败怎样判断？
5. read 返回 0、正数和 -1 分别表示什么？
6. read 为什么不能保证一次取得请求的全部字节？
7. write 为什么可能需要循环？
8. 为什么不能直接把 read 后的 buffer 当 C 字符串输出？
9. errno 在什么时候才有意义？perror 做了什么？
10. 为什么 open 成功后必须考虑所有退出路径上的 close？
11. strace 为什么可能显示 openat，而源码中写的是 open？
12. close 后，fd 变量还在，为什么资源却已经无效？
```

---

## 7. Git 提交建议

确认代码和笔记完成后：

```bash
cd ~/code/system-learning
git status
git add linux/week4/day1
git commit -m "week4 day1 linux fd and file io"
```

---

## 8. 下一天衔接

Day2 会继续解决今天留下的两个工程问题：

```text
问题一：如果中途失败，手动 close 很容易漏掉，怎样用 RAII 管理 fd？
问题二：怎样可靠地把一个文件复制到另一个文件，并处理创建、截断、short write 和 EINTR？
```

今天先把这条最小链路走通：

```text
path
-> open
-> fd
-> read bytes
-> write bytes
-> EOF
-> close
-> strace 验证
```
