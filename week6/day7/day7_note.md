## 总结

今天就是把怎么样去解析 http 报文给你讲清楚，然后动手实现这个 parser。

HTTP 是 application-layer protocol。
它规定 client 和 server 怎样组织 request / response bytes。

## string find npos

`npos` 是 `no position` 的缩写，表示“没有找到位置”。

`std::string::find()` 返回的是位置下标；找不到时返回 `std::string::npos`。

```cpp
#include <iostream>
#include <string>

int main() {
    std::string text = "hello world";

    std::size_t pos = text.find("world");

    if (pos != std::string::npos) {
        std::cout << "found at: " << pos << '\n';  // 6
    } else {
        std::cout << "not found\n";
    }
}
```

再看找不到：

```cpp
std::string text = "hello";

if (text.find("cpp") == std::string::npos) {
    std::cout << "cpp not found\n";
}
```

`find` 还有一个可选的起始位置：

```cpp
std::string text = "a-b-a-b";

std::size_t first = text.find("a");       // 0
std::size_t second = text.find("a", 1);   // 从下标 1 开始找，得到 4
```

别写成 `find(...) == -1`。`find` 的返回类型通常是无符号的 `std::size_t`，正确比较对象永远是：

```cpp
std::string::npos
```

压缩记忆：

```text
find 成功 -> 返回第一个匹配位置
find 失败 -> 返回 std::string::npos
```