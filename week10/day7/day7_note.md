## 手绘

### listener ready

![img](day7_note.assets/c58b05c392e098d349374f1e2fd5d3cf_720.png)

### 调用 connection callback

![img](day7_note.assets/48c622c2862a06d4b589d231bba7f14b_720-17895372366661.png)

### connected socket ready

![img](day7_note.assets/ad4dae5a56c8f35715aac46958f9ad03_720.png)

### clean up

![img](day7_note.assets/c6774a3495a8514ed473572eea6a21f4_720-17895372455682.png)

### Connection::try_message_callback

![img](day7_note.assets/c78c695ec814043f8b3317eaafb3626c_720.png)

## mermaid

### listener ready

```mermaid
flowchart TD
    A["listener ready"] --> B["kernel 观察到 socket ready"]
    B -- "把 ready records返回" --> C["用户态 call epoll_wait 返回对应fd的event"]
    C --> D["Eventloop::poll_once"]
    D --> E["Eventloop 去 dispatch返回的records"]
    E --> F["dispatch:根据 fd, channel, set_ready_event()\nhandle_event()"]
    F --> G["channel 的 read callback\n(因目前是EPOLLIN的event)"]
    
    G --> H["Acceptor 的 handle_accept()"]
    H --> I["accept4 得到新connected socket"]
    
    I -- "正常得到" --> J["调用connection callback(新connection)"]
    I -- "出现error\n据errno分类" --> K((" "))
    
    K -- "EINTR" --> L["重试"]
    L -- "循环" --> I
    J -- "循环" --> I
    K -- "EAGAIN/\nEWOULDBLOCK" --> M["本次循环结束"]
    M --> N["return"]
    
    K -- "其他" --> O["抛\nstd::system_error"]
```

### 调用 connection callback

```mermaid
flowchart TD
    A["调用 Connection callback\n(当前得到了新的connected socket)\n调用 application protocol所设置的callback"] --> B["make_unique: connection object, 用新socket构造"]
    B --> C["令 Connection = unique_ptr"]
    C --> D["Connection -> set_message_callback()"]
    D --> E["Connection -> set_close_callback()"]
    E --> F["Connection -> start()"]
    F --> G["向 server main中的 unordered_map\n加入 fd -> unique_ptr<Connection>\n的映射."]
```

### connected socket ready

```mermaid
flowchart TD
    A["connected socket ready"] --> B["kernel 观察到 socket ready"]
    B -- "把 ready records返回" --> C["用户态 call epoll_wait 返回对应fd的event"]
    C --> D["Eventloop::poll_once"]
    D --> E["去调用目前batch的records\n对应channel的 set_ready_event, \nhandle_event"]
    E --> F["Channel::handle_event"]
    
    F -- "有read-related masks" --> G["Channel::read_callback()"]
    G --> H["Connection::handle_recv()"]
    H --> I["不断::recv bytes 直至边界(若有EINTR则重试)"]
    
    I -- "边界" --> J((" "))
    
    J -- "n=0, EOF" --> K["try_message_callback\n记录 peer_write_close"]
    K -- "若output empty\ntrue" --> L["close helper"]
    
    J -- "其他errno" --> M["Connection::close_helper()\nConnection::system_error_helper"]
    
    J -- "errno = EAGAIN /\nEWOULDBLOCK" --> N["try_message_callback"]
    
    F -- "EPOLLOUT" --> O["Channel::write_callback"]
    O --> P["Connection::handle_send"]
    P --> Q["省略."]
    
    F -- "EPOLLERR" --> R["Channel::error_callback"]
    R --> S["Connection::handle_error"]
```

### clean up

```mermaid
flowchart TD
    A["clean up\n调用 Connection::close callback"] --> B["向 main 发送 close request"]
    B --> C["EventLoop::poll_once 结束"]
    C --> D["统一处理 pending close"]
    D --> E["connections.erase(fd)"]
    E --> F["从 unordered_map 中删除这对(k,v)"]
    F --> G["析构 unique_ptr"]
    G --> H["析构 unique_ptr 指向的 Connection"]
    H --> I["EventLoop::remove_channel"]
    I --> J["析构 Connection members"]
    J --> K["析构 UniqueFd, ....省略."]
    K --> L["::close(fd)"]
```

### Connection::try_message_callback

```mermaid
flowchart TD
    A["Connection::try_message_callback"] -- "recv_flag为true" --> B["try_message_callback"]
    
    B -- "有异常" --> C["close helper"]
    C --> D["throw ;"]
    
    B -- "正常" --> E["找到最后一个 newline"]
    E --> F["Connection::send"]
    F --> G["bytes 放入 output Buffer"]
    G --> H["Connection::handle_send"]
    
    H --> I["全部发完, 移除EPOLLOUT"]
    
    H -- "暂时未发完" --> J["Channel::add_interest_event(EPOLLOUT)"]
    J --> K["Connection::try_update_channel"]
```



## ownership table

使用四列：

| Resource / object  | Owner                                                        | Non-owning user                     | Destruction trigger                               |
| ------------------ | ------------------------------------------------------------ | ----------------------------------- | ------------------------------------------------- |
| epoll fd           | Eventloop                                                    | 无                                  | 当 Eventloop 析构的时候                           |
| listening fd       | Acceptor（实际上 owner 是管理这个 fd 的 UniqueFd，但是这个 UniqueFd 的 owner 也是 Acceptor，所以我认为是 Acceptor） | Eventloop,Channel                   | 当 Acceptor 析构的时候                            |
| accepted fd        | Connection                                                   | Eventloop,Channel                   | 其发出 close request，后续 main 去析构 connection |
| listener Channel   | Acceptor                                                     | Eventloop                           | Acceptor 析构的时候                               |
| connection Channel | Connection                                                   | Eventloop                           | Connection 析构                                   |
| Connection         | connections 中的 unique_ptr                                  |                                     | 其发出 close request，后续 main 去析构 connection |
| input Buffer       | Connection                                                   | Message callback 会临时使用到 input | Connection 析构                                   |
| output Buffer      | Connection(只有 Connection 直接操作)                         | 无                                  | Connection 析构                                   |