如果 `A` 是第一次定义：

```cpp
MyClass A = B;
```

调用的是 **copy constructor（拷贝构造）**，不是 assignment。

因为这件事是在“构造 `A`”：

```text
A 还不存在
-> 用 B 初始化 A
-> copy constructor
```

而如果 `A` 已经存在：

```cpp
MyClass A;
A = B;
```

调用的是 **copy assignment operator（拷贝赋值运算符）**：

```text
A 已经构造好了
-> 用 B 覆盖 A 当前的内容
-> operator=
```

对应关系：

```cpp
MyClass A = B;  // copy constructor
MyClass A(B);   // copy constructor

MyClass A;
A = B;          // copy assignment
```

实际编译时可能发生 copy elision，省掉某次临时对象复制；但前两种在语义分类上仍然是“构造/初始化”，不是赋值。