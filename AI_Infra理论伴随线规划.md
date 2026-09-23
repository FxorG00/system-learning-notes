# AI Infra 理论伴随线规划

> 版本：2026-09-20，T3 进度同步与 serving 生态校准版
> 适用对象：FxorG，中山大学计算机科学与技术专业；系统主线已完成 Week10、正在 Week11，理论线 T1~T3 已通过、下一模块为 T4
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

### 2.1 必须具备并映射到 AI 的知识

```text
Python / NumPy
线性代数在 Tensor shape / matmul / transformation 中的映射
微积分在 gradient / backpropagation 中的映射
概率统计在 softmax / loss / sampling 中的映射
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

### 2.5 用户当前数学基础与课程分工

用户已明确：

```text
学校微积分：基础扎实，不需要伴随线从头重学
学校线性代数：基础扎实，不需要再完整刷 MIT 18.06 或 3Blue1Brown
学校概率论：属于正式课程，用户计划配合一门 B 站大学数学网课完整学完
```

因此从现在起，不再把 T2、T4、T5 理解成三门数学补习课。三类来源的职责是：

```text
学校课程 / 概率网课：负责系统定义、公式、习题和考试深度
AI Theory T module：负责把已学数学映射到 NumPy/PyTorch、Tensor shape、loss、sampling 和性能
代码 gate：负责验证“会做数学题”已经转化为“会解释模型计算”
```

具体调速：

```text
线代或微积分 checkpoint 能口述并手算
-> 不看重复视频
-> 直接完成 NumPy / finite-difference / shape 验证

概率论学校尚未讲到某个概念
-> T5/T6 可以等待学校进度，或只补当前代码必需的最小概念
-> 不同时再开 Harvard Statistics 110 全课

学校已经学完且掌握
-> T module 只做 AI application mapping，不抄第二份数学笔记
```

这里的“掌握”不按成绩猜测，而用很短的 diagnostic gate 判断；若能手算、解释并完成对应代码，就直接通过数学部分。

---

## 3. 和系统主线怎样并行

### 3.1 当前起点与术语修正

当前系统主线位置：

```text
Week1 ~ Week10 已完成
当前：Week11 HTTP Server V1
后续：Mini Redis -> 项目证据与投递
```

理论线从 `T1` 开始。文件继续使用 `T1~T24` 编号，但从现在起：

```text
T = Theory module
T 不等于一个自然周
```

简单模块可能 3~5 天通过；T17、T18、T21、T24 可能分别需要 2~4 个自然周。不能再用“24 周、每周 3 小时”掩盖真实工作量。

### 3.2 每日投入与可持续周预算

用户给出的真实投入：

```text
AI 理论线：每天 30~60 分钟
系统主线：每天至少 3 小时
```

折算为：

```text
AI 名义上限：每周 3.5~7 小时
AI 可持续计划值：每周 4~6 小时
考试、主线故障或休息会使个别周低于计划值
```

推荐把一个自然周拆成短块，而不是等某一天硬学 3 小时：

```text
2 天：教程主线、术语、精确视频
2~3 天：独立 coding
1 天：错误路径、shape/value/tolerance 验证
1 天：note、口述和缓冲；疲劳时可以只复盘或休息
```

每天只有一个 30~60 分钟块，不另开七份 AI daily。每个 T module 仍只有一份 `Tn.md`。

### 3.3 真实总工时

按当前产出和通过标准，合理估算不是 72 小时：

| 阶段 | 范围 | 估算有效工时 | 说明 |
|---|---|---:|---|
| Phase 1 | T1~T8 | 30~45h | 数学基础扎实，可用 diagnostic 跳过重复理论 |
| Phase 2 求职核心 | T9~T13、T15~T16 | 45~60h | PyTorch、autograd、MLP、token/mask、attention |
| Phase 2 可延期 | T14 | 6~10h | CNN/ResNet 对 LLM inference 不是硬前置 |
| Phase 3 | T17~T24 | 65~90h | decoder、KV Cache、batching、benchmark、最终整合 |

总量约：

```text
150~210 个有效小时
```

按每周平均 4~6 小时，需要约 25~53 个自然周，也就是大约 6~12 个月。`2027-03-31` 是进取目标：它要求多数周接近 5.5~7 小时、数学模块通过 diagnostic 加速，并且不发生长期停摆；若实际长期接近每天 30 分钟，T24 应顺延到 2027 年第二季度，不能靠删 correctness gate 伪造按时完成。这个数字是容量估算，不是要求每天打卡满额。

### 3.4 系统 milestone 与 T module 的硬锚点

| 系统主线出口 | AI 理论至少到达 | 目标日期 | 当时应有的 AI 证据 |
|---|---|---|---|
| Week9 | T1 | 2026.08 末~09 初 | `numpy_basics.py`，能解释 shape/dtype/nbytes |
| Week10 | T3 | 2026.09 | matmul/broadcast reference 与 shape 推导 |
| Week11 | T6 | 2026.09 末 | finite difference、概率映射、stable softmax |
| Week12 | T8 / Theory Gate 1 | 2026.10 上半 | NumPy linear/softmax model 与 ML workflow |
| Week13 | T10 | 2026.10 下半 | Tensor layout 与 Module inference |
| Week14 | T12 | 2026.11 | autograd + MLP training/inference flow |
| Week15 | T13 + T15~T16 | 2026.12 上半 | token/mask 与 single-head attention reference |
| Week16 | T16 必达；T17~T18 stretch | 2026.12 下半 | 简历不等待 T24；有余力完成 decoder forward |

这里的“至少到达”是进度控制锚点，不是主线代码的编译依赖。若 Week10 已结束而 T3 未完成，必须在进度记录中写明欠账和补齐日期，不能把 T 线静默冻结。

### 3.5 求职日期锚点

```text
2026.10.15 前：T1~T8，Theory Gate 1
2026.12.15 前：T1~T13 + T15~T16，T14 允许延期
2027.01 第一轮投递：T17~T18 作为 AI Infra 冲刺项，不等待 T24
2027.02：T19~T21
2027.03：进取目标，T22~T24，形成 tiny_transformer_reference
2027.Q2：若周均只有约 4h，这是 T24 的正常后备窗口，不影响 2027.01 首轮投递
```

第一次投递时：

```text
后台/C++ Infra：Mini Redis 是主项目，AI 线是差异化证据
AI 业务基础设施：T1~T16 证明 workload literacy
推理引擎/CUDA：仍是冲刺，T18 也不等于具备 kernel 经验
```

### 3.6 延期与删减规则

如果某个锚点落后超过两个自然周，按这个顺序处理：

```text
1. 先删重复视频、QA 和已经由学校掌握的理论讲解
2. 保留独立代码、关键 mechanism 和 correctness gate
3. 延期 T14 CNN/ResNet，不删除 T15~T18
4. T13 只保留一次清楚的 overfit/regularization observation，不扩展调参
5. T24 允许拆成 2~4 周，不压缩成一次赶工
6. 仍然落后时，移动 T19~T24 日期；不牺牲 Mini Redis 和第一次投递
```

不可删的桥梁：

```text
T3 matmul/shape
T6 stable softmax
T9 Tensor/layout
T11 autograd
T16 single-head attention
T18 decoder-only forward
T21 KV Cache
T23 correctness/benchmark
```

考试周、睡眠不足或主线出现 correctness blocker 时可以临时降载，但下一周必须重新排期。理论线可以延期，不能没有账本地消失。

---

## 4. 学习方法与固定产出

每个 T module 固定产出：

```text
1. 一份短 note：只记录真正不熟的概念
2. 一个可以运行的 .py / notebook
3. 至少一组 shape / value / tolerance 验证
4. 一段“这和 AI Infra 有什么关系”的解释
```

每个 T module 开始前，再单独生成一份 `Tn.md` 教程。下面只定义 AI Theory 教程的写法，不定义或修改系统主线 `daily.md` 的编写规则：

```text
AI Theory Tn.md
-> 概念理解、数学映射和数据流优先
-> 前期默认约 70% 讲解、30% 手推/实验/coding
-> 默认写成一份从头可连续阅读的自包含讲义
-> 逐个 T 判断是否存在值得独立撞一次的认知墙，不统一删除或统一套用 Round / Reading Gate
```

视频与官方文档承担校准、补充或第二解释源，不能用“去看第几 P”代替教程正文；反过来，也不应把一份很长的外部资料变成必读前置，再让用户猜它应该插在教程哪一段。

理论线每个概念应在主线第一次需要它的位置直接讲清楚：

```text
当前问题
-> 新对象/新术语
-> 最小数值或 shape 例子
-> 完整推导与因果链
-> 紧邻的小实验
-> 自然进入下一个概念
```

外部链接放在对应概念之后，标明“查证 / 选看 / 延伸”；除非某一课程片段确实比文字讲义更适合承担主讲，否则不把跳出文档阅读设成必经闸门。

### Round / Reading Gate 的使用判定

闸门是教学工具，不是理论线的固定格式。生成每份 `Tn.md` 前，先判断本 T 是否存在一个适合“先独立尝试、再揭示机制”的真实认知墙。

```text
没有真实认知墙
-> 使用连续讲义
-> 概念讲清后紧邻小实验
-> 不为了保持系列外观制造 Round

存在真实认知墙
-> 在必要前置讲解之后设置一次有目的的 Round1
-> 用户先预测、设计或实现
-> Reading Gate 后才解释关键机制、常见分支和改进方向
-> 根据用户真实 code / note / 问题定向编排后续内容
```

“真实认知墙”至少满足下面一项：

```text
1. 仅凭已有知识可以开始，但第一次实现很可能暴露一个值得讨论的模型偏差
2. 运行前 prediction 与运行后 evidence 的差异本身就是本 T 的核心知识
3. 存在有意义的设计选择，需要先看到用户自己的取舍
4. 提前阅读后文会直接泄露主练习的关键算法、shape rule 或 correctness strategy
```

例如：T1 的基础 ndarray/shape/dtype 以建立地形图为主，不必设置 Round；T3 的 broadcasting、batch matmul 和运行前 shape prediction 存在真实认知墙，应保留 `Round1 -> review -> Round2/3`。

一旦使用闸门，闸门前必须让用户具备独立开工能力：

```text
必须给：程序用途、文件名、输入/输出、public API、必要前置语法、边界、可观察的完成标准
必须保留：实现组织、关键算法、核心因果链、应由第一次尝试暴露的错误与设计选择
禁止：嘴上说“不给答案”，随后用伪代码、职责清单或逐步提示把答案完整拼出来
```

闸门后的内容不能机械预制成错误全集。Round1 正式检阅后，应结合用户的实现、笔记、提问和设计取舍，重新核对并定向润色后续部分。

固定顺序：

```text
读取总规划、MEMORY、上一 T module 结果
-> 生成完整 Tn.md
-> 把本 T 的必学知识编排成一条连续解释链
-> 在相关位置列出精确视频/官方资料，默认作为补充
-> 用户完成手推、最小实验和独立产出
-> 根据真实 note、代码和问题补强薄弱概念
-> 验收并同步 MEMORY 进度
```

视频基准只使用用户指定的两条课程线：

- 吴恩达：[机器学习课程合集 `BV1owrpYKEtP`](https://www.bilibili.com/video/BV1owrpYKEtP)
- 李沐：[“跟李沐学AI”账号内搜索《动手学深度学习》](https://space.bilibili.com/1567748478/search?keyword=%E5%8A%A8%E6%89%8B)

吴恩达 2014 传统机器学习课程另有一份本地连续自学讲义：[ML/ML.md](ML/ML.md)，以及按经典 `ex1~ex8` 组织的中文实践教程 [ML/ML_配套练习.md](ML/ML_配套练习.md)。练习不再按知识章节散列成抽象题目，而是逐套交付真实问题、最终程序、本地数据路径、数据字段、实现阶段、原题检查值和图像 evidence。Python starter notebooks、Data、Figures 与原始题面保存在本机 `ML/official_assignments/`，第三方材料不进入仓库提交。它们不新增一条必须逐周打卡的主线，也不替代 `Tn.md` 的 NumPy/PyTorch code gate；进入 T4~T13 时按当前概念调用相应作业，不要求暂停系统主线连续做完八套。

映射规则：

```text
吴恩达课程：使用 P 号 + 分集标题定位
李沐课程：使用官方章节号 + 标题 + 单课链接定位
没有直接对应视频：明确写“本周无强制视频”，由 Tn.md 和官方文档承担
一个概念已经由学校课程掌握：视频可作为定位资料，不要求重复播放
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

理论笔记与对应教程放在一起：

```text
ai_theory/Tn/Tn_note.md
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

当某个 T module 的固定产出是可执行程序时，还要有最小工程验收纪律：

```text
成功路径：明确打印/记录 PASS，exit status == 0
失败路径：unexpected mismatch / non-finite / shape error / exception 可定位，exit status != 0
数值比较：给出当前 case 的具体 dtype、epsilon、rtol/atol，不写“差不多相等”
证据边界：说明这组 oracle 能证明什么、不能证明什么
```

这不等于把系统主线的 GoogleTest、CTest、sanitizer、压力测试和长 checklist 全部搬进理论线。理论产出按风险选择最小而明确的 oracle；纯手推 module 不为 exit code 制造空壳程序。

---

# 第一阶段：Python / NumPy 与数学到模型计算的映射

> 周次：T1~T8
> 预算：合计约 30~45 个有效小时；目标 2026-10-15 前通过 Theory Gate 1
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

### 对应视频

```text
本周无强制视频。
```

- 吴恩达 [P5 `jupyter笔记本`](https://www.bilibili.com/video/BV1owrpYKEtP?p=5) 只对应 notebook 使用环境，不负责 `ndarray` 语义。
- 李沐 [04 `数据操作 + 数据预处理`](https://www.bilibili.com/video/BV1CV411Y7i4/) 使用的是 PyTorch Tensor，统一留到 T9，不提前混入 T1。
- T1 继续以 NumPy stable 官方 beginner guide 为主资料；环境 baseline 统一记录在 `ai_theory/ENVIRONMENT.md`，不由宿主机的旧 system Python 决定。

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

## T2：向量、矩阵与线性变换的 AI 映射

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

本节默认用户已经完成学校线代训练。先做手算 diagnostic；能够解释 linear combination、basis 和 matrix-vector multiplication 时，直接进入 NumPy 代码，不重复看完整线代视频。

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

### 对应视频

- 李沐：[05 `线性代数`](https://www.bilibili.com/video/BV1eK4y1U7Qy/) 中的“线性代数”“线性代数实现”“按特定轴求和”。
- 吴恩达：[P17 `向量化（第一部分）`](https://www.bilibili.com/video/BV1owrpYKEtP?p=17)、[P18 `向量化（第二部分）`](https://www.bilibili.com/video/BV1owrpYKEtP?p=18)。

学校线代 diagnostic 已通过时，这些是对应关系，不是重复刷课要求。

### 代码产出

```text
vector_matrix.py
```

用 NumPy 验证手算结果，并检查 input/output shapes。

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

### 对应视频

- 李沐：[06 `矩阵计算`](https://www.bilibili.com/video/BV1eZ4y1w7PY/)；05 的“按特定轴求和”作为 broadcasting/reduction 前置。
- 吴恩达：[P17 `向量化（第一部分）`](https://www.bilibili.com/video/BV1owrpYKEtP?p=17)、[P18 `向量化（第二部分）`](https://www.bilibili.com/video/BV1owrpYKEtP?p=18)、[P19 `多重线性回归的梯度下降`](https://www.bilibili.com/video/BV1owrpYKEtP?p=19)。
- 需要再次从神经网络语境看 matmul 时，对应 [P52 `矩阵乘法`](https://www.bilibili.com/video/BV1owrpYKEtP?p=52)、[P53 `矩阵乘法规则`](https://www.bilibili.com/video/BV1owrpYKEtP?p=53)、[P54 `矩阵乘法代码`](https://www.bilibili.com/video/BV1owrpYKEtP?p=54)。

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

## T4：gradient 与 chain rule 的计算图映射

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

本节默认用户已经掌握学校微积分。重点不是重学求导规则，而是把：

```text
复合函数
-> computation graph
-> local derivative
-> reverse accumulation
-> parameter gradient
```

串成后续 autograd/backpropagation 可使用的模型。手推通过后可跳过微积分视频，直接做 finite difference 验证。

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

### 对应视频

- 李沐：[07 `自动求导`](https://www.bilibili.com/video/BV1KA411N7Px/) 中的“自动求导”“自动求导实现”。
- 吴恩达：[P67 `什么是导数（可选）`](https://www.bilibili.com/video/BV1owrpYKEtP?p=67)、[P68 `计算图（可选）`](https://www.bilibili.com/video/BV1owrpYKEtP?p=68)、[P69 `更大神经网络示例（可选）`](https://www.bilibili.com/video/BV1owrpYKEtP?p=69)。

T4 仍以手推和 finite difference 为 gate；视频不替代计算。

### 代码产出

```text
finite_difference_gradient.py
```

用 finite difference 检查手推 gradient。

### 通过标准

能解释 gradient 是什么、shape 是什么、为什么 chain rule 支撑 backpropagation；能独立写 analytic 与 forward-only numerical 两条路径，并用具体 tolerance、finite/shape/input-non-mutation invariants 给出明确 PASS/failure。

---

## T5：学校概率论到模型概率的接口

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

完整概率论由学校课程和用户选择的 B 站大学数学网课承担。T5 不另起一门平行概率课，只检查这些概念能否用于描述 model output、categorical sampling 和 expected value。

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

### 对应视频

```text
两条基准课程中没有一组能够替代学校概率论的直接对应章节，T5 不强制追加视频。
```

吴恩达 [P109 `高斯（正态）分布`](https://www.bilibili.com/video/BV1owrpYKEtP?p=109) 只对应 Gaussian 的应用片段，不承担 T5 的条件概率、随机变量、期望和方差主线。

### 代码产出

```text
discrete_probability.py
```

模拟 coin / categorical distribution，比较理论 expectation 与 sample mean。

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

### 对应视频

- 李沐：[09 `Softmax 回归 + 损失函数 + 图片分类数据集`](https://www.bilibili.com/video/BV1K64y1Q7wu/) 中的“Softmax 回归”“损失函数”“从零开始实现”；[14 `数值稳定性 + 模型初始化和激活函数`](https://www.bilibili.com/video/BV1u64y1i75a/) 中的“数值稳定性”。
- 吴恩达：[P60 `多类别`](https://www.bilibili.com/video/BV1owrpYKEtP?p=60)、[P61 `Softmax`](https://www.bilibili.com/video/BV1owrpYKEtP?p=61)、[P62 `带 Softmax 输出的神经网络`](https://www.bilibili.com/video/BV1owrpYKEtP?p=62)、[P63 `Softmax 的改进实现`](https://www.bilibili.com/video/BV1owrpYKEtP?p=63)。

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

### 对应视频

- 李沐：[08 `线性回归 + 基础优化算法`](https://www.bilibili.com/video/BV1PX4y1g7KC/) 中的“线性回归”“基础优化算法”“从零开始实现”“简洁实现”。
- 吴恩达线性回归模型：[P6 `线性回归模型`](https://www.bilibili.com/video/BV1owrpYKEtP?p=6)、[P7 `成本函数及其直觉`](https://www.bilibili.com/video/BV1owrpYKEtP?p=7)、[P8 `可视化成本函数`](https://www.bilibili.com/video/BV1owrpYKEtP?p=8)、[P9 `可视化示例`](https://www.bilibili.com/video/BV1owrpYKEtP?p=9)。
- 吴恩达梯度下降：[P10 `梯度下降`](https://www.bilibili.com/video/BV1owrpYKEtP?p=10)、[P11 `实现梯度下降`](https://www.bilibili.com/video/BV1owrpYKEtP?p=11)、[P12 `梯度下降直觉`](https://www.bilibili.com/video/BV1owrpYKEtP?p=12)、[P13 `学习率`](https://www.bilibili.com/video/BV1owrpYKEtP?p=13)、[P14 `线性回归的梯度下降`](https://www.bilibili.com/video/BV1owrpYKEtP?p=14)、[P15 `运行梯度下降`](https://www.bilibili.com/video/BV1owrpYKEtP?p=15)。
- 吴恩达多特征与收敛：[P16 `多特征`](https://www.bilibili.com/video/BV1owrpYKEtP?p=16)、[P17 `向量化（第一部分）`](https://www.bilibili.com/video/BV1owrpYKEtP?p=17)、[P18 `向量化（第二部分）`](https://www.bilibili.com/video/BV1owrpYKEtP?p=18)、[P19 `多重线性回归的梯度下降`](https://www.bilibili.com/video/BV1owrpYKEtP?p=19)、[P20 `特征缩放（第一部分）`](https://www.bilibili.com/video/BV1owrpYKEtP?p=20)、[P21 `特征缩放（第二部分）`](https://www.bilibili.com/video/BV1owrpYKEtP?p=21)、[P22 `检查梯度下降是否收敛`](https://www.bilibili.com/video/BV1owrpYKEtP?p=22)、[P23 `选择学习率`](https://www.bilibili.com/video/BV1owrpYKEtP?p=23)。

T7 的 NumPy 手写实现仍是主产出，不复制课程 framework lab。

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

### 对应视频

- 吴恩达逻辑回归：[P26 `动机`](https://www.bilibili.com/video/BV1owrpYKEtP?p=26)、[P27 `逻辑回归`](https://www.bilibili.com/video/BV1owrpYKEtP?p=27)、[P28 `决策边界`](https://www.bilibili.com/video/BV1owrpYKEtP?p=28)、[P29 `逻辑回归的成本函数`](https://www.bilibili.com/video/BV1owrpYKEtP?p=29)、[P30 `简化后的逻辑回归成本函数`](https://www.bilibili.com/video/BV1owrpYKEtP?p=30)、[P31 `梯度下降实现`](https://www.bilibili.com/video/BV1owrpYKEtP?p=31)。
- 吴恩达 regularization：[P32 `过拟合问题`](https://www.bilibili.com/video/BV1owrpYKEtP?p=32)、[P33 `解决过拟合`](https://www.bilibili.com/video/BV1owrpYKEtP?p=33)、[P34 `带正则化的成本函数`](https://www.bilibili.com/video/BV1owrpYKEtP?p=34)、[P35 `正则化线性回归`](https://www.bilibili.com/video/BV1owrpYKEtP?p=35)、[P36 `正则化逻辑回归`](https://www.bilibili.com/video/BV1owrpYKEtP?p=36)。
- 吴恩达 evaluation：[P70 `决定下一步尝试什么`](https://www.bilibili.com/video/BV1owrpYKEtP?p=70)、[P71 `模型评估`](https://www.bilibili.com/video/BV1owrpYKEtP?p=71)、[P72 `模型选择与训练/交叉验证/测试集`](https://www.bilibili.com/video/BV1owrpYKEtP?p=72)、[P73 `诊断偏差与方差`](https://www.bilibili.com/video/BV1owrpYKEtP?p=73)、[P74 `正则化与偏差方差`](https://www.bilibili.com/video/BV1owrpYKEtP?p=74)、[P75 `建立基准性能水平`](https://www.bilibili.com/video/BV1owrpYKEtP?p=75)、[P76 `学习曲线`](https://www.bilibili.com/video/BV1owrpYKEtP?p=76)、[P77 `决定下一步尝试什么（再谈）`](https://www.bilibili.com/video/BV1owrpYKEtP?p=77)、[P78 `偏差、方差与神经网络`](https://www.bilibili.com/video/BV1owrpYKEtP?p=78)、[P79 `ML 开发迭代循环`](https://www.bilibili.com/video/BV1owrpYKEtP?p=79)、[P80 `错误分析`](https://www.bilibili.com/video/BV1owrpYKEtP?p=80)、[P83 `ML 项目完整周期`](https://www.bilibili.com/video/BV1owrpYKEtP?p=83)。
- 李沐：[09 `Softmax 回归 + 损失函数 + 图片分类数据集`](https://www.bilibili.com/video/BV1K64y1Q7wu/)；[11 `模型选择 + 过拟合和欠拟合`](https://www.bilibili.com/video/BV1kX4y1g7jp/) 中的“模型选择”“过拟合和欠拟合”。

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
> 预算：T9~T13、T15~T16 合计约 45~60h；T14 另约 6~10h，可延期
> 求职锚点：2026-12-15 前至少完成 T1~T13 + T15~T16
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

### 对应视频

- 李沐：[04 `数据操作 + 数据预处理`](https://www.bilibili.com/video/BV1CV411Y7i4/) 中的“数据操作”“数据操作实现”。这是该视频第一次作为正式主线使用。
- 吴恩达本合集没有讲 Tensor layout/stride 的直接对应分集，本周不强行配吴恩达视频。
- API 和 stride 的准确语义继续用 [PyTorch 官方 Learn the Basics](https://docs.pytorch.org/tutorials/beginner/basics/) 与 API docs 校准。

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

### 对应视频

- 李沐：[16 `PyTorch 神经网络基础`](https://www.bilibili.com/video/BV1AK4y1P7vs/) 中的“模型构造”“参数管理”“自定义层”“读写文件”。
- 吴恩达 forward/inference 对应：[P45 `代码中的推理`](https://www.bilibili.com/video/BV1owrpYKEtP?p=45)、[P46 `TensorFlow 中的数据`](https://www.bilibili.com/video/BV1owrpYKEtP?p=46)、[P47 `构建神经网络`](https://www.bilibili.com/video/BV1owrpYKEtP?p=47)、[P48 `单层前向传播`](https://www.bilibili.com/video/BV1owrpYKEtP?p=48)、[P49 `前向传播通用实现`](https://www.bilibili.com/video/BV1owrpYKEtP?p=49)。这些不负责 PyTorch `Module` API。

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

### 对应视频

- 李沐：[07 `自动求导`](https://www.bilibili.com/video/BV1KA411N7Px/) 全部三节，重点对应 PyTorch autograd 代码。
- 吴恩达：[P67 `什么是导数（可选）`](https://www.bilibili.com/video/BV1owrpYKEtP?p=67)、[P68 `计算图（可选）`](https://www.bilibili.com/video/BV1owrpYKEtP?p=68)、[P69 `更大神经网络示例（可选）`](https://www.bilibili.com/video/BV1owrpYKEtP?p=69)。

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

### 对应视频

- 李沐：[10 `多层感知机 + 代码实现`](https://www.bilibili.com/video/BV1hh411U7gn/)；[14 `数值稳定性 + 模型初始化和激活函数`](https://www.bilibili.com/video/BV1u64y1i75a/) 中的“模型初始化和激活函数”。
- 吴恩达 neural-network object/forward：[P38 `欢迎来到深度学习部分`](https://www.bilibili.com/video/BV1owrpYKEtP?p=38)、[P39 `神经元与大脑`](https://www.bilibili.com/video/BV1owrpYKEtP?p=39)、[P40 `需求预测`](https://www.bilibili.com/video/BV1owrpYKEtP?p=40)、[P41 `图像识别示例`](https://www.bilibili.com/video/BV1owrpYKEtP?p=41)、[P42 `神经网络层`](https://www.bilibili.com/video/BV1owrpYKEtP?p=42)、[P43 `更复杂的神经网络`](https://www.bilibili.com/video/BV1owrpYKEtP?p=43)、[P44 `推理：预测与前向传播`](https://www.bilibili.com/video/BV1owrpYKEtP?p=44)。
- 吴恩达 code/activation：[P45 `代码中的推理`](https://www.bilibili.com/video/BV1owrpYKEtP?p=45)、[P46 `TensorFlow 中的数据`](https://www.bilibili.com/video/BV1owrpYKEtP?p=46)、[P47 `构建神经网络`](https://www.bilibili.com/video/BV1owrpYKEtP?p=47)、[P48 `单层前向传播`](https://www.bilibili.com/video/BV1owrpYKEtP?p=48)、[P49 `前向传播通用实现`](https://www.bilibili.com/video/BV1owrpYKEtP?p=49)、[P57 `Sigmoid 激活替代`](https://www.bilibili.com/video/BV1owrpYKEtP?p=57)、[P58 `选择激活函数`](https://www.bilibili.com/video/BV1owrpYKEtP?p=58)、[P59 `为什么需要激活函数`](https://www.bilibili.com/video/BV1owrpYKEtP?p=59)。

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

### 对应视频

- 李沐：[11 `模型选择 + 过拟合和欠拟合`](https://www.bilibili.com/video/BV1kX4y1g7jp/)、[12 `权重衰退`](https://www.bilibili.com/video/BV1UK4y1o7dy/)、[13 `丢弃法`](https://www.bilibili.com/video/BV1Y5411c7aY/)。
- 吴恩达 regularization：[P32 `过拟合问题`](https://www.bilibili.com/video/BV1owrpYKEtP?p=32)、[P33 `解决过拟合`](https://www.bilibili.com/video/BV1owrpYKEtP?p=33)、[P34 `带正则化的成本函数`](https://www.bilibili.com/video/BV1owrpYKEtP?p=34)、[P35 `正则化线性回归`](https://www.bilibili.com/video/BV1owrpYKEtP?p=35)、[P36 `正则化逻辑回归`](https://www.bilibili.com/video/BV1owrpYKEtP?p=36)。
- 吴恩达 diagnosis：[P71 `模型评估`](https://www.bilibili.com/video/BV1owrpYKEtP?p=71)、[P72 `模型选择与训练/交叉验证/测试集`](https://www.bilibili.com/video/BV1owrpYKEtP?p=72)、[P73 `诊断偏差与方差`](https://www.bilibili.com/video/BV1owrpYKEtP?p=73)、[P74 `正则化与偏差方差`](https://www.bilibili.com/video/BV1owrpYKEtP?p=74)、[P75 `建立基准性能水平`](https://www.bilibili.com/video/BV1owrpYKEtP?p=75)、[P76 `学习曲线`](https://www.bilibili.com/video/BV1owrpYKEtP?p=76)、[P77 `决定下一步尝试什么（再谈）`](https://www.bilibili.com/video/BV1owrpYKEtP?p=77)、[P78 `偏差、方差与神经网络`](https://www.bilibili.com/video/BV1owrpYKEtP?p=78)、[P79 `ML 开发迭代循环`](https://www.bilibili.com/video/BV1owrpYKEtP?p=79)、[P80 `错误分析`](https://www.bilibili.com/video/BV1owrpYKEtP?p=80)。

### 通过标准

不能只写“加 dropout 防止过拟合”；要能说明实验中观察到了什么，以及结果不能推广到哪里。

---

## T14：CNN 与 ResNet forward 第一层（可延期）

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

时间边界：T14 对 LLM inference 不是硬前置。若 2026 年 12 月求职锚点受压，先进入 T15~T18，T14 在 T24 后或出现 CV inference 岗位需要时补回。

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

### 对应视频

- 李沐卷积 shape 主线：[19 `卷积层`](https://www.bilibili.com/video/BV1L64y1m7Nh/)、[20 `卷积层里的填充和步幅`](https://www.bilibili.com/video/BV1Th411U7UN/)、[21 `卷积层里的多输入多输出通道`](https://www.bilibili.com/video/BV1MB4y1F7of/)、[22 `池化层`](https://www.bilibili.com/video/BV1EV411j7nX/)。
- 李沐残差主线：[29 `残差网络 ResNet`](https://www.bilibili.com/video/BV1bV41177ap/) 中的“ResNet”“代码”。
- 吴恩达本合集没有 CNN/ResNet 对应分集，本周不强配。

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

### 对应视频

- 李沐：[52 `文本预处理`](https://www.bilibili.com/video/BV1Fo4y1Q79L)、[53 `语言模型`](https://www.bilibili.com/video/BV1ZX4y1F7K3/) 中的“语言模型”。
- 这两节覆盖 token/vocabulary/sequence 前置，但不完整覆盖 decoder-only causal mask；embedding 与两类 mask 仍由 `T15.md` 教程和代码补齐。
- 吴恩达本合集没有 tokenization/embedding/mask 的直接对应分集。

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

### 对应视频

- 李沐：[64 `注意力机制`](https://www.bilibili.com/video/BV1264y1i7R1/)、[65 `注意力分数`](https://www.bilibili.com/video/BV1Tb4y167rb/)、[67 `自注意力`](https://www.bilibili.com/video/BV19o4y1m7mo/)。
- T16 只建立 single-head Q/K/V、score、mask、softmax、weighted sum；68 Transformer 留到 T17。
- 吴恩达本合集没有 self-attention 的直接对应分集。

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
[ ] 能画出 MLP 完整 forward；T14 已完成时再补 ResNet forward
[ ] 能推导 single-head attention shapes
[ ] 当前至少一个 C++ 系统项目已形成测试/README/benchmark 证据
```

---

# 第三阶段：Transformer 与 LLM inference 理论桥接

> 周次：T17~T24
> 建议前置：Theory Gate 2 通过
> 预算：合计约 65~90 个有效小时；T24 单独预留 15~25h，可拆成 2~4 个自然周
> 时间锚点：T17~T18 对齐 2027-01 冲刺投递；T19~T24 以 2027-02~03 为进取窗口，周均约 4h 时顺延到 2027.Q2
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

### 对应视频

- 李沐：[67 `自注意力`](https://www.bilibili.com/video/BV19o4y1m7mo/)、[68 `Transformer`](https://www.bilibili.com/video/BV1Kq4y1H7FL/) 中的“Transformer”“多头注意力代码”“Transformer 代码”。
- 吴恩达本合集没有 Transformer 对应分集。
- 论文精读不列入本周基准视频；先把 reference code 写通。

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

### 对应视频

- 李沐：[68 `Transformer`](https://www.bilibili.com/video/BV1Kq4y1H7FL/) 作为 encoder-decoder Transformer 结构前置。
- 两条基准课程都没有完整讲 decoder-only Transformer forward；`T18.md` 必须自行补齐 causal self-attention、residual stream、norm、MLP、LM head 与 logits 的完整主线，不能假装 68 与本周完全等价。

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

### 对应视频

- 吴恩达：[P60 `多类别`](https://www.bilibili.com/video/BV1owrpYKEtP?p=60) 至 [P63 `Softmax 的改进实现`](https://www.bilibili.com/video/BV1owrpYKEtP?p=63)，只对应 logits 到 categorical probabilities 的前置。
- 李沐：[63 `束搜索`](https://www.bilibili.com/video/BV1B44y1C7m1/) 用作“另一种 decoding policy”的对照，不替代 temperature/top-k/top-p 教程。
- 两条基准课程没有覆盖本周全部 sampling methods，主体由 `T19.md` 和实验承担。

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
persistent / per-request / transient state
HBM / host memory / external storage tiers 第一层
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
request metadata 与 scheduler state
跨 tier 搬运时的 staging / transfer buffer
```

T20 只建立对象分类与容量账，不提前实现 offload。估算时必须写清 model、batch、sequence length、dtype、并行方式与是否包含 KV Cache，不能把某个框架的 `allocated` 数字当成全部设备占用。

### 对应视频

- 李沐：[31 `深度学习硬件：CPU 和 GPU`](https://www.bilibili.com/video/BV1TU4y1j7Wd/) 只对应硬件与计算背景。
- 两条基准课程没有系统对比 LLM training/inference memory composition；本周无强制视频，估算和对象分类由 `T20.md` 完成。

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
block / page based KV layout
block table 与 logical token position
prefix reuse / prefix cache
reference count、eviction 与 free-block lifecycle 第一层
prefill/decode 间 KV transfer contract 第一层
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

### 对应视频

```text
两条基准课程没有 KV Cache / prefill / decode 的直接对应章节，本周无强制视频。
```

T21 必须由教程、shape 推导和 `kv_cache_reference.py` 建立机制，不能用普通 Transformer forward 视频冒充 KV Cache 教学。连续 Tensor reference 先证明数值正确，再用 block table simulation 理解 production system 为什么把 KV cache 分块；不在本阶段照抄 vLLM/SGLang allocator。

只比较 correctness 和 operation shape；性能 benchmark 后续再严谨设计。

### 通过标准

能画出 prefill 与单步 decode 的不同数据流，估算 KV Cache 随 batch/sequence/layers/heads/head_dim 的增长关系，并解释 prefix reuse 为什么依赖 block identity、lifetime 与 eviction contract。

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
token budget 与 running/waiting requests
prefill/decode work 的不同成本
chunked prefill 第一层
prefill/decode disaggregation（PD）与 encode/prefill/decode（EPD）只作边界认识
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

只做 CPU 上的离散 simulation：不同 arrival time、prompt length、generation length，比较 static batching 与简单 continuous batching 的 idle/padding 情况；再加入 token budget，观察 long prefill 对 decode latency 的影响。不实现真正的 distributed PD/EPD。

### 对应视频

```text
两条基准课程没有 continuous batching / serving scheduler 的直接对应章节，本周无强制视频。
```

本周直接连接 BlockingQueue、backpressure 与后续 serving，不额外扩展另一套课程。

### 通过标准

能解释 continuous batching 解决什么问题、scheduler 为什么不只是普通 FIFO queue，以及 token budget 怎样把吞吐与单请求延迟联系起来。

---

## T23：correctness、tolerance 与性能模型

### 学习内容

```text
reference output
absolute / relative tolerance
floating-point accumulation order
latency / throughput
TTFT / TPOT（或 ITL）
warmup / repetition / synchronization
FLOPs 直觉
memory bandwidth
compute-bound / memory-bound 第一层
arithmetic intensity 直觉
KV cache usage / prefix-cache hit rate
fixed replay workload 与 cache warm/cold state
version / commit / model / hardware / precision / concurrency
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
p50/p95/p99（服务延迟）
cache state
software/hardware version
```

### 对应视频

- 李沐：[14 `数值稳定性 + 模型初始化和激活函数`](https://www.bilibili.com/video/BV1u64y1i75a/) 中的“数值稳定性”。
- 吴恩达 evaluation/diagnosis 对应：[P70 `决定下一步尝试什么`](https://www.bilibili.com/video/BV1owrpYKEtP?p=70)、[P71 `模型评估`](https://www.bilibili.com/video/BV1owrpYKEtP?p=71)、[P72 `模型选择与训练/交叉验证/测试集`](https://www.bilibili.com/video/BV1owrpYKEtP?p=72)、[P73 `诊断偏差与方差`](https://www.bilibili.com/video/BV1owrpYKEtP?p=73)、[P74 `正则化与偏差方差`](https://www.bilibili.com/video/BV1owrpYKEtP?p=74)、[P75 `建立基准性能水平`](https://www.bilibili.com/video/BV1owrpYKEtP?p=75)、[P76 `学习曲线`](https://www.bilibili.com/video/BV1owrpYKEtP?p=76)、[P77 `决定下一步尝试什么（再谈）`](https://www.bilibili.com/video/BV1owrpYKEtP?p=77)、[P78 `偏差、方差与神经网络`](https://www.bilibili.com/video/BV1owrpYKEtP?p=78)、[P79 `ML 开发迭代循环`](https://www.bilibili.com/video/BV1owrpYKEtP?p=79)、[P80 `错误分析`](https://www.bilibili.com/video/BV1owrpYKEtP?p=80)。这些只对应 evaluation/diagnosis 思维。
- 两条课程都不负责严谨 benchmark 方法；warmup、repetition、synchronization、tolerance 和统计口径由 `T23.md` 完整讲解。

### 通过标准

不能只写“快了 30%”；必须说明基线、输入、正确性和测量边界。operator benchmark 与 serving benchmark 分开：前者关注 shape/dtype/kernel time，后者至少区分 TTFT、TPOT/ITL、throughput、并发、prefix hit 与 cache state。

从 T23 起允许 agent 协助生成 benchmark skeleton、搜索 profiler clue 或提出优化 patch，但不得共享被测实现的错误逻辑来充当 oracle。学习者必须亲自定义 workload、baseline、tolerance、同步点和统计口径，并审查生成代码是否改变语义。agent 加速的是实验迭代，不替代实验设计。

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

### 对应视频

- 复用李沐 [67 `自注意力`](https://www.bilibili.com/video/BV19o4y1m7mo/) 与 [68 `Transformer`](https://www.bilibili.com/video/BV1Kq4y1H7FL/) 作为结构复检，不新增视频范围。
- 吴恩达本合集没有 tiny decoder-only implementation 对应分集。
- T24 是 T15~T23 的代码整合周，重点是 reference、tests、README 与 prefill/decode 第一层，不靠多看课代替收口。

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
固定 request replay 与 serving metrics 计算第一层
```

### README 必须回答

```text
每个 Tensor 的 shape 是什么？
哪些是 parameters，哪些是 activations？
prefill 与 decode 怎样不同？
KV Cache 保存什么？
正确性怎样验证？
benchmark 测了什么，不能证明什么？
model/version/hardware/precision/workload/cache state 是否固定？
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
[ ] 能解释 block/page KV cache、prefix reuse 与 token-budget scheduler 的第一层 contract
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

# 视频与公开课资源选择

> 核对日期：2026-08-26
> 原则：视频只负责第二讲解与课程定位，`Tn.md` 负责主教程，代码和验证才算学习产出。

## 1. 两条固定视频基准

### 吴恩达：机器学习概念骨架

- 固定入口：[吴恩达机器学习课程 `BV1owrpYKEtP`](https://www.bilibili.com/video/BV1owrpYKEtP)
- 定位方式：使用本规划每个 T module 写明的 `P号 + 分集标题`，不从 P1 自动播放到 P146。
- 主要承担：linear/logistic regression、gradient descent、softmax、neural-network forward、model evaluation、bias/variance 与 ML workflow。
- 当前后置：P87~P145 中的 decision tree、clustering、anomaly detection、recommender 与 reinforcement learning；只有后续真实缺口出现才重新开启。

### 李沐：PyTorch 与深度学习实现主线

- 固定入口：[“跟李沐学AI”账号搜索《动手学深度学习》](https://space.bilibili.com/1567748478/search?keyword=%E5%8A%A8%E6%89%8B)
- 教材校准：[Dive into Deep Learning 中文官方在线教材](https://zh.d2l.ai/)
- 定位方式：使用本规划每个 T module 写明的 `章节号 + 标题 + 官方单课链接`。
- 主要承担：Tensor 操作、autograd、PyTorch Module、MLP、regularization、CNN/ResNet、sequence、attention 与 Transformer implementation。

这两条线不完整双刷：

```text
同一 T module 先由 Tn.md 串主线
-> 吴恩达负责概念骨架
-> 李沐负责 PyTorch / implementation 映射
-> 已经掌握或没有直接对应时，明确跳过视频
```

## 2. 数学与概率的分工

```text
学校微积分/线代：已经具备，不重新刷视频课
学校概率论 + 用户自己的大学概率网课：负责完整概率课程
T2/T4/T5/T6：只负责 AI computation mapping 与代码 gate
```

两条基准视频没有直接覆盖的数学内容，不再随意添加第三条 B 站课程凑数。正式资料仍可用于查证：

- [MIT OpenCourseWare 18.06](https://ocw.mit.edu/courses/18-06sc-linear-algebra-fall-2011/)
- [Harvard Statistics 110](https://stat110.hsites.harvard.edu/)

它们是 reference，不是当前并行播放清单。

## 3. T module 怎样调用视频

```text
规划文件：列出每周精确对应关系
Tn.md：根据本周真实任务决定哪些是必看、选看、复检或无强制视频
用户学习：不需要手工寻找课程章节
验收：看代码、shape/value/tolerance evidence 与解释，不检查播放进度
```

若视频标题、分 P 或链接将来发生变化，优先按标题在上述两个基准入口重新定位；不要改用来源不明的“200 集打包版”。

---

## 5. 国外大学公开课怎样使用

这些课程不是三条并行主线，而是在相应 gate 后按主题调用：

### Stanford CS229

- [CS229 官方课程主页与 notes](https://cs229.stanford.edu/)

定位：比吴恩达入门课更数学化的长期 reference。当前只在 T8/T13 需要更严谨理解 regularization、bias/variance、model selection 时查 notes，不完整刷 lecture/problem sets。

### MIT 6.S191

- [MIT 6.S191 官方课程](https://introtodeeplearning.com/)

定位：高密度 deep-learning overview。通过 T12 后可看 Lecture 1 检查全景；进入 sequence/Transformer 后再选对应 lecture。它的 labs/讲解使用的 framework 不负责替代我们的 PyTorch/D2L 代码线。

### CMU 10-414/714 Deep Learning Systems

- [CMU Deep Learning Systems 官方 lectures](https://dlsyscourse.org/lectures/)

该课覆盖 autograd implementation、NN library abstraction、hardware acceleration、Transformer implementation 和 deployment，和长期 AI Infra 很贴近，但现在开启会同时引入一套完整 deep-learning framework implementation。

开启条件：

```text
Theory Gate 2 已通过
已经能使用 PyTorch 解释 Module、autograd 和 basic forward
系统主线的 Reactor / Mini Redis 没有被拖停
准备从 PyTorch user 视角进入 framework/runtime implementation
```

满足后分阶段选：

```text
Theory Gate 2 后：automatic differentiation implementation、NN library abstraction、hardware acceleration
T18 decoder-only forward 后：Transformers implementation
Theory Gate 3 后：model deployment
```

### 当前不采用的方式

```text
吴恩达 ML 全套 + 吴恩达 DLS 全套 + D2L 全套 + CS229 全套同时进行
为了国外名校标签完成所有作业
在不会 Tensor/forward 前直接看 distributed training 和 deployment
```

---

## 6. PyTorch API 入门

- [李沐 04 `数据操作 + 数据预处理`](https://www.bilibili.com/video/BV1CV411Y7i4/)
- [李沐 16 `PyTorch 神经网络基础`](https://www.bilibili.com/video/BV1AK4y1P7vs/)
- [PyTorch 官方 Learn the Basics](https://docs.pytorch.org/tutorials/beginner/basics/)

定位：

```text
李沐 04：Tensor 数据操作入口
李沐 16：Module / parameter / custom layer / save-load 入口
官方教程：核对当前 API 和准确语义
本规划代码：负责 Tensor layout、inference 和 correctness 深度
```

不需要把完整 CV 训练套路当作 AI Infra 主线。

---

## 7. Transformer 论文与直觉

顺序：

```text
T15：embedding / mask
-> T16：single-head attention
-> T17：multi-head + Transformer block
-> 写 reference
-> 再看论文精读
```

推荐：

- [李沐 64 `注意力机制`](https://www.bilibili.com/video/BV1264y1i7R1/)
- [李沐 65 `注意力分数`](https://www.bilibili.com/video/BV1Tb4y167rb/)
- [李沐 67 `自注意力`](https://www.bilibili.com/video/BV19o4y1m7mo/)
- [李沐 68 `Transformer`](https://www.bilibili.com/video/BV1Kq4y1H7FL/)

论文精读不进入当前基准播放线。先做到能推导 `[B,S,H] -> [B,heads,S,head_dim]` 并写出 reference，再决定是否追加。

---

## 8. “我是傅傅猪”课程放在哪里

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

## 9. 不推荐的选课方式

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

# 每个 T module 执行模板

下面的 A/B/C 是任务阶段，不要求各自一次完成；每个阶段可以拆成多个每日 30~60 分钟 block。

## Session A：概念

Session A 默认是 Tn.md 的连续理论主线，不是“先去外部读一份资料清单”：

```text
1. 从一个真实计算问题出发
2. 在需要的位置解释术语、公式和对象
3. 用最小数值/shape 例子逐步推导
4. 紧接一个观察性小实验
5. 用一句过渡把当前结论连接到下一节
```

外部视频与文档可以穿插定位，但正文必须在不打开外链时仍能独立读懂。

## Session B：代码

```text
1. 围绕本 T 的一个核心对象完成最小实现
2. 用 shape / value / tolerance 验证关键结论
3. 与 NumPy/PyTorch reference 比较（适用时）
4. 观察一个真正有教学价值的错误 shape / numerical edge case
```

前期 T1~T8 的 coding 服务于理解，不把简单 numerical exercise 包装成大型工程 contract。T9 以后涉及 PyTorch Module、autograd、inference、KV Cache 或 benchmark 时，可以提高 coding 比例，但仍不在解释主线前堆实现 checklist。

## Session C：复盘

只保留少量能暴露理解的复盘问题：

```text
这周的对象有哪些？
完整数据流是什么？
每一步 shape 是什么？
正确性怎样验证？
它和 CPU/GPU memory/performance 有什么关系？
目前明确没学什么？
```

如果代码已经清楚证明某一点，不机械抄长篇验收答案。

### Tn.md 编辑约束

```text
保留：完整理论链、术语首次解释、公式推导、shape/value 例子、一个综合实验、AI Infra 连接
压缩：环境重复说明、资料导航、相同 invariant 的重复表述
按需保留：能够保护真实独立思考空间的一次 Round / Reading Gate
删除：为了仪式感存在的多层闸门、重复 pass checklist、训诫式常见错误全集、大段固定 note 模板
```

同一个 invariant 正文完整解释一次，结尾最多压缩一次。不能为了显得精确，把 `ndim=len(shape)` 一类简单关系在五处重复或反复套复杂 LaTeX。

自检用于找出理解断点，不把“完成 checklist”冒充“掌握理论”。通常保留 3~5 个高价值问题即可。

---

# 进度记录模板

`Txx_note.md` 不要求固定七节。默认只记录：

```markdown
# Theory Txx Note

## 我真正新理解的内容

## 一条关键推导或实验

## Questions
```

如果本 T 有 numerical experiment，再附最小 evidence：

```text
运行命令
关键 input / expected / actual
tolerance（仅在涉及浮点时）
```

代码已经明确证明的 assertion 不在 note 里逐条复写。用户根据实际学习内容增删标题，不为了填模板制造笔记。

---

# 调速规则

## 可以加速

如果某周内容已经由学校课程或实际代码证明掌握：

```text
直接完成关键推导、code output 和最小 evidence
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

# Theory Gate 3 后的下一步

Theory Gate 3 通过后：

```text
第一主线：mini-infer-cpu
第二伴随：PyTorch reference / Transformer inference
```

同时开始第一轮 serving source reading，但只读固定版本的小型实现：

```text
mini-sglang（固定 snapshot）
-> 先读 docs/structures.md 与 docs/features.md
-> 沿 request/sequence -> scheduler -> batch -> model runner 追一条主路径
-> 再看 radix cache / block table / chunked prefill / overlap scheduling
-> 用自己的 T21/T22 reference 和 simulation 作对照
```

这一轮的产出是对象图、调用流程和一个可验证问题，不是“读完整仓库”。vLLM V1 与完整 SGLang 只在随后 production comparison 中各选一个窄路径；框架 release 快，进入时必须重新核对官方文档和 commit。

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
mini-sglang source path
vLLM V1 或 SGLang production path（二选一）
NCCL multi-GPU
```

---

# 最后压缩

```text
当前继续推进 C++ 系统主线。
AI 理论每天 30~60 分钟，每周可持续目标 4~6 小时。
T 是 module，不保证一个自然周完成。

T1~T8：Python / NumPy / 线代 / 微积分 / 概率 / ML workflow
T9~T13、T15~T16：2026 年底求职核心；T14 CNN 可延期
T17~T24：Transformer / sampling / memory / KV Cache / batching / benchmark

2026.12：至少完成 T1~T13 + T15~T16
2027.01：T17~T18 作为 AI Infra 冲刺项，不等待 T24
2027.03：进取目标，T22~T24 收口 tiny Transformer reference
2027.Q2：周均约 4h 时的正常后备窗口

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
