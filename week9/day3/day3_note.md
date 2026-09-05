## R1

```text
实现一个 TCP bytes 接收器

要求有一个 non-blocking listener 在监听某个端口，然后如果有 connection 的话进行 accept；
然后同时去进行，监听每个 connected socket 的 receive queue 有没有新 bytes，有的话也是接收。

1. 创建 listening socket
2. 进行相关设置

我去，检阅到一半，经过一些检阅提醒，我这样直接 non-blocking accept 是很占用 CPU 时间的；
但是我只需要关注 listener,还有 connection fd 的变化；这些都是可以用一个 epoll 去关注的！
然后我只需要在 returned_event.data.fd 去 check 是 listener 还是 connection fd 的，然后分开做两种操作即可。
```

### 反打印出 IP address,port

可以直接用 `inet_ntop` 把二进制 IPv4 地址转为文本，用 `ntohs` 把网络字节序的端口转回主机字节序：

```cpp
#include <arpa/inet.h>
#include <netinet/in.h>

#include <cstdint>
#include <cstdio>
#include <iostream>

sockaddr_in address{};
address.sin_family = AF_INET;
address.sin_port = htons(9090);
address.sin_addr.s_addr = htonl(INADDR_LOOPBACK);

char ip[INET_ADDRSTRLEN]{};

if (::inet_ntop(AF_INET, &address.sin_addr, ip, sizeof(ip)) == nullptr) {
    std::perror("inet_ntop");
    return 1;
}

const std::uint16_t port = ntohs(address.sin_port);

std::cout << "IP   = " << ip << '\n';
std::cout << "port = " << port << '\n';
```

输出是：

```text
IP   = 127.0.0.1
port = 9090
```

这里两次转换方向正好相反：

```text
设置给 kernel 前：
9090（host byte order）
-> htons
-> address.sin_port（network byte order）

打印给人看前：
address.sin_port（network byte order）
-> ntohs
-> 9090（host byte order）
```

`inet_ntop` 的 `ntop` 是 network-to-presentation：把 `address.sin_addr` 里那 4 个二进制 IPv4 bytes 转成人看得懂的 `"127.0.0.1"`。

顺手纠正一下你代码里的注释：`htons(9090)` 不会让 kernel 选端口；它只是转换字节序。只有设置成：

```cpp
address.sin_port = htons(0);
```

再成功调用 `bind()` 后，kernel 才会分配一个可用临时端口；这时要用 `getsockname()` 取回实际分配的 port。

## R2

```text
R2 进一步修改；
当我们得到 listener ready 的通知的时候，可能 accept queue 里面有很多 pending connection；我们可以 non-blocking accept4 直至 EAGAIN，这样能把本次的 connection 都榨干。
```
