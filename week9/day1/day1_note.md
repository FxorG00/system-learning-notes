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

## R3

```text
新增每个错误都传回 main，由 main 在每个出口统一 close fd
```

## 总结

```text
本节重点讲了 non-blocking，去为了解决一个 server execution flow 可能在 recv A 等待很久，而没办法去 recv B 的问题。
```

