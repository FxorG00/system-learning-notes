# 吴恩达 2014 机器学习讲义：配套练习

> 版本：2026-09-23
>
> 配套正文：[ML.md](ML.md)
>
> 目标：用少量可验证练习把概念落到计算上，不把传统机器学习扩成第二条重型项目主线。

---

## 0. 这份练习怎样使用

每章只安排一个**核心练习**。它负责检查本章最重要的理解，不要求为了“练过”而重复抄公式、堆测试或重做已经在 `ai_theory/T*.md` 中完成的内容。

练习分成三档：

- **核心**：读完本章后最值得亲手完成的部分。
- **官方改编**：来自 Andrew Ng 课程作业目标，但统一使用 Python / NumPy；时间紧时可以只做核心。
- **进阶选做**：更接近 CS229 或完整算法实现，不阻塞系统主线、Mini Redis 和求职时间线。

当前进度是系统主线 Week11、AI Theory T1~T3 已通过，下一模块是 T4。因此：

```text
第 1~5 章：作为诊断题，已经会就快速通过
第 6~7 章：进入 T7~T8 时完成
第 8~9 章：进入 T10~T12 时完成
第 10~11 章：进入 T13 时完成
第 12~18 章：按兴趣和主线需要选做，不阻塞 T15~T24
```

建议把实现放在：

```text
ML/exercises/ch01/
ML/exercises/ch02/
...
```

这份文件不给标准答案。实现后验收的是结果与解释，不是是否长得像课程原代码。

---

## 1. 官方作业来源与采用方式

### 1.1 当前官方课程

Andrew Ng 当前的 [Machine Learning Specialization](https://www.deeplearning.ai/specializations/machine-learning/) 明确列出了这些 practice labs：

```text
Course 1 Week 2：Linear regression
Course 1 Week 3：Logistic regression
Course 2 Week 1：Neural networks
Course 2 Week 2：Neural network training
Course 2 Week 3：Advice for applying machine learning
Course 3 Week 1：Clustering、Anomaly detection
Course 3 Week 2：Collaborative filtering、Content-based filtering
```

这些是当前官方课程的练习方向，但 notebook 和 grader 依赖 Coursera 课程环境。本地练习吸收其目标，不复制受课程环境约束的 notebook。

### 1.2 2014 经典课原始编程作业

经典课程共有八套编程作业。原课程已经下线，下面使用的是课程原始 handout 的公开镜像目录：

| 原作业 | 主题 | 本讲义对应章节 |
|---|---|---|
| [ex1](https://github.com/fengdu78/Coursera-ML-AndrewNg-Notes/tree/master/code/ex1-linear%20regression) | Linear Regression | 第 2、4、5 章 |
| [ex2](https://github.com/fengdu78/Coursera-ML-AndrewNg-Notes/tree/master/code/ex2-logistic%20regression) | Logistic Regression / Regularization | 第 6、7 章 |
| [ex3](https://github.com/fengdu78/Coursera-ML-AndrewNg-Notes/tree/master/code/ex3-neural%20network) | Multi-class / Neural Network Forward | 第 8 章 |
| [ex4](https://github.com/fengdu78/Coursera-ML-AndrewNg-Notes/tree/master/code/ex4-NN%20back%20propagation) | Backpropagation | 第 9 章 |
| [ex5](https://github.com/fengdu78/Coursera-ML-AndrewNg-Notes/tree/master/code/ex5-bias%20vs%20variance) | Bias / Variance / Learning Curve | 第 10 章 |
| [ex6](https://github.com/fengdu78/Coursera-ML-AndrewNg-Notes/tree/master/code/ex6-SVM) | Support Vector Machine | 第 12 章 |
| [ex7](https://github.com/fengdu78/Coursera-ML-AndrewNg-Notes/tree/master/code/ex7-kmeans%20and%20PCA) | K-means / PCA | 第 13、14 章 |
| [ex8](https://github.com/fengdu78/Coursera-ML-AndrewNg-Notes/tree/master/code/ex8-anomaly%20detection%20and%20recommendation) | Anomaly Detection / Recommender | 第 15、16 章 |

这些目录托管在社区镜像中，host 不是 Coursera 官方站；其中 PDF 是经典课原始题面，Python 代码则是社区移植。我们只参考题面与数据，不直接阅读 solution。

### 1.3 CS229 只作进阶题库

Stanford CS229 的 [Problem Set 1](https://cs229.stanford.edu/summer2019/ps1.pdf) 与 [Problem Set 2](https://cs229.stanford.edu/summer2020/ps2.pdf) 更强调证明、概率建模和算法调试。它们适合以后加深 logistic regression、feature map、SVM 与 kernel，不纳入当前必做清单。

---

# 第一周练习：机器学习、线性回归与梯度下降

## 第 1 章：监督学习与无监督学习

### 核心练习：先判断“答案长什么样”

为下面每个任务写出三项：输入、希望得到的输出、学习类型。

```text
预测请求延迟
判断日志是不是异常
把用户自动分组
预测一段文本的下一个 token
根据历史评分推荐电影
把请求路由到不同模型实例
```

分类时至少使用这些词：`regression`、`classification`、`clustering`。遇到推荐、路由这种不完全落入单一类别的任务，要说明你选择的建模角度。

**验收：** 六个任务都有具体输入和输出；能够解释为什么“有没有 label”比任务名字更重要。

**官方对应：** 当前官方 Course 1 Week 1 的 supervised / unsupervised quizzes。经典课没有单独编程作业。

---

## 第 2 章：单变量线性回归

### 核心练习：让一条直线真的学会移动

自己生成一组近似满足 $y=2x+1$ 的数据，并加入少量噪声。只用 NumPy 完成：

1. 根据 $w,b$ 计算 prediction。
2. 计算 mean squared error。
3. 推导并实现 $w,b$ 的 gradient。
4. 从 $w=b=0$ 开始运行 gradient descent。
5. 画出数据点、初始直线和训练后直线。

**验收：** final loss 小于 initial loss；最终 $w,b$ 接近生成数据时使用的参数；能够解释一次 update 为什么必须同时使用旧 $w,b$ 计算出的 gradient。

**官方改编：** classic `ex1` 的 food-truck profit 单变量线性回归；当前官方 Course 1 Week 2 linear regression lab。

---

## 第 3 章：线性代数与 shape

### 核心练习：运行前先写 shape

在不运行代码的情况下推导：

```text
X: [8, 3]
w: [3]
b: scalar
y_hat = X @ w + b
```

回答：

1. `y_hat` 的 shape 是什么？
2. 哪个维度被 reduction？
3. `X * w` 与 `X @ w` 的 shape 和语义有什么不同？
4. 若把 $8$ 看作 batch，它为什么被保留下来？

再用 NumPy 验证每个判断，并增加一个故意不合法的 matmul case，记录完整异常类型。

**验收：** 预测与运行结果一致；能从“匹配维度被消掉、batch 维度被保留”解释答案。

**规划对齐：** 这是 T2/T3 的复检题。若已有代码和笔记能完整回答，不重复写新项目。

---

# 第二周练习：多变量线性回归与 NumPy

## 第 4 章：多变量线性回归

### 核心练习：比较缩放前后的训练路径

构造两个尺度差异明显的特征，例如面积在数千量级、卧室数在个位数。对同一数据分别运行：

```text
原始特征 + gradient descent
Z-score 后的特征 + gradient descent
np.linalg.lstsq 的最小二乘解
```

记录三组参数、loss curve 和最终 prediction。`lstsq` 用作结果参照，不要求参数在不同尺度下逐项相等。

**验收：** 能解释缩放为什么改变收敛路径，却不改变问题要表达的关系；gradient descent 与 `lstsq` 的 prediction 接近。

**官方改编：** classic `ex1` 的 housing price、feature normalization 与 normal equation；当前官方 Course 1 Week 2 practice lab。

---

## 第 5 章：从标量循环走向 NumPy

### 核心练习：同一个结果，两条实现路径

对同一批数据分别实现：

```text
Python for-loop 版本的 prediction 与 gradient
NumPy vectorized 版本的 prediction 与 gradient
```

先比较 exact shape，再用 `np.allclose` 比较 values。最后只做一个轻量 benchmark：固定数据、先 warmup、重复多次并报告 median。

**验收：** 两版数值一致；能够解释时间差主要来自哪里；不声称一次小 benchmark 就证明所有规模下 NumPy 都更快。

**规划对齐：** T1~T3 已经覆盖 ndarray、nbytes、matmul 与 broadcasting；已有同类证据时只做口头复检。

---

# 第三周练习：逻辑回归与正则化

## 第 6 章：逻辑回归

### 核心练习：从 score 得到概率和边界

使用二维二分类数据，自己实现 sigmoid、binary cross-entropy、gradient 和 prediction。训练后画出样本与 decision boundary。

额外检查两个极端 score，例如 $z=1000$ 与 $z=-1000$。实现需要避免直接对 $0$ 取 `log`，并在 note 中写明采用了哪种稳定处理。

**验收：** loss 能下降；gradient shape 正确；概率在 $[0,1]$；边界与样本分布大致吻合。

**官方改编：** classic `ex2` 第一部分；当前官方 Course 1 Week 3 logistic regression lab。

---

## 第 7 章：正则化

### 核心练习：亲眼观察 $\lambda$ 改变模型

为二维输入增加多项式特征，并分别使用：

```text
lambda = 0
一个适中的 lambda
一个很大的 lambda
```

比较训练 loss、验证 loss、参数 norm 和 decision boundary。不要只报告 accuracy。

**验收：** 能指出哪一组更像 overfit、哪一组更像 underfit；解释正则化为何通常不处罚 bias。

**官方改编：** classic `ex2` 第二部分；T13 会继续处理 generalization 与 regularization evidence。

---

# 第四周练习：神经网络前向传播

## 第 8 章：neuron、layer 与 forward

### 核心练习：让两层网络完成一次 forward

只用 NumPy 构造一个小网络：

```text
input_dim = 3
hidden_dim = 4
num_classes = 2
batch = 5
```

完成 linear transform、activation、第二个 linear transform 与 stable softmax。参数可以随机初始化，本章不训练。

**验收：** 每一步运行前先写 shape；最终 probability shape 为 `[5, 2]`；每行概率和接近 $1$；输入整体复制一份后，batch 维行为保持一致。

**官方改编：** classic `ex3` 的 neural network forward；当前官方 Course 2 Week 1 neural network lab。

**规划对齐：** T10 会用 `nn.Module` 重做同一条 forward 主线。这里保留 NumPy reference，不提前依赖 PyTorch。

---

# 第五周练习：反向传播与梯度检查

## 第 9 章：backpropagation

### 核心练习：让 analytic gradient 接受独立审判

先对这个最小计算图手算：

$$
z=wx+b,\qquad e=z-y,\qquad L=e^2
$$

再实现 forward、analytic gradient 和 centered finite difference。对 $w,b$ 分别比较 relative error，并尝试 $\varepsilon\in\{10^{-4},10^{-5},10^{-6}\}$。

通过后，再把同样方法用于第 8 章两层网络中的少量参数坐标，不需要全量检查。

**验收：** numerical oracle 不调用 analytic gradient；误差在合理 tolerance 内；能够解释 $\varepsilon$ 太大和太小各自带来的问题。

**官方改编：** classic `ex4` 的 backpropagation 与 gradient checking；当前官方 Course 2 Week 2 neural network training lab。

**规划对齐：** 第一部分直接对应 T4，PyTorch autograd 对照留给 T11~T12。

---

# 第六周练习：模型诊断与系统设计

## 第 10 章：bias、variance 与 learning curve

### 核心练习：先诊断，再开药

用一个可控制阶数的 polynomial regression 数据集，保存固定 train / validation / test split。比较低阶、中阶和高阶模型：

1. 记录 train 与 validation error。
2. 画 learning curve。
3. 判断主要问题是 high bias 还是 high variance。
4. 只根据诊断选择下一步：更多数据、增加容量或增强 regularization。

**验收：** test set 不参与选择阶数与 $\lambda$；结论能由曲线支持，而不是只写“看起来像”。

**官方改编：** classic `ex5`；当前官方 Course 2 Week 3 advice for applying machine learning lab。

---

## 第 11 章：error analysis 与 threshold

### 核心练习：accuracy 很高，系统仍可能没用

构造一个正类只占约 $1\%$ 的 prediction/label 数组。计算 confusion matrix、precision、recall 与 F1，并扫一组 threshold。

然后假设：

```text
漏报一个真实故障的代价 = 100
误报一个正常请求的代价 = 2
```

选择一个 threshold，并用总成本解释选择。

**验收：** 能解释“永远预测正常”为何 accuracy 很高却没有检测能力；选择由业务代价驱动。

**官方对应：** 当前官方 Course 2 Week 3 的 skewed datasets 与 ML development process。经典课没有独立编程作业。

**主线连接：** 以后 benchmark 也必须先定义 workload 和成功指标，不能只挑一个漂亮数字。

---

# 第七周练习：SVM 与 kernel

## 第 12 章：支持向量机

### 核心练习：观察 $C$ 与 $\sigma$ 怎样改变边界

本章不要求从头实现 SVM optimizer。使用经过验证的 library，在同一二维数据上比较：

```text
linear kernel，不同 C
RBF kernel，不同 C 与 gamma
```

画出 decision boundary，并记录 train/validation accuracy。把 `gamma` 与讲义中的 Gaussian kernel $\sigma$ 联系起来说明。

**验收：** 能从边界形状解释过拟合与欠拟合；没有把 SVM 扩成当前主线项目。

**官方改编：** classic `ex6`。想继续加深时再看 CS229 Problem Set 2 的 SVM/kernel 题。

---

# 第八周练习：聚类与降维

## 第 13 章：K-means

### 核心练习：让 objective 每轮不增加

实现 assignment step 与 centroid update，对二维点集运行 K-means。固定 random seed，记录每轮 objective。

至少处理一个边界：某个 cluster 本轮没有任何样本时，你选择保留旧 centroid，还是重新初始化？把策略写进 note。

**验收：** 正常数据上 objective 单调不增加；不同初始化可能得到不同结果；最终图能显示 points、cluster 与 centroids。

**官方改编：** classic `ex7` 第一部分；当前官方 Course 3 Week 1 clustering lab。

---

## 第 14 章：PCA

### 核心练习：压缩后到底保留了多少

生成具有明显相关性的二维或三维数据。完成：

```text
mean normalization
SVD
project 到 k 维
recover 回原空间
计算 reconstruction error 与 retained variance ratio
```

**验收：** 画出原数据与恢复结果；能解释为什么必须先中心化；能够区分 PCA projection 与 linear regression prediction。

**官方改编：** classic `ex7` 第二部分。当前官方 specialization 讲 PCA，但没有把它作为独立必做 lab。

---

# 第九周练习：异常检测与推荐系统

## 第 15 章：异常检测

### 核心练习：让 validation set 决定阈值

在主要由正常样本组成的训练集上估计每个 feature 的 Gaussian parameters，再计算 validation samples 的 $p(x)$。扫描 $\varepsilon$，使用 validation labels 选择 F1 最好的阈值。

**验收：** training data 只负责估计分布；threshold 由 validation evidence 选择；test 只做最终一次评价。

**官方改编：** classic `ex8` 第一部分；当前官方 Course 3 Week 1 anomaly detection lab。

---

## 第 16 章：推荐系统

### 核心练习：补全一个很小的评分矩阵

给定一个带 missing entries 的小型 user-item matrix：

1. 只在 observed entries 上计算 collaborative-filtering cost。
2. 加入 regularization。
3. 推导 item vectors 与 user vectors 的 gradients。
4. 用 finite difference 抽查几个坐标。
5. 训练后预测 missing entries，并给一个用户输出 top-3 items。

**验收：** missing entry 不被当成评分 $0$；analytic gradient 通过 numerical check；能解释 cold start 为什么仍然存在。

**官方改编：** classic `ex8` 第二部分；当前官方 Course 3 Week 2 collaborative filtering lab。

**规划边界：** 这只是 embedding table 的第一层直觉，不启动亿级向量检索系统。

---

# 第十周练习：大规模训练与流水线

## 第 17 章：batch、SGD 与 mini-batch

### 核心练习：同一个模型，三种更新粒度

在同一线性或逻辑回归数据上实现：

```text
full-batch gradient descent
SGD
mini-batch gradient descent
```

固定初始化和数据顺序策略，记录 wall time、updates/s、每个 epoch 的 loss，以及到达同一 loss threshold 所需时间。

**验收：** 不只比较“跑完用了多久”；能解释 SGD 曲线为什么更 noisy，以及 mini-batch 为什么同时影响 optimization 和 hardware utilization。

**官方对应：** 经典课 large-scale ML 章节没有独立编程作业。本练习由 T23 的 benchmark 纪律改编，当前只做 CPU/NumPy 小实验。

---

## 第 18 章：OCR pipeline 与 ceiling analysis

### 核心练习：下一周到底该优化谁

假设一个 OCR pipeline 当前 end-to-end accuracy 为 $82\%$：

| 临时替换成 perfect output 的阶段 | 新 accuracy |
|---|---:|
| detection | $90\%$ |
| segmentation | $84\%$ |
| recognition | $96\%$ |

回答：

1. 每个阶段的 ceiling gain 是多少？
2. 下一步优先投入哪一段？
3. 为什么不能把三个 gain 直接相加，声称最终能达到某个准确率？
4. 若 detection 延迟占全链路 $70\%$，正确率优先级和性能优先级是否相同？

**验收：** 给出一页以内的决策记录，分别写清 correctness bottleneck 与 performance bottleneck。

**官方对应：** 经典课 Photo OCR / ML pipeline 章节没有独立编程作业；这是按系统主线的 evidence 与 profiling 思维补出的练习。

---

# 收口练习

## 第 19 章：课程最终产出

不要再实现第十一个传统算法。选择前面一个已经完成的模型，整理成一个小型 reference：

```text
README：问题、数据、模型、shape、运行方式
reference implementation：清楚优先
tests：至少一个正常 case、一个边界 case
evidence：loss/metric 曲线或图
limits：它能证明什么、不能证明什么
AI Infra connection：主要 compute、memory 和 batching object 是什么
```

**验收：** 陌生人可以运行；你能在五分钟内讲清从 input 到 metric 的完整链；不把它包装成简历主项目。

## 第 20 章：与当前规划对齐

在 `ML_exercise_progress.md` 中只维护一张表：章节、状态、证据路径、对应 T module。没有完成的选做题写 `deferred`，不要假装完成，也不要让它阻塞系统主线。

## 第 21 章：口头自检

直接回答 [ML.md 第 21 节](ML.md#21-完整自检) 的十二个问题。每题能用自己的例子串出因果链即可，不要求重复写长答案；说不清的题再回到对应练习。

---

## 最终边界

这套练习服务于三件事：

```text
把公式变成可运行 reference
用独立 evidence 检查实现
建立以后理解 PyTorch / Transformer / inference workload 的地基
```

它不改变当前优先级：系统主线继续推进 HTTP Server -> Mini Redis；AI Theory 继续 T4 -> T24；传统机器学习练习按对应 T module 定向完成，不单独抢占一整条主线。
