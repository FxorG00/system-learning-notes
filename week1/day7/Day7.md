﻿# Day7：Week1 快速验收 + 查漏

> Day7 目标：不重复造轮子，只做 Week1 的快速验收和查漏。  
> 你 Day1 ~ Day6 实际只花了约 2 天，而且指针、引用、const、Tracer、RAII、Buffer、StringLike 这些练习大多已经写过。  
> 所以今天不再机械重写 `swap / Tracer / CharArray`，而是用你已有的 Buffer / StringLike 代码做最终验收。

今天只做四件事：

```text
1. 修正 Day6 note 里表达太短或容易误导的地方
2. 整理 StringLike / Buffer 最终版，并用 ASan 跑一次
3. 回答 Week1 关键验收问题，答不上来的才补代码
4. 写 week1_summary.md，准备进入 Week2
```

今天不是开新内容。今天的关键词是：

```text
查漏
验收
总结
准备进入 Week2
```

---

## 0. 今天要拿下什么

做完 Day7，你应该能做到：

```text
1. 能把 Week1 的知识链串起来讲一遍
2. 能用自己的 Buffer / StringLike 解释 RAII 和 Rule of Three
3. 能说明浅拷贝为什么 double delete
4. 能说明 copy assignment 为什么要处理 self-assignment
5. 能说明为什么先 new 新资源，再 delete 旧资源
6. 能用 ASan 跑一次资源管理代码
7. 能写出 week1_summary.md
8. 能判断自己是否可以进入 Week2
```

过关标准：

```text
不用再重复写基础 demo。
只要你能拿已有代码解释清楚，并且 ASan 跑过，Day7 就算达标。
```

---

## 1. 今天代码放哪里

```bash
cd ~/code/system-learning/cpp/week1
mkdir -p day7
cd day7
```

今天建议只放两个文件：

```text
day7/
├── 01_final_string_like.cpp
└── week1_summary.md
```

如果你已经有最终版 `StringLike` 在 day6，也可以不复制代码，只在 `week1_summary.md` 里记录：

```text
最终验收代码使用 day6/03_string_like.cpp
```

但建议你保存一份最终版，方便以后回看。

---

# 第一部分：修正 Day6 note

## 2. 先把 Day6 note 补完整

你 Day6 note 已经过关，但有几个地方要补成能复盘给别人听的版本。

### owning pointer

确认标题是：

```text
owning pointer
```

解释建议补成：

```text
owning pointer 是拥有资源的指针。
如果一个裸指针负责释放某块资源，比如析构函数里 delete[] data_，那它就是 owning pointer。
裸 owning pointer 危险，是因为默认拷贝只会复制地址，容易导致多个对象以为自己都拥有同一块资源。
```

### Buffer V2 为什么是深拷贝

不要只写：

```text
因为我 new 了一个给他。
```

建议补成：

```text
因为拷贝构造里重新 new 了一块独立的 char 数组，然后把 other.data_ 指向的内容复制过来。
所以新对象和 other 的 data_ 地址不同，各自拥有自己的资源，析构时不会 double delete。
```

### copy assignment 的异常安全顺序

补一句：

```text
推荐先 new 新资源，把 other 的内容复制进去；确认新资源准备好后，再 delete[] 旧资源；最后让 data_ 指向 new_data。
这样如果 new 失败，原对象还保持原来的有效状态。
```

### ASan 检查什么

不要只写：

```text
内存错误
```

建议补成：

```text
ASan 可以帮助检查 use-after-free、double-free、heap-buffer-overflow 等堆内存错误。
今天主要用它确认 Buffer / StringLike 没有 double delete 和越界访问。
```

### StringLike 和 std::string 差距

建议补成：

```text
我的 StringLike 只是 toy demo，只支持构造、析构、拷贝构造、拷贝赋值、c_str、size。
std::string 还支持容量管理、自动扩容、移动语义、丰富接口、异常安全、小字符串优化、迭代器等。
```

---

# 第二部分：最终版 StringLike 验收

## 3. 整理 `01_final_string_like.cpp`

今天只保留一个最终验收代码。它应该满足：

```text
从 const char* 构造
析构释放内存
拷贝构造深拷贝
拷贝赋值深拷贝
处理 self-assignment
copy assignment 先 new 新资源，再 delete 旧资源
c_str() 返回 const char*
size() 返回不包含 '\0' 的字符串长度
```

建议最终接口：

```cpp
class StringLike {
public:
    explicit StringLike(const char* s);
    StringLike(const StringLike& other);
    StringLike& operator=(const StringLike& other);
    ~StringLike();

    const char* c_str() const;
    std::size_t size() const;

private:
    std::size_t size_;
    char* data_;
};
```

重点约定：

```text
size_ 表示字符串长度，不包含 '\0'
data_ 实际分配 size_ + 1 个 char
memcpy 时复制 size_ + 1，把 '\0' 一起复制
```

测试必须覆盖：

```cpp
StringLike a("abc");
StringLike b("hello world");

StringLike c = a;   // 拷贝构造

a = b;              // 拷贝赋值

a = a;              // 自赋值

std::cout << a.c_str() << " " << a.size() << std::endl;
std::cout << c.c_str() << " " << c.size() << std::endl;
```

期望现象：

```text
a = b 后 a 输出 hello world，size 为 11
c 是从 abc 拷贝出来的，输出 abc，size 为 3
a = a 不崩，不丢数据
ASan 不报错
```

编译运行：

```bash
g++ -std=c++17 -Wall -Wextra -g 01_final_string_like.cpp -o 01_final_string_like
./01_final_string_like
```

ASan：

```bash
g++ -std=c++17 -Wall -Wextra -g -fsanitize=address 01_final_string_like.cpp -o 01_final_string_like_asan
./01_final_string_like_asan
```

如果 ASan 报错，先不要急着改。先记录：

```text
报错类型是什么
大概发生在哪一行
它说明了什么问题
准备怎么修
```

---

# 第三部分：Week1 知识链总复盘

## 4. 用一条线串起来

在 `week1_summary.md` 里，用 10~20 行写清楚这条线：

```text
指针 / 引用 / const
→ class / struct
→ 构造函数 / 析构函数
→ 栈对象 / 堆对象
→ new / delete
→ new[] / delete[]
→ RAII
→ 默认拷贝
→ 浅拷贝
→ double delete
→ 深拷贝
→ 拷贝构造
→ 拷贝赋值
→ self-assignment
→ Rule of Three
```

你不需要写教材式定义。更推荐写成：

```text
我一开始只是在学指针。
后来发现类里如果有指针，就会牵扯资源所有权。
如果构造函数 new[]，析构函数 delete[]，那这个类就是资源管理类。
资源管理类默认拷贝很危险，因为默认只复制指针值。
这会导致两个对象指向同一块堆内存，最后 double delete。
所以要么禁止拷贝，要么自己写深拷贝。
如果自己写析构函数、拷贝构造、拷贝赋值，这就是 Rule of Three。
```

这段总结比重写三个 demo 更有价值。

---

# 第四部分：20 个关键验收问题

## 5. 只答，不会才补代码

今天不用再新写 `swap` / `Tracer` / `CharArray`。你直接回答这些问题，答不上来的，再回 Day2 ~ Day6 代码补。

```text
1. 指针和引用的区别是什么？
2. const int* / int* const / const int* const 区别是什么？
3. class 和 struct 默认访问权限有什么区别？
4. 构造函数和析构函数什么时候调用？
5. this 指针是什么？
6. const 成员函数是什么意思？
7. 栈对象和堆对象生命周期有什么区别？
8. new/delete 和 malloc/free 的区别是什么？
9. new[] 为什么要配 delete[]？
10. memory leak / dangling pointer / double delete 分别是什么？
11. RAII 是什么？它解决什么问题？
12. 默认拷贝通常做什么？
13. 为什么裸 owning pointer 默认拷贝危险？
14. 浅拷贝和深拷贝区别是什么？
15. 拷贝构造和拷贝赋值区别是什么？
16. operator= 为什么返回 T&？
17. 为什么 copy assignment 要处理 self-assignment？
18. Rule of Three 是什么？
19. StringLike 为什么要给 '\0' 留位置？
20. private 限制的是类外访问，为什么同类成员函数能访问 other 的 private 成员？
```

建议你在 `week1_summary.md` 里加一节：

```markdown
## Week1 验收问题

1. ...
2. ...
```

不用每题写很长。会的 1~2 句话，不会的标出来。

---

# 第五部分：Week1 总结文件

## 6. 写 `week1_summary.md`

建议结构：

```markdown
# Week1 Summary

## 本周学了什么
- ...

## 我已经比较稳的点
- ...

## 我还容易出错的点
- ...

## 我写过的代码
- Day1：...
- Day2：...
- Day3：...
- Day4：...
- Day5：...
- Day6：...
- Day7：...

## 资源管理这条线我怎么理解
用自己的话写 10~20 行。

## Day6 / Day7 重点坑
- owning pointer 拼写
- copy constructor 不能读未初始化 data_
- copy assignment 要处理 self-assignment
- copy assignment 推荐先 new 再 delete
- size_t 不需要判断 index < 0
- c_str() 应返回 const char*
- StringLike 的 size 不包含 '\0'

## Week1 验收问题
- ...

## 下周最该补什么
- ...
```

---

# 第六部分：6.S081 / 15-445 关联点

## 7. 今天不正式展开

按照总规划，Week1 不正式开 6.S081 / 15-445。

今天只保留一个轻关联：

```text
C++ 对象生命周期 / RAII 解决的是用户态程序里的资源管理问题。
后面 Linux 阶段会把资源从堆内存扩展到 fd、socket、pipe、mmap。
那时 RAII 仍然有用：构造时获取 fd，析构时 close(fd)。
```

今天不要展开：

```text
system call 细节
page table
fork / exec / wait
15-445 buffer pool
数据库 page
```

---

# 第七部分：今天不要提前深挖

今天不要学：

```text
move constructor
move assignment
std::move
右值引用
unique_ptr / shared_ptr / weak_ptr
STL allocator
placement new
虚函数表
模板元编程
Linux fd
socket / epoll
```

如果今天验收顺利，Week2 再正式进入：

```text
移动语义
智能指针
异常安全初步
```

---

# 第八部分：Git 提交

如果 Day6 还没提交，先提交 Day6。然后 Day7 完成后提交：

```bash
cd ~/code/system-learning
git status
git add .
git commit -m "week1 day7 quick review"
```

如果你要推到 GitHub：

```bash
git push
```

---

# Day7 完成标准

当你做到：

```text
Day6 note 补完整
01_final_string_like.cpp 或 day6/03_string_like.cpp 最终版确认
最终版 StringLike 能编译运行
最终版 StringLike 用 ASan 跑过且不报错
week1_summary.md 写完
20 个验收问题能回答大部分，不会的已标出来
完成一次 git commit
```

Day7 就结束。

下一步 Week2：

> **拷贝控制 + 移动语义 + 智能指针 + 异常安全初步。**
>
> 但进入 Week2 前，必须确认：你已经能用自己的 Buffer / StringLike 解释 Rule of Three。