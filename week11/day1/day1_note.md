## R1

```text
complete:
    有且仅有 2 个空格
    有且仅有 1 个 \r，1 个 \n；且 \r\n 是连着的，且一定出现在末尾；
    两个空格跟 \r\n 把字符串分成三段。
    要求每一段的长度均 >0
    第一段: 字符只能出现在 method token byte
    method token byte：
    A-Z a-z 0-9 以及 ! # $ % & ' * + - . ^ _ ` | ~
    
	并且 \r\n 之前的 bytes<=kMaxRequestLineBytes
	
第二段：开头一段是 \;
target byte: 且其他 byte 都在 0x21 到 0x7E 之间;并且不能是 '#'

第三段：直接获取；并且只能接收 HTTP/1.1

这里可以写 check 每一段的 helper

needmore:
我觉得需要去分类讨论目前位于哪段前缀

length == 0：data 可以是 nullptr，返回 NeedMore

if 目前没有出现 \r\n:
目前出现了几个空格？只允许 <=2 个空格
0 个空格:
	那么第一段就出来了，可以去 check 第一段合不合法；
1 个空格：
	分成 2 段；
		第二段为空:
			只 check 第一段合不合法
		第二段不为空:
			分别 check 第一二段合不合法
2 个空格:
	出现了连续 2 个空格:
		非法
	分成了 3 段:
		第三段为空:
			去 check 1,2 段合不合法
		第三段不为空:
			去 check 1,2 段合不合法
			去 check 第三段是不是 HTTP/1.1 的前缀，这个单独写个 helper

else if 目前出现了 \r:
	有出现 \n:
		要求一定是都只有一个，并且 \r\n 连着在末尾
	无出现 \n:
		按照 2 个空格第三段不为空的 check 方法

else 目前出现了 \n:
	非法

需要注意，在找 complete 前需要找到第一个 \r\n，并且拿这个前缀去 check complete
```

### 怎么判断 0x21,0x7E

对，逻辑就是这样：

```cpp
if (0x21 <= c[i] && c[i] <= 0x7E) {
    // c[i] 是可接受的 ASCII visible character
}
```

更稳一点的写法是先转成 `unsigned char`，避免 `char` 在某些平台是 signed 时，非 ASCII byte 变成负数：

```cpp
const unsigned char byte = static_cast<unsigned char>(c[i]);

if (0x21 <= byte && byte <= 0x7E) {
    // 合法范围
}
```

如果你是在判断“不合法”，就写：

```cpp
if (byte < 0x21 || byte > 0x7E) {
    // malformed
}
```

### HTTP/2. 是哪种 case

这里应该是 `NeedMore`，不是 `UnsupportedHttpVersion`。

虽然你已经看到 major version 是 `2`，知道它不可能成为受支持的 `HTTP/1.1`；但当前还没法确认它最终属于哪种错误：

```text
HTTP/2.0\r\n  -> 形状合法，但不支持 -> UnsupportedHttpVersion
HTTP/2.x\r\n  -> 形状不合法           -> MalformedRequestLine
HTTP/2.\r\n   -> 少了 minor digit     -> MalformedRequestLine
```

当前的：

```text
HTTP/2.
```

仍可能继续收到 `0`、`1` 等 digit，也可能收到非法字符或直接结束。因此 parser 还无法按你的优先级准确区分“合法形状但不支持”和“根本 malformed”。

所以顺序是：

```text
形状尚未完整，且未来 error category 未确定
-> NeedMore

形状完整：HTTP/digit.digit
-> 再判断是否等于 HTTP/1.1
-> 不等于则 UnsupportedHttpVersion
```