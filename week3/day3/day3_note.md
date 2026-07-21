# Week3 Day3 Note

## c_str

```text
.c_str() 返回指向 string 内部字符序列首字符的 const char*
因为是 C 风格，所以以 \0 结尾
这个指针不能 delete

如果我们修改了原 string 了之后，可能发生扩容，搬移，导致原 c_str() 的 const char* 失效。
```

## npos

find 不到的时候返回这个。no position。

```cpp
const std::size_t pos = text.find("GET");

if (pos == std::string::npos) {
    std::cout << "not found\n";
}
```

## remove_if 为什么没有真正删除？

例如：

```cpp
std::vector<int> values{1, 2, 3, 4, 5, 6};

auto new_end = std::remove_if(
    values.begin(),
    values.end(),
    [](int value) {
        return value % 2 == 0;
    });
```

`remove_if` 只负责重新排列范围：

```text
把要保留的 1、3、5 移到前面
返回新的逻辑结尾 new_end
vector 的 size 仍然是 6
```

真正缩短 vector：

```cpp
values.erase(new_end, values.end());
```

组合起来就是经典 erase-remove idiom：

```cpp
values.erase(
    std::remove_if(values.begin(), values.end(), predicate),
    values.end());
```

为什么算法不直接调用 vector::erase？

直觉答案：

```text
算法只操作迭代器范围，不应该假设背后一定是 vector，也不拥有容器本身。
```

## optional(copy 了一手)

`std::optional<T>` 表示：

```text
这里可能有一个 T
也可能没有值
```

例如：

```cpp
std::optional<int> result;
```

有值：

```cpp
return 42;
```

没有值：

```cpp
return std::nullopt;
```

访问 optional 前应先判断：

```cpp
if (result.has_value()) {
    std::cout << result.value() << '\n';
}
```

也可以写成：

```cpp
if (result) {
    std::cout << *result << '\n';
}
```

如果 optional 没有值，直接调用 `value()` 会抛出 `std::bad_optional_access`。`operator*` 也要求 optional 当前确实有值，因此同样应先判断。

相比返回 `-1`：

```text
optional 明确表达“没有结果”
不会和合法的 -1 数据混淆
调用者必须面对“可能不存在”这个事实
```

## tuple

```cpp
std::tuple<int, std::string, bool> user{7, "FxorG", true};
```

表达多个不同类型的值。

C++17 可以使用结构化绑定：

```cpp
auto [code, message] = response;
auto [id, name, active] = user;
```

就是省去了你

```cpp
code=response.first;
message=response.second;
的这个过程
```

