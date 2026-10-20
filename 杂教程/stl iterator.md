## 基础

先纠正你记忆里的一点：**`std::map` 删除一个元素，只会让指向该元素的 iterator（迭代器）失效，其他元素的迭代器仍然有效。** 我们从“它到底保存什么”开始讲。

**1. Iterator 保存的是访问位置**
比如有两条记录：
```cpp
std::map<int, std::string> records{{1, "Alice"}, {2, "Bob"}};
auto it = records.begin();
std::cout << it->first;   // 1，当前元素的 key
std::cout << it->second;  // Alice，当前元素的 value
++it;                    // 移到下一条记录，现在指向 key=2
```
**迭代器让你找到一个元素，并按容器支持的方式移动到其他位置。** 它通常不拥有元素；复制一个迭代器，只是多保存一个访问位置，不会复制对应记录。

它有点像指针，但不一定就是指针。例如 `map` 的 `++it` 按 key 的排序找到下一条记录，不能理解为地址简单加一。

**2. `end()` 是终点标记**
`begin()` 表示第一个元素，`end()` 表示**越过最后一个元素的位置**。遍历范围写成 `[begin(), end())`：包含起点，不包含终点。

- 指向元素：可以 `*it`、`it->second`。
- 等于 `end()`：可以作为停止标记，但不能解引用，也不能继续 `++`。
- 容器为空：`begin() == end()`。

所以 `find()` 找不到时返回 `end()`，你先比较，再访问。**“没有找到”的迭代器仍是明确的结果，不等于一个尚未初始化的位置。** [标准中的迭代器位置约定](https://eel.is/c++draft/iterator.requirements.general)

**3. 类成员没写初始化，会怎样？**
看这两种声明：
```cpp
using Map = std::map<int, std::string>;
struct Example {
    Map data;
    Map::iterator first;     // 没有显式初始化
    Map::iterator second{};  // 显式值初始化
};
```
在通常的默认构造路径中，`first` 会被默认初始化；对于类类型的迭代器，会调用其默认构造函数。**但标准没有规定它自动等于某个容器的 `end()`，更不会自动指向 `data.begin()`。**

`second{}` 也没有和 `data` 建立关系。底层是不是空指针属于实现细节，不能当成统一的“默认值”使用。

你真正需要的是：**先让成员取得一个属于具体容器的位置，再使用它。** 默认构造的迭代器可以先放着，随后赋一个有效位置；不要先解引用、递增，或拿它随意与 `data.end()` 比较。[默认构造与奇异迭代器规则](https://eel.is/c++draft/iterator.requirements.general)

如果你的设计明确规定“暂时没有当前位置”，可以这样表达：
```cpp
struct Example {
    Map data;                           // 先构造容器
    Map::iterator cursor = data.end();   // 再取得这个容器的终点
};
```
成员按**声明顺序**初始化，所以这里 `data` 必须在前。以后明确执行 `cursor = data.begin()` 或 `data.find(key)`，才取得要访问的位置。

**4. 失效是什么意思？**
**失效表示：原先取得的访问位置，已经不能按原来的方式继续使用。** 迭代器变量可能还在，里面的位也没改变，但这不代表它仍合法；它不会自动变成 `end()`。

对 `map` 来说，假设 `a` 指向 key=1，`b` 指向 key=2：执行 `records.erase(a)` 后，`a` 失效，`b` 仍有效。树即使内部调整，也必须兑现这个保证。[关联容器的失效规则](https://eel.is/c++draft/associative.reqmts)

常见情况可以这样记：

| 容器与操作 | 对原有迭代器的影响 |
|---|---|
| `map/set` 插入 | 不使原有迭代器失效 |
| `map/set` 删除 | 只有被删除元素的迭代器失效 |
| `list` 插入、删除 | 插入不影响；删除只影响被删元素 |
| `vector` 扩容、重新分配存储 | 所有迭代器失效 |
| `vector` 插入但未重新分配 | 插入位置及之后失效，包括旧 `end()` |
| `vector` 删除 | 删除位置及之后失效，包括旧 `end()` |
| `unordered_map` 插入 | 若触发 rehash（重新组织哈希桶），所有迭代器失效 |
| `unordered_map` 删除 | 只有被删除元素的迭代器失效 |

**规则跟容器和操作有关，不能统一记成“修改容器就全部失效”。** 哈希表 rehash 后，元素的指针、引用仍可保持有效，但迭代器失效，三者也要分开判断。[vector 规则](https://eel.is/c++draft/vector.modifiers)、[哈希容器规则](https://eel.is/c++draft/unord.req)

**5. 遍历时删除，怎样接着走？**
`map::erase(it)` 会返回被删除位置之后的迭代器，直接接住：
```cpp
for (auto it = records.begin(); it != records.end(); ) {
    if (it->first == 1) {
        it = records.erase(it);
    } else {
        ++it;
    }
}
```
这里删除分支**不再额外 `++it`**：`erase` 已经给出了下一位置。反过来，先 `erase(it)` 再 `++it`，就是在递增已经失效的迭代器。

**6. 作为类成员，还要考虑生命周期**
成员迭代器会跨函数调用保留，因此你要能回答：**它属于哪个容器？两次调用之间，谁可能删除它指向的元素？**

还有一个容易漏的点：类同时保存容器和迭代器时，默认复制类对象，**不会自动把复制后的迭代器重新绑定到新容器**。新容器复制了元素，迭代器却可能仍指向原容器，所以这种类的复制行为需要单独设计。

最后补两个常用区别：`map` 的迭代器支持 `++/--`，不支持 `it + 3`；`vector` 的迭代器支持随机跳转。`const_iterator` 表示通过它不能修改元素，但迭代器自身仍可以移动。

你现在最该建立的是这条判断链：**先确定它绑定到哪里，再确认当前位置能否访问，最后检查期间发生的容器操作是否让它失效。**

## .end

**对于同一个仍然存活的 `std::map`，如果期间只做 `insert/emplace/erase`，之前保存的 `end()` 仍然有效，并且等于之后取得的 `end()`。** 即使从空变成非空，或者把元素全部删空，也是如此。[标准规定](https://eel.is/c++draft/associative.reqmts#general-175)

例如：

```cpp
std::map<int, int> data;
auto stop = data.end();

data.emplace(1, 100);
assert(stop == data.end());

data.emplace(2, 200);
assert(stop == data.end());

data.erase(1);
assert(stop == data.end());

data.erase(2);  // 现在又空了
assert(stop == data.end());
assert(data.begin() == stop);
```

你可以这样建立直觉：

**`map.end()` 代表这个容器的终点标记，不是“最后一个元素的地址加一”。** 元素数量、最后一个元素可以改变，但这些插入、删除操作不改变这个终点身份。

这里有一个直接影响你代码的结果：

```cpp
cursor = data.end();
data.emplace(3, 300);
```

**此时 `cursor` 仍然等于 `data.end()`，不会自动指向新插入的元素。** 想开始遍历，需要你明确执行 `cursor = data.begin()` 等操作。

不过，“以后每个时刻都一样”要限定范围：**不要把上述保证推广到交换、赋值、移动或销毁容器。** 例如 `swap` 不保证保留旧的尾后迭代器；发生这些操作后，应重新取得 `end()`。[容器交换规则](https://eel.is/c++draft/container.requirements.general#66)