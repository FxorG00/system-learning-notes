## 验收题

### 1. Day1 已经有 non-blocking `recv`，为什么还需要 epoll？

因为 non-blocking receive 它只是说不要让这个 execution flow 在某个 receive A 上睡死。然后你 A 又确实没有可以去读取的消息，那么它就会在 A 上睡死。这个是 non-blocking 的作用。然后 epoll 的话，它解决的问题是说现在有很多个 A、B、C、D 的 socket，但是我不可能说一直都是 fall一遍循环，循环去看看它们有没有能够立刻读取的信息。这样子的话就很浪费 CPU 的时间，所以它就用这个 epoll。如果说某一个它可能，比如说 B 可能有信息的话，那么它会发一个 notification 给这个 epoll。如果你调用 epoll_wait 的话，并且给它 A、B、C 都注册到这个 interest list 里面的话，那么当其中某一个它有这个数据可以读取的话，那么它就会根据这个 epoll_wait 然后返回到最后的这个 epoll_wait 的这个东西里面。这个是这个 epoll 的作用。

### 2. `epfd` 与 `receiver_fd` 分别访问什么 kernel object？

EPFD访问的是一个Epoll的一个 instance，然后 receiver FD，它实际上访问的是 socket。

### 3. interest list 与 ready list 的职责分别是什么？

Ingest list就是说当前你向这个 epo instance 注册了哪一些 FD，就是你要让这个 epo 去关注哪一些 FD 的一个状态的变化。然后这个 ready list 是当前已经就绪状态的那些 FD 的列表。比如说你用 epo In的话，那么 ready list 就是我当前去对这些 ready list 里面的这些 FD 做 read/write operation，有机会达到结果的 FD。

### 4. `epoll_wait` 返回 `EPOLLIN` 后，为什么还必须调用 `recv`，并检查真实返回值？

因为 epoll wait 返回 epoll in，它只是一个 event，只是一个 notification，它不代表真实情况下它真的有这个数据可以读取。返回的话只是代表着刚刚有数据可以读取。然后你真实的 receive 是代表我现实、真实、真正地能够读取到数据，这样子。 而且在 receive 的话，它才会把这个queue里面的这个数据给真正取走。

### 5.为什么第一次 wait 返回后不读取，default LT 仍可能再次报告 receiver？

因为你第二次 Wait 返回后不读取，那你这个它关注的这个 FD 对应的那个 socket 里面的那个 Queue，它仍然是有数据可以读取的，所以你第二次，第二次如果说再 Wait 的话，它仍然会去报告啊，因为现在确确实实是有数据可以读取的。

### 7. `returned_event.data.fd` 是 kernel 自动发现并填写的吗？它来自哪里？

它不是跟到自动发现的，它是我们注册的时候会去向这个 interest list里面去写入一个 watched FD，就表示我要让这个 epoll去监视，去观察，去关注这个FD。然后等到你 wait，epoll wait的时候，它就会去看你之前填入的这些FD，然后去返回来。

---

第 7 题，你实际代码已经写对了：

```
interest.data.fd = receiver_fd;
```

第三个参数决定**监视谁**，这一行决定**附带什么数据回来**。假如这一行填 `123`，仍然监视原来的 socket，但返回的 `data.fd` 就是 `123`。[Linux 接口说明](https://man7.org/linux/man-pages/man2/epoll_ctl.2.html)