## exception:

```cpp
#include <stdexcept>
throw std::runtime_error("something wrong");
```



```cpp
try {
    may_throw();
} catch (const std::exception& e) {
    std::cout << e.what() << '\n';
}
```



## 问题引入：

```cpp
delete[] data_;
data_ = new char[other.size_];

如果 new 失败抛异常，旧资源已经没了。
这个对象可能处于半坏状态。

如何更稳妥一些？
```

## throw 异常

```cpp
void work() {
    Tracer a("a");
    Tracer b("b");

    std::cout << "before throw\n";
    throw std::runtime_error("work failed");

    std::cout << "after throw\n";
}
```

即使，我们 throw 了，但是你 a,b 离开了它的作用域，所以该析构的还是析构，顺序还是先创建的后析构。

`unqiue_ptr` 本身也是 RAII 对象，所以你异常时也会自动释放。

## copy-and-swap

核心：创建临时对象，把 `other` 拷贝到这个对象，拷贝失败抛异常，不影响 `this`。拷贝成功 `swap`。

```cpp
Buffer& operator=(const Buffer& rhs) {
    Buffer temp(rhs);  // 1. 先拷贝出一个临时对象
    swap(temp);        // 2. 拷贝成功后，再交换资源
    return *this;      // 3. temp 离开作用域，析构时释放旧资源
}
```

如果，`Buffer temp(rhs)` 失败了，那么抛异常，后面的 `swap` 没有执行，不会影响 `this`。

tip：这里的 `rhs` 是 `right-hand side`，就是赋值号右边，比如 `a=b` 就是 `b`。

如果成功了，自然没啥事。

```cpp
Buffer& operator=(Buffer temp) {
    swap(temp);
    return *this;
}
```

利用，按值传递的拷贝一个副本 `temp`，因为 `temp` 的作用域时这个函数，所以它离开的时候也会自动析构。

如果拷贝失败，那 `operator=` 函数都进不去。

拷贝成功，那 `swap` 后更没啥问题，`temp` 自动析构。

## 友元函数的 swap

我们也可以不把 `swap` 声明为成员函数。

```cpp
friend void swap(Buffer& a, Buffer& b) noexcept {
    using std::swap;
    swap(a.data_, b.data_);
    swap(a.size_, b.size_);
}
```

## 验收问题

```text
1. throw 之后，当前作用域里已经构造好的局部对象会不会析构？
会。

2. 什么是栈展开？
throw 的话，就不会再往下执行函数了，但是会把这个函数的局部对象给析构了。

3. RAII 为什么能保证异常路径下资源释放？
因为 throw 会调用局部对象的析构函数，RAII 析构的时候释放资源。

4. 为什么裸 new 后面如果发生 throw，可能导致 delete 执行不到？
因为不是 RAII 对象，没有这个析构函数，需要手动 delete，但是 throw 已经不会再接着往下执行函数了。

5. copy assignment 里先 delete 再 new 的风险是什么？
delete 成功，但是 new 失败抛异常，那么旧状态就丢失了。

6. copy-and-swap 的核心步骤是什么？
上文有。

7. copy-and-swap 为什么能处理 self-assignment？
a=a
过程如下：
从 a 深拷贝出 temp
a 和 temp 交换
temp 拿到 a 的旧资源
temp 析构并且 delete 旧资源

8. copy-and-swap 为什么更容易提供强异常安全直觉？
可能抛异常的地方发生在修改 this 之前。
并且就算拷贝失败了，this 不变。

9. 析构函数里应不应该主动 throw？为什么？

析构函数一般不应该抛异常。
如果栈展开期间析构函数再次抛异常，程序会调用 std::terminate，然后就程序终止了。
```

## noexcept

```text
就是你写了 noexcept，那你就是承诺这个函数不抛异常。

那你就要注意容易抛异常的地方。
函数里有 new / make_unique / 容器扩容 / 字符串复制吗？
调用了可能抛异常的函数吗？
复制了可能申请资源的对象吗？
如果有，不要轻易写 noexcept。

函数只是交换指针、修改整数、返回成员、转移所有权吗？
如果所有操作都确定不会抛，适合写 noexcept。
```

