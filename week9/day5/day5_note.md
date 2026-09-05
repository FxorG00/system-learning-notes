## R1

### coding 前

```text

127.0.0.1:9091

每个 connection 独立解析 newline-delimited messages:
就是给每个 connection 独立保存一份 ConnectionState class instance

每条完整 message 原样 echo：
也就是说，对于一个 connection 的 output，我们要把这些 bytes send 出去。

但是因为是 non-blocking send，所以我们一直发送直到遇到 EAGAIN，然后此时没办法再 send 了，那我们只好退出并且等待下次有办法做 write-like operation 的时候；
其实就是需要一个 epoll 去看，哪个 connection 可以去 send 了！

综上，对于 listener，connected sockets 我们需要一个 epoll 去管理；对于 connection 的话我们需要 EPOLLIN，以及 EPOLLOUT（当 output 不为空时注册；当 output 为空，也就是发送完毕后 EPOLL_CTL_MOD：从 interest mask 中移除 EPOLLOUT ）

然后我们还是采取 event loop:
循环：等待通知，处理通知对应的工作，回到等待通知。
并且在处理通知对应的工作时我们根据 fd,event=EPOLLIN/OUT 去 dispatch 到对应的 handler

所以我们应该新增 sender_work(fd) 这个 handler
去把 fd 对应的 connection 对应的 output 去做 non-blocking send。

需要注意，一个 fd 指向一个 kernel socket object；然后你可以向这个 socket recv/send，这是你去调用决定的。

我们需要一个 modify_epoll_info 的接口，去修改某个 fd 对应的 EPOLLIN/EPOLLOUT 信息

clear(fd):
直接清理这个 connection 即可
显式 DEL+ ::close
这是对于某个 connection 遇到错误的时候关闭这个 connection 的调用

然后我们需要一个 set 用来管理尚未 close 的 fd，这样便于我们在遇到错误的时候退出去清理。
```

### coding 时

```text
我需要一个 std::map 来帮助我实现 fd-ConnectionState

因为后续 fd 可能很多，所以我拒绝了开固定大小的数组。

我需要把 receive_work 接收到的 bytes 直接 append 进去对应的 ConnectionState；
创建时为 ConnectionState 初始化！


```

## R2

```text
如果 modify_epoll_info 失败，则清理这个 connection

receiver_work 可能先清理连接，随后 sender_work 又通过 connection_state[fd] 创建空的 ghost state。R2 需要修复。
针对以上问题新增了操作 fd 前进行判断，该 fd 是否还尚未 close。

:30,84：modify_epoll_info() 失败被忽略，会造成 application state 和 kernel interest 不一致。
做法：如果失败了，那我直接clear 这个连接。

```

## R3

```text
modify_epoll_info 可能调用 clear
导致 ConnectionState 遭到析构；

阻塞问题
epoll_echo_server.cpp:139-150 的 modify_epoll_info() 在 MOD 失败时直接调用 clear_connection()，这会销毁当前 ConnectionState。
随后调用者还会访问它：
- append_char():21-32 继续修改 message_count_、input。
- send_output():91-95 继续执行 output.clear()、offset = 0。

我的解决方法是不让 ConnectionState 的 member function 调用 modify
让上层的去调用，这样我能保证在 modify 之后不会再可能访问 ConnectionState；
以及让 modify 的 returned 生效，如果 returned true 代表 connection 已经关闭了，则上层接收到后要退出！
```

