这里两个 cast 做的是完全不同的事：

```cpp
const auto* bytes =
    reinterpret_cast<const unsigned char*>(&address.s_addr);
```

## `reinterpret_cast`：换一种方式看同一块内存

假设：

```cpp
address.s_addr
```

是一个 4-byte 整数。原来的指针类型是：

```cpp
const std::uint32_t*
```

但现在想逐 byte 读取它，所以把地址重新解释成：

```cpp
const unsigned char*
```

内存没有发生复制或转换：

```text
原来：
[address.s_addr：4 bytes 整体]

reinterpret_cast 后：
bytes[0] bytes[1] bytes[2] bytes[3]
```

这正是 `reinterpret_cast` 的典型用途：

```text
同一块内存
-> 换一种底层类型观察
```

C++ 允许通过 `char*`、`unsigned char*` 或 `std::byte*` 查看任意对象的底层 byte representation，所以这里合法。

---

下面这个是另一回事：

```cpp
static_cast<unsigned int>(bytes[i])
```

## `static_cast`：进行正常的值转换

`bytes[i]` 类型是：

```cpp
unsigned char
```

而 `std::cout` 输出 `unsigned char` 时，往往会把它当字符处理。例如：

```cpp
unsigned char value = 65;
std::cout << value;  // 可能输出 A
```

转换成 `unsigned int` 后：

```cpp
std::cout << static_cast<unsigned int>(value);  // 输出 65
```

所以你的代码中：

```cpp
static_cast<unsigned int>(bytes[i])
```

是为了让 `cout` 输出 byte 的十六进制数值，而不是把 byte 当字符输出。

建议补上：

```cpp
std::setfill('0')
```

完整一些：

```cpp
std::cout << "IPv4 bytes: ";

const auto* bytes =
    reinterpret_cast<const unsigned char*>(&address.s_addr);

for (std::size_t i = 0; i < sizeof(address.s_addr); ++i) {
    std::cout << std::hex
              << std::setfill('0')
              << std::setw(2)
              << static_cast<unsigned int>(bytes[i])
              << ' ';
}

std::cout << std::dec << '\n';
```

`std::dec` 是把后续整数输出恢复成十进制。

## 几种 cast 的区别

| cast | 主要用途 | 是否运行时检查 |
|---|---|---:|
| `static_cast` | 正常、明确的值转换或类型层次转换 | 否 |
| `dynamic_cast` | 多态继承体系中安全地向下转换 | 是 |
| `reinterpret_cast` | 重新解释地址或底层表示 | 否 |
| `const_cast` | 添加或移除 `const`/`volatile` | 否 |

### `static_cast`

```cpp
double value = 3.14;
int number = static_cast<int>(value);
```

表示真正进行数值转换，结果是 `3`。

### `dynamic_cast`

用于带虚函数的多态类型：

```cpp
Base* base = get_object();
Derived* derived = dynamic_cast<Derived*>(base);

if (derived == nullptr) {
    // 实际对象不是 Derived
}
```

它会在运行时检查实际对象类型。

### `reinterpret_cast`

```cpp
auto* bytes =
    reinterpret_cast<const unsigned char*>(&value);
```

不进行正常的值转换，只是换一种类型解释同一个地址。它非常底层，需要谨慎使用。

### `const_cast`

```cpp
const int* source = ...;
int* target = const_cast<int*>(source);
```

它只改变类型系统中的 `const` 属性。若原对象本身确实是 `const`，通过 `target` 修改它是未定义行为。

你这段代码可以压缩记忆为：

```text
reinterpret_cast：
把 address.s_addr 的地址看成 byte pointer，逐 byte 读内存。

static_cast：
把每个 unsigned char 转成 unsigned int，让 cout 输出数值而不是字符。
```