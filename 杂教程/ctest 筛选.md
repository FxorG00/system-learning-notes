## ctest

你刚才运行的是：

```bash
cmake -E chdir build ctest --output-on-failure
```

它没有筛选，所以 CTest 把 `build` 里注册过的 **30 个测试**都跑了一遍。

你想测的 HTTP response 实际已经跑到了：

```text
26/30 Test #26: HttpResponseTest.Health ... Passed
```

后面那 6 个失败并不是 HTTP response 出错，而是一些旧 probe/test 在 CTest 注册了、但对应可执行文件没有被构建出来，因此显示 `Not Run`。

只跑 HTTP response，用：

```bash
cmake -E chdir build ctest -R '^HttpResponseTest\.' --output-on-failure
```

这里 `-R` 是按 **CTest 测试名**筛选，不是按 `.cpp` 文件名或 CMake target 名。它会匹配：

```text
HttpResponseTest.Health
```

预期只会看到：

```text
1/1 Test #...: HttpResponseTest.Health ... Passed
```

另外，`--output-on-failure` 的意思是“只有失败才打印测试内部输出”。如果你想连通过时的 GTest 输出也看见，加 `-V`：

```bash
cmake -E chdir build ctest -R '^HttpResponseTest\.' -V
```

它把 CTest 里每一条测试的名字，拿来和正则逐个匹配。

## 例子

例如当前有：

```
HttpResponseTest.Health
HttpCompleteRequestTest.ParsesZeroLengthBodyAndPreservesSuffix
HttpRequestParserTest.SplitTest
```

这个 pattern：

```
^HttpResponseTest\.
```

逐段读：

```
^                 必须从测试名开头开始匹配
HttpResponseTest  普通文字，必须原样出现
\.                匹配字面意义上的点 `.`
```

因此它能匹配：

```
HttpResponseTest.Health
HttpResponseTest.OtherCase
```

但不会匹配：

```
MyHttpResponseTest.Health     # 开头不是 HttpResponseTest
HttpResponseTestXHealth       # 中间没有那个 .
HttpRequestParserTest.SplitTest
```

这里的 `\.` 很关键：正则里单独的 `.` 表示“任意一个字符”；写成 `\.` 才表示真正的点号 `.`。

你在 Bash 里应输入一个反斜杠：

```
cmake -E chdir build ctest -R '^HttpResponseTest\.' --output-on-failure
```

不要写成 `\\.`。因为外层是单引号，Bash 不会处理反斜杠；写两个反斜杠会传给 CTest 两个，含义就变掉了。

若你只想精确运行唯一的 `Health` 测试，则把结尾也固定：

```
cmake -E chdir build ctest -R '^HttpResponseTest\.Health$' --output-on-failure
```

其中 `$` 表示“测试名必须刚好在这里结束”。

## 正则

正则表达式（regular expression，简称 regex）就是一种“**描述字符串长相的规则语言**”。

比如你不想逐字符判断：

```text
是不是全是数字？
是不是一个合法邮箱？
是不是以 GET 开头？
```

可以写一条 pattern（模式），让程序去匹配。

最简单的例子：

```text
[0-9]+
```

意思是：

```text
一个或多个数字
```

所以它能匹配：

```text
"0"
"123"
"1048576"
```

但不能匹配：

```text
"12abc"
""
```

常用符号先记这些就够：

| 写法 | 意思 | 例子 |
|---|---|---|
| `abc` | 原样匹配 `abc` | 匹配 `"abc"` |
| `.` | 任意一个字符 | `a.c` 匹配 `"abc"`、`"a9c"` |
| `[0-9]` | 一个数字 | 匹配 `"7"` |
| `[a-z]` | 一个小写字母 | 匹配 `"x"` |
| `*` | 前一个东西重复零次或多次 | `a*` 匹配 `""`、`"aaa"` |
| `+` | 前一个东西至少一次 | `[0-9]+` 匹配 `"123"` |
| `?` | 前一个东西零次或一次 | `https?` 匹配 `"http"`、`"https"` |
| `^` | 字符串开头 | `^GET` 要求开头是 `GET` |
| `$` | 字符串结尾 | `[0-9]+$` 要求结尾全是数字 |
| `(...)` | 分组 | `(GET|POST)` |
| `|` | 或 | `GET|POST` |

例如，要求一个字符串从头到尾都是数字：

```text
^[0-9]+$
```

这里：

```text
^        必须从开头开始
[0-9]+  一个或多个数字
$        必须正好在结尾结束
```

C++ 里可以这样用：

```cpp
#include <regex>
#include <string>

std::regex digits(R"(^[0-9]+$)");

bool ok = std::regex_match("1048576", digits);  // true
bool bad = std::regex_match("12abc", digits);   // false
```

`R"( ... )"` 是 C++ 的 raw string literal（原始字符串字面量），这样 regex 里的反斜杠不需要写成 `\\`，看起来舒服很多。

再区分一个容易混淆的点：

```cpp
std::regex_match(text, pattern);
```

要求 **整个 `text` 都符合 pattern**。

```cpp
std::regex_search(text, pattern);
```

只要 `text` **某个局部**符合就行。

比如 pattern 是 `[0-9]+`：

```text
regex_match("abc123", pattern)  -> false
regex_search("abc123", pattern) -> true
```

放到你现在 HTTP parser 的语境里：正则可用于小型格式检查，但 HTTP 是有分段、长度、`NeedMore`、body bytes 的 byte stream protocol。**完整 parser 仍然更适合你现在这种逐步扫描和明确状态的写法**；不要试图用一个巨大正则去“解析 HTTP”。