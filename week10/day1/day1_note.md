## R1

```text
buffer 内部采用 std::vector<char> 去存储

原因如下：
1. 需要给 peek() 返回第一个 readable byte 的地址，这要求我们底层应该是连续存储的
2. 在构造的时候需要对底层的 vector 进行一个 reserve

问题1：
append 很好做，就是 push_back
那怎么实现把一段前缀标记为处理完成呢？
vector 没有 pop_front，我们只能开个 offset，表示 [0,offset) 这一块都已经处理完成了，然后 offset 这个位置是实际的开头。

问题2：
这样 vector 元素会一直增长下去，怎么办？
目前我的策略就是，当 offset=vector.size() 的时候，直接 vector.clear()，并且 offset=0 做一次 reset


```

## R2

```text
`retrieve_as_string()` 当前又重复写了一次“推进 offset + 判断 reset”；Round2 可以考虑在成功构造 result 后复用 `retrieve(length)`，让消费状态只有一个实现位置。

ok了；复用了一下。
```



```text


当尾部空间<append 的元素个数的时候；尾部空间=capacity-size

我们不一定要 push_back 然后触发 vector 自动扩容；
如果 capacity>=used+append 的话，说明我们的 vector 是可以放进去的，只是需要把 used 挪到开头，然后再去 append 元素，并且让 offset=0

我的实现是，尾部空间不够的时候就先压缩再 append，这样后续够与不够 vector 会决定


size()：当前 vector 中实际存在多少个 char elements
capacity()：当前 allocation 在不重新分配时最多能容纳多少 elements
```

