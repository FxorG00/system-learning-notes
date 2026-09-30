## R1

```text
更改 application protocol
主要是改 message callback:

    需要有一个while(1)，重复看看能不能解析出 complete request，解析出来的话看这条 request 是否包含 connection: close，包含的话，意味着我不再对这条 request 后续的 requests 响应了，所以这里需要 HTTP session 有一个是否还响应 request 的 flag(如果我们不再响应，那么不能让他进到 message callback，这个需要在 message callback 一开始判）。
    并且在收到这条 request 之后调用 close_after_flush(server 对这条 connection 的话，发完已有 response 后就可以关闭了；因为这个 connection 不再承载 request）；类似于 day5 收到第一条消息一样。以及发过去的 response 的 close_connection 也为 true

```

