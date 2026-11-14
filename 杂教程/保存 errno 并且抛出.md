这句话的意思是：**系统调用失败后，把操作系统给出的错误原因保存下来，再通过异常交给调用者。**

你记得的 `perror` 确实和 `errno` 有关。我们从你熟悉的写法开始。

## 1. `errno` 是什么？

例如调用 `write()` 写入文件时：

```cpp
ssize_t n = ::write(fd, data, length);

if (n == -1) {
    // 写入失败
}
```

`-1` 只告诉你“失败了”，但没告诉你**为什么失败**。

失败原因放在 `errno` 里。例如：

```text
errno = EBADF   文件描述符无效
errno = ENOSPC  设备没有空间
errno = EIO     发生 I/O 错误
```

因此可以理解为：

```text
返回值 -1  → 操作失败了
errno      → 操作为什么失败
```

要注意：**只有当接口通过返回值说明失败时，才去读取 `errno`。** 成功后不能仅凭 `errno` 的旧值判断是否发生错误。

## 2. 它和 `perror` 是什么关系？

你可能见过：

```cpp
if (n == -1) {
    perror("write");
}
```

`perror("write")` 会读取当前的 `errno`，然后向标准错误输出一段提示。例如：

```text
write: No space left on device
```

这里 `"write"` 是你提供的文字，用来说明**哪里出错了**；后面的描述来自 `errno`。

所以 `perror` 的参数不是 `errno`。它接收的是一段提示文字：

```cpp
perror("write");  // 对：perror 内部读取 errno
```

## 3. `std::system_error` 又是做什么？

`perror` 是把错误**打印出来**。但有时当前函数不想只打印，而是要让调用它的人知道操作失败了，由调用者决定怎么处理。

例如：

```cpp
#include <cerrno>
#include <system_error>
#include <unistd.h>

ssize_t n = ::write(fd, data, length);

if (n == -1) {
    const int saved_errno = errno;

    throw std::system_error(
        saved_errno,
        std::generic_category(),
        "write AOF"
    );
}
```

这一步可以拆开看：

```text
saved_errno          保存失败原因，例如 ENOSPC
"write AOF"          说明是在写 AOF 时失败
std::system_error    把这些信息包装成一个异常，交给调用者
```

`std::generic_category()` 告诉错误码对象怎样解释这类通用系统错误码。当前你可以先把它和 `saved_errno` 当作一组来使用。

**为什么先保存 `errno`？** 因为之后调用的其他函数也可能修改它。紧跟失败的系统调用保存，就不会把原本的失败原因弄丢。

## 4. 调用者怎么拿到它？

调用者可以捕获这个异常：

```cpp
try {
    // 调用可能写 AOF 的函数
} catch (const std::system_error& e) {
    std::cout << e.what() << '\n';         // 包含调用语境和错误描述
    std::cout << e.code().value() << '\n'; // 底层错误码
}
```

例如发生空间不足，`e.what()` 可能包含：

```text
write AOF: No space left on device
```

测试也可以检查错误码：

```cpp
EXPECT_EQ(e.code().value(), ENOSPC);
```

这样测试检查的是**具体错误原因**，而不必依赖错误描述文字的措辞。

所以把它们放在一起看：

```text
write 失败
    ↓
errno 记录失败原因
    ↓
立即保存 errno
    ↓
std::system_error 带着错误码和 "write AOF" 往外抛
    ↓
调用者通过 e.code() 检查错误码
```

`perror` 是**直接打印当前错误**；`std::system_error` 是**把错误交给上层处理**。具体哪些 `errno` 需要重试、哪些需要抛异常，还要按照你正在调用的系统接口和项目约定来区分。