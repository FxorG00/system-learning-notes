**你用 GCC/g++，可以用内建函数 `__builtin_add_overflow`：安全地计算加法，并告诉你结果是否越界。** 它是编译器扩展，不是 C++17 标准库 API。[GCC 官方说明](https://gcc.gnu.org/onlinedocs/gcc/Integer-Overflow-Builtins.html)

调用形式：

```cpp
bool overflow = __builtin_add_overflow(a, b, &result);
```

- `a`、`b`：两个整数。
- `&result`：接收结果的地址；**按 result 的整数类型判断能否表示结果**。
- 返回 `true`：越界。
- 返回 `false`：未越界，可以使用 `result`。
- 不需要专门的头文件。

一个独立小例子：

```cpp
#include <cstdint>
#include <limits>
#include <stdexcept>

std::int64_t a = std::numeric_limits<std::int64_t>::max();
std::int64_t b = 1;
std::int64_t result{};

if (__builtin_add_overflow(a, b, &result)) {
    throw std::overflow_error("addition out of range");
}
// 只有未越界时，才把 result 当成正确的数学结果使用。
```

**函数负责检测；`throw std::overflow_error(...)` 是你检测之后主动执行的动作。** 普通的 `a + b` 不会自动替你抛这个异常。

另外也可以用标准库 `<limits>` 的 `std::numeric_limits<T>::max()` 获取上限，**先检查边界，再执行加法**。它只提供上限，本身不检测加法；具体判断留给你设计。