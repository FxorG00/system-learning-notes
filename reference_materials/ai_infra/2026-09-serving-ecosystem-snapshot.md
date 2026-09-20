# 2026-09 AI Infra Serving Ecosystem Snapshot

> 核对日期：2026-09-19
>
> 作用：记录本次规划调整所依据的时间敏感事实。它不是永久 syllabus；进入对应阶段时仍要重新核对官方 release、documentation 与 source commit。

## 1. vLLM

官方 GitHub releases 在核对日的 latest 是 `v0.29.0`（2026-09-09）。项目采用约两周一次的 regular release cadence，因此半年后不能继续把本文件中的版本号当成“当前版本”。

V1 已是学习时应采用的主 architecture：

```text
API server / frontend
-> Engine Core
   -> scheduler
   -> KV cache manager
-> GPU workers / model runner
```

对规划有用的设计主题：

```text
unified token-budget scheduling
prefix caching
chunked prefill
speculative decoding
hybrid KV cache management
async scheduling / CPU-GPU overlap
serving metrics 与 disaggregated KV transfer
```

官方入口：

- https://github.com/vllm-project/vllm/releases
- https://github.com/vllm-project/vllm/blob/main/RELEASE.md
- https://github.com/vllm-project/vllm/blob/main/docs/usage/v1_guide.md
- https://docs.vllm.ai/en/latest/design/arch_overview/
- https://github.com/vllm-project/vllm/blob/main/docs/design/prefix_caching.md
- https://github.com/vllm-project/vllm/blob/main/docs/design/hybrid_kv_cache_manager.md
- https://github.com/vllm-project/vllm/blob/main/docs/design/metrics.md

规划结论：T21~T23 只吸收 block KV cache、token budget 和 metrics contract；Gate D 才沿一个 V1 path 读 source，不下载完整仓库囤积。

## 2. SGLang

官方 GitHub releases 在核对日的 latest 是 `v0.5.19`（2026-09-05）。近期 release/blog 的高频主题不是单一 kernel，而是完整 serving path：

```text
hierarchical cache / L3 storage
prefill-decode prefix reuse
pipeline parallel + hierarchical cache
encode-prefill-decode disaggregation for VLM
heterogeneous CPU/GPU EPD
Rust serving frontend / ingress path
overlap scheduling 与多硬件 backend
```

官方入口：

- https://github.com/sgl-project/sglang/releases
- https://www.lmsys.org/blog/
- https://www.lmsys.org/blog/2026-01-12-epd/
- https://www.lmsys.org/blog/2026-06-01-hetero-epd/
- https://github.com/sgl-project/mini-sglang

规划结论：T22 认识 PD/EPD boundary，但不实现 distributed serving；Theory Gate 3 后先读 mini-sglang，再决定是否把 SGLang 作为 Gate D 的 production path。

## 3. DeepSeek Kernel Stack

FlashMLA 在 2026-09-10 发布 DeepSeek-V4.1 attention kernels，覆盖 prefill/decode、FP8/FP4 KV cache format，并提供 fused norm/RoPE/attention/cast path。其 requirements 和 support matrix 明确依赖具体 GPU architecture、CUDA version、model layout 与 precision。

官方入口：

- https://github.com/deepseek-ai/FlashMLA
- https://github.com/deepseek-ai

规划结论：这不是“现在开始抄 CUDA kernel”的信号，而是 model/runtime/kernel/memory layout/hardware co-design 的现实案例。Gate C 前只用来知道对象和边界；Gate C 后才选择一个窄 kernel path 阅读和复现。

## 4. 《我不得不把才华埋葬在昨天》

归属必须写准确：这是 DeepSeek 工程师刘胜与的个人文章，不是 DeepSeek 官方研究院 publication 或公司 roadmap。

可吸收的工程信号：agent 已经能参与文档/源码检索、CUDA/PTX/SASS 阅读、profiling hypothesis 与 patch generation。不可直接接受的推论：基础不再重要、所有工程师会在固定时间内被替代、或者当前应放弃手写 reference 与 profiler 学习。

规划采用的 workflow：

```text
human：定义 workload、contract、oracle、baseline、measurement
agent：协助检索、代码阅读、候选实现与假设生成
human：审查 semantic diff、lifetime、synchronization、numerical error 与 profiler evidence
result：固定版本和环境后，才形成可复现结论
```

公开报道/转述入口只用于确认作者身份和文章背景，不作为 DeepSeek 技术规范：

- https://tech.yahoo.com/ai/articles/deepseek-engineers-viral-post-talent-073951109.html

## 5. 对当前路线的最终影响

```text
不变：HTTP -> Mini Redis -> AI workload literacy -> CPU inference -> CUDA -> serving framework

增强：
T20 memory object/tier accounting
T21 block/page KV cache 与 prefix reuse
T22 token-budget scheduling、chunked prefill、PD/EPD boundary
T23 TTFT/TPOT/throughput/cache-state benchmark discipline
Theory Gate 3 后 mini-sglang fixed-snapshot reading
Gate D 只选一个 vLLM V1 或 SGLang production path
所有阶段加入 AI-assisted engineering，但保留 human-owned oracle 和 evidence

继续不做：
现在下载完整 vLLM/SGLang
现在展开 DeepEP、multi-GPU、Rust frontend 或 CUDA kernel 主线
把上游 benchmark 数字写成自己的项目证据
```
