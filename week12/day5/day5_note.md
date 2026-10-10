## R1

```text
本质上跟 http_server_v1 一样
我们只需要改 message_callback 即可
因为他俩除了 application layer，其他地方都一样；而 application layer 不一样的地方在于用的是 resp request parser 以及是用 resp 的 command_dispatcher 跟 encoder 的。

就是对 raw bytes，我们先用 resp request parser 解析出来 complete request；再对其 command_dispatch，然后 command_dispatch 里面会根据我们的 request 找到正确的响应并且返回。

connection_over_flag=true: 这个 connection 不再承载 request
所以如果这个 flag 为 true，进入后由 guard 停止业务处理
但是真正让这个 connection 去发送 close_request，是我们调用 Connection::close_after_flush
然后 output.empty 了，这时候 connection 会去调用 close_callback
不过这个是 connection 的事情了
```

