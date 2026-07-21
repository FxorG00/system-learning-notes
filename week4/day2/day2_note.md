## os

### 3.2 操作系统隔离性（isolation）

#### 为啥需要 isolation

**User/kernel mode 是 CPU 提供的硬件机制；OS 是使用这个机制实现隔离的软件。**

##### CPU 本身提供两种权限

这是硬件设计好的能力：

```
User mode：权限低，不能直接操作硬件
Kernel mode：权限高，可以操作内存、磁盘、CPU 等硬件
```

##### OS 使用这两种模式

```
应用程序运行在 User mode
操作系统内核运行在 Kernel mode
```

```text
我们需要保证在不同的应用程序之间有强隔离性。
因为如果没有的话，比如 shell 出现问题，杀死了其他进程，那么很糟糕。

我们需要应用程序与操作系统之间有强隔离性。
如果没有的话，比如某个应用程序出现问题，然后影响了操作系统，使其崩溃。

如果没有操作系统的话，会怎么样？

那就没有 kernel 来管理硬件了，就难以实现在应用程序之间调度和内存隔离。

CPU 是会从一个应用程序切换到另外一个应用程序。目的是同时运行多个应用程序。我们假设 CPU 只有 1 个核。然后我们有 shell 和 echo 两个应用程序，如果 shell 死循环卡住了，那么他永远不会释放 CPU，并且也没有其他程序能杀死他，导致 CPU 没办法切换应用程序。
从而我们得不到真正的 multiplexing（CPU 在多进程分时复用）

从内存的角度说。没有操作系统可能导致两个应用程序的内存相互覆盖。
没办法实现内存隔离。


综上。
os 不是直接将 CPU 提供给应用程序，而是向应用程序提供 process，process abstract CPU。每个时刻一个核上只运行一个 process，由 kernel 进行调度。

```

#### system call interface

**system call interface（系统调用接口）**，用于让 user mode 的程序请求 kernel 提供服务。

```
User mode 程序
    ↓ 调用系统调用接口
open / read / write / fork / exec ...
    ↓ trap / syscall / ecall 指令
进入 Kernel mode
    ↓
内核检查参数并操作文件、进程、内存、设备
    ↓
返回用户态程序
```

##### exec

`exec` 的作用一句话说就是：

> **把“当前进程正在运行的程序”整个替换成另一个程序。**

比如当前进程正在运行 `shell`：

```
当前进程 PID = 123
运行内容：shell 的代码、数据、栈、堆
```

它调用：

```
exec("/bin/ls", ...);
```

成功后变成：

```
当前进程 PID = 123
运行内容：ls 的代码、数据、栈、堆
```

注意两点：

1. **没有创建新进程**，PID 通常不变。
2. 当前程序的代码、全局数据、堆和栈被新程序替换。

可以这样理解：

```
进程 = 一个运行容器
程序 = 磁盘上的可执行文件

exec = 把新程序装进当前这个进程容器
```

为什么 exec 成功后不会返回？

假设：

```
std::cout << "before exec\n";

exec(...);

std::cout << "after exec\n";
```

如果 `exec` 成功，第二句不会执行。因为调用 `exec` 的旧程序已经被替换掉了，原来的代码和栈都不存在了。

##### exec 和 fork 的分工

Unix 通常这样启动新程序：

```
fork
→ 创建一个子进程

子进程调用 exec
→ 把子进程替换成目标程序

父进程继续运行
```

例如 Shell 执行 `ls`：

```
shell
  │
  ├── fork → 创建子进程
  │
  └── 子进程 exec("/bin/ls")
                  ↓
              变成 ls 程序
```

所以：

```
fork：创建新进程
exec：替换当前进程运行的程序
```

## 3.3 操作系统防御性（Defensive）

```text
我们要确保 kernel 具有 defensive。

因为如果应用程序向 system call 传入了一些错误的参数导致 os 崩溃，肯定是不行的。
另一个的话，如果攻击者想要打破 user mode 与 kernel 的隔离，从而控制内核，然后控制硬件，这也是不行的。

因此，就是要具有 defensive。
```

## 回答问题

```text
1. isolation 主要在隔离什么？
应用程序与应用程序
应用程序与 kernel

2. 为什么内核不能信任用户传入的 fd、地址和长度？
因为可能传入一些让 kernel 可能崩溃的参数。所以 os 要具备 defensive。

3. 坏参数为什么应该导致当前调用失败，而不是 kernel panic？

内核把用户参数视为不可信数据
→ 检查 fd、地址、长度和权限
→ 参数无效时让系统调用失败
→ 返回 -1，并通过 errno 说明原因

4. file 和 process 分别抽象了哪类资源？
file 抽象了磁盘。
process 抽象了 CPU。
```

## 正文

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

为了避免手动写一堆 close，我们利用 RAII 来管理 fd。

这就是与 day1 的区别！

### write_all

```text
write_all(fd, data, size)
成功：size 个字节全部写完，返回 true
失败：打印原因，返回 false
它只借用 fd，不负责 close

怎么实现？用 offset 表示当前已经写入了 [0,offset) 的数据，需要写 [offset,size) 的数据。

每次调用 ::write(fd,buffer,n) 去向 fd 写入字节。
```



