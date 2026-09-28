## R1

```text
完整的 request 要求：
1. request line complete
2. header section complete
3. header line 可出现 content-length；若没出现的话，则一定不能有 transfer-encoding，且 body-length=0
4. body 已经到齐，也就是剩下的 bytes >= content length；如果 bytes < content length，那么判为 needmore

如果在解析 request line/header section 的时候，returned result 不为 complete 那么需要根据对应类型去讨论；并且这里是有一些是 needmore 的(拼上上面 4 的那种 needmore 就完整了)。

需要注意，我们的 output 传进来的是引用；但是我们只有在整条 http_request complete 的情况下才能修改这个 output，所以我们函数内需要开一个 tmp_output(因为 parse_request_line complete 的时候会修改传进去的 output)


```

## R3

```text
parse_digits 只负责 strict decimal -> size_t
-> 转换失败：BadRequest

转换成功后由 parse_request 比较 kMaxBodyBytes
-> value > limit：BodyTooLarge
-> value <= limit：作为 body_length
```

这样 `1048576` 仍被接受，`1048577` 才稳定进入 `BodyTooLarge`。