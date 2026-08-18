## 验收

1. BlockingQueue class 应拥有哪几个 state/synchronization objects？它不拥有谁？

   看我代码

   queue 不拥有 threads

2. 为什么 `empty()` 和 `pop()` 两个独立 calls 不能组成可靠 check-then-act？

   因为中间可能插入其他 thread 的操作，就比如原先 check 完 !empty，但是其他 thread 在中间窗口 pop 了，导致不可靠了。

3. V1 的 class invariant 是什么？

   ```text
   capacity_ > 0
   container_.size() <= capacity_
   所有 container_ access 都持有 mutex_
   not_empty 等价于 !container_.empty()
   not_full 等价于 container_.size() < capacity_
   ```

   

4. `push(T value)` 中 value ownership 在 caller、parameter、queue 之间怎样变化？

   caller->parameter->move 进 queue 这个容器里

5. 为什么 class template implementation 初学阶段通常放在 header？

   如果我们把 declaration,definition 分开放，那么 linker 会看到 main.cpp 需要 Box<int>::get() 但是在 .cpp 中没有明确的这个，只有 Box<T>，他不会 link 起来。所以我们把这俩放一起，让 complier 能根据 definition 去实例化使用到的成员。

6. `size()` 即使内部加锁，为什么返回值也只是一张 snapshot？

   因为返回后可能别的地方去 push/pop，所以只是当时的 snapshot

7. 为什么 MPMC test 中每个 consumer 需要一个 sentinel？

   每个 consumer 都需要一个 sentinel，取走它然后退出。

8. queue destructor 前 owner 必须保证什么？`close` 缺失为何让这件事更难？

   没有 execution flow 正在 push/pop
   没有 waiter 仍睡在 queue condition variable 上                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
   所有 producer/consumer threads 已 join

   没有 close 难以保证 consumers 关闭，所以今天用 sentinel

