﻿﻿# Week2 Day6：异常安全初步 + copy-and-swap

> 今日定位：Week2 最后一块核心内容。  
> 前面你已经学了 copy / move / unique_ptr / shared_ptr / weak_ptr。今天要补上一个工程里很重要的问题：**代码执行到一半出错了，资源会不会泄漏？对象会不会坏掉？**

---

## Part A：前情提要和术语

### 1. 前情提要：从生命周期到异常路径

Week2 到现在，你已经在处理这些问题：

```text
copy：资源要不要复制一份？
move：资源能不能直接转移？
unique_ptr：谁独占资源？
shared_ptr：谁共同决定资源生命周期？
weak_ptr：谁只是观察，不参与生命周期？
```

今天换一个角度：

```text
如果函数执行到一半失败了，前面已经创建的对象怎么办？
```

比如：

```cpp
void f() {
    Buffer a(10);
    Buffer b(20);
    throw std::runtime_error("bad");
}
```

问题不是 `throw` 语法本身，而是：

```text
a / b 会不会析构？
它们管理的资源会不会释放？
如果 copy assignment 写到一半失败，对象会不会进入坏状态？
```

这就是 Day6 的核心。

---

### 2. 今日术语

#### exception：异常

异常就是一种“当前函数处理不了这个错误，先把错误往外抛”的机制。

最小形式：

```cpp
throw std::runtime_error("something wrong");
```

外层用：

```cpp
try {
    may_throw();
} catch (const std::exception& e) {
    std::cout << e.what() << '\n';
}
```

今天只学这个最小用法，不展开异常类型体系。

---

#### stack unwinding：栈展开

当一个函数里 `throw` 之后，程序会沿着函数调用栈往外找 `catch`。

**在离开每一层函数之前，C++ 会把已经构造成功的局部对象析构掉。**

所以你可以先记成：

```text
throw 不是直接瞬移走。
它离开作用域时，局部对象仍然会按规则析构。
```

这个过程就叫栈展开。

---

#### RAII 和异常安全

RAII 的核心是：

```text
资源放进对象里。
构造函数拿资源。
析构函数放资源。
```

它和异常安全天然搭在一起，因为：

```text
异常发生时，局部对象会析构。
局部对象析构时，资源会释放。
```

所以 RAII 不是只为“正常 return”服务，它更重要的是覆盖：

```text
提前 return
中途 throw
函数多出口
复杂控制流
```

---

#### exception safety：异常安全

异常安全问的是：

```text
如果代码中途抛异常，程序还能保持合理状态吗？
```

今天只建立两层直觉：

```text
基本异常安全：不泄漏资源，对象还能析构，程序状态不炸。
强异常安全：要么操作成功，要么对象保持操作前的状态。
```

不要现在去背复杂分类，先把直觉抓住。

---

#### copy-and-swap

copy-and-swap 是一种写 copy assignment 的套路：

```text
先复制出一个临时对象。
复制成功后，再和当前对象交换资源。
临时对象离开作用域时，自动释放当前对象的旧资源。
```

它解决的核心问题是：

```text
不要一上来就 delete 当前对象的旧资源。
先把新资源准备好，再替换。
```

这和你之前写 copy assignment 时的原则是一脉相承的：

```text
先 new 新资源
再 delete 旧资源
```

copy-and-swap 是这个原则的更整齐版本。

---

### 3. 今天先别深挖

今天不讲：

```text
复杂异常类型设计
noexcept 传播规则
标准库完整异常保证
异常和性能的深入讨论
placement new
allocator
```

今天只解决一个工程底座问题：

```text
异常发生时，资源不泄漏；赋值失败时，对象不要坏掉。
```

---

## Part B：教程主体

### 1. 今天从什么问题出发？

今天的问题是：

```text
copy assignment 写到一半失败了，对象还能不能保持原来的样子？
```

你之前已经知道，一个管理 `char*` 的 `Buffer`，赋值时不能简单浅拷贝。于是我们会写深拷贝赋值：

```cpp
Buffer& operator=(const Buffer& other) {
    if (this == &temp) {
        return *this;
    }

    char* new_data = new char[other.size_];
    // copy data
    delete[] data_;
    data_ = new_data;
    size_ = other.size_;
    return *this;
}
```

这个版本的关键优点是：

```text
先 new 成功，再 delete 旧资源。
```

但如果有人写成：

```cpp
delete[] data_;
data_ = new char[other.size_];
```

问题就来了：

```text
如果 new 失败抛异常，旧资源已经没了。
这个对象可能处于半坏状态。
```

Day6 就是要把这个风险讲清楚，并写一个更稳的版本。

---

### 2. 先观察：throw 时局部对象会析构

文件：

```text
01_exception_raii.cpp
```

代码：

```cpp
#include <iostream>
#include <stdexcept>

class Tracer {
public:
    explicit Tracer(const char* name) : name_(name) {
        std::cout << "construct " << name_ << '\n';
    }

    ~Tracer() {
        std::cout << "destruct " << name_ << '\n';
    }

private:
    const char* name_;
};

void work() {
    Tracer a("a");
    Tracer b("b");

    std::cout << "before throw\n";
    throw std::runtime_error("work failed");

    std::cout << "after throw\n";
}

int main() {
    try {
        work();
    } catch (const std::exception& e) {
        std::cout << "catch: " << e.what() << '\n';
    }

    return 0;
}
```

你应该观察到：

```text
construct a
construct b
before throw
destruct b
destruct a
catch: work failed
```

注意两个点：

```text
1. after throw 不会执行。
2. b / a 仍然析构，而且析构顺序和构造顺序相反。
```

这就是 RAII 在异常路径下可靠的根基。

---

### 3. 为什么异常路径下 RAII 很重要？

如果你手写这种代码：

```cpp
char* p = new char[100];
may_throw();
delete[] p;
```

如果 `may_throw()` 抛异常，后面的 `delete[] p` 不会执行。

这就可能泄漏。

但如果你写成对象：

```cpp
Buffer buf(100);
may_throw();
```

只要 `Buffer` 的析构函数写对了：

```cpp
~Buffer() {
    delete[] data_;
}
```

那么异常发生时，`buf` 会被析构，资源会被释放。

再往现代 C++ 走，就是：

```cpp
auto p = std::make_unique<char[]>(100);
may_throw();
```

`unique_ptr` 也是 RAII 对象，所以异常时也会自动释放。

今天你要把这个链条说顺：

```text
throw
→ 栈展开
→ 局部对象析构
→ RAII 析构释放资源
→ 异常路径不泄漏
```

---

### 4. 先 delete 再 new 的赋值风险

文件：

```text
02_bad_assignment_exception_risk.cpp
```

这个 demo 不追求写一个“故意炸掉程序”的坏代码，而是模拟一个赋值到一半失败的场景。

代码：

```cpp
#include <cstddef>
#include <iostream>
#include <stdexcept>

class BadBuffer {
public:
    explicit BadBuffer(std::size_t size)
        : data_(new char[size]), size_(size) {
        for (std::size_t i = 0; i < size_; ++i) {
            data_[i] = '?';
        }
    }

    BadBuffer(const BadBuffer& other)
        : data_(new char[other.size_]), size_(other.size_) {
        for (std::size_t i = 0; i < size_; ++i) {
            data_[i] = other.data_[i];
        }
    }

    ~BadBuffer() {
        delete[] data_;
    }

    void set(std::size_t index, char value) {
        if (index < size_) {
            data_[index] = value;
        }
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

    void assign_bad(const BadBuffer& other, bool simulate_fail) {
        delete[] data_;
        data_ = nullptr;
        size_ = 0;

        if (simulate_fail) {
            throw std::runtime_error("simulate allocation failed");
        }

        data_ = new char[other.size_];
        size_ = other.size_;
        for (std::size_t i = 0; i < size_; ++i) {
            data_[i] = other.data_[i];
        }
    }

private:
    char* data_;
    std::size_t size_;
};

int main() {
    BadBuffer a(3);
    a.set(0, 'A');

    BadBuffer b(5);
    b.set(0, 'B');

    try {
        a.assign_bad(b, true);
    } catch (const std::exception& e) {
        std::cout << "catch: " << e.what() << '\n';
    }

    std::cout << "a size after failed assignment=" << a.size() << '\n';
    std::cout << "a[0] after failed assignment='" << a.get(0) << "'\n";

    return 0;
}
```

你要观察：

```text
赋值失败后，a 原来的内容没了。
a 从 size=3 变成 size=0。
```

这说明：

```text
对象虽然还能析构，没有 double free。
但它没有保持赋值前的状态。
```

这就是“先 delete 再准备新资源”的问题。

---

### 5. copy-and-swap 的核心思路

现在写一个更稳的版本。

先看一个更直白的写法：

```cpp
Buffer& operator=(const Buffer& rhs) {
    Buffer temp(rhs);  // 1. 先拷贝出一个临时对象
    swap(temp);        // 2. 拷贝成功后，再交换资源
    return *this;      // 3. temp 离开作用域，析构时释放旧资源
}
```

这三行就是 copy-and-swap 的完整动作。

如果 `Buffer temp(rhs)` 这一步失败，比如里面 `new char[...]` 抛异常，那么：

```text
swap(temp) 根本不会执行。
当前对象完全没有被动过。
```

如果 `Buffer temp(rhs)` 成功，那么：

```text
当前对象和 temp 交换资源。
当前对象拿到新资源。
temp 拿到当前对象原来的旧资源。
函数结束时 temp 析构，旧资源被释放。
```

所以 copy-and-swap 的核心不是“只 swap 一下”，而是：

```text
先把新资源完整准备到临时对象里。
准备成功后，再用一次 noexcept swap 替换当前对象状态。
旧资源交给临时对象析构释放。
```

你后面还会看到一个更短的写法：

```cpp
Buffer& operator=(Buffer temp) {
    swap(temp);
    return *this;
}
```

这个版本看起来函数体里只有 `swap(temp)`，但它不是少了 assign。

真正的 assign 过程藏在这里：

```text
Buffer temp 这个按值参数，会在进入函数体之前由 rhs 拷贝构造出来。
```

也就是说，当你写：

```cpp
a = b;
```

调用过程可以理解成：

```text
1. 用 b 拷贝构造出参数 temp。
2. 如果拷贝失败，operator= 函数体进不去，a 没变化。
3. 如果拷贝成功，进入 operator=。
4. swap(temp)，a 拿到 temp 的新资源。
5. temp 拿到 a 的旧资源。
6. operator= 结束，temp 析构，释放旧资源。
```

所以：

```text
Buffer& operator=(Buffer temp)
```

是 copy-and-swap 的简写版本；为了你今天理解清楚，下面代码会把参数名字写成 `temp`，不写成 `other`。

---
### 6. copy-and-swap 最小 Buffer

文件：

```text
03_copy_and_swap.cpp
```

代码：

```cpp
#include <cstddef>
#include <iostream>
#include <utility>

class Buffer {
public:
    explicit Buffer(std::size_t size)
        : data_(new char[size]), size_(size) {
        for (std::size_t i = 0; i < size_; ++i) {
            data_[i] = '?';
        }
    }

    Buffer(const Buffer& other)
        : data_(new char[other.size_]), size_(other.size_) {
        std::cout << "copy construct\n";
        for (std::size_t i = 0; i < size_; ++i) {
            data_[i] = other.data_[i];
        }
    }

    Buffer& operator=(Buffer other) {
        std::cout << "copy assignment by copy-and-swap\n";
        swap(other);
        return *this;
    }

    ~Buffer() {
        delete[] data_;
    }

    void swap(Buffer& other) noexcept {
        std::swap(data_, other.data_);
        std::swap(size_, other.size_);
    }

    void set(std::size_t index, char value) {
        if (index < size_) {
            data_[index] = value;
        }
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

int main() {
    Buffer a(3);
    a.set(0, 'A');

    Buffer b(5);
    b.set(0, 'B');

    a = b;
    std::cout << "a[0]=" << a.get(0) << " size=" << a.size() << '\n';

    a = a;
    std::cout << "after self assignment a[0]=" << a.get(0) << " size=" << a.size() << '\n';

    return 0;
}
```

你要观察：

```text
a = b 会先 copy construct 出参数 temp
然后 swap
temp 拿到 a 的旧资源
最后 temp 析构，把 a 的旧资源释放掉
```

这里 `a = a` 也能工作，因为：

```text
先从 a 拷贝出一个临时 temp
再和 temp swap
最后 temp 析构旧资源
```

所以 copy-and-swap 通常不需要手写自赋值检查。

不过你要知道：

```text
它会多一次临时对象和 swap，代码更稳但不一定永远最省性能。
```

今天先要它的稳定性，不追性能细节。

---

### 7. free swap 版本：先了解，不强求

以后你可能会看到这种写法：

```cpp
friend void swap(Buffer& a, Buffer& b) noexcept {
    using std::swap;
    swap(a.data_, b.data_);
    swap(a.size_, b.size_);
}
```

然后赋值写成：

```cpp
Buffer& operator=(Buffer other) {
    swap(*this, other);
    return *this;
}
```

今天你不必须这么写。你写成员函数版本：

```cpp
void swap(Buffer& other) noexcept
```

已经够了。

---

### 8. 今天和智能指针的关系

你可能会问：

```text
既然有 unique_ptr，为什么还学 copy-and-swap？
```

因为：

```text
1. 你要理解旧式资源类为什么容易错。
2. 面试会问 copy assignment 的异常安全。
3. 后面读一些 C++ 项目代码时，会看到类似套路。
4. 即使用智能指针，也要理解“先准备成功，再替换旧状态”的思想。
```

现代 C++ 会让你少写很多 `new/delete`，但不会替你思考对象状态。

今天真正要带走的是：

```text
异常安全不是语法点，而是工程代码在失败路径下仍然可靠。
```

---

## Part C：练习、检查和收尾

### 1. 今日代码目录

建议放在 Ubuntu：

```bash
~/code/system-learning/cpp/week2/day6
```

今天写三个文件：

```text
01_exception_raii.cpp
02_bad_assignment_exception_risk.cpp
03_copy_and_swap.cpp
```

每个 demo 都要：

```text
能编译
能运行
能解释输出
```

---

### 2. 编译命令

每个文件都用：

```bash
g++ -std=c++17 -Wall -Wextra -g 文件名.cpp -o r
./r
```

建议至少一个文件加 ASan 跑一下：

```bash
g++ -std=c++17 -Wall -Wextra -g -fsanitize=address 03_copy_and_swap.cpp -o r
./r
```

---

### 3. 练习一：异常时局部对象析构

文件：

```text
01_exception_raii.cpp
```

要求：

```text
1. 写 Tracer 类，构造 / 析构都打印
2. 在函数里创建两个 Tracer
3. 中途 throw
4. main 里 catch
5. 解释为什么 throw 后析构仍然发生
```

你必须能说清：

```text
这是栈展开导致的。
```

---

### 4. 练习二：坏赋值的异常风险

文件：

```text
02_bad_assignment_exception_risk.cpp
```

要求：

```text
1. 写一个 BadBuffer
2. 模拟先 delete 旧资源，再发生异常
3. catch 后观察对象状态
4. note 里解释它为什么不够稳
```

重点不是让程序崩，而是观察：

```text
赋值失败后，原对象的旧状态已经丢了。
```

---

### 5. 练习三：copy-and-swap

文件：

```text
03_copy_and_swap.cpp
```

要求：

```text
1. 写 Buffer
2. 析构释放 char[]
3. 拷贝构造深拷贝
4. 赋值运算符用 copy-and-swap
5. 测 a = b
6. 测 a = a
7. 能解释旧资源什么时候释放
```

今天不要求写 move 版本。你如果想写，也可以，但不要让它抢主线。

---

### 6. day6_note.md 要写什么

建议放在：

```text
C:\Users\FxorG\Desktop\gpt_infra\week2\day6\day6_note.md
```

建议结构：

```markdown
# Day6 Note

## 今天的问题
- copy assignment 写到一半失败，对象会怎样？

## stack unwinding
- ...

## RAII 为什么能处理异常路径
- ...

## 先 delete 再 new 的风险
- ...

## copy-and-swap
- ...

## 我写的代码现象
- 01 输出：...
- 02 输出：...
- 03 输出：...

## 验收问题
- ...

## 我还没想明白的问题
- ...
```

---

### 7. 今日验收问题

写完后，用自己的话回答：

```text
1. throw 之后，当前作用域里已经构造好的局部对象会不会析构？
2. 什么是栈展开？
3. RAII 为什么能保证异常路径下资源释放？
4. 为什么裸 new 后面如果发生 throw，可能导致 delete 执行不到？
5. copy assignment 里先 delete 再 new 的风险是什么？
6. copy-and-swap 的核心步骤是什么？
7. copy-and-swap 为什么能处理 self-assignment？
8. copy-and-swap 为什么更容易提供强异常安全直觉？
9. 析构函数里应不应该主动 throw？为什么？
```

第 9 个问题先答直觉版即可：

```text
析构函数里最好不要 throw。尤其在异常传播过程中，析构再抛异常会让程序直接终止。
```

---

### 8. 面试追问

今天的内容很容易被问成：

```text
1. RAII 和异常安全有什么关系？
2. C++ 异常发生时局部对象会发生什么？
3. copy assignment 怎么写才异常安全？
4. copy-and-swap 是什么？
5. 强异常安全是什么意思？
```

你不用背定义。你要能讲出这条线：

```text
资源交给对象管理
异常时栈展开会析构局部对象
析构释放资源
赋值时先准备新资源再替换旧资源
copy-and-swap 把这个流程整理成固定写法
```

---

### 9. 6.S081 / 15-445 关联点

今天不正式开 6.S081 / 15-445。

只做一个很轻的连接：

```text
系统代码里错误路径很多。
资源释放不能只考虑正常路径。
后面 Linux fd、socket、mutex、thread 都需要 RAII 思想兜住异常 / 提前返回 / 多出口。
```

等进入 Linux 后，你会把这个思想迁移到：

```text
file descriptor
socket
mutex lock
thread join
```

---

### 10. 今天不要提前深挖

不要展开：

```text
异常类型继承体系
noexcept 复杂规则
标准库容器完整异常保证
allocator
placement new
事务性编程
```

今天目标很窄：

```text
能解释栈展开。
能解释 RAII 为什么异常时也释放资源。
能写 copy-and-swap 的 Buffer。
```

---

### 11. git commit 建议

```bash
cd ~/code/system-learning
git status
git add cpp/week2/day6
git commit -m "week2 day6 exception safety copy and swap"
```

---

### 12. 下一天衔接

Day7 是 Week2 复盘，不急着开 STL。

Day7 要检查：

```text
copy / move 区别
std::move 本身做了什么
move 后对象状态
Rule of Five
unique_ptr / shared_ptr / weak_ptr
异常时 RAII
copy-and-swap
是否可以进入 Week3 STL
```

如果 Day6 的异常安全不稳，就先补半天，再进入 Week3。这里是 C++ 工程代码的地基，值得压稳。



