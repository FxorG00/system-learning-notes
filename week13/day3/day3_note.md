## R3

```text
expire_handler 会转换 arguments 中的 seconds
我们要把 seconds*1000，所以要求 0<seconds<=M/1000
并且，我们注意，上述针对 seconds>0
seconds<=0 我们不动，因为实际 expire 会去尝试物理删除 key

exists code code code
三个 code 需要依照同一个时间
也就是我们在一开始需要 time snapshot，再传给 exists
del 同理

```

```cpp
TimeMs read_time_ms() const;

bool exists_at(const std::string& key, TimeMs now_ms) const;
bool erase_at(const std::string& key, TimeMs now_ms);
增加上述 api，然后把 command_dispatcher 的 EXIST,DEL 的 handler 换成上面这两个。
    
这样我们就变成先取时，再去传这个 time snapshot 进入对应函数。
```

```cpp
原先我们在 expire_ms 内取时非法会抛 invalid_argument。
并且在 expire 内时间加法算 deadline overflow 也会抛。
    
bool expire_ms_at(const std::string& key, TimeMs ttl_ms, TimeMs now_ms);

这样，我们先取时，在调用 expire_ms_at。这两个动作能把取时失败与期限范围失败分开。
    
并且，现在。
取时异常让原异常接着向外抛出。
如果是 expire_ms_at 内部期限 overflow，我们在外层需要 catch 并且向外抛出 RESP error 信息。
 
实现的时候注意：
try 外面，前面是取时，这样能让取时抛出的异常逃逸。
try 里是去调用 expire_ms_at，这样能让 expire_ms_at 抛的 overflow 被捕获，然后再转为 error 信息。
    
```

