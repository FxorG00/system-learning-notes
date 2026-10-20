# AIInfraGuide 怎样用于我们的学习

> 核对日期：2026-10-19，T10映射按三个能力阶段与停止点校准，阶段分段不等于独立发现闸门。本文是本地路线的参考映射，不是另一份必修课表。
> 来源：[网站][site]、[GitHub][repo]。本次抽读代表文章，未逐篇审校或固定全站 commit；真正使用某篇时重新核对链接与相关事实。

**有帮助，最适合补上“模型在算什么 -> 占用什么资源 -> 推理服务怎样安排这些工作”这条连接。** Mini Redis主线保持；理论T9已通过、下一步T10，不按网站目录重新学一遍数学、C++或机器学习。

## 1. 当前怎么用

现在主线为Week13 Day4整日已通过99/100、R1历史100保持，Day5教程已生成、待R1；理论T1~T9和Theory Gate 1已通过，T9最终99/100。T10~T14仍属提前稿，按相邻前课通过后的真实结果校准，不因文件存在就登记已学。

进入 T9 时，由我们的讲义先把 NumPy 数组接到 PyTorch Tensor；若需要第二种解释，再读下面指定的小节。网站同一篇文章可能同时含入门、完整实现和 GPU 优化，**只读对应部分，不默认一路读到底**。外部完整代码留在本课独立练习之后；选择性的补充阅读占用原有理论时间，不叠加新课程或重复作业。

## 2. 对应到现有 T 模块

下表的小节名按本次实读页面定位。未来章节改名时，按标题重新核验，不猜锚点或沿用失效编号。

| 本地模块 | 文章与范围 | 插入位置、用途和停止边界 |
|---|---|---|
| T9 | [PyTorch 入门][pytorch] §1.1 创建、§1.2 形状、§1.4 dtype | 基础对象讲清后可选读创建/dtype；独立 layout 预测完成后再对照形状例子。目标是连接 NumPy 与 Tensor；storage/stride 的精确判断用本地正文和官方文档。停在 §1，不跟跑 CUDA 搬运。 |
| T10 | [同文][pytorch] §3 `nn.Module` | 本课R1模型与注册状态已经讲清、最小模型实际运行后，可选读对照组织方式；随后遵守本地R1/R2停止点。复用同一模型，不另写网站的分类器，不提前跟跑后续训练或GPU内容。 |
| T11 | [同文][pytorch] §2 自动微分 | R1 标量实验后对照 `.grad` 累加和清零；结合下方官方更正理解非标量 backward。保留本课的独立预测，不提前读同题答案。 |
| T12 | [同文][pytorch] §4 完整训练循环 | 自己的 MLP 闭环后，对照 forward、loss、backward、step 的连接。不增加另一套数据集、训练器或混合精度任务。 |
| T15 | [3.9 Tokenization 与词嵌入][embedding] §1、§4.3、§6 | 先理解“文字为何要变成数字”和 embedding 查表，再对照 token IDs 到输入矩阵。分词算法细节按需要选看，不实现完整 tokenizer。 |
| T16 | [3.3 Self-Attention][attention] §2、§3、§5~§6 | 本课单头 reference 完成后，复核 Q/K/V 的用途、矩阵轴和缩放来源。§4 的完整代码后读；MHA/GQA/MLA、FlashAttention 留给后续阶段。 |
| T17~T18 | [3.7 Decoder Block][decoder] §2~§3；[Transformer 工程地图][transformer] §3 | 在自己的 block/decoder 链建立后，定位 attention、归一化、FFN 与残差各在处理什么。完整实现放在独立产出之后；架构比较和显存规划只在相应需求出现时读。 |
| T20 | [分布式训练总论][training] §2；[LLM 推理基础][inference] §2.3 | 用自己的 Module/optimizer 对象核算参数、梯度、优化器状态和激活，再对照推理 KV 账。写明 dtype 与训练实现假设；停在对象/容量比较，不启动分布式训练。 |
| T21 | [LLM 推理基础][inference] §1~§2；[PagedAttention][paged] §1~§4 | 自己的连续 KV reference 数值正确后，用块表例子理解按需分配与尾块浪费。先做本地规划已有的分块仿真；本站 §8 参数配置与 §9 框架源码后置 Gate D。 |
| T22 | [Continuous Batching][batching] §1~§4、§7 | 先完成自己的调度仿真，再比较整批等待和按迭代接纳/退出。识别吞吐、排队和延迟的取舍，停止在策略解释；§6 源码留到 Gate D。 |
| T23 | [LLM 推理基础][inference] §3~§4；[PyTorch 入门][pytorch] §6 选看 | 已有本地计时结果后，再连接首词延迟、逐词延迟、吞吐与计算/访存估算。GPU profiler 示例只在具备硬件后使用；CPU 计时、仿真或上游数字均不能充当本机 GPU 证据。 |

T13 继续复用 ML/T8 的 generalization 基础与既定实验，不为引用此站再训练同构模型。T14 仍可延期，首次简历的优先项保持 T1~T13 + T15~T16；T17~T18 仍是后续冲刺项。视频仍以规划中的吴恩达、李沐两条基准为准。

## 3. 以后才启用的部分

**CUDA（GPU 并行编程）从总规划 Gate C 开始。** 先满足 CPU inference 闭环、硬件基础复核和可用 NVIDIA GPU，再用 [CUDA 入门][cuda] 的编程/内存模型补充解释，沿自己的 vector add、reduction 等 reference 验证。设备上限、编译参数和示例语法另查 NVIDIA 官方资料，不能据文章直接改当前 Ubuntu 环境。

**Serving（在线推理服务）的完整源码阅读从既定 Gate D 开始。** Theory Gate 3 后仍先读固定版本 mini-sglang 的一条请求路径；本站推理引擎文章只帮助解释已遇到的对象。已有 InfraTech/nano-vLLM 也按同样方式择优使用，不再增加第二个完整框架项目。运行 GPU 引擎、Triton 算子和实际优化仍需相应 CUDA 前置。

**通信与多卡由 Gate E 控制。** T20 可以选读训练显存账，AllReduce（多参与者归约后让各方都拿到结果）、NCCL、多种并行策略的系统学习则等待单卡 serving 与多 GPU 条件。量化、投机解码等仍按总规划后置，不因本站已有文章提前变成当前任务。

## 4. 面经怎样帮助求职

[面试目录][interviews] 用来寻找缺口，再回到本地项目和知识补缺安排验证。先看真实问题内容和原岗位：同站的 [腾讯实习样本 A][tencent-a] 包含 C#、GameObject、UI，而 [样本 B][tencent-b] 包含 CUDA、Nsight 和算子问题。**相似标题不能证明它们在招聘同一类岗位，也不能合并成你的当前统一门槛。** 这只是对聚合内容的观察，不代表已核验原始面试真实性。

近期仍以 C++/Linux 后台与 Infra 岗位匹配为主，复用已有虚函数、对象生命周期、网络、并发与项目性能证据；AI 算子/推理题按 T 模块与 Gate 归档。实际招聘批次、在校要求和职责要查当次官方岗位，不照搬网站的公司梯队或“岗位多/少”判断。

## 5. 已发现的简化，使用时这样校准

这些例子说明为什么它适合作为第二讲解源，而不是规范；没有据此否定其整站内容，也没有完成全站勘误。

| 文章中的表述 | 我们采用的准确边界 | 核验入口 |
|---|---|---|
| PyTorch 入门把 `backward()` 限为标量 | 非标量也可调用，需要显式传入匹配的上游梯度；省略该参数的调用有更窄条件 | [PyTorch 2.14 `Tensor.backward`][backward-doc] |
| 同文用“内存连续”概括 `view(shape)` 的要求 | 判断的是目标 shape 与原 size/stride 是否兼容；不能把所有非连续 Tensor 都判成不能 view | [PyTorch 2.14 `Tensor.view`][view-doc] |
| PagedAttention 示例注释把 `gpu_memory_utilization` 说成剩余显存的 KV 比例 | 它限制该实例 model executor 使用的设备显存比例，不是“扣掉权重后再乘一次”的 KV 专属比例；默认值按使用版本核验 | [vLLM Engine Arguments][engine-doc] |
| 推理/批处理文章给出固定利用率增幅、近乎无延迟代价等概括 | 当作待测假设。结果取决于模型、硬件、batch、上下文、到达过程与调度；应分别记录吞吐、排队和尾延迟 | 本地 T22 仿真、T23 方法与最终实际 GPU 测量 |

PagedAttention 的分页类比也要限定在相应块池：按需分块减少预留和外部碎片，最后一个未填满块仍会有内部浪费，不能推成整个进程“零碎片”。原理可对照 [PagedAttention 论文][paged-paper]，真实 vLLM 对象和方法以固定版本源码为准。本站独立“性能分析”栏目本次显示 0 篇，PyTorch 与推理文章内已有相关小节；未来生成课程前要确认真正可读内容，而不是只引用目录标题。

## 6. 教程编写时怎样吸收

先找本课还没讲通的问题，再选一处能帮上忙的解释。正文按 MEMORY 的已有规则，从熟悉对象走通动作、结果与用途，再引入名称和公式；引用图时交代图中对象及其与当前问题的关系。**不把学生送去网站自行拼接必学内容，也不把本映射逐行变成作业。**

同一问题已有本地讲义、书或 InfraTech 的充分解释时，不重复指定三份阅读。引用 API/算法/硬件结论先查官方来源，使用性能数字必须保留实验条件。本站与现有资料相互补充，不改变主线 daily 结构、R1 独立空间或 R1 通过后的定向润色规则。

本地只保存本映射和来源链接，未复制第三方全文、代码或图片。公开可读和 GitHub 可见均不等于获得重新分发授权；确需下载或转载时另核许可证与具体内容权利。

[site]: https://caomaolufei.github.io/AIInfraGuide/
[repo]: https://github.com/caomaolufei/AIInfraGuide
[pytorch]: https://caomaolufei.github.io/AIInfraGuide/prerequisites/模块一-前置知识/pyroch/pytorch框架入门/
[embedding]: https://caomaolufei.github.io/AIInfraGuide/prerequisites/模块一-前置知识/transformer/39-tokenization与词嵌入/
[attention]: https://caomaolufei.github.io/AIInfraGuide/prerequisites/模块一-前置知识/transformer/33-self-attention机制深入理解/
[decoder]: https://caomaolufei.github.io/AIInfraGuide/prerequisites/模块一-前置知识/transformer/37-transformer-decoder-block完整解析/
[transformer]: https://caomaolufei.github.io/AIInfraGuide/prerequisites/模块一-前置知识/transformer/31-ai-infra工程师为什么必须懂transformer/
[training]: https://caomaolufei.github.io/AIInfraGuide/distributed/模块三-分布式训练/11-分布式训练总论/
[inference]: https://caomaolufei.github.io/AIInfraGuide/inference/模块四-推理优化/第1章-llm推理基础/11-llm推理基础/
[paged]: https://caomaolufei.github.io/AIInfraGuide/inference/模块四-推理优化/第2章-推理引擎核心技术/21-pagedattention/
[batching]: https://caomaolufei.github.io/AIInfraGuide/inference/模块四-推理优化/第2章-推理引擎核心技术/22-continuous-batching/
[cuda]: https://caomaolufei.github.io/AIInfraGuide/cuda/模块二-cuda编程与算子优化/cuda编程入门指南/
[interviews]: https://caomaolufei.github.io/AIInfraGuide/interview/
[tencent-a]: https://caomaolufei.github.io/AIInfraGuide/interview/腾讯-ai-infra-实习/
[tencent-b]: https://caomaolufei.github.io/AIInfraGuide/interview/腾讯-ai-infra-实习-一二面/
[backward-doc]: https://docs.pytorch.org/docs/2.14/generated/torch.Tensor.backward.html
[view-doc]: https://docs.pytorch.org/docs/2.14/generated/torch.Tensor.view.html
[engine-doc]: https://docs.vllm.ai/en/latest/configuration/engine_args/
[paged-paper]: https://arxiv.org/abs/2309.06180
