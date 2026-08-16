## 验收问题

1. data race、race condition 和 nondeterministic order 分别是什么？

   不同 threads 对同一 memory location 发生 conflicting actions
   并且没有适当 synchronization 建立顺序

   `race condition`：竞态条件。

   它是更广的逻辑概念：结果是否正确取决于不同 execution flows 的时序。

   nondeterministic order：不确定的顺序，比如说多个 thread 的完成先后顺序不同。

2. 为什么一次 transfer 的 mutex scope 必须同时覆盖扣款与入账？

   因为如果不这样的话，而是分开取 mutex，那么可能会在中途被 observer 观察到不正确的 balances，从而导致 invariant(sum balances) 观察到改变。

3. “mutex 保护 balances_”为什么还不够精确？应该怎样描述 invariant？

   不止这个。mutex 是用来保护 invariant 的

   就是不变量，要求对其修改的时候外界没办法观察到，也就是外界只能观察到 invariant 始终保持不变。

   比如day2 还有总额不变、余额非负、失败不改变状态

4. 为什么只读 getter 也可能需要 lock？`const` 为什么不等于 thread-safe？

   因为可能其他 thread 并发 write 同一个 shared state

   const 只是说这个函数内部不会修改成员变量，但是可能有其他 thread 同时修改这个成员变量，这时候即使调用的是 const，也没办法保证成员变量不受修改。

5. 为什么返回内部 `vector&` 会让 method 内部的 lock 失去保护作用？

   因为外部就可以通过这个引用去修改来了。

   `const vector&` 也可能在锁释放后与 writer 并发读取

6. `lock_guard` 与 `unique_lock` 今天的职责差异是什么？

   lock_guard 不支持在中途 lock/unlock，也就是 lock_guard 的 mutex lock 是在 object construct 的时候进行，unlock 是在 destruct 的时候，也就是贯穿整个 lifetime

   unique_lock 支持主动 unlock/relock、defer lock，并用于 condition_variable

7. 同一 mutex 的 unlock 与后续 lock 为 shared state 提供了什么第一层保证？

   因为保证了 synchronization，也就是 T1 先 unlock 后 T2 才能 lock，即 T1 结束了对 shared state 的操作后 T2 才能进行操作。

8. TSan、重复运行和 final invariant 各自能证明什么、不能证明什么？

   Tsan 不 report 只能说明本次执行没有 data race，但是不等于 invariant 一定正确。

   重复运行只能证明在运行的期间保持正确，不能证明一定正确，业务逻辑一定没问题。

   final invariant 只能说明末状态没问题，不能保证中途不会出现 data race 或者说其他的情况。