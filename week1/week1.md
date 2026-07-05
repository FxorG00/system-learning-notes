对，**第一周应该先配环境**。环境是你的“工地”，没工地就没法施工。
但注意：**配环境最多花半天到一天，不要在环境上自嗨三天。**

以后我们就按“每周 plan”来走：

> 我每周给你：学什么、做到什么程度、产出什么、检查问题。
> 你每周给我：笔记、代码、卡点、总结。
> 我来纠偏、追问、加需求。

---

# 第一周总目标

第一周不要贪。

目标只有三个：

```text
1. 配好 C++ / Linux / Go / 6.S081 的基础环境
2. 补 C++ 第一层：指针、引用、const、类对象、构造析构
3. 复盘 6.S081 第一课，并整理成标准笔记
```

第一周不是为了“学很多”，而是为了把学习系统跑起来。

---

# 第 0 步：环境配置

如果你是 Windows，我建议用：

```text
Windows + WSL2 Ubuntu + VS Code Remote WSL
```

不要直接在 Windows 里搞一堆 MinGW。你未来要学 Linux、OS、网络、C++ 系统编程，**必须尽早进入 Linux 环境**。

---

## 需要装的东西

在 Ubuntu / WSL 里准备：

```bash
sudo apt update
sudo apt install -y build-essential gdb cmake make git clang valgrind
```

再装 Go：

```bash
sudo apt install -y golang
```

检查：

```bash
g++ --version
gdb --version
cmake --version
go version
git --version
```

---

## 建一个学习仓库

建议你建一个 repo：

```bash
mkdir system-learning
cd system-learning
mkdir cpp os network go notes
```

目录大概这样：

```text
system-learning/
├── cpp/
│   ├── week1/
│   └── labs/
├── os/
│   └── 6s081-notes/
├── network/
├── go/
└── notes/
```

以后你每周的代码和笔记都放这里。

---

# 第一周具体计划

按你每天 3～5 小时来算，第一周安排 6 天，第 7 天复盘/休息。

---

## Day 1：配环境 + 建仓库

目标：

* WSL / Linux 环境能用
* C++ 能编译运行
* gdb 能调试
* Go 能运行
* Git 仓库建好

你要写一个最小 C++ 程序：

```cpp
#include <iostream>

int main() {
    std::cout << "hello cpp system" << std::endl;
    return 0;
}
```

用命令编译：

```bash
g++ -std=c++17 -Wall -Wextra -g main.cpp -o main
./main
```

然后用 gdb 跑一下：

```bash
gdb ./main
```

Day 1 验收问题：

```text
1. g++ -std=c++17 -Wall -Wextra -g 是什么意思？
2. -g 的作用是什么？
3. 为什么以后项目要用 CMake，而不是一直手写 g++ 命令？
4. WSL/Linux 和 Windows 原生命令行的差别是什么？
```

---

## Day 2：指针、引用、const

目标：把 C++ 最容易混的底层语法先理清楚。

学习内容：

```text
指针
引用
const
const int*
int* const
const int* const
const 引用传参
```

你要写代码验证这些东西。

比如：

```cpp
void foo(const int& x) {
    // x = 10; // 为什么不行？
}

int main() {
    int a = 10;
    int* p = &a;
    int& r = a;

    const int* p1 = &a;
    int* const p2 = &a;
    const int* const p3 = &a;
}
```

Day 2 验收问题：

```text
1. 指针和引用的区别是什么？
2. 引用能不能重新绑定？
3. 指针能不能是 nullptr？
4. const int* 和 int* const 区别是什么？
5. 为什么函数参数常用 const std::string&？
6. 什么时候应该值传递，什么时候应该引用传递？
```

学到什么程度算过关：

> 看到 `const std::string&`、`int* const`、`const int*` 不懵。

---

## Day 3：类、构造函数、析构函数

目标：理解对象是怎么“出生”和“死亡”的。

学习内容：

```text
class / struct
构造函数
析构函数
成员变量初始化
this 指针
对象生命周期
```

你要写一个类：

```cpp
#include <iostream>
#include <string>

class User {
public:
    User(const std::string& name) : name_(name) {
        std::cout << "User constructed: " << name_ << std::endl;
    }

    ~User() {
        std::cout << "User destructed: " << name_ << std::endl;
    }

    void hello() const {
        std::cout << "hello, " << name_ << std::endl;
    }

private:
    std::string name_;
};

int main() {
    User u("fxor");
    u.hello();
}
```

Day 3 验收问题：

```text
1. 构造函数什么时候调用？
2. 析构函数什么时候调用？
3. 栈上对象和堆上对象生命周期有什么区别？
4. this 指针是什么？
5. 为什么成员变量推荐用初始化列表初始化？
6. class 和 struct 默认访问权限有什么区别？
```

学到什么程度算过关：

> 你能讲清楚一个对象从创建到销毁发生了什么。

---

## Day 4：new/delete、new[]/delete[]、RAII 初步

目标：理解为什么 C++ 面试有那么多内存坑。

学习内容：

```text
new
delete
new[]
delete[]
裸指针的风险
RAII 思想
```

重点记住：

```text
new    配 delete
new[]  配 delete[]
```

但不要停留在背诵。你要理解：

* `new` 会构造一个对象；
* `delete` 会析构一个对象；
* `new[]` 会构造一组对象；
* `delete[]` 要逐个析构这一组对象。

Day 4 验收问题：

```text
1. malloc/free 和 new/delete 有什么区别？
2. delete 和 delete[] 为什么不能乱配？
3. 如果一个类有析构函数，new[] 后用 delete 会发生什么风险？
4. 为什么工程里不推荐到处裸 new/delete？
5. RAII 是什么？它解决什么问题？
```

学到什么程度算过关：

> 看到 `delete[]` 这类面试题，你知道它本质考的是对象生命周期和资源释放，不是单纯背规则。

---

## Day 5：6.S081 第一课复盘

目标：把你之前那份笔记整理成更标准的版本。

你要重新整理这些概念：

```text
user mode
kernel mode
system call
file descriptor
shell
fork
exec
wait
redirect
```

你这一天的任务不是继续往后冲，而是把第一课讲顺。

你要能回答：

```text
1. 为什么要区分 user mode 和 kernel mode？
2. system call 是什么？
3. open/read/write 为什么不能直接由普通程序操作硬件完成？
4. file descriptor 到底是什么？
5. fork 后父子进程有什么相同，有什么不同？
6. exec 做了什么？
7. shell 执行 ls 的流程是什么？
8. 重定向的本质是什么？
```

学到什么程度算过关：

> 你能用 5 分钟，从 shell 输入 `ls > out` 开始，把 fork、exec、wait、fd、redirect 串起来讲一遍。

---

## Day 6：小复盘 + 小练习

这一天不要学新东西，做复盘和小练习。

你要写一份 `week1_summary.md`，包括：

```text
1. 本周学了什么
2. 哪些概念我已经会了
3. 哪些地方还模糊
4. 我写了哪些代码
5. 下周最想解决什么问题
```

同时完成 3 个小代码：

### 练习 1：指针和引用

写一个函数交换两个整数，分别用：

```text
指针版本
引用版本
```

---

### 练习 2：类生命周期

写一个类 `Tracer`，在构造、析构时打印日志，用它观察对象生命周期。

---

### 练习 3：new/delete

写一个小程序，分别使用：

```text
new/delete
new[]/delete[]
```

观察构造/析构次数。

---

# 第一周最终验收清单

第一周结束时，你应该有这些产出：

```text
1. Linux / WSL 环境可用
2. system-learning 仓库建好
3. cpp/week1 里有 3~5 个小代码
4. os/6s081-notes 里有第一课标准笔记
5. week1_summary.md
```

你应该能回答这些问题：

```text
1. 指针和引用的区别？
2. const int* / int* const / const int* const 区别？
3. 构造函数和析构函数什么时候调用？
4. 栈对象和堆对象生命周期区别？
5. new/delete 和 malloc/free 区别？
6. 为什么 new[] 要配 delete[]？
7. RAII 是什么？
8. system call 是什么？
9. fork/exec/wait 如何配合 shell 执行命令？
10. file descriptor 是什么？
```

---

# 你以后每周的工作方式

以后每周我都可以按这个格式给你：

```text
本周目标
学习内容
每天任务
代码练习
笔记要求
验收问题
下周衔接
```

然后你每周末发我：

```text
这是我本周的代码
这是我的笔记
这是我的总结
这些问题我还不会
```

我来做：

* 笔记纠错
* 代码 review
* 面试追问
* 下周计划调整

---

# 第一周的核心原则

这一周千万不要贪。

不要想着：

```text
我顺便学智能指针
我顺便学 epoll
我顺便学 K8s
我顺便看 vLLM
```

第一周只要把基础工作台搭好，把 C++ 对象生命周期和 OS 第一课搞清楚，就已经很赚了。

你的学习从第一周开始，正式进入：

> **有计划、有产出、有验收的工程路线。**
