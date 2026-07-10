﻿# Day7：Week1 总复盘 + 小测

> Day7 目标：不急着开新内容，把 Week1 的 C++ 对象和资源管理第一层验收掉。  
> 你已经完成 Day1 ~ Day6，尤其是 Day4 ~ Day6 的主线：
>
> ```text
> new / delete
> RAII
> 默认拷贝
> 浅拷贝 / 深拷贝
> 拷贝构造 / 拷贝赋值
> self-assignment
> Rule of Three
> Buffer / StringLike
> ```
>
> 今天只做一件事：确认这些东西不是“看懂了”，而是能自己写、能解释、能发现坑。

---

## 0. 今天要拿下什么

做完 Day7，你应该能做到：

```text
1. 能把 Week1 的知识链串起来讲一遍
2. 能不看答案写出指针 / 引用 / const 的小 demo
3. 能解释对象生命周期、构造函数、析构函数
4. 能解释 new/delete 和 new[]/delete[] 的本质
5. 能解释 RAII 为什么能减少资源泄漏
6. 能解释默认拷贝为什么会导致浅拷贝
7. 能不看答案写出一个 Rule of Three 小类
8. 能用 ASan 跑一次资源管理代码
9. 能写一份 week1_summary.md
10. 能回答一组面试风格追问
```

今天过关标准：

```text
不是把答案背出来，而是能用自己的 Buffer / StringLike 代码解释。
```

---

## 1. 今天代码放哪里

```bash
cd ~/code/system-learning/cpp/week1
mkdir -p day7
cd day7
```

建议今天写 4 个文件：

```text
day7/
├── 01_pointer_const_review.cpp
├── 02_lifecycle_raii_review.cpp
├── 03_rule_of_three_quiz.cpp
└── week1_summary.md
```

编译统一用：

```bash
g++ -std=c++17 -Wall -Wextra -g 文件名.cpp -o 输出名
```

资源管理代码至少用 ASan 跑一次：

```bash
g++ -std=c++17 -Wall -Wextra -g -fsanitize=address 03_rule_of_three_quiz.cpp -o 03_rule_of_three_quiz_asan
./03_rule_of_three_quiz_asan
```

---

# 第一部分：先修正 Day6 note 的几个点

## 2. 先补 Day6 笔记

你 Day6 note 已经过关，但有几个回答太短。今天先把它补成能复盘的版本。

### owning pointer

确认标题是：

```text
owning pointer
```

不要写成：

```text
owing pointer
```

解释建议写成：

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

建议改成：

```text
因为拷贝构造里重新 new 了一块独立的 char 数组，然后把 other.data_ 指向的内容复制过来。
所以新对象和 other 的 data_ 地址不同，各自拥有自己的资源，析构时不会 double delete。
```

### ASan 检查什么

不要只写：

```text
内存错误
```

建议写成：

```text
ASan 可以帮助检查 use-after-free、double-free、heap-buffer-overflow 等堆内存错误。
今天主要用它确认 Buffer / StringLike 没有 double delete 和越界访问。
```

---

# 第二部分：Week1 知识链总复盘

## 3. 用一条线串起来

今天你要把 Week1 讲成一条线：

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

你可以按这个顺序在 `week1_summary.md` 里写一段 10~20 行的小总结。

重点不是写长，而是写清楚：

```text
每个概念解决什么问题
它和下一个概念怎么连起来
它在 Buffer / StringLike 里怎么体现
```

---

# 第三部分：小测 1：指针、引用、const

## 4. 写 `01_pointer_const_review.cpp`

目标：快速检查 Day2 内容有没有忘。

你要写一个程序，包含这些内容：

```text
1. 用指针版本 swap 两个 int
2. 用引用版本 swap 两个 int
3. 演示 const int*：不能通过指针改值，但指针可以换指向
4. 演示 int* const：可以通过指针改值，但指针不能换指向
5. 演示 const int* const：既不能通过指针改值，也不能换指向
6. 写一个函数 void print_string(const std::string& s)
```

参考骨架：

```cpp
#include <iostream>
#include <string>

void swap_by_pointer(int* a, int* b) {
    // TODO
}

void swap_by_reference(int& a, int& b) {
    // TODO
}

void print_string(const std::string& s) {
    std::cout << s << std::endl;
}

int main() {
    int x = 1;
    int y = 2;

    swap_by_pointer(&x, &y);
    std::cout << x << " " << y << std::endl;

    swap_by_reference(x, y);
    std::cout << x << " " << y << std::endl;

    int a = 10;
    int b = 20;

    const int* p1 = &a;
    // *p1 = 100; // 不允许
    p1 = &b;      // 允许

    int* const p2 = &a;
    *p2 = 100;    // 允许
    // p2 = &b;   // 不允许

    const int* const p3 = &a;
    // *p3 = 200; // 不允许
    // p3 = &b;   // 不允许

    print_string("hello const reference");

    return 0;
}
```

编译运行：

```bash
g++ -std=c++17 -Wall -Wextra -g 01_pointer_const_review.cpp -o 01_pointer_const_review
./01_pointer_const_review
```

你要能解释：

```text
指针和引用的区别
const int* / int* const / const int* const 的区别
为什么 const std::string& 适合只读传参
```

---

# 第四部分：小测 2：对象生命周期和 RAII

## 5. 写 `02_lifecycle_raii_review.cpp`

目标：检查 Day3 / Day4 内容。

写一个 `Tracer` 类：

```text
构造函数打印 construct
析构函数打印 destruct
hello() 打印对象名字
```

再写一个 `MiniBuffer` 类：

```text
构造函数 new[] 一块 int 数组
析构函数 delete[]
禁止拷贝构造
禁止拷贝赋值
set / get / size
```

你要观察：

```text
栈对象离开作用域自动析构
堆对象只有 delete 时才析构
RAII 对象离开作用域自动释放资源
```

要求：

```text
1. main 里创建一个栈上的 Tracer
2. main 里 new 一个堆上的 Tracer，然后 delete
3. 写一个函数 use_buffer()，里面创建 MiniBuffer
4. use_buffer() 结束时 MiniBuffer 自动析构
```

编译运行：

```bash
g++ -std=c++17 -Wall -Wextra -g 02_lifecycle_raii_review.cpp -o 02_lifecycle_raii_review
./02_lifecycle_raii_review
```

你要能解释：

```text
new 做了哪两件事
delete 做了哪两件事
为什么 RAII 能减少 memory leak
为什么 MiniBuffer 要禁止拷贝
```

---

# 第五部分：小测 3：Rule of Three

## 6. 写 `03_rule_of_three_quiz.cpp`

这是今天最重要的代码。

你要不看 Day6 答案，自己写一个 `CharArray` 类。

需求：

```text
CharArray 管理一块 char 数组
构造函数申请内存，并初始化为 '\0'
析构函数释放内存
支持 set / get / size
支持拷贝构造：深拷贝
支持拷贝赋值：深拷贝
处理 self-assignment
拷贝赋值里先 new 新资源，再 delete 旧资源
```

不要写 move，不要用智能指针。今天只测 Rule of Three。

建议接口：

```cpp
class CharArray {
public:
    explicit CharArray(std::size_t size);
    CharArray(const CharArray& other);
    CharArray& operator=(const CharArray& other);
    ~CharArray();

    void set(std::size_t index, char value);
    char get(std::size_t index) const;
    std::size_t size() const;

private:
    std::size_t size_;
    char* data_;
};
```

main 里必须测试：

```cpp
CharArray a(5);
a.set(2, 'A');

CharArray b = a;   // 拷贝构造
b.set(2, 'B');

std::cout << a.get(2) << " " << b.get(2) << std::endl;

CharArray c(2);
c = a;             // 拷贝赋值
std::cout << c.get(2) << std::endl;

a = a;             // 自赋值
std::cout << a.get(2) << std::endl;
```

期望现象：

```text
改 b 不影响 a
c = a 后 c 能读到 A
a = a 不崩，不丢数据
ASan 不报错
```

编译运行：

```bash
g++ -std=c++17 -Wall -Wextra -g 03_rule_of_three_quiz.cpp -o 03_rule_of_three_quiz
./03_rule_of_three_quiz
```

ASan：

```bash
g++ -std=c++17 -Wall -Wextra -g -fsanitize=address 03_rule_of_three_quiz.cpp -o 03_rule_of_three_quiz_asan
./03_rule_of_three_quiz_asan
```

如果 ASan 报错，不要急着改。先写下：

```text
报错类型是什么
大概发生在哪一行
它说明了什么问题
我准备怎么修
```

---

# 第六部分：Week1 总结

## 7. 写 `week1_summary.md`

文件内容建议这样写：

```markdown
# Week1 Summary

## 本周学了什么
- ...

## 我已经比较稳的点
- ...

## 我还容易出错的点
- ...

## 我写过的代码
- day1：...
- day2：...
- day3：...
- day4：...
- day5：...
- day6：...
- day7：...

## 资源管理这条线我怎么理解
用自己的话写 10~20 行。

## ASan / g++ / gdb / git 使用情况
- g++：...
- ASan：...
- gdb：...
- git：...

## 下周最该补什么
- ...
```

注意：不要写成流水账。重点写：

```text
哪些概念真的连起来了
哪些坑你踩过
哪些东西还需要 Week2 继续强化
```

---

# 第七部分：面试追问

## 8. 今天要能回答这些

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

如果你答不上来，不要查一大堆资料。回到你自己的代码：

```text
Tracer
IntBuffer
Buffer
StringLike
CharArray
```

用这些例子解释。

---

# 第八部分：6.S081 / 15-445 关联点

## 9. 今天不正式展开

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

这些等 Week4 以后按主线来。

---

# 第九部分：今天不要提前深挖

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

不是这些不重要，而是今天的任务是 Week1 验收。

如果你今天复盘顺利，Week2 再正式进入：

```text
移动语义
智能指针
异常安全初步
```

---

# 第十部分：Git 提交

如果 Day6 还没提交，先提交 Day6。然后 Day7 完成后提交：

```bash
cd ~/code/system-learning
git status
git add .
git commit -m "week1 day7 review and quiz"
```

如果你要推到 GitHub：

```bash
git push
```

---

# Day7 完成标准

当你做到：

```text
01_pointer_const_review.cpp 能编译运行
02_lifecycle_raii_review.cpp 能编译运行
03_rule_of_three_quiz.cpp 能编译运行
03_rule_of_three_quiz.cpp 用 ASan 跑过且不报错
week1_summary.md 写完
能回答 20 个面试追问中的大部分
完成一次 git commit
```

Day7 就结束。

下一步 Week2：

> **拷贝控制 + 移动语义 + 智能指针 + 异常安全初步。**
>
> 但进入 Week2 前，必须确认：你已经能不看答案写出一个 Rule of Three 资源类。