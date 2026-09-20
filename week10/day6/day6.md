# Week10 Day6：Callback Lifetime、Deferred Cleanup 与 Stale Event

> 当前主线：Reactor V1
>
> 前置：Week10 Day1~Day5 已正式通过
>
> 今日定位：加固现有 Reactor，不重写 Buffer、Channel、EventLoop、Acceptor 或 Connection
>
> 默认环境：Linux，C++17，`g++ -std=c++17 -Wall -Wextra -g`
>
> 今日核心产出：一个 deterministic lifetime probe，以及针对当前 Reactor V1 的 lifetime hardening

---

# Part 1：前情提要与必要术语

## 1. Day5 已经建立了什么

Day5 最终拥有了一条能工作的 Reactor Echo Server：

```text
client connect
-> Acceptor 产出 connected UniqueFd
-> server owner 创建 heap Connection
-> unordered_map<int, unique_ptr<Connection>> 保持 ownership
-> EventLoop 返回 ready event
-> Channel dispatch Connection callback
-> Connection recv 或 send
-> application callback 处理 newline protocol
```

关闭路径也已经从错误版本修成：

```text
Connection 发出 close request
-> CloseCallback 只把 fd 放入 pending_close
-> 当前 poll_once 返回
-> server owner 执行 connections.erase(fd)
-> unique_ptr 析构 Connection
-> Connection 解除 Channel registration
-> UniqueFd 关闭 connected socket
```

这条路径已经通过：

```text
Debug build 零 warning
CTest 14/14
同一 server 顺序连接 10/10
并发连接 8/8
slow client 4,194,305 bytes
half-close client
ASan 与 UBSan
```

所以今天不再证明“echo 能不能工作”。今天要回答的是：

> 为什么 `pending_close` 必须等到 dispatch 边界之后处理？这个边界到底是一次 callback、一个 ready record，还是整个 `epoll_wait` batch？

---

## 2. 从当前代码中的一个问题出发

当前 `Channel::handle_event()` 会按 ready mask 依次检查 read、write 和 error：

```text
read-related bit
-> read callback

EPOLLOUT
-> write callback

EPOLLERR
-> error callback
```

一个 ready record 可以同时携带多个 bits。

现在设想 read callback 中发生：

```text
recv 得到 fatal error
-> Connection 发出 close request
```

这里立刻出现三个不同问题：

1. 如果 close callback 立即 `erase` 当前 Connection，read callback 返回后，`Channel::handle_event()` 还存在吗？
2. 如果没有立即销毁，只记录 close request，同一个 ready record 后面的 write/error callback 是否还应继续做 transport work？
3. 如果一次 `epoll_wait` 返回很多 records，其中后面的 record 仍保存旧 fd，而旧 fd 已经关闭并被复用，会查到旧对象还是新对象？

这三个问题都叫“lifetime 问题”，但不是同一个问题。今天要把它们分开。

---

## 3. 必要术语

### 3.1 lifetime

`lifetime`：生存期。

今天主要讨论 C++ object 从构造完成到析构开始之间，可以被合法访问的时间范围。

```text
内存地址还保留着
不等于
那个地址上的 C++ object 仍处于 lifetime 内
```

对象析构后继续通过旧 pointer 或 reference 访问，可能形成 use-after-free。

### 3.2 callback lifetime

`callback lifetime`：回调执行期间涉及的对象生存期关系。

今天一个 callback 至少牵涉：

```text
保存 callback 的 Channel
callback 捕获的 Connection this
拥有 Connection 的 unique_ptr
拥有 unique_ptr 的 server container
正在执行 handle_event 的 call stack
```

不能只问“callback callable 还在不在”，还要问它捕获和访问的对象是否仍然存活。

### 3.3 self-removal

`self-removal`：对象正在处理自己的 event 时，请求把自己的 registration 从 EventLoop 中移除。

remove registration 与 destroy object 不是同一个动作：

```text
remove
-> 以后不再从 epoll 获得该 registration 的新通知

destroy
-> C++ object lifetime 结束
```

### 3.4 self-destruction

`self-destruction`：对象正在执行自己的 member function 或 callback 时，触发 owner 销毁自己。

例如：

```text
Connection::handle_recv 正在执行
-> close callback
-> connections.erase(fd)
-> Connection destructor
-> 返回到原来的 handle_recv
```

这不是“聪明地提前释放资源”，而是非常危险的控制流：member function 的 `this` 已经失效，但 call stack 还没有自然退出。

### 3.5 use-after-free

`use-after-free`，缩写 `UAF`：对象拥有的 storage 已经被释放，程序仍继续读取、写入或调用它。

ASan 经常可以检测 UAF，但“ASan 没报错”不表示不存在 UAF；未定义行为是否显现取决于执行路径和内存是否恰好被复用。

### 3.6 deferred cleanup

`deferred`：延后的。

`cleanup`：清理。

`deferred cleanup` 的意思是：

```text
callback 现在只记录 cleanup request
-> 等当前规定的 dispatch boundary 结束
-> owner 再真正 remove 与 destroy
```

它不是永远不释放，而是把释放移动到一个不会再使用旧对象的位置。

### 3.7 dispatch

`dispatch`：分发。

EventLoop 根据 ready record 找到 Channel，再由 Channel 根据 event bits 调用对应 callbacks。今天要特别区分：

```text
一次 callback invocation
一次 Channel::handle_event
一次 ready record
一次 epoll_wait 返回的整个 batch
```

它们不是同一个边界。

### 3.8 batch

`batch`：一批。

一次 `epoll_wait` 可以向 user-space event array 写入多条 `epoll_event` records。`poll_once` 从 wait 返回到函数返回之间处理的全部 records，构成今天所说的一个 dispatch batch。

### 3.9 stale event record

`stale`：陈旧的、已经不再对应当前状态的。

`stale event record` 是 user-space 当前 batch 中还保存着、但它原先对应的 registration/object 已经被移除或销毁的 record。

这里不是说 kernel 把时间倒流了。关键是：

```text
epoll_wait 已经把 record 写进 user-space array
-> 处理较早 record 时改变了 lifetime
-> array 后面的 record 不会自动从内存中消失
```

Linux `epoll(7)` 也专门提醒：缓存一批 returned events 时，需要能够标记 earlier processing 已经关闭的对象。

### 3.10 fd reuse

`reuse`：复用。

`close(fd)` 后，这个整数编号可以很快被 kernel 分配给另一个新资源：

```text
旧 connection 使用 fd 7
-> close 7
-> 新 accept 又得到 fd 7
```

两个对象的 fd integer 相同，不代表它们是同一个 socket lifetime。

### 3.11 identity

`identity`：身份。

今天需要区分：

```text
fd integer
kernel open file description
epoll registration
C++ Channel object
C++ Connection object
```

`fd == 7` 只是一项数值信息，单独不足以永久代表一个 Connection identity。

### 3.12 stable token 与 generation

`token`：标记一个 identity 的不透明值。

`generation`：代数或版本号；每次创建新 lifetime 时递增。

例如：

```text
old fd 7 -> token 1001
new fd 7 -> token 1002
```

即使 fd integer 被复用，旧 record 中的 token 仍不能匹配新 object。

今天只理解这种方案解决什么问题。当前 single-thread V1 不默认引入 generation counter。

### 3.13 remove-before-destroy

`remove-before-destroy` 是今天的资源顺序 contract：

```text
先从 EventLoop registry 与 epoll interest 中移除 Channel
-> 再结束 Channel 和 Connection object lifetime
-> 最后由 UniqueFd close fd
```

它保护的是 user-space registry 中的 non-owning pointer，不只是 kernel epoll。

---

## 4. 今天同时存在四种 lifetime

| 对象 | 当前 owner | 结束动作 | 结束后最危险的旧引用 |
|---|---|---|---|
| connected fd integer | `UniqueFd` | `close` | event record 中保存的旧整数 |
| epoll registration | kernel epoll instance | `EPOLL_CTL_DEL` 或最终 fd teardown | returned event array 中已复制的 record |
| `Channel` | `Connection` member | `Connection` 析构 | `EventLoop::map_` 中的 `Channel*` |
| `Connection` | server container 中的 `unique_ptr` | `connections.erase(fd)` | callbacks 捕获的 `this` |

最容易出错的说法是：

> “fd 已经关了，所以什么都没了。”

实际情况是，kernel fd table entry、epoll registration、user-space event record 和 C++ objects 有不同的 owner 与结束时间。

---

## 5. 两层风险：same record 与 same batch

### 5.1 same record

一条 returned record 可能是：

```text
EPOLLIN | EPOLLOUT
```

当前 `Channel::handle_event()` 可能先调用 read callback，再调用 write callback。

如果 read callback 已请求关闭，write callback 是否仍会进入？这是 same-record control-flow 问题。

### 5.2 same batch

一次 `epoll_wait` 可能返回多个不同 registrations 的 records：

```text
record 0 -> fd 9
record 1 -> fd 7
```

假设处理 fd 9 的 callback 时，server policy 同步结束了另一个旧 fd 7 的 object lifetime。后面的 fd 7 record 已经在 returned array 中，不会自动消失。怎样避免它访问旧 pointer，或在 fd 7 随即被复用后把旧 record 分发给新 object？这是 same-batch identity 问题。

---

## 6. 今日范围

今天做：

```text
确定性观察 close request 后的同 record dispatch
解释为什么 callback 中立即 erase 会形成 self-destruction
确定 current V1 的 deferred-cleanup boundary
加固 registry lookup
理解 fd reuse 与 generation token 的适用条件
ASan 与 repeated connection evidence
```

今天不做：

```text
multi-thread EventLoop
跨线程 remove
shared_ptr 化整个 Reactor
复杂 weak_ptr tie framework
lock-free lifetime reclamation
hazard pointer 或 epoch reclamation
io_uring
```

这些都不是当前 Mini Redis 前置。

---

# Part 2：教程与分轮实践

## 7. 教程开始：close request 之后，旧对象还能走多远？

今天不先修改生产代码。

第一步先建立一个极小的、不会被 network timing 干扰的实验：

```text
给 Channel 人工设置 combined ready bits
-> read callback 改变 close-request state
-> 观察同一次 handle_event 是否继续执行 write callback
```

这个实验不调用 `delete this`，因为 R1 的目标是观察 dispatch policy，不是用未定义行为赌 ASan 是否报错。

---

## 8. Round1：`reactor_lifetime_probe.cpp` 是干什么的

### 8.1 文件位置

在当前 canonical Week10 project 中新增：

```text
tests/reactor_lifetime_probe.cpp
```

不要复制一套 Channel 或 Connection。

### 8.2 程序用途

这个 probe 只回答两个问题：

1. 正常 combined event 中，没有 close request 时，read 与 write work 是否都能执行？
2. read work 发出 close request 后，同一 `handle_event` 是否还会进入 write callback？

它不测试真实 TCP、不测试 recv/send，也不替代 Day5 clients。

### 8.3 为什么先用 Channel，不先启动 server

真实 server 同时受到这些因素影响：

```text
kernel 是否在同一 record 返回 IN 与 OUT
TCP packet 到达时间
socket buffer 当前容量
client 何时 half-close
```

R1 要研究的是 callback order。人工设置 ready mask 能直接控制输入，不需要 sleep，也不会因为调度顺序偶尔通过。

---

## 9. R1 已有 API 的最小使用提醒

以下只提醒单个 API 怎样调用，不给出两组 scenario 的完整组合答案：

```cpp
Channel channel(42);

channel.set_read_callback([&] {
    // 记录 read callback 被调用。
});

channel.set_ready_events(EPOLLIN);
channel.handle_event();
```

今天 `42` 只是 probe 中的标签，不会被拿去执行真实 I/O。

要组合多个 ready bits，继续使用已经学过的 bitwise OR：

```cpp
const std::uint32_t ready = EPOLLIN | EPOLLOUT;
```

`std::uint32_t` 与 `EPOLLIN` 已在 Day2 用过，不再重讲。

---

## 10. R1 observable contract

### 10.1 Scenario A：正常 combined dispatch

初始状态：

```text
close_requested = false
read_work_count = 0
write_work_count = 0
```

输入：

```text
ready mask = EPOLLIN | EPOLLOUT
```

read callback 只记录 read work，不请求关闭；write callback 只记录 write work。

Scenario A 必须自动验证：

```text
read_work_count == 1
write_work_count == 1
```

这个 baseline 防止你为了阻止 close 后的 write，误伤正常 combined event。

### 10.2 Scenario B：read callback 发出 close request

重新创建独立的 Channel 与 counters，不复用 Scenario A state。

输入仍然是：

```text
ready mask = EPOLLIN | EPOLLOUT
```

但 read callback 这次执行：

```text
记录 read work
-> 把 close_requested 设为 true
-> 记录 CLOSE_REQUEST
```

write callback 若被进入，应根据当时的 `close_requested` 记录：

```text
WRITE_BEFORE_CLOSE
或
WRITE_AFTER_CLOSE
```

运行之前，先在 `day6_note.md` 写下你的预测：

> 按当前 `Channel::handle_event()`，Scenario B 最终 trace 会是什么？为什么？

不要现在修改 `Channel`。先让当前代码回答。

### 10.3 R1 自动判定

程序必须自动检查 Scenario A 的 exact counters。

Scenario B 本轮不是要求“修成某个指定结果”，而是要求：

```text
read callback 确实执行一次
close request 确实在 read callback 内发生
程序明确打印是否出现 WRITE_AFTER_CLOSE
不存在 crash
```

如果 setup 或 baseline 不成立，返回 non-zero。

如果 probe 成功得到一条可解释的 Scenario B trace，返回 0。

这里的 exit 0 表示“实验有效”，不表示“生产代码已经完成加固”。

### 10.4 建议输出

输出措辞可自行设计，但至少保留：

```text
BASELINE ...
CLOSE_TRACE ...
POST_CLOSE_WRITE yes 或 no
LIFETIME_PROBE_OBSERVED
```

不要只打印 `PASS`，否则之后看不出你究竟观察到了什么。

---

## 11. R1 CMake target

这部分是 build glue，不是今天要你独立设计的算法，可以直接使用：

```cmake
add_executable(reactor_lifetime_probe
    tests/reactor_lifetime_probe.cpp
)

target_compile_options(reactor_lifetime_probe PRIVATE
    -Wall
    -Wextra
    -g
)

target_link_libraries(reactor_lifetime_probe PRIVATE
    channel
)

add_test(
    NAME reactor_lifetime_probe
    COMMAND reactor_lifetime_probe
)

set_tests_properties(reactor_lifetime_probe PROPERTIES
    TIMEOUT 10
)
```

### 11.1 编译运行

在 `~/code/system-learning/cpp/week10`：

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build -j2
./build/reactor_lifetime_probe
```

然后运行当前全部 regression tests：

```bash
cd build
ctest --output-on-failure
cd ..
```

### 11.2 R1 不做什么

R1 不要求：

```text
销毁真实 Connection
故意 dereference dangling pointer
修改 EventLoop registry
制造真实 fd reuse
写新的 TCP client
实现 generation token
```

你只需要把 same-record 状态变化变成确定性 evidence。

---

## 12. Round1 阅读闸门

做到这里先停止阅读。

R1 提交：

```text
tests/reactor_lifetime_probe.cpp
CMake target
一次 exact trace
你的运行前预测与运行后解释
```

先让我检阅 R1。正式通过后，我会以你的 probe、命名、trace 和想法为基准，保留你已经写进本文的内容，再定向润色下面 R2/R3。

---

## 13. Round2：为什么 immediate erase 会变成 self-destruction

R1 已正式通过。你的 `reactor_lifetime_probe.cpp` 用两个独立 `Channel` 场景做了准确对照：

```text
ScenarioA: EPOLLIN | EPOLLOUT
-> read_work_count = 1
-> write_work_count = 1

ScenarioB: EPOLLIN | EPOLLOUT
-> read callback sets close_requested = true
-> write callback still runs once
-> WRITE AFTER CLOSE
```

`day6_note.md` 在运行前就预测到这个结果；fresh Debug build 零 warning，CTest `15/15` PASS。第一次检阅时 Scenario B 只打印 trace，缺少自动证明 read/request/write 三步都发生；你随后补了两个 work counters 与 `assert(close_requested)`，现在这条 evidence 闭合。`assert` 在当前 Debug build 有效，但未来若用定义了 `NDEBUG` 的 Release build，它会被移除；要把 probe 当跨 build-type 的 regression test 时，再改成显式失败返回。

这条 trace 的精确含义是：**Channel 继续调用 write callback**。它没有执行真实 `Connection::handle_send`，所以不能推断 close 后真的调用了 `send`。R2/R3 要分别处理 callback invocation 和 transport work；不把 Channel 的正常 combined-bits dispatch 改成“read 后一律跳过 write”。

先看危险版本的完整调用栈。假设 CloseCallback 直接执行 `connections.erase(fd)`：

```text
EventLoop::poll_once
    |
    v
Channel::handle_event
    |
    v
read_callback
    |
    v
Connection::handle_recv
    |
    v
Connection::close_helper
    |
    v
CloseCallback
    |
    v
connections.erase(fd)
    |
    +--> unique_ptr destroys Connection
    +--> Connection destroys its Channel member
    +--> UniqueFd closes fd
    |
    v
CloseCallback returns
    |
    v
execution attempts to return through destroyed Connection and Channel
```

危险不只在最后一句。

当 `erase` 完成时：

```text
当前 Connection 的 lifetime 已结束
当前 Channel member 的 lifetime 已结束
read_callback 捕获的 this 已失效
Channel::handle_event 的 this 已失效
```

需要精确一点：C++ 中受严格约束的 `delete this` 并非在所有程序里都天然非法；如果对象确实由 `new` 创建、删除后不再访问任何 member、caller 也不再使用旧 pointer，某些特殊设计可以这样做。但你当前调用链不满足这些条件：

```text
Connection close_helper 返回后
-> 某些路径还会调用另一个 member helper

read callback 返回后
-> Channel::handle_event 还会读取 ready_mask_
-> 还可能访问 write_callback_ 或 error_callback_
```

因此当前 callback 内 `erase` 不是抽象意义上的“看起来危险”，而是后续确实仍可能访问已经结束 lifetime 的 Connection/Channel。

---

## 14. close request 不等于立即销毁

当前 Day5 的 CloseCallback 语义是正确方向：

```text
Connection 检测到结束条件
-> close_flag_ 从 false 变为 true
-> CloseCallback 把 fd 记入 pending_close
-> Connection object 仍然存活
```

这里 `close_flag_` 表示：

> 这条 Connection 已经提交过 owner cleanup request，不应该再开始新的普通 transport work。

它不表示 destructor 已经运行，也不表示 fd 已经 close。

所以必须分清三个时刻：

| 时刻 | `close_flag_` | object 是否存活 | fd 是否仍 owned |
|---|---:|---:|---:|
| 正常处理 | false | 是 | 是 |
| 已请求关闭、等待 cleanup | true | 是 | 是 |
| owner erase 完成 | object 不存在 | 否 | 否 |

---

## 15. 当前 V1 的 deferred cleanup boundary

你的 server 目前在 `poll_once` 返回后才 erase：

```cpp
loop.poll_once(-1);

for (int fd : pending_close) {
    connections.erase(fd);
}
pending_close.clear();
```

因为 `poll_once` 自己会处理本次 `epoll_wait` 返回的全部 records，所以当前 boundary 是：

> 整个 `epoll_wait` batch 处理结束，而不只是当前 callback 返回。

完整链为：

```text
epoll_wait fills user space event array
    |
    v
EventLoop begins batch dispatch
    |
    v
Connection callback requests close
    |
    +--> set close_flag_
    +--> append fd to pending_close
    +--> do not erase owner
    |
    v
current callback returns
    |
    v
Channel handle_event returns
    |
    v
EventLoop finishes remaining records in this batch
    |
    v
poll_once returns
    |
    v
server owner erases pending Connections
    |
    +--> unregister Channel
    +--> destroy Connection
    +--> close fd
```

这就是当前 single-thread V1 最重要的 lifetime invariant。

---

## 16. deferred destruction 之后，为什么还需要 close-state guard

延后 erase 只保证 object 还活着。

它没有自动保证：

```text
close request 之后
同一 record 的后续 callbacks
不会继续做 recv send getsockopt
```

因此需要第二层规则：

> callback 可以继续安全地返回，但一旦 `close_flag_` 已经成立，后续 handler 不再开始新的普通 transport work。

对当前 `Connection`，最小 guard 位置是 read、write、error handlers 的入口。

这里不要求 Channel 理解 Connection 的 `close_flag_`。Channel 仍然只负责 event-mask dispatch；Connection 自己负责自己的 lifecycle state。

把你的 R1 trace 接到真实代码：

```text
R1: read callback -> close_requested = true -> write callback still invoked

production: Connection read handler -> close_helper sets close_flag_
            -> Channel may still invoke write callback
            -> Connection write handler sees close_flag_ and returns without send
```

因此目标不是让 R1 的 `WRITE AFTER CLOSE` 消失，而是让这个被调用的 handler 不再进行新的 transport work。`Channel::handle_event` 本身不应该知道 `close_flag_`，否则 transport-specific lifecycle 会渗进通用 Channel。

注意一个重要边界：

```text
peer_write_closed_flag_ == true
不一定等于
close_flag_ == true
```

如果 peer 已经 EOF，但 output Buffer 还有 response：

```text
peer_write_closed_flag_ = true
close_flag_ = false
-> 仍允许 handle_send drain output
-> output empty 后才 request close
```

所以不能写成“看到 EOF 后全部 handlers 一律 return”。真正停止普通 work 的条件是 close request 已经发生。

---

## 17. same batch：returned array 为什么不会自动更新

`epoll_wait` 把 ready information 写入 caller 提供的 array：

```cpp
epoll_event returned_events[1024];
```

函数返回后，这些 records 已经是 user-space memory 中的数据。

假设 batch 包含两个不同 registrations：

```text
record 0: fd 9, EPOLLIN
record 1: fd 7, EPOLLOUT
```

如果处理 fd 9 的 callback 时，application/server policy 顺便立即 remove、destroy、close 另一个 fd 7，后面的 fd 7 record 不会从 array 中神秘消失。若这期间又创建新 resource 并复用整数 7，单靠 `data.fd` lookup 还可能把旧 record 交给新 object。

这就是 Linux `epoll(7)` 所说的 event cache 问题。常见解决方向有：

```text
保留 object 到 batch 结束
或
立即标记 removed，后续 record 查到标记后跳过
或
用 stable token 区分旧新 identity
```

当前 V1 选择第一种作为主策略。

---

## 18. fd reuse 为什么会放大问题

Linux 可以在 close 后快速复用 fd integer：

```text
old Connection A owns fd 7
-> A is destroyed and closes 7
-> later accept returns fd 7
-> new Connection B owns fd 7
```

如果旧 returned record 只保存 `data.fd = 7`，而 registry 已经变成：

```text
map_[7] = Channel of B
```

那么旧 A 的 record 可能被错误地 dispatch 给 B。

这叫 identity confusion：

```text
same integer
!=
same lifetime
```

Day5 的“第一个 client PASS、第二个 client reset”就是 fd reuse 让 stale owner bug 迅速暴露的例子。那次 stale 的是 owner container；今天讨论的是 event record 与 registry。

---

## 19. `map_[fd]` 为什么不是安全 lookup

当前 `EventLoop::poll_once` 使用：

```cpp
map_[fd]->set_ready_events(events);
map_[fd]->handle_event();
```

`std::map::operator[]` 的语义是：

```text
key 存在
-> 返回对应 value

key 不存在
-> 插入一个 value-initialized value
-> 返回新 value
```

对 `Channel*`，value initialization 得到 null pointer。

因此若 record 中的 fd 已经不在 registry：

```text
map_[fd]
-> 插入 fd -> nullptr
-> dereference nullptr
```

而且这个查询还悄悄修改了 registry。

只读查找应使用 `find`：

```cpp
auto it = map_.find(fd);
if (it == map_.end()) {
    // 该 record 已经没有 live Channel；当前 policy 决定跳过或报错。
}
```

### 19.1 `find` 最小例子

```cpp
#include <map>

std::map<int, int> values;
values.emplace(7, 100);

auto found = values.find(7);
if (found != values.end()) {
    const int value = found->second;
}

auto missing = values.find(9);
if (missing == values.end()) {
    // 没有插入 key 9。
}
```

`find` 不会因为 key missing 而创建新 element。

---

## 20. remove failure 时，user-space registry 也不能留下 dangling pointer

当前 `EventLoop::remove_channel` 的顺序是：

```text
epoll_ctl DEL
-> 如果失败，立刻 throw
-> 成功后才 map_.erase(fd)
```

而 `Connection::~Connection() noexcept` 会捕获并吞掉 remove exception。

于是 failure path 可能变成：

```text
epoll_ctl DEL fails
-> remove_channel throws before map erase
-> Connection destructor catches exception
-> Channel object is destroyed
-> EventLoop map still stores old Channel pointer
```

这会留下真正的 dangling pointer。non-throwing destructor 只保证 exception 没有逃逸，不自动保证 cleanup state 一致。

Day6 的要求是：

> 一旦 owner 决定销毁 Channel，EventLoop 的 user-space registry 绝不能继续把它当作 live object。

因此 remove path 即使需要保留并报告 `epoll_ctl` error，也必须先让 registry 回到“不再引用该 Channel”的状态。清理时还应核对 found pointer 确实等于 `&channel`，避免错误删除同 fd 下的其他 identity。

这不是要求忽略 syscall failure。正确思路是：

```text
执行 DEL 并保存 success 或 errno
-> 清除匹配的 user-space registry entry
-> 若 DEL 失败，再按 caller context 报告保存的 error
```

在 destructor context 中，外层仍保持 non-throwing；在普通显式 remove 中，caller 仍可看到 `std::system_error`。

---

## 21. stable token 和 generation 能解决什么

`epoll_event.data` 是一个 union。application 可以保存 `fd`、pointer 或 `u64`：

```cpp
epoll_event event{};
event.data.u64 = token;
```

一种 future design 是：

```text
每次 registration 创建唯一 token
-> epoll_ctl 保存 token
-> epoll_wait 返回同一 token
-> registry 按 token 查 Channel
```

例如：

```text
Connection A: fd 7, token 1001
A destroyed
Connection B: fd 7, token 1002

old record carries token 1001
-> registry no longer contains 1001
-> skip
```

这比只比较 fd integer 更强。

但 token 仍不自动解决一切：

```text
找到 Channel 后
-> dispatch 期间仍必须保证 object lifetime
```

token 解决 identity；deferred cleanup 或 lifetime guard 解决“找到后对象能活多久”。二者不是替代关系。

---

## 22. 为什么当前 V1 不需要立刻 shared_ptr 化

把所有 Connection 改成 `shared_ptr` 看上去可以延长 lifetime，但它会引入新的问题：

```text
谁持有 strong reference
callback 是否形成 cycle
何时真正析构
owner erase 后对象是否因为别处持有而继续存活
```

更重要的是，`shared_ptr` 只能帮助 object 保活，不能自动判断旧 event 属于哪个 registration generation。

当前 single-thread Reactor 已经拥有清楚的唯一 owner：

```text
unordered_map<int, unique_ptr<Connection>>
```

所以当前更小、更可解释的方案是保持 unique ownership，严格规定 deferred cleanup boundary。

未来若进入：

```text
跨线程 callback
async task 捕获 Connection
callback 可能离开 EventLoop thread 后继续执行
```

再评估 `shared_ptr/weak_ptr` 或其他 lifetime guard。

---

## 23. 当前 single-thread Reactor V1 的最终 policy

Day6 要收敛到一套 policy，不实现所有备选方案：

```text
1. EventLoop 不允许 reentrant poll_once
2. Connection callback 只能 request close，不能立即 erase 自己
3. close request 具有 idempotent state
4. close-requested Connection 不再开始新的普通 transport work
5. owner 在整个 poll_once batch 返回后统一 cleanup
6. cleanup 顺序是 unregister -> destroy -> close
7. EventLoop lookup 使用 find，不让 missing key 通过 operator[] 变成 nullptr
8. remove failure 也不能让 registry 留下指向即将销毁 Channel 的 pointer
9. current V1 不在 batch 内 close old fd，因此不在同一 batch 内复用该 integer
```

这套 policy 成立的前提是 single-thread、无 nested event-loop dispatch。以后放宽前提时，generation token 或 stronger lifetime guard 才升级为必要设计。

---

## 24. Round3：根据 Day5 最终代码做什么

以你已经通过的 Scenario A/B、Day5 的 `Connection` 和 `pending_close` 为基线，Round3 不重新设计 dispatch。只升级真实生产路径并给升级后的行为留下对应证据：

### 24.1 在 Connection handlers 入口兑现 close-state policy

检查：

```text
handle_recv
handle_send
handle_error
```

当 close request 已经发生时，这些 handlers 不再开始新的 recv/send/getsockopt work。

不要把 `peer_write_closed_flag_` 当作同一个 guard；EOF 后仍可能需要 drain output。

你的 R1 probe **仍应输出 `WRITE AFTER CLOSE`**：它只模拟 Channel 的 callback 调用，不读取 Connection 的 `close_flag_`。不要为迎合教程改写 probe 或让 Channel 条件性跳过正常 write callback。

### 24.2 EventLoop dispatch 改为非插入式查找

把 `map_[fd]` 的 dispatch lookup 改成：

```text
find fd
-> missing: 按 stale/removed record 处理，不 dereference
-> found: 保存当前 Channel pointer，完成本条 record dispatch
```

不要为了这一步切换到 `data.ptr` 或重写 registry container。

### 24.3 让 remove failure 也清除匹配的 registry entry

当前 `remove_channel` 在 `epoll_ctl DEL` 失败时会先 throw，来不及 `map_.erase`。Round3 要调整 failure ordering：

```text
保存 DEL result 与 errno
-> 只移除 registry 中仍指向当前 Channel 的 entry
-> 再决定是否抛出 system_error
```

这样即使 Connection destructor 吞掉 exception，EventLoop 里也不会留下已经析构的 `Channel*`。

#### 24.3.1 怎么修复这个 bug

> 把 map_.erase 提前

你抓住了核心，但要把“谁会访问谁”分开：

```text
kernel epoll 不认识你的 Connection / Channel C++ 对象。
它只知道：某个 socket/file descriptor 的内核注册。
```

真正可能访问已销毁对象的，是你自己的 `EventLoop::map_`：

```text
fd
-> map_ 找到 Channel*
-> 调用 channel->handle_event(...)
```

原来的坏路径是：

```text
map_[7] = old_channel_ptr

Connection 析构
-> remove_channel(old_channel)
-> epoll_ctl(DEL, 7) 失败
-> remove_channel 直接 throw
-> 析构函数吞掉异常
-> old_channel_ptr 指向的对象被销毁
-> map_[7] 仍是 old_channel_ptr

之后 epoll_wait 返回一个 fd=7 的 event
-> map_.find(7) 找到 old_channel_ptr
-> 调用它
-> use-after-free / dangling pointer
```

所以问题不是“epoll 后面直接访问已经销毁的 Connection”，而是：

```text
epoll_wait 给出 fd
-> EventLoop 根据 fd 从 map_ 取出悬空 Channel*
-> user space 自己解引用了悬空指针
```

你说“把 `map_.erase` 提前就好”，**对 dangling pointer 这个核心问题来说，基本是对的**。更准确的顺序是：

```text
尝试 epoll_ctl DEL
-> 记住是否失败、记住 errno
-> 无论 DEL 成败，都移除 map_ 中与当前 Channel 匹配的 entry
-> 若 DEL 失败，再抛保存好的 system_error
```

这样析构函数即便吞掉异常，后续也会变成：

```text
epoll_wait 返回 fd=7
-> map_.find(7) 找不到
-> 忽略本轮 stale/unmanaged event
```

不会再拿到已销毁的 `Channel*`。

至于 fd 被新连接复用，例如旧连接也是 `7`、新连接后来也拿到 `7`：

```text
old connection: fd=7, Channel=A
A 被销毁，map_[7] 被清除

new connection: fd=7, Channel=B
add_channel(B)
-> map_[7] = B
```

在你当前的单线程 Reactor 模型中，这本身不要求立刻引入 token。因为关闭旧 socket 后，新的 `fd=7` 对应的是新的内核 file object；kernel epoll 不是仅凭“数字 7”把旧连接和新连接混为一谈。

但 `erase` 时确实要做 identity 检查：

```text
map_[fd] 当前保存的指针必须仍然等于 &channel
-> 才允许 erase
```

它防的是这种逻辑错误：

```text
旧 Channel A 正在 remove(fd=7)
-> 某处已经把 fd=7 注册给了新 Channel B
-> A 不加判断地 map_.erase(7)
-> 把 B 的正确注册也删掉
```

更强的 generation token 通常用于更复杂的场景：

```text
多个线程同时修改/dispatch EventLoop
或 event 已经排队、fd 被复用后仍可能处理旧 event
```

那时只靠 `fd` 不够，要识别 `(fd, generation)` 是否仍是同一个注册实例。但对你现在“所有 `epoll_ctl`、map_ 修改和 callback dispatch 都在同一个 loop thread”的设计，先保证：

```text
remove 无论 syscall 成败都不遗留匹配的 Channel*
```

就是当前最重要、也足够合理的修复。

#### 24.3.2 修复完后可能遇到反例？

> 我们的架构: close request + poll_once 后再去析构 connection。其实已经把这个反例给避免了；
>
> 因为你的 fd=7 其实还没被 close，在同一次 poll_once 都不会；而是要等到一次 poll_once 结束后再析构。自然也不会有其他 connection 来占领了。

你这个反例成立；我上一条只讨论了“`epoll_wait` 之后才产生的新 event”，漏掉了**本轮 `epoll_wait` 已经返回到 user space 的旧 event record**。注释 1

可能发生：

```text
epoll_wait 本轮已经返回：
[fd=5 的 event, fd=7 的 event]

fd=7 当时属于 Channel A。

开始 dispatch fd=5
-> application logic 决定关闭 A
-> DEL A、map_.erase(7)、close(7)

随后 accept 新连接
-> OS 恰好复用数字 fd=7
-> add_channel(B)
-> map_[7] = Channel B

继续处理本轮 events 数组中早已拿到的旧 fd=7 record
-> map_.find(7)
-> 找到的是 B
-> 却拿 A 的旧 readiness 去调用 B
```

这不是 dangling pointer 了，而是更隐蔽的 **stale event 被错投递给 fd 复用后的新 Channel**。

`epoll_ctl(DEL)` 即使成功，也无法修改已经由 `epoll_wait` 拷贝到本轮 `events` 数组里的旧 record。因此，单靠：

```cpp
map_.erase(fd);
```

只能消灭悬空指针，**不能单独证明旧 event 不会误命中新连接**。

当前有两种合理保护策略。

```text
策略 A：本轮 batch barrier
```

单线程 Reactor 里，收到关闭请求时先标记 `A` 为 closing，但不立刻析构、不立刻 `close(fd)`；等这一整轮 `epoll_wait` 返回的 records 都 dispatch 完，再统一销毁 A。

这样旧的 `fd=7` 在本轮结束前一直未被内核回收，新连接拿不到同一个数字 `7`。这是你现在 `pending_close` 这种延迟清理设计的重要意义之一。

```text
策略 B：registration token / generation
```

给每次 `add_channel` 分配单调递增的 registration id：

```text
A: fd=7, token=101
B: fd=7, token=102
```

注册 epoll 时，把 `token` 放进 `epoll_event.data.u64`。`epoll_wait` 返回后，按 token 查找 Channel：

```text
旧 event: token=101
-> A 已删，找不到
-> 忽略

新 B: token=102
-> 只会接收它自己的 event
```

这比只存 `fd` 更强，因为它识别的是“第几次注册”，不是“当前哪个对象碰巧拿到了同一个 fd 数字”。

所以结论是：

```text
map erase：解决 dangling pointer，必须做。
延迟 close 到 batch 结束：当前单线程 Reactor 可避免 fd 本轮复用。
generation token：更通用、更稳健地拒绝 stale event。
```

如果你的当前架构严格保证“`poll_once` dispatch 期间不析构 Connection、不 close fd，只把它放进 `pending_close`，等本轮结束后再处理”，那它已经用策略 A 避开了你描述的情况；token 可以作为后续强化，而不是此刻必须立刻上。

### 24.4 保留 batch-end owner cleanup

当前 `pending_close` 方向正确：

```text
callback request
-> poll_once returns
-> owner erase
```

不要退回 callback 内直接 `connections.erase(fd)`，也不要绕过 owner 手动 `close(fd)`。

如果给 server 增加 callback exception boundary，必须保证：

```text
poll_once dispatch throws
-> pending cleanup 仍被处理
-> 然后再按顶层 policy 选择退出或继续
```

今天不要求设计复杂 exception hierarchy。

### 24.5 用 evidence 收口，不再重写 Day5 tests

已保存的 R1 probe 覆盖 **same-record callback invocation**，不覆盖生产 `Connection::handle_send` 是否在 close request 后再次执行。Day5 已经通过的 Buffer、Channel、Connection 和 clients 直接复用；针对 close-state guard 的真实 Connection 路径，只需一条 focused component scenario。测试脚手架可以由 Codex 补，不要求你手写第二套 socketpair boilerplate。

---

## 25. Round3 验证矩阵

### 25.1 必做：deterministic lifetime probe

完成 hardening 后，重新运行已保存的 R1 probe。预期输出仍是：

```text
ScenarioA: read_work_count=1, write_work_count=1
ScenarioB: WRITE AFTER CLOSE
```

这证明通用 Channel 的 combined-bits dispatch 没被误伤。它**不能**证明 Connection 的 post-close guard。后者要由上一节的 focused Connection scenario 检查：close request 后同 record 的 write callback 可以被调用，但不得产生新的 `send` transport work。两个 oracle 观察不同层次，不要把其中一个结果当成另一个的证据。

### 25.2 必做：当前全部 CTest

```bash
cmake --build build -j2
cd build
ctest --output-on-failure
cd ..
```

新增 lifetime test 后，test count 应比 Day5 的 14 增加，而不是仍显示 14。

### 25.3 必做：同一 server process 的重复连接

复用已有 smoke client，不重写 client：

```bash
./build/reactor_echo_server
```

另一终端对同一个 server 连续运行：

```bash
for i in $(seq 1 20); do
    python3 ../week9/echo_client.py || exit 1
done
```

这条证据观察 fd integer reuse 后，owner/registry 是否仍保持一致。

它不能单独证明“同一 batch 一定出现 stale record”，所以不能替代 deterministic probe。

### 25.4 必做：ASan 与 UBSan

复用 Day5 的 sanitizer build，不再抄一份冗长配置：

```bash
cmake --build build-sanitize -j2
cd build-sanitize
ctest --output-on-failure
cd ..
```

今天重点观察：

```text
heap-use-after-free
stack-use-after-scope
invalid member access 造成的后续 crash
null pointer dereference
```

ASan 无报告只是当前覆盖路径的证据，不是 lifetime correctness 的数学证明。

### 25.5 今天不要求 TSan

当前 event loop 是 single-thread。

今天的主要风险是：

```text
object lifetime
dispatch order
stale identity
```

不是多线程 data race，所以 TSan 不作为默认验收。

---

## 26. 一个完整具体场景

假设 socket fd 是 7，本轮 ready mask 同时包含 read 与 write bits。

### 26.1 错误的 immediate destruction

```text
EventLoop dispatches fd 7
-> Channel starts handle_event
-> read callback enters Connection
-> recv reports fatal error
-> Connection calls CloseCallback
-> CloseCallback immediately erases connections[7]
-> Connection and Channel are destroyed
-> execution returns to old read callback stack
-> Channel attempts remaining dispatch
-> use-after-free risk
```

### 26.2 当前选择的 safe boundary

```text
EventLoop dispatches fd 7
-> Channel starts handle_event
-> read callback enters Connection
-> recv reports fatal error
-> Connection sets close requested
-> CloseCallback records fd 7
-> object remains alive
-> later handler observes close requested and performs no new transport work
-> Channel returns
-> EventLoop finishes current batch
-> poll_once returns
-> owner erases connections[7]
-> unregister Channel
-> destroy Connection
-> close fd 7
-> next poll_once may accept a new connection that reuses integer 7
```

这条链就是今天需要真正掌握的内容。

---

## 27. 常见混淆

### 27.1 remove 等于 close 吗

不等于。

```text
EPOLL_CTL_DEL
-> 删除 epoll registration

close
-> 释放当前进程 fd table entry
```

当前对象还涉及 EventLoop registry 与 C++ lifetime。

### 27.2 close request 等于 fd 已关闭吗

不等于。

close request 只把 cleanup 意图交给 owner。真正 fd close 由 `UniqueFd` 在 Connection 销毁链中完成。

### 27.3 deferred cleanup 是不是内存泄漏

不是。

它有明确、有限的释放点：本次 `poll_once` batch 返回后。

### 27.4 fd 数字没变，对象就没变吗

不是。fd integer 可复用。

### 27.5 用 `shared_ptr` 就不会 stale 吗

不会自动解决。`shared_ptr` 可以延长 object lifetime，但不能单独区分 old registration 与 reused fd。

### 27.6 `EPOLL_CTL_DEL` 后，returned array 会被 kernel 改写吗

不会。已经返回到 user-space 的 records 是当前程序内存中的 batch。

### 27.7 peer EOF 后是否立刻停止 write

不一定。TCP 是 full-duplex byte stream；peer 关闭 write half 后，本端仍可能发送已经生成的 response。只有 close request 已经成立时，才停止新的普通 transport work。

---

## 28. 官方资料与阅读边界

正文已经包含今天所需内容。以下只用于查证：

- [epoll_ctl(2)](https://man7.org/linux/man-pages/man2/epoll_ctl.2.html)：重点看 `epoll_event.data` 由 kernel 保存并由 `epoll_wait` 返回，以及 `ADD/MOD/DEL`。
- [epoll_wait(2)](https://man7.org/linux/man-pages/man2/epoll_wait.2.html)：重点看 returned array、record count 和 `data` 的返回语义。
- [epoll(7)](https://man7.org/linux/man-pages/man7/epoll.7.html)：只看 Questions and answers 中 event cache、earlier event 关闭 later record 对象的说明。
- [close(2)](https://man7.org/linux/man-pages/man2/close.2.html)：只确认 fd integer 在 close 过程中可被释放并复用。

不需要通读整页，也不进入多线程 epoll。

---

# Part 3：收尾与验收

## 29. 今日完成标准

Day6 通过需要同时满足：

```text
[ ] R1 probe 确定性建立 normal combined dispatch
[ ] R1 probe 确定性记录 close request 后是否仍进入 write callback
[ ] 能解释 immediate erase 的 self-destruction 调用栈
[ ] close-requested state 不再开始新的普通 transport work
[ ] peer EOF with pending output 仍可 drain，不被错误 guard
[ ] EventLoop missing-key lookup 不使用 operator[]
[ ] remove failure 后 registry 也不保留 dangling Channel pointer
[ ] owner cleanup 保持在整个 poll_once batch 返回后
[ ] remove-before-destroy-before-close 顺序成立
[ ] CTest 包含 lifetime probe 且全部通过
[ ] repeated connections 通过
[ ] ASan/UBSan 无报告
```

不要求：

```text
抄写整套验收题
重写 Day5 clients
引入 shared_ptr
实现 generation counter
跑 TSan
写 README 或 interview 文档
```

---

## 30. 验收问题

这些问题用于判断模型是否完整。若代码、trace 和你的解释已经覆盖，不要求机械重复誊写。

1. 为什么 callback 内 `connections.erase(fd)` 可能让正在执行的 `Channel::handle_event` 失去合法 `this`？
2. 为什么 `pending_close` 必须等到整个 `poll_once` 返回后处理，而不只是 read callback 返回后？
3. deferred destruction 已经保证 object 存活，为什么 close-requested handler 仍需要停止新的 transport work？
4. `peer_write_closed_flag_` 与 `close_flag_` 有什么区别？
5. 为什么 `map_[fd]` 在 dispatch lookup 中比 `find` 更危险？
6. fd 7 被复用后，为什么 old fd 7 与 new fd 7 不是同一个 identity？
7. generation token 解决什么问题？它为什么不能替代 object lifetime guard？
8. 为什么 destructor 吞掉 `remove_channel` exception，仍不能弥补 registry 未 erase？
9. ASan clean 能证明什么，不能证明什么？

---

## 31. `day6_note.md` 建议结构

只记录今天真正形成的认知和证据：

```markdown
## R1

### 运行前预测

### 实际 trace

### close request 后发生了什么

## R2

### immediate erase 为什么危险

### 当前 batch boundary

### fd reuse 与 identity

## R3

### 我对生产代码做的修改

### 最终 evidence
```

不要求复制正文定义。

---

## 32. 今日压缩记忆

```text
callback 中只 request close
-> object 保活到整个 epoll batch 返回
-> close-requested handler 不再做新的 transport work
-> owner remove registration
-> destroy Connection
-> UniqueFd close fd

fd integer 可以复用；
returned event record、registration 和 C++ object 不共享同一个 lifetime。
```

Day6 的重点不是“多写一个 flag”，而是第一次给 Reactor 写出明确的 callback lifetime contract。
