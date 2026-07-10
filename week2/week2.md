# Week2：拷贝控制 + 移动语义 + 智能指针 + 异常安全初步

> 定位：Week2 是 Week1 资源管理的下一层，不开新大坑。  
> Week1 已经完成：对象生命周期、new/delete、RAII、浅拷贝/深拷贝、拷贝构造、拷贝赋值、self-assignment、Rule of Three。  
> Week2 的任务是把“资源怎么复制”推进到“资源怎么转移、怎么表达所有权、异常时怎么不泄漏”。

---

## 本周目标

```text
1. 复稳 Rule of Three，不让 Week1 的资源管理断掉
2. 理解 move 语义解决什么问题
3. 会写一个 move-only 资源类
4. 理解 Rule of Five 的边界：什么时候需要写，什么时候不该手写
5. 初步会用 unique_ptr 表达独占所有权
6. 初步理解 shared_ptr / weak_ptr 的使用场景和循环引用问题
7. 初步建立异常安全直觉：异常发生时资源不能泄漏
8. 能把本周内容和后面的 ThreadPool / AsyncLogger / Reactor 联系起来
```

---

## 本周不追求什么

```text
不深挖完美转发
不深挖万能引用复杂规则
不深挖 allocator / placement new
不深挖 shared_ptr 控制块实现
不深挖 enable_shared_from_this
不做模板元编程
不提前进入 STL 容器系统学习
不提前进入 Linux fd / socket / epoll
不正式开 6.S081 / 15-445
```

---

## 本周学习内容

```text
Rule of Three 复盘
Rule of Five
移动构造函数
移动赋值运算符
std::move
右值引用
move 后对象的有效但未指定状态
noexcept 初步
unique_ptr
shared_ptr
weak_ptr 初步
循环引用问题
异常传播时局部对象自动析构
RAII 和异常安全
copy-and-swap 初步
```

---

## 学到什么程度

本周结束时，你应该能做到：

```text
1. 能解释 copy 和 move 的区别
2. 能解释 std::move 本身不移动，只是把对象转成右值表达式
3. 能写一个禁止拷贝、支持移动的 Buffer
4. 能解释移动后对象为什么仍然要能安全析构
5. 能解释 Rule of Five 和 Rule of Three 的关系
6. 能用 unique_ptr 管理对象资源，不手写 delete
7. 能解释 unique_ptr 为什么不能拷贝但可以移动
8. 能解释 shared_ptr 的共享所有权和引用计数直觉
9. 能解释 weak_ptr 为什么能打破 shared_ptr 循环引用
10. 能解释异常发生时 RAII 为什么能自动释放资源
11. 能写一个简单 copy-and-swap 赋值版本
12. 能说清这些东西以后在 ThreadPool / AsyncLogger / Reactor 里怎么用
```

---

## 本周代码产出

建议放在：

```bash
~/code/system-learning/cpp/week2
```

建议最终目录：

```text
week2/
├── day1_rule_three_review/
├── day2_move_constructor/
├── day3_move_assignment_rule_five/
├── day4_unique_ptr/
├── day5_shared_weak_ptr/
├── day6_exception_safety/
└── week2_review.md
```

本周至少产出：

```text
1. move-only Buffer
2. Rule of Five Buffer
3. unique_ptr 管理资源 demo
4. shared_ptr / weak_ptr 循环引用 demo
5. 异常路径下 RAII 自动释放 demo
6. copy-and-swap 赋值 demo
7. week2_review.md
```

每个 demo 要满足：

```text
能编译
能运行
能解释输出
至少一个资源管理 demo 用 ASan 跑过
```

---

## 6.S081 / 15-445 安排

```text
6.S081：不正式开。可以把 Lecture 1 当背景，但不写重笔记。
15-445：不开。
```

理由：Week2 仍然是 C++ 对象和资源管理主线。OS / DB 现在不要抢主线。

---

# Day1：Rule of Three 复稳 + move 的问题来源

## 今日目标

```text
确认 Week1 的 Rule of Three 已经稳了
理解 move 语义要解决的问题：深拷贝有时太贵
建立“资源转移”直觉
```

## 学习范围

```text
Rule of Three 复盘
深拷贝成本
临时对象
返回对象
资源所有权转移
move 语义的动机
```

## 代码产出

```text
day1_rule_three_review/
├── 01_deep_copy_cost.cpp
└── 02_return_buffer.cpp
```

## 代码要求

```text
1. 用 Buffer / StringLike 观察拷贝构造什么时候发生
2. 打印构造、拷贝构造、拷贝赋值、析构
3. 观察返回对象或临时对象场景下拷贝成本
4. 不要求今天写 move，只理解为什么需要 move
```

## 笔记要求

```text
1. Rule of Three 解决什么问题
2. 深拷贝为什么安全但可能贵
3. “资源转移”和“资源复制”的区别
4. 你觉得哪些场景不应该深拷贝
```

## 验收问题

```text
1. 深拷贝解决了什么问题？
2. 深拷贝为什么可能有性能成本？
3. 如果一个临时 Buffer 马上要销毁，为什么还完整复制一份资源显得浪费？
4. move 语义大概要解决什么问题？
```

## 不要提前深挖

```text
不要讲完美转发
不要讲万能引用
不要讲 std::forward
```

---

# Day2：移动构造函数 + std::move 初步

## 今日目标

```text
理解移动构造函数
理解 std::move 的表面行为
写出第一个支持移动构造的 Buffer
```

## 学习范围

```text
右值引用初步
std::move 初步
移动构造函数
移动后对象仍要能安全析构
nullptr 作为资源移交后的状态
```

## 代码产出

```text
day2_move_constructor/
├── 01_move_constructor_buffer.cpp
└── 02_move_vs_copy.cpp
```

## 代码要求

```text
1. Buffer 支持拷贝构造和移动构造
2. 移动构造中转移 data_ 和 size_
3. 被移动对象的 data_ 置为 nullptr，size_ 置为 0
4. 打印 copy construct / move construct，观察区别
5. 用 ASan 跑一次
```

## 笔记要求

```text
1. std::move 本身做了什么
2. 移动构造和拷贝构造的区别
3. 被移动对象为什么不能留下悬空指针
4. move 后对象为什么仍然要能析构
```

## 验收问题

```text
1. std::move 会真的移动资源吗？
2. 移动构造函数的参数为什么常写 T&& other？
3. 移动构造里为什么要把 other.data_ 置为 nullptr？
4. move 后对象还能不能使用？至少要满足什么要求？
```

## 不要提前深挖

```text
不要讲右值引用折叠
不要讲完美转发
不要讲移动迭代器
```

---

# Day3：移动赋值 + Rule of Five

## 今日目标

```text
补齐移动赋值
理解 Rule of Five
写出一个完整的 Rule of Five Buffer
```

## 学习范围

```text
移动赋值运算符
self-move 初步
Rule of Five
noexcept 初步
拷贝赋值和移动赋值的资源释放顺序
```

## 代码产出

```text
day3_move_assignment_rule_five/
├── 01_rule_of_five_buffer.cpp
└── 02_vector_move_noexcept_observe.cpp
```

## 代码要求

```text
1. Buffer 有析构、拷贝构造、拷贝赋值、移动构造、移动赋值
2. 拷贝赋值仍然先 new 新资源，再 delete 旧资源
3. 移动赋值要释放当前旧资源，再接管 other 资源
4. 处理 this == &other
5. 移动构造 / 移动赋值尽量标 noexcept
6. 用 vector 或简单场景观察 noexcept 的意义，只建立直觉
```

## 笔记要求

```text
1. Rule of Five 是哪五个函数
2. Rule of Five 和 Rule of Three 的关系
3. 移动赋值和移动构造有什么区别
4. noexcept 为什么和移动构造有关
```

## 验收问题

```text
1. 为什么有析构函数的资源类可能需要 Rule of Five？
2. 移动赋值为什么要先释放当前对象已有资源？
3. 移动赋值为什么也要考虑 self-assignment？
4. noexcept 对容器搬移元素有什么直觉影响？
```

## 不要提前深挖

```text
不证明标准库选择 move/copy 的完整规则
不深挖 allocator
不深挖异常安全强保证细节
```

---

# Day4：unique_ptr 和独占所有权

## 今日目标

```text
理解 unique_ptr 表达独占所有权
知道为什么现代 C++ 不推荐裸 new/delete 管资源
用 unique_ptr 改写简单资源管理 demo
```

## 学习范围

```text
unique_ptr 基本使用
make_unique
独占所有权
禁止拷贝
允许移动
unique_ptr 管理单对象
unique_ptr 管理数组初步
```

## 代码产出

```text
day4_unique_ptr/
├── 01_unique_ptr_basic.cpp
├── 02_unique_ptr_move.cpp
└── 03_unique_ptr_array_or_buffer.cpp
```

## 代码要求

```text
1. 用 unique_ptr 管理一个对象
2. 观察 unique_ptr 不能拷贝
3. 观察 unique_ptr 可以移动
4. 用 make_unique 创建对象
5. 对比手写 delete 和 unique_ptr 自动析构
```

## 笔记要求

```text
1. unique_ptr 表达什么所有权
2. unique_ptr 为什么不能拷贝
3. unique_ptr 为什么可以移动
4. unique_ptr 和 RAII 的关系
5. unique_ptr 能不能完全替代所有裸指针
```

## 验收问题

```text
1. unique_ptr 解决了什么问题？
2. 为什么 unique_ptr 不能 copy？
3. std::move 一个 unique_ptr 后，原 unique_ptr 大概变成什么状态？
4. 什么时候用裸指针作为 non-owning pointer 仍然可以接受？
```

## 不要提前深挖

```text
不深挖自定义 deleter
不深挖 unique_ptr 的类型大小
不深挖 shared_ptr 控制块
```

---

# Day5：shared_ptr / weak_ptr 初步

## 今日目标

```text
理解 shared_ptr 的共享所有权
理解引用计数直觉
知道 shared_ptr 不是默认更安全
知道 weak_ptr 用来解决循环引用
```

## 学习范围

```text
shared_ptr 基本使用
make_shared
use_count 观察
共享所有权
循环引用问题
weak_ptr 初步
lock()
```

## 代码产出

```text
day5_shared_weak_ptr/
├── 01_shared_ptr_basic.cpp
├── 02_shared_ptr_cycle.cpp
└── 03_weak_ptr_break_cycle.cpp
```

## 代码要求

```text
1. 用 shared_ptr 创建和共享对象
2. 观察 use_count 的变化
3. 写一个循环引用导致析构不发生的 demo
4. 用 weak_ptr 打破循环引用
5. 只做最小 demo，不做复杂设计
```

## 笔记要求

```text
1. shared_ptr 表达什么所有权
2. 引用计数大概怎么决定对象生命周期
3. shared_ptr 循环引用为什么会泄漏
4. weak_ptr 为什么不增加引用计数
5. weak_ptr::lock() 是干什么的
```

## 验收问题

```text
1. shared_ptr 和 unique_ptr 的核心区别是什么？
2. shared_ptr 的 use_count 能不能作为业务逻辑依据？
3. 为什么两个 shared_ptr 互相指向会导致对象无法析构？
4. weak_ptr 为什么能打破循环引用？
```

## 不要提前深挖

```text
不深挖控制块实现
不深挖 enable_shared_from_this
不深挖多线程下引用计数细节
```

---

# Day6：异常安全初步 + copy-and-swap

## 今日目标

```text
理解异常发生时局部对象会自动析构
理解 RAII 和异常安全的关系
知道 copy assignment 的异常风险
写一个简单 copy-and-swap 赋值版本
```

## 学习范围

```text
throw 初步
异常传播时栈展开
局部对象自动析构
RAII 防泄漏
基本异常安全直觉
强异常安全直觉
copy-and-swap 初步
```

## 代码产出

```text
day6_exception_safety/
├── 01_exception_raii.cpp
├── 02_bad_assignment_exception_risk.cpp
└── 03_copy_and_swap.cpp
```

## 代码要求

```text
1. 写一个函数中途 throw，观察局部对象析构
2. 写一个 RAII 对象，证明异常时析构仍执行
3. 对比先 delete 再 new 的赋值风险
4. 写 copy-and-swap 的最小版本
5. 不要求写工业级异常安全组件
```

## 笔记要求

```text
1. 什么是栈展开
2. 为什么异常时 RAII 能释放资源
3. 基本异常安全和强异常安全的直觉区别
4. copy-and-swap 为什么能让赋值更稳
```

## 验收问题

```text
1. throw 后局部对象会不会析构？
2. RAII 为什么适合处理异常路径？
3. copy assignment 里先 delete 再 new 的风险是什么？
4. copy-and-swap 的核心思路是什么？
```

## 不要提前深挖

```text
不深挖异常类型体系
不深挖 noexcept 传播规则
不深挖标准库异常保证
```

---

# Day7：Week2 复盘 + 是否进入 STL

## 今日目标

```text
检查 Week2 是否真的过关
确认 move / smart pointer / exception safety 是否能接到后续 STL 和组件项目
决定是否进入 Week3：STL + 工程数据结构第一轮
```

## 今日任务

```text
1. 整理 week2_review.md
2. 回答 Week2 验收问题
3. 选择一个本周最重要 demo 用 ASan 再跑一次
4. 标记还不稳的问题
5. 如果 move / unique_ptr 仍不稳，先补半天，不急着进 STL
```

## week2_review.md 建议结构

```markdown
# Week2 Review

## 本周学了什么
- ...

## 我已经比较稳的点
- ...

## 我还不稳的点
- ...

## 我写过的代码
- ...

## move 语义我怎么理解
- ...

## 智能指针我怎么理解
- ...

## 异常安全我怎么理解
- ...

## 下周是否可以进入 STL
- 可以 / 暂缓
- 原因：...
```

## Week2 总验收问题

```text
1. copy 和 move 的区别是什么？
2. std::move 本身做了什么？
3. 移动构造和移动赋值分别在什么时候调用？
4. move 后对象需要满足什么状态？
5. Rule of Five 是什么？
6. unique_ptr 为什么不能拷贝？
7. unique_ptr 什么时候适合用？
8. shared_ptr 解决什么问题？
9. shared_ptr 循环引用为什么泄漏？
10. weak_ptr 怎么解决循环引用？
11. 异常发生时局部对象为什么会析构？
12. copy-and-swap 解决什么问题？
```

## 进入 Week3 的条件

```text
能写 move-only Buffer
能解释 std::move 不是真正移动
能用 unique_ptr 表达独占所有权
能解释 shared_ptr / weak_ptr 基本区别
能解释异常时 RAII 自动释放资源
至少一个 Week2 demo 用 ASan 跑过
```

---

## 本周 Git 提交建议

每天可以小提交，也可以两天一提交，但本周至少有一次完整提交：

```bash
cd ~/code/system-learning
git status
git add .
git commit -m "week2 move smart pointers exception safety"
```

---

## 本周最终完成标准

```text
Day1 ~ Day6 主要 demo 能编译运行
至少一个资源管理 demo 用 ASan 跑过
能解释 Rule of Five
能解释 std::move
能写 move-only Buffer
能用 unique_ptr 管理资源
能解释 shared_ptr / weak_ptr 和循环引用
能解释异常路径下 RAII 自动释放
week2_review.md 写完
确认是否进入 Week3
```