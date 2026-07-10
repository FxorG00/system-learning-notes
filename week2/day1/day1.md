# Week2 Day1：Rule of Three 复稳 + move 的问题来源

> 今日定位：这是 Week2 的入口，不急着写移动构造。  
> 今天真正要弄清楚的是：Week1 的深拷贝虽然安全，但在某些场景里会显得很贵，于是 C++11 引入了 move 语义来表达“资源转移”。

---

## 0. 今天你要完成什么

今天不是新开一堆语法，而是把 Week1 的资源管理往前推半步。

你今天要做到：

```text
1. 再确认自己能解释 Rule of Three
2. 用打印日志观察 copy constructor / copy assignment / destructor 的调用时机
3. 看见深拷贝的成本：每次 copy 都要重新申请内存、复制数据
4. 建立 move 的动机：有些对象马上就不用了，没必要完整复制资源
5. 知道今天暂时不写 move，先理解为什么需要 move
```

今天的代码目录建议：

```bash
mkdir -p ~/code/system-learning/cpp/week2/day1_rule_three_review
cd ~/code/system-learning/cpp/week2/day1_rule_three_review
```

今天建议写两个文件：

```text
01_deep_copy_cost.cpp
02_return_buffer.cpp
```

默认编译命令：

```bash
g++ -std=c++17 -Wall -Wextra -g 01_deep_copy_cost.cpp -o 01_deep_copy_cost
g++ -std=c++17 -Wall -Wextra -g 02_return_buffer.cpp -o 02_return_buffer
```

如果要看内存问题，也可以加 ASan：

```bash
g++ -std=c++17 -Wall -Wextra -g -fsanitize=address 01_deep_copy_cost.cpp -o 01_deep_copy_cost
```

---

## 1. 前置回顾：Week1 你已经会了什么

你 Week1 已经打过一遍这条链：

```text
裸指针
→ new / delete
→ 构造 / 析构
→ RAII
→ 默认拷贝
→ shallow copy
→ double delete
→ deep copy
→ copy constructor
→ copy assignment
→ self-assignment
→ Rule of Three
```

现在你要把它压成一句话：

```text
只要一个类自己管理资源，比如 char*、int*、FILE*、socket fd，
它就不能随便依赖默认拷贝。
```

因为默认拷贝通常只是成员逐个复制。对裸指针来说，就是复制地址值。

所以：

```text
Buffer a 管理一块内存
Buffer b = a 如果只是复制 data_ 指针
那么 a.data_ 和 b.data_ 指向同一块内存
最后两个析构函数都 delete[] 同一块内存
结果就是 double delete，属于未定义行为
```

Rule of Three 的意义就是：

```text
如果你需要自己写析构函数，通常也要认真考虑：
1. copy constructor
2. copy assignment
3. destructor
```

它不是让你机械背“三个函数”，而是在提醒你：

```text
这个类的资源所有权需要你自己设计。
```

---

## 2. 今天的新直觉：深拷贝安全，但可能很贵

Week1 我们修 double delete 的方式是深拷贝。

深拷贝的做法：

```text
1. 给新对象重新申请一块内存
2. 把旧对象的数据复制过去
3. 两个对象各自管理自己的资源
4. 析构时各删各的，不冲突
```

这当然安全。

但是问题来了：如果资源很大呢？

比如：

```text
Buffer a 管理 100 MB 内存
Buffer b = a
```

深拷贝就意味着：

```text
重新 new 100 MB
再复制 100 MB
```

如果这个复制是你真的需要的，那没问题。

但有些场景里，对象只是临时中转一下，马上就不用了。比如函数返回一个临时 Buffer：

```cpp
Buffer make_buffer() {
    Buffer tmp(1000000);
    return tmp;
}

Buffer b = make_buffer();
```

从直觉上说：

```text
tmp 马上就要死了。
它手里那块内存能不能直接交给 b？
为什么还要复制一整份？
```

这就是 move 语义的动机。

今天先不写 move。你只需要先建立这句话：

```text
copy 是复制资源。
move 是转移资源。
```

---

## 3. 必要术语，先轻拿轻放

今天会遇到几个词，不需要钻太深，但要先会说。

### 3.1 copy

copy 是复制一个对象的值。

对资源类来说，正确的 copy 往往意味着深拷贝：

```text
新对象拿到一份独立资源。
```

### 3.2 move

move 是把资源从一个对象转移到另一个对象。

注意：

```text
move 不是把内存里的每个字节搬一遍。
它通常只是转移资源句柄，比如指针、fd、handle。
```

例如一个 Buffer 内部有：

```cpp
char* data_;
std::size_t size_;
```

move 的直觉就是：

```text
新对象接管 data_
旧对象不再拥有 data_
旧对象进入一个还能安全析构的状态
```

### 3.3 临时对象

临时对象就是表达式中短暂存在、很快要被销毁的对象。

比如：

```cpp
Buffer b = make_buffer();
```

`make_buffer()` 的返回值就可能涉及临时对象。

### 3.4 所有权转移

所有权转移就是：

```text
资源原来归 A 管
现在归 B 管
A 不再释放这块资源
B 负责释放这块资源
```

这和深拷贝完全不同。

深拷贝是：

```text
A 有一份，B 也有一份。
```

移动是：

```text
A 把手里的那一份交给 B。
```

---

## 4. 代码练习 1：观察深拷贝成本

文件：

```text
01_deep_copy_cost.cpp
```

目标：写一个带打印日志的 Buffer，观察深拷贝发生在哪里。

### 4.1 你要写的类

要求：

```text
1. Buffer 管理一块 char 数组
2. 构造函数申请内存
3. 析构函数释放内存
4. 拷贝构造做深拷贝
5. 拷贝赋值做深拷贝
6. 每个关键函数都打印一句日志
7. 提供 set / get / size
```

建议打印格式：

```text
construct size=5
copy construct size=5
copy assignment size=5
destruct size=5
```

你可以沿用 Day6 的 Buffer，但这次重点不是再证明深拷贝正确，而是观察：

```text
哪里发生了 copy？
copy 的时候做了什么成本动作？
```

### 4.2 建议代码骨架

你可以自己写，也可以按这个结构写：

```cpp
#include <cstddef>
#include <iostream>

class Buffer {
public:
    explicit Buffer(std::size_t size)
        : data_(new char[size]), size_(size) {
        std::cout << "construct size=" << size_ << '\n';
    }

    Buffer(const Buffer& other)
        : data_(new char[other.size_]), size_(other.size_) {
        std::cout << "copy construct size=" << size_ << '\n';
        for (std::size_t i = 0; i < size_; ++i) {
            data_[i] = other.data_[i];
        }
    }

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

    ~Buffer() {
        std::cout << "destruct size=" << size_ << '\n';
        delete[] data_;
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
    char* data_;
    std::size_t size_;
};
```

### 4.3 main 里要测什么

你至少测这几个场景：

```cpp
int main() {
    Buffer a(5);
    a.set(2, 'x');

    Buffer b = a;
    std::cout << "a[2]=" << a.get(2) << " b[2]=" << b.get(2) << '\n';

    Buffer c(3);
    c = a;
    std::cout << "c[2]=" << c.get(2) << '\n';

    a = a;
    return 0;
}
```

你要观察：

```text
Buffer b = a 调用了什么？
c = a 调用了什么？
a = a 会不会炸？
每个对象什么时候析构？
```

### 4.4 写完后的解释要求

运行后，你在 note 里写这几句话：

```text
1. copy constructor 在什么时候调用？
2. copy assignment 在什么时候调用？
3. deep copy 里做了哪些动作？
4. 为什么 self-assignment 要单独处理？
5. 这个程序里一共发生了几次资源申请？
```

最后一题很重要。你要开始对 `new/delete` 的次数敏感。

---

## 5. 代码练习 2：函数返回对象时发生了什么

文件：

```text
02_return_buffer.cpp
```

目标：观察函数返回 `Buffer` 时，构造 / 拷贝 / 析构日志怎么变化。

### 5.1 先写一个返回 Buffer 的函数

```cpp
Buffer make_buffer(std::size_t size) {
    Buffer tmp(size);
    tmp.set(0, 'A');
    return tmp;
}
```

然后 main 里写：

```cpp
int main() {
    Buffer b = make_buffer(10);
    std::cout << b.get(0) << '\n';
    return 0;
}
```

你可能会发现一个有意思的现象：

```text
日志里不一定出现 copy construct。
```

这不是你写错了。

现代编译器会做返回值优化，也就是 RVO / NRVO。它可能直接在目标位置构造对象，省掉中间拷贝。

今天你不需要深挖优化规则，只要知道：

```text
编译器有时会帮你省掉 copy。
但 C++ 仍然需要一套语言机制，表达“这个对象的资源可以被转移”。
这就是 move 语义存在的理由之一。
```

### 5.2 尝试关闭拷贝省略观察

如果你想更直观看到 copy，可以试试这个编译参数：

```bash
g++ -std=c++17 -Wall -Wextra -g -fno-elide-constructors 02_return_buffer.cpp -o 02_return_buffer
```

注意：

```text
这个参数只是为了观察，不是平时写代码必须加。
```

如果你看到 copy constructor 出现了，就思考：

```text
如果 Buffer 很大，这次 copy 要付出什么成本？
```

### 5.3 今天对 RVO 的掌握程度

只要求会这样说：

```text
RVO / NRVO 是编译器优化返回对象的一种方式，可以省掉不必要的拷贝。
但我不能把资源管理设计完全寄托在优化上。
move 语义是语言层面表达资源转移的机制。
```

不要求今天背标准细节。

---

## 6. 今天不写 move，但要想清楚 move 要怎么修这个问题

假设现在有一个临时对象：

```cpp
Buffer tmp(1000000);
```

它马上要被用来构造另一个对象，然后自己就结束生命周期。

深拷贝做的是：

```text
new 一块同样大小的内存
复制 tmp.data_ 指向的数据
新对象管理新内存
tmp 继续管理旧内存
tmp 析构时释放旧内存
```

move 想做的是：

```text
新对象直接拿走 tmp.data_
新对象 size_ = tmp.size_
tmp.data_ = nullptr
tmp.size_ = 0
tmp 析构时 delete[] nullptr，安全
```

也就是说：

```text
copy 的核心是复制内容。
move 的核心是转移所有权。
```

今天你先不要急着写这段代码，因为 Day2 会正式写移动构造函数。

今天你只要能解释：

```text
为什么 move 后旧对象必须被置成一个安全状态？
```

答案是：

```text
因为旧对象依然会析构。
如果旧对象还保留原来的 data_，它析构时就会 delete[] 那块已经交给新对象的内存，结果还是 double delete。
```

这就是 Day2 的关键点。

---

## 7. 中途检查

写完 `01_deep_copy_cost.cpp` 后，先停一下，回答：

```text
1. Buffer b = a 调用 copy constructor 还是 copy assignment？
2. c = a 调用 copy constructor 还是 copy assignment？
3. copy assignment 里为什么不能先 delete[] data_ 再读 other.data_？
4. a = a 如果没有 self-assignment 检查，会发生什么风险？
```

写完 `02_return_buffer.cpp` 后，再回答：

```text
1. make_buffer 里 tmp 是栈对象还是堆对象？
2. tmp 离开函数时会不会析构？
3. 为什么日志里可能看不到 copy constructor？
4. 如果强行看到 copy，这个 copy 的成本是什么？
```

你答不出来的地方，不要急着继续写 Day2，先把今天的链条补稳。

---

## 8. 面试追问

今天的内容很容易被面试官这样追：

```text
1. Rule of Three 是什么？
2. 为什么有析构函数，通常也要考虑拷贝构造和拷贝赋值？
3. 深拷贝解决了什么问题？
4. 深拷贝有什么代价？
5. 函数返回大对象一定会拷贝吗？
6. RVO / NRVO 大概是什么？
7. move 语义想解决什么问题？
8. move 和 copy 的本质区别是什么？
```

你的回答不需要花哨。可以这样组织：

```text
copy 是复制资源，两个对象各自拥有一份资源。
move 是转移资源，旧对象把资源交给新对象，自己进入可析构的安全状态。
深拷贝能避免 double delete，但如果资源很大，复制成本可能很高。
move 语义就是为了避免某些不必要的深拷贝，尤其是临时对象和所有权转移场景。
```

---

## 9. 6.S081 / 15-445 关联点

今天不正式开 6.S081，也不开 15-445。

但你可以先记一个系统工程方向的影子：

```text
C++ 对象里的资源不一定只是内存。
以后可能是：
- file descriptor
- socket fd
- mutex 相关资源
- thread
- mmap 出来的内存
- 日志文件句柄
- 网络连接对象
```

这些资源很多都不适合随便 copy。

比如一个 socket fd：

```text
复制一个 int fd 并不等于复制了一个网络连接。
```

所以后面你会越来越常见到：

```text
禁止拷贝
允许移动
用 RAII 管理资源
```

这就是 Week2 和后面 Linux / Reactor / ThreadPool 的连接点。

---

## 10. 今天不要提前深挖

今天先不要碰：

```text
完美转发
万能引用
引用折叠
std::forward
移动迭代器
allocator
shared_ptr 控制块
复杂 noexcept 规则
```

这些不是现在的主线。

今天只把这件事看清：

```text
深拷贝安全，但有成本。
move 语义是为资源转移服务的。
```

---

## 11. 今日笔记要求

你的 `day1_note.md` 可以不用很长，但至少写这几块：

```markdown
# Week2 Day1 Note

## 1. Rule of Three 我怎么理解

## 2. deep copy 解决了什么问题

## 3. deep copy 为什么可能贵

## 4. 函数返回 Buffer 时我观察到了什么

## 5. RVO / NRVO 我现在的理解

## 6. copy 和 move 的区别，我现在怎么说

## 7. 今天还不稳的问题
```

如果你只写一句最核心的总结，我希望是这句：

```text
copy 是复制资源，move 是转移资源；move 的前提是被移动对象之后仍然能安全析构。
```

---

## 12. 今日验收问题

做完代码后回答：

```text
1. 深拷贝解决了什么问题？
2. 深拷贝为什么可能有性能成本？
3. copy constructor 和 copy assignment 的区别是什么？
4. 如果一个临时 Buffer 马上要销毁，为什么还完整复制一份资源显得浪费？
5. move 语义大概要解决什么问题？
6. move 后旧对象为什么不能继续拥有原资源？
7. 函数返回对象时，为什么不一定能看到 copy constructor？
8. RVO / NRVO 今天只需要理解到什么程度？
```

这 8 个问题答清楚，Day1 就过。

---

## 13. Git commit

如果今天代码和笔记都完成，可以提交一次：

```bash
cd ~/code/system-learning
git status
git add cpp/week2/day1_rule_three_review
git commit -m "week2 day1 review rule of three and copy cost"
```

如果你还没有把笔记放进仓库，也可以只提交代码。不要为了提交而乱移动笔记。

---

## 14. 下一天衔接

Day2 会正式进入：

```text
移动构造函数
std::move
右值引用初步
move 后对象的安全状态
```

Day2 的核心会是写出这个能力：

```text
Buffer b = std::move(a);
```

并且你要能解释：

```text
std::move 本身不移动资源。
真正移动资源的是移动构造函数 / 移动赋值函数。
```

所以 Day1 的结束标准不是“会写 move”，而是：

```text
你已经知道为什么 C++ 需要 move。
```