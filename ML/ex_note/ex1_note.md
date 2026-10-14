## 几个 api

```python
from pathlib import Path
import numpy as np

ml_dir = Path(__file__).resolve().parents[2]
print(Path(__file__).resolve().parents[0])
data_dir = ml_dir / "official_assignments" / "classic_ml_python" / "Exercise1" / "Data"

food_truck = np.loadtxt(data_dir / "ex1data1.txt", delimiter=",")
print(food_truck.shape)
print(food_truck[:5])
```

**`np.loadtxt` 同时按“换行”分出行、按“逗号”分出列。** `delimiter=","` 指定的是**每一行内部**怎样分列。

假设文件内容是：

```text
1,2
3,4
5,6
```

读取过程就是：

```text
第一行 "1,2" → 按逗号拆成 1 和 2
第二行 "3,4" → 按逗号拆成 3 和 4
第三行 "5,6" → 按逗号拆成 5 和 6
```

最终得到：

```python
array([[1., 2.],
       [3., 4.],
       [5., 6.]])
```

**它没有事先规定“两列”，而是从文件中发现每行有两个数。** 如果每行都有三个数，就会得到三列；默认情况下，各行列数不一致会报错。这里默认把数据转换成浮点数。

再看后面两句：

### `food_truck.shape`

`shape` 是数组的**形状属性**，不是函数：

```python
print(food_truck.shape)
# (3, 2)
```

意思是 **3 行、2 列**。你的餐车数据中，每行就是一个城市：

```text
第一列：人口
第二列：利润
```

### `food_truck[:5]`

这是**切片操作：取前五行，保留这些行的全部列**。

```python
print(food_truck[:5])
```

可以把它读成：

```text
food_truck[0:5]
→ 取第 0、1、2、3、4 行
→ 不包含第 5 行
```

如果文件只有上例的三行，就返回全部三行。

所以整段代码的意思是：

> **读取逗号分列、换行分行的数据文件 → 看看共有多少行、多少列 → 打印前五行确认数据内容。**