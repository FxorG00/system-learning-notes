# 今天干的事：

把一条已经确认的状态变化，编码成以后可以重新执行的 bytes。但是还没有落到文件，只是给出了，写到文件里的内容。

# R1

```text
我们最后会把 record 编码成 RESP Array of Bulk Strings
所以，我们需要写一个 helper
就叫做，encode_resp_array_of_bulk_strings
传只读 vector<std::string> 引用
*data.size()\r\n
encode_resp_bulk_string(data[0])
encode_resp_bulk_string(data[1])
```

# R2

我的 command_dispatcher 的 execute_command 会只返回 reply bytes，但是回到 owner 后，我不知道需不需要 AOF（往文件追加记录），因为我不知道这次 execute_command 是否是在改变了 KvStore 状态。所以要把这个信息也返回。

```text
把返回值改为结构体。
CommandOutcome {
    reply: std::string
    persistence: none 或一份 PersistenceChange
}
```

## 疑问

但是我感觉 aof record 区分 set,del 没啥用，因为本质就是把一些 arguments encode 成 record。而且对于 set,del 其 arguments 我可以直接拿输入的传进去。对于 expire 的，我修改一下即可。

**区分 SET、DEL、EXPIRE，只需要发生在“生成 record”这一层；record 生成完以后，owner 不必再知道它属于哪种命令。因为生成后，我写到文件里即可。**

可以直接简化成：

```
struct CommandOutcome {
    std::string reply;
    std::optional<std::string> aof_record;
};
```

完整关系是：

```
handler 判断命令是否真的改变状态
        ↓
决定应该生成什么可重放命令
        ↓
编码成完整 RESP record
        ↓
owner 只看 aof_record 有没有值
        ↓
有值就追加，没有就跳过

就是，我直接让 execute_command 承担执行命令，并且产生 reply；以及产生 aof 需要追加的 string。
这样我的 app owner 就直接根据返回的 reply 发给 client，根据 aof string 写到文件即可。
```

```text
然后，expire 对应的 aof_record 我就还没生成。
```



| 命令                 | handler 怎样生成候选 record                             | 最终 `aof_record`              |
| -------------------- | ------------------------------------------------------- | ------------------------------ |
| 合法 `SET k v`       | 把 `arguments[1]`、`arguments[2]` 交给 `encode_aof_set` | 总是有值                       |
| `DEL a b`            | 把原 key 序列交给 `encode_aof_del`，执行后看删除数      | 大于 0 时保留，否则 `nullopt`  |
| 正数 `EXPIRE k n`    | 不能照抄原参数；Day4 得到绝对时刻后生成 PEXPIREAT       | Day4 才闭合                    |
| 非正 `EXPIRE k n`    | 若有效 key 被立即删除，生成 `DEL k`                     | 删除成功时有值，否则 `nullopt` |
| `GET/PTTL/PING`      | 不调用 AOF encoder                                      | `nullopt`                      |
| 参数、范围或协议错误 | 不进入成功写路径                                        | `nullopt`                      |

# R3

```text
encode_aof_del({}) 当前仍会生成只有 DEL 的记录，没有抛 invalid_argument。
就是传空 vector 需要抛异常。

PEXPIREAT k -1 // 绝对 Unix 毫秒时刻为负
也就是编码负绝对时刻，也要抛异常。

以及增加对 aof encode 时编码大小的限制，抛异常。

以及，先去生成 aof record，如果不会抛异常，也就是接着往下执行的话，才去修改 store 的状态。
这样能避免反过来，我们先修改了 store 的状态，但是 aof record encode 的时候抛异常了，导致我们这次状态修改进不去 aof 文件。
```

