# AI Infra 理论伴随线规划

> 对齐日期：2026-10-27。岗位与官方资料补充见[本轮调研](reference_materials/ai_infra/2026-10-22_规划对齐与岗位资料更新.md)。
> 当前状态：T1～T10及Theory Gate 1已通过；T10整课与R1均为99/100，下一步T11。T11～T17是未通过的提前稿，Theory Gate 2未通过。
> Git留痕与发布权限统一按`MEMORY.md` §9.12：正式仓库文件有变化就本地commit；push需另行明确授权。
> 系统主线：Week13 Day1～Day7整日均已通过；91个整日通过、92份Daily已生成。Day7整日于2026-10-26以98/100通过，R1历史95/100；Week13整周正式完成，[Week14 Day1](week14/day1/day1.md)已生成，R1尚未开始。
> 目标：LLM inference systems / serving与CUDA/Triton kernel optimization；本线不替代系统项目。
> 时间边界：先完整学完原Week16再整理简历试投；Week17以后实际课表等Week16收口后安排。既有能力Gate与理论范围不变。

当前进度以[MEMORY §4](MEMORY.md)为准，逐次验收证据不在本规划重复堆叠。教材实测与提前生成只证明材料准备情况，不计用户学会或通过。

补充资料：“AI不止算法”的公开CPU推理/CUDA/LLM kernel内容纳入[候选筛选](reference_materials/ai_infra/2026-10-21_AI不止算法_资料筛选.md)，不新增T线作业或付费前置。目录与长期路线重合不等于T10以后的能力已通过，使用时继续遵守原Gate及知识先后。

六块目录的详细落点与必要补强见[课程对齐](reference_materials/ai_infra/2026-10-22_AI不止算法_课程对齐.md)。本T线先建立模型计算与数值参照；CPU性能、CUDA算子接回模型和量化执行路径在后续原Gate中展开。CV部署、完整QAT及特定架构优化按需选用，不反向追加到已通过的T10，也不塞入T20第一次直觉，不增加T25或新的理论必修模块。

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

传统机器学习讲义、经典作业与 T module 也执行同一条去重规则：

```text
Tn.md：当前阶段的主教材，负责讲清本课第一次需要的原理、代码与AI Infra联系
ML/ML.md：按当前T需要调用的理论参考；已在这里学会的内容不重复讲，不要求顺序读完其余章节
ML/ML_配套练习.md：有明确模块映射时，在真实课程数据上形成或复用executable evidence
```

同一个 learning contract 已经由一份实现和一组证据完整覆盖时，允许跨资料等价验收，不再要求换一份 synthetic data 重写同一算法。等价验收必须逐条映射 shape、value、gradient、workflow 与 failure/evidence，不能因为“看过”或“感觉会”直接跳过。抽象层发生变化时不算重复，例如 finite-difference gradient checker、NumPy 到 PyTorch autograd、training 到 inference memory、CPU reference 到 GPU kernel。

### 2.6 传统ML、深度学习与Transformer怎样交接

**现在直接沿T10 → T11 → T12推进，不需要旁边再通关完整ML或DL课程。** 已通过Theory Gate 1，说明当前线性模型、概率/损失、梯度与workflow基础已达到下一阶段门槛，不代表已经学过神经网络结构。

传统ML的连续学习在T8暂时收口。KNN、完整SVM、树/boosting、EM/HMM/CRF等不作为当前前置；后续由岗位、学校课程或项目的具体需要再定向补。T13仍要在深度学习场景使用泛化与正则化，不把“暂时收口”误解为后续不再接触任何共用ML知识。

```text
已完成：线性回归、logistic/softmax分类、loss、正则化与ML workflow
-> T9：Tensor / storage / layout / dtype / device（已通过）
-> T10：用已会线性分类器学习Module、状态与保存恢复
-> T11：用已会标量链学习autograd
-> T12：首次从XOR进入神经网络、隐藏层、ReLU与MLP训练
-> T13：泛化与正则化
-> T14：CNN/ResNet第一层（原有可延期范围保持）
-> T15：token / embedding / mask
-> T16：single-head self-attention
-> Theory Gate 2
-> T17及以后：Transformer与LLM推理机制
```

T9～T11是PyTorch对象、状态与求导的过渡，不依赖先学完整神经网络课程。T12本身承担本路线的DL（deep learning，深度学习）入门；不是先去补完DL才有资格开始T12。

资料也沿这条路线使用：**Tn.md负责当前主讲，ML.md和吴恩达/李沐课程提供按需的第二种解释，官方文档用于机制与API查证。** 视频写在对应概念之后，标清具体课节、阅读时点、必看/选看及要解决的问题；没有必要额外视频时直接写明。经典作业沿既有映射提供或替代证据，不因此新增一条Ex1～Ex8顺序通关线。已有Kaggle与Gate要求保持，不擅自删减。

“负责第一次学懂”只用于实际选来主讲该概念的资料，不再表示ML.md拥有所有后续理论的独占职责。比如T7理论已由ML讲义学会，就复用Ex1；T12尚未学过的MLP，则必须由T12正文完整讲清。

---

## 3. 和系统主线怎样并行

### 3.1 当前起点与术语修正

当前系统主线的Week14 Day1已生成，R1尚未开始；Week13 Day1～Day7均已通过。TTL组件、命令、主动清理、网络接入与虚函数补缺已经收口；原Week14～Week16继续AOF/恢复、故障/性能和项目出口。

理论下一步T11，已通过的T1～T10不重做。Ex1与T7共用已有线性回归证据；T8/Gate 1与T9的等价产出已验收，不为统一文件名再造一份实现。

理论线编号保持 `T1~T24`。它表达模块依赖，不把编号当自然周：

```text
T = Theory module
T 不等于一个自然周
```

简单模块可能 3~5 天通过；T17、T18、T21、T24 可能分别需要 2~4 个自然周。不能再用“24 周、每周 3 小时”掩盖真实工作量。

### 3.2 每日投入与可持续周预算

用户给出的真实投入：

```text
AI 理论线：每天 30~60 分钟
系统主线：平常计划每天3小时以上，区域赛备赛期按实际精力调整
```

折算为：

```text
AI 名义上限：每周 3.5~7 小时
AI 可持续计划值：每周 4~6 小时
区域赛备赛/参赛、考试、主线故障或休息会使个别周低于计划值
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
| Phase 1 | T1~T8 | 30~45h | 数学基础扎实；ML/Ex 与 T7 共用一份线性回归产出，不重复实现 |
| Phase 2 求职核心 | T9~T13、T15~T16 | 45~60h | PyTorch、autograd、MLP、token/mask、attention |
| Phase 2 可延期 | T14 | 6~10h | CNN/ResNet 对 LLM inference 不是硬前置 |
| Phase 3 | T17~T24 | 65~90h | decoder、KV Cache、batching、benchmark、最终整合 |

总量约：

```text
150~210 个有效小时
```

按每周平均 4~6 小时，需要约 25~53 个自然周，也就是大约 6~12 个月。`2027-03-31` 是进取目标：它要求多数周接近 5.5~7 小时、数学模块通过 diagnostic 加速，并且不发生长期停摆；若实际长期接近每天 30 分钟，T24 应顺延到 2027 年第二季度，不能靠删 correctness gate 伪造按时完成。这个数字是容量估算，不是要求每天打卡满额。

### 3.4 系统 milestone 与 T module 的协调锚点

| 系统主线出口 | AI 理论至少到达 | 原目标月份（协调估算） | 当时应有的 AI 证据 |
|---|---|---|---|
| Week9 | T1 | 2026.08 末~09 初 | `numpy_basics.py`，能解释 shape/dtype/nbytes |
| Week10 | T3 | 2026.09 | matmul/broadcast reference 与 shape 推导 |
| Week11 | T6 | 2026.09 末 | finite difference、概率映射、stable softmax |
| Week12 | T8 / Theory Gate 1 | 2026.10 上半 | Ex1 或 T7 fallback 提供 linear evidence；T8 提供 softmax 与 ML workflow |
| Week13 | T10 | 2026.10 下半 | Tensor layout 与 Module inference |
| Week14 | T12 | 2026.11 | autograd + MLP training/inference flow |
| Week15 | T13 + T15~T16 | 2026.12 上半 | token/mask 与 single-head attention reference |
| Week16 | 协调目标T16；T17～T18进阶 | 原估算2026.12下半 | 欠账如实登记；按实际AI证据匹配岗位，不把后置路线变成C++试投前置 |

这里的“至少到达”是进度控制锚点，不是主线代码的编译依赖。若 Week10 已结束而 T3 未完成，必须在进度记录中写明欠账和补齐日期，不能把 T 线静默冻结。

2026-10-18用户澄清：先按原规划学完Week16，再整理简历并向中小厂试投，11月为期望时间。不能据此拆“提前投递版”、前移任务或缩减主线；本表的学习范围和Gate保持，日历日期按区域赛与实际进度核对，不强行赶时长。

### 3.5 投递顺序与后续排课

**原Week16完成后，再整理简历并试投。** 用户希望11月开始，实际由项目完成决定；既不缩减Mini Redis，也不把后置T24/CUDA变成第一批C++/后台岗位的额外门槛。

T16仍是Week16的理论协调目标。若两线速度不同，如实记录欠账与补齐安排，不虚报已会，也不因为AI线尚未全部完成而取消已满足条件的C++/后台试投。

后续依赖保持：

```text
T17～T18：Transformer block与decoder forward
T19～T21：sampling、内存对象与KV Cache
T22～T24：调度直觉、benchmark与reference整合
```

旧2027年1～3月和第二季度窗口只作容量估算，**不是预先冻结的Week17以后课表**。实际课表在原Week16收口后，按届时基础、投入、岗位与硬件重新编排。

投递时继续区分：

```text
后台/C++ Infra：Mini Redis为主项目，已完成AI内容作为补充
AI业务基础设施：按实际模型与服务证据匹配
推理引擎/CUDA：需要后续运行时与GPU证据，T18通过也不等于会kernel优化
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

每个 T module 默认需要覆盖四类 evidence：

```text
1. 一份短 note：只记录真正不熟的概念
2. 一个可以运行的 .py / notebook
3. 至少一组 shape / value / tolerance 验证
4. 一段“这和 AI Infra 有什么关系”的解释
```

这里的“固定产出”按 learning contract 计数，不按文件名计数。若经典作业已经提供同等或更强的代码与 evidence，T module 可以登记该 artifact 为等价产出，只补尚未覆盖的 AI mapping；不能为了让每个目录都有一个新 `.py` 而复制同一 training loop。

每个 T module 开始前，再单独生成一份 `Tn.md` 教程。下面只定义 AI Theory 教程的写法，不定义或修改系统主线 `daily.md` 的编写规则：

```text
AI Theory Tn.md
-> 概念理解、数学映射和数据流优先
-> 前期默认约 70% 讲解、30% 手推/实验/coding
-> 默认写成一份从头可连续阅读的自包含讲义
-> 按能力闭环判断阶段停止点，再单独判断是否需要保护独立发现的Reading Gate；不统一删除或统一套用Round
```

视频与官方文档承担校准、补充或第二解释源，不能用“去看第几 P”代替教程正文；反过来，也不应把一份很长的外部资料变成必读前置，再让用户猜它应该插在教程哪一段。

理论线每个概念应在讲解主线第一次需要它的位置直接讲清楚，教学呈现以 `MEMORY.md` §1.1 为最高优先级：**先走通用途，再命名概念；先说明行为，再解释机制**。用户直接询问一个术语时，可以先用一句简短行为定义和具体例子建立入口，再推导原因，不机械延迟命名。这项要求逐个关键转折执行，不以首屏有例子、术语已译成中文或表格齐全代替；不改变系统主线 daily 的结构与闸门。参考资料按Memory §9.8借鉴语义入口并就近定位，正文默认自包含不等于外部短定义必须后置。默认认知顺序为：

```text
从已有能力产生一个具体新问题
-> 用熟悉对象走通一次最小完整动作、结果与用途
-> 从这个需要推出最小机制
-> 再命名正式术语
-> 展开公式与因果链
-> 从当前最小有意义单位推广到 batch / 一般情形
-> code 对应与紧邻小实验
-> AI Infra workload / memory / numerical connection
```

术语、最终矩阵公式和 framework metadata 不能承担第一次理解的责任。读者应先看见“为什么需要它、怎样使用”，再知道“这个已经出现的对象叫作什么”；不是要求每种需求都只有一种解法。重要公式必须先用一个可手算的小例子落地；不强制每个概念从 scalar 开始，确实从标量推广到矩阵时，必须说明哪个 axis 被归约、哪些 axes 被保留，以及 output shape 为什么与目标对象相同。

若一个抽象来自重复模式，第一次教学不能直接把它压成表格；同时也不按固定次数机械展开。先完整走通能让模式出现的最小实例。一个连续例子若已包含数次同类动作，就沿同一数据流逐步完成；模式仍不可见时才补第二个例子。学习者能够预测下一步后，立即用共同公式、术语、表格或API收束。保留的是形成理解所需的推理，不是同义复述。

用户新增内容应融入教程主线。保留其理解、例子、纠错与已验证事实，但不要求保留临时编号、重复段落或审稿语气；用户独立note/code继续不改。最终教程只呈现当前最清楚的学习顺序，修订过程留给Memory与Git。

每一课、每一Round先确定一条认知主干。正文中的例子、公式、API与图必须推进这条主干；技术上正确但当前不参与因果链的内部实现、例外和未来接口，降为短选看、附录或删除。不要为了预防所有潜在误解提前堆边界；只有当前简化会直接妨碍下一步时才补最小限定。若学习者完成后的笔记是一条短链，而教程仍分裂成大量平行小节，应从笔记反推主干并重排，不继续累加修补段落。

讲懂之后还要按 `MEMORY.md` §6.1 检查阅读负担：**一句推进一个主要认知动作，一段回答一个主要问题。** 先让主结论和例子站稳，再分开原因与必要限定。完整性由整节承担，不靠连续长句同时塞入 API、例外和未来联系。

外部聊天解释应改编成课程所需的连续讲解，不保留现场评价和重复追问。当前任务之外的边界压入短补充；影响正确理解的前置仍就近保留。发布前既查知识顺序，也查连续复句的负担，不把“精简”理解为省略推导或机械切短句。

跨阶段继续按MEMORY §1.1检查主问题是否接续。每一阶段先回答一个主要问题；不参与当前因果链的相关方法或术语讨论，移到主闭环之后。公平实验、数据隔离和状态保存等当下必需条件仍在使用前给足。核心/选读边界改变时，同步任务与通过标准，不把移动章节当成已经对齐，也不强制所有T套三轮。

代码对象的负担按MEMORY §9.3一起检查：先交代整课目标，第一版对象只承担当前需要；新成员、层或helper在具体问题出现后再加入。升级同一组件时明确修改位置、保留行为、是否重建实例及本阶段的运行结果，不把未来角色预装进第一份示例，也不让学生猜多个片段怎样接起来。

### Theory、Lab 与 Gate 的职责分开

同一份 `Tn.md` 可以包含三层内容，但不能把三种文体揉在第一次讲解里：

```text
Theory Note
-> 负责第一次讲懂：问题、例子、直觉、推导、正式定义

Worked Example / Lab
-> 负责亲手算一次、实现一次、观察一次

Gate / Acceptance
-> 负责 contract、tolerance、fixed evidence、PASS boundary
```

Contract、error handling、Reading Gate 与 evidence matrix 可以保留，但默认放在概念主线已经闭环之后。`T7` 这类已经由 `ML/ML.md` 完成第一次理论讲解的模块，应明确标记为 Lab / Checkpoint；它不需要伪装成第二份 Theory Note。反过来，T4 的 chain rule、T8 的 softmax gradient、T9 的 stride 等首次概念，不能用验收规格代替讲解。

### Implementation Bridge：从理论进入代码前必须搭桥

理论已经讲懂，不代表读者看到一组 function signatures 就会自动知道整份程序怎样运转。任何 T module 开始要求写程序时，先按 MEMORY §9.3 讲清下面四件事；图表只是按需要选用的表达方式：

```text
1. 用一句白话说明最终 artifact 是什么、替谁解决什么问题
2. 用可跟完的具体步骤串起输入对象、操作与输出；文字或小图均可，不固定行数
3. 给第一次出现的 function/object 标明角色
4. 先跑通一次 concrete call；确有复用需要时，再从重复动作抽象出 generic API
```

角色说明至少覆盖当前真正出现的类别：

```text
model：持有/引用 parameters 与 persistent state，定义 forward mapping
forward：从 inputs/state/parameters 计算 output
objective / loss：产生 optimization 要最小化的 scalar
metric：用于评价，不负责 backward，也不一定可微
optimizer：读取 gradients/state，修改 parameters
sampler / policy：根据 distribution 或 scores 产生选择
checker / helper：检查或组织其他计算，本身不是 model/loss/optimizer
checkpoint / artifact：持久 state，不是正在执行的 model object
```

第一次出现一个重要 function/object 时，还要用当前程序回答：它消费什么、产生什么、谁调用它、属于 training/evaluation/inference 哪个阶段，以及 state 是 temporary 还是 persistent。API的首次讲解按MEMORY §9.7，以最小调用走通动作和返回结果、说明原对象的变化，再介绍一般条件与限制；相邻操作服务同一需求时，明确这次放宽或改变了什么约束。不是每篇都要硬塞同一张大表，但这些关系不能让读者靠函数名猜。

跨调用状态的表示升级统一按MEMORY §9.3：用同一份具体数据走清旧值与新值各代表什么、新值怎样产生下一次查询需求，再引入对应API。讲清“值为何安全”之后，还要讲清“保存这个值究竟拿来做什么”；这是已有教学顺序的细化，不新增理论作业或改变分轮规则。

对于T9这样的观察脚本，先说明要用程序回答哪几个问题，再把“操作什么、与谁比较、预期支持什么判断”写到对应步骤里。布局对照、metadata、aliasing等分类名称不充当任务说明；原预测的复盘与脚本断言失败分别讲清。完整预测参考值仍放在闸门后，不把明确题意变成预先揭晓答案。这里只细化理论线的教学呈现，不调整T模块范围、Gate或主线daily规则。

框架标签与已学系统模型的衔接按MEMORY §9.3执行：例如先从C++进程内存接到主机内存与GPU显存，再讲device；语言层对象、数据storage、搬运与算子执行分别说明，避免把“在CPU上”压缩成错误的芯片内存画面。

进入机制以后，也按同一规则把“保存的信息”展开为当前实例中的具体值与关系，再走一次读取、判断或更新。只说“保存中间状态”“选择对应版本”不足以解释它怎么工作；完整实现细节可以后置，但完成这次推演需要的最小结构必须在正文出现。

数学进入代码时还要给最小映射，并标明哪些量被求导、哪些固定、哪些是 temporary activation、哪些是 persistent state。例如：

```text
theta -> parameters          被求导 / 被更新
X     -> features            当前 batch fixed input
y     -> labels              当前 batch fixed target
z/Z   -> logits              temporary forward output
L/J   -> loss                scalar objective
grad  -> parameter gradient  dL/dtheta
```

凡是 gradient 代码，都必须回答：gradient of what、with respect to what、holding what fixed。抽象 API 不能承担第一次理解；先用当前具体 loss/sample/tensor 走一遍，再说明这个工具还能接收更通用的 function。

Implementation Bridge 不是泄露核心算法。可以公开 artifact、输入输出语义、调用关系与完整 dataflow；仍把关键公式、实现组织、核心数值技巧和真正值得独立撞的设计墙留给 Round1。Reading Gate 保护 mechanism discovery，不能靠隐藏题意制造难度。

当前讲解规则统一引用`MEMORY.md` §1.1、§6.1、§7与§9.3，不另设一套风格标准。T9从寻址需求推出stride；T10先辨认模型、子模块与参数，再沿状态管理走到保存恢复；T11从已会的标量求导走到记录、梯度保存与生命周期。每次发布检查整课阅读路径：前一步的问题、本节对象与动作、下一步用途必须连起来。多个新词须各有具体过程作为落点，不能互相定义后就认为已讲清。接口目录、角色表和PASS清单不能代替这条解释链。

外部链接放在对应概念之后，标明“查证 / 选看 / 延伸”；除非某一课程片段确实比文字讲义更适合承担主讲，否则不把跳出文档阅读设成必经闸门。

### 阶段停止点与 Reading Gate 分别判断

**先判断怎样分段学习，再判断什么需要先独立尝试。** 两者都是教学工具，不是理论线统一模板。阶段停止点让用户理解并验证一层能力后暂停；Reading Gate保护尚未揭晓的预测、设计或机制发现。

长课跨越多个能力闭环时，可按当前负荷分成几个阶段，也可用Round命名。每阶段说明读到哪里、得到什么能力、怎样运行同一产出和何时暂停；不按小时数机械切成三轮，不为分段新增重复作业。没有真实认知墙，也可以有阶段停止点。

然后判断本T是否存在适合“先独立尝试、再揭示机制”的真实认知墙：

```text
没有真实认知墙
-> 使用连续讲义
-> 概念讲清后紧邻小实验
-> 按能力闭环需要设置阶段停止点，不伪造独立发现任务

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

例如：T1的基础ndarray/shape/dtype以建立地形图为主，不必设置Round；T3的broadcasting、batch matmul和运行前shape prediction存在真实认知墙，应保留`Round1 -> review -> Round2/3`。T10则按模型状态、执行开关、保存恢复分三个能力阶段，不要求用户独立发明框架登记机制。

一旦使用闸门，闸门前必须让用户具备独立开工能力：

```text
必须给：程序用途、文件名、输入/输出、public API、必要前置语法、边界、可观察的完成标准
必须保留：实现组织、关键算法、核心因果链、应由第一次尝试暴露的错误与设计选择
禁止：嘴上说“不给答案”，随后用伪代码、职责清单或逐步提示把答案完整拼出来
```

闸门后的内容不能机械预制成错误全集。已设置R1时，无论它是能力阶段还是独立发现练习，正式检阅通过后都应在同轮结合真实实现、笔记、提问和设计取舍，定向核对完整R2/R3。

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

ML/DL基础的常用视频基准优先使用用户指定的两条课程线：

- 吴恩达：[机器学习课程合集 `BV1owrpYKEtP`](https://www.bilibili.com/video/BV1owrpYKEtP)
- 李沐：[“跟李沐学AI”账号内搜索《动手学深度学习》](https://space.bilibili.com/1567748478/search?keyword=%E5%8A%A8%E6%89%8B)

吴恩达 2014 传统机器学习课程另有一份本地连续自学讲义：[ML/ML.md](ML/ML.md)，以及按经典 `ex1~ex8` 组织的中文实践教程 [ML/ML_配套练习.md](ML/ML_配套练习.md)。练习不再按知识章节散列成抽象题目，而是逐套交付真实问题、最终程序、本地数据路径、数据字段、实现阶段、原题检查值和图像 evidence。Python starter notebooks、Data、Figures 与原始题面保存在本机 `ML/official_assignments/`，第三方材料不进入仓库提交。它们不新增一条必须逐周打卡的主线；当作业完整覆盖某个 T module 的 learning contract 时，可以成为该 T 的等价代码 gate。当前明确：Ex1 可替代 T7 的 synthetic linear-regression 产出；Ex2 可覆盖 T8 的 binary-logistic/regularization 部分，但不能替代 T8 的 multiclass softmax 与 train/validation/test workflow。其余作业是否抵扣，在进入对应 T 时逐条核对，不默认整套互换。

Kaggle 只作为传统 ML 阅读与经典作业之后的端到端 workflow lab，具体任务见 [ML/Kaggle入门实践.md](ML/Kaggle入门实践.md)。当前固定为：T12 + Ex3/Ex4 通过后可选做 Digit Recognizer，T13 + Ex5 通过后必做 Titanic。每项最多 4~6 小时，只允许 baseline、一次有依据的改进和最多一至两次 submission；达到 schema、validation、artifact 和外部 score 的证据后立即停止。它不新增刷榜、特征工程或月赛支线，也不能挤占 HTTP Server、Mini Redis 和后续 inference project。

进入模型系统、benchmark或GPU阶段后，可按问题选用CS336、GPU MODE及框架官方教程；它们是对应阶段的定向参考，不是现在新增第三条完整刷课线。具体入口、用途与停止点见[最新资料映射](reference_materials/ai_infra/2026-10-22_规划对齐与岗位资料更新.md)。

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
> 预算：合计约30～45个有效小时；Theory Gate 1已于2026-10-17通过，旧10月15日目标仅作历史记录
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
probability_sampling.py
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

## T7：linear regression 等价验收与 training-loop bridge

**验收记录（2026-10-14）：Ex1/T7 最终 98/100，正式通过。** 复用用户的餐车、房价两个训练脚本；半 MSE 系数修复后，20/20 私有检查、数值梯度与独立最小二乘参照通过，新房预测口述正确。参照计算由 Codex 提供，不冒充用户已写最小二乘；不再要求另一份训练程序。当时进入 T8；最新进度统一见 §3.1，T8 与 Theory Gate 1 现已正式通过。

### 本周问题

```text
怎样证明自己已经能把 linear-regression 数学变成完整 training loop，同时不把 ML.md 和 Ex1 再做一遍？
```

### 学习内容

```text
model / loss / optimizer 的职责边界
vectorized forward / loss / gradient / simultaneous update
loss curve、parameter/prediction 与 reference 的多层证据
training 与 inference 的第一层对象差异
```

### 学到什么程度

必须能够串出并用代码证明：

```text
input
-> prediction
-> loss
-> gradient
-> parameter update
-> next iteration
```

### 去重入口

若已经学完 [ML/ML.md](ML/ML.md) 的单变量/多变量线性回归，并完成 [Ex1](ML/ML_配套练习.md#ex1让线性回归真正预测餐车利润和房价)，不再播放同一组线性回归视频，也不再写第二份 synthetic implementation。直接把 Ex1 的代码、检查值、loss curve、feature scaling 与 `np.linalg.lstsq` 对照登记为 T7 evidence。

若尚未完成 Ex1，才走 T7 fallback：按原范围写一个最小 synthetic NumPy training loop。两条路径二选一，不能为了形式两套都做。

### 等价代码产出

```text
推荐：ML/exercises/ex1_linear_regression/linear_regression.py
fallback：linear_regression_numpy.py
```

两条路径共同要求：

```text
不用 sklearn
手写 forward / loss / gradient / update
记录 loss curve
用 parameter、prediction、cost/gradient checkpoint 与独立 reference 多层验证
```

### 通过标准

能解释 loss 降低不等于程序绝对正确，并能用参数、prediction、cost/gradient checkpoint 和最小二乘 reference 多层验证。Ex1 满足这些条目时，T7 直接记为等价通过，不再要求 `linear_regression_numpy.py`。

---

## T8：logistic / softmax regression 与 ML workflow

**验收记录（2026-10-17）：T8整课与R3最终100/100，正式通过；Theory Gate 1正式通过。** 最新源码a35aca0a...完整保留三批独立数据、三候选L2训练、验证纯data loss选择及最后test；原输入/数值24项24/24、当前真实main与R2回归16/16，均exit0。此前入口dtype/finite、labels数量/维数、公共shape与空维度扣分全部撤销；仍选A，validation loss0.269190679540/accuracy86.67%，test loss0.289091944672/accuracy85%。旧永久checker90/100只属R1历史；本轮用真实签名的私有检查，不改用户代码、checker、note或T8。当时转入T9，最新阶段见§3.1；不重复训练或另写分类器。

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

去重规则：若 `ML.md` 的逻辑回归/正则化章节和 Ex2 已完成，binary logistic、decision boundary 与 L2 推导只做 diagnostic，不重复看视频或重写；T8 仍必须完成 multiclass softmax、stable logits-space cross entropy、finite-difference spot check 与 train/validation/test workflow，这些不是 Ex1 能替代的。

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

**验收记录：2026-10-17正式通过。** T1~T7已有验收与当轮T8最终100/100共同覆盖下列条件；不要求重做已通过的实验。当时进入T9；最新阶段见§3.1，CPU baseline按原计划执行。

必须全部满足：

```text
[x] 会使用 Python / NumPy 编写并测试小程序
[x] 能推导 matmul output shape
[x] 能手算简单 gradient
[x] 能解释 expectation / variance / conditional probability
[x] 能独立实现 stable softmax
[x] Ex1 或 T7 fallback 已提供一份 linear-regression training evidence，不重复实现
[x] 能实现 NumPy multiclass softmax classifier
[x] 能区分 train / validation / test，并避免 preprocessing leakage
[x] 当前系统主线没有因为理论线停摆
```

未满足时，不通过“多看一个视频”解决；回到对应代码产出补齐。

---

# 第二阶段：PyTorch、机器学习与深度学习基本机制

> 周次：T9~T16
> 建议前置：Theory Gate 1 通过
> 预算：T9~T13、T15~T16 合计约 45~60h；T14 另约 6~10h，可延期
> 协调目标：与原Week16对应推进T1～T13与T15～T16；未达如实记账，具体日期按真实投入校准
> 与主线关系：应在 ThreadPool/AsyncLogger 稳定后逐渐进入；Reactor 很重时允许放慢

---

## T9：PyTorch Tensor、dtype、device、layout

**实际状态（2026-10-19）：T9整课最终99/100，正式通过；R1历史98/100保持。** 当前66行脚本补齐payload、view预期失败、CPU路径及NumPy共享/复制和返回数组修改。普通运行exit0；私有检查24/24，其中19项观察用户脚本，5项为工具参考，不冒充用户另写实验。笔记与教程§9.0补齐接口区分，本次接受它们与现有程序等效覆盖最终机械汇总，不要求重新拼完整§17脚本。旧payload扣分撤销，仅保留基础切片需注明步长条件的1分。下一步T10提前稿已校准；T10与Theory Gate 2尚未通过，不改T9或用户note。

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

**T10于2026-10-25以99/100正式通过，R1历史99/100保持；下一步T11。** 用户笔记与Ubuntu真实脚本共同证明模型状态、两个运行开关和checkpoint恢复主线；实际main完成fresh load与同输入输出对照，私有32项补足四种mode状态、独立存储、尺寸失败和dtype转换。实际TinyClassifier未加入Dropout，train/eval输出差异由笔记等效证明，保留1分但不阻塞通过。机械检查未全部写进用户main不重复扣分。本课继续作为部署/状态前置，三轮证据不重做。

第一版沿用T8已经会的线性多分类器：XW+b对应nn.Linear的一次乘加，不引入隐藏层、ReLU或MLP。先访问linear/weight/bias，再用debug_tensor区分普通属性与框架管理，解释登记后分别读named_modules和named_parameters的完整输出；此时才用树描述本例的包含关系。固定缩放需要共同保存时加入buffer，随后用state_dict收集数值并观察共享与快照。model(inputs)的正常用法就近给出，hook放选读；Dropout仅在R2用于观察模式，第一次出现先用普通概率和具体向量走通随机置零、缩放与eval原样通过，极端概率只作确定性验证。inference mode先用同一个标量乘加展示“不写仍能预测、写了不留求导记录”，再解释with范围并回到当前分类器；四组合必须有可运行观察代码，不只给职责表。保存恢复统一服务于“旧进程消失后，新进程用同类/配置/checkpoint恢复同一预测”，先交代数值文件与可执行对象各缺什么，再出现load链；Module.to另从真实dtype不匹配推出，不混作checkpoint步骤。按MEMORY §9.3保持同一对象的需求链，不按API目录横向展开。三轮任务、CPU环境和不新增训练的范围不变。

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
本次forward临时产生的Tensor
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

将已会的多分类线性计算包装为Module，逐步加入input_scale和模式对照，保存/加载state_dict并比较output。参数名单为linear.weight/bias，持久buffer为input_scale，不要求学习或训练新模型。

### 对应视频

- 李沐：[16 `PyTorch 神经网络基础`](https://www.bilibili.com/video/BV1AK4y1P7vs/) 中的“模型构造”“参数管理”“读写文件”，在正文对应机制讲清后选看。视频可能采用多层例子，只对照Module/状态API，不跟做其新模型。
- 吴恩达P45～P49统一留T12的对应片段，不作为T10前置或新增必看内容。

---

## T11：computation graph、autograd 与 backpropagation

沿T4已经会的标量乘加/平方链学习，不依赖神经网络。`backward()`第一次调用时，先展示调用前`.grad=None`、方法返回`None`、调用后leaf梯度写入`.grad`、参数值保持不变；先让学习者会用API。随后沿同一条`loss -> error -> z -> product -> w/b`反向路径走一次：平方、减法、加法、乘法各推进一个局部导数动作，节点名紧跟对应动作出现。一次完整反传已经提供足够重复，模式出现后立即收束并命名computation graph，不拆成四篇同构说明。图只画当前理解所需的分叉与`w.grad/b.grad`落点，不把`AccumulateGrad`、`next_functions`等engine边界前置。首次使用`grad_fn`时拆明`grad = gradient`、`fn = function`，先给代表性输出，再解释它指向产生当前结果的最后一个运算求导节点，并与保存数值的`.grad`分开。R1完成manual、finite difference、autograd三路对照并保留累积预测；R2只处理梯度清理以及graph saved state与leaf `.grad`的不同寿命，`retain_grad()`降为短选看；R3连续检查最终scalar目标、记录范围与backward依赖旧值。向量输出先走通“上游权重怎样组成标量目标”，再命名VJP；动态分支不进入核心任务。

### 学习内容

```text
forward graph
leaf Tensor
requires_grad
grad_fn
backward
gradient accumulation / clearing
vector output 与 upstream gradient / VJP
no_grad / detach / inference_mode 的用途边界
saved value 与 in-place version check
```

### 学到什么程度

必须能从：

```text
固定x、y；w、b -> z=w*x+b -> loss=(z-y)^2
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

用手推 gradient、finite difference 和 PyTorch autograd 三者交叉验证。正文技术图由本地可复现的D2源与SVG维护，只帮助理解现有对象关系，不新增学生画图或可视化任务。

### 对应视频

- 李沐：[07 `自动求导`](https://www.bilibili.com/video/BV1KA411N7Px/) 全部三节，重点对应 PyTorch autograd 代码。
- 吴恩达：[P67 `什么是导数（可选）`](https://www.bilibili.com/video/BV1owrpYKEtP?p=67)、[P68 `计算图（可选）`](https://www.bilibili.com/video/BV1owrpYKEtP?p=68)。T4已经会的微积分不重听；P69更大神经网络示例留T12后需要时选看，不作为T11前置。

### 通过标准

不要求读PyTorch autograd engine源码，也不把`retain_grad()`记忆作为阻塞项；但必须能沿标量计算图说明forward留下什么、backward怎样返回leaf，理解graph与保存activation会影响memory，并能用“目标、记录、旧值”解释R3三个实验为什么属于同一次正确求导的边界。

---

## T12：MLP、activation、loss 与 optimizer

本模块首次正式讲神经网络结构：XOR暴露单层线性分类器的局限 → 两次Linear仍可合并 → 需要非线性 → ReLU的四点变换 → 隐藏表示与MLP → 训练/保存/恢复。T10的状态管理与T11自动求导是已备好的工具，不倒过来要求T10先接受本模块结构。

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

### 可选外部 workflow lab

T12 与 Ex3/Ex4 都通过、且系统主线没有 correctness blocker 时，可以按 [ML/Kaggle入门实践.md](ML/Kaggle入门实践.md) 完成 Digit Recognizer。只使用本节已经掌握的小型 MLP，重点观察 `[N, 784] -> [B, 784] -> [B, 10]`、checkpoint reload 和不同 batch size 的 inference throughput；不临时扩展 CNN、augmentation 或 leaderboard 调参。最多 6 小时，不作为 T12 通过前置。

---

## T13：generalization、regularization 与实验纪律

### 学习内容

```text
overfitting / underfitting
baseline curves -> weight decay机制
共同initial state与独立optimizer
baseline vs weight decay受控比较
validation选择checkpoint -> 恢复winner -> 最终test
```

Dropout、模式对照，以及data leakage、seed/reproducibility、early stopping的扩展讨论保留在主实验之后的补充区，不属于核心PASS。固定split、seed、数据隔离和test不参与选择等实际规则，仍须在实验使用前明确。

### 代码产出

```text
overfit_observation.py
```

在固定小数据集上观察train/validation curves，再配对加入一种regularization，比较实际变化。不把一定过拟合或一定改善当作通过条件。

R1保持baseline观察。R2-A解释自己的曲线与weight decay后可暂停；R2-B继续安排公平比较和checkpoint选择，不插入另一种正则化。R3在同一个程序完成两组训练、恢复winner与最终test，再回答这次衰减是否有帮助。暂停不新增文件、实验或验收。

### 对应视频

- 李沐：[11 `模型选择 + 过拟合和欠拟合`](https://www.bilibili.com/video/BV1kX4y1g7jp/)、[12 `权重衰退`](https://www.bilibili.com/video/BV1UK4y1o7dy/)对应核心实验；[13 `丢弃法`](https://www.bilibili.com/video/BV1Y5411c7aY/)留到主实验后的补充区选看。
- 吴恩达 regularization：[P32 `过拟合问题`](https://www.bilibili.com/video/BV1owrpYKEtP?p=32)、[P33 `解决过拟合`](https://www.bilibili.com/video/BV1owrpYKEtP?p=33)、[P34 `带正则化的成本函数`](https://www.bilibili.com/video/BV1owrpYKEtP?p=34)、[P35 `正则化线性回归`](https://www.bilibili.com/video/BV1owrpYKEtP?p=35)、[P36 `正则化逻辑回归`](https://www.bilibili.com/video/BV1owrpYKEtP?p=36)。
- 吴恩达 diagnosis：[P71 `模型评估`](https://www.bilibili.com/video/BV1owrpYKEtP?p=71)、[P72 `模型选择与训练/交叉验证/测试集`](https://www.bilibili.com/video/BV1owrpYKEtP?p=72)、[P73 `诊断偏差与方差`](https://www.bilibili.com/video/BV1owrpYKEtP?p=73)、[P74 `正则化与偏差方差`](https://www.bilibili.com/video/BV1owrpYKEtP?p=74)、[P75 `建立基准性能水平`](https://www.bilibili.com/video/BV1owrpYKEtP?p=75)、[P76 `学习曲线`](https://www.bilibili.com/video/BV1owrpYKEtP?p=76)、[P77 `决定下一步尝试什么（再谈）`](https://www.bilibili.com/video/BV1owrpYKEtP?p=77)、[P78 `偏差、方差与神经网络`](https://www.bilibili.com/video/BV1owrpYKEtP?p=78)、[P79 `ML 开发迭代循环`](https://www.bilibili.com/video/BV1owrpYKEtP?p=79)、[P80 `错误分析`](https://www.bilibili.com/video/BV1owrpYKEtP?p=80)。

### 通过标准

用自己的曲线说明train改善与validation变化的关系；能解释衰减更新、共同起点、validation选择与恢复的状态，并在选择结束后报告test。没有改善时如实解释，不要求调到有效；Dropout补充不作为通过前置。

### 必做外部 workflow lab

T13 与 Ex5 都通过后，按 [ML/Kaggle入门实践.md](ML/Kaggle入门实践.md) 完成 Titanic。目标是独立建立固定 train/validation split、无 leakage 的 preprocessing pipeline、一个 baseline、一次受控改进和一个被 Kaggle 接受的 submission。时间上限 6 小时，分数高低和 leaderboard 名次不作为验收标准；完成后立即回到系统主线。

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

时间边界：T14对LLM inference不是硬前置。若协调预算受压，先进入T15～T18；T14在T24后或出现CV inference岗位需要时补回，不按旧月份强行插课。

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

R1保持Conv/ReLU与独立shortcut设计。R2只解释projection怎样通过通道组合与stride同时对齐两条path，再简短对照真实BasicBlock的分支骨架。R3继续观察同一个无BatchNorm组件的参数、buffer、selected activations、hook与state_dict，不增加新层；buffer bytes为0是正确结果。

BatchNorm整块放在核心课完成后的可选扩展，从运行统计量的需求接回parameter/buffer、train/eval与state_dict变化。它不是T14核心通过条件，不要求为了对照真实ResNet改写已完成的教学block。

### 代码产出

```text
residual_block_forward.py
```

只做forward、shape assertions和parameter/buffer/selected activation字节粗算，比较identity/projection配置及实际卷积state；这些数字不是实测peak memory。不新增CNN训练作业，BatchNorm可选，原可延期范围保持。

### 对应视频

- 李沐卷积 shape 主线：[19 `卷积层`](https://www.bilibili.com/video/BV1L64y1m7Nh/)、[20 `卷积层里的填充和步幅`](https://www.bilibili.com/video/BV1Th411U7UN/)、[21 `卷积层里的多输入多输出通道`](https://www.bilibili.com/video/BV1MB4y1F7of/)、[22 `池化层`](https://www.bilibili.com/video/BV1EV411j7nX/)。
- 李沐残差主线：[29 `残差网络 ResNet`](https://www.bilibili.com/video/BV1bV41177ap/) 中的“ResNet”“代码”。
- 吴恩达本合集没有 CNN/ResNet 对应分集，本周不强配。

---

## T15：sequence、token、embedding 与 mask

**教材状态（2026-10-21，进度校准至2026-10-25）：[T15提前稿](ai_theory/T15/T15.md)已按用户要求生成，尚未学习或通过。** 当前理论下一步是T11。T15沿原T13之后的安排学习，T14保留可延期边界；相邻前课通过或正式进入时，再根据最新真实产出校准。

本课分两段能力阶段，不机械套三轮：R1先把固定词表、两个不同长度的序列、右侧补位与embedding查表接通，得到编号`[B,S]`和向量`[B,S,H]`后暂停；R2在同一程序中引入“来源是否真实”与“是否在当前前缀内”，组成允许表并验证屏蔽后的softmax。Q/K/V分数来源留T16。

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

具体采用CPU、long编号、非空原始序列与右侧补位；0为PAD、1为UNK，未知项仍是有效token。允许表统一True=允许，最终返回`[B,S,S]`；先沿来源列排除补位，再按`j<=i`限制未来。用`B!=S`的第二批输入核对广播，并只把真实读取行当作正文结果。屏蔽在softmax前进行，所用公开框架API的布尔极性另行核对。完整空序列/左补齐策略、分词器训练、位置编码与真实attention实现不加入本课。

### 对应视频

- 李沐：[52 `文本预处理`](https://www.bilibili.com/video/BV1Fo4y1Q79L)、[53 `语言模型`](https://www.bilibili.com/video/BV1ZX4y1F7K3/) 中的“语言模型”。
- 这两节覆盖 token/vocabulary/sequence 前置，但不完整覆盖 decoder-only causal mask；embedding 与两类 mask 仍由 `T15.md` 教程和代码补齐。
- 吴恩达本合集没有 tokenization/embedding/mask 的直接对应分集。

---

## T16：self-attention 的 Q / K / V 主线

**教材状态（2026-10-23）：[T16提前稿](ai_theory/T16/T16.md)已生成，尚未学习或通过。** 正式学习当前从T11推进；T15通过后或实际进入T16时，再按真实实现和笔记校准，不因生成教材自动通过Theory Gate 2。

讲解沿“输入位置需要别处内容 -> 按比例汇总 -> 怎样算比例 -> 查询与来源匹配 -> Q/K/V从X投影 -> 缩放/softmax/加权和”连续推进。R1先完成一条序列的手算与PyTorch计算，暂停；R2在同一程序接T15批次和True=允许的mask，验证未来/补位/跨序列隔离与允许来源的影响，再对照逐行参照。复用已会softmax和线性组合，不提前加入多头、训练语言模型或KV Cache。

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

先用小矩阵手算，再写PyTorch单头主实现；独立逐行参照可用NumPy或PyTorch，机械checker可委托，不要求两份同构产品代码。R1输入`[S,H]`，R2兼容`[B,S,H]`，三个W按`[H,D]`保存；返回`(output, probabilities)`。CPU float64完成本课数值证据，不以GPU环境作前置。

mask复用T15非空、右补位规则；本函数只接完整`[S,S]`或`[B,S,S]`的bool允许表，softmax前屏蔽，主动拒绝全False行。核对禁止概率为0、逐行参考数值、有效输出的位置隔离，并区分补位读取行与真实输出。课程最终只要求`single_head_attention.py`，正式收口时提醒本人做笔记；显式S平方中间表只作容量解释，不作性能结论。

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
> 排期边界：保留T17～T24依赖和工时估算；旧2027年1～3月/Q2窗口不是既定课表，实际安排在原Week16收口后确认
> 定位：为 `mini-infer-cpu` 和后续 CUDA reference 做准备，不直接开始 vLLM 源码

---

## T17：multi-head attention 与 Transformer block

**教材状态（2026-10-24）：[T17提前稿](ai_theory/T17/T17.md)已生成，尚未学习或通过。** 正式进入前核对T16及Theory Gate 2；生成文件不代表前置已过，不新增Week16首批C++/后台试投门槛。

R1只解决“同一位置怎样保留多组读取结果”：从T16逐头参照出发，具体编号演示拆头、交换轴和合并，再用输出投影组合结果。R1暂停后，R2才从“保留旧表示并取得更新”引出残差，从“分支输入尺度”引出LayerNorm，最后接逐位置FFN，完成同一个前置归一化block。首次术语沿具体动作出现，不把未来组件提前装进首版。

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

CPU float64，逐步assert shape；以逐头计算和手写LayerNorm公式核对完整输出，不能只调用一个现成Transformer layer后打印结果。R1产出MultiHeadSelfAttention，R2在同文件新增TransformerBlock；输入保持`[B,S,H]`，True=允许表保持`[B,S,S]`，返回输出和`[B,N,S,S]`比例。核心固定前置LayerNorm，不含Dropout；RMSNorm与pre/post-norm只要求辨认，不另交第二套模型。

检查拆合顺序、数值、零分支残差、未来/补位/跨序列隔离，以及参数/输入不被forward改写。容量统计区分参数与显式注意力比例，不登记性能结论。完成后提醒用户亲自写笔记；T16通过或实际进入T17时，按真实实现再校准，R1通过后定向润色R2。T18的完整decoder forward范围保持。

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

T20仍以对象分类与容量账为主，并补足下面的量化直觉，不提前实现offload或量化运行时。估算时必须写清model、batch、sequence length、dtype、并行方式与是否包含KV Cache，不能把某个框架的`allocated`数字当成全部设备占用。

### 量化怎样从容量账走到实际实验

**先让已经正确的浮点模型保持可用，再研究怎样用更少的位数近似保存和计算。** INT8在表里每项占1字节，只回答了数据量；完整学习还要解释数值怎样映射、误差怎样产生，以及实际计算是否真的受益。

T20从一个权重值讲起：选择`scale=0.01`时，`0.374 -> 37 -> 0.37`。scale（缩放刻度）把整数单位对应到原数值尺度；quantization（量化）把浮点数映射到较低精度表示，dequantization（反量化）按刻度恢复其近似值。INT8是8位有符号整数。这里的取整与范围限制会引入误差，量化参数也需要占用空间。

先区分两个动作：FP32转FP16/BF16仍在浮点格式之间转换；INT8量化需要整数值与刻度等信息一起表达原数。不能把一次整数类型强转当成已经完成量化，也不能把4字节变1字节直接写成端到端快4倍。

| 何时进入 | 具体做什么 | 留下什么证据 |
|---|---|---|
| T20的概念入口 | 用一个数走过刻度、取整、范围限制和恢复；分别计算权重本体、量化参数与整份模型内存 | 解释近似误差从哪里来，为什么INT8权重本体约为FP32的1/4而整机峰值不一定如此；沿用`model_memory_estimate.py`，不新增一套训练程序 |
| CPU推理组件中的浮点线性层reference已正确后 | 在同一学习项目中做一个小型INT8数值参考；复用相同输入、权重和bias，对比量化前后的输出 | 保存原浮点基线、量化表示/刻度、权重与输出误差，以及包含量化参数的字节数；能够解释结果 |
| 有匹配低精度算子和硬件后 | 选择一条真实低精度计算路径，与对应浮点路径比较；CPU路径按实际指令/后端条件，CUDA路径仍需Gate C | 固定模型/形状/精度策略、软件版本、硬件、warmup与计时范围，先核对允许误差或任务质量，再记录内存、延迟和吞吐 |
| 后续部署优化阶段 | 在选定的一条服务路径中检查量化前后表现 | 明确收益来自权重存储、数据搬运还是计算，并同时报告质量变化与端到端指标；不另造完整量化运行时 |

CPU数值参考的第一版可以让一张权重矩阵共用一个明确的正刻度：先量化权重，再反量化，最后仍用原浮点输入完成线性计算。**这一版证明表示、误差与数据量，计算仍是浮点，不能声称已实现INT8计算加速。** 后续真正使用低精度算子时继续复用这份数值参照，不反过来让参照迎合被测实现。

首次实验只扩展已有正确线性层，使用固定小输入，检查最大绝对误差等明确量，并解释取整/超出表示范围时的变化。量化输出应采用事先说明的误差或质量标准，不机械套用原浮点实现的严格相等判据。刻度策略复杂化、整模型量化与高级算法等出现真实需求后再展开。

硬件按真实资源安排：本地已有约8 GiB的RTX 4060 Laptop GPU，进入Gate C后优先用于基础kernel、小模型与适配算子的实测；当前Ubuntu的CPU版PyTorch并不代表没有GPU，也不代表CUDA环境已经就绪。需要超出本机资源或指定架构时，可按用户意愿评估租卡，不能自动开通付费实例。硬件快照、环境验证与租用边界统一见[ENVIRONMENT.md §2.1](ai_theory/ENVIRONMENT.md)。

**这些是后续能力方向，不是现在冻结的Week17以后课表。** Week13～16、当前T11、T1～T24编号和原Gate标准保持；T20不增加量化项目，CPU小实验不反向成为T24或Gate B入口的新门槛。原Week16收口后再按真实基础、岗位与硬件确定具体课次。性能问题、测量与最终结论由用户独立掌握，Codex可提供重复测试和脚手架。

核验入口：[NVIDIA量化方案](https://docs.nvidia.com/deeplearning/tensorrt/latest/inference-library/quantized-types-schemes.html)用于核对刻度、取整与表示范围；[TorchAO量化实现层次](https://docs.pytorch.org/ao/stable/contributing/quantization_overview.html)用于区分低精度表示、转换操作与真正执行计算的算子。两者只在对应阶段选读，不要求现在安装库或购买课程；具体框架方案不当成全部量化方法的唯一规则。

### 对应视频

- 李沐：[31 `深度学习硬件：CPU 和 GPU`](https://www.bilibili.com/video/BV1TU4y1j7Wd/) 只对应硬件与计算背景。
- 两条基准课程没有系统对比 LLM training/inference memory composition；本周无强制视频，估算和对象分类由 `T20.md` 完成。

### 代码产出

```text
model_memory_estimate.py
```

### 通过标准

能区分 training memory 与 inference memory，不用“参数量乘 dtype”冒充完整显存占用。

还应能解释一个数怎样按刻度量化/恢复、为什么存在误差，以及量化参数也要计入容量。CPU量化实验与真实低精度性能验证属于上述后续阶段，不是本T的附加编程验收。

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
TTFT / TPOT / ITL各自的统计对象与边界
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

不能只写“快了 30%”；必须说明基线、输入、正确性和测量边界。operator benchmark 与 serving benchmark 分开：前者关注shape/dtype与算子计时，后者分别说明TTFT、TPOT、ITL、throughput、并发与缓存状态。

先让用户看一条请求的发送、首个输出、后续输出与完成时刻，再给指标命名。TTFT是首个输出前的等待；TPOT按单请求计算首个输出之后的平均每token时间；ITL记录相邻流式输出的时间间隔。两者采样对象不同，多token合并输出时尤其不能互换。实际定义与工具版本一起记录，参照[vLLM v0.31.0指标说明](https://docs.vllm.ai/en/v0.31.0/benchmarking/cli/)。

重复使用同一输入前，先声明是否允许命中已有prefix cache（前缀缓存）。CPU对比固定线程数；GPU对比说明同步和数据搬运是否计入。对应方法见[PyTorch benchmark教程](https://docs.pytorch.org/tutorials/recipes/recipes/benchmark.html)。这些是已有benchmark要求的具体化，不要求T23同时搭建完整在线服务。

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

## 10. AIInfraGuide：按当前问题调用的中文补充

2026-10-18 核对后纳入 [AIInfraGuide](https://caomaolufei.github.io/AIInfraGuide/)。具体文章、小节、适用位置及技术勘误见 [统一阅读映射](reference_materials/ai_infra/AIInfraGuide_阅读映射.md)；这里仅规定它在本路线中的位置。

| 当前模块 | 对应补充 | 何时使用 |
|---|---|---|
| T9 | PyTorch 入门的 Tensor、形状与 dtype 小节 | 先接上已经会的 NumPy；独立 layout 预测完成后再对照外部形状示例 |
| T10~T12 | 同文的 Module、autograd、完整训练循环 | 分别在本课对应机制讲清后选读；完整实现留在独立练习后，不新增同构训练作业 |
| T15~T18 | 词元/词嵌入、Self-Attention、Decoder Block | 跟随自己的 token -> attention -> block 链；先做本课 reference，再读相关完整代码 |
| T20~T21 | 训练显存账、LLM 推理基础、PagedAttention | 先列清自己的参数/梯度/状态/KV 对象，再对照估算与分块示例 |
| T22~T23 | Continuous Batching、LLM 推理指标与瓶颈分析 | 复用自己的调度仿真和 benchmark；不把站内速度或利用率数字当作本机结果 |
| Theory Gate 3 之后 | 与总规划 Gate C/D/E 对应的 CUDA、serving、通信文章 | 继续等待各 Gate 的实际前置；没有 GPU 时保留 CPU 路径，不照跑 CUDA 示例 |

**当前T1~T10与Theory Gate 1已通过，下一步T11。** 新资料计入原有每天30~60分钟预算，替换重复的第二讲解，不额外加一份每日阅读任务。T13已有ML/T8 generalization基础，T14仍可延期；不能因为网站目录齐全就新增重复课程或改变求职日期。

生成或获准润色 T 教程时，Codex 先查映射、实读相关小节，再把有用解释编排在当前对象与需求出现的位置。必学机制仍由正文讲清；外部阅读标明用途和停止点。API、数值语义及硬件限制由官方文档复核，遵守 MEMORY §9.8 的资料分工与独立练习保护规则。

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

下面约束生成或已经获准的润色，不是普通问答时自动改稿的权限。沿用 MEMORY §11/§13：R1 正式通过后同轮定向更新本课完整后半；整课正式通过后，同轮校准相邻、已提前生成的下一 T。两者都从最新版增量修改，保留用户增补，不改用户代码或 note；跨多篇更新仍需用户点明范围。

```text
保留：完整理论链、术语首次解释、公式推导、shape/value 例子、一个综合实验、AI Infra 连接
压缩：环境重复说明、资料导航、相同 invariant 的重复表述
分别判断：按能力闭环需要设置阶段停止点；存在真实认知墙时保留一次独立发现Reading Gate
删除：为了仪式感存在的多层闸门、重复 pass checklist、训诫式常见错误全集、大段固定 note 模板
```

同一个 invariant 正文完整解释一次，结尾最多压缩一次。不能为了显得精确，把 `ndim=len(shape)` 一类简单关系在五处重复或反复套复杂 LaTeX。

自检用于找出理解断点，不把“完成 checklist”冒充“掌握理论”。通常保留 3~5 个高价值问题即可。

---

# 进度记录模板

**每个T整课结束时，Codex都要提醒你亲自完成本课笔记。** 已有笔记就在原处补齐，具体收口提醒按MEMORY §13执行；笔记由你自己整理。下面只是可选记录方式，不是固定章节作业；提醒不新增验收闸门，也不追溯撤销旧课通过状态。

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

以下保留后续能力方向与前置关系，不提前冻结 Week17 之后的实际课表；实际安排仍在原 Week16 收口后，按 MEMORY §9.8 的调研与真实进度确定。

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

这一轮的产出是对象图、调用流程和一个可验证问题，不是“读完整仓库”。随后在vLLM V1与完整SGLang中二选一，只对照一个窄路径，不同时新增两个完整项目；进入时重新核对官方文档与commit。

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

从课程目录吸收的实验衔接统一见[课程对齐§4](reference_materials/ai_infra/2026-10-22_AI不止算法_课程对齐.md)。CPU阶段对原浮点组件定位一处成本；CUDA阶段先有边界/数值证据再解释性能；随后把选定算子接回同一小模型，核对逐层输出并区分加载、prefill与decode。高级量化只在基础表示/误差、模型计算与硬件条件齐备后按问题选一条路径，不把后续实验当成当前T线的附加作业。

量化补强按本规划T20的衔接段推进：T20先讲表示与误差；`mini-infer-cpu`的浮点线性层正确后，在同一项目补小型INT8数值参考；真正的低精度算子与部署收益按匹配硬件/后端及原Gate验证。这里不新增固定周次、整套量化运行时或T24通过条件，也不因课程目录出现INT8就抢在当前T11和Mini Redis之前。

之后才进入：

```text
Triton
mini LLM inference
KV Cache optimization
continuous batching
mini-sglang 的后续窄路径对照（复用前一轮阅读，不另开一次完整重读）
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
T9~T13、T15~T16：PyTorch与attention协调目标；T14 CNN可延期
T17~T24：Transformer / sampling / memory / KV Cache / batching / benchmark

原Week16完整收口后，再整理简历并试投。
Week17以后实际课表届时再定，当前只保留能力依赖和工时估算。
理论欠账如实记录，不把提前稿记成通过，也不让C++试投等待完整后置AI路线。

讲义负责连续讲懂，视频提供定向第二解释。
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
