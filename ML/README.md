# ML 学习工作区

这条机器学习线分成两个位置，各自只有一个职责：

```text
Windows：C:\Users\FxorG\Desktop\gpt_infra\ML
    教程、规划与资料索引的 canonical source

Ubuntu：~/code/system-learning/ai-theory/ML
    Python 实现、运行、测试与 evidence 的 canonical workspace
```

后续自己的代码统一写在 Ubuntu：

```text
~/code/system-learning/ai-theory/ML/exercises/
├── ex1_linear_regression/
├── ex2_logistic_regression/
├── ex3_digits_forward/
├── ex4_backpropagation/
├── ex5_bias_variance/
├── ex6_svm_spam/
├── ex7_kmeans_pca/
└── ex8_anomaly_recommender/
```

Ubuntu 当前还保存了教程快照与本地资料：

```text
ML.md
ML_配套练习.md
Kaggle入门实践.md
assets/
official_assignments/
```

其中 `official_assignments/` 只提供原始 notebook、Data、Figures、`utils.py` 与题面 PDF，不在里面写自己的最终实现。该目录在 Ubuntu 由 `.gitignore` 排除；自己的 `exercises/` 代码仍可正常进入 Git。

当前 Ubuntu 环境：

```text
Python 3.12.14
NumPy 2.5.2
SciPy 1.18.1
Matplotlib 3.11.2
pandas 3.0.6
scikit-learn 1.9.1
JupyterLab 4.6.4
```

进入工作区：

```bash
cd ~/code/system-learning/ai-theory/ML
python3 -m pip check
python3 exercises/ex1_linear_regression/linear_regression.py
```

更新纪律：

```text
教程改动：先修改 Windows gpt_infra/ML，再同步到 Ubuntu
代码改动：只修改 Ubuntu exercises，不反向覆盖
同步资料时：不得覆盖 exercises 中的用户实现
```
