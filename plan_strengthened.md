# C++ 系统工程 / AI Infra 求职总规划

> 对齐日期：2026-11-05。最新岗位与资料核对见[本轮调研](reference_materials/ai_infra/2026-10-22_规划对齐与岗位资料更新.md)。
> 学习者：FxorG，中山大学计算机科学与技术专业，2029届。
> 系统主线：Week1～Week13与Week14 Day1～Day3已通过。累计94个整日通过、95份Daily已生成；[Week14 Day3](week14/day3/day3.md)整日98/100正式通过；[Week14 Day4](week14/day4/day4.md)前置已满足，当前进入R1。
> 理论线：T1～T12与Theory Gate 1已通过；T12整课于2026-11-05以98/100正式通过，下一步T13 R1。T13～T21尚未通过，Theory Gate 2未通过；T13～T21已于2026-11-04按T11学习者主线标杆复检，文件更新不等于学习通过。
> Git：正式仓库文件有变化时按`MEMORY.md` §9.12完成本地commit；push与本地留痕分开授权，当前不自动推送。
> 投递顺序：完整学完原Week16，再整理简历并向匹配中小厂试投。11月是期望窗口，不据此缩减项目。
> 长期方向：LLM inference systems / serving与CUDA/Triton kernel optimization。

当前快照只记录“已完成、待完成、下一步”。逐次分数、测试数量与修复经过统一查[MEMORY §4](MEMORY.md)，不把历史计数混入当前状态。

| 文件 | 负责什么 |
|---|---|
| 本文件 | 路线、项目范围、阶段能力门槛与投递顺序 |
| MEMORY.md | 协作与教学规则、真实进度、验收沿革 |
| AI_Infra理论伴随线规划.md | T模块依赖、必做/选读边界与理论Gate |
| weekN/weekN.md、dayN.md | 当周安排与本次具体学习任务 |
| DAILY_INDEX.md、资料目录 | 查阅入口与按阶段使用的参考资料 |

这份文件只回答四个问题：

```text
现在已经会什么？
离目标岗位还缺什么？
接下来按什么顺序产出证据？
哪些课程和技术现在不应该抢主线？
```

详细 daily 教学规范、个人偏好和每一天的验收记录放在 `MEMORY.md`，不在总规划中重复。

---

## 1. 总判断

大的方向不需要推倒：

```text
C++
-> Linux / OS
-> 网络
-> 并发组件
-> epoll / Reactor
-> HTTP Server
-> Mini Redis
-> AI inference systems
```

需要调整的是目标优先级和项目表达：

1. 第一段实习以 **C++ 后台 / Linux 后台 / 系统、存储、网络基础设施** 为主投层；学完Week16后先向匹配中小厂和日常实习试投，再依据真实反馈调整。
2. **大模型平台后端、推理服务外围与AI云原生基础设施** 作为并行投递层。这些岗位同样需要Linux、网络、容器、调度和问题定位，不必等核心CUDA能力全部完成才尝试。
3. **大模型推理引擎 / CUDA / kernel优化** 是少量冲刺层与长期主目标，不把它伪装成当前已经完全匹配的岗位。
4. Reactor 和 HTTP Server 是 Mini Redis 的技术底座，不强行拆成三个注水项目。
5. BlockingQueue、ThreadPool、AsyncLogger 是重要组件证据，但不是三份独立简历项目。
6. 课程按项目暴露的问题调用，不再平铺 CSAPP、CS144、15-445、编译原理和分布式系统。

一句话版本：

> 第一段经历优先选择真正写系统代码、做测试与性能定位的岗位：可以叫C++系统，也可以叫AI平台后端；先取得可信工程证据，再向推理引擎、模型服务与GPU优化深入。

C++学习深度统一按[面试查漏地图](杂教程/C++与系统面试查漏地图.md)分层：项目中正确使用是必需项，容器/对象的常见实现、复杂度和失效是面试必需项，只挑StringLike、LRU等代表题手写；完整STL源码、ABI深水区、生产级allocator、lock-free/RCU和C++26提案按岗位或真实瓶颈后置。长期走AI Infra不会取消C++底座，也不要求先把所有C++社招题学到同一深度。

---

## 2. 当前真实能力基线

### 2.1 已完成的 Week1 ~ Week12

| 阶段 | 已完成内容 | 已形成的证据 |
|---|---|---|
| Week1 | 对象、内存、RAII、深拷贝、Rule of Three | `Buffer` / `StringLike`、ASan 初步 |
| Week2 | 移动语义、Rule of Five、智能指针、异常安全 | copy elision 观察、copy-and-swap、`noexcept` |
| Week3 | STL、迭代器、容器失效、RingBuffer、LRU | 可运行数据结构实现与边界分析 |
| Week4 | Linux fd、文件 I/O、process、pipe、mmap、6.S081 第一轮 | `mycat`、copyfile、重定向、pipe 实验 |
| Week5 | trap、page fault、thread、mutex、condition variable | OS 流程梳理、线程观察、同步实验 |
| Week6 | IP、TCP、socket、client/server、协议与状态观察 | blocking TCP server/client、抓包与状态解释 |
| Week7 | 并发抽象、condition variable、BlockingQueue | bounded MPMC queue、close contract、TSan |
| Week8 | ThreadPool、future、AsyncLogger、GoogleTest、CMake | 组件代码、CTest、TSan、benchmark、integration harness |
| Week9 | non-blocking I/O、epoll、LT/ET、partial I/O | Epoll Echo Server、`ss` / `strace`、LT/ET 与 half-close 实验 |
| Week10 | Buffer、Channel、EventLoop、Acceptor、Connection | Reactor Echo Server、CTest、ASan/UBSan、100 clients 与 fd-count evidence |
| Week11 | HTTP incremental parser、response encoder、route、keep-alive、pipelining | HTTP Server V1、CTest 54/54、raw client、curl、ASan/UBSan、ownership/runtime flow |
| Week12 | RESP2 request/reply、String KV、命令分发、共享 store、每连接输入输出与真实 Redis 第一层 | Mini Redis 受限 V1；CTest 74/74、多客户端/pipeline/binary/协议错误隔离/有限慢读、fd 回落与写背压 trace；Day7 差异与生命周期口述 |

Week1 ~ Week12 已正式通过。以后只在项目需要或面试复盘时回查，不再把这些周的完整 daily 复制进总规划。Week12 于 2026-10-11 收住受限 RESP2 String KV V1；TTL、恢复、性能与项目文档仍按 Week13~Week16 的后续 milestone 推进，不把这个出口升级成完整 Redis 或生产级服务。

### 2.2 当前优势

```text
算法与数据结构基础强
ICPC 亚洲区域赛银牌
CCF CSP 450，全国前 0.16%
NOIP / CSP-S / CSP-J 奖项
学习推进速度快，能独立推导和修改设计
已经有 C++ 资源管理、并发、测试和构建的连续代码证据
能够解释机制，不只会调用 API
```

这些优势对腾讯后台实习有直接价值，尤其能支撑算法面、编码面和“学习能力”判断。

### 2.3 当前短板

| 已有证据 | 尚缺什么 | 在哪里继续 |
|---|---|---|
| Reactor、HTTP Server、受限RESP/String KV、多客户端与背压场景 | AOF/恢复、可复现性能分析、最终项目文档与表达 | 原Week14～Week16 |
| TTL组件、命令、维护、Day6事务/缓存理解及Day7虚函数补缺已通过 | 把内存状态变成可恢复状态 | Week14 AOF/恢复 |
| 已有错误隔离、边界测试、sanitizer与调试证据 | 更完整的故障/恢复语义和能独立捍卫的性能结论 | Week14恢复、Week15故障/性能 |
| C++、OS、网络与并发代码基础 | 稳定口述、object model、atomic/CAS与memory order的定向补缺 | 项目伴随补缺与Week16复盘 |
| T1～T12：NumPy、求导/概率、分类训练、Tensor布局、Module状态、autograd与首次MLP训练 | 泛化实验，再到Attention/Transformer | T13起按依赖推进 |
| 已有本地RTX 4060 Laptop GPU、约8 GiB显存 | GPU运行环境尚未本轮确认，CUDA/kernel/serving优化能力尚未形成 | 原Gate C/D，按需评估租卡 |
| 独立学习与项目实现 | 真实团队协作、工程review与线上环境经历 | 实习、实验室或受限开源协作 |

Mini Redis、数据库第一层、性能证据、口述闭环和 memory model 由 Week12 ~ Week16 的项目与 milestone exit review 解决；Python/PyTorch 继续走 AI 伴随线；CUDA 和 serving framework 继续等待正式 gate；真实协作只能由实习、实验室、开源协作或多人项目补齐。

---

## 3. 岗位匹配审计

本节保留原腾讯样本用于区分三类岗位，不保证旧JD仍在招。2026-10-22的官方岗位抽样、届别限制与读取范围见[最新调研](reference_materials/ai_infra/2026-10-22_规划对齐与岗位资料更新.md)。招聘要求用于识别能力缺口，不直接变成额外课程清单。

### 3.1 岗位 A：C++ / Linux 后台开发实习

原腾讯微信安全后台日常实习样本要求集中在：

```text
C/C++/Java 之一
Linux 网络编程
数据结构与算法
编码风格与系统设计
C++ 项目、竞赛或开源经历加分
每周约 4 天、持续至少 4 个月
```

#### 当前匹配

```text
强匹配：算法竞赛、C++ 基础、Linux、TCP/socket、并发、测试意识
部分匹配：系统设计、工程代码、性能分析
已有项目：epoll/Reactor、HTTP与Mini Redis受限V1及TTL
尚缺证据：原Week14～16出口、长期可用性与真实协作
```

结论：

> 这是当前项目路线对应的主投方向。按原Week13~Week16完成TTL、AOF/恢复、测试/性能与项目出口后，再整理简历试投；岗位匹配仍逐项核对技术栈、毕业届别与到岗条件。

### 3.2 岗位 B：AI 业务后台 / 机器学习基础设施

原腾讯相关岗位样本名称包括：

```text
后台开发工程师 - AI 方向
机器学习基础设施开发 - 存储 / 向量检索 / 参数服务器
模型服务后台、AI 平台或数据基础设施
```

这类岗位通常仍重视：

```text
C++ / Python
Linux 与高并发服务
存储、缓存、检索或调度
可靠性、可扩展性和性能
一定的机器学习系统上下文
```

#### 当前匹配

```text
已经具备：C++、Linux、并发、服务端底座
已经补齐：Reactor、协议、KV、TTL，Python/NumPy与Tensor基础
仍需补齐：持久化、benchmark、PyTorch inference及模型服务上下文
```

结论：

> 这是第一轮可以并行尝试的相邻方向，不再统一写成“等未来才投”。当前大模型平台后端岗位存在只要求一门主语言、Linux与工程基础的入口；云原生AI Infra也会从OS、网络、容器、调度和排障招人。最好的桥梁不是立刻堆CUDA名词，而是把Mini Redis做成可信系统项目，同时继续补真实Python/PyTorch inference证据。

### 3.3 岗位 C：大模型推理引擎 / CUDA AI Infra

原腾讯大模型推理引擎岗位样本要求包含：

```text
C/C++ 和 Python
CUDA / 异构芯片编程
vLLM / SGLang / TensorRT-LLM 等推理框架
深度学习网络与算子底层实现
推理调试、性能分析和优化经验
```

#### 当前匹配

```text
已有可迁移底座：C++、资源管理、并发、系统调试、benchmark 意识
关键缺口：Python/PyTorch、Transformer inference、CUDA、GPU profiling、真实推理框架贡献
```

结论：

> 不把“直接大模型推理引擎实习”设为首批必须命中的目标。当前公开核心岗位常明确要求CUDA、GPU profiling、vLLM/SGLang及cache/调度优化；可以少量冲刺，但主线成功标准仍是拿到高质量C++/系统/AI平台基础设施经历。长期AI Infra目标不变。

### 3.4 招聘批次与时间条件

用户按当前学制为 2029 届。需要把两种实习分开：

```text
正式暑期实习 / 校招批次：常按毕业年份限制，2027 年初未必面向 2029 届
日常实习 / 导师直招：更看当前能力、到岗时间和连续实习时长
```

因此Week16完成后的首批试投及后续投递，不只盯统一校招入口：

```text
腾讯招聘官网持续投递
牛客 / 实习信息渠道筛选日常实习
校友、竞赛圈、实验室和导师内推
开源社区或技术群中的直接招聘
广州 / 深圳岗位优先关注
```

实习可用性是硬条件。投递前必须诚实确认：

```text
每周能到岗几天？
能持续几个月？
区域赛、当前课程与后续学期如何协调？
是否能在广州 / 深圳线下？
```

可到岗天数、连续时长和开始时间按每个岗位核对，不承诺尚未确定的空闲时间。投递与入职是不同时间点；学期和赛程不匹配时诚实说明，不能单凭没有面邀就诊断为技术不足。

### 3.5 本地牛客面经对规划的校准

本地两份资料：

```text
nowcoder_cpp_infra_aiinfra_200_recent.md
nowcoder_cpp_infra_aiinfra_500_recent3y_with_questions.md
```

其中 200 篇汇总适合看主题频次；500 篇汇总包含 352 篇可识别原帖问题、累计 7216 条，适合看真实追问方式。

200 篇汇总的头部主题同样集中在：项目深挖 146、MySQL/数据库 94、内存管理 79、TCP/UDP/HTTP 72、生产级代码 72、对象模型/虚函数 64、线程/线程池 61、Redis/缓存与存储系统各 53、fd/系统调用/IO 50、性能压测 48、LLM Serving 42。它和 500 篇原问题的方向一致。

500 篇的主题覆盖为：

```text
C++ 对象 / 资源：414 篇
项目 / 行为：397 篇
算法 / 手撕：342 篇
Linux / OS：310 篇
分布式 / 工程：265 篇
数据库 / 缓存：250 篇
网络 / Socket：189 篇
高性能网络：156 篇
AI Infra：152 篇
```

对 7216 条原问题做关键词归类，只用于比较相对密度，不当作严格统计概率：

```text
项目 / 性能 / 排查：1058
C++ 对象 / 内存：764
Redis / MySQL / 存储：739
并发 / 内存模型：662
算法 / 手撕：520
AI Infra：400
网络：399
Linux / OS：383
分布式 / RPC：317
```

腾讯相关原问题也呈现同一模式：项目设计与性能证据最密集，Redis/MySQL/存储、并发、C++ 对象模型紧随其后；网络与 OS 往往不是孤立背诵，而会继续追问 epoll、协议状态、系统调用、数据库锁和高并发取舍。

因此规划只增加四类门槛：

```text
1. 已学基础进入 milestone exit 口述复盘，不重学一遍 daily
2. 补 C++ object model + atomic/CAS/memory order 第一层
3. Redis/MySQL/存储随 Mini Redis 分阶段进入，不拖到最后集中背
4. 项目必须保留故障、排查、指标和优化证据，不只展示 happy path
```

数据边界：两份资料混有日常实习、暑期、校招和社招，也有汇总/分析帖；关键词可能重复命中同一道组合问题。因此它们用于决定优先级和追问形态，不用于估算录取概率，也不把某个社招系统设计题直接升级为实习前硬前置。

2026-10-12 再次对照本地原问题与牛客后台实习样本，明确采用 [C++ 项目伴随补缺安排](C++项目伴随补缺规划.md)：虚函数属于“提过第一层、尚未完整练过”，安排 Week13 Day7 独立小专题；已有 RAII/移动/智能指针等先诊断，再决定是否补课。编译链接跟随 Week14 AOF，对象占用、额外分配与容器代价跟随 Week15 性能。面经决定查漏方向，项目继续决定主线与产出。

---

## 4. 2026 年底简历应该有什么

### 4.1 竞赛经历

竞赛已经足够强，简历只需准确、紧凑地列出：

```text
ICPC 亚洲区域赛银牌
CCF CSP 450 / 全国前 0.16%
NOIP / CSP-S 代表性奖项
```

不要继续靠增加普通算法题数量提高简历。算法维持手感即可。

### 4.2 主项目：Mini Redis

简历上的主项目不是“模仿 Redis 命令”，而是一个可以解释的 C++ event-driven KV server。

最低闭环：

```text
TCP server + non-blocking fd + epoll
Reactor ownership 和 callback 边界
RESP parser，支持粘包、半包和 malformed input
SET / GET / DEL / EXISTS
多 client 与连接生命周期
TTL / expiration
AOF append + restart recovery
错误处理与 graceful shutdown
GoogleTest / CTest / ASan / TSan
benchmark 与一份可复现结果
README、架构图、运行示例、已知限制
```

推荐增强项只在 V1 稳定后选择：

```text
LRU / LFU 或内存上限
incremental rehash 或更清楚的数据结构实验
event-loop latency / throughput 分析
简单 metrics
与 Redis 的协议或性能对比
```

不做：

```text
完整 Redis replication / cluster
完整 Redis 源码复刻
为了数量同时开多个半成品 server
没有数据支撑的“高性能”描述
```

#### 4.2.1 Redis / MySQL 基础怎样进入主线

当前真实基础不是“已经系统学过 Redis/MySQL”，而是知道它们大致解决什么问题、接触过少量用法，但知识已经不成体系。规划因此采用 **项目走到哪里，理论补到哪里**，不暂停 Mini Redis 去平行通关两门数据库课。

```text
Week12 Day1~Day3：先完成 RESP 编码、解析与 framing；这里不要求先会 Redis 内部实现

Week12 Day4 开工前：补 Redis 第一层
-> database / cache / in-memory KV store 分别在解决什么问题
-> client、server、keyspace、key、value、command、reply 的关系
-> Redis String 是 binary-safe byte sequence；Mini Redis V1 只实现 string -> string 子集
-> PING / ECHO / SET / GET / DEL / EXISTS 怎样改变或观察 server state
-> cache 与 authoritative database 的边界，memory-only 与 persistence 的边界

Week12 Day7：把本周实现与真实 Redis 做第一次对照
-> data types、event loop、expiration、persistence 只建立地图，不完整展开

Mini Redis V1 收口后、Week13 开头：补 MySQL 第一层
-> table / row / column / schema / primary key
-> SELECT / WHERE 的最小读法
-> index 为什么存在，B+ tree 与 page/range scan 的直觉
-> clustered / secondary / covering index 与回表
-> 用 EXPLAIN 观察 optimizer 选择，不靠猜测“是否走索引”

Week13~Week14 按项目需要继续：
-> expiration 与 eviction
-> transaction / ACID / isolation / MVCC / lock
-> AOF/RDB 与 redo/undo/binlog
```

这条安排有两个硬边界：

1. Redis 第一层必须在写 `KvStore` 与 command dispatcher 前讲，不再默认已有基础。
2. MySQL 的术语、表模型和最小 SQL 必须先于 B+ tree / `EXPLAIN` 实验；不能把一串索引名词当作数据库入门。

参考入口以官方资料为准：[Redis data types](https://redis.io/docs/latest/develop/data-types/)、[Redis keyspace](https://redis.io/docs/latest/develop/using-commands/keyspace/)、[Redis Strings](https://redis.io/docs/latest/develop/data-types/strings/)、[MySQL EXPLAIN](https://dev.mysql.com/doc/refman/8.4/en/explain.html)。官方文档用于查证；daily 负责把当前项目需要的内容顺着讲清楚。

### 4.3 副证据：Reactor / HTTP / 并发组件

简历表达方式：

```text
Reactor / HTTP 可以作为 Mini Redis 的底层演进过程，或一个独立但较短的网络服务证据
ThreadPool / AsyncLogger / BlockingQueue 写在项目技术细节或 GitHub 组件目录中
不把每个组件包装成“生产级项目”
```

面试必须能回答：

```text
为什么使用 epoll？
readable 不等于一次 read 完，代码如何处理？
ET / LT 的边界是什么？
fd 关闭后如何防止 stale event？
EventLoop、Connection、Buffer 分别拥有谁？
backpressure 在哪里出现？
shutdown 如何避免丢任务、死锁和 use-after-free？
测试和 benchmark 分别证明了什么？
```

### 4.4 AI 伴随证据

2026 年底不要求 CUDA 大项目，也不要求为了第一次投递提前完成 T24。T24 的进取目标是 2027 年 3 月，周均投入不足时可顺延到 2027 年第二季度。系统主线按时闭环时，AI 伴随线至少形成：

```text
T1~T8：NumPy、shape/matmul、stable softmax、最小 ML workflow；Ex1 与 T7 共用一份 linear-regression evidence
T9~T13：PyTorch Tensor/Module/autograd/MLP/generalization
T15~T16：token/embedding/mask 与 single-head attention reference
Stretch：T17~T18，能够从 token IDs 串到 decoder-only logits
```

#### 传统ML → DL → Transformer的交接

**当前沿T模块继续，不另开完整传统ML或DL通关线。** T8是当前传统ML连续学习的停止点，未学算法以后由岗位、课程或项目需求再补；T13的泛化/正则化等共用基础仍按原计划学习。

```text
T9 Tensor（已通过）
-> T10 用已会线性分类器学习Module与状态
-> T11 用已会标量链学习autograd
-> T12 先从两个logits的判断推出直线边界，再用XOR进入多层模型、隐藏表示与ReLU
-> T13 泛化/正则化 -> T14 CNN/ResNet（可延期）
-> T15 token/embedding/mask -> T16 attention -> Theory Gate 2
-> T17+ Transformer与LLM推理
```

Tn.md是当前主教材；ML.md、吴恩达和李沐课程按本T的具体需要调用，官方文档用于查证。当前不要求顺序读完ML.md剩余算法，也不用先补完整DL才能进入T12。既有作业等价验收、Kaggle与Gate范围保持，具体规则见理论规划§2.5～§2.6。此处只明确交接，不改变Mini Redis主线、里程碑或投递顺序。

提前稿后半编排校准（2026-11-04）：T13的核心连续完成baseline、weight decay受控对照、validation选checkpoint、恢复与最终test；相关方法和实验纪律扩展随后选读。T14核心完成数值卷积、NCHW/shape、residual mismatch与projection，并在同一无BatchNorm组件上观察state与Tensor字节；pooling、hook、BatchNorm均不抢核心主线。详细任务与PASS统一见[理论规划T13/T14](AI_Infra理论伴随线规划.md)。这只调整教材组织与核心/补充边界，不改变当前T12下一步、T14可延期、既有Kaggle或Theory Gate范围。

教材准备（2026-11-04复检）：[T15](ai_theory/T15/T15.md)建立编号/嵌入/补齐与允许表；[T16](ai_theory/T16/T16.md)完成单头内容汇总、批次和位置隔离；[T17](ai_theory/T17/T17.md)扩为多头并完成前置LayerNorm、残差与逐位置FFN的block；[T18](ai_theory/T18/T18.md)把同一block接到token/position embedding、final norm与LM head之间；[T19](ai_theory/T19/T19.md)把`[B,V]` logits接到token选择；[T20](ai_theory/T20/T20.md)建立训练/推理对象与INT8表示账；[T21](ai_theory/T21/T21.md)完成full recompute、连续KV Cache与block table寻址。各篇首次自定义函数均补齐用途、返回与状态变化；提前稿不前移学习任务，当前下一步是T13 R1，Theory Gate 2未通过。

可展示的代码证据优先是：

```text
stable_softmax.py
tensor_layout.py
module_inference.py
autograd_inspect.py
single_head_attention.py
若按时完成：decoder_only_forward.py
```

这项证据的作用是证明你理解 AI workload 和 inference data flow，不是冒充已经做过推理引擎。`tiny_transformer_reference` 的目标时间是 2027 年 3 月，属于第一次投递后的增强证据。

---

## 5. Week9 之后的项目里程碑

自然周只是标签，是否进入下一阶段由 exit evidence 决定。

### Milestone A / Week9：non-blocking I/O 与 epoll（已通过）

核心问题：

> blocking socket 为什么限制单线程服务多个连接，readiness 到底承诺了什么？

学习与实现：

```text
fcntl / O_NONBLOCK
EAGAIN / EWOULDBLOCK
partial read / partial write
epoll_create1 / epoll_ctl / epoll_wait
LT / ET 第一层
accept/read/write 的 drain loop
连接状态与输出缓冲区
只在存在 pending output 时关注 EPOLLOUT，发送完后取消
Epoll Echo Server
```

出口证据：

```text
多 client 可同时通信
一个慢 client 不阻塞其他 client
能处理半包、partial write、peer close
能解释 LT / ET、readiness 与 fd lifetime，不把“可读”误解成“一次读完”
能解释持续监听 EPOLLOUT 为什么可能造成无效唤醒和 CPU 空转
无明显 fd leak
能用 strace / ss 解释关键行为
能画出 event -> handler -> state change 流程
```

### Milestone B / Week10：Reactor V1（已通过）

核心问题：

> 如何把过程式 epoll loop 拆成 ownership 清楚、可继续演进的组件？

建议边界：

```text
EventLoop：等待事件、分发 callback
Channel：fd 关注的事件与 callback
Connection：socket lifetime、input/output buffer、协议状态
Acceptor：监听 fd 与新连接建立
Buffer：增量读写，不假设一次完成
TimerQueue：只做支撑 timeout / TTL 的最小定时器模型，核心 Reactor 稳定后再接入
```

出口证据：

```text
每个 fd 和 Connection 的 owner 可解释
remove / close / callback 生命周期可解释
支持 write buffering 和 writable interest 切换
有 deterministic tests 或可复现实验覆盖关键边界
能说明 stale event、callback 中 close/remove 和 object lifetime 的关系
```

不提前做多 EventLoop、多线程 Reactor、io_uring 或 lock-free。

Week10 原定的 C++ 第一层对照范围如下，挂回 Week7~8 并发组件和 Reactor lifetime：

```text
virtual dispatch、object layout、virtual destructor 第一层
lambda capture 与 captured object lifetime
template instantiation 的编译期含义
alignment、cache line、false sharing 第一层
atomic 与 mutex/volatile 的边界、CAS、acquire/release、happens-before 第一层
```

Week10 Reactor 主线已通过；上述主题在出口教程中出现，不等于每项都已完成独立理解与实验。虚函数的完整补缺已在 Week13 Day7 收口；其他点先抽查真实调用与已有证据，缺多少补多少，不回退重学 Week10，也不引入复杂模板或 lock-free 实现。

### Milestone C / Week11：HTTP Server V1（已通过）

核心问题：

> Reactor 如何承载一个真正的 application protocol？

最低范围：

```text
HTTP/1.0 或受限 HTTP/1.1
incremental request parser
GET 静态响应或少量固定 route
Content-Length
malformed request 的明确响应
keep-alive 是否支持要写清 contract
curl + 自写 tests
概念上串清 DNS -> TCP -> TLS -> HTTP；V1 不要求自己实现 TLS
```

出口证据：

```text
协议 parser 与 transport 分离
半包 / 多次 read 能正确推进 parser state
curl 可复现实验
错误输入不会让 server 崩溃
能解释 HTTP/1.0、HTTP/1.1、HTTPS 的边界，以及 TLS 保护了什么
```

### Milestone D / Week12：Mini Redis V1 - RESP 与 KV（2026-10-11 正式通过）

```text
RESP2 最小 parser / encoder
SET / GET / DEL / EXISTS
错误响应
多个 client
协议测试
```

Day1~Day3 不回退补完整 Redis 课程。Day4 写 `KvStore` 前，daily 必须先从 database/cache/KV store 的问题出发，讲清 client、server、keyspace、String value、command/reply 和本周六条命令的状态语义；再让用户独立设计 command/store V1。

出口：网络层、协议层、命令层和存储层边界清楚；能解释自己的关联容器（当前实现为 `std::map<string,string>`）在 server 中扮演什么角色；同时能对照经典 Redis 的主要命令执行路径解释常见数据类型和事件循环，知道现代 Redis 还包含 I/O threads 与后台任务，并准确说明本项目只实现了哪些语义。

Week12 只为 MySQL 建立一座桥：Redis 当前是内存 KV 模型，MySQL 是关系模型，二者不是“换个命令的同一种数据库”。本周不要求在尚未理解 table/row/index 的前提下硬做 `EXPLAIN`。

### Milestone E / Week13：Mini Redis V2 - 生命周期与 TTL

Week13 开头先用一个窄教程补 MySQL 第一层，再进入索引实验：

```text
table / row / column / schema / primary key
SELECT / WHERE 的最小语义
MySQL B+ tree index、clustered/secondary index、covering index、回表第一层
EXPLAIN 的目的与“是否走索引不能只靠猜”
最小实验：同一个小表对比一次 full scan、普通 index query 和 covering index query 的 EXPLAIN
```

```text
TTL / EXPIRE / PTTL 中选择最小命令集合
lazy expiration
必要时增加周期性清理
连接 idle：无请求时维护仍能运行，保留长连接，不把 key 到期当成关闭连接
shutdown：核对已有连接清理/进程终止边界；本周不新增优雅停机框架，后续工程收口仍需明确停机策略
时钟注入或可控测试
```

出口：过期语义有 deterministic evidence，不靠长时间 sleep 测试。

伴随补缺：

```text
Redis expiration 与 eviction 的区别
cache penetration / breakdown / avalanche 的问题模型与基本处理
MySQL ACID、transaction、isolation、MVCC、lock/deadlock 第一层
```

Day7 的 V2 核心收口后，另安排约 90~150 分钟的虚函数/对象模型小专题，可分两次完成。先接上类与对象、构造/析构、继承和基类部分，再讲基类引用调用、override/重载/隐藏、纯虚与抽象、虚析构、构造/析构阶段和对象切片，最后用常见虚表模型解释；做一个独立小实验，不改 TTL 时钟或现有 Reactor 架构。完整安排见 [C++ 项目伴随补缺](C++项目伴随补缺规划.md)，独立讲义见 [C++ 面试语法小册](杂教程/C++面试语法小册.md)。

完成状态（2026-10-26）：Day7整日98/100正式通过，V2与虚函数/对象模型补缺均已收口；`override`的重写/重载术语已补准。机械lab未在最终验收中重复执行，理解证据来自本人笔记与口述，不冒记新的编译结果。

### Milestone F / [Week14](week14/week14.md)：Mini Redis V3 - AOF 与恢复

```text
append-only command log
启动 replay
partial/corrupted tail 的明确策略
flush policy 的范围说明
crash consistency 只做到能证明的层次
```

出口：重启后数据可恢复，有故障实验，不声称完整 Redis durability。

具体七日依赖以Week14周规划为准：先从SET/EXPIRE后重启丢状态的行为问题推出可重放记录，
再依次完成完整追加、clean replay、TTL跨重启、服务器接入和尾部/同步故障。
小林Coding用于建立行为入口，Redis/Linux/MySQL官方资料用于校准实现边界；
不把外部目录机械改写成本周知识清单。

伴随补缺：

```text
真实 Redis RDB / AOF 的目标、取舍和恢复边界
MySQL redo / undo / binlog 各自解决什么问题，只到第一层
replication、sharding、consistency、RPC 的最低系统词汇
不实现 Redis Cluster、Raft 或分布式事务
```

C++ 伴随小节跟着 AOF 的 `.hpp/.cpp` 多源文件构建，讲声明/定义、static/extern/inline、编译与链接、模板定义可见性和库的第一层。这里的“多源文件”不是 Redis 7+ 的多文件 AOF。构造/析构、特殊成员函数、const/noexcept 与 move/forward 先对照已有代码诊断，只补不能解释的点；不新增完整编译原理课程。

### Milestone G / Week15：测试、故障与性能

```text
parser / command / TTL / AOF unit tests
multi-client integration tests
ASan / TSan
fd / memory leak 检查
throughput 与 latency baseline
固定环境、workload、样本与统计方式
用现象先区分 CPU / memory / I/O / lock contention，再选择 gdb / strace / perf / sanitizer
perf / flame graph 只在真实瓶颈出现后使用
```

出口：每条性能结论能从命令、环境和结果复现；至少保留一条“现象 -> 假设 -> 工具 -> 证据 -> 修改 -> 复测”的完整排查链。

C++ 伴随小节从真实 Buffer/string/KvStore 观察对象大小、对齐、额外分配和容器行为。智能指针/捕获生命周期与 atomic 第一层复用旧并发组件抽查，不给单线程 Mini Redis 强加并发，不为了练内存池先改正确代码。

### Milestone H / Week16：简历项目收口

```text
README
架构图
build / run / test / benchmark instructions
设计取舍
最难 bug
已知限制
与真实 Redis 的差距
2 分钟与 10 分钟项目讲稿
90 秒自我介绍、为什么投后台/AI Infra、个人贡献与实习时间说明
1~2 个和本项目直接相关的场景设计：限流/backpressure、cache failure 或单机到分片的边界
```

出口：一个不了解仓库的人能按 README 跑起来；简历上的每句话都能指向代码或实验。

Week16 只做前面伴随补缺的收口，不再临时开完整数据库课程：

```text
Redis 常见数据结构、过期、淘汰、RDB/AOF 第一层
MySQL B+ tree index、transaction、ACID、isolation level 第一层
atomic/CAS、acquire/release、happens-before 第一层
把概念挂回 Mini Redis 的设计，不机械背题库
```

---

## 6. 双线推进顺序与时间边界

当前系统主线的Week14 Day1已整日通过，分轮为98/98/99；Day2分轮99/99/97并以97/100整日通过；Day3分轮96/98/98并以98/100整日通过；Day4前置已满足，当前进入R1。理论线下一步T13 R1。Week13已整周通过，完整状态见文件开头，历史证据见MEMORY §4；旧月份与旧计数不再作为“当前任务”。

| 顺序 | 系统主线 | 理论线协调目标 | 保持的边界 |
|---|---|---|---|
| 已完成Week13 | [Day7整周收口](week13/day7/day7.md)（整日98/100，R1历史95/100） | T11已完成：从标量链进入autograd | TTL、虚函数补缺和T11均已收口，不重做 |
| 当前Week14 | [AOF/恢复周规划](week14/week14.md)，Day1～Day3整日已通过；[Day3](week14/day3/day3.md)整日98/100；[Day4](week14/day4/day4.md)当前进入R1 | T12整课已完成首次MLP训练、状态变化与恢复边界，下一步T13 R1 | 系统下一步是Day4 R1；不把恢复语义换成只会写文件 |
| Week15 | 原故障测试、瓶颈定位与性能证据 | T13、T15～T16；T14可延期 | 用户掌握性能问题、测量与结论，机械脚手架可委托 |
| Week16 | 原项目文档、表达与完整出口 | 复检理论欠账；T17～T18为进阶项 | 不拆提前投递版，不降低原项目标准 |
| 原Week16正式完成后 | 整理简历、小范围试投、用反馈定位缺口 | 按真实完成能力呈现 | 此时再制定Week17以后实际课表 |

后续理论的依赖顺序仍是T17～T18、T19～T21、T22～T24；CPU推理与GPU路线仍受原Gate约束。**这些是能力顺序，不是已经排定的Week17以后课表。**

11月试投为用户意向。原2027年1～3月及第二季度的估算只用于判断容量，不是已承诺的完成日期；Week16收口时结合区域赛、实际投入、岗位与硬件再排期。T24不成为第一批C++/后台试投的额外前置。

### 6.1 主线 milestone 与 T 模块出口锚点

这里的“前”是协调目标，不是说 T 线没完成就禁止写主线代码；它用于防止 AI 线无限拖延：

| 系统 milestone 出口前 | AI 理论至少到达 | 连接点 |
|---|---|---|
| Week9 | T1 | array metadata、bytes estimate、reference 思维 |
| Week10 | T3 | shape、matmul、batch 维度，为后续 operator 做准备 |
| Week11 | T6 | gradient/概率映射、stable softmax 与数值稳定性 |
| Week12 | T8 / Theory Gate 1 | Ex1 或 T7 fallback 提供 linear evidence；T8 完成 multiclass softmax 与最小 ML workflow |
| Week13 | T10 | PyTorch Tensor、Module、parameter、inference mode |
| Week14 | T12 | 两个logits到线性边界，再到MLP training/inference flow |
| Week15 | T13 + T15~T16 | generalization 第一层、token/mask、single-head attention |
| Week16 | 协调目标T16；T17～T18为进阶项 | 欠账如实登记，AI岗位按实际证据匹配；C++/后台试投不等待后置完整AI路线 |

AI 理论线按用户真实投入调整为：

```text
每天 30~60 分钟
每周名义 3.5~7 小时，实际可持续目标 4~6 小时
系统主线每天3小时以上为平常计划值，区域赛备赛期按实际可用精力调整
```

不在 Mini Redis 前启动 CUDA 或 vLLM 源码主线。若两条线冲突，先保系统 milestone；但不再用“主线重”作为无限期暂停 T 线的默认理由，而是记录延期并执行 AI 规划中的删减顺序。

近期有区域赛备赛/参赛、周末外出与精力下降的实际背景，具体赛程和有效学习时长未确认；不把全部自然日当作足额学习日，不要求为赶投递日期熬夜或缩减既定项目内容。按真实进展校准时间，内容与通过标准保持。

如果实际学习继续明显快于日历，不靠增加教程字数拖慢：

```text
先扩大真实测试和故障场景
再增强项目边界与性能证据
完成Week16后再整理简历并投递
最后才开启下一门课程或 CUDA gate
```

---

## 7. 求职准备不是最后一周才开始

### 7.1 从 Week9 开始维护 evidence ledger

每个里程碑记录：

```text
实现了什么
为什么这样设计
踩过什么 bug
怎么定位
测试证明什么
benchmark 环境和数字
目前不支持什么
下一步如何优化
```

这不是要求每个 demo 写完整 `interview.md`。只对简历候选项目做正式整理。

### 7.2 每两周做一次岗位雷达

只抽取 5~10 个同类 JD，记录：

```text
高频硬要求
当前已有证据
还缺什么
是否值得改变下一个 milestone
```

原则：只有多个目标岗位重复出现、且能通过项目形成证据的缺口，才调整主线。

### 7.3 面试知识面

2027 年第一轮后台实习前，至少能解释：

```text
C++ object lifetime、RAII、copy/move、smart pointer
virtual dispatch / virtual destructor / object layout 第一层，能用小实验解释
STL complexity 与 iterator invalidation
thread、mutex、condition variable、data race、deadlock
atomic/CAS、acquire/release、happens-before 第一层
process/thread、virtual memory、page fault、system call
fd / open file description / mmap
TCP handshake/close、flow control、socket API
non-blocking I/O、epoll、LT/ET、partial I/O
Reactor ownership、connection lifecycle、backpressure
DNS -> TCP -> TLS -> HTTP 完整链路第一层
Redis 基础数据与常见语义
MySQL index / transaction / isolation 第一层
replication / sharding / consistency / RPC 的最低系统词汇
项目测试、debug、benchmark 和 trade-off
```

### 7.4 Milestone exit 口述复盘

不另开“500 题刷题线”。每个 milestone 结束时，用 30~60 分钟闭卷回答 4~6 个代表问题：

| 出口 | 复盘主题 | 必须挂到的证据 |
|---|---|---|
| Week9 | TCP、non-blocking、epoll、LT/ET、系统调用 | Epoll Echo Server、`ss/strace` |
| Week10 | ownership、object model 第一层对照、thread/atomic/memory order | Reactor lifetime、Week7~8 并发代码；虚函数完整实验转 Week13 Day7 |
| Week11 | HTTP versions、HTTPS/TLS、协议 parser | HTTP Server、curl/抓包 |
| Week12 | Redis/KV/cache 第一层、真实 Redis 数据模型地图 | KV implementation、真实 Redis 对照 |
| Week13 | MySQL 表模型、B+ tree/index、expiration/eviction；独立虚函数补缺 | 三组 EXPLAIN 对照、TTL tests、可控时钟；另一个小调用/析构实验 |
| Week14 | AOF/recovery 主线；RDB、WAL、replication/consistency 只作角色对照；C++ 编译链接 | restart/fault experiment、实际 `.hpp/.cpp` 多源文件构建 |
| Week15 | CPU/memory/I/O/lock bottleneck、工具选择；内存与容器代价 | benchmark 与排查链、对象和分配的实际观察 |
| Week16 | project deep dive、system trade-off、行为问题 | README、代码、指标和时间说明 |

每题按同一结构回答：

```text
30 秒：定义与结论
2 分钟：完整机制和因果链
项目证据：自己的代码、命令、失败实验或 benchmark
边界：当前实现没做什么，代价是什么
```

已能顺畅回答且有证据的题直接通过；答不顺才回查 daily/note。不得为了形式抄写大量标准答案。

基础语法补缺采用 [项目伴随安排](C++项目伴随补缺规划.md)，不另开八股主线。教材中出现过、能认出名词、能解释实际调用、有独立证据是不同状态；没有项目使用场景的明确基础缺口可做一个小实验，不强迫项目采用该特性。Week16 复盘时检查欠账是否闭环，不等到投递前一次补整套 C++。

算法训练：

```text
每周 1~2 次保持手感
以限时编码、边界和表达为主
不再把大量简单题当主线进度
```

### 7.5 简历投递版本

**顺序固定：按原规划学完Week16 -> 再整理投递简历 -> 向匹配中小厂小范围试投。** Mini Redis的TTL、AOF/恢复、正确性/故障/性能与原定项目文档安排保持，不前移、删减或另拆提前投递版本。11月是用户期望窗口，不能覆盖这个先后条件。

首批目的为检验简历能否约面、了解真实面试过程并发现缺口，不设11月必须拿offer。简短记录简历版本、岗位/资格/到岗条件、响应、面试卡点和下一修改；根据具体反馈区分知识、项目证据、表达与编码问题，不从一两次结果推翻主线。

第一版简历建议结构：

```text
教育背景
竞赛荣誉
Mini Redis 主项目
Reactor/HTTP 或并发组件的补充证据
技能：只写能被追问的内容
GitHub / 博客 / 视频总结：有高质量内容再放
```

不要写：

```text
精通尚未深入的技术
没有 benchmark 的“高性能”
没有故障语义的“高可用”
把课程跟练包装成原创生产系统
把还没开始的 CUDA/vLLM 写进技能栏
```

---

## 8. 课程如何进入主线

### 8.1 MIT 6.S081：长期完整通关

6.S081 是 OS 主伴随线，最终需要完整通关，但不与项目每天双开。

```text
Reactor 前后：interrupt、sleep/wakeup、file descriptor、driver 与 I/O 相关部分
Mini Redis 持久化阶段：file system、buffer cache、logging
项目阶段间隙：补完剩余 lecture/lab，形成完整通关记录
```

标准：能把课程机制映射到代码、trace 和实验，不只是看完中文讲义。

### 8.2 CSAPP：现在按主题选学

不从第一页完整重刷。按项目问题调用：

```text
linking / ELF：构建、符号、静态库、动态库问题出现时
ECF / system I/O：Reactor 与 signal/error path
network programming：Week9~11
concurrency：线程池和 EventLoop 边界复盘
memory hierarchy：benchmark 与 cache 问题出现时
virtual memory：mmap、allocator 或性能问题出现时
```

可选实验：Proxy Lab 与当前网络项目高度相关，但不能阻塞 Mini Redis。

### 8.3 Stanford CS144：Reactor/Mini Redis 闭环后评估

CS144 实现 TCP/IP protocol；当前主线使用 Linux kernel TCP 写 application server。两者相关但不是同一任务。

开启 gate：

```text
Reactor / HTTP / Mini Redis 至少一个稳定闭环
确实需要加深 TCP protocol implementation
不会推迟第一版简历和投递
```

可以先选 ByteStream / reassembler，也可以之后完整做 checkpoints。

### 8.4 CMU 15-445：Mini Redis V1 后选学

第一轮只选与存储项目直接相关的内容：

```text
storage layout
buffer pool / memory management
hash index / B+ tree
concurrency control
logging / recovery
```

relational optimizer/executor 和完整 BusTub 不作为 Mini Redis 前置。

### 8.5 编译原理：完整课程后置

当前只需要 toolchain literacy：

```text
preprocess -> compile -> assemble -> link
translation unit
symbol / relocation
ELF
static / dynamic linking
ABI 第一层
```

由 CMake 实验、`nm/readelf/objdump` 和 CSAPP linking 补齐。明确转向 AI compiler / LLVM / MLIR / Triton 后，再完整学编译原理。

### 8.6 MIT 6.824：分布式阶段后置

6.824 使用 Go 并以 Raft / distributed KV 为主。开启 gate：

```text
Mini Redis V1 完成
storage 第一轮完成
明确要进入 replication / consensus
愿意单独安排 Go 与分布式系统阶段
```

### 8.7 计算机组成与硬件基础

当前不并行开完整 CS61C/Nand2Tetris。先补项目所需的最小模型：

```text
data representation
instruction / register / stack
cache / locality / cache line
virtual address / page table / physical memory
atomic / memory ordering 第一层
```

进入 CUDA Gate 前再做一次体系结构 prerequisite audit。

---

## 9. AI Infra 长期路线

AI 理论伴随线的详细周计划见：

```text
AI_Infra理论伴随线规划.md
```

系统主线不变，AI 线按 readiness gate 开启。

### 9.1 2026-09 serving 生态快照

这次校准只吸收会影响学习顺序和证据标准的变化，不追逐每个 release note：

```text
vLLM：V1 已成为主架构，核心对象收敛到 API/frontend、Engine Core、scheduler、
      KV cache manager 与 GPU workers；prefix caching、chunked prefill、
      speculative decoding、disaggregated serving 都建立在这些边界上。

SGLang：近期演进集中在 hierarchical KV cache、prefill/decode 或 encode/prefill/decode
        disaggregation、Rust serving frontend、overlap scheduling 与硬件后端。

DeepSeek：FlashMLA 的 2026-09 更新把新模型 attention、FP8/FP4 KV cache、
          fused operators 与特定 GPU architecture 一起交付，说明模型、runtime、
          kernel、memory layout 和 hardware 正在协同演进。
```

这些变化不会把当前路线改成“立刻读完整 vLLM/SGLang 源码”。它们只把后半程要求说得更具体：

```text
T20：区分 persistent / per-request / transient memory，并认识 HBM、host、external tiers
T21：从连续 Tensor 扩展到 block/page KV cache、prefix reuse、eviction/refcount 与 transfer contract
T22：从普通 FIFO 扩展到 token-budget scheduling、continuous batching 与 PD/EPD boundary
T23：除correctness外分别说明TTFT、TPOT、ITL，记录throughput、KV usage/hit rate与cache state
Gate D：先读 mini-sglang 的小型实现，再对照 vLLM V1 与 SGLang 的一个真实 path
```

“我不得不把才华埋葬在昨天”是 DeepSeek 工程师刘胜与的个人文章，不是 DeepSeek 官方研究院 roadmap。它反映的有效信号是：agent 已经能协助读 CUDA/PTX/SASS、分析 profiler 和生成优化候选；但“人不再需要基础”不是可据此推出的结论。规划只增加下面的 AI-native engineering loop：

```text
人定义 workload / assumptions / contract
-> 人准备 independent correctness oracle 与 reproducible baseline
-> agent 协助检索、读代码、提出 patch 或 profiling hypothesis
-> 人审查 diff、lifetime、synchronization、numerical error 与 profiler evidence
-> 固定 version / commit / model / hardware / precision / workload 后再写结论
```

换句话说，agent 可以加快实现和搜索，但不能替代对错误目标、错误 benchmark 或错误 kernel 的判断。

### 9.2 AIInfraGuide 怎样补充现有路线

[AIInfraGuide](https://caomaolufei.github.io/AIInfraGuide/) 纳入中文补充讲解与查漏来源。具体文章、阅读位置和停止边界统一维护在 [AIInfraGuide 阅读映射](reference_materials/ai_infra/AIInfraGuide_阅读映射.md)，不另建一套刷站进度。

“AI不止算法”公开讲解作为后续CPU推理、CUDA/kernel与系统级推理优化的候选补充，核验与限制见[2026-10-21资料筛选](reference_materials/ai_infra/2026-10-21_AI不止算法_资料筛选.md)。当前不购买、不新增整套课；作者案例在对应能力Gate后按具体缺口调用。Week13～16与Week16收口后再定实际课表的安排保持。

2026-10-22已把用户提供的六块课程目录进一步整理为[课程对齐与补强](reference_materials/ai_infra/2026-10-22_AI不止算法_课程对齐.md)。它区分当前证据、后续已有安排和原规划写得较粗的实验衔接。下面Gate B/C/D据此补实CPU性能分析、算子接回模型与低精度执行路径；不将付费目录全部变成必修，也不改当前Mini Redis、T12、T编号或Week16后的排课时点。

| 现有阶段 | 使用目的 | 保留的边界 |
|---|---|---|
| Week13~16 + T9~T12 | 辅助理解 Tensor、Module、autograd 和训练循环；Mini Redis 继续 TTL/AOF/性能收口 | 不重学 T1~T8，不增加 GPU 安装或额外分类器作业 |
| T15~T18 | 从 token、embedding、attention 接到 decoder 数据流，理解后续要优化的计算对象 | 正文先讲清，独立练习后再看完整实现；不提前读框架源码 |
| T20~T23 | 补内存账、KV Cache 分块、连续批处理和推理指标的第二解释 | 用自己的 reference/simulation 对照；CPU 仿真不能声称得到 GPU 性能结论 |
| Gate C/D/E | 分别补 CUDA、单卡 serving、通信与多卡主题 | 继续遵守下列硬件与能力前置；既定 mini-sglang 路径不被替换成第二个完整框架项目 |

它是第三方教学资料，不是 PyTorch/vLLM 的规范或招聘官方要求。已抽读的文章中存在 API 简化和无统一实验条件的性能概括，使用前按映射中的官方来源核验；面经先辨岗位内容，再决定是否补缺。本站的全栈顺序不替代本规划的项目优先级与求职时间锚点。当前主线Week13已完成；Week14 Day1～Day3均整日通过，Day3为98/100；Day4前置已满足，当前进入R1。理论T12整课已过98/100，下一步T13 R1。

### Gate A：AI workload literacy

前置：Reactor/Mini Redis 主线稳定推进，不因伴随线停工。

```text
Python
NumPy
概率统计与线性代数最小集合
PyTorch tensor / autograd / module / inference
Transformer forward、attention、KV Cache 第一层
```

Gate A 区分三个能力层级，不把它们同时作为第一批C++/后台试投的资格：

```text
Gate A1 / 与Week16协调的AI基础目标：T1~T13 + T15~T16
-> 能解释 NumPy/PyTorch object、forward/autograd、token/mask 和 single-head attention

Gate A2 / 后续Transformer forward能力：补齐 T17~T18
-> 能从 token IDs 串到 decoder-only logits

Gate A3 / 后续模型reference闭环：T19~T24
-> sampling、KV Cache、batching、benchmark 与 tiny Transformer reference
```

T14 CNN/ResNet 对 LLM inference 不是时间线硬前置，首次求职冲刺时可以延期。完整 Gate A 的出口仍是：能运行并解释一个小模型 inference，记录 correctness、latency、throughput 和主要 memory objects。

### Gate B：CPU inference 小闭环

```text
Tensor / shape / dtype / layout
operator abstraction
matmul / activation / normalization
graph 或 execution plan 第一层
测试与 benchmark
```

出口：一个可验证的 CPU inference component，不只会调用 PyTorch。

正确的浮点组件建立后，沿同一条线性层或归一化路径补性能分析：固定形状与编译条件，保留正确性参照，先判断计算和数据移动的规模，再依据实际证据选择循环/cache/SIMD中的一处调整。SIMD（单指令多数据）按实际CPU指令集使用，不把AVX-512当通用前置。需要Python调用时封装同一组件，不重造第二套框架；这是原benchmark要求的展开，不新增当前作业或独立Gate。

**浮点线性层正确后，再补一个小型INT8量化数值参考。** 沿用同一输入、权重和bias，检查量化/反量化后的权重及输出误差，分别记录数据本体与刻度等辅助信息的字节数。第一版允许恢复为浮点后计算，用它建立数值依据，不声称已实现INT8计算加速。概念入口与分阶段证据统一见[理论规划T20](AI_Infra理论伴随线规划.md)的“量化怎样从容量账走到实际实验”。这属于后续补强，不反向增加当前课程或Gate B入口门槛；具体课次仍在原Week16收口后安排。

### Gate C：CUDA 与 kernel

前置：稳定 NVIDIA GPU、CPU inference 闭环、硬件基础复核。

**硬件校准（2026-10-21）：本机已有RTX 4060 Laptop GPU，约8 GiB显存。** 基础CUDA与小模型实验优先本地完成，不把“还要买到GPU”当成阻碍；当前Ubuntu仍是CPU版PyTorch，可编译、运行和分析GPU程序的环境尚待专门验证。具体读数与环境边界统一见[环境记录§2.1](ai_theory/ENVIRONMENT.md)。

用户也愿意按需租卡。只有实际实验需要更大显存、特定架构或多卡时再评估，并事先确认预算、时长和清理方式；不据此提前租用或改变课程顺序。原能力前置与3个基础kernel出口保持，Week16收口后才编排实际课次。

```text
thread / block / grid
memory hierarchy
coalescing
shared memory
reduction / softmax / matmul 初步
Nsight Systems / Compute
```

出口：至少 3 个 kernel，有 correctness tests、baseline 和 profiling 数据。

这项出口按同一实验链推进：先跑通基础计算与边界，再研究访存/归约/矩阵路径，随后按模型需要选择softmax、RMSNorm等算子。每步复用CPU/PyTorch参照；计时区分kernel与含搬运的整段时间。Nsight Systems先看时间线，Nsight Compute在需要时检查选定kernel；采集开销与正式延迟测量分开，不以刷完目录或一次改动必然加速为标准。

算子接回同一个小模型时，要核对逐层输出并测实际调用成本。融合、stream和CUDA Graph由已观察到的开销引出，不同时全部开工。课程中的特定架构路径按本机/租卡条件另行筛选，详见课程对齐，不改变原3个基础kernel出口。

低精度优化在匹配算子与硬件上再验证：复用前面的浮点/量化数值参照，固定输入范围和质量标准后，才比较实际内存、延迟与吞吐。已有INT8存储或在浮点中模拟量化都不能代替这项证据。CPU低精度路径按实际CPU后端条件评估，CUDA量化算子仍服从本Gate；不把所有量化基础都推迟到有GPU以后，也不改原3个基础kernel出口。

### Gate D：Triton / vLLM serving

分阶段前置：源码结构阅读需要 Theory Gate 3；Triton/kernel 与 production optimization 需要 CUDA 证据 + Transformer/KV Cache 理解。

```text
阶段 1：在 Theory Gate 3 后阅读固定版本 mini-sglang
-> request/sequence lifecycle
-> token-budget scheduler
-> radix/prefix cache 与 block table
-> chunked prefill / overlap scheduling 的对象边界

阶段 2：在 CUDA Gate 后做一个可运行 Triton/CUDA operator
-> correctness reference
-> profiler
-> baseline 与固定 workload

阶段 3：只选一个 production path 对照
-> vLLM V1：Engine Core / scheduler / KV cache manager / worker
或
-> SGLang：scheduler / radix cache / hierarchical cache / disaggregation

阶段 4：提交一个小而可验证的贡献
-> docs / test / bug reproduction / profiler evidence / focused patch
```

Gate D 不要求“从头读完整框架”，也不把能运行官方 demo 当作源码能力。第一份贡献可以是高质量 reproducer、test 或文档勘误；核心是能说明问题、版本、证据和边界。

后续选择量化部署作为优化路径时，使用同一模型和可比请求，既检查输出质量，也记录端到端资源与性能变化，明确收益来自哪一段。量化学习入口、CPU参考和真实计算验证仍按理论规划T20分层，不追加第二个完整框架项目或付费前置。

**模型接入与部署的共同路径要讲完整。** 选定模型后，从权重/配置加载走到一次输出，再核对选定算子替换后的逐层误差，分别记录加载、prefill与decode成本。量化分支还需说明校准输入、刻度、打包布局、保存重载与执行kernel怎样对应；基础INT8参考之后按问题择一方案深入，不同时要求完整QAT、AWQ、SmoothQuant和FP8。

ONNX/TensorRT/Triton Inference Server保留为部署岗位或实际项目需要时的可选对照，不另加完整YOLO工程。Triton服务端与Triton算子语言分开，普通动态合批与LLM连续批处理也分别说明。上述细化沿原Gate D分阶段前置展开；TensorRT分支不能反过来成为mini-sglang源码阅读的前置。

### Gate E：multi-GPU / distributed inference

```text
NCCL collectives
tensor / pipeline / expert parallel
communication-computation overlap
failure and observability
```

没有多 GPU 资源和单卡 serving 闭环时不提前展开。

---

## 10. 近期明确不做

```text
Go 主线
DPDK
io_uring 深入
完整 Nginx / Redis 源码
复杂模板元编程
过早 CUDA
多个重型课程并行
完整 6.824
完整 CS144 抢占 Mini Redis
完整 BusTub 抢占 Mini Redis
为了简历数量做多个同质 server
为了显得高级堆 RDMA / eBPF / XDP 等名词
```

出现相关术语可以解释，但不因此改变当前 milestone。

---

## 11. 执行与验收原则

教程讲解按 `MEMORY.md` §1.1、§6.1、§7、§9.3：先从熟悉对象走通具体问题、动作与结果；新概念先用短句和例子说明“表现成什么”，再解释实现机制，不能用内部机制名替代行为定义。成组术语各自落在具体过程后再汇总，不能靠互相定义或中文翻译假定已经理解。一句推进一个主要认知动作，一段解决一个主要问题。指定参考资料也借鉴其概念入口，阅读位置按§9.8的实际用途安排，不一律等机制讲完；当前核心默认仍由正文讲清。

AI Theory的当前质量参照是已正式通过的[T11学习者主线版](ai_theory/T11/T11.md)。它强调唯一目标、连续对象链、API动作与输出先行、最小充分推导、阶段闭环、必要图示，以及教程主干与用户最终笔记大体同构。

它是质量标杆，不是统一目录。后续T模块不能机械复制三轮、章节数或标量例子。

每一阶段守住一个主要问题，R1之后也不突然展开整片知识地图。当前实验需要的条件在使用前讲清；不参与当前因果链的扩展放到主闭环之后，标清必做或选读。内部表示升级先用同一状态轨迹解释“保存什么、下次怎样用”，再给字段/API。主线三Part、独立R1与理论线独立编排保持。

行为说明之后的机制仍按Memory §9.3讲具体：展示一份内部记录包含哪些值，跟完一次保存、查找、判断与结果，交代原对象是否被改变。“保存信息、选择版本”是待展开的问题，不能直接充当解释完成的结论。

每次文件修改最后都按MEMORY §1执行全局对齐；只修受影响且获准编辑的内容，不重写用户代码、笔记和冻结课。

### 11.1 编译基线

```bash
g++ -std=c++17 -Wall -Wextra -g
```

多线程项目补 `-pthread`；sanitizer、optimization 和 benchmark flags 按实验目的单独说明。

### 11.2 Demo 与项目标准

Demo：

```text
能编译
能运行
能观察
能解释
```

简历候选项目：

```text
contract 清楚
ownership 清楚
错误与边界明确
测试覆盖核心风险
sanitizer 证据
benchmark 可复现
README 能让陌生人运行
能讲设计取舍和已知限制
```

不要求机械完成重复验收题。代码、实验、笔记和口头解释能够证明理解时，可以替代体力性重复；但当天核心若是 testing、benchmark 或 failure semantics，不能把核心证据全部省略。

### 11.3 系统主线新任务的推进方式

以下三轮用于系统主线，保留原三 Part 与 R1 独立闸门。AI Theory 使用独立规划：按能力闭环与认知负荷判断阶段停止点，另按真实认知墙判断保护独立发现的闸门，不被本节统一套成三轮。具体教学顺序与文件保护按 MEMORY §1.1、§8、§11、§13 执行。

```text
Round 1：给用途、public contract、文件名、build/run 入口，让用户独立完成第一版
Round 2：R1 正式通过后，根据真实代码、笔记、问题和教程增补，定向讲清本课机制与边界
Round 3：明确本版保留什么、还要完成什么升级，再留下必要的验证与收口证据；性能仅在本课范围内安排
```

教程不能在 Round 1 前用大量“防止你犯错”的实现提示把设计答案泄露完。

R1 通过后，同轮定向润色完整 R2/R3，从最新磁盘内容增量编辑并保留用户修改；不因此取得修改用户代码、tests 或 note 的授权。

### 11.4 路线调整规则

只有同时满足以下条件才修改主线：

```text
多个目标岗位重复要求
当前项目确实暴露了缺口
新内容能形成代码或实验输出
不会破坏最近的简历里程碑
```

否则进入 backlog。

这四条约束针对新增或改换**主线项目/技术方向**。虚函数等目标岗位基础若存在明确掌握缺口，允许用受限小专题补齐，即使当前项目不需要该特性；插入位置和证据单独登记，不为学习它改造项目架构，也不取消已通过的项目验收。

---

## 12. 阶段成功标准

### Week16完成后、首批试投前

```text
一个能运行、测试、压测和解释的 Mini Redis
Reactor / HTTP 的清楚演进证据
C++ / Linux / OS / TCP / concurrency 面试第一轮闭环
AI线协调目标为T1～T13与T15～T16；T17～T18是AI方向进阶项
已完成的stable softmax、PyTorch inference、attention等证据如实列出；未完成者保留欠账，不写成已会
竞赛优势在简历上准确呈现
第一版简历、项目讲稿和目标岗位表
学完既定Week16后开始试投，不继续等待后置T24/CUDA等完整路线全部结束
```

### 2027 年底

```text
至少一段真实工程、实验室或高质量开源协作经历
完成 6.S081 主要课程与实验闭环
完成 AI Gate A/B
根据反馈决定 storage / network / AI inference 的第二项目
```

### 2028 年关键实习前

```text
C++ 系统项目与真实协作证据
CUDA kernel correctness + profiler + benchmark
理解 Transformer inference / KV Cache / batching
至少一个 Triton/vLLM/SGLang 相关贡献或复现优化
能够投递真正的 AI Infra / inference engine / GPU systems 岗位
```

---

## 13. 当前下一步

1. 系统主线的Week14 Day1已以分轮98/98/99完成整日验收；Day2分轮99/99/97并以97/100完成整日验收；[Day3](week14/day3/day3.md)分轮96/98/98并以98/100整日通过；[Day4](week14/day4/day4.md)前置已满足，当前进入R1。Week13已整周通过，TTL、虚函数和Day1～Day3既有证据不重做。后续仍按原Week14～Week16完成恢复、性能与项目出口。
2. 理论线进入T13 R1：T12已经完成XOR从线性边界到hidden representation、ReLU、MLP训练、一次更新的状态变化以及预测/训练恢复边界。T13先只跑baseline并记录train/validation curves，再由实际曲线产生weight decay与checkpoint选择问题。T14的BatchNorm仍为核心课后的选读扩展。
3. T12整课已于2026-11-05以98/100正式通过；T13～T21仍未通过。T20已用同一个TinyMLP串起训练对象、fresh inference对象、权重容量和INT8表示误差；T21再用固定序列完成full recompute、连续KV Cache与block table寻址，但都不前移当前T13 R1。T12的Ubuntu脚本已完成1200次更新、fresh strict load和logits close，原`float(loss)`警告已改为`loss.item()`；R2/R3由用户笔记证明状态变化和训练/推理差异。每课结束继续由用户亲自记笔记。
4. C++类/对象/继承/虚函数补缺已随Week13 Day7收口；string/STL常见实现、LRU并发/大value、allocator第一层和系统面试横向题按Week15～16定向复盘，详见[补缺规划](C++项目伴随补缺规划.md)与[查漏地图](杂教程/C++与系统面试查漏地图.md)。不改Mini Redis架构来凑语法，也不通读全部STL源码。
5. 第一段实习按三层岗位池准备：C++/Linux系统岗主投，AI平台后端/AI云原生并行投，核心推理引擎/CUDA少量冲刺。是否值得去看实际编码、系统问题、性能与协作内容，不只看职位标题。
6. 本轮岗位与官方资料只补充阶段对应的参考入口、实验口径和缺口判断，不开新的整套课程，不提前启动完整推理框架、CUDA或分布式路线。
7. 原Week16完成后再做实际后续排课和简历试投；区域赛期间按真实精力推进，不把自然日都算作满额学习日。

当前不要因为 2026 年 serving 生态更新临时插入 Go、Kafka、Kubernetes、完整 vLLM/SGLang、DeepEP 或 CUDA。先把最接近岗位硬要求、也最接近简历项目闭环的 HTTP -> Mini Redis 做穿，同时保持 AI Theory 的稳定推进。

---

## 14. 参考来源

岗位会变化，以下只用于提取能力模式，不把任何单个JD当永久课表。最新核验及来源可读范围见[2026-10-22调研](reference_materials/ai_infra/2026-10-22_规划对齐与岗位资料更新.md)，以下旧链接保留为追溯入口：

- [腾讯招聘](https://join.qq.com/)
- [腾讯 Careers](https://careers.tencent.com/)
- [腾讯：微信后台开发工程师 - AI 方向](https://careers.tencent.com/jobdesc.html?postId=2084242179768893440)
- [腾讯：微信 AI Infra 工程师 - 大模型推理方向](https://careers.tencent.com/jobdesc.html?postId=2037411502792798208)
- [腾讯：机器学习基础设施开发 - 存储 / 向量检索 / 参数服务器](https://careers.tencent.com/jobdesc.html?postId=2029746419665108992)
- [腾讯：大模型推理引擎研发工程师](https://careers.tencent.com/jobdesc.html?postId=2074414767455518720)
- [百度：大模型平台后端实习生 J106843](https://talent.baidu.com/jobs/detail/INTERN/fc9116ea-102d-48a9-9945-0bc64d362b3c)
- [百度：AI Infra云原生平台实习生 J106487](https://talent.baidu.com/jobs/detail/INTERN/d2f2579e-014a-4d3e-bdb7-66eb90cab622)
- [百度：AI Infra实习生 J104435](https://talent.baidu.com/jobs/detail/INTERN/6ba68d4d-889c-48a1-bed7-d4112c43014b)
- [百度：AI Infra推理工程师 J101235](https://talent.baidu.com/jobs/detail/GRADUATE/7753cdb4-70b0-462b-a634-ee53818c7c9a)
- [微信安全后台开发实习生（日常，公开招聘信息）](https://www.nowcoder.com/jobs/detail/383906)
- [WeChat Backend Developer Intern](https://tencent.wd1.myworkdayjobs.com/en-US/Tencent_Careers/job/WeChat---Backend-Developer-Intern_R107005)
- [MIT 6.S081 中文课程](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/)
- [CSAPP 官方站](https://csapp.cs.cmu.edu/)
- [CS DIY](https://csdiy.wiki/)
- [Stanford CS144](https://cs144.github.io/)
- [CMU 15-445](https://15445.courses.cs.cmu.edu/)
- 本地 `nowcoder_cpp_infra_aiinfra_200_recent.md`：主题频次雷达
- 本地 `nowcoder_cpp_infra_aiinfra_500_recent3y_with_questions.md`：原问题与追问形态样本

最终原则：

> 规划服务于可验证的能力和真实投递，不服务于课程收藏、技术名词数量或形式上的“学完”。
