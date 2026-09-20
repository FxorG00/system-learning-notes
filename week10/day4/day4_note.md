## R1

```text
Acceptor 只拥有 listening fd；它不拥有 accept4 得到的 connected fd。

Acceptor = listening socket owner + listening Channel owner + accept path

需要设置 listening socket 是 non-blocking 的；其实基本上是把 epoll_echo_server copy 过来。

member: listener_fd, listener_channel,start_flag,listening_flag,loop,port,backlog

我需要用 RAII UniqueFd 去管理 listener_fd，这样不会泄露。

设置的 connection_callback 有啥用？
就是说在 accept 得到一个 connected fd 之后，去调用这个 callback，并且用这个 fd 去构造一个 UniuqeFd，把这个 object move 进 callback 的参数里面。

poll_once 的时候，传回来的 event 是 listener 的，那么会去调用 listener_channel 的 handle_event()，也就是我们需要为 listener 准备 read_callback；即 ready_behavior
这个 read_callback 是一直 accept4 得到 connection_fd，然后去调用 connection_callback 的
```

```text
void start();

要求 callback 已设置
调用 listen
让 listener Channel 关注 EPOLLIN
把 Channel ADD 到 EventLoop
成功后标记 listening_flag 为 true

start
-> listening Channel read callback 指向 this->handle_accept()
-> Channel 关注 EPOLLIN
-> EventLoop ADD listening Channel
```

### 一个语法点

这是 C++ 类成员声明的语法问题。

```cpp
Channel listener_channel_(-1);
```

这不是“构造一个 `Channel(-1)`”的合法成员写法。类定义内部，成员的默认初始化只能用：

```cpp
Channel listener_channel_{-1};
```

或：

```cpp
Channel listener_channel_ = Channel{-1};
```

第一种更推荐。

你原来的圆括号形式会让编译器尝试把它按“某种成员函数声明”去解析；但 `-1` 显然不是参数类型，所以它报：

```text
expected a type specifier
```

不过对你的 `Acceptor` 来说，`{-1}` 只是语法上能过，设计上不该是最终答案。因为 `Channel` 的 fd 初始化后不会再改：

```cpp
Channel listener_channel_{-1};
```

意味着它永远描述 fd `-1`，而不是之后 `socket()` 得到的真实 listener fd。

你真正需要的结构应当是：

```cpp
UniqueFd listener_fd_;
Channel listener_channel_;
```

然后在 `Acceptor` 构造函数的初始化列表里，先构造出真实的 `listener_fd_`，再用：

```cpp
listener_channel_(listener_fd_.get())
```

构造 `listener_channel_`。

并且成员声明顺序必须保证：

```cpp
listener_fd_
-> listener_channel_
```

因为初始化顺序由成员声明顺序决定，不由初始化列表的书写顺序决定。你这里已经把 `listener_fd_` 写在前面了，方向是对的。

顺便一点：你既然已经 `#include "unique_fd.hpp"`，listening fd 最终也应该用 `UniqueFd`，不要保留成裸的：

```cpp
int listener_fd_ = -1;
```

否则 `bind` 或 `getsockname` 在构造函数中途抛异常时，`Acceptor` 自己尚未构造完成，析构函数不会运行，裸 fd 容易泄漏。

### 成员函数隐含 this 对象，不是无参数的 callable

```text
解决：
利用 lambda 去 capture this，然后构成 no argument callable
```

### port=0 后 kernel 为我选择的 port 去哪里找

因为 `bind` 把你的 `address` 当作输入，不会把 kernel 选出的实际端口反写回这块用户态内存。

```cpp
address.sin_port = ::htons(0);
```

这里的 `0` 意思是：

```text
请 kernel 为这个 socket 选一个可用的 ephemeral port。
```

kernel 确实选了端口，并把它记录在 `listen_fd` 对应的 socket 内核对象里；但你的局部变量 `address.sin_port` 仍然是原来的 `0`。

成功 `bind` 后，用 `getsockname` 向 kernel 查询实际绑定结果：

```cpp
socklen_t address_length = sizeof(address);

if (::getsockname(
        listen_fd,
        reinterpret_cast<sockaddr*>(&address),
        &address_length) == -1) {
    throw std::system_error(
        errno,
        std::generic_category(),
        "getsockname"
    );
}

const std::uint16_t actual_port = ::ntohs(address.sin_port);
```

这一次 `getsockname` 会把实际地址写进 `address`：

```text
address.sin_port：
network byte order 的实际端口

ntohs(address.sin_port)：
host byte order 的普通整数端口号
```

所以不是 kernel 永远选了 `0`，而是你现在看的还是传给 `bind` 的“请求”，还没向 kernel 取回最终结果。

## R1 补

```text
析构的时候需要向 loop remove channel；因为后面要析构了，所以要向注册删除掉这个。
```

