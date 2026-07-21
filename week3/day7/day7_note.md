## idea

其实就是多了一个，当缓存已经满了，就删除掉 LRU，然后再加入。

### get

```text
给你一个 key，查询这个 key 对应的 value。

先去 check key 的存在性，那就用 unordered_map。

然后我们底层用 list，所以 unordered_map<int,list<int>::iterator> 存放一个 key 对应的元素在底层 list 的位置。

我们找到这个迭代器后就找到 value 了。

然后规定 front 是 MRU，back 是 LRU，所以我们把这个迭代器 erase 了，然后直接 push_front 这个元素
```

### pop LRU

```text
清除 LRU
先判 empty
not empty 的话，直接让 list pop_back，并且在 unordered_map 里面 erase 掉这个 key。
```



### put

```text
给你 key-value

如果 key 不存在，现在 list push_front 这个元素，其为 MRU，然后再在 unordered_map 形成一个 mapping

如果 key 不存在但是缓存已经满了，那么 pop LRU。

如果 key 存在，那么去更新 value。以及让这个元素成为 MRU。

保证缓存中不出现重复 key。
```

## 实现

### 初始化成员列表

```text
list(n)          -> 创建 n 个元素
map()            -> 创建空 map
unordered_map(n) -> 创建空哈希表，n 与 bucket 数量有关

但其实这里 LRU_Cache，我们并不需要一开始就创建 n 个元素的 list，而是一个个插入进去。
```



## list api 使用教程

下面只讲 `std::list` API，不涉及 LRU 的具体实现。

先包含：

```
#include <list>
```

假设：

```
std::list<int> values{10, 20, 30};
```

**begin / end**

```
auto it = values.begin();
auto end = values.end();
```

- `begin()`：返回指向第一个元素的迭代器。
- `end()`：返回尾后迭代器，不指向任何元素。
- 空 list 满足 `begin() == end()`。
- 不能解引用 `end()`。

```
for (auto it = values.begin(); it != values.end(); ++it) {
    std::cout << *it << '\n';
}
```

`list` 是双向链表，所以迭代器支持：

```
++it;
--it;
```

但不支持：

```
it + 3;    // 错误
values[3]; // 错误
```

------

**front / back**

```
int first = values.front(); // 10
int last = values.back();   // 30
```

返回的是引用，因此可以修改：

```
values.front() = 100;
values.back() = 300;
```

注意：空 list 调用 `front()` 或 `back()` 是未定义行为，必须先判断：

```
if (!values.empty()) {
    std::cout << values.front();
}
```

------

**push_front**

在链表开头插入已有对象：

```
values.push_front(5);
```

结果：

```
5 10 20 30
```

有左值和右值版本：

```
void push_front(const T& value);
void push_front(T&& value);
```

复杂度是 `O(1)`，不会让已有元素的迭代器和引用失效。

------

**emplace_front**

直接在链表开头构造元素：

```
values.emplace_front(5);
```

对于 `int`，它和 `push_front(5)` 差别不明显。

对象类型时更直观：

```
struct User {
    int id;
    std::string name;
};

std::list<User> users;
users.emplace_front(1, "FxorG");
```

它会直接调用 `User(1, "FxorG")` 在链表节点中构造对象。

复杂度是 `O(1)`。

------

**pop_back**

删除最后一个元素：

```
values.pop_back();
```

注意它：

```
只负责删除
没有返回值
```

如果想先取得最后一个元素：

```
if (!values.empty()) {
    int value = values.back();
    values.pop_back();
}
```

空 list 调用 `pop_back()` 是未定义行为。

被删除元素的迭代器、指针和引用失效，其他元素的不失效。

------

**erase**

删除迭代器指向的元素：

```
auto it = values.begin();
++it;

it = values.erase(it);
```

`erase(it)` 返回**被删除元素后面那个元素的迭代器**。

单元素版本：

```
iterator erase(const_iterator pos);
```

范围版本：

```
iterator erase(
    const_iterator first,
    const_iterator last);
```

范围仍然是：

```
[first, last)
```

例如：

```
values.erase(values.begin(), values.end());
```

会删除所有元素。

注意：

- 不能执行 `erase(values.end())`。
- 只有被删除元素的迭代器和引用失效。
- 已知迭代器时，删除单个 list 节点是 `O(1)`。

------

**splice**

`splice` 的意思是把已有链表节点移动到另一个位置。

移动一个节点：

```
auto it = values.begin();
++it; // 指向第二个元素

values.splice(values.begin(), values, it);
```

原本：

```
10 20 30
```

操作后：

```
20 10 30
```

参数含义：

```
values.splice(
    values.begin(), // 移动到这个位置之前
    values,         // 节点来自哪个 list
    it);            // 移动哪个节点
```

它移动的是节点，不是复制元素：

```
节点地址通常不变
指向该节点的迭代器仍然有效
单节点移动是 O(1)
```

还可以移动整个 list：

```
destination.splice(destination.end(), source);
```

或者移动一段范围：

```
destination.splice(
    destination.end(),
    source,
    first,
    last);
```

同样使用 `[first, last)`。

------

**size / empty**

```
std::size_t count = values.size();
bool is_empty = values.empty();
```

- `size()`：返回元素数量。
- `empty()`：判断是否没有元素。
- 两者都是 `O(1)`。

判断为空优先写：

```
if (values.empty()) {
}
```

而不是：

```
if (values.size() == 0) {
}
```

前者语义更直接。

**最需要记住的部分**

```
list 不支持下标和 it + n
front / back / pop_back 不能用于空 list
erase 返回被删除元素的下一个迭代器
splice 移动节点，不复制节点
插入和移动通常不让已有 iterator 失效
erase 只让被删除节点的 iterator 失效
已知 iterator 时，单节点插入、删除、移动都是 O(1)
```