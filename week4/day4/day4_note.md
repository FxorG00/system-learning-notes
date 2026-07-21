## dup2

```text
::dup2(source_fd,destination_fd);

让 destination_fd 指向 source_fd 指向的 open file descriptor

需要注意的是，还是跟 day3 一样，只要一个 open file descriptotr 还有 fd 指向它，那么他就不会被释放。

前：
进程 fd 表

0 → 终端输入对应的 open file description
1 → 终端输出对应的 open file description
2 → 终端错误对应的 open file description
3 → redirected.txt 对应的 open file description

后：
0 → 终端输入对应的 open file description
1 ─┐
   ├→ redirected.txt 对应的 open file description
3 ─┘
2 → 终端错误对应的 open file description
```

## 输出

```text
输出都是往 fd 1 输出，但是我们可以把 fd 1 从 terminal 改为某个文件，从而达到 redirect 的效果。

std::cout 和 printf 可能有用户态输出缓冲
→ 写了输出表达式，不一定代表系统调用已经发生

std::cout 用 C++ 的 flush 接口
printf/stdout 用 fflush(stdout)

dup2 改变的是 fd 表，不会自动替你处理旧的用户态缓冲
→ 改变底层 fd 前，先 flush 应该送往旧目标的数据

write 直接进行系统调用
→ 它不经过 std::cout 或 stdout 的用户态缓冲
```



## 验收问题

```text
1. STDIN_FILENO、STDOUT_FILENO、STDERR_FILENO 分别是什么英文，值通常是多少？
stdin file number 0
stdout file number 1
std error file number 2


2. fd 1 为什么默认输出到终端？数字 1 本身有“终端输出”能力吗？
因为 fd 1 默认就是指向终端的。
不是，是 fd 1 默认指向终端，你把 fd 1 让他 redirect 到别的文件，那么也会输出到别的文件上。

3. std::cout、stdout、STDOUT_FILENO 分别是什么类型或哪一层对象？
std::cout 是 std::ostream 对象
stdout 是 FILE*
STDOUT_FILENO 是 fd 1，就是 1 这个数字，是个 define

4. dup(oldfd) 和 dup2(oldfd, newfd) 在选择新 fd 数字上有什么区别？
dup(oldfd) 是给你返回一个新的 fd，你没办法指定。
后者是返回 newfd（如果成功）
然后效果都是两个 fd 指向 oldfd 指向的 open file descriptor

5. dup2(output_fd, STDOUT_FILENO) 中，谁是来源，谁是被改写的目标？
output_fd 是 source
后者是被改写的目标。

6. 如果 STDOUT_FILENO 原本已经指向终端，dup2 成功时原关系怎样了？
啥意思？fd 1 不是原本默认指向终端吗？dup2 就是让 fd 1 指向别的 open file descriptor 啊

7. dup2 成功后，output_fd 与 fd 1 共享什么？
二者指向同一 open file descriptor
所以共享 offset 和 file status flags

8. 为什么 dup2 成功后可以关闭原 output_fd，而 fd 1 仍然有效？
上面说了 因为共享的 open file descriptor 还存在

9. 今天的代码为什么在 dup2 前 flush std::cout？
因为想观察 redirect 前输出到 terminal 上，所以先 flush，让其能够观察到，不然可能在用户态缓冲区里

10. fd 1 被重定向后，为什么 std::cout、printf 和 write(1, ...) 都进入文件？
因为这些都是输出到 fd 1 指向的文件对象的，然后 fd 1 被重定向了。

11. 为什么 perror / fprintf(stderr, ...) 仍显示在终端？
stderr 仍然是指向 terminal

12. dup2 的 oldfd 无效时会怎样？合法的 newfd 会先被关闭吗？
不会 那就 dup 失败

13. dup2(oldfd, oldfd) 在 oldfd 合法时会怎样？
就啥也不做啊

14. 为什么 close(newfd) 再 dup(oldfd) 不如 dup2(oldfd, newfd) 明确可靠？
跟 atomic 有关 具体的我也不知道

15. strace 中哪几类调用能证明重定向已经建立并被使用？
dup2 跟 write

16. lsof 或 /proc/<PID>/fd 中，什么现象能证明只有 stdout 被重定向？
不会

17. 用自己的话解释 Shell 的 command > output.txt 为什么不要求 command 修改输出代码。
command 默认输出到 fd 1
那我只要 redirect fd 1 就好了！就能让他输出到文件了
```

