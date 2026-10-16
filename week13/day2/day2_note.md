## R1

```text
我们现在用 map 存储数据的 key-value 的 value 需要替换成一个结构体。
这样才能保存若干 fields 的 name,value。

fields: value,deadline

在构造我们的 kvstore 对象的时候会进行 clock injection，给我们这个对象提供一个获取时间的能力。这样我们可以得到当前时间，并且计算 deadline。

在默认构造 KvStore 的时候，我们需要写一个 lambda 去得到当前的时间。
```

## R3

```text
之前 expire_ms 在 ttl_ms<=0 的时候会调用自己公开的 erase，erase 内部会再次取时。
我们需要保证只有一次取时，所以不调用公开 erase。
```

