# T13 教材参考实验记录

> 记录日期：2026-09-03
> 本文件是教材验证证据，不是用户的 T13 作业、分数或通过记录。
> 正文观察闸门之前不必阅读本文件。

## 环境与范围

验证使用 Ubuntu 的独立临时 venv，没有替换系统 Python，也没有改动用户主线代码。

| 项目 | 本次实测 |
|---|---|
| Python | 3.12.14 |
| PyTorch | 2.14.0+cpu |
| NumPy | 2.5.2 |
| Matplotlib | 3.11.1 |
| device | CPU |
| PyTorch CPU 运算线程数 | 1 |
| dtype | float32；隔离的衰减小例子使用 float64 |

这些版本是一次验证快照，不是永久 pin。正式学习环境仍按 [ENVIRONMENT.md](../ENVIRONMENT.md) 建立。

## 实验设置

- 数据与模型严格使用 T13 第 4 节。
- train / validation 分别为 seeds 1301 / 1302，24 / 256 个样本。
- 初始化 seeds 13、23、33，每个分别运行 AdamW weight_decay 0.0 / 0.1。
- 两组初始参数逐 Tensor 验证相同，optimizer 分别新建。
- learning rate 0.01，2000 次 full-batch 更新。
- epoch 0 和每 20 次更新记录一次，两种指标都在 eval + inference_mode 下计算。
- 每次记录的 validation MSE 改善时深拷贝 state；新对象恢复后复测。

没有根据结果增加、替换或只挑某个 seed。seed 13 的正则化没有改善验证指标，正文如实展示。

## 原始数据

[reference_results.json](assets/reference_results.json) 保存六组完整 history。

每个对象包含：

- seed、weight_decay；
- initial、best_val_checkpoint、final；
- curve，每一行依次是 epoch、train MSE、validation MSE。

每组有 101 条曲线记录。主图只使用 seed 13 的两组记录；上排显示全程，下排显示 epoch 40 之后，两列共用对应行的纵轴尺度。

![参考曲线](assets/reference_curves.png)

## 已执行的验证

- 六组训练均正常结束；最后 train MSE 低于对应初始值。
- 六组记录时点均为 0、20、40，直到 2000。
- 六组最佳 state 在新对象中恢复，validation MSE 与记录差值小于 1e-6。
- seed 13 按 validation 选择配置后，完成 torch.save、torch.load、load_state_dict，再做 validation 复测及保留 test split 的最终评估；结果有限且非负。没有根据 test 更改选择，数值不作为教材答案发布。
- AdamW 零 gradient 小实验：参数 2.0 更新为 1.96。
- Dropout p=0.5：train 输出取值只有 0/2；train + no_grad 仍然如此；eval 恒等。使用 4096 个全 1 输入观察到的两次零元素数为 2058、2037，检查不依赖这些具体数量。
- 参考程序正常返回 exit 0；没有用本结果替用户宣告 T13 通过。

文档检查另在本地执行：13 个 Python 片段通过 AST 语法检查，37 个数学表达式通过 KaTeX 严格解析，14 个独立公式已生成浏览器预览并目视检查；Markdown fences、本地链接及配图存在性通过。没有直接操作 Typora，不把兼容语法与浏览器预览冒充 Typora 实机验证。

完整教材向 Ubuntu 的额外上传被安全审核阻止，未继续传输；因此不声称正文的 13 个片段全部单独动态执行。上面的训练、Dropout、AdamW 和快照检查来自已成功运行的独立参考程序。

## 证据边界

这证明固定教学实验可以执行，且本次 API / 数据记录 / 状态恢复行为符合预期，不证明：

- weight decay 总能提升泛化；
- 这些超参数适用于真实业务数据；
- 三个初始化覆盖了换数据、换平台的变化；
- 微小 validation 差异具有统计显著性；
- 本实验具有模型部署性能或大型训练工程的代表性。

参考实现只用于教材 QA，不随讲义提供完整训练答案；用户仍独立完成自己的 overfit_observation.py。
