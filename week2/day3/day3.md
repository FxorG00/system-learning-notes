# Week2 Day3：移动赋值 + Rule of Five

> 今日定位：Day2 已经写出了移动构造，解决的是“新对象从 old object 接管资源”。  
> Day3 从另一个具体问题开始：**如果目标对象已经有资源了，再执行 `b = std::move(a)`，旧资源怎么办？**

---

# Part A：前情提要和术语

## 1. 从 Day2 接上来

Day2 的核心结论是：

```text
std::move 本身不移动资源。
std::move 只是把表达式转换成可以匹配右值引用的形式。
真正转移资源的是移动构造函数 / 移动赋值函数。
```

移动构造解决的是这种场景：

```cpp
Buffer a(5);
Buffer b = std::move(a);
```

这里的 `b` 是一个新对象。

所以移动构造只需要：

```text
1. b 接管 a.data_
2. b 接管 a.size_
3. a.data_ = nullptr
4. a.size_ = 0
```

但 Day3 要解决的是另一种场景：

```cpp
Buffer a(5);
Buffer b(3);
b = std::move(a);
```

这里的 `b` 不是新对象。它原本已经有一块资源。

所以问题变成：

```text
b 原来的那块资源怎么办？
```

这就是移动赋值的核心。

---

## 2. 今天的关键术语

### 2.1 移动构造

移动构造用于创建新对象：

```cpp
Buffer b = std::move(a);
```

函数形式：

```cpp
Buffer(Buffer&& other) noexcept;
```

它面对的是：

```text
当前对象正在被创建，还没有旧资源。
```

### 2.2 移动赋值

移动赋值用于给已有对象重新赋值：

```cpp
b = std::move(a);
```

函数形式：

```cpp
Buffer& operator=(Buffer&& other) noexcept;
```

它面对的是：

```text
当前对象已经存在，而且可能已经拥有旧资源。
```

所以移动赋值比移动构造多一个动作：

```text
先释放当前对象已有资源。
```

### 2.3 self-move

self-move 就是这种代码：

```cpp
a = std::move(a);
```

正常代码里很少主动这么写，但泛型代码、容器操作、复杂逻辑里可能间接出现。

今天你先按保守写法处理：

```cpp
if (this == &other) {
    return *this;
}
```

### 2.4 Rule of Five

如果一个类自己管理资源，并且你写了下面这些函数中的一些，通常要认真考虑五个特殊成员函数：

```text
1. destructor
2. copy constructor
3. copy assignment
4. move constructor
5. move assignment
```

这就是 Rule of Five。

它不是让你机械手写五个函数，而是在提醒：

```text
这个类的资源所有权策略要完整。
```

---

## 3. noexcept 今天再推进一点

Day2 你只需要知道：

```text
noexcept 表示这个函数承诺不抛异常。
```

Day3 多加一层直觉：

```text
标准库容器在扩容、搬移元素时，如果 move constructor 是 noexcept，
就更愿意用 move；否则为了异常安全，可能退回 copy。
```

今天不用证明标准库的完整规则，只要建立这个判断：

```text
资源类的移动构造 / 移动赋值，如果只是指针交换和置空，通常应该标 noexcept。
```

---

# Part B：教程主体

## 4. 从今天的问题出发：移动赋值怎么写

现在有两个对象：

```cpp
Buffer a(5);
Buffer b(3);
```

它们各自管理一块内存：

```text
a.data_ ---> 5 字节 char 数组
b.data_ ---> 3 字节 char 数组
```

现在执行：

```cpp
b = std::move(a);
```

我们希望结果是：

```text
a.data_ ---> nullptr
b.data_ ---> 原来 a 管的 5 字节 char 数组
```

但别忘了，`b` 原来那块 3 字节内存也要处理。

所以移动赋值要做五件事：

```text
1. 判断是不是 self-move
2. 释放当前对象 b 原来的资源
3. b 接管 a.data_
4. b 接管 a.size_
5. 把 a 置成安全空状态
```

对应代码：

```cpp
Buffer& operator=(Buffer&& other) noexcept {
    std::cout << "move assignment size=" << other.size_ << '\n';
    if (this == &other) {
        return *this;
    }

    delete[] data_;
    data_ = other.data_;
    size_ = other.size_;

    other.data_ = nullptr;
    other.size_ = 0;
    return *this;
}
```

这就是 Day3 最核心的代码。

---

## 5. 为什么移动赋值要先 delete 当前资源

移动构造不需要先 `delete[] data_`，因为：

```text
移动构造时，当前对象正在创建，还没有旧资源。
```

但移动赋值不一样。

```cpp
Buffer b(3);
b = std::move(a);
```

这里 `b` 已经拥有一块资源。如果你直接写：

```cpp
data_ = other.data_;
size_ = other.size_;
```

那 `b` 原来那块 3 字节内存的地址就丢了。

结果是：

```text
memory leak
```

所以移动赋值必须先释放当前对象已有资源：

```cpp
delete[] data_;
```

然后再接管 `other.data_`。

这就是移动构造和移动赋值最重要的差异。

---

## 6. 为什么移动赋值也要处理 self-move

考虑这句：

```cpp
a = std::move(a);
```

如果没有 self-check，移动赋值可能这样执行：

```cpp
delete[] data_;
data_ = other.data_;
size_ = other.size_;
other.data_ = nullptr;
other.size_ = 0;
```

但这里：

```text
this 和 &other 是同一个对象
```

也就是说：

```text
data_ 和 other.data_ 其实是同一个成员
```

如果不提前返回，很容易把自己的资源删掉，然后又从自己这里接管一个已经被删掉或已经被改乱的指针。

所以今天先用最稳的写法：

```cpp
if (this == &other) {
    return *this;
}
```

这样 `a = std::move(a);` 至少不会炸。

---

## 7. 拷贝赋值 vs 移动赋值

拷贝赋值的目标是：

```text
我不偷你的资源。
我要自己申请一份新资源，然后复制你的内容。
```

推荐写法仍然是先申请新资源，再释放旧资源：

```cpp
Buffer& operator=(const Buffer& other) {
    std::cout << "copy assignment size=" << other.size_ << '\n';
    if (this == &other) {
        return *this;
    }

    char* new_data = new char[other.size_];
    for (std::size_t i = 0; i < other.size_; ++i) {
        new_data[i] = other.data_[i];
    }

    delete[] data_;
    data_ = new_data;
    size_ = other.size_;
    return *this;
}
```

移动赋值的目标是：

```text
我不要复制。
我释放自己的旧资源，然后接管你的资源。
```

```cpp
Buffer& operator=(Buffer&& other) noexcept {
    std::cout << "move assignment size=" << other.size_ << '\n';
    if (this == &other) {
        return *this;
    }

    delete[] data_;
    data_ = other.data_;
    size_ = other.size_;
    other.data_ = nullptr;
    other.size_ = 0;
    return *this;
}
```

对比一下：

```text
copy assignment：new 新资源 + 复制内容 + delete 旧资源
move assignment：delete 旧资源 + 接管 other 指针 + 置空 other
```

这两者的资源动作完全不同。

---

## 8. Rule of Five 怎么串起来

现在你的 `Buffer` 如果要完整支持 copy 和 move，就会有五个特殊成员函数：

```cpp
~Buffer();
Buffer(const Buffer& other);
Buffer& operator=(const Buffer& other);
Buffer(Buffer&& other) noexcept;
Buffer& operator=(Buffer&& other) noexcept;
```

这就是 Rule of Five。

直觉上：

```text
析构函数：我怎么释放资源
拷贝构造：新对象怎么复制资源
拷贝赋值：已有对象怎么复制资源
移动构造：新对象怎么接管资源
移动赋值：已有对象怎么接管资源
```

你不需要把 Rule of Five 当作背诵题。你只要能从资源角度说清楚：

```text
对象创建时怎么办？
对象赋值时怎么办？
对象销毁时怎么办？
copy 时怎么办？
move 时怎么办？
```

这就够了。

---

## 9. 代码练习 1：完整 Rule of Five Buffer

文件：

```text
01_rule_of_five_buffer.cpp
```

目标：在 Day2 的 `Buffer` 基础上，加移动赋值，形成完整 Rule of Five。

今天不是重新写一遍所有旧代码。你可以直接沿用 Day2 版本，然后加：

```cpp
Buffer& operator=(Buffer&& other) noexcept {
    std::cout << "move assignment size=" << other.size_ << '\n';
    if (this == &other) {
        return *this;
    }

    delete[] data_;
    data_ = other.data_;
    size_ = other.size_;

    other.data_ = nullptr;
    other.size_ = 0;
    return *this;
}
```

建议测试：

```cpp
int main() {
    Buffer a(5);
    a.set(0, 'A');

    Buffer b(3);
    b.set(0, 'B');

    b = std::move(a);
    std::cout << "b[0]=" << b.get(0) << '\n';
    std::cout << "a.size()=" << a.size() << '\n';

    Buffer c(2);
    c = b;
    std::cout << "c[0]=" << c.get(0) << '\n';

    b = std::move(b);
    std::cout << "b.size()=" << b.size() << '\n';

    return 0;
}
```

你应该能观察到：

```text
move assignment size=5
b[0]=A
a.size()=0
copy assignment size=5
c[0]=A
move assignment size=5
b.size()=5
```

最后一次 `b = std::move(b)` 因为 self-check，应该不破坏 `b`。

用 ASan 跑一次：

```bash
g++ -std=c++17 -Wall -Wextra -g -fsanitize=address 01_rule_of_five_buffer.cpp -o 01_rule_of_five_buffer
./01_rule_of_five_buffer
```

如果没有报错，说明至少没有明显 double delete / use-after-free。

---

## 10. 代码练习 2：观察 noexcept 的直觉

文件：

```text
02_vector_move_noexcept_observe.cpp
```

这个练习只做观察，不深挖标准规则。

目标是看：

```text
当 vector 扩容需要搬元素时，noexcept 的 move constructor 会影响它更愿意 move 还是 copy。
```

可以写一个简化类：

```cpp
#include <iostream>
#include <vector>

class Item {
public:
    Item() {
        std::cout << "construct\n";
    }

    Item(const Item&) {
        std::cout << "copy construct\n";
    }

    Item(Item&&) noexcept {
        std::cout << "move construct\n";
    }
};

int main() {
    std::vector<Item> v;
    v.reserve(1);
    v.emplace_back();
    v.emplace_back();
    return 0;
}
```

你可以试两次：

```text
1. move constructor 带 noexcept
2. 把 noexcept 去掉
```

观察输出差异。

今天不要纠缠标准完整规则，只写一句笔记：

```text
noexcept 会影响标准库容器在搬移元素时是否放心使用 move。
```

---

# Part C：练习、检查和收尾

## 11. 常见错误

### 11.1 移动赋值忘记释放当前旧资源

错误写法：

```cpp
data_ = other.data_;
size_ = other.size_;
```

问题：

```text
当前对象原来管理的资源地址丢失，memory leak。
```

### 11.2 移动赋值忘记置空 other

错误写法：

```cpp
delete[] data_;
data_ = other.data_;
size_ = other.size_;
return *this;
```

问题：

```text
两个对象都指向同一块资源，析构时 double delete。
```

### 11.3 不处理 self-move

危险场景：

```cpp
a = std::move(a);
```

今天用保守写法处理：

```cpp
if (this == &other) {
    return *this;
}
```

### 11.4 把移动赋值写成返回 void

赋值运算符应该返回：

```cpp
Buffer&
```

这样可以保持赋值表达式的常规行为。

```cpp
return *this;
```

### 11.5 以为写了 move 就不用管 copy

Rule of Five 的意思不是“只要写 move 就行”。

如果你的类既允许 copy，又允许 move，就要让两套语义都正确：

```text
copy：复制资源
move：转移资源
```

如果类不应该 copy，后面 Day4 会用 `unique_ptr` 进一步表达独占所有权。

---

## 12. 中途检查

写完 `01_rule_of_five_buffer.cpp` 后回答：

```text
1. 移动赋值和移动构造最大的区别是什么？
2. 移动赋值为什么要先 delete[] data_？
3. 移动赋值为什么要把 other.data_ 置 nullptr？
4. b = std::move(b) 为什么需要特殊处理？
5. Rule of Five 是哪五个函数？
```

写完 `02_vector_move_noexcept_observe.cpp` 后回答：

```text
1. vector 扩容为什么需要搬元素？
2. noexcept 对 move constructor 有什么直觉影响？
3. 今天是否需要背标准库完整选择规则？
```

---

## 13. 面试追问

今天这些问题很高频：

```text
1. Rule of Five 是什么？
2. Rule of Five 和 Rule of Three 有什么关系？
3. 移动构造和移动赋值区别是什么？
4. 移动赋值为什么要释放当前对象原来的资源？
5. 移动赋值为什么要处理 self-assignment / self-move？
6. move 后对象处于什么状态？
7. noexcept 对移动语义有什么影响？
8. 一个资源类什么时候应该禁止拷贝、允许移动？
```

你可以这样回答移动构造和移动赋值的区别：

```text
移动构造是在创建新对象时接管资源，新对象没有旧资源。
移动赋值是给已有对象重新赋值，所以必须先处理当前对象原来拥有的资源，再接管 other 的资源。
```

---

## 14. 6.S081 / 15-445 关联点

今天仍然不正式开 6.S081 / 15-445。

但移动赋值和后面的系统项目很相关。

比如以后你写这些类：

```text
Fd
Socket
Connection
ThreadHandle
MmapRegion
LogFile
```

它们往往都有这样的性质：

```text
不能随便复制
可以转移所有权
析构时释放资源
```

移动赋值就是支持“已有 owner 接管另一个 owner 的资源”的机制。

---

## 15. 今天不要提前深挖

今天先不要碰：

```text
copy-and-swap 完整异常安全写法
std::exchange
std::swap 定制
完美转发
万能引用
引用折叠
allocator
vector move/copy 标准规则证明
复杂 noexcept 传播
```

其中 `std::exchange` 可以让移动构造写得更漂亮，但今天先别用。先把资源动作写明白。

---

## 16. 今日笔记要求

`day3_note.md` 建议只写这些：

```markdown
# Week2 Day3 Note

## 1. 今天从什么问题出发

## 2. 移动赋值和移动构造的区别

## 3. 移动赋值函数做了什么

## 4. 为什么要先释放当前对象旧资源

## 5. 为什么要处理 self-move

## 6. Rule of Five 我怎么理解

## 7. noexcept 今天我怎么理解

## 8. 今天还不稳的问题
```

最核心一句：

```text
移动构造处理新对象接管资源；移动赋值处理已有对象接管资源，所以移动赋值必须先释放当前对象原有资源。
```

---

## 17. 今日验收问题

```text
1. 移动赋值函数的签名是什么？
2. 移动赋值和移动构造最大的区别是什么？
3. 移动赋值为什么要先 delete[] data_？
4. 移动赋值为什么要把 other.data_ 置 nullptr？
5. self-move 是什么？为什么今天要处理？
6. Rule of Five 是哪五个函数？
7. noexcept 对容器搬移元素有什么直觉影响？
8. 今天的 Buffer 是否能解释 copy 和 move 两套语义？
```

这 8 个问题能答清楚，Day3 就过。

---

## 18. Git commit

如果今天代码和笔记都完成，可以提交：

```bash
cd ~/code/system-learning
git status
git add cpp/week2/day3_move_assignment_rule_five
git commit -m "week2 day3 rule of five buffer"
```

如果笔记不在仓库里，只提交代码也可以。

---

## 19. 下一天衔接

Day4 会进入：

```text
unique_ptr
独占所有权
禁止拷贝
允许移动
现代 C++ 如何减少手写 delete
```

Day3 的结束标准是：

```text
你能写出完整 Rule of Five Buffer，
并能解释移动赋值为什么比移动构造多一步：释放当前对象旧资源。
```