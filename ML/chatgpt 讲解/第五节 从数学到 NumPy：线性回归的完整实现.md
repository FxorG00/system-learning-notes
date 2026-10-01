# 第五节 从数学到 NumPy：线性回归的完整实现

这一节和前面有点不一样：前面主要在推导数学，而第五节的核心是把你已经学会的线性回归数学，真正转换成 NumPy 中可以执行的计算，并理解它为什么能服务于 AI Infra。

你的讲义原本使用 Octave，对应到现在的学习环境，就是 Python + NumPy。第五节从基础数组、向量化、索引、矩阵运算，一直讲到完成一个完整的线性回归程序。

## 5.1 NumPy 中的基本对象：数学公式怎样进入计算机

先看你已经非常熟悉的数学公式：

$$
\hat{\mathbf y}=X\mathbf w+b
$$

数学上，我们会把 $X$ 看作矩阵，把 $\mathbf w$ 看作向量，把 $b$ 看作标量。

在 NumPy 中，它们通常都通过 `ndarray`（多维数组）来表示。

```python
import numpy as np

X = np.array([
    [1.0, 2.0],
    [3.0, 4.0]
])

w = np.array([0.5, -1.0])

b = 0.2

prediction = X @ w + b
```

我们先不急着计算，检查一下这三个对象的 shape。

$$
X:[2,2]
$$

$$
\mathbf w:[2]
$$

$$
b:\text{scalar}
$$

因此：

$$
[2,2]@[2]\longrightarrow[2]
$$

也就是说，两条训练样本，每条样本包含两个特征，最终得到两个预测值。

你可以手算验证：

$$
\hat y^{(1)}=1(0.5)+2(-1)+0.2=-1.3
$$

$$
\hat y^{(2)}=3(0.5)+4(-1)+0.2=-2.3
$$

所以：

```python
print(prediction)
# [-1.3 -2.3]
```

这里的 `@` 就是矩阵乘法运算符。

但有一个你要特别注意的细节：

NumPy 的一维数组 `[2]`，并不严格区分数学中的行向量和列向量。

例如：

```python
w.shape
# (2,)
```

它不是 `(2, 1)`，也不是 `(1, 2)`。

NumPy 的 `matmul` 会根据运算规则处理一维数组，因此 `X @ w` 可以直接得到 `[2]`。

如果你确实需要一个二维列向量，应该明确写成：

```python
w_column = w.reshape(-1, 1)

print(w_column.shape)
# (2, 1)
```

这样：

$$
[2,2]@[2,1]\longrightarrow[2,1]
$$

这两种写法都可以，只是输出的 shape 不同。

对于以后的 AI Infra 学习，你要养成一个习惯：看到任何 Tensor 运算，先确定 shape，再判断数学运算是否正确。

## 5.2 向量化的损失函数和梯度

现在我们把前面学过的梯度下降全部翻译成 NumPy。

回顾成本函数：

$$
J(\mathbf w,b) =\frac1{2m}\sum_{i=1}^{m}e_i^2
$$

其中：

$$
\mathbf e=\hat{\mathbf y}-\mathbf y
$$

在 NumPy 中：

```python
error = prediction - y

loss = np.mean(error ** 2) / 2
```

这里的 `error ** 2` 是对每个元素分别平方。

`np.mean` 则把所有平方误差求平均。

注意，我们讲义使用的损失函数是普通均方误差的一半，即 MSE/2。这样做是为了求导时抵消平方产生的系数 2，并不改变最优参数的位置。

接下来计算梯度：

$$
\nabla_{\mathbf w}J=\frac1mX^T\mathbf e
$$

代码就是：

```python
grad_w = X.T @ error / X.shape[0]
```

我们把它拆开看。

`X.T` 表示数据矩阵转置；`@ error` 计算所有特征与误差的乘加归约；最后除以 `X.shape[0]`，也就是样本数量。

偏差梯度：

$$
\frac{\partial J}{\partial b} =\frac1m\sum_{i=1}^{m}e_i
$$

代码为：

```python
grad_b = np.mean(error)
```

你会发现，之前花了好几轮推导的数学，在 NumPy 中只需要两行。

这就是向量化的价值。

不过，向量化并不是不需要执行乘法和加法，而是把这些操作交给底层经过优化的计算库，避免在 Python 中逐个处理元素。

## 5.3 为什么还要画图？

你之前已经学过 Loss Curve，这里就可以很快理解。

假设我们训练了 1000 次，每次都记录当前成本：

```python
loss_history = []
```

训练过程中：

```python
loss_history.append(loss)
```

训练完成后：

```python
import matplotlib.pyplot as plt

plt.plot(loss_history)

plt.xlabel("Iteration")
plt.ylabel("Loss")

plt.show()
```

你就能观察到成本随迭代次数的变化。

这里我想强调一个工程思维：图不是为了展示模型训练成功了，而是为了检查训练过程中发生了什么。

比如，训练损失一直下降，至少说明当前优化过程在改善训练目标；损失持续上升，可能是学习率太大，也可能是梯度实现错误。

但训练损失下降并不能证明模型具有良好的泛化能力。判断泛化，还需要观察验证集上的表现。

我们等会儿会在完整程序中把训练损失和验证损失一起记录下来。

## 5.4 从数学运算看 AI Infra 的计算负载

这一小节是讲义专门为 AI Infra 添加的联系。它把前面学到的批量矩阵运算、特征尺度、损失曲线和计算复杂度分别对应到 GPU kernel、数值稳定性、可观测性及算法成本。

我们可以再进一步把这些联系变得具体。

### 矩阵运算为什么重要？

你之前写过：

```python
prediction = X @ w + b
```

如果：

$$
X:[10000,512]
$$

$$
w:[512]
$$

那么这次计算会为 10000 条样本分别完成长度为 512 的点积。

在这个例子中，`X @ w` 属于矩阵-向量乘法（GEMV）。

但以后你学习 Transformer 时，会遇到：

$$
A:[m,n]
$$

$$
W:[n,k]
$$

它们相乘得到：

$$
AW:[m,k]
$$

这属于矩阵-矩阵乘法（GEMM）。

现代 GPU 对这类大规模矩阵运算提供了专门的硬件和软件优化，因此模型的 Tensor shape、数据类型和内存布局，会直接影响计算性能。

不过，NumPy 默认在 CPU 上执行计算。我们现在学习的是计算模式，以后使用 PyTorch、CUDA 或 Triton 时，再研究它们怎样映射到 GPU。

## 5.5 创建、索引和移动数据

这一部分看似只是 NumPy 基础，但在 AI Infra 中非常重要。

因为模型真正消费的不是抽象的数学矩阵，而是按照某种 shape、dtype 和内存布局存储的数组。

### 1. 创建数组时，要同时确定 shape 和 dtype

```python
zeros = np.zeros((3, 4), dtype=np.float32)

ones = np.ones((2, 3), dtype=np.float32)

identity = np.eye(4, dtype=np.float32)

sequence = np.arange(
    12, dtype=np.float32
).reshape(3, 4)
```

例如：

```python
print(sequence)
```

得到：

```
[[ 0.  1.  2.  3.]
 [ 4.  5.  6.  7.]
 [ 8.  9. 10. 11.]]
```

这个数组的 shape 是 `[3,4]`，dtype 是 `float32`。

`float32` 表示每个元素通常占用 4 字节。

如果换成 `float64`，每个元素通常占用 8 字节。

因此，在相同 shape 下，`float64` 的数组存储空间通常是 `float32` 的两倍。

这也是为什么以后学习 GPU 显存、混合精度训练时，dtype 会成为一个特别重要的概念。

### 2. 索引操作会影响 shape

我们就用上面的 `sequence`。

```python
sequence[1, 2]
```

得到单个元素：

```
6.0
```

而：

```python
sequence[1, :]
```

得到第二行，shape 为 `[4]`。

再看两个容易混淆的操作：

```python
sequence[:, 2]
```

和：

```python
sequence[:, 2:3]
```

前者的 shape 是：

$$
[3]
$$

后者的 shape 是：

$$
[3,1]
$$

它们的元素值相同，但维度数量不同。

为什么这件事很重要？

因为在 NumPy 中，数组运算除了考虑元素值，还要考虑 shape 和广播规则。

例如：

```python
a = np.ones((3, 1))
b = np.ones((3,))
```

执行：

```python
c = a + b
```

得到的并不是 `[3]` 或 `[3,1]`。

而是：

$$
\boxed{[3,3]}
$$

原因是 NumPy 从末尾维度开始对齐：

```
a: [3, 1]
b: [   3]
---------
c: [3, 3]
```

这是一种非常典型的广播行为。

想象一下，如果你的预测是 `[100,1]`，标签却是 `[100]`，然后你直接计算：

```python
error = prediction - y
```

NumPy 可能会把它们广播成 `[100,100]`。

代码不一定会报错，但数学含义已经完全错了！

因此，实际训练时，特别是手写 Loss Function 时，一定要检查预测和标签的 shape 是否符合预期。

## 5.6 矩阵乘法与逐元素乘法

你现在已经很熟悉矩阵乘法了，所以这一节的重点是避免混淆 NumPy 的两种乘法。

假设：

```python
A = np.array([
    [1, 2],
    [3, 4]
])

B = np.array([
    [5, 6],
    [7, 8]
])
```

矩阵乘法是：

```python
A @ B
```

结果为：

$$
\begin{bmatrix} 19&22\\ 43&50 \end{bmatrix}
$$

而逐元素乘法：

```python
A * B
```

结果为：

$$
\begin{bmatrix} 5&12\\ 21&32 \end{bmatrix}
$$

两者完全不同。

矩阵乘法会沿着某个维度进行乘加归约；逐元素乘法则是对应元素直接相乘，并遵循广播规则。

以后在神经网络里，你会反复看到这两种操作的组合。

例如，一个线性层的矩阵乘法：

$$
Z=AW
$$

后面接一个逐元素激活函数：

$$
A_{\text{next}}=\operatorname{ReLU}(Z)
$$

其中 ReLU 会逐元素计算：

$$
\operatorname{ReLU}(z)=\max(0,z)
$$

它不需要进行矩阵乘法，而是对每个元素独立处理。

### Reduction：哪个维度被消掉了？

接着看求和：

```python
x = np.arange(12).reshape(3, 4)
```

它的 shape 是 `[3,4]`。

执行：

```python
x.sum(axis=0)
```

表示沿第 0 轴求和，也就是把各行对应位置的元素相加。

最终保留 4 列：

$$
[3,4]\longrightarrow[4]
$$

而：

```python
x.sum(axis=1)
```

表示对每一行内部的 4 个元素求和。

因此：

$$
[3,4]\longrightarrow[3]
$$

这里建议你记住一个非常实用的判断方法：

看到 `axis`，先问被归约掉的是哪个维度，剩下的 shape 是什么。

这比单纯背 `axis=0` 是按列求和、`axis=1` 是按行求和，更适合以后处理高维 Tensor。

例如，Transformer 中的 Tensor 可能具有：

$$
[B,T,H]
$$

其中 $B$ 是 batch size，$T$ 是序列长度，$H$ 是隐藏特征维度。

如果：

```python
x.sum(axis=-1)
```

就会沿最后的隐藏特征维度求和，得到：

$$
[B,T]
$$

这和我们刚才的二维数组是同一套规则。

## 5.7 Reshape、Transpose 和 Concatenate

这一节是你以后做 AI Infra 时需要反复使用的基础。

### 1. Reshape：重新组织维度

假设：

```python
x = np.arange(12)
```

它的 shape 是：

$$
[12]
$$

现在执行：

```python
matrix = x.reshape(3, 4)
```

变成：

$$
[3,4]
$$

但是，无论怎么 reshape，元素总数必须保持不变。

因为：

$$
12=3\times4
$$

所以这个 reshape 合法。

如果你尝试：

```python
x.reshape(3, 5)
```

就会报错，因为原始数组只有 12 个元素，却试图组织成 15 个元素。

这里还要补充一个与 Infra 有关的细节：`reshape` 不保证一定不复制数据。能否仅通过修改数组视图来完成 reshape，取决于原始数组的内存布局。

### 2. Transpose：交换维度

例如：

$$
X:[3,4]
$$

执行：

```python
X.T
```

得到：

$$
X^T:[4,3]
$$

你之前已经使用分块矩阵的方式理解了这个操作。

现在我们进一步关注计算机中的实现。

对于普通 NumPy 数组，转置通常可以通过改变数组的 strides（步长，即沿每个轴移动一个元素时，在内存中跨过的字节数）来形成视图，而不必立即复制所有数据。

但是，转置后的数组可能不再连续存储。

后续某些计算内核为了满足自己的内存布局要求，可能需要额外复制数据。

这就是为什么在 AI Infra 中，仅仅知道 Tensor 的 shape 还不够，还需要理解内存布局。

### 3. Concatenate：拼接数组

例如：

```python
A = np.ones((2, 3))
B = np.zeros((2, 3))
```

沿 `axis=0` 拼接：

```python
np.concatenate([A, B], axis=0)
```

得到：

$$
[4,3]
$$

因为行数增加了。

沿 `axis=1` 拼接：

```python
np.concatenate([A, B], axis=1)
```

得到：

$$
[2,6]
$$

因为列数增加了。

这里要注意，除了拼接方向，其他维度必须一致。

以后你学习模型并行或者多头注意力时，经常会遇到 Tensor 的拆分、重新排列和拼接。底层的 shape 规则并没有改变。

## 5.8 绘图是算法检查的一部分

讲义这一节要求线性回归至少能够绘制原始数据与拟合结果、迭代次数与成本，以及在少量参数情况下的等高线。

你已经理解了等高线和 Loss Curve，因此这里不需要再重复推导。

但我希望你建立一个更工程化的习惯：

训练过程中，不要只记录最后的 Loss。

例如，最后的训练损失是 0.01，听上去似乎很好。

但如果你没有记录训练轨迹，你就不知道它之前是否出现过异常的数值波动，也不知道它花了多少步才收敛。

如果再配合验证集的 Loss Curve，你还能观察训练误差下降时，模型在未参与训练的数据上的误差是否也在下降。

这就把优化算法与模型泛化联系起来了。

## 5.9 为什么外层可以循环，内层应该向量化？

这一点特别适合你现在的 AI Infra 学习目标。

先看一种比较直观，但低效的实现：

```python
for i in range(m):
    for j in range(n):
        grad_w[j] += error[i] * X[i, j]
```

数学上，这完全正确。

它就是：

$$
\frac{\partial J}{\partial w_j} =\frac1m\sum_{i=1}^{m}e_i x_{ij}
$$

的直接翻译（最后还需要除以 $m$）。

但是，它把每一个元素的计算都放在 Python 解释器层面执行。

我们可以使用矩阵乘法，把整个计算交给底层数值库：

```python
grad_w = X.T @ error / m
```

这通常能够显著降低 Python 循环的开销，并利用优化过的底层计算实现。

但这不意味着整个训练过程不能出现 `for`。

例如：

```python
for step in range(num_steps):
    prediction = X @ w + b
    error = prediction - y

    grad_w = X.T @ error / len(X)
    grad_b = np.mean(error)

    w = w - learning_rate * grad_w
    b = b - learning_rate * grad_b
```

这个外层循环表示训练轮次。

每一轮都需要使用更新后的参数重新计算预测，因此我们仍然需要不断执行训练步骤。

真正需要避免的是：把本来可以批量完成的元素运算，全部拆成 Python 中的标量循环。

这就是讲义所说的 Matrix-first Programming（矩阵优先编程）的基本思想。

## 5.10 把所有知识整合成一个完整的线性回归程序

现在终于可以把这一节收起来了。

这次我们写一个完整、可以独立运行的 NumPy 程序。

为了和你的 AI Infra 目标建立联系，我们用一个简化的 AI 服务延迟预测例子。

假设我们想根据请求的输入 Token 数和并发请求数，预测请求延迟。

需要注意，实际 AI 服务的延迟与队列、Batching、KV Cache 和硬件负载等因素有关，不一定是简单的线性关系。我们这里只用模拟数据来练习训练计算流程。

整个程序会完成数据生成、训练集与验证集划分、特征标准化、向量化前向传播、梯度计算、参数更新、Loss 记录、最小二乘求解以及绘图。

```python
import numpy as np
import matplotlib.pyplot as plt

rng = np.random.default_rng(42)

# 1. 生成模拟数据
m = 320

tokens = rng.integers(128, 4096, size=m)
concurrency = rng.integers(1, 65, size=m)

X_raw = np.column_stack([
    tokens,
    concurrency
]).astype(np.float64)

# 模拟延迟（仅用于教学）
y = (
    5.0
    + 0.008 * tokens
    + 0.7 * concurrency
    + rng.normal(0, 2.0, size=m)
)

# 2. 划分训练集和验证集
indices = rng.permutation(m)

train_idx = indices[:240]
val_idx = indices[240:]

X_train_raw = X_raw[train_idx]
X_val_raw = X_raw[val_idx]

y_train = y[train_idx]
y_val = y[val_idx]

# 3. 仅使用训练集拟合标准化参数
mu = X_train_raw.mean(axis=0)
sigma = X_train_raw.std(axis=0)

# 防止常数特征导致除以零
sigma = np.where(sigma == 0, 1.0, sigma)

X_train = (X_train_raw - mu) / sigma
X_val = (X_val_raw - mu) / sigma

# 4. 检查数据
print("X_train:", X_train.shape)
print("y_train:", y_train.shape)
print("dtype:", X_train.dtype)

assert np.isfinite(X_train).all()
assert np.isfinite(y_train).all()

# 5. 初始化参数
n = X_train.shape[1]

w = np.zeros(n)
b = 0.0

learning_rate = 0.1
num_steps = 400

train_history = []
val_history = []

# 6. 梯度下降
for step in range(num_steps):

    # Forward
    prediction = X_train @ w + b
    error = prediction - y_train

    # Cost
    train_loss = np.mean(error ** 2) / 2

    val_prediction = X_val @ w + b
    val_error = val_prediction - y_val
    val_loss = np.mean(val_error ** 2) / 2

    train_history.append(train_loss)
    val_history.append(val_loss)

    # Gradients
    grad_w = X_train.T @ error / len(X_train)
    grad_b = np.mean(error)

    # 同步更新参数
    w = w - learning_rate * grad_w
    b = b - learning_rate * grad_b

# 7. 使用最小二乘法作对照
X_design = np.column_stack([
    np.ones(len(X_train)),
    X_train
])

theta_lstsq = np.linalg.lstsq(
    X_design,
    y_train,
    rcond=None
)[0]

print("Gradient Descent:", b, w)
print("Least Squares:", theta_lstsq)

# 8. 绘制 Loss Curve
plt.plot(train_history, label="Train Loss")
plt.plot(val_history, label="Validation Loss")

plt.xlabel("Iteration")
plt.ylabel("Loss")
plt.legend()
plt.grid(True)
plt.show()
```

这段代码的结构，就是你讲义 5.10 要求完成的端到端训练工作流。

## 这里面最重要的四个检查点

1. 数据 shape 是否正确？

   训练集包含 240 条样本、2 个特征，因此：

   $$
   X_{\text{train}}:[240,2],\quad y_{\text{train}}:[240]
   $$

   前向传播和梯度计算都必须符合这个 shape 契约。

2. 标准化是否发生数据泄漏？

   均值和标准差只能由训练集计算。验证集和未来的线上输入都要使用同一套标准化参数。

3. 梯度下降和最小二乘法是否接近？

   两种方法使用同一份标准化训练数据，所以可以直接比较它们得到的偏差和权重。在收敛充分、问题数值条件合适的情况下，它们的结果应该接近。

4. 训练损失和验证损失有什么变化？

   训练损失反映模型对训练数据的拟合情况；验证损失则帮助我们观察模型对未参与训练的数据的表现。

## 最后：第五节对你的 AI Infra 学习真正意味着什么？

到这里，你已经从一个数学公式：

$$
\nabla_{\mathbf w}J=\frac1mX^T\mathbf e
$$

走到了能够在计算机里实际执行的训练程序。

不过，你现在需要建立的能力，并不只是会使用 `np.array`、`reshape` 或 `@`。

真正重要的是，看到一段模型代码时，你开始能够判断它执行了哪种计算、每个 Tensor 的 shape 是什么、哪个维度进行了归约、数据是否需要额外复制，以及这个操作可能产生多少计算和内存开销。

例如，未来你看到 Transformer 中的一层投影：

$$
Y=XW+b
$$

假设：

$$
X:[B,T,H],\qquad W:[H,F]
$$

如果先把 batch 和序列维度合并，就可以组织成：

$$
[B T,H]@[H,F]\longrightarrow[B T,F]
$$

然后再把结果恢复为：

$$
[B,T,F]
$$

这里使用的矩阵乘法、reshape 和 broadcasting，全是第五节刚刚讲过的东西。

你以后学习 GPU kernel、算子融合、显存优化和推理性能时，就是在更深入地研究这些计算怎样被执行、怎样减少中间数据和数据搬运，以及怎样让硬件更高效地完成它们。

到这里，第二周的数学主线与 NumPy 实现就完整串通了。

接下来的第三周会进入逻辑回归（Logistic Regression）和正则化（Regularization）。它们会在你已经掌握的矩阵计算和梯度下降之上，进一步解决分类问题，以及模型为什么可能在训练集上表现很好、在新数据上却表现很差的问题。