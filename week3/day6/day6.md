# Week3 Day6：RingBuffer V1 独立实现日

> 今日定位：这是练习日，不是跟写教程。  
> 今天只给需求、接口契约、边界和验收标准，不提前给状态设计、算法推导、伪代码、关键实现片段或完整答案。

---

## Part A：前情提要和术语

### 1. 为什么今天改成独立实现

Week3 前五天已经完成了 STL 行为铺垫：

```text
vector 的连续存储、size、capacity 和扩容
迭代器、指针和引用失效
string、algorithm、optional
map / set
unordered_map / unordered_set
```

你有 OI / ACM 背景，循环队列的算法难度本身不高。今天真正要锻炼的是：

```text
把自然语言需求翻译成类接口
自己选择并定义内部状态
自己维持类不变量
处理边界和失败路径
为自己的实现设计测试
```

因此，在你完成代码之前，本文件不会告诉你内部应该保存哪些变量，也不会推导 push / pop 的具体步骤。

---

### 2. RingBuffer 的业务直觉

RingBuffer 是固定容量、先进先出的缓冲结构。

它要解决的问题：

```text
底层空间固定
已经读走的位置应该能够重新使用
写到存储末尾后仍能继续工作
push / pop 不进行整体元素搬移
```

后续可能出现的场景：

```text
网络收发缓冲区
异步日志队列
生产者消费者队列的底层存储
音视频流缓冲
```

今天只实现单线程、固定容量、元素类型为 `int` 的 V1。

---

### 3. 今天会用到的术语

#### FIFO

First In, First Out，先进先出。

先 push 的元素必须先被 pop。

#### wrap-around

写入或读取走到存储末尾后，下一次位置回到存储开头。

#### contract

接口契约。它描述调用者能依赖什么，包括成功、失败、边界和副作用。

#### invariant

类不变量。它描述对象在构造完成后以及每次公开操作完成后都必须满足的条件。

#### black-box test

黑盒测试。只通过公开接口验证行为，不读取 private 成员。

---

### 4. 今日限制

```text
元素类型固定为 int
容量构造后不改变
满时拒绝新元素，不覆盖旧元素
不使用 raw new / delete
底层使用 std::vector<int>
不做线程安全
不做 lock-free
不模板化
```

这些限制让今天只聚焦状态设计、边界和测试。

---

## Part B：教程主体

### 1. 教程从需求开始

请实现一个类：

```text
RingBuffer
```

公开接口必须具备以下语义：

```text
explicit RingBuffer(std::size_t capacity)

bool push(int value)
bool pop(int& value)

bool empty() const
bool full() const
std::size_t size() const
std::size_t capacity() const
```

这些签名是需求，不是实现提示。内部状态和算法由你自己设计。

---

### 2. 构造契约

构造函数接收固定容量：

```text
capacity() 永远返回构造时传入的容量
初始 size() == 0
初始 empty() == true
容量大于 0 时，初始 full() == false
```

允许容量为 0，并采用以下契约：

```text
capacity() == 0
size() == 0
empty() == true
full() == true
任何 push 都失败
任何 pop 都失败
```

不要通过崩溃或未定义行为处理容量 0。

---

### 3. push 契约

缓冲区未满时：

```text
push(value) 返回 true
value 成为队尾的新元素
size() 增加 1
之前保存的元素和 FIFO 顺序不变
```

缓冲区已满时：

```text
push(value) 返回 false
不覆盖任何旧元素
size() 不变
后续 pop 的内容和顺序不变
```

失败操作必须保持对象状态不变。

---

### 4. pop 契约

缓冲区非空时：

```text
pop(value) 返回 true
value 得到当前最早写入的元素
该元素从逻辑队列中删除
size() 减少 1
```

缓冲区为空时：

```text
pop(value) 返回 false
size() 仍然是 0
输出参数 value 保持调用前的值
```

这里明确要求失败时不修改输出参数，测试必须覆盖。

---

### 5. 查询契约

```text
empty()：当前没有逻辑元素时为 true
full()：当前没有可写槽位时为 true
size()：当前逻辑元素数量
capacity()：固定容量
```

查询函数不能修改对象，应正确声明为 const 成员函数。

是否给简单查询函数增加 `noexcept`，由你根据前面所学自行判断，并在 note 中说明即可。

---

### 6. 底层存储要求

必须使用：

```text
std::vector<int>
```

要求：

```text
构造完成后就准备好固定数量的可写槽位
push / pop 期间不改变固定容量
不直接管理堆内存
不手写析构、拷贝或移动函数
```

你需要自己判断应该使用 vector 的“创建元素”能力，还是只使用“预留容量”能力。Day1 的实验已经提供了足够前置知识，这里不再给答案。

---

### 7. 必须满足的行为序列

#### 容量为 3

按顺序执行：

```text
push 10：成功
push 20：成功
push 30：成功
push 40：失败

pop：得到 10
push 40：成功

pop：得到 20
pop：得到 30
pop：得到 40
pop：失败
```

这组操作必须同时验证：

```text
写满
满时拒绝
FIFO
释放空间后继续写入
跨越底层存储末尾后仍然正确
读空
```

#### 容量为 1

按顺序执行：

```text
初始 empty 为 true，full 为 false
push 7 成功
此时 empty 为 false，full 为 true
push 8 失败
pop 得到 7
此时 empty 为 true，full 为 false
```

#### 容量为 0

按顺序执行：

```text
empty 为 true
full 为 true
push 失败
pop 失败
输出参数不变
```

---

### 8. 你需要自己做出的设计决策

实现前先在草稿或注释里回答：

```text
1. 需要保存哪些 private 状态？
2. 每个状态变量的唯一含义是什么？
3. 怎样判断 empty？
4. 怎样判断 full？
5. 怎样区分“空”和“满”？
6. 写到存储末尾后怎样继续？
7. 容量为 0 时怎样避免非法运算和越界？
8. push / pop 失败时，哪些状态必须保持不变？
9. 每次成功操作后，哪些不变量必须继续成立？
```

这里不提供标准状态设计。你的实现可以和常见答案不同，只要契约、复杂度和测试都成立，并且能够解释。

---

### 9. 复杂度要求

```text
push：O(1)
pop：O(1)
empty / full / size / capacity：O(1)
空间：O(capacity)
```

不能在每次 pop 时整体搬移剩余元素。

不能在每次 push 时重新分配整个底层存储。

---

### 10. 实现顺序建议

这里只给工程步骤，不给算法步骤：

```text
1. 写公开接口和 private 区域
2. 明确每个状态变量的含义
3. 写构造函数和查询函数
4. 写 push / pop
5. 先测试 capacity 0 和 1
6. 再测试 capacity 3 的写满、读空和跨界复用
7. 最后跑 sanitizer
```

如果某个测试失败，先检查状态定义是否在不同函数中被理解成了不同含义。

---

### 11. 卡住时的提示规则

不要直接查看完整答案。需要帮助时，可以让我按级别提示：

```text
Level 1：只指出违反了哪条契约或不变量
Level 2：指出问题位于哪个状态或哪条操作路径
Level 3：给局部修正思路，但不提供完整函数
Level 4：只有你明确要求时，才给完整修法
```

默认从 Level 1 开始。

---

## Part C：练习、检查和收尾

### 1. 今日代码目录

Ubuntu：

```bash
~/code/system-learning/cpp/week3/day6
```

创建：

```text
ring_buffer.cpp
day6_note.md 或 README.md
```

今天没有需要复制的示例代码，`ring_buffer.cpp` 由你独立完成。

---

### 2. 普通编译与运行

```bash
g++ -std=c++17 -Wall -Wextra -g ring_buffer.cpp -o ring_buffer
./ring_buffer
```

要求：

```text
零 warning
所有测试通过
成功时退出码为 0
失败时能够看到具体失败用例
```

测试可以使用你自己写的 `expect`、`assert` 或其他简单方式，不要求引入测试框架。

---

### 3. sanitizer 验收

```bash
g++ -std=c++17 -Wall -Wextra -g \
    -fsanitize=address,undefined \
    -fno-omit-frame-pointer \
    ring_buffer.cpp -o ring_buffer_san

./ring_buffer_san
```

要求：

```text
没有 ASan 报错
没有 UBSan 报错
容量 0 不发生除零或取模零
没有 vector 越界
```

---

### 4. 黑盒测试清单

必须通过：

```text
1. capacity == 0
2. capacity == 1
3. capacity == 3
4. 初始 empty / full / size / capacity
5. 未满时连续 push
6. 满时 push 失败
7. 非空时连续 pop
8. 空时 pop 失败
9. FIFO 顺序
10. 释放前部空间后继续 push
11. 多轮 push / pop 交替
12. 失败 push 不改变 size 和已有元素
13. 失败 pop 不改变 size 和输出参数
```

测试只能通过公开接口观察结果，不要为了测试把 private 状态暴露出去。

---

### 5. 提交前自查

```text
接口是否与需求一致？
const 查询是否正确？
是否使用了 owning raw pointer？
是否手写了不必要的析构 / 拷贝 / 移动？
底层 vector 是否真的拥有可写元素？
capacity 0 的每条路径是否安全？
失败操作是否保持原状态？
是否依赖调试输出才能维持正确性？
```

---

### 6. 完成后的代码拆解方式

你写完并告诉我 `day6 ok` 后，我会按以下顺序验收：

```text
1. 读取 day6_note
2. SSH 查看你的完整 ring_buffer.cpp
3. 普通编译并运行全部测试
4. 使用 ASan / UBSan 再跑一次
5. 先从整体上拆解你的接口、状态和控制流
6. 再手推写满、绕回、读空的状态变化
7. 最后指出错误、缺失边界和可以保留的设计
```

也就是说，手推和完整代码拆解发生在你独立实现之后，而不是提前泄露解法。

---

### 7. day6_note.md

建议放在：

```text
C:\Users\FxorG\Desktop\gpt_infra\week3\day6\day6_note.md
```

只记录你自己的设计和实际问题：

```markdown
# Week3 Day6 Note

## 我的状态定义
- ...

## 我的空满判断
- ...

## capacity == 0 的处理
- ...

## 测试结果
- 普通编译：...
- ASan / UBSan：...

## 实际遇到的错误
- ...
```

不要在实现前复制一份标准答案式总结。

---

### 8. 今日验收问题

完成代码后，用自己的实现回答：

```text
1. 你的 RingBuffer 保存了哪些状态？
2. 每个状态变量的唯一含义是什么？
3. 你的 empty 和 full 怎样判断？
4. 你的实现怎样区分空和满？
5. 你的写入位置和读取位置分别怎样变化？
6. 走到存储末尾后怎样继续？
7. capacity 0 为什么不会产生非法运算？
8. 满时 push 失败后，怎样证明对象状态没变？
9. 空时 pop 失败后，输出参数是否保持不变？
10. 为什么底层 vector 不能只有 capacity 而没有可写元素？
11. 为什么不需要手写五个特殊成员函数？
12. 哪些测试证明 FIFO 和跨界复用正确？
13. 当前实现为什么不能直接用于多线程？
```

---

### 9. 面试追问

```text
怎样设计固定容量 RingBuffer？
怎样区分空和满？
容量为 0 或 1 时怎样处理？
怎样证明 push / pop 是 O(1)？
失败时覆盖旧元素还是拒绝，为什么？
如果要支持多线程，需要增加什么？
```

回答必须基于你的实现，不背一份与代码不一致的模板。

---

### 10. 今天不要提前深挖

```text
不模板化 RingBuffer
不存放复杂对象
不动态扩容
不覆盖最旧元素
不做多生产者 / 多消费者
不做 lock-free
不研究 memory_order
不接 socket read / write
不引入 CMake 或 gtest
```

---

### 11. 6.S081 / 15-445

```text
6.S081：今天不开
15-445：今天不开
```

今天只做独立组件实现和测试。

---

### 12. Git 提交建议

```bash
cd ~/code/system-learning
git status
git add cpp/week3/day6
git commit -m "week3 day6 ring buffer v1"
```

提交前确保普通编译和 sanitizer 都已经通过。

---

### 13. 下一天衔接

Day7 将实现 LRU Cache V1，并继续采用练习日规则：

```text
先给需求、接口、边界和验收标准
你独立设计并实现
完成后再基于你的代码做完整拆解
```

Day7 会组合 `list + unordered_map`，重点是两个容器之间的一致性和边界，而不是提前复制标准答案。
