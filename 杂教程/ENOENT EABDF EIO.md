这两个都是 Linux 的**错误码**。它们告诉你：系统调用为什么失败了。

先结合你这条测试看：

```text
尝试打开一个不存在的 AOF 文件
        ↓
open() 失败，返回 -1
        ↓
errno 被设置为 ENOENT
```

这里的 **`ENOENT`** 可以记成：

```text
E     → Error，错误
NOENT → No Entry，没有找到对应的目录项
```

在这个场景下，它表示：**你要打开的路径找不到**。可能是文件不存在，也可能是路径中某一级目录不存在。

例如：

```cpp
int fd = ::open("/tmp/does-not-exist.aof", O_RDONLY);
```

如果文件确实不存在：

```text
fd    = -1
errno = ENOENT
```

---

## `EBADF` 是什么？

**`EBADF`** 可以记成：

```text
E    → Error，错误
BADF → Bad File descriptor，文件描述符有问题
```

比如：

```cpp
char buffer[100];

::read(-1, buffer, sizeof(buffer));
```

`-1` 不是一个有效的文件描述符，所以通常得到：

```text
read() 返回 -1
errno = EBADF
```

## 为什么测试说“不能伪装成 EBADF”？

假设代码没有检查 `open()` 的结果，直接继续：

```cpp
int fd = ::open(path.c_str(), O_RDONLY);

// fd 已经是 -1，还是继续读
char buffer[100];
::read(fd, buffer, sizeof(buffer));
```

实际发生的是：

```text
open(path)
  ↓
文件不存在
  ↓
返回 -1，errno = ENOENT
  ↓
read(-1)
  ↓
又失败，errno = EBADF
```

如果这时你才检查 `errno`，看到的就是 `EBADF`。

但**最初的问题其实是 AOF 路径不存在**。后面的 `EBADF` 只是因为程序拿着失败得到的 `-1` 继续调用 `read()`。

## 正确处理顺序

`open()` 失败后，立刻保存错误码并抛出：

```cpp
int fd = ::open(path.c_str(), O_RDONLY);

if (fd == -1) {
    const int saved_errno = errno;

    throw std::system_error(
        saved_errno,
        std::generic_category(),
        "open AOF");
}
```

这样调用者拿到的 `system_error` 里保留的就是原来的 **`ENOENT`**；程序也不会再拿 `-1` 去调用 `read()`。

所以这条测试想证明的是：

> **打开文件在哪一步失败，就把那一步的真实错误交给调用者。**

## EIO

`EIO` 是 Linux 的一个错误码，表示 **Input/Output error（输入输出错误）**。

放到你这句话里：

```text
outcome 有 record，append 抛 EIO
```

意思是：

```text
命令已经产生一条需要写入 AOF 的 record
        ↓
调用 writer.append(record)
        ↓
append 内部的 write() 失败
        ↓
errno 是 EIO
        ↓
append 抛出保留 EIO 的 std::system_error
```

更精确地说，**抛出的不是 `EIO` 这个整数本身，而是带有 `EIO` 错误码的 `std::system_error`**。

### 举个具体例子

假设你的 record 有 100 bytes：

```text
write(fd, data, 100) → 返回 -1
errno                 → EIO
```

这说明本次写入调用遇到了 I/O 错误。它可能与文件系统或底层存储有关，但**只凭 `EIO` 不能断定具体是哪一个硬件坏了**。

你的 `append()` 需要把这个错误交给上层，不能当作写入成功：

```cpp
const int saved_errno = errno;

throw std::system_error(
    saved_errno,
    std::generic_category(),
    "write AOF"
);
```

### 对 server 意味着什么？

按照你们当前要实现的顺序：

```text
产生 record
    ↓
append
    ↓
sync
    ↓
发送成功 reply
```

如果 `append()` 抛出带 `EIO` 的异常，就不能继续假装持久化成功，也不能发送这条命令的成功 reply。

还有一点：如果 `write_all` 前面已经成功写入了一部分 bytes，**后面再遇到 `EIO`，不代表前面写进去的部分会自动撤回**。所以文件尾可能留下半条 record。

测试里如果是通过假的 `write` 函数主动返回 `EIO`，那是在**模拟这个失败分支**，不代表你的磁盘真的发生了故障。