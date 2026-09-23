# 吴恩达 2014 机器学习：面向 AI Infra 的完整自学讲义

> 版本：2026-09-23
>
> 对齐课程：[斯坦福大学 2014 机器学习中文笔记](http://www.ai-start.com/ml2014/)
>
> 原始笔记与配图：[Coursera-ML-AndrewNg-Notes](https://github.com/fengdu78/Coursera-ML-AndrewNg-Notes)
>
> 这份讲义保留原 `ML.md` 的直觉式语言，但补齐课程、公式、图片和 AI Infra 连接。旧稿保存在 [archive/ML_20260923_original.md](archive/ML_20260923_original.md)。

---

## 怎么使用这份讲义

这不是一份需要你从头抄到尾的考试笔记。

你已经学过微积分、线性代数，也正在用 NumPy 做 AI Theory。这里真正要完成的是另一件事：把散落的数学知识串成机器学习的完整计算流程。

这条流程是：

```text
数据
-> 模型做出预测
-> 成本函数衡量错误
-> 优化算法调整参数
-> 验证集判断模型能否泛化
-> 根据误差证据决定下一步
```

以后进入神经网络、Transformer、训练系统和推理系统，这条主线都不会消失。模型会变复杂，参数会变多，底层计算会从 NumPy 转向 GPU kernel，但问题仍然是这些问题。

---

# 第一周：机器学习、线性回归与梯度下降

## 1. 引言（Introduction）

### 1.1 机器学习到底在做什么

传统程序通常由人直接写出规则：

```text
input + hand-written rules -> output
```

机器学习换了一种方式。我们给它 examples 和目标，让算法自己找到一组能够解释数据的 parameters：

```text
examples + learning algorithm -> model parameters
model + new input -> prediction
```

所以机器学习中的“学习”，并不是程序突然拥有了意识，而是**通过数据自动确定模型里的参数**。

### 1.2 监督学习

如果每一条训练数据都带着正确答案，我们就把它叫做**监督学习（Supervised Learning）**。

一条训练样本通常写成：

$$
(x^{(i)},y^{(i)})
$$

$x^{(i)}$ 是第 $i$ 个输入，$y^{(i)}$ 是它对应的正确答案。

监督学习又分成两种常见问题：

- **回归（Regression）**：预测连续数值，例如房价、延迟、吞吐量。
- **分类（Classification）**：预测离散类别，例如邮件是不是垃圾邮件、请求是不是异常流量。

![监督学习示例](assets/week1-supervised.png)

它们的共同点是训练时都有答案；区别只在于需要预测的结果是什么形式。

### 1.3 无监督学习

如果数据只有 $x$，没有提前给出的 $y$，算法只能从数据本身寻找结构，这就叫**无监督学习（Unsupervised Learning）**。

例如我们拿到大量用户行为，却没有“这是谁一类用户”的标签。算法可以根据相似性自动把用户分成若干组。这个过程叫 clustering，后面会在 K-means 中完整展开。

现在先记住最核心的区别：

```text
监督学习：训练时有正确答案
无监督学习：训练时没有正确答案，需要从数据中发现结构
```

---

## 2. 单变量线性回归（Linear Regression with One Variable）

### 2.1 先明确我们要造什么

假设横轴 $x$ 是房屋面积，纵轴 $y$ 是真实售价。现在我们拥有一批历史数据点，希望画出一条尽可能贴合这些点的直线，再用它预测新房子的售价。

这条直线写成：

$$
f_{w,b}(x)=wx+b
$$

![线性模型](assets/week1-linear-model.png)

这里：

- $x$ 是输入特征（feature）。
- $w$ 是权重（weight），也就是直线斜率。
- $b$ 是偏差（bias），也就是纵轴截距。
- $f_{w,b}(x)$ 是模型的预测值，也常写成 $\hat y$。

机器真正要学的不是每套房子的答案，而是 $w$ 和 $b$。

一旦这两个参数确定下来，任何新的面积 $x$ 都能得到一个 prediction。

### 2.2 成本函数：模型怎么知道自己错了多少

只有模型还不够。你可以随便给 $w$ 和 $b$ 赋值，每一组参数都会画出一条直线。机器需要一把统一的尺子，判断哪条线更好。

单个 example 上的错误度量通常叫 **loss**；把所有 examples 的 losses 聚合起来，得到训练时优化的 **cost function**。在线性回归中，我们使用平均平方误差：

$$
J(w,b)=\frac{1}{2m}\sum_{i=1}^{m}
\left(f_{w,b}(x^{(i)})-y^{(i)}\right)^2
$$

别急着背公式，我们把它按物理动作拆开：

1. 模型先对第 $i$ 个样本做出预测 $f_{w,b}(x^{(i)})$。
2. prediction 减去真实答案 $y^{(i)}$，得到 error。
3. 把 error 平方，让正负误差不会互相抵消，同时让大误差受到更重惩罚。
4. 对所有 $m$ 个样本求和并取平均。
5. 分母多出的 $2$ 是为了后面求导时和平方产生的 $2$ 抵消。

![成本函数](assets/week1-cost-function.png)

现在整个训练目标变得非常明确：

$$
\min_{w,b}J(w,b)
$$

也就是寻找一组 $w,b$，让成本函数尽可能小。

### 2.3 成本函数的直觉

如果暂时固定 $b=0$，只改变 $w$，每一个 $w$ 都会对应一条直线，也会对应一个成本 $J(w)$。

把这些点画出来，通常会得到一条碗形曲线。碗底对应的 $w$，就是这批数据上的最优权重。

如果同时改变 $w$ 和 $b$，成本函数会从二维曲线变成三维曲面。参数空间中的每一个点 $(w,b)$，都对应一条模型直线，也对应一个成本高度。

这就是为什么优化经常被描述成“下山”：模型当前参数是山坡上的位置，成本函数的最低点是我们要到达的谷底。

### 2.4 梯度下降：怎样自动走向谷底

梯度下降（Gradient Descent）的核心动作只有一个：计算当前位置最陡的上升方向，然后反向走一步。

参数更新公式是：

$$
w\leftarrow w-\alpha\frac{\partial J(w,b)}{\partial w}
$$

$$
b\leftarrow b-\alpha\frac{\partial J(w,b)}{\partial b}
$$

$\alpha$ 是学习率（Learning Rate），控制每一步走多远。

![梯度下降](assets/week1-gradient-descent.jpg)

为什么是减号？

在当前参数坐标与 Euclidean distance 下，gradient 指向函数上升最快的方向，negative gradient 才是局部下降最快的方向。

为什么两个参数必须同步更新？

因为这一轮的两个 derivatives 都是在同一个旧位置 $(w,b)$ 上计算的。如果先修改 $w$，再用新 $w$ 计算 $b$，两次更新就不再属于同一步。

### 2.5 把线性回归的偏导数推出来

模型是：

$$
f_{w,b}(x^{(i)})=wx^{(i)}+b
$$

对 $w$ 求偏导：

$$
\frac{\partial J}{\partial w}
=\frac{1}{m}\sum_{i=1}^{m}
\left(f_{w,b}(x^{(i)})-y^{(i)}\right)x^{(i)}
$$

对 $b$ 求偏导：

$$
\frac{\partial J}{\partial b}
=\frac{1}{m}\sum_{i=1}^{m}
\left(f_{w,b}(x^{(i)})-y^{(i)}\right)
$$

两者唯一的区别是，$w$ 控制了 $x$ 对 prediction 的影响，因此 chain rule 还会多乘一个 $x^{(i)}$；$b$ 前面的系数是 $1$，所以不需要。

### 2.6 手算一次参数更新

给定：

$$
x=[1,2],\qquad y=[2,4],\qquad w=0,\qquad b=0
$$

初始 predictions 都是 $0$。

于是：

$$
\frac{\partial J}{\partial w}
=\frac{1}{2}\left[(0-2)\cdot1+(0-4)\cdot2\right]=-5
$$

$$
\frac{\partial J}{\partial b}
=\frac{1}{2}\left[(0-2)+(0-4)\right]=-3
$$

若 $\alpha=0.1$：

$$
w\leftarrow0-0.1(-5)=0.5
$$

$$
b\leftarrow0-0.1(-3)=0.3
$$

更新后模型变成 $f(x)=0.5x+0.3$。它还远没有到达 $y=2x$，但已经朝正确方向移动了一步。

### 2.7 学习率为什么重要

实际 update 的大小并不只有 $\alpha$，而是：

$$
\text{step}=\alpha\cdot\nabla J
$$

- $\alpha$ 太小：方向正确，但每一步很短，收敛很慢。
- $\alpha$ 太大：一步跨过谷底，来回震荡，甚至越走越高。
- 接近谷底时，gradient 自己会变小，所以即使 $\alpha$ 固定，实际步长也会自然缩小。

线性回归的平方误差是 convex function，因此不存在比 global minimum 更差的 local minimum。设计矩阵满列秩时最优参数唯一；features 线性相关时可能存在多组等价的 global solutions，但 gradient descent 仍不会被错误的局部谷底困住。

---

## 3. 线性代数回顾（Linear Algebra Review）

### 3.1 为什么这里突然出现矩阵

一套房子不可能只有面积一个特征。加入卧室数、楼层和房龄后，一个样本就不再是 scalar，而是 vector：

$$
\mathbf x=
\begin{bmatrix}
x_1\\x_2\\\vdots\\x_n
\end{bmatrix}
$$

相应地，每个 feature 都需要一个 weight：

$$
\mathbf w=
\begin{bmatrix}
w_1\\w_2\\\vdots\\w_n
\end{bmatrix}
$$

模型可以压缩成：

$$
f_{\mathbf w,b}(\mathbf x)=\mathbf w^T\mathbf x+b
$$

这不是单纯为了让公式好看。它明确告诉实现者：哪些 dimensions 必须相等，哪个 dimension 会被 reduction，以及哪些计算可以批量执行。

### 3.2 Matrix shape 是计算契约

如果一共有 $m$ 个 examples、每个 example 有 $n$ 个 features，可以把数据组成：

$$
X\in\mathbb R^{m\times n}
$$

每一行是一条 example，每一列是一种 feature。

批量 prediction 是：

$$
\hat{\mathbf y}=X\mathbf w+b
$$

shape 关系为：

$$
[m,n]@[n]\longrightarrow[m]
$$

被消掉的 $n$ 表示每个 example 内部完成一次 dot product；保留下来的 $m$ 表示每条 example 都得到一个 prediction。

### 3.3 矩阵乘法不是逐元素乘法

矩阵乘法：

$$
C_{ij}=\sum_k A_{ik}B_{kj}
$$

这里的 $k$ dimension 被求和消掉。

逐元素乘法则要求两个 operands 能按 broadcasting rules 对齐，并保留对齐后的 shape。两者产生的 values 和 shape 都不同。

这正是你在 T2、T3 里练习 shape 推导的原因：AI 模型中的线性层、attention score 和 projection，本质上都在反复组合 matrix multiplication、elementwise operation 与 reduction。

### 3.4 转置与逆

转置把行列交换：

$$
(A^T)_{ij}=A_{ji}
$$

矩阵 inverse 满足：

$$
A^{-1}A=I
$$

但不是每个 matrix 都可逆。即使理论上可逆，直接显式计算 inverse 也常常不是数值计算中的最佳实现。实际代码更倾向调用经过验证的 solver、QR decomposition 或 SVD。

### 3.5 向量化为什么更快

用 Python loop 一个元素一个元素计算，会反复支付 interpreter、dynamic dispatch 和边界检查成本。

把操作写成 NumPy matrix expression 后，实际循环进入经过优化的 C/C++、BLAS、SIMD 或多线程 library。GPU 上还可以把大量独立的 multiply-add 分配给不同计算单元。

所以 vectorization 的准确含义是：**把规则相同的数据计算交给底层批量 kernel**。

它通常能显著提速，但不等于“一万次乘法真的只需要一个时钟周期”。硬件仍然要执行运算、搬运数据、同步并写回结果。

---

# 第二周：多变量线性回归与 NumPy 实现

## 4. 多变量线性回归（Linear Regression with Multiple Variables）

### 4.1 从一条直线扩展到多个特征

多变量模型写成：

$$
f_{\mathbf w,b}(\mathbf x)
=w_1x_1+w_2x_2+\cdots+w_nx_n+b
=\mathbf w^T\mathbf x+b
$$

![多特征表示](assets/week2-multiple-features.png)

从几何上说，两个 features 对应一个平面，更多 features 对应高维空间中的 hyperplane。但训练逻辑没有改变：模型先预测，cost 衡量错误，gradient 更新 parameters。

### 4.2 多变量梯度下降

把 batch predictions 写成：

$$
\hat{\mathbf y}=X\mathbf w+b
$$

那么 weight gradient 可以一次计算：

$$
\nabla_{\mathbf w}J
=\frac{1}{m}X^T(\hat{\mathbf y}-\mathbf y)
$$

bias gradient 是：

$$
\frac{\partial J}{\partial b}
=\frac{1}{m}\sum_{i=1}^{m}(\hat y^{(i)}-y^{(i)})
$$

这里已经出现了现代训练系统的最小雏形：forward 产生 predictions，reduction 得到 scalar loss，backward 产生 gradients，optimizer 更新 parameter tensors。

### 4.3 特征缩放：为什么数值范围会改变下山路线

假设房屋面积在 $500\sim3000$，卧室数却只有 $1\sim5$。

这会让成本函数的等高线变成狭长椭圆。gradient 每次指向当前位置最陡的方向，于是参数会在窄谷两侧来回摆动，而不是直接向谷底前进。

![特征缩放](assets/week2-feature-scaling.jpg)

特征缩放的本质，是把不同 features 的典型尺度拉到接近范围，让同一个 learning rate 能合理地更新所有 dimensions。

常见的 Z-score normalization 是：

$$
x_j'=\frac{x_j-\mu_j}{\sigma_j}
$$

$\mu_j$ 是第 $j$ 个 feature 的 mean，$\sigma_j$ 是 standard deviation。

注意：normalization parameters 必须只从 training set 估计，再应用到 validation、test 和线上输入。否则 test data 的信息会泄漏进训练流程。

### 4.4 怎样从 loss curve 判断学习率

训练时画出 $J$ 随 iteration 的变化：

- 持续下降：至少说明当前 learning rate 能工作。
- 上升或剧烈震荡：learning rate 可能太大，也可能实现存在 bug。
- 下降非常缓慢：learning rate 可能太小，或 features 的 scale 差异太大。

![学习率与收敛](assets/week2-learning-rate.jpg)

loss curve 是训练系统最便宜的 observability。后面做 PyTorch 和分布式训练时，第一件事仍然是检查 loss、gradient norm、learning rate 与 throughput，而不是盲目增加算力。

### 4.5 多项式回归

linear regression 也可以拟合曲线。做法不是改变 optimizer，而是构造新 features：

$$
f(x)=w_1x+w_2x^2+w_3x^3+b
$$

它仍然叫 linear model，因为 parameters $w_1,w_2,w_3$ 仍然只做线性组合。

但是 $x$ 与 $x^3$ 的数值范围可能相差巨大，因此 polynomial features 更依赖 feature scaling，也更容易在高阶时 overfit。

### 4.6 正规方程：直接求最小二乘解

如果把 bias 合并进 parameter，并在 $X$ 前增加一列 $1$，least-squares solution 可以写成：

$$
\theta=(X^TX)^{-1}X^T\mathbf y
$$

![正规方程](assets/week2-normal-equation.png)

它不需要选择 learning rate，也不需要反复 iteration。但是随着 feature 数 $n$ 增大，构造和分解 $X^TX$ 的成本会迅速增加。

实际数值库也不会鼓励你手写 `inverse @ vector`。更稳定的做法是使用 QR、SVD 或 `lstsq` solver。

如果 $X^TX$ 不可逆，常见原因是：

1. 两个 features 线性相关，包含重复信息。
2. feature 数量大于 examples，问题欠定。

此时 pseudo-inverse 仍可给出 least-squares solution，但你需要理解问题本身为什么没有唯一解。

---

## 5. 从 Octave 迁移到 Python / NumPy

原课程用 Octave 教 matrix-first programming。今天不需要重新学一套旧工具，但它想训练的能力必须保留：**不要用标量 loop 描述本来可以批量计算的 matrix operation。**

### 5.1 基本对象

```python
import numpy as np

x = np.array([[1.0, 2.0],
              [3.0, 4.0]])
w = np.array([0.5, -1.0])
b = 0.2

prediction = x @ w + b
```

shape 推导：

```text
x:          [2, 2]
w:          [2]
x @ w:      [2]
prediction: [2]
```

### 5.2 向量化的 MSE 与 gradient

```python
def mse(prediction: np.ndarray, target: np.ndarray) -> float:
    error = prediction - target
    return float(np.mean(error * error) / 2.0)

def linear_gradients(
    x: np.ndarray,
    prediction: np.ndarray,
    target: np.ndarray,
) -> tuple[np.ndarray, float]:
    error = prediction - target
    grad_w = x.T @ error / x.shape[0]
    grad_b = float(np.mean(error))
    return grad_w, grad_b
```

这里不要只看代码短。每一行都对应前面的数学：

```text
prediction - target -> 每条 example 的 error
x.T @ error         -> 每个 feature 对所有 errors 的加权贡献
/ batch size        -> batch mean
```

### 5.3 画图与读取训练状态

NumPy 负责计算，Matplotlib 负责把数据和 loss curve 画出来。图不是装饰，它帮助你回答：

```text
模型是不是明显欠拟合？
loss 有没有下降？
learning rate 有没有导致震荡？
某些异常点是否主导了平方误差？
```

### 5.4 第二周与 AI Infra 的连接

这一周最重要的不是会写线性回归，而是看见同一份数学如何变成系统负载：

```text
batch matrix multiply -> GEMM 与 GPU kernel
feature / activation scale -> numerical stability 与 dtype
loss curve -> training observability
normal equation 在大规模下不可行 -> algorithm 必须尊重 complexity
```

以后你面对 Transformer 的 projection、attention 和 MLP，看到的仍然是更大规模的 matrix multiply、normalization、reduction 和 parameter update。

---

# 第三周：逻辑回归与正则化

## 6. 逻辑回归（Logistic Regression）

### 6.1 为什么分类不能直接沿用线性回归

现在我们不再预测房价，而是判断一封邮件是不是垃圾邮件。

标签只有两个值：

$$
y\in\{0,1\}
$$

如果直接使用 $f(x)=\mathbf w^T\mathbf x+b$，输出可能是 $-3.7$ 或 $8.2$。这些数可以作为 score，却不能直接解释为 probability。

我们需要一个函数，把任意实数压到 $(0,1)$ 之间。这就是 sigmoid：

$$
g(z)=\frac{1}{1+e^{-z}}
$$

![Sigmoid](assets/week3-sigmoid.jpg)

逻辑回归模型于是变成：

$$
z=\mathbf w^T\mathbf x+b
$$

$$
f_{\mathbf w,b}(\mathbf x)=g(z)
$$

输出可以理解为：

$$
f_{\mathbf w,b}(\mathbf x)=P(y=1\mid\mathbf x)
$$

例如输出 $0.8$，表示模型认为 $y=1$ 的概率为 $80\%$。

### 6.2 判定边界从哪里来

若规定 probability 大于等于 $0.5$ 就预测为 $1$：

$$
g(z)\ge0.5\iff z\ge0
$$

所以真正的 decision boundary 由下面这条式子决定：

$$
\mathbf w^T\mathbf x+b=0
$$

![判定边界](assets/week3-decision-boundary.png)

如果 features 只是 $x_1,x_2$，boundary 是直线。如果加入 $x_1^2$、$x_1x_2$ 等 polynomial features，boundary 就可以变成圆或更复杂的曲线。

sigmoid 负责把 score 映射成 probability；boundary 的形状仍由 score function 使用了哪些 features 决定。

### 6.3 为什么不能继续使用平方误差

把 sigmoid 与 squared error 组合后，cost surface 可能不再保持简单 convex shape，optimization 会更困难。

逻辑回归使用 binary cross-entropy：

$$
L(\hat y,y)
=-y\log\hat y-(1-y)\log(1-\hat y)
$$

分两种情况看就很直观。

当 $y=1$：

$$
L=-\log\hat y
$$

模型越接近 $1$，loss 越小；如果模型非常自信地预测接近 $0$，loss 会急剧变大。

当 $y=0$：

$$
L=-\log(1-\hat y)
$$

模型越接近 $0$，loss 越小；如果错误地预测接近 $1$，同样会受到巨大惩罚。

整个 dataset 的 cost 是：

$$
J(\mathbf w,b)=\frac{1}{m}\sum_{i=1}^{m}L(\hat y^{(i)},y^{(i)})
$$

### 6.4 梯度为什么看起来和线性回归很像

逻辑回归的 gradients 最终可以写成：

$$
\nabla_{\mathbf w}J
=\frac{1}{m}X^T(\hat{\mathbf y}-\mathbf y)
$$

$$
\frac{\partial J}{\partial b}
=\frac{1}{m}\sum_i(\hat y^{(i)}-y^{(i)})
$$

公式外形和线性回归相同，但 $\hat y$ 的来源不同：线性回归直接输出 score，逻辑回归还经过 sigmoid。

这个结果不是巧合，而是 sigmoid 与 cross-entropy 组合后，chain rule 中的若干项恰好抵消。后面学习 softmax cross-entropy 时会再次看到类似结构。

### 6.5 高级优化算法需要我们提供什么

Gradient descent 每一步只使用当前 gradient。Conjugate Gradient、BFGS、L-BFGS 等算法会利用更多历史或曲率信息，通常能用更少 iterations 找到较好参数。

在工程上，你不需要自己重写这些 optimizers。你需要向数值库提供两个一致的接口：

```text
给定 parameters -> 返回 cost
给定同一组 parameters -> 返回 gradient
```

如果 cost 与 gradient 对不上，再高级的 optimizer 也只会更快地走向错误结果。这正是 gradient checking 之后还会出现的原因。

### 6.6 多类别分类

如果标签不止两类，可以先用 one-vs-rest：对每一个 class 训练一个二分类器，最后选择 score 最大的 class。

现代神经网络更常用 softmax，一次产生所有 classes 的 probability distribution。one-vs-rest 在这里的意义，是让你先看见“多个类别”可以从多个二分类问题构造出来。

---

## 7. 正则化（Regularization）

### 7.1 模型为什么会过拟合

低阶模型可能太简单，连 training data 的趋势都抓不住，这叫 underfitting，也叫 high bias。

高阶模型可以穿过几乎每个 training point，却在新数据上表现很差，这叫 overfitting，也叫 high variance。

![欠拟合、合适与过拟合](assets/week3-overfitting.jpg)

overfitting 的根本问题不是“训练误差太低”，而是模型把 training set 中偶然出现的噪声也当成了稳定规律。

### 7.2 正则化到底在惩罚什么

一个常用办法是在 cost 中加入 parameter penalty：

$$
J_{reg}(\mathbf w,b)
=J(\mathbf w,b)+\frac{\lambda}{2m}\sum_{j=1}^{n}w_j^2
$$

$\lambda$ 控制惩罚强度。

这项 penalty 会压制过大的 weights，让模型不容易用极端参数追逐训练数据中的细小波动。

通常不正则化 bias $b$，因为单个 bias 对模型复杂度的贡献很小。

### 7.3 $\lambda$ 太大或太小会怎样

- $\lambda$ 太小：regularization 几乎不起作用，仍可能 overfit。
- $\lambda$ 太大：weights 被压得接近 $0$，模型失去表达能力，变成 underfit。

所以 regularization 并不是“越强越安全”。它仍然是一个需要由 validation evidence 选择的 hyperparameter。

### 7.4 与现代深度学习的连接

后面会见到 weight decay、dropout、data augmentation 和 early stopping。它们形式不同，但都在处理同一个问题：训练集上的拟合能力很强，不代表模型对未见数据也能泛化。

---

# 第四周：神经网络怎样完成 Forward

## 8. 神经网络表示（Neural Network Representation）

### 8.1 为什么需要神经网络

逻辑回归只能在现有 features 上画一个 linear boundary。我们当然可以手工制造大量 polynomial features，但 features 一多，组合数量会快速膨胀，而且人很难提前知道哪些组合真正有用。

神经网络换了一个思路：**让中间层自己学习新的表示。**

输入不再直接通向最终 prediction，而是先经过一层或多层 hidden units。

### 8.2 一个 neuron 做了什么

一个 neuron 先做线性变换：

$$
z=\mathbf w^T\mathbf x+b
$$

然后通过 activation function：

$$
a=g(z)
$$

![神经网络结构](assets/week4-neural-network.jpg)

这里的 $a$ 叫 activation。它既是当前 neuron 的输出，也是下一层的输入。

如果没有 activation，连续叠加多个 linear layers 仍然等价于一个 linear transformation：

$$
W_2(W_1x+b_1)+b_2=W'x+b'
$$

因此 nonlinearity 才让深层网络拥有比单层线性模型更强的表达能力。

### 8.3 一层怎样向量化

假设第 $l$ 层有一批输入 $A^{[l-1]}$：

$$
Z^{[l]}=A^{[l-1]}W^{[l]}+b^{[l]}
$$

$$
A^{[l]}=g(Z^{[l]})
$$

若采用 batch-first layout：

```text
A[l-1]: [batch, input_features]
W[l]:   [input_features, output_features]
b[l]:   [output_features]
Z[l]:   [batch, output_features]
```

bias 通过 broadcasting 加到 batch 中每条 example。

![Forward propagation](assets/week4-forward-propagation.png)

这就是 PyTorch `nn.Linear` 最核心的 computation。框架替你管理 parameter、autograd 和 device，但 matrix multiplication 与 broadcasting 没有消失。

### 8.4 Hidden layer 学到了什么

hidden unit 不需要被人工命名成“边缘检测器”或“某种房屋组合特征”。训练只要求最终 loss 下降，网络会自动找到对任务有帮助的 intermediate representation。

这就是 representation learning。

在图像中，早期 layers 可能对边缘和纹理敏感；在语言模型中，token representations 会逐层混合上下文信息。它们都不是手工写出的 feature formula。

原课程还用 AND、OR、NOT 和 XNOR 展示 network 怎样组合简单 decision boundaries。重点不是让神经网络去替代数字电路，而是看见：

```text
一个 hidden unit 可以表示一个简单条件
多个 hidden units 可以并行表示不同条件
下一层可以把这些条件重新组合成更复杂的 boundary
```

这就是 depth 的第一层直觉。每一层都在前一层表示的基础上继续组合，而不是让 output layer 一次完成所有 feature engineering。

### 8.5 多类别输出

如果有 $K$ 个 classes，output layer 通常产生 $K$ 个 logits：

$$
\mathbf z\in\mathbb R^K
$$

再通过 softmax：

$$
p_k=\frac{e^{z_k}}{\sum_{j=1}^{K}e^{z_j}}
$$

所有 $p_k$ 都在 $(0,1)$，并且总和为 $1$。

![多类别输出](assets/week4-multiclass.jpg)

实现时通常先减去最大 logit：

$$
p_k=\frac{e^{z_k-z_{max}}}{\sum_j e^{z_j-z_{max}}}
$$

这个变换不改变结果，却能减少 exponential overflow。这里开始，数值稳定性正式进入模型实现。

### 8.6 Forward 的完整数据流

```text
input batch X
-> linear transform Z1 = XW1 + b1
-> activation A1 = g(Z1)
-> linear transform Z2 = A1W2 + b2
-> output probabilities / logits
-> loss
```

Forward 的职责是根据当前 parameters 产生 prediction 和 loss。它还没有解释 parameters 应该怎样修改，这正是下一周 backpropagation 要解决的问题。

### 8.7 与 AI Infra 的连接

从系统角度看，一个 neural network forward 是一张 operator graph：

```text
tensor allocation
-> GEMM
-> bias broadcast
-> activation kernel
-> next GEMM
-> softmax / loss reduction
```

AI Infra 关心的不只是数学答案，还包括 tensor layout、dtype、kernel launch、memory reuse、operator fusion 和 device communication。但只有先读懂 forward graph，后面才知道系统究竟在优化什么。

---

# 第五周：反向传播与梯度检查

## 9. 反向传播（Backpropagation）

### 9.1 今天真正的问题

Forward 能算出 loss，但一个神经网络可能有数百万甚至数十亿 parameters。我们不可能手工对每个 parameter 单独展开完整公式。

反向传播解决的是：**怎样复用 computation graph 中的局部导数，高效得到 loss 对所有 parameters 的 gradients。**

### 9.2 从一个最小 computation graph 开始

假设：

$$
z=wx+b
$$

$$
e=z-y
$$

$$
L=e^2
$$

先从最后开始：

$$
\frac{\partial L}{\partial L}=1
$$

这是 backward 的 seed gradient。然后每个 operation 只处理自己的 local derivative：

$$
\frac{\partial L}{\partial e}=2e
$$

$$
\frac{\partial L}{\partial z}
=\frac{\partial L}{\partial e}\frac{\partial e}{\partial z}
=2e
$$

$$
\frac{\partial L}{\partial w}
=\frac{\partial L}{\partial z}\frac{\partial z}{\partial w}
=2ex
$$

$$
\frac{\partial L}{\partial b}
=\frac{\partial L}{\partial z}\frac{\partial z}{\partial b}
=2e
$$

这里最重要的不是结果，而是模式：

$$
\text{downstream gradient}
=\text{upstream gradient}\times\text{local derivative}
$$

### 9.3 多条路径为什么要累加

如果一个 value 同时通过多条路径影响 loss，那么总 gradient 是每条路径贡献之和。

例如：

$$
L=x^2+x
$$

$x$ 一条路径进入 square，另一条路径直接进入 addition：

$$
\frac{dL}{dx}=2x+1
$$

这就是为什么 autograd 中 gradient 通常采用 accumulate 语义，而不是“最后一次写入覆盖前一次结果”。

### 9.4 神经网络中的 backward

对每一层：

```text
forward 保存本层 backward 需要的 activations / inputs
backward 接收上游 gradient
-> 乘 local derivative
-> 计算 parameter gradients
-> 把 input gradient 传给前一层
```

![反向传播](assets/week5-backpropagation.png)

Forward 从 input 向 loss 流动；backward 从 loss 沿相反方向传播 gradient。

这也解释了训练为什么比纯 inference 占用更多 memory：训练期间不能随便丢掉 backward 仍然需要的 activations 和 metadata。

### 9.5 展开与还原 parameters

老课程会把多个 weight matrices 展开成一个长 parameter vector，交给 generic optimizer，再还原成原始 shapes。

现代框架会替你维护 parameter tensors，但本质相同：optimizer 需要遍历一组 parameters，并用相同结构的 gradients 更新它们。

无论是否 flatten，都必须保存 shape、offset、dtype 与 parameter identity，否则 gradient 无法准确写回原对象。

### 9.6 Gradient checking：给 backward 找一个独立法官

analytic gradient 来自 backprop。为了验证它，可以用 centered finite difference：

$$
\frac{\partial J}{\partial\theta_i}
\approx
\frac{J(\theta_i+\varepsilon)-J(\theta_i-\varepsilon)}{2\varepsilon}
$$

![梯度检查](assets/week5-gradient-check.png)

finite difference 只调用 forward，不复用 backward formula，因此它能作为独立 correctness oracle。

但 $\varepsilon$ 不是越小越好：

- 太大：Taylor approximation 的 truncation error 增大。
- 太小：floating-point cancellation 与 rounding error 增大。

Gradient check 很慢，因为每个 coordinate 至少需要额外两次 forward。它适合小模型、抽样 parameter 或 reference implementation，不适合每一步大规模训练。

### 9.7 为什么不能把所有 weights 初始化成相同值

如果同一层所有 neurons 以完全相同的 weights 开始，它们会得到相同 output、相同 gradient，并在每一步继续保持相同。

这叫 symmetry。网络虽然有很多 neurons，却像只有一个 neuron。

因此 weights 要随机初始化来打破 symmetry；bias 可以初始化为 $0$。现代初始化方法还会根据 fan-in/fan-out 控制 variance，避免 activations 和 gradients 在深层网络中迅速放大或衰减。

### 9.8 Training 与 inference 的第一条分界线

```text
inference：只执行 forward，主要关心 weights、activations、KV Cache 与 latency
training：forward + backward + optimizer，还要保存 activations、gradients 和 optimizer states
```

同一个模型，training memory 往往远高于 inference memory。以后计算显存账时，不能只数 parameter bytes。

### 9.9 原课程的自动驾驶例子想说明什么

课程展示了早期神经网络从摄像头图像预测方向盘动作的系统。它的历史实现已经不是今天的技术前沿，但例子仍然揭示了 supervised learning 的完整链条：

```text
采集人类驾驶数据
-> 图像成为 input
-> 方向盘动作成为 label
-> network 学习 input 到 action 的 mapping
-> 在新道路图像上执行 forward
```

真正的自动驾驶系统当然还需要感知、预测、规划、控制、冗余与安全验证。一个 supervised network 只是 pipeline 中的一部分，不能把 demo accuracy 等同于系统安全。

---

# 第六周：模型诊断与机器学习系统设计

## 10. 当模型效果不好时，下一步做什么

### 10.1 最昂贵的错误，是凭感觉改模型

模型效果不好时，人很容易立刻做这些事：

```text
收集更多数据
增加 features
换一个更复杂的 model
训练更久
增大或减小 regularization
```

这些动作都有可能有效，也都有可能完全浪费时间。

第六周真正教的是一套工程判断方法：**先用 evidence 判断问题属于哪里，再决定把时间花在哪里。**

### 10.2 Train、validation 与 test 为什么必须分开

- **Training set**：用于学习 parameters。
- **Validation / dev set**：用于选择 model、hyperparameters 和 threshold。
- **Test set**：只用于最后估计泛化能力。

如果反复查看 test result 并据此修改模型，test set 就已经参与了开发过程。它不再是独立证据，而是另一个 validation set。

一个常见流程是：

```text
train multiple candidates on training set
-> choose using validation error
-> report final result once on test set
```

### 10.3 Bias 与 variance 怎样从误差中看出来

假设 human-level 或简单 baseline error 很低：

- train error 很高：模型连 training data 都没有拟合好，通常是 high bias。
- train error 低、validation error 明显更高：模型记住了 training data，却不能泛化，通常是 high variance。

![Bias 与 variance](assets/week6-bias-variance.jpg)

这两个诊断会直接改变下一步：

| 证据 | 更可能有效的动作 |
|---|---|
| High bias | 更强模型、更好 features、训练更充分、降低 regularization |
| High variance | 更多数据、更强 regularization、简化模型、data augmentation |

“更多数据”主要帮助 variance 问题。如果模型本身连训练集都学不好，继续堆同分布数据不一定解决 bias。

### 10.4 Learning curve 把数据量也纳入证据

Learning curve 画的是不同 training-set size 下的 train error 与 validation error。

![Learning curve](assets/week6-learning-curve.png)

High bias 时，两条曲线最终会在较高 error 附近靠拢。继续加数据通常收益有限。

High variance 时，train error 低而 validation error 高，两者之间存在明显 gap。更多数据有机会缩小 gap。

### 10.5 Regularization 与 bias/variance

$\lambda$ 太大，model 被限制得太死，容易 high bias。

$\lambda$ 太小，model 自由度太高，容易 high variance。

因此 $\lambda$ 不能用 test set 选择，而应该在 validation set 上比较多个 candidates。

---

## 11. 机器学习系统设计（Machine Learning System Design）

### 11.1 先建立一个简单 pipeline

以 spam classifier 为例，第一版不需要一次设计完美。可以先完成：

```text
text
-> feature extraction
-> classifier
-> prediction
-> metric
```

让 pipeline 跑起来后，再根据真实 errors 决定下一步。这和系统工程里的 V1 思路相同：先建立可观察的 end-to-end path，再针对瓶颈迭代。

### 11.2 Error analysis

从 validation set 中人工查看一批错误样本，记录错误类别：

```text
拼写变体
钓鱼链接
促销词
非英文内容
图片型垃圾邮件
```

统计每一类出现多少次。这样你能知道“增加某类 feature”最多可能修复多少错误，而不是凭印象重写系统。

### 11.3 Skewed classes 为什么不能只看 accuracy

如果异常请求只占 $1\%$，一个永远预测“正常”的模型也有 $99\%$ accuracy，但它没有任何检测能力。

这时需要 precision 和 recall：

$$
\text{precision}=\frac{TP}{TP+FP}
$$

$$
\text{recall}=\frac{TP}{TP+FN}
$$

![Precision 与 recall](assets/week6-precision-recall.png)

- precision 高：被模型判为 positive 的样本大多真的 positive。
- recall 高：真正的 positive 大多被模型找到了。

F1 score 把两者合并：

$$
F_1=2\cdot\frac{precision\cdot recall}{precision+recall}
$$

但最终选择哪个 metric，仍取决于业务成本。漏掉欺诈和误封正常用户的代价并不相同。

### 11.4 Threshold 是系统策略的一部分

classifier 输出 probability 后，还需要 threshold 才能得到最终 label。

提高 threshold 通常会提升 precision、降低 recall；降低 threshold 通常会提升 recall、降低 precision。

所以 model score 与业务决策不是同一个对象。线上系统经常需要根据 SLA、风险预算和下游处理能力动态选择 threshold。

### 11.5 更多数据什么时候真正有用

如果 features 足以让人类专家从输入中预测输出，并且 model 容量足够，那么更多高质量数据通常有帮助。

但“数据越多越好”不是无条件定律。数据分布错误、label 噪声严重、training-serving skew 或 evaluation metric 不匹配时，盲目扩充数量只会把原问题放大。

### 11.6 与主线的连接

这一周和 AI Infra 的关系比某个具体算法更直接：

```text
train/dev/test separation -> benchmark 不能边看 test 边调参数
error analysis            -> 优化前先定位瓶颈
precision/recall          -> 系统指标必须对应业务代价
learning curve            -> 用证据决定增加 data 还是 compute/model
```

以后做 inference benchmark，也要保持同样纪律：吞吐、延迟、正确率、显存和 workload 必须一起定义，否则一个漂亮数字没有解释力。

---

# 第七周：支持向量机与 Kernel

## 12. 支持向量机（Support Vector Machine）

### 12.1 从逻辑回归走到大间隔分类

逻辑回归只要求把 classes 分开。支持向量机进一步希望 decision boundary 离两边最近的 training examples 都尽可能远。

这个距离叫 margin。

![大间隔分类](assets/week7-large-margin.png)

直觉上，boundary 如果紧贴某个样本，数据稍微发生扰动就可能分类翻转；margin 更大的 boundary 往往更稳健。

### 12.2 Parameter $C$ 在控制什么

SVM 中的 $C$ 可以理解为“多重视训练错误”与“多重视宽 margin”之间的权衡。

- $C$ 很大：强烈惩罚 training errors，boundary 更努力拟合每个样本，variance 可能增大。
- $C$ 较小：允许少量 training errors，换取更宽 margin，regularization 更强。

它与逻辑回归中的 $\lambda$ 方向大致相反：更大的 $C$ 通常意味着更弱的 regularization。

### 12.3 Kernel 解决什么问题

如果原空间中无法用直线分开，可以把 input 映射到新的 features。

Gaussian kernel 衡量 $x$ 与 landmark $l$ 的接近程度：

$$
K(x,l)=\exp\left(-\frac{\|x-l\|^2}{2\sigma^2}\right)
$$

![Gaussian kernel](assets/week7-kernel.png)

离 landmark 越近，kernel value 越接近 $1$；越远则越接近 $0$。以多个 landmarks 生成 features 后，原本弯曲的 boundary 可能在新 feature space 中变成 linear boundary。

$\sigma$ 控制影响范围：

- $\sigma$ 小：每个 landmark 影响范围窄，boundary 更曲折，variance 更高。
- $\sigma$ 大：影响范围宽，boundary 更平滑，bias 更高。

### 12.4 为什么 kernel trick 曾经重要

显式构造高维 features 可能非常昂贵。Kernel method 可以直接计算两个 examples 在隐式 feature space 中的 inner product，而不必真的构造那个巨大 vector。

这是一个非常漂亮的 algorithmic idea：只计算优化真正需要的相似度，而不是 materialize 完整表示。

### 12.5 今天学到什么程度

对当前 AI Infra 路线，SVM 不是主项目。你需要掌握：

```text
margin 的直觉
C 与 regularization 的关系
kernel 是一种相似度与隐式 feature mapping
algorithm choice 会受 dataset size 和 compute complexity 限制
```

不需要现在完整推导 dual optimization，也不需要手写 production SVM。现代 LLM 工作负载的核心计算不在这里。

---

# 第八周：聚类与降维

## 13. K-means 聚类

### 13.1 没有 labels 时，怎样寻找 group

K-means 的目标是把 examples 分到 $K$ 个 clusters，使每个 example 离自己 cluster center 尽可能近。

它反复执行两个步骤：

```text
assignment step：把每个 example 分给最近的 centroid
update step：把每个 centroid 移到所属 examples 的 mean
```

![K-means](assets/week8-kmeans.jpg)

### 13.2 Optimization objective

若 $c^{(i)}$ 表示 example $i$ 所属 cluster，$\mu_k$ 表示第 $k$ 个 centroid：

$$
J=\frac{1}{m}\sum_{i=1}^{m}
\left\|x^{(i)}-\mu_{c^{(i)}}\right\|^2
$$

assignment step 在固定 centroids 时减小 $J$；update step 在固定 assignments 时也减小 $J$。所以每轮 objective 不会上升。

但它只能保证收敛到 local optimum，不保证全局最优。

### 13.3 为什么要多次随机初始化

不同初始 centroids 可能收敛到不同结果。因此通常进行多次 random initialization，选择最终 cost 最低的一次。

如果 $K$ 小于等于 examples 数，可以从 training examples 中随机选择 $K$ 个不同 points 作为初始 centroids，避免所有 centers 从同一点开始。

### 13.4 怎样选择 $K$

Elbow method 会观察 cost 随 $K$ 增加的变化。如果某个位置后收益明显变缓，它可能是合理选择。

但真实数据不一定存在清晰 elbow。很多时候 $K$ 最终由 downstream purpose 决定，例如压缩图片允许多少 colors，或业务希望划分多少用户 groups。

---

## 14. 主成分分析（Principal Component Analysis）

### 14.1 PCA 想保留什么

高维数据中，不同 features 可能高度相关。PCA 希望找到一组新的 orthogonal directions，让前几个 directions 尽可能保留数据 variance。

如果从二维压到一维，就是寻找一条线，让所有 points 投影到这条线后的 reconstruction error 尽可能小。

![PCA 的投影直觉](assets/week8-pca.jpg)

### 14.2 PCA 不是线性回归

线性回归最小化的是 prediction 与 label $y$ 的 vertical error。

PCA 没有 label。它最小化的是 input point 到低维 subspace 的 orthogonal projection distance。

两者图上都可能出现一条线，但解决的问题完全不同。

### 14.3 算法步骤

先进行 mean normalization，必要时做 feature scaling。以下公式中的 $X$ 指已经 centered 的数据，然后计算 covariance-like matrix：

$$
\Sigma=\frac{1}{m}X^TX
$$

再通过 SVD：

$$
U,S,V^T=\operatorname{svd}(\Sigma)
$$

取 $U$ 的前 $k$ 列形成 $U_{reduce}$，把原数据投影到低维：

$$
Z=XU_{reduce}
$$

重建近似：

$$
X_{approx}=ZU_{reduce}^T
$$

### 14.4 怎样选择主成分数量

常见目标是让 retained variance ratio 达到 $99\%$ 或 $95\%$。用 singular values 可计算：

$$
\frac{\sum_{i=1}^{k}S_{ii}}
{\sum_{i=1}^{n}S_{ii}}
$$

选择最小的 $k$，使该比例达到目标。

### 14.5 PCA 的正确用途

PCA 可用于 visualization、compression 和去除高度相关 dimensions。但不要为了“防止 overfitting”而默认先做 PCA。

PCA 会丢失 information，而且它不知道 labels。若 supervised model 过拟合，应先用 regularization、更多数据和正确 validation 诊断。

### 14.6 与 AI Infra 的连接

K-means 与 PCA 不直接等于现代 embedding system，但它们建立了两个重要直觉：

```text
相似 examples 可以在 vector space 中按 distance 组织
高维 representation 可能存在更低维的主要结构
```

以后接触 embedding、vector retrieval、quantization 和 representation compression 时，这些直觉会再次出现。系统侧则要进一步考虑 index、memory footprint、batch query 与 distance kernel。

---

# 第九周：异常检测与推荐系统

## 15. 异常检测（Anomaly Detection）

### 15.1 为什么有些问题不适合普通分类

假设服务器每天产生大量正常 metrics，真正的 failure 却极少，而且新的 failure pattern 可能以前从未出现。

这时很难列举所有异常类别去训练一个普通 classifier。更自然的做法是先学习“正常数据长什么样”，然后判断新样本在这种分布下是不是极不可能出现。

### 15.2 从 Gaussian distribution 开始

一维 Gaussian distribution：

$$
p(x;\mu,\sigma^2)
=\frac{1}{\sqrt{2\pi}\sigma}
\exp\left(-\frac{(x-\mu)^2}{2\sigma^2}\right)
$$

![Gaussian distribution](assets/week9-gaussian.png)

从 training data 估计：

$$
\mu=\frac{1}{m}\sum_{i=1}^{m}x^{(i)}
$$

$$
\sigma^2=\frac{1}{m}\sum_{i=1}^{m}(x^{(i)}-\mu)^2
$$

如果暂时假设各 features 独立：

$$
p(\mathbf x)=\prod_{j=1}^{n}p(x_j;\mu_j,\sigma_j^2)
$$

若 $p(\mathbf x)<\varepsilon$，就判定为 anomaly。

### 15.3 Threshold 怎样选择

$\varepsilon$ 不是凭感觉设置。使用带有少量 labels 的 validation set，比较不同 thresholds 下的 precision、recall 或 F1，再选择符合业务代价的一点。

training set 可以主要由 normal examples 构成；validation/test 中要保留真实 anomalies，才能验证检测能力。

### 15.4 Anomaly detection 与 supervised learning 的边界

更适合 anomaly detection：

```text
positive examples 极少
异常种类很多，未来还会出现新类型
normal behavior 比 anomaly behavior 更容易建模
```

更适合 supervised classification：

```text
positive examples 足够多
未来 positives 与历史 positives 类型相近
模型能够直接学习 class boundary
```

### 15.5 Feature engineering 为什么特别重要

如果 raw features 的分布严重偏斜，可以使用 $\log(x+c)$、square root 等 transformation，让数据更接近 Gaussian shape。

更重要的是，features 要能暴露异常。例如只有 CPU utilization 可能发现不了问题，但“CPU utilization / network traffic”也许能揭示资源比例异常。

### 15.6 Multivariate Gaussian

独立 Gaussian model 分别建模每个 feature，无法直接表示 correlations。

Multivariate Gaussian 使用 covariance matrix：

$$
p(\mathbf x)
=\frac{1}{(2\pi)^{n/2}|\Sigma|^{1/2}}
\exp\left(-\frac{1}{2}(\mathbf x-\mu)^T
\Sigma^{-1}(\mathbf x-\mu)\right)
$$

它能发现“每个 feature 单独看都正常，但组合关系异常”的样本。代价是需要更多数据估计 $\Sigma$，计算也更昂贵。

### 15.7 与系统监控的连接

异常检测直接对应 AI Infra observability：

```text
latency
throughput
GPU utilization
memory usage
queue depth
error rate
```

但是生产告警不能只依赖一个概率公式。还要处理 concept drift、seasonality、missing metrics、alert fatigue 和回滚策略。课程给的是统计核心，不是完整监控系统。

---

## 16. 推荐系统（Recommender Systems）

### 16.1 问题怎样表示

设 $Y_{ij}$ 表示用户 $j$ 对物品 $i$ 的 rating，$R_{ij}=1$ 表示这条 rating 已知。

推荐系统的目标，是预测缺失的 $Y_{ij}$。

![推荐系统矩阵](assets/week9-recommender.png)

### 16.2 Content-based recommendation

如果每个 movie 已有 feature vector $x^{(i)}$，例如 romance、action 的程度，那么每个 user 可以学习自己的 preference vector $\theta^{(j)}$：

$$
\hat y^{(i,j)}=(\theta^{(j)})^Tx^{(i)}
$$

这相当于为每个用户训练一个 linear model。

问题是：现实中 item features 往往也不知道，手工标注成本很高。

### 16.3 Collaborative filtering

Collaborative filtering 同时学习：

```text
每个 item 的 latent feature vector x(i)
每个 user 的 preference vector theta(j)
```

预测仍然是 inner product：

$$
\hat y^{(i,j)}=(\theta^{(j)})^Tx^{(i)}
$$

训练只在 $R_{ij}=1$ 的 observed entries 上计算 error，并对两组 vectors 都做 regularization。

### 16.4 Low-rank matrix factorization

把所有 item vectors 组成 $X$，所有 user vectors 组成 $\Theta$，完整预测矩阵是：

$$
\hat Y=X\Theta^T
$$

![低秩矩阵分解](assets/week9-low-rank.png)

原本巨大的 user-item matrix，被表示成两个较窄 matrices 的乘积。这就是 low-rank factorization。

这里的 latent vector 已经非常接近 embedding 的直觉：一个离散 ID 被映射成可学习的 dense vector，vector geometry 编码了相似性与偏好。

### 16.5 Mean normalization 与 cold start

如果一个新 user 没有任何 ratings，未经处理的 model 可能预测得很差。对每个 item 的 ratings 先减去 mean，模型只学习相对偏好，最终再把 mean 加回去，会得到更合理的 baseline。

但真正的 cold-start problem 不会因此完全消失。新 user 和新 item 缺少 interaction evidence，常需要 content features、热门推荐或探索策略。

### 16.6 与 LLM / AI Infra 的连接

推荐系统把几件事提前摆在了你面前：

```text
embedding table
sparse IDs -> dense vectors
large matrix multiplication
top-k retrieval
online updates
memory capacity 与 sharding
```

这些都是机器学习基础设施中的真实问题。课程只讲 objective；工程上还要解决亿级 embeddings 的存储、更新、一致性、cache 与 distributed serving。

---

# 第十周：大规模机器学习与 Pipeline 分析

## 17. 大规模机器学习（Large Scale Machine Learning）

### 17.1 数据很多时，batch gradient descent 为什么变贵

Batch gradient descent 每次 parameter update 都扫描全部 $m$ 条 examples。

当 $m$ 很大时，单次 update 就可能耗时很久。问题不在公式错误，而在“每走一步都必须读完整 dataset”。

### 17.2 Stochastic gradient descent

SGD 每次只用一个 example 估计 gradient：

```text
shuffle dataset
-> read one example
-> compute prediction and error
-> update parameters immediately
```

![SGD 路径](assets/week10-sgd.jpg)

因为单个 example 的 gradient 很 noisy，cost 不会平滑下降，而是在最优区域附近波动。但 update 非常频繁，能够快速开始学习，也适合 streaming data。

### 17.3 Mini-batch gradient descent

Mini-batch 每次使用 $B$ 条 examples：

$$
\nabla J_B
=\frac{1}{B}\sum_{i\in batch}\nabla L^{(i)}
$$

它位于 batch GD 与 SGD 之间：

- 比单样本 gradient 稳定。
- 比全量 batch 更频繁更新。
- 最重要的是能把 $B$ 条 examples 组织成 matrix operation，利用 SIMD、BLAS 和 GPU parallelism。

这就是现代 deep learning training 的默认形态。

### 17.4 怎样观察 SGD 是否收敛

单条 example 的 loss 噪声太大，通常每隔一段时间对最近若干 losses 求 average，再观察趋势。

如果平均窗口太小，curve 仍然很 noisy；窗口太大，又会掩盖近期变化。

减小 learning rate 通常能让结果在 optimum 附近更稳定，但会牺牲前期速度。现代 optimizer 会使用 learning-rate schedule、momentum 和 adaptive statistics 改进这一过程。

### 17.5 Online learning

在线学习让每次新 interaction 都成为一次 update：

```text
receive user event
-> make prediction
-> observe outcome
-> update model
```

它适合 data distribution 持续变化的场景。但 production system 还必须处理 bad data、feedback loop、rollback、versioning 和 delayed labels。能更新不代表应该让任何请求直接改变线上模型。

### 17.6 MapReduce 与 data parallel 的早期直觉

如果 gradient 是 examples 上贡献的 sum，就可以把 dataset 分片：

```text
worker 1 computes partial gradient on shard 1
worker 2 computes partial gradient on shard 2
...
reduce partial gradients
-> update shared parameters
```

![数据并行](assets/week10-data-parallel.jpg)

现代 distributed training 的 data parallel 仍沿用这个核心结构，只是通信通常由 all-reduce 完成，并加入 gradient bucketing、overlap、mixed precision、fault tolerance 等系统机制。

真正的瓶颈也不只在 compute：

```text
dataset I/O
host-to-device transfer
GPU compute
gradient communication
optimizer state update
checkpoint write
```

AI Infra 的工作，就是找出这些阶段谁在阻塞谁，再通过 batching、parallelism、memory management 与 communication optimization 改善 end-to-end performance。

---

## 18. 应用实例：图片文字识别（Photo OCR）

### 18.1 为什么课程最后讲 pipeline

识别街景图片中的文字，不是一个单独 classifier 就能解决的任务。完整 pipeline 可能包含：

```text
image
-> text detection
-> character segmentation
-> character recognition
-> language correction
-> final text
```

![OCR pipeline](assets/week10-ocr-pipeline.jpg)

这一章真正想教的不是旧版 OCR 技术，而是：复杂 ML product 由多个 stages 组成，最终效果取决于整条 pipeline。

### 18.2 Sliding window

早期 object detection 会用固定窗口在 image 上滑动，对每个位置运行 classifier，再改变 window size 重复扫描。

它计算量大、重复工作多，但建立了 dense prediction 的基本直觉。现代 convolutional architecture 会复用大量 computation，不再把每个 window 当成完全独立任务。

### 18.3 Artificial data synthesis

如果真实 labeled data 不够，可以通过字体渲染、背景合成、旋转、裁剪、颜色变化等方式生成训练数据。

但 synthetic data 必须逼近真实 input distribution。如果合成过程留下过于明显的 artifacts，模型可能只学会区分“合成痕迹”，线上效果仍然很差。

### 18.4 Ceiling analysis

怎样判断 pipeline 下一步该优化哪一段？

把某个 stage 暂时替换成 perfect ground truth，观察 end-to-end metric 最多提升多少。

例如：

```text
当前总准确率 72%
把 detection 替换成完美结果 -> 89%
再把 segmentation 替换成完美结果 -> 91%
再把 recognition 替换成完美结果 -> 99%
```

这说明 detection 与 recognition 都有较大改进空间，segmentation 的上限收益较小。

Ceiling analysis 与性能 profiling 是同一种工程思想：**不要平均优化所有模块，先找到限制 end-to-end result 的主要瓶颈。**

---

## 19. 课程结束后，应该留下什么

十周内容看上去包含很多算法，但真正需要带走的是一套稳定思维：

### 第一层：模型计算

```text
input
-> parameterized forward
-> prediction
-> scalar loss
-> gradient
-> parameter update
```

### 第二层：泛化与证据

```text
training evidence 不能代替 validation evidence
test set 不能参与反复调参
metric 必须对应业务代价
出现问题先判断 bias / variance / data / pipeline bottleneck
```

### 第三层：系统成本

```text
vectorization 把计算交给 optimized kernels
mini-batch 提供并行机会
大模型训练还要支付 activation、gradient、optimizer 和 communication 成本
pipeline 优化必须看 end-to-end bottleneck
```

## 20. 与当前学习规划的最终对齐

这份 ML 讲义不会抢走系统主线，也不会替代 T module。

接下来的职责分工是：

```text
这份 ML.md
-> 给出完整机器学习地图、优化方法和诊断思维

ai_theory/T4~T13
-> 把 gradient、loss、PyTorch、autograd、MLP 真正写成可运行 reference

后续 Transformer / inference modules
-> 把 forward、attention、KV Cache、sampling 映射到 memory 与 performance

C++ 系统主线
-> 完成 HTTP Server、Mini Redis，再进入 serving systems
```

你不需要因为学了传统机器学习，就暂停 Reactor、HTTP Server 和 Mini Redis 去实现十个传统算法项目。

对当前求职目标，最有价值的组合是：

```text
能解释 model 在算什么
+ 能写 correctness reference
+ 能把系统做正确
+ 能用 benchmark 找出真正瓶颈
+ 能说清楚 trade-off
```

这才是机器学习理论真正开始为 AI Infra 服务的地方。

## 21. 完整自检

学完后，试着不用看笔记回答：

1. model、parameter、loss、gradient 与 optimizer 各自负责什么？
2. feature scaling 为什么会改变 gradient descent 路径？
3. logistic regression 为什么使用 sigmoid 与 cross-entropy？
4. regularization 怎样影响 bias 与 variance？
5. backpropagation 为什么是 upstream gradient 乘 local derivative？
6. gradient checking 为什么算独立 oracle，又为什么不能用于大模型每一步训练？
7. train/dev/test 各自承担什么证据职责？
8. precision 与 recall 为什么比 skewed dataset 上的 accuracy 更有意义？
9. K-means、PCA、anomaly detection 与 recommender 各自解决什么问题？
10. mini-batch 为什么同时是 optimization 选择和 systems 选择？
11. data parallel 为什么需要 communication？
12. ceiling analysis 与 performance profiling 的共同思想是什么？

能把这些问题串成一条因果链，这门课就不再是一堆算法名字，而是一张能继续通向 PyTorch、Transformer 与 AI Infra 的地图。

---

## 资料索引

- [中文课程笔记](http://www.ai-start.com/ml2014/)
- [中文笔记 GitHub 与原始配图](https://github.com/fengdu78/Coursera-ML-AndrewNg-Notes)
- [本地 AI Infra 理论伴随线](../AI_Infra理论伴随线规划.md)
- [本地 T modules](../ai_theory/)
- [本地总规划](../plan_strengthened.md)
