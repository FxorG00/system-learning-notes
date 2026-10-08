**`np.array()` 用已有数据创建数组；`np.ndarray` 是数组的类型，它的构造函数更底层。**

平常写：

```python
a = np.array([1, 2, 3], dtype=np.float64)

print(a)        # [1. 2. 3.]
print(type(a))  # <class 'numpy.ndarray'>
```

所以两者的关系是：

```text
np.array(...) 创建出来的对象
                 ↓
          类型是 np.ndarray
```

直接调用 `np.ndarray()` 时，传的主要是 **shape（形状）**，不是元素数据：

```python
a = np.ndarray((2, 3), dtype=np.float64)
```

这会分配一个 shape 为 `(2, 3)` 的数组，**元素没有初始化，不能假定都是零**。

你平常根据目的选这些就够了：

```python
np.array([1, 2, 3])  # 从数据创建
np.zeros((2, 3))     # 创建全零数组
np.ones((2, 3))      # 创建全一数组
np.empty((2, 3))     # 创建未初始化数组
```

教程里的：

```python
parameters: np.ndarray
```

是 **类型注解**，表示 `parameters` 应当是 NumPy 数组，并没有调用构造函数。