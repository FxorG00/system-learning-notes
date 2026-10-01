# 逻辑回归（Logistic Regression）

好，我们进入第三周的 逻辑回归（Logistic Regression）。这一部分建立在你已经学会的线性回归、矩阵乘法、梯度下降之上，但解决的问题从“预测一个连续数值”变成“判断属于哪一类”。

这次我先把 6.1～6.4 一口气讲通：为什么分类不能直接照搬线性回归、sigmoid 到底做了什么、decision boundary 从哪里来、为什么 loss 要换成 cross-entropy，以及为什么最后的梯度公式居然又长得和线性回归很像。讲义正是按这个顺序展开的。

---

## 一、先明确问题发生了什么变化

线性回归解决的是：

$$
x\longrightarrow \hat y\in\mathbb R
$$

例如：
- 输入：房屋面积
- 输出：257.3 万

所以模型：

$$
z=\mathbf w^T\mathbf x+b
$$

直接输出一个任意实数完全没有问题。

但是分类问题不同。

假设我们判断：一个请求是否异常

标签只有：

$$
y\in\{0,1\}
$$

例如：
- 0 = 正常
- 1 = 异常

如果我们依然使用：

$$
z=\mathbf w^T\mathbf x+b
$$

可能得到：
- $z=-7.2$
- 或者 $z=3.6$
- 甚至 $z=184$

这些数字作为一个“分数”没有问题，但它们不能直接解释成概率。

因为概率必须满足：

$$
0\le p\le1
$$

所以现在我们需要解决一个新问题：

怎么把任意实数 $z\in(-\infty,+\infty)$，转换到 $0\sim1$ 之间？

这就是 sigmoid 出场的原因。

---

## 二、Sigmoid 究竟做了什么？

Sigmoid 定义：

$$
\boxed{
g(z)=\frac{1}{1+e^{-z}}
}
$$

逻辑回归就变成：

$$
z=\mathbf w^T\mathbf x+b
$$

然后：

$$
\boxed{
\hat y=g(z)
}
$$

我们先别管导数，先看看数值。

当 $z=0$：

$$
g(0)
=
\frac{1}{1+e^0}
=
\frac12
$$

所以：

$$
g(0)=0.5
$$

当 $z$ 非常大，比如 $z=10$：

那么 $e^{-10}\approx0$，所以：

$$
g(10)\approx1
$$

当 $z$ 非常小，比如 $z=-10$：

那么 $e^{10}$ 非常大，所以：

$$
g(-10)\approx0
$$

因此它完成的是：
- 很大的负数 → 接近 0
- 0          → 0.5
- 很大的正数 → 接近 1

讲义把这个输出解释成：

$$
\boxed{
P(y=1\mid\mathbf x)
}
$$

也就是：给定当前输入 $\mathbf x$，模型认为标签为 1 的概率。

---

## 三、这里其实存在三个不同的对象

这一点我建议你现在就分清楚，因为以后做模型 serving 时非常重要。

逻辑回归不是：输入 → 0/1

它实际上是：

```
输入 x
↓
线性打分
z = wᵀx + b
↓
sigmoid
probability
↓
threshold
↓
最终类别 0 / 1
```

这三个东西分别是：

1. **Logit / score**

$$
z=\mathbf w^T\mathbf x+b
$$

它可以是任意实数。比如 $z=2.3$。

2. **Probability**

$$
p=g(z)
$$

比如 $g(2.3)\approx0.91$。

3. **Prediction**

假设阈值是 $0.5$，那么：

- $p\ge0.5\Rightarrow\hat y_{\text{class}}=1$
- 否则 $\hat y_{\text{class}}=0$

讲义后面专门把这三层分开，因为模型参数决定 probability，而 threshold 是系统策略的一部分。

这个区分以后做 AI Infra / inference service 时特别重要。因为 serving 系统有时候输出的是 logits，有时候输出 probabilities，还有时候直接输出 predicted label。它们不是一回事。

---

## 四、Decision Boundary 为什么是 $w^Tx+b=0$？

这一点其实非常漂亮。

我们规定：

$$
p\ge0.5
$$

预测为 1。

而 $p=g(z)$，我们已经知道 $g(0)=0.5$，并且 sigmoid 是单调递增函数。

所以：

$$
g(z)\ge0.5
$$

等价于：

$$
z\ge0
$$

又因为 $z=\mathbf w^T\mathbf x+b$，所以：

$$
\boxed{
\mathbf w^T\mathbf x+b\ge0
}
$$

就是预测为 1 的区域。

而分类从 0 切换到 1 的那个临界位置满足：

$$
\boxed{
\mathbf w^T\mathbf x+b=0
}
$$

这就是 decision boundary。

---

## 五、举一个二维例子

假设：

$$
z=2x_1+x_2-6
$$

那么 decision boundary 满足：

$$
2x_1+x_2-6=0
$$

整理：

$$
x_2=6-2x_1
$$

所以它是一条直线。

如果某个点满足 $2x_1+x_2-6>0$，那么 $z>0$，因此 $p>0.5$，分类为 1。另一侧则分类为 0。

注意一个特别容易混淆的点：不是 sigmoid 把 decision boundary 变成了一条直线。真正决定边界形状的是 $z=\mathbf w^T\mathbf x+b$。sigmoid 只是把这个 score 转成 $0\sim1$ 的数。

所以如果我们像上一节多项式回归那样构造：

$$
z=w_1x_1+w_2x_2+w_3x_1^2+w_4x_2^2+b
$$

那么令 $z=0$ 得到的 decision boundary 就可以是弯曲的。这一点讲义也明确强调了。

---

## 六、为什么不能继续使用平方误差？

现在到了一个比较关键的地方。

你可能自然会想：线性回归用 $L=\frac12(\hat y-y)^2$，现在逻辑回归不就是多了一个 sigmoid 吗？那我继续用 $L=\frac12(g(z)-y)^2$ 不行吗？

理论上当然可以写出这样一个目标函数，但讲义指出，把 sigmoid 和平方误差组合起来后，优化问题不再保持线性回归那样简单的凸结构，因此逻辑回归采用了另一种更合适的 loss：Binary Cross-Entropy（二元交叉熵）。

公式是：

$$
\boxed{
L(\hat y,y)
=
-y\log\hat y
-(1-y)\log(1-\hat y)
}
$$

第一眼看着很复杂。但因为 $y\in\{0,1\}$，它其实只有两种情况。

---

## 七、当真实标签 $y=1$ 时发生什么？

代入：

$$
L
=
-1\log\hat y
-(1-1)\log(1-\hat y)
$$

第二项直接消失：

$$
\boxed{
L=-\log\hat y
}
$$

现在观察几个数。

- 如果模型预测 $\hat y=0.9$，那么 $-\log(0.9)\approx0.105$，loss 很小。说明真实答案是 1，模型预测 0.9 → 很不错。
- 如果模型预测 $\hat y=0.1$，那么 $-\log(0.1)\approx2.303$，loss 很大。
- 如果模型特别自信地预测错误 $\hat y=0.0001$，那么 $-\log(0.0001)\approx9.21$，loss 非常大。

也就是说：当真实答案是 1 时，模型越接近 1，loss 越小；越自信地预测成 0，惩罚越严重。这就是讲义这一段的直觉。

---

## 八、当真实标签 $y=0$ 时呢？

代入：

$$
L
=
-0\log\hat y
-(1-0)\log(1-\hat y)
$$

于是：

$$
\boxed{
L=-\log(1-\hat y)
}
$$

- 如果 $\hat y=0.1$，那么 $1-\hat y=0.9$，$-\log(0.9)\approx0.105$，loss 很小。说明真实答案 0，预测 0.1 → 很不错。
- 但如果预测 $\hat y=0.99$，那么 $1-\hat y=0.01$，$-\log(0.01)\approx4.605$，惩罚很大。

因此：模型如果“非常自信地错了”，cross-entropy 会给出很大的惩罚。讲义正是用这两种情况解释 BCE。

---

## 九、整个训练集的 cost 怎么来？

你前面线性回归已经很熟悉了。单样本 $L^{(i)}$，多个样本就取平均：

$$
\boxed{
J(\mathbf w,b)
=
\frac1m
\sum_{i=1}^{m}
L(\hat y^{(i)},y^{(i)})
}
$$

也就是：
- 第 1 个样本产生 loss
- 第 2 个样本产生 loss
- 第 3 个样本产生 loss
- ...
- 全部求平均
- 得到整个 batch 的 cost

这部分和之前几乎完全一致。变化的是单样本 loss 的定义。

---

## 十、现在最神奇的地方来了：它的梯度

逻辑回归最后得到：

$$
\boxed{
\nabla_{\mathbf w}J
=
\frac1mX^T(\hat{\mathbf y}-\mathbf y)
}
$$

以及：

$$
\boxed{
\frac{\partial J}{\partial b}
=
\frac1m\sum_i
(\hat y^{(i)}-y^{(i)})
}
$$

是不是看起来非常眼熟？这和线性回归的梯度公式居然一样。讲义也专门提醒：公式外形一样，但 $\hat y$ 的来源不同。

- 线性回归：$\hat y=z=\mathbf w^T\mathbf x+b$
- 逻辑回归：$z=\mathbf w^T\mathbf x+b$，然后 $\hat y=\sigma(z)$

也就是说：

```
线性回归：
Xw+b
 ↓
prediction

逻辑回归：
Xw+b
 ↓
sigmoid
 ↓
prediction
```

但是最后梯度却都是 $X^T(\hat y-y)$。这不是巧合。

---

## 十一、我们把这个梯度亲手推一次

这一步很值得推，因为你现在已经会链式法则了。

先只看一个样本。

定义：

$$
z=\mathbf w^T\mathbf x+b
$$

$$
\hat y=\sigma(z)
$$

以及：

$$
L=
-y\log\hat y
-(1-y)\log(1-\hat y)
$$

我们的目标是 $\frac{\partial L}{\partial w_j}$。

链式法则：

$$
\frac{\partial L}{\partial w_j}
=
\frac{\partial L}{\partial \hat y}
\cdot
\frac{\partial \hat y}{\partial z}
\cdot
\frac{\partial z}{\partial w_j}
$$

我们一个一个算。

**第一步：$\frac{\partial L}{\partial\hat y}$**

因为：

$$
L=
-y\log\hat y
-(1-y)\log(1-\hat y)
$$

所以：

$$
\frac{\partial L}{\partial\hat y}
=
-\frac{y}{\hat y}
+
\frac{1-y}{1-\hat y}
$$

通分：

$$
=
\frac{-y(1-\hat y)+(1-y)\hat y}
{\hat y(1-\hat y)}
$$

展开分子：

$$
-y+y\hat y+\hat y-y\hat y
$$

中间两项抵消：

$$
=\hat y-y
$$

因此：

$$
\boxed{
\frac{\partial L}{\partial\hat y}
=
\frac{\hat y-y}
{\hat y(1-\hat y)}
}
$$

先把它留着。

**第二步：Sigmoid 的导数**

这是一个很经典的结果：

$$
\boxed{
\frac{d\sigma(z)}{dz}
=
\sigma(z)(1-\sigma(z))
}
$$

因为 $\hat y=\sigma(z)$，所以：

$$
\boxed{
\frac{\partial\hat y}{\partial z}
=
\hat y(1-\hat y)
}
$$

现在你有没有发现一个东西？上一步有 $\frac1{\hat y(1-\hat y)}$，这一步刚好有 $\hat y(1-\hat y)$。

**第三步：把两项相乘**

$$
\frac{\partial L}{\partial z}
=
\frac{\partial L}{\partial\hat y}
\frac{\partial\hat y}{\partial z}
$$

所以：

$$
=
\frac{\hat y-y}
{\hat y(1-\hat y)}
\cdot
\hat y(1-\hat y)
$$

直接抵消：

$$
\boxed{
\frac{\partial L}{\partial z}
=
\hat y-y
}
$$

这就是最漂亮的一步。Sigmoid 的导数与 cross-entropy 中出现的项抵消掉了。因此从 loss 反传到 logit：

$$
\boxed{
\frac{\partial L}{\partial z}
=
\hat y-y
}
$$

---

## 十二、再继续传到 $w_j$

我们知道：

$$
z=w_1x_1+\cdots+w_jx_j+\cdots+b
$$

所以：

$$
\frac{\partial z}{\partial w_j}=x_j
$$

于是：

$$
\frac{\partial L}{\partial w_j}
=
\frac{\partial L}{\partial z}
\frac{\partial z}{\partial w_j}
$$

得到：

$$
\boxed{
\frac{\partial L}{\partial w_j}
=
(\hat y-y)x_j
}
$$

是不是又回到了你特别熟悉的形式？

多个样本取平均：

$$
\frac{\partial J}{\partial w_j}
=
\frac1m\sum_i
(\hat y^{(i)}-y^{(i)})
x_j^{(i)}
$$

再按照你之前已经完整推导过的矩阵化过程：

$$
\boxed{
\nabla_{\mathbf w}J
=
\frac1m
X^T
(\hat{\mathbf y}-\mathbf y)
}
$$

整个逻辑就闭合了。

---

## 十三、从 AI Infra 角度看，这里发生了什么？

现在你已经可以把逻辑回归训练拆成几个算子了：

```
X @ w
↓
+b
↓
sigmoid
↓
binary cross entropy
↓
backward
↓
error = probability - label
↓
X.T @ error
↓
parameter update
```

其中：
- `X @ w` 是线性代数计算；
- sigmoid 是 elementwise operation；
- cross-entropy 包含 log 等逐元素操作和 reduction；
- `X.T @ error` 又是线性代数计算；
- 最终还需要更新参数。

以后神经网络本质上就是把这类计算图变得更深、更大。

另外，讲义后面还特别强调实际框架一般不会“先算 sigmoid，再自己取 log”，而会采用数值更稳定的 formulation，例如直接根据 logits 计算 BCE。这其实已经开始进入非常重要的 AI Infra / numerical computing 思维：数学上等价，不代表浮点计算中数值稳定性一样。

例如，如果 sigmoid 输出已经被浮点数近似成 $1.0$，那么再算 $\log(1-\hat y)$ 就可能出现 $\log(0)$，从而产生 -inf。所以像 PyTorch 的 BCEWithLogitsLoss 会把 sigmoid 和 BCE 组合成一个更稳定的公式，而不是机械地逐步执行教科书公式。

---

## 你现在先把逻辑回归压缩成这张图

```
                 Linear Regression

X
↓
Xw + b
↓
prediction
↓
MSE
↓
error
↓
Xᵀ error
↓
gradient


                Logistic Regression

X
↓
Xw + b
↓
logit z
↓
sigmoid
↓
probability
↓
cross entropy
↓
经过链式法则化简
↓
probability - label
↓
Xᵀ error
↓
gradient
```

真正发生变化的主要是 forward 和 loss。而最终反传到线性层以后，又出现了你熟悉的：

$$
X^T(\hat y-y)
$$

这也是为什么你现在前两周打下的矩阵和梯度基础非常重要——从这里开始，它们不是重新学，而是在不断复用。