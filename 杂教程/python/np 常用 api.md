假设已 `import numpy as np`，并有 `a = np.array([[1., 2., 3.], [4., 5., 6.]])`：

| API / 参数 | 用途 | 最小例子 |
|---|---|---|
| `np.array` | 从列表创建数组，指定元素类型 | `np.array([1, 2, 3], dtype=np.float64)` |
| `np.zeros` / `np.ones` | 创建全 0 / 全 1 数组 | `np.zeros((2, 3))` |
| `np.full` | 创建全部为指定值的数组 | `np.full((2, 3), 7)` |
| `np.arange` | 按步长生成序列，**不包含终点** | `np.arange(0, 10, 2)` |
| `np.linspace` | 生成指定数量的等间距数，默认包含两端 | `np.linspace(0, 1, 5)` |
| `a.shape` / `a.ndim` / `a.size` | 形状 / 维数 / 元素总数 | 分别为 `(2, 3)`、`2`、`6` |
| `a.dtype` / `a.astype` | 查看 / 转换元素类型 | `a.astype(np.float32)` |
| `a.reshape` | 改变形状，元素总数不变 | `a.reshape(3, 2)` |
| `a.T` / `np.transpose` | 转置；多维数组可指定轴顺序 | `a.T` |
| `a.copy` | 复制数据，修改副本不会影响原数组 | `b = a.copy()` |
| `np.sum` | 求和 | `np.sum(a, axis=1)` → `[6, 15]` |
| `np.mean` | 算术平均值 | `np.mean(a, axis=1)` → `[2, 5]` |
| `np.average` | 加权平均值 | `np.average([10, 20], weights=[1, 3])` → `17.5` |
| `np.median` | 中位数 | `np.median(a)` → `3.5` |
| [np.var](https://numpy.org/doc/stable/reference/generated/numpy.var.html) | 方差；默认 `ddof=0`，除以元素数量 | `np.var(a)`；样本方差用 `np.var(a, ddof=1)` |
| [np.std](https://numpy.org/doc/stable/reference/generated/numpy.std.html) | 标准差；同一参数下等于方差的平方根 | `np.std(a)`；样本标准差用 `np.std(a, ddof=1)` |
| `np.min` / `np.max` | 最小值 / 最大值 | `np.max(a, axis=1)` → `[3, 6]` |
| `np.argmin` / `np.argmax` | 最小值 / 最大值的位置索引 | `np.argmax(a, axis=1)` → `[2, 2]` |
| `np.percentile` | 百分位数，参数范围 0～100 | `np.percentile(a, 50)` → 中位数 |
| `np.abs` / `np.sqrt` | 逐元素绝对值 / 平方根 | `np.sqrt(a)` |
| `np.exp` / `np.log` | 逐元素指数 / 自然对数 | `np.exp(a)`；`np.log(a)` |
| `np.clip` | 把元素限制在给定范围内 | `np.clip(a, 2, 5)` |
| `np.where` | 根据条件逐元素选择结果 | `np.where(a > 3, a, 0)` |
| `np.concatenate` | 沿**已有轴**拼接数组 | `np.concatenate([a, a], axis=0)` → shape `(4, 3)` |
| `np.stack` | 增加**新轴**后堆叠数组 | `np.stack([a, a], axis=0)` → shape `(2, 2, 3)` |
| `np.sort` / `np.argsort` | 排序后的值 / 对应索引 | `np.argsort([30, 10, 20])` → `[1, 2, 0]` |
| `np.unique` | 获取不重复的值 | `np.unique([1, 1, 2])` → `[1, 2]` |
| `@` / `np.matmul` | 矩阵乘法 | `a @ a.T` → shape `(2, 2)` |
| `np.all` / `np.any` | 是否全部 / 至少一个条件成立 | `np.all(a > 0)` → `True` |
| `np.allclose` | 判断数值是否在容差内接近 | `np.allclose(a, a + 1e-10)` |
| `axis` | 指定聚合哪条轴；二维中 `0` 得每列结果，`1` 得每行结果；默认 `None` 聚合全部元素 | `np.mean(a, axis=0)` → `[2.5, 3.5, 4.5]` |
| `keepdims=True` | 聚合后保留该轴，长度变成 1，方便后续广播 | `np.mean(a, axis=1, keepdims=True)` → shape `(2, 1)` |