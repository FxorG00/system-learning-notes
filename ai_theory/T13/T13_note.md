# R1

## MSE

**MSE = Mean Squared Error**，中文叫**均方误差**。

可以拆成：

- **Mean**：平均
- **Squared**：平方后的
- **Error**：误差

它的计算过程是：**每个预测值减去真实值 → 把误差平方 → 对所有样本求平均。**

对于 \(N\) 个样本：

$$
\mathrm{MSE}=\frac{1}{N}\sum_{i=1}^{N}(\hat{y}_i-y_i)^2
$$

其中 $\hat{y}_i$是预测值，$y_i$ 是真实值。

## 要干啥

- 使用第 4 节的固定数据、模型、seed、AdamW 与 `weight_decay=0.0`。

```text
`Linear(1,64) -> ReLU -> Linear(64,64) -> ReLU -> Linear(64,1)`

也就是 input_dim=1, hidden_dim=64, class_count=1
```



- 完成 2000 次 full-batch 更新；记录 epoch 0 和每 20 次更新后的两种 MSE。

```text
也就是每 20 次 step 就记录一次对 train MSE, validation MSE
```



- 将记录保存到 `out/history.csv`，画出 `out/curves.png`。
- 打印初始、最后与“记录中最低 validation MSE 对应”的 epoch / train MSE / validation MSE。
- 暂不使用 test set，不加入 regularization，不要求保存最佳权重。

## validation loss, train loss 必须使用统一把尺子测量

```text
所以我们统一了一个测量 api
```

# R2

## SGD,Adam

你当然可以把“惩罚 \(w\) 太大”的一项加进 loss。**这在数学和代码上都是合法的。**

这里真正要讲的是：

> **对于普通 SGD，“往 loss 加惩罚项”和“更新时额外缩小权重”效果相同；但换成 Adam 后，这两种做法一般不再相同。**

讲义直接提“历史梯度统计”，却没有先把这两种做法摆出来，所以读着会很跳。我们从你已经会的参数更新开始。

### 1. 先回到你熟悉的参数更新

假设模型只有一个权重 \(w\)，当前训练数据算出的 loss 是：

$$
L_{\text{data}}(w)
$$

你已经知道，可以先求梯度，再更新参数：

$$
w_{\text{new}}
=
w-\eta \frac{\partial L_{\text{data}}}{\partial w}
$$

其中 \(\eta\) 是学习率。

我们把：

$$
g=\frac{\partial L_{\text{data}}}{\partial w}
$$

记成训练数据给出的梯度，更新就简化为：

$$
w_{\text{new}}=w-\eta g
$$

这种直接沿当前梯度更新的方式，在这里只考虑**不带动量的基础 SGD**。你可以把它接到之前学的梯度下降：算梯度，然后沿反方向走一步。

### 2. 把“惩罚大权重”加到 loss

现在你希望模型不要把 \(w\) 变得太大。于是给原来的 loss 加一项：

$$
L_{\text{total}}
=
L_{\text{data}}
+
\frac{\lambda}{2}w^2
$$

其中：

- \(L_{\text{data}}\)：衡量预测和真实值的差距。
- \(\frac{\lambda}{2}w^2\)：权重越大，惩罚越大。
- \(\lambda\)：控制惩罚力度。

对整个 loss 求导：

$$
\frac{\partial L_{\text{total}}}{\partial w}
=
\frac{\partial L_{\text{data}}}{\partial w}
+
\lambda w
=
g+\lambda w
$$

然后用普通 SGD 更新：

$$
w_{\text{new}}
=
w-\eta(g+\lambda w)
$$

展开：

$$
\begin{aligned}
w_{\text{new}}
&=w-\eta g-\eta\lambda w\\
&=(1-\eta\lambda)w-\eta g
\end{aligned}
$$

看最后一行：

$$
\boxed{w_{\text{new}}=(1-\eta\lambda)w-\eta g}
$$

它可以读成两个动作：

```text
先把旧的 w 乘以 (1 - ηλ)
→ 让它向 0 缩一点

再减去 ηg
→ 按训练数据的梯度更新
```

所以，对**普通 SGD** 来说：

```text
方法 A：把 λw²/2 加进 loss，再求梯度更新

方法 B：用数据梯度更新，同时额外把 w 缩小一点
```

在这里可以得到相同的更新结果。这就是上一节说的等价关系。

### 3. 为什么到了 Adam 就不一样？

关键在这里：

**普通 SGD 是直接拿梯度 \(g\) 更新参数。Adam 会先处理梯度，再决定每个参数该走多大一步。**

可以先把 Adam 想成下面这个过程：

```text
当前梯度
    ↓
结合之前梯度的信息
    ↓
调整这一步的更新尺度
    ↓
更新 w
```

因此，如果你把惩罚项加进 loss，Adam 收到的就是：

$$
g_{\text{total}}=g+\lambda w
$$

接下来：

```text
g + λw
    ↓
一起进入 Adam 的梯度统计
    ↓
一起影响 Adam 决定的更新尺度
```

**数据梯度 \(g\)** 和**惩罚项产生的梯度 \(\lambda w\)** 在进入 Adam 时已经混在一起了。

所以最后不能再简单地说：

> “这等价于先把 $w$ 乘上 $1-\eta\lambda$，再按数据梯度更新。”

因为 Adam 对混合后的梯度做了额外处理，而普通 SGD 的推导中没有这一步。

### 4. AdamW 怎么做？

AdamW 把这两件事分开：

```text
训练数据的梯度 g
    ↓
交给 Adam 的梯度统计
    ↓
得到数据驱动的更新

与此同时
    ↓
单独对 w 做一次衰减
```

所以它的更新可以先理解成：

$$
\boxed{
w_{\text{new}}
=
(1-\eta\lambda)w
-
\eta \cdot \text{Adam根据数据梯度算出的更新}
}
$$

这就是 **decoupled（解耦）** 的意思：

> **衰减权重这个动作，和 Adam 处理数据梯度的过程分开。**

在 PyTorch 里，你通过：

```python
optimizer = torch.optim.AdamW(
    model.parameters(),
    lr=0.01,
    weight_decay=0.1,
)
```

让 AdamW 在更新参数时执行这件事。[PyTorch AdamW 文档](https://docs.pytorch.org/docs/stable/generated/torch.optim.AdamW.html)

### 5. 所以到底能不能把惩罚项加进 loss？

**能。** 只是你需要知道自己选择的是哪一种方法：

```text
做法 A：
loss = data_loss + 权重惩罚
↓
对整个 loss 求梯度
↓
Adam 处理混合后的梯度
```

```text
做法 B：
只对 data_loss 求梯度
↓
Adam 处理数据梯度
↓
AdamW 在更新时另外衰减权重
```

**两者都可以用来约束模型，但对于 Adam，它们一般不会产生完全相同的参数更新。**

T13 特意选 AdamW，是因为本课想单独观察“更新时施加 weight decay”的效果。因此两组都使用 AdamW，只改变 `weight_decay`，方便对比。不要为了实现同一项衰减，又额外在 loss 中重复加一份惩罚；那会变成另一个实验。

你现在先抓住这一条就够了：

> **SGD 直接使用当前梯度，所以两种写法可以展开成一样；Adam 会加工梯度，所以“加进梯度”和“单独衰减”就不再是同一个动作。**

## 目前只需要抓住啥

对，**现阶段你不需要先扣清 Adam 内部每一步怎么算**。先知道它会根据梯度及其历史信息调整更新方式，就足够理解 T13 为什么选择 AdamW。

不过，“只能用单独衰减才能惩罚大权重”要稍微改一下：

> **把惩罚项加进 loss 也可以约束权重；AdamW 的单独衰减是另一种做法。两者在 Adam 中通常不是同一种更新效果。**

我们先把 SGD 讲清楚。

### 1. SGD 是什么？

SGD 是 **Stochastic Gradient Descent**，中文叫**随机梯度下降**。

它是一种更新模型参数的方法。最基础的更新形式，是你已经熟悉的：

$$
w_{\text{new}}=w-\eta \cdot g
$$

其中：

- \(w\)：当前参数。
- \(g\)：用当前这批训练数据算出来的梯度。
- $\eta$：学习率，也就是这次走多大一步。

例如：

```text
当前 w = 2.0
梯度 g = 0.5
学习率 η = 0.1

新 w = 2.0 - 0.1 × 0.5
     = 1.95
```

你之前写过的“算梯度，再沿反方向更新参数”，就是这个基本思路。

名字里的 **Stochastic（随机）**，通常是因为每次更新只使用抽取的一个样本或一小批样本，而不是每次都使用整个训练集。

PyTorch 的 `torch.optim.SGD` 是实现这类更新的优化器；它也支持动量等选项。刚才讲义里的推导，指的是**不带动量的基础形式**。

顺便联系 T13：你每次都使用全部 24 条训练数据，因此从数据使用方式看是 **full-batch（全批量）** 更新。你选择的优化器则是 AdamW，而不是 SGD。

### 2. T13 里你现在需要掌握什么？

先把目标说清楚：

> 我们想试试看，训练时给较大的权重施加约束，能不能改善验证集上的表现。

有不止一种方法。T13 选择的是：

```python
optimizer = torch.optim.AdamW(
    model.parameters(),
    lr=0.01,
    weight_decay=0.1,
)
```

你可以先把它理解成：

```text
根据数据算梯度
        ↓
AdamW 利用梯度更新参数
        ↓
同时按 weight_decay 的规则单独衰减权重
```

对照组则设：

```python
weight_decay=0.0
```

然后比较两组的验证集表现。**加了衰减也不保证一定更好，需要看实验结果。**

所以现阶段记住这三点就够了：

1. **SGD 和 AdamW 都是更新参数的方法。**
2. **给 loss 加惩罚项也是一种可用方法，但在 Adam 中通常不等价于 AdamW 的单独衰减。**
3. **T13 选用 AdamW 的 `weight_decay` 做对照，不需要你现在手算 Adam 的内部统计。**

### 3. weight_dacay 对应

对，你已经把它们接起来了！不过要分清**传进去的值**和**实际的缩放因子**：

```python
AdamW(..., lr=η, weight_decay=λ)
```

这里：

- `lr` 对应学习率 \(\eta\)。
- **`weight_decay` 对应衰减系数 \(\lambda\)**。
- 每次更新时，单独衰减权重对应的缩放因子是：

$$
1-\eta\lambda
$$

也就是说，AdamW 中和衰减有关的那部分可以理解为：

$$
w \leftarrow (1-\eta\lambda)w
$$

同时，AdamW 还会根据数据梯度更新参数。

比如 T13 的设置：

```python
lr = 0.01
weight_decay = 0.1
```

那么：

$$
1-\eta\lambda
=
1-0.01\times 0.1
=
0.999
$$

也就是每次更新时，衰减部分会把当前权重乘以 `0.999`。实际更新结果还要再考虑**数据梯度产生的更新**，所以不能说最终权重每次都一定变小。

你说“正则化出来的”这个联系也对：对于上一节的**基础 SGD**，从 loss 里的 \(\frac{\lambda}{2}w^2\) 出发，确实能推导出这个缩放因子。AdamW 则是把这种衰减作为独立动作来执行。

补一个和你代码有关的小细节：如果你直接把 `model.parameters()` 全部交给 AdamW，那么本课这个 `weight_decay` 也会作用于其中参与更新的 **bias**，不只作用于名字叫 `weight` 的参数。

但是我们是不需要对 bias 惩罚其太大的。

# R3

## R3 升级点

```text
1. 从相同 initial state 分别训练 baseline 与 `weight_decay=0.1`，两组各自有全新 optimizer。


2. 用同一套测量函数记录两组 train / validation curves；报告各自最后一行，以及 validation 最低的测量时刻。

3. 保存真正的最佳状态。按两组各自最低 validation MSE 选择本次最终配置；完全相同时固定优先 baseline，组内同分选较早 epoch。

所以我们需要实现一个 api 用来把 model 保存。
跟之前一样，只需要保存 model 的 state_dict()，所以我们把它 deepcopy


4. 在新 model object 中恢复选定状态，先核对 validation 指标，再评估保留的 test set；不根据 test 结果回去换赢家。

我们需要保存在 validation data 中表现最好的那一份模型。
也就是不断打擂台，对 validation mse 最小的进行 save_model

我们需要一个 restore_model 的 api；从 saved_model_state_dict 里恢复出模型
```

## 多加 run,weight_decay 标签

```text
run 标签用于区分是 baseline 还是 regularized

weight_decay 标识这次训练采用的 weight_decay 数值。
```

# 第一次检阅

## 让两个模型从同一个 initial state 恢复

```text
也就是我们先创建一个模型并且 save_model；然后让两个模型从 saved_model_state_dict 进行 restore
```

## 最后加的

```text
保存 out/selected_model.pt
打印 winner run 和 best epoch
用 validation 复测并 assert 接近原记录
最后评估一次 test MSE
输出 T13 CHECKS PASS
```

