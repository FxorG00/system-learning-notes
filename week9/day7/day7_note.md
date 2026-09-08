# R1

## 手绘

### receiver_work

![img](day7_note.assets/dbca2f811baa4236d09afa4eed32b8c9_720.png)

### connection_handler

![img](day7_note.assets/256d3632e603f901249fc7191431346f_720.png)

### listener_handler

![img](day7_note.assets/0289898a9900d43e1914f5627eb79d24_720.png)

### main

![img](day7_note.assets/93963a0ca5418ddec0024c247bad9faa_720.png)

## flowchart

### main

```mermaid
flowchart TD
    A[main: init] --> B[epoll_create / 创建epoll]
    B --> C["register_to_epoll(epfd, listener...)"]
    
    %% Event Loop 作为一个核心节点，多处会循环回到这里
    C --> D[event loop]
    
    D --> E[epoll_wait]
    
    %% 分支1：ready_count < 0
    E -- "ready_count < 0" --> F{error}
    F -- EINTR --> D
    F -- 其他 --> G[清理并return 1]
    
    %% 分支2：ready_count > 0
    E -- "ready_count > 0" --> H{判断通知类型}
    
    H -- 是listener的通知 --> I[listener_handler]
    I --> D
    
    H -- 是connection的通知 --> J[connection_handler]
    J --> D
    
    %% 为匹配原图的红色标注，可以使用类为连接线调色，但在标准Markdown里通常直接用文本标注分支即可清晰表达逻辑。
```



### listener_handler

```mermaid
flowchart TD
    Start([listener_handler]) --> Accept["accept4 尝试得到新的 connection"]
    
    Accept --> ChkConn{"结果判断"}
    
    ChkConn -->|connection >= 0| InitConn["初始化该 connection"]
    InitConn --> Accept

    ChkConn -->|失败| ChkErr{errno 判断}
    ChkErr -->|EINTR| Accept
    ChkErr -->|EAGAIN / EWOULDBLOCK| End([结束])
    ChkErr -->|其他| Error["报错"]
    Error --> End
```

### connection_handler

```mermaid
flowchart TD
    A[connection_handler] --> B{event有EPOLLERR吗?}
    
    B -- 有 --> B_action["getsockopt 并打印报错 -> clear -> return"]
    B -- 无条件向下接着check --> C{有EPOLLRDHUP吗}
    
    C -- 有 --> C_action["receiver_work -> 设置peer_write_closed"]
    C -- 接着check --> D{有EPOLLHUP吗}
    
    D -- 有 --> C_action
    D -- 接着check --> E{有EPOLLIN吗?}
    
    E -- 有 --> E_action[receiver_work]
    E -- 接着check --> F{有EPOLLOUT吗}
    
    F -- 有 --> F_action[sender_work]
    F -- 接着check --> G{"fd仍alive 且 peer_write_closed"}
    
    G -- 成立 --> H["update_epoll_status(EPOLLIN, DEL_FLAG)"]
    H --> I{"output.empty()?"}
    
    %% 更新了这里的“空”判断
    I -- 空 --> J[clear_connection]
```

### receiver_work

```mermaid
flowchart TD
    A["receiver_work"] --> B["n = ::recv(fd, ...)"]
    
    %% n=0
    B -- "n=0" --> C["means EOF -> 设置peer_write_closed -> return"]
    
    %% n>0
    B -- "n>0" --> D["向connection_state append_char(buffer[0,n))"]
    D -- "若形成一个 newline > output" --> E["update_epoll_status(EPOLLOUT, ADDFLAG)"]
    
    %% 结束后回到 recv
    D -- "结束后" --> B
    
    %% n<0，这里用一个空的节点来作为分叉点，完全还原原图的形状且不加字
    B -- "n<0" --> F((" "))
    
    %% n<0 的三个分支
    F -- "errno=EINTR" --> B
    F -- "errno=EAGAIN / EWOULDBLOCK" --> G["return"]
    F -- "其他." --> H["报错并clear_connection -> return"]
```



# R2

```text
baseline = 5
after 100 clients = 5
```

