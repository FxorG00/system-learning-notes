## 基础

这是程序已经被 F5 启动、当前暂停时出现的调试工具条。你平时最常用的是“断点 + F5 + F10”，先把这一套玩熟就够了。

从左到右：

| 按钮 | 快捷键 | 它做什么 |
|---|---|---|
| 继续 / Continue | `F5` | 继续跑，直到下一个断点、异常或程序结束 |
| 单步跳过 / Step Over | `F10` | 执行当前这一行；如果这一行调用函数，不进入函数内部 |
| 单步进入 / Step Into | `F11` | 执行当前这一行；如果调用函数，就进入该函数第一行 |
| 跳出函数 / Step Out | `Shift+F11` | 当前函数剩余部分直接跑完，回到调用它的那一行之后 |
| 重启 | `Ctrl+Shift+F5` | 从头重新运行这次调试 |
| 停止 | `Shift+F5` | 结束程序和调试器 |

最实用的操作流程：

1. 在你想观察的行号左边空白处单击，出现红点，叫 breakpoint（断点）。
2. 按 `F5`。程序会运行到那一行前暂停。
3. 看左侧 `Variables`，或把鼠标悬在变量上，看它此刻的值。
4. 按 `F10` 一行一行走。
5. 遇到你自己想钻进去看的函数，例如 `parse_header_section()`，按 `F11`。
6. 看完函数内部，按 `Shift+F11` 回到 caller。
7. 想一路跑到下一个断点，按 `F5`。

你调 parser 时可以这样放断点：

```cpp
const HeaderSectionParseResult result =
    parser.parse_header_section(input.data(), input.size(), request);
```

先在这行停下，按 `F11` 进入 `parse_header_section()`；随后用 `F10` 看它怎么扫描每一行、何时判定 `NeedMore`、何时提交 `headers`。

记忆一句就够：

```text
F10：这行干完，但不进函数
F11：这行干完，并进入函数
Shift+F11：当前函数干完，回到外面
F5：继续跑
```

对于 GoogleTest 的失败，调试器不会自动替你解释断言为什么失败；最有效的是在“调用 parser 前”和“即将 return result 前”放断点，亲眼看 `status`、`consumed_bytes`、`headers` 的值。

## 怎么打断点能进入我想要的调试

**最简单：把断点直接打在 `execute_command()` 函数内部，然后按 F5，不要一直按 F11。**

你这行：

```cpp
EXPECT_EQ(execute_command(store, {"PING"}), "+PONG\r\n");
```

在进入 `execute_command()` 之前，还要构造参数里的 `std::string`、`vector`，外面又有 GoogleTest 宏。**F11 会沿着实际执行顺序进入这些函数**，所以你先看到了 `basic_string.h`。

这样操作：

1. 打开 `command_dispatcher.cpp`。
2. 在 `execute_command()` **函数体的第一条可执行语句**上打断点。
3. 暂时取消 test 文件里的断点。
4. 按 **F5：继续运行**，它就会在你自己的函数内部停下。

进入之后记住：

| 按键 | 用途 |
|---|---|
| **F10** | 执行当前行，不进去细看其调用的函数 |
| **F11** | 进入当前执行到的函数调用 |
| **Shift + F11** | 执行到当前函数返回 |
| **F5** | 继续运行到下一个断点 |

另外也可以在左侧 **Breakpoints** 区域右键，选择 **Add Function Breakpoint**，填 `execute_command`，直接在函数入口停下。[VS Code 官方说明](https://code.visualstudio.com/docs/cpp/cpp-debug#_function-breakpoints)