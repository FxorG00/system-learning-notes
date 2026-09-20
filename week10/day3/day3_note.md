## R1

```text
EventLoop
拥有 epoll instance
维护 Channel 与 epoll registration 的关系
调用 epoll_wait 等待 ready events
把每条返回记录交给对应 Channel

Q1:
EventLoop 在 poll_once 的时候，要调用 epoll_wait 得到这轮的 events，并且去 dispatch 给 events 对应的 fd 对应的 Channel，让 Channel 去 handle_event()；

我们 epoll_wait 只能得到 fd，不能知道其对应的 callback；所以我们需要保存每个 fd 对应的 Channel。但是是不拥有的。
所以内部我们需要 std::map，去形成 fd->channel 的 mapping

这个 map 用于保存，目前 epoll 关注的 fd 对应的 channel。并且对于 channel 而言，我不拥有它，但是后面我需要调用 channel.set_ready_events()，所以我应该保存的是指向这个 channel 的指针。
即 map<int,Channel*>map_;

我觉得这样是好一些，而且避免了 Channel 本身可能没办法 copy

class member: map,epoll

add_channel(Channel& channel)
那我能获取到 channel 对应的 fd
保存 fd->channel 在 map 中
并且把 channel 的 interest_events 注册到 epoll 里 ADD

update_channel(Channel& channel)
更新 fd->channel 在 map 中
并且把 channel 的 interest_events MOD 到 epoll

remove_channel(Channel& channel)
从 epoll 删掉这个，并且 map.erase

poll_once(int timeout_ms)
epoll_wait 得到若干 returned_events
更新到 fd 对应 channel 的 ready_mask；set
然后依次调用 .fd 对应的 handler_event();


```

### poll_once 的设计思路

#### 提示

你不需要提前知道“总共有多少条 ready records”。

把 `maxevents` 理解成：

```text
我这次提供的 output array 最多能装多少条
```

假设某一刻有很多 fd ready，而你的 array 只能装 `N` 条：

```text
epoll_wait 本轮最多返回 N 条
剩余 ready events 不会因为这次没装下就凭空消失
下一次 epoll_wait 还能继续取得
```

所以你现在要独立决定的是：

```text
1. poll_once 每轮准备多大的 event buffer？
2. epoll_wait 返回 n 后，应该处理 array 的哪个范围？
3. 如果 ready 数量超过这一轮容量，EventLoop 依靠什么继续处理？
```

提示到这里：`maxevents` 限制的是**单次批量大小**，不是 EventLoop 能管理的 fd 总数。你不需要求出一个“绝对够大”的数字。

#### 我的 idea

```text
最简单的肯定是限制 maxevents=1，这样每次只会取出一条 event，如果有的话；
但是它给了一个 timeout_ms，而且 epoll_wait 是可以设置 time_out 时间的；
我的想法是，去记录初始时间，以及每次调用 epoll_wait 的时刻，算出 remained_ms: 还有这么多时间就超时，然后把 remained_ms 给 epoll_wait

使用 std::chrono::steady_clock

epoll_wait 得到若干 returned_events
更新到 fd 对应 channel 的 ready_mask；set
然后依次调用 .fd 对应的 handler_event();
```

#### 对齐后

`poll_once` 应表达“一次 wait、处理这一批返回结果”，不是“在 timeout 时间段里不断收集事件”。



```text
所以我写一个 wait 就好了。

但是计时器在 EINTR 之后再次 epoll_wait 还是有用的。

const auto elapsed = end - begin;

const int elapsed_ms = static_cast<int>(
    std::chrono::duration_cast<std::chrono::milliseconds>(elapsed).count()
);
```

## R3

```text
在 poll_once 中需要加一个判断，就是 remained_ms<0 就直接结束了。

底层 EventLoop 只保存原始 error code 并抛异常，由最外层 probe 统一输出 `error.what()`。也就是把 perror 去掉。底层不输出报错信息。
```

