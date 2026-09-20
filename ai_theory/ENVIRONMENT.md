# AI Theory 开发环境

> 环境基线日期：2026-09-17
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

`xgf` 的 `~/.bashrc` 在 interactive check 之前统一设置：

```bash
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"
```

因此普通 terminal 和 `ssh host "command"` 这种 non-interactive shell 都会得到：

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

AI Theory 不使用 `uv`。从 2026-09-17 起，T1~T24 默认共用 `xgf` 的 Python 3.12 user-level packages：

```text
interpreter：/usr/local/bin/python3
packages：/home/xgf/.local/lib/python3.12/site-packages
dependency declaration：ai_theory/requirements.txt
```

这里的“全局”指 `xgf` 用户的统一理论学习环境，不是覆盖 Ubuntu 的 system Python，也不是给所有 Linux users 安装 packages。`/usr/bin/python3` 继续保持 3.8.10。

选择 Python 3.12 的原因：

```text
Python 3.8 已于 2024-10-07 EOL，不再获得安全更新
NumPy 2.5 支持 Python 3.12~3.14
Python 3.12 与当前 scientific Python package 兼容成熟
```

当前可复现 baseline 为：

```text
NumPy 2.5.2
CPU PyTorch 2.14.0+cpu
Matplotlib 3.11.2
```

精确 pin 是为了复现实验，不是为了迁就旧 Python。当前不安装 CUDA wheel；真正进入 CUDA gate 时再根据 driver、toolkit 与 PyTorch compatibility 选择环境。

## 2. 宿主机快照

2026-09-02 实际配置与验证结果：

```text
OS：Ubuntu 20.04.6 LTS
default python/python3：3.12.14
system /usr/bin/python3：3.8.10
pip：25.0.1 for Python 3.12
stdlib extension build：0 missing，0 failed on import
verified modules：ssl、sqlite3、bz2、lzma、ctypes、venv
AI packages：NumPy 2.5.2、CPU PyTorch 2.14.0+cpu、Matplotlib 3.11.2
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

## 4. 理论线统一环境

T1~T24 的小型脚本共享同一套 NumPy/PyTorch/Matplotlib baseline，不再为每个 T module 重复建立 `.venv`。进入任意理论目录后可以直接运行：

```bash
python3 script_name.py
```

统一安装或恢复环境：

```bash
cd ~/code/system-learning
python3 -m pip install --user -r ai_theory/requirements.txt
```

`--user` 把 packages 安装到 `xgf` 的 user site，不写入 `/usr/lib`，也不改变 Ubuntu system Python。命令统一写成 `python3 -m pip`，避免裸 `pip` 指向错误 interpreter。

验证当前环境：

```bash
command -v python3
python3 --version
python3 -c "import numpy, torch, matplotlib; print(numpy.__version__, torch.__version__, matplotlib.__version__)"
```

当前预期：

```text
/usr/local/bin/python3
Python 3.12.14
2.5.2 2.14.0+cpu 3.11.2
```

如果后续某个实验需要冲突版本，仍可以为该实验单独建立 venv：

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install ...
```

这是 exception，不再是每个 T module 的默认动作。`.venv/` 仍不提交到 Git。

## 5. 安装 packages 的统一写法

恢复当前统一环境：

```bash
python3 -m pip install --user -r ai_theory/requirements.txt
```

若以后使用 CUDA，必须根据 PyTorch Start Locally 与实际 driver/CUDA compatibility 重新选择命令，不能照抄 CPU 或旧 CUDA 安装命令。

## 6. 环境与教程的边界

```text
ENVIRONMENT.md
-> 记录当前 Python/package baseline、shell resolution、宿主机快照和 setup

Tn.md
-> 只说明本课需要什么环境、怎样验证环境门
-> 不重复 Python 的系统安装过程
```

T1 中逐步建立 `.venv` 的内容保留为已经完成的 Python environment 教学记录；从 T2 以后按本文件的新统一环境执行，不要求机械重复 setup。

Python 3.12 当前处于 security-fixes-only 阶段，官方计划支持到 2028 年 10 月。以后升级 patch version 时，更新本文件并重新运行已有 assertions；除非 API 或行为真的变化，不因 patch version 改动重写教学主线。

## 7. 官方依据

- [Python 3.12.14 release](https://www.python.org/downloads/release/python-31214/)
- [Python versions status](https://devguide.python.org/versions/)
- [Python `venv`](https://docs.python.org/3.12/library/venv.html)
- [Installing packages using pip and virtual environments](https://packaging.python.org/en/latest/guides/installing-using-pip-and-virtual-environments/)
- [NumPy stable beginner guide](https://numpy.org/doc/stable/user/absolute_beginners.html)
- [NumPy 2.5.0 release notes](https://numpy.org/doc/stable/release/2.5.0-notes.html)
