# Week5 Day2 Note：Trap 与 ECALL

> 本笔记根据我对 Day2 内容的 5 分 31 秒口述整理。主线保留我的理解方式；英文术语和少量不精确表达由 Codex 校正。 [2026年07月23日 下午08点47分(1).m4a](..\..\..\..\Downloads\2026年07月23日 下午08点47分(1).m4a) 

## 1. 我抓住的核心问题

Week4 已经学过一次 system call request 的基本流程。今天进一步学习的是：

```text
user program 不能直接进入 kernel，
一次 system call 怎样通过 trap mechanism，
受控地从 U-mode 进入 S-mode？
```

普通 function call 只能在当前 privilege mode 下跳到另一个 instruction address，不会自动提升 privilege，也不能让 user code 任意进入 kernel handler。

RISC-V 的 `ECALL` 是 ISA 规定的特殊 instruction。U-mode 执行 ECALL 会产生一次同步 exception，并通过统一的 trap mechanism 进入 kernel 预先设置的可信入口。

因此：

```text
ECALL 不等于直接调用 sys_write。
ECALL 只负责产生一次受控 trap。
```

## 2. 我理解的 xv6 Shell `write` 主路径

xv6 Shell 在 U-mode 中执行：

```c
write(fd, buffer, length);
```

这里的 `write` 是 user-space wrapper。它先按照 RISC-V calling convention 准备：

```text
a0 = fd
a1 = buffer address
a2 = length
a7 = SYS_write，也就是 system call number
```

然后沿下面的路径执行：

```text
xv6 Shell user code
-> write wrapper
-> ECALL
-> CPU 产生 trap
-> stvec 指向的 uservec
-> uservec 保存 user state，准备 kernel environment
-> usertrap 根据 scause 判断 trap 原因
-> syscall dispatcher 根据保存下来的 a7 找到 sys_write
-> sys_write 完成真正的 write 请求
-> 准备返回 user code
```

具体怎样从 kernel 安全返回 U-mode，留到 Day3。

## 3. ECALL 前后的状态

### ECALL 之前

```text
privilege mode = U-mode
PC = ECALL instruction address
a0/a1/a2 = write arguments
a7 = SYS_write
SP = Shell 的 user stack pointer
satp = 当前 user page table
stvec = kernel 预先设置的 trap entry address
```

### 执行 ECALL 时，CPU hardware 自动完成

```text
sepc：
    保存引发 trap 的 ECALL instruction address。

scause：
    记录这是一次来自 U-mode 的 Environment Call exception。

stval：
    保存 exception 的补充信息；对这次 ECALL，值为 0。

sstatus：
    记录 trap 前的 privilege / interrupt state，
    并按 trap 规则更新相关状态。

privilege mode：
    从 U-mode 改为 S-mode。

PC：
    从 stvec 中取得 supervisor trap entry address。
```

### ECALL 刚结束时，hardware 没有自动完成

```text
general-purpose registers：
    a0/a1/a2/a7 等仍是 user values。

SP：
    仍然指向 Shell 的 user stack，
    没有自动切到 kernel stack。

satp：
    仍然指向原来的 user page table，
    没有自动切到 kernel page table。

全部 user state：
    没有被 CPU 自动完整保存。
```

所以后续仍需要 software trap entry 保存 registers，并准备 kernel stack 和 kernel page table。

## 4. trampoline、uservec 与 `sscratch`

### trampoline

xv6 把 trampoline page 映射到每个 user page table 的同一 virtual address。ECALL 刚结束时 `satp` 还没改变，因此 CPU 仍必须在原来的 user page table 下找到最早期 trap code。

这段 mapping 没有设置 `PTE_U`：

```text
U-mode：
    虽然 page table 中有 mapping，但不能执行。

S-mode：
    ECALL 提升 privilege 后，可以执行其中的 supervisor entry code。
```

更精确的说法是：

```text
stvec 指向 trampoline page 中的 uservec entry，
而不是“trampoline 是一条 instruction”。
```

### `sscratch`

`sscratch`：Supervisor Scratch，是 supervisor trap entry 最早期使用的 CSR。

xv6 在返回 user mode 前，预先让 `sscratch` 保存 trapframe address。进入 `uservec` 后，第一条关键操作会交换 `a0` 和 `sscratch`：

```text
交换前：
    a0 = user 的第一个 argument value
    sscratch = trapframe address

交换后：
    a0 = trapframe address，可作为最早期安全工作 register
    sscratch = 原来的 user a0，user value 没有丢
```

因此，`sscratch` 不是自动分配一块 memory；它保存的是 kernel 预先准备好的信息，帮助 entry code 在所有 general registers 都装着 user state 时找到安全落脚点。

## 5. Trap 是 system call 的上位机制

我在口述中说到了“ECALL 是 trap 的来源之一”。完整关系是：

```text
system call：
    user program 主动执行 ECALL，
    产生 synchronous exception，再进入 trap。

exception：
    当前 instruction 同步引发的异常，
    例如 ECALL、page fault。

interrupt：
    timer 或 device 等异步事件。

trap：
    kernel 统一接住 system call、exception 和 interrupt 的上位机制。
```

## 6. CPU 和 register 的最小硬件模型

CPU 会不断重复：

```text
根据 PC 找到 instruction
-> fetch
-> decode
-> execute
-> 更新 PC 和其他 CPU state
```

`PC` 的全称是 Program Counter，不是 Program Count。

`register` 是 CPU 能直接使用的一小组 architecture-visible state slot，可以承担通用运算、传参或特殊控制用途。

```text
general-purpose register：
    例如 a0/a1/a2/a7、sp。

CSR：
    例如 stvec、sepc、scause、sstatus、sscratch、satp，
    用来控制或记录 privilege、trap 和 address translation 等状态。
```

## 7. Mode switch 不等于 context switch

一次 system call 中：

```text
mode switch：
    当前 xv6 Shell 的执行流从 U-mode 进入 S-mode，
    kernel 仍在代表同一个进程处理它自己的请求。

context switch：
    CPU 从一个 process/thread 的 execution context，
    切换去运行另一个 process/thread。
```

因此，执行 ECALL 一定涉及 privilege mode change，但不意味着立刻发生 process switch。

## 8. `strace` 的证据边界

Day2 的对照命令是：

```bash
strace -e trace=write /bin/echo trap-day2
```

它能够直接显示：

```text
Linux process 发起了哪次 write system call
write 的 fd、buffer 摘要和 length
kernel 返回了什么结果
```

它不能直接显示：

```text
xv6/RISC-V 的 stvec、sepc、scause 等 CSR 如何变化
uservec 汇编保存了哪些 registers
Linux 内部是否使用与 xv6 完全相同的 entry path
```

本次口述没有提供实际 `strace` 输出，所以这里只记录证据边界，不把命令结果伪装成已经观察到的个人实验。

## 9. 口述验收结果

| 验收点 | 口述情况 | 结论 |
|---|---|---|
| 普通 call 与 ECALL 的 privilege 差异 | 抓住了“安全进入 S-mode”，但普通 call 为什么不行说得较少 | 基本正确，笔记已补全 |
| trap / system call / exception / interrupt | 说出 ECALL 是 trap 来源之一，没有展开另外两类 | 部分覆盖，笔记已补全 |
| ECALL 前的 arguments、mode、SP、satp | arguments 和 register 关系讲清楚了 | 正确 |
| ECALL 后 changed / unchanged state | 能区分 CSR/mode/PC 的变化与 registers/SP/satp 不变 | 正确 |
| trampoline 为什么可达但 U-mode 不可执行 | 能说出每个 user page table 都有 mapping，并受 permission 限制 | 正确 |
| 七个 CSR 的第一层责任 | 口述涉及主要 CSR，但连续缩写表达不够稳定 | 主线正确，需继续用“解决什么问题”记忆 |
| mode switch / context switch / strace 边界 | 录音没有覆盖 | 未作答，笔记已补充 |

## 10. 今日一句话

```text
xv6 Shell 的 write wrapper 把 arguments 和 system call number 放进 registers，
再用 ECALL 产生一次受控 trap；
CPU 只完成必要的 privilege、PC 和 CSR 更新，
保存完整 user state、切换 kernel environment 并分派到 sys_write，
仍然是 trampoline/uservec/usertrap 等 kernel software 的工作。
```
