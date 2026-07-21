# Week3 Day5：unordered_map / unordered_set + rehash

> 今日定位：承接 Day4 的容器选择，进入无序关联容器。  
> 今天从一个具体问题出发：**以后写 Reactor 时，需要维护 `fd -> Connection`。连接会持续加入和退出，只要求按 fd 精确查找，不需要按 fd 排序和范围查询，是否还应该使用 `map`？**

---

## Part A：前情提要和术语

### 1. 前情提要：Day4 的选择依据

Day4 已经建立：

```text
map / set 按比较器保持有序
find / insert / erase 通常是 O(log n)
lower_bound / upper_bound 适合范围查询
map / set 插入不会让已有迭代器失效
节点式存储有额外内存和 cache locality 代价
```

今天的需求不同：

```text
只按完整 key 精确查找
不需要按 key 有序遍历
不需要 lower_bound 和范围查询
希望平均情况下更快地插入和查找
```

这时可以考虑：

```text
unordered_map：key -> value
unordered_set：只保存 key
```

它们的核心结构不是有序树，而是哈希表。

---

### 2. unordered 的含义

`unordered` 表示容器**不提供按 key 排序的遍历顺序保证**。

```cpp
std::unordered_map<int, std::string> connections;

connections.emplace(30, "c30");
connections.emplace(10, "c10");
connections.emplace(20, "c20");
```

遍历时：

```cpp
for (const auto& [fd, name] : connections) {
    std::cout << fd << ' ' << name << '\n';
}
```

不能假设输出为：

```text
10 20 30
```

也不能依赖当前机器上碰巧观察到的顺序。插入元素或发生 rehash 后，遍历顺序还可能变化。

---

### 3. bucket 是什么

`bucket` 通常译为“桶”。

可以先把哈希表画成：

```text
bucket 0 -> [key A] -> [key D]
bucket 1 -> [key B]
bucket 2 -> empty
bucket 3 -> [key C]
```

查找 key 时，直觉流程是：

```text
1. 对 key 计算 hash value
2. 标准库根据 hash value 定位一个 bucket
3. 只在该 bucket 的候选元素中比较 key
```

常用观察接口：

```cpp
table.bucket_count();     // 当前 bucket 数量
table.bucket(key);        // 某个 key 当前位于哪个 bucket
table.bucket_size(index); // 某个 bucket 中有多少元素
```

不要假设 bucket 数量一定是质数、2 的幂，也不要依赖具体的 bucket 映射公式。不同标准库实现可能不同。

---

### 4. hash 不是唯一编号

默认情况下，`unordered_map<Key, Value>` 会使用：

```cpp
std::hash<Key>
```

hash 函数把 key 转换为一个 `std::size_t`：

```text
key -> hash value
```

但 hash value 不是 key 的唯一身份证：

```text
不同 key 可以得到相同 hash value
不同 hash value 也可能被放进同一个 bucket
```

因此哈希冲突是正常现象，不等于程序出错。

容器还需要 key equality 判断候选元素是否真的是目标 key。默认通常使用：

```cpp
std::equal_to<Key>
```

自定义 hash 和 equality 时必须满足：

```text
如果两个 key 被 equality 判断为相等，它们必须得到相同 hash value
```

反过来不要求成立：相同 hash value 的 key 可以不相等。

---

### 5. 哈希冲突会发生什么

假设多个 key 进入同一个 bucket：

```text
bucket 2 -> [10] -> [42] -> [99]
```

查找时需要在这些候选元素中继续做 equality 比较。

如果 hash 分布较好：

```text
元素分散在许多 bucket
每个 bucket 中候选元素较少
查找平均接近 O(1)
```

如果大量 key 挤进同一 bucket：

```text
一次查找可能需要检查许多元素
最坏情况可能退化到 O(n)
```

所以“unordered_map 查询是 O(1)”必须说完整：

```text
平均 / 期望情况下 O(1)
最坏情况下 O(n)
```

---

### 6. load factor

`load factor` 是当前平均每个 bucket 承担的元素数量：

```text
load_factor = size / bucket_count
```

接口：

```cpp
table.load_factor();
table.max_load_factor();
```

直觉上：

```text
load factor 越高，每个 bucket 平均承担的元素越多
冲突和比较次数可能增加
```

但它只是平均值，不代表每个 bucket 一样长。

当插入元素会让 load factor 超过允许上限时，容器通常需要增加 bucket 数量并重新组织元素，这就是 rehash。

---

### 7. rehash 到底做什么

rehash 可以画成：

```text
旧 bucket array
0 -> A -> D
1 -> B
2 -> C

        重新计算每个元素属于哪个 bucket
                     |
                     v

新 bucket array
0 -> D
1 -> B
2 -> A
3 -> empty
4 -> C
```

注意：

```text
key-value 元素没有被删除
但 bucket 数量和内部组织发生了变化
遍历顺序可能变化
原有迭代器全部失效
```

exact bucket growth policy 由实现决定。不要背某次运行中观察到的增长倍率。

---

### 8. rehash 的失效规则

这是今天最重要的 STL 语义。

对 `unordered_map` / `unordered_set`：

```text
插入没有触发 rehash：已有迭代器通常仍有效
插入触发 rehash：所有已有迭代器失效
显式 rehash：所有已有迭代器失效
erase：只有指向被删除元素的迭代器和引用失效
```

一个容易漏掉的细节：

```text
rehash 会让迭代器失效
但不会让指向元素的引用和指针失效
```

因此，下面两者要区分：

```cpp
auto it = table.find(key);       // iterator
Value* ptr = &it->second;        // pointer to element
```

rehash 后：

```text
不能再使用旧 it
ptr 仍然可以指向原元素
```

前提是该元素没有被 erase，容器也没有析构。

工程上最清楚的做法仍然是：容器结构修改后，如果需要迭代器，就重新 `find()` 获取，不拿旧迭代器赌实现细节。

---

### 9. reserve 和 rehash 的区别

#### reserve

```cpp
table.reserve(1000);
```

表达的是：

```text
我预计会存放大约 1000 个元素
请提前准备足够 bucket，减少插入过程中的反复 rehash
```

#### rehash

```cpp
table.rehash(1000);
```

表达的是：

```text
请让 bucket_count 至少达到实现允许的、不小于该要求的数量
```

所以：

```text
按预计元素数量准备容量：优先使用 reserve
直接控制最少 bucket 数量：使用 rehash
```

调用 `reserve(1000)` 后，最终 bucket 数量不一定正好是 1000，因为容器还要结合 `max_load_factor()` 和实现策略选择 bucket 数量。

如果准备调整 `max_load_factor()`，通常先调整它，再调用 `reserve()`。

---

### 10. operator[] 的规则没有变

Day4 学到的规则同样适用于 `unordered_map`：

```cpp
std::unordered_map<int, std::string> connections;
connections[10];
```

如果 key `10` 不存在，会插入新元素，并对 mapped value 做值初始化。

只查询是否存在时仍然使用：

```cpp
auto it = connections.find(10);

if (it != connections.end()) {
    // found
}
```

今天不重复展开 `operator[]`，只记住换成 unordered 容器后，它的插入副作用并没有消失。

---

## Part B：教程主体

### 1. 教程从什么问题开始

假设 Reactor 中维护：

```text
fd -> Connection
```

常见操作是：

```text
新连接到来：insert
事件到来：根据 fd find
连接关闭：erase
```

通常不需要：

```text
按 fd 从小到大遍历
查询 fd 范围 [100, 200]
lower_bound
```

这时：

```text
map 能做，但付出了维护顺序的成本
unordered_map 不维护顺序，平均精确查找更符合需求
```

但使用 unordered_map 前必须知道：

```text
平均 O(1) 不是永远 O(1)
插入可能触发 rehash
rehash 会让所有迭代器失效
批量插入前 reserve 可以减少内部重组
```

---

### 2. 代码一：观察 rehash 和迭代器失效边界

文件：

```text
01_unordered_rehash.cpp
```

代码：

```cpp
#include <cstddef>
#include <iostream>
#include <string>
#include <unordered_map>

using Table = std::unordered_map<int, std::string>;

void print_state(const Table& table, const char* stage) {
    std::cout
        << stage
        << " size=" << table.size()
        << " bucket_count=" << table.bucket_count()
        << " load_factor=" << table.load_factor()
        << " max_load_factor=" << table.max_load_factor()
        << '\n';
}

int main() {
    Table connections;
    connections.max_load_factor(0.7F);
    connections.reserve(4);

    connections.emplace(1, "client-1");
    connections.emplace(2, "client-2");
    connections.emplace(3, "client-3");

    print_state(connections, "before rehash");

    auto saved = connections.find(1);
    const std::string* saved_value_address = &saved->second;
    const std::size_t old_bucket_count = connections.bucket_count();

    int next_fd = 100;
    while (connections.bucket_count() == old_bucket_count) {
        connections.emplace(next_fd, "extra-client");
        ++next_fd;
    }

    print_state(connections, "after rehash");

    // saved 已因 rehash 失效，不能再使用；重新 find 获取迭代器。
    const auto fresh = connections.find(1);
    std::cout
        << "value address unchanged=" << std::boolalpha
        << (&fresh->second == saved_value_address)
        << '\n';

    std::unordered_map<int, int> prepared;
    prepared.max_load_factor(0.7F);
    prepared.reserve(100);
    const std::size_t prepared_bucket_count = prepared.bucket_count();

    for (int key = 0; key < 100; ++key) {
        prepared.emplace(key, key * 10);
    }

    std::cout
        << "reserved table size=" << prepared.size()
        << " bucket_count unchanged="
        << (prepared.bucket_count() == prepared_bucket_count)
        << '\n';

    return 0;
}
```

你要观察：

```text
max_load_factor 设置后，reserve 如何准备 bucket
持续插入后 bucket_count 在什么时候发生变化
rehash 前后 load_factor 如何变化
为什么 rehash 后不再使用 saved
为什么重新 find 得到的元素地址仍可与旧指针相同
reserve(100) 后插入 100 个元素为什么没有反复改变 bucket_count
```

不要背输出中的具体 bucket 数量。你只观察变化关系。

---

### 3. 为什么旧 iterator 不能用，但元素指针还能用

迭代器除了定位元素，还要能够按照容器当前的内部组织执行：

```cpp
++it;
```

rehash 后，bucket 组织已经改变，旧迭代器携带的遍历状态不再有效。

但元素对象本身不需要因此搬到一个全新的对象地址，所以标准保证元素引用和指针不因 rehash 失效。

这和 vector 扩容不同：

```text
vector 扩容：元素通常搬到新连续内存，指针 / 引用 / 迭代器都失效
unordered_map rehash：bucket 组织变化，迭代器失效，元素引用 / 指针仍有效
```

这正是本周“不同容器有不同失效规则”的核心。

---

### 4. 代码二：故意制造哈希冲突

文件：

```text
02_hash_collision_observe.cpp
```

代码：

```cpp
#include <cstddef>
#include <iostream>
#include <string>
#include <unordered_map>

struct ConstantHash {
    std::size_t operator()(int) const noexcept {
        return 0;
    }
};

struct CountingEqual {
    inline static std::size_t comparisons = 0;

    bool operator()(int lhs, int rhs) const noexcept {
        ++comparisons;
        return lhs == rhs;
    }
};

using BadTable = std::unordered_map<
    int,
    std::string,
    ConstantHash,
    CountingEqual>;

int main() {
    BadTable table;
    table.max_load_factor(100.0F);
    table.rehash(1);

    for (int key : {10, 20, 30, 40, 50}) {
        table.emplace(key, "value");
    }

    const std::size_t bucket_index = table.bucket(10);
    std::cout
        << "size=" << table.size()
        << " bucket_count=" << table.bucket_count()
        << " shared_bucket=" << bucket_index
        << " bucket_size=" << table.bucket_size(bucket_index)
        << '\n';

    std::cout << "keys in shared bucket:";
    for (auto it = table.begin(bucket_index);
         it != table.end(bucket_index);
         ++it) {
        std::cout << ' ' << it->first;
    }
    std::cout << '\n';

    CountingEqual::comparisons = 0;
    const auto found = table.find(30);
    std::cout
        << "find 30=" << std::boolalpha
        << (found != table.end())
        << " equality comparisons=" << CountingEqual::comparisons
        << '\n';

    CountingEqual::comparisons = 0;
    const auto missing = table.find(999);
    std::cout
        << "find 999=" << (missing != table.end())
        << " equality comparisons=" << CountingEqual::comparisons
        << '\n';

    return 0;
}
```

这里的 `ConstantHash` 是故意写坏的：

```cpp
return 0;
```

意味着每个 key 得到相同 hash value，因此全部进入同一个 bucket。

你要观察：

```text
bucket_size 是否等于元素数量
同一个 bucket 的局部迭代器怎样遍历
找到已有 key 时需要做若干次 equality 比较
查找不存在的 key 时为什么可能检查整个 bucket
为什么最坏查找会退化到 O(n)
```

不同实现的 bucket 内顺序和精确比较次数可能不同，不要把某次输出当成标准保证。

---

### 5. local iterator 是什么

平时：

```cpp
table.begin();
table.end();
```

遍历整个容器。

指定 bucket：

```cpp
table.begin(bucket_index);
table.end(bucket_index);
```

得到的是 local iterator，只遍历该 bucket。

它主要用于：

```text
观察 bucket 分布
调试哈希冲突
理解哈希表内部组织
```

普通业务代码通常不需要手动遍历 bucket。

---

### 6. map、unordered_map、vector 怎么选

#### 选择 map

```text
需要按 key 有序遍历
需要 lower_bound / upper_bound
需要范围查询
希望复杂度更稳定地保持 O(log n)
```

#### 选择 unordered_map

```text
主要做完整 key 的精确查找
不需要顺序和范围查询
hash 和 equality 定义自然
能接受平均 O(1)、最坏 O(n)
能管理 rehash 带来的迭代器失效
```

#### 选择 vector 或 sorted vector

```text
数据量较小
一次构建、多次遍历或查询
重视连续内存和 cache locality
可以批量排序，而不是持续维护动态顺序
```

还要考虑：

```text
unordered_map 有 bucket array 和节点等额外开销
字符串 key 的 hash 本身也要扫描字符串
小数据场景里 unordered_map 不一定更快
```

所以不要把容器选择简化成：

```text
O(1) 一定比 O(log n) 快
```

---

### 7. 与后续项目的关系

#### Reactor

```text
fd -> Connection
```

通常只做精确查找，`unordered_map` 很自然。已知大致最大连接数时，可以提前 `reserve()`，减少运行中的 rehash。

#### Mini Redis

```text
key -> value
```

哈希表是重要基础。今天理解的冲突、负载因子和扩容，会成为后面理解 Redis dict 的前置，但现在不读 Redis 源码。

#### LRU Cache

Day7 会使用：

```text
unordered_map：O(1) 平均查找 key
list：O(1) 调整最近使用顺序
```

今天先把 unordered_map 的失效规则弄稳，避免 Day7 只会背“list + unordered_map”。

---

## Part C：练习、检查和收尾

### 1. 今日代码目录

Ubuntu：

```bash
~/code/system-learning/cpp/week3/day5
```

创建：

```text
01_unordered_rehash.cpp
02_hash_collision_observe.cpp
```

今天不要求手写哈希表，也不额外增加重复 API 练习。

---

### 2. 编译命令

```bash
g++ -std=c++17 -Wall -Wextra -g 01_unordered_rehash.cpp -o r
./r
```

```bash
g++ -std=c++17 -Wall -Wextra -g 02_hash_collision_observe.cpp -o r
./r
```

要求：

```text
零 warning
两个程序都能运行
不使用 rehash 前保存的旧迭代器
不依赖 bucket 数量、遍历顺序和精确比较次数
```

---

### 3. 练习一验收

```text
1. bucket_count 表示什么？
2. load_factor 怎样计算？
3. max_load_factor 控制什么？
4. 插入为什么可能触发 rehash？
5. rehash 后为什么不能使用旧迭代器？
6. rehash 后元素指针和引用为什么仍然有效？
7. reserve(n) 中的 n 表示元素数量还是 bucket 数量？
8. 为什么不应该背某次运行的 bucket 增长倍率？
```

---

### 4. 练习二验收

```text
1. 什么叫哈希冲突？
2. 不同 key 为什么可以进入同一个 bucket？
3. hash 相同是否表示 key 相等？
4. equality 判断相等的 key 对 hash 有什么要求？
5. ConstantHash 为什么让所有元素进入同一 bucket？
6. 为什么查找不存在的 key 可能检查整个 bucket？
7. unordered_map 为什么平均 O(1)，最坏 O(n)？
8. local iterator 与普通 iterator 的范围有什么不同？
```

哈希原理对你不难，验收重点是 STL 的具体保证，不需要重新证明散列表复杂度。

---

### 5. 中途判断题

#### 遍历顺序

```cpp
std::unordered_map<int, int> values;
values.emplace(3, 30);
values.emplace(1, 10);
values.emplace(2, 20);
```

能否断言遍历顺序为 `1 2 3`？能否依赖当前运行观察到的顺序？

#### rehash

```cpp
auto it = values.find(1);
values.rehash(values.bucket_count() * 2);
```

之后能否继续使用 `it`？如果事先保存 `int* ptr = &it->second`，`ptr` 是否仍有效？

#### reserve

```cpp
values.reserve(1000);
```

它是否表示 bucket_count 必须正好等于 1000？它主要想解决什么问题？

#### hash contract

假设 `KeyEqual(a, b) == true`，但 `Hash(a) != Hash(b)`，这个自定义 hash/equality 组合是否正确？

---

### 6. day5_note.md

建议放在：

```text
C:\Users\FxorG\Desktop\gpt_infra\week3\day5\day5_note.md
```

你不用抄哈希表基础。只记录此前不熟的 STL 行为，例如：

```markdown
# Week3 Day5 Note

## reserve / rehash
- ...

## rehash 失效规则
- iterator：...
- pointer / reference：...

## 哈希冲突实验
- ...

## map / unordered_map 选择
- ...

## 代码错误或观察
- ...
```

如果某部分对你完全是旧知识，可以不写；验收时能解释即可。

---

### 7. 今日验收问题

```text
1. unordered_map 和 map 的核心组织方式有什么不同？
2. unordered_map 的 unordered 具体不保证什么？
3. 一次精确查找大概经过哪几个步骤？
4. bucket、bucket_count、bucket_size 分别是什么？
5. 什么是哈希冲突？冲突是否代表 hash 函数错误？
6. load_factor 和 max_load_factor 有什么关系？
7. 什么情况下可能触发 rehash？
8. reserve 和 rehash 的参数语义有什么不同？
9. rehash 分别怎样影响 iterator、pointer 和 reference？
10. 插入没有触发 rehash 时，已有迭代器是否失效？
11. erase 会让哪些迭代器和引用失效？
12. 为什么 unordered_map 平均 O(1) 但最坏 O(n)？
13. 为什么 unordered_map 不一定比 map 或 vector 更快？
14. Reactor 的 fd -> Connection 为什么通常适合 unordered_map？
15. 已知预计元素数量时，为什么建议提前 reserve？
```

不要求把这些问题逐题写进 note，只要求能用自己的话回答真正的 STL 语义。

---

### 8. 面试追问

```text
unordered_map 的底层结构是什么？
发生哈希冲突怎么办？
load factor 是什么？
reserve 和 rehash 有什么区别？
rehash 会导致什么失效？
unordered_map 为什么不是永远 O(1)？
map 和 unordered_map 怎么选？
为什么批量插入前建议 reserve？
```

推荐回答主线：

```text
先说 bucket + hash + equality
再说冲突和 load factor
再说 rehash 与失效规则
最后结合有序需求、最坏复杂度、内存和实际场景做容器选择
```

不要只回答：

```text
map O(log n)，unordered_map O(1)
```

---

### 9. 今天不要提前深挖

```text
不手写工业级哈希表
不研究 libstdc++ bucket 策略源码
不背质数扩容或 2 的幂扩容细节
不深挖开放寻址、Robin Hood hashing 等变体
不研究哈希攻击防御
不实现复杂自定义 key hash
不展开 Redis 渐进式 rehash 源码
不深挖 allocator
```

---

### 10. 6.S081 / 15-445

```text
6.S081：今天不开
15-445：今天不开
```

继续保持 Week3 的 STL 行为主线。

---

### 11. Git 提交建议

```bash
cd ~/code/system-learning
git status
git add cpp/week3/day5
git commit -m "week3 day5 unordered containers and rehash"
```

---

### 12. 下一天衔接

Day6 将不再是容器观察 demo，而是第一个本周小组件：

```text
固定容量 RingBuffer V1
vector 作为底层连续存储
head / tail / size
空、满和绕回边界
```

Day1 到 Day5 已经完成了 STL 行为铺垫。Day6 开始把这些知识变成边界明确、可测试、可解释的工程代码。
