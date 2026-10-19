**Python 的 `lambda` 和 C++ 的 lambda 都是匿名函数：临时写一个函数，当作参数传给别人。** 你熟悉的“排序时传入一段逻辑”，就是同一种用途。

### 先看语法对应

Python：

```python
lambda x: x * 2
```

C++：

```cpp
[](int x) { return x * 2; }
```

对应起来看：

| 部分 | Python | C++ |
|---|---|---|
| 参数 | `x` | `(int x)` |
| 函数体 | 冒号后的表达式 | `{ ... }` |
| 返回值 | 表达式的结果自动返回 | 通常写 `return` |
| 捕获外部变量 | 不写捕获列表 | 用 `[]`、`[x]`、`[&x]` 等 |

Python 的 lambda **只能放一个表达式**。需要多条语句、循环或复杂判断时，直接用 `def`。

### 接回刚才的排序

```python
key=lambda item: (item["loss"], -item["accuracy"])
```

相当于先写：

```python
def sorting_key(item):
    return item["loss"], -item["accuracy"]
```

再传进去：

```python
candidates.sort(key=sorting_key)
```

**lambda 只是在这里省去了单独起函数名。** 注意，这个函数收到一个候选，返回排序依据；它不是 C++ `sort` 里接收两个元素的比较器。

### 外部变量怎么用？

Python 可以直接引用外部名字：

```python
factor = 2
f = lambda x: x * factor

factor = 3
print(f(10))  # 30
```

这里调用时才读取 `factor`，**不是创建 lambda 时自动复制一份值**。这个例子的效果更接近 C++ 的引用捕获：

```cpp
int factor = 2;
auto f = [&factor](int x) { return x * factor; };

factor = 3;
// f(10) == 30
```

若希望固定创建时的值，Python 常用默认参数：

```python
factor = 2
f = lambda x, factor=factor: x * factor

factor = 3
print(f(10))  # 20
```

**先记住：Python 是 `lambda 参数: 返回表达式`；C++ 是 `[捕获](参数) { 函数体 }`。**



对，**这个函数有两个参数，第二个参数 `factor` 的默认值，来自创建函数时外部变量 `factor` 的值。** 注释 1

```
factor = 2
f = lambda x, factor=factor: x * factor
#             左边   右边
#             参数名  此时外部变量的值：2
```

关键是：**默认值在创建函数时求值，不是每次调用时重新读取外部变量。**

```
factor = 3

print(f(10))     # 第二个参数没传，用默认值 2 -> 20
print(f(10, 5))  # 显式传入 5，覆盖默认值 -> 50
```

这里内外两个名字恰好都叫 `factor`。换个名字会更清楚：

```
factor = 2
f = lambda x, multiplier=factor: x * multiplier
```