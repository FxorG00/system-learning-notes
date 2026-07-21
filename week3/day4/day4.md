# Week3 Day4：map / set + 容器选择

> 今日定位：从连续容器进入有序关联容器。  
> 今天从一个具体问题出发：**任务会不断插入和删除，我既想按 deadline 查找，又想按 deadline 从小到大遍历，还想快速取出某个时间范围内的任务，应该用什么容器？**

---

## Part A：前情提要和术语

### 1. 前情提要：前几天的容器思维

Day1 到 Day3 已经建立了这些判断：

```text
vector / string 通常使用连续存储
vector 扩容后旧指针、引用和迭代器可能失效
算法通常操作 [first, last) 迭代器范围
选择容器不能只看一个复杂度数字
```

今天换一种需求：

```text
数据需要持续插入和删除
需要按 key 查找
需要始终按 key 有序遍历
需要 lower_bound / upper_bound 做范围定位
```

这时，维持有序的 `std::map` / `std::set` 往往比“每次修改后重新排序 vector”更自然。

---

### 2. associative container 是什么

`associative container` 常译为**关联容器**。

连续容器主要通过位置访问数据：

```cpp
values[3];
```

关联容器主要通过 key 组织和查找数据：

```cpp
scores.find("alice");
```

今天学习的两种容器：

```text
map：key -> value，每个 key 唯一
set：只保存 key，每个 key 唯一
```

例如：

```cpp
std::map<std::string, int> scores;
std::set<int> active_ports;
```

`map` 的一个元素可以理解为：

```cpp
std::pair<const Key, Value>
```

key 带 `const`，因为直接修改 key 会破坏整棵树的排列关系。想换 key，通常应该删除旧元素，再插入新元素。

---

### 3. “有序”是什么意思

`map` / `set` 的有序是：

```text
按照比较器定义的顺序排列
不是按照插入顺序排列
```

默认比较器是：

```cpp
std::less<Key>
```

所以默认按 key 从小到大遍历：

```cpp
std::map<int, std::string> tasks;
tasks.emplace(30, "flush log");
tasks.emplace(10, "heartbeat");
tasks.emplace(20, "check timeout");

for (const auto& [deadline, name] : tasks) {
    std::cout << deadline << ' ' << name << '\n';
}
```

输出顺序是：

```text
10 heartbeat
20 check timeout
30 flush log
```

不是 `30 10 20`。

---

### 4. 红黑树要理解到什么程度

常见标准库实现会使用红黑树一类的平衡搜索树实现 `map` / `set`。

但要注意：

```text
C++ 标准没有要求实现必须叫红黑树
标准保证的是有序行为和主要操作的对数复杂度
```

今天只建立结构直觉：

```text
普通二叉搜索树如果严重倾斜，查找可能退化
平衡树通过维护高度，让树不会过分倾斜
树高保持在 O(log n) 量级
查找 / 插入 / 删除通常因此是 O(log n)
```

不需要手推红黑树的染色和旋转。

---

### 5. 节点式存储

`vector` 通常把元素放在一整段连续内存里。

`map` / `set` 通常把每个元素放在独立的树节点中，节点之间通过指针连接。可以先画成：

```text
        [20]
       /    \
    [10]    [30]
```

这带来两类工程差异：

```text
优点：插入新节点通常不需要搬走已有元素
优点：已有元素的引用和迭代器通常更稳定
代价：节点、指针和单独分配会带来额外内存开销
代价：内存不连续，cache locality 通常不如 vector
```

因此，`O(log n)` 并不会自动战胜 vector。

---

### 6. map / set 的迭代器失效规则

这是今天和 Day1 / Day2 最重要的连接。

对 `map` / `set`：

```text
插入元素不会让已有元素的迭代器和引用失效
删除一个元素，只会让指向被删除元素的迭代器和引用失效
其他元素通常仍然有效
```

例如：

```cpp
auto saved = tasks.find(20);

tasks.emplace(25, "retry");
tasks.erase(10);

std::cout << saved->second << '\n';  // saved 仍指向 key=20
```

但如果执行：

```cpp
tasks.erase(saved);
```

之后就绝对不能再使用 `saved`。

---

### 7. 比较器不只负责排序

比较器还决定两个 key 是否被容器视为“等价”。

对比较器 `comp`，如果：

```cpp
!comp(a, b) && !comp(b, a)
```

容器就认为 `a` 和 `b` 是等价 key。

因此，自定义比较器必须满足严格弱序。当前先记住：

```text
通常写 < 关系
不要用 <= 作为比较器
比较规则必须稳定、不能前后矛盾
```

否则容器的行为可能出问题。

今天不要求写复杂自定义比较器，但要知道：**比较器既决定遍历顺序，也决定 key 是否重复。**

---

### 8. 常用查找和范围接口

#### find

```cpp
auto it = tasks.find(20);

if (it != tasks.end()) {
    std::cout << it->second << '\n';
}
```

找到时返回对应迭代器，找不到时返回 `end()`。

#### lower_bound

```cpp
auto it = tasks.lower_bound(20);
```

返回第一个 key **不小于 20** 的元素。

#### upper_bound

```cpp
auto it = tasks.upper_bound(20);
```

返回第一个 key **大于 20** 的元素。

所以查询闭区间 `[begin, end]` 可以写成：

```cpp
auto first = tasks.lower_bound(begin);
auto last = tasks.upper_bound(end);

for (auto it = first; it != last; ++it) {
    // 处理 begin <= key <= end 的元素
}
```

复杂度直觉：

```text
定位范围起点：O(log n)
遍历范围内 k 个元素：O(k)
总计：O(log n + k)
```

---

### 9. operator[] 会插入

这是 `map` 最常见的误用之一。

```cpp
std::map<std::string, int> scores;
int value = scores["alice"];
```

如果 `alice` 不存在，`operator[]` 不只是“查询失败”，而是会：

```text
插入 key 为 "alice" 的新元素
对 value 做值初始化
int 的值初始化结果是 0
返回该 value 的引用
```

所以 `operator[]` 很适合计数：

```cpp
++word_count[word];
```

但如果你只是想检查 key 是否存在，应使用：

```cpp
find()
```

如果你想读取且不存在时明确报错，可以使用：

```cpp
at()
```

`at()` 不会插入，不存在时会抛出 `std::out_of_range`。

还要区分：

```text
insert / emplace：key 已存在时不覆盖旧 value
insert_or_assign：存在就覆盖，不存在就插入
operator[]：不存在时先创建 value，再返回引用
```

今天不需要把所有插入接口背下来，先把“读取时不要无意识插入”记牢。

---

### 10. set 的元素为什么不能直接修改

`set` 的元素本身就是 key。

```cpp
std::set<int> ports{22, 80, 443};
```

如果允许把节点里的 `80` 原地改成 `10000`，树的有序关系可能立即失效。因此通过 `set` 迭代器拿到的元素不能直接修改。

需要更改时：

```text
erase 旧值
insert 新值
```

---

## Part B：教程主体

### 1. 教程从什么问题开始

假设我们写一个简化任务调度器：

```text
每个任务有 deadline
任务运行期间不断增加和取消
要快速找到指定 deadline
要找到第一个不早于 now 的任务
要遍历某个 deadline 范围
```

如果每次都用无序 vector：

```text
按 key 查找需要线性扫描
范围查询前需要排序
持续插入后还要维护顺序
```

如果用有序 `map<deadline, task>`：

```text
插入后容器继续保持有序
find 做精确查找
lower_bound 找第一个不早于某时间的任务
lower_bound + upper_bound 做范围查询
```

这就是今天使用 `map` 的核心理由：**需求本身需要动态有序和范围定位。**

为了简化 demo，下面假设 deadline 唯一。真实系统里多个任务可能拥有相同 deadline，可以考虑：

```text
multimap<deadline, task>
map<deadline, vector<task>>
或把 deadline + task_id 组成唯一 key
```

今天只知道这个边界，不展开 `multimap`。

---

### 2. 代码一：map / set 基本语义

文件：

```text
01_map_set_basic.cpp
```

代码：

```cpp
#include <cstddef>
#include <iostream>
#include <map>
#include <set>
#include <string>

int main() {
    std::map<std::string, int> word_count;

    ++word_count["redis"];
    ++word_count["reactor"];
    ++word_count["redis"];

    std::cout << "word_count in key order:\n";
    for (const auto& [word, count] : word_count) {
        std::cout << word << ' ' << count << '\n';
    }

    const std::size_t size_before = word_count.size();
    const auto missing = word_count.find("nginx");
    std::cout
        << "find nginx=" << std::boolalpha
        << (missing != word_count.end())
        << " size_changed="
        << (word_count.size() != size_before)
        << '\n';

    const int nginx_count = word_count["nginx"];
    std::cout
        << "operator[] value=" << nginx_count
        << " size=" << word_count.size()
        << '\n';

    std::set<int> ports{443, 22, 80, 80};
    const auto [it, inserted] = ports.insert(8080);
    const auto [same_it, inserted_again] = ports.insert(8080);

    std::cout
        << "inserted " << *it << '=' << inserted
        << " inserted again " << *same_it << '=' << inserted_again
        << '\n';

    std::cout << "ports in key order:";
    for (int port : ports) {
        std::cout << ' ' << port;
    }
    std::cout << '\n';

    return 0;
}
```

你要观察：

```text
word_count 为什么按字符串 key 排序，而不是按插入顺序
find 不存在的 key 为什么不改变 size
operator[] 读取不存在的 key 后为什么 size 增加
set 初始化中的重复 80 为什么只保留一个
第二次 insert(8080) 为什么 inserted_again 为 false
```

---

### 3. insert 返回的 pair

对唯一 key 的 `map` / `set`，`insert` 会返回：

```cpp
std::pair<iterator, bool>
```

含义：

```text
iterator：指向容器中对应 key 的元素
bool：本次是否真的插入了新元素
```

因此：

```cpp
const auto [it, inserted] = ports.insert(8080);
```

当 key 已存在时：

```text
inserted == false
it 仍然指向容器里原有的 8080
```

这和 Day3 的 `pair + 结构化绑定` 正好连接起来。

---

### 4. 代码二：范围查询、迭代器稳定性和容器选择

文件：

```text
02_container_choice.cpp
```

代码：

```cpp
#include <algorithm>
#include <iostream>
#include <map>
#include <string>
#include <vector>

struct Task {
    int deadline;
    std::string name;
};

void print_map_range(
    const std::map<int, std::string>& tasks,
    int begin,
    int end) {
    const auto first = tasks.lower_bound(begin);
    const auto last = tasks.upper_bound(end);

    std::cout << "map range [" << begin << ", " << end << "]:";
    for (auto it = first; it != last; ++it) {
        std::cout << ' ' << it->first << ':' << it->second;
    }
    std::cout << '\n';
}

int main() {
    // 场景一：数据一次构建、之后主要查询，vector 很合适。
    std::vector<Task> batch{
        {30, "flush"},
        {10, "heartbeat"},
        {20, "timeout"}
    };

    std::sort(
        batch.begin(),
        batch.end(),
        [](const Task& lhs, const Task& rhs) {
            return lhs.deadline < rhs.deadline;
        });

    const auto batch_it = std::lower_bound(
        batch.begin(),
        batch.end(),
        18,
        [](const Task& task, int deadline) {
            return task.deadline < deadline;
        });

    if (batch_it != batch.end()) {
        std::cout
            << "vector first deadline >= 18: "
            << batch_it->deadline << ' ' << batch_it->name
            << '\n';
    }

    // 场景二：数据持续修改，并且始终需要有序和范围查询。
    std::map<int, std::string> dynamic_tasks{
        {30, "flush"},
        {10, "heartbeat"},
        {20, "timeout"}
    };

    auto saved = dynamic_tasks.find(20);

    dynamic_tasks.emplace(25, "retry");
    dynamic_tasks.erase(10);

    if (saved != dynamic_tasks.end()) {
        std::cout
            << "saved iterator after other insert/erase: "
            << saved->first << ' ' << saved->second
            << '\n';
    }

    const auto first_not_before = dynamic_tasks.lower_bound(24);
    if (first_not_before != dynamic_tasks.end()) {
        std::cout
            << "map first deadline >= 24: "
            << first_not_before->first << ' '
            << first_not_before->second
            << '\n';
    }

    print_map_range(dynamic_tasks, 20, 29);

    return 0;
}
```

你要解释：

```text
batch 为什么先 sort，才能使用 lower_bound
数据一次构建、查询很多时，为什么 sorted vector 可能很好用
dynamic_tasks 插入 25 后为什么仍自动有序
插入 25、删除 10 后，saved 为什么仍然有效
如果删除的是 key=20，saved 为什么立即失效
lower_bound(24) 为什么指向 25
范围 [20, 29] 为什么用 lower_bound(20) 和 upper_bound(29)
```

---

### 5. 为什么不能只看复杂度表

假设你看到：

```text
vector 查找：O(n)
map 查找：O(log n)
```

不能立刻得出“map 一定更快”。还要问：

```text
数据量多大？
数据是否频繁修改？
是否需要保持有序？
是否需要范围查询？
能否先排序，再进行大量查询？
是否重视连续内存和 cache locality？
是否需要稳定的引用或迭代器？
```

例如：

```text
少量数据顺序扫描：vector 往往简单而且很快
一次构建、多次查询：sorted vector + lower_bound 很有竞争力
持续插入删除且始终要有序：map 更自然
只需要去重和有序 key：set
只做精确 key 查找、不需要顺序：明天再考虑 unordered_map
```

容器选择的主线应该是：

```text
访问方式
→ 修改模式
→ 是否要求顺序 / 范围
→ 生命周期和迭代器稳定性
→ 数据规模和内存局部性
→ 再看复杂度
```

---

### 6. map / set 和后续系统项目的关系

#### map

```text
按时间点有序保存任务
按区间查询配置或记录
需要稳定迭代器的动态有序数据
```

#### set

```text
去重后的 ID 集合
需要按顺序遍历的 key
维护已注册或已访问项目
```

#### vector

```text
批量任务
连接数组
连续缓冲区
一次构建后反复遍历或二分的数据
```

后面的 Reactor 常见 `fd -> Connection` 查询通常不要求 key 有序，因此往往会考虑 `unordered_map`；定时任务如果需要按时间取最早任务，则会考虑有序结构或堆。现在只建立选择依据，不提前设计完整 Reactor。

---

## Part C：练习、检查和收尾

### 1. 今日代码目录

Ubuntu：

```bash
~/code/system-learning/cpp/week3/day4
```

创建：

```text
01_map_set_basic.cpp
02_container_choice.cpp
```

今天不额外手写红黑树，也不为了凑数量增加第三个 demo。

---

### 2. 编译命令

```bash
g++ -std=c++17 -Wall -Wextra -g 01_map_set_basic.cpp -o r
./r
```

```bash
g++ -std=c++17 -Wall -Wextra -g 02_container_choice.cpp -o r
./r
```

要求：

```text
零 warning
两个程序都能运行
能解释主要输出
不在迭代器失效后继续使用它
```

---

### 3. 练习一验收

```text
1. map 和 set 分别存什么？
2. map 的有序是插入顺序吗？
3. map 的元素为什么是 pair<const Key, Value>？
4. find 不存在的 key 会不会插入？
5. operator[] 访问不存在的 key 会发生什么？
6. set 为什么自动去重？
7. insert 返回的 bool 表示什么？
```

---

### 4. 练习二验收

```text
1. map / set 常见操作为什么是 O(log n)？
2. lower_bound 和 upper_bound 分别返回什么？
3. 查询闭区间 [a, b] 应该怎样组合它们？
4. map 插入后，已有迭代器为什么通常仍有效？
5. erase 一个元素后，哪些迭代器失效？
6. sorted vector 和 map 各适合什么修改模式？
7. 为什么不能只看 O(n) 和 O(log n) 选择容器？
```

你有 OI / ACM 基础，二分和树结构本身不需要重复练。重点回答工程语义：存储、修改模式、迭代器稳定性和选择依据。

---

### 5. 中途判断题

#### operator[]

```cpp
std::map<std::string, int> counts;

if (counts["missing"] == 0) {
    // ...
}
```

判断：执行后 `counts.empty()` 是 true 还是 false？为什么？

#### insert

```cpp
std::map<int, std::string> values;
values.emplace(1, "old");
values.emplace(1, "new");
```

判断：key=1 对应的是 `old` 还是 `new`？第二次 `emplace` 是否覆盖？

#### iterator

```cpp
auto it = values.find(1);
values.emplace(2, "two");
values.erase(2);
```

判断：`it` 是否仍然有效？如果改成 `values.erase(1)` 呢？

#### comparator

```cpp
return lhs <= rhs;
```

判断：为什么它不适合作为 `set` / `map` 的比较器？

---

### 6. day4_note.md

建议放在：

```text
C:\Users\FxorG\Desktop\gpt_infra\week3\day4\day4_note.md
```

今天仍不要求重复抄完整教程。只记录你此前不熟或容易误用的点，例如：

```markdown
# Week3 Day4 Note

## map 的有序语义
- ...

## operator[] 的插入行为
- ...

## 迭代器稳定性
- ...

## 容器选择
- ...

## 代码观察或错误
- ...
```

如果这些你本来就会，只记录真实的新信息和实验结果即可。

---

### 7. 今日验收问题

```text
1. 关联容器和连续容器的主要组织方式有什么不同？
2. map / set 的“有序”由谁决定？
3. C++ 标准是否规定 map 必须使用红黑树？
4. map / set 为什么能提供 O(log n) 级别的查找和插入？
5. 比较器怎样判断两个 key 等价？
6. 为什么比较器不能随便写 <=？
7. map 的 operator[] 有什么副作用？
8. find、at、operator[] 的不存在行为有什么区别？
9. lower_bound 和 upper_bound 的语义分别是什么？
10. map 插入和删除时，迭代器失效规则是什么？
11. 为什么 vector 即使查询是 O(n)，工程上仍可能优于 map？
12. sorted vector 和 map 应该根据什么选择？
13. 什么时候只需要 set，而不是 map？
14. 如果多个任务 deadline 相同，map<deadline, task> 有什么问题？
```

不要求把 14 题全部写进 note；验收时要能用自己的话解释核心问题。

---

### 8. 面试追问

```text
map 和 unordered_map 怎么选？
map 为什么有序？
map 的 key 为什么不能直接修改？
map::operator[] 有什么风险？
map 插入元素会让已有迭代器失效吗？
为什么小数据场景 vector 可能比 map 更快？
lower_bound 做范围查询的复杂度是多少？
```

推荐回答主线：

```text
先说是否要求顺序和范围查询
再说修改模式和复杂度
再说节点存储与连续存储的内存局部性
最后补充迭代器稳定性和 operator[] 等接口语义
```

不要只回答“map 是 O(log n)，unordered_map 是 O(1)”。明天会专门拆解为什么这句话不够。

---

### 9. 今天不要提前深挖

```text
不手推红黑树插入和删除旋转
不证明红黑树高度上界
不读取 libstdc++ 树源码
不研究 allocator 和节点内存布局细节
不展开 multimap / multiset 全部接口
不提前深挖哈希冲突和 rehash
不实现完整定时器
```

---

### 10. 6.S081 / 15-445

```text
6.S081：今天不开
15-445：今天不开
```

继续保持 Week3 的 STL 主线。

---

### 11. Git 提交建议

```bash
cd ~/code/system-learning
git status
git add cpp/week3/day4
git commit -m "week3 day4 ordered associative containers"
```

---

### 12. 下一天衔接

Day5 将进入：

```text
unordered_map / unordered_set
bucket
哈希冲突
load factor
reserve / rehash
平均 O(1) 和最坏退化
rehash 引起的迭代器失效
```

Day4 回答的是：

```text
怎样获得动态有序、范围查询和较稳定的迭代器？
```

Day5 会回答：

```text
如果不需要顺序，只追求按 key 的快速精确查找，哈希容器付出了什么代价？
```
