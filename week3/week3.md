# Week3：STL 行为 + 工程数据结构第一轮

> 定位：Week3 承接 Week2 的 copy / move / ownership / noexcept，不把 STL 当成 API 表来背。  
> 本周重点是理解容器为什么扩容、对象为什么搬家、地址和迭代器为什么失效，以及怎样根据工程场景选择容器。

---

## 本周起点

Week2 已经通过：

```text
copy / move
std::move
Rule of Five / Rule of Zero
unique_ptr / shared_ptr / weak_ptr
RAII 和异常安全
copy-and-swap
noexcept 初步
```

这些内容会直接用于理解：

```text
vector 扩容时为什么需要 copy / move
为什么 noexcept move 会影响容器行为
容器搬家后为什么地址、指针和迭代器会失效
unordered_map rehash 为什么会改变内部组织
工程代码为什么必须先想清楚对象生命周期
```

---

## 本周目标

```text
1. 理解 vector 的连续内存、size、capacity 和扩容
2. 能观察 vector 扩容时元素的 copy / move
3. 理解 reserve 和 resize 的区别
4. 理解 vector 常见迭代器、引用和指针失效场景
5. 知道 push_back / emplace_back 的差别，不神化 emplace_back
6. 理解 string 的基本存储行为、c_str 和修改后的失效风险
7. 能根据场景选择 map / set / unordered_map / unordered_set
8. 理解哈希冲突、load factor 和 rehash
9. 掌握常用 algorithm、pair、tuple、optional 的工程用法
10. 用 STL 写一个固定容量 RingBuffer V1
11. 用 list + unordered_map 写一个简化 LRU Cache V1
12. 把 STL 容器和 Reactor / Mini Redis 等后续项目连接起来
```

---

## 本周不追求什么

```text
不手写完整 vector
不深挖 STL allocator
不证明红黑树旋转和平衡规则
不手写工业级哈希表
不研究不同标准库实现源码
不深挖 ranges
不做复杂模板元编程
不追求所有容器 API 全覆盖
不正式开启 6.S081 / 15-445
```

---

## 本周学习内容

```text
vector：连续内存、size、capacity、reserve、resize、扩容
vector：push_back、emplace_back、insert、erase
vector：指针 / 引用 / 迭代器失效
string：size、capacity、c_str、修改和失效
algorithm：sort、find、lower_bound、remove_if
pair / tuple / optional 初步
map / set：有序、树结构直觉、O(log n)
unordered_map / unordered_set：哈希、桶、冲突、load factor、rehash
容器选择：vector / deque / list / map / unordered_map
RingBuffer V1
LRU Cache V1
```

---

## 学到什么程度

本周结束时，你应该能做到：

```text
1. 能解释 vector 为什么是连续内存
2. 能解释 size 和 capacity 的区别
3. 能解释 reserve 为什么不创建元素
4. 能解释 resize 为什么会改变元素数量
5. 能画出 vector 扩容前后的内存变化
6. 能说清扩容时为什么会 copy 或 move 元素
7. 能判断常见迭代器失效场景
8. 能解释 map 和 unordered_map 的选择依据
9. 知道 unordered_map 平均 O(1) 不等于永远 O(1)
10. 能解释 rehash 为什么发生以及造成什么影响
11. 能用 STL 写边界明确的 RingBuffer
12. 能解释 LRU 为什么常用 list + unordered_map
```

---

## 工程映射

```text
vector：连续连接列表、批量任务、网络缓冲区底层存储
string：协议文本、命令、日志消息
unordered_map：fd -> Connection、key -> value、对象注册表
map：有序任务、范围查询、时间点管理
set：去重、有序集合
priority_queue：定时器堆
deque / queue：任务队列、生产者消费者前置
RingBuffer：网络收发缓冲区、异步日志队列
LRU：缓存淘汰、连接和对象缓存
```

本周不是为了背容器，而是要逐渐形成：

```text
场景
→ 数据访问方式
→ 生命周期和失效风险
→ 容器选择
→ 边界和复杂度
```

---

## 本周代码产出

Ubuntu 建议目录：

```bash
~/code/system-learning/cpp/week3
```

建议结构：

```text
week3/
├── day1/
│   ├── 01_vector_growth.cpp
│   └── 02_vector_move_observe.cpp
├── day2/
│   ├── 01_iterator_invalidation.cpp
│   └── 02_push_emplace_erase.cpp
├── day3/
│   ├── 01_string_storage.cpp
│   └── 02_algorithm_optional.cpp
├── day4/
│   ├── 01_map_set_basic.cpp
│   └── 02_container_choice.cpp
├── day5/
│   ├── 01_unordered_rehash.cpp
│   └── 02_hash_collision_observe.cpp
├── day6/
│   └── ring_buffer.cpp
└── day7/
    └── lru_cache.cpp
```

学习期 demo 继续满足：

```text
能编译
能运行
能观察现象
能解释输出
使用 -std=c++17 -Wall -Wextra -g
```

---

# Day1：vector 内存模型 + size / capacity + 扩容

## 今日目标

```text
理解 vector 是可扩容的连续数组
理解 size / capacity
观察 push_back 导致扩容和 data 地址变化
理解扩容时元素为什么需要 copy / move
理解 reserve / resize 的区别
```

## 代码产出

```text
day1/
├── 01_vector_growth.cpp
└── 02_vector_move_observe.cpp
```

## 验收重点

```text
能画出扩容前后的两块内存
能解释旧地址为什么失效
知道增长倍率不是标准固定值
知道 reserve 不改变 size
能把 noexcept move 和扩容联系起来
```

---

# Day2：迭代器失效 + push_back / emplace_back / erase

## 今日目标

```text
理解迭代器、引用、指针为什么会失效
掌握 vector 插入和删除的常见风险
知道 push_back 和 emplace_back 的真实差别
学会安全地边遍历边 erase
```

## 代码产出

```text
day2/
├── 01_iterator_invalidation.cpp
└── 02_push_emplace_erase.cpp
```

## 验收重点

```text
扩容后旧指针为什么不能再用
erase 后哪些迭代器失效
为什么 erase 常写 it = container.erase(it)
emplace_back 为什么不是无条件更快
```

---

# Day3：string + algorithm + optional 初步

## 今日目标

```text
理解 string 和 vector 相似的动态存储直觉
理解 c_str() 返回指针的生命周期风险
掌握 sort / find / lower_bound / remove_if
初步使用 pair / tuple / optional 表达结果
```

## 代码产出

```text
day3/
├── 01_string_storage.cpp
└── 02_algorithm_optional.cpp
```

## 验收重点

```text
string 修改后旧 c_str 指针为什么可能失效
remove_if 为什么通常还要配合 erase
optional 比特殊返回值清楚在哪里
```

## 不深挖

```text
不深挖 SSO 的 ABI 和实现差异
不提前展开 string_view 生命周期陷阱
```

---

# Day4：map / set + 容器选择

## 今日目标

```text
理解 map / set 的有序特性
建立红黑树只需 O(log n) 的结构直觉
区分 key-value 与纯 key 集合
根据有序、范围查询和访问模式选择容器
```

## 代码产出

```text
day4/
├── 01_map_set_basic.cpp
└── 02_container_choice.cpp
```

## 验收重点

```text
map 为什么能按 key 有序遍历
什么时候必须使用有序容器
为什么不能只根据复杂度表选容器
vector 连续内存为什么经常有工程优势
```

## 不深挖

```text
不手推红黑树旋转
不读 STL 树源码
```

---

# Day5：unordered_map / unordered_set + rehash

## 今日目标

```text
理解哈希表、bucket 和哈希冲突
理解 load_factor、reserve 和 rehash
观察 rehash 前后的 bucket_count
理解平均 O(1) 和最坏退化
理解 rehash 对迭代器的影响
```

## 代码产出

```text
day5/
├── 01_unordered_rehash.cpp
└── 02_hash_collision_observe.cpp
```

## 验收重点

```text
为什么不同 key 可能进入同一 bucket
什么时候触发 rehash
reserve 为什么能减少反复 rehash
为什么 unordered_map 不是永远 O(1)
```

## 不深挖

```text
不手写工业级 hash table
不研究攻击性哈希细节
不深挖自定义 allocator
```

---

# Day6：RingBuffer V1

## 今日目标

```text
用 vector 作为底层连续存储
用 head / tail / size 表达环形状态
处理空、满、绕回和容量为零等边界
把 STL 行为变成一个可解释的小组件
```

## 代码产出

```text
day6/
├── ring_buffer.cpp
└── README.md 或 day6_note.md
```

## 最小接口

```cpp
bool push(int value);
bool pop(int& value);
bool empty() const;
bool full() const;
std::size_t size() const;
std::size_t capacity() const;
```

## 验收重点

```text
容量为 0 怎么处理
写满后 push 返回什么
空队列 pop 返回什么
索引如何绕回
head / tail 分别表示什么
```

## 暂时不做

```text
不做多线程安全
不做 lock-free
不做动态扩容
```

---

# Day7：LRU Cache V1 + Week3 出口验收

## 今日目标

```text
理解 LRU 的 O(1) 查找与 O(1) 淘汰需求
理解为什么常用 list + unordered_map
写一个简化 LRU Cache V1
检查是否可以进入 Linux 系统编程前置阶段
```

## 代码产出

```text
day7/
├── lru_cache.cpp
└── day7_note.md
```

## 最小接口

```cpp
bool get(int key, int& value);
void put(int key, int value);
std::size_t size() const;
```

## 验收重点

```text
最近使用的节点为什么要移到链表头
淘汰时为什么删除链表尾
unordered_map 里为什么保存 list iterator
容量为 0 怎么处理
更新已有 key 时发生什么
```

如果 Day6 RingBuffer 边界仍不稳，Day7 优先修 RingBuffer，LRU 可以顺延，不机械赶进度。

---

## 6.S081 / 15-445 安排

```text
6.S081：本周不正式开，最多把 system call 当下周背景
15-445：不开
```

原因：Week3 的核心是 STL 行为和工程数据结构，先把容器与对象生命周期连接稳。

---

## 本周验收问题

```text
1. vector 的 size 和 capacity 有什么区别？
2. vector 扩容大概经历哪些步骤？
3. reserve 和 resize 有什么区别？
4. vector 扩容后哪些地址、引用和迭代器会失效？
5. push_back 和 emplace_back 应该怎样理解？
6. string 的 c_str 指针什么时候可能失效？
7. map 和 unordered_map 怎么选？
8. unordered_map 的哈希冲突是什么？
9. load factor 和 rehash 有什么关系？
10. 为什么 unordered_map 平均 O(1) 但最坏可能退化？
11. RingBuffer 怎样区分空和满？
12. LRU 为什么使用 list + unordered_map？
```

---

## 本周最终完成标准

```text
Day1 到 Day5 的观察 demo 能编译运行并解释输出
能解释 vector 扩容和迭代器失效
能根据场景选择 map / unordered_map
能解释哈希冲突和 rehash
RingBuffer V1 边界测试通过
LRU Cache V1 或其核心结构完成
代码继续使用 -std=c++17 -Wall -Wextra -g
笔记只记录陌生点和错误，不重复抄教程
```

