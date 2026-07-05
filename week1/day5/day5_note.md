## static_cast

`static_cast<void*>(data_)` 就是在做一次类型转换。这是 c++ 风格的。c 风格就是 `(void*)data_` 当然不太推荐。cast 就是类型转换，static 就是编译器在编译的时候就知道转换的规则，比如这里它就知道要从 `int* -> void*`。`void*` 在这里就是明确表达，我只是想把这个指针的地址打印出来看看而已。

## 拷贝构造

`IntBuffer a=b` 用一个对象去在另外一个对象创建的时候初始化它。copy constructor。本质上是一个构造函数。`IntBuffer(const IntBuffer& other)` 你看这个东西，它保证了 other is a reference to const IntBuffer，也就是我们没办法去修改 other，并且是传引用，避免在传参的时候拷贝影响效率。

## 拷贝赋值：

`a=b`，两个对象都已经创建好了，只是一个 copy assignment。`IntBuffer& operator=(const IntBuffer& other)`。

为什么返回 `IntBuffer&`，考虑 `a=b=c`，先执行 `b=c`，再执行 `a=(b=c的返回值b)`。并且，我们考虑 `(a=b)=c`，等价于 `a=c`，也就是说，`=` 这个运算符是需要返回左值的引用的，引用时为了 `(a=b)=c` 的 `=c` 真正修改到 `a`，因为引用就是起别名嘛。

```text
拷贝赋值函数：
1. 判断是不是自己，自己给自己赋值就不用管
2. 原来的资源释放嘛？
3. 需不需要重新申请资源
4. 返回 *this 嘛
```

## std::size_t

`std::size_t` 是一种无符号整型，专门表示对象大小，数组长度之类的。存在于 `cstddef` 头文件里。

## Rule of Three

如果一个类需要自己写析构函数，通常说明它在管理资源；
那它大概率也要自己写拷贝构造和拷贝赋值。

管理资源的时候我们需要考虑实现的。

```text
~T();
T(const T& other);
T& operator=(const T& other);
```

今天的内容对我来说比较简单，所以我只记了一些稍微陌生的。

## 浅拷贝 / 深拷贝

浅拷贝：
只复制指针值，不复制指针指向的资源。
例如 a.data_ 和 b.data_ 指向同一块数组，析构时会 double delete。

深拷贝：
重新申请一块自己的资源，再把内容复制过去。
例如 a.data_ 和 b.data_ 指向不同数组，但数组内容一样。

## self-assignment

self-assignment 就是自己给自己赋值，比如 a = a。

拷贝赋值里要判断：
if (this == &other) return *this;

否则可能先 delete[] data_，再从 other.data_ 复制；
但 other 就是自己，此时 other.data_ 也已经被删了。