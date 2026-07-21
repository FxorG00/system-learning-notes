# Week3 Day3：string + algorithm + optional 初步

> 今日定位：承接 Day1 / Day2 的连续存储和句柄失效。  
> 今天从一个具体问题出发：**我从 `std::string` 里拿到一个 `const char*`，随后修改 string，这个指针为什么可能突然不能用了？**

---

## Part A：前情提要和术语

### 1. 前情提要：把 vector 的生命周期意识迁移到 string

前两天你已经掌握：

```text
vector 使用连续内存
空间不足时可能重新分配
重新分配后旧指针、引用、迭代器失效
容器结构修改后要重新判断句柄是否有效
```

`std::string` 也管理一段字符存储。

因此今天继续问同一种问题：

```text
string 的字符存在哪里？
c_str() 返回的指针由谁拥有？
string 修改后，这个指针还能不能使用？
```

Day2 你总结了插入元素的两个判断：

```text
新元素怎样构造？
本次操作是否导致已有元素搬迁？
```

今天对 string 的判断类似：

```text
我拿到的是独立字符串，还是内部内存的借用指针？
string 修改后，内部内存是否可能变化？
```

---

### 2. std::string 的基本直觉

`std::string` 管理一串字符，并负责：

```text
申请字符存储
复制 / 移动字符串内容
修改长度
在生命周期结束时释放资源
提供以 '\0' 结尾的 C 字符串视图
```

它和 vector 有相似概念：

```cpp
std::string text = "hello";

text.size();
text.capacity();
text.reserve(100);
```

但不要假设 string 的 capacity 增长倍率，也不要深挖具体实现。

---

### 3. c_str()

```cpp
const char* p = text.c_str();
```

`c_str()` 返回：

```text
指向 string 内部字符序列的 const char*
字符序列以 '\0' 结尾
这个指针不拥有内存
不能 delete
```

它主要用于把 `std::string` 交给需要 C 字符串的接口：

```cpp
void print_c_string(const char* text);

std::string message = "hello";
print_c_string(message.c_str());
```

这里的所有权关系是：

```text
message 拥有字符存储
c_str() 返回的指针只是 non-owning view
```

---

### 4. c_str() 指针什么时候有风险？

下面代码有风险：

```cpp
std::string text = "hello";
const char* p = text.c_str();

text += " world and more text";

std::cout << p << '\n';  // 不能保证安全
```

修改 string 可能导致内部存储变化，于是旧 `p` 失效。

现阶段采用保守规则：

```text
拿到 c_str() 后，只在 string 不发生修改且仍然存活时使用。
string 修改后，需要重新调用 c_str()。
string 析构后，c_str() 指针必然不能再用。
```

不要试图根据当前 capacity 猜测某次修改是否一定安全。工程代码里重新获取指针通常更清楚。

---

### 5. '\0' 和 size()

`std::string` 的逻辑字符数量不包含结尾的 `\0`。

```cpp
std::string text = "abc";
```

可以理解成：

```text
字符内容：'a' 'b' 'c' '\0'
size()：3
```

这和 Week1 的 `StringLike` 一样：

```text
字符串长度不包含结尾 '\0'
底层 C 字符串存储需要额外的 '\0'
```

---

### 6. npos

`std::string::find` 找不到时返回：

```cpp
std::string::npos
```

例如：

```cpp
const std::size_t pos = text.find("GET");

if (pos == std::string::npos) {
    std::cout << "not found\n";
}
```

不要拿 `-1` 和 `std::size_t` 随意混用。直接与 `std::string::npos` 比较最清楚。

---

### 7. algorithm 的范围

标准算法通常接收一个半开区间：

```text
[first, last)
```

意思是：

```text
包含 first 指向的元素
不包含 last 指向的位置
```

vector 全范围通常写：

```cpp
values.begin(), values.end()
```

你已经知道 `end()` 不是元素，正好对应半开区间的末尾。

---

### 8. 今天使用的算法

#### sort

```cpp
std::sort(values.begin(), values.end());
```

把范围内元素排序。

#### find

```cpp
auto it = std::find(values.begin(), values.end(), target);
```

找到时返回对应迭代器；找不到返回 `values.end()`。

#### lower_bound

```cpp
auto it = std::lower_bound(values.begin(), values.end(), target);
```

前提：范围已经按相同规则排序。

返回第一个：

```text
不小于 target 的位置
```

它返回的是可能的插入位置，不代表一定找到了 target。

#### remove_if

```cpp
auto new_end = std::remove_if(first, last, predicate);
```

它不会真正缩短容器，而是把“保留的元素”移动到前面，并返回新的逻辑结尾。

---

### 9. optional

`std::optional<T>` 表示：

```text
这里可能有一个 T
也可能没有值
```

例如：

```cpp
std::optional<int> result;
```

有值：

```cpp
return 42;
```

没有值：

```cpp
return std::nullopt;
```

访问 optional 前应先判断：

```cpp
if (result.has_value()) {
    std::cout << result.value() << '\n';
}
```

也可以写成：

```cpp
if (result) {
    std::cout << *result << '\n';
}
```

如果 optional 没有值，直接调用 `value()` 会抛出 `std::bad_optional_access`。`operator*` 也要求 optional 当前确实有值，因此同样应先判断。

相比返回 `-1`：

```text
optional 明确表达“没有结果”
不会和合法的 -1 数据混淆
调用者必须面对“可能不存在”这个事实
```

---

### 10. pair / tuple

#### pair

```cpp
std::pair<int, std::string> response{200, "OK"};
```

表达两个相关值。

#### tuple

```cpp
std::tuple<int, std::string, bool> user{7, "FxorG", true};
```

表达多个不同类型的值。

C++17 可以使用结构化绑定：

```cpp
auto [code, message] = response;
auto [id, name, active] = user;
```

今天只会用即可，不讨论 tuple 内部实现。

---

## Part B：教程主体

### 1. 今天从什么问题出发？

假设你以后写网络协议解析：

```cpp
std::string request = "GET /index.html";
const char* raw = request.c_str();
```

然后为了继续拼接请求内容：

```cpp
request += " HTTP/1.1";
```

此时继续使用旧 `raw` 是否安全？

不能保证。

因为：

```text
raw 不是独立副本
raw 只是借用 request 的内部存储
request 修改时可能重新组织字符存储
旧 raw 可能失效
```

安全思路：

```cpp
request += " HTTP/1.1";
const char* fresh_raw = request.c_str();
```

这和 vector 扩容后重新获取迭代器是同一种生命周期意识。

---

### 2. 代码一：观察 string 存储和 c_str 地址

文件：

```text
01_string_storage.cpp
```

代码：

```cpp
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <iostream>
#include <string>

int main() {
    std::string text = "GET /";

    std::cout
        << "text=" << text
        << " size=" << text.size()
        << " capacity=" << text.capacity()
        << " strlen(c_str)=" << std::strlen(text.c_str())
        << '\n';

    const std::size_t old_capacity = text.capacity();
    const std::uintptr_t old_address =
        reinterpret_cast<std::uintptr_t>(text.c_str());

    while (text.capacity() == old_capacity) {
        text.push_back('x');
    }

    const std::uintptr_t new_address =
        reinterpret_cast<std::uintptr_t>(text.c_str());

    std::cout
        << "after growth: size=" << text.size()
        << " capacity=" << text.capacity()
        << " old_address=" << old_address
        << " new_address=" << new_address
        << " address_changed=" << std::boolalpha
        << (old_address != new_address)
        << '\n';

    // 修改后重新获取 c_str()，不再使用旧指针。
    const char* fresh = text.c_str();
    std::cout << "fresh c_str=" << fresh << '\n';

    const std::size_t slash_pos = text.find('/');
    if (slash_pos != std::string::npos) {
        std::cout << "slash position=" << slash_pos << '\n';
    }

    const std::size_t missing_pos = text.find("POST");
    if (missing_pos == std::string::npos) {
        std::cout << "POST not found\n";
    }

    return 0;
}
```

你要观察：

```text
size() 和 strlen(c_str()) 对普通无内嵌 '\0' 文本是否相同
capacity 变化时 c_str() 地址是否变化
为什么修改后只使用 fresh
find 找不到时为什么与 npos 比较
```

注意：

```text
string 可能使用小字符串优化，但今天不依赖也不深挖它。
只观察修改可能让内部地址发生变化。
```

---

### 3. c_str() 的正确使用边界

适合：

```cpp
call_c_api(text.c_str());
```

只在函数调用期间借用，期间不修改 `text`。

危险：

```cpp
const char* saved = text.c_str();
store_for_later(saved);
```

如果外部长期保存该指针，而原 string 修改或析构，就会悬空。

如果对方需要长期持有文本，应让对方拥有自己的副本或明确设计生命周期，而不是默默保存 `c_str()`。

---

### 4. sort 和 find

```cpp
std::vector<int> values{7, 2, 9, 2, 5};

std::sort(values.begin(), values.end());
```

排序后：

```text
2 2 5 7 9
```

查找：

```cpp
auto it = std::find(values.begin(), values.end(), 5);

if (it != values.end()) {
    std::cout << "found=" << *it << '\n';
}
```

算法通常不返回“神秘下标”，而是返回迭代器，让同一算法可以适配不同容器。

---

### 5. lower_bound 不是“保证找到”

对已排序范围：

```cpp
auto it = std::lower_bound(values.begin(), values.end(), 6);
```

假设数据是：

```text
2 2 5 7 9
```

返回指向 `7`，因为 `7` 是第一个不小于 `6` 的元素。

判断是否真的找到 `6`：

```cpp
if (it != values.end() && *it == 6) {
    std::cout << "found\n";
} else {
    std::cout << "not found, but this is insertion position\n";
}
```

这点对你算法背景应该很熟，今天只把返回值语义写进工程代码。

---

### 6. remove_if 为什么没有真正删除？

例如：

```cpp
std::vector<int> values{1, 2, 3, 4, 5, 6};

auto new_end = std::remove_if(
    values.begin(),
    values.end(),
    [](int value) {
        return value % 2 == 0;
    });
```

`remove_if` 只负责重新排列范围：

```text
把要保留的 1、3、5 移到前面
返回新的逻辑结尾 new_end
vector 的 size 仍然是 6
```

真正缩短 vector：

```cpp
values.erase(new_end, values.end());
```

组合起来就是经典 erase-remove idiom：

```cpp
values.erase(
    std::remove_if(values.begin(), values.end(), predicate),
    values.end());
```

为什么算法不直接调用 vector::erase？

直觉答案：

```text
算法只操作迭代器范围，不应该假设背后一定是 vector，也不拥有容器本身。
```

---

### 7. optional 解决特殊返回值歧义

错误设计直觉：

```cpp
int find_value(...) {
    // 找不到返回 -1
}
```

如果 `-1` 本身可能是合法数据，就产生歧义。

使用 optional：

```cpp
std::optional<int> find_first_greater_than(
    const std::vector<int>& values,
    int limit) {
    auto it = std::find_if(
        values.begin(),
        values.end(),
        [limit](int value) {
            return value > limit;
        });

    if (it == values.end()) {
        return std::nullopt;
    }

    return *it;
}
```

调用：

```cpp
auto result = find_first_greater_than(values, 10);

if (result.has_value()) {
    std::cout << *result << '\n';
}
```

也可以：

```cpp
std::cout << result.value_or(-1) << '\n';
```

但如果 `-1` 有业务含义，输出层仍然应该明确区分“无结果”，不要重新制造歧义。

---

### 8. 代码二：algorithm + optional + 结构化绑定

文件：

```text
02_algorithm_optional.cpp
```

代码：

```cpp
#include <algorithm>
#include <iostream>
#include <iterator>
#include <optional>
#include <string>
#include <tuple>
#include <utility>
#include <vector>

std::optional<int> find_first_greater_than(
    const std::vector<int>& values,
    int limit) {
    auto it = std::find_if(
        values.begin(),
        values.end(),
        [limit](int value) {
            return value > limit;
        });

    if (it == values.end()) {
        return std::nullopt;
    }

    return *it;
}

int main() {
    std::vector<int> values{7, 2, 9, 2, 5, 6, 4};

    std::sort(values.begin(), values.end());

    std::cout << "sorted:";
    for (int value : values) {
        std::cout << ' ' << value;
    }
    std::cout << '\n';

    auto found = std::find(values.begin(), values.end(), 5);
    if (found != values.end()) {
        std::cout << "find 5 at index="
                  << std::distance(values.begin(), found)
                  << '\n';
    }

    auto lower = std::lower_bound(values.begin(), values.end(), 6);
    if (lower != values.end()) {
        std::cout << "first value >= 6 is " << *lower << '\n';
    }

    values.erase(
        std::remove_if(
            values.begin(),
            values.end(),
            [](int value) {
                return value % 2 == 0;
            }),
        values.end());

    std::cout << "after removing even numbers:";
    for (int value : values) {
        std::cout << ' ' << value;
    }
    std::cout << '\n';

    const auto result = find_first_greater_than(values, 7);
    if (result.has_value()) {
        std::cout << "first value > 7 is " << *result << '\n';
    } else {
        std::cout << "no value > 7\n";
    }

    std::pair<int, std::string> response{200, "OK"};
    auto [status_code, message] = response;
    std::cout << "response=" << status_code << ' ' << message << '\n';

    std::tuple<int, std::string, bool> user{7, "FxorG", true};
    auto [id, name, active] = user;
    std::cout
        << "user=" << id << ' ' << name
        << " active=" << std::boolalpha << active
        << '\n';

    return 0;
}
```

你要解释：

```text
为什么 lower_bound 前先 sort
find 找不到时返回什么
remove_if 返回的是什么
为什么还需要 erase
optional 怎样表达无结果
结构化绑定怎样取出 pair / tuple 的字段
```

---

### 9. 今天与系统项目的关系

#### string

```text
网络请求文本
协议字段
日志消息
Redis 命令和 key
```

要警惕 `c_str()` 指针被异步任务长期保存。

#### algorithm

```text
排序事件
查找连接或任务
过滤无效数据
定位插入位置
```

#### optional

```text
查找可能失败
配置项可能不存在
解析结果可能没有值
缓存可能 miss
```

它们让“失败和不存在”进入类型，而不是藏在神秘数字里。

---

## Part C：练习、检查和收尾

### 1. 今日代码目录

Ubuntu：

```bash
~/code/system-learning/cpp/week3/day3
```

创建：

```text
01_string_storage.cpp
02_algorithm_optional.cpp
```

今天不要求单独为 pair / tuple 再建文件。

---

### 2. 编译命令

```bash
g++ -std=c++17 -Wall -Wextra -g 01_string_storage.cpp -o r
./r
```

```bash
g++ -std=c++17 -Wall -Wextra -g 02_algorithm_optional.cpp -o r
./r
```

要求：

```text
零 warning
能解释主要输出
不解引用失效的 c_str 指针
```

---

### 3. 练习一验收

```text
1. c_str() 返回什么类型？
2. 返回的指针是否拥有内存？能不能 delete？
3. 为什么 string 修改后要重新获取 c_str()？
4. string 析构后，旧 c_str 指针会怎样？
5. size() 是否包含结尾 '\0'？
6. find 找不到时返回什么？
7. 为什么只比较旧地址数字，不使用旧指针？
```

---

### 4. 练习二验收

```text
1. sort 接收的 [begin, end) 表示什么？
2. find 找不到时返回什么？
3. lower_bound 为什么要求范围有序？
4. lower_bound 返回的位置为什么不代表一定找到？
5. remove_if 是否改变 vector::size()？
6. erase-remove 分别负责什么？
7. optional 的“无值”怎样表达？
8. pair 和 tuple 怎样通过结构化绑定取值？
```

---

### 5. 中途判断题

#### c_str 生命周期

```cpp
const char* get_text() {
    std::string text = "hello";
    return text.c_str();
}
```

返回的指针能否使用？为什么？

#### lower_bound

```cpp
std::vector<int> values{1, 3, 5, 7};
auto it = std::lower_bound(values.begin(), values.end(), 4);
```

`it` 指向哪个元素？是否说明找到了 4？

#### optional

```cpp
std::optional<int> result = std::nullopt;
```

能否直接调用：

```cpp
result.value();
```

如果无值，应该怎样安全处理？

---

### 6. day3_note.md

建议放在：

```text
C:\Users\FxorG\Desktop\gpt_infra\week3\day3\day3_note.md
```

你掌握较快，不要求回答所有重复问题，只记录三条主线：

```markdown
# Week3 Day3 Note

## c_str 生命周期
- ...

## algorithm 返回值
- find：...
- lower_bound：...
- remove_if：...

## optional
- ...

## 两个 demo 的观察
- ...

## 我还不稳的点
- ...
```

---

### 7. 今日验收问题

```text
1. string 和 vector 在动态存储上有什么相似直觉？
2. c_str() 返回的指针是什么所有权关系？
3. 哪些情况下旧 c_str 指针可能失效？
4. string::size() 是否包含 '\0'？
5. string::find 找不到时怎样判断？
6. 标准算法为什么通常接收 [first, last)？
7. find 和 lower_bound 返回的都是什么？
8. lower_bound 的前提和返回语义是什么？
9. remove_if 为什么不能真正缩短 vector？
10. erase-remove idiom 的两个步骤分别做什么？
11. optional 比返回 -1 清楚在哪里？
12. optional 无值时直接 value() 会怎样？
13. pair / tuple 和结构化绑定解决什么表达问题？
```

---

### 8. 面试追问

```text
std::string::c_str() 返回的指针何时失效？
string 的 size 是否包含 '\0'？
lower_bound 返回什么？
remove_if 为什么还要配合 erase？
optional 适合解决什么问题？
```

推荐回答主线：

```text
先说返回值和所有权。
再说前置条件。
最后说修改容器后生命周期或迭代器是否变化。
```

---

### 9. 今天不要提前深挖

```text
不深挖 small string optimization
不研究 string ABI
不展开 string_view 生命周期
不深挖算法复杂模板实现
不学习 ranges
不把所有 algorithm API 一次背完
不深挖 optional 内存布局
```

---

### 10. 6.S081 / 15-445

```text
6.S081：不开
15-445：不开
```

继续保持 STL 主线。

---

### 11. Git 提交建议

```bash
cd ~/code/system-learning
git status
git add cpp/week3/day3
git commit -m "week3 day3 string algorithms optional"
```

---

### 12. 下一天衔接

Day4 会进入：

```text
map / set 的有序特性
树结构和 O(log n) 直觉
key-value 与纯 key 集合
根据工程场景选择容器
```

Day3 学会理解算法返回值，Day4 会把这些查找和遍历习惯迁移到有序关联容器。
