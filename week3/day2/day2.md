# Week3 Day2：迭代器失效 + push_back / emplace_back / erase

> 今日定位：承接 Day1 的 vector 扩容。  
> 今天从一个具体问题出发：**我保存了一个指向 vector 元素的迭代器，随后执行 `push_back` 或 `erase`，它为什么可能突然不能用了？**

---

## Part A：前情提要和术语

### 1. 前情提要：Day1 已经解释了“为什么会失效”

Day1 你已经观察到：

```text
vector 使用连续内存
size == capacity 时继续插入会触发扩容
扩容时申请新内存
已有元素 copy / move 到新内存
旧对象析构
旧内存释放
data() 地址改变
```

你还通过错误实验确认了：

```cpp
std::vector<int> v;
v.reserve(100);
v[0] = 1;  // 错误：capacity 有空间，但 size 仍为 0
```

这说明 STL 的风险经常不是“有没有申请内存”，而是：

```text
这个元素是否真的存在？
这个地址是否仍然属于当前元素？
这个迭代器是否还有效？
```

今天就解决第三个问题。

---

### 2. iterator：迭代器

迭代器可以先理解成：

```text
用于定位和遍历容器元素的对象。
```

例如：

```cpp
std::vector<int> values{10, 20, 30};

auto it = values.begin();
std::cout << *it << '\n';  // 10

++it;
std::cout << *it << '\n';  // 20
```

这里：

```text
begin()：指向第一个元素
end()：指向最后一个元素之后的位置
*it：访问当前元素
++it：移动到下一个元素
```

注意：

```text
end() 不指向真实元素，不能解引用。
```

---

### 3. invalidation：失效

迭代器失效的意思不是变量 `it` 消失了，而是：

```text
it 里面保存的定位信息已经不能再用于访问原来的元素。
```

例如扩容后：

```text
旧内存：[10][20][30]
             ^ it

新内存：[10][20][30][_][_][_]
             ^ 新位置
```

`it` 仍然记录旧内存中的位置，而旧内存已经释放。

继续：

```cpp
std::cout << *it;
```

就是未定义行为。

---

### 4. 不只是 iterator 会失效

你可能保存三种东西：

```cpp
auto it = values.begin();  // 迭代器
int* p = &values[0];       // 指针
int& ref = values[0];      // 引用
```

如果 vector 扩容导致元素搬家，那么：

```text
it 失效
p 失效
ref 失效
```

所以以后说“vector 迭代器失效”，通常也要想到：

```text
指向元素的指针和引用是否也失效？
```

---

### 5. 今天涉及的操作

#### push_back

```cpp
v.push_back(value);
```

把一个已经存在的对象 copy 或 move 到 vector 尾部。

#### emplace_back

```cpp
v.emplace_back(args...);
```

使用参数直接在 vector 尾部构造元素。

#### erase

```cpp
auto next = v.erase(it);
```

删除 `it` 指向的元素，并返回**删除位置之后**的新迭代器。

对于 vector，删除中间元素后，后面的元素通常需要向前移动填补空位。

---

## Part B：教程主体

### 1. 今天从什么问题出发？

看下面代码：

```cpp
std::vector<int> values{10, 20, 30};
auto it = values.begin();

values.push_back(40);

std::cout << *it << '\n';
```

最后一行是否安全？

答案是：

```text
取决于 push_back 是否触发了重新分配。
```

如果发生扩容：

```text
所有指向旧元素的迭代器、指针和引用全部失效。
```

如果没有扩容：

```text
原有元素没有搬家，指向原有元素的迭代器、指针和引用仍然有效；
但旧的 end() 会失效，因为“最后一个元素之后”的位置改变了。
```

这就是 vector 使用中最常见的生命周期问题之一。

---

### 2. vector 常见失效规则

先掌握下面这张表，不需要今天背所有标准细节。

| 操作 | 发生重新分配时 | 未发生重新分配时 |
|---|---|---|
| `push_back / emplace_back` | 所有迭代器、指针、引用失效 | 原有元素句柄有效，旧 `end()` 失效 |
| `reserve` | 如果 capacity 增大，全部失效 | capacity 没变则不失效 |
| `insert` | 全部失效 | 插入位置及之后失效 |
| `erase` | 不会因为 erase 扩容 | 被删除位置及之后失效 |

这里的“句柄”是方便表达：

```text
迭代器
指针
引用
```

工程上不要只背表，要问原因：

```text
扩容：所有元素搬家，所以全部失效。
insert：中间元素可能向后移动，所以插入位置及之后失效。
erase：后续元素向前移动，所以删除位置及之后失效。
```

---

### 3. 为什么 erase 会让后面的迭代器失效？

例如：

```text
[10][20][30][40]
```

删除 `20` 后，vector 仍然必须连续：

```text
[10][30][40]
```

原来的 `30`、`40` 都向前移动了。

所以：

```text
指向 20 的迭代器失效
指向原 30 的迭代器失效
指向原 40 的迭代器失效
指向 10 的迭代器仍然有效
```

`erase` 会返回一个新迭代器：

```cpp
auto next = values.erase(it);
```

`next` 指向删除后接替该位置的元素；如果删除的是最后一个元素，则返回新的 `end()`。

---

### 4. 错误的边遍历边删除

下面写法有问题：

```cpp
for (auto it = values.begin(); it != values.end(); ++it) {
    if (*it % 2 == 0) {
        values.erase(it);
    }
}
```

问题是：

```text
erase(it) 后，it 已经失效。
循环结尾又对失效的 it 执行 ++it。
```

正确写法：

```cpp
for (auto it = values.begin(); it != values.end();) {
    if (*it % 2 == 0) {
        it = values.erase(it);
    } else {
        ++it;
    }
}
```

逻辑是：

```text
删除了：使用 erase 返回的新迭代器，不额外 ++it
没删除：正常 ++it
```

---

### 5. 代码一：安全观察扩容失效和 erase 返回值

文件：

```text
01_iterator_invalidation.cpp
```

代码：

```cpp
#include <cstddef>
#include <cstdint>
#include <iostream>
#include <vector>

int main() {
    std::vector<int> values;
    values.reserve(4);

    int next_value = 10;
    while (values.size() < values.capacity()) {
        values.push_back(next_value);
        next_value += 10;
    }

    auto old_it = values.begin();
    const int old_value = *old_it;
    const std::uintptr_t old_address =
        reinterpret_cast<std::uintptr_t>(values.data());
    const std::size_t old_capacity = values.capacity();

    std::cout
        << "before reallocation: value=" << old_value
        << " size=" << values.size()
        << " capacity=" << old_capacity
        << " data=" << old_address
        << '\n';

    values.push_back(999);  // size == capacity，必然需要更多存储

    const std::uintptr_t new_address =
        reinterpret_cast<std::uintptr_t>(values.data());

    std::cout
        << "after reallocation: size=" << values.size()
        << " capacity=" << values.capacity()
        << " data=" << new_address
        << " address_changed=" << std::boolalpha
        << (old_address != new_address)
        << '\n';

    // old_it 已失效，不能再解引用。

    std::vector<int> numbers{10, 20, 30, 40, 50};
    auto erase_pos = numbers.begin() + 1;
    auto next_it = numbers.erase(erase_pos);

    std::cout << "erase returned value=" << *next_it << '\n';
    std::cout << "after erase:";
    for (int value : numbers) {
        std::cout << ' ' << value;
    }
    std::cout << '\n';

    return 0;
}
```

你要解释：

```text
为什么 push_back 前先填满 capacity
为什么这次 push_back 一定需要更多存储
为什么只保存旧地址的整数值用于比较
为什么扩容后不再解引用 old_it
为什么 erase 返回的迭代器指向 30
```

---

### 6. 负面实验：让调试模式抓住失效迭代器

你 Day1 已经用过错误实验。今天可以继续，但要明确标注“故意错误”。

临时写：

```cpp
std::vector<int> values;
values.reserve(1);
values.push_back(10);

auto it = values.begin();
values.push_back(20);  // 当前环境中触发扩容

std::cout << *it << '\n';  // 故意错误：解引用失效迭代器
```

使用：

```bash
g++ -std=c++17 -Wall -Wextra -g -D_GLIBCXX_DEBUG bad_iterator.cpp -o r
./r
```

libstdc++ 调试模式通常会直接报告：

```text
attempt to dereference a singular iterator
```

这个实验结束后不要把错误代码混进正常 demo。

---

### 7. push_back 的三种常见情况

假设元素类型是 `Item`。

#### 传入左值

```cpp
Item item(1);
items.push_back(item);
```

`item` 仍然要保留自己的状态，所以通常调用 copy constructor。

#### 传入右值

```cpp
items.push_back(Item(2));
```

先构造临时 `Item(2)`，再把它 move 到 vector 的元素位置。

#### 直接在尾部构造

```cpp
items.emplace_back(3);
```

用参数 `3` 直接在 vector 的尾部存储位置调用 `Item(int)`。

---

### 8. emplace_back 不是无条件更快

`emplace_back` 的优势主要是：

```text
可以直接使用构造参数创建新元素，避免先手动创建临时对象。
```

但如果你已经有一个对象：

```cpp
Item item(1);
```

写：

```cpp
items.push_back(item);
```

语义很清楚：保留 `item`，向 vector 复制一份。

不要为了统一使用 emplace 而写难懂的代码。

还要注意：

```text
emplace_back 只影响新元素如何构造。
如果本次插入触发扩容，已有元素仍然需要 copy / move。
```

所以它不会消除 vector 扩容成本。

---

### 9. 代码二：隔离观察 push / emplace，并安全 erase

文件：

```text
02_push_emplace_erase.cpp
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
    items.reserve(3);  // 避免三次插入之间发生扩容，隔离新元素构造行为

    Item first(1);

    std::cout << "\n--- push_back lvalue ---\n";
    items.push_back(first);

    std::cout << "\n--- push_back rvalue ---\n";
    items.push_back(Item(2));

    std::cout << "\n--- emplace_back ---\n";
    items.emplace_back(3);

    std::cout << "\n--- erase even numbers ---\n";
    std::vector<int> numbers{1, 2, 3, 4, 5, 6};

    for (auto it = numbers.begin(); it != numbers.end();) {
        if (*it % 2 == 0) {
            it = numbers.erase(it);
        } else {
            ++it;
        }
    }

    for (int value : numbers) {
        std::cout << value << ' ';
    }
    std::cout << '\n';

    return 0;
}
```

预期观察：

```text
push_back(first)：copy construct
push_back(Item(2))：临时对象 construct，然后 move construct
emplace_back(3)：直接 construct
删除偶数后：1 3 5
```

因为提前 `reserve(3)`，这里不会混入已有元素扩容搬迁日志。

---

### 10. insert 的直觉

虽然今天不要求专门写 insert demo，但要知道：

```cpp
values.insert(values.begin() + 1, 99);
```

vector 必须保持连续：

```text
插入前：[10][20][30]
插入后：[10][99][20][30]
```

即使 capacity 足够，原来的 `20`、`30` 也会向后移动。

因此在没有重新分配时：

```text
插入位置之前的句柄保持有效
插入位置及之后的句柄失效
```

如果插入触发重新分配，则全部失效。

---

### 11. 为什么系统代码特别在意失效？

以后 Reactor 可能出现类似结构：

```cpp
std::vector<Connection> connections;
Connection* current = &connections[0];
```

如果随后：

```cpp
connections.push_back(new_connection);
```

触发扩容，`current` 就可能变成悬空指针。

工程上常见解决方向：

```text
提前 reserve，减少重新分配
不长期保存 vector 元素地址
保存稳定的 id / index，并明确修改规则
根据需求选择地址更稳定的容器或间接存储
```

今天不急着选其他容器，先养成意识：

```text
容器发生结构修改后，旧句柄还能不能用？
```

---

## Part C：练习、检查和收尾

### 1. 今日代码目录

Ubuntu：

```bash
~/code/system-learning/cpp/week3/day2
```

创建：

```text
01_iterator_invalidation.cpp
02_push_emplace_erase.cpp
```

可选负面实验：

```text
03_bad_iterator_debug.cpp
```

如果保留负面实验，文件头必须标明它故意包含未定义行为，只用于 `_GLIBCXX_DEBUG` 检查。

---

### 2. 编译命令

```bash
g++ -std=c++17 -Wall -Wextra -g 01_iterator_invalidation.cpp -o r
./r
```

```bash
g++ -std=c++17 -Wall -Wextra -g 02_push_emplace_erase.cpp -o r
./r
```

负面实验：

```bash
g++ -std=c++17 -Wall -Wextra -g -D_GLIBCXX_DEBUG 03_bad_iterator_debug.cpp -o r
./r
```

---

### 3. 练习一验收

```text
1. 扩容前 old_it 指向什么？
2. 为什么 push_back(999) 后不能再解引用 old_it？
3. 为什么保存整数形式的旧地址用于打印，而不访问旧内存？
4. 如果 push_back 没有扩容，原有元素迭代器是否有效？
5. 没扩容时，旧 end() 为什么仍然失效？
6. erase 返回的迭代器表示什么？
```

---

### 4. 练习二验收

```text
1. 为什么先 reserve(3)？
2. push_back(first) 为什么 copy？
3. push_back(Item(2)) 为什么 move？
4. emplace_back(3) 少了哪个临时对象步骤？
5. emplace_back 是否能避免已有元素在扩容时搬迁？
6. 为什么 erase 后不能继续 ++ 原 it？
7. it = erase(it) 得到的是什么？
```

---

### 5. 中途判断题

#### 情况一

```cpp
std::vector<int> v;
v.reserve(100);
v.push_back(1);

int* p = &v[0];
v.push_back(2);
```

在 capacity 仍足够的前提下，`p` 是否仍有效？

#### 情况二

```cpp
auto it = v.end();
v.push_back(3);
```

即使没有扩容，旧 `end()` 是否仍有效？

#### 情况三

```cpp
std::vector<int> v{10, 20, 30, 40};
auto it = v.begin() + 2;  // 30
v.erase(v.begin() + 1);   // 删除 20
```

原来的 `it` 是否仍然可以解引用？为什么？

---

### 6. day2_note.md

建议放在：

```text
C:\Users\FxorG\Desktop\gpt_infra\week3\day2\day2_note.md
```

只记录今天的新判断：

```markdown
# Week3 Day2 Note

## vector 失效规则
- 扩容：...
- push_back 不扩容：...
- insert：...
- erase：...

## push_back / emplace_back
- ...

## erase 遍历写法
- ...

## 调试模式抓到的错误
- 没做负面实验可以不写

## 验收问题
- ...
```

---

### 7. 今日验收问题

```text
1. 什么叫迭代器失效？
2. vector 扩容后哪些句柄会失效？
3. push_back 没扩容时，哪些东西仍然失效？
4. erase 为什么会让删除位置及之后的迭代器失效？
5. erase 返回的迭代器指向哪里？
6. 怎样安全地边遍历 vector 边 erase？
7. push_back 左值时通常调用 copy 还是 move？
8. push_back 右值时通常调用 copy 还是 move？
9. emplace_back 的核心作用是什么？
10. 为什么不能说 emplace_back 永远更快？
11. emplace_back 能否避免扩容时搬运已有元素？
12. 为什么系统项目中长期保存 vector 元素地址有风险？
```

---

### 8. 面试追问

常见表达：

```text
vector 扩容会使哪些迭代器失效？
vector erase 后迭代器怎么处理？
push_back 和 emplace_back 有什么区别？
为什么 emplace_back 不一定更快？
```

推荐回答主线：

```text
先判断是否重新分配。
重新分配意味着全部元素搬家，所有元素句柄失效。
没有重新分配时，再根据插入或删除位置判断哪些元素发生移动。
```

---

### 9. 今天不要提前深挖

```text
不背所有容器的迭代器失效表
不深挖迭代器 category
不研究 allocator
不展开完美转发
不急着学 list 的稳定性细节
不提前学习 remove-erase idiom，Day3 配合 algorithm 再讲
```

---

### 10. 6.S081 / 15-445

```text
6.S081：不开
15-445：不开
```

继续保持 Week3 STL 主线。

---

### 11. Git 提交建议

```bash
cd ~/code/system-learning
git status
git add cpp/week3/day2
git commit -m "week3 day2 iterator invalidation and erase"
```

---

### 12. 下一天衔接

Day3 会进入：

```text
string 的动态存储和 c_str 指针失效
sort / find / lower_bound / remove_if
pair / tuple / optional 初步
```

今天学的是 vector 修改后句柄是否有效；Day3 会把同样的生命周期意识迁移到 string 和算法结果。

