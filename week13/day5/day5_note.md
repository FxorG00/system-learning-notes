## R1

```text
app 中 poll_once(50); 表示设置超时时间为 50ms，如果 50ms 都无 events 就直接返回了。
有事件的话，读完一批 records 后提前返回。

在每次 poll_once 结束后，app 主动去调用 sweep_expired(16);
```

## R3

```text
相比于 R1，升级了：
相邻两次 sweep_expired 间隔 >=100ms
这个用 std::chrono::steady_clock
```

