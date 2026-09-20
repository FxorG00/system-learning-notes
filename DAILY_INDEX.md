# Daily 教程总目录

> 更新日期：2026-09-21
>
> 收录范围：主线 Week1 Day1 至 Week11 Day1，共 71 份正式 daily 教程。
>
> 用途：快速定位“某个知识点在哪一天学过、当天写了什么、应该回看哪份教程”。

这份文件只做索引，不替代：

```text
plan_strengthened.md：总路线与求职里程碑
weekN/weekN.md：每周目标、范围与七天依赖
weekN/dayN/dayN.md：完整教程
dayN_note.md：你的理解、实验和验收证据
MEMORY.md：长期规则、进度与历次检阅结论
```

说明：

```text
Week1 Day7 的 backup 文件不重复收录
Week8 Day7 的 README 不是 daily，不单独收录
Week1 到 Week10 已通过
Week11 Day1 已正式通过；下一步为 Week11 Day2
```

---

## 一眼看主线

| 阶段 | 周 | 主线内容 |
|---|---|---|
| C++ 对象与资源 | [Week1](#week1c-对象内存与深拷贝) | 指针、类、生命周期、裸内存、深拷贝、RAII |
| 现代 C++ 所有权 | [Week2](#week2移动语义智能指针与异常安全) | move、Rule of Five、智能指针、异常安全 |
| STL 与数据结构 | [Week3](#week3stl-容器与小型数据结构) | vector、iterator、string、map、hash、RingBuffer、LRU |
| Linux 系统编程 | [Week4](#week4linux-fd文件进程与-ipc) | fd、文件 I/O、dup、fork、exec、pipe、mmap |
| OS 机制与同步 | [Week5](#week5虚拟内存trap调度与同步) | 虚拟内存、trap、page fault、thread、mutex、sleep/wakeup |
| 网络与 TCP/HTTP | [Week6](#week6网络路径tcp-与-http) | link/IP/route、UDP、TCP socket、可靠传输、HTTP framing |
| 并发组件 | [Week7](#week7线程同步blockingqueue-与-atomic) | thread lifecycle、mutex、condition variable、BlockingQueue、atomic |
| ThreadPool 工程化 | [Week8](#week8threadpoolasynclogger-与工程证据) | task/future、ThreadPool、GoogleTest、CMake、AsyncLogger、benchmark |
| non-blocking 与 epoll | [Week9](#week9non-blocking-ioepoll-与事件驱动-server) | EAGAIN、epoll、per-connection state、dynamic EPOLLOUT、LT/ET |
| Reactor V1 | [Week10](#week10reactor-v1) | Buffer、Channel、EventLoop、Acceptor、Connection，继续加固 callback lifetime |
| HTTP Server V1 | [Week11](#week11http-server-v1) | incremental request parser、response encoder、Reactor integration、keep-alive |

---

# Week1：C++ 对象、内存与深拷贝

| Day | 主要内容 | 主要产出 / 观察 | 检索关键词 |
|---|---|---|---|
| [Day1：开发环境](week1/day1/day1.md) | VMware Ubuntu 与 Windows VS Code Remote SSH；安装 C++ toolchain，第一次使用 gdb、CMake 与 Git | 可远程编译、运行、调试 C++ 的学习仓库 | Ubuntu, SSH, VS Code, g++, gdb, CMake, Git |
| [Day2：指针、引用与 const](week1/day2/day2.md) | 从变量地址建立 pointer/reference 模型；解引用、`nullptr`、const pointer 与 const reference | 指针和引用修改外部对象的基础 demos | pointer, reference, nullptr, dereference, const |
| [Day3：class 与对象生命周期](week1/day3/Day3.md) | `class/struct`、constructor、destructor、`this`、member initializer list、const member function | 观察对象构造/析构与作用域顺序 | class, struct, constructor, destructor, this, initialization order |
| [Day4：new/delete 与 RAII](week1/day4/Day4.md) | stack/heap object、`new/delete`、`new[]/delete[]`；memory leak、dangling pointer、double free；RAII 初步 | 最小资源拥有类与错误实验 | heap, new, delete, leak, dangling pointer, double free, RAII |
| [Day5：浅拷贝与深拷贝](week1/day5/Day5.md) | copy constructor 与 copy assignment 的调用场景；浅拷贝为何 double free；深拷贝与 self-assignment | Rule of Three buffer | copy constructor, copy assignment, shallow copy, deep copy, Rule of Three |
| [Day6：Buffer / StringLike](week1/day6/Day6.md) | 用 `Buffer` 和 `StringLike` 综合资源管理、深拷贝、`\0`、`strlen/memcpy` 与 assignment 顺序 | 可运行的 Buffer V1/V2 和 StringLike | Buffer, StringLike, strlen, memcpy, null terminator, exception safety |
| [Day7：Week1 出口](week1/day7/Day7.md) | 修正 owning pointer 等术语，验收最终 StringLike，串起对象生命周期与资源管理 | Week1 知识链与出口复盘 | owning pointer, ASan, Rule of Three, ownership review |

---

# Week2：移动语义、智能指针与异常安全

| Day | 主要内容 | 主要产出 / 观察 | 检索关键词 |
|---|---|---|---|
| [Day1：move 的问题来源](week2/day1/day1.md) | 深拷贝虽然安全但成本高；函数返回对象、copy elision、RVO/NRVO；建立 move 动机 | 观察 Buffer copy cost 与返回对象行为 | copy elision, RVO, NRVO, temporary, move motivation |
| [Day2：移动构造与 std::move](week2/day2/day2.md) | lvalue/rvalue/rvalue reference；移动构造接管资源；moved-from state；`std::move` 只做 value-category cast | 为 Buffer 增加 move constructor | lvalue, rvalue, rvalue reference, move constructor, std::move |
| [Day3：移动赋值与 Rule of Five](week2/day3/day3.md) | move assignment 先释放旧资源再接管；self-move；五个特殊成员函数；`noexcept` 第一层 | 完整 Rule of Five Buffer | move assignment, self-move, Rule of Five, noexcept |
| [Day4：unique_ptr](week2/day4/day4.md) | owning/non-owning pointer、unique ownership；`unique_ptr` 不能 copy 但可以 move；`make_unique` 与数组 | `unique_ptr` 版 Buffer / array demos | unique_ptr, make_unique, exclusive ownership, Rule of Zero |
| [Day5：shared_ptr / weak_ptr](week2/day5/day5.md) | shared ownership、reference count、循环引用；`weak_ptr` 不增加 strong count 并用 `lock()` 观察对象 | circular reference 与打破循环实验 | shared_ptr, weak_ptr, use_count, circular reference |
| [Day6：异常安全与 copy-and-swap](week2/day6/day6.md) | stack unwinding 与 RAII；先 delete 再 new 的破坏风险；copy-and-swap 的强异常安全思路 | 异常路径 demos 与 copy-and-swap Buffer | exception, stack unwinding, strong guarantee, copy-and-swap, swap |
| [Day7：Week2 出口](week2/day7/day7.md) | Rule of Zero、所有权选择、`noexcept` 与 `vector` 搬运策略；判断特殊成员函数需求 | Week2 ownership decision review | Rule of Zero, ownership choice, vector move, noexcept review |

---

# Week3：STL 容器与小型数据结构

| Day | 主要内容 | 主要产出 / 观察 | 检索关键词 |
|---|---|---|---|
| [Day1：vector 内存模型](week3/day1/day1.md) | contiguous storage、`size/capacity`、扩容迁移、`reserve/resize`；元素 move 是否 `noexcept` | 观察 capacity 与 `data()` 地址变化 | vector, size, capacity, reallocation, reserve, resize |
| [Day2：迭代器失效](week3/day2/day2.md) | vector 扩容与 `erase` 的 iterator/reference/pointer invalidation；安全边遍历边删除；push 与 emplace | 失效实验与安全 erase loop | iterator, invalidation, erase, push_back, emplace_back |
| [Day3：string / algorithm / optional](week3/day3/day3.md) | `string` 与 `c_str()` lifetime、`\0`、`npos`；`sort/find/lower_bound/remove_if`；`optional` 表达无结果 | string/algorithm/optional 使用练习 | string, c_str, npos, algorithm, lower_bound, remove_if, optional |
| [Day4：map / set](week3/day4/day4.md) | ordered associative containers、key order、iterator；`find/lower_bound/upper_bound` 与容器选择 | map/set 查询和范围练习 | map, set, ordered container, lower_bound, upper_bound |
| [Day5：unordered containers](week3/day5/day5.md) | hash table、bucket、load factor、rehash；平均复杂度与 invalidation；何时选 unordered | unordered_map/set 与 rehash 观察 | hash, bucket, load_factor, rehash, unordered_map |
| [Day6：RingBuffer V1](week3/day6/day6.md) | 根据 contract 独立设计固定容量环形缓冲区；head/tail/size invariant、wrap-around、empty/full | `RingBuffer` V1 | ring buffer, circular buffer, head, tail, wrap-around |
| [Day7：LRU Cache V1](week3/day7/day7.md) | `list + map` 组合；访问后移动节点、淘汰 least recently used；iterator 稳定性与 capacity | `LRUCache` V1 + Week3 出口 | LRU, list, splice, cache, eviction, iterator stability |

---

# Week4：Linux fd、文件、进程与 IPC

| Day | 主要内容 | 主要产出 / 观察 | 检索关键词 |
|---|---|---|---|
| [Day1：进入 Linux kernel](week4/day1/day1.md) | user mode 通过 system call 使用 kernel；fd table；`open/read/write/close`；`argc/argv`、`errno/perror` | `mycat.cpp`，MIT 6.S081 Lec01 对照 | syscall, fd, open, read, write, close, argc, argv, errno |
| [Day2：可靠复制与 UniqueFd](week4/day2/day2.md) | partial read/write、`EINTR`、可靠 copy loop；RAII 管理 fd；header include 与编译过程第一层 | `UniqueFd` 与 `copyfile.cpp` | partial I/O, EINTR, UniqueFd, copyfile, header, compilation |
| [Day3：元数据、偏移与共享打开状态](week4/day3/day3.md) | `stat/fstat`、inode、`st_dev/st_ino` 判断同一文件；`lseek`；`dup` 共享 open file description；硬/软链接 | 安全 copyfile、offset/dup 与 link 实验 | stat, fstat, inode, dev, lseek, dup, open file description, hard link, symlink |
| [Day4：dup2 与重定向](week4/day4/day4.md) | standard fds、`dup2` 替换 fd table entry；Shell I/O redirection；stdio/user buffer 与 kernel fd 的边界 | `redirect.c/cpp` 与输出重定向实验 | dup2, stdin, stdout, stderr, redirect, buffering, fflush |
| [Day5：fork / wait / exit](week4/day5/day5.md) | `fork` 产生两个执行流与不同返回值；fd inheritance；`wait/waitpid` 与 exit status；`return/exit/_exit` | process lifecycle 实验 | fork, parent, child, waitpid, exit status, _exit, process |
| [Day6：pipe + exec](week4/day6/day6.md) | kernel pipe buffer 与两个新 fd；fork 后关闭无用端；`dup2` 安排 stdin/stdout；`exec` 替换进程映像；parent wait | 最小两进程 pipeline | pipe, pipe buffer, dup2, exec, fork-exec-wait, EOF |
| [Day7：mmap / signal 与 Week4 出口](week4/day7/day7.md) | file-backed mapping、page-aligned offset、`MAP_SHARED/PRIVATE`；signal 初步；ECALL 与受控进入 kernel | mmap 观察与 Week4 系统调用闭环 | mmap, mapping, backing file, offset, signal, ECALL, user mode, kernel mode |

---

# Week5：虚拟内存、Trap、调度与同步

| Day | 主要内容 | 主要产出 / 观察 | 检索关键词 |
|---|---|---|---|
| [Day1：VA 到 PA](week5/day1/day1.md) | address space、virtual/physical address、page、page table、MMU、TLB；ELF segment 与 file-backed mapping | `/proc/<pid>/maps` 与 address layout 观察 | VA, PA, page table, MMU, TLB, ELF, backing file, maps |
| [Day2：ECALL 与 Trap 入口](week5/day2/day2.md) | xv6 Shell `write` 路径；user/kernel mode、CSR、`sepc/scause/stvec/sscratch`、trapframe、kernel stack | system-call trap path 梳理 | trap, ECALL, CSR, trapframe, kernel stack, uservec |
| [Day3：Trap 返回 user](week5/day3/day3.md) | `uservec -> usertrap -> syscall -> usertrapret -> userret -> sret`；保存/恢复 registers、page table 与返回值 `a0` | 完整 trap return flow | usertrap, syscall, usertrapret, userret, sret, a0, trampoline |
| [Day4：Page fault / lazy / COW](week5/day4/day4.md) | page fault cause 与 faulting VA；kernel 修复 mapping 后重试 instruction；lazy allocation、demand paging、copy-on-write | `mmap_private_cow.cpp` | page fault, lazy allocation, COW, demand paging, PTE, retry |
| [Day5：race 与 mutex](week5/day5/day5.md) | `counter++` 的 read-modify-write；data race、critical section、mutex、deadlock；TSan 能证明什么 | race/fixed counter 对照 | data race, race condition, mutex, lock_guard, deadlock, TSan |
| [Day6：thread 与 context switch](week5/day6/day6.md) | process/thread identity；PID/TID；user/kernel stack；context、scheduler、`sched/swtch`；寄存器恢复 | `thread_identity.cpp`、`ps -L` 与 `/proc/.../task` | thread, PID, TID, context switch, scheduler, stack, swtch |
| [Day7：blocking 与 wakeup](week5/day7/day7.md) | sleep/wakeup、channel、predicate、lost wakeup；condition variable 的 wait/notify 与锁内重检 | `blocking_wakeup.cpp` + Week5 出口 | blocking, sleep, wakeup, predicate, lost wakeup, condition_variable |

---

# Week6：网络路径、TCP 与 HTTP

| Day | 主要内容 | 主要产出 / 观察 | 检索关键词 |
|---|---|---|---|
| [Day1：端到端网络路径](week6/day1/day1.md) | application bytes 经 socket、TCP/IP、link、NIC、router 到对端；packet/frame 与 encapsulation | network path 流程图、`ip addr/ip route/ss` | layer, encapsulation, packet, frame, NIC, router, host |
| [Day2：MAC、IP、route 与 link](week6/day2/day2.md) | link 是一组可直接用当前 link-layer protocol 交付 frame 的 interfaces；next hop、ARP/neighbour、MAC/IP/port 分工；network byte order | `address_demo.cpp` 与 route/neighbour 观察 | link, Ethernet, MAC, IP, route, next hop, ARP, inet_pton, byte order |
| [Day3：UDP 与 DNS](week6/day3/day3.md) | datagram boundary、connectionless socket；`sendto/recvfrom` 与 peer address；DNS query 第一层 | `udp_echo_server.cpp`、`nc -u`、`dig` | UDP, datagram, sendto, recvfrom, sockaddr, DNS |
| [Day4：TCP Server 两类 socket](week6/day4/day4.md) | `socket/bind/listen/accept`；listening socket 与 connected socket；accept queue、backlog、blocking behavior | `tcp_echo_server_v1.cpp`、`ss -lntp` | TCP server, bind, listen, accept, listener, connected socket, backlog |
| [Day5：TCP client 与 byte stream](week6/day5/day5.md) | `connect`；TCP 没有 message boundary；partial I/O、`EINTR`、EOF、half-close；send/recv loop contract | `tcp_client.cpp` + robust echo pair | connect, byte stream, partial read, partial write, EOF, shutdown |
| [Day6：TCP 可靠性与状态](week6/day6/day6.md) | 三次握手与 ISN；sequence/ACK、重传、滑动窗口；flow/congestion control；四次关闭、CLOSE-WAIT、TIME-WAIT | `ss/tcpdump` 连接生命周期观察 | handshake, seq, ACK, retransmission, rwnd, cwnd, FIN, TIME-WAIT |
| [Day7：HTTP request framing](week6/day7/day7.md) | HTTP/1.1 request line、headers、空行、`Content-Length`；在 TCP byte stream 上做 incremental parsing | `http_request_parser.cpp`、curl/nc 联调 | HTTP, request line, header, Content-Length, framing, parser |

---

# Week7：线程同步、BlockingQueue 与 atomic

| Day | 主要内容 | 主要产出 / 观察 | 检索关键词 |
|---|---|---|---|
| [Day1：thread lifecycle](week7/day1/day1.md) | thread object 与 execution flow；joinable state、`join/detach`；argument copy/move、`std::ref`、result ownership | `parallel_sum.cpp` | std::thread, join, detach, joinable, std::ref, ownership |
| [Day2：mutex 保护 invariant](week7/day2/day2.md) | shared state 与 invariant；critical section、lock scope；`lock_guard/unique_lock`；锁保护关系而非变量名 | `shared_invariant.cpp` | mutex, invariant, critical section, lock scope, unique_lock |
| [Day3：producer-consumer](week7/day3/day3.md) | bounded queue、backpressure；`not_empty/not_full` predicates；condition variable wait/notify 与 while 重检 | `producer_consumer.cpp` | producer, consumer, bounded queue, backpressure, predicate, notify |
| [Day4：BlockingQueue V1](week7/day4/day4.md) | 把 producer-consumer 封装为 header-only `BlockingQueue<T>`；capacity、MPMC、template 第一层 | `blocking_queue.hpp` 与 tests | BlockingQueue, MPMC, template, push, pop, capacity |
| [Day5：close / drain](week7/day5/day5.md) | OPEN/CLOSED lifecycle；close 唤醒 blocked producers/consumers；剩余 items drain；graceful shutdown 与 join-before-destruction | BlockingQueue V2 | close, drain, notify_all, graceful shutdown, lifecycle |
| [Day6：atomic 与 CAS](week7/day6/day6.md) | atomic read-modify-write、sequential consistency、`compare_exchange`；atomic counter 可替代 mutex 的边界 | `atomic_counter.cpp`、`cas_max.cpp` | atomic, RMW, CAS, compare_exchange, seq_cst |
| [Day7：contention / false sharing](week7/day7/day7.md) | correctness 与 performance 分离；lock contention、cache line、false sharing；可重复 timing | `contention_false_sharing.cpp` + Week7 复检 | contention, cache line, false sharing, benchmark, median |

---

# Week8：ThreadPool、AsyncLogger 与工程证据

| Day | 主要内容 | 主要产出 / 观察 | 检索关键词 |
|---|---|---|---|
| [Day1：task abstraction](week8/day1/day1.md) | callable 被 type-erasure 成统一 task；queue 保存未来 work；worker loop 取出并执行；task/result lifetime | `task_dispatch_demo.cpp` | callable, std::function, task, type erasure, worker loop |
| [Day2：ThreadPool V1](week8/day2/day2.md) | ThreadPool 拥有 workers 与 BlockingQueue；`submit`、bounded backpressure、queue close、drain、join 与 destructor | `thread_pool.hpp` + V1 tests | ThreadPool, submit, worker, shutdown, drain, queue capacity |
| [Day3：future 与 exception](week8/day3/day3.md) | generic submit 的 return type；`bind`、`packaged_task`、future/shared state；worker exception 回到 submitter；move-only task bridge | result-returning ThreadPool | packaged_task, future, shared state, invoke_result, bind, exception |
| [Day4：GoogleTest / CMake / TSan](week8/day4/day4.md) | 把 contract 变成 deterministic executable oracle；fixture/gate；CMake target 与 CTest 汇总；stress 与 TSan 边界 | ThreadPool test suite 与构建入口 | GoogleTest, CMake, CTest, deterministic test, gate, TSan |
| [Day5：AsyncLogger V1](week8/day5/day5.md) | producer 把 records 交给 bounded queue，single writer 独占 output stream；close/drain 与 writer lifetime | `async_logger.hpp/.cpp` + basic tests | AsyncLogger, producer, single writer, log queue, flush, shutdown |
| [Day6：logger evidence / benchmark](week8/day6/day6.md) | accepted/rejected/file accounting oracle；backpressure 与 shutdown 交错；同步/异步日志的 producer-visible 和 end-to-end 性能比较 | lifecycle tests + benchmark | accounting, benchmark, latency, throughput, saturation, median |
| [Day7：组件集成](week8/day7/day7.md) | ThreadPool tasks 调用 AsyncLogger；dependency/ownership、composition root 与正确 shutdown order；组合证据 | integration demo + Week8 出口 | integration, dependency, composition root, lifetime, shutdown order |

---

# Week9：non-blocking I/O、epoll 与事件驱动 Server

| Day | 主要内容 | 主要产出 / 观察 | 检索关键词 |
|---|---|---|---|
| [Day1：blocking vs non-blocking](week9/day1/day1.md) | `O_NONBLOCK` 与 open file description；`recv` 的 bytes/EOF/EAGAIN/error 四类结果；partial I/O 与 drain | `nonblocking_stream_probe.cpp` | non-blocking, fcntl, O_NONBLOCK, EAGAIN, EOF, drain, socketpair |
| [Day2：epoll readiness](week9/day2/day2.md) | I/O multiplexing；epoll instance、interest/ready list；`epoll_create1/ctl/wait`；create-register-wait-consume 模型与 LT 第一层 | `epoll_stream_probe.cpp` | epoll, readiness, interest list, ready list, epoll_ctl, epoll_wait |
| [Day3：多连接 read server](week9/day3/day3.md) | single-thread event loop 区分 listener/connection events；non-blocking `accept4` 与 recv drain；一个 idle client 不拖住其他 clients | `epoll_read_server.cpp` | event loop, accept4, accept queue, multi-client, recv drain |
| [Day4：per-connection parser state](week9/day4/day4.md) | TCP chunk 不等于 message；newline delimiter、incremental parsing；kernel buffer、temporary buffer、user input buffer 分层 | `connection_state_demo.cpp` | byte stream, framing, delimiter, incremental parser, pending input |
| [Day5：partial send 与 EPOLLOUT](week9/day5/day5.md) | per-connection output buffer 与 write offset；`send` partial/EAGAIN；只在 pending output 时关注 EPOLLOUT；backpressure 第一层 | `epoll_echo_server.cpp` V1 | partial write, output buffer, EPOLLOUT, dynamic interest, MSG_NOSIGNAL |
| [Day6：LT / ET 与 lifecycle](week9/day6/day6.md) | readiness level/transition；ET drain-to-EAGAIN；`EPOLLRDHUP/HUP/ERR`、half-close、combined bits；fd reuse 与 stale event 风险 | `lt_et_probe.cpp` + hardened echo server | LT, ET, EPOLLET, half-close, stale event, fd reuse, lifecycle |
| [Day7：Week9 evidence 收口](week9/day7/day7.md) | 用 claim/evidence/oracle ledger 整理 normal/slow/large/half-close 等证据；观察 repeated connection 前后 fd count；映射到 Reactor components | architecture flow + evidence ledger | evidence, oracle, fd leak, known limitation, Reactor mapping |

---

# Week10：Reactor V1

| Day | 主要内容 | 主要产出 / 观察 | 检索关键词 |
|---|---|---|---|
| [Day1：Buffer component](week10/day1/day1.md) | 把 Week9 的 `string + offset` 提炼为可追加、可消费的 bytes owner；read/write positions、compact/grow、contiguous peek 与 pointer lifetime | `buffer.hpp/.cpp` + focused GTest | Buffer, readable bytes, retrieve, append, offset, compact, grow |
| [Day2：Channel component](week10/day2/day2.md) | 把 fd、desired interest、current ready mask 与 callbacks 放入描述对象；combined bits 独立 dispatch；lambda capture 与 non-owning fd | `channel.hpp/.cpp` + dispatch tests | Reactor, Channel, interest mask, ready mask, callback, dispatch |
| [Day3：EventLoop component](week10/day3/day3.md) | EventLoop 拥有 epoll fd；ADD/MOD/DEL registration；`data.fd + map` stable identity；single-batch `poll_once`、EINTR 与 `timeout=-1` | `event_loop.hpp/.cpp` + delayed-readiness probe | EventLoop, registration, epoll fd, poll_once, maxevents, EINTR, infinite timeout |
| [Day4：Acceptor component](week10/day4/day4.md) | 把 listening path 从 main 抽出；Acceptor 拥有 listener 与 listening Channel；accept-drain；accepted fd 通过 move-only `UniqueFd` 移交给 server owner | `acceptor.hpp/.cpp` + 3-pending-connections probe | Acceptor, listening socket, accept4, drain, handoff, UniqueFd, backlog |
| [Day5：Connection component](week10/day5/day5.md) | Connection 接管 connected socket，在多轮 readiness events 间保存 input/output Buffer、EOF 与 desired interest；newline policy 与 transport 分离 | `connection.hpp/.cpp` + Reactor Echo Server V1 | Connection, input Buffer, output Buffer, dynamic EPOLLOUT, half-close, application policy |
| [Day6：callback lifetime hardening](week10/day6/day6.md) | 区分 close request、same-record dispatch、整个 epoll batch 与 object destruction；deferred cleanup、stale record、fd reuse 和 identity | deterministic lifetime probe + Reactor V1 lifetime hardening | callback lifetime, self-destruction, deferred cleanup, stale event, fd reuse, generation token |
| [Day7：Reactor V1 出口](week10/day7/day7.md) | 用真实函数画 runtime flow 与 ownership graph；区分 callback dispatch 和 object lifetime；把 lambda capture、composition/virtual、template/type erasure、atomic/mutex/volatile 与 happens-before 挂回现有代码 | architecture flow + ownership table + fd-count observation | Reactor architecture, composition root, ownership graph, lambda capture, virtual destructor, happens-before |

---

# Week11：HTTP Server V1

| Day | 主要内容 | 主要产出 / 观察 | 检索关键词 |
|---|---|---|---|
| [Day1：HTTP request line](week11/day1/day1.md) | 在 TCP arbitrary fragmentation/coalescing 下，从累计 byte range 增量识别 method、origin-form target 与 HTTP/1.1；区分 NeedMore/Complete/Error，并用 consumed bytes 保留 suffix | `HttpRequest` + request-line parser + split-point tests | HTTP, request line, incremental parser, CRLF, NeedMore, consumed bytes, fragmentation |

---

# 按关键词反查

## C++ 对象与所有权

```text
pointer / reference / const              -> Week1 Day2
constructor / destructor / this          -> Week1 Day3
new/delete / dangling pointer / RAII      -> Week1 Day4
deep copy / Rule of Three                 -> Week1 Day5~Day7
move / std::move / Rule of Five           -> Week2 Day1~Day3
unique_ptr / shared_ptr / weak_ptr        -> Week2 Day4~Day5
exception safety / copy-and-swap          -> Week2 Day6
Rule of Zero                              -> Week2 Day7
```

## STL 与数据结构

```text
vector / capacity / reserve / resize      -> Week3 Day1
iterator invalidation / erase             -> Week3 Day2
string / c_str / npos / optional          -> Week3 Day3
map / set / bounds                        -> Week3 Day4
unordered_map / hash / rehash             -> Week3 Day5
RingBuffer                                -> Week3 Day6
LRU / list / splice                       -> Week3 Day7
```

## Linux 与 OS

```text
fd / open / read / write / errno          -> Week4 Day1~Day2
stat / inode / lseek / dup / links        -> Week4 Day3
dup2 / redirect / stdio buffering         -> Week4 Day4
fork / wait / exit                        -> Week4 Day5
pipe / exec                               -> Week4 Day6
mmap / signal / ECALL                     -> Week4 Day7
VA / page table / MMU / TLB               -> Week5 Day1
trap / trapframe / uservec / userret      -> Week5 Day2~Day3
page fault / lazy / COW                    -> Week5 Day4
scheduler / context switch                -> Week5 Day6
sleep / wakeup / lost wakeup              -> Week5 Day7
```

## 网络与事件驱动

```text
network layers / router / frame           -> Week6 Day1
MAC / IP / route / ARP / link             -> Week6 Day2
UDP / DNS                                 -> Week6 Day3
TCP listener / accept                     -> Week6 Day4
TCP byte stream / partial I/O             -> Week6 Day5
handshake / sequence / ACK / TIME-WAIT    -> Week6 Day6
HTTP framing / parser                     -> Week6 Day7
O_NONBLOCK / EAGAIN / EOF                 -> Week9 Day1
epoll readiness                           -> Week9 Day2
multi-client event loop                   -> Week9 Day3
per-connection state                      -> Week9 Day4
EPOLLOUT / output buffer                  -> Week9 Day5
LT / ET / stale fd                        -> Week9 Day6
Reactor Buffer / Channel / EventLoop      -> Week10 Day1~Day3
Acceptor / accepted fd ownership          -> Week10 Day4
Connection / input-output Buffer          -> Week10 Day5
dynamic EPOLLOUT / half-close             -> Week9 Day5~Day6, Week10 Day5
callback lifetime / deferred cleanup      -> Week10 Day6
stale event / fd reuse / generation       -> Week9 Day6, Week10 Day6
Reactor architecture / composition root   -> Week10 Day7
HTTP request line / incremental parser    -> Week11 Day1
```

## 并发与工程工具

```text
thread / join / detach / std::ref         -> Week7 Day1
mutex / invariant / lock scope            -> Week7 Day2
condition_variable / backpressure         -> Week7 Day3
BlockingQueue / MPMC                      -> Week7 Day4~Day5
atomic / CAS                              -> Week7 Day6
contention / false sharing                -> Week7 Day7
ThreadPool / future / packaged_task       -> Week8 Day1~Day3
GoogleTest / CMake / CTest / TSan         -> Week8 Day4
AsyncLogger / benchmark                   -> Week8 Day5~Day6
component integration / shutdown order    -> Week8 Day7
lambda capture / virtual / happens-before -> Week10 Day7
```

---

# 维护规则

每次新建或修改主线 daily 后，检查本目录是否需要同步：

```text
daily 路径或标题改变
-> 更新对应链接和名称

核心问题、主要产出或技术范围改变
-> 更新该 Day 的三列摘要与关键词

新增一周或新一天
-> 更新“一眼看主线”、详细周表和关键词反查

只修改解释措辞、注释或局部例子
-> 若不影响检索含义，可以不改目录
```

维护目录时只编辑 `DAILY_INDEX.md`，不得为了匹配目录反向改写任何 daily 内容。
