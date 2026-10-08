## R3

```text
我之前是在都解析完了之后，用 consumed_bytes 去判断当前 frame 大小是否超过限制；
但是我们在 R3 需要改成，如果当前已经解析成功的 byte count 超过限制，那么也是不行的。也就是看当前的 cursor
在每次 cursor 移动后都加一个判断
```

