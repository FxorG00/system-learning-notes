# Week2 Day7：Week2 出口验收 + Week3 入口判断

> 今日定位：今天不再学习一个新的大知识点，也不重复手写 Buffer。  
> Day1 到 Day6 已经完成，今天只做两件事：确认 Week2 的知识链是否真正连起来，以及判断能否进入 Week3 的 STL 主线。

---

## Part A：前情提要和术语

### 1. 你的实际进度

Week2 到目前已经完成：

```text
Day1：从深拷贝成本理解 move 的问题来源
Day2：移动构造、右值引用、std::move 初步
Day3：移动赋值、Rule of Five、noexcept 直觉
Day4：unique_ptr、独占所有权、move-only 资源类
Day5：shared_ptr、weak_ptr、引用计数、循环引用
Day6：栈展开、RAII 异常安全、copy-and-swap
```

这些内容你都已经写过代码并经过 review，其中资源管理代码也用 ASan 验证过。因此 Day7 不要求：

```text
不重新写 Rule of Five Buffer
不重新写 unique_ptr / shared_ptr demo
不重新制造循环引用
不重新抄 Day1 到 Day6 的笔记
不重复跑已经通过的 ASan 测试
```

今天要检查的是：

```text
遇到一个资源管理问题时，你能不能自己选对方案并解释原因？
```

---

### 2. Week2 的完整知识链

你这周学的不是六个互不相关的语法点，而是一条线：

```text
资源需要复制
→ 深拷贝
→ 深拷贝可能很贵
→ move 转移资源
→ std::move 让表达式可以匹配移动操作
→ unique_ptr 表达独占所有权
→ shared_ptr 表达共享所有权
→ weak_ptr 表达不拥有对象的观察关系
→ 异常发生时依靠 RAII 自动释放资源
→ copy-and-swap 让赋值失败时原对象保持不变
```

Week2 真正的关键词只有三个：

```text
生命周期
所有权
失败路径
```

---

### 3. 今天需要用准的术语

#### copy

```text
创建一份独立状态。
对 owning raw pointer 类来说，通常意味着重新申请资源并复制内容。
```

#### move

```text
把资源所有权从源对象转移到目标对象。
源对象仍然必须可以安全析构和重新赋值。
```

#### std::move

```text
std::move 本身不移动资源。
它只是把表达式转换成可被移动构造 / 移动赋值匹配的右值表达式。
真正转移资源的是移动构造或移动赋值。
```

#### moved-from object

```text
被移动后的对象仍然是有效对象，但具体值不应随意假设。
如果类自己规定移动后 size_=0、data_=nullptr，那么可以依赖这个类的规定。
默认移动不会自动把所有普通成员清零。
```

#### ownership

```text
ownership 关心谁负责决定资源生命周期、谁负责最终释放资源。
```

#### strong exception safety

```text
操作要么成功，要么对象保持操作前的状态。
copy-and-swap 的关键是：可能失败的复制发生在修改 this 之前，成功后只做 noexcept swap。
```

---

### 4. 一个新结论：优先 Rule of Zero

你学会 Rule of Five，不代表以后每个类都要手写五个函数。

如果类直接管理 owning raw pointer：

```text
你需要认真考虑析构、拷贝构造、拷贝赋值、移动构造、移动赋值。
```

如果类用标准 RAII 类型管理资源：

```cpp
class Buffer {
private:
    std::size_t size_{};
    std::unique_ptr<char[]> data_;
};
```

析构和资源释放已经交给 `unique_ptr`。很多时候可以让编译器生成或删除特殊成员函数，这就是 Rule of Zero 的方向：

```text
能让成员对象管理资源，就不要让当前类手写资源释放。
```

今天只记这个工程结论，不深挖规则组合。

---

## Part B：教程主体

### 1. 今天从什么问题出发？

今天的问题是：

```text
为什么学完 copy / move / noexcept / 智能指针之后，下一周才能开始系统学习 vector？
```

考虑一个场景：

```cpp
std::vector<Buffer> buffers;
buffers.push_back(Buffer(1024));
```

以后 `vector` 空间不够时，需要把已有元素搬到新内存。

它必须面对这些问题：

```text
Buffer 能不能 copy？
Buffer 能不能 move？
move 会不会抛异常？
搬移失败后，原来的 vector 能不能保持有效？
Buffer 的资源会不会泄漏或 double free？
```

这正是 Week2 的全部内容。

所以 Week2 不是独立语法周，而是在给 Week3 的 STL 行为打地基。

---

### 2. noexcept 为什么会连接到 vector？

假设 `vector` 扩容时正在搬运已有元素。

如果移动构造写成：

```cpp
Buffer(Buffer&& other) noexcept;
```

标准库知道移动不会抛异常，就**更有信心**使用 move 搬运元素。

如果移动可能抛异常，而 copy 又可用，标准库为了尽量保持原容器状态，可能选择 copy。

今天不用证明标准库的完整选择规则，只要建立这个连接：

```text
noexcept 不只是注释。
它会影响标准库是否敢使用移动操作。
```

但不要滥加 `noexcept`：

```text
只有确定执行路径不会让异常逃出时，才做这个承诺。
```

---

### 3. 所有权选择表

以后看到一个资源关系，可以先按下面判断。

| 场景 | 优先选择 | 原因 |
|---|---|---|
| 对象本身就是成员的一部分 | 直接成员对象 | 生命周期最简单 |
| 只有一个 owner | `std::unique_ptr` | 表达独占所有权 |
| 多个 owner 必须共同延长生命 | `std::shared_ptr` | 共享所有权和引用计数 |
| 只观察 shared_ptr 管理的对象 | `std::weak_ptr` | 不增加引用计数 |
| 临时借用，不负责释放 | 引用或裸指针 | non-owning 关系 |
| 必须直接管理特殊裸资源 | RAII 封装类 | 析构统一释放 |

默认思路：

```text
直接成员对象
→ unique_ptr
→ 确实需要时才 shared_ptr
```

不要因为 `shared_ptr` 会自动释放，就把它当成默认智能指针。

---

### 4. 特殊成员函数选择表

| 类的情况 | 需要考虑什么 |
|---|---|
| 只有普通成员和标准 RAII 成员 | 优先 Rule of Zero |
| 直接拥有 raw pointer | Rule of Three / Five |
| 必须独占资源且不能复制 | 删除 copy，支持 move |
| 需要深拷贝语义 | 自定义 copy constructor / copy assignment |
| move 只转移指针和普通状态 | move 尽量 `noexcept` |

这里最重要的不是背规则名字，而是先问：

```text
这个类是否直接负责释放某个资源？
```

如果答案是“否”，通常没必要急着手写特殊成员函数。

---

### 5. 五个代码片段判断

今天不要求运行这些代码。你要先在脑中判断，再把答案写进 `day7_note.md`。

#### 片段一

```cpp
auto p1 = std::make_unique<int>(42);
auto p2 = p1;
```

回答：

```text
能否编译？
如果不能，违反了什么所有权语义？
应该如何转移？
```

#### 片段二

```cpp
Buffer a(10);
Buffer b = std::move(a);
```

回答：

```text
std::move 做了什么？
真正转移资源的是谁？
a 之后至少要满足什么要求？
能否默认断言 a.size() == 0？
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
哪一条关系适合改成 weak_ptr？
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
这个版本可能满足基本异常安全吗？
怎样调整顺序更稳？
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
拷贝失败时为什么 this 不变？
swap 后旧资源去了哪里？
为什么它能处理 self-assignment？
```

---

### 6. 系统项目里的落点

这些知识以后不是为了继续写 Buffer，而是会出现在：

```text
ThreadPool：任务对象和线程对象的生命周期
AsyncLogger：日志缓冲区和后台线程资源
Reactor：Connection / Channel 的所有权关系
Mini Redis：连接、命令对象、缓存数据的生命周期
Linux fd / socket：异常或提前 return 时必须关闭
```

你以后看到系统项目里的指针，第一反应应该是：

```text
这是 owner 还是 observer？
谁保证它活着？
异常或提前退出时谁释放？
能不能 move？
```

这就是 Week2 对后续主线的价值。

---

## Part C：练习、检查和收尾

### 1. 今天不写新 demo

你的 Day1 到 Day6 代码已经覆盖：

```text
深拷贝
移动构造 / 移动赋值
Rule of Five
unique_ptr
shared_ptr / weak_ptr
异常路径 RAII
copy-and-swap
ASan
```

所以今天不创建新的 `.cpp`。不要为了凑文件重复劳动。

---

### 2. 今日唯一笔记产出

创建：

```text
C:\Users\FxorG\Desktop\gpt_infra\week2\day7\day7_note.md
```

不需要写“本周学了什么”这种重复总结，只写下面三部分：

```markdown
# Day7 Note

## 五个代码片段判断
1. ...
2. ...
3. ...
4. ...
5. ...

## Week2 验收问题
1. ...
2. ...

## 我还不稳的点
- 没有就写“暂时没有”
- 有就只写具体问题
```

---

### 3. Week2 最终验收问题

请用自己的话回答，不查定义式答案：

```text
1. copy 和 move 在资源处理上有什么本质区别？
2. std::move 本身到底做了什么？
3. 移动构造和移动赋值的区别是什么？
4. moved-from 对象至少要满足什么要求？
5. Rule of Five 是哪五个函数？什么时候不需要手写它们？
6. unique_ptr 为什么不能 copy，但可以 move？
7. shared_ptr 解决什么问题，又引入什么风险？
8. weak_ptr 为什么能打破循环引用？lock() 返回什么？
9. throw 之后，为什么 RAII 资源仍能释放？
10. copy assignment 里先 delete 再 new 有什么风险？
11. copy-and-swap 为什么更容易提供强异常安全？
12. 哪些函数适合写 noexcept？为什么 move 的 noexcept 对 vector 有意义？
```

回答标准：

```text
不要求书面定义。
能说清对象、资源、生命周期和失败路径即可。
已经在前几天笔记里完整回答过的，可以简答，不需要重复展开。
```

---

### 4. 进入 Week3 的判断标准

满足下面条件，就进入 STL：

```text
能解释 std::move 不负责真正移动
能解释 moved-from 对象仍要有效
能根据所有权选择 unique_ptr / shared_ptr / weak_ptr
能解释循环引用
能解释异常时 RAII 为什么不泄漏
能解释 copy-and-swap 的资源流转
知道 noexcept 是承诺，不能随便添加
现有 Week2 demo 已能编译运行并经过 ASan 检查
```

根据 Day1 到 Day6 的实际完成情况，你目前已经满足代码侧条件。Day7 note 的作用只是确认表达和判断也过关。

---

### 5. Git 收尾

今天没有新 C++ demo，不需要制造无意义提交。

如果 Week2 的最终修改还没提交，可以统一提交：

```bash
cd ~/code/system-learning
git status
git add cpp/week2
git commit -m "finish week2 ownership move exception safety"
```

如果已经提交完成，只运行 `git status` 确认工作区状态即可。

---

### 6. 6.S081 / 15-445

今天仍然不正式开启：

```text
6.S081：不占 Day7 主线
15-445：不开
```

Week3 仍然以 C++ STL 和工程数据结构为主，不让伴随线抢进度。

---

### 7. 下一周衔接

Day7 通过后进入 Week3：

```text
STL + 工程数据结构第一轮
```

第一条主线会从 `vector` 开始：

```text
size / capacity
连续内存
扩容
copy / move 搬运元素
noexcept 的实际影响
迭代器为什么会失效
```

这会直接复用 Week2，而不是把 Week2 放下后另开一门课。

