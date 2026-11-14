# R1

## 升级点

```text
我们的 application 的 mini redis 没有把返回的 aof 写到文件里；以及 mini redis 启动前没有先从 aof 恢复 kvstore。
```

```mermaid
flowchart TD
    A["进程参数给出 AOF path"] --> B["建立共享 KvStore 与 AofWriter"]
    B --> C["replay_aof_file 恢复旧状态"]
    C -->|"全部成功"| D["Acceptor::start 开始监听"]
    C -->|"失败"| E["打印诊断并退出，不对外服务"]

    D --> F["Connection 收到完整 RESP request"]
    F --> G["execute_command 返回 CommandOutcome"]
    G --> H{"aof_record 有值吗"}
    H -->|"没有"| I["安排 reply"]
    H -->|"有"| J["append 完整 record"]
    J --> K["sync 成功"]
    K --> I
```

## 怎么使用接口

### replay

```cpp
AofWriter writer(aof_path);
replay_aof_file(store, aof_path, unix_now);
```

### aof write

```cpp
const auto outcome = execute_command(store, arguments, unix_now);
writer.append(*outcome.aof_record);
writer.sync();
connection.send(outcome.reply.data(), outcome.reply.size());
```

### 启动顺序

replay 全部成功，才能调用 `acceptor.start()` 让我们的 acceptor 进入 listen

