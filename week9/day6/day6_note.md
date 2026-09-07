## R1

```text
LT WAIT2 预测：
是会有通知的，因为这里的 LT 关注的是当前能不能去做 read-like operation，然后确实 recv queue 里面还有 bytes

ET WAIT2 预测：
不会有通知；ET 关注的是刚刚是否从无数据变到有数据，但是当我们第一次做完 recv 3 bytes 时，是从有数据到有数据。

new write 后 WAIT3 预测：
都有通知；因为对 LT 来说，有数据了；对 ET 来说，从没数据 -> 有数据。

实验结果：预测均正确

注意通过命令行选择模式，所以要注意 argc,argv
```

### argc argv

```cpp
int main(int argc, char* argv[]) {
    // ...
}
```

这里：

```text
argc：argument count，命令行参数总数
argv：argument vector，参数字符串数组
```

例如：

```bash
./lt_et_probe lt
```

则：

```text
argc == 2
argv[0] == "./lt_et_probe"
argv[1] == "lt"
```

你可以这样判断模式：

```cpp
#include <cstring>
#include <iostream>

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::cerr << "usage: ./lt_et_probe <lt|et>\n";
        return 1;
    }

    const bool edge_triggered = std::strcmp(argv[1], "et") == 0;

    if (!edge_triggered && std::strcmp(argv[1], "lt") != 0) {
        std::cerr << "mode must be lt or et\n";
        return 1;
    }

    // edge_triggered 为 true：ET
    // edge_triggered 为 false：LT
}
```

`argv[1]` 的类型是 `char*`，不能用 `== "et"` 比较字符串内容；要用 `std::strcmp`。

### strcmp

`std::strcmp` 是 C 风格字符串比较函数。

```cpp
#include <cstring>

int std::strcmp(const char* left, const char* right);
```

它逐字符比较两个以 `'\0'` 结尾的字符串，返回值：

```text
== 0：内容相同
< 0：left 的字典序更小
> 0：left 的字典序更大
```

你这里最常用的是判断相同：

```cpp
std::strcmp(argv[1], "et") == 0
```

意思是：`argv[1]` 的内容是否为 `"et"`。

例如：

```cpp
if (std::strcmp(argv[1], "lt") == 0) {
    std::cout << "LT mode\n";
} else if (std::strcmp(argv[1], "et") == 0) {
    std::cout << "ET mode\n";
} else {
    std::cerr << "mode must be lt or et\n";
    return 1;
}
```

为什么不能写：

```cpp
argv[1] == "et"
```

因为这比较的是两个 `char*` 指针地址，而不是字符串里的字符内容。`strcmp` 才是在比较 `e`、`t`、`\0` 这些内容。

### set O_NONBLOCK

差一点点，更准确地说：

```text
它给 fd 所指向的 open file description 设置 O_NONBLOCK 这个 file status flag。
```

效果是：之后通过这个 fd 做会等待的 I/O 时，系统不会让当前线程阻塞等待。

例如对一个 connected socket：

```text
recv：暂时没数据 -> -1，errno=EAGAIN/EWOULDBLOCK
send：当前 send buffer 没空间 -> -1，errno=EAGAIN/EWOULDBLOCK
```

而不是把 event-loop thread 卡住。

所以在你当前语境里，可以先记成：

```text
让这个 socket fd 的后续 recv/send 采用 non-blocking behavior。
```

但别把它理解成“修改整个 kernel socket object 的全局属性”。`O_NONBLOCK` 属于 open file description；如果你 `dup` 出另一个 fd，它们共享同一个 open file description，因此另一个 fd 也会看到这个 flag。

还有一个很实用的边界：

```text
listener 设置 O_NONBLOCK
-> 只保证对 listener 的 accept 不阻塞

新 accept 出来的 connection
-> 不一定自动 non-blocking
```

所以你 Day3/Day5 使用：

```cpp
::accept4(listener, nullptr, nullptr, SOCK_NONBLOCK | SOCK_CLOEXEC)
```

很合适：新 connection 在创建时就直接带 `O_NONBLOCK`。

## R2

```text
1. listener 与 connections 在 ET mode 下都带 EPOLLET ; ok
2. connection registration 增加 EPOLLRDHUP ; ok
3. 每个 ConnectionState 能表示 peer write side 是否已经结束 ok
4. HUP/RDHUP 到达后仍先 drain readable bytes ok
5. 已形成的 pending output 在 half-close 后仍能发送完成 ok
6. fatal/finished cleanup 后，本轮不再访问旧 state ok
7. interest mask 始终由 mode、read-side state 和 pending output 共同决定 ok

需要记录 peer_write_closed(在 
ConnectionState 的 member 增加对应 boolean)
根据 peer_write_closed 与 pending output 决定 interest 或 cleanup

规范化 event-loop 里 dispatch 的过程，并且 clean up 在对应 receiver_work/sender_work

规范化代码ing。

HUP/RDHUP 到达后仍先 drain readable bytes
对应 fd 的 handler 需要处理这个；这个需要提前(before EPOLLIN)去判断一下；
并且标记 peer_write_closed=true;

拿到 fd/event mask
-> 确认它仍对应 active ConnectionState
-> 若有 EPOLLERR，读取 SO_ERROR 并进入 fatal cleanup policy
-> 若有 EPOLLIN/RDHUP/HUP，推进 recv 到 bytes/EAGAIN/EOF/fatal boundary
-> connection 若已 fatal，停止
-> 若仍有 pending output 且本轮适合写，推进 send
-> connection 若已 fatal，停止
-> 根据 peer_write_closed 与 pending output 决定 interest 或 cleanup

因为每个 EPOLL 状态只有一位，所以我可以写一个 update EPOLL status 去 add/del 某一个位；这样替换掉 modify_epoll_info

如果说处理 connection 的时候，EPOLLOUT，那么我会尝试 send。并且即使是 EPOLLHUP 我也是可以尝试的，大不了就返回错误。

需要注意的是，当 peer_write_closed 的时候，peer 不会再发过来的，如果我的 output 也空了，因为我是 echo，所以后续我也不会再发送了，可以清理 connection
```

