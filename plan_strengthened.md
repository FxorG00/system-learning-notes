# plan.md：C++ 主线系统工程 / AI Infra 准备路线（200 篇面经强化版）

> 版本：2026-07-05  
> 定位：近期去掉 Go，先把 **C++ / Linux / OS / 网络 / 系统项目 / 面试表达** 打硬；中途穿插 MIT 6.S081 和 CMU 15-445，但不让它们抢主线。  
> 总目标：本科阶段拿到技术密度高的实习 / 工作机会，长期往基础架构、云平台、中间件、数据库/存储、AI Infra 方向延展。

---

## 本版强化说明：根据 200 篇 C++ / Infra / AI Infra 面经调整

这版不推倒原路线，而是在原来的 **C++ 主线 + 6.S081 + 15-445** 上做强化。

### A. 权重上调

```text
MySQL / 数据库：从后置补充上调为中间件阶段必修
存储系统：从了解上调为 15-445 伴随线
生产级代码：从项目加分项上调为项目验收项
性能压测：从后期优化上调为每个系统项目必做
排查工具：从工具池上调为项目排查能力
RPC / 协议：从可选项上调为 Reactor / Mini Redis 后的补充模块
项目深挖：从简历准备上调为每个项目的硬性产出
```

### B. 不变的主线

```text
C++ 主线不变
Linux / OS 主线不变
网络 / Reactor 主线不变
Mini Redis 主项目不变
Go 仍然暂时不回主线
AI Infra 仍然后置，但保留接口
```

### C. 面经雷达机制

以后每周末抽 5~10 篇同类面经，不逐篇背，只做三件事：

```text
1. 记录不会回答的问题
2. 标记和当前主线相关的问题
3. 把高频问题变成下一周任务
```

输出格式：

```markdown
## 本周面经雷达

### 高频但我不会的
- ...

### 和当前项目相关的
- ...

### 下周要补的
- ...

### 暂时不碰的
- ...
```

时间控制在每周 30~60 分钟，不让面经抢主线。

### D. 生产级代码标准

学习期 demo 的标准：

```text
能编译
能运行
能观察现象
能解释输出
```

项目期代码的标准：

```text
接口清楚
边界明确
错误处理
资源释放可靠
线程安全说明
有基本测试
有 README
有性能数据
能讲设计取舍
```

从 ThreadPool / AsyncLogger 开始，项目代码提交前过一遍：

```text
边界输入处理了吗？
错误返回设计了吗？
资源释放可靠吗？
是否可能内存泄漏？
是否可能 double free？
是否有数据竞争？
线程退出能否 graceful shutdown？
日志够不够定位问题？
有没有最小单元测试？
有没有基本压测？
README 能不能让别人跑起来？
```

### E. 项目深挖硬性产出

每个项目都维护一个 `interview.md`：

```markdown
# 项目面试问答

## 1. 为什么做这个项目？

## 2. 整体架构是什么？

## 3. 为什么这么设计？

## 4. 最难的 bug 是什么？

## 5. 怎么压测？

## 6. 性能瓶颈在哪里？

## 7. 如果让你继续优化，你会怎么做？

## 8. 和真实 Redis / Nginx / muduo / MySQL 的差距在哪里？
```

项目 README 至少包含：

```text
项目简介
功能列表
架构图
构建方式
使用示例
测试方式
压测结果
踩坑总结
后续优化
```

---

## 本版新增阶段：Week 13 ~ Week 15

### Week 13 ~ Week 14：MySQL / 15-445 第一轮

目标：把数据库 / 存储从“会背概念”变成“能和项目、面试、系统设计联系起来”。

学习内容：

```text
MySQL 基本使用回顾
索引和 B+ tree
聚簇索引 / 二级索引
explain
事务和隔离级别
MVCC 直觉
锁：行锁 / 间隙锁 / next-key lock 了解
undo / redo / binlog 直觉
buffer pool
WAL / recovery
```

15-445 穿插：

```text
Database system overview
Storage hierarchy
Buffer pool
Hash table
B+ tree
Transaction / Concurrency Control 第一轮
Recovery / WAL 第一轮
```

产出：

```text
B+ tree 笔记
buffer pool 笔记
MySQL explain 小实验
事务隔离级别 demo
WAL / redo / undo 对比笔记
把 15-445 概念挂到 MySQL 和 Mini Redis 的总结
```

验收：

```text
能解释为什么 MySQL 用 B+ tree
能解释为什么需要 buffer pool
能解释事务解决什么问题
能解释 MVCC 的基本直觉
能解释 WAL 为什么能用于恢复
```

### Week 15：RPC / 协议设计初步

目标：为后续服务框架、Mini Redis 协议层、分布式系统做准备。

学习内容：

```text
请求 / 响应模型
协议格式
序列化 / 反序列化
错误码
超时
重试
连接复用
同步调用 / 异步调用
```

产出：

```text
基于 TCP 的简单 RPC demo
请求响应协议文档
错误码设计
超时处理 demo
README：协议格式和设计取舍
```

暂时不碰：

```text
完整 gRPC
复杂 IDL
服务发现
负载均衡
熔断限流
```

---


---

## 0. 当前总决策

### 0.1 主线不变：C++ 系统工程优先

近期不把 Go 放进主线。

Go 的定位：

```text
未来可选副线
不是当前 Week1 ~ Week8 主线
不作为每天 .md 的默认内容
等 C++ / Linux / OS / 网络 / 系统项目稳定后，再评估是否补
```

当前主线：

```text
C/C++ 基础
→ C++11 / 现代 C++
→ Linux 系统编程
→ OS 基础
→ 数据结构在工程里的应用
→ 必要设计模式
→ C++ 基础组件
→ 网络编程 / 高性能网络
→ Redis / MySQL / Nginx / Kafka 等中间件
→ 测试 / 调试 / 性能分析
→ C++ 项目实战
→ 分布式 / 云原生
→ AI Infra
```

这条线的核心不是“学一堆课”，而是：

```text
知识点
+ 小 demo 验证
+ 项目落地
+ 性能/调试工具
+ 面试表达
```

---

### 0.2 新增两条伴随线

现在加入两条伴随线：

```text
MIT 6.S081：OS 伴随线
CMU 15-445：数据库 / 存储伴随线
```

但它们的优先级不同。

```text
C++ 系统工程主线：必须推进
MIT 6.S081：从 Week4 / Week5 开始穿插，服务 Linux / OS 理解
CMU 15-445：后置到中间件阶段，服务 Mini Redis / MySQL / 存储系统理解；Mini Redis V1 后必须开始预热
```

一句话：

```text
6.S081 可以早一点穿插；
15-445 不要太早正式开。
```

---

### 0.3 当前进度

```text
Day1：环境搭建，通过
Day2：指针 / 引用 / const，通过
Day3：class / struct / 构造函数 / 析构函数 / this / const 成员函数，通过
Day4：new / delete / new[] / delete[] / RAII 初步，已生成，下一步执行
```

Day1 ~ Day3 你之前都接触过，所以推进快是正常的。后面保持：

```text
熟悉内容快速过
关键内容代码验证
薄弱内容重点补
每天根据实际进度动态调整
```

---

## 1. 规划依据

### 1.1 你的个人目标

你当前的目标不是普通 CRUD 后端，而是：

```text
本科就业
优先找技术密度高的实习
长期往基础架构 / 云平台 / 中间件 / 数据库/存储 / AI Infra 方向延展
```

所以主线必须以：

```text
C++
Linux
OS
网络
系统项目
中间件
性能分析
```

为核心。

---

### 1.2 面试真实趋势

近两年 C++ 大厂面经体现出几个趋势：

```text
C++ 不再只问孤立定义，而是问对象生命周期、RAII、拷贝/移动、STL 行为、智能指针、异常安全怎么在项目里用。
OS/Linux、网络、项目深挖经常绑在一起问。
线程模型、锁、虚拟内存、mmap、TCP、epoll、Reactor 是高频主线。
面试官特别爱追问为什么这么设计、异常情况、性能验证、线上排查。
手撕题通常不离谱，但要可运行、边界完整、复杂度清楚。
```

所以新规划必须显式加入：

```text
异常安全
对象内存布局 / 虚函数表 / 多态
STL 细节：vector 扩容、迭代器失效、容器选型
OS demo：fork/COW、mmap、锁竞争
调试排查：gdb、strace、valgrind、日志、benchmark
项目表达：STAR + 技术取舍 + 指标验证
少量长期手撕题训练
```

---

### 1.3 为什么加入 MIT 6.S081

6.S081 对你有价值，因为它能解释：

```text
system call
trap
user mode / kernel mode
page table
process
scheduler
context switch
file descriptor
virtual memory
```

这些内容会直接支撑：

```text
Linux 系统编程
OS 面试
网络 IO
epoll / Reactor
C++ 系统项目
```

但注意：

```text
现在不急着全刷 lab
先看核心 lecture
配合 Linux 小 demo 和笔记
能解释概念优先
```

---

### 1.4 为什么加入 CMU 15-445

15-445 对你后面有价值，因为它能解释：

```text
数据库存储
buffer pool
page
B+ tree
hash index
query execution
concurrency control
transaction
WAL / recovery
```

这些内容会直接支撑：

```text
MySQL 原理
Mini Redis 后续深化
KVStore / 存储项目
数据库 / 中间件面试
AI Infra 中的数据和存储系统理解
```

但注意：

```text
15-445 不现在主开
等 C++ / STL / Linux / OS 第一轮完成后再穿插
更适合放在 Mini Redis / MySQL 阶段
```

---

## 2. 学习原则

### 2.1 每周有总计划，每天动态调整

每周先给一个 week plan，但每天生成 `.md` 时，不机械照搬周计划，而是综合：

```text
1. 本周总目标
2. 前一天实际完成情况
3. 笔记里暴露出的薄弱点
4. 当前最该补的知识
5. 面试高频程度
6. 项目路线和找工作价值
7. 6.S081 / 15-445 是否适合穿插
```

也就是说，每天的 `.md` 是动态调整版，不是死课表。

---

### 2.2 主线和伴随线的比例

当前阶段默认比例：

```text
C++ / Linux / OS / 网络主线：80%
6.S081：20% 以内
15-445：暂时 0%，后面中间件阶段再开始
```

等进入中间件阶段后：

```text
C++ 项目 / Mini Redis：60%
Redis / MySQL / 15-445：30%
测试 / 性能 / 面试表达：10%
```

---

### 2.3 讲解风格

以后讲知识点不机械使用 `What / Why / How` 这种标题。

默认风格：

```text
先建立直觉
再给必要术语
再解释底层机制
再写代码验证
中途穿插检查问题
最后给验收题
```

术语要有，但不堆砌。

目标是：

```text
能和别人交流
能看懂代码
能解释给面试官
```

---

### 2.4 代码和笔记习惯

```text
代码：默认放 Ubuntu 的 ~/code/system-learning
笔记：按自己的习惯存，不强制放 Ubuntu
提交：每个学习日尽量有一次 git commit
```

建议仓库结构逐渐变成：

```text
system-learning/
├── cpp/
│   ├── week1/
│   ├── week2/
│   └── components/
├── linux/
│   ├── fd/
│   ├── process/
│   └── mmap/
├── os/
│   └── 6s081-notes/
├── network/
│   ├── tcp/
│   ├── epoll/
│   └── reactor/
├── db/
│   ├── redis/
│   ├── mysql/
│   └── 15445-notes/
└── projects/
    ├── threadpool/
    ├── async_logger/
    ├── reactor/
    └── mini_redis/
```

不用现在一次建完，后面按模块自然增长。

---

### 2.5 不追求“大而全”

现在最重要的是：

```text
C++ 对象和资源管理
Linux 系统调用和工具链
OS 进程 / 线程 / 虚拟内存 / IO
网络 TCP / HTTP / socket / epoll
C++ 系统项目：线程池、Reactor、Mini Redis
调试 / 测试 / 性能验证
```

暂时不要被这些内容分散：

```text
DPDK
io_uring 深入
完整 Nginx 源码
Ceph
TiDB
Skynet
OpenResty WAF
Firewall / netfilter
完整 Kafka 实现
CUDA 过早深入
复杂模板元编程
15-445 全部 project 硬刷
6.S081 全部 lab 硬刷
```

---

## 3. 总路线图

### 3.1 阶段总览

| 阶段 | 时间 | 主目标 | 关键词 |
|---|---|---|---|
| 阶段 0 | 当前第一周 | 环境 + C++ 对象和内存基础 | g++、gdb、cmake、git、指针、引用、const、构造析构、new/delete、RAII |
| 阶段 1 | 当前 ~ 2026.10 | ACM 主线 + 工程底座 | 现代 C++、Linux 工具链、OS、网络基础、6.S081 核心 lecture、少量面试题 |
| 阶段 2 | 2026.10 ~ 2027.1 | C++ 系统编程入门项目 | 阻塞队列、线程池、异步日志、TCP Server、epoll、Reactor |
| 阶段 3 | 2027.1 ~ 2027.4 | 中间件项目主线 | Mini Redis、Redis 原理、MySQL 原理、15-445 选学、RPC/协议、benchmark、gtest、valgrind、项目压测 |
| 阶段 4 | 2027.4 ~ 2027.6 | 实习投递准备 | 项目打磨、简历、面试、Nginx/Kafka 基础、性能数据、项目讲稿 |
| 阶段 5 | 2027 暑假 | 第一份实习 | 基础架构、云平台、中间件、C++ 后端 |
| 阶段 6 | 2027.7 ~ 2028.1 | 分布式 / 云原生 | Raft、Mini KV、Docker、K8s、Prometheus、存储系统 |
| 阶段 7 | 2028 | AI Infra 主线 | ML/DL、Transformer、LLM Serving、CUDA |

---

## 4. 优先级分层

### P0：现在必须进入主线

```text
C++ 基础和现代 C++
RAII / 拷贝控制 / 移动语义 / 智能指针
STL 行为：vector、string、map、unordered_map、迭代器失效
Linux 工具链：git / gdb / cmake / make / ssh / strace
OS：进程、线程、锁、虚拟内存、fd、IO 模型
网络原理：TCP / UDP / HTTP / DNS / Socket
高性能 IO：select / poll / epoll
Reactor 模型
C++ 多线程：thread / mutex / condition_variable / atomic
MIT 6.S081 核心 lecture：system call / page table / trap / process / scheduler / file system 基础
```

---

### P1：退役后重点推进

```text
BlockingQueue 阻塞队列
ThreadPool 线程池
AsyncLogger 异步日志
Timer 定时器
RingBuffer
TCP Echo Server
Epoll Server
Reactor 框架
HTTP Server 初步
MemoryPool 初步
ConnectionPool 初步
Mini Redis
Redis 协议和数据结构
MySQL 索引、事务、MVCC、锁
CMU 15-445 选学：storage / buffer pool / B+ tree / transaction / concurrency / recovery
RPC / 协议设计初步：请求响应、序列化、超时、错误码
gtest / benchmark / valgrind / strace / gdb
项目 README / 架构图 / 性能数据 / 面试讲稿 / 排查记录
```

---

### P2：项目打磨和平台能力

```text
Nginx 基础：反向代理、负载均衡、worker 模型、事件驱动
Kafka 基础：topic、partition、consumer group、offset
Docker
Kubernetes
Prometheus / Grafana
Raft
Mini KV
RocksDB / LSM Tree 初步
15-445 project 思路选读
```

---

### P3：暂时不碰，后面按方向选修

```text
DPDK
io_uring 深入
完整 Nginx 源码模块开发
Ceph
TiDB
FUSE
OpenResty WAF
Firewall / netfilter
Skynet
ZeroMQ
MQTT
完整 Kafka 实现
复杂模板元编程
CUDA 过早深入
MIT 6.S081 全部 lab 强刷
CMU 15-445 全部 project 强刷
```

---

## 5. 当前 8 周执行计划

### Week 1：C++ 对象和内存基础

目标：把 C++ 对象、指针、引用、const、构造析构、new/delete、RAII 第一层打牢。

```text
Day1：环境搭建：VMware Ubuntu + VS Code SSH + g++ / gdb / cmake / git
Day2：指针 / 引用 / const
Day3：class / struct / 构造函数 / 析构函数 / this / const 成员函数
Day4：new / delete / new[] / delete[] / RAII 初步
Day5：拷贝构造 / 拷贝赋值 / 浅拷贝 / 深拷贝
Day6：复盘 + 小型 String/Buffer 类练习
```

6.S081 / 15-445：

```text
不正式开。
最多看 6.S081 课程简介，了解它是干什么的。
15-445 不开。
```

产出：

```text
system-learning 仓库
Day1 ~ Day6 小代码
git commit 记录
每日至少一份简短总结
```

---

### Week 2：拷贝控制 + 移动语义 + 智能指针 + 异常安全初步

目标：理解 C++ 对象复制、移动、资源所有权和异常时资源如何释放。

学习内容：

```text
拷贝构造
拷贝赋值
析构函数
Rule of Three
Rule of Five
浅拷贝 / 深拷贝
move 语义
std::move
右值引用
unique_ptr
shared_ptr
weak_ptr 初步
异常安全初步
noexcept 初步
copy-and-swap 初步
```

6.S081 / 15-445：

```text
不正式开。
可以听 6.S081 Lecture 1，但只当作背景，不写重笔记。
15-445 不开。
```

产出：

```text
手写 IntBuffer / StringLike
演示浅拷贝 double delete
修成深拷贝版本
修成禁止拷贝 + 支持 move 版本
unique_ptr 管理资源 demo
异常路径下 RAII 自动释放 demo
```

---

### Week 3：STL + 工程数据结构第一轮

目标：把 STL 从“会用”升级到“知道工程含义和面试细节”。

学习内容：

```text
vector 扩容
capacity / size
push_back / emplace_back
迭代器失效
string 基本机制
map / set 与红黑树
unordered_map / unordered_set 与哈希表
哈希冲突
rehash
erase 时迭代器怎么处理
pair / tuple / optional 初步
算法库常用函数
```

工程数据结构映射：

```text
hash table → Redis dict / unordered_map
skiplist → Redis zset
B+ tree → MySQL 索引
heap → 定时器
ringbuffer → 网络 buffer / 日志队列
LRU → 缓存淘汰
bitmap → 状态压缩
Bloom Filter → 快速判断不存在
```

6.S081 / 15-445：

```text
6.S081 可轻看 Lecture 2：OS organization / system calls。
15-445 仍不正式开。
```

产出：

```text
vector 扩容观察 demo
迭代器失效 demo
unordered_map 哈希冲突 demo
简化 LRU Cache
简化 RingBuffer
```

---

### Week 4：Linux 系统编程第一轮 + 6.S081 正式穿插

目标：从 C++ 语法进入 Linux 程序的真实运行环境。

学习内容：

```text
file descriptor
open / read / write / close
stat
lseek
dup / dup2
pipe
fork / exec / wait
exit / _exit
signal 初步
mmap 初步
errno
strace
lsof
ss
ps / top / htop
```

6.S081 穿插：

```text
Lecture：system calls / OS organization / page table 前置
重点问题：
- 用户程序怎么进内核？
- system call 是什么？
- fd 为什么可以代表文件、pipe、socket？
- fork 为什么能复制进程？
```

15-445：

```text
不开。
```

产出：

```text
mycat：读取文件并输出
copyfile：文件复制
pipe demo：父子进程通信
fork-exec demo
mmap demo
strace 观察系统调用笔记
6.S081 system call / fd 对应笔记
```

---

### Week 5：OS 第一轮 + 6.S081 核心 lecture

目标：把 MIT 6.S081 / OSTEP 的核心概念和 Linux 编程对应起来。

学习内容：

```text
user mode / kernel mode
system call
process / thread
context switch
scheduler 基本思想
lock
condition_variable
virtual memory
page table
file descriptor
blocking IO
fork / COW
mmap
```

6.S081 穿插：

```text
重点 lecture：
- page tables
- traps
- system calls
- scheduling
- locks
- file system 可先了解

暂时不强求：
- 全部 lab
- xv6 源码逐行看
```

产出：

```text
system call 笔记
process / thread 对比笔记
fd 机制图
虚拟内存直觉图
fork/COW demo 笔记
mmap demo 笔记
6.S081 page table / trap / syscall 笔记
```

---

### Week 6：网络原理第一轮

目标：能写 TCP client/server，并知道网络 API 背后在干什么。

学习内容：

```text
TCP / UDP
三次握手 / 四次挥手
TIME_WAIT / CLOSE_WAIT
可靠传输直觉
滑动窗口大概思想
拥塞控制大概思想
HTTP 请求响应
DNS 基本流程
socket
bind
listen
accept
connect
recv
send
close
阻塞 IO
```

6.S081：

```text
作为背景资料，不占主线。
可以把 fd / blocking IO / sleep-wakeup 和网络 IO 联系起来。
```

15-445：

```text
不开。
```

产出：

```text
TCP echo server
TCP client
HTTP 请求文本解析 demo
用 ss 查看监听端口
用 nc/telnet 测试服务
```

---

### Week 7：C++ 多线程和同步

目标：为阻塞队列、线程池和高性能服务端做准备。

学习内容：

```text
std::thread
join / detach
mutex
lock_guard
unique_lock
condition_variable
producer-consumer
BlockingQueue
atomic 基础
CAS 初步
false sharing 了解即可
```

6.S081 穿插：

```text
看 locks / scheduling 相关内容。
把课程里的 sleep / wakeup 和 C++ condition_variable 联系起来。
```

15-445：

```text
不开。
```

产出：

```text
多线程计数器 demo
condition_variable wait/notify demo
生产者消费者 BlockingQueue
atomic counter demo
锁竞争 demo
```

---

### Week 8：线程池 + 异步日志 + 测试 / benchmark 初步

目标：写出第一个真正有工程味的 C++ 基础组件组合。

学习内容：

```text
task queue
worker threads
condition_variable
future / packaged_task 初步
graceful shutdown
BlockingQueue 复用
AsyncLogger 异步日志
gtest 初步
benchmark 初步
```

6.S081：

```text
可作为并发背景，不新增 lecture 压力。
```

15-445：

```text
不开。
```

产出：

```text
ThreadPool V1
AsyncLogger V1
单元测试
简单 benchmark
README：设计、接口、使用示例、踩坑
```

---

## 6. Week 9 之后的衔接计划

### Week 9：epoll / Reactor 第一轮

目标：把 TCP Server 从阻塞模型升级到事件驱动模型。

学习内容：

```text
阻塞 / 非阻塞 IO
select / poll / epoll
LT / ET
fd event
EventLoop
Channel
Acceptor
Connection
Callback
```

6.S081：

```text
理解 IO 阻塞、进程睡眠、内核事件通知。
```

产出：

```text
Epoll Echo Server
Reactor V1
README：为什么 epoll 适合大量连接
```

---

### Week 10：HTTP Server / 网络项目打磨

目标：把 Reactor 应用到 HTTP Server 初步。

学习内容：

```text
HTTP 请求格式
HTTP 响应格式
GET 请求
Connection: close / keep-alive 初步
Buffer 封装
日志接入
```

产出：

```text
HTTP Server V1
接入 AsyncLogger
简单压测
README
```

---

### Week 11 ~ Week 12：Mini Redis V1

目标：进入中间件项目主线。

学习内容：

```text
Redis 基本命令
RESP 协议
SET / GET / DEL
内存 KV
TTL 初步
Reactor 网络层复用
```

15-445：

```text
可以开始预热数据库系统导论。
不做 project。
只看：
- database system overview
- storage hierarchy
- buffer pool 大概思想
```

产出：

```text
Mini Redis V1
RESP parser
SET / GET / DEL
README
简单测试
```

---

## 7. MIT 6.S081 穿插路线

### 7.1 学习定位

6.S081 是 OS 伴随线，不是当前主线。

目标不是“刷完神课”，而是服务这些问题：

```text
system call 是怎么发生的？
为什么用户程序不能直接访问硬件？
进程和线程到底是什么？
虚拟地址怎么变成物理地址？
trap 是什么？
scheduler 为什么能切换程序？
file descriptor 为什么这么统一？
```

---

### 7.2 建议学习顺序

```text
第一轮：听核心 lecture + 写概念笔记
第二轮：结合 Linux demo 验证
第三轮：有余力再挑 lab
```

当前第一轮重点：

```text
Lecture 1：Introduction / OS overview
Lecture 2：OS organization / system calls
Lecture 3：Page tables
Lecture 4：Traps
Lecture 5：Copy-on-write / memory
Lecture 6：Multithreading / locks
Lecture 7：Scheduling
Lecture 8：File system 了解
```

不用急着完整做：

```text
xv6 syscall lab
page table lab
traps lab
cow lab
thread lab
file system lab
```

如果后面时间足够，再挑最有价值的 lab：

```text
syscall
page table
traps
cow
thread
```

---

### 7.3 和主线的对应关系

```text
Linux fd / open / read / write → 6.S081 system call / file descriptor
fork / exec / wait → 6.S081 process
mmap / virtual memory → 6.S081 page table
signal / trap → 6.S081 trap
thread / lock → 6.S081 scheduling / locks
blocking IO → OS sleep / wakeup
```

---

### 7.4 6.S081 验收标准

不用一上来能改 xv6。第一轮只要求：

```text
能解释用户态 / 内核态
能解释 system call 大概流程
能解释 page table 的意义
能解释 trap 是什么
能解释 fork 为什么能创建进程
能解释 COW 是什么
能解释 scheduler 为什么能切换进程
能解释 fd 为什么能统一文件、pipe、socket
```

---

## 8. CMU 15-445 穿插路线

### 8.1 学习定位

15-445 是数据库 / 存储伴随线，后置到中间件阶段。

它服务的是：

```text
MySQL 原理
Mini Redis 深化
KVStore
存储引擎
B+ tree
buffer pool
transaction
concurrency control
recovery
```

现在不正式开，是因为你还需要先打好：

```text
C++
STL
Linux
OS
网络
Reactor
Mini Redis 网络层
```

---

### 8.2 建议开始时间

推荐从这个阶段开始：

```text
Mini Redis V1 前后
MySQL 原理学习前
大约 Week11 ~ Week12 后
```

不要一开始就追求完整刷完 project。

---

### 8.3 第一轮只看这些

```text
Database system overview
Storage hierarchy
Disk / page / tuple
Buffer pool
Hash table
B+ tree index
Query execution 了解
Transaction 了解
Concurrency control
Recovery / WAL
```

先不深挖：

```text
完整 query optimizer
复杂 SQL execution
全部 BusTub project
分布式数据库
高级事务理论
```

---

### 8.4 和主线的对应关系

```text
STL / 工程数据结构 → hash table / B+ tree
Linux IO / mmap / page cache → storage / buffer pool
MySQL 索引 → B+ tree
MySQL 事务 / MVCC → concurrency control
持久化 / AOF / WAL → recovery
Mini Redis / KVStore → storage system 思想
```

---

### 8.5 15-445 验收标准

第一轮只要求：

```text
能解释数据库为什么需要 buffer pool
能解释 page 是什么
能解释 B+ tree 为什么适合磁盘索引
能解释 hash index 和 B+ tree index 的区别
能解释 transaction 要解决什么问题
能解释 WAL 为什么能帮助恢复
能把 15-445 的概念挂到 MySQL / Mini KV / Mini Redis 上
```

---

## 9. 各模块详细路线

## 9.1 C/C++ 基础

学习内容：

```text
指针 / 引用 / const
const int* / int* const / const int* const
const reference
static
作用域
头文件 / 源文件
编译 / 链接
class / struct
构造函数 / 析构函数
this
const 成员函数
new / delete
new[] / delete[]
RAII 初步
```

学到什么程度：

```text
能解释对象生命周期
能解释栈对象和堆对象区别
能解释 new = 分配内存 + 构造对象
能解释 delete = 析构对象 + 释放内存
能解释为什么裸 new/delete 危险
```

---

## 9.2 C++11 / 现代 C++

学习内容：

```text
auto
nullptr
range-for
enum class
lambda
std::function
move 语义
右值引用
unique_ptr / shared_ptr / weak_ptr
thread / mutex / condition_variable
atomic
optional 初步
noexcept 初步
```

学到什么程度：

```text
会写现代 C++ 风格代码
不乱用裸指针拥有资源
能用 RAII 管资源
能用智能指针表达所有权
能写基本多线程程序
能解释 move 和 copy 的区别
```

---

## 9.3 C++ 对象模型 / 多态 / 内存布局

这个模块不是一开始学，但必须在智能指针和 STL 后补上。

学习内容：

```text
对象内存布局
成员变量布局
this 指针
成员函数不存进每个对象
虚函数
虚表 vtable
虚指针 vptr
动态绑定
虚析构函数
对象切片
多态
多继承了解即可
```

学到什么程度：

```text
能解释为什么基类析构函数常需要 virtual
能解释虚函数调用为什么有运行时分派
能解释对象切片是什么
能画出简单对象内存布局
```

---

## 9.4 异常安全

学习内容：

```text
异常传播时局部对象自动析构
RAII 和异常安全
基本异常安全
强异常安全
不抛异常保证
copy-and-swap
noexcept
move 构造为什么常写 noexcept
```

学到什么程度：

```text
知道异常时资源不能泄漏
能解释为什么 RAII 比手写 delete 更安全
能解释 vector 扩容时 move 如果不是 noexcept 可能影响行为
能写一个简单 copy-and-swap 赋值
```

---

---

### 9.4A C++ 学习细化：结合当前实际进度

这一小节是对 `cpp基础.md` 的吸收和细化，用来指导当前到 Week8 的 C++ 学习。核心原则不变：不是把 C++ 当考试科目刷语法，而是把它学成能支撑 Mini Redis、RPC、线程池、Reactor、AI Infra 底层服务的系统语言。

当前你的实际情况：

```text
中大计科大一
有 OI / ACM 背景，算法和写代码手感不差
当前主要短板不是“不会写程序”，而是工程化 C++、资源管理、Linux/OS/网络系统底座
已经完成 Day1 ~ Day5
正在 Day6：Buffer / StringLike 复盘资源管理
```

所以 C++ 部分的学习策略是：

```text
熟悉语法快速过
对象生命周期和资源管理必须写熟
现代 C++ 不追花活，只学工程项目会用的
STL 不只会调 API，要知道容器行为和工程含义
模板先够看懂常见泛型代码，不提前深挖元编程
并发必须落到 BlockingQueue / ThreadPool
性能意识和调试工具跟项目一起补
```

---

#### C++-0：当前阶段，C++ 对象和资源管理第一轮

对应阶段：Week1 + Week2 前半。

要学什么：

```text
指针 / 引用 / const
const int* / int* const / const int* const
class / struct
构造函数 / 析构函数
this 指针
const 成员函数
new / delete
new[] / delete[]
RAII
owning pointer
memory leak / dangling pointer / double delete
默认拷贝
浅拷贝 / 深拷贝
拷贝构造
拷贝赋值
self-assignment
Rule of Three
```

学到什么程度：

```text
能解释对象从构造到析构发生了什么
能解释栈对象和堆对象生命周期区别
能解释 new = 分配内存 + 构造对象
能解释 delete = 析构对象 + 释放内存
知道裸 owning pointer 为什么危险
看到类里有裸指针，能立刻想到拷贝控制问题
能画出浅拷贝两个指针指向同一块资源
能画出深拷贝两个对象拥有不同资源但内容相同
能写出 Buffer / StringLike 的 Rule of Three
能处理 self-assignment
能解释 operator= 为什么返回 T&
能用 ASan 初步检查 double free / use-after-free / leak
```

代码产出：

```text
01_buffer_no_copy.cpp：禁止拷贝版 Buffer
02_buffer_deep_copy.cpp：深拷贝版 Buffer
03_string_like.cpp：最小 StringLike，处理 size_ + 1 和 '\0'
04_review_questions.md：Day4 ~ Day6 资源管理复盘
```

验收问题：

```text
1. 为什么有析构函数的资源类通常要考虑 Rule of Three？
2. 拷贝构造和拷贝赋值的区别是什么？
3. 为什么 copy assignment 要判断 this == &other？
4. 为什么 copy assignment 推荐先 new 新资源，再 delete 旧资源？
5. data_ 是资源本身还是资源地址？真正资源在哪里？
6. StringLike 为什么要分配 size_ + 1 个 char？
7. '\0' 在 C 字符串里起什么作用？
8. ASan 能帮你抓哪些内存问题？
```

当前不要提前深挖：

```text
move constructor
move assignment
std::move 深入
copy-and-swap 完整版
allocator
placement new
SSO 小字符串优化
复杂模板
```

---

#### C++-1：移动语义、智能指针、异常安全初步

对应阶段：Week2。

要学什么：

```text
右值引用
std::move
移动构造
移动赋值
Rule of Five
unique_ptr
shared_ptr
weak_ptr 初步
异常传播时局部对象自动析构
RAII 和异常安全
noexcept 初步
copy-and-swap 初步
```

学到什么程度：

```text
能解释 copy 和 move 的区别
知道 std::move 本身不移动，只是把对象转成右值表达式
能写一个禁止拷贝、支持移动的 Buffer
默认优先用 unique_ptr 表达独占所有权
知道 shared_ptr 是共享所有权，不是“更安全的裸指针”
知道 weak_ptr 用来打破循环引用
知道异常发生时局部对象会自动析构
能解释为什么 RAII 比手写 delete 更安全
知道 move 构造常写 noexcept 的原因，先不深挖标准细节
```

代码产出：

```text
Buffer move-only 版本
unique_ptr 管理数组 / 对象 demo
shared_ptr / weak_ptr 循环引用小 demo
异常路径下 RAII 自动释放 demo
copy-and-swap 赋值小 demo
```

验收问题：

```text
1. std::move 到底做了什么？
2. 移动后对象还能不能析构？应该处于什么状态？
3. unique_ptr 为什么不能拷贝？
4. shared_ptr 的引用计数解决什么问题，又带来什么问题？
5. weak_ptr 为什么能解决循环引用？
6. 异常发生时 RAII 如何保证资源释放？
7. noexcept 和 vector 扩容时的 move 有什么关系？
```

暂时不深挖：

```text
完美转发
万能引用复杂规则
enable_shared_from_this
自定义 deleter 深入
allocator / memory_resource
复杂异常安全分类证明
```

---

#### C++-2：STL 和工程数据结构第一轮

对应阶段：Week3。

要学什么：

```text
vector：size / capacity / 扩容 / 连续内存
string：基本行为 / c_str / 拷贝和移动成本
map / set：有序结构，红黑树直觉
unordered_map / unordered_set：哈希表，冲突和 rehash
deque / queue / priority_queue
iterator 基本使用和失效场景
algorithm：sort / find / lower_bound / remove_if
optional 初步
pair / tuple 初步
```

学到什么程度：

```text
知道 vector 为什么扩容，扩容时元素会搬家
能解释迭代器失效为什么发生
能根据场景选择 vector / deque / list / map / unordered_map
知道 unordered_map 最坏情况会退化，不只背平均 O(1)
能把 STL 容器和系统项目场景对应起来
能用 STL 写可读的工程代码，不乱造轮子
```

工程映射：

```text
vector：连续内存、cache 友好、连接列表 / buffer 管理
unordered_map：KV 存储、连接 fd 到 Connection 的映射
map / set：有序任务、范围查询
priority_queue：定时器堆
deque / queue：任务队列雏形
string：协议解析、命令存储、日志文本
```

代码产出：

```text
vector 扩容观察 demo
迭代器失效 demo
unordered_map rehash demo
LRU Cache 简化版
RingBuffer 简化版
TimerHeap 简化版
```

验收问题：

```text
1. vector 的 size 和 capacity 区别是什么？
2. vector push_back 什么时候导致迭代器失效？
3. map 和 unordered_map 怎么选？
4. 为什么 Redis dict 类似 hash table？
5. 为什么 MySQL 索引不用普通 vector / hash table 解决所有问题？
6. 为什么定时器常用 heap？
```

暂时不深挖：

```text
STL allocator 实现
红黑树旋转细节
哈希表工业级实现
复杂模板技巧
ranges 深入
```

---

#### C++-3：对象模型、多态和内存布局

对应阶段：智能指针和 STL 后补，不放在 Week1 硬塞。

要学什么：

```text
对象内存布局
成员变量布局和对齐直觉
this 指针
成员函数不存进每个对象
虚函数
vtable / vptr
动态绑定
virtual 析构函数
对象切片
多态
多继承了解即可
```

学到什么程度：

```text
能解释为什么普通成员函数不增加每个对象大小
能解释虚函数为什么需要运行时分派
能解释为什么基类析构函数常要 virtual
能解释对象切片是什么
能画出简单单继承对象布局
知道多态适合接口抽象，但不要滥用继承
```

代码产出：

```text
sizeof 对象布局观察 demo
virtual / non-virtual 析构对比 demo
对象切片 demo
基类指针调用派生类函数 demo
```

验收问题：

```text
1. this 指针是什么？
2. 成员函数存在每个对象里吗？
3. vptr / vtable 大概是什么？
4. 为什么 delete Base* 指向 Derived 时，Base 析构通常要 virtual？
5. 对象切片怎么发生？
```

暂时不深挖：

```text
多继承复杂布局
虚继承
ABI 细节
手写 vtable 模拟器
```

---

#### C++-4：并发编程和基础组件

对应阶段：Week7 ~ Week8。

要学什么：

```text
std::thread
join / detach
mutex
lock_guard
unique_lock
condition_variable
producer-consumer
BlockingQueue
atomic 基础
CAS 初步
future / packaged_task 初步
```

学到什么程度：

```text
能解释 race condition
能解释锁保护的是共享状态，不是代码块本身
能写生产者消费者模型
能写 BlockingQueue
能写 ThreadPool V1
知道 condition_variable 为什么要配合 while 判断条件
知道 graceful shutdown 为什么重要
能用简单日志定位线程执行路径
```

代码产出：

```text
多线程计数器错误版 / 加锁版 / atomic 版
condition_variable wait/notify demo
BlockingQueue
ThreadPool V1
AsyncLogger V1
简单 benchmark
```

验收问题：

```text
1. 什么是数据竞争？
2. mutex 保护的是什么？
3. condition_variable 为什么可能虚假唤醒？
4. BlockingQueue 如何退出？
5. ThreadPool 析构时如何 graceful shutdown？
6. atomic 适合替代所有锁吗？
```

暂时不深挖：

```text
lock-free 队列
复杂内存序
协程
线程池工业级调度
work stealing
```

---

#### C++-5：工程化和性能意识

对应阶段：贯穿 Week2 之后，项目期加强。

要学什么：

```text
头文件 / 源文件拆分
CMake 初步
gdb 基本调试
ASan / valgrind 初步
日志定位
简单单元测试
const 引用传参 vs 值传参
copy / move 成本
cache locality 直觉
emplace vs push_back
```

学到什么程度：

```text
能把代码从单文件逐步拆成 .h / .cpp
能写最小 CMakeLists.txt
能用 gdb 看 backtrace / 变量
能用 ASan 检查内存错误
知道什么时候用 const T& 传参
知道什么时候值传递反而可以接受
能解释 vector 连续内存为什么 cache 友好
能在 README 写清构建、运行、测试方式
```

代码产出：

```text
Buffer / StringLike 拆分头文件和源文件
最小 CMake demo
gdb 调试一次段错误
ASan 检查一次 use-after-free / double-free
README：如何编译运行
```

验收问题：

```text
1. 头文件里放声明还是定义？
2. 为什么项目不能永远只有 main.cpp？
3. gdb backtrace 能帮你定位什么？
4. ASan 和 valgrind 大概检查什么？
5. const std::string& 和 std::string 值传递怎么选？
6. 为什么频繁 new/delete 可能影响性能？
```

暂时不深挖：

```text
大型 CMake 工程
clang-tidy 规则体系
perf / 火焰图深入
链接模型复杂细节
```

---

#### 当前 C++ 学习的阶段验收总表

```text
C++-0 资源管理：能不看答案写 Buffer / StringLike Rule of Three
C++-1 现代 C++：能写 move-only Buffer，能用 unique_ptr 表达所有权
C++-2 STL：能解释 vector / unordered_map 行为，并写 LRU / RingBuffer
C++-3 对象模型：能解释 virtual 析构、对象切片、简单对象布局
C++-4 并发：能写 BlockingQueue / ThreadPool V1
C++-5 工程化：能拆文件、用 CMake、用 gdb/ASan、写 README
```

这一整段 C++ 学习的最终目标不是“背完语法”，而是为这些系统项目铺底：

```text
BlockingQueue
ThreadPool
AsyncLogger
TCP Server
Epoll Server
Reactor
Mini Redis
RPC demo
```

## 9.5 Linux 系统编程

学习内容：

```text
fd
open / read / write / close
stat / lseek
dup / dup2
pipe
fork / exec / wait
signal 初步
mmap 初步
errno
blocking / non-blocking
strace / lsof / ss / top / htop
```

学到什么程度：

```text
知道用户态程序如何通过系统调用请求内核服务
能用 fd 理解文件、socket、pipe
能写简单 Linux 小工具
能用 strace 看程序调用了什么系统调用
```

---

## 9.6 OS 基础

学习内容：

```text
用户态 / 内核态
系统调用
进程 / 线程
上下文切换
调度
锁
条件变量
虚拟内存
页表
文件系统基础
IO 模型
fork / COW
mmap
页缓存了解
```

学到什么程度：

```text
能解释 fork / exec / wait
能解释线程和进程区别
能解释虚拟内存为什么存在
能解释锁为什么需要
能解释阻塞 IO 为什么阻塞
能解释 COW 大概是什么
```

资料：

```text
MIT 6.S081：核心 lecture + xv6 概念
OSTEP：概念补充和查漏
```

---

## 9.7 数据结构在工程里的应用

学习方式：不是重新刷算法，而是问“这个结构在系统里解决什么问题”。

重点：

```text
动态数组 vector：扩容、连续内存、cache 友好
hash table：快速查找、冲突、rehash
红黑树：有序 map / set，范围查询
skiplist：Redis zset
B+ tree：MySQL 索引
heap：定时器、优先队列
ringbuffer：网络 buffer、日志队列、生产者消费者
LRU：缓存淘汰
bitmap：状态压缩、布隆过滤器前置
Bloom Filter：快速判断不存在
```

产出：

```text
LRU Cache
RingBuffer
TimerHeap
HashTable 小实现或源码阅读笔记
```

---

## 9.8 必要设计模式

不学设计模式大全，只学项目会用的。

重点：

```text
RAII：资源管理核心
Singleton：只了解，少用
Factory：对象创建解耦
Observer / Callback：事件通知
Strategy：策略替换
Producer-Consumer：任务队列
Reactor：高性能网络核心结构
```

学到什么程度：

```text
能在项目里说清为什么这么组织代码
能避免把所有逻辑堆在 main.cpp
能写出 EventLoop / Channel / Connection 这种基本结构
```

---

## 9.9 C++ 基础组件

组件顺序：

```text
BlockingQueue
ThreadPool
AsyncLogger
RingBuffer
Timer
Logger
MemoryPool 初步
ConnectionPool 初步
Config Parser
```

每个组件都要有：

```text
代码
测试
README
设计图或文字说明
至少一个踩坑总结
面试追问：为什么这么设计，有什么缺陷，怎么优化
```

优先级：

```text
阻塞队列：必须
线程池：必须
异步日志：必须
定时器：必须
ringbuffer：建议
内存池：初步即可
连接池：和 MySQL 阶段结合
```

---

## 9.10 网络编程 / 高性能网络

学习内容：

```text
TCP / UDP / HTTP
socket API
阻塞 IO
非阻塞 IO
select / poll / epoll
LT / ET
Reactor
Connection 封装
Buffer 封装
HTTP Parser 初步
```

项目递进：

```text
TCP Echo Server
多客户端阻塞版 Server
select/poll 版 Server
epoll 版 Server
Reactor 版 Server
HTTP Server 初步
Mini Redis 网络层
```

学到什么程度：

```text
能解释 socket / bind / listen / accept / recv / send
能解释 epoll 为什么适合大量连接
能解释 Reactor 如何把 fd 事件分发到回调
能写一个可维护的 C++ 网络小框架
```

---

## 9.11 Redis / MySQL / Nginx / Kafka 中间件

### Redis

学习层次：

```text
第一层：会用 string / hash / list / set / zset / expire
第二层：懂 RESP、dict、skiplist、过期策略、淘汰策略、事件循环
第三层：了解 RDB / AOF、主从、哨兵、Cluster
```

项目：

```text
Mini Redis V1：RESP + SET/GET/DEL
Mini Redis V2：epoll/Reactor + 多客户端 + TTL
Mini Redis V3：LRU/LFU + 简单持久化 + benchmark + README
```

---

### MySQL

学习层次：

```text
会用：SQL、join、索引、事务、explain
懂原理：B+树、聚簇索引、二级索引、MVCC、undo/redo/binlog、隔离级别、锁
项目结合：连接池、慢查询、索引优化案例
```

---

### Nginx

学习层次：

```text
会配置反向代理
会配置负载均衡
理解 worker 进程模型
理解事件驱动大概原理
暂不深挖完整源码
```

---

### Kafka

学习层次：

```text
producer / consumer
topic / partition
consumer group
offset
broker
削峰填谷
异步解耦
```

不要求实现 Kafka，只要求能用、能讲。

---

## 9.12 测试 / 调试 / 性能分析

学习内容：

```text
gtest
Google Benchmark
valgrind
strace
gdb backtrace
core dump 初步
日志定位问题
perf 初步
火焰图后置
top / htop / ss / lsof
```

每个系统项目至少要有：

```text
单元测试
基本压测
QPS 结果
内存泄漏检查
性能瓶颈分析
问题定位记录
```

---

## 10. 项目线

### 项目线 A：C++ 系统项目线，主线

```text
BlockingQueue
→ ThreadPool
→ AsyncLogger
→ TCP Echo Server
→ Epoll Server
→ Reactor
→ HTTP Server 初步
→ Mini Redis
```

这是 2027 实习前最核心的项目线。

---

### 项目线 B：工程组件线

```text
RingBuffer
Timer
Logger
MemoryPool 初步
ConnectionPool
Config Parser
```

这些组件为系统项目服务，不单独为了写而写。

---

### 项目线 C：中间件理解线

```text
Redis 原理
MySQL 原理
Nginx 基础
Kafka 基础
CMU 15-445 选学
```

目标不是实现所有中间件，而是能在项目和面试中讲清核心机制。

---

### 项目线 D：OS 伴随线

```text
MIT 6.S081 核心 lecture
Linux demo 验证
fork / COW / mmap / syscall / trap / page table 笔记
```

目标是让你的 OS 知识不是背八股，而是能和代码、系统调用、项目连接起来。

---

### 项目线 E：分布式 / 云原生线，后置

```text
Raft demo
Mini KV
Docker 镜像化
K8s 部署
Prometheus 监控
```

---

### 项目线 F：AI Infra 线，2028 主线

```text
PyTorch 小训练
Transformer 推理理解
Mini LLM Serving
KV Cache / batch scheduler
CUDA 优化
```

---

## 11. 简历项目目标

### 2027 实习前理想项目组合

```text
主项目：Mini Redis（C++）
副项目：C++ Reactor / HTTP Server / ThreadPool / AsyncLogger
辅助：MySQL 连接池 / Nginx 代理 / RPC demo / benchmark / gtest / valgrind / strace
伴随能力：6.S081 支撑 OS 面试，15-445 支撑数据库/存储面试
```

---

### Mini Redis 简历表述目标

不要写：

```text
实现了一个 Redis。
```

而是写成：

```text
基于 C++ 实现轻量级内存 KV 服务，支持 RESP 协议解析、epoll 事件驱动、多客户端连接、TTL 过期机制、LRU 淘汰策略、简单持久化与 benchmark 压测。
```

---

### 面试主线

```text
C++：对象生命周期、RAII、拷贝/移动、智能指针、STL、异常安全、虚函数表
Linux：fd、系统调用、进程、线程、IO、mmap
OS：虚拟内存、调度、锁、COW、文件系统基础
网络：TCP、HTTP、socket、epoll、Reactor
并发：mutex、condition_variable、atomic、CAS、线程池、阻塞队列
Redis：数据结构、过期、淘汰、持久化、事件循环
MySQL / DB：索引、B+树、buffer pool、事务、MVCC、锁、WAL
项目：架构设计、并发模型、生产级代码、性能数据、踩坑复盘、线上排查
```

---

## 12. 面试驱动长期任务

### 12.1 每周少量手撕题

你有 OI 背景，不需要现在大量刷题，但手感不能断。

节奏：

```text
每周 2~3 题
写成可运行代码
补边界测试
说明复杂度
```

优先题型：

```text
链表
栈 / 队列
哈希
二分
滑动窗口
DFS / BFS
TopK
LRU
字符串处理
简单动态规划
```

---

### 12.2 每个项目必须有面试讲稿

每个项目都要能按这个结构讲：

```text
背景：为什么做这个项目
职责：我实现了哪些模块
架构：整体模块怎么拆
难点：最难的点是什么
取舍：为什么这么设计
验证：如何测试和压测
问题：遇到什么 bug，如何定位
优化：还能怎么优化
```

项目 README 至少包含：

```text
项目简介
功能列表
架构图
构建方式
使用示例
测试方式
压测结果
踩坑总结
后续优化
```

---

### 12.3 每个工具都要服务排查

工具不是为了“学过”，而是为了回答：

```text
程序卡住了怎么查？
内存泄漏怎么查？
服务端口没起来怎么查？
QPS 上不去怎么查？
线程死锁怎么查？
崩溃 core 怎么看？
```

对应工具：

```text
gdb：断点、变量、调用栈、core dump
strace：系统调用
valgrind：内存泄漏
ss / lsof：端口和 fd
top / htop：进程资源
日志：定位执行路径
benchmark：性能数据
```

---

## 13. 资料池

### C++

```text
LearnCpp：适合系统补现代 C++ 和语法细节
cppreference：适合查标准库和语言规则
C++ Primer：可作为书本补充，不要求从头硬啃
Effective Modern C++：现代 C++ 后期补充
```

---

### Linux / OS

```text
MIT 6.S081：理解 OS 和 xv6
OSTEP：理解进程、虚拟内存、并发、持久化
Linux man-pages：查系统调用和库函数
The Linux Programming Interface：后期系统编程参考书
```

6.S081 使用原则：

```text
先看核心 lecture
先做概念笔记
配合 Linux demo 理解
不急着全刷 lab
```

---

### 数据库 / 存储

```text
CMU 15-445：数据库系统和存储系统核心课
MySQL 官方文档：查 SQL / 索引 / 事务
Redis 文档：查命令和行为
```

15-445 使用原则：

```text
后置到 Mini Redis / MySQL 阶段
先看 storage / buffer pool / B+ tree / transaction / recovery
不急着全刷 BusTub project
```

---

### 网络 / 系统项目

```text
Beej's Guide：socket 入门可参考
UNP：后期网络编程参考，不要求现在硬啃
muduo：Reactor 设计可选读
Redis 源码：Mini Redis 后期选读
Nginx 文档：配置和反向代理
```

---

### 测试 / 性能

```text
gtest
google/benchmark
valgrind
strace
perf
```

---

### 面试

```text
牛客 C++ / Infra / AI Infra 面经：只用于反推考点，不沉迷刷面经
200 篇面经雷达：每周抽样，不逐篇背
自己的项目 README 和讲稿：比背八股更重要
手撕题：每周少量保持手感
```

资料使用原则：

```text
先以每日 .md 为主线
资料只作为查漏补缺
不要被资料海淹没
每学一个模块都要有代码产出
```

---

## 14. 每周执行格式

以后每周计划都按这个格式：

```text
本周目标：
本周学什么：
学到什么程度：
代码产出：
笔记产出：
验收问题：
和找工作关系：
6.S081 / 15-445 是否穿插：
下周衔接：
```

每周末你给我：

```text
1. 本周代码
2. 本周笔记
3. 本周总结
4. 卡住的问题
5. 自己回答验收问题
6. 本周面经雷达：抽样 5~10 篇，列出下周要补的问题
```

我来做：

```text
代码 review
笔记纠错
概念追问
面试追问
下周计划调整
```

---

## 15. 每日 .md 生成规则

当你让我生成某一天的 `.md` 时，我会默认结合：

```text
1. 当前 plan.md
2. 本周 week plan
3. 你前一天的 note / 总结 / 验收题
4. 你暴露出的薄弱点
5. 你已经会的内容
6. 项目路线和找工作价值
7. 真实面试高频点
8. 当前是否适合穿插 6.S081 / 15-445
```

每天 `.md` 默认包含：

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

不会机械使用 `What / Why / How` 标题，但会自然覆盖“这是啥、为什么、怎么用、什么时候用”。

---

## 16. 长期停止清单

看到这些内容，不是不学，而是暂时不优先：

```text
完整 C++ 模板元编程
复杂 SFINAE / concepts 深挖
操作系统内核源码全读
DPDK
io_uring 深入
完整 Nginx 源码
完整 Redis 源码逐行读
Ceph / TiDB 工业级源码
CUDA 过早深入
论文海量阅读
MIT 6.S081 全 lab 强刷
CMU 15-445 全 project 强刷
```

判断标准：

```text
如果它不能服务于当前 C++ 主线、系统项目、实习准备，就先放下。
```

---

## 17. 最后总纲

你现在真正要打穿的是：

```text
C++ 对象和资源管理
→ 拷贝/移动/智能指针/异常安全
→ STL 行为和工程数据结构
→ Linux 系统调用
→ OS 进程线程和 IO
→ MIT 6.S081 核心概念加固
→ TCP / HTTP / epoll
→ 阻塞队列 / 线程池 / 异步日志
→ Reactor
→ Mini Redis
→ Redis / MySQL / Nginx / Kafka 原理
→ RPC / 协议设计初步
→ CMU 15-445 数据库/存储概念加固
→ 测试 / 调试 / 性能分析
→ 项目讲稿和面试追问
→ 分布式 / 云原生
→ AI Infra
```

这条线走通，你的简历会从“会写代码”变成：

```text
懂 C++ 底层
懂 Linux 和 OS
懂网络和高性能服务端
懂数据库/存储系统基本原理
能写有技术密度的系统项目
能用数据和工具证明项目质量
能往基础架构和 AI Infra 延伸
```

这就是接下来所有 week plan 和 daily .md 的总依据。
