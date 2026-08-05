# 常用 STL API（C++17）

> 目的：需要某个常用容器或算法时，可以快速确认“怎么构造、接口做什么、返回什么、复杂度和坑在哪里”。
>
> 默认编译：`g++ -std=c++17 -Wall -Wextra -g source.cpp -o program`

这不是 STL 全量手册。当前优先覆盖日常写题和系统项目里最常见的部分：

```text
vector / array / string / deque / list
map / unordered_map / set / unordered_set
stack / queue / priority_queue
iterator / algorithm / numeric
```

---

## 0. 先回答这次遇到的问题：构造时指定 size 和初始值

### 0.1 一维 `vector`

`vector`：动态数组容器。

```cpp
#include <vector>

std::vector<int> a;        // size = 0
std::vector<int> b(5);     // size = 5，五个 int 都是 0
std::vector<int> c(5, 7);  // size = 5，五个 int 都是 7
std::vector<int> d{5};     // size = 1，唯一元素是 5
std::vector<int> e{5, 7};  // size = 2，元素是 5、7
```

最容易混淆的是：

```text
vector<int> b(5)   -> 5 个默认值为 0 的元素
vector<int> d{5}   -> 1 个值为 5 的元素
```

圆括号通常是在选“数量构造函数”，花括号通常是在提供元素列表。

### 0.2 `vector(n)` 中的元素怎样初始化

```cpp
std::vector<int> numbers(3);           // 0, 0, 0
std::vector<double> values(3);         // 0.0, 0.0, 0.0
std::vector<std::string> words(3);     // 三个空 string
std::vector<MyClass> objects(3);       // 调用三次 MyClass 的默认构造函数
```

这里会对元素进行 value-initialization，当前可以理解为：

```text
内置数值类型 -> 0
class 类型    -> 调用默认构造函数
```

因此：

```cpp
std::vector<MyClass> objects(3);
```

要求 `MyClass` 能够无参数构造。

### 0.3 三维 `vector`

假设：

```cpp
struct Db {
    int value{};
};
```

创建大小为 `A x B x C` 的三维容器：

```cpp
std::vector<std::vector<std::vector<Db>>> arr(
    A,
    std::vector<std::vector<Db>>(
        B,
        std::vector<Db>(C)
    )
);
```

压成一行就是：

```cpp
std::vector<std::vector<std::vector<Db>>> arr(
    A, std::vector<std::vector<Db>>(B, std::vector<Db>(C)));
```

从内向外读：

```text
vector<Db>(C)
-> 创建一行，里面有 C 个 Db

vector<vector<Db>>(B, 上面那一行)
-> 创建一个平面，里面有 B 行

vector<vector<vector<Db>>>(A, 上面那个平面)
-> 创建 A 个平面
```

最终：

```cpp
arr.size()          == A;
arr[0].size()       == B;
arr[0][0].size()    == C;

arr[a][b][c].value = 42;
```

总共构造 `A * B * C` 个 `Db` object。

### 0.4 用 type alias 降低噪声

`alias`：别名。`using` 可以给复杂类型取短名字。

```cpp
using Row = std::vector<Db>;
using Plane = std::vector<Row>;
using Space = std::vector<Plane>;

Space arr(A, Plane(B, Row(C)));
```

这种写法更适合实际代码。

### 0.5 为三维元素指定统一初始值

```cpp
Db initial{7};
Space arr(A, Plane(B, Row(C, initial)));
```

于是每个 `Db::value` 初始都是 `7`。

注意：`vector(count, value)` 会根据 `value` 构造每个元素，所以元素类型需要支持复制。

### 0.6 嵌套 `vector` 不是一整块连续三维内存

每个最内层 `Row` 自己管理一段连续内存，但不同 Row 之间不保证连续：

```text
arr
 |
 +--> Plane 0
 |      +--> Row 0 -> [Db][Db][Db]
 |      +--> Row 1 -> [Db][Db][Db]
 |
 +--> Plane 1
        +--> Row 0 -> [Db][Db][Db]
```

它还可以变成不规则形状：

```cpp
arr[0][0].resize(100);  // 只有这一行改变长度
```

如果后续需要真正连续的 `A * B * C` 内存，可以使用一维 `vector`：

```cpp
std::vector<Db> arr(A * B * C);

const std::size_t index = (a * B + b) * C + c;
arr[index].value = 42;
```

当前先会用嵌套 `vector`；性能敏感时再考虑 flat storage。

---

## 1. `size`、`capacity`、`resize`、`reserve`、`assign`

### 1.1 `size()`：当前真实元素数量

```cpp
std::vector<int> values{10, 20, 30};
std::cout << values.size();  // 3
```

合法下标是：

```text
[0, size())
```

### 1.2 `capacity()`：当前已分配空间最多能容纳多少元素

```cpp
std::cout << values.capacity();
```

必须记住：

```text
size     = 已经存在的 object 数量
capacity = 不重新分配时最多能容纳的 object 数量
```

### 1.3 `resize(n)`：改变元素数量

```cpp
std::vector<int> values{1, 2};

values.resize(5);     // 1, 2, 0, 0, 0
values.resize(3);     // 1, 2, 0
values.resize(6, 9);  // 1, 2, 0, 9, 9, 9
```

扩大时会真正构造新元素；缩小时会析构被移除的元素。

### 1.4 `reserve(n)`：只预留容量，不创建元素

```cpp
std::vector<int> values;
values.reserve(100);

std::cout << values.size();      // 0
std::cout << values.capacity();  // >= 100
```

此时下面是错误的：

```cpp
values[0] = 7;  // 错误：size 仍然是 0
```

正确方式：

```cpp
values.push_back(7);
```

### 1.5 `assign(count, value)`：替换整个内容

```cpp
std::vector<int> values{1, 2, 3};
values.assign(4, 8);  // 8, 8, 8, 8
```

还有 range 版本：

```cpp
std::vector<int> source{10, 20, 30, 40};
std::vector<int> destination;

destination.assign(source.begin() + 1, source.end());
// 20, 30, 40
```

### 1.6 五个操作快速对照

| 操作 | 改变 size | 可能改变 capacity | 创建/删除元素 |
|---|---:|---:|---:|
| `vector(n)` | 是 | 是 | 创建 n 个 |
| `resize(n)` | 是 | 是 | 是 |
| `reserve(n)` | 否 | 是 | 否 |
| `assign(n, value)` | 是 | 可能 | 替换全部元素 |
| `clear()` | 变为 0 | 通常不主动缩小 | 删除全部元素 |

---

## 2. 所有常见容器都要先认识的接口

大部分容器都支持：

```cpp
container.empty();  // 是否没有元素，返回 bool
container.size();   // 元素数量
container.clear();  // 删除全部元素
container.begin();  // 第一个元素的 iterator
container.end();    // 尾后 iterator，不指向元素
```

判断空容器优先写：

```cpp
if (container.empty()) {
    // ...
}
```

不要为了判断空而写：

```cpp
if (container.size() == 0) {
    // 也能工作，但 empty() 表意更直接
}
```

范围遍历：

```cpp
for (const auto& value : container) {
    std::cout << value << '\n';
}
```

需要修改元素：

```cpp
for (auto& value : container) {
    value *= 2;
}
```

只写 `auto value` 会复制元素：

```cpp
for (auto value : container) {
    value *= 2;  // 不会修改原容器
}
```

---

## 3. `std::vector`

头文件：

```cpp
#include <vector>
```

### 3.1 构造

```cpp
std::vector<int> a;                  // empty
std::vector<int> b(5);               // 5 个 0
std::vector<int> c(5, 9);            // 5 个 9
std::vector<int> d{1, 2, 3};         // initializer list
std::vector<int> e(d.begin(), d.end()); // iterator range
std::vector<int> f = d;              // copy
std::vector<int> g = std::move(f);   // move
```

### 3.2 元素访问

```cpp
values[index];       // 不检查越界
values.at(index);    // 越界时抛 std::out_of_range
values.front();      // 第一个元素，容器不能 empty
values.back();       // 最后一个元素，容器不能 empty
values.data();       // 指向连续元素区域的 pointer
```

示例：

```cpp
std::vector<int> values{10, 20, 30};

std::cout << values[1];     // 20
std::cout << values.at(1);  // 20
std::cout << values.front();// 10
std::cout << values.back(); // 30
```

### 3.3 尾部插入和删除

```cpp
values.push_back(value);          // 插入已有 value
values.push_back(std::move(obj)); // 移动插入
values.emplace_back(args...);     // 使用 args 在尾部构造元素
values.pop_back();                // 删除最后一个，无返回值
```

`pop_back()` 不返回被删除元素：

```cpp
const int last = values.back();
values.pop_back();
```

### 3.4 任意位置插入和删除

```cpp
auto it = values.insert(values.begin() + 1, 99);
// it 指向插入后的 99

it = values.erase(values.begin() + 1);
// it 指向被删除元素之后的元素

values.erase(values.begin() + 2, values.end());
// 删除 [begin + 2, end)
```

中间位置插入/删除需要移动后续元素，复杂度通常是 `O(n)`。

### 3.5 扩容与 iterator 失效

`vector` 扩容时可能申请新内存，并把元素移动到新地址：

```text
old storage -> move/copy elements -> new storage -> release old storage
```

如果发生 reallocation：

```text
原来的 pointer / reference / iterator 全部失效
```

示例：

```cpp
std::vector<int> values{1, 2, 3};
int* old_pointer = values.data();

values.push_back(4);

// 不能假设 old_pointer 仍然有效
```

提前知道大致元素数量时：

```cpp
std::vector<Job> jobs;
jobs.reserve(expected_count);
```

### 3.6 常用复杂度

| 操作 | 复杂度 |
|---|---:|
| `operator[]` / `at` | `O(1)` |
| `front` / `back` | `O(1)` |
| `push_back` / `emplace_back` | 摊还 `O(1)` |
| `pop_back` | `O(1)` |
| 中间 `insert` / `erase` | `O(n)` |
| `find` 普通线性查找 | `O(n)` |

---

## 4. `std::array`

`array`：固定大小数组容器。长度是类型的一部分，必须在编译期确定。

```cpp
#include <array>

std::array<int, 4> a{};          // 0, 0, 0, 0
std::array<int, 4> b{1, 2, 3, 4};

b.fill(7);                       // 7, 7, 7, 7
std::cout << b.size();           // 4
std::cout << b.at(2);            // 7
```

对比：

```text
array<T, N>  -> N 编译期固定，object 内直接包含元素
vector<T>    -> size 运行期可变，通常单独管理 heap storage
```

---

## 5. `std::string`

`string`：管理字符序列的容器。

```cpp
#include <string>
```

### 5.1 构造

```cpp
std::string a;             // empty
std::string b("hello");   // hello
std::string c(5, 'x');     // xxxxx
std::string d = b;         // copy
```

### 5.2 常用接口

```cpp
text.size();
text.empty();
text[index];
text.at(index);
text.front();
text.back();
text.push_back('!');
text.pop_back();
text += " world";
text.append(" world");
text.clear();
```

### 5.3 `substr`

`substring`：子字符串。

```cpp
std::string text = "abcdef";

std::string part1 = text.substr(2);     // cdef
std::string part2 = text.substr(2, 3);  // cde
```

参数：

```text
pos   -> 起始下标
count -> 最多取多少字符
```

### 5.4 `find` 与 `npos`

```cpp
const std::size_t position = text.find("cd");

if (position != std::string::npos) {
    std::cout << position;
}
```

`npos`：no position，表示没有找到。

常见查找：

```cpp
text.find(target);      // 从前向后
text.rfind(target);     // reverse find，从后向前
text.find_first_of(chars);
text.find_last_of(chars);
```

### 5.5 `c_str()`

```cpp
const char* pointer = text.c_str();
```

它用于把 `string` 内容交给需要 C string 的接口。`size()` 不包含结尾的 `\0`。

修改 `string` 后，之前取得的 `c_str()` pointer 可能失效，不要长期保存。

### 5.6 读取一整行

```cpp
std::string line;
std::getline(std::cin, line);
```

如果先使用 `operator>>`，再使用 `getline`，注意前一个输入可能留下 newline：

```cpp
int count = 0;
std::cin >> count;
std::cin.ignore();
std::getline(std::cin, line);
```

真实程序中可使用更明确的 `ignore` 上限，但当前先理解“前一个 newline 仍在输入流中”。

---

## 6. `std::deque`

`deque`：double-ended queue，双端队列。

```cpp
#include <deque>

std::deque<int> values;
values.push_back(2);   // 2
values.push_front(1);  // 1, 2
values.emplace_back(3);// 1, 2, 3
values.pop_front();    // 2, 3
values.pop_back();     // 2
```

它支持：

```cpp
values[index];
values.at(index);
values.front();
values.back();
```

选型直觉：

```text
需要连续内存、缓存友好、尾部增长 -> vector
需要频繁从头尾插入删除           -> deque
```

`deque` 不保证所有元素位于一整块连续内存中，不要把它的 `&values[0]` 当作连续数组起点。

---

## 7. `std::list`

`list`：双向链表容器。

```cpp
#include <list>

std::list<int> values;
values.push_front(1);
values.push_back(3);
auto it = values.begin();
++it;
values.insert(it, 2);  // 1, 2, 3
```

常用接口：

```cpp
front / back
push_front / emplace_front
push_back / emplace_back
pop_front / pop_back
insert / erase
splice
size / empty / clear
```

### 7.1 `erase` 返回下一个 iterator

```cpp
for (auto it = values.begin(); it != values.end();) {
    if (*it < 0) {
        it = values.erase(it);
    } else {
        ++it;
    }
}
```

### 7.2 `splice`

`splice`：把 list node 从一个位置转移到另一个位置，不复制 node 中的元素。

```cpp
std::list<int> source{1, 2, 3};
std::list<int> destination{10};

auto it = source.begin();
++it;  // 指向 2

destination.splice(destination.begin(), source, it);
// destination: 2, 10
// source:      1, 3
```

这是 LRU Cache 常见的接口。

### 7.3 iterator 稳定性

插入 list node 通常不会让其他 node 的 iterator/reference 失效；删除某个 node 只让指向该 node 的 iterator/reference 失效。

不要因为这个特性就默认 list 更快。链表 node 分散、缓存局部性差，绝大多数顺序数据默认仍优先考虑 vector。

---

## 8. `std::map` 与 `std::unordered_map`

### 8.1 基本区别

```cpp
#include <map>
#include <unordered_map>

std::map<std::string, int> ordered;
std::unordered_map<std::string, int> hashed;
```

```text
map           -> key 有序，常见实现是平衡树，操作 O(log n)
unordered_map -> key 无序，hash table，平均 O(1)，最坏 O(n)
```

### 8.2 插入和更新

```cpp
std::map<std::string, int> score;

score["alice"] = 90;
score.insert({"bob", 80});
score.emplace("carol", 95);
score.try_emplace("dave", 88);          // C++17
score.insert_or_assign("alice", 100);   // C++17
```

返回值例子：

```cpp
const auto [it, inserted] = score.insert({"bob", 70});

if (!inserted) {
    std::cout << "bob already exists: " << it->second;
}
```

### 8.3 `operator[]` 会插入缺失的 key

```cpp
std::map<std::string, int> count;

std::cout << count.size();  // 0
std::cout << count["x"];   // 0
std::cout << count.size();  // 1
```

因为 `"x"` 不存在时，`operator[]` 会创建：

```text
key = "x"
value = int{}，也就是 0
```

只想查询、不想插入时使用 `find`：

```cpp
const auto it = count.find("x");
if (it != count.end()) {
    std::cout << it->second;
}
```

或者 `at`：

```cpp
const int value = count.at("x");
```

不存在时 `at` 抛出 `std::out_of_range`，不会插入。

### 8.4 C++17 判断 key 是否存在

C++20 才有 `contains`。当前 C++17 写法：

```cpp
if (score.find("alice") != score.end()) {
    // exists
}
```

### 8.5 删除

```cpp
score.erase("alice");  // 返回删除的元素数量：0 或 1

auto it = score.find("bob");
if (it != score.end()) {
    score.erase(it);
}
```

### 8.6 遍历

```cpp
for (const auto& [name, value] : score) {
    std::cout << name << ' ' << value << '\n';
}
```

这是 C++17 structured binding：结构化绑定。

### 8.7 `unordered_map` 的 `reserve`

预计会插入很多元素时：

```cpp
std::unordered_map<int, Job> jobs;
jobs.reserve(expected_count);
```

rehash 可能让 iterator 失效。不要跨插入操作长期保存 unordered container 的 iterator，除非已经确认不会发生 rehash。

---

## 9. `std::set` 与 `std::unordered_set`

只保存唯一 key，没有单独的 mapped value。

```cpp
#include <set>
#include <unordered_set>

std::set<int> ordered{3, 1, 2};
std::unordered_set<int> hashed{3, 1, 2};
```

常用接口：

```cpp
const auto [it, inserted] = ordered.insert(4);
ordered.find(4);
ordered.erase(4);
ordered.size();
ordered.empty();
```

C++17 判断存在：

```cpp
if (ordered.find(target) != ordered.end()) {
    // exists
}
```

`set` 中的元素就是 key，不能通过 iterator 随意修改，否则会破坏有序结构。

---

## 10. Container adapters：`stack`、`queue`、`priority_queue`

`adapter`：适配器。它限制底层容器暴露出来的操作。

### 10.1 `std::stack`

LIFO：last in, first out，后进先出。

```cpp
#include <stack>

std::stack<int> values;
values.push(1);
values.emplace(2);

std::cout << values.top();  // 2
values.pop();               // 无返回值
```

常用接口：

```text
push / emplace / top / pop / size / empty
```

### 10.2 `std::queue`

FIFO：first in, first out，先进先出。

```cpp
#include <queue>

std::queue<int> values;
values.push(1);
values.push(2);

std::cout << values.front(); // 1
std::cout << values.back();  // 2
values.pop();                // 删除 1，无返回值
```

常用接口：

```text
push / emplace / front / back / pop / size / empty
```

### 10.3 `std::priority_queue`

默认是 max heap：最大元素优先。

```cpp
#include <queue>
#include <vector>

std::priority_queue<int> max_heap;
max_heap.push(3);
max_heap.push(10);
max_heap.push(5);

std::cout << max_heap.top();  // 10
```

min heap：最小元素优先。

```cpp
#include <functional>

std::priority_queue<
    int,
    std::vector<int>,
    std::greater<int>
> min_heap;
```

`pop()` 仍然无返回值：

```cpp
const int value = min_heap.top();
min_heap.pop();
```

---

## 11. Iterator：STL 中的通用位置对象

`iterator`：迭代器。它表示容器中的一个位置，并提供适合该容器的移动/访问操作。

```cpp
auto it = values.begin();
std::cout << *it;
++it;
```

不要简单记成“iterator 就是 pointer”。更准确的是：

```text
pointer 可以作为一种 iterator
STL iterator 是统一访问位置的抽象接口
不同容器的 iterator 能力不同
```

### 11.1 `[begin, end)`

STL 通常使用左闭右开 range：

```text
[begin, end)
```

`end()` 指向尾后位置，不能解引用：

```cpp
auto it = values.end();
// std::cout << *it;  // 错误
```

### 11.2 `next`、`prev`、`distance`

```cpp
#include <iterator>

auto second = std::next(values.begin());
auto last = std::prev(values.end());
auto count = std::distance(values.begin(), values.end());
```

不要对 list iterator 写：

```cpp
it + 3;  // list iterator 不支持 random access
```

应使用：

```cpp
auto target = std::next(it, 3);
```

但对 list 前进 3 步仍然需要实际走 3 个 node。

### 11.3 常见 iterator 失效速查

| 容器/操作 | 典型影响 |
|---|---|
| `vector` reallocation | 全部 iterator/reference/pointer 失效 |
| `vector` 中间 erase | 被删位置及其后面的 iterator 失效 |
| `list` insert | 其他 iterator 通常保持有效 |
| `list` erase | 只让被删 node 的 iterator 失效 |
| `map/set` insert | 其他 iterator 保持有效 |
| `map/set` erase | 被删元素 iterator 失效 |
| `unordered_map/set` rehash | iterator 失效 |

---

## 12. 常用 `<algorithm>`

头文件：

```cpp
#include <algorithm>
```

algorithm 通常接收 iterator range，而不是直接接收容器。

### 12.1 `sort`

```cpp
std::vector<int> values{4, 1, 3, 2};

std::sort(values.begin(), values.end());
// 1, 2, 3, 4

std::sort(values.begin(), values.end(), std::greater<int>{});
// 4, 3, 2, 1
```

自定义比较：

```cpp
std::sort(jobs.begin(), jobs.end(),
    [](const Job& left, const Job& right) {
        return left.priority < right.priority;
    });
```

comparator 必须表达严格弱序，最常见形式使用 `<`，不要随意写 `<=`。

### 12.2 `find` 与 `find_if`

```cpp
const auto it = std::find(values.begin(), values.end(), 3);

if (it != values.end()) {
    std::cout << "found";
}
```

```cpp
const auto it = std::find_if(
    values.begin(), values.end(),
    [](int value) {
        return value > 10;
    });
```

### 12.3 `count` 与 `count_if`

```cpp
const auto count1 = std::count(values.begin(), values.end(), 3);

const auto count2 = std::count_if(
    values.begin(), values.end(),
    [](int value) {
        return value % 2 == 0;
    });
```

### 12.4 `lower_bound`、`upper_bound`、`binary_search`

前提：range 已按同一比较规则排序。

```cpp
std::vector<int> values{10, 20, 20, 30, 40};

auto lower = std::lower_bound(values.begin(), values.end(), 20);
// 第一个 >= 20 的位置

auto upper = std::upper_bound(values.begin(), values.end(), 20);
// 第一个 > 20 的位置

bool exists = std::binary_search(values.begin(), values.end(), 30);
```

等于 `20` 的元素数量：

```cpp
const auto count = std::distance(lower, upper);
```

### 12.5 `min_element` 与 `max_element`

```cpp
auto minimum = std::min_element(values.begin(), values.end());
auto maximum = std::max_element(values.begin(), values.end());

if (minimum != values.end()) {
    std::cout << *minimum;
}
```

空 range 会返回 `end()`，所以解引用前要检查。

### 12.6 `reverse`

```cpp
std::reverse(values.begin(), values.end());
```

### 12.7 `remove` 不会真的缩短 vector

```cpp
std::vector<int> values{1, 2, 3, 2, 4};

auto new_end = std::remove(values.begin(), values.end(), 2);
```

此时 `size()` 还没有改变。正确使用 erase-remove idiom：

```cpp
values.erase(
    std::remove(values.begin(), values.end(), 2),
    values.end()
);
```

按条件删除：

```cpp
values.erase(
    std::remove_if(
        values.begin(), values.end(),
        [](int value) {
            return value < 0;
        }),
    values.end()
);
```

### 12.8 `unique` 只消除相邻重复

```cpp
std::vector<int> values{3, 1, 3, 2, 1};

std::sort(values.begin(), values.end());
values.erase(
    std::unique(values.begin(), values.end()),
    values.end()
);
// 1, 2, 3
```

### 12.9 `copy`

```cpp
std::vector<int> source{1, 2, 3};
std::vector<int> destination(source.size());

std::copy(
    source.begin(), source.end(),
    destination.begin()
);
```

如果 destination 初始为空，可以使用 back inserter：

```cpp
#include <iterator>

std::vector<int> destination;
std::copy(
    source.begin(), source.end(),
    std::back_inserter(destination)
);
```

### 12.10 `transform`

```cpp
std::vector<int> source{1, 2, 3};
std::vector<int> squares(source.size());

std::transform(
    source.begin(), source.end(),
    squares.begin(),
    [](int value) {
        return value * value;
    });
```

---

## 13. 常用 `<numeric>`

### 13.1 `accumulate`

`accumulate`：累加。

```cpp
#include <numeric>

std::vector<int> values{1, 2, 3, 4};
const int sum = std::accumulate(values.begin(), values.end(), 0);
// 10
```

第三个参数同时决定初始值和累计结果类型：

```cpp
std::vector<long long> values{1, 2, 3};

const long long sum = std::accumulate(
    values.begin(), values.end(), 0LL);
```

写 `0` 会让累计类型是 `int`，大整数场景可能溢出。

---

## 14. 常用辅助类型

### 14.1 `std::pair`

```cpp
#include <utility>

std::pair<std::string, int> item{"alice", 90};

std::cout << item.first;
std::cout << item.second;

const auto [name, score] = item;
```

### 14.2 `std::tuple`

```cpp
#include <tuple>

std::tuple<int, std::string, double> value{1, "job", 3.5};

std::cout << std::get<0>(value);

const auto& [id, name, cost] = value;
```

### 14.3 `std::optional`

表示“可能有一个值，也可能没有”。

```cpp
#include <optional>

std::optional<int> find_value(bool found) {
    if (!found) {
        return std::nullopt;
    }
    return 42;
}
```

使用：

```cpp
const auto result = find_value(true);

if (result.has_value()) {
    std::cout << result.value();
}

std::cout << result.value_or(-1);
```

也可以写：

```cpp
if (result) {
    std::cout << *result;
}
```

---

## 15. 容器选型速查

| 需求 | 第一选择 | 原因 |
|---|---|---|
| 普通动态顺序数据 | `vector` | 连续内存、缓存友好、接口完整 |
| 编译期固定长度 | `array` | 固定大小、无动态分配 |
| 字符序列 | `string` | 字符串接口和 C string 互操作 |
| 头尾频繁插入删除 | `deque` | 两端操作高效 |
| 需要稳定 node iterator / splice | `list` | node-based container |
| key 有序 | `map` / `set` | 排序、范围查询、`O(log n)` |
| 只需快速 key 查询 | `unordered_map` / `unordered_set` | 平均 `O(1)` hash lookup |
| 后进先出 | `stack` | LIFO interface |
| 先进先出 | `queue` | FIFO interface |
| 每次取最大/最小元素 | `priority_queue` | heap interface |

默认顺序容器优先考虑 `vector`，有明确理由时再换。

---

## 16. 高频错误速查

### 16.1 `reserve` 后直接下标访问

```cpp
std::vector<int> values;
values.reserve(10);
values[0] = 1;  // 错误，size 仍为 0
```

### 16.2 混淆圆括号与花括号

```cpp
std::vector<int> a(5);  // 5 个 0
std::vector<int> b{5};  // 1 个 5
```

### 16.3 对 empty 容器调用 `front/back/top/pop`

```cpp
if (!values.empty()) {
    std::cout << values.back();
    values.pop_back();
}
```

### 16.4 保存 vector iterator 后继续插入

```cpp
auto it = values.begin();
values.push_back(10);  // 可能 reallocate
// it 可能已经失效
```

### 16.5 用 map 的 `operator[]` 做只读查询

```cpp
if (count["missing"] == 0) {
    // 已经插入了 "missing"
}
```

只读查询用 `find`。

### 16.6 忘记检查 `find` 结果

```cpp
auto it = values.find(key);
if (it != values.end()) {
    // 才能使用 *it 或 it->second
}
```

### 16.7 以为 `remove` 会改变 size

必须配合容器的 `erase`。

### 16.8 对未排序 range 使用二分算法

`lower_bound / upper_bound / binary_search` 的前提是 range 已按相同规则排序。

### 16.9 comparator 使用 `<=`

```cpp
// 错误倾向：return left <= right;
// 正确倾向：return left < right;
```

### 16.10 把 `string::npos` 存进 `int`

`npos` 类型与 `std::string::size_type` 对齐，优先使用：

```cpp
const std::size_t position = text.find(target);
```

---

## 17. 一页压缩记忆

```text
vector(n)          -> n 个 value-initialized elements
vector(n, value)   -> n 个 value copies
vector{a, b, c}    -> element list

size               -> 当前 object 数量
capacity           -> 当前 storage 容量
resize             -> 改 size，构造/析构元素
reserve            -> 只改 capacity，不创建元素

vector             -> 默认动态顺序容器
array              -> 固定长度
deque              -> 头尾操作
list               -> stable node + splice
map/set            -> ordered O(log n)
unordered_*        -> hash，平均 O(1)

operator[]         -> 常常不检查边界；map 中还可能插入
at                 -> 检查并可能抛异常
erase(iterator)    -> 常返回下一个 iterator
pop                -> 通常不返回被删除值

lower_bound        -> first >= target
upper_bound        -> first > target
find               -> found iterator 或 end
remove/unique      -> 只重排 logical end，vector 还要 erase

vector reallocate  -> pointer/reference/iterator 全失效
end()              -> 尾后位置，不能解引用
```

你这次遇到的三维写法，最终压缩成一句：

```cpp
using Row = std::vector<Db>;
using Plane = std::vector<Row>;
using Space = std::vector<Plane>;

Space arr(A, Plane(B, Row(C)));
```

读法永远从最里面开始：先创建 C 个元素的一行，再创建 B 行的平面，最后创建 A 个平面。
