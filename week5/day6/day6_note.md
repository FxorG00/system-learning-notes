## lambda

对，C++ lambda 的完整基础形状就是：

```
[capture](parameters) -> return_type {
    function_body
};
```

例如：

```
[]() {
    std::cout << "hello\n";
};
```

各部分含义：

```
[]    capture list，捕获外部变量
()    parameter list，参数列表
{}    function body，函数体
```

最简单时，空参数列表 `()` 可以省略：

```
[] {
    std::cout << "hello\n";
};
```

但上面只是创建了一个 lambda object，还没有调用。可以这样调用：

```
auto task = [] {
    std::cout << "hello\n";
};

task();
```

也可以立即调用：

```
[] {
    std::cout << "hello\n";
}();
```

你 Day5/Day6 常见的写法：

```
int counter = 0;

auto task = [&counter]() {
    ++counter;
};
```

意思是：

```
[&counter]  按引用捕获外面的 counter
()          不接收调用参数
{}          执行 ++counter
```

传给 thread：

```
std::thread worker(task);
```

新 thread 会调用这个 lambda。注意最后的分号属于 lambda 表达式所在的 C++ statement，不属于 `{}` 函数体。

## std::thread

`std::thread` 用来创建一个新的线程，让某个函数与当前线程并发执行。

```
#include <iostream>
#include <thread>

void work(int id) {
    std::cout << "worker " << id << '\n';
}

int main() {
    std::thread worker(work, 1);  // 创建线程，执行 work(1)

    // main 线程可以继续做其他事情
    std::cout << "main thread\n";

    worker.join();  // 等待 worker 执行结束
    return 0;
}
```

编译时需要加 `-pthread`：

```
g++ -std=c++17 -Wall -Wextra -g main.cpp -pthread -o main
```

也可以传入 lambda：

```
int value = 10;

std::thread worker([value]() {
    std::cout << value << '\n';
});

worker.join();
```

最重要的是理解这几个接口：

- `std::thread t(function, arguments...)`：创建线程，在线程中调用函数。
- `t.join()`：当前线程等待 `t` 结束。
- `t.detach()`：让线程脱离管理、独立运行，初学阶段尽量少用。
- `t.joinable()`：检查线程是否还能执行 `join()` 或 `detach()`。

特别注意：一个仍然处于 `joinable` 状态的 `std::thread` 对象如果直接析构，程序会调用 `std::terminate()`：

```
int main() {
    std::thread worker([] {
        std::cout << "hello\n";
    });

    // 没有 worker.join()，程序会异常终止
}
```

你目前可以先把它理解成：

```
创建 std::thread
      |
      v
新线程开始执行指定函数
      |
      +---- main 线程继续运行
      |
main 调用 join()
      |
      v
等待新线程结束，再继续
```

`join` 的英文原意是“汇合”：新线程执行完之后，与等待它的线程重新汇合。

## std::thread 会复制一份副本供自己使用

报错原因是：`std::thread` 默认会把传入的参数复制一份副本，到线程对象内部去使用，并不会自动保留引用。

你的函数要求：

```
void task(int& i, std::mutex& mutex_lock)
```

但这里：

```
workers.emplace_back(task, i, mutex_lock);
```

`std::thread` 会尝试保存：

- `i` 的副本
- `mutex_lock` 的副本

而 `std::mutex` 禁止拷贝；同时保存后的参数也无法按普通的 `int&`、`std::mutex&` 传给 `task`，所以出现：

```
std::thread arguments must be invocable after conversion to rvalues
```

你的线程编号其实不需要引用，推荐改成按值传递；只有互斥锁使用 `std::ref` 显式传引用：

```
#include <functional>

void task(int i, std::mutex& mutex_lock) {
    std::lock_guard<std::mutex> guard(mutex_lock);

    std::cout << "worker " << i << '\n';
    // ...
}

int main() {
    int thread_count = 3;
    std::vector<std::thread> workers;
    std::mutex mutex_lock;

    for (int i = 1; i <= thread_count; ++i) {
        workers.emplace_back(task, i, std::ref(mutex_lock));
    }

    for (std::thread& worker : workers) {
        worker.join();
    }
}
```

`std::ref(mutex_lock)` 的意思是：

```
不要复制 mutex_lock
请在线程中使用原来的 mutex_lock
```

不要对循环变量 `i` 使用 `std::ref(i)`。否则三个线程都会引用同一个循环变量，而主线程还会不断修改它，可能产生数据竞争，甚至在线程访问前它已经离开作用域。

因此这里正确的参数语义是：

```
线程编号 i：每个线程保存自己的值
mutex_lock：所有线程引用并共享同一把锁
```

## 验收问题

### 问题 1

program、process、thread 分别是什么？为什么说 process 更像资源容器，而 thread 更像 execution flow？

program 是程序 磁盘上的 executable/code 与静态内容，本身不是正在执行的实体

process 是正在运行的 program 实例，是进程

thread 是线程，process 内部一条可以独立执行的 execution flow

process 为 thread 提供资源，比如其 address space。

CPU 的 core 每次选择 thread 去运行。

### 问题 2

同一 process 内的 threads 共享什么？至少列出四项。每个 thread 私有或独立的执行状态又有哪些？

全局区 静态数据区 代码区 Heap

stack, PC, SP

### 问题 3

为什么同一 process 的 workers 得到相同 PID、不同 TID？为什么它们看到相同 global/heap virtual address，却看到不同 local variable address？

因为不同 workers 是不同 thread，TID 自然不同，但是都属于当前这个 process，所以 PID 相同。

前者是共享的，后者是每个 thread 私有的，因为是在 stack 上的数据。

### 问题 4

timer interrupt 在 preemptive scheduling 中负责什么？它为什么不是 scheduler 本身？

负责让当前 thread 进入 kernel，去做检查和决策

因为它本身并不会去让选择 rannable 的 execution flow 去执行，只是负责上述内容。

### 问题 5

从 P1 user mode 被 timer interrupt 打断，到 P2 user mode 恢复，按顺序说出主路径。`trapframe` 与 xv6 `context` 分别保存哪一层状态？

```text
1. P1 user mode 被 timer interrupt 打断
2. P1 user mode 进入 uservec，保存 P1 user registers 到 P1 的 trapframe，切换到 P1 的 kernel stack
3. 进入 usertrap
4. 进入 devintr 去识别出是 timer interrupt
5. 执行 timer interrupt 对应操作，回到 usertrap
6. yiled(),P1.state=RUNNABLE
7. sched()
8. swtch()
9. 进入 scheduler 的 thread
10. swtch(&scheduler.context,&P2.context)
11. 恢复 P2 执行
12. 从 P2 上一次 swtch 接着往下执行
13. P2 接着执行 sched()
14. P2 接着执行 yiled()
15. P2 执行完 usertrap,usertrapret,userret
16. 恢复 P2 的 user registers，从 trapframe 当中，切换成 P2 的 user stack
17. P2 接着执行 user mode 中的 instruction

trapframe 负责保存一个 execution flow trap之后返回 user mode 能继续执行指令的信息状态
context 负责保存一个 execution flow 被切换后，下次再执行到，能成功恢复继续执行的信息状态
```

### 问题 6

context switch 为什么不需要复制整个 stack、heap 和 globals？切换 `SP` 有什么意义？

这些都是 memory 里的，不会动。

让 CPU 改用目标线程的 kernel stack，从而恢复它的函数栈帧、局部变量和调用链。

### 问题 7

scheduler 与 context switch 分别解决什么问题？一次 trap 为什么不一定导致 thread context switch？

scheduler 去选择 runnable 的 execution flow 去执行

context switch: 保存旧 execution flow 的信息；恢复新 execution flow 信息；ret 到 RA 接着执行

比如 trap 是 system call 请求引起的，而不是 timer interrupt

trap 只是进入 kernel，但是 kernel 的决策未必是 switch

### 问题 8

xv6 为什么要让 `p->lock` 覆盖 `RUNNING -> RUNNABLE`、保存 context、停止使用旧 kernel stack 这一整段状态变化？

避免被别的 CPU 观察到，比如 P1 已经 RUNNABLE 了，但是旧 CPU 仍然在 P1 kernel stack 上，那 P2 选择 P1 去执行，两个 CPU 用同一个 kernel stack。