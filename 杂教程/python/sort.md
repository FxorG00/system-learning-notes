可以，不过 Python 排序通常用 **`key`：告诉它“按什么值排序”**，比手写 `cmp` 更常用。

比如你记录了三个候选：

```python
candidates = [
    {"name": "A", "loss": 0.30, "accuracy": 0.85},
    {"name": "B", "loss": 0.22, "accuracy": 0.90},
    {"name": "C", "loss": 0.22, "accuracy": 0.88},
]
```

你想要 **loss 从小到大；loss 相同时，accuracy 从大到小**：

```python
candidates.sort(key=lambda item: (item["loss"], -item["accuracy"]))
```

这里 `lambda` 是匿名函数，给每个候选取出一个排序用的 tuple（元组）：

```text
A -> (0.30, -0.85)
B -> (0.22, -0.90)
C -> (0.22, -0.88)
```

**元组先比较第一项，相同再比较第二项。** 所以结果是 B、C、A。两项都相同时，Python 的稳定排序会保留原顺序，正好符合你之前定的规则。

### 真要像 C++ 一样写 cmp

用 `cmp_to_key`：

```python
from functools import cmp_to_key

def cmp(a, b):
    if a["loss"] < b["loss"]:
        return -1
    if a["loss"] > b["loss"]:
        return 1

    if a["accuracy"] > b["accuracy"]:
        return -1
    if a["accuracy"] < b["accuracy"]:
        return 1

    return 0

candidates.sort(key=cmp_to_key(cmp))
```

注意与 C++ 的区别：**这里的 cmp 返回负数、0、正数，分别表示 a 排前面、相等、a 排后面；不是返回 bool。**

另外，`list.sort()` **直接修改原列表，返回 `None`**；`sorted(candidates, key=...)` 则返回一个排好序的新列表。