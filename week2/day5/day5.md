# Week2 Day5：shared_ptr / weak_ptr 初步

> 今日定位：承接 Day4 的 `unique_ptr`。  
> Day4 你已经能用 `unique_ptr` 表达“独占所有权”。今天只解决一个新问题：如果一个对象真的需要被多个地方共同持有，它的生命周期该怎么管理？

---

## Part A：前情提要和术语

### 1. 前情提要：从 unique_ptr 到 shared_ptr

Day4 的核心结论是：

```text
unique_ptr 表达独占所有权。
一个资源只有一个 owner。
owner 析构时，资源自动释放。
unique_ptr 不能 copy，只能 move。
```

这很适合你现在写的 `Buffer`：

```text
Buffer 拥有一块 char[]
这块内存只属于这个 Buffer
Buffer 死亡，内存释放
Buffer 移动，所有权转移
```

但是工程里有些对象的生命周期没这么简单。比如：

```text
一个 Session 对象，可能被连接管理器持有，也可能被某个异步任务临时持有。
一个 Config 对象，可能被多个模块读取。
一个资源对象，可能多个使用者都需要保证它暂时别被释放。
```

这时如果还硬用裸指针，就容易出现：

```text
A 以为对象还活着
B 已经 delete 了对象
A 再访问，变成 dangling pointer
```

所以今天引入 `std::shared_ptr`。

---

### 2. 今日术语

#### shared ownership：共享所有权

意思是：

```text
一个对象不再只有一个 owner。
多个 shared_ptr 可以共同拥有同一个对象。
只要还有至少一个 shared_ptr 活着，对象就不能被释放。
最后一个 shared_ptr 析构时，对象才释放。
```

重点不是“多个指针指向同一个对象”，裸指针也可以做到这一点。重点是：

```text
这些 shared_ptr 共同决定对象生命周期。
```

---

#### reference count：引用计数

`shared_ptr` 内部大概会维护一个计数：

```text
有几个 shared_ptr 正在拥有这个对象。
```

当你 copy 一个 `shared_ptr`：

```text
计数 +1
```

当某个 `shared_ptr` 析构或被重新赋值：

```text
计数 -1
```

当计数变成 0：

```text
对象被释放
```

今天只建立这个直觉，不深挖控制块实现。

---

#### weak_ptr：弱引用 / 不拥有对象的观察者

`weak_ptr` 可以指向一个由 `shared_ptr` 管理的对象，但它不增加引用计数。

也就是说：

```text
weak_ptr 可以观察对象
但 weak_ptr 不负责延长对象生命
```

它最重要的用途之一：

```text
打破 shared_ptr 循环引用
```

---

#### lock()

`weak_ptr` 不能直接像普通指针那样访问对象。你要先调用：

```cpp
auto p = weak.lock();
```

如果对象还活着：

```text
p 是一个有效的 shared_ptr
```

如果对象已经释放：

```text
p 是 nullptr
```

所以 `lock()` 的意思可以理解成：

```text
我先确认一下这个对象还活着吗？如果还活着，就临时拿一个 shared_ptr 用一下。
```

---

### 3. 今天先别误解的点

`shared_ptr` 不是默认答案。

```text
unique_ptr：默认优先，表达独占所有权
shared_ptr：只有真的需要共享生命周期时才用
weak_ptr：观察 shared_ptr 管理的对象，但不拥有它
裸指针：可以表达 non-owning pointer，但不能负责释放资源
```

一句话：

```text
能 unique_ptr 就不要 shared_ptr。
需要共享生命周期，再考虑 shared_ptr。
有环，就必须警惕 weak_ptr。
```

---

## Part B：教程主体

### 1. 今天从什么问题出发？

今天的问题是：

```text
如果一个对象被多个地方共同使用，它到底什么时候释放？
```

举个直觉场景：

```text
有一个 Resource 对象。
main 函数里要用它。
另一个函数也要临时保存它。
你希望只要还有人用它，它就不能析构。
等最后一个使用者离开，它再析构。
```

如果用裸指针：

```text
谁 delete？
什么时候 delete？
另一个人会不会还在用？
```

如果用 `unique_ptr`：

```text
只能有一个 owner。
不能 copy 给别人共同拥有。
```

所以这里才轮到 `shared_ptr` 上场。

---

### 2. shared_ptr 的最小例子

先写一个能观察构造和析构的对象：

```cpp
#include <iostream>
#include <memory>

class Resource {
public:
    explicit Resource(int id) : id_(id) {
        std::cout << "Resource construct id=" << id_ << '\n';
    }

    ~Resource() {
        std::cout << "Resource destruct id=" << id_ << '\n';
    }

    int id() const {
        return id_;
    }

private:
    int id_;
};

int main() {
    auto p1 = std::make_shared<Resource>(1);
    std::cout << "count after p1=" << p1.use_count() << '\n';

    {
        auto p2 = p1;
        std::cout << "count after p2=" << p1.use_count() << '\n';
        std::cout << "p2 id=" << p2->id() << '\n';
    }

    std::cout << "count after p2 dead=" << p1.use_count() << '\n';
    return 0;
}
```

你要观察的不是语法，而是生命周期：

```text
p1 创建对象，count 是 1
p2 = p1，共享对象，count 变成 2
p2 离开作用域，count 回到 1
main 结束，p1 析构，count 变成 0，对象释放
```

编译：

```bash
g++ -std=c++17 -Wall -Wextra -g 01_shared_ptr_basic.cpp -o r
./r
```

---

### 3. use_count 能看，但不要依赖它写业务逻辑

`use_count()` 对学习很有用，因为它能帮你观察引用计数变化。

但是工程里不要写这种逻辑：

```cpp
if (p.use_count() == 1) {
    // 我觉得只有我在用，所以做某件事
}
```

原因先记直觉：

```text
引用计数是生命周期管理细节，不应该成为业务判断核心。
以后多线程场景下，这个数还可能马上变化。
```

今天你可以用它观察现象，但不要把它当设计工具。

---

### 4. shared_ptr 为什么会有循环引用问题？

现在看今天最重要的坑。

假设有两个对象：

```text
Person A 持有 Person B
Person B 也持有 Person A
```

如果它们互相用 `shared_ptr` 指向对方，就会出现：

```text
A 的引用计数降不到 0，因为 B 还持有 A
B 的引用计数降不到 0，因为 A 还持有 B
```

结果：

```text
main 都结束了，但 A / B 的析构函数没有执行
```

这就是循环引用。

代码：

```cpp
#include <iostream>
#include <memory>
#include <string>

class Person {
public:
    explicit Person(std::string name) : name_(std::move(name)) {
        std::cout << "Person construct " << name_ << '\n';
    }

    ~Person() {
        std::cout << "Person destruct " << name_ << '\n';
    }

    void set_friend(std::shared_ptr<Person> other) {
        friend_ = other;
    }

private:
    std::string name_;
    std::shared_ptr<Person> friend_;
};

int main() {
    auto a = std::make_shared<Person>("A");
    auto b = std::make_shared<Person>("B");

    a->set_friend(b);
    b->set_friend(a);

    return 0;
}
```

你应该看到：

```text
construct 有输出
但 destruct 没有输出
```

这不是对象没创建成功，而是它们互相把对方“吊住”了。

---

### 5. weak_ptr 怎么打破这个环？

问题的核心是：

```text
friend_ 这个关系一定要拥有对方吗？
```

很多时候不是。

比如：

```text
A 知道 B 是自己的 friend
但 A 不一定负责延长 B 的生命周期
```

这种“知道 / 观察 / 访问前检查”的关系，就适合 `weak_ptr`。

把成员改成：

```cpp
std::weak_ptr<Person> friend_;
```

完整代码：

```cpp
#include <iostream>
#include <memory>
#include <string>
#include <utility>

class Person {
public:
    explicit Person(std::string name) : name_(std::move(name)) {
        std::cout << "Person construct " << name_ << '\n';
    }

    ~Person() {
        std::cout << "Person destruct " << name_ << '\n';
    }

    void set_friend(const std::shared_ptr<Person>& other) {
        friend_ = other;
    }

    void print_friend() const {
        auto p = friend_.lock();
        if (p != nullptr) {
            std::cout << name_ << " friend is " << p->name_ << '\n';
        } else {
            std::cout << name_ << " friend is gone\n";
        }
    }

private:
    std::string name_;
    std::weak_ptr<Person> friend_;
};

int main() {
    auto a = std::make_shared<Person>("A");
    auto b = std::make_shared<Person>("B");

    a->set_friend(b);
    b->set_friend(a);

    a->print_friend();
    b->print_friend();

    return 0;
}
```

这次你应该看到析构输出。

因为：

```text
a 和 b 是真正的 shared_ptr owner
friend_ 只是 weak_ptr 观察者
weak_ptr 不增加引用计数
main 结束时，a / b 正常释放
```

---

### 6. shared_ptr / weak_ptr 和后面项目的关系

先不要急着到处用 `shared_ptr`。

后面写系统组件时，大概会遇到这些场景：

```text
ThreadPool 里的任务对象：有时会被队列和 worker 临时持有
Reactor 里的 Connection：可能被 EventLoop、Channel、回调共同牵涉
AsyncLogger：资源所有权一般更适合 unique_ptr 或直接成员对象
```

你今天只需要建立一个判断框架：

```text
对象只有一个明确 owner：优先 unique_ptr 或直接成员对象
对象需要多个 owner 共同延长生命：shared_ptr
对象只是观察 shared_ptr 管理的对象：weak_ptr
对象只是临时借用，不负责生命周期：裸指针或引用
```

---

## Part C：练习、检查和收尾

### 1. 今日代码目录

建议放在：

```bash
~/code/system-learning/cpp/week2/day5
```

今天写三个文件：

```text
01_shared_ptr_basic.cpp
02_shared_ptr_cycle.cpp
03_weak_ptr_break_cycle.cpp
```

每个都要能编译运行。

---

### 2. 练习一：shared_ptr 基础

文件：

```text
01_shared_ptr_basic.cpp
```

要求：

```text
1. 写一个 Resource 类
2. 构造 / 析构都打印
3. 用 make_shared 创建对象
4. copy 一个 shared_ptr
5. 用 use_count 观察引用计数变化
6. 能解释对象什么时候析构
```

验收输出里至少能看到：

```text
construct
count 变化
destruct
```

---

### 3. 练习二：循环引用

文件：

```text
02_shared_ptr_cycle.cpp
```

要求：

```text
1. 写两个互相持有 shared_ptr 的对象
2. 构造 / 析构都打印
3. main 结束时观察析构是否发生
4. 在 note 里解释为什么没析构
```

今天这个 demo 的重点是：

```text
它能编译运行，但逻辑上有资源泄漏问题。
```

你要学会区分：

```text
编译通过 != 资源管理正确
程序结束 != 没有泄漏风险
```

---

### 4. 练习三：weak_ptr 打破循环

文件：

```text
03_weak_ptr_break_cycle.cpp
```

要求：

```text
1. 把互相持有的一边或双方改成 weak_ptr
2. 用 weak_ptr::lock() 访问对象
3. main 结束时确认析构发生
4. 解释 weak_ptr 为什么不增加引用计数
```

注意：

```text
weak_ptr 不是裸指针。
它知道对象是否还活着。
但它不拥有对象。
```

---

### 5. 编译命令

每个文件都用：

```bash
g++ -std=c++17 -Wall -Wextra -g 文件名.cpp -o r
./r
```

如果你想用 ASan 检查，可以额外跑：

```bash
g++ -std=c++17 -Wall -Wextra -g -fsanitize=address 02_shared_ptr_cycle.cpp -o r
./r
```

注意：循环引用这种泄漏，ASan 不一定默认在所有环境都稳定报出来；今天主要靠析构打印观察。

---

### 6. day5_note.md 要写什么

今天 note 不需要长，但要把关键点写准。

建议结构：

```markdown
# Day5 Note

## shared_ptr 是什么
- ...

## shared_ptr 和 unique_ptr 的区别
- ...

## use_count 我观察到了什么
- ...

## 循环引用为什么泄漏
- ...

## weak_ptr 为什么能解决
- ...

## 今天代码里最关键的一行
- ...

## 我还没想明白的问题
- ...
```

---

### 7. 今日验收问题

你写完后，用自己的话回答：

```text
1. shared_ptr 解决的到底是什么问题？
2. shared_ptr 和 unique_ptr 的核心区别是什么？
3. copy 一个 shared_ptr 时，资源有没有被复制？
4. use_count 增加说明了什么？
5. 为什么 shared_ptr 互相指向会导致析构不发生？
6. weak_ptr 为什么不增加引用计数？
7. weak_ptr::lock() 返回的是什么？
8. 什么时候你会优先 unique_ptr，而不是 shared_ptr？
```

---

### 8. 今天不要提前深挖

今天不展开：

```text
shared_ptr 控制块实现
make_shared 的内存布局优化
enable_shared_from_this
shared_ptr 多线程引用计数细节
自定义 deleter
循环引用的复杂工程设计
```

这些以后会遇到，但今天的目标是先把生命周期直觉打准。

---

### 9. git commit 建议

如果今天代码和 note 都完成，可以提交：

```bash
cd ~/code/system-learning
git status
git add cpp/week2/day5
git commit -m "week2 day5 shared weak ptr"
```

---

### 10. 下一天衔接

Day6 会进入：

```text
异常安全初步 + copy-and-swap
```

今天的 `shared_ptr / weak_ptr` 仍然是“生命周期管理”。Day6 会换一个角度看同一件事：

```text
如果函数执行到一半 throw 了，已经申请的资源还能不能正确释放？
```

这会把 Week1 的 RAII、Week2 的智能指针和后续工程代码连接起来。
