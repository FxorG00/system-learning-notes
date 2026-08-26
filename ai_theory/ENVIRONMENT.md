# AI Theory 开发环境

> 环境基线日期：2026-08-27
> 作用：集中记录 AI Theory 的 Python 版本、package 版本和安装方式
> 原则：宿主机现状是 observation，不是新项目必须继承的技术基线

## 1. 当前环境策略

Ubuntu 20.04 自带的 Python 3.8.10 可以继续留给 operating system 和历史脚本，不卸载、不替换，也不向里面安装 AI Theory packages。

AI Theory 使用独立环境：

```text
managed CPython 3.12.x
    |
    +--> 每个学习项目自己的 .venv
            |
            +--> 当前 NumPy baseline：2.5.2
```

选择 Python 3.12 的原因：

```text
Python 3.8 已于 2024-10-07 EOL，不再获得安全更新
NumPy 2.5 支持 Python 3.12~3.14
Python 3.12 既处于支持期，也有成熟的 scientific Python package compatibility
```

这里 pin NumPy 2.5.2 是为了复现实验，不是为了迁就旧 system Python。以后升级 baseline 时，应修改本文件的日期和版本，并重新运行已有 assertions。

## 2. 宿主机快照

2026-08-23 曾观察到：

```text
OS：Ubuntu 20.04
system Python：3.8.10
system pip：未安装
system NumPy：未安装
```

这段只说明当时机器上有什么。它不决定 T1、T2 或后续项目应该使用什么版本。

## 3. 安装 Python 管理工具

本路线默认使用 `uv` 管理独立 Python，不向 Ubuntu 的 system Python 动手。

先检查：

```bash
uv --version
```

若尚未安装，使用 uv 官方 installer：

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"
uv --version
```

安装或确认 Python 3.12：

```bash
uv python install 3.12
```

`uv python install 3.12` 安装 uv 管理的 Python，不会把 `/usr/bin/python3` 替换成另一个版本。

## 4. 每个项目建立独立 venv

以 T1 为例：

```bash
cd ~/code/system-learning/ai-theory/t01_numpy_basics
uv venv --python 3.12 .venv
source .venv/bin/activate
uv pip install "numpy==2.5.2"
```

验证当前 shell 使用的确实是项目环境：

```bash
which python
python --version
python -c "import numpy as np; print(np.__version__)"
```

预期关系：

```text
which python -> 当前项目的 .venv/bin/python
python --version -> Python 3.12.x
NumPy -> 2.5.2
```

重新打开 terminal 后需要再次执行：

```bash
cd ~/code/system-learning/ai-theory/t01_numpy_basics
source .venv/bin/activate
```

`.venv/` 不提交到 Git。项目若需要长期复现，应提交 dependency declaration 或 lock file，而不是提交整个 virtual environment。

## 5. 环境与教程的边界

```text
ENVIRONMENT.md
-> 记录当前推荐 Python/package baseline、宿主机快照和 setup

Tn.md
-> 只说明本课需要什么环境、怎样验证环境门
-> 不把某次机器检查结果永久写成课程知识
```

环境升级后，优先修改本文件和 dependency declaration。除非 API 或行为真的变化，否则不因为 patch version 改动重写教学主线。

## 6. 官方依据

- [Python versions status](https://devguide.python.org/versions/)
- [uv：Installing and managing Python](https://docs.astral.sh/uv/guides/install-python/)
- [uv：Using environments](https://docs.astral.sh/uv/pip/environments/)
- [NumPy stable beginner guide](https://numpy.org/doc/stable/user/absolute_beginners.html)
- [NumPy 2.5.0 release notes](https://numpy.org/doc/stable/release/2.5.0-notes.html)
