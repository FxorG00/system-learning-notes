# Week2 Day2：移动构造函数 + std::move 初步

> 今日定位：Day1 已经知道 deep copy 安全但可能浪费。  
> Day2 从一个具体问题开始：**move 到底怎么写出来？为什么 `std::move(a)` 之后会进移动构造？**

---

# Part A：前情提要和术语

## 1. 从 Day1 接上来

Day1 的结论是：

```text
deep copy 能避免 double delete，但如果资源很大，复制成本可能很高。
move 的动机是：当 old object 快不用了，与其复制资源，不如转移资源所有权。
```

Day2 不是重新刷 Rule of Three。

今天只是把这个动机写成代码：

```cpp
Buffer b = std::move(a);
```

今天的核心问题是：

```text
move 到底怎么写出来？
std::move(a) 到底干了什么？
真正转移资源的代码在哪里？
```

---

## 2. 左值、右值、右值引用：今天只学够用版

### 2.1 左值

你可以先粗略理解成：

```text
有名字、可以反复使用的对象表达式。
```

例如：

```cpp
Buffer a(5);
```

表达式 `a` 是左值。

所以：

```cpp
Buffer b = a;
```

这里会倾向于 copy。

### 2.2 右值

你可以先粗略理解成：

```text
临时的、快要结束生命周期的表达式。
```

例如：

```cpp
Buffer(5)
make_buffer(10)
```

这类东西通常可以被移动。

### 2.3 右值引用

写法是：

```cpp
T&&
```

移动构造函数写成：

```cpp
Buffer(Buffer&& other)
```

今天先把它理解成：

```text
我接收一个可以被我接管资源的 Buffer。
```

不要写成：

```cpp
Buffer(const Buffer&& other)
```

因为 move 要修改 `other`，把它置空。加了 `const` 就不能做这件事。

---

## 3. `noexcept` 今天只要知道一层

移动构造常写：

```cpp
Buffer(Buffer&& other) noexcept
```

今天只需要知道：

```text
noexcept 表示这个移动构造承诺不抛异常。
标准库容器以后搬元素时，会更愿意使用 noexcept 的 move。
```

完整规则 Day3 再说，不在 Day2 深挖。

---

# Part B：教程主体

## 4. 从今天的问题出发：move 怎么写

现在你已经有一个资源类 `Buffer`：

```cpp
Buffer a(5);
a.set(0, 'A');
```

`a` 里面有一块自己管理的堆内存：

```text
a.data_ ---> char 数组
```

如果你写：

```cpp
Buffer b = a;
```

这表示：

```text
a 还要继续保留自己的资源
b 需要拿到一份独立资源
```

所以它应该调用 copy constructor，做 deep copy。

但今天我们想表达另一件事：

```text
a 这份资源我不想复制了。
我愿意让 b 直接接管 a 手里的那块内存。
```

这时候你想写的是：

```cpp
Buffer b = std::move(a);
```

今天整节课就围绕这句展开：

```text
Buffer b = std::move(a);
```

它到底发生了什么？

---

## 5. 先看目标效果

move 之后，我们希望从这个状态：

```text
a.data_ ---> char 数组
```

变成这个状态：

```text
a.data_ ---> nullptr
b.data_ ---> 原来 a 管的 char 数组
```

也就是说：

```text
资源没有复制。
资源的 owner 从 a 变成 b。
```

所以移动构造函数要做的事情很直接：

```text
1. b.data_ 接管 a.data_
2. b.size_ 接管 a.size_
3. a.data_ 置空
4. a.size_ 置 0
```

对应代码就是：

```cpp
Buffer(Buffer&& other) noexcept
    : data_(other.data_), size_(other.size_) {
    std::cout << "move construct size=" << size_ << '\n';
    other.data_ = nullptr;
    other.size_ = 0;
}
```

这就是 Day2 最核心的代码。

---

## 6. `std::move(a)` 到底干了啥

先把最容易误解的点说死：

```text
std::move(a) 不会移动 a 的资源。
std::move(a) 不会修改 a.data_。
std::move(a) 不会 delete。
std::move(a) 不会自动把 a 置空。
```

它做的事情更接近：

```text
把表达式 a 转成一种“可以被移动构造函数接收”的表达式。
```

更贴近代码一点说：

```cpp
std::move(a)
```

大致可以理解成：

```cpp
static_cast<Buffer&&>(a)
```

你现在不用深挖 `static_cast` 和值类别，只要抓住这句：

```text
std::move 是一个强制转换。
它把 a 从“普通左值表达式”转换成“可以绑定到 Buffer&& 的表达式”。
```

所以这句：

```cpp
Buffer b = std::move(a);
```

真正的调用链是：

```text
1. a 本来是左值，所以 Buffer b = a 会优先走 copy constructor
2. std::move(a) 把 a 转成可移动表达式
3. 编译器发现你有 Buffer(Buffer&& other)
4. 所以调用移动构造函数
5. 移动构造函数内部接管 data_，再把 other.data_ 置空
```

因此：

```text
std::move 负责“让移动构造有机会被选中”。
移动构造函数负责“真正转移资源”。
```

这句话是今天的核心。

---

## 7. 如果没有移动构造，会发生什么

假设你的类只有 copy constructor：

```cpp
Buffer(const Buffer& other);
```

没有：

```cpp
Buffer(Buffer&& other);
```

这时你写：

```cpp
Buffer b = std::move(a);
```

它不一定报错。它可能还是调用 copy constructor。

原因是：

```text
std::move(a) 只是把 a 转成“可移动表达式”。
但类没有移动构造函数，没人负责接管资源。
const Buffer& 又可以绑定这个表达式。
所以最后仍然可能走 copy constructor。
```

所以不要把 `std::move` 当成魔法。

它不是：

```text
std::move 一出现，资源就被移动。
```

而是：

```text
std::move 一出现，编译器允许优先匹配移动构造/移动赋值。
如果你没写移动构造，那就没有真正的资源转移。
```

---

## 8. 为什么移动构造里必须把 old 对象置空

移动构造如果只写成：

```cpp
Buffer(Buffer&& other) noexcept
    : data_(other.data_), size_(other.size_) {
}
```

那 move 后会变成：

```text
b.data_     ---> char 数组
other.data_ ---> 同一块 char 数组
```

这就又回到 Week1 的浅拷贝问题了：

```text
两个对象都以为自己拥有同一块资源。
两个对象析构时都会 delete[] 同一块内存。
```

所以必须写：

```cpp
other.data_ = nullptr;
other.size_ = 0;
```

这样 move 后是：

```text
b.data_     ---> char 数组
other.data_ ---> nullptr
```

旧对象还会析构，但：

```cpp
delete[] nullptr;
```

是安全的。

所以“move 后对象仍然有效”今天先理解成：

```text
它不一定还有原来的值。
但它必须能安全析构，最好也能被重新赋值。
```

---

## 9. 拷贝构造 vs 移动构造

拷贝构造是：

```cpp
Buffer(const Buffer& other)
    : data_(new char[other.size_]), size_(other.size_) {
    std::cout << "copy construct size=" << size_ << '\n';
    for (std::size_t i = 0; i < size_; ++i) {
        data_[i] = other.data_[i];
    }
}
```

它的动作是：

```text
new 一块新内存
复制 old 内存里的内容
新旧对象各自拥有一份资源
```

移动构造是：

```cpp
Buffer(Buffer&& other) noexcept
    : data_(other.data_), size_(other.size_) {
    std::cout << "move construct size=" << size_ << '\n';
    other.data_ = nullptr;
    other.size_ = 0;
}
```

它的动作是：

```text
不 new 新内存
不复制内容
直接接管 old 的指针
把 old 置成安全空状态
```

所以今天要观察的不是“语法好不好看”，而是资源动作不同：

```text
copy：复制资源
move：转移 owner
```

---

## 10. 代码练习 1：给 Buffer 加移动构造

文件：

```text
01_move_constructor_buffer.cpp
```

目标：在 Day1 的 `Buffer` 基础上，只加移动构造，不重新做重复 work。

你需要加：

```cpp
#include <utility>
```

以及：

```cpp
Buffer(Buffer&& other) noexcept
    : data_(other.data_), size_(other.size_) {
    std::cout << "move construct size=" << size_ << '\n';
    other.data_ = nullptr;
    other.size_ = 0;
}
```

建议最小测试：

```cpp
int main() {
    Buffer a(5);
    a.set(0, 'A');

    Buffer b = a;
    std::cout << "b[0]=" << b.get(0) << '\n';

    Buffer c = std::move(a);
    std::cout << "c[0]=" << c.get(0) << '\n';
    std::cout << "a.size()=" << a.size() << '\n';

    return 0;
}
```

你应该看到类似：

```text
construct size=5
copy construct size=5
b[0]=A
move construct size=5
c[0]=A
a.size()=0
destruct size=5
destruct size=5
destruct size=0
```

你要解释清楚：

```text
Buffer b = a;            因为 a 是左值，所以走 copy construct
Buffer c = std::move(a); 因为 std::move(a) 可绑定到 Buffer&&，所以走 move construct
```

---

## 11. 代码练习 2：证明 std::move 没有魔法

文件：

```text
02_move_vs_copy.cpp
```

这个练习专门用来回答：

```text
std::move 到底是不是自己移动资源？
```

做两轮实验。

### 实验 A：注释掉移动构造

先注释掉：

```cpp
Buffer(Buffer&& other) noexcept
```

保留：

```cpp
Buffer(const Buffer& other)
```

然后写：

```cpp
Buffer a(5);
Buffer b = std::move(a);
```

如果输出是：

```text
copy construct size=5
```

说明：

```text
std::move(a) 自己没有转移资源。
没有 move constructor 时，最后还是 copy。
```

### 实验 B：恢复移动构造

恢复：

```cpp
Buffer(Buffer&& other) noexcept
```

再运行：

```cpp
Buffer a(5);
Buffer b = std::move(a);
```

如果输出是：

```text
move construct size=5
```

说明：

```text
移动构造函数被选中了。
真正转移资源的是移动构造函数里的 data_ 接管和 other 置空。
```

---

## 12. 可选观察：函数返回时 copy 变 move

如果你有时间，可以把 Day1 的返回对象例子拿来观察。

```cpp
Buffer make_buffer(std::size_t size) {
    Buffer tmp(size);
    tmp.set(0, 'A');
    return tmp;
}

int main() {
    Buffer b = make_buffer(10);
}
```

普通编译时，RVO/NRVO 可能让你只看到一次构造。

如果你加：

```bash
g++ -std=c++17 -Wall -Wextra -g -fno-elide-constructors 01_move_constructor_buffer.cpp -o 01_move_constructor_buffer
```

在有移动构造的情况下，`return tmp` 可能会显示：

```text
move construct size=10
```

这说明：

```text
当编译器不能省掉返回过程时，它会倾向于用 move，而不是 deep copy。
```

今天只要这个直觉，不背标准细节。

---

# Part C：练习、检查和收尾

## 13. 常见错误

### 13.1 以为 std::move 会自动清空对象

错误理解：

```text
std::move(a) 会把 a 的资源移动走。
```

正确理解：

```text
std::move(a) 只是转换表达式。
是否清空 a，取决于移动构造 / 移动赋值怎么写。
```

### 13.2 move 后不置空 old 对象

错误写法：

```cpp
Buffer(Buffer&& other) noexcept
    : data_(other.data_), size_(other.size_) {
}
```

风险：

```text
double delete
```

### 13.3 move 后继续依赖原内容

可以观察：

```cpp
std::cout << a.size() << '\n';
```

因为你的实现把 `size_` 置成 0。

但不要期待：

```cpp
a.get(0)
```

还能返回原来的 `'A'`。

move 后对象原则：

```text
可以析构，可以重新赋值，但不要依赖它保留原内容。
```

### 13.4 忘记 include utility

`std::move` 来自：

```cpp
#include <utility>
```

---

## 14. 中途检查

写完 `01_move_constructor_buffer.cpp` 后回答：

```text
1. Buffer b = a 为什么走 copy construct？
2. Buffer c = std::move(a) 为什么走 move construct？
3. std::move(a) 本身有没有修改 a.data_？
4. 真正修改 a.data_ 的是哪一行？
5. a 被 move 后，析构时为什么不会 double delete？
```

写完 `02_move_vs_copy.cpp` 后回答：

```text
1. 没有 move constructor 时，std::move(a) 为什么可能还是 copy？
2. 恢复 move constructor 后，输出发生了什么变化？
3. std::move 和 move constructor 的分工是什么？
```

---

## 15. 面试追问

```text
1. std::move 是什么？
2. std::move 会真的移动对象吗？
3. 移动构造函数的参数为什么是 T&&？
4. 移动构造和拷贝构造有什么区别？
5. move 后对象还能不能使用？
6. 为什么移动构造里要把原对象指针置空？
7. 如果一个类没有移动构造，std::move 会发生什么？
8. 为什么移动构造通常要标 noexcept？
```

今天最重要的回答模板：

```text
std::move 本质上是一个转换，它把对象变成可以匹配右值引用的表达式。
它本身不移动资源。
真正移动资源的是移动构造函数或移动赋值函数。
```

---

## 16. 6.S081 / 15-445 关联点

今天不正式开 6.S081 / 15-445。

但后面系统项目里很多资源都不适合 copy：

```text
socket fd
file fd
thread
mmap memory
connection object
logger file handle
```

这些类常见设计会是：

```text
禁止拷贝
允许移动
用 RAII 保证释放
```

所以移动构造不是孤立语法，它是在给后面的 ThreadPool / Reactor / Mini Redis 铺资源管理底座。

---

## 17. 今天不要提前深挖

今天先不要碰：

```text
完美转发
万能引用
引用折叠
std::forward
std::move_if_noexcept
vector 选择 move/copy 的完整规则
复杂 noexcept 传播
移动赋值完整设计
```

移动赋值：

```cpp
Buffer& operator=(Buffer&& other)
```

Day3 再写。

---

## 18. 今日笔记要求

`day2_note.md` 建议只写这些：

```markdown
# Week2 Day2 Note

## 1. 今天从什么问题出发

## 2. std::move 我现在怎么理解

## 3. 移动构造函数做了什么

## 4. copy construct 和 move construct 输出有什么区别

## 5. 为什么 move 后要把 other.data_ 置空

## 6. move 后对象还能不能用

## 7. 今天还不稳的问题
```

最核心一句：

```text
std::move 本身不移动资源，它只是让表达式可以匹配移动构造；真正转移资源的是移动构造函数。
```

---

## 19. 今日验收问题

```text
1. std::move 会真的移动资源吗？
2. std::move(a) 对 a.data_ 做了什么修改？
3. 移动构造函数的参数为什么写 Buffer&& other？
4. 移动构造和拷贝构造的资源处理有什么区别？
5. 为什么移动构造里要把 other.data_ 置为 nullptr？
6. move 后对象还能不能使用？至少要满足什么要求？
7. 如果没有移动构造函数，Buffer b = std::move(a) 可能会调用什么？
8. noexcept 今天只需要建立什么直觉？
```

这 8 个问题能答清楚，Day2 就过。

---

## 20. Git commit

```bash
cd ~/code/system-learning
git status
git add cpp/week2/day2_move_constructor
git commit -m "week2 day2 add move constructor buffer"
```

如果笔记不在仓库里，只提交代码也可以。

---

## 21. 下一天衔接

Day3 会补齐：

```text
移动赋值
Rule of Five
noexcept 再往前一点
```

Day2 的结束标准不是会背所有右值引用规则，而是你能解释这段：

```cpp
Buffer(Buffer&& other) noexcept
    : data_(other.data_), size_(other.size_) {
    other.data_ = nullptr;
    other.size_ = 0;
}
```

为什么它：

```text
没有复制整块资源
转移了 owner
也不会 double delete
```