# Week3 Day1：vector 内存模型 + size / capacity + 扩容

> 今日定位：Week3 的第一天，不背 vector API。  
> 今天从一个具体问题出发：**为什么一次普通的 `push_back`，可能让 vector 里所有元素都搬家，并让旧地址失效？**

---

## Part A：前情提要和术语

### 1. 前情提要：Week2 为什么是 vector 的前置

Week2 你已经学过：

```text
copy：复制独立资源
move：转移资源所有权
std::move：把表达式转换成可匹配移动操作的右值表达式
noexcept：承诺函数不会让异常逃出
RAII：对象析构时自动释放资源
```

今天它们会一起出现。

假设：

```cpp
std::vector<Buffer> buffers;
```

当 vector 当前空间不够时，它需要申请一块更大的连续内存，再把已有的 `Buffer` 搬过去。

这时必须回答：

```text
是 copy 每个 Buffer，还是 move 每个 Buffer？
move 会不会抛异常？
搬完后旧 Buffer 怎样析构？
旧内存何时释放？
原来指向元素的指针还能不能用？
```

所以 Week3 不是换了一门课，而是在标准容器里继续使用 Week2。

---

### 2. 今日术语

#### contiguous storage：连续存储

`std::vector<T>` 的元素在内存中连续排列。

可以把它想成：

```text
[T0][T1][T2][T3]
```

这意味着：

```text
可以通过下标快速访问
对 CPU cache 通常比较友好
可以用 data() 拿到底层首地址
空间不够时不能原地随便接一块，需要整体搬到更大的连续区域
```

---

#### size

```cpp
v.size()
```

表示 vector 当前真正拥有多少个已经构造好的元素。

例如：

```cpp
std::vector<int> v{10, 20, 30};
```

此时：

```text
size == 3
```

---

#### capacity

```cpp
v.capacity()
```

表示在不重新申请内存的前提下，当前这块存储最多能容纳多少个元素。

可能出现：

```text
size == 3
capacity == 4
```

意思是：

```text
已经构造了 3 个元素
当前内存还能再放 1 个元素
```

capacity 不是元素数量，不可以因为 capacity 大就直接用下标访问未构造位置。

---

#### reallocation：重新分配 / 扩容搬迁

当 `size == capacity`，继续添加元素时，vector 可能需要：

```text
1. 申请一块更大的连续内存
2. 把旧元素 copy 或 move 到新内存
3. 析构旧内存中的元素
4. 释放旧内存
5. 在新内存中完成新元素插入
```

这个过程叫 reallocation。

---

#### data()

```cpp
v.data()
```

返回 vector 底层连续存储的**首地址**。

观察 `data()` 是否变化，是今天判断 vector 是否搬家的直接方式。

---

#### reserve

```cpp
v.reserve(100);
```

要求 vector 提前准备至少能容纳 100 个元素的空间。

重点：

```text
reserve 改变 capacity
reserve 不改变 size
reserve 不会凭空创建 100 个元素
```

---

#### resize

```cpp
v.resize(100);
```

把当前元素数量调整为 100。

重点：

```text
resize 改变 size
变大时会创建新元素
变小时会析构尾部元素
必要时也可能增加 capacity
```

---

### 3. 今天必须分清的一组概念

```text
size：已经存在的元素数量
capacity：当前内存最多能容纳的元素数量
reserve：提前准备空间，不创建元素
resize：改变元素数量，会构造或析构元素
```

这段代码是错误的：

```cpp
std::vector<int> v;
v.reserve(10);
v[0] = 42;  // 错误：size 仍然是 0
```

`reserve(10)` 只准备内存，没有创建 `v[0]`。

正确方式之一：

```cpp
v.push_back(42);
```

或者：

```cpp
v.resize(10);
v[0] = 42;
```

---

## Part B：教程主体

### 1. 今天从什么问题出发？

看下面代码：

```cpp
std::vector<int> values;
values.push_back(10);

int* old_ptr = &values[0];

values.push_back(20);
values.push_back(30);
values.push_back(40);
```

问题：

```text
old_ptr 还能一直使用吗？
```

答案是：不能保证。

某次 `push_back` 可能触发扩容。扩容后元素搬到新内存，`old_ptr` 仍保存旧地址，而旧地址对应的内存已经释放。

这就是为什么理解 vector 不能只会写：

```cpp
v.push_back(x);
```

你还必须知道这次操作有没有改变底层存储。

---

### 2. vector 的直觉模型

概念上，可以把 vector 想象成保存了三个位置：

```text
begin：底层内存起点
end：最后一个已构造元素之后
capacity_end：当前内存末尾
```

示意：

```text
begin             end          capacity_end
  |                |                |
  v                v                v
[10][20][30][未使用][未使用][未使用]
```

于是：

```text
size     = end - begin
capacity = capacity_end - begin
```

这只是帮助理解的模型，不要求你现在研究 libstdc++ 内部字段。

---

### 3. push_back 没有触发扩容时

如果：

```text
size < capacity
```

当前内存还有空位。

例如：

```text
添加前：[10][20][未使用][未使用]
size=2, capacity=4

添加后：[10][20][30][未使用]
size=3, capacity=4
```

这种情况下通常不需要整体搬家，`data()` 地址不会变化。

---

### 4. push_back 触发扩容时

如果：

```text
size == capacity
```

已经没有空位。

扩容过程可以理解成：

```text
旧内存：[10][20]

申请更大的新内存：[_][_][_][_]

搬运已有元素：[10][20][_][_]

插入新元素：[10][20][30][_]

析构旧元素并释放旧内存
```

因此：

```text
data() 地址可能改变
旧元素地址失效
旧指针、旧引用、旧迭代器可能失效
```

迭代器失效会在 Day2 专门展开。今天先把“为什么失效”理解清楚。

---

### 5. capacity 的增长倍率不是标准保证

你运行代码时可能看到：

```text
0 -> 1 -> 2 -> 4 -> 8 -> 16
```

也可能在其他环境看到不同序列。

C++ 标准不要求 vector 必须按两倍增长。因此不要写依赖具体倍率的逻辑：

```cpp
// 不要假设下一次 capacity 一定等于当前 capacity * 2
```

你可以依赖的是：

```text
capacity 表示当前可容纳数量
空间不足时 vector 会获得足够的新存储
重新分配会影响地址和迭代器
```

---

### 6. 代码一：观察 size / capacity / data 地址

文件：

```text
01_vector_growth.cpp
```

代码：

```cpp
#include <cstddef>
#include <iostream>
#include <vector>

int main() {
    std::vector<int> values;

    const int* previous_data = values.data();

    for (int value = 0; value < 20; ++value) {
        const std::size_t old_capacity = values.capacity();

        values.push_back(value);

        const bool address_changed = values.data() != previous_data;
        const bool capacity_changed = values.capacity() != old_capacity;

        std::cout
            << "push=" << value
            << " size=" << values.size()
            << " capacity=" << values.capacity()
            << " data=" << static_cast<const void*>(values.data())
            << " address_changed=" << std::boolalpha << address_changed
            << " capacity_changed=" << capacity_changed
            << '\n';

        previous_data = values.data();
    }

    return 0;
}
```

你需要观察：

```text
size 每次增加 1
capacity 不是每次都变化
capacity 变化时，data 地址通常也变化
没有扩容时，多次 push_back 可以使用同一块底层内存
```

不要只截图输出，要在 note 里写一条你观察到的规律。

---

### 7. reserve 到底解决什么问题？

假设你已经知道大概要插入 10000 个元素：

```cpp
std::vector<int> values;
values.reserve(10000);

for (int i = 0; i < 10000; ++i) {
    values.push_back(i);
}
```

提前 `reserve` 可以减少扩容次数，也就减少：

```text
重复申请内存
重复搬运元素
旧地址反复失效
```

但不要这样写：

```cpp
for (int i = 0; i < 10000; ++i) {
    values.reserve(values.size() + 1);
    values.push_back(i);
}
```

这样可能破坏 vector 原本的增长策略，导致几乎每次都重新分配，反而很慢。

工程判断：

```text
已知大致元素数量：可以提前 reserve
完全不知道数量：先让 vector 自己增长
不要为了“优化”而盲目 reserve 巨大空间
```

---

### 8. reserve 和 resize 的观察代码

可以在 `01_vector_growth.cpp` 末尾追加：

```cpp
std::vector<int> numbers;

numbers.reserve(8);
std::cout
    << "after reserve: size=" << numbers.size()
    << " capacity=" << numbers.capacity()
    << '\n';

numbers.resize(8);
std::cout
    << "after resize: size=" << numbers.size()
    << " capacity=" << numbers.capacity()
    << '\n';
```

你应该看到：

```text
reserve 后 size 仍是 0
resize 后 size 变成 8
```

对于 `vector<int>`，`resize(8)` 新增的元素会被值初始化为 `0`。

这和你刚学过的：

```cpp
new int[8]{}
```

有相似的“基础类型清零”直觉。

---

### 9. 扩容时 copy 还是 move？

如果 vector 元素是 `int`，搬运成本很直观。

如果元素是你写过的资源类：

```cpp
std::vector<Buffer> buffers;
```

扩容时 vector 需要在新内存中构造已有元素。

它可能使用：

```text
拷贝构造：深拷贝资源，通常更贵
移动构造：转移资源，通常更便宜
```

如果移动构造承诺 `noexcept`，标准库更容易在保持异常安全的前提下选择 move。

这就是 Week2 的 `noexcept` 在 STL 中的第一个真实落点。

---

### 10. 代码二：观察 vector 搬运对象

文件：

```text
02_vector_move_observe.cpp
```

代码：

```cpp
#include <iostream>
#include <utility>
#include <vector>

class Item {
public:
    explicit Item(int id) : id_(id) {
        std::cout << "construct id=" << id_ << '\n';
    }

    Item(const Item& other) : id_(other.id_) {
        std::cout << "copy construct id=" << id_ << '\n';
    }

    Item(Item&& other) noexcept : id_(other.id_) {
        std::cout << "move construct id=" << id_ << '\n';
        other.id_ = -1;
    }

    ~Item() {
        std::cout << "destruct id=" << id_ << '\n';
    }

private:
    int id_;
};

int main() {
    std::vector<Item> items;

    for (int id = 1; id <= 5; ++id) {
        std::cout << "\n--- before emplace id=" << id << " ---\n";
        std::cout
            << "size=" << items.size()
            << " capacity=" << items.capacity()
            << '\n';

        items.emplace_back(id);

        std::cout
            << "after: size=" << items.size()
            << " capacity=" << items.capacity()
            << '\n';
    }

    return 0;
}
```

你要观察：

```text
什么时候只构造新 Item
什么时候除了构造新 Item，还出现已有 Item 的 move construct
move 后的旧 Item 为什么会析构
capacity 变化和 move 日志是否对应
```

输出顺序可能受标准库实现细节影响，不要求逐行和教程预想一致。你只需要确认：

```text
发生扩容时，已有元素需要搬到新存储。
```

---

### 11. noexcept 对照实验

第一次运行保持：

```cpp
Item(Item&& other) noexcept
```

第二次临时去掉 `noexcept`：

```cpp
Item(Item&& other)
```

再次编译运行，观察已有元素搬运时，GCC 当前标准库更倾向打印：

```text
copy construct
```

原因直觉：

```text
move 可能抛异常
copy 又可用
为了更容易保持扩容失败前的状态，vector 可能选择 copy
```

注意：

```text
不要把日志的精确顺序或 capacity 倍率当成跨平台标准保证。
今天观察的是 copy / move / noexcept 之间的关系。
```

实验结束后把 `noexcept` 加回来。

---

### 12. push_back 和 emplace_back 今天先知道多少？

代码二用了：

```cpp
items.emplace_back(id);
```

它会使用参数在 vector 的存储位置直接构造新元素。

而：

```cpp
items.push_back(Item(id));
```

表达的是把一个已有对象放进 vector，可能发生 copy 或 move。

但不要得出：

```text
emplace_back 永远比 push_back 快
```

具体区别和常见误区放到 Day2。今天只要能看懂代码即可。

---

### 13. 今天与系统项目的关系

后面的系统项目经常保存一批对象：

```text
连接列表
待处理任务
网络缓冲区
日志批次
定时器节点
```

如果用 vector，你必须知道：

```text
它的连续内存通常 cache 友好
扩容可能搬运全部元素
保存元素地址时要警惕扩容失效
已知数量时 reserve 可以减少搬运
元素的 move/noexcept 会影响搬运成本和异常安全
```

这就是“会用 vector”和“知道工程含义”的区别。

---

## Part C：练习、检查和收尾

### 1. 今日代码目录

Ubuntu：

```bash
~/code/system-learning/cpp/week3/day1
```

创建：

```text
01_vector_growth.cpp
02_vector_move_observe.cpp
```

今天不手写 vector，也不写复杂封装。

---

### 2. 编译命令

```bash
g++ -std=c++17 -Wall -Wextra -g 01_vector_growth.cpp -o r
./r
```

```bash
g++ -std=c++17 -Wall -Wextra -g 02_vector_move_observe.cpp -o r
./r
```

要求：

```text
两个文件都能编译运行
不保留 -Wall / -Wextra warning
能解释主要输出，不要求记住具体 capacity 序列
```

---

### 3. 练习一验收

`01_vector_growth.cpp` 至少观察并回答：

```text
1. 前 20 次 push_back 中，capacity 变化了几次？
2. capacity 变化时，data 地址是否同时变化？
3. capacity 没变化时，data 地址是否保持不变？
4. reserve(8) 后 size 是多少？
5. resize(8) 后 size 是多少？
6. 为什么 reserve 后不能直接写 v[0]？
```

注意：只记录你机器上的现象，不把增长倍率写成 C++ 标准保证。

---

### 4. 练习二验收

`02_vector_move_observe.cpp` 至少完成：

```text
1. 运行 noexcept move 版本
2. 找到一次 capacity 变化
3. 观察扩容时已有元素的 move construct
4. 临时去掉 noexcept 再运行
5. 比较 copy / move 日志
6. 实验后恢复 noexcept
```

不用逐行抄输出，只写结论。

---

### 5. 中途检查

看到下面代码，先口头判断：

```cpp
std::vector<int> v;
v.reserve(100);
```

此时：

```text
v.size() 是多少？
v.capacity() 至少是多少？
v[0] 是否存在？
```

再看：

```cpp
v.resize(100);
```

此时：

```text
v.size() 是多少？
新增 int 的值是什么？
```

如果这组问题还会混，就回到 Part A，不需要继续加 API。

---

### 6. day1_note.md

建议放在：

```text
C:\Users\FxorG\Desktop\gpt_infra\week3\day1\day1_note.md
```

你不需要抄教程，只写：

```markdown
# Week3 Day1 Note

## 我观察到的 vector 扩容
- size / capacity 变化：...
- data 地址变化：...

## reserve / resize
- ...

## copy / move / noexcept
- ...

## 验收问题
- ...

## 我还不稳的点
- ...
```

---

### 7. 今日验收问题

```text
1. vector 为什么需要连续内存？
2. size 和 capacity 的区别是什么？
3. vector 扩容大概经历哪些步骤？
4. 为什么扩容后旧元素地址可能失效？
5. capacity 的增长倍率是标准规定的吗？
6. reserve 和 resize 的区别是什么？
7. 为什么 reserve(10) 后不能直接使用 v[0]？
8. 已知将插入大量元素时，reserve 有什么价值？
9. 为什么不应该在每次 push_back 前 reserve(size()+1)？
10. vector 扩容时，copy 和 move 分别意味着什么成本？
11. noexcept move 为什么可能影响 vector 的选择？
12. vector 连续内存对系统项目有什么优势和风险？
```

---

### 8. 面试追问

常见问法：

```text
vector 底层怎么扩容？
vector 扩容后迭代器为什么失效？
size 和 capacity 有什么区别？
reserve 和 resize 有什么区别？
vector 扩容时为什么有时 copy、有时 move？
```

你回答时不要只背“二倍扩容”。更好的表达是：

```text
vector 使用连续存储。
空间不足时申请更大的连续区域，把已有元素 copy 或 move 过去，再释放旧区域。
因此旧地址和迭代器可能失效。
具体增长倍率由实现决定，不是标准固定为两倍。
```

---

### 9. 今天不要提前深挖

```text
不手写 vector
不深挖 allocator
不研究 libstdc++ 源码
不证明摊还复杂度
不展开全部迭代器失效规则
不深挖 emplace_back 完美转发
```

今天只把这条线打通：

```text
连续内存
→ size / capacity
→ 空间不足
→ 申请新内存
→ copy / move 已有元素
→ 释放旧内存
→ 旧地址失效
```

---

### 10. 6.S081 / 15-445

```text
6.S081：今天不开
15-445：今天不开
```

继续保持 C++ STL 主线，不让伴随课程抢节奏。

---

### 11. Git 提交建议

```bash
cd ~/code/system-learning
git status
git add cpp/week3/day1
git commit -m "week3 day1 vector growth and move"
```

如果只是实验中临时删掉 `noexcept`，提交前记得恢复。

---

### 12. 下一天衔接

Day2 会接着解决：

```text
既然扩容会搬家，哪些指针、引用和迭代器会失效？
erase 之后怎样继续遍历？
push_back 和 emplace_back 到底差在哪里？
```

Day1 先理解“为什么会失效”，Day2 再学习“怎样安全使用”。

