## 表

**对：默认参数已经在 `.hpp` 声明中给出，`.cpp` 定义里就不要再写。** 但 `const`、`noexcept` 等不是同一类规则，不能统一当成“声明写过，定义就省略”。

下面按 **class 内声明、class 外定义** 这种常见写法说明。

**对照表**
| 内容 | `.hpp` 中的声明 | `.cpp` 中的类外定义 |
|---|---|---|
| 默认参数 | `void reset(int n = 0);` | 写 `void A::reset(int n)`，**不重复默认值** |
| 成员函数末尾的 `const` | `int get() const;` | **必须保留**：`int A::get() const` |
| `noexcept` | `void f() noexcept;` | **异常约定必须一致**，通常同样写 `noexcept` |
| `explicit` | `explicit A(int n);` | **不能再写**：`A::A(int n)` |
| `static`，静态成员函数 | `static int count();` | **不再写**：`int A::count()` |
| `virtual`，虚函数 | `virtual void run();` | **不再写**：`void A::run()` |
| `override` / `final` | 类内成员声明处写 | **类外定义不写** |
| `constexpr`，可用于常量表达式的函数 | 声明写了 | 定义也要写；通常定义放在头文件中 |

默认值不能在已可见的声明和定义中重复指定，**即使两次都是 `0` 也不行**。[默认参数规则](https://en.cppreference.com/w/cpp/language/default_arguments)  
`explicit` 和 `virtual` 的使用位置由语言规则限定；它们不是定义时需要重复的函数限定。[C++ 标准草案](https://eel.is/c++draft/dcl.fct.spec)

**看一个完整对应**
声明：

```cpp
// Example.hpp
class Example {
public:
    explicit Example(int value = 0) noexcept;

    int get() const noexcept;
    void reset(int value = 0) noexcept;

private:
    int value_;
};
```

定义：

```cpp
// Example.cpp
#include "Example.hpp"

Example::Example(int value) noexcept
    : value_(value) {}

int Example::get() const noexcept {
    return value_;
}

void Example::reset(int value) noexcept {
    value_ = value;
}
```

这里你可以直接逐项对照：

- 构造函数：**去掉 `explicit` 和默认值，保留 `noexcept`**。
- `get`：**保留 `const noexcept`**。
- `reset`：**去掉默认值，保留 `noexcept`**。

`noexcept` 表示函数承诺不让异常逃出；声明与定义的异常约定必须一致，不是只给调用者看的备注。[noexcept 规则](https://en.cppreference.com/w/cpp/language/noexcept_spec)

**为什么默认值只放声明？**
因为**调用位置需要看到默认值**：

```cpp
Example object;   // 看见声明里的默认参数，相当于传入 0
object.reset();  // 同样使用声明提供的默认值 0
```

`.cpp` 的函数体收到的已经是一个实际参数，不需要再声明一次默认值。

**注意区分两种 `const`**
你平时最关心的是：

```cpp
int get() const;                   // 约束当前对象，定义必须保留
void set(const std::string& text); // 参数是“引用到 const string”，定义也必须匹配
```

但**按值参数最外层的 `const`**是一个例外：

```cpp
// 声明
void set(int value);

// 定义可以这样写
void Example::set(const int value) {
    // 这里只限制函数体内不能修改这份参数副本。
}
```

这一对参数类型可以匹配；不要把它和 `get() const` 混为一谈。

**先记你当前最常用的四个：默认值不重复，`explicit` 不重复，成员 `const` 保留，`noexcept` 保持一致。**

## 跟 preprocess,complie 的关系

**对，你已经抓到核心了。** 补准一点：不是“编译时一定只能看到声明”，而是**调用者所在的翻译单元，需要能看到默认参数；不需要看到函数体。** 注释 1

假设三个文件：

```cpp
// Example.hpp
class Example {
public:
    void reset(int value = 0);
};
```

```cpp
// Example.cpp
#include "Example.hpp"

void Example::reset(int value) {
    // 实现……
}
```

```cpp
// main.cpp
#include "Example.hpp"

int main() {
    Example object;
    object.reset();
}
```

编译过程可以这样串：

```text
预处理 main.cpp
→ 展开 Example.hpp
→ main.cpp 对应的翻译单元里能看到 reset(int value = 0)

编译这个翻译单元
→ 检查 object.reset() 这个调用
→ 根据可见的默认参数，按传入 0 来处理
→ 生成调用 reset(int) 的目标代码

分别编译 Example.cpp
→ 生成 reset(int) 的实现

链接
→ 把调用与对应实现连接起来
```

**链接器不负责寻找默认参数，也不负责补上那个 `0`。这件事在编译调用代码时已经处理好了。**

所以如果默认值只写在 `Example.cpp`，`main.cpp` 的翻译单元看不到它，`object.reset()` 就会在**编译阶段**因缺少参数而报错，还没到链接阶段。

你说的“因为还没链接”方向是对的；更准确的因果关系是：**各翻译单元独立编译，调用是否合法必须当场判断，因此默认参数必须在调用处可见。**