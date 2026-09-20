# C++ 系统工程 / AI Infra 求职总规划

> 版本：2026-09-20，Week11 / T3 / serving 生态与真实进度校准版
> 学习者：FxorG，中山大学计算机科学与技术专业，按当前学制为 2029 届
> 当前进度：Week1 ~ Week10 已完成，Reactor V1 已闭环；Week11 HTTP Server V1 正在推进。AI Theory T1~T3 已通过，下一模块为 T4
> 近期目标：2026 年 12 月形成第一版简历，2027 年 1 月开始投递后台开发、C++ Infra 与 AI 业务基础设施相关实习
> 长期目标：本科就业进入 AI Infra，重点发展 LLM inference systems / serving 与 CUDA kernel optimization

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

1. 2027 年第一段实习以 **C++ 后台 / Linux 后台 / 系统基础设施** 为主投方向。
2. **AI 业务中的后台或机器学习基础设施** 是冲刺方向，尤其关注存储、向量检索、参数服务、模型服务外围系统。
3. **大模型推理引擎 / CUDA AI Infra** 是长期主目标，不把它伪装成 2027 年 1 月已经完全匹配的岗位。
4. Reactor 和 HTTP Server 是 Mini Redis 的技术底座，不强行拆成三个注水项目。
5. BlockingQueue、ThreadPool、AsyncLogger 是重要组件证据，但不是三份独立简历项目。
6. 课程按项目暴露的问题调用，不再平铺 CSAPP、CS144、15-445、编译原理和分布式系统。

一句话版本：

> 先凭扎实的 C++ / Linux / 网络 / 并发和一个可信的 Mini Redis 拿到系统方向实习，再把这套能力迁移到推理引擎、模型服务与 GPU 优化。

---

## 2. 当前真实能力基线

### 2.1 已完成的 Week1 ~ Week10

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

Week1 ~ Week10 已正式通过。以后只在项目需要或面试复盘时回查，不再把这些周的完整 daily 复制进总规划。Week11 已生成周规划与 Day1 教程，但仍按真实学习和验收推进，不能把“教程存在”记成“HTTP 已完成”。

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

```text
HTTP protocol parser 与 HTTP Server V1 尚未闭环
Mini Redis 的 RESP、KV、TTL、AOF 与完整项目证据尚未形成
数据库与 Redis 使用、持久化语义还未形成工程证据
项目还缺稳定的性能数据、故障案例和简历表达
已学 C++ / OS / 并发内容尚未形成稳定的面试口述闭环
C++ object model、atomic/CAS、memory order 仍需定向补强
Python / NumPy 已有 T1~T3 的 ndarray、线性变换、matmul/broadcasting 小型证据，PyTorch 与 Transformer inference 证据尚未形成
CUDA、推理框架、算子优化尚未开始正式 gate
缺少真实团队协作、代码评审和线上环境经验
```

HTTP/Mini Redis、数据库第一层、性能证据、口述闭环和 memory model 由 Week11 ~ Week16 的项目与 milestone exit review 解决；Python/PyTorch 继续走 AI 伴随线；CUDA 和 serving framework 继续等待正式 gate；真实协作只能由实习、实验室、开源协作或多人项目补齐。

---

## 3. 腾讯岗位匹配审计

### 3.1 岗位 A：C++ / Linux 后台开发实习

当前公开的腾讯微信安全后台日常实习要求集中在：

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
尚缺证据：epoll/Reactor、完整 C++ 网络项目、长期可用性、真实协作
```

结论：

> 这是 2027 年 1 月最现实的主投方向。Week8 结束时已经具备明显基础，但简历项目仍偏组件化；完成 Reactor + Mini Redis V1 后，岗位画像会闭合得多。

### 3.2 岗位 B：AI 业务后台 / 机器学习基础设施

腾讯当前相关岗位名称包括：

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
即将补齐：Reactor、协议、KV、TTL、持久化、benchmark
仍需补齐：Python、NumPy/PyTorch inference、向量/模型服务的最小上下文
```

结论：

> 这是 2027 年的冲刺方向。最好的桥梁不是立刻堆 CUDA 名词，而是把 Mini Redis 做成可信系统项目，并补一个小而真实的 Python/PyTorch inference 证据。

### 3.3 岗位 C：大模型推理引擎 / CUDA AI Infra

腾讯当前大模型推理引擎岗位公开要求包含：

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

> 2027 年 1 月不把“直接大模型推理引擎实习”设为必须命中的目标。可以投、可以冲，但主线成功标准仍是拿到高质量 C++/系统/AI 业务基础设施经历。长期 AI Infra 目标不变。

### 3.4 招聘批次与时间条件

用户按当前学制为 2029 届。需要把两种实习分开：

```text
正式暑期实习 / 校招批次：常按毕业年份限制，2027 年初未必面向 2029 届
日常实习 / 导师直招：更看当前能力、到岗时间和连续实习时长
```

因此 2027 年第一轮重点不是只盯统一校招入口：

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
寒假后开学如何协调课程？
是否能在广州 / 深圳线下？
```

如果 2027 年春季无法连续每周 3~4 天，技术匹配也可能被时间条件挡住。此时应把窗口转为暑期、实验室或远程开源协作，不把它误判为技术路线失败。

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
T1~T8：NumPy、shape/matmul、stable softmax、最小 ML workflow
T9~T13：PyTorch Tensor/Module/autograd/MLP/generalization
T15~T16：token/embedding/mask 与 single-head attention reference
Stretch：T17~T18，能够从 token IDs 串到 decoder-only logits
```

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

出口前做一次 C++ 定向补缺，挂回 Week7~8 并发组件和 Reactor lifetime，不进入复杂模板或 lock-free 实现：

```text
virtual dispatch、object layout、virtual destructor 第一层
lambda capture 与 captured object lifetime
template instantiation 的编译期含义
alignment、cache line、false sharing 第一层
atomic 与 mutex/volatile 的边界、CAS、acquire/release、happens-before 第一层
```

### Milestone C / Week11：HTTP Server V1（进行中）

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

### Milestone D / Week12：Mini Redis V1 - RESP 与 KV

```text
RESP2 最小 parser / encoder
SET / GET / DEL / EXISTS
错误响应
多个 client
协议测试
```

出口：网络层、协议层、命令层和存储层边界清楚；同时能对照经典 Redis 的主要命令执行路径解释常见数据类型和事件循环为什么高效，知道现代 Redis 还包含 I/O threads 与后台任务，并准确说明本项目只实现了哪些语义。

伴随补缺，不新增数据库项目：

```text
MySQL B+ tree index、clustered/secondary index、covering index、回表第一层
EXPLAIN 的目的与“是否走索引不能只靠猜”
最小实验：同一个小表对比一次 full scan、普通 index query 和 covering index query 的 EXPLAIN
```

### Milestone E / Week13：Mini Redis V2 - 生命周期与 TTL

```text
TTL / EXPIRE / PTTL 中选择最小命令集合
lazy expiration
必要时增加周期性清理
连接 idle / shutdown 行为
时钟注入或可控测试
```

出口：过期语义有 deterministic evidence，不靠长时间 sleep 测试。

伴随补缺：

```text
Redis expiration 与 eviction 的区别
cache penetration / breakdown / avalanche 的问题模型与基本处理
MySQL ACID、transaction、isolation、MVCC、lock/deadlock 第一层
```

### Milestone F / Week14：Mini Redis V3 - AOF 与恢复

```text
append-only command log
启动 replay
partial/corrupted tail 的明确策略
flush policy 的范围说明
crash consistency 只做到能证明的层次
```

出口：重启后数据可恢复，有故障实验，不声称完整 Redis durability。

伴随补缺：

```text
真实 Redis RDB / AOF 的目标、取舍和恢复边界
MySQL redo / undo / binlog 各自解决什么问题，只到第一层
replication、sharding、consistency、RPC 的最低系统词汇
不实现 Redis Cluster、Raft 或分布式事务
```

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

## 6. 2026-08 到 2027-03 双线时间表

截至 2026-09-20 的真实状态：系统主线已完成 Week10，正在 Week11；AI Theory 已通过 T1~T3，T4 是下一模块。下表后续日期仍是协调目标，不把落后模块静默记成完成。

| 时间 | 系统主线 | AI 理论伴随线 | 必须形成的结果 |
|---|---|---|---|
| 2026.08 下旬 | Week9 | 启动 T1 | Epoll Echo Server；能解释 ndarray/shape/dtype |
| 2026.09 | Week10~11 | T2~T3 已达；T4~T6 为当月后续目标 | Reactor 已通过、HTTP 进行中；matmul/broadcast reference 已形成 |
| 2026.10 上半 | Week12 | T7~T8，Theory Gate 1 | Mini Redis RESP/KV；NumPy ML 小闭环 |
| 2026.10 下半~11 月 | Week13~14 | T9~T12 | TTL/AOF；PyTorch Tensor/Module/autograd/MLP |
| 2026.11 下半~12 月上半 | Week15 | T13、T15~T16；T14 可延期 | 测试/性能；single-head attention reference |
| 2026.12 下半 | Week16 | 复检 T1~T16；Stretch T17~T18 | 项目 README/简历；能解释 Transformer block 与 decoder forward |
| 2027.01 | 第一轮投递 | 完成未收口的 T17~T18 | 后台/C++ Infra 主投；AI infra 相关岗位有可解释伴随证据 |
| 2027.02 | 投递反馈驱动补缺 | T19~T21 | sampling、training/inference memory、KV Cache reference |
| 2027.03 | 项目迭代/继续投递 | T22~T24 进取目标 | batching simulation、benchmark 方法、tiny Transformer reference |

若 AI 线长期只能保持约 4 小时/周，T24 的正常后备窗口是 2027 年第二季度。这个顺延不阻塞 2027 年 1 月第一轮投递，也不能成为推迟 Mini Redis 或简历的理由。

### 6.1 主线 milestone 与 T 模块出口锚点

这里的“前”是协调目标，不是说 T 线没完成就禁止写主线代码；它用于防止 AI 线无限拖延：

| 系统 milestone 出口前 | AI 理论至少到达 | 连接点 |
|---|---|---|
| Week9 | T1 | array metadata、bytes estimate、reference 思维 |
| Week10 | T3 | shape、matmul、batch 维度，为后续 operator 做准备 |
| Week11 | T6 | gradient/概率映射、stable softmax 与数值稳定性 |
| Week12 | T8 / Theory Gate 1 | 完成 NumPy 与最小 ML workflow |
| Week13 | T10 | PyTorch Tensor、Module、parameter、inference mode |
| Week14 | T12 | autograd、MLP、training/inference flow |
| Week15 | T13 + T15~T16 | generalization 第一层、token/mask、single-head attention |
| Week16 | T16 必达；T17~T18 为 stretch | 第一版简历不等待 T24；有余力再完成 decoder-only forward |

AI 理论线按用户真实投入调整为：

```text
每天 30~60 分钟
每周名义 3.5~7 小时，实际可持续目标 4~6 小时
系统主线每天仍保持 3 小时以上
```

不在 Mini Redis 前启动 CUDA 或 vLLM 源码主线。若两条线冲突，先保系统 milestone；但不再用“主线重”作为无限期暂停 T 线的默认理由，而是记录延期并执行 AI 规划中的删减顺序。

如果实际学习继续明显快于日历，不靠增加教程字数拖慢：

```text
先扩大真实测试和故障场景
再增强项目边界与性能证据
然后提前投递
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
virtual function / object layout 第一层
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
| Week10 | ownership、virtual/object layout、thread/atomic/memory order | Reactor lifetime、Week7~8 并发代码 |
| Week11 | HTTP versions、HTTPS/TLS、协议 parser | HTTP Server、curl/抓包 |
| Week12 | Redis data model、B+ tree/index | KV implementation、三组 EXPLAIN 对照 |
| Week13 | expiration/eviction、transaction/MVCC/locks | TTL tests、可控时钟 |
| Week14 | AOF/RDB、WAL/recovery、replication/consistency | restart/fault experiment |
| Week15 | CPU/memory/I/O/lock bottleneck、工具选择 | benchmark 与排查链 |
| Week16 | project deep dive、system trade-off、行为问题 | README、代码、指标和时间说明 |

每题按同一结构回答：

```text
30 秒：定义与结论
2 分钟：完整机制和因果链
项目证据：自己的代码、命令、失败实验或 benchmark
边界：当前实现没做什么，代价是什么
```

已能顺畅回答且有证据的题直接通过；答不顺才回查 daily/note。不得为了形式抄写大量标准答案。

算法训练：

```text
每周 1~2 次保持手感
以限时编码、边界和表达为主
不再把大量简单题当主线进度
```

### 7.5 简历投递版本

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
T23：除 correctness 外记录 TTFT、TPOT/ITL、throughput、KV usage/hit rate 与 cache state
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

### Gate A：AI workload literacy

前置：Reactor/Mini Redis 主线稳定推进，不因伴随线停工。

```text
Python
NumPy
概率统计与线性代数最小集合
PyTorch tensor / autograd / module / inference
Transformer forward、attention、KV Cache 第一层
```

Gate A 分成两个求职时间点：

```text
Gate A1 / 2026.12 第一版简历前：T1~T13 + T15~T16
-> 能解释 NumPy/PyTorch object、forward/autograd、token/mask 和 single-head attention

Gate A2 / 2027.01 AI Infra 冲刺投递：补齐 T17~T18
-> 能从 token IDs 串到 decoder-only logits

Gate A3 / 2027.03 进取目标，2027.Q2 后备窗口：T19~T24
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

### Gate C：CUDA 与 kernel

前置：稳定 NVIDIA GPU、CPU inference 闭环、硬件基础复核。

```text
thread / block / grid
memory hierarchy
coalescing
shared memory
reduction / softmax / matmul 初步
Nsight Systems / Compute
```

出口：至少 3 个 kernel，有 correctness tests、baseline 和 profiling 数据。

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

### 11.3 每个新任务的推进方式

```text
Round 1：给用途、public contract、文件名、build/run 入口，让用户独立完成第一版
Round 2：根据真实 R1 代码讲机制、竞态、生命周期和边界
Round 3：只补高价值测试、性能证据和项目收口
```

教程不能在 Round 1 前用大量“防止你犯错”的实现提示把设计答案泄露完。

### 11.4 路线调整规则

只有同时满足以下条件才修改主线：

```text
多个目标岗位重复要求
当前项目确实暴露了缺口
新内容能形成代码或实验输出
不会破坏最近的简历里程碑
```

否则进入 backlog。

---

## 12. 阶段成功标准

### 2027 年第一轮投递前

```text
一个能运行、测试、压测和解释的 Mini Redis
Reactor / HTTP 的清楚演进证据
C++ / Linux / OS / TCP / concurrency 面试第一轮闭环
AI Theory 至少完成 T1~T13 + T15~T16；T17~T18 作为 AI Infra 冲刺项
有 stable softmax、PyTorch inference 和 single-head attention 的可运行证据
竞赛优势在简历上准确呈现
第一版简历、项目讲稿和目标岗位表
开始真实投递，而不是继续等待“全部学完”
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

```text
1. 继续完成 Week11 HTTP Server V1，不推倒 Week10 Reactor
2. AI Theory 进入 T4，把已有微积分映射到 gradient / chain rule / finite difference
3. Week11 出口后进入 Week12 RESP parser 与 Mini Redis V1
4. T20~T24 到达前只维护 serving 资料索引，不启动完整 vLLM/SGLang 源码主线
5. 每个系统 milestone 继续保留 correctness、sanitizer、failure case 与可复现实验
6. 到 Theory Gate 3 后先读 mini-sglang，再决定 production framework 的一个窄路径
```

当前不要因为 2026 年 serving 生态更新临时插入 Go、Kafka、Kubernetes、完整 vLLM/SGLang、DeepEP 或 CUDA。先把最接近岗位硬要求、也最接近简历项目闭环的 HTTP -> Mini Redis 做穿，同时保持 AI Theory 的稳定推进。

---

## 14. 参考来源

岗位会变化，以下只用于提取能力模式，不把任何单个 JD 当永久 syllabus：

- [腾讯招聘](https://join.qq.com/)
- [腾讯 Careers](https://careers.tencent.com/)
- [腾讯：微信后台开发工程师 - AI 方向](https://careers.tencent.com/jobdesc.html?postId=2084242179768893440)
- [腾讯：微信 AI Infra 工程师 - 大模型推理方向](https://careers.tencent.com/jobdesc.html?postId=2037411502792798208)
- [腾讯：机器学习基础设施开发 - 存储 / 向量检索 / 参数服务器](https://careers.tencent.com/jobdesc.html?postId=2029746419665108992)
- [腾讯：大模型推理引擎研发工程师](https://careers.tencent.com/jobdesc.html?postId=2074414767455518720)
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
