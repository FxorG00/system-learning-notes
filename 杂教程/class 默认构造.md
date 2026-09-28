会是空字符串，不是未定义。

```cpp
HttpHeaderField tmp;
```

会默认构造两个 `std::string` 成员，等价于：

```cpp
HttpHeaderField tmp{
    std::string{},
    std::string{}
};
```

因此：

```cpp
tmp.name  == ""
tmp.value == ""
```

两者都是合法、可用的空字符串。

注意区别：若成员是基础类型：

```cpp
struct Example {
    int count;
};

Example x;
```

那么 `x.count` 是未初始化的，读取它是未定义行为；而 `std::string` 自己有默认构造函数，所以安全。