## routing table

```text
default via 192.168.56.2 dev ens33 proto dhcp metric 100 
169.254.0.0/16 dev ens33 scope link metric 1000 
192.168.56.0/24 dev ens33 proto kernel scope link src 192.168.56.129 metric 100 

哪个 prefix 表示 local network？
192.168.56.0/24

哪个 address 是 default gateway？ 
192.168.56.2

remote destination 会从哪个 interface 发出？
ens33
```

## 验收问题

1. `192.168.56.129/24` 发往 `192.168.56.1` 时，IP destination、next-hop IP 和 ARP target 分别是谁？

   都是 192.168.56.1

2. 同一 host 发往 `8.8.8.8` 时，为什么第一跳 Ethernet destination MAC 不是 `8.8.8.8` 所在机器的 MAC？

   因为 8.8.8.8 是 IP destination 啊。destination MAC 是当前这一跳把 frame 交给哪个 interface，而不是整个发送过程的 destination。

3. routing lookup 与 ARP lookup 的先后顺序是什么？各自回答什么问题？

   routing lookup 先。

   前者查找 next hop 的 IP address

   后者查找这个 IP address 对应的 MAC address

4. 一个 router 转发普通 IPv4 packet 时，Ethernet header 与 IP header 分别怎样处理？哪些 IP header 字段可能改变？

   要对 Ethernet header 里的 source MAC 跟 destination MAC 进行修改。

   根据 IP header 里的 IP destination 找到 next hop 的 interface。然后再去构造出新的 link layer header。

   TTL 可能改变, IPv4 header checksum 也变。

5. MAC address、IPv4 address、port、socket object 和 fd 各自属于什么范围，分别解决什么问题？

   | 标识         | 当前层次的作用                                               | 作用范围                     | 它不是什么                                     |
   | ------------ | ------------------------------------------------------------ | ---------------------------- | ---------------------------------------------- |
   | MAC address  | 标识当前 link 上 Ethernet frame 的 source/destination interface | 当前链路的一跳               | 不是跨互联网的完整路线                         |
   | IPv4 address | 标识 IP 网络中的 source/destination，并供 router 查路由      | 跨网络                       | 不是进程编号                                   |
   | port         | 让 TCP/UDP 在一台 host 内找到 transport endpoint             | 目标 host 的 transport layer | 不是 fd，也不能单独唯一表示一条 TCP connection |
   | fd           | 当前 process 访问某个 kernel object 的本地整数句柄           | 当前进程                     | 不会作为网络地址发给远端                       |
   | socket           |     kernel 中通信端点对象                                                         | 这个我也搞不清楚，还没用过                     |                        |

   

6. `192.168.56.0/24 dev ens33` 与 `default via 192.168.56.2 dev ens33` 分别会匹配什么 destination？

   前者匹配 192.168.56.0/24

   后者是最低优先级，匹配没有被更高优先级 route 命中的 destination

7. `htons` 的英文来源、输入、输出和用途分别是什么？它是否产生字符串？

   host to network short

   输入输出 uint16_t

   只是为了满足这个 endian 调整 byte order

   不产生字符串。

8. `inet_pton` 返回 `1`、`0`、`-1` 分别表示什么？

   ```
   1：转换成功
   0：输入不是指定 address family 的合法地址文本
   -1：指定的 address family 不受 inet_pton 支持，并设置 errno
   ```

9. 一个 Ethernet frame 到达目标 NIC 后，kernel 如何逐层找到 socket receive queue？

   

   copy 了。累了。

   ```mermaid
   flowchart TD
       A["NIC 收到 Ethernet frame"] --> B["Ethernet 检查 destination MAC 与 EtherType"]
       B --> C["EtherType 指向 IPv4 parser"]
       C --> D["IP 检查 destination IP 与 protocol"]
       D --> E["protocol 指向 TCP parser"]
       E --> F["TCP 检查 source/destination ports 与 connection state"]
       F --> G["kernel 找到匹配的 socket"]
       G --> H["payload bytes 进入 socket receive queue"]
       H --> I["若 application 正阻塞在 recv，满足条件后使 waiter 可运行"]
       I --> J["waiter 将来被 scheduler 选中，recv 返回 bytes"]
   ```

10. 如果 `ip neigh` 已经存在 gateway 的 `REACHABLE` entry，再次发送 packet 时为什么可能看不到新的 ARP request？

    因为已经能从 ip neigh 找到 IPv4 address 对应的 MAC address 了。就不需要再发送 ARP request