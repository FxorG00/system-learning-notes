# MEMORY.md：C++ 系统工程学习长期记忆

> 用途：给本地 Codex 作为长期上下文入口。每次生成 daily.md、review 代码、调整路线时，优先结合本文件和 plan_strengthened.md。

---

## 1. 我的背景和目标

我是中大计科大一，偏 OI / ACM 背景，算法基础不错。现在不是从零学编程，而是在从算法型训练转向工程化 C++、Linux、OS、网络和系统项目。

长期目标：本科就业，尽早拿到技术密度高的实习 / 工作机会，方向偏：

```text
基础架构
中间件
云平台
系统工程
AI Infra
```

当前重点不是普通 CRUD，也不是追热点，而是把 C++ / Linux / OS / 网络 / 系统项目打硬。

---

## 2. 当前主线

主路线：

```text
C++ 基础
→ 现代 C++
→ Linux 系统编程
→ OS
→ 网络
→ 线程池 / 异步日志 / Reactor
→ Mini Redis
→ Redis / MySQL / Nginx / Kafka
→ 分布式 / 云原生
→ AI Infra
```

当前最新主规划文件：

```text
C:\Users\FxorG\Desktop\gpt_infra\plan_strengthened.md
```

这个规划结合了 200 篇 C++ / Infra / AI Infra 面经，把这些内容权重上调：

```text
MySQL / 数据库
生产级代码
项目深挖
性能压测
排查工具
RPC / 协议
```

但主线不变：

```text
C++
Linux / OS
网络 / Reactor
Mini Redis
```

---

## 3. 当前不要主动扩展

近期不要主动扩展：

```text
Go
DPDK
io_uring 深入
完整 Nginx / Redis 源码
复杂模板元编程
过早 CUDA
15-445 全 project
6.S081 全 lab
```

判断标准：如果它不能服务当前 C++ 主线、系统项目和实习准备，就先放下。

---

## 4. 6.S081 和 15-445 安排

MIT 6.S081 和 CMU 15-445 都可以进路线，但不能三线乱飞。

当前结论：

```text
MIT 6.S081：可以早一点穿插，作为 OS 伴随线
CMU 15-445：后置到 Mini Redis / MySQL 阶段，作为数据库 / 存储伴随线
```

节奏：

```text
Week1 ~ Week3：C++ 主线，不正式开 15-445
Week4 / Week5：Linux / OS 时正式穿插 6.S081
Mini Redis V1 前后：开始预热 15-445
```

---

## 5. 当前进度

已经完成：

```text
Day1：环境搭建，通过
Day2：指针 / 引用 / const，通过
Day3：class / struct / 构造函数 / 析构函数 / this / const 成员函数，通过
Day4：new / delete / new[] / delete[] / RAII，通过
Day5：拷贝构造 / 拷贝赋值 / 浅拷贝 / 深拷贝 / Rule of Three，通过
```

历史评价：

```text
Day4：90/100
Day5：95/100
```

当前最新任务：

```text
Day6：复盘 + 小型 Buffer/StringLike 练习
```

Day6 目标不是学新概念，而是把 Day4 / Day5 的资源管理写熟：

```text
RAII
深拷贝
拷贝赋值
self-assignment
Rule of Three
ASan 初步
```

Day6 代码安排：

```text
01_buffer_no_copy.cpp
02_buffer_deep_copy.cpp
03_string_like.cpp
04_review_questions.md
```

Day6 当前进度：

```text
01_buffer_no_copy.cpp 已完成并 review
02_buffer_deep_copy.cpp 已完成并 review
下一步：03_string_like.cpp + 04_review_questions.md + ASan
```

---

## 6. 当前最重要的知识链

现在刚过 C++ 资源管理第一道坎：

```text
指针
→ 对象生命周期
→ 构造 / 析构
→ new / delete
→ RAII
→ 默认拷贝
→ 浅拷贝
→ double delete
→ 深拷贝
→ 拷贝赋值
→ self-assignment
→ Rule of Three
```

接下来 Day6 要把这条链练熟。Day6 过了以后，再进入：

```text
move 语义
std::move
右值引用
Rule of Five
unique_ptr
shared_ptr
```

不要现在急着跳。

---

## 7. 最近暴露的问题

Day6 暴露 / 修正过的问题：

```text
1. owning pointer 曾拼成 owing pointer。正确是 owning pointer。
2. owning pointer = 拥有资源的指针，也就是负责释放某块资源的指针。
3. 成员变量统一用 `_` 后缀，比如 name_、data_、size_。
4. dangling pointer = 悬空指针，指针还在，但指向的资源已经释放。
5. 拷贝构造中不能读取未初始化的 data_。
6. 拷贝构造里不能像 copy assignment 一样先 delete[] data_，因为新对象还没有旧资源。
7. copy assignment 要判断 self-assignment：if (this == &other)。
8. copy assignment 推荐先 new 新资源，再 delete 旧资源。
9. get / size 这种不修改对象的函数应加 const。
10. size_t 是无符号类型，不需要判断 index < 0。
11. 文件注释要和版本一致：深拷贝版本不要再写“禁止拷贝”。
```

---

## 8. 学习风格

适合的讲解方式：

```text
先直觉
再术语
再机制
再代码验证
再验收问题
```

不喜欢机械的 `What / Why / How` 标题。

偏好的表达：

```text
这玩意本质上是……
这里会炸在哪里……
面试官会怎么追问……
```

笔记不一定写很长，倾向于只记陌生点。但遇到核心坎，比如 RAII / 拷贝控制 / Rule of Three，需要补完整。

---

## 9. 代码和 review 规则

C++ 默认编译参数：

```bash
g++ -std=c++17 -Wall -Wextra -g 文件名.cpp -o 输出名
```

学习期 demo 标准：

```text
能编译
能运行
能观察现象
能解释输出
```

发现错误时：

```text
先解释原因
再给修法
不要直接堆大段高级代码
```

每次改代码前要说明准备改什么。

项目代码逐渐追求：

```text
边界明确
错误处理
资源释放可靠
基本测试
README
可解释
```

---

## 10. daily.md 生成规则

生成每日 `.md` 时，本地 Codex 默认先读：

```text
1. plan_strengthened.md
2. MEMORY.md
3. 当前 week plan
4. 当前 daily.md
5. 前一天 note
6. 当前代码 / 最近 review 暴露的问题
```

每日 `.md` 默认包含：

```text
今日目标
前置回顾
核心概念和术语
代码练习
中途检查
面试追问
6.S081 / 15-445 关联点
不要提前深挖的内容
笔记要求
验收问题
git commit
下一天衔接
```

每天的 `.md` 应该动态调整，不要机械照搬周计划。

---

## 11. 本地 Codex / 网页 GPT 分工

当前决定：生成每日 `.md` 主要交给本地 Codex。

分工：

```text
本地 Codex：读取 plan / MEMORY / daily / notes，生成每日 .md，陪写代码，跑测试，review，修 bug，整理 README
网页端 ChatGPT：只作为备用，用于偶尔的大方向讨论或临时概念解释
```

原因：本地 Codex 能直接围绕本地文件和代码工作，不需要反复复制上下文，更适合长期学习系统。

---

## 12. 下一步衔接

当前最该继续做：

```text
完成 Day6：
- 03_string_like.cpp
- 04_review_questions.md
- 至少一个程序用 ASan 跑过
- git commit
```

Day6 完成后，下一天建议：

```text
Day7：Week1 总复盘 + 小测
```

Day7 不开新大主题，而是检查：

```text
指针
引用
const
class / struct
构造 / 析构
this
const 成员函数
new / delete
RAII
拷贝构造
拷贝赋值
浅拷贝 / 深拷贝
self-assignment
Rule of Three
```

一句话总结：

```text
我不是在刷 C++ 语法，而是在用 C++ 基础逐步搭系统工程底座。Codex 的任务是每天帮我把路线压稳、代码写实、概念讲透、问题及时纠偏。
```