不是。TSan 是 `ThreadSanitizer`，用于发现多线程里的 data race。

它会检查：

```text
两个或更多线程
同时访问同一块内存
至少一个是写
但中间没有 mutex、atomic 等正确同步
```

例如：

```cpp
int count = 0;

std::thread a([&] { ++count; });
std::thread b([&] { ++count; });
```

这里 `count` 有 data race；用：

```bash
g++ -std=c++17 -Wall -Wextra -g -fsanitize=thread -pthread app.cpp -o app_tsan
```

运行后 TSan 会报告冲突的读写位置和两个线程的调用栈。

看 system call 用的是 `strace`，例如：

```bash
strace -f -e trace=epoll_wait,recvfrom,sendto ./server
```

对，`strace` 就是 **system call tracer**，可理解为“系统调用追踪器”。

它让你看到进程实际向 Linux kernel 发了哪些 system call、参数是什么、返回值是什么，例如：

```text
epoll_wait(...)
accept4(...)
recvfrom(...)
sendto(...)
close(...)
```

所以它特别适合验证：

```text
代码以为自己调用了什么
vs
进程实际上调用了什么 syscall
```

比如：

```bash
strace -f -e trace=epoll_wait,accept4,recvfrom,sendto ./server
```

`-f` 表示连同子进程或线程一起追踪；`-e trace=...` 表示只显示你关心的 system calls。