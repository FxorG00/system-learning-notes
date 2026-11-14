这段代码的目标是：**训练过程中记下每个时刻的 MSE，然后把同一份记录分别保存成表格和曲线。**

整条路径是：

```text
训练模型
   ↓
每 20 次更新测量 train / validation MSE
   ↓
保存在 history 中
   ├── 写成 history.csv，方便查看具体数字
   └── 画成 curves.png，方便观察变化趋势
```

我们从这两个函数共同使用的 `history` 看起。

## 1. `history` 里装的是什么？

你在训练函数里创建了：

```python
history = []
```

然后每隔 20 次参数更新，就调用：

```python
record(i + 1)
```

`record()` 会算出当前模型在训练集和验证集上的 MSE，把它们存成一个字典，再加进 `history`：

```python
history.append({
    "epoch": epoch,
    "train_mse": evaluate_mse(model, train_x, train_y),
    "validation_mse": evaluate_mse(model, validation_x, validation_y),
})
```

假设训练到 40 轮，`history` 看起来可能是：

```python
history = [
    {"epoch": 0,  "train_mse": 0.80, "validation_mse": 0.85},
    {"epoch": 20, "train_mse": 0.50, "validation_mse": 0.60},
    {"epoch": 40, "train_mse": 0.30, "validation_mse": 0.45},
]
```

每个字典是一条记录：

```text
在哪一轮测量
→ 训练集误差是多少
→ 验证集误差是多少
```

你的代码还会在训练前记录 `epoch 0`。所以训练 2000 次、每 20 次记录一次，最终共有 **101 条记录**：第 0 轮一条，后面每 20 轮一条。

---

# 一、把记录保存成 CSV

## 2. CSV 是什么？

CSV 是一种用文本保存表格的格式。你这份 `history` 写出去以后，大致是：

```csv
epoch,train_mse,validation_mse
0,0.8,0.85
20,0.5,0.6
40,0.3,0.45
```

第一行是列名，后面每一行对应 `history` 里的一个字典。

所以：

```text
Python 内存中的 list[dict]
        ↓
保存成文件
        ↓
history.csv
```

以后你可以用文本编辑器、表格软件或者 Python 再读取它。Python 的 `csv` 模块负责处理这些行和列的格式。[Python 官方 csv 文档](https://docs.python.org/3/library/csv.html)

## 3. 文件放在哪里？

你的 `main()` 里有：

```python
output_directory = Path(__file__).resolve().parent / "out"
```

假设你的脚本位置是：

```text
/home/xgf/code/t13_generalization/overfit_observation.py
```

这行一步步得到：

```text
Path(__file__)
→ 当前脚本的路径

.resolve()
→ 转成解析后的绝对路径

.parent
→ 脚本所在目录

/ "out"
→ 在这个目录后面接上 out
```

因此：

```text
output_directory
= /home/xgf/code/t13_generalization/out
```

然后：

```python
output_directory / "history.csv"
```

得到：

```text
/home/xgf/code/t13_generalization/out/history.csv
```

这里 `/` 是 `Path` 用来**拼接路径**的，不是数学除法。

## 4. 创建目录

保存 CSV 的函数一开始写了：

```python
output_path.parent.mkdir(parents=True, exist_ok=True)
```

假设 `output_path` 是：

```text
/home/xgf/code/t13_generalization/out/history.csv
```

那么：

```python
output_path.parent
```

就是：

```text
/home/xgf/code/t13_generalization/out
```

接下来的 `mkdir()` 创建这个目录：

- `parents=True`：需要时一并创建不存在的父目录。
- `exist_ok=True`：目录已经存在时不报错。

**它创建的是目录，不是 `history.csv` 文件。**

## 5. 打开 CSV 文件

```python
with output_path.open(
    "w",
    newline="",
    encoding="utf-8",
) as csv_file:
```

这里得到的 `csv_file` 是一个已经打开的文件对象，后面要把表格写进去。

几个参数分别是：

```text
"w"
→ 写入模式；文件不存在时创建，已经存在时会清空原内容

newline=""
→ 让 csv 模块自己处理换行

encoding="utf-8"
→ 文字使用 UTF-8 编码
```

离开 `with` 的缩进范围后，文件会自动关闭。即使中间发生异常，也会执行关闭。

**注意：你再次运行程序时，同一个 `history.csv` 会被覆盖，不是追加。**

## 6. `DictWriter` 怎样把字典写成表格？

```python
writer = csv.DictWriter(
    csv_file,
    fieldnames=("epoch", "train_mse", "validation_mse"),
)
```

可以把 `writer` 理解成一个“表格写入器”：

- `csv_file`：写到哪个已经打开的文件。
- `fieldnames`：表格有哪些列，以及列的顺序。

随后：

```python
writer.writeheader()
```

写入列名：

```csv
epoch,train_mse,validation_mse
```

再执行：

```python
writer.writerows(history)
```

它会依次读取 `history` 中的每个字典，按照 `fieldnames` 的顺序写入各列。

例如：

```python
{"epoch": 20, "train_mse": 0.50, "validation_mse": 0.60}
```

会变成类似：

```csv
20,0.5,0.6
```

**到这里，CSV 就完成了。**

---

# 二、把记录画成曲线

## 7. 先准备横轴和纵轴数据

画图需要知道：每个点的横坐标是多少，纵坐标是多少。

你的代码先从 `history` 里分别取出三列：

```python
epochs = [row["epoch"] for row in history]
train_mse = [row["train_mse"] for row in history]
validation_mse = [row["validation_mse"] for row in history]
```

这是 Python 的**列表推导式**。比如第一行相当于：

```python
epochs = []

for row in history:
    epochs.append(row["epoch"])
```

对前面的示例，得到：

```python
epochs = [0, 20, 40]
train_mse = [0.80, 0.50, 0.30]
validation_mse = [0.85, 0.60, 0.45]
```

这三份列表的位置是一一对应的：

```text
epoch 0  → train MSE 0.80 → validation MSE 0.85
epoch 20 → train MSE 0.50 → validation MSE 0.60
epoch 40 → train MSE 0.30 → validation MSE 0.45
```

## 8. `plt.subplots()` 创建什么？

```python
figure, axis = plt.subplots()
```

它返回两个对象：

```text
figure：整张图
axis：图里面放曲线的坐标区域
```

可以这样理解：

```text
figure：整张画布
┌────────────────────────────┐
│         图表标题             │
│                            │
│   axis：坐标区域             │
│   │    train 曲线           │
│   │    validation 曲线      │
│   └──────────────────      │
└────────────────────────────┘
```

这次默认只有一个坐标区域，所以得到一个 `axis`。后续画曲线是在 `axis` 上画；保存整张图片则由 `figure` 完成。[Matplotlib `subplots` 文档](https://matplotlib.org/stable/api/_as_gen/matplotlib.pyplot.subplots.html)

## 9. `plot()` 怎样把数据变成线？

```python
axis.plot(epochs, train_mse, label="train MSE")
```

第一份列表是横坐标，第二份是纵坐标。对应起来就是：

```text
(0,  0.80)
(20, 0.50)
(40, 0.30)
```

`plot()` 在坐标区域里画出这些点，并按顺序把它们连起来。

`label="train MSE"` 是给这条线起名字，后面图例会用到。

第二行同理：

```python
axis.plot(epochs, validation_mse, label="validation MSE")
```

于是**同一个坐标区域里有两条线**，可以比较训练误差和验证误差怎样变化。

## 10. 加标题、图例并保存

```python
axis.set(
    xlabel="epoch",
    ylabel="MSE",
    title="T13 baseline curves",
)
```

分别设置：

```text
xlabel → 横轴名称：epoch
ylabel → 纵轴名称：MSE
title  → 图表标题
```

然后：

```python
axis.legend()
```

根据刚才两次 `plot()` 的 `label` 显示图例，让你知道哪条线是 train，哪条线是 validation。

```python
figure.tight_layout()
```

调整布局，尽量让标题、坐标轴名称等内容不要挤在一起。

```python
figure.savefig(output_path, dpi=140)
```

把整张图保存到 `output_path`。你的路径以 `.png` 结尾，因此保存为 PNG 图片；`dpi=140` 控制保存图片的分辨率。

最后：

```python
plt.close(figure)
```

关闭这张图，释放 Matplotlib 对它持有的资源。**图片已经保存，不会因为关闭而被删除。**

## 11. 为什么要用 `Agg`？

你在 Ubuntu 上通过 SSH 运行脚本，不一定有图形窗口可以弹出。所以开头写了：

```python
import matplotlib
matplotlib.use("Agg")

import matplotlib.pyplot as plt
```

这里选择 `Agg` 作为 Matplotlib 的**非交互式绘图后端**。简单说，就是让它在没有弹窗的情况下生成图片文件。

因此程序运行后，你不会看到一个窗口弹出来；结果直接写进：

```text
out/curves.png
```

`matplotlib.use("Agg")` 放在导入 `pyplot` 之前，确保后续绘图使用这个后端。[Matplotlib 后端说明](https://matplotlib.org/stable/users/explain/figure/backends.html)

---

最后把两个输出放在一起看：

```text
history
├── save_history_csv()
│   └── history.csv：保存每次测量的具体数字
│
└── save_curves()
    └── curves.png：把同样的数字画成两条曲线
```

**画图并没有重新训练模型，也没有重新计算 MSE。** 它只是读取你训练时已经记录在 `history` 里的数。