# Week4 Day3：文件元数据、文件偏移与共享打开状态

> Day2 的 `copyfile` 已经能够可靠复制字节，并通过 `UniqueFd` 管理 fd 生命周期。今天不重复复制逻辑，而是继续追问两个昨天故意留下的问题：两个不同路径是否可能是同一个底层文件？为什么对一个 fd 连续 `read`，第二次会自动从后面继续？

今天是**教学日 + 两个观察型 demo**。先建立内核对象关系，再写代码验证。完整代码放在对应问题的推导之后，可以先按接口要求独立写，再回来对照。

---

# Part 1：前情提要与必要术语

## 0. 今日资料定位：1.5 / 1.6 只是起点，不是 Day3 主教程

今天不新增 6.S081 整讲。下面两个小节只负责提供 Day3 的**接口直觉**：

1. [1.5 read、write、exit 系统调用](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/lec01-introduction-and-examples/1.5-some-systemcalls)
2. [1.6 open 系统调用](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/lec01-introduction-and-examples/1.6-open-xi-tong-tiao-yong)

如果刚读完并且能复述下面几点，不需要再次复听。

### 1.5 原文真正提供了什么

```text
read(fd, buffer, size) 接收 fd、内存地址和最大长度
read 返回正数表示实际读取字节数
read 返回 0 表示 EOF，返回 -1 表示失败
read / write 只处理字节流，不理解文本或其他数据格式
系统调用的返回值需要由应用程序检查
```

1.5 讲清了“怎样读一段字节”，但没有解释普通文件连续读取时，下一次从哪里继续。

### 1.6 原文真正提供了什么

```text
open(path, flags) 打开或创建文件
open 成功后返回一个较小的非负 fd
fd 是当前进程内核状态表中的 key
每个进程都有独立的 fd 空间
不同进程中的相同 fd 数字可以对应不同资源
多次 read 一个普通文件时，会按连续字节顺序向后读取
```

1.6 建立了：

```text
fd
→ 当前进程的 fd 表
→ 某个打开的资源
```

但原文没有继续展开 fd 表项后面的内核对象。

### 这些内容不在 1.5 / 1.6 中

```text
stat / fstat
lseek
dup
open file description
st_dev / st_ino
dup 后共享文件偏移
同一路径重新 open 后偏移独立
```

所以不要回到课程文字中寻找这些术语。你没有漏读，这是 Lec01 入门演示的范围；它展示接口现象，不负责讲完 Linux 文件打开状态。

### Day3 的新知识来自哪里

今天真正的新知识由 Linux 文档和代码实验补上：

```bash
man 2 open
man 2 stat
man 2 lseek
man 2 dup
```

资料关系是：

```text
6.S081 1.5：read / write 是字节流接口
6.S081 1.6：open 返回 fd，每个进程有自己的 fd 表

Linux open(2)：open 创建 open file description，保存 offset 和状态 flags
Linux lseek(2)：读取或修改其中的 offset
Linux dup(2)：新 fd 与旧 fd 指向同一个 open file description
Linux stat(2)：通过路径或 fd 查询文件元数据
```

### 今天的课程完成标准

```text
能说出 1.5 / 1.6 直接讲了哪些内容
能指出 open file description、stat、lseek、dup 不是这两节的原文内容
能把“连续 read 会往后推进”的现象连接到今天学习的 offset
```

今天不继续听 Lec03 3.4，不进入 page table、trap 或 xv6 文件系统源码。6.S081 最终仍要完整通关，但本日主课是 Linux 系统编程。

---

## 英文术语先认清：名字、原词和实际作用

今天的函数名很短，是因为 Unix 接口喜欢短名称。不要只背字母；第一次遇到时按：

```text
名字是什么
→ 完整英文或核心英文是什么
→ 中文直觉是什么
→ 它实际改变或查询什么
```

来记。

| 名称 | 英文来源或正式描述 | 中文直觉 | 实际作用 |
|---|---|---|:-:|
| `fd` | **file descriptor** | 文件描述符 | 当前进程 fd 表中的整数入口 |
| `dup` | **duplicate a file descriptor** | 复制一个 fd 入口 | 创建新 fd，让它引用与旧 fd 相同的 open file description；不是复制文件内容 |
| `stat` | **get file status**，核心词是 **status** | 查询文件状态 | 通过路径查询文件类型、大小、权限、设备号、inode 等 metadata |
| `fstat` | 可以理解成 **fd-based stat** | 通过 fd 查询状态 | 查询已经打开的 fd 所引用文件，而不是重新解析路径 |
| `lseek` | 正式描述是 **reposition read/write file offset**；核心词 **seek** 是“寻找、定位” | 重新定位读写位置 | 修改某个 open file description 的当前 offset |
| `offset` | **offset** | 偏移量、离开起点的距离 | 表示当前读写位置距离文件开头多少字节 |
| `open file description` | **open file description** | 一次打开产生的内核状态 | 保存 offset、状态 flags，并引用底层文件 |
| `metadata` | **meta-data**，描述数据的数据 | 文件自身的说明信息 | 文件类型、大小、权限、时间、身份等，不是文件正文 |
| `inode` | Unix 的 **inode** 术语，常被解释为 index node，但今天不依赖这段词源 | 文件系统中的文件身份/元数据对象 | 配合设备号标识文件，并保存文件系统元数据 |
| `sparse file` | **sparse** = 稀疏的 | 稀疏文件 | 逻辑空间很大，但部分区域没有实际分配磁盘块 |

### 三个最容易混的名字

#### `dup`：记住 duplicate，不是 copy file

```text
duplicate fd entry
```

它复制的是“访问入口”：

```text
旧 fd ─┐
       ├→ 同一个 open file description
新 fd ─┘
```

因此文件数据没有复制，当前 offset 也没有复制成两份，而是被两个 fd 共享。

#### `stat`：记住 status，不是 statistics

这里的 `stat` 不是“统计学 statistics”，而是 file status：

```text
这个路径是什么类型？
多大？
权限是什么？
设备号和 inode 是什么？
```

`fstat` 做同类查询，只是入口从 path 换成 fd。`f` 可以按“file descriptor 版本”理解，不需要把它背成另一个无关函数。

#### `lseek`：记住 seek position

Linux 手册对它的正式描述是：

```text
reposition read/write file offset
```

也就是“重新定位读写偏移”。标准文档并不要求你把函数名中的 `l` 强行展开成某个现代概念；记成 `L-seek` 即可，真正有用的词是：

```text
seek → 寻找 / 定位
offset → 距离文件开头的字节位置
```

所以看到：

```cpp
::lseek(fd, 10, SEEK_SET);
```

应该立即翻译成：

```text
把 fd 对应的读写位置定位到“距离文件开头 10 字节”处
```

### 字段和类型名也可以拆开记

```text
st_size：stat structure 中的 size
st_mode：stat structure 中的 mode
st_dev ：stat structure 中的 device
st_ino ：stat structure 中的 inode number

off_t ：offset type
mode_t：mode type
dev_t ：device type
ino_t ：inode-number type
```

`_t` 是 Unix/POSIX 类型名中常见的 **type** 后缀。它提醒你这些是系统定义的类型，不要擅自假设它们一定等于 `int`。

`SEEK_*` 也直接按英文拆：

```text
SEEK_SET：set，设置为“从开头算出的指定位置”
SEEK_CUR：current，以当前位置为基准
SEEK_END：end，以文件末尾为基准
```

文件类型宏：

```text
S_ISREG：is regular file，是否普通文件
S_ISDIR：is directory，是否目录
S_ISFIFO：is FIFO，是否先进先出字节流
S_ISSOCK：is socket，是否套接字
```

这里先把名字和动作建立联系，后面的机制与代码才不需要靠死记。

---

## 1. 从 Day2 留下的两个问题出发

### 问题一：路径字符串不同，就一定是两个文件吗

下面两个路径文字不同：

```text
source.txt
source_hardlink.txt
```

但在 Linux 中，它们可能是同一个底层文件的两个名字。只比较字符串无法可靠判断文件身份。

这直接影响 Day2：

```bash
./copyfile source.txt source_hardlink.txt
```

如果两个路径指向同一个文件，打开目标时的 `O_TRUNC` 会把源文件一起清空。

### 问题二：偏移到底保存在哪里

昨天的代码连续执行：

```text
read(source_fd, buffer, 4096)
read(source_fd, buffer, 4096)
```

第二次自动从第一次结束的位置继续。但 fd 本身只是一个整数，例如 `3`，整数 3 里面显然装不下当前偏移。

今天要建立的模型是：

```text
fd 数字
→ 当前进程的 fd 表项
→ open file description
→ 底层文件对象
```

---

## 2. fd、open file description 和文件对象

先看一次普通 `open`：

```cpp
int fd = ::open("letters.txt", O_RDONLY);
```

可以近似画成：

```text
当前进程 fd 表
┌────┬────────────────────────────┐
│ 3  │ ───────────────┐            │
└────┴────────────────│────────────┘
                      ↓
            open file description
            ┌─────────────────────┐
            │ current offset = 0  │
            │ status flags        │
            │ reference to file   │
            └──────────┬──────────┘
                       ↓
                 底层文件对象
            ┌─────────────────────┐
            │ identity            │
            │ metadata            │
            │ file data           │
            └─────────────────────┘
```

### file descriptor

```text
file descriptor，简称 fd
当前进程 fd 表中的非负整数索引
```

### open file description

这是 Linux 文档使用的术语，可以译为“打开文件描述”。它表示一次打开产生的内核状态，重要内容包括：

```text
当前文件偏移 current file offset
文件状态 flags
指向底层文件对象的引用
```

不要把它和 file descriptor 混为一谈：

```text
fd：进程表中的整数入口
open file description：fd 指向的内核打开状态
```

### 底层文件对象

今天只需要把它理解成文件系统中真正代表文件身份、元数据和内容的对象。Linux 文件系统内部还有 VFS、inode 等更多层次，本日不展开源码实现。

### 当前文件偏移属于哪一层

结论：

```text
current file offset 属于 open file description
```

它不属于：

```text
路径字符串
用户态 fd 整数变量
buffer
文件本身的永久元数据
```

因此：

```text
read 成功读取 n 字节
→ 对应 open file description 的 offset 通常推进 n
```

---

## 3. 同一路径 open 两次与 dup（duplicate）的根本区别

### 同一路径 open 两次

```cpp
int fd1 = ::open("letters.txt", O_RDONLY);
int fd2 = ::open("letters.txt", O_RDONLY);
```

模型：

```text
fd 3 ─→ open file description A：offset = 0 ─┐
                                               ├→ 同一个底层文件
fd 4 ─→ open file description B：offset = 0 ─┘
```

虽然底层文件相同，但每次 `open` 通常创建新的 open file description，所以两个 offset 相互独立。

### 对一个 fd 调用 dup

`dup` 来自 **duplicate a file descriptor**。它的主语是 file descriptor，不是 file：

```text
复制一个 fd 表入口
而不是复制文件内容
```

```cpp
int fd2 = ::dup(fd1);
```

模型：

```text
fd 3 ─┐
      ├→ 同一个 open file description：offset = 0 → 底层文件
fd 4 ─┘
```

`dup` 创建一个新的 fd 表入口，但两个 fd 指向同一个 open file description，因此共享：

```text
当前文件偏移
文件状态 flags
```

如果通过 fd 3 读取 3 字节，offset 变为 3；接着通过 fd 4 读取，就会从 offset 3 开始。

### close 一个 dup 出来的 fd 会怎样

open file description 在内核中有引用关系。关闭 fd 3 只是删除一个 fd 表入口：

```text
fd 3：关闭
fd 4：仍然指向原来的 open file description，可以继续使用
```

只有最后一个引用它的 fd 被关闭后，这次打开对应的内核状态才会被释放。

---

## 4. stat（status）与 fstat：从哪里查询文件信息

Linux 手册把这一组接口描述为 **get file status**，也就是“取得文件状态”。这里的 status 是文件元数据，不是程序退出状态。

接口：

```cpp
#include <sys/stat.h>

int ::stat(const char* path, struct stat* result);
int ::fstat(int fd, struct stat* result);
```

返回值：

```text
0  ：成功
-1 ：失败，并设置 errno
```

### stat

`stat` 记成 **status by path**：它从路径出发。

```text
路径
→ 内核解析目录和文件名
→ 找到文件对象
→ 填充 struct stat
```

适合回答：

```text
“这个路径现在指向什么文件？”
```

### fstat

`fstat` 记成 **status by file descriptor**：它从已经打开的 fd 出发。

```text
fd
→ fd 表项
→ open file description
→ 底层文件对象
→ 填充 struct stat
```

适合回答：

```text
“我已经打开并持有的这个资源是什么？”
```

路径可能在 `open` 后被重命名甚至删除，但 fd 仍可能继续引用原来的已打开文件对象。这时 `fstat(fd)` 描述的是 fd 真正持有的对象，通常比重新查询旧路径更贴近当前操作目标。

---

## 5. struct stat 今天只看四组字段

`struct stat` 包含很多信息。今天不要整张表硬背，只看：

```text
st_mode：文件类型和权限位
st_size：逻辑文件大小，普通文件中通常以字节计
st_dev ：所在设备的标识
st_ino ：文件在该设备上的 inode 编号
```

### 判断文件类型

不要自己手搓 bit mask，使用系统宏：

```cpp
S_ISREG(mode)  // regular file
S_ISDIR(mode)  // directory
S_ISCHR(mode)  // character device
S_ISBLK(mode)  // block device
S_ISFIFO(mode) // FIFO / named pipe
S_ISSOCK(mode) // socket
```

`stat` 默认跟随符号链接，查询它指向的目标。要检查符号链接本身需要 `lstat`，今天不展开。

### 查看权限位

```cpp
mode & 0777
```

只保留常见的用户、组和其他用户权限位。输出时使用八进制：

```cpp
std::cout << std::oct << (mode & 0777) << std::dec;
```

`std::dec` 是为了把后续整数输出恢复成十进制。

### 判断两个查询结果是否是同一个文件

在同一台系统当前视图下，第一层判断是：

```text
st_dev 相同
并且
st_ino 相同
```

只比较 `st_ino` 不够，因为不同设备上的 inode 编号可能重复。

---

## 6. lseek：seek 到新的 offset

`seek` 是“寻找、定位”。`lseek` 的正式作用是 **reposition read/write file offset**：重新定位读写偏移。

它不是查找文件内容，也不是读取数据；它只改“下一次从哪里读或写”。

接口：

```cpp
#include <unistd.h>

off_t ::lseek(int fd, off_t offset, int whence);
```

成功返回：

```text
调整后的新偏移
```

失败返回：

```text
-1，并设置 errno
```

### 三种 whence

```text
SEEK_SET：以文件开头为基准
SEEK_CUR：以当前偏移为基准
SEEK_END：以文件末尾为基准
```

例子：

```cpp
::lseek(fd, 10, SEEK_SET);  // 新偏移为 10
::lseek(fd, 3, SEEK_CUR);   // 从当前位置再向后 3
::lseek(fd, -5, SEEK_END);  // 文件末尾之前 5 字节
```

获取当前偏移但不改变它：

```cpp
off_t current = ::lseek(fd, 0, SEEK_CUR);
```

### lseek 不会读取或写入数据

它只修改 open file description 中的 offset：

```text
lseek
→ 改位置

read / write
→ 在当前位置传输数据，并推进位置
```

### 为什么 pipe 不能 lseek

普通文件可以理解成一段可随机访问的字节序列：

```text
0 1 2 3 4 5 ...
```

pipe 是随生产随消费的字节流，没有一个可长期随机访问的“第 100 个字节位置”。因此对 pipe 调用 `lseek` 会失败，Linux 通常报告：

```text
errno == ESPIPE
Illegal seek
```

今天只理解原因，不提前学习 `pipe()` 编程；pipe 会在 Day6 正式进入。

---

## 7. 今天会遇到的类型

### off_t

用于表示文件偏移和文件大小相关数值。它是有符号整数类型，因为某些 `lseek` 用法允许传入负的相对偏移，例如 `SEEK_END` 配合 `-5`。

### mode_t

用于保存文件类型和权限位。

### ino_t 与 dev_t

分别用于 inode 编号和设备标识。不要假设它们一定就是 `int`。

今天使用系统提供的类型，不自己替换成 `int`。

---

# Part 2：教程主体

## 教程开始：怎样证明两个不同路径其实是同一个文件？

只比较路径字符串会漏掉：

```text
硬链接
符号链接解析后的同一目标
包含 . 或 .. 的等价路径
```

今天的第一份程序 `stat_info.cpp` 要从内核返回的身份信息出发。

### stat_info.cpp 的公开需求

命令：

```bash
./stat_info <path>
```

行为：

```text
1. 使用 stat(path) 查询路径
2. 使用 open(path) 得到 fd
3. 使用 fstat(fd) 查询已打开对象
4. 输出类型、权限、大小、st_dev、st_ino
5. 比较 stat 与 fstat 的 st_dev / st_ino
6. 所有失败都返回非 0
7. fd 使用 Day2 的 UniqueFd 管理
```

先自己思考：

```text
stat 成功后，open 是否仍可能失败？
open 成功后，为什么还要检查 fstat？
为什么不能只比较 inode？
```

答案是：系统状态可能变化，每个系统调用都必须根据自己的返回值判断；`st_dev + st_ino` 才构成今天使用的文件身份组合。

---

## 1. stat_info.cpp 完整教学实现

文件：`stat_info.cpp`

```cpp
#include "../day2/unique_fd.hpp"

#include <cstdio>
#include <fcntl.h>
#include <iomanip>
#include <iostream>
#include <sys/stat.h>
#include <unistd.h>

const char* file_type(mode_t mode) {
    if (S_ISREG(mode)) {
        return "regular file";
    }
    if (S_ISDIR(mode)) {
        return "directory";
    }
    if (S_ISCHR(mode)) {
        return "character device";
    }
    if (S_ISBLK(mode)) {
        return "block device";
    }
    if (S_ISFIFO(mode)) {
        return "fifo";
    }
    if (S_ISSOCK(mode)) {
        return "socket";
    }
    return "other";
}

void print_info(const char* label, const struct stat& info) {
    std::cout << label << '\n';
    std::cout << "  type: " << file_type(info.st_mode) << '\n';
    std::cout << "  permissions: "
              << std::oct << (info.st_mode & 0777) << std::dec << '\n';
    std::cout << "  size: "
              << static_cast<long long>(info.st_size) << " bytes\n";
    std::cout << "  device: "
              << static_cast<unsigned long long>(info.st_dev) << '\n';
    std::cout << "  inode: "
              << static_cast<unsigned long long>(info.st_ino) << '\n';
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::fprintf(stderr, "usage: %s <path>\n", argv[0]);
        return 1;
    }

    struct stat path_info {};
    if (::stat(argv[1], &path_info) == -1) {
        ::perror("stat");
        return 1;
    }

    UniqueFd file_fd(::open(argv[1], O_RDONLY));
    if (!file_fd.valid()) {
        ::perror("open");
        return 1;
    }

    struct stat fd_info {};
    if (::fstat(file_fd.get(), &fd_info) == -1) {
        ::perror("fstat");
        return 1;
    }

    print_info("stat(path):", path_info);
    print_info("fstat(fd):", fd_info);

    const bool same_file =
        path_info.st_dev == fd_info.st_dev &&
        path_info.st_ino == fd_info.st_ino;

    std::cout << "same file object: "
              << (same_file ? "yes" : "no") << '\n';
    return 0;
}
```

编译：

```bash
g++ -std=c++17 -Wall -Wextra -g stat_info.cpp -o stat_info
```

这里复用了：

```cpp
#include "../day2/unique_fd.hpp"
```

编译器会从 `day3/stat_info.cpp` 所在目录出发，先进入 `..`，再到 `day2` 中找到头文件。这样 `UniqueFd` 只实现一次，不需要在 Day3 复制类定义。

### 中途检查 1

```text
1. stat 的第一个参数为什么是路径，fstat 的第一个参数为什么是 fd？
2. path_info 和 fd_info 为什么都要分别初始化？
3. open 失败时，file_fd 内部是什么值？析构会不会错误 close？
4. get() 是转移所有权还是借用 fd？
5. 为什么输出权限后要恢复 std::dec？
```

---

## 2. 用硬链接验证文件身份

准备文件：

```bash
printf 'same data\n' > original.txt
ln original.txt hardlink.txt
ln -s original.txt symlink.txt
```

观察：

```bash
./stat_info original.txt
./stat_info hardlink.txt
./stat_info symlink.txt
```

你应该看到：

```text
original.txt 与 hardlink.txt：st_dev、st_ino 相同
stat(symlink.txt)：默认跟随链接，也会得到目标文件的身份
```

路径字符串不同，但身份相同。这就是为什么 Day2 的 copyfile 不能只写：

```cpp
if (source_path == destination_path) {
    // reject
}
```

这种字符串判断最多挡住完全相同的文字，挡不住硬链接和等价路径。

---

## 3. Day2 copyfile 应该怎样利用文件身份

今天不要求重写一遍 `copyfile.cpp`。只需要能讲清正确顺序：

```text
1. open 源文件，得到 source_fd
2. fstat(source_fd)，得到源文件身份
3. stat(destination_path)
4. 如果目标存在，并且 st_dev / st_ino 与源相同，拒绝复制
5. 如果目标不存在且 errno == ENOENT，允许后续创建
6. 其他 stat 失败按错误处理
7. 确认不是同一文件后，才用 O_TRUNC 打开目标
```

这段里的英文逐个翻译：

```text
source              = 源；source_fd 就是“源文件的 file descriptor”
destination         = 目的地；destination_path 就是“目标文件的路径”
path                = 路径
fd                  = file descriptor，文件描述符
stat                = get file status，通过路径查询文件状态
fstat               = 通过 fd 查询 file status；可理解为 fd-based stat
st_dev              = struct stat 中的 device ID，文件所在文件系统的设备标识
st_ino              = struct stat 中的 inode number，该文件在这个文件系统内的 inode 编号
errno               = error number，系统调用失败后用于说明错误原因的错误编号
ENOENT              = errno 的一个符号常量，正式含义是 No such file or directory
O_TRUNC             = open 的 truncate flag；TRUNC 来自 truncate，表示把已有文件截断为 0 字节
```

`ENOENT` 可以这样帮助记忆，但不要把它当作严格的官方单词拆写：

```text
E      → errno 错误常量的前缀
NOENT  → 记成 no entry：路径中的文件或目录项不存在
```

这里的判断顺序实际上是：

```cpp
if (::stat(destination_path, &destination_info) == -1) {
    if (errno == ENOENT) {
        // No such file or directory：目标不存在，之后可以创建。
    } else {
        // stat 因权限、路径错误等其他原因失败，不能假装目标不存在。
    }
}
```

只有在 `stat()` 已经返回 `-1`、明确表示失败后，才读取 `errno`。成功时不要检查 `errno`，因为其中可能还保留着之前某次失败留下的旧值。

关键点是：

```text
身份检查必须发生在 O_TRUNC 之前
```

否则目标已经被清空，再发现同一文件就晚了。

这套顺序仍有路径在检查后被其他进程修改的竞争窗口，也就是后续会遇到的 TOCTOU 问题。

`TOCTOU` 是 **Time Of Check To Time Of Use**：

```text
Time Of Check：检查路径身份时
Time Of Use  ：真正打开或使用路径时
```

两者之间如果对象被替换，检查结果就可能过期。今天只认识这个英文全称和问题边界，不设计生产级无竞争复制工具。

---

## 第二个问题：为什么 dup 出来的 fd 会互相影响读取位置？

接下来通过 `offset_dup.cpp` 对比两种行为：

```text
dup(original_fd)
重新 open 同一路径
```

准备内容：

```text
ABCDEFGHIJ
```

预期手推：

```text
original 读 3 字节 → ABC，共享 offset 变为 3
duplicated 读 3 字节 → DEF，共享 offset 变为 6
independent 读 3 字节 → ABC，独立 offset 变为 3

lseek(duplicated, 1, SEEK_SET)
→ 共享 offset 被改为 1

original 再读 3 字节 → BCD，共享 offset 变为 4
independent 再读 3 字节 → DEF，独立 offset 变为 6
```

如果你能在看代码前手推这个输出，今天最重要的模型就已经建立了。

---

## 4. offset_dup.cpp 完整教学实现

文件：`offset_dup.cpp`

```cpp
/*
功能：验证 dup 得到的 fd 会与原 fd 共享文件偏移，
     而重新 open 同一路径得到的 fd 拥有独立的文件偏移。

运行过程：
1. original_fd 打开文件。
2. duplicated_fd 由 dup(original_fd) 得到，与 original_fd 共享打开状态。
3. independent_fd 重新 open 同一路径，拥有另一份独立的打开状态。
4. 交替读取并修改偏移，通过输出观察三者的关系。
*/
#include "../day2/unique_fd.hpp"

#include <cerrno>
#include <cstddef>
#include <cstdio>
#include <fcntl.h>
#include <iostream>
#include <unistd.h>

// 从 fd 最多读取 size 字节到 buffer。
// 如果 read 被信号中断并返回 EINTR，就重新尝试；其他结果直接交给调用者处理。
// fd 只是借用，本函数不拥有它，也不会 close(fd)。
ssize_t read_retry(int fd, char* buffer, std::size_t size) {
    while (true) {
        const ssize_t count = ::read(fd, buffer, size);
        if (count == -1 && errno == EINTR) {
            continue;
        }
        return count;
    }
}

// 从 fd 读取 3 字节，然后报告“读取内容”和“读取后的当前偏移”。
// label 只用于区分输出来自哪个 fd；成功返回 true，失败返回 false。
// 与 read_retry 一样，本函数只借用 fd，不负责关闭它。
bool read_and_report(const char* label, int fd) {
    char buffer[3];

    // read 成功后，会推进 fd 对应 open file description 中的 offset。
    const ssize_t count = read_retry(fd, buffer, sizeof(buffer));

    if (count == -1) {
        ::perror("read");
        return false;
    }

    // SEEK_CUR 表示以当前位置为基准；移动量为 0，因此只查询、不改变当前 offset。
    const off_t current = ::lseek(fd, 0, SEEK_CUR);
    if (current == static_cast<off_t>(-1)) {
        ::perror("lseek current");
        return false;
    }

    std::cout << label << " fd=" << fd << " read=\"";
    // buffer 不是以 '\0' 结尾的 C 字符串，所以按 count 指定的实际字节数输出。
    std::cout.write(buffer, count);
    std::cout << "\" offset="
              << static_cast<long long>(current) << '\n';
    return true;
}

// 程序入口：要求命令行提供一个文件路径，并完成“dup 与重新 open”的对照实验。
int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::fprintf(stderr, "usage: %s <file>\n", argv[0]);
        return 1;
    }

    // 第一次 open：创建一份 open file description，初始 offset 为 0。
    // UniqueFd 拥有返回的 fd，并在离开作用域时自动 close。
    UniqueFd original_fd(::open(argv[1], O_RDONLY));
    if (!original_fd.valid()) {
        ::perror("open original");
        return 1;
    }

    // dup 创建一个新的 fd 表入口，但它与 original_fd 指向同一个
    // open file description，因此二者共享 offset 和文件状态 flags。
    UniqueFd duplicated_fd(::dup(original_fd.get()));
    if (!duplicated_fd.valid()) {
        ::perror("dup");
        return 1;
    }

    // 第二次 open 同一路径：创建另一份 open file description。
    // 它指向同一个文件对象，但拥有独立的 offset，初始值同样为 0。
    UniqueFd independent_fd(::open(argv[1], O_RDONLY));
    if (!independent_fd.valid()) {
        ::perror("open independent");
        return 1;
    }

    // original 先读 3 字节，把共享 offset 从 0 推进到 3。
    if (!read_and_report("original   ", original_fd.get())) {
        return 1;
    }
    // duplicated 从共享 offset 3 开始读，而不是从文件开头读。
    if (!read_and_report("duplicated ", duplicated_fd.get())) {
        return 1;
    }
    // independent 有自己的 offset，所以第一次读取仍从 0 开始。
    if (!read_and_report("independent", independent_fd.get())) {
        return 1;
    }

    // 通过 duplicated_fd 把共享 offset 设置为距离文件开头 1 字节的位置。
    // 因为 original_fd 共享同一份打开状态，它下一次读取也会从位置 1 开始。
    const off_t new_offset =
        ::lseek(duplicated_fd.get(), 1, SEEK_SET);
    if (new_offset == static_cast<off_t>(-1)) {
        ::perror("lseek set");
        return 1;
    }

    std::cout << "lseek duplicated to offset "
              << static_cast<long long>(new_offset) << '\n';

    // 预期从位置 1 读出 BCD，证明 duplicated 对 offset 的修改影响了 original。
    if (!read_and_report("original   ", original_fd.get())) {
        return 1;
    }
    // independent 的 offset 未被 lseek 影响，继续从自己的位置 3 读出 DEF。
    if (!read_and_report("independent", independent_fd.get())) {
        return 1;
    }

    // main 返回后，三个 UniqueFd 分别关闭三个不同的 fd 表入口。
    return 0;
}
```

编译：

```bash
g++ -std=c++17 -Wall -Wextra -g offset_dup.cpp -o offset_dup
```

准备并运行：

```bash
printf 'ABCDEFGHIJ' > letters.txt
./offset_dup letters.txt
```

普通文件上预期输出：

```text
original    fd=3 read="ABC" offset=3
duplicated  fd=4 read="DEF" offset=6
independent fd=5 read="ABC" offset=3
lseek duplicated to offset 1
original    fd=3 read="BCD" offset=4
independent fd=5 read="DEF" offset=6
```

实际 fd 数字不必一定是 `3、4、5`，但读取内容和偏移关系应该一致。

### 为什么 buffer 不需要 '\0'

这里使用：

```cpp
std::cout.write(buffer, count);
```

它按明确长度输出，不把 buffer 当 C 字符串，因此不需要结尾 `\0`。这和 Day1/Day2 的“按实际返回字节数处理”是同一原则。

### read_retry 的 fd 是什么所有权

```text
read_retry(int fd, ...)
read_and_report(..., int fd)
```

两个函数都只借用 fd，不负责 `close`。真正拥有 fd 的是 `main` 中三个 `UniqueFd` 对象。

### 中途检查 2

```text
1. duplicated_fd 和 original_fd 的整数值相同吗？
2. 它们为什么仍会共享 offset？
3. independent_fd 指向同一文件，为什么偏移独立？
4. 对 duplicated_fd 调用 lseek 后，original_fd 为什么受影响？
5. 三个 UniqueFd 析构时会发生几次 close？是否属于重复关闭？
```

答案方向：三个 fd 数字各不相同，所以会各自关闭一次；其中两个 fd 虽然共享 open file description，但它们仍是两个合法 fd 表入口，不是对同一个 fd 数字 double close。

---

## 5. 用 strace 看见模型

观察 `stat_info`：

```bash
strace -e trace=openat,newfstatat,fstat,close \
    ./stat_info original.txt
```

源码写的是 `stat`，Linux/glibc 环境下 `strace` 可能显示 `newfstatat`。这与 Day1 源码写 `open`、trace 看到 `openat` 类似：用户态接口可能通过另一个具体 Linux 系统调用实现。

观察共享偏移实验：

```bash
strace -e trace=openat,dup,read,lseek,close \
    ./offset_dup letters.txt
```

重点找：

```text
第一次 open 返回 original fd
dup(original) 返回新 fd
第二次 open 返回 independent fd
两个 open 是两次独立打开
lseek 作用在 duplicated fd
后续 original 的 read 仍从被修改后的共享位置开始
```

`strace` 不会直接打印“这两个 fd 共享 open file description”，需要把调用顺序和程序输出结合起来推断。

---

## 6. 可选实验：sparse file

本实验不影响 Day3 通过。

创建一个逻辑大小为 1 GiB 的稀疏文件：

```bash
truncate -s 1G sparse.bin
ls -lh sparse.bin
du -h sparse.bin
./stat_info sparse.bin
```

可能观察到：

```text
ls -l / stat 的 st_size：逻辑大小很大
du：实际占用磁盘块很少
```

原因是文件的逻辑地址空间可以包含没有实际分配磁盘块的 hole。今天只观察“逻辑大小不等于实际占用”，不深入文件系统块分配、page cache 或 hole 的内部实现。

`lseek` 可以把 offset 移到文件末尾之外；如果之后写入数据，中间区域可能形成 hole。这也是 sparse file 的来源之一。

---

# Part 3：收尾、验证与验收

## 1. 今日必须完成

沿用当前 Ubuntu 仓库路径：

```bash
mkdir -p ~/code/system-learning/cpp/week4/day3
cd ~/code/system-learning/cpp/week4/day3
```

必做产出：

```text
stat_info.cpp
offset_dup.cpp
day3_note.md
```

不复制 `UniqueFd`，直接包含：

```cpp
#include "../day2/unique_fd.hpp"
```

完成顺序：

```text
1. 定向复听 6.S081 Lec01 1.5 / 1.6
2. 画出 fd → open file description → 文件对象
3. 独立完成 stat_info.cpp，再对照教学实现
4. 用普通文件、目录、硬链接测试 stat_info
5. 先手推 offset_dup 的输出
6. 独立完成 offset_dup.cpp，再对照教学实现
7. 用 strace 对照 open / dup / read / lseek / close
8. 只把新增重点和真实问题写入 day3_note.md
```

---

## 2. 必做测试清单

### stat_info：普通文件

```bash
printf 'hello stat\n' > regular.txt
./stat_info regular.txt
```

确认：

```text
类型是 regular file
size 与实际字节数一致
stat 和 fstat 的 st_dev / st_ino 一致
```

### stat_info：目录

```bash
./stat_info .
```

确认类型是 `directory`。目录的 `st_size` 不要直接解释成“目录中所有文件大小之和”。

### stat_info：硬链接

```bash
printf 'identity\n' > identity_a.txt
ln identity_a.txt identity_b.txt
./stat_info identity_a.txt
./stat_info identity_b.txt
```

确认两个路径的 `st_dev / st_ino` 相同。

### stat_info：不存在的路径

```bash
./stat_info does_not_exist
echo $?
```

确认打印错误并返回非 0。

### offset_dup：标准输入

```bash
printf 'ABCDEFGHIJ' > letters.txt
./offset_dup letters.txt
```

先不看预期结果手推，再核对实际输出。

### offset_dup：短文件

```bash
printf 'XY' > short.txt
./offset_dup short.txt
```

观察 `read` 返回少于 3 字节甚至 EOF 时，程序是否仍按实际长度输出，而不是把 buffer 当字符串。

---

## 3. 编译要求

```bash
g++ -std=c++17 -Wall -Wextra -g stat_info.cpp -o stat_info
g++ -std=c++17 -Wall -Wextra -g offset_dup.cpp -o offset_dup
```

验收：

```text
两份代码都无 warning
所有系统调用都检查关键返回值
所有 owning fd 都立刻交给 UniqueFd
借用 fd 的函数不 close 参数
```

---

## 4. 今日易错点

### 错误 1：把 fd 和 open file description 当成一个东西

```text
fd 是入口
open file description 是入口指向的共享内核状态
```

### 错误 2：认为同一个底层文件只有一个 offset

同一路径 `open` 两次通常得到两个独立 open file description，所以有两个独立 offset。

### 错误 3：认为不同 fd 一定拥有不同 offset

`dup` 产生不同 fd，但它们共享同一个 open file description，所以共享 offset。

### 错误 4：只比较 inode

文件身份第一层比较需要：

```text
st_dev + st_ino
```

### 错误 5：在同文件检查前 O_TRUNC

一旦成功用 `O_TRUNC` 打开目标，文件已经被截断。检查必须在此之前完成。

### 错误 6：认为 lseek 会读取数据

`lseek` 只改偏移。真正传输字节的是 `read / write`。

### 错误 7：认为所有 fd 都能 seek

pipe、socket 等流式资源没有普通文件式的随机位置，对它们调用 `lseek` 会失败。

---

## 5. 面试式追问

```text
1. fd、fd 表项和 open file description 分别是什么？
2. 当前文件偏移保存在哪里？
3. 同一路径 open 两次，两个 fd 是否共享偏移？
4. dup 后为什么共享偏移？
5. close 掉其中一个 duplicated fd，另一个还能不能使用？
6. stat 和 fstat 的输入与适用场景有什么区别？
7. 怎样判断两个路径当前是否指向同一个底层文件？
8. 为什么只比较路径字符串或 inode 都不充分？
9. lseek 的返回值是什么？
10. SEEK_SET、SEEK_CUR、SEEK_END 分别以哪里为基准？
11. 为什么 pipe 不能 lseek？
12. sparse file 的逻辑大小和实际磁盘占用为什么可能不同？
```

其中第 `1、2、3、4、6、7` 题必须能够结合今天的图口头解释。

---

## 6. 6.S081 与 Linux demo 的对应

先区分知识来源：

```text
直接来自 6.S081 1.5 / 1.6：
- read / write 按字节处理数据
- 连续 read 普通文件时会向后读取
- open 返回 fd
- 每个进程有自己的 fd 表

由 Day3 Linux 文档和实验补充：
- fd 表项指向 open file description
- offset 保存在 open file description 中
- 同一路径 open 两次通常得到独立 offset
- dup 后两个 fd 共享 offset
- stat / fstat 查询文件元数据
```

再把它们连接起来：

```text
课程现象：连续 read 会继续推进
→ Linux 机制：对应 open file description 的 offset 被推进

课程现象：每个进程有自己的 fd 表
→ Linux 机制：fd 是表项索引，表项再引用 open file description

课程现象：Unix 使用 file 抽象存储资源
→ Linux 接口：stat / fstat 从路径或已打开 fd 查询文件对象信息
```

不要说“6.S081 1.5 / 1.6 已经讲了 open file description”。准确表达是：课程给出了现象和第一层 fd 模型，Day3 再用 Linux 文档与 demo 解释机制。

---

## 7. day3_note.md 建议内容

不需要重复抄 Day1/Day2 的 `open/read/close` 定义。只记：

```text
1. dup = duplicate a file descriptor：复制入口，不复制文件数据
2. stat = get file status；fstat = 通过 fd 查询同类 status
3. lseek = reposition file offset；seek 是定位，offset 是离开开头的距离
4. fd → fd 表项 → open file description → 文件对象图
5. offset 属于哪一层
6. open 两次与 dup 的区别
7. stat / fstat 的区别
8. st_dev + st_ino 为什么一起比较
9. 一次 offset_dup 的手推和实际输出
10. 一组关键 strace 记录
11. pipe 不能 lseek 的原因
12. 今天答错或不确定的问题
```

代码中已经写清楚的机械步骤可以省略；但“共享什么、谁拥有、为什么”不能只靠代码代替。

---

## 8. 今日验收题

完成代码后，在 `day3_note.md` 回答：

```text
1. fd 数字本身为什么没有保存文件偏移？
2. open file description 至少保存哪些今天关心的状态？
3. read 成功返回 n 后，哪一层的什么状态发生变化？
4. 对同一路径 open 两次，为什么偏移通常相互独立？
5. dup 创建了什么，复用了什么？
6. duplicated fd 的整数不同，为什么仍共享偏移？
7. stat(path) 和 fstat(fd) 分别从哪里找到文件对象？
8. 路径在 open 后被重命名，为什么原 fd 通常仍可使用？
9. 判断同一文件为什么要同时比较 st_dev 和 st_ino？
10. Day2 copyfile 的同文件检查为什么必须在 O_TRUNC 前完成？
11. lseek(fd, 0, SEEK_CUR) 有什么用途？
12. 对 duplicated fd 调用 lseek，为什么 original fd 的后续 read 也受影响？
13. 为什么 pipe 没有普通文件式的随机偏移？
14. 三个 UniqueFd 分别拥有不同 fd，但其中两个共享 open file description，这会不会造成 double close？为什么？
```

---

## 9. 今日不提前深挖

```text
不进入 VFS / inode 内核源码
不系统学习硬链接和符号链接全部规则
不处理 TOCTOU 的生产级解决方案
不学习 pread / pwrite
不展开 page cache 和磁盘块分配
不提前进入 dup2 和标准流重定向
不正式开始 pipe 编程
```

---

## 10. 今日完成标准

```text
[ ] 能区分 1.5 / 1.6 原文内容与 Day3 的 Linux 补充内容
[ ] 能画出 fd → open file description → 文件对象
[ ] stat_info.cpp 编译无 warning
[ ] 能区分 stat 与 fstat
[ ] 能用 st_dev + st_ino 判断当前查询到的文件身份
[ ] 能解释同文件检查必须早于 O_TRUNC
[ ] offset_dup.cpp 编译无 warning
[ ] 先手推再验证 dup 共享 offset
[ ] 能解释重新 open 为什么有独立 offset
[ ] 能解释 lseek 修改的是哪一层状态
[ ] 能解释 pipe 为什么不可 seek
[ ] 至少跑一次相关 strace
[ ] day3_note.md 只记录新增重点和真实问题
```

---

## 11. Git 提交建议

```bash
git status
git add cpp/week4/day3
git commit -m "feat: inspect file metadata and shared offsets"
```

提交前确认：

```text
没有提交 stat_info / offset_dup 可执行文件
没有提交测试生成的普通文件和 sparse file
没有重复复制 unique_fd.hpp
```

---

## 12. 下一天衔接

Day4 将进入：

```text
dup / dup2
标准输入、标准输出、标准错误
输出重定向
fd 表变化
```

今天你已经知道：

```text
dup 让两个 fd 指向同一个 open file description
```

明天继续追问：

```text
dup2(old_fd, STDOUT_FILENO)
为什么能让原本写向终端的 stdout 改写到文件？
```

今天先把这条链压稳：

```text
路径 / fd 查询文件身份
→ st_dev + st_ino 判断同一对象
→ offset 属于 open file description
→ open 两次偏移独立
→ dup 后共享偏移
→ lseek 修改共享状态
```
