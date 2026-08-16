## vscode tab

有，但你这个需求根本不需要插件，VS Code 自带就能处理。

选中这些多了一个缩进的行，然后按：

```
Shift + Tab
```

或者：

```
Ctrl + [
```

就会让所有选中行整体减少一级缩进。VS Code 官方把这个操作叫 `Outdent Line`。

## echo $?

这两行是在测试 `tcp_client` 的退出状态：

```bash
./tcp_client < /dev/null
echo $?
```

第一行：

```bash
./tcp_client < /dev/null
```

含义是：

- `./tcp_client`：运行当前目录下的 `tcp_client`
- `< /dev/null`：把 `tcp_client` 的标准输入重定向到 `/dev/null`
- `/dev/null`：Linux 的“空设备”，从里面读取时会立刻得到 EOF

所以这相当于：

```text
启动 client
-> stdin 立即 EOF
-> client 不需要等待用户输入
-> 测试 stdin EOF 后的处理逻辑
```

第二行：

```bash
echo $?
```

`$?` 是 shell 保存的“上一条命令的退出状态”。

```text
0       表示上一条命令成功
非 0    表示上一条命令失败
```

例如：

```bash
./tcp_client < /dev/null
echo $?
```

如果 server 没启动：

```text
stderr: Connection refused
1
```

这里的 `1` 表示 `connect` 失败，client 非正常退出。

如果 server 正常启动，并且正确处理空输入：

```text
0
```

表示：

```text
client 连接成功
-> stdin 立即 EOF
-> shutdown(SHUT_WR)
-> 正常完成关闭流程
-> 成功退出
```

注意 `$?` 只记录紧挨着的上一条命令，所以要马上执行：

```bash
./tcp_client < /dev/null
echo $?
```

不要中间再执行其他命令。

## wc

`wc` 是 Linux 的统计工具，缩写是 **word count**，可以统计文件的行数、单词数和字节数。

这里：

```bash
wc -c empty.out
```

其中：

```text
wc       统计文件内容
-c       count bytes，统计字节数
empty.out 要统计的文件
```

例如：

```text
0 empty.out
```

表示 `empty.out` 中有 `0` 个字节。

结合完整命令：

```bash
./tcp_client < /dev/null > empty.out
echo $?
wc -c empty.out
```

含义是：

```text
stdin 立刻 EOF
    |
    v
client 不读取任何输入
    |
    v
stdout 重定向到 empty.out
    |
    v
检查退出码
    |
    v
检查 empty.out 的字节数
```

预期：

```text
0
0 empty.out
```

第一个 `0` 是 `tcp_client` 成功退出；第二个 `0` 是输出文件确实没有任何 payload。

也可以这样写：

```bash
wc -c < empty.out
```

输出通常只有：

```text
0
```

因为文件名没有作为参数传给 `wc`，所以它不会打印文件名。

## 断点

断点可以理解成：

> 程序运行到某一行时，先暂停下来，让你检查当时的变量、调用栈和执行位置。

你之前用 `cout` 是把状态“打印出来”；断点是让程序停住，你可以现场观察状态，还能一步一步继续执行。

### 最基本用法

确保编译时带调试信息：

```bash
g++ -std=c++17 -Wall -Wextra -g your_file.cpp -o your_program
```

`-g` 很重要，它让 `gdb` 知道源代码和机器指令之间的对应关系。

然后在 VS Code 中：

1. 打开 `.cpp` 文件。
2. 点击某一行左侧的空白区域，会出现红点。
3. 按 `F5` 启动调试。
4. 程序运行到红点所在行时暂停。

常用快捷键：

```text
F5           继续运行到下一个断点
F9           添加/取消断点
F10          单步执行，但不进入函数
F11          单步进入函数
Shift + F11  从当前函数返回
Shift + F5   停止调试
```

暂停后，你可以在左侧 Debug 面板观察：

```text
Variables    当前变量
Watch        你主动关注的表达式
Call Stack   当前函数是被谁调用的
```

也可以把鼠标放到变量上查看值。

### 用你的 `send_all` 举例

假设代码大概是：

```cpp
while (offset < size) {
    ssize_t sent = send(fd, data + offset, size - offset, flags);
    offset += sent;
}
```

你可以在 `send` 那一行打断点。暂停后观察：

```text
offset
size
size - offset
sent
errno
```

然后按 `F10` 执行一行，看看：

```text
send 实际发送了多少？
offset 有没有正确增加？
剩余长度有没有变小？
```

如果你想观察 `EINTR` 分支，可以在这里打条件断点：

```cpp
if (errno == EINTR) {
    // retry
}
```

右键断点，选择条件断点，填写：

```text
errno == EINTR
```

这样只有满足条件时才暂停。

### 断点和 `cout` 的区别

`cout`：

```cpp
std::cout << offset << '\n';
```

适合长期记录运行过程，但会：

- 修改代码；
- 改变程序输出；
- 影响时序；
- 可能污染测试结果。

断点：

- 不需要插入打印语句；
- 可以同时观察多个变量；
- 可以查看调用栈；
- 可以控制程序执行到哪一步；
- 可以进入函数内部检查过程。

对于网络程序尤其方便，因为你可以暂停在：

```text
connect
send
recv
shutdown
accept
```

附近，观察 fd、返回值、`errno` 和当前状态。

### 一个重要提醒

断点会暂停程序，所以它不适合观察所有问题。

例如：

- 多线程竞态；
- TCP 超时；
- 依赖精确时序的问题；
- client/server 互相等待的问题。

这类问题加断点后，时序可能改变。此时可以使用 VS Code 的 `Logpoint`：它像 `cout` 一样记录变量，但不需要修改源代码。

你现在最适合的调试方式是：

```text
先用断点观察控制流
-> 再用 Watch 观察关键变量
-> 用 F10/F11 单步确认因果关系
-> 最后用 F5 继续运行
```

对 Day5 的代码，可以先在 `send_all`、`recv_exact`、`shutdown(SHUT_WR)` 和 `accept` 这些位置打断点。