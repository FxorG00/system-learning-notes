## R1

### 设计

```text
整体类似 ThreadPool，更简单。

what we need?
ofstream 对象
writer thread
string blocking queue

构造：构造 writer thread;构造 blocking_queue;拿到 output 对象;
constructor 打开一个新的 output file；失败时报告错误

writer_thread: 不断从 queue 里拿出来，并且 output。直到拿出来 nullopt 为止。

log: 类似于 submit，直接往 queue 里 push 元素；
push 失败的话，return false;
成功就 return true;

shutdown: queue.close()
然后 join writer thread（需要 joinable），这样会 drain all accepted string

destructor: 调用一次 shutdown
```

### 工作目录，运行时相对路径

因为 `"logger_api_demo.txt"` 是**运行时相对路径**，它相对的是程序启动时的 **current working directory（当前工作目录，就是终端当前的位置）**，和 `.cpp` 文件实际放在哪个目录没有关系。

你大概率是在 `week8` 根目录执行了测试程序，例如：

```bash
~/code/system-learning/cpp/week8$ ./build/async_logger_test
```

所以运行时：

```cpp
AsyncLogger logger("logger_api_demo.txt", 1);
```

等价于把文件写到：

```text
~/code/system-learning/cpp/week8/logger_api_demo.txt
```

`tests/async_logger_test.cpp` 只是在**编译时**被读取；程序运行后并不知道“这一行代码原本来自 tests 目录”。

你可以用这个模型记：

```text
#include "async_logger.hpp"
    -> 编译期：按 include path 找头文件

"logger_api_demo.txt"
    -> 运行期：按当前工作目录找/创建文件
```

如果你改成：

```cpp
AsyncLogger logger("tests/logger_api_demo.txt", 1);
```

它仍然是相对于当前工作目录；只有当当前目录是 `week8` 时，才会落到 `week8/tests/`。

顺便看一眼你的测试，建议最后补一句：

```cpp
EXPECT_EQ(nw, 5);
```

否则文件少写一行时，`while` 少循环一次，前面的逐行比较仍可能全通过。反过来如果文件多于 5 行，`str[nw]` 会越界。

### constructor 创建 thread 失败了咋办？

构造 writer thread 失败也要报告错误，但是这里真的能 catch 吗？如果我放在初始化列表。

**如果 std::thread 自身构造失败，会抛 std::system_error**；由于 thread object 没有成功构造（**那自然不会去调用其析构函数**，因为它这个都不是完整的 object），不存在 joinable thread，**之前构造好的 queue/output 会正常析构**，**然后我们让这个 system_error 传播出去即可。**

### constructor 创建 writer 后就不要去做可能抛异常的工作

`stack unwinding` 就是“异常一路往外找谁来处理”的过程中，**C++ 自动销毁已经成功构造的局部对象和成员对象。中文通常叫“栈展开”**。

你这里最关键的结论是：

```text
AsyncLogger 的 constructor 抛异常
-> AsyncLogger 这个完整对象没有构造成功
-> 不会调用 AsyncLogger::~AsyncLogger()
-> 但已经构造成功的 members 会按反向顺序析构
```

假设成员大致是：

```cpp
BlockingQueue<std::string> queue_;
std::ofstream output_;
std::thread writer_;
```

构造函数 body 里做了：

```cpp
writer_ = std::thread(&AsyncLogger::writer_loop, this);
// 此时 writer_ 已经是 joinable

throw std::runtime_error("later setup failed");
```

此时发生的是：

```text
constructor body 抛异常
-> AsyncLogger 对象构造失败，不调用 ~AsyncLogger()
-> 开始栈展开，去自动销毁已经构造的对象
-> 析构已成功构造的 writer_
-> std::thread 发现自己仍 joinable；
一定是要仍然 joinable 的，然后去析构，才会调用 terminate；
如果是 non-joinable 的 thread object 去析构（这个 object 没有跟任何一个 execution flow 有关系），是安全的。
-> std::terminate()，导致整个 process 终止
```

所以不是“直接出去”，也不是“调用整个 `AsyncLogger` 的析构函数”。而是 C++ 自动清理已经存在的成员；恰好 `std::thread` 的析构规则很严格：它还代表一个没 `join()` / `detach()` 的线程（就仍然 joinable），就直接终止程序。

这也是教程里说“启动 writer 后不要再做可能抛异常的工作”的原因：

```text
先构造 queue
-> 打开并检查 file
-> 做完所有其他可能失败的准备
-> 最后启动 writer
-> constructor 正常结束
```

这样就不会出现“线程已经跑起来，但对象构造又失败”的半成品状态。