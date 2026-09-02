# AI Theory 开发环境

> 环境基线日期：2026-09-02
> 作用：集中记录 AI Theory 的 Python 版本、package 版本和安装方式
> 原则：Ubuntu 的日常 Python 使用 3.12；发行版自带解释器仍留给系统脚本

## 1. 当前环境策略

Ubuntu 20.04 已直接安装 CPython 3.12.14：

```text
/usr/local/bin/python      -> Python 3.12.14
/usr/local/bin/python3     -> Python 3.12.14
/usr/local/bin/python3.12  -> Python 3.12.14

/usr/bin/python3           -> Python 3.8.10
```

正常打开 terminal 后，`/usr/local/bin` 位于 `/usr/bin` 前面，因此：

```bash
python --version
python3 --version
```

都会得到 Python 3.12.14。

这里没有改写 `/usr/bin/python3`。Ubuntu 20.04 的 `apt` 和部分系统脚本使用绝对路径调用它，强行替换可能破坏系统工具。换句话说：

```text
日常开发默认 Python：3.12.14
Ubuntu 系统内部 Python：3.8.10
```

这已经满足理论线直接使用 Python 3.12，同时保留系统边界。

AI Theory 不使用 `uv`。每个学习项目使用 Python 标准库自带的 `venv` 隔离 packages：

```text
Python 3.12.14
    |
    +--> python -m venv .venv
            |
            +--> 当前项目自己的 pip 和 packages
```

选择 Python 3.12 的原因：

```text
Python 3.8 已于 2024-10-07 EOL，不再获得安全更新
NumPy 2.5 支持 Python 3.12~3.14
Python 3.12 与当前 scientific Python package 兼容成熟
```

当前 NumPy reproducible baseline 是 2.5.2。精确 pin 是为了复现实验，不是为了迁就旧 Python。

## 2. 宿主机快照

2026-09-02 实际配置与验证结果：

```text
OS：Ubuntu 20.04.6 LTS
default python/python3：3.12.14
system /usr/bin/python3：3.8.10
pip：25.0.1 for Python 3.12
stdlib extension build：0 missing，0 failed on import
verified modules：ssl、sqlite3、bz2、lzma、ctypes、venv
```

Python 3.12.14 使用 Python 官方 source tarball 构建，并通过 `make altinstall` 安装到 `/usr/local`。`altinstall` 的目的正是并存安装，避免覆盖发行版的 `python3` 文件。

## 3. 验证默认解释器

```bash
command -v python
python --version
command -v python3
python3 --version
/usr/bin/python3 --version
python -m pip --version
```

预期关系：

```text
python/python3 -> /usr/local/bin -> Python 3.12.14
/usr/bin/python3 -> Python 3.8.10
python -m pip -> Python 3.12 的 pip
```

教程统一写 `python -m pip`，不单独写 `pip`。这样能明确表示“由当前这个 Python 解释器运行它对应的 pip”，避免 Python 和 pip 指向不同版本。

## 4. 每个项目建立独立 venv

不使用 `uv` 不等于把所有第三方 packages 装进全局 Python。`venv` 是 Python 自带功能，不是额外的 Python version manager。

以 T1 为例：

```bash
cd ~/code/system-learning/ai-theory/t01_numpy_basics
python -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install "numpy==2.5.2"
```

验证当前 shell 使用项目环境：

```bash
which python
python --version
python -c "import numpy as np; print(np.__version__)"
```

预期关系：

```text
which python -> 当前项目的 .venv/bin/python
python --version -> Python 3.12.14
NumPy -> 2.5.2
```

重新打开 terminal 后需要再次激活：

```bash
cd ~/code/system-learning/ai-theory/t01_numpy_basics
source .venv/bin/activate
```

`.venv/` 不提交到 Git。需要长期复现时提交 dependency declaration 或 lock file，而不是提交整个 virtual environment。

## 5. 安装 packages 的统一写法

NumPy：

```bash
python -m pip install "numpy==2.5.2"
```

CPU-only PyTorch：

```bash
python -m pip install torch --index-url https://download.pytorch.org/whl/cpu
```

若以后使用 CUDA，必须根据 PyTorch Start Locally 与实际 driver/CUDA compatibility 重新选择命令，不能照抄 CPU 或旧 CUDA 安装命令。

## 6. 环境与教程的边界

```text
ENVIRONMENT.md
-> 记录当前 Python/package baseline、宿主机快照和 setup

Tn.md
-> 只说明本课需要什么环境、怎样验证环境门
-> 不重复 Python 的系统安装过程
```

Python 3.12 当前处于 security-fixes-only 阶段，官方计划支持到 2028 年 10 月。以后升级 patch version 时，更新本文件并重新运行已有 assertions；除非 API 或行为真的变化，不因 patch version 改动重写教学主线。

## 7. 官方依据

- [Python 3.12.14 release](https://www.python.org/downloads/release/python-31214/)
- [Python versions status](https://devguide.python.org/versions/)
- [Python `venv`](https://docs.python.org/3.12/library/venv.html)
- [Installing packages using pip and virtual environments](https://packaging.python.org/en/latest/guides/installing-using-pip-and-virtual-environments/)
- [NumPy stable beginner guide](https://numpy.org/doc/stable/user/absolute_beginners.html)
- [NumPy 2.5.0 release notes](https://numpy.org/doc/stable/release/2.5.0-notes.html)
