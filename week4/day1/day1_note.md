## mit 6.s081

### 1.2 操作系统结构

```text
应用程序位于 user space
区别于 user space 里的程序，kernel 是一个特殊的程序，总是被第一个启动。
kernel 管理文件、进程、内存和设备
system call 是连接用户程序与 kernel 的 interface
file descriptor 是应用程序访问已打开资源的 handle

为什么应用程序不直接操作磁盘？
user mode,kernel mode,底层硬件，只有 kernel 才能跟底层硬件打交道，而 user mode 里的应用程序需要通过 interface 与 kernel 交互，才能操作磁盘。
```

### 1.5 read, write, exit系统调用

### 1.6

```text
fd 本质对应 kernel 里的一个表单数据。
kernel 维护了每个运行进程的表单。
表单的 key 是 fd。
并且每个进程都有自己独立的表单。
```



## 笔记

### fd,file descriptor

```cpp
int fd = ::open("note.txt", O_RDONLY);
```

就是 `open()` 成功后会返回一个非负整数。

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

fd 是当前进程用来访问某个内核资源的编号。

比如现在，你就用 `fd=3` 就可以访问内核中的 note.txt，所以后面我们就不需要传 note.txt 了，一个 3 就好了。

### errno,perror

errno=error number，错误编号。

当一个函数失败的时候，会返回 -1，表示失败。并且把具体的错误编号写入 errno。

perror 就是去 print error，把 errno 翻译成人能看的文字。`::perror("open");` 可能输出 `open: No such file or directory`，就是你提供的 `str+错误信息`。

### unistd.h

```text
#include <unistd.h>
理解为 UNIX standard
包含 Unix/POSIX 标准接口声明的头文件
有
read()
write()
close()
fork()
pipe()

还定义了
STDIN_FILENO   // 0
STDOUT_FILENO  // 1
STDERR_FILENO  // 2

FILENO 就是 file descriptor number，文件描述符编号

Linux 上有，win 没有
```

例如：

```cpp
#include <unistd.h>

::write(STDOUT_FILENO, "hello\n", 6);
```

这里前面的 `::` 表示使用**全局命名空间**中的 `write`。它不是 C++ 标准库的：

```
std::write // 没有这个
```

### cat

`mycat` 就是 **my cat**，意思是“我自己实现的 `cat` 命令”。

Linux 自带 `cat`：

```
cat sample.txt
```

它会把**文件内容输出到标准输出，也就是通常显示在终端**：

```
文件
  ↓ read
cat 程序
  ↓ write
标准输出 fd 1
  ↓
终端
```

我们写的：

```
./mycat sample.txt
```

是在模仿它最基础的功能：

```
1. open 打开文件
2. read 循环读取文件
3. write 写到标准输出
4. close 关闭文件
```

这里的 `cat` 原本来自 **concatenate**，意思是“连接、串联”。因为真正的 `cat` 可以连续输出多个文件：

```
cat a.txt b.txt
```

它会依次输出：

```
a.txt 的内容
b.txt 的内容
```

而当前的 `mycat` 只实现一个文件的最小版本，重点不是复刻完整 `cat`，而是练习：

```
open → read → write → close
```

## 中途检查题

```text
1. open 成功和失败分别返回什么？
open 成功，返回 fd
失败，返回 -1

2. fd 3 是否表示“第三个文件”？
不是，只是一个编号，用于当前进程访问 kernel 中的资源。

3. read 返回 0 和 -1 分别是什么？
0：EOF
-1：read 失败了

4. read 返回 20 时，为什么不能输出整个 buffer？
返回 20 是因为本次只有 buffer[0..19] 是有效的，与整个文件是否读完无关，后续需要看再次 read 是否为 EOF 来判定。

5. 为什么 write 也要检查实际返回值？
因为可能一些字节没成功写入。

6. open 成功后，哪些路径需要 close？
所有退出路径。

7. 为什么 mycat 不应该 close STDOUT_FILENO？
因为这个 fd 的生命周期不归我们管。

8. errno 应该在什么前提下读取？
在有错误/某个函数失败的前提下。
```

### close

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

### 验收题目

```text
1. 用户态程序为什么需要系统调用才能访问文件？
上面有了

2. fd 是什么？它为什么只是一个 int？
file descriptor。因为 kernel 会为每个 process 都保存一个 fd 表单，这里的 fd 只是一个 key 而已，所以是 int。

3. fd 0、1、2 通常分别表示什么？
STDIN STDOUT STDERR

4. open/read/write/close 的成功和失败怎样判断？
-1 是失败
其他是成功

5. read 返回 0、正数和 -1 分别表示什么？
0：EOF
正数：读取到的字节数
-1：读取失败

6. read 为什么不能保证一次取得请求的全部字节？
因为可能字节流长度超过了 buffer 的大小。

7. write 为什么可能需要循环？
因为可能没办法一次 write 完所有字节。

8. 为什么不能直接把 read 后的 buffer 当 C 字符串输出？
结尾没有 \0。

9. errno 在什么时候才有意义？perror 做了什么？
上面有

10. 为什么 open 成功后必须考虑所有退出路径上的 close？
啥意思？不是最后记得 close open 得到的 fd 就好了嘛？

11. strace 为什么可能显示 openat，而源码中写的是 open？
open 是 POSIX 接口，由 C 库提供包装；
在 Linux 上包装层可能通过 openat 系统调用进入内核。

12. close 后，fd 变量还在，为什么资源却已经无效？
因为这个 fd 数字虽然还在，但是对应的 handle 已经不属于这个 process 了。
```

## 代码

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

// argc：argument count 命令行参数数量，包含程序名本身。
// argv：argument vector 参数字符串数组。
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

