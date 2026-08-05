### 问题 1

UDP 没有 TCP handshake，为什么 `sendto` 仍然知道把 datagram 发给谁？

因为 `sendto` 每次调用都提供 destination socket address

### 问题 2

假设：

```text
fd = 3
local port = 8080
```

分别解释 `3` 和 `8080` 在哪里有效，它们如何通过 kernel socket object 联系起来。

fd=3 是一个用于访问 kernel object 的整数 handle，在 application layer

8080 是在 UDP layer 发挥作用，去找到对应的 UDP socket

就是如上，fd=3 用于在 application 访问 kernel socket object。然后 port 会去帮助找到 UDP socket

### 问题 3

sender 连续发送：

```text
3-byte datagram
5-byte datagram
```

如果两条都到达，receiver 的一次普通 `recvfrom` 会不会自动返回 8 bytes？为什么？

因为 UDP 交付的是有明确边界的 message

### 问题 4

`recvfrom` 阻塞时，等待的 condition 是什么？packet 到达后，哪些明确主体依次做了什么？

就是 socket receive queue 非空

packet 进入 socket receive queue，然后去 wakeup 可能满足条件的 waiters

```text
packet 进入 IP layer
-> 交给 UDP layer
-> destination port demux 到 socket
-> datagram 进入 receive queue
-> waiter 变为 RUNNABLE
-> scheduler 将来恢复 waiter
-> recvfrom 复制一条 datagram 并返回
```



### 问题 5

为什么 echo 必须使用 `recvfrom` 的返回值作为 `sendto` length，而不能使用 `strlen(buffer)`？

因为是要把收到的信息发出去，而且不是 C 风格字符串，无 \0 结尾

### 问题 6

`sendto` 返回 payload length，能否证明 peer application 已收到？为什么？

不能。因为这个只是发出去了这么多，在中途可能丢失之类的

### 问题 7

解释：

```text
stub resolver
向 recursive resolver 进行询问

recursive resolver

root DNS server
TLD DNS server
authoritative DNS server
```

它们在一次没有 cache 命中的查询中分别做什么？

```text
stub resolver
向 recursive resolver 进行询问

application/stub resolver
    |
    v
recursive resolver，也就是常说的 local DNS server（才会去递归跑这个查询）
    |
    +--> 问 root：
    |       .com 应该继续问谁？
    |
    +--> 问 .com TLD server：
    |       example.com 的 authoritative server 是谁？
    |
    +--> 问 authoritative server：
    |       example.com 的 A record 是什么？
    |
    v
recursive resolver cache 结果
    |
    v
把 IPv4 answer 返回 application
```



### 问题 8

为什么 `dig example.com A` 的 `SERVER` 通常不是 root server？

`dig` 默认直接询问系统配置的 recursive resolver，`SERVER` 显示的就是它。cache 只影响 resolver 是否继续询问上游，不是 `SERVER` 不是 root 的原因。

### 问题 9

今天在 `127.0.0.1` 上完成 UDP echo，为什么通常观察不到 Day2 的 ARP 和 router forwarding？

`127.0.0.1` 走本机 loopback path，packet 不离开 host，因此不需要 next-hop MAC、ARP 或 router forwarding。

### 问题 10

UDP `recvfrom` 返回 `0` 表示什么？为什么不能套用 TCP EOF 的解释？

表示收到 payload length=0 的 datagram

因为这个也是 message，UDP 允许 payload 为空