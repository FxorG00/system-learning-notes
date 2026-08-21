## R1

### 1

```text
我的第一个问题就是，嗯，你用这个，你要求我写的这个 submit，它是要去实现一个，传入一个 function，传入对应的参数，然后要能够，我知道就是先用 bind 去给它打包起来，然后再去给它包装到这个 package task 里面，这样就会有一个 future 能够去获得它的相关的一些 shared state。但是问题来了，我怎么样把这个 package task 给它放到这个 blocking queue 里面？因为你这个 package task，它的 return type，它是在变化的，但是我 blocking queue 我是需要初始化的。

经过提示后，我发现对于 worker 来说，我只需要知道这里有一个可以执行的任务，然后我把这个 task 给执行了，把这个 package task 给执行了。然后它会执行完了之后，它会去写入那个相关的 shared state。但是我并不需要关心它的返回值，因为返回值对 worker 来说没有意义。而且它最后会把返回值，如果成功的话，会写到那个 shared state 里面。所以我是不是可以统一一下，就是把它变成一个 void 的一个类型呢？我的现在的想法是这样，然后我现在实践一下。
```

### 2

```text
所以我最后去实现这个 submit 的想法就是，我先把这个函数跟你的参数给它 bind 成一个不需要那个参数列表就可以调用的一个 callable。然后我再用这个 package task 去创建这个新对象，然后拿这个 callable 去初始化了，去构造了。然后我再创建一个对应的 future。然后最后我往这个 blocking queue 里面 push 的元素是这个 package task 的 STD move，并且是给它 static cast 成这个 package task<void>的括号。就是我强令它，让它们全部都是返回值为 void。这样子我那个 blocking queue 的那个元素的类型它就是固定的。
```



你这个质疑非常好。关键在于：

> `static_cast` 不一定是在“原对象身上换一种看法”。当目标是一个非引用的 class type 时，它可以调用构造函数，产生新的目标类型对象。

你的代码：

```
static_cast<std::packaged_task<void()>>(std::move(task))
```

当 `return_type` 是 `int` 时，概念上接近：

```
std::packaged_task<void()> outer(std::move(task));
```

确实构造了一个新的临时 `packaged_task<void()>`。

**为什么能构造**
假设原来的类型是：

```
std::packaged_task<int()> task;
```

它本身也是一个 callable，而且注意：

```
task(); // packaged_task::operator() 的返回类型是 void
```

`int` 不会从 `task()` 直接 return 出来，而是被写入 shared state。因此，`packaged_task<int()>` 可以作为一个“调用后返回 `void`”的 callable，交给：

```
std::packaged_task<void()>
```

所以对象关系是：

```
outer packaged_task<void()>
    |
    | 内部保存被 move 进来的 callable
    v
inner packaged_task<int()>
    |
    v
原来的 bind object
```

完整过程：

```
inner packaged_task<int()>
    |
    | get_future()
    +--------> future<int> -> shared state A
    |
static_cast<packaged_task<void()>>
    |
    v
构造 outer packaged_task<void()>
outer 把 inner 当作 callable 保存
outer 自己还关联 shared state B
    |
    v
进入 BlockingQueue
```

worker 调用时：

```
worker 调用 outer()
-> outer 调用内部保存的 inner()
-> inner 调用真正的 function
-> function 返回 int
-> inner 把 int 写入 shared state A
-> caller 的 future<int> 从 A 取得结果
-> inner() 本身返回 void
-> outer 把完成状态写入无人使用的 shared state B
```

因此，我说“外层包住内层”不是根据代码表面语法说的，而是根据这个 `static_cast` 最终选择的**目标类型构造函数**说的。

`static_cast` 在这里不是：

```
把同一个对象的类型标签强行改掉
```

而是：

```
请编译器根据源表达式，构造一个目标类型的新对象
```

如果没有合法构造方式，这个 `static_cast` 会直接编译失败。

还有一个精确边界：当原任务本身就是 `packaged_task<void()>` 时，源类型和目标类型相同，这里通常就是一次 move construction，不再形成两层不同 specialization。两层包装主要发生在 `R != void` 时。

所以你的代码很巧，但写成下面这样会更容易让人一眼看出“正在构造新对象”：

```
Task outer(std::move(task));
tasks.push(std::move(outer));
```

你原来的写法与这个在核心语义上相近，只是 `static_cast` 把“构造新对象”这件事藏得比较深。

### 3

```text
然后我还在想，如果说你的 push 失败了怎么办？因为如果说这个 blocking queue 在关闭了之后，它这个 push 失败了怎么办？而且你还是，我们说你的返回值还是限定成一个 future，所以我的想法是我暂且不要管它，感觉后面的 round two 可能之类会讲到。
```

