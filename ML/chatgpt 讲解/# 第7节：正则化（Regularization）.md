# 第7节：正则化（Regularization）

这一节最重要的不是记住一个多出来的 $\lambda$，而是理解一个新的训练目标：

> **我们不只希望模型把训练集拟合好，还希望它不要为了训练集里的偶然噪声，把自己变得过于“极端”。**

讲义把欠拟合对应到 high bias，把过拟合对应到 high variance，并强调过拟合的真正问题不是“训练误差太低”，而是模型把训练数据中的偶然波动也当成了规律。

## 1. 为什么“训练误差更低”反而可能更差？

先用你已经学过的多项式回归想。

真实规律假设大概是：

$$
y\approx 2x+1
$$

但训练数据有一点噪声。

如果我们只用一次模型：

$$
\hat y=w_1x+b
$$

它可能抓住主要趋势。

如果我们突然给模型非常强的表达能力：

$$
\hat y = w_1x+w_2x^2+w_3x^3+\cdots+w_{20}x^{20}+b
$$

那么模型可能做到一件事情：

**为了让每一个训练点的误差都很小，它开始在数据点之间疯狂弯曲。**

假设训练集中某个点只是因为测量误差稍微偏高一点，模型却可能说：

> “不，这不是噪声，这一定是宇宙规律，我要专门拐个弯穿过去。”

于是训练误差 $J_{\text{train}}$ 确实越来越小。

但是新来一个没见过的样本，它就可能预测得很差。

这就是：

$$
\text{training fit很好} \not\Rightarrow \text{generalization很好}
$$

这里的 generalization（泛化），就是对没参与训练的新数据依然表现良好的能力。

---

## 2. 那我们怎么阻止模型“为了几个点玩命弯曲”？

一种思路是直接降低模型能力。

比如不要 $x,x^2,\ldots,x^{20}$，只保留 $x,x^2,x^3$。这是可以的。

但还有另一种更柔和的方法：

> **我允许你拥有很多参数，但如果你想把某些参数搞得特别大，你要付额外代价。**

这就是 L2 regularization。

原来的目标 $J_{\text{data}}(\mathbf w,b)$ 现在变成：

$$
J_{\text{reg}}(\mathbf w,b) = J_{\text{data}}(\mathbf w,b) + \frac{\lambda}{2m} \sum_{j=1}^{n} w_j^2
$$

讲义的定义就是这样，并且通常不把 bias $b$ 放进这个 penalty。

这里第一次出现两个目标在“拔河”。

第一部分 $J_{\text{data}}$ 告诉模型：尽量把训练数据预测准。

第二部分 $\frac{\lambda}{2m}\sum_j w_j^2$ 告诉模型：可以拟合，但别为了拟合把 weights 搞得太极端。

所以 optimization 现在寻找的不是单纯“训练误差最小”，而是寻找一个折中：

$$
\text{数据拟合} + \text{参数规模惩罚}
$$

---

## 3. 为什么平方权重能够起到这个作用？

假设只有两个参数。

方案 A：$w_1=1,\; w_2=2$，penalty = $1^2+2^2=5$

方案 B：$w_1=10,\; w_2=20$，penalty = $10^2+20^2=500$

所以第二组参数要付出非常大的额外 cost。

optimizer 就会问：“你为了把 data loss 再降低一点，真的值得把 parameter 从 2 推到 20 吗？”

如果降低的 data loss 不足以抵消增加的 regularization penalty，它就不会这么做。

于是模型**倾向于**选择比较温和的 weights。

这里注意我说的是“倾向”。不是说大 weight 一定过拟合，也不是说小 weight 就一定泛化好。L2 regularization 是通过限制 parameter magnitude 来约束模型自由度的一种方法。

---

## 4. $\lambda$ 到底控制什么？

现在看：

$$
J_{\text{reg}} = J_{\text{data}} + \frac{\lambda}{2m}\sum_j w_j^2
$$

$\lambda$ 就像 regularization penalty 的音量旋钮。

- 如果 $\lambda=0$，那么 $J_{\text{reg}}=J_{\text{data}}$，完全没有 regularization。
- 如果 $\lambda$ 比较小，模型主要还是在乎数据拟合。
- 如果 $\lambda$ 很大，那么 optimizer 会非常害怕出现较大的 weights。

极端情况下，$w_1,w_2,\ldots,w_n\approx0$，模型可能只剩一个接近常数的预测 $\hat y\approx b$，它已经没有足够能力描述数据了，于是又产生 underfitting。

因此你可以把它想成：

- 小 $\lambda$ → 模型自由度较大
- 大 $\lambda$ → 模型受到更强约束

讲义也明确指出：太小仍可能 overfit，太大则可能 underfit，所以 regularization 不是越强越好；$\lambda$ 是需要通过验证集选择的 hyperparameter。

---

## 5. 现在我们把梯度亲手推出来

这一步其实非常简单，因为你已经会梯度了。

假设线性回归原来的 loss 是 $J_{\text{data}}(\mathbf w,b)$。

现在：

$$
J_{\text{reg}} = J_{\text{data}} + \frac{\lambda}{2m} \sum_{j=1}^{n} w_j^2
$$

我们求 $\frac{\partial J_{\text{reg}}}{\partial w_j}$。

利用求导的线性性质：

$$
\frac{\partial J_{\text{reg}}}{\partial w_j} = \frac{\partial J_{\text{data}}}{\partial w_j} + \frac{\partial}{\partial w_j} \left( \frac{\lambda}{2m} \sum_k w_k^2 \right)
$$

求 $w_j$ 的偏导时，其他 $w_k$ 都是常数。所以只剩 $\frac{\lambda}{2m} w_j^2$ 求导：

$$
\frac{\partial}{\partial w_j} \frac{\lambda}{2m} w_j^2 = \frac{\lambda}{2m} \cdot 2 w_j = \frac{\lambda}{m} w_j
$$

于是：

$$
\frac{\partial J_{\text{reg}}}{\partial w_j} = \frac{\partial J_{\text{data}}}{\partial w_j} + \frac{\lambda}{m} w_j
$$

这就是整个 L2 regularization 的 gradient。没有什么新的求导魔法，就是：

$$
\text{原梯度} + \text{regularization gradient}
$$

讲义在线性回归里也是这个结果。

---

## 6. 写成向量之后更简单

如果 $\mathbf w = \begin{bmatrix} w_1 \\ w_2 \\ \vdots \\ w_n \end{bmatrix}$，那么：

$$
\nabla_{\mathbf w} J_{\text{reg}} = \nabla_{\mathbf w} J_{\text{data}} + \frac{\lambda}{m} \mathbf w
$$

shape 检查：$\nabla_{\mathbf w} J_{\text{data}}:[n]$，$\mathbf w:[n]$，所以 $[n]+[n]\rightarrow[n]$。最终 gradient shape 仍然和 parameter shape 相同。

你以后在 PyTorch 里看到 L2 penalty，本质上就是在原来的 gradient 上多出这样一个与 parameter 本身有关的项。

---

## 7. 为什么它会产生“Weight Decay”？

现在把刚才的梯度代入 gradient descent：

$$
w_j \leftarrow w_j - \alpha \left( \frac{\partial J_{\text{data}}}{\partial w_j} + \frac{\lambda}{m} w_j \right)
$$

展开：

$$
w_j \leftarrow w_j - \alpha \frac{\partial J_{\text{data}}}{\partial w_j} - \alpha \frac{\lambda}{m} w_j
$$

把两个 $w_j$ 合在一起：

$$
w_j \leftarrow \left(1 - \frac{\alpha \lambda}{m}\right) w_j - \alpha \frac{\partial J_{\text{data}}}{\partial w_j}
$$

看第一项：$\left(1 - \frac{\alpha \lambda}{m}\right) w_j$。如果 $0 < 1 - \frac{\alpha \lambda}{m} < 1$，那么每次更新前，旧 weight 都会先被乘上一个略小于 1 的数字。比如 $0.99 w_j$，它会有一种不断被往零方向轻轻拉的效果。

这就是讲义说的：weight decay 这个名字的第一层来源。

举个数字例子。假设 $w=10$，并且 $\frac{\alpha \lambda}{m}=0.01$。先暂时假设 data gradient 为零。那么：

$$
10 \rightarrow 9.9 \rightarrow 9.801 \rightarrow 9.703 \rightarrow \cdots
$$

parameter 会逐渐衰减。

当然实际训练还有 data gradient，所以不是简单地一直趋近于零，而是两股力量同时存在：

- data gradient：让我更好拟合数据
- regularization：别让 weight 变得没必要地大

这两个共同决定最终参数。

---

## 8. 为什么 bias 通常不 regularize？

假设模型 $\hat y = w^T x + b$。

$w$ 控制各个 feature 怎样影响模型。而 $b$ 更多是在整体上移动预测或者 decision boundary。

例如 $z = w_1 x_1 + w_2 x_2 + b$。改变 $w_1, w_2$ 可能改变边界方向、形状以及模型对各特征的敏感程度。而改变 $b$ 更像整体移动这条边界。

所以常见实践是 regularize weights，而不 regularize bias。讲义也是这样处理的。

但你不要把它理解为数学定律。它是一个常用的 modeling convention。

---

## 9. Logistic Regression 要重新发明 regularization 吗？

不需要。这是这一节很漂亮的一点。

线性回归：$J_{\text{data}} = \text{MSE}$
逻辑回归：$J_{\text{data}} = \text{Binary Cross Entropy}$

但是 regularization 都可以是 $\frac{\lambda}{2m} \|\mathbf w\|_2^2$。

所以逻辑回归：

$$
J_{\text{reg}} = J_{\text{BCE}} + \frac{\lambda}{2m} \|\mathbf w\|_2^2
$$

gradient 同样是：

$$
\nabla_{\mathbf w} J_{\text{reg}} = \nabla_{\mathbf w} J_{\text{BCE}} + \frac{\lambda}{m} \mathbf w
$$

而我们刚刚已经知道 $\nabla_{\mathbf w} J_{\text{BCE}} = \frac{1}{m} X^T (\hat{\mathbf y} - \mathbf y)$，所以：

$$
\nabla_{\mathbf w} J_{\text{reg}} = \frac{1}{m} X^T (\hat{\mathbf y} - \mathbf y) + \frac{\lambda}{m} \mathbf w
$$

这正是讲义 7.6 的意思：**model 的 data loss 可以变，但 regularization 是附加在 objective 上的独立约束。**

---

## 10. 这里有一个非常容易犯的错误

假设你写：

```python
loss = data_loss + reg_loss
```

但是 gradient 却还是：

```python
grad_w = X.T @ error / m
```

那就错了。因为你告诉 optimizer “我要优化的是 regularized loss”，但给它的 gradient 却是 unregularized loss 的 gradient。两者不是同一个函数。

正确逻辑必须是：

$$
J = J_{\text{data}} + J_{\text{reg}}
$$

因此：

$$
\nabla J = \nabla J_{\text{data}} + \nabla J_{\text{reg}}
$$

这和我们上一节讲高级 optimizer 时强调的 **cost 和 gradient 必须属于同一个 objective** 正好接上了。

---

## 11. 为什么不能看训练 loss 来选择 $\lambda$？

这一步非常重要。

假设我们试 $\lambda=0$，$\lambda=1$，$\lambda=100$。你不能简单说“哪个 training loss 最低，我就选哪个”。因为 regularization 本来就在故意牺牲一部分 training fit，以换取更好的 generalization。

我们真正关心的是新数据上的表现。

所以讲义给出的流程是：

$$
\text{train} \rightarrow \text{fit parameters}
$$

然后：

$$
\text{validation} \rightarrow \text{选择 } \lambda
$$

最后配置全部确定以后：

$$
\text{test} \rightarrow \text{做最终评估}
$$

正则化负责控制模型自由度，validation 才负责告诉我们“这个强度是否真的让未见数据表现更好”。

---

## 你现在可以把整节压缩成这一条链

$$
\text{模型能力很强} \rightarrow \text{可能把噪声也拟合进去} \rightarrow \text{overfitting / high variance}
$$

加入 $\frac{\lambda}{2m} \|\mathbf w\|^2$ → 大 weights 要付额外代价 → gradient 多出 $\frac{\lambda}{m} \mathbf w$ → 每次更新对 weights 有向零拉回的效果 → 降低模型追逐训练噪声的倾向 → 最终是否有效，要看 validation，而不是只看 training loss。

到这里，第三周的 **Logistic Regression + Regularization** 主线基本完整了。下一步就进入第四周：**神经网络**。而它并不是突然出现的新世界——第一个神经元其实就是你刚学过的 $z = \mathbf w^T \mathbf x + b$ 再接一个 activation。真正新的地方，是我们开始把很多这样的“小模型”连接起来，让前一层自动产生下一层所需要的 features。