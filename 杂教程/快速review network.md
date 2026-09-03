我把它改成了正确的逻辑：区分了 UDP/TCP 的内核分用、TCP 的 `accept queue` 与 connected socket 的 receive buffer，也补上了 server/client 的 socket 角色差异。

```text
+---------------------------------------------------+
| Application layer                                 |
| 应用程序调用：sendto / recvfrom / connect /       |
|             accept / send / recv                  |
+---------------------------------------------------+
                         |
                         v
+---------------------------------------------------+
| Transport layer                                   |
| UDP 或 TCP                                        |
+---------------------------------------------------+
                         |
                         v
+---------------------------------------------------+
| Network layer                                     |
| IP：根据 destination IP 把 packet 送到目标 host   |
+---------------------------------------------------+
                         |
                         v
+---------------------------------------------------+
| Link layer                                        |
| Ethernet 是常见的 link-layer protocol             |
| 负责当前链路上的 frame 交付                       |
+---------------------------------------------------+


UDP
===

sender application
        |
        v
+---------------------------------------------------+
| sendto(udp_fd, data, destination IP:port)         |
+---------------------------------------------------+
        |
        v
+---------------------------------------------------+
| sender kernel：UDP + IP + link layer 发送 datagram|
+---------------------------------------------------+
        |
        v
====================== network ======================
        |
        v
+---------------------------------------------------+
| receiver kernel 收到 packet                       |
| IP 交给 UDP                                       |
| UDP 根据 protocol + local IP + local port         |
| 找到对应的 UDP socket                             |
+---------------------------------------------------+
        |
        v
+---------------------------------------------------+
| 这个 UDP socket 的 receive queue                  |
| 保存一个个完整 UDP datagram                        |
+---------------------------------------------------+
        |
        v
+---------------------------------------------------+
| receiver application                              |
| recvfrom(udp_fd, ...)                             |
| 取出一个 datagram，同时得到 sender address        |
+---------------------------------------------------+


TCP server
==========

server application
        |
        v
+---------------------------------------------------+
| socket -> bind(local IP:port) -> listen           |
+---------------------------------------------------+
        |
        v
+---------------------------------------------------+
| listening socket                                  |
| 只负责接收新的 TCP connection                     |
+---------------------------------------------------+
        |
        v
client connect()
        |
        v
+---------------------------------------------------+
| client/server kernel 完成 TCP handshake           |
+---------------------------------------------------+
        |
        v
+---------------------------------------------------+
| server listening socket 的 accept queue           |
| 保存：已经建立、但 application 尚未 accept 的     |
| pending connections                               |
+---------------------------------------------------+
        |
        v
server application 调用 accept(listening_fd)
        |
        v
+---------------------------------------------------+
| accept 返回一个新的 connected_fd                  |
| listening_fd 仍然继续 listening                   |
+---------------------------------------------------+
        |
        v
+---------------------------------------------------+
| server connected socket                           |
| 对应一个具体 TCP connection                       |
| local IP:local port + peer IP:peer port           |
| 这四个值共同标识这条 connection                   |
+---------------------------------------------------+
        |
        v
+---------------------------------------------------+
| connected socket 的 TCP receive buffer            |
| peer 发送的 TCP byte stream 会进入这里            |
+---------------------------------------------------+
        |
        v
+---------------------------------------------------+
| server application 调用 recv(connected_fd, ...)   |
| 从 receive buffer 读取当前可用的 bytes            |
+---------------------------------------------------+


TCP 的 socket 角色
=================

server：

    one listening socket
        |
        +--> accept queue：等待 application accept 的 connections

    one connected socket per accepted connection
        |
        +--> receive buffer：这条 connection 收到的 TCP bytes

client：

    通常只有一个 connected socket
        |
        +--> 用 connect 建立 connection
        +--> 用 send / recv 通信
```

最容易混的地方就是：

```text
accept queue
= listening socket 上等待 accept 的 connection queue

TCP receive buffer
= 某个 connected socket 上等待 recv 的 byte stream
```

它们不是同一个 queue。