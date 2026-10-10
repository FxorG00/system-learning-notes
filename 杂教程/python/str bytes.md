**`b"hello"` 是字节序列 `bytes`，不加 `b` 的 `"hello"` 是文本字符串 `str`。** 两者看起来相似，但表示的对象不同。

### 1. `str`：给人读的文本

```python
text = "hello"
name = "你好"
```

Python 的 `str` 保存 Unicode 文本，能够表示中文等字符。

**Python 没有单独的 `char` 类型。** 一个字符也是长度为 1 的 `str`：

```python
text[0]          # "h"
type(text[0])    # str
```

### 2. `bytes`：给网络、文件处理的原始字节

```python
data = b"hello"
```

可以把它理解成不可修改的字节数组，每个字节的值在 `0～255`：

```python
data[0]         # 104，是整数，字母 h 的 ASCII 编码
data[:1]        # b"h"，切片仍然是 bytes
```

对照来看：

| 操作 | `str` | `bytes` |
|---|---|---|
| 内容 | 字符 | 字节 |
| 示例 | `"hello"` | `b"hello"` |
| 取一个元素 | `"h"` | `104` |
| 能否原地修改 | 不能 | 不能 |

**`b` 前缀创建字节字面量，并不是执行一次通用的文本编码。** 例如直接写 `b"你好"` 会产生语法错误，需要通过编码转换。

### 3. 文本与字节怎样转换？

```python
text = "你好"

data = text.encode("utf-8")  # 文本 -> UTF-8 字节
# b'\xe4\xbd\xa0\xe5\xa5\xbd'

restored = data.decode("utf-8")  # UTF-8 字节 -> 文本
# "你好"
```

这里最值得观察的是：

```python
len(text)   # 2：两个 Unicode 字符
len(data)   # 6：UTF-8 编码后六个字节
```

**字符数和字节数不是一回事。** `"hello"` 恰好都是 5，容易让人误以为它们相同。

### 4. `bytearray`：可以修改的字节序列

`bytearray` 可以理解成 Python 中方便追加、修改的 byte buffer（字节缓冲区）：

```python
buffer = bytearray(b"hello")

buffer[0] = 72          # 把第一个字节改为 H
buffer.extend(b"!")     # 追加字节

print(buffer)           # bytearray(b'Hello!')
data = bytes(buffer)    # 转成不可修改的 bytes
```

这就解释了你之前的接收代码：

```python
received = bytearray()  # 用可变 buffer 累积
received.extend(chunk)  # chunk 是 socket 收到的 bytes
return bytes(received)  # 最后返回不可变的 bytes
```

**联系你现在的网络代码：`socket` 收发的是字节，所以使用 `bytes`；拼接接收内容时用 `bytearray`；需要把内容当文本解释时，再按明确的编码 `decode`。**