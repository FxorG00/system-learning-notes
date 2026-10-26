# 教程技术图：本地可复现工作流

## 1. 为什么选 D2

教程里的计算图、对象关系、生命周期和多阶段因果链，常常需要比纯文字更直观的结构。这里使用 D2 保存**可版本控制的文本源图**，再导出 Typora 能直接显示的 SVG。

当前分工：

| 内容 | 默认工具 | 原因 |
|---|---|---|
| 简单流程、分支、循环 | Markdown 内 Mermaid | 与正文放在一起，适合快速维护 |
| 计算图、对象关系、多面板状态对照 | D2 源文件 + SVG | 布局、颜色和分组更稳定，SVG 清晰且可重复生成 |
| loss 曲线、benchmark、真实数值图 | Matplotlib 等数据绘图工具 | 图必须由真实数据产生 |
| 实物、界面、硬件外观 | 合法来源图片或原创位图 | 代码式框图不能替代需要观察的真实对象 |

图不是装饰。只有当图能让读者看清**对象、关系、方向或状态变化**时才加入；图后必须用一两句说明该看什么，以及它怎样承接上下文。

## 2. 本地工具

已下载官方 D2 `v0.9.0` Windows AMD64 预编译包到：

```text
.tools/d2/d2-v0.9.0/bin/d2.exe
```

下载包的 SHA256 已按官方 `SHA256SUMS` 核对：

```text
5f63b643de8f5a6dfb922d172e1b5496e4caf47497c33c4427cf1127f28c340f
```

`.tools/` 是本机工具目录，不提交第三方二进制。教程中的 `.d2` 源文件和生成后的 `.svg` 继续提交，其他机器即使没有 D2 也能直接阅读教程。

官方资料：

- [D2 安装说明](https://d2lang.com/tour/install/)
- [D2 导出 SVG/PNG](https://www.d2lang.com/tour/exports/)
- [D2 GitHub releases](https://github.com/d2lang/d2/releases)

## 3. 生成图

在仓库根目录执行：

```powershell
powershell -ExecutionPolicy Bypass -File reference_materials/diagram_tools/render_d2.ps1 `
  -InputPath ai_theory/T11/images/computation_graph.d2
```

默认在源文件旁生成同名 `.svg`。脚本固定使用 `--scale=1`，让 SVG 最外层带有明确的宽高；这样 Typora 和浏览器把它作为 Markdown 图片加载时，不会退回过小的默认尺寸。也可以显式指定输出：

```powershell
powershell -ExecutionPolicy Bypass -File reference_materials/diagram_tools/render_d2.ps1 `
  -InputPath ai_theory/T11/images/computation_graph.d2 `
  -OutputPath ai_theory/T11/images/computation_graph.svg
```

生成后至少检查：

1. D2 退出码为 0。
2. SVG 能解析，根 `viewBox` 和最外层 `width`、`height` 都是非零值。
3. 图中文字、箭头和正文结论一致。
4. 在 Typora 或等价浏览器预览中没有裁切、重叠和横向溢出。
