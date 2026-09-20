## R1

按当前 `Channel::handle_event()`，Scenario B 最终 trace 会是什么？为什么？

最终会记录到 WRITE_AFTER_CLOSE；

也就是，read callback 执行，记录 CLOSE_REQUEST，write callback 执行。

## R3

```text
其实就是去增加，当 Connection 这个 object 虽然还没有被删除；但是已经调用了 close callback，发了 close request 了，是一个名义上已经需要被删除地状态。

这时候我们不允许这个 connection 去再进行任何 recv/send 了；所以在做这些操作前需要 check 一下这个 connection 是否 close。

以及 map 需要先 find，再利用 map[fd_] 去获取。
```

