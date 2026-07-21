## MIT 6.S081

```text
最小 fork 示例为什么产生 parent 和 child 两份输出
fork 就是分叉。
parent process 调用完 fork 后，就会产生一个 child process 也在接着执行一模一样的代码。
然后运行到下面的 if，因为 parent process 的 fork() 返回值为 child pid，所以 >0，输出 parent。然后 child process 的 fork 返回值为 0，输出 child。

为什么两边用不同返回值进入不同分支
用于区分是 parent/child process

为什么父子输出可能交织
父子内存和 fd 继承分别是什么关系
fork 完相当于两个进程。
父子进程拥有独立的地址空间，然后初始的内容是相同的。
然后 fd 表也会复制一份给 child。

为什么 Shell 需要 fork 后让 child exec，而不是自己 exec？
你自己 exec 的话，那么原先的 shell 就完全被替换成另一个程序了，你就没办法再输入命令了。


parent 的 wait 等待什么、得到什么？
wait 是在等待子进程结束并 exit。得到子进程的 status，并且 waite 会返回子进程 PID，并且取得退出状态。

exec 失败时为什么会走到 exit(1)
因为就是没有替换 child process 执行的 shell 这个程序，所以失败了就接着往下执行。

为什么 wait 不能用来等父进程。
wait 的对象是当前进程的子进程。

为什么 N 个 child 通常需要 N 次成功 wait
一个 wait 等待一个 child process 的结束。所以需要 N 个。

为什么 COW 能优化 
fork 后立刻 exec 的场景。
因为我们 fork 出子进程后，会复制大量内容。再 exec 会丢弃他们，很浪费。
```

## fork

我觉得 fork 是很形象的。

就是一个代码执行到 fork 的时候分叉了！

然后两叉都在 fork 返回处接着往下执行代码。

然后利用 fork() 返回值区分父子进程。

![img](day5_note.assets/8ab5041eb4e7cd25ea6cf489ade9524e_720.png)