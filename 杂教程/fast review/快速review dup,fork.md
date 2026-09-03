你记得的那条链，核心是在：

- [Week4 Day3 §2](C:/Users/FxorG/Desktop/gpt_infra/week4/day3/day3.md:266)：`fd -> fd table entry -> open file description -> file object`
- [Week4 Day3 §3](C:/Users/FxorG/Desktop/gpt_infra/week4/day3/day3.md:351)：`open` 两次和 `dup` 的根本区别
- [Week4 Day5 §8](C:/Users/FxorG/Desktop/gpt_infra/week4/day5/day5.md:921)：`fork` 后父子怎样共享同一个 open file description
- [Week4 Day6](C:/Users/FxorG/Desktop/gpt_infra/week4/day6/day6.md:351)：用 `pipe + fork + dup2` 实际观察继承与重定向

先把三种情况并排摆回来：

```text
1. 同一路径 open 两次

fd 3 -> open file description A -> 同一个底层 file object
fd 4 -> open file description B -> 同一个底层 file object

A、B 是两个不同的“本次打开状态”
所以：
offset 独立
O_NONBLOCK 等 file status flags 独立
```

```text
2. dup(fd1)

同一个 process 的 fd table：

fd 3 --\
        -> 同一个 open file description A -> file/socket object
fd 4 --/

dup 创建：
    新的 fd table entry

dup 不创建：
    新的 open file description
    新的底层 file/socket object

所以共享：
    current file offset
    O_NONBLOCK 等 file status flags
```

例如普通文件：

```text
fd 3 从 offset 0 read 3 bytes
    |
    v
同一个 open file description 的 offset 变成 3
    |
    v
fd 4 再 read
    |
    v
从 offset 3 开始
```

`close(fd 3)` 只移除 fd 3 这个入口；fd 4 仍然能用。等最后一个引用这个 open file description 的 fd 被关闭，它才会释放。

`fork` 的关键是：它新建的是 **child process 的 fd table**，不是重新 `open` 资源。

```text
fork 前：

parent fd table
fd 3 -> open file description A -> file/socket object


fork 后：

parent fd table                 child fd table
fd 3 --------\                 /-------- fd 3
              \               /
               -> 同一个 open file description A
                         |
                         v
                  file/socket object
```

所以 `fork` 后：

```text
父、子各自有独立 fd table
父的 fd 3 和子的 fd 3 都是各自进程里的整数入口
但两个 entry 一开始引用同一个 open file description
```

因此也共享：

```text
普通文件的 current offset
O_NONBLOCK 等 file status flags
```

但父进程 `close(3)` 不会把子进程的 `3` 一起关掉；它们是两个 fd table entry。只有两边都不再引用这个 open file description，相关内核打开状态才会释放。

放回你现在的 Week9 `O_NONBLOCK`：

```text
dup：
同一个进程的两个 fd
-> 同一个 open file description
-> 改 O_NONBLOCK，两个 fd 都会观察到

fork：
父、子各自的对应 fd
-> 同一个 open file description
-> 父或子改 O_NONBLOCK，另一边也可能观察到

socketpair:
fd[0] -> open file description A -> endpoint A
fd[1] -> open file description B -> endpoint B

A、B 是两个不同 endpoint，也是两个不同 open file descriptions
-> 只把 fd[0] 设 O_NONBLOCK
-> fd[1] 不会自动变成 non-blocking
```

还有一个容易混淆的边界：

```text
O_NONBLOCK
= file status flag
= 属于 open file description
= dup / fork 共享时会共享观察

FD_CLOEXEC
= fd flag
= 属于某个 fd table entry
= 不应和 O_NONBLOCK 混为同一种 flag
```

一句话重新压缩：

> `dup` 复制同一进程里的 fd entry；`fork` 复制出 child 的 fd table entries；二者都不是重新 `open`，所以都会让对应 entry 指向同一个 open file description。