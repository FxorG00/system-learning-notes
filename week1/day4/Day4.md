# Day4：new / delete、堆对象、裸指针风险、RAII 初步

> Day4 目标：把 Day2 的“指针”和 Day3 的“构造 / 析构”真正串起来。  
> 你已经能理解：栈上对象离开作用域会自动析构，block scope 可以控制对象什么时候死亡。  
> 今天进一步看：**对象如果被 new 到堆上，它什么时候出生，什么时候死亡，谁负责让它死亡。**

Day3 你已经掌握了构造函数、析构函数、作用域块、成员初始化列表、`this`、`const` 成员函数。  
所以 Day4 不再重新讲“对象是什么”，直接进入 C++ 最容易出 bug 的地方：

```text
new / delete
new[] / delete[]
栈对象 vs 堆对象
内存泄漏
悬空指针
重复释放
RAII 初步
```

今天你会第一次看到：  
**为什么现代 C++ 不推荐裸 new / delete，而推荐 RAII 和智能指针。**

不过注意：今天还不正式学智能指针。  
今天只先搞懂：**裸指针为什么危险，RAII 为什么能救命。**

---

## 0. 今天你要拿下什么

做完 Day4，你应该能做到：

```text
1. 区分栈对象和堆对象
2. 知道 new 做了哪两件事
3. 知道 delete 做了哪两件事
4. 知道 new 和 delete 必须配对
5. 知道 new[] 和 delete[] 必须配对
6. 理解内存泄漏 memory leak
7. 理解悬空指针 dangling pointer
8. 理解重复释放 double delete
9. 能解释为什么裸指针管理资源很危险
10. 初步理解 RAII：让对象析构函数自动释放资源
```

今天的过关标准：

```text
你能讲清楚：
new 创建的对象为什么不会自动随着作用域结束而析构；
delete 为什么既会调用析构函数，又会释放内存；
RAII 为什么能避免忘记 delete。
```

---

## 1. 今天代码放哪里

代码仍然放 Ubuntu：

```bash
cd ~/code/system-learning/cpp/week1
mkdir -p day4
cd day4
```

建议今天写 5 个小程序：

```text
day4/
├── 01_stack_vs_heap.cpp
├── 02_new_delete_tracer.cpp
├── 03_new_array_delete_array.cpp
├── 04_memory_bug_demo.cpp
└── 05_raii_buffer.cpp
```

每个文件都可以这样编译：

```bash
g++ -std=c++17 -Wall -Wextra -g 文件名.cpp -o 输出名
```

例如：

```bash
g++ -std=c++17 -Wall -Wextra -g 01_stack_vs_heap.cpp -o 01_stack_vs_heap
./01_stack_vs_heap
```

笔记按你的习惯存，不强制放 Ubuntu。

---

# 第一部分：栈对象 vs 堆对象

## 2. 栈上对象：离开作用域自动析构

Day3 你已经见过这种代码：

```cpp
{
    Tracer b("b");
}
```

`b` 是一个局部对象，也可以先理解成“栈上对象”。

它的特点是：

```text
进入作用域：自动构造
离开作用域：自动析构
```

所以：

```cpp
int main() {
    Tracer a("a");

    {
        Tracer b("b");
    }

    return 0;
}
```

大概过程是：

```text
construct a
construct b
destruct b
destruct a
```

`b` 的生命周期被内部 `{}` 控住了。  
这个你 Day3 已经过关了。

---

## 3. 堆上对象：不会自动跟着作用域死

现在看另一种写法：

```cpp
Tracer* p = new Tracer("heap");
```

这里 `new Tracer("heap")` 会在堆上创建一个 `Tracer` 对象，然后返回它的地址。  
这个地址被存在指针 `p` 里面。

重点来了：

```text
p 是一个局部变量，会随着作用域结束自动消失；
但 p 指向的堆对象，不会因为 p 消失就自动析构。
```

所以你必须手动写：

```cpp
delete p;
```

否则堆上的对象就没人管了。

---

## 4. new 做了什么，delete 做了什么

这组非常重要：

```cpp
Tracer* p = new Tracer("heap");
delete p;
```

`new Tracer("heap")` 做两件事：

```text
1. 在堆上申请一块足够放 Tracer 对象的内存
2. 在这块内存上调用 Tracer 的构造函数
```

`delete p` 也做两件事：

```text
1. 调用 p 指向对象的析构函数
2. 释放这块堆内存
```

所以不要把 `delete` 理解成“单纯释放内存”。  
对对象来说，`delete` 还会触发析构函数。

一句话：

```text
new = 分配内存 + 构造对象
delete = 析构对象 + 释放内存
```

---

## 5. 写代码对比栈对象和堆对象

创建文件：

```bash
touch 01_stack_vs_heap.cpp
```

写入：

```cpp
#include <iostream>
#include <string>

class Tracer {
public:
    Tracer(const std::string& name)
        : name_(name) {
        std::cout << "construct: " << name_ << std::endl;
    }

    ~Tracer() {
        std::cout << "destruct: " << name_ << std::endl;
    }

    void hello() const {
        std::cout << "hello from " << name_ << std::endl;
    }

private:
    std::string name_;
};

int main() {
    std::cout << "enter main" << std::endl;

    Tracer stack_obj("stack");
    stack_obj.hello();

    Tracer* heap_obj = new Tracer("heap");
    heap_obj->hello();

    std::cout << "before delete" << std::endl;
    delete heap_obj;
    std::cout << "after delete" << std::endl;

    std::cout << "leave main" << std::endl;
    return 0;
}
```

编译运行：

```bash
g++ -std=c++17 -Wall -Wextra -g 01_stack_vs_heap.cpp -o 01_stack_vs_heap
./01_stack_vs_heap
```

你要观察：

```text
heap 对象在 delete 的时候析构
stack 对象在 main 结束的时候析构
```

也就是说：

```text
栈对象：作用域结束自动析构
堆对象：delete 时才析构
```

---

## 6. 这一小节你要能回答

```text
1. Tracer stack_obj("stack"); 创建的对象在哪里？
2. Tracer* heap_obj = new Tracer("heap"); 创建的对象在哪里？
3. heap_obj 这个指针变量本身在哪里？
4. new 做了哪两件事？
5. delete 做了哪两件事？
6. 为什么堆对象不 delete 会出问题？
```

第 3 题要注意：  
`heap_obj` 这个指针变量本身是局部变量，在栈上；但它指向的对象在堆上。

---

# 第二部分：new / delete 的配对

## 7. new 出来的单个对象，用 delete

如果你写：

```cpp
Tracer* p = new Tracer("one");
```

那么应该用：

```cpp
delete p;
```

不要写：

```cpp
delete[] p;
```

单个对象：

```text
new T      对应 delete
```

数组对象：

```text
new T[n]   对应 delete[]
```

这组配对不能乱。

---

## 8. 写代码观察 delete 调用析构函数

创建文件：

```bash
touch 02_new_delete_tracer.cpp
```

写入：

```cpp
#include <iostream>
#include <string>

class Tracer {
public:
    Tracer(const std::string& name)
        : name_(name) {
        std::cout << "construct: " << name_ << std::endl;
    }

    ~Tracer() {
        std::cout << "destruct: " << name_ << std::endl;
    }

private:
    std::string name_;
};

int main() {
    Tracer* p = new Tracer("object");

    std::cout << "object is alive" << std::endl;

    delete p;

    std::cout << "object is dead" << std::endl;

    return 0;
}
```

编译运行：

```bash
g++ -std=c++17 -Wall -Wextra -g 02_new_delete_tracer.cpp -o 02_new_delete_tracer
./02_new_delete_tracer
```

你要观察：

```text
delete p 这一行会触发 destruct: object
```

---

## 9. delete 后指针变量还在，但已经不能用了

看这段：

```cpp
Tracer* p = new Tracer("object");
delete p;
```

`delete p` 之后：

```text
p 这个指针变量还在
p 里面可能还保存着原来的地址
但那个地址上的对象已经死了，内存也被释放了
```

这种指针叫：

```text
悬空指针，dangling pointer
```

如果你继续用：

```cpp
p->hello();
```

就是在访问已经释放的对象，行为未定义。

这里有个术语：

```text
undefined behavior，未定义行为
```

意思是：

```text
程序可能崩，可能不崩，可能输出奇怪东西，不能依赖。
```

一个小习惯：

```cpp
delete p;
p = nullptr;
```

这样后面至少可以判断：

```cpp
if (p != nullptr) {
    // use p
}
```

但记住：  
`p = nullptr` 只能降低误用风险，真正更好的方式是不要手动管理资源，而是用 RAII / 智能指针。

---

# 第三部分：new[] / delete[]

## 10. new[] 创建数组，delete[] 释放数组

如果你要在堆上创建数组：

```cpp
int* arr = new int[5];
```

释放时必须写：

```cpp
delete[] arr;
```

配对规则：

```text
new      -> delete
new[]    -> delete[]
```

不能混用。

---

## 11. 对象数组会调用多次构造 / 析构

如果是对象数组：

```cpp
Tracer* arr = new Tracer[3];
delete[] arr;
```

会发生：

```text
构造 3 个 Tracer
析构 3 个 Tracer
```

不过这要求 `Tracer` 有默认构造函数，因为 `new Tracer[3]` 不知道每个对象要用什么参数构造。

---

## 12. 写代码验证 new[] / delete[]

创建文件：

```bash
touch 03_new_array_delete_array.cpp
```

写入：

```cpp
#include <iostream>

class Tracer {
public:
    Tracer() {
        std::cout << "construct Tracer" << std::endl;
    }

    ~Tracer() {
        std::cout << "destruct Tracer" << std::endl;
    }
};

int main() {
    std::cout << "new array" << std::endl;

    Tracer* arr = new Tracer[3];

    std::cout << "delete array" << std::endl;

    delete[] arr;

    return 0;
}
```

编译运行：

```bash
g++ -std=c++17 -Wall -Wextra -g 03_new_array_delete_array.cpp -o 03_new_array_delete_array
./03_new_array_delete_array
```

你要观察：

```text
construct Tracer 出现 3 次
destruct Tracer 出现 3 次
```

---

## 13. 这一小节你要能回答

```text
1. new T 对应什么？
2. new T[n] 对应什么？
3. 为什么 new Tracer[3] 要求 Tracer 有默认构造函数？
4. delete[] arr 会不会调用每个元素的析构函数？
5. new 和 delete[] 混用行不行？
```

第 5 题：不行。  
这是未定义行为。

---

# 第四部分：三个经典内存错误

## 14. 内存泄漏：忘记 delete

看这个：

```cpp
void leak() {
    Tracer* p = new Tracer("leak");
}
```

函数结束后：

```text
p 这个局部指针变量没了
但 p 指向的堆对象还活着
你也拿不到它的地址了
所以没法 delete 了
```

这叫：

```text
内存泄漏，memory leak
```

内存泄漏的本质：

```text
申请的资源没有释放。
```

如果程序很快结束，可能看起来没事。  
但服务器程序、后台服务、数据库、Redis、Nginx 这种长期运行的程序，内存泄漏会越来越严重。

这也是为什么我们学系统编程必须认真理解资源管理。

---

## 15. 悬空指针：delete 后继续用

看这个：

```cpp
Tracer* p = new Tracer("dangling");

delete p;

p->hello(); // 错
```

`delete p` 之后对象已经死了。  
`p` 还保存着旧地址，但这个地址不再属于你。

这叫：

```text
悬空指针，dangling pointer
```

它非常危险，因为有时候程序不会立刻崩。  
不崩反而更坏，因为 bug 可能藏很久。

---

## 16. 重复释放：delete 两次

看这个：

```cpp
Tracer* p = new Tracer("double");

delete p;
delete p; // 错
```

同一块内存释放两次，叫：

```text
重复释放，double delete
```

这也是未定义行为。

工程里经常见到这样的补救写法：

```cpp
delete p;
p = nullptr;
```

然后第二次：

```cpp
delete p;
```

如果 `p` 是 `nullptr`，`delete nullptr` 是安全的，什么也不会发生。

但这只是补救，不是根治。  
根治方式是：让资源有明确的主人，用 RAII 管理。

---

## 17. 写代码看这些错误长什么样

创建文件：

```bash
touch 04_memory_bug_demo.cpp
```

写入：

```cpp
#include <iostream>
#include <string>

class Tracer {
public:
    Tracer(const std::string& name)
        : name_(name) {
        std::cout << "construct: " << name_ << std::endl;
    }

    ~Tracer() {
        std::cout << "destruct: " << name_ << std::endl;
    }

    void hello() const {
        std::cout << "hello from " << name_ << std::endl;
    }

private:
    std::string name_;
};

void memory_leak_demo() {
    Tracer* p = new Tracer("leak");

    // 忘记 delete p;
    // 函数结束后，p 没了，但堆上的对象还没析构。
}

void safe_demo() {
    Tracer* p = new Tracer("safe");

    p->hello();

    delete p;
    p = nullptr;
}

int main() {
    std::cout << "safe demo:" << std::endl;
    safe_demo();

    std::cout << "memory leak demo:" << std::endl;
    memory_leak_demo();

    std::cout << "program end" << std::endl;
    return 0;
}
```

编译运行：

```bash
g++ -std=c++17 -Wall -Wextra -g 04_memory_bug_demo.cpp -o 04_memory_bug_demo
./04_memory_bug_demo
```

你要观察：

```text
safe 对象有 destruct
leak 对象没有 destruct
```

这说明 `memory_leak_demo` 里的堆对象没有被正确释放。

注意：  
今天不要故意写 `delete p; delete p;` 或 `delete p; p->hello();` 来玩崩溃。  
这些是未定义行为，不是稳定实验。

---

## 18. 这一小节你要能回答

```text
1. 什么是内存泄漏？
2. 什么是悬空指针？
3. 什么是重复释放？
4. delete 后为什么常见 p = nullptr？
5. p = nullptr 能不能彻底解决资源管理问题？
6. 为什么长期运行的服务器特别怕内存泄漏？
```

---

# 第五部分：RAII 初步

## 19. 裸指针管理资源为什么危险

裸指针管理堆内存时，你必须保证：

```text
1. 每次 new 都有 delete
2. 每条提前 return 的路径也 delete
3. 出异常时也 delete
4. 不要 delete 两次
5. delete 后不要继续用
6. new[] 和 delete[] 不要配错
```

这太容易错了。

比如：

```cpp
void foo(bool bad) {
    int* p = new int[100];

    if (bad) {
        return; // 忘记 delete[] p，泄漏
    }

    delete[] p;
}
```

你看，逻辑一复杂，就容易漏。

所以 C++ 发展出一个核心习惯：

```text
不要让裸指针直接拥有资源。
```

这里有个术语：

```text
owning pointer，拥有资源的指针
```

如果一个裸指针负责 delete 某块内存，它就是 owning pointer。  
这种裸 owning pointer 很危险。

---

## 20. RAII 是什么

RAII 全称：

```text
Resource Acquisition Is Initialization
```

中文常翻译成：

```text
资源获取即初始化
```

这个翻译有点怪，你先这样理解：

```text
把资源交给一个对象管理；
对象构造时拿资源；
对象析构时自动释放资源。
```

也就是：

```text
构造函数：拿资源
析构函数：还资源
```

这样资源就跟对象生命周期绑定在一起了。

而你 Day3 已经知道：

```text
栈上对象离开作用域会自动析构。
```

所以 RAII 利用这个规则：

```text
对象离开作用域自动析构
析构函数里自动释放资源
于是资源自动释放
```

这就是 C++ 资源管理的核心思想。

---

## 21. 写一个最小 RAII 类

我们先写一个很简单的 `IntBuffer`。  
它在构造函数里 `new[]`，在析构函数里 `delete[]`。

创建文件：

```bash
touch 05_raii_buffer.cpp
```

写入：

```cpp
#include <iostream>
#include <cstddef>

class IntBuffer {
public:
    explicit IntBuffer(std::size_t size)
        : size_(size), data_(new int[size]) {
        std::cout << "IntBuffer construct, size = " << size_ << std::endl;
    }

    ~IntBuffer() {
        std::cout << "IntBuffer destruct, size = " << size_ << std::endl;
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

    // 今天先禁止拷贝，避免引出深拷贝 / 浅拷贝问题。
    IntBuffer(const IntBuffer&) = delete;
    IntBuffer& operator=(const IntBuffer&) = delete;

private:
    std::size_t size_;
    int* data_;
};

void use_buffer() {
    IntBuffer buffer(5);

    buffer.set(0, 100);
    buffer.set(1, 200);

    std::cout << "buffer[0] = " << buffer.get(0) << std::endl;
    std::cout << "buffer[1] = " << buffer.get(1) << std::endl;

    // 不需要手动 delete[]。
    // 函数结束时 buffer 自动析构，析构函数里会 delete[] data_。
}

int main() {
    std::cout << "enter main" << std::endl;

    use_buffer();

    std::cout << "leave main" << std::endl;
    return 0;
}
```

编译运行：

```bash
g++ -std=c++17 -Wall -Wextra -g 05_raii_buffer.cpp -o 05_raii_buffer
./05_raii_buffer
```

你要观察：

```text
IntBuffer 在 use_buffer 里构造
use_buffer 结束时自动析构
析构函数里自动 delete[] data_
```

这就是 RAII 的雏形。

---

## 22. 这个 RAII 类为什么先禁止拷贝

你可能注意到这两行：

```cpp
IntBuffer(const IntBuffer&) = delete;
IntBuffer& operator=(const IntBuffer&) = delete;
```

意思是：

```text
禁止拷贝构造
禁止拷贝赋值
```

为什么？

因为 `IntBuffer` 里面有裸指针 `data_`，如果默认拷贝，就会出现两个对象指向同一块堆内存：

```text
buffer1.data_ ----> 一块 int 数组
buffer2.data_ ----> 同一块 int 数组
```

那两个对象析构时都会 `delete[] data_`，就会重复释放。

这个问题叫：

```text
浅拷贝导致 double delete
```

今天不展开拷贝构造和拷贝赋值。  
Day5 或后面专门学“拷贝控制”时再处理。

你今天只需要知道：

```text
一个类如果自己管理裸资源，就必须认真处理拷贝问题。
```

这也是为什么现代 C++ 更推荐直接用：

```cpp
std::vector<int>
std::string
std::unique_ptr<int[]>
```

这些现成 RAII 类型。

---

## 23. RAII 和智能指针的关系

今天我们手写了一个很小的 RAII 类。  
现代 C++ 里，很多标准库类型本身就是 RAII：

```text
std::string：自动管理字符串内存
std::vector：自动管理动态数组内存
std::unique_ptr：自动管理独占堆对象
std::shared_ptr：自动管理共享堆对象
std::lock_guard：自动管理锁
std::fstream：自动管理文件句柄
```

所以你以后看到：

```cpp
std::vector<int> v(100);
```

它本质上比你自己写：

```cpp
int* arr = new int[100];
delete[] arr;
```

安全得多。

今天先记住一句工程原则：

```text
能不用裸 new/delete，就不用裸 new/delete。
```

学习它们不是为了天天写它们，而是为了知道底层发生了什么，以及为什么 RAII / 智能指针更安全。

---

## 24. 这一小节你要能回答

```text
1. RAII 的英文全称是什么？
2. RAII 的核心思想是什么？
3. 构造函数在 RAII 里通常做什么？
4. 析构函数在 RAII 里通常做什么？
5. 为什么 RAII 能减少忘记 delete 的问题？
6. 为什么 IntBuffer 要禁止拷贝？
7. std::vector 和 RAII 有什么关系？
```

---

# 第六部分：今天不要提前深挖的东西

今天先不要展开：

```text
智能指针详细用法
shared_ptr 引用计数
weak_ptr
拷贝构造
拷贝赋值
移动构造
移动赋值
异常安全
operator new / placement new
内存池
allocator
```

这些后面都会学。

Day4 只处理：

```text
new / delete 的基本语义
new[] / delete[] 配对
堆对象和栈对象生命周期区别
三类典型内存错误
RAII 的第一层直觉
```

不要一口气吃太多。

---

# 第七部分：你的笔记写什么

笔记按你的习惯存。

建议至少写这些：

```markdown
# Day4 Notes

## 栈对象和堆对象
- 栈对象什么时候构造：
- 栈对象什么时候析构：
- 堆对象什么时候构造：
- 堆对象什么时候析构：
- 指针变量本身和它指向的对象可能在哪里：

## new / delete
- new 做了哪两件事：
- delete 做了哪两件事：
- new T 对应什么：
- new T[n] 对应什么：

## 内存错误
- memory leak 是什么：
- dangling pointer 是什么：
- double delete 是什么：
- delete 后 p = nullptr 有什么用：
- p = nullptr 能不能彻底解决问题：

## RAII
- RAII 全称：
- RAII 核心思想：
- 构造函数在 RAII 中负责什么：
- 析构函数在 RAII 中负责什么：
- 为什么 RAII 能减少资源泄漏：
- 为什么手写资源管理类要考虑拷贝问题：
```

不用写很长，但必须用自己的话。

---

# 第八部分：Day4 验收问题

做完后，把这些问题回答给我：

```text
1. 栈对象和堆对象的生命周期有什么区别？
2. new 做了哪两件事？
3. delete 做了哪两件事？
4. new T 和 new T[n] 分别应该怎么释放？
5. delete p 之后，p 这个指针变量还在吗？p 指向的对象还在吗？
6. 什么是内存泄漏？
7. 什么是悬空指针？
8. 什么是重复释放？
9. 为什么 delete 后常写 p = nullptr？
10. p = nullptr 能不能从根上解决资源管理问题？
11. RAII 的英文全称是什么？
12. RAII 的核心思想是什么？
13. 为什么 RAII 能避免忘记 delete？
14. IntBuffer 为什么要禁止拷贝？
15. 为什么现代 C++ 不推荐到处写裸 new / delete？
```

过关标准：

```text
能拿 Tracer / IntBuffer 两个例子解释，不是背定义。
```

---

# 第九部分：Git 提交

回到仓库根目录：

```bash
cd ~/code/system-learning
git status
git add .
git commit -m "week1 day4 new delete raii"
```

如果你要推到 GitHub：

```bash
git push
```

---

# Day4 完成标准

当你做到：

```text
5 个小代码能编译运行
能解释 new / delete 的构造析构输出
能解释 new[] / delete[] 的配对
能解释 memory leak / dangling pointer / double delete
能解释 RAII 的基本思想
笔记写完
能回答 Day4 验收问题
完成一次 git commit
```

Day4 就结束。

下一步 Day5：

> **拷贝构造、拷贝赋值、浅拷贝、深拷贝：解释为什么 IntBuffer 这种类不能随便拷贝。**
