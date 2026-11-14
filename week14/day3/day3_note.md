# R1

```text
实现一个 replayer

输入: aof raw bytes, kvstore
动作: 按顺序解析并且执行里面的 set/del
返回: 成功解析并且执行了几条 records; consumed_bytes
```

# R2

```text
加一个从文件中 read_all
然后把读到的 bytes 去进行 replay

对 error 且非 EINTR,我们保存 errno 并且抛出 system_error
```

# R3 对边界的修正



| 输入                  | 预期                                | 证明什么                                          |
| --------------------- | ----------------------------------- | ------------------------------------------------- |
| 完整 `GET k` record   | 抛错并停止                          | RESP 合法不等于 AOF 合法                          |
| 完整 `SET k` record   | 抛错并停止                          | SET 参数数量必须精确                              |
| 完整但无 key 的 `DEL` | 抛错并停止                          | DEL 至少需要一个 key                              |
| 最后一条缺一个 byte   | 当前版本抛 incomplete error         | Day3 不静默接受残缺尾部                           |
| 非 RESP 顶层 bytes    | 保留 parser error 与 offset         | 格式错误可定位                                    |
| 不存在的 AOF path     | 抛出的 `system_error` 保留 `ENOENT` | `open()` 失败不会被后续 `read(-1)` 伪装成 `EBADF` |

**文件打开或读取失败**：抛 `std::system_error`，保留 `errno`。

**完整 record 的命令或参数不符合 AOF 规则**：可以抛 `std::invalid_argument`。

**文件结束，但最后一条 record 不完整**：可以抛 `std::runtime_error`。

## 改进

```text
1. 判断 aof record 对应指令是否在我们处理的集合中.
2. 判断 aof record 的参数对不对
3. 如果 parse error,那么我们抛出 parser 的 error message 以及当前 offset
4. open 失败抛 system_error
```