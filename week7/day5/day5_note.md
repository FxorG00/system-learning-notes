## practice

```text
今天新增 close()
1. 在第一次调用 close() 的时候将 queue 的 status 设置为 closed，这个涉及到 shared_state，肯定要拿 mutex；并且 notify_all 所有 waiter；如果不是第一次设置为 close，那不要去理他。

2. 当 queue 为 closed 的时候，应该保证没有 producer/consumer 在 sleeping，所以把每个的 predicate 加上这个判断。

3. push 的时候，如果 queue closed 了，则 push 失败；否则按照之前一样，check 是否为空，再去 push；也就是写成一个 predicate 表示 push_can_wake_up，一个是 not full，另一个是 close 了。

4. pop 的时候一样；写成一个 pop_can_wake_up；一个是 not_empty，另一个是 closed；
醒来的时候去 check，如果已经 closed 了，则判断是否 not empty，是的话还能成功 pop 出来一个，不是的话需要返回 std::nullopt
如果没有 closed，醒来的时候就是 not_empty，正常 pop 一个
```

