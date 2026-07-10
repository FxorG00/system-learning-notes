# 牛客近两年 C++ / Infra / AI Infra 面经整理（200 篇）

> 生成日期：2026-07-05
> 时间范围：2024-07-05 至 2026-07-05。
> 整理原则：优先保留能识别出大厂/知名技术公司、且岗位为 C++、基础架构、Infra、AI Infra、服务端/中间件/系统方向的面经；正文为复述式整理，不逐篇搬运原帖。

## 使用建议

- 不要逐篇背。把这份当作面试雷达：看高频问题反推你的 `plan_latest.md` 每周任务。
- 优先盯住：C++ 对象生命周期、RAII、拷贝/移动、智能指针、STL、Linux/OS、TCP/epoll、线程池、Redis/MySQL、项目深挖。
- 每周抽 10 篇同类面经，把不会回答的问题变成下一周的学习清单。

## 高频主题 Top 25

- 项目深挖：146 篇
- MySQL/数据库：94 篇
- 内存管理：79 篇
- 链表/树/图：76 篇
- TCP/UDP/HTTP：72 篇
- 生产级代码：72 篇
- 对象模型/虚函数：64 篇
- 线程/线程池：61 篇
- 进程/线程/调度：57 篇
- 智能指针：55 篇
- STL 容器：54 篇
- 二分/滑窗/TopK：54 篇
- Redis/缓存：53 篇
- 存储系统：53 篇
- 动态规划/字符串：52 篇
- fd/系统调用/IO：50 篇
- 性能压测：48 篇
- 锁/条件变量：44 篇
- LLM Serving：42 篇
- 分布式基础：37 篇
- 排查工具：36 篇
- 拷贝/移动语义：33 篇
- 缓存题：32 篇
- RAII：30 篇
- RPC/协议：29 篇

## 公司/组织出现频次 Top 20

- 字节：53 篇
- 腾讯：44 篇
- 百度：26 篇
- 华为：24 篇
- 美团：22 篇
- 阿里：17 篇
- OD：14 篇
- 快手：8 篇
- 蚂蚁：7 篇
- 拼多多：6 篇
- 网易：5 篇
- 滴滴：5 篇
- 米哈游：4 篇
- 小米：4 篇
- 中兴：3 篇
- 京东：3 篇
- WXG：3 篇
- 虾皮：3 篇
- 360：2 篇
- 大疆：2 篇

## 200 篇面经整理

### 001. [25 暑期实习&秋招面经](https://www.nowcoder.com/discuss/759208803077275648)

- 时间：2025-06-02
- 公司/组织：阿里 / 蚂蚁 / 腾讯
- 岗位/方向：AI Infra / 大模型基础设施，Infra / 基础架构，C++ 后端/服务端
- 轮次：一面 / 二面 / 三面 / 四面
- 作者认证：上海交通大学 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，Infra / 基础架构，C++ 后端/服务端，面试内容集中在 C++：RAII、拷贝/移动语义、智能指针、STL 容器、对象模型/虚函数、内存管理、模板/泛型、const/static/volatile；并发：线程/线程池、锁/条件变量、atomic/CAS；Linux/OS：进程/线程/调度、虚拟内存/mmap/COW、fd/系统调用/IO、排查工具；网络：TCP/UDP/HTTP、连接状态、epoll/Reactor、RPC/协议，并涉及 LRU/LFU 缓存、链表/树/图、TopK/堆/排序、二分/滑动窗口、动态规划/字符串。
- 面试内容整理：
  - C++：RAII、拷贝/移动语义、智能指针、STL 容器、对象模型/虚函数、内存管理、模板/泛型、const/static/volatile
  - 并发：线程/线程池、锁/条件变量、atomic/CAS
  - Linux/OS：进程/线程/调度、虚拟内存/mmap/COW、fd/系统调用/IO、排查工具
  - 网络：TCP/UDP/HTTP、连接状态、epoll/Reactor、RPC/协议
  - 中间件/分布式：Redis/缓存、MySQL/数据库、Kafka/消息队列、分布式基础、存储系统
  - AI Infra：LLM Serving、CUDA/GPU、Transformer/PyTorch
- 手撕/代码：LRU/LFU 缓存、链表/树/图、TopK/堆/排序、二分/滑动窗口、动态规划/字符串
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor

### 002. [2025春招实习面经汇总（已接阿里offer）](https://www.nowcoder.com/discuss/736868736837173248)

- 时间：2025-04-17
- 公司/组织：阿里 / 蚂蚁 / 字节
- 岗位/方向：AI Infra / 大模型基础设施，Infra / 基础架构，C++ 后端/服务端
- 轮次：笔试 / 一面 / 二面 / HR面
- 作者认证：Duke University 后端工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，Infra / 基础架构，C++ 后端/服务端，面试内容集中在 C++：智能指针、内存管理；并发：锁/条件变量；Linux/OS：进程/线程/调度、fd/系统调用/IO、排查工具；网络：TCP/UDP/HTTP，并涉及 LRU/LFU 缓存、链表/树/图、二分/滑动窗口、动态规划/字符串、手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：智能指针、内存管理
  - 并发：锁/条件变量
  - Linux/OS：进程/线程/调度、fd/系统调用/IO、排查工具
  - 网络：TCP/UDP/HTTP
  - 中间件/分布式：Redis/缓存、MySQL/数据库、分布式基础、存储系统
  - AI Infra：LLM Serving、CUDA/GPU、Transformer/PyTorch
- 手撕/代码：LRU/LFU 缓存、链表/树/图、二分/滑动窗口、动态规划/字符串、手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor

### 003. [竞赛党的25秋招投递历程与面经](https://www.nowcoder.com/discuss/636158171937030144)

- 时间：2024-09-18
- 公司/组织：科大讯飞 / 中兴
- 岗位/方向：AI Infra / 大模型基础设施，Infra / 基础架构，C++ 后端/服务端
- 轮次：一面 / 二面 / 三面 / HR面
- 作者认证：电子科技大学 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，Infra / 基础架构，C++ 后端/服务端，面试内容集中在 C++：对象模型/虚函数；并发：线程/线程池；Linux/OS：进程/线程/调度；网络：TCP/UDP/HTTP，并涉及 链表/树/图、TopK/堆/排序、二分/滑动窗口、动态规划/字符串、手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：对象模型/虚函数
  - 并发：线程/线程池
  - Linux/OS：进程/线程/调度
  - 网络：TCP/UDP/HTTP
  - 中间件/分布式：MySQL/数据库、存储系统
  - AI Infra：LLM Serving
- 手撕/代码：链表/树/图、TopK/堆/排序、二分/滑动窗口、动态规划/字符串、手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor

### 004. [百度提前批（直接开始二战） 高性能计算工程师一面面经](https://www.nowcoder.com/discuss/645703205451505664)

- 时间：2024-07-24
- 公司/组织：字节 / 百度
- 岗位/方向：AI Infra / 大模型基础设施，Infra / 基础架构，C++ 开发
- 轮次：一面
- 作者认证：北京邮电大学 算法工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，Infra / 基础架构，C++ 开发，面试内容集中在 C++：智能指针、异常安全；Linux/OS：fd/系统调用/IO；网络：RPC/协议；中间件/分布式：Redis/缓存、存储系统，并涉及 动态规划/字符串。
- 面试内容整理：
  - C++：智能指针、异常安全
  - Linux/OS：fd/系统调用/IO
  - 网络：RPC/协议
  - 中间件/分布式：Redis/缓存、存储系统
  - AI Infra：LLM Serving、CUDA/GPU、Transformer/PyTorch
  - 项目/工程：项目深挖、性能压测
- 手撕/代码：动态规划/字符串
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor；Mini Redis / MySQL / 分布式后置主线

### 005. [字节飞书后端面经 大模型应用](https://www.nowcoder.com/feed/main/detail/2274640)

- 时间：2024-07-08
- 公司/组织：阿里 / 字节 / 腾讯
- 岗位/方向：AI Infra / 大模型基础设施，Infra / 基础架构，C++ 后端/服务端
- 轮次：笔试 / 一面 / 二面
- 作者认证：字节跳动 后端开发
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，Infra / 基础架构，C++ 后端/服务端，面试内容集中在 C++：拷贝/移动语义、内存管理；并发：锁/条件变量、atomic/CAS；中间件/分布式：Redis/缓存、MySQL/数据库；AI Infra：LLM Serving，并涉及 LRU/LFU 缓存、TopK/堆/排序。
- 面试内容整理：
  - C++：拷贝/移动语义、内存管理
  - 并发：锁/条件变量、atomic/CAS
  - 中间件/分布式：Redis/缓存、MySQL/数据库
  - AI Infra：LLM Serving
  - 项目/工程：项目深挖
  - 手撕/算法：缓存题、二分/滑窗/TopK
- 手撕/代码：LRU/LFU 缓存、TopK/堆/排序
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Mini Redis / MySQL / 分布式后置主线；2028 AI Infra：推理、CUDA、LLM Serving 预热

### 006. [百度（光速入池了咱就是说）高性能计算二三面面经](https://www.nowcoder.com/discuss/650066190634692608)

- 时间：2024-08-05
- 公司/组织：百度
- 岗位/方向：AI Infra / 大模型基础设施，Infra / 基础架构，C++ 开发
- 轮次：二面 / 三面 / OC
- 作者认证：北京邮电大学 算法工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，Infra / 基础架构，C++ 开发，面试内容集中在 C++：智能指针、STL 容器、对象模型/虚函数；AI Infra：CUDA/GPU；项目/工程：项目深挖、性能压测；手撕/算法：二分/滑窗/TopK，并涉及 TopK/堆/排序。
- 面试内容整理：
  - C++：智能指针、STL 容器、对象模型/虚函数
  - AI Infra：CUDA/GPU
  - 项目/工程：项目深挖、性能压测
  - 手撕/算法：二分/滑窗/TopK
- 手撕/代码：TopK/堆/排序
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；2028 AI Infra：推理、CUDA、LLM Serving 预热；项目 README、压测、debug 和面试讲稿；每周 2-3 题保持手感

### 007. [携程 秋招 一面](https://www.nowcoder.com/feed/main/detail/2692991)

- 时间：2025-09-16
- 公司/组织：携程
- 岗位/方向：AI Infra / 大模型基础设施，Infra / 基础架构，C++ 开发
- 轮次：一面
- 作者认证：四平职业大学 Java
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，Infra / 基础架构，C++ 开发，面试内容集中在 C++：内存管理；并发：线程/线程池；AI Infra：LLM Serving；项目/工程：项目深挖，并涉及 链表/树/图。
- 面试内容整理：
  - C++：内存管理
  - 并发：线程/线程池
  - AI Infra：LLM Serving
  - 项目/工程：项目深挖
  - 手撕/算法：链表/树/图
- 手撕/代码：链表/树/图
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；2028 AI Infra：推理、CUDA、LLM Serving 预热；项目 README、压测、debug 和面试讲稿

### 008. [挑战美团最快速通记录！面经还愿。](https://www.nowcoder.com/discuss/664025961465200640)

- 时间：2024-09-13
- 公司/组织：美团
- 岗位/方向：AI Infra / 大模型基础设施，Infra / 基础架构，C++ 后端/服务端
- 轮次：一面 / 二面 / OC
- 作者认证：门头沟学院 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，Infra / 基础架构，C++ 后端/服务端，面试内容集中在 C++：拷贝/移动语义；并发：线程/线程池；Linux/OS：fd/系统调用/IO；网络：RPC/协议，并涉及 手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：拷贝/移动语义
  - 并发：线程/线程池
  - Linux/OS：fd/系统调用/IO
  - 网络：RPC/协议
  - AI Infra：CUDA/GPU、Transformer/PyTorch
  - 项目/工程：项目深挖、性能压测
- 手撕/代码：手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor

### 009. [网易Ai infra 校招面经](https://www.nowcoder.com/feed/main/detail/2796838)

- 时间：2026-02-28
- 公司/组织：网易
- 岗位/方向：AI Infra / 大模型基础设施，Infra / 基础架构，C++ 开发
- 轮次：OC
- 作者认证：门头沟学院 机器学习
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，Infra / 基础架构，C++ 开发，面试内容集中在 C++：拷贝/移动语义、智能指针、对象模型/虚函数、内存管理；并发：线程/线程池；中间件/分布式：存储系统；AI Infra：CUDA/GPU，并涉及 链表/树/图、TopK/堆/排序。
- 面试内容整理：
  - C++：拷贝/移动语义、智能指针、对象模型/虚函数、内存管理
  - 并发：线程/线程池
  - 中间件/分布式：存储系统
  - AI Infra：CUDA/GPU
  - 项目/工程：项目深挖、性能压测
  - 手撕/算法：链表/树/图、二分/滑窗/TopK
- 手撕/代码：链表/树/图、TopK/堆/排序
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Mini Redis / MySQL / 分布式后置主线；2028 AI Infra：推理、CUDA、LLM Serving 预热

### 010. [快手C++搜推部门一面](https://www.nowcoder.com/feed/main/detail/2678412)

- 时间：2025-09-02
- 公司/组织：快手
- 岗位/方向：AI Infra / 大模型基础设施，Infra / 基础架构，C++ 开发
- 轮次：一面
- 作者认证：门头沟学院 深度学习
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，Infra / 基础架构，C++ 开发，面试内容集中在 C++：智能指针、对象模型/虚函数；中间件/分布式：存储系统；AI Infra：LLM Serving。
- 面试内容整理：
  - C++：智能指针、对象模型/虚函数
  - 中间件/分布式：存储系统
  - AI Infra：LLM Serving
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Mini Redis / MySQL / 分布式后置主线；2028 AI Infra：推理、CUDA、LLM Serving 预热

### 011. [华为面经](https://www.nowcoder.com/feed/main/detail/2718792)

- 时间：2025-10-17
- 公司/组织：华为
- 岗位/方向：AI Infra / 大模型基础设施，Infra / 基础架构，C++ 开发
- 轮次：一面 / OC
- 作者认证：北京大学 产品经理
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，Infra / 基础架构，C++ 开发，面试内容集中在 Linux/OS：排查工具；中间件/分布式：存储系统；项目/工程：项目深挖、性能压测；手撕/算法：链表/树/图、二分/滑窗/TopK，并涉及 链表/树/图、TopK/堆/排序。
- 面试内容整理：
  - Linux/OS：排查工具
  - 中间件/分布式：存储系统
  - 项目/工程：项目深挖、性能压测
  - 手撕/算法：链表/树/图、二分/滑窗/TopK
- 手撕/代码：链表/树/图、TopK/堆/排序
- 对你规划的用处：Week4-5：Linux 系统编程与 OS 基础；Mini Redis / MySQL / 分布式后置主线；项目 README、压测、debug 和面试讲稿；每周 2-3 题保持手感

### 012. [AIinfra 百度实习一面](https://www.nowcoder.com/feed/main/detail/2798883)

- 时间：2026-03-04
- 公司/组织：百度
- 岗位/方向：AI Infra / 大模型基础设施，Infra / 基础架构，C++ 开发
- 轮次：一面
- 作者认证：华东理工大学 Java
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，Infra / 基础架构，C++ 开发，面试内容集中在 C++：RAII、拷贝/移动语义、智能指针、模板/泛型；Linux/OS：fd/系统调用/IO；AI Infra：CUDA/GPU、Transformer/PyTorch；项目/工程：项目深挖。
- 面试内容整理：
  - C++：RAII、拷贝/移动语义、智能指针、模板/泛型
  - Linux/OS：fd/系统调用/IO
  - AI Infra：CUDA/GPU、Transformer/PyTorch
  - 项目/工程：项目深挖
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week4-5：Linux 系统编程与 OS 基础；2028 AI Infra：推理、CUDA、LLM Serving 预热；项目 README、压测、debug 和面试讲稿

### 013. [美团笔试加 ai 面试面经、经验及体验](https://www.nowcoder.com/feed/main/detail/2816455)

- 时间：2026-03-22
- 公司/组织：美团
- 岗位/方向：AI Infra / 大模型基础设施，C++ 后端/服务端，C++ 开发
- 轮次：笔试
- 作者认证：美团 后端开发(实习)
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，C++ 后端/服务端，C++ 开发，面试内容集中在 AI Infra：LLM Serving；项目/工程：项目深挖。
- 面试内容整理：
  - AI Infra：LLM Serving
  - 项目/工程：项目深挖
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：2028 AI Infra：推理、CUDA、LLM Serving 预热；项目 README、压测、debug 和面试讲稿

### 014. [21届有经验--C++面经-华od](https://www.nowcoder.com/discuss/750308780910317568)

- 时间：2025-05-09
- 公司/组织：华为 / OD
- 岗位/方向：AI Infra / 大模型基础设施，Infra / 基础架构，C++ 开发
- 轮次：笔试 / 一面 / 二面 / 主管面
- 作者认证：南京邮电大学 Java
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，Infra / 基础架构，C++ 开发，面试内容集中在 C++：智能指针、STL 容器、内存管理；并发：线程/线程池；Linux/OS：fd/系统调用/IO、排查工具；网络：TCP/UDP/HTTP、连接状态，并涉及 链表/树/图、TopK/堆/排序、二分/滑动窗口、动态规划/字符串、手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：智能指针、STL 容器、内存管理
  - 并发：线程/线程池
  - Linux/OS：fd/系统调用/IO、排查工具
  - 网络：TCP/UDP/HTTP、连接状态
  - 中间件/分布式：MySQL/数据库、Kafka/消息队列
  - AI Infra：LLM Serving
- 手撕/代码：链表/树/图、TopK/堆/排序、二分/滑动窗口、动态规划/字符串、手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor

### 015. [汇总篇-阿里系-阿里云（待续）+通义+淘天-秋招面经](https://www.nowcoder.com/discuss/796016932313919488)

- 时间：2025-09-12
- 公司/组织：阿里 / 腾讯
- 岗位/方向：AI Infra / 大模型基础设施，Infra / 基础架构，C++ 开发
- 轮次：二面 / 三面
- 作者认证：武汉大学 Java
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，Infra / 基础架构，C++ 开发，面试内容集中在 C++：智能指针、内存管理、模板/泛型；网络：TCP/UDP/HTTP；中间件/分布式：MySQL/数据库、分布式基础；AI Infra：LLM Serving、Transformer/PyTorch，并涉及 链表/树/图、TopK/堆/排序。
- 面试内容整理：
  - C++：智能指针、内存管理、模板/泛型
  - 网络：TCP/UDP/HTTP
  - 中间件/分布式：MySQL/数据库、分布式基础
  - AI Infra：LLM Serving、Transformer/PyTorch
  - 项目/工程：项目深挖
  - 手撕/算法：链表/树/图、二分/滑窗/TopK
- 手撕/代码：链表/树/图、TopK/堆/排序
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week6 + 项目线：socket、epoll、Reactor；Mini Redis / MySQL / 分布式后置主线；2028 AI Infra：推理、CUDA、LLM Serving 预热

### 016. [蚂蚁C++后端开发一面-秋招面经](https://www.nowcoder.com/feed/main/detail/2765183)

- 时间：2025-12-10
- 公司/组织：蚂蚁
- 岗位/方向：AI Infra / 大模型基础设施，C++ 后端/服务端，C++ 开发
- 轮次：一面
- 作者认证：重庆大学 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，C++ 后端/服务端，C++ 开发，面试内容集中在 C++：内存管理、const/static/volatile；并发：锁/条件变量；Linux/OS：进程/线程/调度；中间件/分布式：MySQL/数据库，并涉及 链表/树/图。
- 面试内容整理：
  - C++：内存管理、const/static/volatile
  - 并发：锁/条件变量
  - Linux/OS：进程/线程/调度
  - 中间件/分布式：MySQL/数据库
  - AI Infra：LLM Serving
  - 项目/工程：项目深挖
- 手撕/代码：链表/树/图
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Mini Redis / MySQL / 分布式后置主线

### 017. [面试真题 | 美团校招面经](https://www.nowcoder.com/discuss/645921022222327808)

- 时间：2024-07-25
- 公司/组织：美团 / 华为
- 岗位/方向：AI Infra / 大模型基础设施，C++ 后端/服务端，C++ 开发
- 轮次：OC
- 作者认证：华为 系统工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，C++ 后端/服务端，C++ 开发，面试内容集中在 C++：RAII、对象模型/虚函数、内存管理、异常安全；并发：线程/线程池、锁/条件变量；Linux/OS：进程/线程/调度、fd/系统调用/IO；网络：TCP/UDP/HTTP，并涉及 链表/树/图。
- 面试内容整理：
  - C++：RAII、对象模型/虚函数、内存管理、异常安全
  - 并发：线程/线程池、锁/条件变量
  - Linux/OS：进程/线程/调度、fd/系统调用/IO
  - 网络：TCP/UDP/HTTP
  - 中间件/分布式：MySQL/数据库
  - 项目/工程：工程工具、性能压测
- 手撕/代码：链表/树/图
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor

### 018. [拼多多AI Infra面经](https://www.nowcoder.com/feed/main/detail/2796505)

- 时间：2026-02-28
- 公司/组织：拼多多
- 岗位/方向：AI Infra / 大模型基础设施，Infra / 基础架构，C++ 开发
- 轮次：未标明
- 作者认证：陕西理工大学 算法工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，Infra / 基础架构，C++ 开发，面试内容集中在 Linux/OS：fd/系统调用/IO；AI Infra：CUDA/GPU、Transformer/PyTorch；项目/工程：项目深挖；手撕/算法：生产级代码，并涉及 手写数据结构/复杂度分析。
- 面试内容整理：
  - Linux/OS：fd/系统调用/IO
  - AI Infra：CUDA/GPU、Transformer/PyTorch
  - 项目/工程：项目深挖
  - 手撕/算法：生产级代码
- 手撕/代码：手写数据结构/复杂度分析
- 对你规划的用处：Week4-5：Linux 系统编程与 OS 基础；2028 AI Infra：推理、CUDA、LLM Serving 预热；项目 README、压测、debug 和面试讲稿；每周 2-3 题保持手感

### 019. [字节-系统工程-暑期实习一面面经-2025.3.12](https://www.nowcoder.com/discuss/729821154558353408)

- 时间：2025-03-13
- 公司/组织：字节
- 岗位/方向：AI Infra / 大模型基础设施，Infra / 基础架构，C++ 开发
- 轮次：笔试 / 一面
- 作者认证：南京理工大学 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，Infra / 基础架构，C++ 开发，面试内容集中在 C++：拷贝/移动语义、智能指针、STL 容器；并发：线程/线程池；中间件/分布式：Redis/缓存、MySQL/数据库、存储系统；AI Infra：CUDA/GPU、Transformer/PyTorch，并涉及 LRU/LFU 缓存、链表/树/图、手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：拷贝/移动语义、智能指针、STL 容器
  - 并发：线程/线程池
  - 中间件/分布式：Redis/缓存、MySQL/数据库、存储系统
  - AI Infra：CUDA/GPU、Transformer/PyTorch
  - 项目/工程：项目深挖
  - 手撕/算法：缓存题、链表/树/图、生产级代码
- 手撕/代码：LRU/LFU 缓存、链表/树/图、手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Mini Redis / MySQL / 分布式后置主线；2028 AI Infra：推理、CUDA、LLM Serving 预热

### 020. [Momenta C++ 智驾 二面 面经](https://www.nowcoder.com/discuss/866604572402380800)

- 时间：2026-03-26
- 公司/组织：字节 / Momenta
- 岗位/方向：AI Infra / 大模型基础设施，Infra / 基础架构，C++ 开发
- 轮次：二面 / 技术面 / OC
- 作者认证：浙江大学 算法工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，Infra / 基础架构，C++ 开发，面试内容集中在 C++：拷贝/移动语义、智能指针、STL 容器、对象模型/虚函数、内存管理、模板/泛型、const/static/volatile；并发：线程/线程池、锁/条件变量、atomic/CAS、生产者消费者；Linux/OS：进程/线程/调度、fd/系统调用/IO、排查工具；中间件/分布式：Redis/缓存、MySQL/数据库、分布式基础，并涉及 TopK/堆/排序、动态规划/字符串。
- 面试内容整理：
  - C++：拷贝/移动语义、智能指针、STL 容器、对象模型/虚函数、内存管理、模板/泛型、const/static/volatile
  - 并发：线程/线程池、锁/条件变量、atomic/CAS、生产者消费者
  - Linux/OS：进程/线程/调度、fd/系统调用/IO、排查工具
  - 中间件/分布式：Redis/缓存、MySQL/数据库、分布式基础
  - 项目/工程：项目深挖、性能压测
  - 手撕/算法：缓存题、二分/滑窗/TopK、动态规划/字符串
- 手撕/代码：TopK/堆/排序、动态规划/字符串
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Mini Redis / MySQL / 分布式后置主线

### 021. [腾讯数据平台部暑期实习后端面经](https://www.nowcoder.com/feed/main/detail/2574791)

- 时间：2025-04-03
- 公司/组织：腾讯
- 岗位/方向：AI Infra / 大模型基础设施，C++ 后端/服务端，C++ 开发
- 轮次：未标明
- 作者认证：清华大学 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，C++ 后端/服务端，C++ 开发，面试内容集中在 中间件/分布式：Redis/缓存；AI Infra：LLM Serving、CUDA/GPU；项目/工程：项目深挖；手撕/算法：动态规划/字符串、生产级代码，并涉及 动态规划/字符串、手写数据结构/复杂度分析。
- 面试内容整理：
  - 中间件/分布式：Redis/缓存
  - AI Infra：LLM Serving、CUDA/GPU
  - 项目/工程：项目深挖
  - 手撕/算法：动态规划/字符串、生产级代码
- 手撕/代码：动态规划/字符串、手写数据结构/复杂度分析
- 对你规划的用处：Mini Redis / MySQL / 分布式后置主线；2028 AI Infra：推理、CUDA、LLM Serving 预热；项目 README、压测、debug 和面试讲稿；每周 2-3 题保持手感

### 022. [影石高性能计算面经（一二面）](https://www.nowcoder.com/feed/main/detail/2860254)

- 时间：2026-06-06
- 公司/组织：360
- 岗位/方向：AI Infra / 大模型基础设施，Infra / 基础架构，C++ 开发
- 轮次：一面 / 二面
- 作者认证：中国农业大学 算法工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，Infra / 基础架构，C++ 开发，面试内容集中在 C++：STL 容器；AI Infra：CUDA/GPU；项目/工程：项目深挖、性能压测；手撕/算法：动态规划/字符串、生产级代码，并涉及 动态规划/字符串、手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：STL 容器
  - AI Infra：CUDA/GPU
  - 项目/工程：项目深挖、性能压测
  - 手撕/算法：动态规划/字符串、生产级代码
- 手撕/代码：动态规划/字符串、手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；2028 AI Infra：推理、CUDA、LLM Serving 预热；项目 README、压测、debug 和面试讲稿；每周 2-3 题保持手感

### 023. [百度移动抓取与收录研发工程师面经](https://www.nowcoder.com/feed/main/detail/2700691)

- 时间：2025-09-25
- 公司/组织：百度
- 岗位/方向：AI Infra / 大模型基础设施，Infra / 基础架构，C++ 开发
- 轮次：未标明
- 作者认证：National University of Singapore 数据分析师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，Infra / 基础架构，C++ 开发，面试内容集中在 Linux/OS：fd/系统调用/IO；网络：TCP/UDP/HTTP；中间件/分布式：存储系统；AI Infra：Transformer/PyTorch。
- 面试内容整理：
  - Linux/OS：fd/系统调用/IO
  - 网络：TCP/UDP/HTTP
  - 中间件/分布式：存储系统
  - AI Infra：Transformer/PyTorch
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor；Mini Redis / MySQL / 分布式后置主线；2028 AI Infra：推理、CUDA、LLM Serving 预热

### 024. [27实习百度ai infra面经分享](https://www.nowcoder.com/feed/main/detail/2846362)

- 时间：2026-05-01
- 公司/组织：百度
- 岗位/方向：AI Infra / 大模型基础设施，Infra / 基础架构，C++ 开发
- 轮次：未标明
- 作者认证：门头沟学院 算法工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，Infra / 基础架构，C++ 开发，面试内容集中在 C++：内存管理；项目/工程：项目深挖；手撕/算法：二分/滑窗/TopK，并涉及 TopK/堆/排序。
- 面试内容整理：
  - C++：内存管理
  - 项目/工程：项目深挖
  - 手撕/算法：二分/滑窗/TopK
- 手撕/代码：TopK/堆/排序
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；项目 README、压测、debug 和面试讲稿；每周 2-3 题保持手感

### 025. [百度 文心一言ai infra-实习面经](https://www.nowcoder.com/feed/main/detail/2846354)

- 时间：2026-05-01
- 公司/组织：百度
- 岗位/方向：AI Infra / 大模型基础设施，Infra / 基础架构，C++ 开发
- 轮次：OC
- 作者认证：门头沟学院 Java
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，Infra / 基础架构，C++ 开发，面试内容集中在 中间件/分布式：存储系统；AI Infra：LLM Serving、CUDA/GPU、Transformer/PyTorch；项目/工程：项目深挖。
- 面试内容整理：
  - 中间件/分布式：存储系统
  - AI Infra：LLM Serving、CUDA/GPU、Transformer/PyTorch
  - 项目/工程：项目深挖
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Mini Redis / MySQL / 分布式后置主线；2028 AI Infra：推理、CUDA、LLM Serving 预热；项目 README、压测、debug 和面试讲稿

### 026. [留子的25秋招记录](https://www.nowcoder.com/discuss/652951147329695744)

- 时间：2024-12-16
- 公司/组织：大疆 / 中兴
- 岗位/方向：AI Infra / 大模型基础设施，Infra / 基础架构，C++ 开发
- 轮次：一面
- 作者认证：Georgia Institute of Technology 无线通信工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，Infra / 基础架构，C++ 开发，面试内容集中在 C++：拷贝/移动语义、智能指针、STL 容器、对象模型/虚函数、const/static/volatile；AI Infra：LLM Serving、CUDA/GPU；项目/工程：项目深挖；手撕/算法：链表/树/图。
- 面试内容整理：
  - C++：拷贝/移动语义、智能指针、STL 容器、对象模型/虚函数、const/static/volatile
  - AI Infra：LLM Serving、CUDA/GPU
  - 项目/工程：项目深挖
  - 手撕/算法：链表/树/图
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；2028 AI Infra：推理、CUDA、LLM Serving 预热；项目 README、压测、debug 和面试讲稿；每周 2-3 题保持手感

### 027. [C++菜鸡的暑期实习总结（已完结）](https://www.nowcoder.com/discuss/620397328725299200)

- 时间：2024-10-09
- 公司/组织：阿里 / 字节 / 腾讯
- 岗位/方向：AI Infra / 大模型基础设施，Infra / 基础架构，C++ 开发
- 轮次：笔试 / 一面 / 二面 / OC
- 作者认证：蚌埠坦克学院 机器学习
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，Infra / 基础架构，C++ 开发，面试内容集中在 C++：智能指针、对象模型/虚函数；Linux/OS：fd/系统调用/IO、排查工具；AI Infra：LLM Serving、CUDA/GPU、Transformer/PyTorch；项目/工程：项目深挖、性能压测，并涉及 链表/树/图、手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：智能指针、对象模型/虚函数
  - Linux/OS：fd/系统调用/IO、排查工具
  - AI Infra：LLM Serving、CUDA/GPU、Transformer/PyTorch
  - 项目/工程：项目深挖、性能压测
  - 手撕/算法：链表/树/图、生产级代码
- 手撕/代码：链表/树/图、手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week4-5：Linux 系统编程与 OS 基础；2028 AI Infra：推理、CUDA、LLM Serving 预热；项目 README、压测、debug 和面试讲稿

### 028. [AI infra应届春招](https://www.nowcoder.com/feed/main/detail/2817437)

- 时间：2026-03-25
- 公司/组织：京东
- 岗位/方向：AI Infra / 大模型基础设施，Infra / 基础架构，C++ 开发
- 轮次：一面
- 作者认证：门头沟学院 算法工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，Infra / 基础架构，C++ 开发，面试内容集中在 C++：对象模型/虚函数。
- 面试内容整理：
  - C++：对象模型/虚函数
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理

### 029. [阿里智能信息 凉经](https://www.nowcoder.com/feed/main/detail/2593255)

- 时间：2025-04-25
- 公司/组织：阿里
- 岗位/方向：AI Infra / 大模型基础设施，Infra / 基础架构，C++ 开发
- 轮次：一面
- 作者认证：门头沟学院 Java
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，Infra / 基础架构，C++ 开发，面试内容集中在 中间件/分布式：Redis/缓存、MySQL/数据库；AI Infra：LLM Serving；项目/工程：项目深挖、性能压测；手撕/算法：链表/树/图，并涉及 链表/树/图。
- 面试内容整理：
  - 中间件/分布式：Redis/缓存、MySQL/数据库
  - AI Infra：LLM Serving
  - 项目/工程：项目深挖、性能压测
  - 手撕/算法：链表/树/图
- 手撕/代码：链表/树/图
- 对你规划的用处：Mini Redis / MySQL / 分布式后置主线；2028 AI Infra：推理、CUDA、LLM Serving 预热；项目 README、压测、debug 和面试讲稿；每周 2-3 题保持手感

### 030. [华为海思-图灵业务部](https://www.nowcoder.com/discuss/899808901892239360)

- 时间：2026-06-27
- 公司/组织：字节 / 华为
- 岗位/方向：AI Infra / 大模型基础设施，Infra / 基础架构，C++ 开发
- 轮次：笔试 / 一面 / 主管面
- 作者认证：南京理工大学
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，Infra / 基础架构，C++ 开发，面试内容集中在 C++：内存管理；网络：TCP/UDP/HTTP；AI Infra：CUDA/GPU；项目/工程：项目深挖、工程工具，并涉及 链表/树/图、TopK/堆/排序、手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：内存管理
  - 网络：TCP/UDP/HTTP
  - AI Infra：CUDA/GPU
  - 项目/工程：项目深挖、工程工具
  - 手撕/算法：链表/树/图、二分/滑窗/TopK、生产级代码
- 手撕/代码：链表/树/图、TopK/堆/排序、手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week6 + 项目线：socket、epoll、Reactor；2028 AI Infra：推理、CUDA、LLM Serving 预热；项目 README、压测、debug 和面试讲稿

### 031. [AI云原生实习生 - 博纳讯动 - bocloud - Golang - 日常实习 - 一二面](https://www.nowcoder.com/discuss/719486030037917696)

- 时间：2025-02-20
- 公司/组织：腾讯
- 岗位/方向：AI Infra / 大模型基础设施，Infra / 基础架构，C++ 后端/服务端
- 轮次：一面 / 二面 / 技术面 / OC
- 作者认证：广东工业大学 golang
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，Infra / 基础架构，C++ 后端/服务端，面试内容集中在 C++：STL 容器、内存管理；并发：atomic/CAS、生产者消费者；Linux/OS：进程/线程/调度、fd/系统调用/IO、排查工具；网络：TCP/UDP/HTTP，并涉及 TopK/堆/排序。
- 面试内容整理：
  - C++：STL 容器、内存管理
  - 并发：atomic/CAS、生产者消费者
  - Linux/OS：进程/线程/调度、fd/系统调用/IO、排查工具
  - 网络：TCP/UDP/HTTP
  - 中间件/分布式：Redis/缓存、MySQL/数据库、Kafka/消息队列
  - AI Infra：LLM Serving
- 手撕/代码：TopK/堆/排序
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor

### 032. [腾讯/百度/minimax 大模型算法面经总结帖](https://www.nowcoder.com/feed/main/detail/2562044)

- 时间：2025-03-21
- 公司/组织：腾讯 / 百度
- 岗位/方向：AI Infra / 大模型基础设施，C++ 开发
- 轮次：未标明
- 作者认证：门头沟学院 算法工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，C++ 开发，面试内容集中在 AI Infra：LLM Serving；手撕/算法：链表/树/图、生产级代码，并涉及 链表/树/图、手写数据结构/复杂度分析。
- 面试内容整理：
  - AI Infra：LLM Serving
  - 手撕/算法：链表/树/图、生产级代码
- 手撕/代码：链表/树/图、手写数据结构/复杂度分析
- 对你规划的用处：2028 AI Infra：推理、CUDA、LLM Serving 预热；每周 2-3 题保持手感

### 033. [华为面经/通用软开](https://www.nowcoder.com/feed/main/detail/2461066)

- 时间：2024-11-14
- 公司/组织：华为
- 岗位/方向：AI Infra / 大模型基础设施，C++ 开发
- 轮次：一面 / 二面 / OC
- 作者认证：上海交通大学 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，C++ 开发，面试内容集中在 AI Infra：CUDA/GPU；项目/工程：项目深挖。
- 面试内容整理：
  - AI Infra：CUDA/GPU
  - 项目/工程：项目深挖
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：2028 AI Infra：推理、CUDA、LLM Serving 预热；项目 README、压测、debug 和面试讲稿

### 034. [商汤大模型应用开发工程师校招一面凉经](https://www.nowcoder.com/feed/main/detail/2389918)

- 时间：2024-09-23
- 公司/组织：商汤
- 岗位/方向：AI Infra / 大模型基础设施，C++ 开发
- 轮次：一面 / OC
- 作者认证：西北工业大学 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，C++ 开发，面试内容集中在 AI Infra：LLM Serving；项目/工程：项目深挖；手撕/算法：生产级代码，并涉及 手写数据结构/复杂度分析。
- 面试内容整理：
  - AI Infra：LLM Serving
  - 项目/工程：项目深挖
  - 手撕/算法：生产级代码
- 手撕/代码：手写数据结构/复杂度分析
- 对你规划的用处：2028 AI Infra：推理、CUDA、LLM Serving 预热；项目 README、压测、debug 和面试讲稿；每周 2-3 题保持手感

### 035. [蚂蚁-NLP算法面经](https://www.nowcoder.com/feed/main/detail/2498827)

- 时间：2025-03-24
- 公司/组织：蚂蚁
- 岗位/方向：AI Infra / 大模型基础设施，C++ 开发
- 轮次：二面 / 三面 / OC
- 作者认证：南昌大学 自然语言处理
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，C++ 开发，面试内容集中在 AI Infra：Transformer/PyTorch；项目/工程：项目深挖；手撕/算法：链表/树/图。
- 面试内容整理：
  - AI Infra：Transformer/PyTorch
  - 项目/工程：项目深挖
  - 手撕/算法：链表/树/图
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：2028 AI Infra：推理、CUDA、LLM Serving 预热；项目 README、压测、debug 和面试讲稿；每周 2-3 题保持手感

### 036. [平头哥芯软暑期面经](https://www.nowcoder.com/feed/main/detail/2593607)

- 时间：2025-08-21
- 公司/组织：阿里
- 岗位/方向：AI Infra / 大模型基础设施，C++ 开发
- 轮次：笔试 / 二面
- 作者认证：西安交通大学 嵌入式软件开发
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，C++ 开发，面试内容集中在 C++：内存管理；并发：线程/线程池；Linux/OS：虚拟内存/mmap/COW；AI Infra：Transformer/PyTorch，并涉及 TopK/堆/排序。
- 面试内容整理：
  - C++：内存管理
  - 并发：线程/线程池
  - Linux/OS：虚拟内存/mmap/COW
  - AI Infra：Transformer/PyTorch
  - 项目/工程：项目深挖
  - 手撕/算法：二分/滑窗/TopK
- 手撕/代码：TopK/堆/排序
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；2028 AI Infra：推理、CUDA、LLM Serving 预热

### 037. [三战暑期腾讯后台面经](https://www.nowcoder.com/feed/main/detail/2834560)

- 时间：2026-04-21
- 公司/组织：腾讯
- 岗位/方向：AI Infra / 大模型基础设施，C++ 后端/服务端，C++ 开发
- 轮次：OC
- 作者认证：哈尔滨工业大学（威海） C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，C++ 后端/服务端，C++ 开发，面试内容集中在 C++：对象模型/虚函数；并发：线程/线程池；网络：TCP/UDP/HTTP；中间件/分布式：MySQL/数据库。
- 面试内容整理：
  - C++：对象模型/虚函数
  - 并发：线程/线程池
  - 网络：TCP/UDP/HTTP
  - 中间件/分布式：MySQL/数据库
  - AI Infra：LLM Serving
  - 项目/工程：项目深挖
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week6 + 项目线：socket、epoll、Reactor；Mini Redis / MySQL / 分布式后置主线

### 038. [百度社招面经 大模型推理c++方向](https://www.nowcoder.com/feed/main/detail/2702032)

- 时间：2025-09-25
- 公司/组织：百度
- 岗位/方向：AI Infra / 大模型基础设施，C++ 开发
- 轮次：一面
- 作者认证：门头沟学院 算法工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，C++ 开发，面试内容集中在 C++：STL 容器、模板/泛型；Linux/OS：进程/线程/调度、fd/系统调用/IO；中间件/分布式：Redis/缓存、MySQL/数据库；AI Infra：LLM Serving、Transformer/PyTorch，并涉及 LRU/LFU 缓存、手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：STL 容器、模板/泛型
  - Linux/OS：进程/线程/调度、fd/系统调用/IO
  - 中间件/分布式：Redis/缓存、MySQL/数据库
  - AI Infra：LLM Serving、Transformer/PyTorch
  - 项目/工程：项目深挖
  - 手撕/算法：缓存题、链表/树/图、生产级代码
- 手撕/代码：LRU/LFU 缓存、手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week4-5：Linux 系统编程与 OS 基础；Mini Redis / MySQL / 分布式后置主线；2028 AI Infra：推理、CUDA、LLM Serving 预热

### 039. [字节一面&美团一面面经](https://www.nowcoder.com/feed/main/detail/2598579)

- 时间：2025-05-08
- 公司/组织：字节 / 美团
- 岗位/方向：AI Infra / 大模型基础设施，C++ 开发
- 轮次：笔试 / 一面
- 作者认证：西安交通大学 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，C++ 开发，面试内容集中在 C++：STL 容器、对象模型/虚函数；Linux/OS：进程/线程/调度；AI Infra：CUDA/GPU；项目/工程：项目深挖。
- 面试内容整理：
  - C++：STL 容器、对象模型/虚函数
  - Linux/OS：进程/线程/调度
  - AI Infra：CUDA/GPU
  - 项目/工程：项目深挖
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week4-5：Linux 系统编程与 OS 基础；2028 AI Infra：推理、CUDA、LLM Serving 预热；项目 README、压测、debug 和面试讲稿

### 040. [图像算法岗（1年工作经验）-华为OD面经](https://www.nowcoder.com/discuss/737051368216702976)

- 时间：2025-04-02
- 公司/组织：华为 / OD
- 岗位/方向：AI Infra / 大模型基础设施，C++ 开发
- 轮次：一面 / 二面 / 技术面 / 主管面
- 作者认证：门头沟学院 算法工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，C++ 开发，面试内容集中在 C++：智能指针、STL 容器；并发：线程/线程池；Linux/OS：fd/系统调用/IO、排查工具；项目/工程：项目深挖，并涉及 链表/树/图、TopK/堆/排序、二分/滑动窗口、动态规划/字符串、手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：智能指针、STL 容器
  - 并发：线程/线程池
  - Linux/OS：fd/系统调用/IO、排查工具
  - 项目/工程：项目深挖
  - 手撕/算法：链表/树/图、二分/滑窗/TopK、动态规划/字符串、生产级代码
- 手撕/代码：链表/树/图、TopK/堆/排序、二分/滑动窗口、动态规划/字符串、手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；项目 README、压测、debug 和面试讲稿

### 041. [中兴领军C++一面面经](https://www.nowcoder.com/discuss/794260560257773568)

- 时间：2025-09-07
- 公司/组织：中兴
- 岗位/方向：AI Infra / 大模型基础设施，C++ 开发
- 轮次：一面
- 作者认证：门头沟学院 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，C++ 开发，面试内容集中在 C++：对象模型/虚函数；AI Infra：LLM Serving、Transformer/PyTorch；项目/工程：项目深挖。
- 面试内容整理：
  - C++：对象模型/虚函数
  - AI Infra：LLM Serving、Transformer/PyTorch
  - 项目/工程：项目深挖
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；2028 AI Infra：推理、CUDA、LLM Serving 预热；项目 README、压测、debug 和面试讲稿

### 042. [拼多多 搜推大模型推理加速 面经](https://www.nowcoder.com/feed/main/detail/2664454)

- 时间：2025-08-19
- 公司/组织：拼多多
- 岗位/方向：AI Infra / 大模型基础设施，C++ 开发
- 轮次：一面
- 作者认证：东南大学 机器学习
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，C++ 开发，面试内容集中在 C++：对象模型/虚函数；AI Infra：LLM Serving。
- 面试内容整理：
  - C++：对象模型/虚函数
  - AI Infra：LLM Serving
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；2028 AI Infra：推理、CUDA、LLM Serving 预热

### 043. [腾讯二面](https://www.nowcoder.com/feed/main/detail/2583420)

- 时间：2025-04-14
- 公司/组织：腾讯
- 岗位/方向：AI Infra / 大模型基础设施，C++ 开发
- 轮次：二面
- 作者认证：门头沟学院 Java
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，C++ 开发，面试内容集中在 C++：拷贝/移动语义、内存管理；网络：TCP/UDP/HTTP；中间件/分布式：Redis/缓存；AI Infra：LLM Serving，并涉及 手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：拷贝/移动语义、内存管理
  - 网络：TCP/UDP/HTTP
  - 中间件/分布式：Redis/缓存
  - AI Infra：LLM Serving
  - 手撕/算法：链表/树/图、生产级代码
- 手撕/代码：手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week6 + 项目线：socket、epoll、Reactor；Mini Redis / MySQL / 分布式后置主线；2028 AI Infra：推理、CUDA、LLM Serving 预热

### 044. [MiniMax 算法工程研发工程师 面经](https://www.nowcoder.com/discuss/798036152795004928)

- 时间：2025-10-17
- 公司/组织：MiniMax
- 岗位/方向：AI Infra / 大模型基础设施，C++ 开发
- 轮次：hr面
- 作者认证：早稲田大学 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，C++ 开发，面试内容集中在 C++：内存管理；并发：锁/条件变量、atomic/CAS；Linux/OS：进程/线程/调度；中间件/分布式：MySQL/数据库，并涉及 链表/树/图。
- 面试内容整理：
  - C++：内存管理
  - 并发：锁/条件变量、atomic/CAS
  - Linux/OS：进程/线程/调度
  - 中间件/分布式：MySQL/数据库
  - AI Infra：LLM Serving、CUDA/GPU
  - 项目/工程：项目深挖
- 手撕/代码：链表/树/图
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Mini Redis / MySQL / 分布式后置主线

### 045. [美团大模型算法二面-秋招面经](https://www.nowcoder.com/feed/main/detail/2769366)

- 时间：2025-12-18
- 公司/组织：美团
- 岗位/方向：AI Infra / 大模型基础设施，C++ 开发
- 轮次：二面
- 作者认证：山东大学 算法工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，C++ 开发，面试内容集中在 AI Infra：LLM Serving。
- 面试内容整理：
  - AI Infra：LLM Serving
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：2028 AI Infra：推理、CUDA、LLM Serving 预热

### 046. [腾讯一面凉经](https://www.nowcoder.com/feed/main/detail/2842215)

- 时间：2026-04-24
- 公司/组织：腾讯
- 岗位/方向：AI Infra / 大模型基础设施，C++ 开发
- 轮次：一面
- 作者认证：大连理工大学 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，C++ 开发，面试内容集中在 Linux/OS：fd/系统调用/IO；中间件/分布式：Redis/缓存；AI Infra：LLM Serving；项目/工程：项目深挖、性能压测。
- 面试内容整理：
  - Linux/OS：fd/系统调用/IO
  - 中间件/分布式：Redis/缓存
  - AI Infra：LLM Serving
  - 项目/工程：项目深挖、性能压测
  - 手撕/算法：缓存题
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week4-5：Linux 系统编程与 OS 基础；Mini Redis / MySQL / 分布式后置主线；2028 AI Infra：推理、CUDA、LLM Serving 预热；项目 README、压测、debug 和面试讲稿

### 047. [寒武纪面经](https://www.nowcoder.com/discuss/877218958682644480)

- 时间：2026-04-24
- 公司/组织：寒武纪
- 岗位/方向：AI Infra / 大模型基础设施，C++ 开发
- 轮次：一面
- 作者认证：门头沟学院 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，C++ 开发，面试内容集中在 C++：RAII、拷贝/移动语义、对象模型/虚函数；AI Infra：LLM Serving、Transformer/PyTorch；项目/工程：项目深挖；手撕/算法：链表/树/图、生产级代码，并涉及 链表/树/图、手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：RAII、拷贝/移动语义、对象模型/虚函数
  - AI Infra：LLM Serving、Transformer/PyTorch
  - 项目/工程：项目深挖
  - 手撕/算法：链表/树/图、生产级代码
- 手撕/代码：链表/树/图、手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；2028 AI Infra：推理、CUDA、LLM Serving 预热；项目 README、压测、debug 和面试讲稿；每周 2-3 题保持手感

### 048. [快star-x二面凉经](https://www.nowcoder.com/feed/main/detail/2629138)

- 时间：2025-07-09
- 公司/组织：抖音
- 岗位/方向：Infra / 基础架构，C++ 后端/服务端，C++ 开发
- 轮次：一面 / 二面 / OC
- 作者认证：西安交通大学 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 后端/服务端，C++ 开发，面试内容集中在 并发：线程/线程池、锁/条件变量；Linux/OS：fd/系统调用/IO；中间件/分布式：MySQL/数据库；项目/工程：项目深挖，并涉及 手写数据结构/复杂度分析。
- 面试内容整理：
  - 并发：线程/线程池、锁/条件变量
  - Linux/OS：fd/系统调用/IO
  - 中间件/分布式：MySQL/数据库
  - 项目/工程：项目深挖
  - 手撕/算法：生产级代码
- 手撕/代码：手写数据结构/复杂度分析
- 对你规划的用处：Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Mini Redis / MySQL / 分布式后置主线；项目 README、压测、debug 和面试讲稿

### 049. [面经-腾讯篇](https://www.nowcoder.com/feed/main/detail/2598310)

- 时间：2025-05-10
- 公司/组织：腾讯
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：一面 / 二面
- 作者认证：中国科学技术大学 Java
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 C++：内存管理；Linux/OS：进程/线程/调度、fd/系统调用/IO；网络：TCP/UDP/HTTP；中间件/分布式：Redis/缓存，并涉及 链表/树/图、TopK/堆/排序、手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：内存管理
  - Linux/OS：进程/线程/调度、fd/系统调用/IO
  - 网络：TCP/UDP/HTTP
  - 中间件/分布式：Redis/缓存
  - 项目/工程：项目深挖
  - 手撕/算法：链表/树/图、二分/滑窗/TopK、生产级代码
- 手撕/代码：链表/树/图、TopK/堆/排序、手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor；Mini Redis / MySQL / 分布式后置主线

### 050. [暑期实习记录（附c++面经）](https://www.nowcoder.com/discuss/746424726964154368)

- 时间：2025-04-28
- 公司/组织：腾讯
- 岗位/方向：Infra / 基础架构，C++ 后端/服务端，C++ 开发
- 轮次：一面 / OC
- 作者认证：武汉科技大学 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 后端/服务端，C++ 开发，面试内容集中在 C++：智能指针、STL 容器、对象模型/虚函数、内存管理；并发：生产者消费者；Linux/OS：进程/线程/调度；网络：TCP/UDP/HTTP、连接状态、epoll/Reactor，并涉及 手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：智能指针、STL 容器、对象模型/虚函数、内存管理
  - 并发：生产者消费者
  - Linux/OS：进程/线程/调度
  - 网络：TCP/UDP/HTTP、连接状态、epoll/Reactor
  - 中间件/分布式：Redis/缓存、MySQL/数据库、分布式基础
  - 项目/工程：项目深挖
- 手撕/代码：手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor

### 051. [网易互娱游戏研发面经+时间线](https://www.nowcoder.com/feed/main/detail/2592824)

- 时间：2025-04-25
- 公司/组织：字节 / 网易
- 岗位/方向：Infra / 基础架构，C++ 后端/服务端，C++ 开发
- 轮次：一面 / 二面
- 作者认证：中山大学 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 后端/服务端，C++ 开发，面试内容集中在 C++：const/static/volatile；并发：atomic/CAS；Linux/OS：进程/线程/调度；网络：TCP/UDP/HTTP、连接状态，并涉及 动态规划/字符串。
- 面试内容整理：
  - C++：const/static/volatile
  - 并发：atomic/CAS
  - Linux/OS：进程/线程/调度
  - 网络：TCP/UDP/HTTP、连接状态
  - 中间件/分布式：存储系统
  - 项目/工程：项目深挖
- 手撕/代码：动态规划/字符串
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor

### 052. [十二面上岸鹅厂，暑期有亿点点难](https://www.nowcoder.com/discuss/744646976490266624)

- 时间：2025-04-23
- 公司/组织：腾讯
- 岗位/方向：Infra / 基础架构，C++ 开发
- 轮次：一面 / 二面 / OC
- 作者认证：东莞市东华初级中学 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 开发，面试内容集中在 C++：智能指针、对象模型/虚函数、内存管理；中间件/分布式：MySQL/数据库、分布式基础；项目/工程：项目深挖。
- 面试内容整理：
  - C++：智能指针、对象模型/虚函数、内存管理
  - 中间件/分布式：MySQL/数据库、分布式基础
  - 项目/工程：项目深挖
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Mini Redis / MySQL / 分布式后置主线；项目 README、压测、debug 和面试讲稿

### 053. [暑期实习面经 攒人品](https://www.nowcoder.com/discuss/739148660356677632)

- 时间：2025-04-08
- 公司/组织：阿里 / 蚂蚁 / 字节
- 岗位/方向：Infra / 基础架构，C++ 后端/服务端，C++ 开发
- 轮次：一面 / 二面 / 三面 / 四面
- 作者认证：武汉大学 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 后端/服务端，C++ 开发，面试内容集中在 C++：RAII、智能指针、STL 容器、对象模型/虚函数、内存管理、异常安全、const/static/volatile；并发：线程/线程池、锁/条件变量、atomic/CAS；Linux/OS：进程/线程/调度、虚拟内存/mmap/COW、fd/系统调用/IO、排查工具；网络：TCP/UDP/HTTP、连接状态、epoll/Reactor，并涉及 LRU/LFU 缓存、链表/树/图、TopK/堆/排序、二分/滑动窗口、动态规划/字符串。
- 面试内容整理：
  - C++：RAII、智能指针、STL 容器、对象模型/虚函数、内存管理、异常安全、const/static/volatile
  - 并发：线程/线程池、锁/条件变量、atomic/CAS
  - Linux/OS：进程/线程/调度、虚拟内存/mmap/COW、fd/系统调用/IO、排查工具
  - 网络：TCP/UDP/HTTP、连接状态、epoll/Reactor
  - 中间件/分布式：Redis/缓存、MySQL/数据库、Kafka/消息队列、分布式基础、存储系统
  - AI Infra：LLM Serving
- 手撕/代码：LRU/LFU 缓存、链表/树/图、TopK/堆/排序、二分/滑动窗口、动态规划/字符串
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor

### 054. [腾讯云一二三 hr面经](https://www.nowcoder.com/feed/main/detail/2567468)

- 时间：2025-03-27
- 公司/组织：腾讯
- 岗位/方向：Infra / 基础架构，C++ 后端/服务端，C++ 开发
- 轮次：hr面
- 作者认证：哈尔滨理工大学 后端工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 后端/服务端，C++ 开发，面试内容集中在 C++：智能指针；网络：RPC/协议；中间件/分布式：MySQL/数据库、存储系统。
- 面试内容整理：
  - C++：智能指针
  - 网络：RPC/协议
  - 中间件/分布式：MySQL/数据库、存储系统
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week6 + 项目线：socket、epoll、Reactor；Mini Redis / MySQL / 分布式后置主线

### 055. [26届美团暑期后端一面面经](https://www.nowcoder.com/discuss/734463560968871936)

- 时间：2025-03-26
- 公司/组织：美团
- 岗位/方向：Infra / 基础架构，C++ 后端/服务端，C++ 开发
- 轮次：一面 / 二面
- 作者认证：大连理工大学 Java
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 后端/服务端，C++ 开发，面试内容集中在 C++：STL 容器、对象模型/虚函数、内存管理；并发：线程/线程池、atomic/CAS；网络：TCP/UDP/HTTP、RPC/协议；中间件/分布式：Redis/缓存、MySQL/数据库、Kafka/消息队列、存储系统，并涉及 二分/滑动窗口、动态规划/字符串、手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：STL 容器、对象模型/虚函数、内存管理
  - 并发：线程/线程池、atomic/CAS
  - 网络：TCP/UDP/HTTP、RPC/协议
  - 中间件/分布式：Redis/缓存、MySQL/数据库、Kafka/消息队列、存储系统
  - 项目/工程：项目深挖、性能压测
  - 手撕/算法：缓存题、链表/树/图、二分/滑窗/TopK、动态规划/字符串、生产级代码
- 手撕/代码：二分/滑动窗口、动态规划/字符串、手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week6 + 项目线：socket、epoll、Reactor；Mini Redis / MySQL / 分布式后置主线

### 056. [26届美团暑期实习后端开发二面面经（已oc）](https://www.nowcoder.com/feed/main/detail/2564006)

- 时间：2025-03-25
- 公司/组织：字节 / 美团
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：一面 / 二面 / OC
- 作者认证：字节跳动 后端开发
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 C++：内存管理；项目/工程：项目深挖。
- 面试内容整理：
  - C++：内存管理
  - 项目/工程：项目深挖
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；项目 README、压测、debug 和面试讲稿

### 057. [字节跳动 游戏研发实习生 面经](https://www.nowcoder.com/discuss/733765896732241920)

- 时间：2025-03-24
- 公司/组织：字节
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：一面 / 二面
- 作者认证：门头沟学院 Unity3D客户端
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 C++：RAII、拷贝/移动语义、智能指针、STL 容器、对象模型/虚函数、内存管理；并发：线程/线程池、atomic/CAS；Linux/OS：进程/线程/调度、fd/系统调用/IO；网络：TCP/UDP/HTTP、epoll/Reactor、RPC/协议，并涉及 链表/树/图、TopK/堆/排序、动态规划/字符串、手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：RAII、拷贝/移动语义、智能指针、STL 容器、对象模型/虚函数、内存管理
  - 并发：线程/线程池、atomic/CAS
  - Linux/OS：进程/线程/调度、fd/系统调用/IO
  - 网络：TCP/UDP/HTTP、epoll/Reactor、RPC/协议
  - AI Infra：LLM Serving
  - 项目/工程：项目深挖
- 手撕/代码：链表/树/图、TopK/堆/排序、动态规划/字符串、手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor

### 058. [关乎秋招的一点所思所想](https://www.nowcoder.com/discuss/685167490510446592)

- 时间：2024-11-10
- 公司/组织：华为 / 理想 / 得物
- 岗位/方向：AI Infra / 大模型基础设施，Infra / 基础架构，C++ 开发
- 轮次：笔试 / 一面 / 二面 / 主管面
- 作者认证：浙江大学 算法工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，Infra / 基础架构，C++ 开发，面试内容集中在 C++：智能指针、STL 容器、内存管理、异常安全；中间件/分布式：MySQL/数据库；AI Infra：LLM Serving、CUDA/GPU、Transformer/PyTorch；项目/工程：项目深挖、性能压测，并涉及 链表/树/图、TopK/堆/排序、手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：智能指针、STL 容器、内存管理、异常安全
  - 中间件/分布式：MySQL/数据库
  - AI Infra：LLM Serving、CUDA/GPU、Transformer/PyTorch
  - 项目/工程：项目深挖、性能压测
  - 手撕/算法：链表/树/图、二分/滑窗/TopK、生产级代码
- 手撕/代码：链表/树/图、TopK/堆/排序、手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Mini Redis / MySQL / 分布式后置主线；2028 AI Infra：推理、CUDA、LLM Serving 预热；项目 README、压测、debug 和面试讲稿

### 059. [211本，字节OC面经贴分享](https://www.nowcoder.com/discuss/676821795248373760)

- 时间：2024-10-26
- 公司/组织：阿里 / 蚂蚁 / 字节
- 岗位/方向：Infra / 基础架构，C++ 后端/服务端，C++ 开发
- 轮次：笔试 / 一面 / 二面 / OC
- 作者认证：字节跳动 后端开发
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 后端/服务端，C++ 开发，面试内容集中在 C++：STL 容器、对象模型/虚函数、内存管理、const/static/volatile；并发：线程/线程池、锁/条件变量、生产者消费者；Linux/OS：进程/线程/调度、fd/系统调用/IO、排查工具；网络：TCP/UDP/HTTP、连接状态、epoll/Reactor、RPC/协议，并涉及 线程池/阻塞队列、链表/树/图、动态规划/字符串、手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：STL 容器、对象模型/虚函数、内存管理、const/static/volatile
  - 并发：线程/线程池、锁/条件变量、生产者消费者
  - Linux/OS：进程/线程/调度、fd/系统调用/IO、排查工具
  - 网络：TCP/UDP/HTTP、连接状态、epoll/Reactor、RPC/协议
  - 中间件/分布式：Redis/缓存、MySQL/数据库、Kafka/消息队列、分布式基础、存储系统
  - 项目/工程：项目深挖、工程工具、性能压测
- 手撕/代码：线程池/阻塞队列、链表/树/图、动态规划/字符串、手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor

### 060. [面经深度解析：C++-米哈游](https://www.nowcoder.com/feed/main/detail/2348093)

- 时间：2024-08-31
- 公司/组织：米哈游
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：未标明
- 作者认证：上海交通大学 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 C++：const/static/volatile；项目/工程：性能压测。
- 面试内容整理：
  - C++：const/static/volatile
  - 项目/工程：性能压测
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；项目 README、压测、debug 和面试讲稿

### 061. [字节后端一面面经，稳定一批！](https://www.nowcoder.com/discuss/648273029868400640)

- 时间：2024-08-01
- 公司/组织：字节
- 岗位/方向：Infra / 基础架构，C++ 后端/服务端，C++ 开发
- 轮次：一面
- 作者认证：字节跳动 服务端开发工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 后端/服务端，C++ 开发，面试内容集中在 Linux/OS：排查工具；网络：RPC/协议；中间件/分布式：分布式基础。
- 面试内容整理：
  - Linux/OS：排查工具
  - 网络：RPC/协议
  - 中间件/分布式：分布式基础
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor；Mini Redis / MySQL / 分布式后置主线

### 062. [25秋招WXG后端面经](https://www.nowcoder.com/feed/main/detail/2600998)

- 时间：2025-05-10
- 公司/组织：WXG
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：未标明
- 作者认证：门头沟学院 Java
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 Linux/OS：fd/系统调用/IO；网络：TCP/UDP/HTTP、连接状态、epoll/Reactor；中间件/分布式：分布式基础。
- 面试内容整理：
  - Linux/OS：fd/系统调用/IO
  - 网络：TCP/UDP/HTTP、连接状态、epoll/Reactor
  - 中间件/分布式：分布式基础
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor；Mini Redis / MySQL / 分布式后置主线

### 063. [腾讯日常实习一面面经（2027暑期向）（有点非常规。。。）](https://www.nowcoder.com/feed/main/detail/2805283)

- 时间：2026-03-10
- 公司/组织：字节 / 腾讯
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：一面
- 作者认证：字节跳动 后端工程师(实习)
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 项目/工程：项目深挖；手撕/算法：动态规划/字符串、生产级代码，并涉及 动态规划/字符串、手写数据结构/复杂度分析。
- 面试内容整理：
  - 项目/工程：项目深挖
  - 手撕/算法：动态规划/字符串、生产级代码
- 手撕/代码：动态规划/字符串、手写数据结构/复杂度分析
- 对你规划的用处：项目 README、压测、debug 和面试讲稿；每周 2-3 题保持手感

### 064. [4.2字节后端一面](https://www.nowcoder.com/feed/main/detail/2826230)

- 时间：2026-04-02
- 公司/组织：字节
- 岗位/方向：Infra / 基础架构，C++ 后端/服务端，C++ 开发
- 轮次：一面
- 作者认证：四川大学 Java
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 后端/服务端，C++ 开发，面试内容集中在 C++：内存管理；中间件/分布式：MySQL/数据库；项目/工程：项目深挖。
- 面试内容整理：
  - C++：内存管理
  - 中间件/分布式：MySQL/数据库
  - 项目/工程：项目深挖
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Mini Redis / MySQL / 分布式后置主线；项目 README、压测、debug 和面试讲稿

### 065. [数据库内核开发 - 社招面经](https://www.nowcoder.com/discuss/721384389753446400)

- 时间：2025-05-10
- 公司/组织：阿里 / 京东 / 拼多多
- 岗位/方向：Infra / 基础架构，C++ 开发
- 轮次：笔试 / 一面 / 二面 / OC
- 作者认证：上海邦德职业技术学院 数据库工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 开发，面试内容集中在 C++：智能指针、STL 容器、内存管理、const/static/volatile；并发：线程/线程池、锁/条件变量、atomic/CAS；Linux/OS：进程/线程/调度、fd/系统调用/IO、排查工具；网络：TCP/UDP/HTTP、epoll/Reactor、RPC/协议，并涉及 链表/树/图、TopK/堆/排序、动态规划/字符串、手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：智能指针、STL 容器、内存管理、const/static/volatile
  - 并发：线程/线程池、锁/条件变量、atomic/CAS
  - Linux/OS：进程/线程/调度、fd/系统调用/IO、排查工具
  - 网络：TCP/UDP/HTTP、epoll/Reactor、RPC/协议
  - 中间件/分布式：MySQL/数据库、分布式基础、存储系统
  - 项目/工程：项目深挖、工程工具、性能压测
- 手撕/代码：链表/树/图、TopK/堆/排序、动态规划/字符串、手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor

### 066. [字节国际电商提前批一二面经](https://www.nowcoder.com/discuss/654454457932992512)

- 时间：2024-08-20
- 公司/组织：字节
- 岗位/方向：Infra / 基础架构，C++ 开发
- 轮次：一面 / 二面
- 作者认证：四川大学 golang
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 开发，面试内容集中在 C++：STL 容器；并发：线程/线程池；Linux/OS：进程/线程/调度；网络：RPC/协议，并涉及 TopK/堆/排序、手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：STL 容器
  - 并发：线程/线程池
  - Linux/OS：进程/线程/调度
  - 网络：RPC/协议
  - 中间件/分布式：Redis/缓存、MySQL/数据库、分布式基础
  - 项目/工程：项目深挖
- 手撕/代码：TopK/堆/排序、手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor

### 067. [百度c++面经](https://www.nowcoder.com/feed/main/detail/2322934)

- 时间：2024-08-23
- 公司/组织：百度
- 岗位/方向：Infra / 基础架构，C++ 开发
- 轮次：一面
- 作者认证：中南大学 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 开发，面试内容集中在 C++：智能指针、对象模型/虚函数；网络：TCP/UDP/HTTP、RPC/协议；中间件/分布式：Kafka/消息队列；项目/工程：项目深挖。
- 面试内容整理：
  - C++：智能指针、对象模型/虚函数
  - 网络：TCP/UDP/HTTP、RPC/协议
  - 中间件/分布式：Kafka/消息队列
  - 项目/工程：项目深挖
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week6 + 项目线：socket、epoll、Reactor；Mini Redis / MySQL / 分布式后置主线；项目 README、压测、debug 和面试讲稿

### 068. [百度后端研发oc，两面面经](https://www.nowcoder.com/feed/main/detail/2565884)

- 时间：2025-04-02
- 公司/组织：百度
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：一面 / OC
- 作者认证：中南大学 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 中间件/分布式：分布式基础；项目/工程：项目深挖。
- 面试内容整理：
  - 中间件/分布式：分布式基础
  - 项目/工程：项目深挖
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Mini Redis / MySQL / 分布式后置主线；项目 README、压测、debug 和面试讲稿

### 069. [美团暑期实习后端 面经](https://www.nowcoder.com/feed/main/detail/2562354)

- 时间：2025-03-24
- 公司/组织：字节 / 美团
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：未标明
- 作者认证：门头沟学院 后端工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 项目/工程：项目深挖。
- 面试内容整理：
  - 项目/工程：项目深挖
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：项目 README、压测、debug 和面试讲稿

### 070. [腾讯ieg游戏引擎面经](https://www.nowcoder.com/feed/main/detail/2612039)

- 时间：2025-06-04
- 公司/组织：腾讯
- 岗位/方向：Infra / 基础架构，C++ 开发
- 轮次：未标明
- 作者认证：中国科学技术大学 引擎开发
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 开发，面试内容集中在 C++：RAII、STL 容器、对象模型/虚函数、内存管理、const/static/volatile；中间件/分布式：存储系统。
- 面试内容整理：
  - C++：RAII、STL 容器、对象模型/虚函数、内存管理、const/static/volatile
  - 中间件/分布式：存储系统
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Mini Redis / MySQL / 分布式后置主线

### 071. [快手游戏服务端开发一面](https://www.nowcoder.com/feed/main/detail/2348644)

- 时间：2024-08-31
- 公司/组织：快手
- 岗位/方向：Infra / 基础架构，C++ 后端/服务端，C++ 开发
- 轮次：一面 / 二面
- 作者认证：杭州电子科技大学 后端工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 后端/服务端，C++ 开发，面试内容集中在 中间件/分布式：MySQL/数据库；项目/工程：项目深挖；手撕/算法：链表/树/图、生产级代码，并涉及 链表/树/图、手写数据结构/复杂度分析。
- 面试内容整理：
  - 中间件/分布式：MySQL/数据库
  - 项目/工程：项目深挖
  - 手撕/算法：链表/树/图、生产级代码
- 手撕/代码：链表/树/图、手写数据结构/复杂度分析
- 对你规划的用处：Mini Redis / MySQL / 分布式后置主线；项目 README、压测、debug 和面试讲稿；每周 2-3 题保持手感

### 072. [秋招公司面经](https://www.nowcoder.com/discuss/662996951700451328)

- 时间：2024-10-11
- 公司/组织：海康
- 岗位/方向：Infra / 基础架构，C++ 开发
- 轮次：一面 / 技术面
- 作者认证：广州大学 Java
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 开发，面试内容集中在 C++：STL 容器、内存管理；中间件/分布式：Redis/缓存、MySQL/数据库、存储系统；项目/工程：项目深挖、性能压测。
- 面试内容整理：
  - C++：STL 容器、内存管理
  - 中间件/分布式：Redis/缓存、MySQL/数据库、存储系统
  - 项目/工程：项目深挖、性能压测
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Mini Redis / MySQL / 分布式后置主线；项目 README、压测、debug 和面试讲稿

### 073. [字节跳动+后端开发面经](https://www.nowcoder.com/discuss/779307977856626688)

- 时间：2025-08-12
- 公司/组织：字节
- 岗位/方向：Infra / 基础架构，C++ 后端/服务端，C++ 开发
- 轮次：OC
- 作者认证：杭州电子科技大学 大数据开发工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 后端/服务端，C++ 开发，面试内容集中在 C++：RAII、拷贝/移动语义、智能指针、对象模型/虚函数、内存管理；并发：线程/线程池、锁/条件变量；Linux/OS：进程/线程/调度、fd/系统调用/IO；网络：TCP/UDP/HTTP、连接状态、epoll/Reactor，并涉及 链表/树/图、动态规划/字符串。
- 面试内容整理：
  - C++：RAII、拷贝/移动语义、智能指针、对象模型/虚函数、内存管理
  - 并发：线程/线程池、锁/条件变量
  - Linux/OS：进程/线程/调度、fd/系统调用/IO
  - 网络：TCP/UDP/HTTP、连接状态、epoll/Reactor
  - 中间件/分布式：MySQL/数据库、存储系统
  - 项目/工程：项目深挖
- 手撕/代码：链表/树/图、动态规划/字符串
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor

### 074. [虾皮后端面经（一面二面）](https://www.nowcoder.com/feed/main/detail/2720424)

- 时间：2025-10-19
- 公司/组织：虾皮
- 岗位/方向：Infra / 基础架构，C++ 后端/服务端，C++ 开发
- 轮次：一面 / 二面
- 作者认证：门头沟学院 Java
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 后端/服务端，C++ 开发，面试内容集中在 中间件/分布式：MySQL/数据库、存储系统。
- 面试内容整理：
  - 中间件/分布式：MySQL/数据库、存储系统
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Mini Redis / MySQL / 分布式后置主线

### 075. [美团后端开发面经](https://www.nowcoder.com/feed/main/detail/2500666)

- 时间：2024-12-13
- 公司/组织：美团
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：一面 / hr面
- 作者认证：门头沟学院 研发工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 并发：线程/线程池；中间件/分布式：MySQL/数据库；项目/工程：项目深挖；手撕/算法：链表/树/图，并涉及 线程池/阻塞队列、链表/树/图。
- 面试内容整理：
  - 并发：线程/线程池
  - 中间件/分布式：MySQL/数据库
  - 项目/工程：项目深挖
  - 手撕/算法：链表/树/图
- 手撕/代码：线程池/阻塞队列、链表/树/图
- 对你规划的用处：Week7-8：线程、锁、线程池、异步日志；Mini Redis / MySQL / 分布式后置主线；项目 README、压测、debug 和面试讲稿；每周 2-3 题保持手感

### 076. [字节生活服务(三面挂)](https://www.nowcoder.com/feed/main/detail/2704734)

- 时间：2025-09-28
- 公司/组织：字节 / 抖音
- 岗位/方向：Infra / 基础架构，C++ 开发
- 轮次：三面
- 作者认证：山东师范大学 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 开发，面试内容集中在 C++：STL 容器、对象模型/虚函数、内存管理；并发：线程/线程池；中间件/分布式：存储系统；手撕/算法：二分/滑窗/TopK，并涉及 TopK/堆/排序。
- 面试内容整理：
  - C++：STL 容器、对象模型/虚函数、内存管理
  - 并发：线程/线程池
  - 中间件/分布式：存储系统
  - 手撕/算法：二分/滑窗/TopK
- 手撕/代码：TopK/堆/排序
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Mini Redis / MySQL / 分布式后置主线；每周 2-3 题保持手感

### 077. [腾讯TEG研发管理部面经（三轮技术+HR）](https://www.nowcoder.com/feed/main/detail/2588590)

- 时间：2025-04-19
- 公司/组织：腾讯
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：未标明
- 作者认证：厦门大学 后端工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 C++：内存管理。
- 面试内容整理：
  - C++：内存管理
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理

### 078. [美团后端一面面经 C++](https://www.nowcoder.com/discuss/735242848370425856)

- 时间：2025-04-01
- 公司/组织：美团
- 岗位/方向：Infra / 基础架构，C++ 后端/服务端，C++ 开发
- 轮次：一面
- 作者认证：东南大学 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 后端/服务端，C++ 开发，面试内容集中在 C++：对象模型/虚函数、内存管理；中间件/分布式：Redis/缓存、MySQL/数据库、分布式基础；项目/工程：项目深挖；手撕/算法：缓存题、链表/树/图，并涉及 链表/树/图。
- 面试内容整理：
  - C++：对象模型/虚函数、内存管理
  - 中间件/分布式：Redis/缓存、MySQL/数据库、分布式基础
  - 项目/工程：项目深挖
  - 手撕/算法：缓存题、链表/树/图
- 手撕/代码：链表/树/图
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Mini Redis / MySQL / 分布式后置主线；项目 README、压测、debug 和面试讲稿；每周 2-3 题保持手感

### 079. [字节十三面（附面经），终于战胜...（下）](https://www.nowcoder.com/feed/main/detail/2751996)

- 时间：2025-11-26
- 公司/组织：字节 / 腾讯
- 岗位/方向：Infra / 基础架构，C++ 开发
- 轮次：三面
- 作者认证：腾讯 客户端开发(准入职)
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 开发，面试内容集中在 中间件/分布式：MySQL/数据库、存储系统；项目/工程：项目深挖、性能压测；手撕/算法：二分/滑窗/TopK，并涉及 TopK/堆/排序。
- 面试内容整理：
  - 中间件/分布式：MySQL/数据库、存储系统
  - 项目/工程：项目深挖、性能压测
  - 手撕/算法：二分/滑窗/TopK
- 手撕/代码：TopK/堆/排序
- 对你规划的用处：Mini Redis / MySQL / 分布式后置主线；项目 README、压测、debug 和面试讲稿；每周 2-3 题保持手感

### 080. [26届秋招面经 ～ 网易雷火](https://www.nowcoder.com/feed/main/detail/2687434)

- 时间：2025-10-27
- 公司/组织：网易
- 岗位/方向：Infra / 基础架构，C++ 开发
- 轮次：笔试 / 一面 / 二面
- 作者认证：门头沟学院 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 开发，面试内容集中在 C++：RAII、拷贝/移动语义；并发：线程/线程池；Linux/OS：进程/线程/调度、fd/系统调用/IO；网络：TCP/UDP/HTTP，并涉及 动态规划/字符串。
- 面试内容整理：
  - C++：RAII、拷贝/移动语义
  - 并发：线程/线程池
  - Linux/OS：进程/线程/调度、fd/系统调用/IO
  - 网络：TCP/UDP/HTTP
  - 中间件/分布式：MySQL/数据库
  - AI Infra：LLM Serving
- 手撕/代码：动态规划/字符串
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor

### 081. [腾讯C++后端一面面经](https://www.nowcoder.com/discuss/791004631638855680)

- 时间：2025-08-29
- 公司/组织：腾讯
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：一面 / OC
- 作者认证：门头沟学院 后端工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 C++：模板/泛型；网络：TCP/UDP/HTTP、RPC/协议；中间件/分布式：Redis/缓存、MySQL/数据库、Kafka/消息队列；手撕/算法：缓存题、动态规划/字符串、生产级代码，并涉及 动态规划/字符串、手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：模板/泛型
  - 网络：TCP/UDP/HTTP、RPC/协议
  - 中间件/分布式：Redis/缓存、MySQL/数据库、Kafka/消息队列
  - 手撕/算法：缓存题、动态规划/字符串、生产级代码
- 手撕/代码：动态规划/字符串、手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week6 + 项目线：socket、epoll、Reactor；Mini Redis / MySQL / 分布式后置主线；每周 2-3 题保持手感

### 082. [cpp c++面经分享](https://www.nowcoder.com/discuss/820064405449625600)

- 时间：2025-11-17
- 公司/组织：字节 / 米哈游 / 海康
- 岗位/方向：AI Infra / 大模型基础设施，Infra / 基础架构，C++ 后端/服务端
- 轮次：笔试 / 一面 / 二面 / 三面
- 作者认证：Université d’Auvergne-Clermont-Ferrand 1 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，Infra / 基础架构，C++ 后端/服务端，面试内容集中在 C++：RAII、拷贝/移动语义、智能指针、STL 容器、对象模型/虚函数、内存管理、const/static/volatile；并发：线程/线程池、锁/条件变量；Linux/OS：进程/线程/调度；网络：TCP/UDP/HTTP、连接状态、epoll/Reactor、RPC/协议，并涉及 线程池/阻塞队列、链表/树/图、TopK/堆/排序、动态规划/字符串、手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：RAII、拷贝/移动语义、智能指针、STL 容器、对象模型/虚函数、内存管理、const/static/volatile
  - 并发：线程/线程池、锁/条件变量
  - Linux/OS：进程/线程/调度
  - 网络：TCP/UDP/HTTP、连接状态、epoll/Reactor、RPC/协议
  - 中间件/分布式：MySQL/数据库、分布式基础、存储系统
  - AI Infra：CUDA/GPU
- 手撕/代码：线程池/阻塞队列、链表/树/图、TopK/堆/排序、动态规划/字符串、手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor

### 083. [4.15 暑期腾讯WXG三面，吓死人](https://www.nowcoder.com/feed/main/detail/2835749)

- 时间：2026-04-17
- 公司/组织：腾讯 / WXG
- 岗位/方向：Infra / 基础架构，C++ 开发
- 轮次：三面
- 作者认证：未显示
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 开发，面试内容集中在 并发：线程/线程池；中间件/分布式：MySQL/数据库；项目/工程：项目深挖；手撕/算法：链表/树/图，并涉及 线程池/阻塞队列、链表/树/图。
- 面试内容整理：
  - 并发：线程/线程池
  - 中间件/分布式：MySQL/数据库
  - 项目/工程：项目深挖
  - 手撕/算法：链表/树/图
- 手撕/代码：线程池/阻塞队列、链表/树/图
- 对你规划的用处：Week7-8：线程、锁、线程池、异步日志；Mini Redis / MySQL / 分布式后置主线；项目 README、压测、debug 和面试讲稿；每周 2-3 题保持手感

### 084. [滴滴后端提前批面经（三轮）](https://www.nowcoder.com/feed/main/detail/2316902)

- 时间：2024-08-13
- 公司/组织：腾讯 / 百度 / 滴滴
- 岗位/方向：Infra / 基础架构，C++ 后端/服务端，C++ 开发
- 轮次：一面
- 作者认证：清华大学 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 后端/服务端，C++ 开发，面试内容集中在 C++：对象模型/虚函数、const/static/volatile；并发：线程/线程池；中间件/分布式：存储系统；项目/工程：项目深挖，并涉及 手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：对象模型/虚函数、const/static/volatile
  - 并发：线程/线程池
  - 中间件/分布式：存储系统
  - 项目/工程：项目深挖
  - 手撕/算法：生产级代码
- 手撕/代码：手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Mini Redis / MySQL / 分布式后置主线；项目 README、压测、debug 和面试讲稿

### 085. [华为OD-C++开发面经-24届空挡](https://www.nowcoder.com/discuss/869158187847512064)

- 时间：2026-04-02
- 公司/组织：华为 / OD
- 岗位/方向：Infra / 基础架构，C++ 开发
- 轮次：笔试 / 一面 / 二面 / 三面
- 作者认证：南京邮电大学 Java
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 开发，面试内容集中在 C++：拷贝/移动语义、智能指针、STL 容器、对象模型/虚函数、内存管理；Linux/OS：排查工具；中间件/分布式：MySQL/数据库；项目/工程：项目深挖、工程工具，并涉及 链表/树/图、TopK/堆/排序、动态规划/字符串、手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：拷贝/移动语义、智能指针、STL 容器、对象模型/虚函数、内存管理
  - Linux/OS：排查工具
  - 中间件/分布式：MySQL/数据库
  - 项目/工程：项目深挖、工程工具
  - 手撕/算法：链表/树/图、二分/滑窗/TopK、动态规划/字符串、生产级代码
- 手撕/代码：链表/树/图、TopK/堆/排序、动态规划/字符串、手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week4-5：Linux 系统编程与 OS 基础；Mini Redis / MySQL / 分布式后置主线；项目 README、压测、debug 和面试讲稿

### 086. [字节三面-业务中台（过）](https://www.nowcoder.com/feed/main/detail/2613766)

- 时间：2025-06-04
- 公司/组织：字节 / 美团
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：三面 / HR面
- 作者认证：东北大学 后端工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 C++：内存管理；Linux/OS：虚拟内存/mmap/COW；手撕/算法：二分/滑窗/TopK，并涉及 TopK/堆/排序。
- 面试内容整理：
  - C++：内存管理
  - Linux/OS：虚拟内存/mmap/COW
  - 手撕/算法：二分/滑窗/TopK
- 手撕/代码：TopK/堆/排序
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week4-5：Linux 系统编程与 OS 基础；每周 2-3 题保持手感

### 087. [腾讯CSIG一二三+HR面经验+timeline（已OC）](https://www.nowcoder.com/discuss/750097981927325696)

- 时间：2025-05-09
- 公司/组织：腾讯
- 岗位/方向：Infra / 基础架构，C++ 开发
- 轮次：二面 / HR面 / OC
- 作者认证：门头沟学院 Web前端
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 开发，面试内容集中在 网络：TCP/UDP/HTTP；中间件/分布式：Redis/缓存；项目/工程：项目深挖；手撕/算法：缓存题、动态规划/字符串，并涉及 动态规划/字符串。
- 面试内容整理：
  - 网络：TCP/UDP/HTTP
  - 中间件/分布式：Redis/缓存
  - 项目/工程：项目深挖
  - 手撕/算法：缓存题、动态规划/字符串
- 手撕/代码：动态规划/字符串
- 对你规划的用处：Week6 + 项目线：socket、epoll、Reactor；Mini Redis / MySQL / 分布式后置主线；项目 README、压测、debug 和面试讲稿；每周 2-3 题保持手感

### 088. [tme腾讯音乐 后台开发一面](https://www.nowcoder.com/feed/main/detail/2606015)

- 时间：2025-05-19
- 公司/组织：腾讯
- 岗位/方向：Infra / 基础架构，C++ 后端/服务端，C++ 开发
- 轮次：一面 / OC
- 作者认证：北京邮电大学 算法工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 后端/服务端，C++ 开发，面试内容集中在 C++：智能指针、STL 容器、const/static/volatile；并发：线程/线程池；Linux/OS：进程/线程/调度；网络：TCP/UDP/HTTP、连接状态、epoll/Reactor，并涉及 链表/树/图、动态规划/字符串。
- 面试内容整理：
  - C++：智能指针、STL 容器、const/static/volatile
  - 并发：线程/线程池
  - Linux/OS：进程/线程/调度
  - 网络：TCP/UDP/HTTP、连接状态、epoll/Reactor
  - 中间件/分布式：MySQL/数据库、分布式基础、存储系统
  - 项目/工程：项目深挖
- 手撕/代码：链表/树/图、动态规划/字符串
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor

### 089. [网易雷火交叉面第一面嬉皮笑脸另一面唯唯诺诺（居然过了）](https://www.nowcoder.com/feed/main/detail/2664533)

- 时间：2025-08-26
- 公司/组织：网易
- 岗位/方向：Infra / 基础架构，C++ 后端/服务端，C++ 开发
- 轮次：一面 / OC
- 作者认证：深圳大学 后端工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 后端/服务端，C++ 开发，面试内容集中在 C++：对象模型/虚函数、内存管理；网络：TCP/UDP/HTTP；中间件/分布式：MySQL/数据库；项目/工程：项目深挖，并涉及 链表/树/图。
- 面试内容整理：
  - C++：对象模型/虚函数、内存管理
  - 网络：TCP/UDP/HTTP
  - 中间件/分布式：MySQL/数据库
  - 项目/工程：项目深挖
  - 手撕/算法：链表/树/图
- 手撕/代码：链表/树/图
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week6 + 项目线：socket、epoll、Reactor；Mini Redis / MySQL / 分布式后置主线；项目 README、压测、debug 和面试讲稿

### 090. [[VIVO OC]3年经验汽车C++开发 社招面经](https://www.nowcoder.com/discuss/838085726678892544)

- 时间：2026-02-20
- 公司/组织：小米 / 理想 / 商汤
- 岗位/方向：AI Infra / 大模型基础设施，Infra / 基础架构，C++ 后端/服务端
- 轮次：笔试 / 一面 / 二面 / 三面
- 作者认证：吉利控股 C++安全开发
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，Infra / 基础架构，C++ 后端/服务端，面试内容集中在 C++：RAII、拷贝/移动语义、智能指针、STL 容器、对象模型/虚函数、内存管理、模板/泛型；并发：线程/线程池、锁/条件变量、atomic/CAS、生产者消费者；Linux/OS：进程/线程/调度、fd/系统调用/IO、排查工具；网络：TCP/UDP/HTTP、epoll/Reactor、RPC/协议，并涉及 链表/树/图、TopK/堆/排序、手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：RAII、拷贝/移动语义、智能指针、STL 容器、对象模型/虚函数、内存管理、模板/泛型
  - 并发：线程/线程池、锁/条件变量、atomic/CAS、生产者消费者
  - Linux/OS：进程/线程/调度、fd/系统调用/IO、排查工具
  - 网络：TCP/UDP/HTTP、epoll/Reactor、RPC/协议
  - 中间件/分布式：Redis/缓存、MySQL/数据库、Kafka/消息队列
  - AI Infra：LLM Serving、CUDA/GPU
- 手撕/代码：链表/树/图、TopK/堆/排序、手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor

### 091. [拼多多服务端一面面经，全程项目](https://www.nowcoder.com/feed/main/detail/2560003)

- 时间：2025-03-19
- 公司/组织：拼多多
- 岗位/方向：Infra / 基础架构，C++ 后端/服务端，C++ 开发
- 轮次：笔试 / 一面
- 作者认证：河北大学 后端工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 后端/服务端，C++ 开发，面试内容集中在 项目/工程：项目深挖；手撕/算法：链表/树/图，并涉及 链表/树/图。
- 面试内容整理：
  - 项目/工程：项目深挖
  - 手撕/算法：链表/树/图
- 手撕/代码：链表/树/图
- 对你规划的用处：项目 README、压测、debug 和面试讲稿；每周 2-3 题保持手感

### 092. [美团逆天后端二面凉经](https://www.nowcoder.com/feed/main/detail/2352456)

- 时间：2024-09-08
- 公司/组织：字节 / 腾讯 / 美团
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：二面
- 作者认证：门头沟学院 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 C++：智能指针；Linux/OS：进程/线程/调度；网络：RPC/协议。
- 面试内容整理：
  - C++：智能指针
  - Linux/OS：进程/线程/调度
  - 网络：RPC/协议
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor

### 093. [华为OD-C++面经](https://www.nowcoder.com/discuss/806133002932649984)

- 时间：2025-10-10
- 公司/组织：华为 / OD
- 岗位/方向：Infra / 基础架构，C++ 开发
- 轮次：未标明
- 作者认证：华为 HR
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 开发，面试内容集中在 C++：智能指针、STL 容器、对象模型/虚函数；网络：TCP/UDP/HTTP；中间件/分布式：MySQL/数据库；手撕/算法：链表/树/图，并涉及 链表/树/图。
- 面试内容整理：
  - C++：智能指针、STL 容器、对象模型/虚函数
  - 网络：TCP/UDP/HTTP
  - 中间件/分布式：MySQL/数据库
  - 手撕/算法：链表/树/图
- 手撕/代码：链表/树/图
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week6 + 项目线：socket、epoll、Reactor；Mini Redis / MySQL / 分布式后置主线；每周 2-3 题保持手感

### 094. [美团暑期实习后端开发四面面经](https://www.nowcoder.com/feed/main/detail/2604119)

- 时间：2025-05-21
- 公司/组织：美团
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：二面 / 四面
- 作者认证：门头沟学院 Java
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 中间件/分布式：Redis/缓存；项目/工程：项目深挖、工程工具；手撕/算法：缓存题、链表/树/图，并涉及 链表/树/图。
- 面试内容整理：
  - 中间件/分布式：Redis/缓存
  - 项目/工程：项目深挖、工程工具
  - 手撕/算法：缓存题、链表/树/图
- 手撕/代码：链表/树/图
- 对你规划的用处：Mini Redis / MySQL / 分布式后置主线；项目 README、压测、debug 和面试讲稿；每周 2-3 题保持手感

### 095. [华为OD面经-双非](https://www.nowcoder.com/feed/main/detail/2726408)

- 时间：2025-10-25
- 公司/组织：华为 / OD
- 岗位/方向：Infra / 基础架构，C++ 开发
- 轮次：二面 / OC
- 作者认证：安庆师范大学 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 开发，面试内容集中在 C++：对象模型/虚函数、内存管理；中间件/分布式：MySQL/数据库；项目/工程：项目深挖；手撕/算法：动态规划/字符串、生产级代码，并涉及 动态规划/字符串、手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：对象模型/虚函数、内存管理
  - 中间件/分布式：MySQL/数据库
  - 项目/工程：项目深挖
  - 手撕/算法：动态规划/字符串、生产级代码
- 手撕/代码：动态规划/字符串、手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Mini Redis / MySQL / 分布式后置主线；项目 README、压测、debug 和面试讲稿；每周 2-3 题保持手感

### 096. [PDD提前批-后端一面面经](https://www.nowcoder.com/feed/main/detail/2649425)

- 时间：2025-08-05
- 公司/组织：PDD
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：一面
- 作者认证：武汉大学 Java
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 并发：atomic/CAS；手撕/算法：生产级代码，并涉及 手写数据结构/复杂度分析。
- 面试内容整理：
  - 并发：atomic/CAS
  - 手撕/算法：生产级代码
- 手撕/代码：手写数据结构/复杂度分析
- 对你规划的用处：Week7-8：线程、锁、线程池、异步日志；每周 2-3 题保持手感

### 097. [百度云基础架构暑期一面](https://www.nowcoder.com/feed/main/detail/2564768)

- 时间：2025-03-24
- 公司/组织：百度 / 微软
- 岗位/方向：Infra / 基础架构，C++ 后端/服务端，C++ 开发
- 轮次：一面
- 作者认证：微软 后端开发实习生
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 后端/服务端，C++ 开发，面试内容集中在 C++：对象模型/虚函数、const/static/volatile；Linux/OS：排查工具；项目/工程：项目深挖。
- 面试内容整理：
  - C++：对象模型/虚函数、const/static/volatile
  - Linux/OS：排查工具
  - 项目/工程：项目深挖
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week4-5：Linux 系统编程与 OS 基础；项目 README、压测、debug 和面试讲稿

### 098. [小红书/字节跳动三面凉经](https://www.nowcoder.com/feed/main/detail/2275107)

- 时间：2024-07-09
- 公司/组织：字节 / 百度
- 岗位/方向：Infra / 基础架构，C++ 开发
- 轮次：一面 / 三面
- 作者认证：门头沟学院 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 开发，面试内容集中在 C++：拷贝/移动语义；网络：TCP/UDP/HTTP；中间件/分布式：Redis/缓存、存储系统；项目/工程：项目深挖，并涉及 链表/树/图、手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：拷贝/移动语义
  - 网络：TCP/UDP/HTTP
  - 中间件/分布式：Redis/缓存、存储系统
  - 项目/工程：项目深挖
  - 手撕/算法：链表/树/图、生产级代码
- 手撕/代码：链表/树/图、手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week6 + 项目线：socket、epoll、Reactor；Mini Redis / MySQL / 分布式后置主线；项目 README、压测、debug 和面试讲稿

### 099. [字节C++日常实习面经](https://www.nowcoder.com/discuss/788099969260457984)

- 时间：2025-08-21
- 公司/组织：字节
- 岗位/方向：Infra / 基础架构，C++ 后端/服务端，C++ 开发
- 轮次：一面 / 二面 / hr面 / OC
- 作者认证：中国科学技术大学 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 后端/服务端，C++ 开发，面试内容集中在 C++：STL 容器、内存管理、模板/泛型、异常安全；Linux/OS：进程/线程/调度、虚拟内存/mmap/COW、fd/系统调用/IO；网络：TCP/UDP/HTTP、RPC/协议；中间件/分布式：分布式基础、存储系统，并涉及 链表/树/图、TopK/堆/排序、手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：STL 容器、内存管理、模板/泛型、异常安全
  - Linux/OS：进程/线程/调度、虚拟内存/mmap/COW、fd/系统调用/IO
  - 网络：TCP/UDP/HTTP、RPC/协议
  - 中间件/分布式：分布式基础、存储系统
  - 项目/工程：项目深挖
  - 手撕/算法：链表/树/图、二分/滑窗/TopK、生产级代码
- 手撕/代码：链表/树/图、TopK/堆/排序、手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor；Mini Redis / MySQL / 分布式后置主线

### 100. [数据库内核开发 - 社招面经2](https://www.nowcoder.com/discuss/743507475093078016)

- 时间：2025-05-20
- 公司/组织：百度
- 岗位/方向：Infra / 基础架构，C++ 开发
- 轮次：未标明
- 作者认证：上海邦德职业技术学院 数据库工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 开发，面试内容集中在 C++：RAII、拷贝/移动语义、智能指针、模板/泛型、异常安全；Linux/OS：fd/系统调用/IO；中间件/分布式：MySQL/数据库、分布式基础；项目/工程：项目深挖。
- 面试内容整理：
  - C++：RAII、拷贝/移动语义、智能指针、模板/泛型、异常安全
  - Linux/OS：fd/系统调用/IO
  - 中间件/分布式：MySQL/数据库、分布式基础
  - 项目/工程：项目深挖
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week4-5：Linux 系统编程与 OS 基础；Mini Redis / MySQL / 分布式后置主线；项目 README、压测、debug 和面试讲稿

### 101. [滴滴面经](https://www.nowcoder.com/feed/main/detail/2400824)

- 时间：2024-09-28
- 公司/组织：滴滴
- 岗位/方向：Infra / 基础架构，C++ 开发
- 轮次：hr面 / OC
- 作者认证：California State University,San Bernardino C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 开发，面试内容集中在 C++：对象模型/虚函数、内存管理；Linux/OS：排查工具；项目/工程：项目深挖。
- 面试内容整理：
  - C++：对象模型/虚函数、内存管理
  - Linux/OS：排查工具
  - 项目/工程：项目深挖
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week4-5：Linux 系统编程与 OS 基础；项目 README、压测、debug 和面试讲稿

### 102. [美团C++后端二面面经](https://www.nowcoder.com/discuss/794223706988879872)

- 时间：2025-09-07
- 公司/组织：美团
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：二面
- 作者认证：门头沟学院 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 C++：拷贝/移动语义；Linux/OS：进程/线程/调度、fd/系统调用/IO。
- 面试内容整理：
  - C++：拷贝/移动语义
  - Linux/OS：进程/线程/调度、fd/系统调用/IO
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week4-5：Linux 系统编程与 OS 基础

### 103. [米哈游后端开发 一面凉经](https://www.nowcoder.com/feed/main/detail/2389671)

- 时间：2024-09-24
- 公司/组织：米哈游
- 岗位/方向：Infra / 基础架构，C++ 后端/服务端，C++ 开发
- 轮次：一面
- 作者认证：上海交通大学 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 后端/服务端，C++ 开发，面试内容集中在 C++：STL 容器；并发：锁/条件变量；中间件/分布式：MySQL/数据库、存储系统。
- 面试内容整理：
  - C++：STL 容器
  - 并发：锁/条件变量
  - 中间件/分布式：MySQL/数据库、存储系统
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Mini Redis / MySQL / 分布式后置主线

### 104. [字节跳动 C++ 面经](https://www.nowcoder.com/discuss/894531017640296448)

- 时间：2026-06-11
- 公司/组织：字节
- 岗位/方向：Infra / 基础架构，C++ 后端/服务端，C++ 开发
- 轮次：未标明
- 作者认证：浙江大学 算法工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 后端/服务端，C++ 开发，面试内容集中在 项目/工程：项目深挖。
- 面试内容整理：
  - 项目/工程：项目深挖
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：项目 README、压测、debug 和面试讲稿

### 105. [汇总篇-快手-C++工程师-广告+搜推面经](https://www.nowcoder.com/discuss/796025128453677056)

- 时间：2025-09-12
- 公司/组织：阿里 / 快手
- 岗位/方向：Infra / 基础架构，C++ 后端/服务端，C++ 开发
- 轮次：一面
- 作者认证：武汉大学 Java
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 后端/服务端，C++ 开发，面试内容集中在 C++：内存管理；并发：锁/条件变量、atomic/CAS；Linux/OS：虚拟内存/mmap/COW、排查工具；中间件/分布式：MySQL/数据库。
- 面试内容整理：
  - C++：内存管理
  - 并发：锁/条件变量、atomic/CAS
  - Linux/OS：虚拟内存/mmap/COW、排查工具
  - 中间件/分布式：MySQL/数据库
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Mini Redis / MySQL / 分布式后置主线

### 106. [美团核心本地 后端 面经](https://www.nowcoder.com/feed/main/detail/2391930)

- 时间：2024-09-24
- 公司/组织：美团
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：未标明
- 作者认证：华南理工大学 后端工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 项目/工程：项目深挖；手撕/算法：链表/树/图、生产级代码，并涉及 链表/树/图、手写数据结构/复杂度分析。
- 面试内容整理：
  - 项目/工程：项目深挖
  - 手撕/算法：链表/树/图、生产级代码
- 手撕/代码：链表/树/图、手写数据结构/复杂度分析
- 对你规划的用处：项目 README、压测、debug 和面试讲稿；每周 2-3 题保持手感

### 107. [字节后端面经](https://www.nowcoder.com/discuss/801171624639692800)

- 时间：2025-09-26
- 公司/组织：字节
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：未标明
- 作者认证：门头沟学院 后端工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 C++：拷贝/移动语义；Linux/OS：进程/线程/调度。
- 面试内容整理：
  - C++：拷贝/移动语义
  - Linux/OS：进程/线程/调度
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week4-5：Linux 系统编程与 OS 基础

### 108. [拼多多服务端开发C++一面面经](https://www.nowcoder.com/feed/main/detail/2554966)

- 时间：2025-03-18
- 公司/组织：拼多多
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：一面
- 作者认证：安徽大学 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 C++：拷贝/移动语义；并发：锁/条件变量；Linux/OS：进程/线程/调度；项目/工程：项目深挖，并涉及 链表/树/图。
- 面试内容整理：
  - C++：拷贝/移动语义
  - 并发：锁/条件变量
  - Linux/OS：进程/线程/调度
  - 项目/工程：项目深挖
  - 手撕/算法：链表/树/图
- 手撕/代码：链表/树/图
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；项目 README、压测、debug 和面试讲稿

### 109. [百度C++/go后端秋招面经 激情拷打90min版](https://www.nowcoder.com/discuss/798562287219920896)

- 时间：2025-09-19
- 公司/组织：百度
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：未标明
- 作者认证：华南理工大学
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 C++：RAII、智能指针、STL 容器、对象模型/虚函数、内存管理；并发：线程/线程池、锁/条件变量；Linux/OS：进程/线程/调度、fd/系统调用/IO；网络：TCP/UDP/HTTP、连接状态，并涉及 TopK/堆/排序、手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：RAII、智能指针、STL 容器、对象模型/虚函数、内存管理
  - 并发：线程/线程池、锁/条件变量
  - Linux/OS：进程/线程/调度、fd/系统调用/IO
  - 网络：TCP/UDP/HTTP、连接状态
  - 中间件/分布式：MySQL/数据库
  - 项目/工程：项目深挖
- 手撕/代码：TopK/堆/排序、手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor

### 110. [拼多多PDD-5.6服务端研发实习生三面面经](https://www.nowcoder.com/discuss/749310973986476032)

- 时间：2025-05-06
- 公司/组织：拼多多 / PDD / 荣耀
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：二面 / 三面
- 作者认证：南京大学 Java
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 项目/工程：项目深挖；手撕/算法：链表/树/图，并涉及 链表/树/图。
- 面试内容整理：
  - 项目/工程：项目深挖
  - 手撕/算法：链表/树/图
- 手撕/代码：链表/树/图
- 对你规划的用处：项目 README、压测、debug 和面试讲稿；每周 2-3 题保持手感

### 111. [今日两篇面经](https://www.nowcoder.com/feed/main/detail/2284979)

- 时间：2024-07-20
- 公司/组织：字节 / 快手
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：一面 / 二面
- 作者认证：南京大学 后端工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 Linux/OS：排查工具；网络：TCP/UDP/HTTP；项目/工程：项目深挖。
- 面试内容整理：
  - Linux/OS：排查工具
  - 网络：TCP/UDP/HTTP
  - 项目/工程：项目深挖
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor；项目 README、压测、debug 和面试讲稿

### 112. [腾讯-微信支付C++ 一面 面经总结](https://www.nowcoder.com/discuss/861198529715245056)

- 时间：2026-03-11
- 公司/组织：腾讯
- 岗位/方向：Infra / 基础架构，C++ 后端/服务端，C++ 开发
- 轮次：一面 / 技术面 / OC
- 作者认证：浙江大学 算法工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 后端/服务端，C++ 开发，面试内容集中在 C++：拷贝/移动语义、智能指针、STL 容器、对象模型/虚函数、内存管理、模板/泛型、const/static/volatile；并发：线程/线程池、锁/条件变量；Linux/OS：进程/线程/调度、虚拟内存/mmap/COW、fd/系统调用/IO、排查工具；网络：TCP/UDP/HTTP、epoll/Reactor、RPC/协议，并涉及 链表/树/图、TopK/堆/排序、动态规划/字符串、手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：拷贝/移动语义、智能指针、STL 容器、对象模型/虚函数、内存管理、模板/泛型、const/static/volatile
  - 并发：线程/线程池、锁/条件变量
  - Linux/OS：进程/线程/调度、虚拟内存/mmap/COW、fd/系统调用/IO、排查工具
  - 网络：TCP/UDP/HTTP、epoll/Reactor、RPC/协议
  - 中间件/分布式：MySQL/数据库、Kafka/消息队列、存储系统
  - AI Infra：LLM Serving
- 手撕/代码：链表/树/图、TopK/堆/排序、动态规划/字符串、手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor

### 113. [快手C++一面-秋招面经](https://www.nowcoder.com/feed/main/detail/2754338)

- 时间：2025-11-27
- 公司/组织：快手
- 岗位/方向：Infra / 基础架构，C++ 开发
- 轮次：一面
- 作者认证：门头沟学院 Java
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 开发，面试内容集中在 C++：STL 容器、对象模型/虚函数；中间件/分布式：MySQL/数据库；项目/工程：性能压测；手撕/算法：链表/树/图、生产级代码，并涉及 手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：STL 容器、对象模型/虚函数
  - 中间件/分布式：MySQL/数据库
  - 项目/工程：性能压测
  - 手撕/算法：链表/树/图、生产级代码
- 手撕/代码：手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Mini Redis / MySQL / 分布式后置主线；项目 README、压测、debug 和面试讲稿；每周 2-3 题保持手感

### 114. [teg db组数据库内核开发一面大败而归](https://www.nowcoder.com/feed/main/detail/2639515)

- 时间：2025-07-23
- 公司/组织：快手
- 岗位/方向：Infra / 基础架构，C++ 开发
- 轮次：一面
- 作者认证：武汉大学 Java
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 开发，面试内容集中在 并发：atomic/CAS；中间件/分布式：MySQL/数据库、分布式基础。
- 面试内容整理：
  - 并发：atomic/CAS
  - 中间件/分布式：MySQL/数据库、分布式基础
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week7-8：线程、锁、线程池、异步日志；Mini Redis / MySQL / 分布式后置主线

### 115. [阿里云 面试 面经](https://www.nowcoder.com/feed/main/detail/2387351)

- 时间：2024-09-30
- 公司/组织：阿里
- 岗位/方向：Infra / 基础架构，C++ 开发
- 轮次：OC
- 作者认证：门头沟学院 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 开发，面试内容集中在 C++：内存管理；并发：锁/条件变量；中间件/分布式：MySQL/数据库。
- 面试内容整理：
  - C++：内存管理
  - 并发：锁/条件变量
  - 中间件/分布式：MySQL/数据库
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Mini Redis / MySQL / 分布式后置主线

### 116. [美团平台 后端 复试面经](https://www.nowcoder.com/feed/main/detail/2391853)

- 时间：2024-09-24
- 公司/组织：腾讯 / 美团
- 岗位/方向：Infra / 基础架构，C++ 后端/服务端，C++ 开发
- 轮次：未标明
- 作者认证：华南理工大学 后端工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 后端/服务端，C++ 开发，面试内容集中在 中间件/分布式：Kafka/消息队列、分布式基础；项目/工程：项目深挖、性能压测；手撕/算法：链表/树/图、生产级代码，并涉及 链表/树/图、手写数据结构/复杂度分析。
- 面试内容整理：
  - 中间件/分布式：Kafka/消息队列、分布式基础
  - 项目/工程：项目深挖、性能压测
  - 手撕/算法：链表/树/图、生产级代码
- 手撕/代码：链表/树/图、手写数据结构/复杂度分析
- 对你规划的用处：Mini Redis / MySQL / 分布式后置主线；项目 README、压测、debug 和面试讲稿；每周 2-3 题保持手感

### 117. [腾讯 wxg 秋招 二面](https://www.nowcoder.com/feed/main/detail/2698851)

- 时间：2025-09-22
- 公司/组织：腾讯
- 岗位/方向：Infra / 基础架构，C++ 开发
- 轮次：笔试 / 二面
- 作者认证：四平职业大学 Java
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 开发，面试内容集中在 网络：TCP/UDP/HTTP、RPC/协议；中间件/分布式：存储系统；手撕/算法：链表/树/图，并涉及 链表/树/图。
- 面试内容整理：
  - 网络：TCP/UDP/HTTP、RPC/协议
  - 中间件/分布式：存储系统
  - 手撕/算法：链表/树/图
- 手撕/代码：链表/树/图
- 对你规划的用处：Week6 + 项目线：socket、epoll、Reactor；Mini Redis / MySQL / 分布式后置主线；每周 2-3 题保持手感

### 118. [腾讯ieg后端秋招面经](https://www.nowcoder.com/discuss/787054343198412800)

- 时间：2025-08-18
- 公司/组织：字节 / 腾讯
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：未标明
- 作者认证：华南理工大学
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 C++：对象模型/虚函数；Linux/OS：fd/系统调用/IO；网络：TCP/UDP/HTTP、连接状态、epoll/Reactor；项目/工程：项目深挖，并涉及 动态规划/字符串、手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：对象模型/虚函数
  - Linux/OS：fd/系统调用/IO
  - 网络：TCP/UDP/HTTP、连接状态、epoll/Reactor
  - 项目/工程：项目深挖
  - 手撕/算法：动态规划/字符串、生产级代码
- 手撕/代码：动态规划/字符串、手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor；项目 README、压测、debug 和面试讲稿

### 119. [华为OD面经-C++算法](https://www.nowcoder.com/discuss/751756760758636544)

- 时间：2025-05-13
- 公司/组织：字节 / 华为 / OD
- 岗位/方向：Infra / 基础架构，C++ 开发
- 轮次：笔试 / 一面 / 二面 / 技术面
- 作者认证：华为 HR
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 开发，面试内容集中在 C++：智能指针、STL 容器、内存管理；并发：线程/线程池；Linux/OS：进程/线程/调度；中间件/分布式：存储系统，并涉及 TopK/堆/排序、手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：智能指针、STL 容器、内存管理
  - 并发：线程/线程池
  - Linux/OS：进程/线程/调度
  - 中间件/分布式：存储系统
  - 项目/工程：项目深挖
  - 手撕/算法：二分/滑窗/TopK、生产级代码
- 手撕/代码：TopK/堆/排序、手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Mini Redis / MySQL / 分布式后置主线

### 120. [bilibili 广告引擎后端一面 -- 最舒服的一集](https://www.nowcoder.com/feed/main/detail/2672856)

- 时间：2025-08-28
- 公司/组织：bilibili
- 岗位/方向：Infra / 基础架构，C++ 后端/服务端，C++ 开发
- 轮次：一面
- 作者认证：华中科技大学 Java
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 后端/服务端，C++ 开发，面试内容集中在 并发：锁/条件变量；中间件/分布式：Redis/缓存、MySQL/数据库、分布式基础；项目/工程：项目深挖、性能压测；手撕/算法：生产级代码，并涉及 手写数据结构/复杂度分析。
- 面试内容整理：
  - 并发：锁/条件变量
  - 中间件/分布式：Redis/缓存、MySQL/数据库、分布式基础
  - 项目/工程：项目深挖、性能压测
  - 手撕/算法：生产级代码
- 手撕/代码：手写数据结构/复杂度分析
- 对你规划的用处：Week7-8：线程、锁、线程池、异步日志；Mini Redis / MySQL / 分布式后置主线；项目 README、压测、debug 和面试讲稿；每周 2-3 题保持手感

### 121. [一份字节tk后端秋招面经奉上](https://www.nowcoder.com/discuss/787606165415796736)

- 时间：2025-08-20
- 公司/组织：字节
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：未标明
- 作者认证：华南理工大学
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 C++：内存管理；网络：TCP/UDP/HTTP；项目/工程：项目深挖。
- 面试内容整理：
  - C++：内存管理
  - 网络：TCP/UDP/HTTP
  - 项目/工程：项目深挖
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week6 + 项目线：socket、epoll、Reactor；项目 README、压测、debug 和面试讲稿

### 122. [美团复活赛一面面经](https://www.nowcoder.com/discuss/673889260646211584)

- 时间：2024-10-10
- 公司/组织：美团
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：一面
- 作者认证：门头沟学院 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 C++：内存管理；项目/工程：项目深挖。
- 面试内容整理：
  - C++：内存管理
  - 项目/工程：项目深挖
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；项目 README、压测、debug 和面试讲稿

### 123. [腾讯CSIG后端开发日常实习一面面经](https://www.nowcoder.com/feed/main/detail/2815096)

- 时间：2026-03-20
- 公司/组织：腾讯
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：一面
- 作者认证：深圳大学 golang
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 项目/工程：项目深挖；手撕/算法：链表/树/图、生产级代码，并涉及 链表/树/图、手写数据结构/复杂度分析。
- 面试内容整理：
  - 项目/工程：项目深挖
  - 手撕/算法：链表/树/图、生产级代码
- 手撕/代码：链表/树/图、手写数据结构/复杂度分析
- 对你规划的用处：项目 README、压测、debug 和面试讲稿；每周 2-3 题保持手感

### 124. [小米c++一面面经](https://www.nowcoder.com/discuss/800081368934834176)

- 时间：2025-09-23
- 公司/组织：小米
- 岗位/方向：Infra / 基础架构，C++ 开发
- 轮次：一面
- 作者认证：未显示
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 开发，面试内容集中在 C++：RAII、对象模型/虚函数；网络：TCP/UDP/HTTP、epoll/Reactor；中间件/分布式：Redis/缓存、MySQL/数据库、存储系统；手撕/算法：动态规划/字符串、生产级代码，并涉及 动态规划/字符串、手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：RAII、对象模型/虚函数
  - 网络：TCP/UDP/HTTP、epoll/Reactor
  - 中间件/分布式：Redis/缓存、MySQL/数据库、存储系统
  - 手撕/算法：动态规划/字符串、生产级代码
- 手撕/代码：动态规划/字符串、手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week6 + 项目线：socket、epoll、Reactor；Mini Redis / MySQL / 分布式后置主线；每周 2-3 题保持手感

### 125. [快手搜索 日常实习一面](https://www.nowcoder.com/feed/main/detail/2574149)

- 时间：2025-04-02
- 公司/组织：快手
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：一面
- 作者认证：门头沟学院 Java
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 C++：内存管理；网络：RPC/协议；项目/工程：项目深挖。
- 面试内容整理：
  - C++：内存管理
  - 网络：RPC/协议
  - 项目/工程：项目深挖
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week6 + 项目线：socket、epoll、Reactor；项目 README、压测、debug 和面试讲稿

### 126. [腾讯-微信支付 C++ 一面 面经 分析](https://www.nowcoder.com/discuss/865880571782717440)

- 时间：2026-03-24
- 公司/组织：腾讯
- 岗位/方向：Infra / 基础架构，C++ 后端/服务端，C++ 开发
- 轮次：一面
- 作者认证：浙江大学 算法工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 后端/服务端，C++ 开发，面试内容集中在 C++：智能指针、STL 容器；并发：线程/线程池；Linux/OS：进程/线程/调度、虚拟内存/mmap/COW、fd/系统调用/IO；网络：TCP/UDP/HTTP、epoll/Reactor、RPC/协议。
- 面试内容整理：
  - C++：智能指针、STL 容器
  - 并发：线程/线程池
  - Linux/OS：进程/线程/调度、虚拟内存/mmap/COW、fd/系统调用/IO
  - 网络：TCP/UDP/HTTP、epoll/Reactor、RPC/协议
  - 中间件/分布式：MySQL/数据库
  - 项目/工程：项目深挖
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor

### 127. [百度面经](https://www.nowcoder.com/discuss/668200936866648064)

- 时间：2024-09-24
- 公司/组织：百度
- 岗位/方向：Infra / 基础架构，C++ 后端/服务端，C++ 开发
- 轮次：未标明
- 作者认证：中国地质大学 Java
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 后端/服务端，C++ 开发，面试内容集中在 C++：STL 容器、内存管理；并发：锁/条件变量；网络：TCP/UDP/HTTP、RPC/协议；中间件/分布式：Redis/缓存、MySQL/数据库、Kafka/消息队列、分布式基础、存储系统，并涉及 TopK/堆/排序、动态规划/字符串。
- 面试内容整理：
  - C++：STL 容器、内存管理
  - 并发：锁/条件变量
  - 网络：TCP/UDP/HTTP、RPC/协议
  - 中间件/分布式：Redis/缓存、MySQL/数据库、Kafka/消息队列、分布式基础、存储系统
  - 项目/工程：项目深挖、工程工具、性能压测
  - 手撕/算法：缓存题、链表/树/图、二分/滑窗/TopK、动态规划/字符串
- 手撕/代码：TopK/堆/排序、动态规划/字符串
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week6 + 项目线：socket、epoll、Reactor；Mini Redis / MySQL / 分布式后置主线

### 128. [字节二面秒挂](https://www.nowcoder.com/feed/main/detail/2809309)

- 时间：2026-03-17
- 公司/组织：字节
- 岗位/方向：Infra / 基础架构，C++ 后端/服务端，C++ 开发
- 轮次：二面
- 作者认证：门头沟学院 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 后端/服务端，C++ 开发，面试内容集中在 C++：STL 容器；中间件/分布式：Redis/缓存、存储系统；手撕/算法：缓存题、动态规划/字符串，并涉及 动态规划/字符串。
- 面试内容整理：
  - C++：STL 容器
  - 中间件/分布式：Redis/缓存、存储系统
  - 手撕/算法：缓存题、动态规划/字符串
- 手撕/代码：动态规划/字符串
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Mini Redis / MySQL / 分布式后置主线；每周 2-3 题保持手感

### 129. [美团移动端 C++开发 二面 面经](https://www.nowcoder.com/discuss/861564385204994048)

- 时间：2026-03-12
- 公司/组织：美团
- 岗位/方向：Infra / 基础架构，C++ 开发
- 轮次：二面 / 技术面 / OC
- 作者认证：浙江大学 算法工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 开发，面试内容集中在 C++：RAII、拷贝/移动语义、智能指针、STL 容器、对象模型/虚函数、内存管理、模板/泛型、异常安全；并发：线程/线程池、锁/条件变量、atomic/CAS、生产者消费者；Linux/OS：进程/线程/调度、fd/系统调用/IO、排查工具；网络：TCP/UDP/HTTP，并涉及 TopK/堆/排序、动态规划/字符串。
- 面试内容整理：
  - C++：RAII、拷贝/移动语义、智能指针、STL 容器、对象模型/虚函数、内存管理、模板/泛型、异常安全
  - 并发：线程/线程池、锁/条件变量、atomic/CAS、生产者消费者
  - Linux/OS：进程/线程/调度、fd/系统调用/IO、排查工具
  - 网络：TCP/UDP/HTTP
  - 中间件/分布式：MySQL/数据库、Kafka/消息队列、存储系统
  - AI Infra：LLM Serving
- 手撕/代码：TopK/堆/排序、动态规划/字符串
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor

### 130. [蚂蚁oceanbase秋招面经](https://www.nowcoder.com/discuss/699018601419870208)

- 时间：2024-12-18
- 公司/组织：阿里 / 蚂蚁 / 字节
- 岗位/方向：Infra / 基础架构，C++ 后端/服务端，C++ 开发
- 轮次：一面 / 二面 / hr面 / OC
- 作者认证：门头沟学院 后端工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 后端/服务端，C++ 开发，面试内容集中在 C++：RAII、对象模型/虚函数、内存管理；并发：线程/线程池、锁/条件变量、生产者消费者；Linux/OS：fd/系统调用/IO；中间件/分布式：Redis/缓存、MySQL/数据库、分布式基础、存储系统，并涉及 链表/树/图、TopK/堆/排序。
- 面试内容整理：
  - C++：RAII、对象模型/虚函数、内存管理
  - 并发：线程/线程池、锁/条件变量、生产者消费者
  - Linux/OS：fd/系统调用/IO
  - 中间件/分布式：Redis/缓存、MySQL/数据库、分布式基础、存储系统
  - 项目/工程：项目深挖
  - 手撕/算法：链表/树/图、二分/滑窗/TopK
- 手撕/代码：链表/树/图、TopK/堆/排序
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Mini Redis / MySQL / 分布式后置主线

### 131. [米哈游 服务器开发方向 C++ 二面 面经](https://www.nowcoder.com/discuss/869118355582509056)

- 时间：2026-04-01
- 公司/组织：米哈游
- 岗位/方向：Infra / 基础架构，C++ 后端/服务端，C++ 开发
- 轮次：二面 / 技术面 / OC
- 作者认证：浙江大学 算法工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 后端/服务端，C++ 开发，面试内容集中在 C++：智能指针、STL 容器、对象模型/虚函数、内存管理、模板/泛型、const/static/volatile；并发：线程/线程池、锁/条件变量、atomic/CAS；Linux/OS：进程/线程/调度、fd/系统调用/IO、排查工具；网络：epoll/Reactor、RPC/协议，并涉及 链表/树/图、TopK/堆/排序、动态规划/字符串。
- 面试内容整理：
  - C++：智能指针、STL 容器、对象模型/虚函数、内存管理、模板/泛型、const/static/volatile
  - 并发：线程/线程池、锁/条件变量、atomic/CAS
  - Linux/OS：进程/线程/调度、fd/系统调用/IO、排查工具
  - 网络：epoll/Reactor、RPC/协议
  - 中间件/分布式：Redis/缓存、MySQL/数据库、Kafka/消息队列、分布式基础、存储系统
  - 项目/工程：项目深挖、工程工具、性能压测
- 手撕/代码：链表/树/图、TopK/堆/排序、动态规划/字符串
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor

### 132. [字节推荐系统架构后端暑期实习面经(已offer)](https://www.nowcoder.com/feed/main/detail/2801289)

- 时间：2026-03-06
- 公司/组织：字节
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：未标明
- 作者认证：字节跳动 后端(实习)
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 C++：内存管理；项目/工程：项目深挖。
- 面试内容整理：
  - C++：内存管理
  - 项目/工程：项目深挖
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；项目 README、压测、debug 和面试讲稿

### 133. [26届秋招面经 ～ 腾讯](https://www.nowcoder.com/feed/main/detail/2677882)

- 时间：2025-10-21
- 公司/组织：腾讯
- 岗位/方向：Infra / 基础架构，C++ 开发
- 轮次：一面 / 二面 / 三面
- 作者认证：门头沟学院 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 开发，面试内容集中在 C++：对象模型/虚函数、内存管理；并发：线程/线程池；Linux/OS：进程/线程/调度；网络：TCP/UDP/HTTP，并涉及 LRU/LFU 缓存、TopK/堆/排序。
- 面试内容整理：
  - C++：对象模型/虚函数、内存管理
  - 并发：线程/线程池
  - Linux/OS：进程/线程/调度
  - 网络：TCP/UDP/HTTP
  - 中间件/分布式：Redis/缓存、MySQL/数据库、分布式基础
  - 项目/工程：项目深挖
- 手撕/代码：LRU/LFU 缓存、TopK/堆/排序
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor

### 134. [深信服_C++开发_面经](https://www.nowcoder.com/feed/main/detail/2430713)

- 时间：2024-10-20
- 公司/组织：深信服
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：一面
- 作者认证：电子科技大学 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 Linux/OS：进程/线程/调度；项目/工程：项目深挖。
- 面试内容整理：
  - Linux/OS：进程/线程/调度
  - 项目/工程：项目深挖
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week4-5：Linux 系统编程与 OS 基础；项目 README、压测、debug 和面试讲稿

### 135. [腾讯TEG研发管理部，后端开发面经](https://www.nowcoder.com/discuss/792490205637857280)

- 时间：2025-09-02
- 公司/组织：腾讯
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：OC
- 作者认证：门头沟学院 后端工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 C++：智能指针；中间件/分布式：Kafka/消息队列。
- 面试内容整理：
  - C++：智能指针
  - 中间件/分布式：Kafka/消息队列
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Mini Redis / MySQL / 分布式后置主线

### 136. [华为暑期实习-一面-面经](https://www.nowcoder.com/discuss/753682991645233152)

- 时间：2025-05-18
- 公司/组织：华为
- 岗位/方向：Infra / 基础架构，C++ 开发
- 轮次：一面
- 作者认证：南京理工大学 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 开发，面试内容集中在 C++：内存管理；中间件/分布式：分布式基础、存储系统；项目/工程：项目深挖。
- 面试内容整理：
  - C++：内存管理
  - 中间件/分布式：分布式基础、存储系统
  - 项目/工程：项目深挖
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Mini Redis / MySQL / 分布式后置主线；项目 README、压测、debug 和面试讲稿

### 137. [美团外卖-后端-c++一面](https://www.nowcoder.com/feed/main/detail/2579234)

- 时间：2025-04-09
- 公司/组织：美团
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：一面
- 作者认证：东南大学 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 手撕/算法：生产级代码，并涉及 手写数据结构/复杂度分析。
- 面试内容整理：
  - 手撕/算法：生产级代码
- 手撕/代码：手写数据结构/复杂度分析
- 对你规划的用处：每周 2-3 题保持手感

### 138. [面经回馈，希望大家都能有不错的假期和offer](https://www.nowcoder.com/discuss/669937843933831168)

- 时间：2024-09-29
- 公司/组织：阿里 / 美团
- 岗位/方向：Infra / 基础架构，C++ 开发
- 轮次：OC
- 作者认证：同济大学 Java
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 开发，面试内容集中在 并发：锁/条件变量；Linux/OS：fd/系统调用/IO、排查工具；中间件/分布式：Redis/缓存、MySQL/数据库、Kafka/消息队列、分布式基础。
- 面试内容整理：
  - 并发：锁/条件变量
  - Linux/OS：fd/系统调用/IO、排查工具
  - 中间件/分布式：Redis/缓存、MySQL/数据库、Kafka/消息队列、分布式基础
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Mini Redis / MySQL / 分布式后置主线

### 139. [金山 C++ 二面 面经](https://www.nowcoder.com/discuss/872472595738722304)

- 时间：2026-04-11
- 公司/组织：字节
- 岗位/方向：Infra / 基础架构，C++ 后端/服务端，C++ 开发
- 轮次：一面 / 二面 / 技术面 / OC
- 作者认证：浙江大学 算法工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 后端/服务端，C++ 开发，面试内容集中在 C++：RAII、智能指针、STL 容器、对象模型/虚函数、内存管理、模板/泛型、异常安全、const/static/volatile；并发：线程/线程池、锁/条件变量、atomic/CAS、生产者消费者；Linux/OS：进程/线程/调度、fd/系统调用/IO、排查工具；网络：TCP/UDP/HTTP、连接状态、RPC/协议，并涉及 线程池/阻塞队列、TopK/堆/排序、动态规划/字符串。
- 面试内容整理：
  - C++：RAII、智能指针、STL 容器、对象模型/虚函数、内存管理、模板/泛型、异常安全、const/static/volatile
  - 并发：线程/线程池、锁/条件变量、atomic/CAS、生产者消费者
  - Linux/OS：进程/线程/调度、fd/系统调用/IO、排查工具
  - 网络：TCP/UDP/HTTP、连接状态、RPC/协议
  - 中间件/分布式：Redis/缓存、MySQL/数据库
  - AI Infra：LLM Serving
- 手撕/代码：线程池/阻塞队列、TopK/堆/排序、动态规划/字符串
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor

### 140. [华为26暑期实习面经](https://www.nowcoder.com/feed/main/detail/2612224)

- 时间：2025-05-30
- 公司/组织：华为
- 岗位/方向：Infra / 基础架构，C++ 开发
- 轮次：技术面 / 主管面
- 作者认证：西安电子科技大学 Java
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 开发，面试内容集中在 C++：内存管理；中间件/分布式：MySQL/数据库；项目/工程：项目深挖；手撕/算法：链表/树/图、二分/滑窗/TopK、生产级代码，并涉及 链表/树/图、TopK/堆/排序、手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：内存管理
  - 中间件/分布式：MySQL/数据库
  - 项目/工程：项目深挖
  - 手撕/算法：链表/树/图、二分/滑窗/TopK、生产级代码
- 手撕/代码：链表/树/图、TopK/堆/排序、手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Mini Redis / MySQL / 分布式后置主线；项目 README、压测、debug 和面试讲稿；每周 2-3 题保持手感

### 141. [腾讯PCG二面面经分享](https://www.nowcoder.com/feed/main/detail/2603904)

- 时间：2025-05-15
- 公司/组织：腾讯 / PCG
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：二面
- 作者认证：河南理工大学 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 C++：智能指针、对象模型/虚函数；并发：锁/条件变量；中间件/分布式：MySQL/数据库；项目/工程：项目深挖。
- 面试内容整理：
  - C++：智能指针、对象模型/虚函数
  - 并发：锁/条件变量
  - 中间件/分布式：MySQL/数据库
  - 项目/工程：项目深挖
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Mini Redis / MySQL / 分布式后置主线；项目 README、压测、debug 和面试讲稿

### 142. [2.24百度一面（已挂）](https://www.nowcoder.com/feed/main/detail/2546253)

- 时间：2025-03-07
- 公司/组织：百度
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：一面
- 作者认证：武汉大学 后端工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 项目/工程：项目深挖。
- 面试内容整理：
  - 项目/工程：项目深挖
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：项目 README、压测、debug 和面试讲稿

### 143. [腾讯CDG一面面经](https://www.nowcoder.com/feed/main/detail/2752037)

- 时间：2025-11-25
- 公司/组织：腾讯
- 岗位/方向：Infra / 基础架构，C++ 开发
- 轮次：一面 / hr面
- 作者认证：复旦大学 Java
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 开发，面试内容集中在 C++：STL 容器；Linux/OS：进程/线程/调度、fd/系统调用/IO；中间件/分布式：MySQL/数据库、分布式基础、存储系统；AI Infra：LLM Serving。
- 面试内容整理：
  - C++：STL 容器
  - Linux/OS：进程/线程/调度、fd/系统调用/IO
  - 中间件/分布式：MySQL/数据库、分布式基础、存储系统
  - AI Infra：LLM Serving
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week4-5：Linux 系统编程与 OS 基础；Mini Redis / MySQL / 分布式后置主线；2028 AI Infra：推理、CUDA、LLM Serving 预热

### 144. [同程旅行 C++一面凉经(只记得这么多了)](https://www.nowcoder.com/feed/main/detail/2718829)

- 时间：2025-10-17
- 公司/组织：字节
- 岗位/方向：Infra / 基础架构，C++ 后端/服务端，C++ 开发
- 轮次：一面 / OC
- 作者认证：门头沟学院 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 后端/服务端，C++ 开发，面试内容集中在 C++：智能指针、内存管理；并发：线程/线程池、锁/条件变量；Linux/OS：进程/线程/调度；网络：TCP/UDP/HTTP、epoll/Reactor。
- 面试内容整理：
  - C++：智能指针、内存管理
  - 并发：线程/线程池、锁/条件变量
  - Linux/OS：进程/线程/调度
  - 网络：TCP/UDP/HTTP、epoll/Reactor
  - 中间件/分布式：Redis/缓存、MySQL/数据库、分布式基础
  - 项目/工程：项目深挖、工程工具
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor

### 145. [百度C++/go后端秋招面经](https://www.nowcoder.com/discuss/800294334682656768)

- 时间：2025-09-24
- 公司/组织：百度
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：二面 / 三面 / OC
- 作者认证：华南理工大学
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 网络：TCP/UDP/HTTP；项目/工程：项目深挖；手撕/算法：生产级代码，并涉及 手写数据结构/复杂度分析。
- 面试内容整理：
  - 网络：TCP/UDP/HTTP
  - 项目/工程：项目深挖
  - 手撕/算法：生产级代码
- 手撕/代码：手写数据结构/复杂度分析
- 对你规划的用处：Week6 + 项目线：socket、epoll、Reactor；项目 README、压测、debug 和面试讲稿；每周 2-3 题保持手感

### 146. [竞技世界C++开发一面](https://www.nowcoder.com/discuss/871804904774393856)

- 时间：2026-04-09
- 公司/组织：腾讯 / 百度
- 岗位/方向：Infra / 基础架构，C++ 后端/服务端，C++ 开发
- 轮次：一面 / OC
- 作者认证：华北电力大学 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 后端/服务端，C++ 开发，面试内容集中在 C++：RAII、拷贝/移动语义、智能指针、STL 容器、对象模型/虚函数、模板/泛型；并发：线程/线程池、锁/条件变量；Linux/OS：进程/线程/调度、fd/系统调用/IO、排查工具；网络：TCP/UDP/HTTP，并涉及 链表/树/图、动态规划/字符串。
- 面试内容整理：
  - C++：RAII、拷贝/移动语义、智能指针、STL 容器、对象模型/虚函数、模板/泛型
  - 并发：线程/线程池、锁/条件变量
  - Linux/OS：进程/线程/调度、fd/系统调用/IO、排查工具
  - 网络：TCP/UDP/HTTP
  - 中间件/分布式：Redis/缓存、MySQL/数据库、Kafka/消息队列、分布式基础、存储系统
  - 项目/工程：项目深挖、性能压测
- 手撕/代码：链表/树/图、动态规划/字符串
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor

### 147. [【面经】美团平台-美团直播 后端实习转正](https://www.nowcoder.com/discuss/839455546997473280)

- 时间：2026-01-10
- 公司/组织：美团
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：未标明
- 作者认证：哈尔滨工业大学（威海） Java
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 中间件/分布式：MySQL/数据库；项目/工程：项目深挖。
- 面试内容整理：
  - 中间件/分布式：MySQL/数据库
  - 项目/工程：项目深挖
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Mini Redis / MySQL / 分布式后置主线；项目 README、压测、debug 和面试讲稿

### 148. [滴滴后端一二面面经](https://www.nowcoder.com/feed/main/detail/2704568)

- 时间：2025-09-28
- 公司/组织：滴滴
- 岗位/方向：Infra / 基础架构，C++ 后端/服务端，C++ 开发
- 轮次：二面
- 作者认证：门头沟学院 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 后端/服务端，C++ 开发，面试内容集中在 C++：对象模型/虚函数；中间件/分布式：MySQL/数据库。
- 面试内容整理：
  - C++：对象模型/虚函数
  - 中间件/分布式：MySQL/数据库
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Mini Redis / MySQL / 分布式后置主线

### 149. [百度分布式计算一面](https://www.nowcoder.com/feed/main/detail/2432071)

- 时间：2024-10-21
- 公司/组织：百度
- 岗位/方向：Infra / 基础架构，C++ 开发
- 轮次：一面 / 二面 / OC
- 作者认证：武汉理工大学 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 开发，面试内容集中在 C++：智能指针、对象模型/虚函数；网络：TCP/UDP/HTTP；中间件/分布式：分布式基础；手撕/算法：链表/树/图，并涉及 链表/树/图。
- 面试内容整理：
  - C++：智能指针、对象模型/虚函数
  - 网络：TCP/UDP/HTTP
  - 中间件/分布式：分布式基础
  - 手撕/算法：链表/树/图
- 手撕/代码：链表/树/图
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week6 + 项目线：socket、epoll、Reactor；Mini Redis / MySQL / 分布式后置主线；每周 2-3 题保持手感

### 150. [百度搜索一二面凉经](https://www.nowcoder.com/discuss/664244051390095360)

- 时间：2024-09-13
- 公司/组织：百度
- 岗位/方向：Infra / 基础架构，C++ 后端/服务端，C++ 开发
- 轮次：笔试 / 一面 / 二面
- 作者认证：第一拖拉机制造厂拖拉机学院 研发工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 后端/服务端，C++ 开发，面试内容集中在 C++：STL 容器、异常安全；网络：TCP/UDP/HTTP、epoll/Reactor；中间件/分布式：Redis/缓存、MySQL/数据库、分布式基础；项目/工程：项目深挖，并涉及 链表/树/图。
- 面试内容整理：
  - C++：STL 容器、异常安全
  - 网络：TCP/UDP/HTTP、epoll/Reactor
  - 中间件/分布式：Redis/缓存、MySQL/数据库、分布式基础
  - 项目/工程：项目深挖
  - 手撕/算法：缓存题、链表/树/图
- 手撕/代码：链表/树/图
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week6 + 项目线：socket、epoll、Reactor；Mini Redis / MySQL / 分布式后置主线；项目 README、压测、debug 和面试讲稿

### 151. [深圳潮流网络(grandstream)linux驱动开发校招面经base杭州](https://www.nowcoder.com/feed/main/detail/2751342)

- 时间：2025-11-24
- 公司/组织：字节
- 岗位/方向：Infra / 基础架构，C++ 开发
- 轮次：OC
- 作者认证：门头沟学院 安卓
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 开发，面试内容集中在 Linux/OS：排查工具；网络：TCP/UDP/HTTP、连接状态、epoll/Reactor；中间件/分布式：存储系统；手撕/算法：动态规划/字符串，并涉及 动态规划/字符串。
- 面试内容整理：
  - Linux/OS：排查工具
  - 网络：TCP/UDP/HTTP、连接状态、epoll/Reactor
  - 中间件/分布式：存储系统
  - 手撕/算法：动态规划/字符串
- 手撕/代码：动态规划/字符串
- 对你规划的用处：Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor；Mini Redis / MySQL / 分布式后置主线；每周 2-3 题保持手感

### 152. [[面经]-腾讯teg 开发一面凉经](https://www.nowcoder.com/discuss/792491099548844032)

- 时间：2025-09-02
- 公司/组织：腾讯
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：一面
- 作者认证：门头沟学院 后端工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 网络：TCP/UDP/HTTP、RPC/协议。
- 面试内容整理：
  - 网络：TCP/UDP/HTTP、RPC/协议
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week6 + 项目线：socket、epoll、Reactor

### 153. [网易 C++ 研发岗 二面 面经](https://www.nowcoder.com/discuss/869565285177581568)

- 时间：2026-04-03
- 公司/组织：字节 / 网易
- 岗位/方向：Infra / 基础架构，C++ 后端/服务端，C++ 开发
- 轮次：二面 / 技术面 / OC
- 作者认证：浙江大学 算法工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 后端/服务端，C++ 开发，面试内容集中在 C++：RAII、拷贝/移动语义、智能指针、STL 容器、对象模型/虚函数、内存管理、模板/泛型、异常安全；并发：线程/线程池、锁/条件变量、atomic/CAS；Linux/OS：进程/线程/调度、虚拟内存/mmap/COW、fd/系统调用/IO、排查工具；网络：TCP/UDP/HTTP、RPC/协议，并涉及 LRU/LFU 缓存、链表/树/图、TopK/堆/排序、动态规划/字符串、手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：RAII、拷贝/移动语义、智能指针、STL 容器、对象模型/虚函数、内存管理、模板/泛型、异常安全
  - 并发：线程/线程池、锁/条件变量、atomic/CAS
  - Linux/OS：进程/线程/调度、虚拟内存/mmap/COW、fd/系统调用/IO、排查工具
  - 网络：TCP/UDP/HTTP、RPC/协议
  - 中间件/分布式：Redis/缓存、MySQL/数据库、Kafka/消息队列、分布式基础、存储系统
  - 项目/工程：项目深挖、性能压测
- 手撕/代码：LRU/LFU 缓存、链表/树/图、TopK/堆/排序、动态规划/字符串、手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor

### 154. [字节后端开发面经2](https://www.nowcoder.com/discuss/792519675077730304)

- 时间：2025-09-02
- 公司/组织：字节
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：未标明
- 作者认证：门头沟学院 后端工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 Linux/OS：排查工具；中间件/分布式：Redis/缓存、Kafka/消息队列；项目/工程：项目深挖。
- 面试内容整理：
  - Linux/OS：排查工具
  - 中间件/分布式：Redis/缓存、Kafka/消息队列
  - 项目/工程：项目深挖
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week4-5：Linux 系统编程与 OS 基础；Mini Redis / MySQL / 分布式后置主线；项目 README、压测、debug 和面试讲稿

### 155. [快手-C++工程师-一面面经](https://www.nowcoder.com/feed/main/detail/2652330)

- 时间：2025-08-08
- 公司/组织：百度 / 快手
- 岗位/方向：Infra / 基础架构，C++ 开发
- 轮次：一面 / 三面
- 作者认证：武汉大学 Java
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 开发，面试内容集中在 中间件/分布式：MySQL/数据库、分布式基础；手撕/算法：链表/树/图，并涉及 链表/树/图。
- 面试内容整理：
  - 中间件/分布式：MySQL/数据库、分布式基础
  - 手撕/算法：链表/树/图
- 手撕/代码：链表/树/图
- 对你规划的用处：Mini Redis / MySQL / 分布式后置主线；每周 2-3 题保持手感

### 156. [c++#od面经分享#（已得授权）](https://www.nowcoder.com/discuss/592331701716561920)

- 时间：2024-09-12
- 公司/组织：华为
- 岗位/方向：Infra / 基础架构，C++ 开发
- 轮次：一面 / 二面 / 技术面 / 主管面
- 作者认证：深圳大学 人力资源主管
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 开发，面试内容集中在 Linux/OS：排查工具；项目/工程：项目深挖；手撕/算法：动态规划/字符串、生产级代码，并涉及 动态规划/字符串、手写数据结构/复杂度分析。
- 面试内容整理：
  - Linux/OS：排查工具
  - 项目/工程：项目深挖
  - 手撕/算法：动态规划/字符串、生产级代码
- 手撕/代码：动态规划/字符串、手写数据结构/复杂度分析
- 对你规划的用处：Week4-5：Linux 系统编程与 OS 基础；项目 README、压测、debug 和面试讲稿；每周 2-3 题保持手感

### 157. [阿里 智能信息 实习岗 面经（1~3面及HR面）](https://www.nowcoder.com/discuss/652946178472001536)

- 时间：2024-08-13
- 公司/组织：阿里
- 岗位/方向：Infra / 基础架构，C++ 开发
- 轮次：一面 / HR面
- 作者认证：东华理工大学 大数据开发工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 开发，面试内容集中在 C++：智能指针、STL 容器、对象模型/虚函数、内存管理；并发：线程/线程池、锁/条件变量；中间件/分布式：MySQL/数据库、存储系统；项目/工程：项目深挖，并涉及 线程池/阻塞队列。
- 面试内容整理：
  - C++：智能指针、STL 容器、对象模型/虚函数、内存管理
  - 并发：线程/线程池、锁/条件变量
  - 中间件/分布式：MySQL/数据库、存储系统
  - 项目/工程：项目深挖
- 手撕/代码：线程池/阻塞队列
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Mini Redis / MySQL / 分布式后置主线；项目 README、压测、debug 和面试讲稿

### 158. [深信服一面凉经](https://www.nowcoder.com/feed/main/detail/2704195)

- 时间：2025-09-27
- 公司/组织：深信服
- 岗位/方向：Infra / 基础架构，C++ 开发
- 轮次：一面
- 作者认证：门头沟学院 Java
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 开发，面试内容集中在 并发：线程/线程池；中间件/分布式：MySQL/数据库；项目/工程：性能压测；手撕/算法：二分/滑窗/TopK，并涉及 TopK/堆/排序。
- 面试内容整理：
  - 并发：线程/线程池
  - 中间件/分布式：MySQL/数据库
  - 项目/工程：性能压测
  - 手撕/算法：二分/滑窗/TopK
- 手撕/代码：TopK/堆/排序
- 对你规划的用处：Week7-8：线程、锁、线程池、异步日志；Mini Redis / MySQL / 分布式后置主线；项目 README、压测、debug 和面试讲稿；每周 2-3 题保持手感

### 159. [暑假实习g了，只有小厂去，有必要去吗？附字节、华为面经](https://www.nowcoder.com/feed/main/detail/2609827)

- 时间：2025-05-26
- 公司/组织：字节 / 华为
- 岗位/方向：Infra / 基础架构，C++ 开发
- 轮次：一面
- 作者认证：华中科技大学 Java
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 开发，面试内容集中在 Linux/OS：进程/线程/调度；网络：TCP/UDP/HTTP；中间件/分布式：Redis/缓存、MySQL/数据库、Kafka/消息队列；项目/工程：项目深挖、性能压测，并涉及 手写数据结构/复杂度分析。
- 面试内容整理：
  - Linux/OS：进程/线程/调度
  - 网络：TCP/UDP/HTTP
  - 中间件/分布式：Redis/缓存、MySQL/数据库、Kafka/消息队列
  - 项目/工程：项目深挖、性能压测
  - 手撕/算法：生产级代码
- 手撕/代码：手写数据结构/复杂度分析
- 对你规划的用处：Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor；Mini Redis / MySQL / 分布式后置主线；项目 README、压测、debug 和面试讲稿

### 160. [c++面经分享](https://www.nowcoder.com/feed/main/detail/2496068)

- 时间：2024-12-07
- 公司/组织：华为
- 岗位/方向：Infra / 基础架构，C++ 开发
- 轮次：笔试 / 一面 / 二面
- 作者认证：深圳大学 人力资源主管
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 开发，面试内容集中在 C++：对象模型/虚函数；中间件/分布式：MySQL/数据库；项目/工程：项目深挖；手撕/算法：生产级代码，并涉及 手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：对象模型/虚函数
  - 中间件/分布式：MySQL/数据库
  - 项目/工程：项目深挖
  - 手撕/算法：生产级代码
- 手撕/代码：手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Mini Redis / MySQL / 分布式后置主线；项目 README、压测、debug 和面试讲稿；每周 2-3 题保持手感

### 161. [25秋招-荣耀互联网应用软件开发面经](https://www.nowcoder.com/feed/main/detail/2396517)

- 时间：2024-09-26
- 公司/组织：荣耀
- 岗位/方向：Infra / 基础架构，C++ 开发
- 轮次：未标明
- 作者认证：河海大学 Java
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 开发，面试内容集中在 并发：锁/条件变量；中间件/分布式：Redis/缓存、MySQL/数据库、Kafka/消息队列；项目/工程：项目深挖；手撕/算法：链表/树/图。
- 面试内容整理：
  - 并发：锁/条件变量
  - 中间件/分布式：Redis/缓存、MySQL/数据库、Kafka/消息队列
  - 项目/工程：项目深挖
  - 手撕/算法：链表/树/图
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week7-8：线程、锁、线程池、异步日志；Mini Redis / MySQL / 分布式后置主线；项目 README、压测、debug 和面试讲稿；每周 2-3 题保持手感

### 162. [华为OD-AI岗位面经-25届空挡一年](https://www.nowcoder.com/feed/main/detail/2850950)

- 时间：2026-05-21
- 公司/组织：华为 / OD
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：未标明
- 作者认证：西安电子科技大学 Java
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 C++：拷贝/移动语义；并发：线程/线程池；手撕/算法：生产级代码，并涉及 手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：拷贝/移动语义
  - 并发：线程/线程池
  - 手撕/算法：生产级代码
- 手撕/代码：手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；每周 2-3 题保持手感

### 163. [GAP两年没凉！华为OD--- C++面经分享](https://www.nowcoder.com/feed/main/detail/2848202)

- 时间：2026-05-07
- 公司/组织：华为 / OD
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：一面 / 二面
- 作者认证：华为 HR
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 C++：对象模型/虚函数；项目/工程：项目深挖；手撕/算法：二分/滑窗/TopK、生产级代码，并涉及 TopK/堆/排序、手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：对象模型/虚函数
  - 项目/工程：项目深挖
  - 手撕/算法：二分/滑窗/TopK、生产级代码
- 手撕/代码：TopK/堆/排序、手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；项目 README、压测、debug 和面试讲稿；每周 2-3 题保持手感

### 164. [腾讯-微信支付 C++ 二面 面经 分析](https://www.nowcoder.com/discuss/866341436608823296)

- 时间：2026-03-25
- 公司/组织：腾讯
- 岗位/方向：Infra / 基础架构，C++ 后端/服务端，C++ 开发
- 轮次：一面 / 二面
- 作者认证：浙江大学 算法工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 后端/服务端，C++ 开发，面试内容集中在 C++：智能指针、内存管理；并发：线程/线程池、锁/条件变量；Linux/OS：fd/系统调用/IO；网络：TCP/UDP/HTTP。
- 面试内容整理：
  - C++：智能指针、内存管理
  - 并发：线程/线程池、锁/条件变量
  - Linux/OS：fd/系统调用/IO
  - 网络：TCP/UDP/HTTP
  - 中间件/分布式：Redis/缓存、MySQL/数据库、Kafka/消息队列、分布式基础
  - 项目/工程：项目深挖、工程工具、性能压测
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor

### 165. [360日常一面](https://www.nowcoder.com/feed/main/detail/2690118)

- 时间：2025-09-17
- 公司/组织：360
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：一面 / OC
- 作者认证：门头沟学院 后端工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 中间件/分布式：Redis/缓存；项目/工程：项目深挖；手撕/算法：链表/树/图，并涉及 链表/树/图。
- 面试内容整理：
  - 中间件/分布式：Redis/缓存
  - 项目/工程：项目深挖
  - 手撕/算法：链表/树/图
- 手撕/代码：链表/树/图
- 对你规划的用处：Mini Redis / MySQL / 分布式后置主线；项目 README、压测、debug 和面试讲稿；每周 2-3 题保持手感

### 166. [秋招面经-京东-TET技术方向-后端开发](https://www.nowcoder.com/discuss/791061770335973376)

- 时间：2025-08-29
- 公司/组织：京东
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：未标明
- 作者认证：门头沟学院 后端工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 网络：TCP/UDP/HTTP；手撕/算法：动态规划/字符串，并涉及 动态规划/字符串。
- 面试内容整理：
  - 网络：TCP/UDP/HTTP
  - 手撕/算法：动态规划/字符串
- 手撕/代码：动态规划/字符串
- 对你规划的用处：Week6 + 项目线：socket、epoll、Reactor；每周 2-3 题保持手感

### 167. [补发一篇 秋招小米的面经,附自己的复盘解答](https://www.nowcoder.com/discuss/840141644329447424)

- 时间：2026-01-12
- 公司/组织：字节 / 小米
- 岗位/方向：Infra / 基础架构，C++ 开发
- 轮次：OC
- 作者认证：未显示
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 开发，面试内容集中在 C++：RAII、对象模型/虚函数、内存管理、异常安全、const/static/volatile；并发：线程/线程池、锁/条件变量；Linux/OS：进程/线程/调度、fd/系统调用/IO、排查工具；网络：TCP/UDP/HTTP，并涉及 TopK/堆/排序、动态规划/字符串。
- 面试内容整理：
  - C++：RAII、对象模型/虚函数、内存管理、异常安全、const/static/volatile
  - 并发：线程/线程池、锁/条件变量
  - Linux/OS：进程/线程/调度、fd/系统调用/IO、排查工具
  - 网络：TCP/UDP/HTTP
  - 中间件/分布式：MySQL/数据库、存储系统
  - AI Infra：LLM Serving
- 手撕/代码：TopK/堆/排序、动态规划/字符串
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor

### 168. [校招百度c++面经](https://www.nowcoder.com/discuss/813517977319473152)

- 时间：2025-10-30
- 公司/组织：百度
- 岗位/方向：Infra / 基础架构，C++ 开发
- 轮次：未标明
- 作者认证：门头沟学院 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 开发，面试内容集中在 网络：epoll/Reactor；中间件/分布式：MySQL/数据库、存储系统；项目/工程：项目深挖、工程工具。
- 面试内容整理：
  - 网络：epoll/Reactor
  - 中间件/分布式：MySQL/数据库、存储系统
  - 项目/工程：项目深挖、工程工具
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week6 + 项目线：socket、epoll、Reactor；Mini Redis / MySQL / 分布式后置主线；项目 README、压测、debug 和面试讲稿

### 169. [百度C++二面面经](https://www.nowcoder.com/discuss/799351478514143232)

- 时间：2025-09-21
- 公司/组织：百度
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：二面
- 作者认证：门头沟学院 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 C++：RAII、智能指针、对象模型/虚函数、const/static/volatile；并发：线程/线程池、锁/条件变量；Linux/OS：进程/线程/调度；网络：TCP/UDP/HTTP，并涉及 动态规划/字符串、手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：RAII、智能指针、对象模型/虚函数、const/static/volatile
  - 并发：线程/线程池、锁/条件变量
  - Linux/OS：进程/线程/调度
  - 网络：TCP/UDP/HTTP
  - 中间件/分布式：MySQL/数据库
  - 项目/工程：项目深挖
- 手撕/代码：动态规划/字符串、手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor

### 170. [腾讯金融科技暑期一面凉经（偏基础 + 项目拷打 + 手撕）](https://www.nowcoder.com/feed/main/detail/2832261)

- 时间：2026-04-11
- 公司/组织：腾讯
- 岗位/方向：Infra / 基础架构，C++ 后端/服务端，C++ 开发
- 轮次：一面
- 作者认证：门头沟学院 Java
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 后端/服务端，C++ 开发，面试内容集中在 中间件/分布式：分布式基础；项目/工程：项目深挖；手撕/算法：动态规划/字符串、生产级代码，并涉及 动态规划/字符串、手写数据结构/复杂度分析。
- 面试内容整理：
  - 中间件/分布式：分布式基础
  - 项目/工程：项目深挖
  - 手撕/算法：动态规划/字符串、生产级代码
- 手撕/代码：动态规划/字符串、手写数据结构/复杂度分析
- 对你规划的用处：Mini Redis / MySQL / 分布式后置主线；项目 README、压测、debug 和面试讲稿；每周 2-3 题保持手感

### 171. [OPPO C++ 软件开发 一面 面经](https://www.nowcoder.com/discuss/868416561575383040)

- 时间：2026-03-31
- 公司/组织：字节 / OPPO
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：一面 / 技术面 / OC
- 作者认证：浙江大学 算法工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 C++：RAII、拷贝/移动语义、智能指针、STL 容器、对象模型/虚函数、内存管理、模板/泛型、异常安全；并发：线程/线程池；Linux/OS：进程/线程/调度、fd/系统调用/IO、排查工具；网络：TCP/UDP/HTTP、epoll/Reactor，并涉及 链表/树/图、动态规划/字符串。
- 面试内容整理：
  - C++：RAII、拷贝/移动语义、智能指针、STL 容器、对象模型/虚函数、内存管理、模板/泛型、异常安全
  - 并发：线程/线程池
  - Linux/OS：进程/线程/调度、fd/系统调用/IO、排查工具
  - 网络：TCP/UDP/HTTP、epoll/Reactor
  - 中间件/分布式：MySQL/数据库
  - 项目/工程：项目深挖、工程工具、性能压测
- 手撕/代码：链表/树/图、动态规划/字符串
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor

### 172. [南京小西科技管培实习生面经C++（一轮技术面）](https://www.nowcoder.com/feed/main/detail/2773516)

- 时间：2025-12-25
- 公司/组织：字节
- 岗位/方向：Infra / 基础架构，C++ 开发
- 轮次：技术面
- 作者认证：浙江理工大学 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 开发，面试内容集中在 C++：内存管理；并发：线程/线程池、锁/条件变量；Linux/OS：进程/线程/调度、排查工具；网络：TCP/UDP/HTTP、epoll/Reactor，并涉及 LRU/LFU 缓存、线程池/阻塞队列。
- 面试内容整理：
  - C++：内存管理
  - 并发：线程/线程池、锁/条件变量
  - Linux/OS：进程/线程/调度、排查工具
  - 网络：TCP/UDP/HTTP、epoll/Reactor
  - 中间件/分布式：Redis/缓存、MySQL/数据库、存储系统
  - 项目/工程：项目深挖、性能压测
- 手撕/代码：LRU/LFU 缓存、线程池/阻塞队列
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor

### 173. [华为 2026 暑期实习全流程面经（技术+主管面）](https://www.nowcoder.com/feed/main/detail/2685990)

- 时间：2025-09-09
- 公司/组织：华为
- 岗位/方向：Infra / 基础架构，C++ 开发
- 轮次：一面 / 二面 / 技术面 / 主管面
- 作者认证：清华大学 产品经理
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 开发，面试内容集中在 C++：内存管理；中间件/分布式：MySQL/数据库；项目/工程：项目深挖；手撕/算法：二分/滑窗/TopK，并涉及 TopK/堆/排序。
- 面试内容整理：
  - C++：内存管理
  - 中间件/分布式：MySQL/数据库
  - 项目/工程：项目深挖
  - 手撕/算法：二分/滑窗/TopK
- 手撕/代码：TopK/堆/排序
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Mini Redis / MySQL / 分布式后置主线；项目 README、压测、debug 和面试讲稿；每周 2-3 题保持手感

### 174. [1年多~C++开发面经-华od](https://www.nowcoder.com/discuss/790604884318887936)

- 时间：2025-09-05
- 公司/组织：华为 / OD
- 岗位/方向：AI Infra / 大模型基础设施，C++ 后端/服务端，C++ 开发
- 轮次：一面 / 二面 / 三面 / 主管面
- 作者认证：南京邮电大学 Java
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 AI Infra / 大模型基础设施，C++ 后端/服务端，C++ 开发，面试内容集中在 C++：RAII、拷贝/移动语义、模板/泛型、const/static/volatile；AI Infra：LLM Serving；项目/工程：项目深挖；手撕/算法：链表/树/图、二分/滑窗/TopK、动态规划/字符串、生产级代码，并涉及 链表/树/图、TopK/堆/排序、二分/滑动窗口、动态规划/字符串、手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：RAII、拷贝/移动语义、模板/泛型、const/static/volatile
  - AI Infra：LLM Serving
  - 项目/工程：项目深挖
  - 手撕/算法：链表/树/图、二分/滑窗/TopK、动态规划/字符串、生产级代码
- 手撕/代码：链表/树/图、TopK/堆/排序、二分/滑动窗口、动态规划/字符串、手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；2028 AI Infra：推理、CUDA、LLM Serving 预热；项目 README、压测、debug 和面试讲稿；每周 2-3 题保持手感

### 175. [华为OD面经-C++开发岗](https://www.nowcoder.com/discuss/792057773491032064)

- 时间：2025-09-01
- 公司/组织：华为 / OD
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：技术面 / 主管面 / HR面
- 作者认证：深圳大学 Java
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 C++：RAII、拷贝/移动语义、STL 容器；并发：线程/线程池、锁/条件变量；中间件/分布式：MySQL/数据库；项目/工程：项目深挖、性能压测，并涉及 手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：RAII、拷贝/移动语义、STL 容器
  - 并发：线程/线程池、锁/条件变量
  - 中间件/分布式：MySQL/数据库
  - 项目/工程：项目深挖、性能压测
  - 手撕/算法：生产级代码
- 手撕/代码：手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Mini Redis / MySQL / 分布式后置主线；项目 README、压测、debug 和面试讲稿

### 176. [20届，C++面经-华OD](https://www.nowcoder.com/discuss/764140386339024896)

- 时间：2025-06-16
- 公司/组织：华为 / OD
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：一面 / 二面 / HR面
- 作者认证：南京邮电大学 Java
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 C++：对象模型/虚函数、内存管理、const/static/volatile；网络：TCP/UDP/HTTP、RPC/协议；中间件/分布式：MySQL/数据库；项目/工程：项目深挖、工程工具，并涉及 TopK/堆/排序、动态规划/字符串、手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：对象模型/虚函数、内存管理、const/static/volatile
  - 网络：TCP/UDP/HTTP、RPC/协议
  - 中间件/分布式：MySQL/数据库
  - 项目/工程：项目深挖、工程工具
  - 手撕/算法：二分/滑窗/TopK、动态规划/字符串、生产级代码
- 手撕/代码：TopK/堆/排序、动态规划/字符串、手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week6 + 项目线：socket、epoll、Reactor；Mini Redis / MySQL / 分布式后置主线；项目 README、压测、debug 和面试讲稿

### 177. [百度 - 后端 - 一面](https://www.nowcoder.com/feed/main/detail/2829764)

- 时间：2026-04-13
- 公司/组织：百度
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：一面
- 作者认证：电子科技大学 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 C++：RAII、拷贝/移动语义、智能指针、STL 容器；并发：锁/条件变量；网络：TCP/UDP/HTTP；中间件/分布式：Redis/缓存、MySQL/数据库，并涉及 LRU/LFU 缓存、手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：RAII、拷贝/移动语义、智能指针、STL 容器
  - 并发：锁/条件变量
  - 网络：TCP/UDP/HTTP
  - 中间件/分布式：Redis/缓存、MySQL/数据库
  - 手撕/算法：缓存题、生产级代码
- 手撕/代码：LRU/LFU 缓存、手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week6 + 项目线：socket、epoll、Reactor；Mini Redis / MySQL / 分布式后置主线

### 178. [大疆 | C++开发工程师 二面 面经](https://www.nowcoder.com/discuss/867669026103713792)

- 时间：2026-03-28
- 公司/组织：大疆
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：二面
- 作者认证：浙江大学 算法工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 C++：对象模型/虚函数、模板/泛型；并发：线程/线程池；Linux/OS：进程/线程/调度；项目/工程：项目深挖、性能压测。
- 面试内容整理：
  - C++：对象模型/虚函数、模板/泛型
  - 并发：线程/线程池
  - Linux/OS：进程/线程/调度
  - 项目/工程：项目深挖、性能压测
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；项目 README、压测、debug 和面试讲稿

### 179. [字节泛架构二面面经](https://www.nowcoder.com/feed/main/detail/2819636)

- 时间：2026-03-25
- 公司/组织：字节
- 岗位/方向：Infra / 基础架构，C++ 后端/服务端，C++ 开发
- 轮次：一面 / 二面 / HR面
- 作者认证：合肥工业大学 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 后端/服务端，C++ 开发，面试内容集中在 中间件/分布式：Redis/缓存、MySQL/数据库；项目/工程：项目深挖；手撕/算法：链表/树/图、生产级代码，并涉及 链表/树/图、手写数据结构/复杂度分析。
- 面试内容整理：
  - 中间件/分布式：Redis/缓存、MySQL/数据库
  - 项目/工程：项目深挖
  - 手撕/算法：链表/树/图、生产级代码
- 手撕/代码：链表/树/图、手写数据结构/复杂度分析
- 对你规划的用处：Mini Redis / MySQL / 分布式后置主线；项目 README、压测、debug 和面试讲稿；每周 2-3 题保持手感

### 180. [小米 C++ 软件开发 一面 面经](https://www.nowcoder.com/discuss/866392896113496064)

- 时间：2026-03-25
- 公司/组织：字节 / 小米
- 岗位/方向：Infra / 基础架构，C++ 后端/服务端，C++ 开发
- 轮次：一面 / 技术面 / OC
- 作者认证：浙江大学 算法工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 后端/服务端，C++ 开发，面试内容集中在 C++：RAII、拷贝/移动语义、智能指针、STL 容器、对象模型/虚函数、内存管理、模板/泛型、异常安全；并发：线程/线程池、锁/条件变量、atomic/CAS；Linux/OS：进程/线程/调度、虚拟内存/mmap/COW、fd/系统调用/IO、排查工具；网络：TCP/UDP/HTTP，并涉及 链表/树/图、TopK/堆/排序、动态规划/字符串、手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：RAII、拷贝/移动语义、智能指针、STL 容器、对象模型/虚函数、内存管理、模板/泛型、异常安全
  - 并发：线程/线程池、锁/条件变量、atomic/CAS
  - Linux/OS：进程/线程/调度、虚拟内存/mmap/COW、fd/系统调用/IO、排查工具
  - 网络：TCP/UDP/HTTP
  - 中间件/分布式：Redis/缓存、Kafka/消息队列、存储系统
  - AI Infra：LLM Serving
- 手撕/代码：链表/树/图、TopK/堆/排序、动态规划/字符串、手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor

### 181. [CVTE C++ 软件开发 二面 面经](https://www.nowcoder.com/discuss/864811056835719168)

- 时间：2026-03-21
- 公司/组织：字节
- 岗位/方向：Infra / 基础架构，C++ 后端/服务端，C++ 开发
- 轮次：一面 / 二面 / 技术面 / OC
- 作者认证：浙江大学 算法工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 后端/服务端，C++ 开发，面试内容集中在 C++：RAII、智能指针、STL 容器、对象模型/虚函数、内存管理、模板/泛型、异常安全、const/static/volatile；并发：线程/线程池；Linux/OS：进程/线程/调度、虚拟内存/mmap/COW、fd/系统调用/IO；网络：TCP/UDP/HTTP、epoll/Reactor，并涉及 链表/树/图、动态规划/字符串。
- 面试内容整理：
  - C++：RAII、智能指针、STL 容器、对象模型/虚函数、内存管理、模板/泛型、异常安全、const/static/volatile
  - 并发：线程/线程池
  - Linux/OS：进程/线程/调度、虚拟内存/mmap/COW、fd/系统调用/IO
  - 网络：TCP/UDP/HTTP、epoll/Reactor
  - 中间件/分布式：Redis/缓存、Kafka/消息队列、存储系统
  - AI Infra：LLM Serving
- 手撕/代码：链表/树/图、动态规划/字符串
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor

### 182. [百度 C++软件开发 二面 面经](https://www.nowcoder.com/discuss/863771805712949248)

- 时间：2026-03-18
- 公司/组织：百度
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：二面 / 技术面 / OC
- 作者认证：浙江大学 算法工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 C++：RAII、拷贝/移动语义、智能指针、STL 容器、对象模型/虚函数、内存管理、模板/泛型、异常安全；并发：线程/线程池、锁/条件变量、atomic/CAS；Linux/OS：进程/线程/调度、虚拟内存/mmap/COW、fd/系统调用/IO、排查工具；网络：TCP/UDP/HTTP、连接状态、epoll/Reactor、RPC/协议，并涉及 TopK/堆/排序、动态规划/字符串。
- 面试内容整理：
  - C++：RAII、拷贝/移动语义、智能指针、STL 容器、对象模型/虚函数、内存管理、模板/泛型、异常安全
  - 并发：线程/线程池、锁/条件变量、atomic/CAS
  - Linux/OS：进程/线程/调度、虚拟内存/mmap/COW、fd/系统调用/IO、排查工具
  - 网络：TCP/UDP/HTTP、连接状态、epoll/Reactor、RPC/协议
  - 中间件/分布式：MySQL/数据库
  - 项目/工程：性能压测
- 手撕/代码：TopK/堆/排序、动态规划/字符串
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor

### 183. [虾皮-信贷业务-后端一面](https://www.nowcoder.com/feed/main/detail/2803425)

- 时间：2026-03-10
- 公司/组织：虾皮
- 岗位/方向：Infra / 基础架构，C++ 后端/服务端，C++ 开发
- 轮次：一面
- 作者认证：蚌埠坦克学院 推荐算法
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 后端/服务端，C++ 开发，面试内容集中在 C++：STL 容器、对象模型/虚函数；中间件/分布式：MySQL/数据库、存储系统。
- 面试内容整理：
  - C++：STL 容器、对象模型/虚函数
  - 中间件/分布式：MySQL/数据库、存储系统
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Mini Redis / MySQL / 分布式后置主线

### 184. [字节日常实习一面自我感觉良好，但是两天了都没收到后续消息](https://www.nowcoder.com/feed/main/detail/2779442)

- 时间：2026-01-08
- 公司/组织：字节
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：一面
- 作者认证：门头沟学院 算法工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 项目/工程：项目深挖；手撕/算法：链表/树/图、生产级代码，并涉及 链表/树/图、手写数据结构/复杂度分析。
- 面试内容整理：
  - 项目/工程：项目深挖
  - 手撕/算法：链表/树/图、生产级代码
- 手撕/代码：链表/树/图、手写数据结构/复杂度分析
- 对你规划的用处：项目 README、压测、debug 和面试讲稿；每周 2-3 题保持手感

### 185. [字节电商面经3面-后端开发](https://www.nowcoder.com/feed/main/detail/2696796)

- 时间：2025-10-13
- 公司/组织：字节
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：未标明
- 作者认证：东华大学 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 Linux/OS：排查工具。
- 面试内容整理：
  - Linux/OS：排查工具
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week4-5：Linux 系统编程与 OS 基础

### 186. [阿里云秋招后端开发一面，含智力题](https://www.nowcoder.com/discuss/797588492166463488)

- 时间：2025-09-16
- 公司/组织：阿里 / 腾讯
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：一面
- 作者认证：未显示
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 C++：内存管理、模板/泛型；网络：TCP/UDP/HTTP；手撕/算法：二分/滑窗/TopK，并涉及 TopK/堆/排序。
- 面试内容整理：
  - C++：内存管理、模板/泛型
  - 网络：TCP/UDP/HTTP
  - 手撕/算法：二分/滑窗/TopK
- 手撕/代码：TopK/堆/排序
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week6 + 项目线：socket、epoll、Reactor；每周 2-3 题保持手感

### 187. [字节一面](https://www.nowcoder.com/feed/main/detail/2837358)

- 时间：2026-04-17
- 公司/组织：字节
- 岗位/方向：Infra / 基础架构，C++ 后端/服务端，C++ 开发
- 轮次：一面
- 作者认证：东北大学 嵌入式工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 后端/服务端，C++ 开发，面试内容集中在 C++：const/static/volatile；中间件/分布式：存储系统。
- 面试内容整理：
  - C++：const/static/volatile
  - 中间件/分布式：存储系统
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Mini Redis / MySQL / 分布式后置主线

### 188. [滴滴 C++后端开发 一面 面经](https://www.nowcoder.com/discuss/870354606277021696)

- 时间：2026-04-05
- 公司/组织：腾讯 / 滴滴
- 岗位/方向：Infra / 基础架构，C++ 后端/服务端，C++ 开发
- 轮次：一面 / 技术面 / OC
- 作者认证：浙江大学 算法工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 后端/服务端，C++ 开发，面试内容集中在 C++：智能指针、STL 容器、对象模型/虚函数、内存管理、模板/泛型、const/static/volatile；并发：线程/线程池、锁/条件变量；Linux/OS：进程/线程/调度、fd/系统调用/IO；网络：TCP/UDP/HTTP、epoll/Reactor，并涉及 LRU/LFU 缓存、线程池/阻塞队列、链表/树/图、动态规划/字符串、手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：智能指针、STL 容器、对象模型/虚函数、内存管理、模板/泛型、const/static/volatile
  - 并发：线程/线程池、锁/条件变量
  - Linux/OS：进程/线程/调度、fd/系统调用/IO
  - 网络：TCP/UDP/HTTP、epoll/Reactor
  - 中间件/分布式：Redis/缓存、MySQL/数据库、Kafka/消息队列、分布式基础、存储系统
  - AI Infra：LLM Serving
- 手撕/代码：LRU/LFU 缓存、线程池/阻塞队列、链表/树/图、动态规划/字符串、手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor

### 189. [北京心影随行科技有限公司 C++ 一面 面经](https://www.nowcoder.com/discuss/862251219832664064)

- 时间：2026-03-14
- 公司/组织：字节
- 岗位/方向：Infra / 基础架构，C++ 后端/服务端，C++ 开发
- 轮次：一面
- 作者认证：浙江大学 算法工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 后端/服务端，C++ 开发，面试内容集中在 C++：异常安全；并发：线程/线程池；Linux/OS：进程/线程/调度；网络：TCP/UDP/HTTP、RPC/协议，并涉及 动态规划/字符串。
- 面试内容整理：
  - C++：异常安全
  - 并发：线程/线程池
  - Linux/OS：进程/线程/调度
  - 网络：TCP/UDP/HTTP、RPC/协议
  - 中间件/分布式：Redis/缓存
  - 项目/工程：项目深挖、工程工具、性能压测
- 手撕/代码：动态规划/字符串
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor

### 190. [wxg微信读书一面](https://www.nowcoder.com/feed/main/detail/2868181)

- 时间：2026-06-26
- 公司/组织：腾讯
- 岗位/方向：Infra / 基础架构，C++ 开发
- 轮次：一面
- 作者认证：西安工业大学 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 开发，面试内容集中在 C++：智能指针；并发：线程/线程池；Linux/OS：进程/线程/调度、fd/系统调用/IO；网络：epoll/Reactor，并涉及 链表/树/图。
- 面试内容整理：
  - C++：智能指针
  - 并发：线程/线程池
  - Linux/OS：进程/线程/调度、fd/系统调用/IO
  - 网络：epoll/Reactor
  - 中间件/分布式：Redis/缓存、MySQL/数据库
  - 手撕/算法：链表/树/图
- 手撕/代码：链表/树/图
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor

### 191. [滴滴 C++后端开发 二面 面经](https://www.nowcoder.com/discuss/870601191745454080)

- 时间：2026-04-06
- 公司/组织：滴滴
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：二面 / 技术面 / OC
- 作者认证：浙江大学 算法工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 C++：RAII、拷贝/移动语义、智能指针、STL 容器、对象模型/虚函数、内存管理、模板/泛型、const/static/volatile；并发：线程/线程池；Linux/OS：进程/线程/调度、fd/系统调用/IO、排查工具；网络：TCP/UDP/HTTP、epoll/Reactor、RPC/协议，并涉及 TopK/堆/排序、动态规划/字符串、手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：RAII、拷贝/移动语义、智能指针、STL 容器、对象模型/虚函数、内存管理、模板/泛型、const/static/volatile
  - 并发：线程/线程池
  - Linux/OS：进程/线程/调度、fd/系统调用/IO、排查工具
  - 网络：TCP/UDP/HTTP、epoll/Reactor、RPC/协议
  - 中间件/分布式：MySQL/数据库、Kafka/消息队列
  - 项目/工程：项目深挖、工程工具、性能压测
- 手撕/代码：TopK/堆/排序、动态规划/字符串、手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor

### 192. [阿里云26秋招后端开发一面](https://www.nowcoder.com/feed/main/detail/2738628)

- 时间：2025-11-10
- 公司/组织：阿里 / 腾讯
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：一面
- 作者认证：门头沟学院 Java
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 C++：内存管理、模板/泛型；网络：TCP/UDP/HTTP；手撕/算法：二分/滑窗/TopK，并涉及 TopK/堆/排序。
- 面试内容整理：
  - C++：内存管理、模板/泛型
  - 网络：TCP/UDP/HTTP
  - 手撕/算法：二分/滑窗/TopK
- 手撕/代码：TopK/堆/排序
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week6 + 项目线：socket、epoll、Reactor；每周 2-3 题保持手感

### 193. [C++开发面经-华为OD-23届](https://www.nowcoder.com/discuss/809729676418502656)

- 时间：2025-10-20
- 公司/组织：华为 / OD
- 岗位/方向：Infra / 基础架构，C++ 后端/服务端，C++ 开发
- 轮次：一面 / 二面 / 技术面
- 作者认证：南京邮电大学 Java
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 后端/服务端，C++ 开发，面试内容集中在 C++：内存管理；并发：线程/线程池；网络：TCP/UDP/HTTP；项目/工程：项目深挖，并涉及 链表/树/图、TopK/堆/排序、二分/滑动窗口、动态规划/字符串、手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：内存管理
  - 并发：线程/线程池
  - 网络：TCP/UDP/HTTP
  - 项目/工程：项目深挖
  - 手撕/算法：链表/树/图、二分/滑窗/TopK、动态规划/字符串、生产级代码
- 手撕/代码：链表/树/图、TopK/堆/排序、二分/滑动窗口、动态规划/字符串、手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week6 + 项目线：socket、epoll、Reactor；项目 README、压测、debug 和面试讲稿

### 194. [虾皮二面凉经](https://www.nowcoder.com/feed/main/detail/2712432)

- 时间：2025-10-11
- 公司/组织：虾皮
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：二面
- 作者认证：门头沟学院 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 并发：线程/线程池；Linux/OS：进程/线程/调度；项目/工程：项目深挖。
- 面试内容整理：
  - 并发：线程/线程池
  - Linux/OS：进程/线程/调度
  - 项目/工程：项目深挖
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；项目 README、压测、debug 和面试讲稿

### 195. [华为OD 面经分享 软开 C++](https://www.nowcoder.com/feed/main/detail/2695075)

- 时间：2025-09-18
- 公司/组织：华为 / OD
- 岗位/方向：Infra / 基础架构，C++ 开发
- 轮次：一面 / 二面 / HR面
- 作者认证：北京邮电大学 Java
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 开发，面试内容集中在 C++：智能指针、内存管理、const/static/volatile；并发：线程/线程池；Linux/OS：进程/线程/调度；网络：TCP/UDP/HTTP，并涉及 TopK/堆/排序、手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：智能指针、内存管理、const/static/volatile
  - 并发：线程/线程池
  - Linux/OS：进程/线程/调度
  - 网络：TCP/UDP/HTTP
  - 中间件/分布式：存储系统
  - 项目/工程：项目深挖
- 手撕/代码：TopK/堆/排序、手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor

### 196. [美团 基础研发平台 一面面经](https://www.nowcoder.com/feed/main/detail/2451150)

- 时间：2024-11-01
- 公司/组织：字节 / 美团
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：一面
- 作者认证：字节跳动 后端开发工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 C++：内存管理；项目/工程：项目深挖。
- 面试内容整理：
  - C++：内存管理
  - 项目/工程：项目深挖
- 手撕/代码：原帖未明显提到或只笼统提到手撕
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；项目 README、压测、debug 和面试讲稿

### 197. [腾讯c++后端wxg 日常实习 一面面经](https://www.nowcoder.com/feed/main/detail/2867094)

- 时间：2026-06-23
- 公司/组织：腾讯
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：一面
- 作者认证：华南理工大学 C++
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 C++：内存管理；并发：锁/条件变量、atomic/CAS、生产者消费者；中间件/分布式：Redis/缓存、MySQL/数据库；项目/工程：项目深挖、工程工具，并涉及 LRU/LFU 缓存、线程池/阻塞队列、TopK/堆/排序、手写数据结构/复杂度分析。
- 面试内容整理：
  - C++：内存管理
  - 并发：锁/条件变量、atomic/CAS、生产者消费者
  - 中间件/分布式：Redis/缓存、MySQL/数据库
  - 项目/工程：项目深挖、工程工具
  - 手撕/算法：缓存题、二分/滑窗/TopK、生产级代码
- 手撕/代码：LRU/LFU 缓存、线程池/阻塞队列、TopK/堆/排序、手写数据结构/复杂度分析
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Mini Redis / MySQL / 分布式后置主线；项目 README、压测、debug 和面试讲稿

### 198. [C++ 数据库开发 面经总结](https://www.nowcoder.com/discuss/898926724425994240)

- 时间：2026-06-23
- 公司/组织：OD
- 岗位/方向：Infra / 基础架构，C++ 后端/服务端，C++ 开发
- 轮次：OC
- 作者认证：浙江大学 算法工程师
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 Infra / 基础架构，C++ 后端/服务端，C++ 开发，面试内容集中在 C++：RAII、STL 容器、内存管理、异常安全；并发：线程/线程池、锁/条件变量；Linux/OS：进程/线程/调度、fd/系统调用/IO、排查工具；网络：TCP/UDP/HTTP、epoll/Reactor，并涉及 动态规划/字符串。
- 面试内容整理：
  - C++：RAII、STL 容器、内存管理、异常安全
  - 并发：线程/线程池、锁/条件变量
  - Linux/OS：进程/线程/调度、fd/系统调用/IO、排查工具
  - 网络：TCP/UDP/HTTP、epoll/Reactor
  - 中间件/分布式：Redis/缓存、MySQL/数据库、Kafka/消息队列、存储系统
  - 项目/工程：项目深挖、工程工具、性能压测
- 手撕/代码：动态规划/字符串
- 对你规划的用处：Week1-3：C++ 对象、RAII、STL、内存管理；Week7-8：线程、锁、线程池、异步日志；Week4-5：Linux 系统编程与 OS 基础；Week6 + 项目线：socket、epoll、Reactor

### 199. [WXG后台开发一面面经](https://www.nowcoder.com/feed/main/detail/2853782)

- 时间：2026-05-19
- 公司/组织：腾讯 / WXG
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：一面
- 作者认证：北京懂车帝科技有限公司 后端(实习)
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 项目/工程：项目深挖；手撕/算法：链表/树/图，并涉及 链表/树/图。
- 面试内容整理：
  - 项目/工程：项目深挖
  - 手撕/算法：链表/树/图
- 手撕/代码：链表/树/图
- 对你规划的用处：项目 README、压测、debug 和面试讲稿；每周 2-3 题保持手感

### 200. [字节一面 AI Agent面经？](https://www.nowcoder.com/feed/main/detail/2836844)

- 时间：2026-04-20
- 公司/组织：字节
- 岗位/方向：C++ 后端/服务端，C++ 开发
- 轮次：一面
- 作者认证：未显示
- 筛选层级：严格匹配：大厂/知名公司 + C++/Infra/AI Infra
- 原帖核心：这篇主要对应 C++ 后端/服务端，C++ 开发，面试内容集中在 手撕/算法：生产级代码，并涉及 手写数据结构/复杂度分析。
- 面试内容整理：
  - 手撕/算法：生产级代码
- 手撕/代码：手写数据结构/复杂度分析
- 对你规划的用处：每周 2-3 题保持手感
