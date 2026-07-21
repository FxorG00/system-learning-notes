# Week4 Day2：可靠文件复制与 fd 的 RAII 所有权

> 昨天你已经用 `open / read / write / close` 写出了 `mycat`，也建立了“fd 是当前进程访问内核资源的编号”这层模型。今天不重复实现另一个 `cat`，而是把问题推进一步：当程序同时拥有输入 fd 和输出 fd，并且 `read / write` 可能只完成一部分工作时，怎样保证数据复制正确、所有错误路径都不泄漏资源？

今天属于**教学日 + 一次完整实现**。教程会先讲清契约和机制，再在后半部分给出完整教学实现。建议先根据接口独立写一版，再向下对照。

---

# Part 1：前情提要与必要术语

## 0. 今日 6.S081 听课任务

今天进入：

```text
Lec03：OS Organization and System Calls
```

按下面顺序阅读中文材料：

1. [3.1 上一节课回顾](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/lec03-os-organization-and-system-calls/3.1-shang-jie-ke-hui-gu)
2. [3.2 操作系统隔离性 isolation](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/lec03-os-organization-and-system-calls/3.2-cao-zuo-xi-tong-ge-li-xing-isolation)
3. [3.3 操作系统防御性 defensive](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/lec03-os-organization-and-system-calls/3.3-cao-zuo-xi-tong-fang-yu-xing-defensive)

建议投入：`25~35` 分钟。

### 每节重点听什么

#### 3.1：快速复习，不重新抄笔记

只确认下面这条链仍然清楚：

```text
用户程序
→ 调用 system call 接口
→ 内核检查请求并执行受保护操作
→ 通过返回值和 errno 告诉用户程序结果
```

你昨天已经通过 `strace` 看到了这条链，不需要再把 `open / read / write / close` 的定义抄一遍。

#### 3.2：重点理解 isolation

`isolation` 读作“隔离”。今天只抓住三个抽象：

```text
process：隔离 CPU 和内存资源
file：抽象磁盘等持久化资源
fd：当前进程访问已打开内核资源的句柄
```

关键问题：

```text
为什么一个普通程序写错指针，不应该直接破坏另一个进程？
为什么程序不能绕开内核，随便读取别人的文件和内存？
为什么 OS 要给程序提供 process、file、fd 这些抽象？
```

#### 3.3：重点理解 defensive

`defensive` 在这里是“防御性”。内核不能相信用户程序传入的内容一定正确：

```text
fd 可能无效
地址可能不可访问
长度可能越界
权限可能不足
请求可能与资源类型不匹配
```

所以内核必须验证请求。验证失败时，应该让当前系统调用失败，而不是让整个内核崩溃。

把它和今天的代码对应起来：

```text
内核负责检查不可信参数
应用程序负责检查系统调用返回值
errno 说明内核或包装层拒绝请求的具体原因
```

注意，这两者不是一回事。我们检查返回值，不是在替内核做参数验证，而是在正确处理内核返回的结果。

### 今天听到什么程度算完成

你能用自己的话回答：

```text
1. isolation 主要在隔离什么？
2. 为什么内核不能信任用户传入的 fd、地址和长度？
3. 坏参数为什么应该导致当前调用失败，而不是 kernel panic？
4. file 和 process 分别抽象了哪类资源？
5. 今天 copyfile 检查返回值，与内核防御性有什么联系？
```

### 今天明确不听

```text
3.4 硬件对于强隔离的支持
3.5 user mode / kernel mode 的进一步展开
3.6 及之后的 xv6 启动、ECALL 和系统调用内部实现
```

这些内容留到 Week4 Day7 或 Week5。6.S081 最终要完整通关，但今天只吃透 `3.1~3.3`，不要顺手开新坑。

---

## 1. 从昨天的 mycat 往前走一步

昨天的数据流是：

```text
源文件
  ↓ read(input_fd)
buffer
  ↓ write(STDOUT_FILENO)
终端
```

其中：

```text
input_fd：由 mycat 打开，mycat 拥有它，最后必须 close
STDOUT_FILENO：程序只是借用，不应该擅自 close
```

今天的数据流变成：

```text
源文件
  ↓ read(source_fd)
buffer
  ↓ write(destination_fd)
目标文件
```

现在程序同时拥有：

```text
source_fd
destination_fd
```

而且可能出现更多失败位置：

```text
打开源文件失败
打开目标文件失败
读取中途失败
写入中途失败
系统调用被信号打断
```

这就是今天的问题起点：**数据必须完整，资源也必须在每条退出路径上正确释放。**

---

## 2. 今天的程序契约

命令形式：

```bash
./copyfile 源文件 目标文件
```

例如：

```bash
./copyfile source.txt destination.txt
```

成功契约：

```text
源文件存在并且可以读取
目标文件不存在时创建
目标文件已经存在时先截断为 0 字节
复制的是原始字节，不依赖文本和 '\0'
成功时返回 0
```

失败契约：

```text
参数数量错误时打印 usage，返回非 0
open / read / write 失败时输出可理解的错误，返回非 0
不论在哪一步失败，已经拥有的 fd 都要被释放
```

今天“可靠”的范围是：

```text
正确处理 short read / short write
正确处理 EINTR
正确管理 fd 生命周期
```

今天暂时不承诺：

```text
保留源文件权限、时间戳等元数据
处理稀疏文件
保证断电后数据已经落盘
原子替换目标文件
复制目录
检测源文件和目标文件是否其实是同一个底层文件
```

最后一点尤其要记住：如果源和目标是同一个文件，目标端的 `O_TRUNC` 会把源内容清空。Day3 学习 `stat / fstat` 后，再用设备号和 inode 正确识别它；今天测试时必须使用不同文件。

---

## 3. 必要术语

### short read

你请求读取 `N` 字节，但 `read` 返回一个满足：

```text
0 < actual < N
```

的结果，这叫 short read，也就是“短读”。

它不是错误。程序必须处理已经读到的 `actual` 个字节，然后继续调用 `read`。只有返回 `0` 才表示 EOF。

对于普通文件，短读常见于接近文件尾；以后读取 pipe、终端和 socket 时，短读会更加常见。因此现在就按接口契约写，不依赖“普通文件通常一次能填满 buffer”这个现象。

### short write

你要求写入 `N` 字节，但 `write` 只返回：

```text
0 < actual < N
```

这叫 short write，也就是“短写”。

已经写入的前 `actual` 个字节不能重写。下一次必须从：

```text
buffer + actual
```

继续写剩余部分。

### EINTR

`EINTR` 可以理解为：

```text
Error: INTerrupted system call
```

某个阻塞中的系统调用被信号打断时，它可能返回 `-1`，并令：

```cpp
errno == EINTR
```

今天的第一层处理方式是：

```text
read/write 返回 -1 且 errno == EINTR
→ 本次不当作真正失败
→ 重新调用
```

不要把它扩展成 signal 教程。今天只认识这个错误码和重试策略。

### owning fd

如果一段代码负责最终 `close(fd)`，那么它拥有这个 fd：

```text
owning fd = 有释放责任的 fd
```

### borrowed fd

如果一段代码只临时使用 fd，但不负责关闭：

```text
borrowed fd = 借来的 fd
```

今天的例子：

```text
UniqueFd 对象内部的 fd：owning
copy_fd(int source_fd, int destination_fd) 的参数：borrowed
```

函数拿到一个 `int` 并不自动获得所有权。所有权要由接口契约说明。

### invalid fd sentinel

系统调用成功返回的 fd 是非负整数，因此可以使用：

```text
-1
```

表示“当前对象没有拥有任何 fd”。移动后旧对象也应该回到这个状态。

注意判断有效 fd 时应该写 `fd >= 0`，不能写 `fd > 0`。如果标准输入已经关闭，下一次 `open` 完全可能返回 `0`。

---

## 4. 今天会用到的新 open flags

打开源文件：

```cpp
::open(source_path, O_RDONLY)
```

打开目标文件：

```cpp
::open(destination_path, O_WRONLY | O_CREAT | O_TRUNC, 0644)
```

各部分含义：

```text
O_WRONLY：只写打开
O_CREAT ：目标不存在时创建
O_TRUNC ：目标已存在时把长度截断为 0
```

`|` 是按位或，用来把多个独立 flag 组合起来。

### 为什么多了第三个参数 0644

只要使用了 `O_CREAT`，就必须提供新文件的权限模式：

```text
0644
```

开头的 `0` 表示八进制。`0644` 大致对应：

```text
文件所有者：可读、可写
同组用户：只读
其他用户：只读
```

最终权限还会受到当前进程 `umask` 的过滤，所以它不一定原样成为 `0644`。今天知道这一层即可。

---

# Part 2：教程主体

## 教程开始：怎样保证文件中的每一个字节都被写出去？

最直觉的复制逻辑是：

```text
read 一块
write 这一块
重复直到 EOF
```

真正的问题藏在“write 这一块”里。

假设本次：

```text
read 返回 100
write(fd, buffer, 100) 返回 40
```

此时状态是：

```text
buffer[0..39]   已写入
buffer[40..99]  还没写入
```

如果立刻进行下一次 `read`，旧 buffer 会被覆盖，剩下的 60 字节就永久丢失了。

所以复制程序需要一个明确的小工具：

```text
write_all(fd, data, size)
```

它的契约是：

```text
成功：size 个字节全部写完，返回 true
失败：打印原因，返回 false
它只借用 fd，不负责 close
```

---

## 1. 手推 write_all 的状态

需要维护一个偏移量：

```text
offset = 已经成功写出的字节数
```

每一轮要写的起点和长度是：

```text
起点：data + offset
长度：size - offset
```

假设总共 100 字节，连续三次 `write` 分别返回 `40、35、25`：

| 调用前 offset | 本次请求范围 | write 返回 | 调用后 offset |
|---:|---|---:|---:|
| 0 | `[0, 100)` | 40 | 40 |
| 40 | `[40, 100)` | 35 | 75 |
| 75 | `[75, 100)` | 25 | 100 |

当：

```text
offset == size
```

才算成功。

### write 的四种结果

```text
n > 0
    成功写入 n 字节，推进 offset

n == -1 && errno == EINTR
    被信号打断，不推进 offset，重新调用

n == -1 && errno != EINTR
    真正失败，输出错误并退出

n == 0
    没有进展；为避免死循环，今天把它当异常情况处理
```

`write` 对一个正数长度返回 `0` 在普通文件场景很少见，但循环必须保证每轮要么推进状态，要么结束，不能原地无限转。

### 中途检查 1

先不要向下看代码，回答：

```text
1. offset 表示已经写了多少，还是还剩多少？
2. 下一次 write 的地址为什么是 data + offset？
3. short write 后为什么不能重新从 data 开头写？
4. errno == EINTR 时为什么不能清空 offset？
5. write 返回 0 时为什么不能直接 continue？
```

### write_all 教学实现

```cpp
bool write_all(int fd, const char* data, std::size_t size) {
    std::size_t offset = 0;

    while (offset < size) {
        const ssize_t written =
            ::write(fd, data + offset, size - offset);

        if (written > 0) {
            offset += static_cast<std::size_t>(written);
            continue;
        }

        if (written == -1 && errno == EINTR) {
            continue;
        }

        if (written == -1) {
            ::perror("write");
            return false;
        }

        std::fputs("write: returned 0 bytes\n", stderr);
        return false;
    }

    return true;
}
```

这里的 `fd` 是 borrowed fd。`write_all` 使用它，但不会关闭它。

---

## 2. read 循环如何与 write_all 配合

一次 `read` 后只看返回值，不猜测 buffer 状态：

```text
read_count > 0
    buffer[0..read_count-1] 有效
    调用 write_all 写完这部分
    然后继续 read

read_count == 0
    EOF，复制完成

read_count == -1 && errno == EINTR
    本次被打断，重新 read

read_count == -1 && errno != EINTR
    真正失败
```

注意：

```text
read 返回一个小于 buffer 大小的正数
```

不等于已经 EOF。你仍然要处理这些字节，并继续下一次 `read`；只有下一次真正返回 `0`，才能确认 EOF。

可以把复制核心写成一个只借用两个 fd 的函数：

```cpp
bool copy_fd(int source_fd, int destination_fd) {
    char buffer[4096];

    while (true) {
        const ssize_t count =
            ::read(source_fd, buffer, sizeof(buffer));

        if (count > 0) {
            if (!write_all(destination_fd,
                           buffer,
                           static_cast<std::size_t>(count))) {
                return false;
            }
            continue;
        }

        if (count == 0) {
            return true;
        }

        if (errno == EINTR) {
            continue;
        }

        ::perror("read");
        return false;
    }
}
```

这个函数不会 `close(source_fd)` 或 `close(destination_fd)`，因为它并不拥有它们。

### 中途检查 2

```text
1. count 为正数但小于 4096 时，为什么仍然不能直接宣布 EOF？
2. 为什么传给 write_all 的长度必须是 count，而不是 sizeof(buffer)？
3. copy_fd 失败返回时，两个 fd 应该由谁释放？
4. copy_fd 为什么不应该擅自 close 参数？
```

---

## 3. 先看手动资源管理会在哪里变乱

不使用 RAII 时，`main` 需要自己记住：

```text
源文件打开失败：什么都不用 close
目标文件打开失败：close source_fd
复制失败：close source_fd 和 destination_fd
复制成功：close source_fd 和 destination_fd
```

“最后统一 close”在当前这个简单控制流里可以工作，因为所有打开成功后的分支都汇合到同一个出口。

但只要以后增加一个提前 `return`，就可能绕过统一清理位置。这也解释了你 Day1 笔记里那个问题：

```text
不是只要文件末尾有一行 close 就天然安全；
而是必须证明 open 成功后的每条退出路径都一定经过 close。
```

你在 Week1/Week2 已经用 RAII 管理过 `new[]`，现在只是把资源从“堆内存”换成“fd”。

---

## 4. 最小 UniqueFd 应该维护什么不变量

这个类只维护一个成员：

```text
fd_ >= 0：对象独占并负责关闭这个 fd
fd_ == -1：对象当前不拥有 fd
```

它的行为契约：

```text
构造：接管传入 fd
析构：如果 fd 有效，调用 close
拷贝：禁止
移动：把 fd 所有权交给新对象，旧对象变为 -1
get：借出 fd 供系统调用使用，不转移所有权
valid：判断当前是否拥有有效 fd
```

### 为什么禁止拷贝

如果只复制整数：

```text
a.fd_ == 3
b.fd_ == 3
```

两个对象都以为自己拥有 fd 3，析构时会发生两次 `close(3)`。

更危险的是，第一次 close 后数字 3 可能已经被系统重新分配给别的资源，第二次 close 甚至可能误关一个新的资源。

所以：

```text
独占所有权资源
→ 禁止拷贝
→ 允许移动
```

这和 `std::unique_ptr` 的规则完全同源。

### 为什么移动后要写成 -1

假设：

```cpp
UniqueFd second(std::move(first));
```

移动前：

```text
first.fd_ = 3
```

移动后：

```text
second.fd_ = 3
first.fd_  = -1
```

这样 `first` 仍然是一个可以安全析构的对象，只是它不再拥有资源。

### 为什么移动函数可以 noexcept

移动过程只做：

```text
整数赋值
把旧对象写成 -1
必要时调用 close，而 close 用返回值报告失败，不抛 C++ 异常
```

它不分配内存，也不调用会抛出 C++ 异常的构造操作，因此移动构造和移动赋值可以承诺 `noexcept`。

### 为什么析构函数不能随意抛异常

析构函数可能在栈展开期间运行。如果此时再抛出第二个异常，程序会调用 `std::terminate`。

因此最小封装的策略是：

```text
析构时尽力 close
不从析构函数抛异常
```

这不等于 `close` 永远不会失败。生产级封装如果必须报告关闭错误，可以额外提供显式关闭接口；今天不扩展错误类型和异常体系。

---

## 5. UniqueFd 的完整教学实现

文件：`unique_fd.hpp`

```cpp
#pragma once

#include <unistd.h>

class UniqueFd {
public:
    explicit UniqueFd(int fd = -1) noexcept
        : fd_(fd) {
    }

    ~UniqueFd() noexcept {
        close_current();
    }

    UniqueFd(const UniqueFd&) = delete;
    UniqueFd& operator=(const UniqueFd&) = delete;

    UniqueFd(UniqueFd&& other) noexcept
        : fd_(other.fd_) {
        other.fd_ = -1;
    }

    UniqueFd& operator=(UniqueFd&& other) noexcept {
        if (this == &other) {
            return *this;
        }

        close_current();
        fd_ = other.fd_;
        other.fd_ = -1;
        return *this;
    }

    int get() const noexcept {
        return fd_;
    }

    bool valid() const noexcept {
        return fd_ >= 0;
    }

private:
    void close_current() noexcept {
        if (fd_ >= 0) {
            ::close(fd_);
            fd_ = -1;
        }
    }

    int fd_;
};
```

这里有三个需要你自己解释的点：

```text
1. 构造函数为什么加 explicit
2. move assignment 为什么先 close_current
3. get() 为什么返回 int，却不把 fd_ 设成 -1
```

第三点的答案方向是：`get()` 只是借出，不转移所有权。

---

## 6. 完整教学实现：copyfile.cpp

建议你先只根据前面的契约写自己的版本，再回来逐行对照。

```cpp
#include "unique_fd.hpp"

#include <cerrno>
#include <cstddef>
#include <cstdio>
#include <fcntl.h>
#include <iostream>
#include <unistd.h>

bool write_all(int fd, const char* data, std::size_t size) {
    std::size_t offset = 0;

    while (offset < size) {
        const ssize_t written =
            ::write(fd, data + offset, size - offset);

        if (written > 0) {
            offset += static_cast<std::size_t>(written);
            continue;
        }

        if (written == -1 && errno == EINTR) {
            continue;
        }

        if (written == -1) {
            ::perror("write");
            return false;
        }

        std::fputs("write: returned 0 bytes\n", stderr);
        return false;
    }

    return true;
}

bool copy_fd(int source_fd, int destination_fd) {
    char buffer[4096];

    while (true) {
        const ssize_t count =
            ::read(source_fd, buffer, sizeof(buffer));

        if (count > 0) {
            if (!write_all(destination_fd,
                           buffer,
                           static_cast<std::size_t>(count))) {
                return false;
            }
            continue;
        }

        if (count == 0) {
            return true;
        }

        if (errno == EINTR) {
            continue;
        }

        ::perror("read");
        return false;
    }
}

int main(int argc, char* argv[]) {
    if (argc != 3) {
        std::cerr << "usage: " << argv[0]
                  << " <source> <destination>\n";
        return 1;
    }

    UniqueFd source_fd(::open(argv[1], O_RDONLY));
    if (!source_fd.valid()) {
        ::perror("open source");
        return 1;
    }

    UniqueFd destination_fd(
        ::open(argv[2], O_WRONLY | O_CREAT | O_TRUNC, 0644));
    if (!destination_fd.valid()) {
        ::perror("open destination");
        return 1;
    }

    if (!copy_fd(source_fd.get(), destination_fd.get())) {
        return 1;
    }

    return 0;
}
```

编译：

```bash
g++ -std=c++17 -Wall -Wextra -g copyfile.cpp -o copyfile
```

### 这里 RAII 实际帮你处理了哪些路径

#### 打开源文件失败

```text
source_fd.fd_ == -1
return 1
析构不 close
```

#### 打开目标文件失败

```text
source_fd 拥有源 fd
destination_fd.fd_ == -1
return 1
source_fd 析构并 close
```

#### read 或 write 中途失败

```text
copy_fd 返回 false
main 返回 1
destination_fd 先析构
source_fd 后析构
两个 fd 都被 close
```

#### 正常完成

```text
main 返回 0
两个局部对象逆序析构
两个 fd 都被 close
```

这就是 RAII 的价值：资源释放不再依赖你在每个 `return` 前手工补一组 `close`。

---

## 7. errno 今天要更精确一点

错误写法：

```text
系统调用成功后，看看 errno 是不是 0
```

原因是：成功的系统调用通常不会替你清空旧的 `errno`。它里面可能还留着更早一次失败的错误码。

正确顺序：

```text
调用系统调用
→ 先检查返回值
→ 只有返回值表示失败时，才读取 errno 或调用 perror
```

例如：

```cpp
const ssize_t count = ::read(fd, buffer, sizeof(buffer));

if (count == -1) {
    if (errno == EINTR) {
        // retry
    } else {
        ::perror("read");
    }
}
```

另外，`errno` 应该在失败后尽快读取。后续调用其他库函数或系统调用，可能再次改变它。

---

## 8. 今天不需要强行观察到 short write

向普通磁盘文件写入 4096 字节时，`write` 很可能每次都完整成功。因此运行一次程序没有出现 short write，不代表循环是多余的。

这里是在按接口契约编程：

```text
返回值允许部分完成
→ 调用方必须处理部分完成
```

以后写 pipe、socket 和非阻塞 IO 时，这个循环会真正频繁派上用场。今天不要为了制造 short write 提前进入 non-blocking IO。

---

# Part 3：收尾、验证与验收

## 1. 今日必须完成

沿用你当前 Ubuntu 仓库的实际路径，不在周中搬目录：

```bash
mkdir -p ~/code/system-learning/cpp/week4/day2
cd ~/code/system-learning/cpp/week4/day2
```

必做产出：

```text
unique_fd.hpp
copyfile.cpp
day2_note.md
```

周计划原本写的是 `unique_fd.cpp`。今天改成 `unique_fd.hpp`，是为了让封装只实现一次，再由 `copyfile.cpp` 直接使用，避免重复 work。

完成顺序：

```text
1. 先按不变量写 UniqueFd
2. 写 write_all
3. 写 copy_fd
4. 写 main 中的参数检查和两个 open
5. 编译并修完全部 warning
6. 跑成功、失败和边界测试
7. 用 strace 验证
8. 写 day2_note.md
```

---

## 2. 测试清单

### 测试 1：普通文本文件

```bash
printf 'hello\nlinux\n' > source.txt
./copyfile source.txt destination.txt
cmp source.txt destination.txt
echo $?
```

预期：

```text
cmp 没有输出
退出码为 0
```

### 测试 2：空文件

```bash
: > empty.txt
./copyfile empty.txt empty_copy.txt
cmp empty.txt empty_copy.txt
echo $?
```

### 测试 3：跨越多次 read 的二进制文件

```bash
head -c 65537 /dev/urandom > source.bin
./copyfile source.bin destination.bin
cmp source.bin destination.bin
echo $?
```

这里使用 `65537`，是为了保证文件明显大于 4096 字节，并且不是 buffer 大小的整数倍。

### 测试 4：目标文件原本更长

```bash
printf 'old old old old old old\n' > old_target.txt
printf 'new\n' > new_source.txt
./copyfile new_source.txt old_target.txt
cmp new_source.txt old_target.txt
echo $?
```

这个测试验证 `O_TRUNC`，确保目标文件没有残留旧尾巴。

### 测试 5：源文件不存在

```bash
./copyfile does_not_exist.txt out.txt
echo $?
```

预期：打印 `open source: ...`，退出码非 0。

### 测试 6：目标路径不可作为普通输出文件打开

```bash
./copyfile source.txt .
echo $?
```

预期：打开目标失败，退出码非 0；源 fd 仍会由 RAII 释放。

### 测试 7：参数数量错误

```bash
./copyfile
./copyfile a b c
```

预期：打印 usage，退出码非 0。

### 明确禁止的测试

不要执行：

```bash
./copyfile source.txt source.txt
```

当前版本尚未检测同一个底层文件，`O_TRUNC` 会先把它清空。这个边界将在 Day3 使用 `stat / fstat` 处理。

---

## 3. 用 strace 验证真实行为

只观察相关系统调用：

```bash
strace -e trace=openat,read,write,close \
    ./copyfile source.txt destination.txt
```

重点找这条顺序：

```text
openat(... source.txt ..., O_RDONLY) = source_fd
openat(... destination.txt ..., O_WRONLY|O_CREAT|O_TRUNC, 0644) = destination_fd
read(source_fd, ..., 4096) = 正数
write(destination_fd, ..., 正数) = 正数
read(source_fd, ..., 4096) = 0
close(destination_fd) = 0
close(source_fd) = 0
```

实际 trace 中还会出现动态链接器打开库文件的记录。不要抄全部，只记录能和自己代码对应的几行。

再观察失败路径：

```bash
strace -e trace=openat,close \
    ./copyfile source.txt .
```

确认目标打开失败后，已经成功打开的源 fd 最终仍被 `close`。

---

## 4. 中途检查题

```text
1. read 返回 100，是否说明已经到达 EOF？
2. write 请求 100 字节却返回 40，下一次应该从哪个地址开始写？
3. write_all 为什么必须维护 offset？
4. read/write 返回 -1 时，为什么要先区分 EINTR？
5. errno 为什么不能在系统调用成功后随便读取？
6. O_CREAT 为什么会让 open 多出第三个参数？
7. O_TRUNC 在什么时候修改目标文件长度？
8. fd 为 0 时为什么仍可能是有效 fd？
```

---

## 5. 面试式追问

```text
1. short read 和 EOF 是一回事吗？
2. 为什么普通文件中很少观察到 short write，代码仍要处理？
3. owning fd 和 borrowed fd 的区别是什么？
4. 为什么 fd RAII 包装类应该禁止拷贝？
5. UniqueFd 的移动构造做了哪两次状态修改？
6. move assignment 为什么必须先处理自己原来拥有的 fd？
7. 移动后的对象还能析构吗？应该处于什么状态？
8. close 可能失败，为什么析构函数仍不应该随意抛异常？
9. get() 返回原始 fd 后，所有权有没有转移？
10. 为什么函数参数写成 int fd，仍需要额外说明所有权契约？
```

回答时不要只背一句“RAII 自动释放”，要能手推：

```text
谁拥有 fd
什么时候转移
移动后谁变成 -1
每条 return 路径上哪个析构函数会执行
```

---

## 6. 6.S081 关联点

今天需要写进笔记的课程到代码映射只有三条：

```text
isolation
→ 每个进程有受保护的资源视图，不能随意破坏其他进程

defensive kernel
→ 内核检查用户传入的 fd、地址、长度和权限

系统调用失败返回值 + errno
→ 用户程序必须处理内核拒绝请求后的结果
```

不要把“我们写 RAII”说成“这是内核隔离机制”。RAII 是用户程序管理自身资源生命周期的方法；isolation 和 defensive 是 OS 在内核边界上提供保护的机制。它们解决的问题不同，但会在一条可靠调用链中配合。

---

## 7. day2_note.md 建议内容

你的笔记不需要重新抄 Day1。只记录今天真正新增或修正的东西：

```text
1. short read / short write 的定义
2. write_all 的 offset 不变量
3. EINTR 的第一层含义和处理方式
4. errno 只有在调用失败后才有意义
5. owning fd / borrowed fd
6. UniqueFd 的不变量
7. 为什么删除拷贝、允许移动
8. 一组成功路径和一组失败路径的 strace 关键记录
9. 6.S081 3.2 / 3.3 与今天代码的对应
10. 今天验收题中答错或不确定的题
```

不要求为了长度重复写已经掌握的：

```text
fd 0/1/2
open/read/write/close 的基础定义
mycat 的完整流程
```

---

## 8. 今日验收题

完成代码后，在 `day2_note.md` 回答：

```text
1. read 返回正数、小于 buffer 容量时，程序下一步应该做什么？
2. write_all 的循环不变量是什么？
3. 如果 write 先返回 40，再返回 60，offset 怎样变化？
4. errno == EINTR 时为什么通常选择重试？
5. 为什么 errno 不能被理解为一个永远代表“当前程序状态”的全局错误？
6. source_fd 和 destination_fd 的所有权分别属于谁？
7. copy_fd 收到两个 int 后，为什么不能 close 它们？
8. UniqueFd 为什么不能使用编译器生成的拷贝构造？
9. 移动构造后，源对象、目标对象分别保存什么？
10. move assignment 如果不先关闭旧 fd，会发生什么？
11. 目标 open 失败时，源 fd 为什么仍能正确关闭？
12. 为什么析构函数中的 close 失败不能直接通过抛异常处理？
13. `./copyfile a a` 为什么危险？Day3 准备用什么信息解决？
14. 内核防御性与应用程序检查返回值分别是谁的责任？
```

其中第 `2、6、8、11、14` 题必须能脱离笔记口头解释。

---

## 9. 今日完成标准

满足以下条件才算 Day2 完成：

```text
[ ] 阅读 6.S081 Lec03 的 3.1、3.2、3.3
[ ] 能解释 isolation 和 defensive 的第一层含义
[ ] unique_fd.hpp 无 warning
[ ] copyfile.cpp 使用 -std=c++17 -Wall -Wextra -g 编译无 warning
[ ] 正确处理 short write
[ ] read/write 遇到 EINTR 会重试
[ ] UniqueFd 禁止拷贝、允许移动
[ ] 移动后源对象为 -1
[ ] 文本、空文件、二进制文件 cmp 全部一致
[ ] 已存在的长目标文件能被正确截断
[ ] 源文件不存在和目标打开失败时退出码非 0
[ ] strace 能看到成功路径的 openat/read/write/close
[ ] strace 能证明目标打开失败后源 fd 仍被 close
[ ] day2_note.md 只记录新增重点和真实问题
```

---

## 10. Git 提交建议

```bash
git status
git add cpp/week4/day2
git commit -m "feat: add reliable file copy with fd RAII"
```

提交前确认：

```text
没有把 copyfile 可执行文件加入 Git
没有提交测试生成的随机二进制文件
代码没有 warning
```

---

## 11. 下一天衔接

Day3 将进入：

```text
stat / fstat
文件类型和元数据
lseek 与文件偏移
dup 后共享打开文件状态
```

今天留下的两个问题会在 Day3 接上：

```text
1. 怎样判断源路径和目标路径其实指向同一个底层文件？
2. 两个不同 fd 是否可能共享同一个文件偏移？
```

今天先把这条链写稳：

```text
open 两个 fd
→ read 允许部分完成
→ write_all 补齐剩余字节
→ EINTR 重试
→ UniqueFd 管住所有退出路径
→ cmp 和 strace 验证
```
