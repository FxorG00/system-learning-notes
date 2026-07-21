# Week3 Day7：LRU Cache V1 + Week3 出口验收

> 今日定位：独立实现日，也是 Week3 收尾。  
> 今天只补齐 `std::list` 的必要语义，然后给出 LRU 的需求、接口、边界、复杂度与验收标准；不提前给成员变量答案、操作伪代码、关键实现片段或完整参考实现。

---

## Part A：前情提要和术语

### 1. 前情提要

Day5 已经完成：

```text
unordered_map 平均 O(1) 精确查找
bucket、冲突和 load factor
reserve / rehash
rehash 的迭代器失效规则
```

Day6 已经完成：

```text
把自然语言需求翻译成组件接口
自己设计状态和不变量
处理容量 0、容量 1、写满、绕回和读空
普通编译与 ASan / UBSan 验收
```

Day7 会把这两条线合起来：

```text
哈希索引负责快速定位 key
顺序结构负责维护“最近使用”的先后关系
两个结构必须始终保持一致
```

今天的难点不是 LRU 算法本身，而是多个容器之间的一致性、更新已有 key 和容量边界。

---

### 2. LRU 是什么

`LRU` 是 `Least Recently Used`，即“最近最少使用”。

当缓存已满，需要加入新元素时：

```text
淘汰最长时间没有被成功访问或更新的元素
```

一次“使用”包括：

```text
成功 get 一个已有 key
put 一个新 key
put 并更新一个已有 key
```

失败的 get 不算使用，因为对应 key 根本不存在。

---

### 3. MRU 和 LRU

#### MRU

`Most Recently Used`，最近刚被使用的元素。

#### LRU

`Least Recently Used`，目前最久没有被使用的元素。

缓存内部必须能够：

```text
快速把某个已有元素更新为 MRU
缓存满时快速找到并删除 LRU
```

你可以自行选择顺序结构的哪一端表示 MRU、哪一端表示 LRU，但必须从头到尾保持一致，并在 note 中写清楚。常见约定是前端表示 MRU、后端表示 LRU。

---

### 4. std::list 的必要直觉

`std::list` 通常实现为双向链表。

与 vector 不同：

```text
元素不要求连续存储
不能通过下标随机访问
已知某个元素的迭代器时，可以 O(1) 插入或删除该节点
在其他位置插入、删除或移动节点，通常不会让未删除节点的迭代器失效
只有被删除节点对应的迭代器、指针和引用失效
```

今天允许查阅这些 `std::list` 接口的标准文档：

```text
begin / end
front / back
push_front / emplace_front
pop_back
erase
splice
size / empty
```

其中 `splice` 可以把已有节点移动到另一个位置，而不复制节点内容。你需要自己查清它的参数和失效规则，本文件不提前给调用代码。

---

### 5. 为什么单独使用 unordered_map 不够

unordered_map 能快速回答：

```text
key 是否存在？
对应 value 是什么？
```

但它不提供：

```text
哪个 key 最近刚使用？
哪个 key 最久没使用？
```

它的遍历顺序没有 LRU 语义，而且 rehash 后顺序还可能改变。

所以 LRU Cache 需要额外的顺序结构。

---

### 6. 为什么单独使用 list 不够

list 可以维护使用顺序，但如果只靠 list 查找指定 key：

```text
最坏需要从头扫到尾
get 会变成 O(n)
put 更新已有 key 也可能先花 O(n) 查找
```

因此 Week3 规划要求组合：

```text
std::list
std::unordered_map
```

怎样分配 key、value 和定位信息，由你独立设计。

---

### 7. iterator 在今天的作用

Day4 已经把 iterator 理解为“容器位置的抽象”。

今天需要解决：

```text
unordered_map 找到 key 后，怎样直接定位顺序结构中的对应节点？
```

如果定位仍需要扫描 list，就无法满足平均 O(1) 的要求。

你需要自己决定哈希索引应该保存什么信息，才能直接定位对应节点。

注意区分：

```text
unordered_map 自己的 iterator
存储在 unordered_map 元素里的某个 list iterator
```

前者可能因 unordered_map rehash 失效；后者指向另一个容器，其有效性由 list 的操作决定。完成代码后，验收时会结合你的具体成员类型检查这一点。

---

## Part B：教程主体

### 1. 教程从需求开始

实现：

```text
LRUCache
```

最小公开接口：

```text
explicit LRUCache(std::size_t capacity)

bool get(int key, int& value)
void put(int key, int value)
std::size_t size() const
```

内部必须使用：

```text
std::list
std::unordered_map
```

具体成员类型和数据布局由你自己决定。

---

### 2. 构造与容量契约

构造时给定固定容量：

```text
初始 size() == 0
容量构造后不改变
任何时刻 size() <= capacity
```

允许容量为 0：

```text
put 不保存任何元素
get 永远失败
size() 永远为 0
不崩溃、不越界、不访问空容器元素
```

周计划的最小接口没有要求公开 `capacity()`，可以把容量只作为内部状态。

---

### 3. get 契约

key 存在时：

```text
get(key, value) 返回 true
value 得到缓存中的对应值
该 key 成为 MRU
size() 不变
```

key 不存在时：

```text
get(key, value) 返回 false
输出参数 value 保持调用前的值
缓存内容不变
使用顺序不变
```

失败 get 不能意外插入 key，也不能改变后续淘汰结果。

---

### 4. put 新 key 的契约

key 不存在且缓存未满时：

```text
插入 key-value
新 key 成为 MRU
size() 增加 1
不淘汰元素
```

key 不存在且缓存已满时：

```text
先保证最终只淘汰当前 LRU
插入新 key-value
新 key 成为 MRU
最终 size() 不超过 capacity
```

容量为 0 时：

```text
put 什么都不保存
```

---

### 5. put 已有 key 的契约

key 已存在时：

```text
更新对应 value
该 key 成为 MRU
size() 不变
不因为“已满”而额外淘汰其他 key
缓存中不能出现重复 key
```

这是 LRU 实现最容易漏掉的分支之一。

---

### 6. 复杂度要求

```text
get：平均 O(1)
put：平均 O(1)
size：O(1)
空间：O(capacity)
```

这里写“平均 O(1)”是因为 unordered_map 的复杂度不是永远 O(1)。

以下实现不合格：

```text
每次 get 都线性扫描 list
每次 put 都重新构建整个容器
每次淘汰都扫描所有 key 计算最久未使用者
```

---

### 7. 两个结构的一致性要求

无论你怎样设计成员，都必须保证：

```text
哈希索引与顺序结构描述的是同一批 key
缓存中每个 key 只出现一次
两个结构记录的逻辑元素数量一致
索引中的定位信息始终指向正确 key
成功 get / put 后，使用顺序正确
erase 后不保留指向已删除节点的定位信息
任何时刻逻辑 size 不超过 capacity
```

这组条件就是今天最重要的类不变量。

如果一次操作只更新了一个容器，忘记同步另一个容器，后续可能出现：

```text
find 成功但定位信息悬空
list 中有节点但 map 中找不到
同一个 key 出现两次
淘汰错误 key
访问已经删除的节点
```

---

### 8. 必须满足的行为序列一：访问改变淘汰结果

容量为 2：

```text
put(1, 10)
put(2, 20)
get(1)     -> 成功，得到 10
put(3, 30) -> 应淘汰 key 2

get(2)     -> 失败，输出参数不变
get(1)     -> 成功，得到 10
get(3)     -> 成功，得到 30
```

这组测试证明：

```text
成功 get 会更新 recency
淘汰的不是单纯最早插入的 key
失败 get 不产生元素
```

---

### 9. 必须满足的行为序列二：更新已有 key

容量为 2：

```text
put(1, 10)
put(2, 20)
put(1, 15)
put(3, 30)

get(1) -> 成功，得到 15
get(2) -> 失败
get(3) -> 成功，得到 30
size() -> 2
```

这组测试证明：

```text
put 已有 key 会更新 value
更新已有 key 会更新 recency
更新不增加 size
更新时不会错误淘汰其他 key
```

---

### 10. 必须满足的行为序列三：失败 get 不改变顺序

容量为 2：

```text
put(1, 10)
put(2, 20)
get(999)   -> 失败
put(3, 30) -> 应淘汰 key 1

get(1) -> 失败
get(2) -> 成功，得到 20
get(3) -> 成功，得到 30
```

如果失败 get 意外改变了顺序，这组测试会暴露问题。

---

### 11. 必须满足的行为序列四：容量边界

#### 容量为 0

```text
put(1, 10)
size() -> 0
get(1) -> 失败，输出参数不变
```

#### 容量为 1

```text
put(1, 10)
get(1) -> 成功，得到 10
put(2, 20)
get(1) -> 失败
get(2) -> 成功，得到 20
size() -> 1
```

---

### 12. 你需要自己做出的设计决策

实现前先回答：

```text
1. 哪个结构保存完整 key-value？
2. 哈希索引需要保存什么才能直接定位顺序节点？
3. 顺序结构哪一端是 MRU，哪一端是 LRU？
4. 成功 get 如何同时保持 value 与顺序正确？
5. put 新 key 与 put 已有 key 如何区分？
6. 淘汰时两个容器应保持什么一致性？
7. 删除节点前后，哪些 iterator 会失效？
8. unordered_map rehash 是否会影响指向 list 节点的 iterator？
9. capacity == 0 时，哪条路径必须提前结束？
10. 怎样保证同一个 key 永远只出现一次？
```

本文件不提供标准成员布局。只要满足契约、复杂度和不变量，你可以选择自己的组织方式。

---

### 13. 实现顺序建议

只给工程步骤，不给函数算法：

```text
1. 查清需要使用的 list API 和 iterator 规则
2. 写公开接口与 private 成员
3. 写 size 和容量 0 行为
4. 完成 get
5. 分别处理 put 新 key 与已有 key
6. 加入淘汰路径
7. 逐个运行四组行为序列
8. 用 sanitizer 检查悬空 iterator 和非法访问
```

卡住时仍按练习日提示规则：

```text
Level 1：只指出违反的契约或不变量
Level 2：指出出错容器或操作路径
Level 3：给局部修正思路，不给完整函数
Level 4：只有你明确要求时才给完整修法
```

---

## Part C：练习、检查和收尾

### 1. 今日代码目录

Ubuntu：

```bash
~/code/system-learning/cpp/week3/day7
```

创建：

```text
lru_cache.cpp
day7_note.md
```

今天没有参考实现可以复制，LRUCache 由你独立完成。

---

### 2. 普通编译与运行

```bash
g++ -std=c++17 -Wall -Wextra -g lru_cache.cpp -o lru_cache
./lru_cache
```

要求：

```text
零 warning
四组行为序列全部通过
成功时退出码为 0
失败时能定位具体用例
```

测试可以使用简单 `expect`、`assert` 或你自己的检查方式，不引入测试框架。

---

### 3. sanitizer 验收

```bash
g++ -std=c++17 -Wall -Wextra -g \
    -fsanitize=address,undefined \
    -fno-omit-frame-pointer \
    lru_cache.cpp -o lru_cache_san

./lru_cache_san
```

重点检查：

```text
使用已 erase 的 list iterator
淘汰后 map 中残留旧定位信息
空 list 上访问 front / back
capacity 0 路径非法访问
```

---

### 4. 黑盒测试清单

```text
1. capacity == 0
2. capacity == 1
3. 未满时插入新 key
4. 满时插入新 key并淘汰 LRU
5. 成功 get 更新 recency
6. 失败 get 不修改输出参数
7. 失败 get 不改变 recency
8. put 已有 key 更新 value
9. put 已有 key 不改变 size
10. put 已有 key 更新 recency
11. 多轮 get / put / eviction
12. size 始终不超过 capacity
13. 被淘汰 key 确实无法 get
14. 未被淘汰 key 的 value 保持正确
```

只通过公开接口测试，不暴露 private 成员。

---

### 5. 提交前一致性自查

```text
两个容器是否包含同一批 key？
是否可能出现重复 key？
每次 get 成功后是否更新顺序？
get 失败是否完全无副作用？
更新已有 key 是否误增 size 或误淘汰？
淘汰后是否同时清理两个结构？
所有保存的 iterator 是否仍然有效？
capacity 0 是否提前处理？
是否使用 owning raw pointer？
是否手写了不必要的特殊成员函数？
```

---

### 6. 完成后的验收顺序

你完成并告诉我 `day7 ok` 后，我会：

```text
1. 读取 day7_note
2. SSH 查看完整 lru_cache.cpp
3. 普通编译并运行测试
4. 用 ASan / UBSan 复验
5. 先拆解你实际选择的数据布局和不变量
6. 再手推 get、更新已有 key、淘汰和容量 0
7. 检查 iterator 生命周期与两个容器的一致性
8. 最后做 Week3 出口点评
```

完整代码拆解发生在你独立实现之后。

---

### 7. day7_note.md

笔记仍然只记真实的新东西，不要求抄完整教程：

```markdown
# Week3 Day7 Note

## 我的数据布局
- ...

## MRU / LRU 方向
- ...

## 两个容器的不变量
- ...

## iterator 生命周期
- ...

## 实际错误或新知识
- ...
```

如果实现顺利，设计草稿、遇到的一个 API 问题或一句关键不变量也可以作为有效 note。

---

### 8. Day7 验收问题

完成代码后基于自己的实现回答：

```text
1. LRU 和 MRU 分别是什么？
2. 哪些操作会把 key 更新为 MRU？
3. 失败 get 是否改变 recency？
4. 你的顺序结构哪一端是 MRU，哪一端是 LRU？
5. 为什么只使用 unordered_map 不够？
6. 为什么只使用 list 不够？
7. 哈希索引怎样直接定位 list 节点？
8. 为什么 get 和 put 能达到平均 O(1)？
9. put 已有 key 时发生什么？
10. 缓存满时怎样确定被淘汰 key？
11. 淘汰时怎样保证两个容器一致？
12. 哪些 list iterator 会因 erase 失效？
13. unordered_map rehash 是否会让 list iterator 失效？
14. capacity 0 怎样处理？
15. 怎样证明 size 永远不超过 capacity？
```

---

### 9. Week3 出口验收

完成 LRU 后，检查能否解释：

```text
vector 的 size / capacity / reserve / resize
vector 扩容和迭代器失效
push_back / emplace_back 的真实差别
string::c_str 的生命周期
remove_if + erase
optional 的无值表达
map / set 的有序、范围查询和迭代器稳定性
unordered_map 的 bucket、冲突、load factor 和 rehash
map / unordered_map / sorted vector 的选择
RingBuffer 的状态、不变量和边界
LRU 的两个容器与一致性
```

这里不要求再写一份重复 summary。验收以已完成代码、已有 note 和口头解释为准。

---

### 10. 面试追问

```text
怎样实现 O(1) 平均复杂度的 LRU Cache？
为什么组合 list 和 unordered_map？
为什么 map 中要保存能直接定位 list 节点的信息？
成功 get 为什么要更新顺序？
更新已有 key 时怎样处理？
淘汰时为什么两个容器都要删除？
rehash 会影响哪些 iterator？
容量为 0 怎么办？
```

回答必须与自己的实现一致。

---

### 11. 今天不要提前深挖

```text
不模板化 LRUCache
不做 TTL
不做 LFU
不做线程安全
不做 sharding
不做持久化
不做复杂异常注入
不读 Redis 淘汰源码
不引入 CMake 或 gtest
```

---

### 12. 6.S081 / 15-445

```text
6.S081：今天不开
15-445：今天不开
```

先完成 Week3 出口，Week4 再进入 Linux 系统编程与 6.S081 前置。

---

### 13. Git 提交建议

```bash
cd ~/code/system-learning
git status
git add cpp/week3/day7
git commit -m "week3 day7 lru cache v1"
```

提交前确保普通编译、行为测试和 sanitizer 都通过。

---

### 14. 下一阶段衔接

Day7 通过后，Week3 正式结束。

下一步不是继续堆 STL API，而是按照总规划进入 Week4：

```text
Linux 系统编程第一轮
file descriptor
open / read / write / close
errno
strace
进程与 system call 前置
6.S081 正式穿插准备
```

Week4 的具体 week plan 和 daily 等 Day7 验收通过后再生成，不提前展开。
