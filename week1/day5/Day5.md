# Day5：拷贝构造、拷贝赋值、浅拷贝、深拷贝

> Day5 目标：接着 Day4 的 `IntBuffer` 往下走。  
> Day4 你已经知道：`IntBuffer` 里面有一个 `int* data_`，构造函数里 `new[]`，析构函数里 `delete[]`。  
> 现在问题来了：  
> **如果这个对象被复制，会发生什么？**

今天你要把这几个词真正搞懂：

```text
copy constructor，拷贝构造函数
copy assignment operator，拷贝赋值运算符
shallow copy，浅拷贝
deep copy，深拷贝
self-assignment，自赋值
Rule of Three，三法则
```

Day4 你为了避免出事，先写了：

```cpp
IntBuffer(const IntBuffer&) = delete;
IntBuffer& operator=(const IntBuffer&) = delete;
```

Day5 就是解释：

```text
为什么要禁？
如果不禁，会炸在哪里？
如果想允许拷贝，应该怎么正确写？
```

---

## 0. 今天要拿下什么

做完 Day5，你应该能做到：

```text
1. 区分“拷贝构造”和“拷贝赋值”
2. 知道默认拷贝是成员逐个拷贝
3. 理解浅拷贝为什么会导致 double delete
4. 理解深拷贝为什么能解决问题
5. 能自己写 copy constructor
6. 能自己写 copy assignment operator
7. 知道为什么赋值运算符要返回 *this
8. 知道为什么要处理 self-assignment
9. 初步理解 Rule of Three
```

今天的过关标准：

```text
看到 IntBuffer a(5); IntBuffer b = a; 能解释发生了什么。
看到 b = a; 能解释和上一句有什么不同。
能说清楚浅拷贝和深拷贝的区别。
能写出一个不会 double delete 的 IntBuffer。
```

---

## 1. 今天代码放哪里

代码仍然放 Ubuntu：

```bash
cd ~/code/system-learning/cpp/week1
mkdir -p day5
cd day5
```

建议今天写 5 个程序：

```text
day5/
├── 01_default_copy_simple.cpp
├── 02_bad_shallow_copy.cpp
├── 03_deep_copy_constructor.cpp
├── 04_copy_assignment.cpp
└── 05_rule_of_three_buffer.cpp
```

普通编译命令：

```bash
g++ -std=c++17 -Wall -Wextra -g 文件名.cpp -o 输出名
```

今天有一个故意写坏的程序，建议用 AddressSanitizer 观察：

```bash
g++ -std=c++17 -Wall -Wextra -g -fsanitize=address 02_bad_shallow_copy.cpp -o 02_bad_shallow_copy
```

`-fsanitize=address` 可以帮你抓内存错误。今天只是初步用一下，不深挖。

---

# 第一部分：什么是拷贝

## 2. 普通对象的拷贝通常没问题

先看一个没那么危险的类：

```cpp
class User {
public:
    User(const std::string& name, int age)
        : name_(name), age_(age) {}

private:
    std::string name_;
    int age_;
};
```

如果你写：

```cpp
User a("fxor", 18);
User b = a;
```

这叫拷贝。

此时默认行为大概是：

```text
b.name_ = a.name_
b.age_ = a.age_
```

这里一般没问题，因为：

```text
std::string 自己已经会管理内部资源
int 本身就是普通值
```

也就是说，默认拷贝不是永远有问题。

真正危险的是：

```text
你的类里有“自己管理的裸资源”
```

比如 Day4 的：

```cpp
int* data_;
```

如果一个类里有这种需要自己 `delete` 的指针，默认拷贝就很危险。

---

## 3. 写代码看普通拷贝

创建文件：

```bash
touch 01_default_copy_simple.cpp
```

写入：

```cpp
#include <iostream>
#include <string>

class User {
public:
    User(const std::string& name, int age)
        : name_(name), age_(age) {}

    void print() const {
        std::cout << "name = " << name_
                  << ", age = " << age_ << std::endl;
    }

    void set_age(int age) {
        age_ = age;
    }

private:
    std::string name_;
    int age_;
};

int main() {
    User a("fxor", 18);

    User b = a;  // 拷贝构造：用 a 创建一个新对象 b

    b.set_age(20);

    std::cout << "a: ";
    a.print();

    std::cout << "b: ";
    b.print();

    return 0;
}
```

编译运行：

```bash
g++ -std=c++17 -Wall -Wextra -g 01_default_copy_simple.cpp -o 01_default_copy_simple
./01_default_copy_simple
```

你要观察：

```text
改 b 的 age，不会影响 a。
```

这一小节先记住：

```text
默认拷贝 = 成员逐个拷贝。
普通值成员通常没问题。
自己管理裸资源时，默认拷贝可能出大事。
```

---

# 第二部分：拷贝构造 vs 拷贝赋值

## 4. 两句话看区别

这两句很像，但不是一回事：

```cpp
IntBuffer b = a;
b = a;
```

第一句：

```cpp
IntBuffer b = a;
```

意思是：

```text
用已有对象 a 创建一个新对象 b。
```

这叫：

```text
copy constructor，拷贝构造函数
```

第二句：

```cpp
b = a;
```

意思是：

```text
b 已经存在了，现在把 a 的内容赋给 b。
```

这叫：

```text
copy assignment operator，拷贝赋值运算符
```

区别非常重要：

```text
拷贝构造：新对象还没出生，用别人来初始化它。
拷贝赋值：对象已经活着，把它原来的内容替换成别人的内容。
```

---

## 5. 语法长什么样

拷贝构造函数：

```cpp
IntBuffer(const IntBuffer& other)
```

读法：

```text
用另一个 IntBuffer 来构造当前 IntBuffer。
```

为什么参数是 `const IntBuffer&`？

```text
const：不会修改 other
&：避免为了拷贝而再次拷贝
```

拷贝赋值运算符：

```cpp
IntBuffer& operator=(const IntBuffer& other)
```

读法：

```text
把 other 赋值给当前对象。
```

为什么返回 `IntBuffer&`？

因为 C++ 允许链式赋值：

```cpp
a = b = c;
```

所以 `b = c` 做完后，要返回 `b` 自己，才能继续给 `a` 赋值。

常见写法：

```cpp
return *this;
```

`this` 是指向当前对象的指针，所以 `*this` 就是当前对象本身。

---

# 第三部分：浅拷贝为什么会炸

## 6. Day4 的 IntBuffer 如果允许默认拷贝

Day4 你写过类似这个类：

```cpp
class IntBuffer {
public:
    explicit IntBuffer(std::size_t size)
        : size_(size), data_(new int[size]) {}

    ~IntBuffer() {
        delete[] data_;
    }

private:
    std::size_t size_;
    int* data_;
};
```

如果现在写：

```cpp
IntBuffer a(5);
IntBuffer b = a;
```

默认拷贝会怎么做？

```text
b.size_ = a.size_
b.data_ = a.data_
```

注意第二行：

```text
不是重新申请一块数组。
而是把指针里的地址值复制过去。
```

于是变成：

```text
a.data_ ----> 一块 int 数组
b.data_ ----> 同一块 int 数组
```

这就叫：

```text
shallow copy，浅拷贝
```

浅拷贝的意思不是“复制得很少”这么简单，而是：

```text
只复制了指针值，没有复制指针指向的资源本身。
```

然后作用域结束：

```text
b 析构，delete[] data_
a 析构，又 delete[] 同一块 data_
```

这就是：

```text
double delete，重复释放
```

---

## 7. 写一个故意出错的版本

这个程序是为了观察错误。它是坏代码。今天只跑一次看看现象，不要模仿这种写法。

创建文件：

```bash
touch 02_bad_shallow_copy.cpp
```

写入：

```cpp
#include <iostream>
#include <cstddef>

class IntBuffer {
public:
    explicit IntBuffer(std::size_t size)
        : size_(size), data_(new int[size]) {
        std::cout << "construct, data = "
                  << static_cast<void*>(data_) << std::endl;
    }

    ~IntBuffer() {
        std::cout << "destruct, data = "
                  << static_cast<void*>(data_) << std::endl;
        delete[] data_;
    }

    void set(std::size_t index, int value) {
        if (index < size_) {
            data_[index] = value;
        }
    }

    int get(std::size_t index) const {
        if (index < size_) {
            return data_[index];
        }
        return 0;
    }

private:
    std::size_t size_;
    int* data_;
};

int main() {
    IntBuffer a(3);
    a.set(0, 100);

    IntBuffer b = a;  // 默认拷贝：浅拷贝，危险

    std::cout << "a[0] = " << a.get(0) << std::endl;
    std::cout << "b[0] = " << b.get(0) << std::endl;

    return 0;
}
```

用 AddressSanitizer 编译：

```bash
g++ -std=c++17 -Wall -Wextra -g -fsanitize=address 02_bad_shallow_copy.cpp -o 02_bad_shallow_copy
./02_bad_shallow_copy
```

你要观察：

```text
construct 只出现一次
destruct 会尝试释放同一个 data 地址两次
ASan 可能会报告 double-free
```

这里不要纠结错误信息的每一行。你只需要看懂核心：

```text
a 和 b 的 data_ 地址一样。
两个对象都以为自己拥有这块数组。
最后两个析构函数都 delete[] 它。
```

---

# 第四部分：深拷贝怎么解决

## 8. 深拷贝的直觉

浅拷贝是：

```text
只复制地址。
```

深拷贝是：

```text
重新申请一块自己的资源，再把内容复制过去。
```

也就是：

```text
a.data_ ----> 一块 int 数组，内容是 100 200 300
b.data_ ----> 另一块 int 数组，内容也是 100 200 300
```

它们内容一样，但资源不是同一块。这样各删各的，不会 double delete。

---

## 9. 写拷贝构造函数

创建文件：

```bash
touch 03_deep_copy_constructor.cpp
```

写入：

```cpp
#include <iostream>
#include <cstddef>

class IntBuffer {
public:
    explicit IntBuffer(std::size_t size)
        : size_(size), data_(new int[size]) {
        std::cout << "construct, data = "
                  << static_cast<void*>(data_) << std::endl;

        for (std::size_t i = 0; i < size_; ++i) {
            data_[i] = 0;
        }
    }

    // 拷贝构造函数：用 other 创建一个新对象
    IntBuffer(const IntBuffer& other)
        : size_(other.size_), data_(new int[other.size_]) {
        std::cout << "copy construct, from "
                  << static_cast<void*>(other.data_)
                  << " to "
                  << static_cast<void*>(data_) << std::endl;

        for (std::size_t i = 0; i < size_; ++i) {
            data_[i] = other.data_[i];
        }
    }

    ~IntBuffer() {
        std::cout << "destruct, data = "
                  << static_cast<void*>(data_) << std::endl;
        delete[] data_;
    }

    void set(std::size_t index, int value) {
        if (index < size_) {
            data_[index] = value;
        }
    }

    int get(std::size_t index) const {
        if (index < size_) {
            return data_[index];
        }
        return 0;
    }

private:
    std::size_t size_;
    int* data_;
};

int main() {
    IntBuffer a(3);
    a.set(0, 100);
    a.set(1, 200);

    IntBuffer b = a;  // 调用拷贝构造函数

    b.set(0, 999);

    std::cout << "a[0] = " << a.get(0) << std::endl;
    std::cout << "b[0] = " << b.get(0) << std::endl;

    return 0;
}
```

编译运行：

```bash
g++ -std=c++17 -Wall -Wextra -g 03_deep_copy_constructor.cpp -o 03_deep_copy_constructor
./03_deep_copy_constructor
```

你要观察：

```text
a 和 b 的 data_ 地址不同。
改 b[0] 不影响 a[0]。
两个析构函数各自 delete 不同的数组。
```

这就是正确的深拷贝。

---

# 第五部分：拷贝赋值怎么写

## 10. 拷贝赋值比拷贝构造麻烦一点

拷贝构造是：

```cpp
IntBuffer b = a;
```

此时 `b` 还没出生。你只需要：

```text
申请新资源
复制 other 的内容
```

拷贝赋值是：

```cpp
b = a;
```

此时 `b` 已经活着，而且可能已经拥有一块旧资源。所以你要处理：

```text
1. 如果是自己给自己赋值怎么办？
2. b 原来的资源要不要释放？
3. 要不要重新申请资源？
4. 最后要不要返回 *this？
```

---

## 11. 自赋值是什么

看这句：

```cpp
a = a;
```

这叫：

```text
self-assignment，自赋值
```

工程里可能间接发生，比如：

```cpp
buffers[i] = buffers[j];
```

当 `i == j` 时，就是自赋值。

如果你写拷贝赋值时不处理自赋值，可能会这样：

```text
先 delete[] 自己的 data_
再从 other.data_ 复制

但 other 就是自己。
所以 other.data_ 也被你删掉了。
```

因此拷贝赋值通常先判断：

```cpp
if (this == &other) {
    return *this;
}
```

---

## 12. 写一个拷贝赋值版本

创建文件：

```bash
touch 04_copy_assignment.cpp
```

写入：

```cpp
#include <iostream>
#include <cstddef>

class IntBuffer {
public:
    explicit IntBuffer(std::size_t size)
        : size_(size), data_(new int[size]) {
        std::cout << "construct, data = "
                  << static_cast<void*>(data_) << std::endl;

        for (std::size_t i = 0; i < size_; ++i) {
            data_[i] = 0;
        }
    }

    IntBuffer(const IntBuffer& other)
        : size_(other.size_), data_(new int[other.size_]) {
        std::cout << "copy construct, data = "
                  << static_cast<void*>(data_) << std::endl;

        for (std::size_t i = 0; i < size_; ++i) {
            data_[i] = other.data_[i];
        }
    }

    IntBuffer& operator=(const IntBuffer& other) {
        std::cout << "copy assignment" << std::endl;

        if (this == &other) {
            std::cout << "self assignment, do nothing" << std::endl;
            return *this;
        }

        delete[] data_;

        size_ = other.size_;
        data_ = new int[size_];

        for (std::size_t i = 0; i < size_; ++i) {
            data_[i] = other.data_[i];
        }

        return *this;
    }

    ~IntBuffer() {
        std::cout << "destruct, data = "
                  << static_cast<void*>(data_) << std::endl;
        delete[] data_;
    }

    void set(std::size_t index, int value) {
        if (index < size_) {
            data_[index] = value;
        }
    }

    int get(std::size_t index) const {
        if (index < size_) {
            return data_[index];
        }
        return 0;
    }

private:
    std::size_t size_;
    int* data_;
};

int main() {
    IntBuffer a(3);
    a.set(0, 100);

    IntBuffer b(2);
    b.set(0, 999);

    b = a;  // 调用拷贝赋值运算符

    std::cout << "a[0] = " << a.get(0) << std::endl;
    std::cout << "b[0] = " << b.get(0) << std::endl;

    a = a;  // 自赋值测试

    return 0;
}
```

编译运行：

```bash
g++ -std=c++17 -Wall -Wextra -g 04_copy_assignment.cpp -o 04_copy_assignment
./04_copy_assignment
```

你要观察：

```text
b = a 调用 copy assignment
a = a 触发 self assignment
程序不会 double delete
```

---

## 13. 这个版本还不是最完美

刚才这个赋值版本：

```cpp
delete[] data_;

size_ = other.size_;
data_ = new int[size_];
```

在普通学习阶段够用。

但它有一个更高级的问题：

```text
如果 delete[] 后，new int[size_] 失败了怎么办？
```

这就会进入：

```text
exception safety，异常安全
```

今天先不展开。你先知道：

```text
真正工程里常用 copy-and-swap 处理得更漂亮。
```

---

# 第六部分：Rule of Three

## 14. 为什么叫三法则

如果一个类需要自己写析构函数，通常说明它在管理某种资源：

```text
堆内存
文件句柄
socket fd
mutex
数据库连接
```

如果它管理资源，那它通常也要认真考虑：

```text
析构时怎么释放
拷贝构造时怎么复制
拷贝赋值时怎么替换
```

这三个函数是：

```cpp
~T();
T(const T& other);
T& operator=(const T& other);
```

这叫：

```text
Rule of Three，三法则
```

直觉版：

```text
如果你需要自己写析构函数，那你大概率也需要自己写拷贝构造和拷贝赋值。
```

为什么？

因为默认拷贝很可能只是浅拷贝。浅拷贝对拥有资源的类很危险。

---

## 15. 完整写一个 Rule of Three 版本

创建文件：

```bash
touch 05_rule_of_three_buffer.cpp
```

写入：

```cpp
#include <iostream>
#include <cstddef>

class IntBuffer {
public:
    explicit IntBuffer(std::size_t size)
        : size_(size), data_(new int[size]) {
        std::cout << "construct, size = " << size_
                  << ", data = " << static_cast<void*>(data_) << std::endl;

        for (std::size_t i = 0; i < size_; ++i) {
            data_[i] = 0;
        }
    }

    IntBuffer(const IntBuffer& other)
        : size_(other.size_), data_(new int[other.size_]) {
        std::cout << "copy construct, size = " << size_
                  << ", data = " << static_cast<void*>(data_) << std::endl;

        for (std::size_t i = 0; i < size_; ++i) {
            data_[i] = other.data_[i];
        }
    }

    IntBuffer& operator=(const IntBuffer& other) {
        std::cout << "copy assignment" << std::endl;

        if (this == &other) {
            return *this;
        }

        int* new_data = new int[other.size_];

        for (std::size_t i = 0; i < other.size_; ++i) {
            new_data[i] = other.data_[i];
        }

        delete[] data_;

        data_ = new_data;
        size_ = other.size_;

        return *this;
    }

    ~IntBuffer() {
        std::cout << "destruct, size = " << size_
                  << ", data = " << static_cast<void*>(data_) << std::endl;
        delete[] data_;
    }

    void set(std::size_t index, int value) {
        if (index < size_) {
            data_[index] = value;
        }
    }

    int get(std::size_t index) const {
        if (index < size_) {
            return data_[index];
        }
        return 0;
    }

    std::size_t size() const {
        return size_;
    }

private:
    std::size_t size_;
    int* data_;
};

int main() {
    IntBuffer a(3);
    a.set(0, 100);
    a.set(1, 200);

    std::cout << "copy construct b from a" << std::endl;
    IntBuffer b = a;

    b.set(0, 999);

    std::cout << "a[0] = " << a.get(0) << std::endl;
    std::cout << "b[0] = " << b.get(0) << std::endl;

    std::cout << "copy assignment c = a" << std::endl;
    IntBuffer c(1);
    c = a;

    std::cout << "c[0] = " << c.get(0) << std::endl;

    std::cout << "self assignment a = a" << std::endl;
    a = a;

    return 0;
}
```

编译运行：

```bash
g++ -std=c++17 -Wall -Wextra -g 05_rule_of_three_buffer.cpp -o 05_rule_of_three_buffer
./05_rule_of_three_buffer
```

这里赋值运算符写成了更安全的顺序：

```cpp
int* new_data = new int[other.size_];
// 先复制到新资源
delete[] data_;
// 再释放旧资源
data_ = new_data;
size_ = other.size_;
```

比这个顺序更好：

```cpp
delete[] data_;
data_ = new int[size_];
```

因为如果 `new` 失败，旧对象至少还没有被破坏。

今天你不需要完全掌握异常安全，但要有这个直觉：

```text
项目代码里，资源释放顺序很重要。
```

这也就是强化版 plan 里“生产级代码标准”的早期影子。

---

# 第七部分：今天不要提前深挖

今天先不要展开：

```text
移动构造
移动赋值
std::move
unique_ptr 详细用法
shared_ptr 引用计数
copy-and-swap 完整写法
异常安全完整分类
Rule of Five
模板
allocator
placement new
```

这些后面都会学。

Day5 只处理：

```text
默认拷贝
浅拷贝
深拷贝
拷贝构造
拷贝赋值
self-assignment
Rule of Three
```

不要一口气吃太多。

---

# 第八部分：今天笔记写什么

建议写成这样：

```markdown
# Day5 Notes

## 拷贝构造和拷贝赋值
- 拷贝构造是什么：
- 拷贝赋值是什么：
- `IntBuffer b = a;` 调用什么：
- `b = a;` 调用什么：
- 为什么拷贝赋值要返回 `*this`：

## 浅拷贝和深拷贝
- 默认拷贝通常做什么：
- 浅拷贝是什么：
- 深拷贝是什么：
- 为什么 IntBuffer 默认拷贝会 double delete：
- 怎么观察 a.data_ 和 b.data_ 是否相同：

## 拷贝构造函数
- 函数签名：
- 参数为什么是 `const IntBuffer& other`：
- 深拷贝构造里要做哪几步：

## 拷贝赋值运算符
- 函数签名：
- 为什么要处理 self-assignment：
- 为什么要先释放旧资源：
- 为什么更安全的写法是先申请新资源再释放旧资源：

## Rule of Three
- 三个函数分别是什么：
- 什么情况下要想到 Rule of Three：
- 为什么有析构函数的类通常要考虑拷贝构造和拷贝赋值：
```

不用写很长，但必须用自己的话。

---

# 第九部分：Day5 验收问题

做完后，把这些问题回答给我：

```text
1. 什么是拷贝构造函数？
2. 什么是拷贝赋值运算符？
3. `IntBuffer b = a;` 和 `b = a;` 有什么区别？
4. 默认拷贝通常做什么？
5. 什么是浅拷贝？
6. 什么是深拷贝？
7. 为什么 Day4 的 IntBuffer 如果默认拷贝会 double delete？
8. 拷贝构造函数为什么一般写成 `T(const T& other)`？
9. 拷贝赋值为什么一般返回 `T&`？
10. `return *this;` 是什么意思？
11. 什么是 self-assignment？
12. 为什么拷贝赋值要处理 self-assignment？
13. Rule of Three 是什么？
14. 为什么“自己管理裸资源”的类要特别小心拷贝？
15. 为什么现代 C++ 更推荐 `std::vector` / `std::string` / 智能指针，而不是自己手写裸资源类？
```

过关标准：

```text
能拿 IntBuffer 画出：
浅拷贝：两个 data_ 指向同一块数组
深拷贝：两个 data_ 指向不同数组但内容一样
```

---

# 第十部分：Git 提交

回到仓库根目录：

```bash
cd ~/code/system-learning
git status
git add .
git commit -m "week1 day5 copy control"
```

如果你要推到 GitHub：

```bash
git push
```

---

# Day5 完成标准

当你做到：

```text
5 个小代码能编译运行
能解释拷贝构造和拷贝赋值的区别
能解释默认拷贝为什么是浅拷贝
能解释浅拷贝为什么 double delete
能写出深拷贝构造函数
能写出拷贝赋值运算符
能解释 self-assignment
能解释 Rule of Three
笔记写完
能回答 Day5 验收问题
完成一次 git commit
```

Day5 就结束。

下一步 Day6：

> **复盘 + 小型 String/Buffer 类练习：把 Day4 / Day5 的资源管理真正写熟。**
