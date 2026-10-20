## R1

```text
struct ExpireSweepResult {
    std::size_t examined = 0;
    std::size_t removed = 0;
};

ExpireSweepResult sweep_expired(std::size_t max_examined);

新增以上 api

以 map 的顺序，检查至多 max_exmained 个记录，然后看每条记录是否已经过期，如果已经过期了就从 map 中物理删除。

每轮预算为 1 时，连续最多 $N$ 次调用应回收全部当前到期记录。
也就是说，我们需要记录本次应该从哪个位置开始检查记录。

小预算连续调用能够回收后面的到期记录。

并且 max_exmained 应该与 data_.size() 取个 min。

以及我们不能让 sweep_expired_start 指向失效的位置，所以如果最后删完了，要让它指向 end
```

## R3

```text
我的感觉就是，因为 std::string 是有自己的 cmp 规则的（字典序）
所以我们可以把 key 都看成数字，就是变成在值域上。
那么我们只需要记录上次的 key 检查到哪里，也就是用一个 cursor
比如 cursor=100，意味着 100 及之前的我都扫过了。
但是我们现在的 key 是 200，300，301
那我们就用 upper_bound 找到 cursor 后面的第一个 key，然后接着这样在值域上跳。

初始的时候让 cursor="" 即可。其实随便哪一个都是可以的，反正走到 end 我就让 cursor=data_.begin() 对应的 key。相当于给环随便找个起点。

这样有啥用呢？
这样我们就不需要关心，cursor 对应的 key 是否被 erase 了，因为我们不要求其一定存在。
原先我们是要求 cursor 对应的 key 一定存在，这样我们才能用 iterator 找到下一个位置。

还有一个问题，如果我们 auto copied=store; 如果采取 iterator 方案的话，copied 的 iterator 指向的是 store 的节点，这样也是不对的。

但是我们只保存 cursor 的方案将定位与 node 的生命周期独立开。


```

