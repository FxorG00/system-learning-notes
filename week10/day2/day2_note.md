## R1

```text
member 是简单的

目前来看就是按着 contract 写就好了
```

### noexcept,explicit

对，二者不一样。

```cpp
class Channel {
public:
    explicit Channel(int fd) noexcept;
};
```

类外 definition 必须写 `noexcept`：

```cpp
Channel::Channel(int fd) noexcept
    : fd_(fd) {
}
```

但不能、也不需要再写 `explicit`：

```cpp
// 错误：类外 definition 不能写 explicit
explicit Channel::Channel(int fd) noexcept {
}
```

原因：

- `explicit` 只在 declaration 处规定“禁止 `Channel c = 3;` 这种隐式转换”，它不是构造函数实现的一部分。
- `noexcept` 是函数的异常规格：声明承诺“不抛异常”，definition 也必须保持同样承诺；省略会变成声明与定义不一致，编译报错。

## R2

```text
set callback 不要标 `noexcept`：`std::function` 的构造或赋值可能分配内存，失败时可能抛异常。

并且，因为我们的 argument 是按值传的 function，所以再赋值给 member 的时候，应该用 move-assignment，减少不必要的 copy

Channel 描述 fd，但不拥有 fd，所以析构时不负责 close
```
