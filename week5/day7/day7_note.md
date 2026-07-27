## 验收问题

### 问题 1

busy waiting 与 blocking 分别是什么？为什么长期等待 pipe、disk 或 network event 时通常不应 busy wait？

busy waiting 就是不让出 CPU，然后 execution flow 一直在运行，并且都是在不断循环并且检查条件。

blocking 就是某个 execution flow 阻塞了，没办法向前推进，需要等到某个 execution flow 执行/hardware event

因为会长期占据 CPU，这样其他的 execution flow 没办法得到执行。

### 问题 2

一个 blocked thread 被 notify/wakeup 后，为什么通常先进入 `RUNNABLE`，而不是立刻变成 `RUNNING`？

因为 RUNNABLE 是说这个 execution flow 达到了可以执行的状态。

但是是否执行它，是看 scheduler 的。scheduler 是选 RUNNABLE 的 execution flow 去执行，然后状态变成 RUNNING。

### 问题 3

请手推一次 lost wakeup：从 waiter 检查 predicate 为 false 开始，到 notifier 的通知被错过，再到 waiter 永久睡下去。

```text
waiter 检查 predicate 为 false
释放 mutex

这时候 notifier 获取 mutex 并且把 predicate = true
然后尝试 wakeup 正在 sleep 的 execution flow
但是没有sleeper
notifier 释放 mutex

然后 waiter 进入 sleeping

就是这个窗口导致 lost wakeup
```



### 问题 4

为什么 predicate 的检查和修改必须由同一 mutex 保护？`wait` 为什么必须把“释放 mutex”和“进入等待”连接成一个不可插入普通 notifier 的过程？

否则没啥意义吧。mutex 守护的是 shared state 这些的。这样能让 waiter 拿到 mutex 的时候，producer 没办法修改 predicate。

这样能让 notifier 没有插入窗口。不然就会跟 question3 一样 lost wakeup

### 问题 5

为什么 `condition_variable::wait` 使用 `unique_lock`，而不是你 Day5 常用的 `lock_guard`？

unique_lock 支持显示 lock(),unlock(),这样才能传入 wait。因为 wait 里面要用

### 问题 6

为什么 wait 被唤醒后还要重新检查 predicate？至少给出两个原因。

spurious wakeup

而且可能是 notify_all() 唤醒了某个 channel 的所有 execution flow，然后你可能一个 execution flow 先拿到 mutex 后，然后执行操作，predicate 就为 false 了。后面的 execution flow 就需要检查。

### 问题 7

`notify_one` 做了什么？它不保证什么？为什么说 notification 不是数据，也不保存业务事实？

唤醒一个等待者参与竞争。

不保证被被唤醒者立刻执行。不保证一定最先拿到 mutex。不保证predicate 对每个被唤醒者为 true。

因为数据是 share state 这些。这个只是负责叫醒。

### 问题 8

在 xv6 `sleep(chan, lk)` 中，为什么不能一直持有 condition lock 睡眠？为什么又不能先普通释放 condition lock、稍后再进入 SLEEPING？`p->lock` 在中间解决了什么问题？

不然 notifier 拿不到 condition lock，也就没办法修改 predicate 了。

普通的话会有窗口，详细见 Q3。

condition lock: 保护 data，比如 pipe lock

p->lock: 保护 channel/state 和切换 invariant

两个 lock 配合挡住了 notifier，避免窗口期从而导致 lost wakeup。