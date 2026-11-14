# 讲解

**先给结论：`namespace` 用来给名字划分区域；匿名命名空间用来把名字限制在当前 `.cpp` 文件内部。**

你当前的需求非常具体：

```text
encode_aof_set
encode_aof_del
encode_aof_pexpireat
```

这三个函数要给其他 `.cpp` 使用，所以放进 public header。

而：

```text
encode_resp_array_of_bulk_string
```

只是这三个函数内部共用的 helper。其他文件不需要知道它，因此适合放进匿名命名空间。

**1. 普通 namespace 解决什么问题**

假设项目里有两个 `parse()`：

```cpp
// HTTP parser
ParseResult parse(...);

// RESP parser
ParseResult parse(...);
```

它们名字和参数相同时会冲突。

可以分别装进两个命名空间：

```cpp
namespace http {

ParseResult parse(...);

}

namespace resp {

ParseResult parse(...);

}
```

调用时明确指定：

```cpp
http::parse(...);
resp::parse(...);
```

所以：

```text
namespace 名字::函数名字
```

共同构成函数的完整名字。

`namespace` 不是对象，也不会在运行时创建什么东西。它只负责组织 C++ 名字。

---

**2. 同一个命名空间可以跨文件延续**

例如：

```cpp
// parser.hpp
namespace resp {

RespResult parse(const char* data);

}
```

```cpp
// parser.cpp
namespace resp {

RespResult parse(const char* data) {
    // 实现
}

}
```

```cpp
// main.cpp
#include "parser.hpp"

resp::parse(data);
```

三个文件中的 `resp` 表示同一个命名区域。

这就是普通命名空间在多文件项目里的作用：

```text
header 声明 resp::parse
.cpp 实现 resp::parse
其他文件调用 resp::parse
```

---

**3. 匿名命名空间解决什么问题**

现在看你的 helper：

```cpp
namespace {

std::string encode_resp_array_of_bulk_string(
    const std::vector<std::string>& data) {
    // 实现
}

}
```

这里没有写名字：

```cpp
namespace {
}
```

所以叫 **anonymous namespace（匿名命名空间）**，也叫 unnamed namespace（未命名命名空间）。

它的行为是：

> **里面的名字只属于当前这个 `.cpp` 编译单元，其他 `.cpp` 无法使用它。**

例如：

```cpp
// aof_record.cpp
namespace {

void helper() {
}

}
```

另一个文件不能这样调用：

```cpp
// main.cpp
helper();  // 找不到
```

因为 `helper()` 没有被公开给 `main.cpp`。

---

**4. 两个 `.cpp` 可以各有一个同名 helper**

```cpp
// aof_record.cpp
namespace {

void helper() {
    // AOF 的 helper
}

}
```

```cpp
// command_dispatcher.cpp
namespace {

void helper() {
    // dispatcher 的 helper
}

}
```

它们不会冲突。

可以把它理解成编译器分别给它们加了当前文件独有的身份：

```text
aof_record.cpp 独有的 helper
command_dispatcher.cpp 独有的 helper
```

即使文字名字都叫 `helper`，也不是同一个函数。

---

**5. 放回你的代码**

最自然的排列是：

```cpp
#include "aof_record.hpp"

#include "resp_encoder.hpp"

#include <sstream>

namespace {

std::string encode_resp_array_of_bulk_string(
    const std::vector<std::string>& data) {
    std::ostringstream builder;
    builder << "*" << data.size() << "\r\n";

    std::string result = builder.str();

    for (const auto& item : data) {
        result += encode_resp_bulk_string(item);
    }

    return result;
}

}  // namespace

std::string encode_aof_set(
    std::string_view key,
    std::string_view value) {
    // 可以调用上面的 helper
}
```

这里形成了很清楚的边界：

```text
aof_record.hpp
→ 只告诉其他文件：AOF 组件能做哪三件事

aof_record.cpp 的匿名命名空间
→ 保存这个组件自己的内部工具

三个公开函数
→ 使用内部工具完成工作
```

匿名命名空间里的函数仍然要在调用前声明或定义。它只改变“其他文件能不能看到”，不会取消 C++ 的声明顺序规则。

**6. 一条实用判断**

写函数时可以问：

```text
其他 .cpp 是否应该直接调用它？
```

答案是“应该”：

```text
放进 header，成为模块接口
```

答案是“不应该，只是当前 .cpp 的内部工具”：

```text
放进当前 .cpp 的匿名命名空间
```

因此你这次把 helper 从 public header 移走，方向完全正确。现在只要把它的定义移动到三个公开函数之前即可。

# 感觉上加了前缀

对，**这个直觉基本正确**。

普通命名空间可以理解为给里面的名字增加一个限定前缀：

```cpp
namespace resp {

void parse();

}
```

函数的完整名字就是：

```cpp
resp::parse
```

另一个命名空间可以有同名函数：

```cpp
namespace http {

void parse();

}
```

它的完整名字是：

```cpp
http::parse
```

所以两者不会冲突：

```cpp
resp::parse();
http::parse();
```

编译器生成给链接器使用的函数符号时，通常也会把命名空间、函数名和参数类型编码进去。这个过程叫 **name mangling（名字修饰）**，但具体编码格式属于编译器实现。

匿名命名空间则可以直观理解成：

```cpp
namespace 当前cpp独有的隐藏名字 {

void helper();

}
```

例如编译器在概念上可以把两个文件理解成：

```text
aof_record.cpp 独有名字::helper
command_dispatcher.cpp 独有名字::helper
```

所以两个 `.cpp` 即使都写：

```cpp
namespace {
void helper();
}
```

它们仍然是两个不同的函数。

不过 namespace 不只是简单的文本替换。它还决定：

- 这个名字在哪个范围里可以直接使用。
- 其他文件能不能引用同一个实体。
- 同名函数是否会发生冲突。

但作为第一层理解，你完全可以先记成：

> **普通 namespace 给名字加一个可写的限定符；匿名 namespace 给名字加一个当前 `.cpp` 独有、外部无法写出的限定身份。**