# 新总规划：AI Infra / 基础架构方向学习路线（加入网络原理与中间件版）

> 版本定位：在原路线 **C++ → Linux → OS → 网络 → Go 并发 → 系统项目 → 分布式 → 云原生 → ML/DL → Transformer → AI Infra → CUDA** 不变的基础上，补上更完整的网络原理、中间件、性能分析和工程项目链路。  
> 核心原则：不是把所有课表都学完，而是把对找实习、写项目、面试和 AI Infra 有用的内容按优先级吃掉。

---

## 0. 一句话总纲

你的新路线不是改方向，而是把原路线补完整：

```text
C++ 工程基础
→ Linux 工具链 / OS
→ 网络原理 / 高性能网络编程
→ Redis / MySQL / Kafka / Nginx 中间件
→ Mini Redis / RPC / Mini KV 等系统项目
→ Docker / K8s / 分布式系统
→ ML / DL / Transformer
→ LLM Serving / vLLM / CUDA / AI Infra
```

注意：**网络、中间件、分布式、云原生、AI Infra 都要学，但不是现在一起学。**

---

## 1. 新增内容怎么放进原规划

你发的截图大概可以分成这些板块：

```text
1. 精进基石：数据结构、设计模式、C++ 新特性、Linux 工具链
2. 高性能网络：select/poll/epoll、Reactor、HTTP Server、协程、io_uring、DPDK
3. 基础组件：线程池、内存池、连接池、CAS、无锁队列、定时器、protobuf、日志
4. 中间件：Redis、MySQL、Kafka、gRPC、Nginx
5. 开源框架：Skynet、OpenResty、CUDA、Workflow、MQTT、ZeroMQ
6. 云原生：Docker、Kubernetes
7. 性能分析：gtest、benchmark、火焰图、BPF/eBPF、内核观测
8. 分布式架构：RocksDB、TiDB、Ceph、etcd、Prometheus、P2P
9~11. 上线产品项目：KVStore、RPC、WAF、Firewall、存储系统等
```

我们不照单全收，而是分优先级。

---

## 2. 优先级分层

### P0：现在必须进入主线的内容

这些和你 2027 找实习、系统项目、C++ 面试直接相关：

```text
Modern C++
Linux 工具链：git / gdb / cmake / make / ssh / strace
操作系统：进程、线程、锁、虚拟内存、IO 模型
网络原理：TCP / UDP / HTTP / DNS / Socket
高性能 IO：select / poll / epoll
Reactor 模型
线程池
内存池初步
Redis 基础原理
MySQL 基础原理
Go 并发
```

### P1：2026.10 退役后重点推进

这些用于把项目做深，让简历能打：

```text
Mini Redis
TCP Server
Epoll Server
Reactor
HTTP Server 初步
benchmark / 压测
gtest / 单元测试
日志系统 spdlog
protobuf / gRPC
MySQL 连接池
Redis 协议与数据结构
MySQL 索引、事务、MVCC、锁
Nginx 基础：反向代理、负载均衡、配置
Kafka 基础：topic、partition、producer、consumer、consumer group
```

### P2：2027 下半年之后进入

这些属于分布式和平台能力：

```text
Docker
Kubernetes
Raft
etcd
Prometheus
Kafka 深入
Nginx 模块原理
RocksDB / LSM Tree
分布式 KV
分布式监控
```

### P3：先不要碰，后面看方向选修

这些很有价值，但现在学会严重分散主线：

```text
DPDK
io_uring 深入
Windows IOCP
Skynet
OpenResty WAF
Firewall / netfilter
Ceph
TiDB
FUSE
P2P
MQTT
ZeroMQ
游戏服务器框架
完整 Nginx 源码模块开发
```

结论：不是它们不重要，而是现在不适合你优先学。你现在最重要的是把 C++ / OS / 网络 / Redis / MySQL / RPC 项目打穿。

---

## 3. 阶段路线总览

| 阶段 | 时间 | 主目标 | 关键词 |
|---|---|---|---|
| 阶段 0 | 现在第一周 | 环境和学习系统跑起来 | VMware Ubuntu、VS Code SSH、g++、gdb、cmake、git |
| 阶段 1 | 现在 ~ 2026.10 | ACM 主线 + 工程底座 | C++、OS、网络、Go 并发 |
| 阶段 2 | 2026.10 ~ 2027.1 | C++ 系统编程入门项目 | 线程池、TCP Server、epoll、Reactor |
| 阶段 3 | 2027.1 ~ 2027.4 | 中间件项目主线 | Mini Redis、Redis/MySQL、benchmark |
| 阶段 4 | 2027.4 ~ 2027.6 | 实习投递准备 | RPC Framework、简历、面试、项目打磨 |
| 阶段 5 | 2027 暑假 | 第一份实习 | 基础架构 / 后端基础架构 / 云平台 |
| 阶段 6 | 2027.7 ~ 2028.1 | 分布式与云原生 | Raft、Mini KV、Docker、K8s |
| 阶段 7 | 2028 | AI Infra 主线 | ML/DL、Transformer、LLM Serving、CUDA |

---

# 阶段 0：Day1 ~ 第一周

## 目标

把学习工地搭好，开始进入稳定产出节奏。

## 学什么

```text
VMware Ubuntu
Windows VS Code Remote SSH
g++ / gdb / cmake / make / git
Go 环境
system-learning 仓库
```

## 产出

```text
day1 环境搭建完成
hello-gpp
hello-cmake
hello-go
第一次 git commit
```

## 学到什么程度

不用深挖 CMake / gdb / Makefile。只要能做到：

```text
会编译
会运行
会 gdb 跑一次
会 cmake 构建一次
会 git commit
```

---

# 阶段 1：现在 ~ 2026.10

## 阶段定位

这阶段你还在打 ACM，所以不能把工程学习排成全职。

建议时间分配：

```text
ACM：70%
工程基础：30%
```

工程这 30% 要非常克制，只学最核心的底座。

---

## 1.1 C++ 工程基础

### 学什么

```text
指针 / 引用 / const / static
class / struct
构造 / 析构
拷贝构造 / 拷贝赋值
移动构造 / 移动赋值
RAII
智能指针
STL：vector / map / unordered_map / string
lambda
function / bind
thread / mutex / condition_variable
atomic 基础
```

### 学到什么程度

```text
能解释对象生命周期
能避免裸 new/delete 乱飞
能写 RAII 风格代码
能用智能指针管理资源
能写简单多线程代码
能看懂常见 C++ 面试题
```

### 典型问题

```text
1. 引用和指针区别是什么？
2. const int* 和 int* const 区别是什么？
3. 构造函数和析构函数什么时候调用？
4. 为什么 new[] 要配 delete[]？
5. RAII 解决了什么问题？
6. unique_ptr 和 shared_ptr 区别是什么？
7. move 语义解决什么问题？
```

---

## 1.2 Linux 工具链

### 学什么

```text
git
gdb
cmake
make
ssh
strace 初步
top / htop
ps
ss
lsof
```

### 学到什么程度

```text
会用 git 管理项目
会用 gdb 看变量、打断点、看调用栈
会写最简单 CMakeLists.txt
会用 ss 看端口
会用 htop 看进程
知道 strace 是看系统调用的
```

### 暂时不深挖

```text
复杂 Makefile
configure 原理
多线程 gdb
core dump 深入
perf
BPF/eBPF
火焰图
```

---

## 1.3 OS 主线

### 学什么

```text
user mode / kernel mode
system call
process / thread
context switch
lock
virtual memory
page table
file descriptor
IO model
```

### 推荐资料

```text
MIT 6.S081：听核心课，不急着全刷 lab
OSTEP：查概念
```

### 学到什么程度

```text
能讲清 fork / exec / wait
能讲清 fd 是什么
能理解线程和进程区别
能理解锁为什么需要
能理解虚拟内存为什么存在
能理解 IO 为什么会阻塞
```

---

## 1.4 网络原理

这是新规划里要明确补上的部分。

### 学什么

```text
TCP / UDP
三次握手 / 四次挥手
TIME_WAIT / CLOSE_WAIT
滑动窗口
拥塞控制大概思想
粘包 / 半包
HTTP 请求响应
DNS
Socket API
阻塞 / 非阻塞 IO
select / poll / epoll 的基本区别
```

### 学到什么程度

现在不要追求“网络专家”，而是达到：

```text
能写 TCP echo server
能解释 TCP 为什么可靠
能解释 HTTP 基本格式
能解释 socket / bind / listen / accept / recv / send
知道 epoll 是为了解决大量连接事件管理
```

### 暂时不深挖

```text
DPDK
QUIC 深入
io_uring
TCP 内核源码
协议栈实现
```

---

## 1.5 Go 并发

### 学什么

```text
goroutine
channel
sync.Mutex
sync.WaitGroup
context
select
GMP 概念
```

### 学到什么程度

```text
能写并发任务处理
能用 context 控制超时/取消
能解释 goroutine 为什么轻量
能知道 channel 不只是队列，还有同步语义
```

---

## 阶段 1 产出

```text
1. C++ week1~weekN 小代码
2. 6.S081 核心笔记
3. 网络基础笔记
4. Go 并发小 demo
5. 每周一次总结
```

这阶段不要求大项目。你只需要把工程底座一点点铺起来。

---

# 阶段 2：2026.10 ~ 2027.1

## 阶段定位

ACM 退役后，正式从 ACM 选手转成系统工程候选人。这阶段目标是写出系统项目的前置组件。

---

## 2.1 Thread Pool

### 学什么

```text
std::thread
mutex
condition_variable
task queue
worker threads
graceful shutdown
```

### 项目要求

写一个 C++ 线程池：

```text
能提交任务
多个 worker 能并发执行
支持停止
无明显死锁
有简单测试
```

### 面试问题

```text
1. 线程池解决什么问题？
2. 任务队列怎么保护？
3. condition_variable 为什么要配合 while？
4. 如何优雅停止线程池？
5. 线程池大小怎么设置？
```

---

## 2.2 TCP Echo Server

### 学什么

```text
socket
bind
listen
accept
recv
send
close
阻塞 IO
多客户端处理
```

### 项目要求

```text
能启动 server
client 连接后发什么回什么
支持多个 client
能用 ss -lntp 查看监听端口
```

---

## 2.3 Epoll Server

### 学什么

```text
select / poll / epoll
fd
事件驱动
LT / ET 基础
非阻塞 IO
```

### 项目要求

```text
单线程管理多个连接
使用 epoll_wait
支持多客户端
能解释为什么 epoll 适合大量连接
```

---

## 2.4 Reactor

### 学什么

```text
EventLoop
Channel
Acceptor
Connection
Callback
```

### 项目要求

把 epoll server 组织成一个小 Reactor 框架。

你不用一开始写成 muduo，但要有基本结构：

```text
EventLoop 管事件循环
Channel 封装 fd 和事件
Acceptor 负责新连接
Connection 负责读写
```

---

# 阶段 3：2027.1 ~ 2027.4

## 阶段定位

进入中间件主线。这阶段最重要的项目是 **Mini Redis**。

---

## 3.1 Redis 学习路线

### 第一层：会用

```text
string
hash
list
set
zset
expire
publish / subscribe 了解
```

### 第二层：懂原理

```text
RESP 协议
dict / hash table
跳表 skiplist
过期删除策略
内存淘汰策略 LRU / LFU
单线程事件循环
持久化 RDB / AOF 概念
```

### 第三层：高级部分后置

```text
主从复制
Sentinel
Cluster
Lua
事务
Redis ACID 分析
```

这些不急着全做，面试前要会讲。

---

## 3.2 Mini Redis 项目

### V1：能跑

```text
TCP Server
RESP 协议解析
SET / GET / DEL
内存 KV 存储
CLI 或 nc/telnet 可测试
README
```

### V2：像一个服务

```text
epoll / Reactor
多客户端
EXPIRE / TTL
Hash 或 List
日志
简单配置文件
```

### V3：能写简历

```text
LRU / LFU
简单持久化
benchmark
gtest
压测结果
架构图
项目难点总结
```

### 简历写法目标

不是写“实现了一个 Redis”，而是写：

```text
基于 C++ 实现轻量级内存 KV 服务，支持 RESP 协议解析、epoll 事件驱动、多客户端连接、TTL 过期机制、LRU 淘汰策略、简单持久化与 benchmark 压测。
```

---

## 3.3 MySQL 学习路线

### 第一层：会用

```text
SQL CRUD
join
索引
事务
explain
```

### 第二层：懂原理

```text
B+ 树
聚簇索引 / 二级索引
最左匹配
覆盖索引
MVCC
undo log / redo log / binlog
事务隔离级别
行锁 / 间隙锁 / next-key lock
```

### 第三层：和项目结合

```text
MySQL 连接池
慢查询分析
索引优化
事务问题分析
```

### 目标

你不用变 DBA。你要达到后端 / infra 面试能讲清：

```text
为什么索引能加速查询
为什么 B+ 树适合数据库
MVCC 解决什么问题
可重复读怎么实现
什么情况下索引失效
```

---

## 3.4 测试与性能分析初步

### 学什么

```text
gtest
简单 benchmark
time
top / htop
ss
strace
valgrind 初步
```

### 目标

Mini Redis 不是“我本地跑通了”就结束。至少要有：

```text
单元测试
基本压测
QPS 结果
内存泄漏检查
```

---

# 阶段 4：2027.4 ~ 2027.6

## 阶段定位

开始实习投递准备。这阶段目标不是继续无限学新东西，而是把已有项目打磨到能投递。

---

## 4.1 RPC Framework（Go）

### 学什么

```text
protobuf
gRPC
net/rpc 思想
服务注册
服务发现
超时
重试
连接管理
日志
指标
```

### 项目要求

```text
能定义服务
client 像调用本地函数一样调用远程服务
支持超时控制
支持简单服务注册/发现
有 demo
有 README
```

---

## 4.2 Kafka 基础

### 学什么

```text
producer
consumer
topic
partition
consumer group
offset
broker
发布订阅
削峰填谷
异步解耦
```

### 学到什么程度

2027 实习前不需要你实现 Kafka。你只要能回答：

```text
Kafka 解决什么问题？
为什么要 partition？
consumer group 是什么？
offset 是什么？
Kafka 为什么吞吐高？
```

### 和项目结合

可以在 RPC / Web 服务 demo 里接一个简单 Kafka：

```text
请求进入服务
异步写入消息队列
后台 worker 消费
```

---

## 4.3 Nginx 基础

### 学什么

```text
反向代理
负载均衡
静态文件服务
upstream
location
worker 进程模型
事件驱动大概原理
```

### 学到什么程度

能用 Nginx 把你的服务代理出去：

```text
client → nginx → rpc/http server
```

能讲清：

```text
反向代理是什么
负载均衡是什么
Nginx 为什么适合高并发
```

不要现在深挖完整 Nginx 源码。

---

## 4.4 简历与面试准备

### 项目组合

到 2027.6，比较理想的组合是：

```text
主项目：Mini Redis（C++）
副项目：RPC Framework（Go）
辅助 demo：Nginx + Kafka + MySQL/Redis 组合部署
```

### 面试主线

```text
C++ 对象生命周期 / RAII / 智能指针 / STL
OS 进程线程 / 锁 / 虚拟内存 / IO
网络 TCP / HTTP / epoll / Reactor
Redis 数据结构 / 过期 / 淘汰 / 持久化
MySQL 索引 / 事务 / MVCC / 锁
Go 并发 / context / channel
项目设计与压测
```

---

# 阶段 5：2027 暑假实习

## 投递方向

不要只投 AI Infra。

优先级：

```text
1. AI Infra / LLM Serving / 推理平台
2. 基础架构
3. 云平台
4. 中间件 / 存储 / 数据库内核周边
5. C++ 后端 / Go 后端
```

第一份实习最重要的是进入技术密度高的团队。

---

# 阶段 6：2027.7 ~ 2028.1

## 阶段定位

从服务端工程进入分布式系统和云原生。

---

## 6.1 分布式理论

### 学什么

```text
Raft
CAP
一致性哈希
Gossip
WAL
Snapshot
Leader Election
Log Replication
```

### 项目：Mini KV

参考 etcd 的简化思想：

```text
Leader 选举
日志复制
WAL
Snapshot
简单 KV API
```

不用一开始做成工业级。重点是能讲分布式状态复制和一致性。

---

## 6.2 Docker / Kubernetes

### Docker

```text
image
container
Dockerfile
volume
network
docker compose
namespace / cgroup 概念
```

### Kubernetes

```text
Pod
Deployment
Service
Ingress
ConfigMap
Secret
kubectl
yaml
```

### 学到什么程度

能把自己的服务部署起来：

```text
Mini Redis / RPC 服务
→ Docker 镜像
→ docker compose
→ k8s deployment + service
```

---

## 6.3 Prometheus / 监控

### 学什么

```text
metric
counter
gauge
histogram
PromQL 基础
exporter
Grafana
```

### 目标

给你的服务加监控：

```text
请求数
错误数
延迟
连接数
内存占用
```

---

# 阶段 7：2028 AI Infra 主线

## 7.1 ML / DL 基础

### ML

```text
监督 / 无监督
训练 / 验证 / 测试
损失函数
梯度下降
过拟合 / 欠拟合
正则化
线性回归 / 逻辑回归 / 决策树
```

### DL

```text
神经网络
前向传播 / 反向传播
激活函数
SGD / Adam
BatchNorm / LayerNorm
Dropout
Attention
```

### PyTorch

```text
tensor
autograd
module
dataloader
optimizer
loss
train / eval
checkpoint
```

---

## 7.2 Transformer / LLM Serving

### 学什么

```text
embedding
position encoding
attention
multi-head attention
FFN
LayerNorm
decoder-only
autoregressive generation
KV Cache
prefill / decode
batch scheduling
streaming output
```

### 项目：Mini LLM Serving

```text
HTTP API
请求队列
动态 batch
streaming 输出
KV cache 管理
超时 / 取消
简单监控
```

---

## 7.3 CUDA / 高性能计算

### 学什么

```text
kernel
thread / block / grid
shared memory
warp
memory coalescing
GEMM
FlashAttention 思想
```

### 项目方向

```text
Mini FlashAttention
vLLM 某模块阅读与小优化
LLM serving benchmark
```

这一步是加分项，不是 2027 实习前必须完成。

---

# 4 条长期项目线

## 项目线 A：C++ 系统项目线

```text
Thread Pool
→ TCP Echo Server
→ Epoll Server
→ Reactor
→ Mini Redis
```

这是你 2027 实习最核心的项目线。

---

## 项目线 B：Go 分布式服务线

```text
Go 并发 demo
→ RPC Framework
→ 服务注册发现
→ Kafka/Nginx/MySQL/Redis 组合 demo
```

这是你补 Go / 云原生 / 分布式工程感的项目线。

---

## 项目线 C：分布式系统线

```text
Raft demo
→ Mini KV
→ Docker/K8s 部署
→ Prometheus 监控
```

这是 2027 下半年以后冲基础架构更高层的项目线。

---

## 项目线 D：AI Infra 线

```text
PyTorch 小训练
→ Transformer 推理理解
→ Mini LLM Serving
→ KV Cache / batch scheduler
→ CUDA 优化
```

这是 2028 进入 AI Infra 的主线。

---

# 每周执行格式

以后每周都按这个格式推进：

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

你每周末给我：

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

# 现在最重要的 8 周

你现在先别被这张大图吓到。当前只执行前 8 周。

## Week 1

```text
VMware Ubuntu + VS Code SSH 环境
C++ 编译 / gdb / cmake / git
```

## Week 2

```text
C++ 指针 / 引用 / const
对象生命周期
构造 / 析构
new / delete
RAII 初步
```

## Week 3

```text
拷贝构造 / 拷贝赋值
move 语义
unique_ptr / shared_ptr / weak_ptr
```

## Week 4

```text
STL：vector / string / map / unordered_map
哈希表基本原理
红黑树只要求知道 map 底层和性质，不深挖证明
```

## Week 5

```text
6.S081：system call / fork / exec / wait / fd
整理 OS 第一阶段笔记
```

## Week 6

```text
网络原理第一轮：TCP / UDP / HTTP / socket
写 TCP client/server 小 demo
```

## Week 7

```text
Go 并发：goroutine / channel / sync / context
写 worker pool 小 demo
```

## Week 8

```text
C++ 线程：thread / mutex / condition_variable
写一个简化 Thread Pool 原型
```

这 8 周跑完，你才真正进入“工程底座已启动”的状态。

---

# 最后：这份新规划怎么理解

你发的培训班大纲内容很多，其中不少确实很有价值。但我们不能被它拖着学成“大杂烩”。

你的新策略是：

```text
先吸收它里面对你最有用的：
C++ / Linux / OS / 网络 / Redis / MySQL / Kafka / Nginx / RPC / Docker / K8s / 性能分析

暂时放下太重的：
DPDK / io_uring / Ceph / TiDB / OpenResty WAF / Firewall / Skynet / 完整源码级项目
```

你真正要打穿的是这条链：

```text
C++ + OS + 网络
→ 高性能服务端
→ Redis/MySQL/RPC 中间件项目
→ 分布式/云原生
→ AI Infra
```

这条链打穿，才对你的实习、简历、面试、未来 AI Infra 有最大收益。
