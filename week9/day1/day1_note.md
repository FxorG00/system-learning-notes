## R1

```text
先创建两个 connected 的 sockets
设置好 non-blocking

然后让 socket[0]->socket[1]

同一个 main 可以依次制造四个状态：
空且 peer open -> recv
peer send -> recv 到 drain 完
peer 仍 open -> 再 recv
close peer -> 再 recv
```

