![img](day5_note.assets/32d4ebfaa975c4363b28a6fe743a5a76.png)

### 问题 1

`counter++` 为什么不是一个有 C++ atomicity guarantee 的操作？请手推两个 thread 怎样得到 lost update。

因为 counter++ 其实是 counter=counter+1，需要先读 counter，再 modify 把 counter+1，最后再 write。

```text
初始：counter=0
A: counter++
B: counter++

A 拿到 counter=0
B 拿到 counter=0
A 计算 counter+1=1
B 计算 counter+1=1
A 写入 counter，此时 counter=1
B 写入 counter，此时 counter=1
```

### 问题 2

`race condition` 与 C++ `data race` 有什么区别？为什么错误版一次输出正确也不能证明程序正确？

race condition: 程序正确性依赖谁先发生，也就是依赖执行顺序。

data race: 是多个 thread 并发访问同一个 memory location，然后至少一个 access 是 write。access 之间没有同步，访问也不是正确的 atomic access。

### 问题 3

mutex 机械上做了什么？程序设计中它应该保护“代码”、一个变量，还是 shared state 的 invariant？

mutex 就是加了一把互斥锁，同一时刻只能被一个线程持有。

shared_state 的 invariant

### 问题 4

为什么 critical section 必须覆盖完整 read-modify-write？只给 read 或 write 加锁会怎样？

因为要保证 observer 看不到中间暂时不稳定的状态。

就是 observer 能看到喽。

还有比如只给 read 加锁，那你 Thread A 读完后 release lock，然后 Thread B 去读，这样后面还是没锁，仍然会导致 lost update

### 问题 5

Thread A 按 `M1 -> M2` 获取锁，Thread B 按 `M2 -> M1` 获取锁，怎样形成 deadlock？固定 lock ordering 怎样破坏它？

图片有

### 问题 6

为什么工程上通常先从 coarse-grained lock 开始？什么 evidence 出现后，才值得拆成 fine-grained locks？

正确性保证了之后。因为避免一开始就用很细的锁，把状态拆的很复杂。

### 问题 7

TSan 报告 data race 能证明什么？一次运行没有报告又不能证明什么？

这次执行发生 data race。不能证明所有执行都不会 data race。