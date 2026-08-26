它们都是标准异常体系里的类型，最上面共同的父类是：

```cpp
std::exception
```

它最基本的接口是：

```cpp
const char* what() const noexcept;
```

用于取得错误描述。你现在最常见的是这几类：

```text
std::exception
├── std::logic_error
│   ├── std::invalid_argument
│   ├── std::out_of_range
│   ├── std::length_error
│   └── std::future_error
│
├── std::runtime_error
│   ├── std::range_error
│   ├── std::overflow_error
│   └── std::underflow_error
│
├── std::system_error
├── std::bad_alloc
├── std::bad_function_call
└── std::bad_cast / std::bad_typeid
```

结合你现在的线程池：

```cpp
throw std::invalid_argument("worker_count must be positive");
```

`invalid_argument`：**调用者传入的参数本身不合法**。

```text
ThreadPool(0, 4)
BlockingQueue<int>(0)
```

这类通常是调用方违反了接口前置条件，属于 `logic_error` 一支。

```cpp
throw std::runtime_error("thread pool is closed");
```

`runtime_error`：参数本身未必有问题，但**程序运行到当前状态时，这件事做不了**。

```text
pool.shutdown()
-> pool.submit(...)
```

`submit` 的 callable 和参数可能完全合法，只是 pool 已关闭，不能再接收任务，所以今天选 `runtime_error` 合理。

常用的另外几种：

```cpp
std::out_of_range
```

下标或位置越界。例如：

```cpp
std::vector<int> values{1, 2};
values.at(5); // 抛 out_of_range
```

```cpp
std::bad_alloc
```

`new` 或容器扩容申请内存失败时可能抛出。

```cpp
std::bad_function_call
```

调用了空的 `std::function`：

```cpp
std::function<void()> task;
task(); // 抛 bad_function_call
```

这正是 Day3 的 empty `std::function` 场景。

```cpp
std::future_error
```

错误使用 `future/promise/packaged_task` 的 API。例如：

```cpp
future.get(); // 第一次正常
future.get(); // 普通 future 第二次，抛 future_error
```

还有你当前 rejection 未处理时看到的：

```text
std::future_error: Broken promise
```

它表示：future 等待的那份 shared state 的生产者已经销毁，却从未写入 value 或 exception。

```cpp
std::system_error
```

系统层或线程库操作失败。例如 `std::thread` 创建失败，或者错误地 `join()` 自己。

实际 catch 时，优先按具体含义处理，最后再兜底：

```cpp
try {
    // ...
} catch (const std::invalid_argument& error) {
    // 参数不合法
} catch (const std::runtime_error& error) {
    // 运行状态不允许
} catch (const std::exception& error) {
    // 其他标准异常
}
```

压缩记忆：

```text
invalid_argument：你给我的输入不对
out_of_range：你访问的位置不对
runtime_error：输入未必错，但当前运行状态做不了
bad_function_call：调用了空 std::function
future_error：future/promise/packaged_task 用法或状态不对
bad_alloc：内存申请失败
system_error：线程、文件描述符等系统资源操作失败
```