## R1

```text
其实最基本就是 echo_server，然后改 application 层协议得到这个。

curl connects
-> server accepts this connection
-> 进入 connection_callback，去初始化这个 connection
-> connection receives HTTP bytes
-> 调用 message_callback, HTTP application callback 去 parse request
-> 解析出来目前 input 这些 raw bytes 是否 complete 构成一条 request
-> 如果 complete 的话，那么应该去 route this HTTP request 然后得到对应 response
-> encode response 得到 wire response
-> connection sends it
-> server closes after output drains，就是 send 后 output 为空了！那么我会去调用这个 connection 的 close_helper，让它发送 close request 给 owner
-> curl receives complete response and EOF
```

```text
connection_callback
类似之前 echo_server
1. 为它建立独立的 `Connection` 与 HTTP application state；
2. 安装 MessageCallback 和 CloseCallback；
3. 调用 `start()`；
4. 保持这些对象存活，直到 close callback 已提交并在安全位置执行 deferred erase。

message_callback:
如果 first_request_over_flag_ 为 true，那么不进入。
对 input 调用 parse_request 看看 result，如果是 complete 的话，就 retrieve 对应 consumed_bytes 并且 route,encode,send,然后 请求 close_after_flush()
```

```text
close_after_flush()
调用后会让 connection 在 output 为空的时候调用 close_helper；所以我们需要一个 close_after_flush_flag。这个函数标记 this flag 为 true。

然后这个函数先判断 flag 是否为 true，为 true 的话就直接 return(意味着直接调用过了，那么在 send 到 output empty 的时候就会调用 close_helper)
为 false 的话改为 true，并且判断 output empty 吗？empty 的话调用 close_helper

handler_send()
如果 send 到最后发现 output 为空，那么再判断是否 close_after_flush_flag 为 true，为 true 的话调用 close_helper

由于 day5 需要只对第一条 request 相应；所以我们需要一个 first_request_over_flag_ 去标记有没有响应完第一条 request。
如果其为 true 那么 message_callback 不能进行，但是我们还是可以 recv raw bytes 到 input buffer 里面，这是 tcp 层的事情。
```

### close_after_flush 调用的时候已经明确拒绝 peer 再发送 request 了吗

**没有自动拒绝。** `close_after_flush()` 表达的是“这边不再提交新的响应，排空现有 output 后关闭”。它不能阻止 peer 在关闭前继续向 TCP 连接发送字节。

按你目前的 `Connection` 代码，`EPOLLIN` 仍在关注范围内；如果只新增一个“等待排空”flag，`handle_recv()` 仍可能读到后续 request 并调用 MessageCallback。Day5 还需要让 **HTTP session 在第一份 response 确定后，不再解析或响应第二条 request**。你也可以让 `Connection` 停止关注读事件，但那是实现选择。

记住这三个层次就清楚了：

```text
peer 还能不能尝试发送：能，直到连接实际关闭
Connection 会不会收到这些 bytes：取决于读事件处理
HTTP session 会不会处理第二条 request：Day5 规定不能
```

还有，等待排空时不能让关闭标志挡住 `handle_send()`，否则剩余响应发不完。
