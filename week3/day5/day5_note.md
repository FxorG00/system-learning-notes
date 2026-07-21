## unordered_map/unordered_set

这俩的实现是通过哈希表。

## hash

hash 函数会把 `key -> hash value`，然后根据 `hash value` 放入对应的 `bucket`。

不同的 `key` 对应相同的 `hash value` 的时候就会发生哈希冲突，也就是说可能有很多 `key` 在一个 `bucket` 里面。

## load factor

```text
load_factor = size / bucket_count
table.load_factor();
table.max_load_factor(可以填你设定的 max);

直觉上，load factor 越高，每个 bucket 平均承担的元素越多
冲突和比较次数可能增加
```

## rehash

rehassh 会导致哈希表的组织结构发生变化，所以原有迭代器失效。但是元素所在的内存还是那块内存，所以你的元素引用 or 指针不失效（与 vector 扩容整体搬移内存不同）

```cpp
table.rehash(1000);
```

是让 `bucket_count` 至少达到我要求的数量。

## 验收问题：

```text
1. unordered_map 和 map 的核心组织方式有什么不同？
hash/红黑树

2. unordered_map 的 unordered 具体不保证什么？
不保证按一维有序

3. 一次精确查找大概经过哪几个步骤？
key->hash value-> 根据 hash value 找到对应的 bucket -> 在 bucket 内精确找到这个 key -> 返回 value

4. bucket、bucket_count、bucket_size 分别是什么？
桶，桶的数量，桶里面元素的总数

5. 什么是哈希冲突？冲突是否代表 hash 函数错误？
上有

6. load_factor 和 max_load_factor 有什么关系？
load_factor 是目前的一个指标
后者是我们设定的最大值，超过这个值就会 rehash

7. 什么情况下可能触发 rehash？
上面有

8. reserve 和 rehash 的参数语义有什么不同？
reserve 是预留出存储这么多元素的足够的 bucket
rehash 是至少预留这么多 bucket

9. rehash 分别怎样影响 iterator、pointer 和 reference？
上面有

10. 插入没有触发 rehash 时，已有迭代器是否失效？
不

11. erase 会让哪些迭代器和引用失效？
只要被删除元素的迭代器和引用失效

12. 为什么 unordered_map 平均 O(1) 但最坏 O(n)？
可能 hash 冲突，导致某个 bucket 的 size 很大。

13. 为什么 unordered_map 不一定比 map 或 vector 更快？
问题 12 有回答。主要还是具体情况。
```

