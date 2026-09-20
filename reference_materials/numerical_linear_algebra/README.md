# Applied/Numerical Linear Algebra 本地参考资料索引

> 建立日期：2026-09-18
>
> 定位：给 AI Theory 与后续 AI Infra 的数值计算、稳定性和性能分析提供定向参考；不构成新的并行课程。

---

## 1. 资料信息

```text
文件名：NLA-en.pdf
标题：Applied/numerical linear algebra
作者：Tiansong Cheng
页数：88
本地路径：C:\Users\FxorG\Desktop\gpt_infra\reference_materials\numerical_linear_algebra\NLA-en.pdf
```

这是一份英文课程讲义，内容从基础线性代数一路延伸到：

```text
LU / Cholesky
least squares / regularization
orthogonality / QR / numerical stability
eigenvalue / SVD / pseudoinverse / PCA
condition number / iterative methods / gradient descent
convolution / DFT / FFT
```

它的主要价值不是替代学校线代，而是把数学对象继续连接到：

```text
operation count
numerical stability
conditioning
iterative convergence
low-rank approximation
convolution and FFT
```

---

## 2. 按阶段定向使用

| 页码 | 内容 | 在当前规划中的用途 |
|---|---|---|
| 1~4 | vector space、inner product、norm、matrix multiplication | T2/T3 可选查证；用户已有线代基础，不设为必读 |
| 18~29 | least squares、pseudoinverse、regression、regularization | T7/T8 进入 regression 与 regularization 时定向参考 |
| 30~43 | orthogonality、Gram-Schmidt、QR、least squares、stability | T23 或数值正确性专题，用于解释“公式等价不代表数值表现等价” |
| 44~65 | eigenvalue、SVD、low-rank approximation、PCA | T14 可延期阶段或后续 compression/quantization 前置参考 |
| 66~80 | operator norm、condition number、iterative methods、gradient descent、convergence | T7 的梯度下降只选必要片段；T23 再系统连接 conditioning 与 convergence |
| 81~88 | convolution、Toeplitz/circulant matrix、DFT、FFT | 后续 operator/kernel 阶段参考，不提前塞进当前 T module |

页码以 PDF 页面编号为准。使用前应再核对对应页面标题，避免因为版本变化机械引用。

---

## 3. 使用边界

这份讲义不作为当前 T3 或后续任意一周的整本必读材料，原因是：

```text
用户已经完成学校线性代数训练
讲义是高密度英文课堂笔记，不是循序渐进教材
部分示例使用 MATLAB 记法
覆盖范围远大于当前 AI Infra 主线的即时需要
```

以后生成相关 `Tn.md` 时：

```text
先按 AI_Infra理论伴随线规划.md 确认本周边界
-> 只读取本索引中真正相关的页段
-> 用教程自己的中文因果链讲清机制
-> 数值算法/API 事实再用正式教材、NumPy/PyTorch 官方文档或 source 核验
-> 用最小代码和 observable evidence 验证当前结论
```

不能因为本地已有整本讲义，就额外增加一条“完整数值线性代数通关线”。讲义中的复杂度、稳定性和收敛结论也不能脱离 assumptions 直接写成普遍结论。

---

## 4. 本地保存与版本管理

PDF 只用于个人学习和教程准备。当前没有随文件提供的明确再分发许可信息，因此 `NLA-en.pdf` 已由父仓库 `.gitignore` 排除；本索引可以进入 Git，PDF 原件不随公开学习仓库分发。
