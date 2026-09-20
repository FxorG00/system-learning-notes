## R1

```text
day5 是目前最有挑战的一天。但也还好。
Acceptor,Connection 设计思路类似。

Acceptor 是拥有并且管理 listening socket 的
Connection 拥有并管理 connected socket

connection member: connected socket,connection channel,input/output buffer,message_callback,close_callback,start_flag

明确：connection 的核心是去 send/recv  bytes；其他的并不是其核心职责。

connected socket 出现 read-related readiness
-> Channel 调用 Connection 的 private read handler
-> read handler 调用 recv
-> recv 返回 n > 0
-> Connection 把这 n bytes append 到自己的 input Buffer
-> 当前 read-drain 结束后，Connection 调用已保存的 MessageCallback
```

### transport,application 职责分开

```text
但是我们的 connection 是拥有 input/output buffer 的；这个的意思是说，我们要把 transport 跟 application 的职责给分开，就是我们的 connection 只去 recv 并且把 n bytes 加到 input buffer；怎么样解析 bytes 是 application 提供的 message callback 的事情。

所以目前我们不需要去理会怎么样把 message 从 input buffer->output buffer
```

### close request

```text
多次 close 只发送一次 request

close callback
真正触发它的是 `Connection`：当 peer EOF 后 output 已经 drain，或者 socket 遇到无法继续的 fatal error 时，Connection 发出一次 close request。即调用一次 close callback
```

### handle_recv

```text
类似 acceptor 的 handle_accept。
connection 在 epoll_wait 得到对应的 EPOLLIN 的 event 的时候，会去调用对应 channel 的 handle_event，进而调用 read_callback；我们需要为 channel 安装这个 read_callback。这个在 start 时安装，并且向 eventloop add channel

也就是 handle_recv:
在能 recv 的情况下，一直 recv，直到遇到边界。跟之前的 epoll_echo_server 的 receiver_work 类似。copy
并且把每次 recv 得到的 n bytes 都加入到 connection 的 input；
不能再 recv 的时候，看本次有没有 recv 的 bytes>0，有的话调用 connection 的 message_callback
```

### output 是干啥的？

```text
MessageCallback 会从 input 里解析出完整 message
生成 response
调用 connection.send(response)
connection 负责把 response ::send 出去

但是问题是，我们的 connected socket non-blocking
所以尽管调用 send，也不能保证 response 均发送出去。
所以还会剩下一段本次没有被发出去的 response，我们直接 append 到 output buffer 里面
等待下次再先发 output buffer
```

### send

```text
::send output buffer 的内容并且 retrieve
::send data 的内容，直至遇到边界
data 中没有被 send 的 bytes append 到 output buffer 里面

既然如此，我们先把 data append 到 output
再统一发 output 即可，不需要两次 while
```

### EPOLLRDHUP

````text
收到这个通知意味着 peer 已经关闭了 write
我需要去调用 read_callback

EPOLLHUP 就是 peer 已经关闭了连接，同样也是需要调用 read_callback，去接收还未 recv 的 bytes

你当前 Day2 `Channel` 如果只把 `EPOLLIN` 路由给 read callback，需要做一个很小的 integration update：让 `EPOLLRDHUP`/`EPOLLHUP` 也能触发 read-side handling

Day5 建议 read-related interest 包含：
```text
EPOLLIN | EPOLLRDHUP
```
也就是多注册一个 EPOLLRDHUP
````

### channel 新增 add/del_interest_events

```text
为了便于我们增加/删除某个 EPOLLxxx
```

### handle_send

```text
start 时给 channel 的 write_callback 安装 handle_send
因为 output 不可能一次性都发完。
所以我们要在通知 EPOLLOUT 的时候去调用 handle_send
尝试去发 output
```

### 析构函数不调用 close callback

```text
close callback 是请求 owner 去销毁这个对象
而在析构函数的时候，已经是在销毁这个对象了，所以肯定不需要再次发请求。
```

### peer_write_closed_flag_ 意味着什么？

```text
意味着 peer 不会再 send 过来 bytes
并且，我是在 recv 到 EOF 的时候，再去 set 这个 flag，所以还代表着，我已经接收完了所有 bytes
```

### Connection 不可移动/复制

这是 `std::vector<Connection>` 和你刻意设计成“不可移动”的 `Connection` 冲突了。

报错主线是：

```text
vector.emplace_back(...)
-> vector 未来可能扩容
-> 扩容时需要把旧 Connection 搬到新内存
-> 尝试构造 Connection(Connection&&)
-> 但你写了 Connection(Connection&&) = delete
-> 编译失败
```

报错中的这段最关键：

```text
std::move_iterator<Connection*>
...
result type must be constructible from value type
```

它表示：`vector` 正在尝试把旧数组里的 `Connection` move 到新数组，但做不到。

而且这不是单纯“把 move constructor 打开”就该解决的事。你这个 `Connection` 现在通常含有：

```text
Channel
Channel callbacks 里的 [this]
EventLoop 中保存的 Channel*
```

假如 `vector` 扩容把 `Connection` 从旧地址搬到新地址：

```text
旧 Connection 地址失效
-> Channel callback 可能还捕获旧 this
-> EventLoop registry 可能还保存旧 Channel*
```

这会直接变成悬空指针/lifetime bug。所以 Day5 的 `Connection` 当前应该保持不可复制、不可移动，这个设计是对的。

真正该调整的是 server owner 保存 active connections 的方式：容器可以移动“owner”，但每个 `Connection` object 本身地址必须稳定。典型形态是：

```cpp
std::unordered_map<int, std::unique_ptr<Connection>> connections_;
```

或者：

```cpp
std::map<int, std::unique_ptr<Connection>> connections_;
```

这里 map/unordered_map 可能 rehash、节点可能移动，但移动的是 `unique_ptr`；它指向的 heap 上 `Connection` 地址不变。

一句话：

```text
vector<Connection> 要求 Connection 可移动；
但当前 Reactor Connection 绑定了 callback / Channel / EventLoop identity，不该移动；
所以应让 owner 容器保存 unique_ptr<Connection>。
```

`reserve()` 也不是根治，只是把第一次扩容推迟；超过预留容量后问题仍然回来。

### unique_ptr

最常用的是 `std::make_unique`：

```cpp
#include <memory>

auto connection = std::make_unique<Connection>(loop, std::move(socket));
```

它做了三件事：

```text
new Connection(loop, std::move(socket)
-> 得到 Connection*
-> 交给 std::unique_ptr<Connection> 独占管理
```

等价但不推荐手写的版本：

```cpp
std::unique_ptr<Connection> connection(
    new Connection(loop, std::move(socket)));
```

你的 Day5 场景可以这样理解：

```cpp
std::unordered_map<int, std::unique_ptr<Connection>> connections;

auto connection = std::make_unique<Connection>(loop, std::move(socket));

const int fd = connection->fd();
connection->set_message_callback(...);
connection->set_close_callback(...);
connection->start();

connections.emplace(fd, std::move(connection));
```

`std::move(connection)` 不是移动 `Connection` object；移动的是 `unique_ptr` 的所有权。

```text
move 前：local variable connection owns heap Connection
move 后：connections[fd] owns the same heap Connection
```

heap 上那个 `Connection` 的地址不变，所以 `Channel` 保存的 callback `this`、以及 `EventLoop` 保存的 `Channel*` 不会因为容器扩容而失效。

### 如何关闭 fd，在 reactor_echo_server 里

**关键问题**

`reactor_echo_server.cpp:46-48` 的 cleanup 写错了：

```
for (auto fd : pending_close) {
    ::close(fd);
}
```

这里关闭了 fd，但没有删除：

```
connections[fd]
```

结果是：

```
旧 Connection 仍在 map 中
-> EventLoop 中仍保存旧 Channel*
-> UniqueFd 仍认为自己拥有该 fd
-> kernel 可能复用相同 fd
-> 新连接插入 connections 失败
-> 新 Connection 被销毁
-> client 被 reset
```

实际验证：

```
第一次 reactor_echo_smoke.py：PASS
第二次 reactor_echo_smoke.py：Connection reset by peer
server：仍然存活
```

正确的 owner cleanup 是：

```
for (int fd : pending_close) {
    connections.erase(fd);
}
pending_close.clear();
```

不要手动 `::close(fd)`。`erase` 会触发：

```
Connection destructor
-> remove Channel
-> UniqueFd destructor
-> close connected fd
```

### map erase 发生了什么？

对，你这条理解基本完全对，但要区分容器类型。

如果你用的是：

```cpp
std::map<int, std::unique_ptr<Connection>> connections;
```

那么 `std::map` 通常是红黑树。执行：

```cpp
connections.erase(fd);
```

大致发生：

```text
map 根据 key=fd 找到对应红黑树节点
-> 删除该节点
-> 销毁节点中的 pair<const int, unique_ptr<Connection>>
-> unique_ptr<Connection> 析构
-> delete 它持有的 heap Connection
-> Connection::~Connection() 执行
-> Connection 的成员依次析构
-> UniqueFd 析构，最终 close connected socket
```

所以 `erase` 本身不认识 `Connection`，也不特别认识 RAII；它只是遵循 C++ 的对象生命周期规则：

```text
容器删除元素
-> 元素析构
-> 元素里的 unique_ptr 析构
-> unique_ptr 自动析构其独占对象
```

你说的“`unique_ptr` 已经 move 到节点上”也对：

```cpp
connections.emplace(fd, std::move(connection));
```

之后 local variable `connection` 变空，红黑树节点中的 `unique_ptr` 成了唯一 owner。

不过这也是为什么 Day5 不能在 `Connection` 自己的 callback 还在执行时直接：

```cpp
connections.erase(fd);
```

因为这会立刻析构当前正在运行的 `Connection`。所以我们先记录 `pending_close`，等 `poll_once()` 返回后再 `erase`。Day6 会专门把这个 lifetime 问题做严谨。

### port 被占用了；怎么关闭占用 port 的 process

对，`9091` 已经被某个 listening socket 占着了，最可能就是上次启动的 echo server 还在运行。

先查是谁占用：

```bash
ss -lntp 'sport = :9091'
```

如果看到类似：

```text
LISTEN ... 127.0.0.1:9091 ... users:(("reactor_echo_server",pid=12345,...))
```

记住 `pid=12345`，然后正常结束它：

```bash
kill 12345
```

再确认端口已释放：

```bash
ss -lntp 'sport = :9091'
```

没有输出后，重新启动：

```bash
./build/reactor_echo_server 9091
```

如果 `kill` 后它仍不退出，再用：

```bash
kill -9 12345
```

但先用普通 `kill` 就够了。

也可以临时换端口：

```bash
./build/reactor_echo_server 9092
```

不过你当前的 `reactor_echo_smoke.py` 默认连 `9091`，换端口后也要对应改 client；现在更适合释放旧的 `9091`。

`terminate called after throwing ... bind: Address already in use` 的原因是：你的 `Acceptor` 正确地把 `bind` 失败包装成 `std::system_error`，但 `main` 没有 catch 它，于是进程打印错误后终止。真正的问题不是 `system_error`，而是端口已被占用。

### std::size_t 倒序 for

> 如果我们写 for(std::size_t i=size-1;i>=0;i--)，那么当 i=0 时会尝试 i--，绕到一个特别大的整数，这是不可以的。因为是 unsigned
>
>  那么怎么办？那其实枚举 i+1 就好了。

不用转 `int`。最清楚、安全的写法是把 `i` 当成“当前要检查范围的长度”，而不是数组下标：

```cpp
const std::size_t readable = input.readable_bytes();
const char* begin = input.peek();

std::size_t prefix_length = 0;

for (std::size_t i = readable; i > 0; --i) {
    if (begin[i - 1] == '\n') {
        prefix_length = i;
        break;
    }
}

if (prefix_length != 0) {
    connection.send(begin, prefix_length);
    input.retrieve(prefix_length);
}
```

这里 `i` 的变化是：

```text
readable = 3

i = 3 -> 检查下标 2
i = 2 -> 检查下标 1
i = 1 -> 检查下标 0
i = 0 -> i > 0 为假，循环结束
```

所以永远不会真的出现“下标 `-1`”。`i - 1` 只会在 `i > 0` 已经成立时计算。

你原来的：

```cpp
for (std::size_t i = n - 1; i >= 0; --i)
```

有两个问题：

- `std::size_t` 是无符号数，`i >= 0` 永远为真。
- 当 `i == 0` 再 `--i` 时，它不会变成 `-1`，而是绕回一个非常大的无符号数。

不建议为了倒序就 `static_cast<int>`；除非你能证明长度永远不超过 `INT_MAX`，否则是人为缩窄范围。这里用 `i > 0` 再访问 `i - 1` 是 C++ 里最常见的 `size_t` 倒序模式。

### 修完上面的 bug 后又多一个

```cpp
上面记录改为 pos=i-1
if(pos!=-1) {
    connection.send(input.peek(),pos+1);
    input.retrieve(pos+1);
}
```

