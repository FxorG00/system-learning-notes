有，C++17 里最适合你的是 `std::ostringstream`：

```cpp
#include <sstream>
#include <string>

std::ostringstream builder;
builder << "Hello" << 5 << "Hi";

std::string result = builder.str();
// result == "Hello5Hi"
```

`ostringstream` 是“输出到内存字符串的 `ostream`”。你像用 `std::cout` 一样连续 `<<` 写入，最后通过 `.str()` 取出拼好的 `std::string`。

也可以封装成一行：

```cpp
std::ostringstream oss;
oss << "worker " << id << " failed";
return oss.str();
```

你现在是 C++17，别用 `std::format`，它是 C++20 才有的接口。