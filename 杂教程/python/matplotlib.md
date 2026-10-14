**用 Matplotlib（Python 绘图库）。这张图主要用两个 API：`scatter` 画真实数据的点，`plot` 画训练得到的直线。**

先导入：

```python
import numpy as np
import matplotlib.pyplot as plt
```

`plt` 只是给 `matplotlib.pyplot` 起的简短名字。

**1. `plt.scatter(x, y)`：画散点**

例如：

```python
plt.scatter([1, 2, 3], [2, 5, 4])
```

它会画三个点：**`(1,2)`、`(2,5)`、`(3,4)`**。两个数组中相同下标的元素组成一个坐标。[官方说明](https://matplotlib.org/stable/api/_as_gen/matplotlib.pyplot.scatter.html)

在你的作业中，每个点就是：

```text
横坐标：某个城市的人口
纵坐标：这个城市的真实利润
```

**2. `plt.plot(x, y)`：按顺序连接这些点**

例如：

```python
plt.plot([1, 3], [2, 6])
```

它把 `(1,2)` 和 `(3,6)` 连起来。**你的模型是一条直线，因此算出人口范围两端的预测值，再连接这两个点即可。** [官方说明](https://matplotlib.org/stable/api/_as_gen/matplotlib.pyplot.plot.html)

**放到你的作业里**

假设 `food_truck` 已读入，`theta` 是训练得到的参数，模型为：

$$
\hat y=\theta_0+\theta_1x
$$

其中 $\theta_0$ 是截距，$\theta_1$ 是斜率：

```python
x = food_truck[:, 0]  # 所有城市的人口
y = food_truck[:, 1]  # 所有城市的真实利润

# 取人口范围的两端，计算模型在这两处的预测。
x_line = np.array([x.min(), x.max()])
y_line = theta[0] + theta[1] * x_line

plt.figure()  # 创建一张新图

plt.scatter(x, y, color="red", marker="x", label="Actual data")
plt.plot(x_line, y_line, color="blue", label="Trained model")

plt.xlabel("Population (10,000 people)")
plt.ylabel("Profit (10,000 USD)")
plt.title("Food truck linear regression")
plt.legend()

plt.savefig("food_truck_fit.png", dpi=150, bbox_inches="tight")
plt.show()
```

这里新增参数的含义：

| 写法 | 作用 |
|---|---|
| `color="red"` | 使用红色 |
| `marker="x"` | 散点画成叉号 |
| `label="Actual data"` | 给这一组点命名 |
| `plt.legend()` | 显示这些名称对应的图例 |
| `xlabel/ylabel/title` | 设置横轴、纵轴、标题 |
| `savefig(...)` | 保存图片；`dpi` 控制分辨率，`bbox_inches="tight"` 收紧外围空白 |
| `show()` | 在支持图形界面的环境中显示图 |

**最终你应该看到：红色叉号是历史数据，蓝色直线是你训练出来的预测关系。** Matplotlib 接收你算好的坐标，负责把它们画出来。

你在 Ubuntu Remote SSH 中运行时，先用 `savefig` 保存图片即可；没有图形界面时，可以省略 `show()`。