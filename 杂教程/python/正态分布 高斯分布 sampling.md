**这里用 NumPy 的 `rng.normal()`：生成服从正态分布（也叫高斯分布）的随机数。** 教程应该先把这个 API 讲清楚，再让你生成数据。

你的目标是：**让 100 个点散布在中心 `(-2,-1)` 周围，而不是全部重叠在中心上。**

```python
import numpy as np

rng = np.random.default_rng(2026)  # 创建随机数生成器，2026 是 seed

noise = rng.normal(
    loc=0.0,       # 均值：扰动围绕 0
    scale=0.8,     # 标准差：控制散开的程度
    size=(100, 2)  # 100 个点，每个点的两个坐标各有一个扰动
)

center = np.array([-2.0, -1.0])
points = center + noise

print(points.shape)  # (100, 2)
print(points[:3])    # 看前三个点
```

三个参数记成：

| 参数 | 含义 | 本次设置 |
|---|---|---|
| `loc` | 正态分布的均值 | `0.0` |
| `scale` | **标准差，不是方差** | `0.8` |
| `size` | 返回数组的形状 | `(100, 2)` |

这些含义对应 [NumPy 官方文档](https://numpy.org/doc/stable/reference/random/generated/numpy.random.Generator.normal.html)。

**`center + noise` 就是在给每个点的坐标加上随机偏移。** 举个示意：

```text
中心             随机偏移           得到的点
(-2, -1)    +   ( 0.3, -0.2)   =   (-1.7, -1.2)
(-2, -1)    +   (-0.5,  0.4)   =   (-2.5, -0.6)
```

这里使用你学过的 broadcasting：`center [2]` 加到 `noise [100,2]` 的每一行。

另外，**0.8 控制分布的散布程度，不表示偏移被限制在 ±0.8 内**。其他两类沿用相同生成方式，换中心，并分别配上标签 1、2 即可。

`default_rng(2026)` 用固定种子初始化生成器，在相同环境和调用顺序下可以复现数据；**整份数据创建一次 rng，再连续使用它**。[随机数生成器说明](https://numpy.org/doc/stable/reference/random/generator.html)