## 练习一

```text
pipe 创建管道成功的会会把 read end 填入 pipefd[0]，把 write end 填入 pipefd[1]

那我应该先 pipe 再 fork，这样 pipe 出来的 pipefd 在子进程中也有一份，然后指向的仍然是同一个 kernel 里面的 pipe read_end,write_end

然后注意在父子进程中不用到的就立刻关闭即可。

利用 unique_fd 来管理 parent 的 write end，child 的 read end。

然后一些可以重复使用的，我就 copy 了之前的代码，什么 waitpid_retry,write_all

需要注意的是，你直接 write 一个 "hello" 的话，实际上过去 6 个字节，多了一个 \0，所以你要限制 sizeof(data)-1。
因为是字节流。

```

## 练习二

### bg

这次不让 child 自己写 payload。child 要把 stdout 接到 pipe，然后用 `exec` 变成另一个程序；parent 从 pipe 捕获新程序的输出。

这对应 1.10 的思想，只是把输出目标从文件替换为 pipe：

```text
课程：echo fd 1 -> output.txt
今天：echo fd 1 -> pipe write end -> parent
```

### idea

```text
先 pipe，再 fork

parent 作为 reader
child 作为 writer

把 parent 的 pipefd[1](write_fd) 关闭了，然后还是用 Uniquefd 去管理 read_fd

child 的话，先关闭 read_fd，再 dup2(source,destination)，让 stdout 也指向 write_end 的那个 fd，然后 close write_end。
接下来就 execlp，把 child process 替换成另一个程序 echo。
那么现在 echo 输出到 fd 1 实际上就是输出到 pipe了，我在 parent 那边读取即可。

然后 child process 执行完程序了之后会退出，在 parent 那里 wait 即可。
```

