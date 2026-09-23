# Classic Machine Learning Assignments

这个目录保存吴恩达经典机器学习课程 `ex1~ex8` 的本地学习材料。

## 本机已有内容

```text
official_assignments/
├── classic_ml_python/       # Python starter notebooks、Data、Figures、utils.py
├── original_handouts/      # ex1.pdf ~ ex8.pdf
└── README.md
```

`classic_ml_python/` 对应第三方 Python starter 仓库在下载时的 commit：

```text
d901c1ca71766bda9d5994af4a27a44f82ae3ae5
```

来源：

- Python starter notebooks：[dibgerge/ml-coursera-python-assignments](https://github.com/dibgerge/ml-coursera-python-assignments)
- 原始题面镜像：[fengdu78/Coursera-ML-AndrewNg-Notes](https://github.com/fengdu78/Coursera-ML-AndrewNg-Notes/tree/master/code)

这些第三方文件只保存在本机，已由仓库根目录 `.gitignore` 排除，不会随本仓库提交或推送。我们自己的中文任务编排在 [../ML_配套练习.md](../ML_配套练习.md)。

## 重新下载

若本地材料丢失，执行：

```powershell
cd C:\Users\FxorG\Desktop\gpt_infra\ML\official_assignments
git clone --depth 1 https://github.com/dibgerge/ml-coursera-python-assignments.git classic_ml_python
```

原始 PDF 只用于核对旧课程题面。平时直接读中文教程并使用 `classic_ml_python/ExerciseN/Data/` 中的数据即可。

## 使用边界

starter notebook 中已经嵌入英文任务说明和空实现位置，也带有旧 Coursera grader 相关代码。当前学习不依赖旧 grader，不要求安装它记录的 Python 3.6 环境，也不要求照着 notebook 从头到尾填空。

统一使用当前 AI Theory 的 Python 3.12 环境。实现写进自己的 `ML/exercises/exN/`，starter notebook 只负责提供原始题意、数据、图片和检查值。
