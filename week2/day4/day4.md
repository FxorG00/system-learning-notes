# Week2 Day4：unique_ptr 和独占所有权

> 今日定位：Day1~Day3 你已经手写过 Rule of Five。  
> Day4 从一个具体问题开始：**既然手写 `new/delete + Rule of Five` 这么容易出错，能不能用一个类型直接表达“这块资源只有我拥有”？**

---

# Part A：前情提要和术语

## 1. 从 Day3 接上来

Day3 你已经写出了完整的资源类：

```text
destructor
copy constructor
copy assignment
move constructor
move assignment
```

也就是 Rule of Five。

你现在应该能解释：

```text
copy：复制资源
move：转移资源
destructor：释放资源
```

但这也暴露出一个问题：

```text
手写资源管理很容易错。
```

比如：

```text
忘记 delete -> memory leak
多 delete 一次 -> double delete
move 后忘记置空 -> double delete
copy assignment 顺序不稳 -> 异常时对象可能坏掉
self-assignment / self-move 忘处理 -> 容易出 bug
```

所以 Day4 要进入现代 C++ 的一个核心方向：

```text
用类型表达所有权，少手写 delete。
```

今天主角是：

```cpp
std::unique_ptr
```

---

## 2. 今天的关键术语

### 2.1 owning pointer

owning pointer 是拥有资源的指针。

也就是说：

```text
它不只是指向对象。
它还负责在合适的时候释放对象。
```

裸指针也可以是 owning pointer：

```cpp
int* p = new int(10);
```

但裸指针的问题是：

```text
类型本身看不出来谁负责 delete。
```

### 2.2 non-owning pointer

non-owning pointer 只是观察，不负责释放。

例如：

```cpp
void print(const int* p);
```

这里 `p` 可能只是借来看一下，不拥有对象。

今天你只要记住：

```text
裸指针可以作为 non-owning pointer。
但不推荐用裸指针表达 owning pointer。
```

### 2.3 unique ownership

unique ownership 是独占所有权。

意思是：

```text
同一时刻只有一个 owner 负责释放资源。
```

如果所有权要换人，只能 move，不能 copy。

这正是 `std::unique_ptr` 的语义。

### 2.4 RAII

`unique_ptr` 本质上也是 RAII：

```text
构造 / 创建时拿到资源
析构时自动释放资源
```

区别是：

```text
以前你自己写析构函数 delete。
现在 unique_ptr 的析构函数帮你 delete。
```

---

## 3. 需要包含什么头文件

`unique_ptr` 和 `make_unique` 在：

```cpp
#include <memory>
```

今天默认使用 C++17，可以直接用：

```cpp
std::make_unique<T>()
```

编译命令仍然是：

```bash
g++ -std=c++17 -Wall -Wextra -g 文件名.cpp -o 输出名
```

---

# Part B：教程主体

## 4. 从今天的问题出发：能不能不手写 delete

先看你之前的写法：

```cpp
class Buffer {
public:
    explicit Buffer(std::size_t size)
        : data_(new char[size]), size_(size) {}

    ~Buffer() {
        delete[] data_;
    }

private:
    char* data_;
    std::size_t size_;
};
```

这套写法的问题是：

```text
只要类里有 owning raw pointer，你就要认真处理拷贝、赋值、移动、析构。
```

所以 Day1~Day3 才一路写到 Rule of Five。

但如果你只是想表达：

```text
这个对象独占一块资源，生命周期结束时自动释放。
```

那现代 C++ 通常会优先考虑：

```cpp
std::unique_ptr
```

例如单对象：

```cpp
std::unique_ptr<int> p = std::make_unique<int>(42);
```

这句话表达：

```text
p 独占一个 int 对象。
p 析构时，这个 int 自动释放。
```

你不用写：

```cpp
delete p;
```

也不能写，因为 `p` 不是裸指针。

---

## 5. unique_ptr 的核心语义：不能 copy，可以 move

`unique_ptr` 表达独占所有权。

独占的意思是：

```text
同一块资源不能同时被两个 unique_ptr 拥有。
```

所以这段代码不能编译：

```cpp
std::unique_ptr<int> p1 = std::make_unique<int>(42);
std::unique_ptr<int> p2 = p1;  // 错误：不能 copy
```

为什么？

因为如果允许 copy，就会变成：

```text
p1 以为自己拥有 int
p2 也以为自己拥有同一个 int
```

这就回到了裸指针 shallow copy 的老问题：

```text
double delete
```

所以 `unique_ptr` 直接从类型层面禁止 copy。

但是可以 move：

```cpp
std::unique_ptr<int> p1 = std::make_unique<int>(42);
std::unique_ptr<int> p2 = std::move(p1);
```

move 后：

```text
p2 接管资源
p1 变成 nullptr
```

也就是说：

```text
所有权从 p1 转移给 p2。
```

这和 Day2/Day3 你手写的 move 本质一致，只是现在标准库帮你写好了。

---

## 6. unique_ptr 和裸指针的本质差别

裸指针：

```cpp
int* p = new int(42);
```

它只告诉你：

```text
p 里存了一个地址。
```

它没有告诉你：

```text
谁负责 delete？
什么时候 delete？
能不能 copy？
copy 后谁释放？
```

`unique_ptr`：

```cpp
std::unique_ptr<int> p = std::make_unique<int>(42);
```

它直接告诉你：

```text
p 是 owner。
p 独占资源。
p 不能 copy。
p 可以 move。
p 析构时自动释放资源。
```

这就是“用类型表达所有权”。

这也是为什么现代 C++ 不推荐裸 `new/delete` 到处飞。

---

## 7. make_unique 为什么更推荐

你可以这样创建：

```cpp
std::unique_ptr<int> p(new int(42));
```

但更推荐：

```cpp
auto p = std::make_unique<int>(42);
```

原因先不用深挖异常安全细节，今天只记三点：

```text
1. 更短，更清楚
2. 避免裸 new 出现在业务代码里
3. 以后和异常安全关系更好
```

所以今天默认写：

```cpp
auto p = std::make_unique<T>(args...);
```

而不是到处写：

```cpp
new T(...)
```

---

## 8. unique_ptr 管理数组

如果你需要管理数组，可以写：

```cpp
auto data = std::make_unique<char[]>(size);
```

访问：

```cpp
data[index] = 'A';
std::cout << data[index] << '\n';
```

它会在析构时自动做数组版本释放。

也就是说：

```text
unique_ptr<T>   管理单对象
unique_ptr<T[]> 管理数组
```

对应到你之前的 `Buffer`：

```cpp
class Buffer {
public:
    explicit Buffer(std::size_t size)
        : data_(std::make_unique<char[]>(size)), size_(size) {}

private:
    std::unique_ptr<char[]> data_;
    std::size_t size_;
};
```

这样之后：

```text
你不需要手写析构函数 delete[] data_。
```

因为 `unique_ptr<char[]>` 的析构函数会自动释放数组。

---

## 9. unique_ptr 版本 Buffer 会发生什么变化

如果你把 `char* data_` 改成：

```cpp
std::unique_ptr<char[]> data_;
```

那么默认行为会变成：

```text
不能 copy
可以 move
自动析构释放数组
```

也就是说，这个类天然更接近：

```text
move-only Buffer
```

这很符合很多系统资源类的设计：

```text
资源不能复制，只能转移所有权。
```

比如：

```text
socket fd
file fd
thread
connection
```

很多都不应该随便 copy。

所以 `unique_ptr` 不只是为了少写 `delete`，它更重要的是表达：

```text
这个资源只能有一个 owner。
```

---

## 10. unique_ptr 能不能完全替代裸指针

不能。

更准确地说：

```text
unique_ptr 用来表达 owning pointer。
裸指针仍然可以用来表达 non-owning pointer。
```

比如：

```cpp
void print_value(const int* p) {
    if (p != nullptr) {
        std::cout << *p << '\n';
    }
}
```

这里 `p` 只是借用一下，不负责释放。

也可以从 `unique_ptr` 拿裸指针观察：

```cpp
auto p = std::make_unique<int>(42);
int* raw = p.get();
```

注意：

```text
raw 不能 delete。
raw 只是观察。
p 仍然是 owner。
```

今天先把这条边界记清楚：

```text
owning 用 unique_ptr。
non-owning 可以用裸指针 / 引用。
```

---

# Part C：练习、检查和收尾

## 11. 代码练习 1：unique_ptr 基本使用

文件：

```text
01_unique_ptr_basic.cpp
```

目标：观察 `unique_ptr` 自动析构。

建议写一个类：

```cpp
#include <iostream>
#include <memory>

class Resource {
public:
    explicit Resource(int value) : value_(value) {
        std::cout << "Resource construct " << value_ << '\n';
    }

    ~Resource() {
        std::cout << "Resource destruct " << value_ << '\n';
    }

    int value() const {
        return value_;
    }

private:
    int value_;
};

int main() {
    auto p = std::make_unique<Resource>(42);
    std::cout << p->value() << '\n';
    return 0;
}
```

你要观察：

```text
没有手写 delete，但析构函数仍然执行。
```

编译：

```bash
g++ -std=c++17 -Wall -Wextra -g 01_unique_ptr_basic.cpp -o 01_unique_ptr_basic
./01_unique_ptr_basic
```

---

## 12. 代码练习 2：unique_ptr 不能 copy，可以 move

文件：

```text
02_unique_ptr_move.cpp
```

先写不能 copy 的版本，观察编译错误：

```cpp
auto p1 = std::make_unique<int>(42);
// auto p2 = p1;  // 打开这行，应该编译失败
```

然后写 move：

```cpp
#include <iostream>
#include <memory>
#include <utility>

int main() {
    auto p1 = std::make_unique<int>(42);
    auto p2 = std::move(p1);

    if (p1 == nullptr) {
        std::cout << "p1 is null\n";
    }

    if (p2 != nullptr) {
        std::cout << "p2 value=" << *p2 << '\n';
    }

    return 0;
}
```

你要解释：

```text
p1 move 后为什么变成 nullptr？
p2 为什么能拿到原来的值？
为什么 unique_ptr 禁止 copy？
```

---

## 13. 代码练习 3：unique_ptr 数组 / Buffer

文件：

```text
03_unique_ptr_array_or_buffer.cpp
```

目标：用 `unique_ptr<char[]>` 改写一个简单 Buffer。

建议版本：

```cpp
#include <cstddef>
#include <iostream>
#include <memory>
#include <utility>

class Buffer {
public:
    explicit Buffer(std::size_t size)
        : data_(std::make_unique<char[]>(size)), size_(size) {
        std::cout << "Buffer construct size=" << size_ << '\n';
    }

    void set(std::size_t index, char value) {
        if (index >= size_) {
            return;
        }
        data_[index] = value;
    }

    char get(std::size_t index) const {
        if (index >= size_) {
            return ' ';
        }
        return data_[index];
    }

    std::size_t size() const {
        return size_;
    }

private:
    std::unique_ptr<char[]> data_;
    std::size_t size_;
};

int main() {
    Buffer a(5);
    a.set(0, 'A');
    std::cout << a.get(0) << '\n';

    // Buffer b = a;  // 不能 copy
    Buffer c = std::move(a);  // 可以 move
    std::cout << c.get(0) << '\n';

    return 0;
}
```

这里你会发现：

```text
你没有写析构函数。
你没有写 copy constructor。
你没有写 move constructor。
```

但由于 `unique_ptr` 自己的语义：

```text
Buffer 默认不能 copy。
Buffer 可以 move。
数组资源会自动释放。
```

注意一个很重要的细节：

```text
默认 move 会移动 data_，但 size_ 只是普通整数，会被按值复制。
```

所以：

```cpp
Buffer a(5);
Buffer c = std::move(a);
std::cout << a.size() << " " << c.size() << '\n';
```

很可能输出：

```text
5 5
```

这不是 `unique_ptr` 没有 move，而是：

```text
unique_ptr 成员被 move 了，a.data_ 变空；
size_ 这个普通成员没有被自动置 0。
```

因此，move 后的 `a` 仍然是“有效但不要依赖原内容”的对象。你不应该在业务逻辑里依赖 moved-from 对象的 `size()` 仍然有语义。

如果你希望 `a.size()` 在 move 后变成 0，就需要自己写 move constructor / move assignment，把 `other.size_` 置 0。今天先知道这个边界即可。

这就是现代 C++ 的味道：

```text
成员的所有权语义，会影响整个类的默认行为；
但普通成员的 moved-from 状态仍然要由你设计。
```

如果编译时因为默认 move 构造没有生成而报错，把完整错误贴给我看。今天先不要求你手写这个版本的 move。

---

## 14. 常见错误

### 14.1 试图 copy unique_ptr

错误：

```cpp
auto p2 = p1;
```

原因：

```text
unique_ptr 表示独占所有权，不能 copy。
```

### 14.2 move 后继续解引用原 unique_ptr

危险：

```cpp
auto p2 = std::move(p1);
std::cout << *p1 << '\n';
```

move 后 `p1` 通常是 nullptr。解引用 nullptr 会出问题。

正确做法：

```cpp
if (p1 != nullptr) {
    std::cout << *p1 << '\n';
}
```

### 14.3 对 get() 拿到的裸指针 delete

错误：

```cpp
int* raw = p.get();
delete raw;
```

原因：

```text
raw 只是 non-owning pointer。
p 仍然是 owner。
你 delete raw 会破坏 unique_ptr 的所有权，之后可能 double delete。
```

### 14.4 把 unique_ptr 当 shared_ptr 用

`unique_ptr` 是独占所有权。

如果你发现自己想让很多对象共同拥有同一个资源，Day5 才会学：

```cpp
std::shared_ptr
```

今天不要提前扩展。

---

## 15. 中途检查

写完 `01_unique_ptr_basic.cpp` 后回答：

```text
1. 没有手写 delete，为什么 Resource 仍然析构？
2. unique_ptr 和 RAII 的关系是什么？
```

写完 `02_unique_ptr_move.cpp` 后回答：

```text
1. unique_ptr 为什么不能 copy？
2. unique_ptr 为什么可以 move？
3. move 后原 unique_ptr 大概是什么状态？
```

写完 `03_unique_ptr_array_or_buffer.cpp` 后回答：

```text
1. unique_ptr<char[]> 管理数组时，释放由谁负责？
2. 用 unique_ptr 改写 Buffer 后，你少写了哪些函数？
3. 为什么这个 Buffer 更像 move-only 类型？
```

---

## 16. 面试追问

今天这些问题很常见：

```text
1. unique_ptr 解决了什么问题？
2. unique_ptr 为什么不能拷贝？
3. unique_ptr 为什么可以移动？
4. std::move 一个 unique_ptr 后，原 unique_ptr 是什么状态？
5. make_unique 有什么好处？
6. unique_ptr 和裸指针的区别是什么？
7. 什么时候裸指针仍然可以接受？
8. unique_ptr 和 RAII 的关系是什么？
```

回答模板：

```text
unique_ptr 表达独占所有权。它不能 copy，因为 copy 会导致多个 owner 管同一块资源；它可以 move，因为所有权可以转移。unique_ptr 析构时会自动释放资源，所以它是 RAII 的一种典型应用。
```

---

## 17. 6.S081 / 15-445 关联点

今天不正式开 6.S081 / 15-445。

但 `unique_ptr` 和后面的系统项目非常相关。

以后这些对象常常适合独占所有权：

```text
Connection
Buffer
Task
Timer
LogFile
Fd wrapper
```

很多系统资源不应该随便 copy：

```text
一个 fd 不是复制一个 int 就能复制资源语义。
一个连接对象通常也不该有两个 owner 同时释放。
```

所以 `unique_ptr` 是你后面写 ThreadPool / Reactor / Mini Redis 时会不断遇到的基础工具。

---

## 18. 今天不要提前深挖

今天先不要碰：

```text
shared_ptr 控制块
weak_ptr
enable_shared_from_this
自定义 deleter 深入
unique_ptr 类型大小
allocator
复杂模板实现
所有权图复杂设计
```

Day5 会学 `shared_ptr / weak_ptr`。

今天只把独占所有权打清楚。

---

## 19. 今日笔记要求

`day4_note.md` 建议写这些：

```markdown
# Week2 Day4 Note

## 1. 今天从什么问题出发

## 2. unique_ptr 表达什么所有权

## 3. unique_ptr 为什么不能 copy

## 4. unique_ptr 为什么可以 move

## 5. make_unique 我怎么理解

## 6. unique_ptr 和 RAII 的关系

## 7. 裸指针什么时候还能用

## 8. 今天还不稳的问题
```

最核心一句：

```text
unique_ptr 用类型表达独占所有权：不能 copy，可以 move，析构时自动释放资源。
```

---

## 20. 今日验收问题

```text
1. unique_ptr 解决了什么问题？
2. unique_ptr 表达的是 shared ownership 还是 unique ownership？
3. 为什么 unique_ptr 不能 copy？
4. 为什么 unique_ptr 可以 move？
5. std::move 一个 unique_ptr 后，原 unique_ptr 大概是什么状态？
6. make_unique 的好处是什么？
7. unique_ptr 和 RAII 的关系是什么？
8. 裸指针什么时候仍然可以作为 non-owning pointer 使用？
```

这 8 个问题能答清楚，Day4 就过。

---

## 21. Git commit

如果今天代码和笔记都完成，可以提交：

```bash
cd ~/code/system-learning
git status
git add cpp/week2/day4_unique_ptr
git commit -m "week2 day4 learn unique ptr ownership"
```

如果笔记不在仓库里，只提交代码也可以。

---

## 22. 下一天衔接

Day5 会进入：

```text
shared_ptr
weak_ptr
共享所有权
引用计数
循环引用
```

Day4 的结束标准是：

```text
你能解释 unique_ptr 为什么不能 copy、为什么可以 move，
并且能用它改掉简单资源管理代码里的手写 delete。
```