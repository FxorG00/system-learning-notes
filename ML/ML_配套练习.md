# 吴恩达经典机器学习：8 套编程作业中文实践教程

> 版本：2026-09-23
>
> 配套正文：[ML.md](ML.md)
>
> 本地原作业材料：[official_assignments/README.md](official_assignments/README.md)

这份文件不是“学过哪些知识”的清单。它要解决的是一个更具体的问题：**读完 `ML.md` 的一段理论后，怎样拿到真实数据，做成一个能运行、能画图、能自检的机器学习程序。**

整套实践以吴恩达经典课程原来的 `ex1~ex8` 为骨架。题目、数据和检查值来自经典课程；本地的 Python notebook 是社区维护的 starter version（起步版本）。我们保留原作业的故事和数据，但统一使用当前 Python 3.12、NumPy、SciPy 和 Matplotlib 完成，不安装它记录的旧 Python 3.6 环境，也不依赖已经下线的 Coursera grader（在线评分器）。

---

## 1. 你现在到底拿到了什么

本机目录：

```text
ML/official_assignments/
├── classic_ml_python/
│   ├── Exercise1/
│   │   ├── exercise1.ipynb
│   │   ├── utils.py
│   │   ├── Data/
│   │   └── Figures/
│   ├── Exercise2/
│   ├── ...
│   └── Exercise8/
├── original_handouts/
│   ├── ex1.pdf
│   ├── ...
│   └── ex8.pdf
└── README.md
```

每个 `ExerciseN` 已经包含：

- `exerciseN.ipynb`：英文题面、starter code（起步代码）和官方检查值；
- `Data/`：完成本题需要的数据，不需要你再去 Kaggle 找；
- `Figures/`：原作业希望你观察到的图；
- `utils.py`：画图、训练或展示数据时使用的辅助函数。

你自己的实现不要直接改进第三方快照。统一放到：

```text
ML/exercises/
├── ex1_linear_regression/
├── ex2_logistic_regression/
├── ex3_digits_forward/
├── ex4_backpropagation/
├── ex5_bias_variance/
├── ex6_svm_spam/
├── ex7_kmeans_pca/
└── ex8_anomaly_recommender/
```

每次开始一套作业时，先打开对应 notebook 看原题图和数据说明，再回到本教程顺着做。**不要先读别人完整 solution（答案实现）**；中文博客只用于卡住后确认题意，不作为抄代码来源。

---

## 2. 开始一套作业时的固定动作

你不需要自己猜“第一步是什么”。每一套都按这条路径开始：

```text
找到本地 Data
-> 先加载并打印 shape / 前几行
-> 画原始数据或样本
-> 实现本题核心函数
-> 用原作业检查值验证局部函数
-> 跑完整训练或推理流程
-> 保存最终图和一句结论
```

当前环境至少需要：

```text
numpy
scipy
matplotlib
scikit-learn（只在 Ex6 使用成熟 SVM 时需要）
```

检查环境：

```bash
python3 --version
python3 -c "import numpy, scipy, matplotlib; print('ML LAB ENV OK')"
```

`.mat` 是 MATLAB matrix file（MATLAB 矩阵文件）。读取方式不是 `np.loadtxt`，而是：

```python
from scipy.io import loadmat

data = loadmat("ex3data1.mat")
X = data["X"]
y = data["y"].reshape(-1)
```

后面每套作业都会再次写清**用哪个文件、里面有什么变量**，你不需要自己拆二进制文件。

### 为什么这里采用经典 `ex1~ex8`

当前 [Machine Learning Specialization](https://www.deeplearning.ai/courses/machine-learning-specialization/) 仍把 linear regression、logistic regression、neural networks、ML diagnosis、clustering、anomaly detection 和 collaborative filtering 作为 practice labs（实践实验）的主干，但完整 notebook 与 grader 依赖 Coursera 课程环境。

经典课程的 `ex1~ex8` 有稳定的原始题面、数据和 numerical checkpoints（数值检查点），更适合在本地独立完成。我们的处理是：**用经典原题作为可运行实验，用当前课程目录核对知识主线，用 Python 3.12 重写自己的实现。** 本地 `classic_ml_python` 是第三方 Python starter，不冒充 Coursera 官方仓库；真正作为技术基准的是它保留的原题任务、数据和检查值。

---

# Ex1：让线性回归真正预测餐车利润和房价

## 3. 这次要做成什么

你经营一批餐车，准备决定下一座城市值不值得进入。你手里只有各城市的人口和已有餐车利润。Ex1 要你完成一个 `linear_regression.py`：它读入真实课程数据，画出散点图，用 gradient descent（梯度下降）学出一条直线，再预测新城市的利润。

第二部分换成房价：输入房屋面积和卧室数，预测价格，并亲眼观察 feature scaling（特征缩放）为什么会影响梯度下降速度。

最终目录建议：

```text
ML/exercises/ex1_linear_regression/
├── linear_regression.py
└── outputs/
    ├── food_truck_fit.png
    ├── cost_curve.png
    └── learning_rates.png
```

## 4. 数据已经在哪里

```text
ML/official_assignments/classic_ml_python/Exercise1/Data/ex1data1.txt
ML/official_assignments/classic_ml_python/Exercise1/Data/ex1data2.txt
```

`ex1data1.txt` 每行两列：

```text
城市人口（单位：一万人）, 餐车利润（单位：一万美元）
```

利润为负数表示亏损。`ex1data2.txt` 每行三列：

```text
房屋面积（平方英尺）, 卧室数, 房价（美元）
```

先运行这个最小加载动作，确认你确实拿到了数据：

```python
from pathlib import Path
import numpy as np

ml_dir = Path(__file__).resolve().parents[2]
data_dir = ml_dir / "official_assignments" / "classic_ml_python" / "Exercise1" / "Data"

food_truck = np.loadtxt(data_dir / "ex1data1.txt", delimiter=",")
print(food_truck.shape)
print(food_truck[:5])
```

## 5. 第一段：先看数据，再写模型

把第一列画在横轴、第二列画在纵轴。现在你不是为了练 Matplotlib API，而是为了回答：人口增加时，利润整体上有没有上升趋势？有没有明显离群点？

接着实现：

```python
def compute_cost(X, y, theta):
    ...

def gradient_descent(X, y, theta, alpha, iterations):
    ...
```

这里的 `X` 已经包含一列全 1，用于 bias（偏置项）$\theta_0$。你的程序需要完成这条数据流：

```text
X @ theta
-> 得到每个城市的预测利润
-> prediction - y 得到误差
-> 所有误差共同形成 cost 与 gradient
-> 同步更新 theta
```

不要先训练一千多轮再判断对错。原作业给了两个局部检查点：

```text
theta = [0, 0]      -> cost 约为 32.07
theta = [-1, 2]     -> cost 约为 54.24
```

这两个值不对，就停在 `compute_cost`，不要继续调梯度下降。

## 6. 第二段：让直线真的移动

使用原作业参数：

```text
theta 初始值：[0, 0]
alpha：0.01
iterations：1500
```

训练完成后，$\theta$ 应大约接近：

```text
[-3.6303, 1.1664]
```

然后在同一张图上画出原始散点与训练后的直线。此时你做成的不是“一个梯度函数”，而是一个完整的小程序：**读取城市历史数据，学出人口到利润的关系，并对新人口规模作预测。**

## 7. 第三段：为什么房价数据要先缩放

加载 `ex1data2.txt`。房屋面积通常是几千，卧室数通常只有几。两个 feature（特征）的数量级差太大时，cost surface（成本函数曲面）会狭长，固定 learning rate（学习率）的梯度下降容易来回摆动。

实现：

```python
def feature_normalize(X):
    """返回 X_norm、每列均值 mu 和标准差 sigma。"""
    ...
```

随后比较几个 learning rate 的 loss curve（损失曲线），并预测一套 `1650 sq-ft, 3 bedrooms` 的房子。最后再用 normal equation（正规方程）或 `np.linalg.lstsq` 计算参照结果；两条路线的参数表示可能不同，但 prediction 应接近。

## 8. Ex1 完成证据

你完成 Ex1 后，应当能直接展示：

1. 原始餐车数据散点图；
2. `32.07` 与 `54.24` 两个 cost 检查值；
3. 学到的 $\theta$ 与拟合直线；
4. 房价特征缩放前后的 loss curve；
5. 梯度下降与最小二乘对同一房子的预测。

这套作业对应 `ML.md` 的线性回归、成本函数、梯度下降、多特征和特征缩放，也对应理论线 T7~T8。当前 T1~T3 已通过时，不需要立刻为了进度表硬做；进入相关 T 模块后再完整完成。

---

# Ex2：从考试成绩判断录取，再处理弯曲边界

## 9. 这次要做成什么

第一部分，你有一批申请者的两门考试成绩和最终录取结果，要做一个 `logistic_regression.py`，输出每个人被录取的概率，并画出 decision boundary（决策边界）。

第二部分，数据换成芯片的两项检测结果。合格与不合格样本无法用一条直线分开，因此你要加入 polynomial features（多项式特征）和 regularization（正则化），观察边界怎样随 $\lambda$ 改变。

## 10. 数据已经在哪里

```text
Exercise2/Data/ex2data1.txt  # 两门考试成绩 + 是否录取
Exercise2/Data/ex2data2.txt  # 两项芯片测试 + 是否合格
```

每行都是：

```text
feature_1, feature_2, label
```

`label=1` 表示录取或合格，`label=0` 表示未录取或不合格。先把两类点用不同 marker（点型）画出来。你应该先看见：第一份数据大致能被直线分开，第二份数据的边界明显是弯的。

## 11. 第一段：从 score 到 probability

实现四个函数：

```python
def sigmoid(z):
    ...

def cost_and_gradient(theta, X, y, lambda_=0.0):
    ...

def predict_probability(theta, X):
    ...

def predict(theta, X, threshold=0.5):
    ...
```

主线是：

```text
考试成绩 X
-> linear score z = X @ theta
-> sigmoid(z) 得到 0~1 概率
-> threshold 把概率变成类别
```

先用 `theta=0` 检查：

```text
cost 约为 0.693
gradient 约为 [-0.1000, -12.0092, -11.2628]
```

再把 cost 和 gradient 交给 `scipy.optimize.minimize` 求参数。训练结果应大约为：

```text
cost：0.203
theta：[-25.161, 0.206, 0.201]
training accuracy：约 89%
```

这些值负责告诉你“公式和 shape 基本写对了”，不是要求最后几位 bitwise equal（逐位相等）。

## 12. 第二段：一条直线不够时怎么办

芯片数据的原始二维点无法被一条直线合理分开。原作业把 $x_1,x_2$ 扩展成最高六次的多项式组合，让 logistic regression 获得弯曲边界。

你不需要把 feature mapping 写成字符串拼接。可以直接复用 starter `utils.py` 中的 `mapFeature`，把精力放在 regularized cost 与 gradient：

```python
def regularized_cost_and_gradient(theta, X, y, lambda_):
    ...
```

比较：

```text
lambda = 0      -> 边界很复杂，容易追着训练点走
lambda = 1      -> 原作业的合理基线，accuracy 约 83.1%
lambda = 100    -> 参数被压得过强，容易 underfit
```

最终保存三张 decision boundary 图。你要解释的不是“哪个 accuracy 最大”，而是 $\lambda$ 怎样改变模型复杂度。

## 13. Ex2 完成证据

最终交付：

```text
admission_data.png
admission_boundary.png
microchip_lambda_0.png
microchip_lambda_1.png
microchip_lambda_100.png
```

加上一段终端输出：局部 cost/gradient 检查、训练 accuracy、一个新申请者的 probability。对应 `ML.md` 的逻辑回归与正则化，建议在理论线 T8、T13 附近完成。

---

# Ex3：用 5000 张手写数字理解多分类和前向传播

## 14. 这次要做成什么

这一次输入不再是两个 feature，而是 20×20 的灰度手写数字。每张图被摊平成 400 个数。你先训练 10 个 one-vs-all classifiers（一对其余分类器），再加载课程给定的 neural network weights（神经网络权重）完成一次 forward propagation（前向传播）。

最终程序应能读取 5000 张数字图，显示其中 100 张，并输出两种分类方式的 training accuracy。

## 15. 数据和对象

```text
Exercise3/Data/ex3data1.mat
Exercise3/Data/ex3weights.mat
```

`ex3data1.mat`：

```text
X：[5000, 400]，每行是一张 20×20 图像
y：[5000, 1]，标签
```

旧 MATLAB 数据把数字 `0` 记为标签 `10`。Python 读取后先把 `10` 映射回 `0`，否则你的类别索引会错一位。

`ex3weights.mat` 保存已经训练好的两层权重：`Theta1` 的 shape 为 `[25, 401]`，`Theta2` 为 `[10, 26]`。它不是让你训练网络，而是让你检查：给定 weights 后，你能否把一批输入正确地沿网络传到 output activations（输出层激活值）。

## 16. 第一段：10 个二分类器怎样组成多分类器

实现：

```python
def logistic_cost_gradient(theta, X, y, lambda_):
    ...

def one_vs_all(X, y, num_labels, lambda_):
    ...

def predict_one_vs_all(all_theta, X):
    ...
```

`all_theta` 每一行负责一个数字：

```text
第 0 行：当前图片是不是 0
第 1 行：当前图片是不是 1
...
第 9 行：当前图片是不是 9
```

预测时一次计算 10 个 score，取最大者对应的类别。完成后 training accuracy 应约为 `95.1%`。

## 17. 第二段：让给定神经网络跑一次 forward

加载 `Theta1` 与 `Theta2` 后实现：

```python
def predict_neural_network(theta1, theta2, X):
    ...
```

每一步都先写 shape：

```text
X
-> 添加 bias column
-> hidden linear transform
-> sigmoid activation
-> 再添加 bias column
-> output linear transform
-> 每行取最大类别
```

使用给定权重时，training accuracy 应约为 `97.5%`。这个结果不是证明网络泛化得多好；它只证明你的 forward 数据流和标签映射大致正确。

## 18. Ex3 完成证据

保存一张 10×10 digits grid（数字网格图），打印两个 accuracy，并随机抽 10 张显示 `label -> prediction`。这套作业对应 `ML.md` 的多分类、神经元和前向传播，也为 T10 的 `nn.Module` 建立 NumPy reference（参考实现）。

---

# Ex4：不只会 forward，让梯度通过独立检查

## 19. 这次要做成什么

Ex3 使用了现成权重。Ex4 要解决的是：**权重怎样从数据中学出来？**

你会在同一批手写数字上实现 two-layer neural network（两层神经网络）的 cost、backpropagation（反向传播）和 regularization，然后用 finite difference（有限差分）独立检查 gradient。最后再调用优化器训练网络。

## 20. 数据和网络结构

```text
Exercise4/Data/ex4data1.mat
Exercise4/Data/ex4weights.mat
```

网络大小固定为：

```text
input：400
hidden：25
output classes：10
```

你的主要函数：

```python
def nn_cost_and_gradient(
    nn_params,
    input_size,
    hidden_size,
    num_labels,
    X,
    y,
    lambda_=0.0,
):
    ...
```

`nn_params` 是把两张 weight matrices（权重矩阵）摊平后拼成的一维数组。函数内部先按已知 shape 拆回 `Theta1` 和 `Theta2`，完成 forward，计算 cost，再 backward 得到同样 shape 的 gradient，最后重新摊平返回。

## 21. 先检查 forward cost，再写 backward

使用课程给定 weights：

```text
lambda = 0 -> cost 约为 0.287629
lambda = 1 -> cost 约为 0.383770
```

这两个值不对，说明 forward、one-hot labels（独热标签）或 regularization cost 仍有问题。不要在错误 forward 上继续调 backward。

随后实现：

```python
def sigmoid_gradient(z):
    ...

def random_initialize_weights(in_size, out_size):
    ...
```

随机初始化的目的，是让不同 hidden units（隐藏单元）从不同状态开始学习；如果所有 weights 都是 0，它们会收到相同梯度并一直保持对称。

## 22. 用 finite difference 当法官

你的 analytic gradient（解析梯度）来自 backpropagation。numerical gradient（数值梯度）只允许调用 forward cost：

$$
\frac{\partial J}{\partial \theta_i}
\approx
\frac{J(\theta_i+\varepsilon)-J(\theta_i-\varepsilon)}{2\varepsilon}
$$

两者不能共享 backprop 代码，否则可能把同一个 bug 同时写进“答案”和“检查器”。原作业的小网络 gradient check 相对误差应小于 `1e-9`。

通过后再加 regularized gradients，并训练完整网络。training accuracy 通常约为 `95.3%`，会因随机初始化略有波动。

## 23. Ex4 完成证据

```text
未正则化与正则化 cost 检查值
gradient-check relative error
训练后的 accuracy
若干输入的 label/prediction
```

Ex4 与当前下一模块 T4 直接相连：T4 先在最小计算图上建立 chain rule 与 finite difference；Ex4 再把同一证据方法扩展到神经网络。不要在 T4 尚未理解时直接硬啃整套 Ex4。

---

# Ex5：模型效果不好时，先诊断是 bias 还是 variance

## 24. 这次要做成什么

你要预测水库水位变化时，大坝流出的水量。直线模型会 underfit（欠拟合），高阶 polynomial regression（多项式回归）又可能 overfit（过拟合）。Ex5 的重点不是再写一次 gradient descent，而是学习怎样用 train/validation/test 和 learning curve（学习曲线）决定下一步。

## 25. 数据已经替你分好

```text
Exercise5/Data/ex5data1.mat
```

文件中已有：

```text
X, y          # training set
Xval, yval    # cross-validation set
Xtest, ytest  # test set
```

先画 `X,y`，你会看到这批点并不适合一条简单直线。不要重新随机切分，否则无法和原作业图与检查值对照。

## 26. 第一段：建立最简单 baseline

实现 regularized linear regression 的 cost 和 gradient，然后用 starter `utils.trainLinearReg` 或 `scipy.optimize.minimize` 求参数。接着实现：

```python
def learning_curve(X, y, Xval, yval, lambda_):
    ...
```

它不是只训练一次。训练样本数从少到多时，每次重新训练模型，再记录：

```text
当前子训练集上的 error
完整 validation set 上的 error
```

画出两条曲线。如果二者最后都较高且接近，说明模型表达能力不足，主要是 high bias（高偏差）。

## 27. 第二段：增加容量后再用 lambda 控制

把一个水位 feature 扩展为：

$$
x, x^2, x^3, \ldots, x^p
$$

实现：

```python
def polynomial_features(X, degree):
    ...

def validation_curve(X, y, Xval, yval, lambdas):
    ...
```

依次观察：

```text
lambda = 0   -> training error 很低，但曲线可能在边缘剧烈弯折
lambda = 1   -> 原作业中通常形成较合理折中
lambda = 100 -> 约束过强，再次 underfit
```

用 validation set 选择 $\lambda$，最后只用 test set 做一次最终评价。不要根据 test 结果反复调参数，否则 test 就被你训练过程“看见”了。

## 28. Ex5 完成证据

至少保存：linear fit、linear learning curve、polynomial fit、polynomial learning curve、validation curve。最后写一句可执行决策：下一步应该增加数据、增加模型容量，还是调整 regularization。它对应理论线 T13 的 generalization（泛化）与诊断。

---

# Ex6：用 SVM 画非线性边界，再做垃圾邮件分类

## 29. 这次要做成什么

Ex6 分成两个有联系的产出：

1. 在三个二维数据集上观察 $C$ 和 Gaussian kernel（高斯核）怎样改变 SVM boundary；
2. 把 email text（邮件文本）变成 1899 维 feature vector，再训练 spam classifier（垃圾邮件分类器）。

这一天的重点不是从头实现 SVM optimizer。课程本身也提供训练器；当前可以使用 starter `utils.svmTrain`，或者使用 `sklearn.svm.SVC`，但 Gaussian kernel、参数选择和邮件 feature extraction 仍由你完成。

## 30. 数据在哪里

```text
Exercise6/Data/ex6data1.mat
Exercise6/Data/ex6data2.mat
Exercise6/Data/ex6data3.mat
Exercise6/Data/emailSample1.txt
Exercise6/Data/emailSample2.txt
Exercise6/Data/spamSample1.txt
Exercise6/Data/spamSample2.txt
Exercise6/Data/spamTrain.mat
Exercise6/Data/spamTest.mat
Exercise6/Data/vocab.txt
```

`ex6data3.mat` 已经包含 `X,y,Xval,yval`，专门用于选择 $C$ 和 $\sigma$。`spamTrain.mat` 有 4000 封已处理邮件，`spamTest.mat` 有 1000 封；每封最终表示成 1899 维 binary features（二值特征）。

## 31. 第一段：先把 kernel 当成 similarity

实现：

```python
def gaussian_kernel(x1, x2, sigma):
    ...
```

它回答的是“两条样本在当前 $\sigma$ 尺度下有多相似”。$\sigma$ 小，相似度只在很近的邻域内保持较高；$\sigma$ 大，影响范围更宽。

在 `ex6data1` 比较 $C=1$ 与 $C=100$，观察一个离群点是否强行扭动边界。在 `ex6data2` 使用 Gaussian kernel 得到弯曲边界。然后对 `ex6data3` 穷举：

```text
0.01, 0.03, 0.1, 0.3, 1, 3, 10, 30
```

的全部 $(C,\sigma)$ 组合，使用 validation error 选最优参数，而不是选择 training accuracy 最高者。

## 32. 第二段：文本怎样变成固定 shape

邮件不能直接交给 SVM。原作业先做 normalization（归一化文本表示）：

```text
lowercase
移除 HTML
URL -> httpaddr
email address -> emailaddr
number -> number
dollar sign -> dollar
tokenize / stemming
映射到 vocab index
```

完成：

```python
def process_email(text, vocabulary):
    ...

def email_features(word_indices, vocabulary_size=1899):
    ...
```

`email_features` 输出长度必须是 `1899`。原样例应产生 `45` 个 non-zero entries（非零位置）。训练好的 linear SVM 在原数据上大约达到：

```text
training accuracy：99.8%
test accuracy：98.5%
```

这只是旧课程数据上的检查值，不代表真实邮件系统也会保持该效果。

## 33. Ex6 完成证据

保存三个二维 boundary 图，打印选中的 $C,\sigma$，展示一封邮件经过 normalization 后的 tokens 与 non-zero feature count，最后报告 train/test accuracy。SVM 在当前 AI Infra 主线中是选做知识，不阻塞 Transformer 与系统项目。

---

# Ex7：K-means 压缩图片，PCA 压缩人脸表示

## 34. 这次要做成什么

这套作业不是只在二维点上跑两个公式。它有两个肉眼可见的产出：

- 用 K-means（K 均值聚类）把一张 128×128 彩色图片压缩到 16 种代表颜色；
- 用 PCA（主成分分析）把 1024 维人脸压到 100 维，再恢复出近似人脸，观察丢失了什么。

## 35. 数据在哪里

```text
Exercise7/Data/ex7data1.mat    # 2D PCA 示例
Exercise7/Data/ex7data2.mat    # 2D K-means 示例
Exercise7/Data/bird_small.png  # 128×128 RGB 图片
Exercise7/Data/bird_small.mat
Exercise7/Data/ex7faces.mat    # 32×32 灰度人脸，摊平成 1024 维
```

## 36. 第一段：先让点找到最近中心

实现：

```python
def find_closest_centroids(X, centroids):
    ...

def compute_centroids(X, assignments, k):
    ...

def initialize_centroids(X, k, rng):
    ...
```

算法循环是：

```text
每个样本找最近 centroid
-> 每组样本重新求 mean
-> 新 centroids 再次参与分配
```

原作业对前三个样本的 assignment 检查值是 `[0, 2, 1]`。你的程序还要明确 empty cluster（空簇）策略，例如保留旧 centroid 或重新选择样本，不能让 `mean(empty)` 静默地产生 NaN。

## 37. 第二段：把一张图片压到 16 种颜色

读取 `bird_small.png` 后：

```text
[128, 128, 3]
-> reshape 为 [16384, 3]
-> 每个 pixel 是一个 RGB sample
-> K-means 找到 16 个 centroids
-> 每个 pixel 替换为所属 centroid 的 RGB
-> reshape 回图片
```

保存 original/compressed side-by-side 图。此时 centroid 不再只是抽象点，它就是一组代表颜色。

## 38. 第三段：PCA 为什么能够减少维度

先对 `ex7data1.mat` 的二维数据中心化，再实现：

```python
def pca(X_centered):
    ...

def project_data(X, U, k):
    ...

def recover_data(Z, U, k):
    ...
```

主路径：

```text
X
-> covariance matrix
-> SVD 得到 principal directions
-> 只保留前 k 个方向
-> project 得到 Z
-> recover 得到 X_approx
```

第一个 principal component 约为 `[-0.707, -0.707]`，整体乘以 `-1` 也同样正确；eigenvector 的正负方向不改变它表示的轴。第一个样本投影值约为 `±1.481`，恢复值约为 `[-1.047, -1.047]`。

最后在 `ex7faces.mat` 上保留前 100 个 components，把 1024 维人脸压成 100 维并恢复。把原图与恢复图并排展示：轮廓还在，细节变模糊。

## 39. Ex7 完成证据

```text
K-means 每轮 objective
二维 cluster 过程图
鸟图原图/16 色压缩图
PCA principal directions
二维投影与恢复图
人脸原图/100 维恢复图
```

K-means 与 PCA 都属于传统 ML 选做，不阻塞当前主线；PCA 的 shape、memory reduction 和 approximation 思维对 AI Infra 仍有价值。

---

# Ex8：先找异常服务器，再给自己推荐电影

## 40. 这次要做成什么

Ex8 仍然有两个独立产出：

1. 根据服务器 latency（延迟）与 throughput（吞吐）找出低概率异常点；
2. 根据用户已经打过的电影评分，补全未知评分并输出 top recommendations（最高推荐项）。

## 41. 数据在哪里

```text
Exercise8/Data/ex8data1.mat
Exercise8/Data/ex8data2.mat
Exercise8/Data/ex8_movies.mat
Exercise8/Data/ex8_movieParams.mat
Exercise8/Data/movie_ids.txt
```

`ex8data1.mat` 的 training set 有 307 个服务器样本，主要用于估计正常分布；`Xval,yval` 用带标签的 validation evidence 选择异常阈值。`ex8data2.mat` 是 11 维版本。

电影数据来自 MovieLens 100k：`Y[i,j]` 是用户 $j$ 对电影 $i$ 的 1~5 分评分，`R[i,j]=1` 才表示这个评分真实存在。**`R=0` 的位置是 missing，不是用户打了 0 分。**

## 42. 第一段：异常不是“数值大”，而是“在正常模型下概率低”

实现：

```python
def estimate_gaussian(X):
    ...

def select_threshold(yval, pval):
    ...
```

先由大多数正常样本估计每个 feature 的 mean 与 variance，再计算每个样本的 $p(x)$。然后只在 validation set 上扫描阈值 $\varepsilon$，以 F1 score（F1 分数）选择最佳值。

第一份数据的检查值：

```text
epsilon 约为 8.99e-05
F1 约为 0.875
```

11 维数据：

```text
epsilon 约为 1.38e-18
F1 约为 0.615385
检测到 117 个异常点
```

二维数据要画出 probability contours（概率等高线）和被红圈标出的 anomalies（异常点）。

## 43. 第二段：只在真实评分位置计算误差

实现：

```python
def collaborative_filtering_cost_gradient(
    params,
    Y,
    R,
    num_users,
    num_movies,
    num_features,
    lambda_,
):
    ...
```

模型使用 movie vectors `X` 和 user vectors `Theta`：

$$
\widehat{Y}=X\Theta^T
$$

但 cost 只能计算 `R==1` 的位置。原作业给定小矩阵与参数时：

```text
未正则化 cost 约为 22.22
lambda = 1.5 时 cost 约为 31.34
```

先用 finite difference 抽查 gradient，再调用优化器。随后在 `movie_ids.txt` 中给自己真实看过的几部电影打分，把你作为一个新用户加入矩阵，训练后输出 predicted top-10 movies。

## 44. Ex8 完成证据

```text
二维服务器分布与异常点图
两个数据集的 epsilon/F1
collaborative-filtering cost 检查值
gradient-check 结果
你输入的电影评分
最终 top-10 推荐及预测分数
```

推荐系统中的 user/item vectors 是 embedding table（嵌入表）的早期直觉，但本练习不扩展成向量数据库或在线推荐服务。

---

# 45. 这 8 套作业怎样进入我们的实际时间线

它们不是要求你现在连续做八周。系统主线仍然是 HTTP Server -> Mini Redis，AI Theory 仍按 T 模块推进。

| 到达理论线位置 | 对应作业 | 处理方式 |
|---|---|---|
| T4 | Ex4 的最小 gradient check | 先完成 T4 小计算图，不直接训练完整数字网络 |
| T7~T8 | Ex1 | 完整完成，建立 regression 闭环 |
| T8、T13 | Ex2 | 完成 logistic + regularization |
| T10 | Ex3 forward 部分 | 作为 NumPy reference，对照 `nn.Module` |
| T11~T12 | Ex4 | 完整完成 backprop + gradient check |
| T13 | Ex5 | 完成 bias/variance 与 learning curve |
| T14 或以后 | Ex6 | 选做，不阻塞主线 |
| 以后需要传统 ML 全景时 | Ex7、Ex8 | 定向选做 |

Ex3 的 one-vs-all、Ex6、Ex7、Ex8 不需要为了“课程完整率”抢在系统项目之前。真正的完成标准不是八个目录都出现绿色勾，而是到相应理论模块时，你能把公式、数据、代码和 evidence 接成一条完整链。

经典作业解决“算法与机制怎样亲手实现”，但不会完整覆盖隐藏 test、submission schema 和线上评分流程。到 T12/T13 后，使用 [Kaggle入门实践.md](Kaggle入门实践.md) 再走一次端到端 workflow：

| 到达位置 | Kaggle 实践 | 要求 |
|---|---|---|
| T12 + Ex3/Ex4 通过后 | Digit Recognizer | 选做；只做 MLP、batch inference 和一次 submission，最多 6 小时 |
| T13 + Ex5 通过后 | Titanic | 必做；验证集、无 leakage 的 preprocessing、一次受控改进和一次有效 submission，最多 6 小时 |

Kaggle 不新增刷榜线。完成规定 evidence 后立即回到 HTTP Server、Mini Redis 和后续 AI Infra 主线。

---

# 46. 卡住时应该先看哪里

顺序固定：

1. 当前这套作业的本地 `exerciseN.ipynb`，确认原题到底要什么；
2. `original_handouts/exN.pdf`，核对经典题面；
3. [ML.md](ML.md) 对应理论章节；
4. 再看中文笔记帮助理解题意；
5. 仍然卡住时，把你的当前代码、shape 和错误输出交给我，不要先复制完整 solution。

本教程编排时参考了：

- [dibgerge 的 Python starter assignments](https://github.com/dibgerge/ml-coursera-python-assignments)：提供 notebook、数据、图片与空实现位置；
- [经典 ex1~ex8 公开镜像](https://github.com/fengdu78/Coursera-ML-AndrewNg-Notes/tree/master/code)：核对原题面和完整作业序列；
- [中文作业翻译索引](https://github.com/PowersYang/Coursera_ML_Exercise)：核对中文学习者通常需要哪些题意解释；
- [博客园 Ex4 回顾](https://www.cnblogs.com/EtoDemerzel/p/7793608.html)：核对 backprop 作业的学习断点；
- [CSDN Ex1 实践记录](https://blog.csdn.net/weixin_55037029/article/details/127620509)：核对数据列含义和从加载到画图的衔接。

这些中文资料只帮助改善讲解顺序。公式、数据含义和检查值仍以本地原作业题面与 starter notebook 为准。

---

# 47. 最后压缩

以后看到“完成 ExN”，你应该立刻知道四件事：

```text
我要做成哪个程序
数据文件已经放在哪里
程序要经过哪几段计算
最后用哪些数值、图和预测证明它真的工作
```

这才是一套可以开工的练习。只有“实现 logistic regression”“比较 lambda”这种一句话要求，不再算合格任务书。
