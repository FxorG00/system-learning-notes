## 问题：

如果一块对象不止有一个 owner，那 unique_ptr 就不行了，我应该用啥？

## shared_ptr

```text
一个对象有多个 owner
多个 shared_ptr 可以同时指向一个对象
只要有一个 shared_ptr 活着这个对象就不能被释放
只有当最后一个 shared_ptr 析构的时候，这个对象才释放。
总结：这些 shared_ptr 共同决定这个对象的生命周期。
```

## reference count

shared_ptr 会维护这个。

当多了一个 shared_ptr 指向这个对象的时候，也就是多了一个 shared_ptr 的值是这个对象的地址。那么 `计数+1`。

当某个 `shared_ptr` 析构或者指向其他对象，那么 `计数-1`。

显然，当 `计数=0` 的时候，没有 `shared_ptr` 指向它，那这个对象被释放。

计数的存在确保了：shared_ptr 共同决定对象生命周期。

## weak_ptr

可以指向对象，但不影响这个对象的计数。

计数是跟对象生命周期有关，所以 weak_ptr 不影响生命周期。

weak_ptr 要先调用 `auto p=weak.lock()`，如果对象还或者，则 `p 是一个有效的 shared_ptr`，否则是一个 `nullptr`。 就是去 check 指向的对象是否存活。

## 循环引用的问题

我想要析构 b，但是 a 里面有一个 `shared_ptr  ` 指向 b，也就是说，还有人，需要用到 b 这个对象，所以你没办法析构！

析构 a 同理。

如果你想要表示，多个 ptr 共同拥有一个对象，但并不是这些 ptr 共同决定这个对象的生命周期，而是其中有一些 ptr 只是观察，但是并不影响对象生命周期，我们就可以用 `weak_ptr`。

## 验收问题

```text
1. shared_ptr 解决的到底是什么问题？
一个资源有多个 owner，并且这些 owner 共同决定它的生命周期。

2. shared_ptr 和 unique_ptr 的核心区别是什么？
是否一个 ptr 独占一块资源。

3. copy 一个 shared_ptr 时，资源有没有被复制？
没有，比如 p2=p1，就是让 p2 也指向 p1 所指向的资源而已。

4. use_count 增加说明了什么？
多了一个指向这块资源的 shared_ptr。

5. 为什么 shared_ptr 互相指向会导致析构不发生？
上文有。

6. weak_ptr 为什么不增加引用计数？
一般只是为了观察。而且 weak_ptr 不影响对象生命周期，故不影响其计数。

7. weak_ptr::lock() 返回的是什么？
上文。

8. 什么时候你会优先 unique_ptr，而不是 shared_ptr？
看这块资源是否是被 ptr 独自拥有的，也就是看是否只有 1 个 owner。
```

