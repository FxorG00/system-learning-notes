# Day1：VMware Ubuntu + Windows VS Code 远程开发环境配置

> 目标：把以后写 C++ / OS / Linux / Go 项目的“工地”搭好。  
> 今天不是学 C++，也不是学 Linux 命令大全；今天只保证环境能跑、工具能用、仓库结构搭好。

---

## 0. Day1 最终目标

今天做完，你应该达到：

```text
1. VMware 里的 Ubuntu 能正常联网
2. Windows VS Code 能通过 SSH 远程连接 Ubuntu
3. g++ / gdb / cmake / make / git 可用
4. Go 可用
5. 能编译运行一个 C++ hello world
6. 能用 gdb 调试一次
7. 能用 CMake 构建一次
8. 建好 system-learning 学习仓库
9. 完成第一次 git commit
```

今天不要追求“高级配置”。  
**能稳定跑起来，就是 Day1 成功。**

---

## 1. VMware Ubuntu 基础确认

### 1.1 推荐虚拟机配置

如果你还没配好 Ubuntu，建议：

```text
系统：Ubuntu 22.04 LTS 或 Ubuntu 24.04 LTS
CPU：2~4 核
内存：4GB 起步，推荐 6GB 或 8GB
磁盘：50GB 起步，推荐 80GB
网络：NAT 模式
```

说明：

- NAT 模式最省心，Ubuntu 能联网，Windows 通常也能连进虚拟机。
- 内存别给太小，否则后面跑 VS Code Server、编译、调试会卡。
- 磁盘别只给 20GB，后面装工具、写项目、编译缓存很快就会占空间。

### 1.2 检查 Ubuntu 是否联网

在 Ubuntu 终端执行：

```bash
ping -c 4 baidu.com
```

或者：

```bash
ping -c 4 8.8.8.8
```

能看到返回数据就行。

---

## 2. 更新 Ubuntu 软件包

在 Ubuntu 终端执行：

```bash
sudo apt update
sudo apt upgrade -y
```

这一步是在更新软件包列表和系统包，避免后面安装工具时出现依赖问题。

如果速度慢，今天先别急着折腾换源。  
Day1 的主线是把环境跑通，不是优化下载速度。

---

## 3. 安装 C++ / Linux 开发工具

执行：

```bash
sudo apt install -y build-essential gdb cmake make git clang clang-format valgrind curl wget tree unzip pkg-config htop lsof net-tools iproute2
```

这些工具分别大概负责：

```text
build-essential：gcc / g++ / make 等基础编译工具
gdb：调试 C++ 程序
cmake：现代 C++ 项目构建工具
make：传统构建工具
git：版本控制
clang-format：代码格式化
valgrind：内存检查，后面再用
curl / wget：下载工具
tree：查看目录结构
htop：查看进程和资源占用
lsof / ss：后面观察端口和文件描述符会用
```

检查版本：

```bash
g++ --version
gdb --version
cmake --version
make --version
git --version
```

只要这些命令能正常输出版本，就说明工具链基本 OK。

---

## 4. 安装 Go

先用 apt 安装即可：

```bash
sudo apt install -y golang
```

检查：

```bash
go version
```

现在不用纠结 Go 是不是最新版。  
等后面真的做 RPC Framework 时，如果版本不够，再换官方安装方式。

---

## 5. 配置 Ubuntu SSH 服务

你现在的开发方式是：

```text
Windows VS Code
    ↓ SSH
VMware Ubuntu
```

也就是说，VS Code 在 Windows 上运行，但代码实际放在 Ubuntu 里，编译、运行、调试也都发生在 Ubuntu。

### 5.1 安装 SSH Server

在 Ubuntu 里执行：

```bash
sudo apt install -y openssh-server
```

启动 SSH：

```bash
sudo systemctl enable ssh
sudo systemctl start ssh
```

检查状态：

```bash
sudo systemctl status ssh
```

如果看到：

```text
active (running)
```

说明 SSH 服务已经启动。

退出状态页面按：

```text
q
```

### 5.2 查看 Ubuntu IP

执行：

```bash
hostname -I
```

你会看到类似：

```text
192.168.80.128
```

记下这个 IP，后面 VS Code 远程连接要用。

也可以用：

```bash
ip addr
```

查看更详细的网卡信息。

---

## 6. Windows VS Code 远程连接 Ubuntu

### 6.1 安装 VS Code 插件

Windows 上打开 VS Code，安装这些插件：

```text
Remote - SSH
C/C++
CMake Tools
Go
```

其中：

- Remote - SSH：让 Windows VS Code 连进 Ubuntu。
- C/C++：提供 C++ 代码补全、跳转、调试支持。
- CMake Tools：后面写 CMake 项目会用。
- Go：后面写 Go RPC 项目会用。

### 6.2 连接 Ubuntu

按：

```text
Ctrl + Shift + P
```

输入并选择：

```text
Remote-SSH: Connect to Host
```

如果是第一次连接，选择：

```text
Add New SSH Host
```

输入：

```bash
ssh 你的Ubuntu用户名@你的Ubuntu_IP
```

例如：

```bash
ssh fxor@192.168.80.128
```

第一次连接会问是否信任，选 yes。

然后输入 Ubuntu 用户密码。

连接成功后，VS Code 左下角应该显示类似：

```text
SSH: 192.168.80.128
```

这说明你已经在用 Windows VS Code 远程操作 Ubuntu 了。

---

## 7. 建立学习仓库

以后你的代码和笔记统一放在 `~/code/system-learning`。

在 VS Code 远程终端里执行：

```bash
mkdir -p ~/code
cd ~/code

mkdir system-learning
cd system-learning

mkdir -p cpp/week1
mkdir -p os/6s081-notes
mkdir -p network
mkdir -p go/week1
mkdir -p notes
```

查看目录：

```bash
tree -L 3
```

你应该看到类似：

```text
.
├── cpp
│   └── week1
├── go
│   └── week1
├── network
├── notes
└── os
    └── 6s081-notes
```

初始化 Git：

```bash
git init
```

配置 Git 用户名和邮箱：

```bash
git config --global user.name "FxorG"
git config --global user.email "你的邮箱"
```

如果你不想用真实邮箱，可以先随便填一个学习用邮箱，之后再改。

---

## 8. 测试 C++ 编译

进入目录：

```bash
cd ~/code/system-learning/cpp/week1
mkdir hello-gpp
cd hello-gpp
touch main.cpp
```

用 VS Code 打开 `main.cpp`，写入：

```cpp
#include <iostream>

int main() {
    std::cout << "hello cpp system" << std::endl;
    return 0;
}
```

编译：

```bash
g++ -std=c++17 -Wall -Wextra -g main.cpp -o main
```

运行：

```bash
./main
```

你应该看到：

```text
hello cpp system
```

这里你先记住几个参数：

```text
-std=c++17：使用 C++17 标准
-Wall：开启常见警告
-Wextra：开启更多警告
-g：生成调试信息，给 gdb 用
-o main：输出文件名为 main
```

这一块属于 C++ 工具链基础，后面会反复用。

---

## 9. 第一次使用 gdb

在 `hello-gpp` 目录下执行：

```bash
gdb ./main
```

进入 gdb 后输入：

```gdb
break main
run
next
next
quit
```

如果问是否退出，输入：

```text
y
```

今天只要求你知道这些命令：

```text
break main：在 main 函数打断点
run：运行程序
next：执行下一行
print 变量名：打印变量
quit：退出
```

gdb 今天只是跑通。  
后面写 C++ 时，我们会专门学怎么用 gdb 查变量、看调用栈、定位段错误。

---

## 10. 测试 CMake

进入目录：

```bash
cd ~/code/system-learning/cpp/week1
mkdir hello-cmake
cd hello-cmake
touch main.cpp CMakeLists.txt
```

`main.cpp` 写：

```cpp
#include <iostream>

int main() {
    std::cout << "hello cmake" << std::endl;
    return 0;
}
```

`CMakeLists.txt` 写：

```cmake
cmake_minimum_required(VERSION 3.10)

project(hello_cmake)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_executable(hello main.cpp)
```

构建：

```bash
cmake -S . -B build
cmake --build build
```

运行：

```bash
./build/hello
```

你应该看到：

```text
hello cmake
```

这里先记住：

```text
cmake -S . -B build：从当前目录读取源码和 CMakeLists.txt，把构建文件放到 build 目录
cmake --build build：真正执行编译
add_executable(hello main.cpp)：用 main.cpp 生成一个叫 hello 的可执行文件
```

以后项目文件多了，就不能一直手写 `g++ xxx.cpp xxx.cpp xxx.cpp`，所以要用 CMake。

---

## 11. 测试 Go

进入 Go 目录：

```bash
cd ~/code/system-learning/go/week1
go mod init system-learning/week1
touch main.go
```

`main.go` 写：

```go
package main

import "fmt"

func main() {
    fmt.Println("hello go system")
}
```

运行：

```bash
go run .
```

你应该看到：

```text
hello go system
```

现在只要确认 Go 能跑。  
Go 后面主要用于 RPC Framework、服务注册发现、分布式组件这些项目。

---

## 12. 认识几个基础观察命令

这些命令今天只要会运行，不需要深入。

查看进程和资源：

```bash
htop
```

退出按：

```text
q
```

查看端口监听：

```bash
ss -lntp
```

查看 IP：

```bash
ip addr
```

查看磁盘：

```bash
df -h
```

查看内存：

```bash
free -h
```

后面你写 TCP Server / Mini Redis 时，经常会用：

```bash
ss -lntp
```

看服务有没有监听端口。

---

## 13. 第一次 Git 提交

回到仓库根目录：

```bash
cd ~/code/system-learning
git status
git add .
git commit -m "week1 env setup"
```

如果 commit 成功，说明 Day1 的代码和目录已经被 Git 管起来了。

以后每周至少 commit 一次。  
项目不是一次写完的，Git 能记录你怎么一步步推进。

---

## 14. Day1 最终验收

做完后，把下面命令的输出发给我：

```bash
g++ --version
gdb --version
cmake --version
go version
git --version
hostname -I
tree ~/code/system-learning -L 3
```

再发这三个运行结果：

```bash
~/code/system-learning/cpp/week1/hello-gpp/main
~/code/system-learning/cpp/week1/hello-cmake/build/hello
cd ~/code/system-learning/go/week1 && go run .
```

如果有报错，不要自己硬憋，把完整报错贴给我。

---

## 15. Day1 简单理解问题

这些不是考试，只是确认你没有机械复制命令。

你能简单回答即可：

```text
1. Windows VS Code 远程 VMware Ubuntu，本质上是通过什么连接的？
2. 你的代码实际存在哪里？Windows 还是 Ubuntu？
3. g++、gdb、cmake、git 分别大概干什么？
4. 为什么我们把项目放在 ~/code/system-learning？
5. g++ 编译命令里的 -g 是给谁用的？
6. CMake 里的 add_executable 是干什么的？
```

不会的就标出来，我再给你讲。

---

## 16. 今天不要做什么

今天不要碰：

```text
复杂 Makefile
configure
多文件 CMake
多线程 gdb
core dump
tcpdump
iostat / sar / mpstat
Docker
K8s
Mini Redis
```

这些以后都会学，但不是 Day1。

---

# Day1 完成标准

当你能做到：

```text
Windows VS Code 能远程连上 VMware Ubuntu
Ubuntu 里能编译 C++
Ubuntu 里能 gdb 调试
Ubuntu 里能 CMake 构建
Ubuntu 里能跑 Go
system-learning 仓库建好并 commit
```

Day1 就结束。

下一步进入 Day2：

> **C++ 指针 / 引用 / const：把 C++ 最基础但最容易混的东西讲清楚，并写小代码验证。**
