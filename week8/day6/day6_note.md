## R1

```text
新增 accounting test

不要用 thread_pool 去测试，因为可能淹没掉我的 logger 的成本，加入了其他因素。直接手动 std::thread ,join

benchmark:
prepare identical records
-> run one case
-> obtain submission time
-> obtain end-to-end time
-> validate output
-> print one structured result row

constants:
record count
record bytes
producer count
queue capacity
output path

注意要对 record 的范围划分给 producers

sync_logger：
对这个而言，submission time 就是都调用了 log; end-to-end time 就包括 flush,close

async_logger:

submission time
指的是提交的时间，就是不理你提交都结束后，records 有没有都 output。
我们让所有 producers 都去 log，然后执行完这段代码就记录 end time；

end-to-end time
保证 records 都提交且 output 且 flush,close
开始的时刻都是一样的。
区别在于，让 producers 都去 log 了之后，这个 log 都成功 output（就不只是进入队列里）。所以我们需要让 logger drain。

validate output:
这里我就统一 producer: i log: j
然后去验证每一条 record 在最终文件都出现了。


```

### 我担心的情况：submit 是会阻塞等待的，因为里面的 push 是阻塞等待，所以会卡在这里，直到 submit 成功了才会继续执行下去(旧版)

你描述的情况是一个真实的并发边界，但它**不会发生在你这段代码当前的执行顺序里**。

```cpp
for (...) {
    pool.submit(...);  // 主线程在这里可能阻塞
}
pool.shutdown();       // 只有循环完全结束后才能执行到这里
```

这里只有主线程会调用 `shutdown()`。所以若某次 `submit()` 因队列满而阻塞：

```text
main 卡在 submit
-> worker 取走一个旧 task
-> queue 出现空位
-> 本次 submit 成功入队并返回
-> main 继续下一轮循环
-> 所有 submit 都返回后
-> main 才能调用 shutdown()
```

因此，这 10 个 task 都会被接受；随后 `pool.shutdown()` 的 drain 语义会等待它们都执行完。

你担心的情况只会在这种结构下出现：

```text
线程 A：正在 submit，队列满，于是阻塞
线程 B：同时调用 pool.shutdown()
```

这时 ThreadPool 的契约必须明确规定：

```text
shutdown
-> 关闭 BlockingQueue
-> 唤醒所有因队列满而阻塞的 submit
-> 被唤醒的 submit 发现 queue 已关闭
-> 本次任务不入队，并明确报告失败
```

报告失败的方式取决于接口设计，例如 `submit()` 抛 `std::runtime_error`，或返回 `std::optional<future<...>>`。核心是：**不能假装提交成功，也不能无限卡住。**

所以不需要为了你现在这个测试改 ThreadPool；但你的直觉是对的：一个合格的 ThreadPool 必须定义“并发 `submit` 与 `shutdown` 时，阻塞提交者最终会怎样”。

### 一些 test cases

```text
record count: 30000
producer count: 1000
async logger queue capacity: 1000000
record_time_run_sync_logger: 0.0353121 s
PASS

record_time_run_async_logger: 
submission time: 0.029965 s
end-to-end time: 0.0305122 s
PASS

record count: 300000
producer count: 100
async logger queue capacity: 1000000
record_time_run_sync_logger: 0.0458984 s
PASS

record_time_run_async_logger: 
submission time: 0.115952 s
end-to-end time: 0.153313 s
PASS

record count: 3000000
producer count: 1000
async logger queue capacity: 1000000
record_time_run_sync_logger: 0.500913 s
PASS

record_time_run_async_logger: 
submission time: 9.95171 s
end-to-end time: 10.0903 s
PASS
```

## R2

```text
起点都放在把对象创建结束之后。保证算的是纯 log() 的 call time。

但是，你注意，你要先创建 thread，并且让他们还没有开始调用 call 的这个时候开始计时，所以你需要闸门，开一个 gate；然后所有 thread 等待 gate=true 的时候，才能开始执行；否则阻塞等待。
然后在 main thread 里先记录时刻，再打开 gate，这样能保证开始时刻之前没有 thread 调用 call。
如果反过来，可能在开始时刻之前已经调用了 call 了。

end-to-end time end 放在 flush,close 之后

对每个 case 保存 5 组重复测试
然后加了些数据的小处理而已。
```

```
record count: 300000
producer count: 1
async logger queue capacity: 100000
record_time_run_sync_logger: 
submission time: 0.0184623s end-to-end time: 0.0215484s PASS
submission time: 0.0164912s end-to-end time: 0.0196078s PASS
submission time: 0.0198269s end-to-end time: 0.0229952s PASS
submission time: 0.016734s end-to-end time: 0.0200519s PASS
submission time: 0.0164073s end-to-end time: 0.0196198s PASS
submission time: 
median: 0.016734s, min: 0.0164073s, max: 0.0198269s
end-to-end time: 
median: 0.0200519s, min: 0.0196078s, max: 0.0229952s
records per second: 1.49611e+07
record_time_run_async_logger: 
submission time: 0.146743 s end-to-end time: 0.159826 s PASS
submission time: 0.139948 s end-to-end time: 0.154007 s PASS
submission time: 0.150942 s end-to-end time: 0.16441 s PASS
submission time: 0.153047 s end-to-end time: 0.166782 s PASS
submission time: 0.143116 s end-to-end time: 0.157944 s PASS
submission time: 
median: 0.146743s, min: 0.139948s, max: 0.153047s
end-to-end time: 
median: 0.159826s, min: 0.154007s, max: 0.166782s
records per second: 1.87704e+06
