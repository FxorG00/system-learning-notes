#### 片段一

```cpp
auto p1 = std::make_unique<int>(42);
auto p2 = p1;
```

回答：

```text
能否编译？
不能

如果不能，违反了什么所有权语义？
make_unique 是独占资源，不能 copy。

应该如何转移？
auto p1 = std::make_unique<int>(42);
auto p2=std::move(p1);
```

#### 片段二

```cpp
Buffer a(10);
Buffer b = std::move(a);
```

回答：

```text
std::move 做了什么？
把 a 转换成了能被 move constructor or move assignment 接收的参数

真正转移资源的是谁？
是 move constructor or move assignment 函数

a 之后至少要满足什么要求？
能否默认断言 a.size() == 0？

a 这个 Buffer 对象仍然有效，可以安全析构和重新赋值。
不能默认断言 a.data_ == nullptr 或 a.size() == 0，
除非 Buffer 自己的移动函数明确保证了这个状态。
```

#### 片段三

```cpp
struct Node {
    std::shared_ptr<Node> next;
};
```

两个 `Node` 的 `next` 相互指向。

回答：

```text
为什么外部 shared_ptr 都析构后，Node 仍可能不析构？
啥意思？
是 auto p1=std::make_shared<Node>();
auto p2=std::make_shared<Node>();
p1->next=p2; p2->next=p1 吗？
如果是我理解的这样，那 p1,p2 都是没办法析构的，因为 p1 指向的 Node 对象，p2.next 也指向它，然后因为 shared_ptr 会有一个循环引用，我猜你的问题是这个，所以就没办法析构。

哪一条关系适合改成 weak_ptr？
next 这个，表示一种，我只用来观察，但是我不影响你 next 指向的对象的生命周期。
```

#### 片段四

```cpp
Buffer& operator=(const Buffer& other) {
    delete[] data_;
    data_ = new char[other.size_];
    // copy data
    return *this;
}
```

回答：

```text
如果 new 抛异常，对象发生什么？
那么对象的 data 已经被清空了，然后又抛异常了，所以旧状态丢失了。
这个对象就是半坏的感觉。

这个版本可能满足基本异常安全吗？
不满足。因为 data_ 仍然指向那块失效的内存。后续析构的时候可能 double free

怎样调整顺序更稳？
用 copy-and-swap
```

#### 片段五

```cpp
Buffer& operator=(Buffer temp) {
    swap(temp);
    return *this;
}
```

回答：

```text
temp 在什么时候构造？
在按值传入的时候，temp 就构造，是传入的实际对象的副本。

拷贝失败时为什么 this 不变？
拷贝失败就根本不会进入函数体。也就不会修改到 this。

swap 后旧资源去了哪里？
temp，然后最后离开这个函数 temp 析构了。

为什么它能处理 self-assignment？
考虑 a=a，其实这个在 day6_note 有，我就不重复了。
```

#### 验收问题：

```text
1. copy 和 move 在资源处理上有什么本质区别？
copy 是你有一份，我也有一份。
move 是转移资源管理权。

2. std::move 本身到底做了什么？
上面有。

3. 移动构造和移动赋值的区别是什么？
一个是 constructor，在对象创建的时候调用。
另外一个是 assignment，可以通过赋值这一行为调用。

4. moved-from 对象至少要满足什么要求？
p2=std::move(p1)
p1 这个 unique_ptr 仍然有效，可以安全析构和重新赋值。

5. Rule of Five 是哪五个函数？什么时候不需要手写它们？
析构函数
copy/move constructor
copy/move assignemnt
看情况吧！比如我利用了 unique_ptr 这些自动管理生命周期的，就可以不用手写。

6. unique_ptr 为什么不能 copy，但可以 move？
copy 的话，就会导致资源不是独占的。
move 是可以的。

7. shared_ptr 解决什么问题，又引入什么风险？
解决一个资源有多个 owner。循环引用。

8. weak_ptr 为什么能打破循环引用？lock() 返回什么？
weak_ptr 不影响对象生命周期。
auto p=weak_ptr1.lock(); 如果 weak_ptr1指向的对象存活，那么返回指向这个对象的 shared_ptr。否则空的 shared_ptr。

9. throw 之后，为什么 RAII 资源仍能释放？
栈展开保证 throw 后会去调用局部对象的析构函数，RAII 析构的时候会释放资源。

10. copy assignment 里先 delete 再 new 有什么风险？
上面有。

11. copy-and-swap 为什么更容易提供强异常安全？
day6_note 有

12. 哪些函数适合写 noexcept？为什么 move 的 noexcept 对 vector 有意义？
能承诺这个函数不抛异常，比如一些简单的赋值，指针赋值。
vector 在扩容时，优先考虑 noexcept 的移动构造；移动构造可能抛异常且 copy 可用时，可能改用 copy。
```

