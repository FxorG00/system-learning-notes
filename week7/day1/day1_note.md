## 验收问题

1. `std::thread object` 与真正运行 callable 的 execution flow 有什么区别？

   std::thread object 是 C++ standard library 里用来管理 execution flow 的一个 object

   thread object 是管理句柄，execution flow 才是真正并发执行 callable 的主体。

2. worker callable 已经返回，但还没 `join()` 时，thread object 为什么仍可能 `joinable()`？

   因为 joinable 为 true 意味着这个 object 还管理着一个尚未 join/detach 的 execution flow

   那你还没 join 确实有可能是 joinable（不 detach 的话）

3. 为什么 joinable thread object 不能直接析构？

   可能对应的 execution flow 还在运行。那么 std::thread destructor 会调用 std::terminate

   即使 execution flow 已经结束，只要 thread object 仍是 joinable，
   直接析构仍会调用 std::terminate，使得整个 process 均 terminate。

4. `join()` 改变了什么状态？它会不会主动终止 worker？

   join 改变了 joinable

   不会，他会等到 worker 执行结束

   `join()` 等待结束、回收关联并令 object 不再 joinable，不会主动终止 worker。

5. `detach()` 为什么不能解决 reference lifetime 和 graceful shutdown？

   不是很懂这两个问题

   detach 只解除 std::thread object 与 execution flow 的关联；
   execution flow 仍可能继续访问引用，因此对象析构后可能产生 dangling reference。

   graceful shutdown 需要通知停止 -> 等待执行结束 -> 再销毁依赖对象；
   detach 没有提供等待完成的手段。

6. `std::ref` 做了什么，又没有做什么？

   指定 thread argument 直接引用原变量，因为默认情况是搞个副本保存在 thread 里

   但它不延长 `number` 生命周期

7. 为什么 `parallel_sum` 可以不用 mutex？请从 input、ranges、result slots 和 join 顺序说明。

   因为我们把每个 worker 的 input range 进行划分，使得他们不 overlap，这样他们把其对应的区间求和起来，存到各自独立 的 result slots，再等待 main join 后得到结果，就一定是对的。没有存在什么 shared variable 多个 thread 可能竞争

   但 `value` 和 `sum` 仍是 shared objects。无需 mutex 是因为 input 只读、每个 worker 写不同 memory location、main 在 join 后读取。

8. main 为什么必须在 join 后再汇总 partial results？

   join 能保证 worker 执行结束；这样 result 里存的结果才是对的。