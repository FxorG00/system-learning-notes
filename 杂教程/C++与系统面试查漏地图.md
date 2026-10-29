# C++ 与系统面试查漏地图：哪些已经会，哪些需要补到什么深度

**这些题目是雷达，不是一张新的必修课表。** 你的长期目标是 AI Infra，但第一段实习最可靠的入口仍然是 C++/Linux/系统基础设施，以及与 AI 推理服务相邻的平台后端。C++ 基础要学扎实，不需要先把所有标准库源码、ABI 和社招高频追问全部啃完。

## 1. 先给结论：第一段实习不是“C++ 或 AI Infra”二选一

更准确的岗位梯度是：

```text
第一主投层
C++ 后台 / Linux 后台 / 网络 / 存储 / 中间件 / 系统基础设施

第二并行层
大模型平台后端 / 推理服务外围 / AI 云原生平台

第三冲刺层
推理引擎 / CUDA / kernel / GPU profiling 核心 AI Infra
```

当前最强证据在第一层：

```text
C++ ownership / lifetime
Linux I/O 与进程
TCP / non-blocking socket
epoll / Reactor
HTTP parser 与 server
RESP parser / Mini Redis / TTL
correctness tests / sanitizer / 性能证据意识
```

第二层已经开始具备入口：你在学 PyTorch、Transformer 对象链和推理系统概念，Mini Redis 也能证明服务端与状态系统能力。当前官方岗位中，大模型平台后端会接受 Go/Python/C++ 中至少一种语言、Linux、数据结构与工程能力；AI 云原生平台则重视 OS、网络、容器、调度与问题定位。这类岗位可以和 C++ 系统岗一起投。

第三层暂时不作为首批命中标准。当前核心推理岗位常直接要求 CUDA/CUTLASS/Triton、推理引擎、KV Cache、调度和 GPU 性能分析。你会逐步补齐，但不能只凭“目标是 AI Infra”就把尚未形成的能力写成已有项目。

因此第一轮投递建议是：

```text
主投：C++ / Linux / 系统 / 存储 / 网络
并行投：AI 平台后端、推理服务平台、AI 云原生基础设施
少量冲刺：允许培养、要求相对开放的 AI Infra 核心岗
```

不要机械执行固定比例。看岗位实际职责：**只要工作内容能让你继续写系统代码、定位性能和接近模型运行链，它就能成为通往 AI Infra 的第一段经历。**

当前岗位核验入口：

- [百度大模型平台后端实习生 J106843](https://talent.baidu.com/jobs/detail/INTERN/fc9116ea-102d-48a9-9945-0bc64d362b3c)：语言、Linux、数据结构与平台后端是入口，容器经验加分。
- [百度 AI Infra 云原生平台实习生 J106487](https://talent.baidu.com/jobs/detail/INTERN/d2f2579e-014a-4d3e-bdb7-66eb90cab622)：OS/网络/Linux/容器是底座，再连接 GPU/RDMA 与模型工作负载。
- [百度 AI Infra 实习生 J104435](https://talent.baidu.com/jobs/detail/INTERN/6ba68d4d-889c-48a1-bed7-d4112c43014b)：代表核心训推优化层，明确要求 PyTorch、CUDA、GPU 集群 profiling 与 vLLM/SGLang。
- [百度 AI Infra 推理工程师 J101235](https://talent.baidu.com/jobs/detail/GRADUATE/7753cdb4-70b0-462b-a634-ee53818c7c9a)：代表更深的引擎/kernel层，要求 CUDA/CUTLASS/CuTe/Triton/TileLang 与推理核心优化。

岗位会变化。正式投递时重新核对日期、学历、到岗时间与职责；上面只用来说明岗位分层，不把某一家公司的要求永久写成课程标准。

---

## 2. C++ 到底要学多深

用四层判断，避免两个极端：既不只会调 API，也不先钻进所有实现细节。

### 第一层：项目里必须正确使用

你要能写对：

```text
ownership / lifetime
RAII / copy / move
iterator 与 pointer 失效
容器选择
异常与清理
线程同步边界
I/O 与协议边界
```

这是任何系统或 AI Infra 岗都需要的底座。

### 第二层：面试要能解释常见实现模型

例如：

```text
vector 为什么连续、扩容发生什么
unordered_map 为什么平均 O(1)、rehash 改变什么
map 为什么通常用平衡树
string 为什么可能有 SSO
虚调用常见怎样经过 vptr/vtable
malloc/free 为什么能找到分配块 metadata
```

要求是能从需求推到结构、复杂度和边界。具体布局、阈值或 ABI 结论必须限定实现，不能背成标准保证。

### 第三层：挑代表题手写

不需要把整个 STL 重写。首批代表题保留：

```text
StringLike：深拷贝、移动、异常安全
vector/RingBuffer：size/capacity 与元素生命
LRU：list + unordered_map 的共同 invariant
BlockingQueue / ThreadPool：条件变量与关闭语义
```

这些已经能覆盖大部分“你是否真的懂对象与容器”的追问。

### 第四层：等岗位或真实瓶颈再深入

```text
特定 libstdc++/libc++ 全源码
多继承 ABI 与复杂虚表布局
生产级 allocator
lock-free hash map / RCU
C++26 proposal / LLVM backend
```

它们可能出现在量化、高频或核心 runtime 社招面试中，但不是你进入第一段实习前的统一前置。

---

## 3. 你列出的题目，现在分别是什么状态

状态含义：

```text
A：已有项目或实验形成证据，Week16只需压成稳定口述
B：学过第一层，需要按面试问法复盘
C：尚缺一段定向讲解或小实验
D：当前后置，真实岗位/反馈需要时再深入
```

| 题组 | 状态 | 当前证据或缺口 | 安排 |
|---|---|---|---|
| 多态、虚函数、override/final、虚析构、构造析构顺序、vptr/vtable | A | Week13 Day7 已用普通/虚调用、销毁和对象模型完成 | Week16 闭卷口述，不重做整套 lab |
| const、static、volatile | B | const/static 已在类、链接、并发中使用；volatile 已明确不能替代线程同步 | 小册复盘常见问法，避免关键词背诵 |
| vector 底层、size/capacity、扩容与失效 | A | Week3 Day1 与后续 Buffer/RingBuffer 有真实证据 | Week15 用内存/benchmark语境复盘 |
| map 与 unordered_map | A/B | Week3 Day4/5 已学树/哈希、load factor、rehash、失效与选择 | 补常见实现模型；不手写完整红黑树/哈希表 |
| string、SSO/SBO、手撕 string | C | 旧小册只有一句 SSO；Week1/2 已有 StringLike 所有权基础 | 新增小册第10章，Week15复用已有代码 |
| LRU、并发LRU、分片锁、大value | A+C | Week3 Day7 已有单线程正确基线；并发/大value尚未系统比较 | 新增小册第11章；先粗锁，分片/共享value靠benchmark决定 |
| `shared_ptr<string>` 与 `shared_ptr<const string>` | B/C | 已懂共享所有权与线程安全边界；尚未接大value接口 | 第11章从复制成本、只读承诺和延迟释放解释 |
| select/poll/epoll | B | epoll/Reactor 已深学；三者横向比较还需压成面试回答 | Week15/16补复杂度、fd集合复制与事件模型对照 |
| LT/ET | A/B | Reactor中已有 non-blocking 与 drain 边界 | Week16用真实 receive/send 路径作证据 |
| Reactor/Proactor | B/C | Reactor已实现；Proactor只需建立完成通知模型对照 | 定向一节，不另写Proactor框架 |
| TCP/UDP、断开判定、大小端 | A | Week6～12 的协议、EOF/error、半关闭、序列化有证据 | Week16稳定口述 |
| ping 原理 | C | 目前使用过命令，但未系统走 ICMP Echo 请求/应答 | 面试查漏短专题，不加入Mini Redis代码 |
| 条件变量虚假唤醒 | A | BlockingQueue/ThreadPool 已用 predicate while 模型 | Week16从状态条件解释，不背“莫名被唤醒” |
| 进程/线程与上下文切换 | B | OS/线程阶段学过，项目中有线程池与单线程Reactor对照 | 面试复盘保存/切换对象和地址空间差异 |
| 系统调用完整流程 | B/C | 已用 read/write/epoll/mmap/strace；硬件入口细节需收束 | 讲到 user/kernel、陷入、检查、执行、返回；架构细节后置 |
| `fflush` 与 `fsync` | C | Week14 AOF 正好产生“用户态缓冲 vs 内核/设备持久性”问题 | 在AOF真实路径中补，不单独背答案 |
| malloc/free 怎样管理块 | C | 已懂对象生命与原始存储；allocator metadata/size class未系统学 | Week15只补第一层并用测量校准 |
| 页面置换算法 | C/D | OS概念缺口，与当前项目无直接实现 | Week16后按面试反馈补 FIFO/LRU/Clock 第一层 |
| 单例模式 | C/D | 不是当前项目需要；容易把全局状态包装成类 | 只讲局部static线程安全初始化、测试/依赖问题；不改项目凑模式 |
| 菱形继承、虚继承 | D | Day7明确后置，当前对象模型已够项目使用 | 若真实题目高频再做一个独立对象布局实验 |
| function/lambda/bind | B | lambda、捕获、函数指针、std::function已学；bind不是项目主线 | 补一页调用适配对照，不重写callback系统 |
| auto/decltype/模板类型推导 | B | 小册第9章与模板专题已有基础 | 复盘引用/const丢失和转发引用；复杂元编程后置 |

这张表说明：**你不是“这些都没学”。** 很多题已经学过，只是此前按项目问题出现，没有按面试标题重新索引。

---

## 4. Week15～16 怎样补，不打断 Mini Redis

## Week15：让实现模型服务于性能问题

只补会影响当前性能判断的内容：

```text
string 对象、SSO、capacity、借用寿命
vector/map/unordered_map/list 的布局、分配与失效复盘
allocator 第一层：块 metadata、size class、复用与RSS边界
LRU 大value/粗锁/分片候选的可测取舍
select/poll/epoll 与 Reactor/Proactor 的横向表达
```

每项都必须接一个现有对象或 workload。不能因为面试题写着“如何优化”，就跳过 baseline 直接上内存池、分片锁或 lock-free。

## Week16：把已有证据压成面试回答

从下面选 4～6 个代表题闭卷讲清：

```text
虚调用与正确销毁
vector/string 扩容和借用失效
map/unordered_map选择与最坏情况
Reactor、LT/ET 与连接关闭
条件变量与关闭语义
AOF中write/fflush/fsync分别承诺什么
一次性能优化怎样从baseline走到profile和复测
```

回答结构固定为：

```text
它解决什么问题
-> 常见机制是什么
-> 关键边界/失败是什么
-> 我项目里的证据是什么
```

不是把教程背成定义。

## Week16后：真实面试反馈决定剩余深度

若试投反复问到：

```text
菱形继承
singleton
页面置换
malloc allocator细节
手写多线程LRU
```

再按真实缺口补专题。一次反馈产生一个问题，不把整张题单重新变成半年课程。

---

## 5. 怎样判断第一段实习值不值得去

职位名称不是唯一标准。优先问工作内容：

1. 是否真正写 C++/Go/Python 服务或系统组件？
2. 是否接触 Linux、网络、存储、调度、资源管理或性能定位？
3. 是否有代码评审、测试、benchmark、线上问题或开源协作？
4. AI 平台岗是否真的靠近推理服务/资源调度，而不是只调接口或做数据运营？
5. 核心 AI Infra 岗是否给新人合理培养空间，而不是要求入职前已独立优化过 CUDA kernel？

一个高质量 C++/系统实习，完全可以成为后续 AI Infra 的跳板。反过来，一个标题带“AI Infra”但工作只是配置平台、重复调用 API，也未必比系统岗更适合你。

当前简历表达应诚实分层：

```text
已经能捍卫：C++系统项目、协议/parser、Reactor、TTL/AOF、正确性与性能方法
正在形成：PyTorch模型执行、Transformer推理对象链、内存与调度直觉
长期目标：推理引擎、CUDA/kernel与GPU性能优化
```

这不是降低目标，而是选择一条能真正走到目标的入口。

---

## 6. 停止边界

首批投递前，不把下面这些设为统一门槛：

```text
完整STL源码通读
手写生产级allocator
完整lock-free容器/RCU
C++26提案
LLVM backend优化phase
完整vLLM/SGLang源码
多GPU训练与通信
```

它们以后可能有价值。当前更重要的是：Mini Redis完成Week14～16闭环，C++题能用项目证据回答，T线继续推进，并开始获得真实投递反馈。
