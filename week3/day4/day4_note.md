## map/set 迭代器失效

对于 map/set，删除一个元素，只会让指向被删除元素的迭代器失效。

## mp 的 [] 会插入

就是如果 `mp["nihao"]` 不存在的话。你写 `int value=mp["nihao"]` 会向 map 插入 `key="nihao"` 的元素，并且对 value 做初始化，然后返回这个 value 的引用。

## 迭代器 iterator 理解

```text
迭代器 ≈ STL 的广义指针
本质 = 表示容器中的位置 + 提供访问和移动操作
```

## insert 返回的 pair

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

## 练习 2 问题

```text
batch 为什么先 sort，才能使用 lower_bound
lower_bound 本质是二分，要求单调，这个单调可以是你定义的某个关系。

数据一次构建、查询很多时，为什么 sorted vector 可能很好用
因为是静态数据结构，我们不需要插入删除，而 query 这些反而是 sorted vector 的强项。我打 oi 的时候就是数据结构大神啊，你问我这些都太简单了。

dynamic_tasks 插入 25 后为什么仍自动有序
插入 25、删除 10 后，saved 为什么仍然有效
如果删除的是 key=20，saved 为什么立即失效
lower_bound(24) 为什么指向 25
删除 10，只影响 10 这个 key 的迭代器。
都太简单了。

范围 [20, 29] 为什么用 lower_bound(20) 和 upper_bound(29)
[<=20,>29) 
```

我打 oi 的时候就是数据结构大神啊，你问我这些都太简单了。今天简单了。