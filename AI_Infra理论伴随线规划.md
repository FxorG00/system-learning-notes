# AI Infra 理论伴随线规划

> 版本：2026-08-21
> 适用对象：FxorG，中山大学计算机科学与技术专业，当前 Week8 Day1 已通过
> 职业目标：本科就业，主攻 LLM inference systems / serving 与 CUDA/Triton kernel optimization
> 本文件定位：`plan_strengthened.md` 的 AI Infra 理论伴随线，不替代 C++ / Linux / OS / 网络 / Reactor / Mini Redis 主线

---

## 1. 为什么需要这条理论线

AI Infra 不是纯模型算法研究，但仍然需要理解模型到底在算什么。

以后做：

```text
Tensor / operator
CUDA kernel
Transformer inference
KV Cache
quantization
continuous batching
vLLM / Triton
```

都会不断遇到：

```text
shape 为什么这样变化
矩阵乘为什么是主要计算
softmax 为什么要减 max
normalization 在哪个维度计算
dtype 为什么影响显存、速度和误差
attention 为什么同时消耗计算和内存
prefill 与 decode 为什么性能特征不同
```

如果完全不学线性代数、概率、机器学习和深度学习，就只能背框架名词；但如果现在暂停系统主线，完整刷数学系课程和算法研究路线，又会偏离就业目标。

所以采用：

```text
系统工程主线：80%~90%
AI 理论伴随线：10%~20%
```

这条线的目标不是考试高分，而是：

```text
能解释模型 forward 的对象和数据流
能写最小 NumPy / PyTorch reference
能检查 shape、dtype 和数值误差
能为 CPU/CUDA implementation 提供 correctness oracle
能把数学操作映射到内存、并行和性能问题
```

---

## 2. 当前结论

### 2.1 必须学习

```text
Python / NumPy
线性代数
微积分与梯度最低入口
概率统计最低入口
机器学习基本 workflow
深度学习 forward / backward 第一层
PyTorch Tensor / Module / inference
Attention / Transformer
LLM inference 基本机制
```

### 2.2 不需要现在完整通关

```text
整门证明导向概率论
整套传统机器学习算法
复杂统计推断
凸优化完整理论
从零训练大型模型
GAN / 强化学习 / 图神经网络全线
海量论文复现
训练对齐与 RLHF
```

### 2.3 对当前方向的优先级

```text
第一优先：线性代数、Tensor、shape、dtype、数值计算
第二优先：深度学习 forward、Attention、Transformer
第三优先：微积分、gradient、backpropagation
第四优先：概率、cross entropy、sampling、maximum likelihood
第五优先：传统机器学习算法大全
```

概率论仍然重要，但对当前 inference / serving / kernel 目标，它不应该排在线性代数、Tensor 和 Transformer 之前。

### 2.4 课程依赖与资料依据

这条顺序不是因为“AI 视频都这么排”，而是参考了正式课程与框架材料：

- [Stanford CS229](https://cs229.stanford.edu/) 把 Python/NumPy、概率、多元微积分和线性代数列为机器学习先修。
- [Dive into Deep Learning](https://www.d2l.ai/) 在正式模型前安排数据操作、线性代数、微积分、自动微分和概率统计预备。
- [MIT 18.06 Linear Algebra](https://ocw.mit.edu/courses/18-06sc-linear-algebra-fall-2011/) 提供矩阵、子空间、最小二乘、特征值和 SVD 的完整长期参考。
- [Harvard Statistics 110](https://stat110.hsites.harvard.edu/) 覆盖条件概率、随机变量、期望方差和常见分布，可在概率缺口出现时定向补。
- [PyTorch Learn the Basics](https://docs.pytorch.org/tutorials/beginner/basics/) 按 Tensor、data、Module、autograd、optimization 和 save/load 组织实践入口。

本规划不会把这些完整课程全部并行通关，而是根据 AI Infra 当前需要选择章节，再用代码 gate 验收。

---

## 3. 和系统主线怎样并行

### 3.1 当前起点

当前系统主线位置：

```text
Week8 Day1 已通过
下一步：Week8 Day2 ThreadPool V1
后续：AsyncLogger -> Reactor -> HTTP Server -> Mini Redis
```

理论线从 `T1` 开始。`T` 表示 Theory companion week，与主线的 `WeekN` 不要求一一对应。

例如：

```text
主线 Week9 很重
-> T2 可以用两个自然周完成

学校考试周
-> 理论线暂停一周

主线进展很顺
-> 一周完成一个 T Week
```

不为了追表格破坏主线节奏。

### 3.2 每周时间

默认每周约 `3` 小时：

```text
Session A：60~90 分钟，概念 + 视频
Session B：60~90 分钟，独立代码
Session C：30~60 分钟，复盘 + 验证
```

推荐安排：

```text
周二或主线较轻的一天：Session A
周四或周五：Session B
周末：Session C
```

不建议每天再开一份重型 AI daily。理论线以每周一个小闭环推进。

### 3.3 主线优先规则

出现以下情况时，本周理论线缩减为一次 60 分钟复习：

```text
主线项目出现未解决 correctness bug
主线 daily 尚未通过
考试周或课程大作业
睡眠明显不足
理论线开始挤占 C++ 项目实现时间
```

理论线可以慢，不能把两条线都做成半成品。

---

## 4. 学习方法与固定产出

每个 T Week 固定产出：

```text
1. 一份短 note：只记录真正不熟的概念
2. 一个可以运行的 .py / notebook
3. 至少一组 shape / value / tolerance 验证
4. 一段“这和 AI Infra 有什么关系”的解释
```

不要只留下：

```text
看完第 1~20 P
收藏了 8 门课程
抄了几十页公式
运行了别人 notebook 但不知道输出为什么对
```

### 4.1 建议代码目录

Ubuntu 后续逐步创建，不要求现在一次建完：

```text
~/code/system-learning/ai-theory/
├── t01_numpy_basics/
├── t02_vector_matrix/
├── ...
└── t24_transformer_reference/
```

Windows 笔记可放：

```text
C:\Users\FxorG\Desktop\gpt_infra\ai_theory_notes\
```

本次只创建规划文件，不提前创建 24 个空目录。

### 4.2 验收原则

```text
视频看完：不算通过
公式抄完：不算通过
代码能跑但无法解释 shape：不算通过

能手推一个小例子
+ 能独立写 reference
+ 能用 assert / tolerance 验证
+ 能解释和 inference/performance 的关系
= 通过
```

---

# 第一阶段：数学、Python 与 NumPy 最低闭环

> 周次：T1~T8
> 建议强度：每周约 3 小时
> 与主线关系：可从现在低强度开始，不进入 CUDA，不开大型模型项目

---

## T1：Python / NumPy 与 ndarray

### 本周问题

```text
C++ 中的数据通常由 type、object、memory 表达；
NumPy 中一个 ndarray 到底包含什么？
```

### 学习内容

```text
Python list 与 NumPy ndarray 的差异
ndarray.shape / ndim / size / dtype
创建 zeros / ones / arange / array
索引、切片和 axis 第一层
elementwise operation
reshape 的使用边界
```

### 学到什么程度

必须能够看到：

```python
x.shape == (2, 3, 4)
```

并解释：

```text
有 3 个 dimensions
每个 dimension 的 extent 是 2 / 3 / 4
总元素数为 24
dtype 决定每个元素的表示和字节数
```

本周不深入：

```text
NumPy C API
高级 ndarray subclass
复杂 fancy indexing
```

### 代码产出

```text
numpy_basics.py
```

固定验证：

```text
创建 1D / 2D / 3D arrays
打印并 assert shape / ndim / size / dtype
reshape 前后元素总数不变
故意写一个 shape 不匹配案例并解释 error
```

### 通过标准

能把 `shape / axis / dtype / element count` 用自己的话讲清楚。

---

## T2：向量、矩阵与线性变换直觉

### 本周问题

```text
矩阵为什么不只是二维数字表？
```

### 学习内容

```text
scalar / vector / matrix / tensor
vector addition 与 scalar multiplication
linear combination
span / basis 直觉
matrix 作为 linear transformation
row vector / column vector 的 shape 区别
```

### 学到什么程度

必须能够：

```text
画出 2D vector
解释矩阵 A 作用于 x 得到 y
手算一个 2x2 matrix-vector multiplication
说明 matrix 的 columns 怎样决定 basis vectors 被映射到哪里
```

不要求：

```text
抽象向量空间严格公理证明
Jordan normal form
```

### 代码产出

```text
vector_matrix.py
```

用 NumPy 验证手算结果，并检查 input/output shapes。

### 推荐视频

- 主看：[3Blue1Brown 官方账号《线性代数的本质》第 1 讲](https://www.bilibili.com/video/BV1Ys411k7yQ)
- 配套实现：[李沐《动手学深度学习》线性代数](https://www.bilibili.com/video/BV1eK4y1U7Qy/)

### 通过标准

不能只说“matrix 是二维数组”；要能同时从数值存储和线性变换两层解释。

---

## T3：矩阵乘、转置、内积、范数与 broadcasting

### 本周问题

```text
为什么 Transformer 中到处都是 matmul？
```

### 学习内容

```text
matrix multiplication 的 shape rule
矩阵乘是 linear transformations 的 composition
transpose
dot product
L1 / L2 norm 直觉
batch matrix multiplication 第一层
broadcasting 对齐规则
```

### 学到什么程度

给出：

```text
A: [B, M, K]
B: [B, K, N]
```

能判断输出：

```text
[B, M, N]
```

并能解释为什么 `K` 必须匹配。

必须区分：

```text
elementwise multiply
dot product
matrix multiply
batch matrix multiply
```

### 代码产出

```text
matmul_broadcast.py
```

固定实验：

```text
用三层 for loop 写一个小 matmul reference
与 np.matmul 对比
测试 2D 和 batched shapes
测试一次合法 broadcasting 和一次非法 broadcasting
```

### 通过标准

能在不运行代码前推导至少 5 组 matmul/broadcast output shapes。

---

## T4：导数、偏导、梯度与 chain rule

### 本周问题

```text
训练时参数为什么知道应该向哪个方向变化？
```

### 学习内容

```text
derivative：单变量变化率
partial derivative：固定其他变量
gradient：所有 partial derivatives 组成的方向信息
chain rule：复合计算的导数传播
Jacobian 只建立 shape 直觉
gradient descent 基本更新式
```

### 学到什么程度

必须能够手推：

```text
y = (wx + b)^2
dy/dw
dy/db
```

能画出：

```text
w -> z = wx+b -> y = z^2
```

并沿图反向应用 chain rule。

不要求：

```text
epsilon-delta 严格证明
复杂 Hessian 推导
凸优化完整理论
```

### 代码产出

```text
finite_difference_gradient.py
```

用 finite difference 检查手推 gradient。

### 推荐视频

- 直觉主看：[3Blue1Brown 官方账号《微积分的本质》第 1 讲](https://www.bilibili.com/video/BV1cx411m78R/)

只选看导数、chain rule、gradient 相关章节，不要求本周刷完整套微积分。

### 通过标准

能解释 gradient 是什么、shape 是什么、为什么 chain rule 支撑 backpropagation。

---

## T5：概率最低入口

### 本周问题

```text
模型输出“概率”、sampling 和 expected value 分别在说什么？
```

### 学习内容

```text
sample space / event
conditional probability
Bayes rule 直觉
random variable
PMF / PDF 的区别
expectation / variance
independence
```

### 学到什么程度

必须能够：

```text
计算一个离散 random variable 的 expectation / variance
解释 P(A|B) 与 P(B|A) 不同
解释概率分布不是“模型一定会输出的答案”
```

不要求：

```text
测度论
极限定理证明
复杂连续变量变换
Markov chain 全章
```

### 代码产出

```text
discrete_probability.py
```

模拟 coin / categorical distribution，比较理论 expectation 与 sample mean。

### 推荐资源

- B 站辅助：[数据科学的概率基础](https://www.bilibili.com/video/BV1st411R7yU/)只选事件、条件概率、随机变量、期望方差
- 更严谨的长期参考：[Harvard Statistics 110](https://stat110.hsites.harvard.edu/)

### 通过标准

能解释 conditional probability、expectation、variance，并用采样实验验证。

---

## T6：常见分布、log、softmax 与数值稳定性

### 本周问题

```text
为什么直接 exp(logit) 可能溢出？
```

### 学习内容

```text
Bernoulli / categorical / Gaussian 直觉
log probability
log likelihood / maximum likelihood 直觉
logits 与 probability
softmax
cross entropy
log-sum-exp trick
floating-point overflow / underflow 第一层
```

### 学到什么程度

必须能够说明：

```text
logit 不一定在 [0, 1]
softmax output 总和为 1
softmax(x) == softmax(x - constant)
减 max 可以改善数值稳定性
```

### 代码产出

```text
stable_softmax.py
```

固定对比：

```text
naive softmax
stable softmax
输入 [1000, 1001, 1002]
与 NumPy/PyTorch reference 对比
```

### 推荐视频

- [李沐：Softmax 回归、损失函数与实现](https://www.bilibili.com/video/BV1K64y1Q7wu/)

### 通过标准

能独立写 stable softmax，并解释正确性与稳定性，而不是背一行代码。

---

## T7：linear regression 与 gradient descent

### 本周问题

```text
model、loss 和 optimizer 分别负责什么？
```

### 学习内容

```text
supervised learning
feature / label
linear model
mean squared error
full-batch gradient descent
learning rate
parameter update
```

### 学到什么程度

必须能够串出：

```text
input
-> prediction
-> loss
-> gradient
-> parameter update
-> next iteration
```

### 代码产出

```text
linear_regression_numpy.py
```

要求：

```text
自己生成 synthetic data
不用 sklearn
手写 forward / loss / gradient / update
记录 loss 下降
与真实参数比较
```

### 通过标准

能解释 loss 降低不等于程序绝对正确，并能用参数、prediction 和 loss 多层验证。

---

## T8：logistic / softmax regression 与 ML workflow

### 本周问题

```text
训练集表现很好，为什么模型仍可能没用？
```

### 学习内容

```text
classification
binary logistic regression 直觉
multiclass softmax regression
train / validation / test
overfitting / underfitting
regularization 直觉
accuracy 与 loss 的区别
bias / variance 只到直觉
```

### 学到什么程度

必须区分：

```text
训练过程使用的数据
超参数选择使用的数据
最终泛化评估使用的数据
```

传统 ML 暂停在这里，不要求继续刷：

```text
KNN
SVM 完整对偶推导
decision tree / boosting 全线
EM / HMM / CRF
```

### 代码产出

```text
softmax_classifier_numpy.py
```

要求在小 synthetic dataset 上完成 train/validation split 和 confusion observation。

### 通过标准

能够解释完整 ML workflow，并知道 validation/test 不能混用。

---

## Theory Gate 1：进入 PyTorch / 深度学习阶段

必须全部满足：

```text
[ ] 会使用 Python / NumPy 编写并测试小程序
[ ] 能推导 matmul output shape
[ ] 能手算简单 gradient
[ ] 能解释 expectation / variance / conditional probability
[ ] 能独立实现 stable softmax
[ ] 能实现 NumPy linear regression 或 softmax classifier
[ ] 当前系统主线没有因为理论线停摆
```

未满足时，不通过“多看一个视频”解决；回到对应代码产出补齐。

---

# 第二阶段：PyTorch、机器学习与深度学习基本机制

> 周次：T9~T16
> 建议前置：Theory Gate 1 通过
> 与主线关系：应在 ThreadPool/AsyncLogger 稳定后逐渐进入；Reactor 很重时允许放慢

---

## T9：PyTorch Tensor、dtype、device、layout

### 学习内容

```text
torch.Tensor
shape / stride / storage_offset 第一层
dtype
device
contiguous / non-contiguous 直觉
view / reshape / transpose
NumPy 与 Tensor 转换
in-place operation 风险第一层
```

### 学到什么程度

必须能够解释：

```text
Tensor 不只是多维数组接口
它还关联 dtype、device、layout/stride 和 storage
transpose 后 shape 改变，底层数据不一定复制
```

### 代码产出

```text
tensor_layout.py
```

打印并验证 transpose 前后的 shape、stride、contiguous state 和 data relation。

### 资源

- [PyTorch 官方 Learn the Basics](https://docs.pytorch.org/tutorials/beginner/basics/)
- B 站可用小土堆补 API：[PyTorch 快速入门](https://www.bilibili.com/video/BV1hE411t7RN/)

小土堆定位是 API 入门，不替代 Tensor/storage/inference 的机制理解。

---

## T10：`nn.Module`、parameter、forward 与 inference mode

### 学习内容

```text
nn.Module
parameter / buffer
forward
train mode / eval mode
torch.inference_mode
state_dict
save / load
```

### 学到什么程度

必须区分：

```text
Module object
parameter Tensor
activation Tensor
checkpoint/state_dict
```

并解释：

```text
eval() 改变部分 modules 的 behavior
inference_mode() 控制 autograd-related execution behavior
二者不是同一个按钮
```

### 代码产出

```text
module_inference.py
```

构造最小两层 Module，保存/加载 state_dict，并比较 output。

---

## T11：computation graph、autograd 与 backpropagation

### 学习内容

```text
forward graph
leaf Tensor
requires_grad
grad_fn
backward
gradient accumulation
zero_grad
dynamic graph 直觉
```

### 学到什么程度

必须能从：

```text
x -> Linear -> ReLU -> Linear -> loss
```

说明：

```text
forward 创建了哪些 activations
backward 需要哪些中间值
parameter.grad 在哪里累积
为什么推理可以不保留这些训练信息
```

### 代码产出

```text
autograd_inspect.py
```

用手推 gradient、finite difference 和 PyTorch autograd 三者交叉验证。

### 通过标准

不要求读 PyTorch autograd engine 源码，但必须理解 graph 与保存 activation 会影响 memory。

---

## T12：MLP、activation、loss 与 optimizer

### 学习内容

```text
Linear layer
ReLU / GELU 直觉
hidden dimension
depth / width
cross entropy
SGD / Adam 只到使用与机制第一层
batch
epoch / iteration
```

### 代码产出

```text
mlp_train_and_infer.py
```

要求：

```text
小数据集训练
保存 checkpoint
新进程或新 object 加载
inference_mode 下执行
验证 output shape 和 basic accuracy
```

### 通过标准

能完整串出 training flow 与 inference flow，并指出 inference 少了哪些对象和步骤。

---

## T13：generalization、regularization 与实验纪律

### 学习内容

```text
overfitting / underfitting
weight decay
dropout
train/eval behavior difference
data leakage
baseline
random seed 与 reproducibility 边界
```

### 代码产出

```text
overfit_observation.py
```

在小数据集上故意制造 overfitting，再加入一种 regularization，记录 train/validation curves。

### 通过标准

不能只写“加 dropout 防止过拟合”；要能说明实验中观察到了什么，以及结果不能推广到哪里。

---

## T14：CNN 与 ResNet forward 第一层

### 为什么 AI Infra 仍要学一点 CNN

CNN 是理解：

```text
operator composition
Tensor layout
parameter / activation
model forward
checkpoint execution
```

的一个紧凑例子。目标不是转向 CV 算法岗。

### 学习内容

```text
convolution input/output shape
channel / kernel / stride / padding
pooling
residual connection
ResNet block forward
```

### 学到什么程度

能对一个小 ResNet block 标注每一步 shape；不要求手推完整 convolution backward。

### 代码产出

```text
residual_block_forward.py
```

只做 forward、shape assertions 和 parameter/activation memory 粗略统计。

---

## T15：sequence、token、embedding 与 mask

### 学习内容

```text
token ID
vocabulary
embedding table lookup
batch / sequence / hidden dimensions
padding
padding mask
causal mask 直觉
```

### 学到什么程度

必须能够解释：

```text
token ID 本身不是语义向量
embedding lookup 怎样得到 [B, S, H]
padding mask 与 causal mask 解决不同问题
```

### 代码产出

```text
embedding_and_mask.py
```

构造小 vocabulary 和两个不同长度 sequences，完成 padding、embedding 和 masks。

---

## T16：self-attention 的 Q / K / V 主线

### 本周问题

```text
一个 token 怎样从其他 tokens 获取上下文？
```

### 学习内容

```text
Q / K / V projections
attention score
scale by sqrt(d)
mask
softmax
weighted sum
self-attention output
```

### 学到什么程度

给定：

```text
X: [B, S, H]
Wq/Wk/Wv: [H, D]
```

必须推导：

```text
Q/K/V: [B, S, D]
scores: [B, S, S]
probabilities: [B, S, S]
output: [B, S, D]
```

### 代码产出

```text
single_head_attention.py
```

先用小矩阵手算，再写 NumPy/PyTorch reference；验证 mask 后不允许关注的位置概率为 0 或数值上接近 0。

### 推荐视频

- [李沐：注意力分数](https://www.bilibili.com/video/BV1Tb4y167rb/)
- 李宏毅 2021 课程只选 Self-attention 上/下，不刷完整 40 讲：[B 站镜像入口](https://www.bilibili.com/video/BV1z5411A7b9/)

### 通过标准

能独立写出 single-head attention 主线并解释每个 shape，不背图。

---

## Theory Gate 2：进入 Transformer / inference 阶段

必须满足：

```text
[ ] 能解释 Tensor 的 shape / dtype / device / stride 第一层
[ ] 能区分 parameter、activation 和 checkpoint
[ ] 能解释 forward graph 与 backward 保存中间值的关系
[ ] 能写一个最小 PyTorch Module 并保存/加载
[ ] 能区分 train / eval / inference_mode
[ ] 能画出 ResNet 或 MLP 完整 forward
[ ] 能推导 single-head attention shapes
[ ] 当前至少一个 C++ 系统项目已形成测试/README/benchmark 证据
```

---

# 第三阶段：Transformer 与 LLM inference 理论桥接

> 周次：T17~T24
> 建议前置：Theory Gate 2 通过
> 定位：为 `mini-infer-cpu` 和后续 CUDA reference 做准备，不直接开始 vLLM 源码

---

## T17：multi-head attention 与 Transformer block

### 学习内容

```text
head dimension
split / transpose / merge heads
multi-head attention
output projection
residual connection
LayerNorm / RMSNorm 直觉
feed-forward network / MLP
pre-norm / post-norm 只到识别
```

### 代码产出

```text
transformer_block_reference.py
```

要求逐步 assert shape，不能只调用一个现成 Transformer layer 后打印结果。

### 推荐视频

- [李沐：Transformer](https://www.bilibili.com/video/BV1Kq4y1H7FL/)
- 通过后再看：[李沐 Transformer 论文逐段精读](https://www.bilibili.com/video/BV1pu411o7BE/)

论文精读不是入门第一步，先把 reference code 写通。

---

## T18：decoder-only Transformer 完整 forward

### 学习内容

```text
token embedding
position information 第一层
causal self-attention
RMSNorm / LayerNorm
MLP
residual stream
final norm
LM head
logits
```

### 代码产出

```text
decoder_only_forward.py
```

只做 1~2 layers 的 tiny model，固定随机种子和极小 dimensions，逐层打印 shape。

### 通过标准

能够从 token IDs 一直串到 logits，不把 logits 叫作 probabilities。

---

## T19：probability distribution 与 token sampling

### 学习内容

```text
logits -> temperature -> softmax
greedy decoding
categorical sampling
top-k
top-p 直觉
random seed
EOS
```

### 代码产出

```text
sampling_methods.py
```

在同一 logits 上比较 greedy、temperature、top-k，并用大量采样近似验证 categorical probabilities。

### 通过标准

能解释 sampling policy 改变 output distribution，但没有改变 model weights 和前面的 logits computation。

---

## T20：training 与 inference 的对象、内存和计算差异

### 学习内容

```text
weights
activations
gradients
optimizer states
training batch
inference batch
inference_mode
mixed precision 第一层
```

### 固定估算

对一个给定参数量 `P` 的模型，能够粗略估算：

```text
FP32 weights: P * 4 bytes
FP16/BF16 weights: P * 2 bytes
INT8 weights: P * 1 byte（忽略额外 scales/metadata 时的粗略值）
```

并明确这还没有包含：

```text
activations
KV Cache
allocator fragmentation
framework workspace
CUDA context
```

### 代码产出

```text
model_memory_estimate.py
```

### 通过标准

能区分 training memory 与 inference memory，不用“参数量乘 dtype”冒充完整显存占用。

---

## T21：prefill、decode 与 KV Cache

### 本周问题

```text
自回归生成为什么不应该每次重新计算全部历史 K/V？
```

### 学习内容

```text
prefill
decode
autoregressive generation
past keys / values
KV Cache shape
sequence length growth
memory cost
compute-memory trade-off
```

### 代码产出

```text
kv_cache_reference.py
```

比较：

```text
每一步重新计算 full prefix
缓存 previous K/V 后只计算 new token
```

只比较 correctness 和 operation shape；性能 benchmark 后续再严谨设计。

### 通过标准

能画出 prefill 与单步 decode 的不同数据流，并估算 KV Cache 随 batch/sequence/layers/heads/head_dim 的增长关系。

---

## T22：batching、padding、continuous batching 直觉

### 学习内容

```text
static batch
dynamic batch
padding waste
request arrival time
sequence length difference
continuous batching
finished request removal
backpressure 与 scheduler
```

### 和当前系统主线连接

```text
request queue -> scheduler -> model batch -> token output
```

与已经学过的：

```text
BlockingQueue
ThreadPool
backpressure
Reactor
```

建立映射，但不假装它们等价。

### 代码产出

```text
batch_scheduler_sim.py
```

只做 CPU 上的离散 simulation：不同 arrival time、prompt length、generation length，比较 static batching 与简单 continuous batching 的 idle/padding 情况。

### 通过标准

能解释 continuous batching 解决什么问题，以及 scheduler 为什么不只是普通 FIFO queue。

---

## T23：correctness、tolerance 与性能模型

### 学习内容

```text
reference output
absolute / relative tolerance
floating-point accumulation order
latency / throughput
warmup / repetition / synchronization
FLOPs 直觉
memory bandwidth
compute-bound / memory-bound 第一层
arithmetic intensity 直觉
```

### 代码产出

```text
operator_correctness_bench.py
```

选择：

```text
matmul / softmax / RMSNorm 三选一
```

记录：

```text
shape
dtype
reference
tolerance
warmup
repetitions
median/min/max
```

### 通过标准

不能只写“快了 30%”；必须说明基线、输入、正确性和测量边界。

---

## T24：tiny Transformer reference 小闭环

### 最终产出

```text
tiny_transformer_reference/
├── model.py
├── attention.py
├── sampling.py
├── test_reference.py
├── benchmark.py
└── README.md
```

### 最小范围

```text
tiny decoder-only model
token embedding
1~2 Transformer blocks
causal attention
norm + MLP
logits
greedy 或 top-k sampling
prefill/decode 第一层
KV Cache 第一层
```

### README 必须回答

```text
每个 Tensor 的 shape 是什么？
哪些是 parameters，哪些是 activations？
prefill 与 decode 怎样不同？
KV Cache 保存什么？
正确性怎样验证？
benchmark 测了什么，不能证明什么？
下一步怎样接 CPU operator implementation？
```

### 通过标准

```text
tests 可执行
forward 数据流可画
shape 全部可解释
sampling 可运行
有最小 benchmark
没有把课程代码原样换名冒充独立项目
```

---

## Theory Gate 3：进入 `mini-infer-cpu`

满足：

```text
[ ] stable softmax / normalization / attention 都有 reference
[ ] 能解释 Transformer decoder forward
[ ] 能区分 parameter / activation / KV Cache
[ ] 能区分 prefill / decode
[ ] 能估算 weights 和 KV Cache 的主要内存项
[ ] 能使用 tolerance 检查 operator correctness
[ ] tiny Transformer reference 有 tests 与 README
[ ] 主线至少完成 Reactor / Mini Redis 中一个完整项目
```

通过后进入总规划 Gate B 对应的 CPU inference：

```text
Tensor storage / shape / stride
operator interface
computation graph
CPU matmul / softmax / norm
model execution
```

仍然不自动进入 CUDA。CUDA 必须继续满足总规划 Gate C：C++/内存/并发稳定、CPU reference 完成、有可靠 GPU 环境。

---

# B 站视频资源选择

> 核对日期：2026-08-21
> 原则：视频只负责讲解，教材/官方文档负责校准，代码和验证才算学习产出。

## 1. 线性代数与微积分直觉

### 主推荐：3Blue1Brown 中国官方账号

- [线性代数的本质，第 1 讲](https://www.bilibili.com/video/BV1Ys411k7yQ)
- [微积分的本质，第 1 讲](https://www.bilibili.com/video/BV1cx411m78R/)

使用方式：

```text
线代系列：T2~T3 选择性看
微积分系列：T4 选择 derivative / chain rule 相关章节
```

优点：几何直觉强。

限制：

```text
不能替代手算
不能替代 NumPy implementation
不能替代学校线代/高数课程中的基本训练
```

### 可选深入：MIT Gilbert Strang

- [B 站 MIT 18.06 课程入口](https://www.bilibili.com/video/BV1qC4y1H7zK/)
- [MIT OpenCourseWare 18.06 官方课程](https://ocw.mit.edu/courses/18-06sc-linear-algebra-fall-2011/)

当前不要完整刷 35 讲。只有 basis、projection、eigenvalue、SVD 明显不懂时定向补。

---

## 2. 概率论

### 当前推荐

- [B 站《数据科学的概率基础》](https://www.bilibili.com/video/BV1st411R7yU/)
- [Harvard Statistics 110 官方](https://stat110.hsites.harvard.edu/)

当前只学：

```text
event
conditional probability
Bayes
random variable
expectation
variance
Bernoulli / categorical / Gaussian
```

暂不要求：

```text
完整组合计数训练
moment generating function
limit theorem proof
Markov chain
```

学校开设概率论时，以学校课程为主；本规划负责把知识映射到 softmax、sampling、cross entropy 和 model output。

---

## 3. 机器学习 / 深度学习主课

### 第一主课：李沐《动手学深度学习 v2》

优先使用“跟李沐学AI”账号的单课视频，不追“2026 全集打包”。

关键入口：

- [线性代数与实现](https://www.bilibili.com/video/BV1eK4y1U7Qy/)
- [Softmax、损失函数与实现](https://www.bilibili.com/video/BV1K64y1Q7wu/)
- [注意力分数](https://www.bilibili.com/video/BV1Tb4y167rb/)
- [Transformer](https://www.bilibili.com/video/BV1Kq4y1H7FL/)
- [Dive into Deep Learning 官方在线教材](https://www.d2l.ai/)

选学顺序按 T Week，不按视频列表从 P1 一路自动播放。

### 第二讲解源：李宏毅机器学习 2021

- [B 站课程镜像入口](https://www.bilibili.com/video/BV1z5411A7b9/)

只选：

```text
机器学习基本概念
训练任务攻略
backpropagation
batch / momentum / learning rate
self-attention 上下
Transformer 上下
network compression 第一层（量化阶段再看）
```

不看：

```text
GAN 全线
reinforcement learning 全线
meta learning
life-long learning
为了“完整”刷完 40 讲
```

说明：B 站条目是镜像，若失效，回到李宏毅课程官方页面/YouTube playlist；不要依赖单个搬运地址保存学习进度。

---

## 4. PyTorch API 入门

### 辅助推荐：小土堆

- [作者账号 PyTorch 快速入门](https://www.bilibili.com/video/BV1hE411t7RN/)
- [PyTorch 官方 Learn the Basics](https://docs.pytorch.org/tutorials/beginner/basics/)

定位：

```text
小土堆：帮助熟悉 Dataset / DataLoader / Module / save/load 等 API
官方教程：核对当前 API 和准确语义
本规划代码：负责 Tensor layout、inference 和 correctness 深度
```

不需要把完整 CV 训练套路当作 AI Infra 主线。

---

## 5. Transformer 论文与直觉

顺序：

```text
T15：embedding / mask
-> T16：single-head attention
-> T17：multi-head + Transformer block
-> 写 reference
-> 再看论文精读
```

推荐：

- [李沐：Transformer 视频与代码](https://www.bilibili.com/video/BV1Kq4y1H7FL/)
- [李沐：Transformer 论文逐段精读](https://www.bilibili.com/video/BV1pu411o7BE/)

不要在还推不出 `[B,S,H] -> [B,heads,S,head_dim]` 时，用论文精读制造“听懂了”的错觉。

---

## 6. “我是傅傅猪”课程放在哪里

本地已有完整盘点：

```text
我是傅猪猪/我是傅傅猪_UP主视频盘点与AI_Infra学习路线.md
```

使用时机：

```text
T1~T16：不作为主课
T17~T24：只看与 Tensor / operator / graph 的连接
Theory Gate 3 后：KuiperInfer 重制版正式进入 CPU inference 项目
Gate C 后：KuiperLlama / CUDA
更后面：Triton / vLLM 选集
```

当前不因为已经收藏课程就提前照抄推理框架。

---

## 7. 不推荐的选课方式

谨慎对待标题形如：

```text
“2026 最新 200 集”
“全网最全 400 集”
“三天从零到精通”
“关注公众号领取 300G 资料”
```

问题不一定是内容全部错误，而是：

```text
来源和授权常不清楚
章节被不同课程拼接
“最新版”不代表讲解更好
很容易把收藏量当学习进度
```

本规划优先使用：

```text
原作者/官方账号
大学官方课程
官方框架文档
可运行代码与测试
```

---

# 每周执行模板

## Session A：概念

```text
1. 先读本周问题和停止边界
2. 看指定主视频，不自动连播
3. 只记录 3~5 个真正不懂的术语
4. 手推一个最小例子
```

## Session B：代码

```text
1. 关闭参考代码
2. 自己写最小实现
3. 加 shape / value assertions
4. 与 NumPy/PyTorch reference 比较
5. 故意测一个错误 shape / edge case
```

## Session C：复盘

回答：

```text
这周的对象有哪些？
完整数据流是什么？
每一步 shape 是什么？
正确性怎样验证？
它和 CPU/GPU memory/performance 有什么关系？
目前明确没学什么？
```

如果代码已经清楚证明某一点，不机械抄长篇验收答案。

---

# 进度记录模板

```markdown
# Theory Txx Note

## 1. 本周主线

## 2. 我真正新理解的机制

## 3. Shape / formula 手推

## 4. Code and tests

## 5. 与 AI Infra 的连接

## 6. 当前不会的边界

## 7. Questions
```

验收记录至少包含：

```text
运行命令
输入 shape / dtype
expected / reference
tolerance（如涉及浮点）
实际结果
失败案例
```

---

# 调速规则

## 可以加速

如果某周内容已经由学校课程或实际代码证明掌握：

```text
直接完成 code output + gate check
不用重复看完整视频
```

## 必须放慢

出现：

```text
推不出 shape
只能复制 reference
不知道 dtype/device
把 logits 当 probability
不知道训练和推理差异
attention 只会背图
```

就停在当前周，不靠播放更多课程逃避基础缺口。

## 学校课程怎样计入

```text
学校线代/概率/高数：承担系统理论与习题训练
本伴随线：承担 NumPy/PyTorch/AI Infra 映射
```

同一知识不重复抄两份笔记。学校课程已经掌握的章节，可以直接做本规划代码验收。

---

# 24 周后的下一步

Theory Gate 3 通过后：

```text
第一主线：mini-infer-cpu
第二伴随：PyTorch reference / Transformer inference
```

当总规划 Gate C 满足后：

```text
CUDA vector add
-> reduce
-> softmax
-> RMSNorm
-> matmul/GEMV
-> RoPE/attention sub-operator
```

每个 CUDA operator 都复用本规划产生的 NumPy/PyTorch reference，而不是重新猜正确结果。

之后才进入：

```text
Triton
mini LLM inference
KV Cache optimization
continuous batching
vLLM / nano-vLLM
NCCL multi-GPU
```

---

# 最后压缩

```text
当前继续推进 C++ 系统主线。
AI 理论每周约 3 小时，不每日开第二份重课表。

T1~T8：Python / NumPy / 线代 / 微积分 / 概率 / ML workflow
T9~T16：PyTorch / Module / autograd / MLP / ResNet / Attention
T17~T24：Transformer / sampling / memory / KV Cache / batching / benchmark

视频负责建立直觉。
代码负责证明理解。
reference 负责检查正确性。
gate 决定是否进入 CPU inference / CUDA。
```

这条线的最终目的不是让简历上多一个“熟悉机器学习”，而是让你以后能够真正回答：

```text
模型在算什么？
数据放在哪里？
为什么结果正确？
瓶颈在哪里？
为什么这个优化有效？
```
