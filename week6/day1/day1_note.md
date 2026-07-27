## 感觉

感觉今天的内容都是比较抽象，比较高维的，对于一些具体路径我并不是很清楚如何 work 的，很多地方目前是没办法理的顺，只能先知道有这个东西。

## 验收

### 问题 1

MIT 6.S081 Lec21.1 为什么先从多个 LAN 和 router 讲起？为什么不把全世界所有 hosts 放进一个巨大 LAN？

因为一个简单的场景就是只有几个 host，然后他们组成一个 LAN。

router 沟通 networks

因为巨大 LAN 的 broadcast 成本会更大。比如有 1w 台 host 那么 host1 broadcast，其余的 host 都要去检查，这样很贵！

### 问题 2

Application、Transport、Network、Link 四层分别解决什么问题？为什么“层”不等于四个独立 processes？

Application 负责准备 message

Transport 负责处理端到端传输语义

Network 处理跨 network 寻址与下一跳

Link 生成当前链路上的 frame

layer 是职责和协议边界；不意味着每一层一定由一个独立的 process 运行。

### 问题 3

从 sender application 调用 `send` 开始，到 receiver application 的 `recv` 返回为止，按真实执行主体讲完整路径。

```text
1. Application A 准备 bytes
2. Application A 调用 send
3. Sender kernel socket 接收这些 bytes
4. Transport layer 处理端到端语义
5. Network layer 处理跨 network 寻址与下一跳
6. Link layer 生成当前链路上的 frame
7. Sender NIC 把 frame 交给 network
8. 去找 receiver
9. 同一 LAN 的话，，就用 switch/link 送 frame；不同 network 就用一些 intermediate routers 去转发。
10. Receiver NIC 把收到的 frame 交给 receiver kernel
11. Receiver kernel 自底向上 Link -> Network -> Transport
12. Transport payload 进入目标 socket receive queue
13. kernel 更新 receive queue 后 wakeup 等待线程。也就是让这些 execution flow RUNNABLE
14. scheduler 选择这个 execution flow RUNNING
15. recv 返回可交付给 application 的 bytes.
```



### 问题 4

receiver socket 暂时没有 data 时，`recv` 为什么可以阻塞而不持续 busy wait？packet 到达后，data、wakeup 和 scheduler 分别做什么？

如果有 data 到达，那么 kernel 会去 wakeup 对应的 execution flow。并且，receive queue 为空的时候，receiver thread 会 blocking/sleeping 然后让出 CPU。恢复后由 receive thread 在 recv path 中取 bytes

data 就放进去 socket receive queue

wakeup 就唤醒等待这个条件的 execution flow

scheduler 就选择 RUNNABLE 的 execution flow 变成 RUNNING

### 问题 5

访问 `127.0.0.1` 时，哪些 external devices 通常不会经过？为什么又不能说它完全绕过 kernel networking？

不会经过物理 NIC，外部 switch，外部 router。

因为 application 仍然用 socket，并且 kernel 处理本机网络路径。

### 问题 6

application message、TCP segment/UDP datagram、IP packet 和 Ethernet frame 分别属于哪一层？为什么一次 `send` 不能直接等同于一个 packet？

Application; Transport; Network; Link;

因为可能会分段、合并、重传之类的。

### 问题 7

`ip address`、`ip route`、`ss` 分别直接展示什么？各自不能证明什么？

我直接 copy 了。

| 命令                | 观察的主要对象                        | 不能替代什么                    |
| ------------------- | ------------------------------------- | ------------------------------- |
| `ip -brief address` | network interface 与 protocol address | 不显示 socket                   |
| `ip route`          | kernel routing table                  | 不显示 live packet              |
| `ss -lntup`         | socket state                          | 不显示完整 route 或 packet path |