## fd,mmap 区别

```text
read/write：每次请内核搬运文件数据，是有一个 fd->open file description->文件对象的过程的。每次什么读取的时候又有个 offset。

mmap：先让内核建立“虚拟地址和文件区间”的关系，之后像访问内存一样访问，跟数组一样进行访问。
就是在当前 process 的虚拟地址里多了一段 mapping 到对应文件。
通过首地址+长度来确定。
```

## system call 的发生过程

```text
用户代码调用 mmap() 包装函数
-> 包装函数准备 system call number 和参数
-> 包装函数执行 ECALL（RISC-V）或 syscall（x86-64）指令
-> CPU 切换到 kernel mode，并跳到内核规定的统一入口
-> 内核根据 number 分派到具体系统调用实现
-> 内核检查参数、权限和当前进程状态
-> 内核执行请求
-> 内核放好返回值
-> CPU 恢复 user mode，从特殊指令之后继续执行
-> 包装函数把结果返回给你的 C++ 代码
```

## 验收问题

1. `read` 文件与 `mmap` 文件在程序使用方式上的核心区别是什么？

   read 是通过 fd，每次请内核搬运数据，然后将字节读到用户态程序内存里的 buffer。

   mmap 就是在 process 的虚拟地址里增加一个 mapping，之后就像访问内存一样了，就首地址+长度。

2. 为什么 `mmap` 失败要比较 `MAP_FAILED`，而且空文件不能直接按 length 0 映射？

   因为 mmap 失败返回的不是 nullptr。

   因为空文件没有字节需要映射啊，自然没有什么首地址之类的。

3. `mmap` 成功后为什么可以关闭 fd？`munmap` 后原地址又为什么不能继续使用？

   因为 mmap 成功后就在当前 process 的虚拟地址里多了一个 mapping，是不依赖于 fd 的。

   munmap 后解除 mapping，原地址失效了。

4. `MAP_PRIVATE` 与 `MAP_SHARED` 的第一层区别是什么？

   PRIVATE：私有，对映射的修改不写回源文件

   SHARED：修改可以对其他共享映射可见，并且可以反映到底层文件。

5. `SIGINT`、`SIGTERM` 分别表达什么？为什么 signal handler 不能简单当作普通函数调用理解？

   SIGNAL INTERRUPT，打断

   SIGNAL TERMINATE：终止

   你也没细说，说是后面会提到。

6. 用户程序不能直接执行特权指令时，system call 怎样把请求受控地交给内核？

   上面有。

## Q：

```text
我们之前说的 system call 不是那个 user space 跟 kernel 间交互的 interface 吗？
那我看这里的 system call 是 kernel 在执行的，内核执行请求，应该是一个请求，这个 system call
```

### 回答

你之前的理解没有错：**system call 是 user space 请求 kernel 提供服务的受控接口。**

这里容易混淆，是因为“system call”在日常表达中常被同时用来指：

```text
1. 系统调用接口：
   user space 与 kernel 交互的规则和入口。

2. 一次系统调用请求：
   某个进程这一次请求内核执行 mmap、read、fork 等服务。

3. 内核中的系统调用处理：
   进入 kernel 后，内核根据 system call number 找到并执行对应处理函数。
```

以 `mmap()` 为例：

```text
用户空间的 mmap() 包装函数
-> 准备 system call number 和参数
-> 通过 ECALL/syscall 指令进入 kernel
-> 内核执行 mmap 对应的处理函数
-> 返回结果给用户空间
```

因此更准确地说：

```text
system call interface：规定用户程序怎样向内核提出请求
system call invocation：当前发生的这一次具体请求
kernel handler：内核中真正检查参数并完成工作的代码
```

“内核执行 system call”是一种常见简写。严格来说，是**当前进程的执行流进入 kernel mode，内核代表该进程执行对应的 system call handler**。

所以 system call 不只是一个孤立的“请求”，而是整套受控调用机制；`system call number + arguments` 才是这次调用交给内核的具体请求内容。

