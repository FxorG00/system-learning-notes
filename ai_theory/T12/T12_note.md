# R1

```text
就是本来的特征，我们用 Linear 去做的话，没办法做到很低的 loss；或者就是说这个例子，我们用直线无论怎么分，都没办法分准确。

但是我们可以通过一层中间计算，得到一组新特征。然后新特征就能用直线去准确分了。
```

- $(h_0,h_1)$ 是 hidden representation（隐藏表示）：输入经过中间计算后得到的一组新特征。
- $\max(0,x)$ 是 ReLU（修正线性单元）：负数变成零，非负数保持不变。
- 这种让整体不再等价于一次 Linear 的规则叫 nonlinear activation（非线性激活）。
- `Linear -> ReLU -> Linear` 组成的前馈模型叫 MLP（multi-layer perceptron，多层感知机）。

```text
输入                [B, 2]
  ↓ Linear(2, 8)
中间结果            [B, 8]
  ↓ ReLU
中间结果            [B, 8]
  ↓ Linear(8, 2)
类别分数 logits     [B, 2]
```

## ReLU 让模型有能力变成非线性

对，你理解得很准：**ReLU 让两层 Linear 之间加入了非线性规则。** 如果把 ReLU 去掉，前后两层 Linear 就可以合并成一层。

我们顺着算一遍。

假设输入是 $x$，第一层算出：

$$
h = W_1x + b_1
$$

第二层接着算：

$$
z = W_2h + b_2
$$

如果中间没有 ReLU，把第一式代入第二式：

$$
\begin{aligned}
z
&= W_2(W_1x + b_1) + b_2 \\
&= (W_2W_1)x + (W_2b_1 + b_2)
\end{aligned}
$$

现在把合并后的参数记成：

$$
W' = W_2W_1,\qquad b' = W_2b_1 + b_2
$$

就得到：

$$
\boxed{z = W'x + b'}
$$

这和一层 Linear 的形式一样。

也就是说，**即使中间算出了 8 个数，只要中间没有非线性处理，整个模型对输入做的仍然相当于一次线性变换加偏置。**

### 加上 ReLU 后呢？

现在中间变成：

$$
h = \operatorname{ReLU}(W_1x + b_1)
$$

而 ReLU 会对每个数执行：

$$
\operatorname{ReLU}(a) = \max(0, a)
$$

看一个数就很直观：

```text
输入 a：    -2   -1    0    1    2
ReLU(a)：    0    0    0    1    2
```

负数那一段全部变成了 0，正数那一段则保留下来。

**同一条直线没办法同时表达这两段规则。**

所以加了 ReLU 以后：

$$
z = W_2\operatorname{ReLU}(W_1x + b_1) + b_2
$$

一般就**不能再合并成一个 $W'x + b'$**。

模型因此有能力表达更复杂的分类边界，才有机会解决 XOR。

### 一个小补充

加入 ReLU 是让模型**有能力**变成非线性，并不保证任何参数下都一定非线性。

例如，如果第一层的结果在你观察的范围内始终为正，ReLU 在这段范围内就只是原样保留。

# R2

```text
backward 会改 .grad,不修改 paremeters
optimizer step 就是进行梯度下降,读取 .grad 并且修改 parameter value
下一轮 forward 前需要清空 gradient;因为 backward 会让 gradient accumulation
下一轮 forward 读取更新后的 parameters
```



# R3

## 为什么训练状态比推理状态更多

> **推理主要是拿现有参数算出结果;训练还需要根据 loss 算出 gradient,再用 gradient 更新 parameters**

用同一个模型来看：

```text
输入 x
  ↓
模型参数 W、b
  ↓
输出 logits
```

**推理**走到输出就可以了。计算过程中当然也会产生中间值，但如果后面的计算已经不再需要它们，就不需要为了反向传播把它们继续留着。

而**训练**得到 logits 后，还要继续：

```text
logits + 正确答案
        ↓
       loss
        ↓
    backward
        ↓
  参数的 gradient
        ↓
 optimizer 更新参数
```

所以，除了参数值本身，还会多出：

- **中间值和计算关系**：供 backward 按链式法则计算梯度。
- **参数的 gradient**：记录 loss 对各参数的导数。
- **optimizer 的 state（优化器状态）**：某些优化器需要保存以前更新的信息。例如 AdamW 会为参数维护额外的统计量；普通 SGD 没有启用 momentum（动量）时，就不一定有这些额外状态。
- **训练所需的标签和 loss**：用来衡量预测与正确答案的差距。

所以你刚才说的那条因果链很准确：

> **推理只需要算出结果；训练还要算出“参数该怎样调整”，并真正调整它们，因此需要保留更多信息。**

补一句：这是比较**同一个模型、同一类输入规模**时的典型情况。实际峰值内存还受 batch 大小、输入长度和实现方式影响，不能只看“训练”或“推理”两个字就直接得出具体数字。