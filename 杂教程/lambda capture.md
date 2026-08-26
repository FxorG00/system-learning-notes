## capture 全局变量

因为 `str` 是全局变量，lambda 不需要 capture 它。

lambda 的 capture（`[i]`、`[&]`）只针对**外层函数里的局部自动变量**。全局变量本来就在名字查找范围里，lambda 的函数体可直接访问：

```cpp
std::vector<std::string> str;  // 全局变量

void f() {
    int i = 3;                 // f 的局部变量

    auto task = [i] {
        sync_log(str[i]);      // str 是全局变量：可直接用
                               // i 是局部变量：必须 capture
    };
}
```

所以你的闭包对象里大致只保存了一份 `i`：

```text
lambda closure:
    i = 当前循环的 i 值
```

执行任务时，它通过全局名字 `str` 找到同一个全局 vector。

补一个精确点：全局 `vector` 对象本身具有 **static storage duration（静态存储期）**，程序结束才析构；但它内部保存字符串的那块元素数组通常是在堆上分配的。只要所有任务执行期间你不并发修改、扩容或销毁 `str`，这里的读取就是安全的。

## 调用其他函数

允许。lambda 的函数体和普通函数体一样，能调用：

```cpp
void sync_log(const std::string& message);

auto task = [i] {
    sync_log(str[i]);  // 调用普通全局函数，完全可以
};
```

调用全局函数、命名空间函数、静态成员函数都不需要 capture。

如果要调用某个对象的成员函数，lambda 需要能拿到那个对象：

```cpp
auto task = [this, i] {
    this->sync_log(str[i]);
};
```

这里 capture 的不是成员函数，而是 `this` 指针；之后才能通过它调用成员函数。

## capture mutex

**capture 的意义在于，让 lambda 内部获得访问外界变量的能力；但不等同于立刻去访问外界变量。**

对，完全是两回事。

```cpp
std::mutex mutex;

auto task = [&mutex] {
    // 这里只是拥有对原 mutex 的引用
};
```

创建这个 lambda、复制这个 lambda、把它交给 `std::thread` 或 ThreadPool 时，都**不会**自动：

```text
mutex.lock()
mutex.unlock()
```

`[&mutex]` 的意思只是：

```text
lambda 之后执行时，
可以访问外面那个同一个 mutex 对象。
```

真正拿锁，要在 lambda 的执行体里显式发生：

```cpp
auto task = [&mutex] {
    std::lock_guard<std::mutex> guard(mutex);
    // guard 构造时 lock()
    // 离开这个 lambda 时 guard 析构，自动 unlock()
};
```

所以你说得对：捕获只是“保存访问它的能力”，不是“占有这把锁”。

唯一需要额外记住的是生命周期：lambda 捕获的是引用，因此原来的 `mutex` 必须活到 lambda 真正执行完。多个 lambda 即使都捕获了同一个 `mutex`，也只是都指向同一把锁；谁先成功 `lock()`，谁才真正进入临界区。