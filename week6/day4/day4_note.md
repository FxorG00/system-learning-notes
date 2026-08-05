## 核心机制

```text
socket
-> setsockopt（配置 restart 行为）
-> bind（确定 local endpoint）
-> listen（变成 listening socket）
-> accept（取出一个 pending connection，返回新 fd）
-> recv / send（只操作 connected socket）
-> close```
```

今天的难点在于理解上面的步骤。

1. 一个 socket 创建出来，经过 setsockopt,bind,listen，变成 listening socket，此时这个 socket 的 queue 是用于存储 pending connection 的，也就是如果有 client 向当前 server 主动发起请求，那么会在 kernel network stack 去建立起这个 connection
2. 但是目前的 connection 叫做 pending connection，因为还没有被 application 接走
3. application 可以通过 accept 往 listening socket 的 queue 里取出一个 pending connection，并且得到这个 connected socket fd。
4. 后续可以通过这个 fd 在这个 connection 进行接收跟发送信息，也就是 socket 的 recv,send

## accept

```text
1. application 调用 accept(listening_fd)
2. kernel 检查 listening socket 的 accept queue
3. queue 中有没有 pending connections
4. 有的话，取出并且分配一个 new_fd，然后 accept 返回这个。
5. 没有的话，当前 execution flow blocking，让出 CPU，并且变成 SLEEPING
6. 如果有 client 发起连接，network packets 到达
7. kernel network stack 建立 connection
8. kernel 把 connection 放入 accept queue
9. 唤醒等待该条件的 execution flow
10. 符合条件的 execution flow 醒来后再看 predicate，然后为 true 就变成 RUNNABLE，并且等待 scheduler 选择调用
11. kernel 重新检查 queue，若有 connection，则 accept 创建 connected fd 并且返回
```

## backlog

就是 accept queue 的大小上限。

也就是同一个时刻最多能有几个 pending connection。
