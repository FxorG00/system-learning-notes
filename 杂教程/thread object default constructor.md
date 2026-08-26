你抓到重点了：`std::thread` 不能复制，但你这句并不是复制，而是**移动赋值**。

```cpp
writer_ = std::thread(writer_work, std::ref(queue), std::ref(output));
```

可以拆成三步理解：

```text
1. writer_ 默认构造
   -> 不代表任何实际线程
   -> writer_.joinable() == false

2. std::thread(...) 创建一个临时 thread object
   -> 新线程立刻开始执行 writer_work(...)
   -> 这个临时对象暂时拥有“管理该线程、以后 join/detach 的责任”

3. writer_ = 临时对象
   -> 调用 move assignment，不是 copy assignment
   -> “管理线程的责任”从临时对象转移到 writer_
   -> 临时对象变成 non-joinable，马上析构也安全
```

关键是：被移动的不是“正在跑的 execution flow”，而是 `std::thread` 这个管理它的 handle/ownership。

```text
temporary thread object  --move-->  writer_
        joinable                      joinable

temporary object 析构
        non-joinable，所以没事
```

下面这种才是复制，根本不能编译：

```cpp
std::thread a(work);
std::thread b = a;  // 错：std::thread copy constructor 被 delete
```

而你的右边是一个临时对象，属于 rvalue，所以匹配的是：

```cpp
std::thread& operator=(std::thread&& other);
```

也就是 move assignment。

还有一个很重要的危险边界：

```cpp
writer_ = std::thread(work1);  // writer_ 开始管理 thread 1

writer_ = std::thread(work2);  // 若 thread 1 仍 joinable，直接 std::terminate()
```

这里甚至不是“旧 writer 自动析构并 join”，而是 `std::thread` 的 move assignment 发现左边仍是 joinable，就直接终止程序。因为标准库不敢替你决定：你是想 `join` 旧线程，还是 `detach` 它。

所以正确规则是：

```text
default constructed / 已 join / 已 detach 的 thread
-> non-joinable
-> 可以接收一个新的 std::thread move assignment

仍 joinable 的 thread
-> 不能直接重新赋值
-> 必须先 join 或 detach
```

在 `AsyncLogger` 里，`writer_` 一开始是默认构造的空 handle，因此 constructor 末尾这句完全合法：

```cpp
writer_ = std::thread(&AsyncLogger::writer_loop, this);
```

而 `std::ref(queue)`、`std::ref(output)` 表示新线程借用 queue 和 output，不复制它们；因此它们必须在 writer 结束并 `join()` 后才能销毁。这正是 logger 里 `close -> drain -> join -> members destruct` 的原因。