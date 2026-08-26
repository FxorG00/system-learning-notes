这是 VS Code 的 IntelliSense 没有使用你真实构建时的 `-I.../include` 参数；编译器能过，编辑器仍划红线是两套配置没对齐。

推荐让 CMake 生成 `compile_commands.json`，再交给 VS Code。它记录每个 `.cpp` 的真实编译命令，包括 include path、C++17、宏定义等。C/C++ 扩展会优先用这份命令配置当前文件的 IntelliSense。[官方说明](https://code.visualstudio.com/docs/cpp/configure-intellisense) [CMake 说明](https://cmake.org/cmake/help/latest/variable/CMAKE_EXPORT_COMPILE_COMMANDS.html)

你现在的 `CMakeLists.txt` 在 `tests/`，所以在 `tests/` 下重新 configure：

```bash
cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
cmake --build build -j
```

这会生成：

```text
/home/xgf/code/system-learning/cpp/week8/tests/build/compile_commands.json
```

接着在远程 VS Code 中：

```text
Ctrl+Shift+P
-> C/C++: Edit Configurations (JSON)
```

在对应 configuration 里加：

```json
"compileCommands": "/home/xgf/code/system-learning/cpp/week8/tests/build/compile_commands.json"
```

保存后执行：

```text
Ctrl+Shift+P
-> Developer: Reload Window
```

红线就应该消失。

临时的简易修法是在同一份配置中加：

```json
"includePath": [
  "/home/xgf/code/system-learning/cpp/week8/include"
]
```

但我更推荐 `compile_commands.json`：以后 CMake 增加 `-I`、`-D`、不同 target 的编译选项时，VS Code 会跟着真实构建走，不需要手动维护第二份 include path。