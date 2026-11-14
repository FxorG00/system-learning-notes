# Week14 Day6：只修复 AOF 最后一条残缺记录

> 版本：2026-11-10，待 R1
> 前置：Week14 Day1～Day5 已整日通过；Day5 分轮 100/99/100、整日 99/100
> 今日产出：启动重放可以保留完整前缀，截掉 EOF 处的残缺尾部并同步文件；中间损坏与完整非法命令仍然拒绝启动
> 学习方式：R1 独立完成尾部识别与修复；R2 再补截断/同步失败；R3 用进程场景收住“写入、同步、客户端得知”三条边界

[TOC]

---

# Part 1：前两条已经完整，为什么最后半条要拖垮整个启动

## 0. 今天只解决一个真实启动问题

Day5 已经把恢复接回真实服务器：

```text
AofWriter 打开或创建 AOF
-> replay_aof_file 恢复 KvStore
-> replay 成功后 acceptor.start
```

当前 replayer 遇到任何 `NeedMore` 都会抛异常。

这对 Day3 是正确的第一版：不带着不完整日志开始服务。

但现在考虑一次真实的追加中断：

```text
[完整 SET][完整 DEL][只写了一半的 SET]
```

前两条已经可以完整解析并恢复。

最后一条只差后半段，而且文件已经到 EOF，不会再从磁盘里长出剩余 bytes。

今天要回答的是：

> 能否保留前两条已经确认正确的状态，只删掉最后那段无法组成完整 record 的 bytes？

答案是可以，但只允许修复这一种边界。

## 1. 先看一组具体 byte 位置

假设文件由下面三段组成：

```text
byte 0  ........ 26   完整 SET a 1
byte 27 ........ 48   完整 DEL old
byte 49 ........ 58   不完整 SET 的前缀
```

前两条结束以后，下一个 record 应从 byte 49 开始。

因此：

```text
文件原长度             = 59
最后一个确认正确的边界 = 49
需要丢弃的尾部长度     = 10
```

这个 `49` 叫 `last_good_offset`，中文可以直接理解为：

> 最后一条已经完整解析、通过命令检查并成功应用的 record 结束后的 byte 位置。

它不是 record 数量，也不是指针。

它是文件中的 byte 边界。

修复后文件应从 59 bytes 变回 49 bytes。

## 2. 残缺尾部和中间损坏不是同一种情况

### 2.1 EOF 处的残缺尾部

```text
[完整 SET][完整 DEL][半条 SET][EOF]
```

parser 已经确认前两条完整。

解析第三条时返回 `NeedMore`，而输入已经到 EOF。

这说明当前 record 缺少后续 bytes。

本项目允许把文件截回第三条开始前的 byte 边界。

这只是本项目根据 `NeedMore + EOF` 采用的恢复策略。

它不能从历史上证明尾部一定由进程崩溃造成。

### 2.2 中间损坏

```text
[完整 SET][不是 RESP 的 bytes][后面还有其他 bytes]
```

**parser 返回 `Error`。**

此时不能从错误位置继续猜下一条 record 从哪里开始。

如果静默跳过，后面的 bytes 可能恰好看起来像 RESP，但已经没有可靠的 record 边界。

因此中间损坏仍然让启动失败，原文件不自动修改。

### 2.3 RESP 完整，但命令不允许重放

```text
GET k
```

它在 RESP 层可能是完整命令。

但 AOF replayer 只允许当前项目定义的 `SET / DEL / PEXPIREAT`。

这种情况也不是“少了后半条”，所以不能截掉以后继续启动。

今天唯一新增的恢复规则是：

```text
EOF + NeedMore
-> 可以修复最后一个不完整 record

parser Error / 完整非法命令 / 参数错误
-> 启动失败，不自动修复
```

## 3. 现有返回值还缺一条信息

当前结果只有：

```cpp
struct AofReplayResult {
    std::size_t records_applied{0};
    std::size_t bytes_consumed{0};
};
```

它能表达完整文件：

```text
records_applied = 2
bytes_consumed  = 文件总长度
```

但它不能区分：

```text
刚好在完整 record 边界到达 EOF
```

和：

```text
在下一条 record 中间到达 EOF
```

R1 把结果扩为：

```cpp
struct AofReplayResult {
    std::size_t records_applied{0};
    std::size_t bytes_consumed{0};
    bool incomplete_tail_found{false};
};
```

三个字段分别回答：

| 字段 | 回答的问题 |
|---|---|
| `records_applied` | 有多少条完整、合法 record 已经应用到 store |
| `bytes_consumed` | 最后一个有效 record 后面的 byte 边界在哪里 |
| `incomplete_tail_found` | EOF 时是否还有一条只完成了前缀的 record |

对 §1 的例子，结果应为：

```text
records_applied       = 2
bytes_consumed        = 49
incomplete_tail_found = true
```

`replay_aof_bytes()` 只报告这个事实，不负责修改文件。

`replay_aof_file()` 才拥有 path 和 fd，因此由文件层完成物理修复。

## 4. `ftruncate()` 在本课做什么

`ftruncate`（按 fd 截断文件）把一个已打开的普通文件改成指定 byte 长度。

声明来自 `<unistd.h>`；打开模式仍使用 `<fcntl.h>` 中的标志。

本例目标是：

```cpp
ftruncate(fd, 49);
```

成功以后：

```text
原来的 byte [49, 59)
-> 不再属于这个文件

文件新长度
-> 49
```

它需要 fd 以可写方式打开。

因此当前 `replay_aof_file()` 的 `O_RDONLY` 不再足够；R1 需要让恢复 fd 同时可以读取和截断。

这里的 `off_t` 是文件 API 使用的有符号 byte 位置类型。

把 `bytes_consumed` 交给 `ftruncate()` 前，目标长度必须能由 `off_t` 表示。

本课只会缩短文件，不会用 `ftruncate()` 扩大文件或制造零填充区域。

接口行为可对照 [Linux `ftruncate(2)`][ftruncate]。

## 5. 截短成功以后，为什么还要 `fdatasync()`

`ftruncate()` 成功说明当前内核看到的新文件长度已经是 49。

它不等于本项目选定的同步边界已经完成。

文件长度 `st_size` 会影响后续怎样读取数据。

Linux 的 `fdatasync()` 会同步读取文件所必需的数据和元数据；文件长度正属于这种必要元数据。

所以修复成功路径是：

```text
确认最后有效边界
-> 把文件截到该边界
-> 同步这次文件长度变化
-> replay_aof_file 才返回成功
-> acceptor.start 才能执行
```

这不是要求你证明所有硬件故障下的数据都绝对存在。

它只延续 Day2 已经选定的学习项目同步策略。

接口语义可对照 [Linux `fsync/fdatasync(2)`][fdatasync]。

## 6. R1 的公开行为合同

R1 保留现有两个函数名：

```cpp
AofReplayResult replay_aof_bytes(
    KvStore& store,
    std::string_view aof_bytes,
    const UnixNow& unix_now);

AofReplayResult replay_aof_file(
    KvStore& store,
    const std::string& path,
    const UnixNow& unix_now);
```

行为升级如下：

| 输入状态 | `replay_aof_bytes()` | `replay_aof_file()` |
|---|---|---|
| 空输入 | 返回 0 条、0 bytes、无残缺尾部 | 空文件保持不变 |
| 全部完整合法 | 应用全部记录，消费全部 bytes | 文件保持不变 |
| 完整前缀 + EOF 残缺尾部 | 应用完整前缀，报告最后有效边界和残缺尾部 | 截到该边界并同步后返回 |
| 第一条就是残缺记录 | 返回 0 条、边界 0、发现残缺尾部 | 截成空文件并同步后返回 |
| parser Error | 抛出带 offset 的原错误 | 启动失败，文件不自动修复 |
| 完整但不允许重放的命令 | 保留既有异常 | 启动失败，文件不自动修复 |
| 合法命令但参数错误 | 保留既有异常 | 启动失败，文件不自动修复 |

这张表规定外部结果，不规定你的 `if` 顺序或内部 helper 怎样拆。

R1 的核心设计仍由你完成。

## 7. 当前启动链怎样复用这次升级

Day5 当前顺序是：

```text
AofWriter writer(aof_path)
-> replay_aof_file(store, aof_path, unix_now)
-> acceptor.start()
```

R1 保持这个顺序和函数签名。

因此 `mini_redis_server.cpp` 不需要为了尾部修复再造一条启动路径。

恢复文件 fd 完成截断与同步后才返回。

Day5 已经保证 `acceptor.start()` 位于返回之后，所以修复失败时仍然不会监听 6380。

writer 已经以 `O_APPEND` 打开同一文件。

后续每次 `write()` 都会以当时的文件末尾作为追加位置，因此下一条 record 会接在修复后的 EOF 后面。

这项行为可对照 [Linux `open(2)` 中的 `O_APPEND`][open].

## 8. R1 修改范围

只修改：

```text
include/mini_redis/aof_replay.hpp
src/aof_replay.cpp
tests/aof_replay_test.cpp
```

若继续使用原 `aof_replay_test` target，CMake 不需要变化。

R1 不修改：

```text
apps/mini_redis_server.cpp
AofWriter
RESP parser
KvStore
command dispatcher
Connection / EventLoop
```

Day2 已经验证的 short write、append `EIO` 和 sync `EIO` 不在 R1 重写。

## 9. R1 最小证据

下面不是五个新知识点。

它们只证明“只修复 EOF 残缺尾部”这一条规则没有误伤其他输入。

| 场景 | 必须观察到的结果 |
|---|---|
| 完整文件 | 全部恢复，长度不变，`incomplete_tail_found == false` |
| 两条完整 + 半条尾部 | 前两条恢复，尾部 key 不出现，文件长度回到 `bytes_consumed` |
| 第一条就是半条 | 0 条恢复，文件变为空文件 |
| 修复后再次重放 | 第二次看到的是完整文件，不再重复修复 |
| 中间 parser Error 或完整 `GET` | 仍然抛错，文件 bytes 完全不变 |

机械 GoogleTest 可以继续委托 Codex。

你需要能解释每个 oracle 为什么来自 §6 的合同。

## 10. R1 停止点

R1 完成后先停，只回答四个问题：

1. `last_good_offset` 表示哪一个 byte 位置？
2. 为什么 `NeedMore + EOF` 可以修复，而 parser `Error` 不能按同一规则处理？
3. 为什么物理截断属于 `replay_aof_file()`，不属于只接收 `string_view` 的 bytes 函数？
4. 为什么 `ftruncate()` 成功以后还不能立刻开始监听？

不要提前加入 AOF rewrite、backup 文件或通用 repair tool。

---

# Round 2：修复动作自己也可能失败

## 11. 新问题不是“怎样再截一次”

R1 假设：

```text
ftruncate 成功
fdatasync 成功
```

现在只问：其中一个系统调用失败时，服务器能不能继续假装文件已经修好？

不能。

修复失败必须继续沿 Day5 的启动 fatal path 非零退出，并保持 6380 未监听。

## 12. `ftruncate()` 失败时发生什么

仍使用 59 -> 49 的例子。

假设 `ftruncate(fd, 49)` 返回 `-1`，并设置 `errno = EIO`。

这次调用没有成功完成修复。

本项目要求：

```text
保留 EIO 来源
-> 不调用修复后的 fdatasync
-> replay_aof_file 不返回成功
-> server 不监听
```

POSIX 的 `ftruncate` 合同规定，调用失败时文件不受这次操作影响。[POSIX `ftruncate`][ftruncate-posix]

测试可以据此确认原文件 bytes 仍在。

若第一次返回 `EINTR`，表示调用被信号打断。

与 Day2 的 write/sync 处理一致，本项目重试同一个截断目标。

## 13. 截短成功、同步失败时发生什么

这次顺序是：

```text
ftruncate(fd, 49) -> 成功
fdatasync(fd)     -> EIO
```

此时当前进程读取文件时，长度可能已经是 49。

但同步边界没有成功，所以服务器仍然必须退出，不能开始监听。

不要为了“回滚”而把文件重新扩回 59 bytes。

扩回去只会产生零填充区域，无法恢复已经截掉的原始尾部。

这条失败路径的准确结论是：

```text
文件内容可能已经被缩短
同步结果失败
启动失败
不声称修复已经持久保存
```

## 14. R2 的最小可控入口

真实普通文件很难稳定制造指定的 `EINTR` 或 `EIO`。

R2 可以沿用 `AofWriter` 已经采用的 callable 注入方式。

一个可接受的最小入口是给文件重放增加测试 overload：

```cpp
using AofTruncateFn = std::function<int(int, off_t)>;
using AofRepairSyncFn = std::function<int(int)>;
```

这两个 callable 需要 `<functional>`，`off_t` 来自 `<sys/types.h>`。

生产入口继续使用真实 `::ftruncate` 与 `::fdatasync`。

测试入口传入带计数器的 lambda。

名字或组织方式可以等价调整，但不要把故障注入参数放进服务器命令行，也不要新造通用 filesystem hierarchy。

## 15. R2 故障矩阵

| 场景 | truncation 调用 | sync 调用 | 文件与启动结果 |
|---|---:|---:|---|
| 完整文件 | 0 | 0 | 长度不变，正常恢复 |
| 尾部残缺，truncate 首次 `EINTR` 后成功 | 2 | 1 | 修复成功 |
| truncate 返回 `EIO` | 1 | 0 | 保留原文件，启动失败 |
| truncate 成功，sync 首次 `EINTR` 后成功 | 1 | 2 | 修复成功 |
| truncate 成功，sync 返回 `EIO` | 1 | 1 | 不监听；不声称修复已持久 |
| parser Error / 完整非法命令 | 0 | 0 | 原文件不改，启动失败 |

这里复用 Day2 已经通过的 errno 保存与 `system_error` 习惯。

R2 不重新教学 `std::function`、lambda 或 EINTR。

## 16. R2 停止点

R2 完成后，应能说清：

```text
截断失败
-> 文件没有完成本次修复

截断成功但同步失败
-> 文件可能已经变短，但不能宣布同步边界成功
```

这两个场景不能都概括成“修复失败，所以文件没变化”。

---

# Round 3：把写命令、文件状态和客户端认知放在同一条时间线上

## 17. 四个时刻不是一个状态

沿用一条会生成 AOF record 的 `SET k v`：

| 时刻 | 已经成立什么 | 还不能推出什么 |
|---|---|---|
| dispatcher 成功 | store 已改变，record 已生成 | record 已进入文件 |
| append 完成 | 完整 bytes 已交给内核文件路径 | 当前同步策略已经成功 |
| sync 返回成功 | 本项目选择的同步边界已经完成 | 客户端已经收到 reply |
| client 收到 reply | 客户端知道这次命令返回成功 | 所有硬件/文件系统故障都已覆盖 |

Day6 不再重新实现这些步骤。

它把 Day2、Day5 与尾部修复放进同一张故障地图。

## 18. 三个进程场景

### 18.1 append 只写了一部分，随后进程退出

文件可能变成：

```text
[旧完整 records][新 record 前缀]
```

客户端没有得到成功 reply。

下次启动把新 record 前缀当作残缺尾部截掉，只恢复旧完整 records。

### 18.2 append 完整，但 sync 失败

完整新 record 可能仍能从当前文件读到。

客户端仍然不应得到成功 reply。

受控重启可能重放这条 record，但这不能倒推出失败时它已经满足持久性边界。

文件里“现在看得见”与“当时 sync 成功”是两个问题。

### 18.3 sync 成功，但 reply 尚未到达客户端

重启后这条 record 应当可以恢复。

客户端却可能不知道上一条请求是否成功。

这是 Day5 已经保留的不确定窗口。

Day6 不加入 request ID、去重或事务协议来消除它。

## 19. R3 的进程级证据

在现有 restart checker 上增加一个独立 tail-repair 场景：

```text
准备：两条完整 records + 半条尾部
-> 启动真实 mini_redis_server
-> 等待它完成恢复并开始监听
-> 检查完整前缀对应的 key
-> 检查半条尾部对应的 key 不存在
-> 结束进程
-> 检查 AOF 长度等于 last_good_offset
-> 再次启动同一文件
-> 第二次不再发生修复，服务仍然健康
```

再准备两份坏文件：

```text
完整 SET + parser Error + 后续 bytes
完整但不允许重放的 GET
```

两者都必须非零退出，6380 不监听，文件哈希保持不变。

这些 socket、进程与 byte 拼接脚手架可以由 Codex 补全。

你负责说明三类文件为什么分别得到“修复并启动”或“拒绝启动”。

## 20. 完整回归

最终至少运行：

```bash
cd /home/xgf/code/system-learning/cpp/week10

cmake -S . -B build
cmake --build build -j
ctest --test-dir build --output-on-failure

python3 tests/mini_redis_aof_restart_check.py \
  --server ./build/mini_redis_server
```

并继续保留：

```text
mini_redis_smoke.py
mini_redis_protocol_check.py
mini_redis_ttl_check.py
```

不要让多个 checker 同时占用 6380。

## 21. Day6 可以证明什么

今天可以证明：

```text
完整合法前缀 + EOF 残缺 record
-> 保留完整前缀
-> 截掉残缺尾部
-> 同步修复后才监听

parser Error / 完整非法命令
-> 不自动截断
-> 启动失败
```

今天不能证明：

```text
能够修复任意中间损坏
能够从随机 bytes 中重新寻找 record 边界
等同于 redis-check-aof
所有掉电、控制器缓存和文件系统故障都已覆盖
每次截断与同步的性能可接受
```

真实 Redis 的官方说明同样区分“最后一条被截断”和“文件中间损坏”，但真实实现、配置和多文件 AOF 都比本项目复杂。只把它作为行为对照，不冒充实现复刻。[Redis 持久化说明][redis-persistence]

---

# Part 3：交付、笔记与下一步

## 22. 今天的交付

必须完成：

```text
AofReplayResult
-> 能报告是否发现 EOF 残缺尾部

replay_aof_bytes
-> 保留完整前缀与 last_good_offset
-> Error/非法命令继续失败

replay_aof_file
-> 只对 EOF 残缺尾部执行 truncate + sync
-> 修复成功后才返回

tests
-> 正常、尾部修复、中间损坏与修复失败边界
```

不要求：

```text
AOF backup/rename
redis-check-aof clone
AOF rewrite
后台 fsync
group commit
多文件 manifest
通用事务日志框架
```

## 23. 六道验收题

1. `last_good_offset` 与 `records_applied` 分别表示什么？为什么二者不能互换？
2. 整个文件只有半条第一记录时，为什么允许截成空文件？
3. parser `Error` 为什么不能像 EOF `NeedMore` 一样截到当前 offset 后启动？
4. `ftruncate()` 成功、`fdatasync()` 失败时，文件可能处于什么状态？服务器为什么仍不能监听？
5. append 只完成一部分后崩溃，下一次启动为什么不会恢复这条命令？
6. sync 成功但客户端没收到 reply，为什么服务端状态与客户端认知仍可能不一致？

## 24. 笔记只保留新增关系

建议在 `week14/day6/day6_note.md` 记录：

1. 一组你自己的 `original_size / last_good_offset / truncated_bytes` 数字。
2. `NeedMore + EOF` 与 parser `Error` 的不同处理。
3. `ftruncate -> fdatasync -> listen` 的顺序。
4. 截断失败与同步失败后，文件状态为什么不能用同一句话概括。

Day2 的 short write、Day3 的完整重放和 Day5 的 append/sync/reply 顺序不重复抄写。

## 25. Day7 从哪里继续

Day6 完成后，Mini Redis V3 已经具备：

```text
规范化记录
完整追加与同步边界
启动重放
TTL 跨重启
真实服务器接线
EOF 残缺尾部修复
中间损坏拒绝启动
```

Day7 不再增加持久化机制。

它只把本周证据整理成项目说明：哪些状态能恢复、哪些故障会失败、哪些结论还没有证明，以及它与真实 Redis/MySQL 日志的边界。

[redis-persistence]: https://redis.io/docs/latest/management/persistence/
[ftruncate]: https://man7.org/linux/man-pages/man2/truncate.2.html
[ftruncate-posix]: https://man7.org/linux/man-pages/man3/ftruncate.3p.html
[fdatasync]: https://man7.org/linux/man-pages/man2/fsync.2.html
[open]: https://man7.org/linux/man-pages/man2/open.2.html
