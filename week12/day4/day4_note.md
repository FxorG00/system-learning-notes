## R1

```text
kv_store
用 map<> 去存储数据
```

## 一个报错

我们就按英文的顺序拆：

> **passing ‘const std::map<...>’ as ‘this’ argument discards qualifiers**

### 1. `passing ... as ... argument`

这个句式是：

**“把……作为……参数传入。”**

例如：

```text
passing x as the first argument
把 x 作为第一个参数传入
```

### 2. `passing ‘const std::map<...>’ as ‘this’ argument`

意思是：

**“把这个 const map 对象，作为 `this` 参数传入。”**

你调用：

```cpp
data_[key]
```

实际上是在调用 `data_` 的 `operator[]` 成员函数。成员函数通过隐含的 **`this` 指针**访问“当前是哪个对象在调用我”。这里的对象就是 `data_`。

### 3. `discards qualifiers`

- **discard**：丢弃、去掉。
- **qualifier**：限定符；这里指 **`const`**。

所以这一部分是：

**“会丢弃 const 限定符。”**

整句话翻成人话：

> **你拿一个 const map 去调用 `operator[]`，但这个函数要求可修改的 map。这样就相当于要去掉 const，编译器不允许。**

它省略了中间的原因，完整逻辑是：

```text
你提供的是 const map
→ operator[] 要求可修改的 map
→ 两者不匹配
→ 强行匹配就得去掉 const
→ 报错：discards qualifiers
```

## execute_command

```text
就是个 dispatcher，根据 command name route 到对应的 handler
```