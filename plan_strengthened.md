# C++ 系统工程 / AI Infra 求职总规划

> 版本：2026-08-26，Week9 / 腾讯实习目标校准版
> 学习者：FxorG，中山大学计算机科学与技术专业，按当前学制为 2029 届
> 当前进度：Week1 ~ Week8 已完成，下一站是 non-blocking I/O、epoll 与 Reactor
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

### 2.1 已完成的 Week1 ~ Week8

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

Week1 ~ Week8 已正式通过。以后只在项目需要或面试复盘时回查，不再把这些周的完整 daily 复制进总规划。

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
还没有 non-blocking I/O / epoll / Reactor 的完整实现
还没有一个真实协议驱动、可对外演示的主项目
数据库与 Redis 使用、持久化语义还未形成工程证据
项目还缺稳定的性能数据、故障案例和简历表达
Python / NumPy / PyTorch 尚未形成可投递证据
CUDA、推理框架、算子优化尚未开始正式 gate
缺少真实团队协作、代码评审和线上环境经验
```

前三项由 Week9 ~ Week16 正面解决；最后一项只能由实习、实验室、开源协作或多人项目补齐。

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

2026 年底不要求 CUDA 大项目。若系统主线按时闭环，增加一个小证据：

```text
Python 基础 + NumPy
PyTorch tensor / module / inference / no_grad
能解释 batch、shape、dtype、device、operator、latency、throughput
用一个小模型完成 CPU/GPU inference benchmark，记录环境和结果
```

这项证据的作用是证明你知道 AI workload 长什么样，不是冒充已经做过推理引擎。

---

## 5. Week9 之后的项目里程碑

自然周只是标签，是否进入下一阶段由 exit evidence 决定。

### Milestone A / Week9：non-blocking I/O 与 epoll

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
Epoll Echo Server
```

出口证据：

```text
多 client 可同时通信
一个慢 client 不阻塞其他 client
能处理半包、partial write、peer close
无明显 fd leak
能用 strace / ss 解释关键行为
能画出 event -> handler -> state change 流程
```

### Milestone B / Week10：Reactor V1

核心问题：

> 如何把过程式 epoll loop 拆成 ownership 清楚、可继续演进的组件？

建议边界：

```text
EventLoop：等待事件、分发 callback
Channel：fd 关注的事件与 callback
Connection：socket lifetime、input/output buffer、协议状态
Acceptor：监听 fd 与新连接建立
Buffer：增量读写，不假设一次完成
```

出口证据：

```text
每个 fd 和 Connection 的 owner 可解释
remove / close / callback 生命周期可解释
支持 write buffering 和 writable interest 切换
有 deterministic tests 或可复现实验覆盖关键边界
```

不提前做多 EventLoop、多线程 Reactor、io_uring 或 lock-free。

### Milestone C / Week11：HTTP Server V1

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
```

出口证据：

```text
协议 parser 与 transport 分离
半包 / 多次 read 能正确推进 parser state
curl 可复现实验
错误输入不会让 server 崩溃
```

### Milestone D / Week12：Mini Redis V1 - RESP 与 KV

```text
RESP2 最小 parser / encoder
SET / GET / DEL / EXISTS
错误响应
多个 client
协议测试
```

出口：网络层、协议层、命令层和存储层边界清楚。

### Milestone E / Week13：Mini Redis V2 - 生命周期与 TTL

```text
TTL / EXPIRE / PTTL 中选择最小命令集合
lazy expiration
必要时增加周期性清理
连接 idle / shutdown 行为
时钟注入或可控测试
```

出口：过期语义有 deterministic evidence，不靠长时间 sleep 测试。

### Milestone F / Week14：Mini Redis V3 - AOF 与恢复

```text
append-only command log
启动 replay
partial/corrupted tail 的明确策略
flush policy 的范围说明
crash consistency 只做到能证明的层次
```

出口：重启后数据可恢复，有故障实验，不声称完整 Redis durability。

### Milestone G / Week15：测试、故障与性能

```text
parser / command / TTL / AOF unit tests
multi-client integration tests
ASan / TSan
fd / memory leak 检查
throughput 与 latency baseline
固定环境、workload、样本与统计方式
perf / flame graph 只在真实瓶颈出现后使用
```

出口：每条性能结论能从命令、环境和结果复现。

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
```

出口：一个不了解仓库的人能按 README 跑起来；简历上的每句话都能指向代码或实验。

Week16 同时留一个短的岗位补缺窗口，不开完整数据库课程：

```text
Redis 常见数据结构、过期、淘汰、RDB/AOF 第一层
MySQL B+ tree index、transaction、ACID、isolation level 第一层
把概念挂回 Mini Redis 的设计，不机械背题库
```

---

## 6. 2026-08 到 2027-02 时间表

| 时间 | 主任务 | 必须形成的结果 |
|---|---|---|
| 2026.08 下旬 | Week9 | Epoll Echo Server，多 client 与 partial I/O 证据 |
| 2026.09 | Week10~11 | Reactor V1、HTTP Server V1 |
| 2026.10~11 | Week12~15 | Mini Redis RESP/KV/TTL/AOF、测试和 benchmark |
| 2026.12 | Week16 + 求职准备 | README、项目讲稿、第一版简历、岗位清单 |
| 2027.01 | 第一轮投递 | 日常实习、导师直招、后台/C++ Infra 主投，AI infra 相关岗位冲刺 |
| 2027.02 起 | 投递反馈驱动补缺 | 面试复盘、项目修订、短板专题，不重新开一堆课程 |

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
process/thread、virtual memory、page fault、system call
fd / open file description / mmap
TCP handshake/close、flow control、socket API
non-blocking I/O、epoll、LT/ET、partial I/O
Reactor ownership、connection lifecycle、backpressure
Redis 基础数据与常见语义
MySQL index / transaction / isolation 第一层
项目测试、debug、benchmark 和 trade-off
```

算法训练：

```text
每周 1~2 次保持手感
以限时编码、边界和表达为主
不再把大量简单题当主线进度
```

### 7.4 简历投递版本

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

### Gate A：AI workload literacy

前置：Reactor/Mini Redis 主线稳定推进，不因伴随线停工。

```text
Python
NumPy
概率统计与线性代数最小集合
PyTorch tensor / autograd / module / inference
Transformer forward、attention、KV Cache 第一层
```

出口：能运行并解释一个小模型 inference，记录 latency、throughput、memory。

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

前置：CUDA 证据 + Transformer/KV Cache 理解。

```text
Triton kernel
continuous batching
PagedAttention / KV Cache management
request scheduling
prefill / decode
latency / throughput / memory trade-off
vLLM 或 SGLang 源码级小贡献
```

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
1. 生成并完成 Week9 Day1
2. 从 blocking server 的问题进入 O_NONBLOCK / EAGAIN
3. 完成 Epoll Echo Server
4. 用真实代码和实验验收 Week9
5. 进入 Reactor V1
```

当前不要为了腾讯岗位临时插入 Go、Kafka、Kubernetes、完整 MySQL 课程或 CUDA。先把最接近岗位硬要求、也最接近简历项目闭环的 epoll -> Reactor -> Mini Redis 做穿。

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

最终原则：

> 规划服务于可验证的能力和真实投递，不服务于课程收藏、技术名词数量或形式上的“学完”。
