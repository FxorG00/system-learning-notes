对，你这样写就可以：

```cpp
std::function<int()> tmp = get;
```

它的意思是：**把 `get` 这个函数保存到 `tmp` 中，以后可以通过 `tmp()` 调用它。**

我们用一个完整例子来看：

```cpp
#include <functional>
#include <iostream>

int get() {
    return 42;
}

int main() {
    std::function<int()> tmp = get;

    int result = tmp();
    std::cout << result << '\n';  // 42
}
```

这里分两步：

```cpp
std::function<int()> tmp = get;
```

先把 `get` 保存起来，**这一步没有调用 `get()`**。

接着：

```cpp
int result = tmp();
```

这里才会通过 `tmp` 调用 `get()`，得到 `42`。

## `std::function<int()>` 怎么读？

```cpp
std::function<int()> tmp;
              │   │
              │   └─ 参数列表为空
              └───── 返回 int
```

也就是说，`tmp` 可以保存一个**无参数、调用结果可作为 `int` 返回**的函数或其他可调用对象。

比如下面这个也可以：

```cpp
std::function<int()> tmp = [] {
    return 42;
};

std::cout << tmp();  // 42
```

所以 `std::function` 的作用是：**用一个统一的类型，保存以后可以调用的东西。** 这里的 `get` 和 lambda（匿名函数）都可以放进去。

## 有参数时怎么写？

假设函数是：

```cpp
int add(int a, int b) {
    return a + b;
}
```

那就把参数写进括号：

```cpp
std::function<int(int, int)> calculate = add;

int result = calculate(3, 4);  // 7
```

这里：

```text
int(int, int)

前面的 int       → 返回值
括号里的 int, int → 两个参数
```

## 注意 `get` 和 `get()` 的区别

```cpp
std::function<int()> tmp = get;
```

这是**保存函数**，以后再调用。

```cpp
int value = get();
```

这是**现在就调用函数**，把返回的整数保存到 `value`。

所以对你这个例子，写 `tmp = get` 就对了。

顺便联系一下你之前的 `KvStore`：它保存的那个获取时间的能力，本质上也是类似的思路。store 不需要现在就知道具体由谁提供时间，只要之后调用这个对象，能得到所需的时间值就行。