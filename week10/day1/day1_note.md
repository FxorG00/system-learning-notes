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

