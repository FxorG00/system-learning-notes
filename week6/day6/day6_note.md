## 分析抓包

```text
xgf@ubuntu:~/code/system-learning/cpp/week6/day5$ sudo tcpdump -i lo -nn -tttt 'tcp port 18080'
[sudo] password for xgf: 
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on lo, link-type EN10MB (Ethernet), capture size 262144 bytes
2026-08-08 07:20:38.269638 IP 127.0.0.1.39928 > 127.0.0.1.18080: Flags [S], seq 2959893570, win 65495, options [mss 65495,sackOK,TS val 415386028 ecr 0,nop,wscale 7], length 0
2026-08-08 07:20:38.269652 IP 127.0.0.1.18080 > 127.0.0.1.39928: Flags [S.], seq 3745674939, ack 2959893571, win 65483, options [mss 65495,sackOK,TS val 415386028 ecr 415386028,nop,wscale 7], length 0
2026-08-08 07:20:38.269664 IP 127.0.0.1.39928 > 127.0.0.1.18080: Flags [.], ack 1, win 512, options [nop,nop,TS val 415386028 ecr 415386028], length 0
2026-08-08 07:20:38.269720 IP 127.0.0.1.39928 > 127.0.0.1.18080: Flags [P.], seq 1:11, ack 1, win 512, options [nop,nop,TS val 415386028 ecr 415386028], length 10
2026-08-08 07:20:38.269725 IP 127.0.0.1.18080 > 127.0.0.1.39928: Flags [.], ack 11, win 512, options [nop,nop,TS val 415386028 ecr 415386028], length 0
2026-08-08 07:20:38.269791 IP 127.0.0.1.18080 > 127.0.0.1.39928: Flags [P.], seq 1:11, ack 11, win 512, options [nop,nop,TS val 415386028 ecr 415386028], length 10
2026-08-08 07:20:38.269817 IP 127.0.0.1.39928 > 127.0.0.1.18080: Flags [.], ack 11, win 512, options [nop,nop,TS val 415386028 ecr 415386028], length 0
2026-08-08 07:20:38.269892 IP 127.0.0.1.39928 > 127.0.0.1.18080: Flags [F.], seq 11, ack 11, win 512, options [nop,nop,TS val 415386028 ecr 415386028], length 0
2026-08-08 07:20:38.269990 IP 127.0.0.1.18080 > 127.0.0.1.39928: Flags [F.], seq 11, ack 12, win 512, options [nop,nop,TS val 415386028 ecr 415386028], length 0
2026-08-08 07:20:38.270018 IP 127.0.0.1.39928 > 127.0.0.1.18080: Flags [.], ack 12, win 512, options [nop,nop,TS val 415386028 ecr 415386028], length 0

```



这段抓包非常好，几乎把 Day5 的 echo 和 Day6 的握手、关闭完整串起来了。

先记一个最关键的点：`tcpdump` 默认会在握手后把 seq/ack 显示成**相对序号**。

所以：

```text
握手时显示真实 ISN：
client_isn = 2959893570
server_isn = 3745674939

握手后显示：
1、11、12
```

这里的 `1` 其实不是实际 TCP sequence number 为 1，而是：

```text
相对于各自 ISN + 1 的位置。
```

例如 client 后续的：

```text
seq 1:11
```

实际就是：

```text
[2959893571, 2959893581)
```

也就是 10 个 byte。

`Flags` 的读法：

```text
[S]   SYN
[S.]  SYN + ACK
[.]   ACK
[P.]  PSH + ACK
[F.]  FIN + ACK
```

`P` 是 `PSH`，可以先把它理解为“这批数据尽快交给接收应用”的提示；它不是 TCP message boundary，不能据此说“一条 `P.` 就是一条应用消息”。

逐行看：

| 行   | 报文                                                         | 含义                                                         |
| ---- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| 1    | client `39928 -> 18080`，`[S] seq 2959893570`                | client 发 SYN，选择真实 `client_isn`                         |
| 2    | server `18080 -> 39928`，`[S.] seq 3745674939 ack 2959893571` | server 发 SYN+ACK：自己的 ISN 是 `3745674939`，并确认 client SYN |
| 3    | client `[...] ack 1`                                         | 第三次 ACK。这里 `ack 1` 是相对值，实际是 `3745674940 = server_isn + 1`；client 确认 server SYN |
| 4    | client `[P.] seq 1:11 ack 1 length 10`                       | client 发 10 byte 数据；范围是 `[1, 11)`，即相对位置 1 到 10 |
| 5    | server `[.] ack 11`                                          | server 确认 client 的 10 byte 都收到了；下一步期待 client 位置 11 |
| 6    | server `[P.] seq 1:11 ack 11 length 10`                      | server 把同样 10 byte echo 回 client                         |
| 7    | client `[.] ack 11`                                          | client 确认 server 的 10 byte echo 都收到了                  |
| 8    | client `[F.] seq 11 ack 11`                                  | client 发 FIN：client 方向已经没有更多数据；FIN 使用位置 11  |
| 9    | server `[F.] seq 11 ack 12`                                  | server 同时做两件事：确认 client FIN，所以 `ack=12`；自己也发 FIN，所以 `seq=11` |
| 10   | client `[.] ack 12`                                          | client 确认 server FIN；client 随后进入 `TIME-WAIT`，server 收到该 ACK 后进入 `CLOSED` |

第 8～10 行特别有价值：它实际证明了你文档里那句“关闭常画四条 segment，但 ACK 与 FIN 有时可以合并”。

这里没有：

```text
client FIN
server ACK
server FIN
client ACK
```

而是：

```text
client FIN
server FIN + ACK
client ACK
```

所以抓包只有 3 条关闭相关 segment。server 收到 client FIN 后，逻辑上仍会经历：

```text
ESTABLISHED
-> CLOSE-WAIT
-> LAST-ACK
-> CLOSED
```

只是 server application 很快关闭了自己的方向，于是 `ACK client FIN` 和 `FIN` 合并进同一个 `[F.]` 包；`CLOSE-WAIT` 可能短到你用 `ss` 根本来不及看到。

你这次输入是 10 byte，因为：

```text
client payload: seq 1:11, length 10
server payload: seq 1:11, length 10
```

这正好对应我们前面说的左闭右开范围：

```text
[1, 11) 的长度 = 11 - 1 = 10
```

如果你想让 `tcpdump` 后续也始终显示真实绝对序号，可以加 `-S`：

```bash
sudo tcpdump -i lo -nn -tttt -S 'tcp port 18080'
```

但你当前这个相对序号输出反而很适合练习：它清楚地显示了 `SYN` 占掉 `0`，所以第一批业务数据从相对 `seq=1` 开始；10 byte 后下一位置变成 `11`；FIN 再占一个位置，确认号变成 `12`。

## 验收问题

### 问题 1

从 `client connect` 开始，到 `server accept` 返回 connected fd 为止，按主体串出完整流程。必须区分：

```text
client application
client kernel
server kernel
server application
```

做太多次了！

### 问题 2

为什么三次握手不能只记成“确认双方能收能发”？两个 ISN 分别怎样被对方确认？

因为还要确认双方的 ISN。

client 第一次握手，发 isn 过去给 server；server 学到 client 的 isn 并且发 ack=seq+1 进行确认。

同时 server 也会发送 seq=server's isn 给 client，合起来是第二次握手，SYN+ACK

然后 client 学到 server 的 isn 后会发 ack=seq+1 过去确认。

### 问题 3

解释：

```text
seq = 1000, length = 100
ack = 1100
```

这些数字描述 byte stream 的什么范围？

seq=1000,length=100，表示本次发送的是 byte stream [1000,1100) 这个 position range 的 bytes

然后 ack=1100，表示期望下一次收到 1100 开始的 pay load。

### 问题 4

为什么后到的累计 `ACK 700` 可能覆盖丢失的 `ACK 600`？ACK 确认的是 application message 还是 continuous byte progress？

因为 ACK 700，就表明前面 [1,700) 的 position 已经收到了，自然收到了 600，覆盖掉了。

continuous byte progress

### 问题 5

TCP reliable 为什么仍然不能证明：

```text
send 返回后 peer application 已处理数据
```

`send > 0` 只保证 **本机 kernel 接受了这些 bytes**。它们可能仍在本机 send buffer 中，也可能稍后重传或最终发送失败。即使 peer TCP ACK 了，也仍不能证明 peer application 已经处理。

### 问题 6

分别说明 `rwnd` 与 `cwnd` 保护谁、由谁维护/提供信息。为什么有效发送范围要同时受两者限制？

rwnd 保护 receiver；cwnd 保护网络。

前者 receiver 通告 window ；后者 sender 根据 network signals 估计

因为 sender 要确保不要把网络跟 receiver 撑爆。

### 问题 7

peer 发送 FIN 后，本机进入 CLOSE-WAIT。此时：

```text
本机还能不能 send？
recv 最终为什么返回 0？
CLOSE-WAIT 怎样才能进入 LAST-ACK？
```

可以。

本机 application 把FIN 前已经到达的普通 bytes 均读完后，recv 返回 0

当本机的 application 调用 shutdown(SHUT_WR) 或者 close

### 问题 8

TIME-WAIT 为什么可以在 fd 已 close、process 甚至已经退出后继续存在？它主要防哪两类问题？

1. 防止 client 对 server 的 FIN 的 ack 丢失，导致 server 重传 FIN 后，client 能够再次发送 ack
2. 让本次已经关闭的 connection 的旧报文在网络中彻底消失。

### 问题 9

画出：

```text
client shutdown(SHUT_WR)
-> server recv 0
-> server delayed close
-> CLOSE-WAIT / FIN-WAIT-2
-> server close
-> TIME-WAIT
```

每一步写明 application action、kernel action 和 state owner。

做太多次了，copy 一个过来

```text
client application:
    stdin EOF
    -> shutdown(SHUT_WR)

client kernel:
    -> 发送 FIN, seq=11
    -> client 进入 FIN-WAIT-1

server kernel:
    收到 FIN
    -> 确认该 FIN，发 ACK=12
    -> 标记“client 不会再发新数据”
    -> server 进入 CLOSE-WAIT

server application:
    调用 recv()
    -> 若 receive buffer 还有 FIN 前的 payload，先返回那些正长度 bytes
    -> 当这些 bytes 都交付完，下一次 recv() 返回 0
```



### 问题 10

tcpdump 看到 `[S] [S.] [.] [F.] [.]` 时，每个 flag 是什么？为什么实际正常关闭不一定永远显示成教科书式四个独立 packets？

上面有