# Week6：网络原理第一轮 + 阻塞式 Socket 编程

> 定位：Week4 已经掌握 Linux fd 与阻塞 I/O，Week5 已经理解 blocking、scheduler、sleep/wakeup 和 condition variable。Week6 从这些基础自然进入网络：应用程序仍然通过 fd 发起系统调用，只是 fd 背后的内核对象从普通文件或 pipe 变成 socket。
>
> 本周主线：网络分层与地址 -> Ethernet / ARP / IP -> UDP / DNS -> TCP server -> TCP client 与字节流 -> TCP 状态和可靠性 -> HTTP 文本协议。
>
> 本周仍然是第一轮：目标是能独立写出可验证的阻塞式 TCP client/server，并解释 API 背后的连接、队列、阻塞与协议状态；不提前进入 I/O 多路复用、Reactor、线程池或高性能网卡。

---

## 1. 规划依据

### 1.1 当前真实起点

已经通过 Week5 出口验收：

```text
能解释 fd -> open file description / kernel object 的资源访问模型
知道 read/write 最终通过 system call 进入 kernel
能解释 blocking execution flow 为什么不持续占用 CPU
能区分 SLEEPING、RUNNABLE 和 RUNNING
知道 scheduler、context switch、sleep/wakeup 的职责边界
能解释 predicate + mutex + wait/notify 如何避免 lost wakeup
能使用 C++ RAII 管理 fd，能处理 read/write 的 ssize_t 返回值
会用 strace、ss、ps、lsof 等 Linux 工具观察程序
```

因此 Week6 不重新安排：

```text
重新写普通文件 read/write demo
重新讲 fd 是一个整数编号
重新练 UniqueFd 的拷贝/移动语义
重新手推 scheduler 或 condition_variable
重新完成 pipe 父子进程通信
```

Week6 要回答的新问题是：

```text
当 fd 背后是 socket 时，kernel 还维护了哪些网络状态？
两个不同主机上的进程，怎样通过协议栈和网络互相交换字节？
```

### 1.2 结合实际学习速度

你的 C++、Linux API 和 OS 基础推进较快，重复写同类 demo 收益低。本周采用：

```text
先建立一条完整 packet / byte flow
-> 再认识当天必需的 socket API
-> 独立实现一个能运行的最小程序
-> 用 Linux 工具观察 kernel 状态
-> 最后解释现象，而不是只记录命令输出
```

每天只新增一层主要复杂度：

```text
Day1：分层与端到端路径
Day2：地址、ARP、IP 与路由
Day3：无连接的 UDP 和 DNS
Day4：TCP server 端资源与调用链
Day5：TCP client、字节流与健壮收发
Day6：TCP 状态机和可靠传输直觉
Day7：HTTP 在 TCP 字节流上的消息边界
```

已经掌握的机制只做连接，不要求重复长篇证明。每日 note 仍优先记录：

```text
当天真正新增的概念
自己卡住的因果链
运行结果与工具证据
错误实验的原因和修正
验收问题答案
```

---

## 2. 本周核心问题

```text
1. application、socket layer、TCP/UDP、IP、Ethernet 分别负责什么？
2. packet、segment、datagram、byte stream 在当前层次分别指什么？
3. IP address、port、socket、connection、fd 为什么不是同一个东西？
4. 从应用调用 send 到另一端 recv 返回，中间有哪些明确的执行主体？
5. socket 为什么也能使用 fd、read/write/close 这一套接口？
6. bind、listen、accept、connect 分别改变了什么 kernel state？
7. listening socket 与 connected socket 为什么是两个不同的 fd？
8. blocking accept/recv 没有数据时，当前 execution flow 去了哪里？
9. 为什么 TCP 的一次 send 不对应对端的一次 recv？
10. partial write、partial read、EOF 和 error 应该怎样区分？
11. TCP 三次握手和四次挥手分别解决什么问题？
12. TIME_WAIT 和 CLOSE_WAIT 分别说明哪一方做过什么、还没做什么？
13. TCP 为什么能提供可靠、有序的 byte stream？
14. flow control 与 congestion control 分别保护谁？
15. UDP 为什么保留 datagram boundary，却不保证可靠与有序？
16. DNS 怎样把 domain name 逐步变成可连接的 IP address？
17. HTTP 怎样在没有 TCP 消息边界的 byte stream 上定义自己的消息边界？
```

---

## 3. 本周目标深度

### 3.1 网络分层与地址

本周结束时做到：

```text
能画 application -> transport -> network -> link 的发送和接收路径
知道发送时逐层添加 header，接收时逐层检查并移除 header
能区分 MAC address、IP address 和 port 的第一层职责
知道 loopback、local network、router 和 default route 的作用
知道 IPv4 address 与 port 共同参与定位通信 endpoint
知道 network byte order 是 big-endian，并会使用 htons/ntohs
```

暂时不要求：

```text
背完整 Ethernet/IP/TCP header bit layout
手算复杂 subnet、CIDR 和路由聚合
深入 IPv6、NAT、VLAN、BGP、OSPF
实现 ARP/IP/TCP 协议栈
```

### 3.2 Socket 与阻塞 I/O

本周结束时做到：

```text
能解释 socket() 创建 kernel socket object，并返回当前进程的 fd
知道 sockaddr_in 是 IPv4 socket address 的内存表示
能说清 server 的 socket -> bind -> listen -> accept
能说清 client 的 socket -> connect
能区分 listening socket 和 accept 返回的 connected socket
知道 recv/accept 在条件不满足时可以阻塞当前 execution flow
知道 close fd 是释放进程对 socket 的一个引用，不等于凭空删除网络
能用 RAII 管理每一个成功创建的 socket fd
```

暂时不要求：

```text
select / poll / epoll
non-blocking socket
edge-triggered / level-triggered
Reactor / Proactor
多线程或线程池网络服务器
io_uring
```

### 3.3 TCP

本周结束时做到：

```text
能独立写一个 IPv4 blocking TCP echo server
能独立写一个 TCP client
知道 TCP 提供可靠、有序、全双工的 byte stream
不假设一次 send 等于一次 recv
能正确处理 partial send、partial recv、EINTR、EOF 和错误
能解释三次握手与四次挥手的第一层因果链
能使用 ss 观察 LISTEN、ESTABLISHED、TIME-WAIT 等状态
能区分 TIME_WAIT 与 CLOSE_WAIT 的责任方向
知道 sequence number、ACK、retransmission、sliding window（滑动窗口）的直觉
知道 flow control（流量控制）与 congestion control（拥塞控制）解决的是不同问题
```

暂时不要求：

```text
手算复杂 TCP sequence number
背完整 TCP state transition diagram
深入 RTT estimator、RTO、SACK、Nagle、delayed ACK
深入 Reno/CUBIC/BBR 算法
百万连接或吞吐 benchmark
```

### 3.4 UDP 与 DNS

本周结束时做到：

```text
知道 UDP 保留一条 datagram 的边界
能解释 sendto/recvfrom 为什么通常不先建立连接
知道 UDP 可能丢失、重复、乱序，protocol 本身不重传
能写或补全一个最小 UDP echo server
能用 dig 观察一次 DNS 查询的结果
知道 resolver、recursive resolver、root、TLD、authoritative server 的基本角色
知道 DNS cache 会让实际查询路径缩短
```

暂时不要求：

```text
手写 DNS binary packet parser
实现 UDP 可靠传输
深入 DNSSEC、DoH、DoT
完整掌握所有 DNS record types
```

### 3.5 HTTP

本周结束时做到：

```text
知道 HTTP/1.1 是运行在 TCP byte stream 上的 application protocol
能区分 request line、status line、headers、empty line 和 body
知道 CRLF 是什么
能解释 Content-Length 如何帮助确定 body boundary
能解析一个受控范围内的 HTTP request text
能用 nc/curl 向本地服务发送请求并观察原始文本
```

暂时不要求：

```text
完整 HTTP server
chunked transfer encoding
复杂 keep-alive/pipelining
TLS / HTTPS
HTTP/2、HTTP/3、QUIC
浏览器完整加载流程
```

---

## 4. MIT 6.S081 使用方式

本周参考：

- [Lec21 Networking](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/lec21-networking-robert)
- [21.1 计算机网络概述](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/lec21-networking-robert/21.1-ji-suan-ji-wang-luo-gai-shu)
- [21.2 二层网络：Ethernet](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/lec21-networking-robert/21.2-er-ceng-wang-luo-ethernet)
- [21.3 二/三层地址转换：ARP](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/lec21-networking-robert/21.3-er-san-ceng-di-zhi-zhuan-huan-arp)
- [21.4 三层网络：Internet](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/lec21-networking-robert/21.4-san-ceng-wang-luo-internet)
- [21.5 四层网络：UDP](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/lec21-networking-robert/21.5-si-ceng-wang-luo-udp)
- [21.6 网络协议栈](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081/lec21-networking-robert/21.6-wang-lu-xie-yi-zhan-network-stack)

本周只对 Lec21 做与主线一致的第一段：

```text
Day1：21.1
Day2：21.2~21.4
Day3：21.5~21.6
Day4~Day7：回到 Linux socket、TCP、DNS 和 HTTP 主线
```

掌握程度：

```text
能解释分层、header、address、packet path 和 socket layer
能把课程里的 packet flow 与 Linux 应用的 socket fd 接起来
能说清 UDP/IP/Ethernet 各自只负责当前层的事情
不背 packet header 每个字段
不进入 xv6 NIC driver 源码
```

`21.7 Ring Buffer`、`21.8 Receive Livelock`、`21.9 如何解决 Livelock` 本周暂缓：

```text
它们更接近网卡驱动、DMA、队列调度和高负载性能问题。
这些内容没有被永久跳过，后续高性能网络 / AI Infra 性能阶段再回到 Lec21 完成。
```

这样既保持 MIT 6.S081 最终完整通关，也不让课程顺序把 Week6 的阻塞式 socket 主线带偏。

daily 生成时必须实际阅读当天指定页面，并在教程中提供顺着课程的中文讲解，而不只留下网址和“去看某节”。仍按：

```text
先读 daily 的前情与术语
-> 读 daily 中顺着课程组织的讲解
-> 再阅读中文课程对应小节
-> 回到 Linux 命令或 C++ 代码验证
-> 用自己的因果链和运行证据收尾
```

---

## 5. 七天总览

| Day | 主线问题 | MIT 6.S081 范围 | 主要观察或产出 |
|---|---|---|---|
| Day1 | 两个进程之间的字节究竟经过哪些层 | Lec21：21.1 | `network_path` 流程图；`ip addr` / `ip route` / `ss` 观察 |
| Day2 | MAC、IP、port 和 route 怎样共同把 packet 送向下一站 | Lec21：21.2~21.4 | `address_demo.cpp`；ARP/route/byte-order 观察 |
| Day3 | UDP 为什么不握手，DNS 怎样利用网络取得地址 | Lec21：21.5~21.6 | `udp_echo_server.cpp`；`nc -u` / `dig` |
| Day4 | TCP server 怎样从 socket fd 走到 connected fd | 只复用 21.6 socket layer | `tcp_echo_server_v1.cpp`；`ss -lntp` / `nc` |
| Day5 | TCP client 怎样连接；byte stream 为什么必须循环收发 | 不新增 6.S081 | `tcp_client.cpp`；升级为健壮 echo pair |
| Day6 | TCP 怎样建立、关闭并提供可靠传输 | 不新增 6.S081 | `ss -tanp` 状态观察；可选 `tcpdump` |
| Day7 | HTTP 怎样在 TCP byte stream 上划分 request | 不新增 6.S081 | `http_request_parser.cpp`；`curl` / `nc` 联调 |

---

# Day1：从“send 出去”到另一端“recv 返回”

## 今日目标

```text
从完整端到端问题开始，而不是先背七层模型
建立 application -> transport -> network -> link 的当前层次模型
区分 message、byte stream、segment/datagram、IP packet、Ethernet frame
理解 encapsulation / decapsulation
知道 local host、loopback、NIC、router 和 remote host 在路径中的位置
把 Week5 的 blocking I/O 接到 socket receive queue
```

## MIT 6.S081 范围

必读：

```text
21.1 计算机网络概述
```

听到这个程度：

```text
知道网络系统为什么采用分层协议
知道每一层只向相邻层提供接口
知道 packet 在发送和接收方向会经历相反的封装过程
能讲出“应用数据不会直接跳到远端应用”的完整路径
```

今天不要深入：

```text
Ethernet/IP header 的具体字段
TCP 状态机
socket API 的完整参数
```

## 计划产出

不要求为了“有代码”而写无意义 demo。完成：

```text
1. 在 day1_note.md 画发送与接收的完整双向流程图
2. 用 ip addr 找到 loopback 与当前 NIC address
3. 用 ip route 找到 local route 和 default route
4. 用 ss -lntup 观察本机正在使用的 TCP/UDP sockets
5. 解释 localhost 通信为什么也能经过协议栈，但通常不经过物理网卡
```

Day1 通过标准：

```text
面对“应用调用 send 后谁接手”时，不再只回答“网络发过去”
能够逐层说出执行主体、数据形态和下一步
```

---

# Day2：地址不是一个东西，路由也不是“直接找到目标”

## 今日目标

```text
区分 MAC address、IPv4 address、port 和 socket endpoint
理解 Ethernet 负责同一 link 上的一跳传输
理解 ARP 用 IPv4 address 查询当前链路需要的 MAC address
理解 IP routing 决定下一跳，不保证一次直达最终主机
理解 port 用于把到达主机的数据交给正确的 transport endpoint
掌握 host byte order / network byte order
```

## MIT 6.S081 范围

按顺序阅读：

```text
21.2 二层网络：Ethernet
21.3 二/三层地址转换：ARP
21.4 三层网络：Internet
```

听到这个程度：

```text
能画 local host -> next hop/router -> remote network 的第一层路径
知道 MAC address 通常只在当前 link 上承担交付
知道 IP address 用于跨 network 的逻辑寻址和 routing
知道 ARP 解决的是“已知同链路 IPv4/next-hop IP，下一帧交给哪个 MAC”
```

暂时不要求：

```text
背 Ethernet frame 和 IPv4 header 的所有 bit
复杂 subnetting 计算
深入 router forwarding table 算法
```

## 计划产出

`address_demo.cpp` 只承担明确目标：

```text
1. 使用 inet_pton 把 IPv4 text 转成 network binary form
2. 使用 inet_ntop 把 binary form 转回 text
3. 使用 htons/ntohs 观察一个 16-bit port 的 byte order
4. 输出原值和转换后的 byte sequence
```

Linux 观察：

```text
ip addr
ip route
ip neigh
ping -c 1 <同网段或网关地址>
```

Day2 通过标准：

```text
不再把 IP、port、fd 和 socket 混成一个“地址”
能够解释一个 remote IPv4 packet 为什么仍需要先交给 next-hop MAC
```

---

# Day3：UDP 没有连接，为什么仍然能把数据送到对端

## 今日目标

```text
理解 UDP datagram 的边界与 endpoint
认识 socket、bind、sendto、recvfrom
理解 UDP 没有 TCP handshake 和 per-connection reliable byte stream
把 packet 经过 network stack 的接收路径串起来
建立 DNS 查询的第一层完整流程
```

## MIT 6.S081 范围

按顺序阅读：

```text
21.5 四层网络：UDP
21.6 网络协议栈
```

听到这个程度：

```text
知道 UDP header 的核心是 source/destination port、length、checksum
知道接收 packet 会自底向上解析，发送 packet 会自顶向下添加 header
知道 socket layer 把 transport endpoint 与应用可用的 fd/queue 联系起来
知道 recvfrom 阻塞时，数据到达后由协议栈放入相应 socket receive queue
```

今天停止在：

```text
socket layer 与 UDP/IP/Ethernet 的职责边界
不进入 NIC driver、DMA ring、receive livelock
```

## 计划产出

独立实现 `udp_echo_server.cpp`：

```text
IPv4 + UDP
bind 到 loopback 的指定 port
recvfrom 一条 datagram
把同一批 bytes 用 sendto 发回原 peer
检查每个 system call 返回值
使用 RAII 管理 socket fd
```

测试：

```text
使用 nc -u 发送不同长度 datagram
用 ss -lunp 观察 bound UDP socket
使用 dig 查询一个 domain name，记录 answer、server、query time
```

不强制再写一个几乎重复的 UDP client；`nc -u` 足以完成本日客户端角色。若 daily 判断你需要练 `sendto`，再把 client 设为增强项。

Day3 通过标准：

```text
能明确说明 UDP 的“一次接收对应一条 datagram”与 TCP byte stream 的差异
能讲出 DNS 从 application/resolver 到取得 IP address 的基本参与者
```

---

# Day4：TCP Server 为什么需要 socket、bind、listen、accept 四步

## 今日目标

```text
从“一个 fd 为什么不能同时代表监听入口和某个具体连接”出发
理解 socket、bind、listen、accept 的职责分工
区分 listening socket 与 connected socket
理解 accept blocking 与 kernel accept queue 的第一层关系
完成第一个单连接 blocking TCP echo server
```

## 与已有 OS 知识连接

今天不新增 6.S081 阅读。daily 需要把 Week5 机制接进来：

```text
process 调用 accept/recv
-> system call 进入 kernel
-> 条件暂时不满足
-> execution flow blocking/sleeping
-> packet/connection event 到达
-> kernel 更新 socket state / receive queue
-> waiter 变为 runnable
-> 将来被 scheduler 选中
-> system call 返回
```

这只是机制连接，不要求重画 Week5 全部 scheduler 细节。

## 计划产出

独立实现 `tcp_echo_server_v1.cpp`：

```text
socket(AF_INET, SOCK_STREAM, ...)
setsockopt(SO_REUSEADDR) 的当前层次用途
bind loopback + chosen port
listen
accept 一个 client
recv 一批 bytes
send 回去
分别管理 listening fd 和 connected fd
检查每一步返回值
```

测试：

```text
server 未运行时观察 connect failure
server 运行后用 ss -lntp 确认 LISTEN
使用 nc 连接、发送、接收 echo
client 退出后 server 正常结束
```

Day4 不要求：

```text
并发 client
永久 accept loop
完整 partial-write helper
应用层 message framing
```

这些边界故意留到 Day5，避免第一份 TCP server 同时承担过多问题。

---

# Day5：TCP 是 byte stream，所以收发必须尊重边界与返回值

## 今日目标

```text
独立写 TCP client
理解 connect 的作用与 blocking 行为
确认 TCP 不保存 application message boundary
正确处理 partial send、partial recv、EINTR、EOF 和 fatal error
把 Day4 server 升级成真正可循环工作的 echo pair
```

## 核心边界

本日必须建立：

```text
send(buffer, N) 返回 n，不保证 n == N
recv(buffer, capacity) 返回 n，只说明这次取得 n bytes
recv 返回 0 表示 peer 已完成发送方向的 orderly shutdown / EOF
recv 返回 -1 才进入 errno error path
TCP 不会自动附加 '\0'
application 若需要 message boundary，必须自己定义 protocol
```

daily 应从具体错误假设出发：

```text
client send 两次，server 就一定 recv 两次吗？
```

再通过代码和观察否定这个假设。

## 计划产出

1. 新增 `tcp_client.cpp`：

```text
socket
inet_pton
connect
从参数或 stdin 获得待发送 bytes
循环 send
读取 echo
处理 EOF/error
```

2. 将 Day4 server 升级为 `tcp_echo_server.cpp`：

```text
对一个 connected client 循环 recv
每批收到多少就只发送多少
使用 send_all helper 处理 partial send
peer EOF 后正确关闭 connected fd
至少可以继续 accept 下一个 client，或明确保持单连接版本并解释边界
```

3. 测试：

```text
空输入
短文本
包含换行的文本
明显大于单次 buffer 的输入
client 先关闭
server 不存在或 port 错误
```

Day5 通过标准：

```text
代码里不存在“send 一次必定写完”或“recv 一次得到完整消息”的隐含假设
能区分 transport byte stream 与 application protocol message
```

---

# Day6：连接建立和关闭后，kernel 为什么出现这些 TCP 状态

## 今日目标

```text
理解三次握手解决双方初始序列空间与收发能力确认
理解 full-duplex TCP 的两个方向可以分别关闭
理解四次挥手为何通常是两个独立方向的 FIN/ACK
区分 active close 与 passive close
理解 TIME_WAIT 与 CLOSE_WAIT 的第一层含义
建立 reliable transport、flow control、congestion control 的不同职责
```

## 今天的机制链

daily 应完整串起：

```text
client connect
-> SYN
-> server SYN+ACK
-> client ACK
-> ESTABLISHED
-> application send/recv
-> sequence/ACK/retransmission 保证可靠有序
-> 一方 close/shutdown
-> FIN/ACK 关闭一个发送方向
-> 另一方完成剩余工作并关闭
-> 状态最终释放
```

同时明确：

```text
TIME_WAIT：通常是 active closer 已完成最后 ACK 后保留一段时间
CLOSE_WAIT：本机 kernel 已收到 peer FIN，但本机 application 还没有 close 对应 socket
```

## 计划产出

本日是机制观察日，不为了凑文件再重写一套 client/server。复用 Day5 代码：

```text
1. server LISTEN 时使用 ss -lntp
2. client 连上后观察 ESTABLISHED
3. 正常关闭后观察可能出现的 TIME-WAIT
4. 做一个受控的延迟 close 实验，观察 CLOSE-WAIT 的产生条件
5. 记录“哪一方先 close、哪一方暂未 close、ss 看到了什么”
```

可选：

```text
使用 tcpdump -i lo 抓 loopback 上的 SYN/FIN/ACK
只确认 handshake/close 顺序，不要求分析完整 header
```

可靠性掌握到：

```text
sequence number：标识 byte stream 中的位置
ACK：确认已经收到的范围
retransmission：超时或其他信号表明丢失时重发
sliding window（滑动窗口）：允许多个尚未逐一确认的 bytes/segments 在途
flow control（流量控制）：避免 sender 压垮 receiver
congestion control（拥塞控制）：避免 sender 向 network 注入过多流量
```

不要求背算法或公式。

---

# Day7：HTTP 怎样从没有消息边界的 TCP 中解析出一条请求

## 今日目标

```text
把 application protocol 与 TCP byte stream 接起来
认识 HTTP/1.1 request/response 的文本结构
理解 CRLF、空行、header 和 body boundary
实现一个受控范围的 HTTP request parser
用 curl/nc 观察真实 request text
完成 Week6 出口复盘
```

## HTTP 本周范围

请求：

```text
request line: METHOD SP request-target SP HTTP-version CRLF
zero or more header fields
empty line
optional body
```

响应：

```text
status line
headers
empty line
optional body
```

必须理解：

```text
TCP 只提供 bytes，不知道 header 在哪里结束
HTTP/1.1 使用 CRLF 和 empty line 划分 start-line/headers
有 body 时还需要 Content-Length 等 framing information
一次 recv 可能只有半行，也可能包含多行甚至后续 bytes
```

## 计划产出

独立实现 `http_request_parser.cpp`，受控范围：

```text
输入一段已经完整收集到 memory 的 HTTP request text
解析 method、target、version
解析 headers 直到 empty line
header name/value 至少处理冒号和可选前导空格
若存在 Content-Length，检查 body bytes 是否足够
对 malformed request 返回明确错误，不越界
```

本周不要求 parser 直接从 socket 增量读取，也不要求写完整 HTTP server。先把：

```text
transport 收 bytes
application parser 找 message boundary
```

作为两个职责分开的模块。

观察：

```text
nc -l 监听本地 port，再用 curl 发送 request
或让已有 TCP server 打印收到的 raw bytes
记录 curl 实际发送的 request line、Host header 和 empty line
```

Week6 出口复盘：

```text
画一次 TCP client -> kernel protocol stack -> server -> HTTP parser 的完整流程
只画本周新增层次，不重复 Week5 trap/context-switch 细节
回答本周核心验收问题
```

---

## 6. 本周建议目录

Windows 学习资料：

```text
C:\Users\FxorG\Desktop\gpt_infra\week6\
├── week6.md
├── day1\
│   ├── day1.md
│   └── day1_note.md
├── day2\
│   ├── day2.md
│   └── day2_note.md
...
└── day7\
    ├── day7.md
    └── day7_note.md
```

Ubuntu 代码：

```text
~/code/system-learning/cpp/week6/
├── day1/
├── day2/
│   └── address_demo.cpp
├── day3/
│   └── udp_echo_server.cpp
├── day4/
│   └── tcp_echo_server_v1.cpp
├── day5/
│   ├── tcp_echo_server.cpp
│   └── tcp_client.cpp
├── day6/
└── day7/
    └── http_request_parser.cpp
```

不要现在一次性创建所有 daily 或代码。每天进入对应 Day 时，再依据完成状态生成教程和任务。

---

## 7. Daily 教程生成约定

每一份 `dayN.md` 固定为三个大 Part：

```text
Part 1：前情提要与必要术语
Part 2：当天教程
Part 3：收尾、练习、测试与验收
```

顺序不能调整。Part 2 的开头必须明确标出：

```text
教程开始：从“当天的具体问题”出发
```

### 7.1 术语规则

首次出现的英文术语至少解释：

```text
英文全称或词源
中文含义
在当前上下文中的作用
它不是什么
```

Week6 特别注意：

```text
socket、endpoint、peer、packet、frame、segment、datagram
bind、listen、accept、connect
backlog、queue、blocking
host/network byte order
loopback、route、gateway
ACK、FIN、RST、TIME_WAIT、CLOSE_WAIT
resolver、recursive、authoritative
request、response、header、body、CRLF
```

不能只贴 API 名称或缩写。

### 7.2 完整流程与明确主语

网络机制必须明确“谁在做什么”：

```text
client application 调用 connect
client kernel 发送 SYN
server kernel 处理连接状态
server application 在 accept 返回后获得 connected fd
sender application 调用 send
kernel protocol stack 处理 bytes/packets
receiver kernel 把 bytes 放入 socket receive queue
blocked receiver 将来被 scheduler 恢复
receiver application 的 recv 返回
```

复杂路径优先使用 Mermaid flowchart，并配合文字说明。流程图不能替代对每个节点责任的解释。

### 7.3 教学代码

每段完整教学代码必须说明：

```text
程序实现什么
怎样编译运行
每个自定义函数负责什么
关键 socket API 的参数和返回值
错误、EOF 和资源释放路径
预期输出或验证方式
```

本周所有 C++ 默认：

```bash
g++ -std=c++17 -Wall -Wextra -g source.cpp -o program
```

若 daily 引入 sanitizer，必须说明它检查什么，不能把 sanitizer 当作编译成功的替代品。

### 7.4 练习不泄露答案

练习日只提供：

```text
需求
接口范围
输入输出
状态与所有权约束
错误路径要求
测试方法
验收标准
```

不在练习前给出能直接拼接成答案的完整实现。必要的手推、参考实现拆解放在用户独立完成之后。

---

## 8. 本周工具要求

核心工具：

```text
ip addr
ip route
ip neigh
ss -lntup
ss -tanp
nc
curl
dig
strace
```

可选工具：

```text
tcpdump
lsof
getent hosts
```

工具的使用目的：

```text
ip：观察 local address、neighbor 和 route
ss：观察 kernel 中 socket 与 TCP state
nc：充当最小 TCP/UDP peer，减少重复客户端代码
curl：生成真实 HTTP request
dig：观察 DNS answer 与 resolver
strace：确认 socket/bind/listen/accept/connect/recv/send/close system calls
tcpdump：可选观察 packet，不进行深度抓包分析
```

如果 Ubuntu 缺少某个工具，在生成对应 daily 时再检查并安装；Week6 计划阶段不提前折腾环境。

---

## 9. 本周核心验收问题

1. 为什么 socket 可以表现为 fd？fd 与 socket/connection 是同一个对象吗？
2. MAC address、IP address、port 各自在哪一层解决什么问题？
3. 已知 remote IP 时，为什么发送 Ethernet frame 仍可能先需要 gateway 的 MAC？
4. server 为什么要先 bind 再 listen？
5. accept 返回的新 fd 与 listening fd 各自代表什么？
6. connect、accept 或 recv 阻塞时，application thread 与 kernel 分别在做什么？
7. 为什么一次 `send(100 bytes)` 不能假设对端一次 `recv` 就得到同样 100 bytes？
8. `recv` 返回正数、0、-1 分别表示什么？
9. TCP 为什么需要三次握手，而不是双方各发一次就结束？
10. 为什么 TCP 关闭常被描述为四次挥手？
11. TIME_WAIT 与 CLOSE_WAIT 分别更值得检查哪一方的行为？
12. sequence number、ACK 和 retransmission 怎样共同形成可靠有序的第一层直觉？
13. flow control 与 congestion control 的保护对象有何不同？
14. UDP datagram boundary 与 TCP byte stream 有何不同？
15. DNS 查询中 stub resolver、recursive resolver、root/TLD/authoritative server 各自做什么？
16. HTTP 为什么需要 CRLF、empty line 和 Content-Length 等 framing rules？
17. 如果一条 HTTP request 被拆成多次 recv，parser 和 transport 层各自应承担什么责任？

---

## 10. Week6 最终完成标准

### 核心通过

以下项目全部达到，Week6 即可通过：

```text
能画 application -> socket -> TCP/UDP -> IP -> link 的发送/接收路径
能区分 MAC、IP、port、socket fd、endpoint 和 TCP connection
能独立实现并运行 blocking TCP echo server
能独立实现并运行 TCP client
代码正确处理 partial I/O、EINTR、EOF 和 error
能使用 ss/nc 验证 LISTEN 与 ESTABLISHED
能解释三次握手、四次挥手、TIME_WAIT、CLOSE_WAIT
能解释可靠性、flow control、congestion control 的第一层差异
能解释 UDP 的语义并完成一次 UDP/DNS 观察
能解析受控范围的 HTTP/1.1 request text
所有核心 C++ 代码在规定参数下零 warning
```

### 工程增强，不阻塞 Week6

```text
支持 IPv6
支持多个并发 clients
为 socket RAII 封装补充单元测试
给 parser 加更完整的 malformed cases
使用 tcpdump 保存完整 handshake 证据
使用 sanitizer 验证 parser
```

### Week6 不通过的真正原因

```text
只能背 socket API 顺序，但解释不了每个 fd 和 kernel state
把 TCP 当成“有消息边界的安全版 UDP”
代码默认 send/recv 一次完成
分不清 EOF 与 error
把 TIME_WAIT 和 CLOSE_WAIT 混为一谈
只会运行 server，不能用 ss/nc/curl 提供验证证据
HTTP parser 假设一次 recv 就是一条完整 request
```

不会因为以下原因阻塞：

```text
没有写并发 server
没有使用 epoll
没有完整背 TCP state diagram
没有实现 DNS packet parser
没有实现 HTTPS
没有学习 6.S081 NIC driver 与 receive livelock
```

---

## 11. 与后续主线的连接

Week6 建立的是：

```text
single execution flow
+ blocking socket
+ TCP/UDP protocol semantics
+ application protocol framing
```

它会成为后续内容的直接基础：

```text
Week7：C++ 多线程、BlockingQueue、atomic
Week8：ThreadPool、异步日志、测试与 benchmark
后续网络阶段：non-blocking I/O、epoll、Reactor、timer、connection state
项目阶段：HTTP server、Mini Redis、AI Infra service/data path
性能阶段：buffer、queue、batching、backpressure、profiling
```

本周最重要的不是“背完网络八股”，而是建立这条可运行、可解释的主链：

```text
application bytes
-> socket system call
-> kernel socket / protocol state
-> packet through network
-> peer kernel receive queue
-> peer application bytes
-> application protocol parser
```

这条链以后会被线程池、epoll、Reactor、RPC 和 AI Infra 数据通路继续扩展。

---

## 12. Week6 结束后的出口

Week6 结束时，应当可以用自己的话回答：

```text
“我不只会照着模板写 socket。

我知道每个 fd 代表什么，知道 server 为什么需要 listening socket 和 connected socket，
知道阻塞发生在哪里，知道 TCP 只提供 byte stream，因此应用必须自己处理收发循环和消息边界。

我能用 ss、nc、curl、dig 和程序输出验证自己的理解，
也知道这一版为什么暂时不能处理高并发，以及后续 epoll/Reactor 要解决什么问题。”
```
