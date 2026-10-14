不用逐个列举 `int16/int32/int64`，用 **`np.issubdtype(labels.dtype, np.integer)`**：检查 `labels` 的元素类型是否属于整数类型。

```python
labels = np.array([0, 2], dtype=np.int32)

if not np.issubdtype(labels.dtype, np.integer):
    raise ValueError("labels must have an integer dtype")
```

它会接受各种有符号和无符号整数类型，拒绝浮点和布尔类型：

```python
np.issubdtype(np.dtype("int64"), np.integer)    # True
np.issubdtype(np.dtype("uint16"), np.integer)   # True
np.issubdtype(np.dtype("float64"), np.integer)  # False
np.issubdtype(np.dtype("bool"), np.integer)     # False
```

**类型检查通过后，再检查每个 label 是否满足 `0 <= label < C`。** `0.0` 即使数值像整数，它的 dtype 仍然是浮点，不符合这个接口的契约。