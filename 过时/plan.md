# plan.md：C++ 主线系统工程 / AI Infra 准备路线

> 版本：2026-07-05  
> 定位：去掉近期 Go 主线，先把 **C++ / Linux / OS / 网络 / 系统项目** 打硬。  
> 总目标：本科阶段拿到技术密度高的实习 / 工作机会，长期往基础架构、云平台、中间件、AI Infra 方向延展。

---

## 0. 当前决策

### 0.1 主线调整

现在先不把 Go 放进近期规划。Go 暂时降级为未来可选副线。

新的主线是：

```text
C/C++ 基础
→ C++11/现代 C++
→ Linux 系统编程
→ OS 基础
→ 数据结构在工程里的应用
→ 必要设计模式
→ C++ 基础组件
→ 网络编程 / 高性能网络
→ Redis / Nginx / MySQL / Kafka 等中间件
→ 性能分析 / 开源阅读 / 项目实战
→ 分布式 / 云原生
→ AI Infra
```

Go 的处理方式：

```text
近期不主动安排
不放进 Week1 ~ Week8
不作为每天 .md 的默认内容
等 C++ / Linux / OS / 网络主线稳定后，再评估是否作为副线补充
```

### 0.2 当前进度

```text
Day1：环境搭建，通过
Day2：指针 / 引用 / const，通过
Day3：class / struct / 构造函数 / 析构函数 / this / const 成员函数，通过
Day4：new / delete / RAII 初步，已生成，下一步执行
```

Day1 ~ Day3 的特点：你之前都接触过，所以推进快是正常的。后面仍然要保持“快速过熟悉内容，重点打磨薄弱点”的节奏。

---

## 1. 学习原则

### 1.1 每周有总规划，每天根据实际进度调整

每周先给一个 week plan，但每天生成 `.md` 时，不机械照搬周计划，而是综合：

```text
1. 本周总目标
2. 前一天实际完成情况
3. 笔记里暴露出的薄弱点
4. 当前最该补的知识
5. 和项目 / 找实习 / 长期方向的关系
```

也就是说，每天的 `.md` 是动态调整版，不是死课表。

### 1.2 讲解风格

以后讲知识点不机械使用 `What / Why / How` 这种标题。

更自然的结构是：

```text
先建立直觉
再给术语
再解释底层机制
再写代码验证
中途穿插检查问题
最后给验收题
```

术语要有，但不堆砌。比如：

```text
const int*：pointer to const int，指向常量的指针
int* const：const pointer to int，指针常量
const std::string&：reference to const std::string，常量引用 / const 引用
```

目标是：能和别人交流，也能真正理解代码。

### 1.3 代码和笔记习惯

```text
代码：默认放 Ubuntu 的 ~/code/system-learning
笔记：按自己的习惯存，不强制放 Ubuntu
提交：每个学习日尽量有一次 git commit
```

### 1.4 不追求“大而全”

我们不照培训班大纲全学一遍，而是按找实习、写项目、面试、AI Infra 的收益排序。

现在最重要的是：

```text
C++ 对象和资源管理
Linux 系统调用和工具链
OS 进程 / 线程 / 虚拟内存 / IO
网络 TCP / HTTP / socket / epoll
C++ 系统项目：线程池、Reactor、Mini Redis
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
```

---

## 2. 总路线图

### 阶段总览

| 阶段 | 时间 | 主目标 | 关键词 |
|---|---|---|---|
| 阶段 0 | 当前第一周 | 环境 + C++ 对象和内存基础 | g++、gdb、cmake、git、指针、引用、const、构造析构、new/delete、RAII |
| 阶段 1 | 当前 ~ 2026.10 | ACM 主线 + 工程底座 | 现代 C++、Linux 工具链、OS、网络基础 |
| 阶段 2 | 2026.10 ~ 2027.1 | C++ 系统编程入门项目 | 线程池、TCP Server、epoll、Reactor |
| 阶段 3 | 2027.1 ~ 2027.4 | 中间件项目主线 | Mini Redis、Redis 原理、MySQL 原理、benchmark、gtest |
| 阶段 4 | 2027.4 ~ 2027.6 | 实习投递准备 | 项目打磨、简历、面试、Nginx/Kafka 基础、性能数据 |
| 阶段 5 | 2027 暑假 | 第一份实习 | 基础架构、云平台、中间件、C++ 后端 |
| 阶段 6 | 2027.7 ~ 2028.1 | 分布式 / 云原生 | Raft、Mini KV、Docker、K8s、Prometheus |
| 阶段 7 | 2028 | AI Infra 主线 | ML/DL、Transformer、LLM Serving、CUDA |

---

## 3. 优先级分层

### P0：现在必须进入主线

```text
C++ 基础和现代 C++
Linux 工具链：git / gdb / cmake / make / ssh / strace
OS：进程、线程、锁、虚拟内存、fd、IO 模型
网络原理：TCP / UDP / HTTP / DNS / Socket
高性能 IO：select / poll / epoll
Reactor 模型
C++ 多线程：thread / mutex / condition_variable / atomic
RAII / 智能指针 / STL
```

### P1：退役后重点推进

```text
线程池
TCP Echo Server
Epoll Server
Reactor 框架
HTTP Server 初步
定时器
ringbuffer
内存池初步
连接池初步
日志系统
Mini Redis
Redis 协议和数据结构
MySQL 索引、事务、MVCC、锁
gtest / benchmark / valgrind / strace
```

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
```

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
```

---

## 4. 当前 8 周执行计划

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

产出：

```text
system-learning 仓库
Day1 ~ Day6 小代码
git commit 记录
每日至少一份简短总结
```

### Week 2：拷贝控制 + 移动语义 + 智能指针

目标：理解 C++ 对象复制、移动、资源所有权。

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
```

产出：

```text
手写 IntBuffer / StringLike
演示浅拷贝 double delete
修成深拷贝版本
修成禁止拷贝 + 支持 move 版本
unique_ptr 管理资源 demo
```

验收：

```text
能解释为什么有裸资源的类必须处理拷贝问题
能解释 unique_ptr 为什么不能拷贝但能 move
能解释 shared_ptr 的基本引用计数思想
```

### Week 3：STL + 工程数据结构第一轮

目标：把 STL 从“会用”升级到“知道工程含义”。

学习内容：

```text
vector 扩容
string 基本机制
map / set 与红黑树
unordered_map / unordered_set 与哈希表
迭代器失效
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
```

产出：

```text
vector 扩容观察 demo
unordered_map 哈希冲突 demo
简化 LRU Cache
简化 ringbuffer
```

### Week 4：Linux 系统编程第一轮

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
strace
lsof
ss
ps / top / htop
```

产出：

```text
mycat：读取文件并输出
copyfile：文件复制
pipe demo：父子进程通信
fork-exec demo
strace 观察系统调用笔记
```

### Week 5：OS 第一轮

目标：把 MIT 6.S081 / OSTEP 的核心概念和 Linux 编程对应起来。

学习内容：

```text
user mode / kernel mode
system call
process / thread
context switch
scheduler 基本思想
lock
virtual memory
page table
file descriptor
blocking IO
```

推荐节奏：

```text
6.S081：看核心 lecture，不急着全刷 lab
OSTEP：当作概念字典，查 process / virtual memory / concurrency
```

产出：

```text
system call 笔记
process / thread 对比笔记
fd 机制图
虚拟内存直觉图
```

### Week 6：网络原理第一轮

目标：能写 TCP client/server，并知道网络 API 背后在干什么。

学习内容：

```text
TCP / UDP
三次握手 / 四次挥手
TIME_WAIT / CLOSE_WAIT
可靠传输直觉
滑动窗口大概思想
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

产出：

```text
TCP echo server
TCP client
HTTP 请求文本解析 demo
用 ss 查看监听端口
用 nc/telnet 测试服务
```

### Week 7：C++ 多线程和同步

目标：为线程池和高性能服务端做准备。

学习内容：

```text
std::thread
join / detach
mutex
lock_guard
unique_lock
condition_variable
producer-consumer
atomic 基础
false sharing 了解即可
```

产出：

```text
多线程计数器 demo
生产者消费者队列
condition_variable wait/notify demo
atomic counter demo
```

### Week 8：线程池 + 测试 / benchmark 初步

目标：写出第一个真正有工程味的 C++ 基础组件。

学习内容：

```text
task queue
worker threads
condition_variable
future / packaged_task 初步
graceful shutdown
gtest 初步
benchmark 初步
```

产出：

```text
ThreadPool V1
单元测试
简单 benchmark
README：设计、接口、使用示例、踩坑
```

---

## 5. 各模块详细路线

## 5.1 C/C++ 基础

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

找工作关系：

```text
这是 C++ 面试最底层的地基，也是后面智能指针、STL、线程池、Reactor、Mini Redis 的前置知识。
```

---

## 5.2 C++11 / 现代 C++

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
```

学到什么程度：

```text
会写现代 C++ 风格代码
不乱用裸指针拥有资源
能用 RAII 管资源
能用智能指针表达所有权
能写基本多线程程序
```

---

## 5.3 Linux 系统编程

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

## 5.4 OS 基础

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
```

学到什么程度：

```text
能解释 fork / exec / wait
能解释线程和进程区别
能解释虚拟内存为什么存在
能解释锁为什么需要
能解释阻塞 IO 为什么阻塞
```

资料：

```text
MIT 6.S081：核心 lecture + xv6 概念
OSTEP：概念补充和查漏
```

---

## 5.5 数据结构在工程里的应用

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

## 5.6 必要设计模式

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

## 5.7 C++ 基础组件

组件顺序：

```text
ThreadPool
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
```

优先级：

```text
线程池：必须
定时器：必须
ringbuffer：建议
日志系统：建议
内存池：初步即可
连接池：和 MySQL 阶段结合
```

---

## 5.8 网络编程 / 高性能网络

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

## 5.9 Redis / MySQL / Nginx / Kafka 中间件

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

### MySQL

学习层次：

```text
会用：SQL、join、索引、事务、explain
懂原理：B+树、聚簇索引、二级索引、MVCC、undo/redo/binlog、隔离级别、锁
项目结合：连接池、慢查询、索引优化案例
```

### Nginx

学习层次：

```text
会配置反向代理
会配置负载均衡
理解 worker 进程模型
理解事件驱动大概原理
暂不深挖完整源码
```

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

## 5.10 性能分析 / 测试

学习内容：

```text
gtest
Google Benchmark
valgrind
strace
perf 初步
火焰图后置
top / htop / ss / lsof
```

Mini Redis 至少要有：

```text
单元测试
基本压测
QPS 结果
内存泄漏检查
性能瓶颈分析
```

---

## 6. 项目线

### 项目线 A：C++ 系统项目线，主线

```text
ThreadPool
→ TCP Echo Server
→ Epoll Server
→ Reactor
→ HTTP Server 初步
→ Mini Redis
```

这是 2027 实习前最核心的项目线。

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

### 项目线 C：中间件理解线

```text
Redis 原理
MySQL 原理
Nginx 基础
Kafka 基础
```

目标不是实现所有中间件，而是能在项目和面试中讲清核心机制。

### 项目线 D：分布式 / 云原生线，后置

```text
Raft demo
Mini KV
Docker 镜像化
K8s 部署
Prometheus 监控
```

### 项目线 E：AI Infra 线，2028 主线

```text
PyTorch 小训练
Transformer 推理理解
Mini LLM Serving
KV Cache / batch scheduler
CUDA 优化
```

---

## 7. 简历项目目标

### 2027 实习前理想项目组合

```text
主项目：Mini Redis（C++）
副项目：C++ Reactor / HTTP Server / ThreadPool
辅助：MySQL 连接池 / Nginx 代理 / benchmark / gtest / valgrind
```

### Mini Redis 简历表述目标

不要写：

```text
实现了一个 Redis。
```

而是写成：

```text
基于 C++ 实现轻量级内存 KV 服务，支持 RESP 协议解析、epoll 事件驱动、多客户端连接、TTL 过期机制、LRU 淘汰策略、简单持久化与 benchmark 压测。
```

### 面试主线

```text
C++：对象生命周期、RAII、智能指针、STL、移动语义
Linux：fd、系统调用、进程、线程、IO
OS：虚拟内存、调度、锁、文件系统基础
网络：TCP、HTTP、socket、epoll、Reactor
Redis：数据结构、过期、淘汰、持久化、事件循环
MySQL：索引、事务、MVCC、锁
项目：架构设计、并发模型、性能数据、踩坑复盘
```

---

## 8. 资料池

### C++

```text
LearnCpp：适合系统补现代 C++ 和语法细节
cppreference：适合查标准库和语言规则
C++ Primer：可作为书本补充，不要求从头硬啃
Effective Modern C++：现代 C++ 后期补充
```

### Linux / OS

```text
MIT 6.S081：理解 OS 和 xv6
OSTEP：理解进程、虚拟内存、并发、持久化
Linux man-pages：查系统调用和库函数
The Linux Programming Interface：后期系统编程参考书
```

### 网络 / 系统项目

```text
Beej's Guide：socket 入门可参考
UNP：后期网络编程参考，不要求现在硬啃
muduo：Reactor 设计可选读
Redis 源码：Mini Redis 后期选读
Nginx 文档：配置和反向代理
```

### 测试 / 性能

```text
gtest
google/benchmark
valgrind
strace
perf
```

资料使用原则：

```text
先以我给你的每日 .md 为主线
资料只作为查漏补缺
不要被资料海淹没
每学一个模块都要有代码产出
```

---

## 9. 每周执行格式

以后每周计划都按这个格式：

```text
本周目标：
本周学什么：
学到什么程度：
代码产出：
笔记产出：
验收问题：
和找工作关系：
下周衔接：
```

每周末你给我：

```text
1. 本周代码
2. 本周笔记
3. 本周总结
4. 卡住的问题
5. 自己回答验收问题
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

## 10. 每日 .md 生成规则

当你让我生成某一天的 `.md` 时，我会默认结合：

```text
1. 当前 plan.md
2. 本周 week plan
3. 你前一天的 note / 总结 / 验收题
4. 你暴露出的薄弱点
5. 你已经会的内容
6. 项目路线和找工作价值
```

每天 `.md` 默认包含：

```text
今日目标
前置回顾
核心概念和术语
代码练习
中途检查
不要提前深挖的内容
笔记要求
验收问题
git commit
下一天衔接
```

不会机械使用 `What / Why / How` 标题，但会自然覆盖“这是啥、为什么、怎么用、什么时候用”。

---

## 11. 长期停止清单

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
```

判断标准：

```text
如果它不能服务于当前 C++ 主线、系统项目、实习准备，就先放下。
```

---

## 12. 最后总纲

你现在真正要打穿的是：

```text
C++ 对象和资源管理
→ Linux 系统调用
→ OS 进程线程和 IO
→ TCP / HTTP / epoll
→ 线程池 / Reactor
→ Mini Redis
→ Redis / MySQL / Nginx / Kafka 原理
→ 性能分析
→ 分布式 / 云原生
→ AI Infra
```

这条线走通，你的简历会从“会写代码”变成：

```text
懂 C++ 底层
懂 Linux 和 OS
懂网络和高性能服务端
能写有技术密度的系统项目
能往基础架构和 AI Infra 延伸
```

这就是接下来所有 week plan 和 daily .md 的总依据。
