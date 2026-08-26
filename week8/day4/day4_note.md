## R1

```
constructor 参数边界

contract: worker_count=0 throw std::invalid_argument("invalid argument: worker_count=0\n");

Arrange: 构造 thread_pool,worker_count=0
Act: throw invalid_argument
Assert / oracle: EXPECT_THROW(...,...)
Cleanup: 离开作用域析构 thread_pool

返回 int / void 的 task
contract: 提交一个返回 int 比如 101 的 callable，会返回一个 future 给我，最终会 ready，且可以get。
Arrange: 构造 thread_pool
Act: submit task and get future
Assert: future.get() 得到 101
cleanup: shutdown

task exception 通过 future 传播
contract: 提交一个 throw std::runtime_error callable，会返回一个 future 给我，最终能从该 future get 到该 exception
Arrange: 构造 thread_pool
Act: submit task and get future
Assert: future.get() 得到 std::runtime_error
cleanup: shutdown

shutdown 后 submission 被拒绝
contract: shutdown 后再 submit 会被拒绝，且 throw runtime_error
Arrange: 构造 thread_pool
Act: shutdown and submit task
Assert: submit 当场抛异常
cleanup: shutdown

多个 tasks 最终完成
contract: 每个 task 完成后，其 submit 返回的 future 都会变成 ready
Arrange: 构造 thread_pool
Act: submit all tasks and shutdown and check all future
Assert: all future eventually become ready 且能 get 到正确结果
cleanup: shutdown
```

## R2

### 怎么样 check 每个 task 被执行 exactly one

```text
R2就是对检测是不是所有的 task 最终都完成，把它的这个检测的手法变成了为每个 task 分配一个 unique ID，然后准备 N 个这个 count，然后去看看是不是每一个 count i 它都是 1。这样就能够证明它每一个 task 它只执行恰好一次。
```

### how to check shutdown 时仍然有 pending tasks

对，就是这个意思。你已经把这个测试为什么需要 `helper thread` 想明白了。

关键是：`shutdown()` 不是一个瞬间完成的动作，而是有顺序的：

```text
shutdown()
    ->
queue.close()        // 立刻拒绝新任务
    ->
join workers         // 这里可能长时间阻塞，等待 A、B 都结束
    ->
shutdown() return
```

所以如果 test thread 自己直接调用：

```cpp
pool.shutdown();
```

它会卡在 `join`，而 test thread 后面就没机会：

```text
提交 C
release A
验证 B
```

因此让 helper thread 调 `shutdown()`，test thread 才能观察 `shutdown` 的中间状态。

完整因果链正是你说的这样：

```text
1. pool：1 worker，queue capacity=1

2. submit A
   worker 取走 A
   A 报告“我启动了”
   A 卡在 release gate

3. submit B
   此时 worker 仍被 A 占住
   queue 原本空，因此 B 成功进入 queue
   B 已 accepted，但还没有开始执行
   => B 是 pending task

4. helper thread 调用 shutdown()
   -> queue.close()
   -> helper 卡在 join，因为 A 还卡在 gate

5. test thread submit C
   -> queue 已关闭
   -> C 被拒绝，submit 抛 runtime_error
   -> 此时 A 仍未 release
   -> 唯一 worker 不可能执行 B
   => 可证明：queue 已 close，但 B 仍 pending

6. test thread release A
   -> A 结束
   -> worker 终于能从已关闭但非空的 queue 取出 B
   -> B 执行完
   -> worker 发现 closed 且 queue empty，退出
   -> helper 的 join 完成，shutdown() 返回

7. test thread join helper
   -> 断言 A/B 都正确执行
   -> 断言 C 从未被 accepted
```

最重要的证明点其实在第 5 步：

```text
C 已被 reject
+
A 还没有被 release
+
只有一个 worker
+
B 已经成功入队
=
close 已发生时，B 一定仍是 pending
```

它同时验证了三个 contract：

```text
1. shutdown 会先 close queue，再等待 workers
2. close 后不再接受 C
3. close 前已经接受的 B 不会丢失，而会在之后被 drain
```

`capacity = 1` 很关键：它让 B 的位置非常明确，就是 queue 中唯一的 pending task；`worker_count = 1` 则让你能确定 B 不可能偷偷被另一个 worker 执行。

还有一个细节：C 刚开始调用 `submit` 时，queue 可能仍是满的，所以它可以暂时阻塞在 `push`。等 helper 执行 `queue.close()`，`close()` 会唤醒这个等待中的提交者；C 醒来发现 closed，再返回失败。这个“C 被拒绝且 A 仍卡住”的观察，就是不靠 `sleep` 的同步证据。

### empty std::function 怎么抛出异常

对，你这次抓到关键了。

```cpp
[] {}
```

不是 empty function。它只是“函数体什么都不做”的 lambda，但它依然有可调用的 `operator()`，所以是一个合法 callable：

```cpp
auto do_nothing = [] {};
do_nothing();  // 正常返回，不抛异常
```

真正的 empty `std::function` 是：

```cpp
std::function<void()> empty;
```

它内部没有保存任何 callable target，因此：

```cpp
if (!empty) {
    // true
}

empty();  // 自动抛 std::bad_function_call
```

你后面问得尤其好：**原本空的 `std::function` 经过层层包装后，外层确实会变成“非空的 wrapper”，但它没有修好最里面那个空 function。**

你的 Day3 链可以这样看：

```text
inner std::function<void()> empty
    |
    | std::bind(empty)
    v
bind object
    |
    | packaged_task<void()>
    v
packaged_task
    |
    | lambda capture shared_ptr
    v
outer lambda
    |
    | std::function<void()> Task
    v
queue
```

外层对象的状态是：

```text
inner empty std::function
    !inner == true

bind object
    是一个合法 object，可以被调用

packaged_task
    有内部 callable，所以有效

outer lambda
    有 operator()，所以有效

queue 中的 Task std::function
    保存了 outer lambda，所以 !Task == false
```

因此，worker 从 queue 里取出的那个 `Task` 的确**不是空的**。它调用后会一层层往里走：

```text
worker 调用 outer Task
-> 调用 outer lambda
-> 调用 packaged_task
-> 调用 bind object
-> bind object 最终调用 inner empty std::function
-> 此时才抛 std::bad_function_call
```

随后 `packaged_task` 把这个异常存到它自己的 shared state，`future.get()` 再重抛。

所以你实际测到“包装完外层不再 empty”，完全正确；但这里的包装只是保留了“将来调用原对象”的动作，不会把原对象从：

```text
没有 callable target
```

变成：

```text
有 callable target
```

最容易记的一句是：

> `[] {}` 是“不做事但能调用”的 callable；empty `std::function` 是“连可调用目标都没有”的 wrapper。外层包装可以非空，但最终仍会调用到最里面那个空的 `std::function`。