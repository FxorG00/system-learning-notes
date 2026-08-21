## R1

## threadpool status

```text
1. 关于 submit 跟 shutdown 谁赢，这俩实现是去调用 blocking queue 的 push 跟 close，我们在外界不需要对 threadpool 的状态再做一个记录，因为内部的 blocking queue 已经为我们记录了。
关于谁先谁后，这个是去看谁在 blocking queue 里面能竞争到 mutex，与外界我们调用的没有关系；如果 close 先的话，那 submit 的 push 也会返回失败的。

2. Day2 的简单设计让 BlockingQueue 成为 task acceptance 的 single source of truth。呼应 1 中不需要为 thread pool 开一个 status。
```

## exception

V1 采用一个明确但有限的 policy：

```text
worker 捕获 task exception
-> atomic failed_task_count +1
-> worker 不退出
-> 继续执行后续 task
```

`failed_task_count()` 让测试和调用者至少知道有 tasks 失败。

限制：

```text
不保存每项 exception 的具体类型/message
调用者不知道是哪一个 task 失败
```

