# R1

## 干了啥

> 今天增加了对 expire 的 aof 写入跟 replay 的支持。

```text
expire 的时候，把 Unix 毫秒写到 AOF。
也就是，写日志的时候：
unix_deadline=old_wall_now+ttl

replay:
remaining=max(0,unix_deadline-new_wall_now)

然后把 remaining 传入 expire
```

```cpp
UnixTimeMs checked_unix_deadline_ms(
    UnixTimeMs unix_now_ms,
    KvStore::TimeMs ttl_ms);

安全的转换，unix_now_ms+ttl_ms 算出来 unix_deadline_ms

bool apply_aof_pexpireat(
    KvStore& store,
    const std::string& key,
    UnixTimeMs unix_deadline_ms,
    UnixTimeMs unix_now_ms);

先从 kvstore 读取一次 now_ms，以这次为基准。
算出来 remaining 并且调用 store.expire_ms_at
也就是去对 key 设置准过期时间。
但是你的 key 肯定是要存在的，所以需要先 exists_at 判断。
```

| 调用前状态       | 墙上时钟关系          | 对外结果                                       |
| ---------------- | --------------------- | ---------------------------------------------- |
| `code` 有效      | deadline 在未来       | 返回 `true`，PTTL 等于尚未经过的时间           |
| `code` 有效      | deadline 已到或已过去 | 返回 `true`，立即删除 `code`                   |
| `code` 不存在    | 任意合法时刻          | 返回 `false`，仍不创建 `code`                  |
| 墙上时钟整数非法 | 无法比较              | 抛出 `std::invalid_argument`，store 保持原状态 |

## wall clock

| 时间                        | 本项目用来回答什么             | 是否写入 AOF |
| --------------------------- | ------------------------------ | ------------ |
| wall clock（墙上时钟）      | 现实世界已经走到哪个 Unix 毫秒 | 写入绝对期限 |
| monotonic clock（单调时钟） | 当前进程内还剩多久、是否到期   | 不写入旧数值 |

# R2

## 升级注意点

```text
我们需要注意，kvstore 本身就只是有这个 get,del,expire,... 的功能；但是我们不把 aof 塞进去。

而是把 aof 塞到 command_dispatcher 里面。这样把职责分离开。

这样我们调用 kvstore 的 member function 就不用担心会产生 aof 了。这个在 replay 的时候有用。
```

## 挂个 wall_clock

```text
加个 wall clock 以 callable 的形式传入 execute_command。
这样我们的 expire_handler 就有获取 unix_ms 的能力。
```

## expire_handler

```text
所以我们本次需要执行 expire_ms_at 并且产生 aof 记录返回。

先用 checked_unix_deadline_ms 算出来 unix_deadline_ms

再生成 aof
```

| 场景                             | reply / record                        | store          |
| -------------------------------- | ------------------------------------- | -------------- |
| key 有效，期限与编码均成功       | `:1`，带完整 `PEXPIREAT` record       | 得到新 TTL     |
| key 不存在或已经失效             | `:0`，没有 record                     | 保持缺失       |
| 取时、期限换算或 record 编码失败 | 不能伪造成功 reply，也没有半条 record | 保持调用前状态 |

## replay

```text
增加重放 PEXPIREAT key unix_deadline_ms
的能力

只有在 unix_deadline_ms 是完整非负整数才合法。


识别出来，并且去调用 apply_aof_pexpireat。

并且，我们要给 replay_aof_file 传入获取 unix 时钟的能力。
```

