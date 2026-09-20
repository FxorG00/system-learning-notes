# AI Infra 本地参考资料索引

> 建立日期：2026-09-17；最近校准：2026-09-19
>
> 定位：服务后续 AI Theory 与 AI Infra 教程编写，不构成新的并行课程。

---

## 1. 本地资料

### 1.1 《深入理解 AI Infra：量化分析与系统设计》

```text
本地路径：C:\Users\FxorG\Desktop\gpt_infra\AI-Infra-Book.pdf
作者：李博杰
页数：518
```

主要用途：

```text
第 1~3 章：workload、模型执行、训练/推理负载与资源估算
第 4~5 章：accelerator、operator、runtime、data movement
第 6~7 章：parallelism、collective communication、data-center network
第 8 章：request lifecycle、batching、KV Cache、quantization、speculative decoding
第 9~10 章：distributed inference 与 training systems
```

后续教程优先吸收它的分析方法：

```text
先明确 workload 和 assumptions
-> 画清对象、数据和依赖流
-> 分别计算 capacity / computation / communication
-> 找出谁必须等待谁
-> 给出理论 lower bound
-> 用 measurement 校正模型
```

不把整本书设为当前必读任务，也不在 Week11 HTTP / Week12 Mini Redis 中提前展开 accelerator、vLLM 或 distributed inference。

### 1.2 InfraTech 精选本地镜像

```text
上游：https://github.com/CalvinXKY/InfraTech
固定 commit：b55ed0b7bcadcc1b203d98af5d2b9d83bb2b9299
本地目录：C:\Users\FxorG\Desktop\gpt_infra\reference_materials\ai_infra\InfraTech
```

上游当前没有明确的 `LICENSE` 文件，因此本地镜像只用于个人学习与教程准备，已被父仓库 `.gitignore` 排除。引用代码或图示时保留来源链接，不把 notebook 原文复制进自己的公开教程。

---

## 2. 精选 notebook 与 serving source snapshots

| 本地相对路径 | 主要用途 | 预计使用阶段 |
|---|---|---|
| `deeplearning_framework/mini_dl_framework.ipynb` | 从小型计算图到 MLP training flow | T7~T12 的补充实验，不替代自己的 reference implementation |
| `models/modules/rope_principle.ipynb` | RoPE 的 shape、position 与旋转机制 | T15~T18，进入 Transformer block 后再用 |
| `llm_infer/LLM_sampling.ipynb` | temperature、top-k、top-p 等 sampling 行为 | T19；T5/T6 只建立概率与 stable softmax 基础 |
| `llm_infer/nano_vllm.ipynb` | Sequence、block table、KV block 与简化 serving flow | T21~T23；先完成 attention/decoder/KV 基础 |
| `llm_infer/vllm_mem_snapshot.ipynb` | vLLM memory snapshot 的最小观察 | T20~T21，配合内存估算与实测 |
| `llm_infer/vllm_basic_scheduler.ipynb` | waiting/running sequence 与 batch scheduling | T22；先写自己的 batching simulation，再对照 |
| `llm_infer/quantization.ipynb` | quantization 第一层实验 | T24 后或正式推理优化阶段 |
| `llm_infer/parallel_strategies.ipynb` | tensor/pipeline/data parallel 的映射 | 单 GPU serving 稳定后的 distributed gate |
| `deeplearning_framework/collective_operations.ipynb` | collective communication 基本操作 | NCCL / distributed inference gate，不提前进入当前主线 |

本地还保存了上游 `README.md`，用于确认原作者给出的主题地图。未下载的 MLA、speculative decoding、SGLang profiling、RL co-location 等 notebook，不属于当前阶段资料；真正进入对应阶段时再重新核对上游最新版本，而不是一次性囤积。

### 2.1 Mini-SGLang 官方源码快照

```text
上游：https://github.com/sgl-project/mini-sglang
下载日期：2026-09-19
页面核对 commit：9a91cfa（2026-05-17）
本地目录：reference_materials/ai_infra/serving_sources/mini-sglang
许可证：MIT
```

它是约 5,000 行 Python 的教学型 serving implementation，包含 radix cache、chunked prefill、overlap scheduling、tensor parallel 与 optimized-kernel integration。当前只保存，不安装、不运行；Theory Gate 3 前不进入源码主线。到达 Gate 后先读 `docs/structures.md`、`docs/features.md`，再沿一条 request-to-runner path 阅读，不能把“下载了源码”记成“掌握 SGLang”。

### 2.2 DeepSeek FlashMLA 官方源码快照

```text
上游：https://github.com/deepseek-ai/FlashMLA
下载日期：2026-09-19
页面核对 commit：ba89a34（2026-09-15）
本地目录：reference_materials/ai_infra/serving_sources/FlashMLA
许可证：MIT
```

该 snapshot 已包含 2026-09-10 发布的 DeepSeek-V4.1 attention kernels：prefill/decode、FP8/FP4 KV cache format 与 fused norm/RoPE/attention/cast path。它用于未来观察 model/runtime/kernel/hardware co-design，不是当前 CUDA 入门材料；当前机器没有满足其 SM90/SM100 与 CUDA 12.8+ 要求的证据，因此不安装、不跑 benchmark，也不引用上游性能数字作为本机结果。

---

## 3. 教程生成时怎样使用

### AI Theory

```text
先按 AI_Infra理论伴随线规划.md 确认当前 T module 的学习边界
-> 读取本索引中真正对应的章节/notebook
-> 教程用自己的中文因果链讲清机制
-> notebook 只作为第二解释源、实验参考或独立对照
-> 仍由自己的最小代码、prediction 和 observable evidence 验收
```

### 系统主线 daily

只有当当天问题确实进入 model serving、data movement、runtime、KV Cache 或 distributed systems 时，才引用这些资料。当前 HTTP、RESP、Mini Redis 的协议解析与系统工程主线不因为资料存在而改道。

### 技术核验

```text
书和 notebook：用于建立解释、量化模型和实验线索
官方文档 / specification / framework source：用于核验会变化的 API 与实现事实
实测：用于验证当前机器、版本和 workload 下的行为
```

硬件参数、框架行为与性能数字必须记录 assumptions、版本或 commit。不能把教育 notebook 当成永久规范，也不能把某次 benchmark 数字写成普遍结论。

---

## 4. 2026-09 serving 官方资料入口

这些链接用于核验会快速变化的事实，不做离线全文镜像：

本轮完整核对记录见 `2026-09-serving-ecosystem-snapshot.md`。

```text
核对日期：2026-09-19
vLLM latest GitHub release：v0.29.0（2026-09-09）
SGLang latest GitHub release：v0.5.19（2026-09-05）
```

| 主题 | 官方入口 | 进入时机 |
|---|---|---|
| vLLM release cadence / releases | `https://github.com/vllm-project/vllm/releases`、`RELEASE.md` | 每次真正开始 vLLM 实验前重新核对 |
| vLLM V1 architecture | `docs/usage/v1_guide.md`、`docs/design/arch_overview.md` | T21~T23 只读设计边界；Gate D 才追 source |
| vLLM prefix / hybrid KV cache | `docs/design/prefix_caching.md`、`hybrid_kv_cache_manager.md` | T21 后 |
| vLLM metrics | `docs/design/metrics.md` | T23 |
| SGLang releases | `https://github.com/sgl-project/sglang/releases` | 开始 production comparison 前 |
| SGLang/LMSYS engineering blogs | `https://www.lmsys.org/blog/` | T22~Gate D 定向阅读 PD/EPD、HiCache、benchmark |
| DeepSeek kernels | `https://github.com/deepseek-ai/FlashMLA` | Gate C 后 |

截至 2026-09-19，vLLM 已以 V1 为主架构，SGLang 的近期变化集中在 hierarchical cache、disaggregation、serving frontend 与多后端，DeepSeek FlashMLA 则直接体现模型结构、KV format、fused kernel 与 GPU architecture 的协同。它们共同支持当前规划中的 T20~T23 增强项，但不构成提前学习完整框架、Rust、多 GPU、DeepEP 或 CUDA 的理由。

刘胜与的《我不得不把才华埋葬在昨天》按个人工程文章处理，不归类为 DeepSeek 官方研究院 publication。可吸收的只有 AI-assisted engineering 方法：人负责 contract、oracle、workload、baseline 与 profiler 判断，agent 可协助检索、读代码和生成候选 patch；其中任何时间预测都不能写进硬性学习日程。
