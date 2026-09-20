# Serving Source Snapshots

> 下载日期：2026-09-19
>
> 作用：为 Theory Gate 3、CUDA Gate 和后续 serving source reading 保存可追溯的官方源码快照。源码目录只在本机保留，并由父仓库 `.gitignore` 排除。

## mini-sglang

```text
upstream: https://github.com/sgl-project/mini-sglang
page-verified commit: 9a91cfa
download ZIP SHA256: 00DAE714C91887E9638D64662122EEBC1DEA4826DA01760D35362BACCEEEC5E6
local directory: mini-sglang/
license: MIT
```

进入顺序：

```text
Theory Gate 3
-> docs/structures.md
-> docs/features.md
-> request/sequence -> scheduler -> batch -> model runner 主路径
-> radix cache / block table / chunked prefill / overlap scheduling
```

这是一份教学型 reference，不代表 production SGLang 的全部架构或当前行为。真正对照 SGLang 前重新核对官方 release 和当前 commit。

## FlashMLA

```text
upstream: https://github.com/deepseek-ai/FlashMLA
page-verified commit: ba89a34
download ZIP SHA256: F69901BC02C06231F44A32106CD17D66C0A235252DB34AE329791AEBBC1B7C86
local directory: FlashMLA/
license: MIT
```

本 snapshot 包含 2026-09-10 的 DeepSeek-V4.1 attention kernel 更新。进入顺序：

```text
Theory Gate 3 完成
-> CPU inference reference 完成
-> CUDA Gate 通过并有合适 GPU
-> 先读 README 的 requirements / layouts / tests
-> 再选择一个 prefill、decode 或 fused path
```

未经匹配硬件和固定 workload 的复现实验，不把上游 benchmark 数字写成自己的性能结论。

## 不在当前阶段下载

```text
完整 vLLM repository
完整 SGLang repository
DeepEP / DeepGEMM / TileKernels dependency graph
模型 weights
```

原因不是它们不重要，而是版本变化快、体积和依赖大，并且当前学习阶段没有能提出的窄问题。需要时按当时的官方 release/commit 重新获取，避免拿过期快照当永久规范。
