# Kaggle 入门实践：把机器学习知识走成一次完整交付

> 版本：2026-09-24
>
> 前置讲义：[ML.md](ML.md)
>
> 经典算法作业：[ML_配套练习.md](ML_配套练习.md)

可以做 Kaggle，但它在当前路线里只承担一个任务：**把已经学过的模型，放进一次真实的“读数据、做验证、生成预测、提交结果”工作流。**

它不是新的竞赛主线。我们不刷 leaderboard（排行榜），也不把大量时间投入手工特征工程。系统主线仍然是 HTTP Server -> Mini Redis，后续再走向 inference serving（推理服务）。

---

## 1. 为什么经典作业之后还要做一次 Kaggle

`ex1~ex8` 很适合学习算法，因为数据、局部检查值和目标都已经整理好。但真实任务不会替你把每一层边界都铺平。

一场最小 Kaggle 实践会多出下面这条链：

```text
拿到 train/test 文件
-> 检查 schema、shape、缺失值和 label
-> 从 train 中划出本地 validation set
-> 只用 training split 拟合 preprocessing 和 model
-> 用 validation metric 判断是否真的改进
-> 在完整 train 上重新训练
-> 为隐藏 label 的 test 生成 submission.csv
-> Kaggle 返回一次外部 score
```

这条链对 AI Infra 有价值。模型服务最终接收的也是有 schema（数据结构约定）的输入，经过 preprocessing（预处理）、batching（批处理）和 inference（推理），再产生可检查的 output。Kaggle 让你先在小数据上经历一次完整边界，而不是只在 notebook 里看一个 loss 下降。

---

## 2. 只安排两场，不开刷榜支线

| 定位 | 比赛 | 进入时间 | 要解决的问题 | 时间上限 |
|---|---|---|---|---:|
| 必做 | [Titanic](https://www.kaggle.com/competitions/titanic) | T13 和 Ex5 通过后 | validation、缺失值、类别字段、submission workflow | 4~6 小时 |
| 选做 | [Digit Recognizer](https://www.kaggle.com/competitions/digit-recognizer) | T12 和 Ex3/Ex4 通过后 | image tensor shape、batch inference、accuracy、吞吐观察 | 4~6 小时 |

顺序看起来有一点反直觉：`Digit Recognizer` 的模型更接近 T12，但它是选做；`Titanic` 更简单，却要等 T13。

原因是 Kaggle 最重要的第一课不是“模型越复杂越好”，而是**先建立可信的本地验证，再看隐藏 test 的分数**。T13 正好补齐 generalization（泛化）、data leakage（数据泄漏）和 baseline（基线）这些必要能力。

`House Prices` 当前不安排。它本身是好比赛，但更容易把时间吸进 tabular feature engineering（表格特征工程）和 boosting 调参，对当前 C++ / AI Infra 路线的边际收益较低。

---

## 3. 开始前只配置一次 Kaggle

不要现在为了“提前准备”打断 T4。真正走到对应节点时再做下面的设置。

### 3.1 安装本地工具

```bash
python3 -m pip install --user kaggle pandas scikit-learn
```

- `pandas`（表格数据处理库）：读取 CSV、检查字段和生成 submission；
- `scikit-learn`（经典机器学习库）：负责数据切分、预处理、baseline model 和 metric；
- `kaggle`：官方 CLI（命令行工具），负责下载比赛文件和提交结果。

### 3.2 账号与凭据

1. 打开比赛页面并点击 `Join Competition`，阅读并接受规则；
2. 在 Kaggle Settings 的 API 区域配置登录；
3. 优先使用 `kaggle auth login`，或者把 token 放进 Kaggle 官方指定的位置；
4. **任何 token、`kaggle.json` 或 access token 都不能进入本仓库。**

检查 CLI：

```bash
kaggle --version
kaggle competitions files titanic
```

如果 CLI 配置卡住，直接从比赛的 `Data` 页面手动下载也可以。账号配置不是本次机器学习练习的核心。

### 3.3 本地目录

```text
ML/kaggle/
├── titanic/
│   ├── data/          # 比赛原始数据，不提交 Git
│   ├── src/           # 你的代码
│   ├── artifacts/     # metric、图、submission
│   └── README.md
└── digit_recognizer/
    ├── data/
    ├── src/
    ├── artifacts/
    └── README.md
```

下载 Titanic：

```bash
mkdir -p ML/kaggle/titanic/data
kaggle competitions download titanic -p ML/kaggle/titanic/data --unzip
```

下载 Digit Recognizer：

```bash
mkdir -p ML/kaggle/digit_recognizer/data
kaggle competitions download digit-recognizer -p ML/kaggle/digit_recognizer/data --unzip
```

---

# 实践一：Titanic

## 4. 这次到底要做成什么

你会得到三份 CSV：

```text
train.csv
test.csv
gender_submission.csv
```

`train.csv` 有乘客资料和 `Survived` label（生存标签）；`test.csv` 只有乘客资料，真正答案由 Kaggle 保管；`gender_submission.csv` 只是 submission format（提交格式）示例，不是 test 的 ground truth（真实答案）。

最终程序完成四件事：

```text
读取 train.csv
-> 建立一个可复现的本地 validation score
-> 使用全部 train rows 训练最终模型
-> 对 test.csv 预测并生成 submission.csv
```

Kaggle 官方使用 accuracy（准确率），也就是预测正确的乘客占全部乘客的比例。提交文件必须只有 `PassengerId` 和 `Survived` 两列，共 418 条预测加一行 header。

---

## 5. 第一眼先确认数据，而不是先选模型

新建：

```text
ML/kaggle/titanic/src/train_and_submit.py
```

先加载数据：

```python
from pathlib import Path

import pandas as pd

data_dir = Path(__file__).resolve().parents[1] / "data"
train = pd.read_csv(data_dir / "train.csv")
test = pd.read_csv(data_dir / "test.csv")

print(train.shape)
print(test.shape)
print(train.columns.tolist())
print(train["Survived"].value_counts(dropna=False))
print(train.isna().sum().sort_values(ascending=False).head())
```

这一步不是 EDA（exploratory data analysis，探索性数据分析）表演。你只回答会影响程序 contract 的问题：

- 一行是不是一名乘客；
- label 在哪一列；
- 除 `Survived` 外，train/test 是否拥有相同 feature columns；
- 哪些字段有 missing value（缺失值）；
- 哪些字段是数字，哪些是类别文字；
- test 的 row order 和 `PassengerId` 怎样进入最终 submission。

到这里先不要看高分 notebook。你需要先从数据本身建立第一版理解。

---

## 6. 本地 validation 才是主要法官

Kaggle 隐藏了 `test.csv` 的答案，所以你不能每改一次代码就靠 leaderboard 判断方向。先从 `train.csv` 划出 training split（训练子集）和 validation split（验证子集）。

本次固定：

```text
random_state = 42
validation ratio = 20%
stratify by Survived
metric = accuracy
```

`stratify`（分层抽样）会让两个 split 的生存/未生存比例尽量接近。固定 random seed 不是证明结果绝对可复现；它只是保证你比较两次改动时，没有同时偷偷换一套划分。

最重要的边界是：

```text
training split
-> fit 缺失值填充规则、类别编码和 model

validation split
-> 只执行 transform 和 predict
-> 不能参与 fit
```

如果先用整个 `train.csv` 计算 Age 中位数或类别字典，再切 validation，validation information 已经进入 preprocessing。这个问题就叫 data leakage。

---

## 7. 第一版 baseline 怎样收住范围

第一版只使用一小组容易解释的字段：

```text
Pclass
Sex
Age
SibSp
Parch
Fare
Embarked
```

建立两条 preprocessing branch（预处理分支）：

```text
numeric columns: Age, SibSp, Parch, Fare
-> missing value imputation
-> scaling

categorical columns: Pclass, Sex, Embarked
-> missing value imputation
-> one-hot encoding
```

再把两条 branch 的 output 交给一个 logistic regression（逻辑回归）baseline。这里允许使用 `scikit-learn` 的 `ColumnTransformer` 和 `Pipeline`，因为本题重点是完整 workflow，不是第三次重写 logistic optimizer。

程序至少打印：

```text
training rows / validation rows
feature columns
validation accuracy
confusion matrix
```

confusion matrix（混淆矩阵）把预测拆成四种计数：真实死亡/生存分别被预测成什么。它能防止你只看到一个总 accuracy，却不知道错误集中在哪一类。

---

## 8. 只允许一次有理由的改进

baseline 跑通后，只选下面一种改进：

1. 增加一个简单、可解释的 `FamilySize = SibSp + Parch + 1`；
2. 在相同 split 和相同 metric 下，把 logistic regression 换成 random forest；
3. 改进缺失值处理，但不同时更换模型。

先写一句 hypothesis（假设）：为什么这项改动可能影响结果。改完后只比较同一 validation split 上的结果。

```text
baseline score
-> one controlled change
-> new score
-> keep or revert
```

如果分数降低，也算有效实验。你需要记录的是“改了什么、为什么、证据怎样”，不是强迫每次数字上涨。

---

## 9. 生成并提交 `submission.csv`

选定最终 pipeline 后，用全部 `train.csv` 重新 `fit`，再对 `test.csv` 预测。

生成文件前检查：

```text
columns exactly: PassengerId, Survived
row count exactly: 418
PassengerId comes from test.csv
Survived only contains 0 or 1
no missing values
```

提交：

```bash
kaggle competitions submit titanic \
  -f ML/kaggle/titanic/artifacts/submission.csv \
  -m "logistic baseline with fixed local validation"
```

Kaggle score 是一次外部 hidden-test signal（隐藏测试信号），不是让你开始反复调 leaderboard。若本地 validation 与 public score 有差异，只记录差异和可能原因；本练习最多提交两次。

---

## 10. Titanic 的完成证据与停止条件

保存：

```text
src/train_and_submit.py
artifacts/metrics.json
artifacts/confusion_matrix.png
artifacts/submission.csv
README.md
```

`README.md` 只回答：

```text
使用了哪些 columns
怎样划分 validation
baseline metric 是多少
唯一一次改进是什么、结果怎样
Kaggle submission 是否有效、score 是多少
这组证据不能证明什么
```

以下条件满足就停止：

- 本地 pipeline 从空目录可以重跑；
- validation 没有明显 leakage；
- submission schema 正确且 Kaggle 接受；
- 做过一次受控改进；
- 总投入不超过 6 小时。

**不以榜单名次、0.80 或任意高分阈值作为通过条件。**

---

# 实践二：Digit Recognizer（选做）

## 11. 为什么它比继续做 Titanic 特征工程更贴近 AI Infra

Digit Recognizer 使用 MNIST 手写数字。每张 $28 \times 28$ 灰度图片在 CSV 里被摊平成 784 个 pixel columns（像素列）。

这会把 T10~T12 的对象接起来：

```text
CSV rows
-> tensor shape [N, 784]
-> normalize pixel values
-> DataLoader produces batches [B, 784]
-> MLP produces logits [B, 10]
-> argmax produces labels [B]
-> concatenate all batches into submission
```

这里最有价值的不是识别数字本身，而是**同一模型在不同 batch size 下，input/output shape、input tensor bytes、latency 和 throughput 怎样变化。**

---

## 12. 最终产出

数据文件通常是：

```text
train.csv             # label + pixel0 ... pixel783
test.csv              # pixel0 ... pixel783
sample_submission.csv # ImageId + Label
```

建立：

```text
src/train.py
src/infer.py
artifacts/checkpoint.pt
artifacts/metrics.json
artifacts/batch_benchmark.csv
artifacts/submission.csv
```

模型只用 T12 已经掌握的小型 MLP。**不为了 Kaggle score 临时学习 CNN、augmentation、ensemble 或 pretrained model。**

---

## 13. 这次按三段完成

### 13.1 先证明数据形状

加载后检查：

```text
X_train.shape == [N, 784]
y_train.shape == [N]
pixel range is 0..255 before normalization
one sample can reshape to [28, 28]
```

保存一张带真实 label 的样本图。它证明 CSV column order 能恢复成正确图像，而不是只证明代码没有异常。

### 13.2 再训练一个可解释 baseline

固定 training/validation split、seed、model architecture 和 epoch budget。至少记录：

```text
train loss by epoch
validation accuracy
best checkpoint rule
final confusion matrix
```

不要以 training accuracy 作为最终结果。Kaggle test 也不能替代本地 validation，因为 leaderboard 不适合承担每次开发迭代。

### 13.3 最后做一次 batch inference observation

在 CPU 上选择三组 batch size，例如：

```text
1
32
256
```

对同一批固定 samples 做 warmup 后计时，记录：

```text
batch size
total samples
input tensor bytes
elapsed time
samples / second
maximum absolute logit difference
label mismatch count
```

以 `batch_size = 1` 的 output 为 reference，用合理 tolerance 比较 logits，并单独记录最终 label 是否改变。不要假设不同 batch partition 必须 bitwise identical（逐位完全相同）。

不要用一次 wall-clock measurement 宣称普遍性能结论。这个小实验只建立第一层直觉：增大 batch 往往能减少逐样本调用开销并提高 throughput，但 latency、memory 和收益上限会随硬件与 workload 改变。

---

## 14. Digit Recognizer 的停止条件

- 本地 validation pipeline 正确；
- checkpoint 能在新进程加载并完成 inference；
- 三组 batch size 的预测一致；
- 生成合法 submission，并且最多提交一次；
- 写下 batch observation 与证据边界；
- 总投入不超过 6 小时。

若系统主线正在处理 HTTP Server 或 Mini Redis correctness blocker，本项直接延期。它是选做，不构成 T12/T13 或主线 Week 的通过前置。

---

## 15. 这两场比赛怎样服务后续 AI Infra

| Kaggle 动作 | 后续 AI Infra 对象 |
|---|---|
| 检查 CSV schema 和 feature order | inference request schema、tensor layout |
| train/validation/test 分离 | benchmark dataset 与 regression evidence |
| preprocessing fit/transform 边界 | training-serving skew、artifact versioning |
| checkpoint 保存和新进程加载 | model loading、warmup、deployment lifecycle |
| batch inference | dynamic batching、throughput/latency trade-off |
| submission file contract | service output contract、offline evaluator |
| 固定 seed 与记录配置 | reproducibility 与 experiment tracking |

真正需要带走的是这些边界，而不是“我在 Kaggle 排了多少名”。简历主项目仍然应该是能运行、能测试、能 benchmark 的系统项目；Kaggle 在这里最多作为机器学习 workflow 的辅助证据。

---

## 16. 最后的执行顺序

```text
当前 T4~T11
-> 不做 Kaggle，继续理论线和系统主线

T12 + Ex3/Ex4 通过
-> 若主线平稳，可选做 Digit Recognizer，最多 6 小时

T13 + Ex5 通过
-> 必做 Titanic，最多 6 小时

完成一次有效 submission
-> 停止刷榜，回到 Mini Redis / AI Infra 主线
```

Kaggle 的正确位置，是帮你把模型知识送过一次真实交付边界，然后让路给更重要的系统工程。

---

## 17. 资料来源

- [Kaggle Getting Started competitions](https://www.kaggle.com/competitions?segment=gettingStarted)：核对当前入门赛分类；
- [Titanic Overview / Evaluation](https://www.kaggle.com/competitions/titanic/overview/evaluation)：核对数据规模、accuracy 和 submission schema；
- [Digit Recognizer](https://www.kaggle.com/competitions/digit-recognizer/overview)：核对长期滚动赛与分类任务；
- [Kaggle Competitions CLI](https://github.com/Kaggle/kaggle-cli/blob/main/docs/competitions.md)：核对下载与提交命令；
- [Kaggle Intro to Machine Learning](https://www.kaggle.com/learn/intro-to-machine-learning/how-models-work)：只在第一次不熟悉 model validation workflow 时定向查阅；
- [Kaggle Intermediate Machine Learning](https://www.kaggle.com/learn/intermediate-machine-learning)：只在 Titanic 的 missing values、categorical variables、pipeline 或 leakage 处卡住时查对应章节，不完整刷课。
