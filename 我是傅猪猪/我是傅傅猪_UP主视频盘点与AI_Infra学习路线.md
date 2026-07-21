# 「我是傅傅猪」UP 主视频盘点与 AI Infra 学习路线建议

> 抓取对象：[我是傅傅猪（UID 1822828582）](https://space.bilibili.com/1822828582/video)  
> 盘点日期：2026-07-14  
> 目标：判断这些视频对一条以 **C++ / CUDA / 推理框架 / AI Infra 求职** 为目标的学习路线有什么帮助，并给出可执行的观看顺序。

## 先说结论

这个 UP 的内容最适合补齐“**会用 PyTorch，但不了解模型如何真正跑在 CPU/GPU 上**”这一段能力。它不是一套从编程零基础开始的课，而是一条从张量、算子、计算图，逐步走到 CUDA Kernel、LLM 推理、Triton、vLLM 和求职准备的工程路线。

对学习路线最有价值的顺序是：

1. 现代 C++、Linux、CMake、线性代数基础；
2. 用 KuiperInfer 理解张量、算子、计算图和模型执行；
3. 用 CUDA 版大模型推理框架理解显存、KV Cache、Attention、量化和性能分析；
4. 用 Triton 训练 Kernel 编写与优化能力；
5. 用 vLLM 理解生产级推理系统中的调度、PagedAttention、Worker/Executor；
6. 最后按个人情况选看规划、简历和模拟面试内容。

**不要按发布时间从头刷完 114 条。** 旧版与重制版课程重复较多，规划课也高度依赖个人背景。正确用法是“一个主线项目 + 两组专题 + 少量求职视频”。

## 抓取口径与完整性说明

B 站公开列表的搜索快照显示该账号共有 **114 条公开视频投稿**（抓取时页面显示“51/114”）。账号内容主要分布在六组系列和少量独立视频中：

| 内容组 | 可核对的条目数 | 主要价值 |
|---|---:|---|
| 自制深度学习推理框架：第一次录制 | 17 | CPU 推理框架基本结构，历史版 |
| 从零自制深度学习推理框架：重制版 | 9 | 更紧凑的入门主线，推荐优先 |
| CUDA 自制大模型推理框架 | 22 条公开合集槽位 | LLM、CUDA、量化、KV Cache、Attention |
| Triton 自制大模型推理框架 | 6 | Triton、Matmul、Softmax、Reduce、FlashAttention |
| vLLM 大模型推理框架 | 7 | 生产级推理框架架构与显存管理 |
| AI Infra 秋招与职业规划 | 34 | 路线、简历、实习、模拟面试与案例 |

系列之间存在交叉收录，不能简单相加作为投稿总数。B 站网页/API 对匿名批量请求触发了 412/-799 风控，因此本文采用“公开列表快照 + 各视频页的合集目录 + 作者 GitHub 课程目录”交叉核对。下文覆盖了全部可索引主题与主要系列，但不把付费课堂的 26 个课时冒充为 26 条公开视频。付费课页面可用于核对课程结构：[《动手自制大模型推理框架》共 26 课时](https://www.bilibili.com/cheese/play/ss23408)。

## 全部视频内容盘点（按系列去重归类）

### 1. 自制深度学习推理框架：第一次录制（17 条）

这是较早、较细的 KuiperInfer 版本。完整列表可从任一合集视频页核对，例如[第四课 ReLU](https://www.bilibili.com/video/BV1bG4y1J7sQ/)。

1. 前言与框架整体介绍
2. 张量类 Tensor 的实现
3. 从 CSV 文件初始化 Tensor
4. 实现第一个算子 ReLU
5. 算子注册机制
6. MaxPooling 算子的实现
7. 构建自己的计算图
8.1 计算图中的表达式（上）
8.2 计算图中的表达式（下）
9. 计算图知识补充
10. 卷积算子与 Im2col 加速
11. 再探 Tensor、图关系与输入输出预分配
12. 算子的执行流程
13. 使用自制框架完成 ResNet 推理与图片分类
14. 最终章：支持 YOLOv5 推理
15. Milestone：KuiperInfer 支持 YOLOv5n
16. 从 KuiperInfer 出发谈工程开发经验

帮助：建立推理框架的完整心智模型；对现代 C++ 工程、抽象设计、调试和面试项目叙述都有帮助。

建议：如果时间有限，不要整套看。优先选 2、4、5、7、10、11、12、13/14；其余用重制版替代。

### 2. 从零自制深度学习推理框架：重制版（9 讲）

作者仓库给出了完整目录和视频链接：[KuiperInfer README](https://github.com/zjhellofss/KuiperInfer#课程大纲)。

1. [项目预览和环境配置](https://www.bilibili.com/video/BV118411f7yM)
2. [张量 Tensor 的设计与实现](https://www.bilibili.com/video/BV1hN411k7q7)
3. [计算图的定义](https://www.bilibili.com/video/BV1vc411M7Yp)
4. [构建计算图关系和执行顺序](https://www.bilibili.com/video/BV19s4y1r7az)
5. [KuiperInfer 中的算子和注册工厂](https://www.bilibili.com/video/BV1gx4y1o7pj)
6. [卷积和池化算子的实现](https://www.bilibili.com/video/BV1hx4y197dS)
7. [表达式层：词法分析、语法分析与算子实现](https://www.bilibili.com/video/BV1j8411o7ao)
8. [支持 ResNet 网络推理](https://www.bilibili.com/video/BV1o84y1o7ni)
9. [支持 YOLOv5 网络推理](https://www.bilibili.com/video/BV1Qk4y1A7XL)

帮助：这是最适合作为主线的系列。它把“模型文件 → 计算图 → 算子 → 执行顺序 → 推理结果”串成了一个项目闭环。

### 3. CUDA 自制大模型推理框架（公开合集约 22 条）

公开合集可从[张量类视频页](https://www.bilibili.com/video/BV1dH4y1F735/)或[MLP 视频页](https://www.bilibili.com/video/BV1uRnRe7EFQ/)核对。公开条目包括：

1. CUDA 从零学：从零自制大模型推理框架
2. 使用 Nsight Compute 对 CUDA 算子调优
3. 大模型推理框架：张量类的设计
4. 大模型推理框架：算子类的设计
5. 内存与显存资源如何管理（试看）
6. 一个靠谱的 C++ 程序员是怎么练成的
7. 从零手写 Qwen2.5 推理流程
8. Softmax 算子的 CUDA 实现（原标题拼作 sofmax）
9. LLaMA 多头注意力机制的实现
10. 用 CUDA 实现 LLaMA 的 MLP 层
11. KV Cache 原理
12. 算子创建与权重载入
13. CUDA 显存管理
14. CUDA 算子再优化与 Nsight Compute 分析
15. 大模型 INT8 分组量化
16. CUDA 大模型推理框架：算子类实现
17. CUDA 大模型推理框架：张量与显存管理
18. RMSNorm 的 CUDA 实现
19. GEMV 算子的量化实现
20. 《自制深度学习推理框架》新书预告
21. INT8 量化实现
22. 工业级 LLM 推理系统：CUDA 加速 Qwen3 全流程

帮助：把 CPU 推理框架扩展到 LLM 与 GPU，内容覆盖资源管理、核心模型结构、Kernel 实现、量化和 Profiling，是从“会写 CUDA”到“能解释推理性能”的关键过渡。

注意：公开视频是付费完整课的切片和演示，不等于完整课程。学习时应配合 [KuiperLLama](https://github.com/zjhellofss/KuiperLLama) 仓库自己补齐代码闭环。

### 4. Triton 自制大模型推理框架（6 条主系列）

合集目录可从[推理优化综述](https://www.bilibili.com/video/BV11oRWYWEmW/)核对：

1. Triton 自制多模态大模型推理框架：用 Triton 写 FlashAttention
2. 用 Triton 写出高性能 Matmul
3. Triton 介绍和逐级编译流程
4. 使用 OpenAI Triton 实现 Softmax
5. 大模型推理优化综述
6. 使用 OpenAI Triton 实现 Reduce

此外还有与该系列关联的发布/展示视频，如“OpenAI Triton 自制深度学习推理框架发布，支持 Qwen3”和“OpenAI Triton 自制多模态推理框架，FlashAttention 原理与实战”。

帮助：Triton 比手写 CUDA 更容易快速验证算法，但仍需要理解访存、并行划分和数值稳定性。适合在 CUDA 基础之后学习，不能替代 CUDA 基础。

### 5. vLLM 大模型推理框架（7 条）

合集目录可从[技术分享与答疑](https://www.bilibili.com/video/BV1FCLV6LEsu/)核对：

1. vLLM 分块显存管理
2. KV Cache 初始化流程
3. 请求和显存块的映射
4. vLLM 引擎架构与流式推理
5. Worker 与 Executor 组件协作
6. 显存分块管理：PagedAttention 的基石
7. vLLM 技术分享与推理框架学习/工作答疑

帮助：前面的自制框架回答“一个模型怎么执行”，vLLM 系列进一步回答“多个请求如何被调度、缓存和并发执行”。这是从单机 Demo 走向生产系统的必要一层。

### 6. AI Infra 秋招、职业规划与模拟面试（34 条合集）

抓取到的完整合集目录可从[2026-05-30 规划实录](https://www.bilibili.com/video/BV1wTVj6SEhk/)核对：

1. AI Infra 购课平台上线
2. 8 月 13 日学员会议：从零开始的 AI Infra 学习规划
3. 一次对 AI Infra 新学员的规划课
4. AI Infra 2025 年秋招经验分享
5. 大模型推理加速岗位的简历怎么写
6. AI Infra 2025 年暑期实习经验分享
7. 用 CUDA 写支持 Qwen3 的大模型推理框架
8. 如何写一份合格的 AI Infra 秋招简历
9. 大模型推理框架开发实习岗位面试实录
10. 冲击 2026 秋招 SSP
11. 2025 秋招无 Offer，如何准备春招
12. 怎么学习算子开发
13. 怎么关联实习工作和目标岗位
14. 如何选择实习 Offer
15. 怎么学习大模型推理框架
16. ACM 经历对 AI Infra 是否有帮助
17. 芯片与互联网公司的 Infra 岗是否通用
18. 如何从后端转方向，以及端侧 AI 部署
19. “2026 年的 SSP 被预定了一个”案例
20. 面试三个种子选手案例
21. 实习、比赛、论文和项目全优案例
22. 如何寻找简历亮点
23. 留学生 Infra 岗简历/实习研讨
24. 算子高手如何成长
25. 算子实习生超过社招同学的案例
26. 社招转 Infra 岗改简历
27. 2026-04-03 春招规划实录
28. 2026-04-11 规划/模拟面实录（长版）
29. 2026-04-11 规划/模拟面实录（短版）
30. 2026-04-26 算子优化五步法
31. 2026-05-01 为 vLLM Omni/vLLM 贡献者修改简历
32. 2026-05-09 高性能算子库经历案例
33. 博士求职案例
34. Nano-vLLM 怎么学才有竞争力
35. 2026-05-30 职业规划实录

页面目录实际出现 35 个标题位置，其中 2026-04-11 有两个同名但时长不同的投稿；B 站合集计数和搜索快照在不同抓取时间可能存在 1 条更新差异。

帮助：用于校准方向和输出方式，而不是替代技术学习。最值得普遍观看的是 2/3、4/6、8/9、12、15、18、22、30、34；其余按个人背景选择。

### 7. 独立发布、宣传与交叉收录内容

搜索快照还显示了一些没有稳定归入上述主线、或在多个合集之间交叉出现的视频：

- [AI Infra 购课平台上线](https://www.bilibili.com/video/BV13kvKzrEa9)
- [自制深度学习推理框架出书](https://www.bilibili.com/video/BV1MAZBYBELQ/)
- AI Infra 必备 CUDA 入门：Matmul 优化初步
- AI Infra 的招聘要求与学习路线
- AI Infra 2025 秋招/暑期实习经验分享
- OpenAI Triton 推理框架发布与 Qwen3 展示
- 工业级 LLM 推理系统与 Qwen3 全流程展示
- 项目、新书和课程发布类短视频

这些内容更适合用于了解课程边界、岗位趋势和项目包装，不应占用主线编码时间。

## 它对你的学习路线具体有什么帮助

由于工作区里没有找到你现有的路线文档，以下按最常见的目标作出假设：**希望从普通 C++/后端/算法基础，转向 AI Infra、推理框架或算子开发，并用于实习/校招/转岗。**

| 你的路线阶段 | 该 UP 能提供的帮助 | 不能替代的内容 |
|---|---|---|
| C++ 工程基础 | 类设计、工厂注册、资源管理、CMake、测试与项目组织 | C++ 语法、STL、并发、操作系统基础 |
| 深度学习基础 | 用代码解释 Tensor、Conv、Pooling、ResNet、YOLO、LLaMA 组件 | 训练、反向传播、概率统计、优化理论 |
| 推理框架 | 计算图、算子执行、模型加载、内存预分配、后处理 | ONNX Runtime/TensorRT 的完整生产实践 |
| CUDA/算子 | 显存管理、Softmax/RMSNorm/GEMV、Nsight、量化 | 系统的 CUDA 编程教材、GPU 架构与并行算法基础 |
| LLM 推理 | KV Cache、Attention、MLP、权重加载、Qwen/LLaMA | 分布式推理、通信、Serving 稳定性、训练系统 |
| Triton | 编译流程、Matmul、Reduce、Softmax、FlashAttention | 完整编译器原理、MLIR/LLVM 深入内容 |
| vLLM/Serving | PagedAttention、块管理、调度组件与流式推理 | 真实线上容量规划、监控、故障恢复与多机部署 |
| 求职 | 路线校准、简历案例、模拟面试、项目叙述 | 算法题、基础八股、真实实习和开源贡献 |

最大的帮助不是“多知道几个名词”，而是可以形成一条能展示的证据链：

`自己实现算子 → 接入计算图 → 跑通模型 → 做性能基准 → 找到瓶颈 → CUDA/Triton 优化 → 对比结果 → 写成项目文档`

## 推荐学习路线（约 16～24 周）

### 阶段 0：先修检查（2～4 周）

最低要求：

- 能独立写 C++17 小项目，理解 RAII、智能指针、模板、移动语义；
- 会 Linux、Git、CMake、GDB，能读编译报错；
- 理解矩阵乘法、卷积、Softmax、归一化；
- 用过 PyTorch，并知道 ResNet 和 Transformer 的基本结构。

验收物：一个带 CMake、GoogleTest 和 Benchmark 的小型矩阵/张量项目。

### 阶段 1：CPU 推理框架（4～6 周）

主看重制版 1～9 讲；遇到理解断点，再去旧版找细讲。

必须亲手完成：

- Tensor 的 shape/stride/内存布局；
- ReLU、Pooling、Conv 中至少三个算子；
- 算子注册工厂；
- DAG 拓扑关系和执行顺序；
- 跑通 ResNet 或 YOLOv5 中至少一个模型；
- 为算子补单测和性能基准。

阶段验收：不看视频，能画出从模型文件到输出结果的数据流，并能解释每个核心类的职责。

### 阶段 2：CUDA 与 LLM 推理（5～7 周）

按以下顺序选看 CUDA 系列：

1. 资源/显存管理、Tensor、算子类；
2. RMSNorm、Softmax、GEMV；
3. KV Cache；
4. MLP 与多头注意力；
5. 权重加载与完整 Qwen/LLaMA 推理；
6. INT8 分组量化；
7. Nsight Compute 性能分析。

阶段验收：至少有一个 Kernel 的朴素版与优化版，对比正确性、延迟、带宽或吞吐，并写出瓶颈解释。

### 阶段 3：Triton 与 Kernel 优化（3～4 周）

推荐顺序：Reduce → Softmax → Matmul → FlashAttention → 编译流程/综述回看。

阶段验收：对同一个算子给出 PyTorch、CUDA 或 Triton 至少两种实现，并说明输入尺寸变化时性能为何改变。

### 阶段 4：vLLM 与生产推理（2～3 周）

推荐顺序：KV Cache 初始化 → 分块显存 → 请求到块映射 → PagedAttention → 引擎/Worker/Executor → 答疑。

阶段验收：能解释连续批处理、PagedAttention、KV Cache 分配，以及请求从 API 到 Worker 执行的主要路径；最好给 vLLM 或 nano-vLLM 做一次小改动。

### 阶段 5：求职输出（贯穿全程，集中 1～2 周）

只在项目已有可验证结果后看简历与模拟面试视频。简历至少应包含：

- 做了什么组件；
- 为什么这样设计；
- 如何验证正确性；
- 优化前后数据；
- 你本人解决的具体问题；
- 仓库、测试、Benchmark 或 PR 链接。

## 最小观看清单：时间不够时只看这些

1. 重制版 2～6 讲：Tensor、计算图、执行顺序、算子工厂、卷积/池化；
2. 重制版 8 或 9：跑通一个真实模型；
3. CUDA：显存管理、RMSNorm/Softmax、KV Cache、Attention、Nsight；
4. Triton：Matmul、Softmax、FlashAttention；
5. vLLM：分块显存、PagedAttention、引擎架构；
6. 规划：学习大模型推理框架、学习算子开发、简历怎么写、算子优化五步法、Nano-vLLM 如何学。

## 容易踩的坑

- **只看不写**：这类内容的价值 80% 来自编码、调试和性能测量。
- **两个 KuiperInfer 版本都逐集看**：重制版作主线，旧版作字典。
- **过早上 vLLM 源码**：如果还说不清 Tensor、算子和 KV Cache，先回到自制框架。
- **把 Demo 当工业项目**：补齐测试、错误处理、Benchmark、文档和可复现环境后，项目才有求职价值。
- **只报加速百分比**：同时报告硬件、输入尺寸、精度、批量、预热方式和基线。
- **把宣传/规划视频当技术课**：规划内容控制在总学习时间的 10% 以内。
- **忽略基础课**：该 UP 的课程不能替代 C++、操作系统、计算机组成、网络、线代和深度学习基础。

## 建议最终形成的作品集

1. `mini-infer-cpu`：Tensor + 计算图 + 5～8 个算子 + ResNet/YOLO 推理；
2. `mini-llm-cuda`：LLaMA/Qwen 单卡推理 + KV Cache + 关键 CUDA Kernel；
3. `kernel-lab`：CUDA/Triton 的 Matmul、Softmax、RMSNorm、Reduce 性能对比；
4. `vllm-notes-or-pr`：一次源码路径分析、功能改动或开源 PR；
5. 一页技术总结：架构图、性能表、踩坑记录与后续计划。

如果这五项能独立复现并清楚讲出来，这个 UP 的视频就真正转化成了你的学习成果，而不只是播放记录。

## 主要核对来源

- [B 站 UP 主空间](https://space.bilibili.com/1822828582/video)
- [KuiperInfer 项目与两版公开课程目录](https://github.com/zjhellofss/KuiperInfer)
- [KuiperLLama 项目](https://github.com/zjhellofss/KuiperLLama)
- [第一次录制版合集入口](https://www.bilibili.com/video/BV1bG4y1J7sQ/)
- [CUDA 大模型推理框架合集入口](https://www.bilibili.com/video/BV1uRnRe7EFQ/)
- [Triton 系列目录入口](https://www.bilibili.com/video/BV11oRWYWEmW/)
- [vLLM 系列目录入口](https://www.bilibili.com/video/BV1FCLV6LEsu/)
- [AI Infra 规划/模拟面合集入口](https://www.bilibili.com/video/BV1wTVj6SEhk/)
- [付费完整课结构（仅用于核对，不计作公开视频）](https://www.bilibili.com/cheese/play/ss23408)
