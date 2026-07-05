# Day2：C++ 指针、引用、const（术语补强版）

> 今天的主题：**指针、引用、const**。  
> 这三个东西是 C++ 的第一道门槛，也是后面对象生命周期、RAII、智能指针、线程池、Mini Redis 的地基。
>
> 今天不追求背术语，但该知道的名字要知道。  
> 比如 `const int*` 常叫“指向常量的指针”，`int* const` 常叫“指针常量”。  
> 术语只是帮助你和别人交流，真正要抓住的是：**到底是谁不能改。**

---

## 0. 今天的目标

做完 Day2，你应该能做到：

```text
1. 看懂 int a = 10; int* p = &a; *p = 20;
2. 知道 &a、p、*p 分别是什么意思
3. 知道 nullptr 是什么，为什么不能随便 *p
4. 区分指针和引用
5. 知道引用为什么像“别名”
6. 区分 const int*、int* const、const int* const
7. 知道常量指针、指针常量这些术语大概对应什么
8. 理解为什么函数参数经常写 const std::string&
9. 写完 4 个小代码，并能解释输出
```

今天的过关标准：

```text
看到 const std::string&、const int*、int* const 不懵；
别人说“常量指针 / 指针常量”时，你能反应过来他大概在说什么。
```

---

## 1. 今天代码放哪里

代码仍然放 Ubuntu：

```bash
cd ~/code/system-learning/cpp/week1
mkdir -p day2
cd day2
```

今天建议写 4 个小程序：

```text
day2/
├── 01_pointer_basic.cpp
├── 02_reference_swap.cpp
├── 03_const_pointer.cpp
└── 04_const_ref_param.cpp
```

笔记你按自己的习惯存，不强制放 Ubuntu。

每个 `.cpp` 文件都可以这样编译：

```bash
g++ -std=c++17 -Wall -Wextra -g 文件名.cpp -o 输出名
```

例如：

```bash
g++ -std=c++17 -Wall -Wextra -g 01_pointer_basic.cpp -o 01_pointer_basic
./01_pointer_basic
```

---

# 第一部分：变量、地址、指针

## 2. 从变量到地址

你写：

```cpp
int a = 10;
```

不要只把它看成“创建了一个变量”。

更底层一点，你可以想成：

```text
内存里有一块空间
这块空间的名字叫 a
这块空间里存着 10
这块空间有一个地址
```

在 C++ 里：

```cpp
&a
```

表示：

```text
取变量 a 的地址
```

比如：

```cpp
int a = 10;
std::cout << &a << std::endl;
```

会输出一个类似：

```text
0x7ffdxxxx
```

这样的值。它就是 `a` 在内存里的位置。

这里有一个术语：

```text
地址：某个对象在内存中的位置。
```

现在不用深挖“虚拟地址 / 物理地址”，后面学 OS 页表时会回来讲。

---

## 3. 指针：存地址的变量

普通变量存值：

```cpp
int a = 10;
```

指针变量存地址：

```cpp
int* p = &a;
```

这句话拆开：

```text
int* p     p 是一个指针，指向 int 类型对象
&a         取 a 的地址
p = &a     把 a 的地址存进 p
```

所以现在有两个变量：

```text
a：存 10
p：存 a 的地址
```

术语上，`p` 叫：

```text
指针变量
```

`int*` 叫：

```text
指针类型
```

`int* p` 的意思是：

```text
p 是一个 int* 类型的变量，也就是“指向 int 的指针”。
```

---

## 4. 解引用：顺着地址找到对象

如果：

```cpp
int* p = &a;
```

那么：

```cpp
*p
```

表示：

```text
顺着 p 里存的地址，找到那个 int 对象。
```

这个动作有个术语，叫：

```text
解引用，dereference
```

所以：

```cpp
*p = 20;
```

意思是：

```text
把 p 指向的那个对象改成 20。
```

而 `p` 指向的是 `a`，所以 `a` 会变成 20。

你现在先记住这组关系：

```text
&a：取 a 的地址
p：存地址
*p：访问 p 指向的对象
```

---

## 5. 写代码验证指针

创建文件：

```bash
touch 01_pointer_basic.cpp
```

写入：

```cpp
#include <iostream>

int main() {
    int a = 10;
    int* p = &a;

    std::cout << "a      = " << a << std::endl;
    std::cout << "&a     = " << &a << std::endl;
    std::cout << "p      = " << p << std::endl;
    std::cout << "*p     = " << *p << std::endl;

    *p = 20;

    std::cout << "after *p = 20" << std::endl;
    std::cout << "a      = " << a << std::endl;
    std::cout << "*p     = " << *p << std::endl;

    return 0;
}
```

编译运行：

```bash
g++ -std=c++17 -Wall -Wextra -g 01_pointer_basic.cpp -o 01_pointer_basic
./01_pointer_basic
```

你要重点观察：

```text
&a 和 p 基本一样
*p 的值和 a 一样
*p = 20 会让 a 变成 20
```

---

## 6. 这一小节你要能回答

```text
1. p 里面存的是 a 的值，还是 a 的地址？
2. *p 代表 p 本身，还是 p 指向的对象？
3. “解引用”是什么意思？
4. 为什么 *p = 20 会让 a 变成 20？
```

---

# 第二部分：nullptr

## 7. 空指针：指针可以暂时不指向对象

指针很强，但也危险。因为它可以指向一个对象，也可以暂时不指向任何有效对象。

```cpp
int* p = nullptr;
```

这句话意思是：

```text
p 是一个 int 指针，但现在不指向任何 int 对象。
```

这里有两个术语：

```text
nullptr：空指针字面量
空指针：不指向任何有效对象的指针
```

`nullptr` 是现代 C++ 推荐使用的空指针写法。  
你可能在旧代码里见过 `NULL` 或者 `0`，但以后你自己写 C++，优先用 `nullptr`。

---

## 8. nullptr 常出现在哪里

它常见于：

```text
查找失败
对象还没创建
资源还没初始化
链表走到尾部
函数返回“没有结果”
```

比如链表最后通常是：

```text
node1 -> node2 -> node3 -> nullptr
```

`nullptr` 表示链表到头了。

---

## 9. 空指针不能乱解引用

下面这种写法很危险：

```cpp
int* p = nullptr;
std::cout << *p << std::endl;
```

因为 `p` 没有指向有效对象，`*p` 就是在访问不存在的东西。程序很可能直接崩。

安全写法：

```cpp
int* p = nullptr;

if (p != nullptr) {
    std::cout << *p << std::endl;
} else {
    std::cout << "p is null" << std::endl;
}
```

先记住：

```text
用指针前，要想一下它会不会是 nullptr。
```

今天不深入空指针崩溃、段错误、内存权限这些。后面学 OS 和 gdb 时会再回来讲。

---

# 第三部分：引用

## 10. 引用：变量的别名

看这个：

```cpp
int a = 10;
int& r = a;
```

`r` 是 `a` 的引用。你可以先把它理解成：

```text
r 是 a 的另一个名字
```

术语上，`r` 叫：

```text
引用变量
```

`int&` 叫：

```text
引用类型
```

所以：

```cpp
r = 20;
```

等价于：

```cpp
a = 20;
```

---

## 11. 引用的两个硬规则

引用有两个关键规则：

```text
1. 定义时必须初始化
2. 一旦绑定到某个变量，就不能再改绑到别的变量
```

比如：

```cpp
int a = 10;
int b = 30;

int& r = a;
r = b;
```

注意：

```cpp
r = b;
```

不是让 `r` 改绑到 `b`。

它的意思是：

```text
把 b 的值赋给 r，也就是赋给 a
```

执行后：

```text
a 变成 30
r 仍然是 a 的别名
```

所以引用跟指针不一样。  
指针可以之后改成指向别的对象：

```cpp
int* p = &a;
p = &b;
```

但引用不行：

```cpp
int& r = a;
// r 永远是 a 的别名
```

---

# 第四部分：指针和引用的关系

## 12. 它们都能修改外部变量

指针版本：

```cpp
void change_by_pointer(int* p) {
    *p = 100;
}
```

引用版本：

```cpp
void change_by_reference(int& r) {
    r = 100;
}
```

这两个都可以修改函数外面的变量。

区别在于调用方式：

```cpp
change_by_pointer(&x);
change_by_reference(x);
```

指针要传地址，引用直接传变量。

---

## 13. 写交换函数验证

创建文件：

```bash
touch 02_reference_swap.cpp
```

写入：

```cpp
#include <iostream>

void swap_by_pointer(int* a, int* b) {
    int tmp = *a;
    *a = *b;
    *b = tmp;
}

void swap_by_reference(int& a, int& b) {
    int tmp = a;
    a = b;
    b = tmp;
}

int main() {
    int x = 10;
    int y = 20;

    std::cout << "before swap: x = " << x << ", y = " << y << std::endl;

    swap_by_pointer(&x, &y);
    std::cout << "after pointer swap: x = " << x << ", y = " << y << std::endl;

    swap_by_reference(x, y);
    std::cout << "after reference swap: x = " << x << ", y = " << y << std::endl;

    return 0;
}
```

编译运行：

```bash
g++ -std=c++17 -Wall -Wextra -g 02_reference_swap.cpp -o 02_reference_swap
./02_reference_swap
```

---

## 14. 指针和引用怎么选

先记这个表：

| 对比点 | 指针 | 引用 |
|---|---|---|
| 直觉 | 存地址的变量 | 变量的别名 |
| 术语 | 指针变量 / 指针类型 | 引用变量 / 引用类型 |
| 能不能为空 | 可以是 `nullptr` | 正常情况下必须绑定对象 |
| 定义时是否必须初始化 | 不一定 | 必须 |
| 后面能不能改指向 | 可以 | 不可以重新绑定 |
| 使用方式 | `*p`、`p->` | 像普通变量一样 |
| 工程语义 | 可能没有对象，或者需要改指向 | 对象一定存在，只是借用 |

粗略规则：

```text
如果对象一定存在，只是想传进去用：优先引用
如果对象可能不存在：用指针
如果需要改“指向谁”：用指针
如果只是避免拷贝且不修改：const 引用
```

---

## 15. 这一小节你要能回答

```text
1. 引用能不能重新绑定？
2. int& r = a; 之后 r = b; 是重新绑定吗？
3. 指针能不能是 nullptr？
4. 为什么 swap_by_pointer 调用时要传 &x、&y？
5. 为什么 swap_by_reference 调用时直接传 x、y？
```

---

# 第五部分：const

## 16. const：不许改的承诺

最简单的例子：

```cpp
const int x = 10;
```

之后：

```cpp
x = 20;
```

会编译错误。

术语上，这里的 `x` 可以叫：

```text
常量对象
```

更准确一点说：

```text
x 是一个 const int 类型的对象。
```

`const` 的核心价值是：

```text
1. 防止误修改
2. 表达函数不会改参数
3. 让接口更清楚
4. 让编译器帮你抓错误
```

在工程里，`const` 不是装饰品，而是一种承诺：

```text
我这个函数不会改你传进来的东西。
```

---

# 第六部分：const 和指针

## 17. 先说术语：常量指针和指针常量

这部分中文术语很容易绕。

你会经常听到：

```text
常量指针
指针常量
```

有些教材和文章叫法不完全统一，所以你不要只靠名字硬背。  
我建议你这样记：

```text
const int* p      更推荐叫：指向常量的指针
int* const p      常叫：指针常量，或者 const 指针
const int* const p 指向常量的指针常量
```

也有人把 `const int*` 直接叫“常量指针”。  
为了避免混乱，你以后可以更精确地说：

```text
const int*：指向常量的指针
int* const：指针本身是常量
```

这样不容易误会。

核心判断方法只有一句：

```text
p 是指针本身
*p 是 p 指向的对象
```

看一个声明时，就问：

```text
不能改的是 p，还是 *p？
```

---

## 18. const int* p：指向常量的指针

```cpp
int a = 10;
int b = 20;

const int* p1 = &a;
```

名字：

```text
指向常量的指针
也常被叫作：常量指针
```

含义：

```text
p1 可以改指向
但不能通过 p1 修改它指向的值
```

可以：

```cpp
p1 = &b;
```

不可以：

```cpp
*p1 = 30;
```

注意，不是说 `a` 本身一定是常量。  
而是说：

```text
你不能通过 p1 这条路去修改 a。
```

比如：

```cpp
int a = 10;
const int* p1 = &a;

// *p1 = 30;  不行
a = 30;       // 可以，因为 a 本身不是 const
```

一句话：

```text
const int*：指向的值不能通过这个指针改，指针自己能改。
```

---

## 19. int* const p：指针常量

```cpp
int a = 10;
int b = 20;

int* const p2 = &a;
```

名字：

```text
指针常量
也可以说：指针本身是 const
```

含义：

```text
p2 自己不能改指向
但可以通过 p2 修改它指向的值
```

可以：

```cpp
*p2 = 30;
```

不可以：

```cpp
p2 = &b;
```

一句话：

```text
int* const：指针自己不能改，指向的值能改。
```

---

## 20. const int* const p：指向常量的指针常量

```cpp
int a = 10;
int b = 20;

const int* const p3 = &a;
```

名字：

```text
指向常量的指针常量
```

含义：

```text
p3 自己不能改指向
也不能通过 p3 修改它指向的值
```

不可以：

```cpp
p3 = &b;
*p3 = 30;
```

一句话：

```text
const int* const：指针自己不能改，指向的值也不能通过它改。
```

---

## 21. 一个快速读法

你可以先用这个简单规则：

```text
const 在 * 左边：限制 *p，也就是限制指向的值
const 在 * 右边：限制 p，也就是限制指针本身
```

例子：

```cpp
const int* p;
```

`const` 在 `*` 左边，所以限制 `*p`：

```text
不能通过 p 改指向的值。
```

例子：

```cpp
int* const p;
```

`const` 在 `*` 右边，所以限制 `p`：

```text
p 自己不能改指向。
```

例子：

```cpp
const int* const p;
```

左右都有，所以：

```text
p 不能改，*p 也不能改。
```

这个规则先够用。

---

## 22. 用代码验证 const 指针

创建文件：

```bash
touch 03_const_pointer.cpp
```

写入：

```cpp
#include <iostream>

int main() {
    int a = 10;
    int b = 20;

    // p1：指向常量的指针
    // p1 可以改指向，但不能通过 p1 修改 *p1
    const int* p1 = &a;
    p1 = &b;
    // *p1 = 30; // 取消注释会编译错误

    // p2：指针常量
    // p2 自己不能改指向，但可以通过 p2 修改 *p2
    int* const p2 = &a;
    *p2 = 30;
    // p2 = &b; // 取消注释会编译错误

    // p3：指向常量的指针常量
    // p3 自己不能改指向，也不能通过 p3 修改 *p3
    const int* const p3 = &a;
    // p3 = &b;  // 取消注释会编译错误
    // *p3 = 40; // 取消注释会编译错误

    std::cout << "a = " << a << std::endl;
    std::cout << "b = " << b << std::endl;
    std::cout << "*p1 = " << *p1 << std::endl;
    std::cout << "*p2 = " << *p2 << std::endl;
    std::cout << "*p3 = " << *p3 << std::endl;

    return 0;
}
```

编译运行：

```bash
g++ -std=c++17 -Wall -Wextra -g 03_const_pointer.cpp -o 03_const_pointer
./03_const_pointer
```

然后你可以每次取消一个非法语句的注释，看看编译器怎么报错。  
不要一次取消多个，不然报错会很乱。

---

## 23. 这一小节你要能回答

```text
1. const int* p 的常见术语是什么？
2. int* const p 的常见术语是什么？
3. const int* p 中，不能改的是 p 还是 *p？
4. int* const p 中，不能改的是 p 还是 *p？
5. const int* const p 中，哪个不能改？
6. 为什么说 const int* p 不是说 a 本身一定是常量？
```

---

# 第七部分：const 引用传参

## 24. const std::string&：只读借用

你以后会经常看到这种函数：

```cpp
void print_name(const std::string& name) {
    std::cout << name << std::endl;
}
```

拆开看：

```text
std::string&：引用，避免拷贝
const：函数内部不允许修改 name
```

所以：

```cpp
const std::string& name
```

整体意思是：

```text
我借用你的 string，不拷贝，也不修改。
```

术语上，这个叫：

```text
const 引用
常量引用
```

更准确一点：

```text
对 const std::string 的引用
```

但平时说“常量引用”就够了。

---

## 25. 为什么常用 const 引用

如果写：

```cpp
void print_name(std::string name)
```

那调用时会拷贝一份 string。

对于 `int`、`double` 这种小对象，拷贝没啥。  
但对于 `std::string`、`std::vector`、大结构体，拷贝就可能比较贵。

所以只读大对象常写：

```cpp
void foo(const std::string& s);
void bar(const std::vector<int>& v);
```

这表示：

```text
不拷贝
不修改
只借用
```

---

## 26. 写代码验证参数传递

创建文件：

```bash
touch 04_const_ref_param.cpp
```

写入：

```cpp
#include <iostream>
#include <string>

void print_by_value(std::string s) {
    std::cout << "by value: " << s << std::endl;
}

void print_by_const_ref(const std::string& s) {
    std::cout << "by const ref: " << s << std::endl;
    // s = "changed"; // 取消注释会编译错误
}

void change_by_ref(std::string& s) {
    s = "changed";
}

int main() {
    std::string name = "fxor";

    print_by_value(name);
    std::cout << "after print_by_value: " << name << std::endl;

    print_by_const_ref(name);
    std::cout << "after print_by_const_ref: " << name << std::endl;

    change_by_ref(name);
    std::cout << "after change_by_ref: " << name << std::endl;

    return 0;
}
```

编译运行：

```bash
g++ -std=c++17 -Wall -Wextra -g 04_const_ref_param.cpp -o 04_const_ref_param
./04_const_ref_param
```

你要观察：

```text
print_by_value 不会改原变量，但会拷贝
print_by_const_ref 不会改原变量，也避免拷贝
change_by_ref 会修改原变量
```

---

## 27. 参数传递的粗略选择规则

先记这个版本，后面学 move 和智能指针时还会升级。

```text
int / double / char / bool 这种小对象：
通常值传递

std::string / std::vector / 大 struct / 大 class：
只读，用 const T&

需要修改外部对象：
用 T&

对象可能不存在，或者需要表达“可能为空”：
用 T*
```

例子：

```cpp
void f(int x);                    // 小对象，值传递
void f(const std::string& s);      // 大对象，只读，const 引用 / 常量引用
void f(std::string& s);            // 要修改外部 string，普通引用
void f(int* p);                    // 可能传 nullptr，或者明确传地址
```

---

# 第八部分：今天的练习

## 练习 1：地址和指针

基于 `01_pointer_basic.cpp`，你要能解释：

```text
&a 输出的是什么？
p 输出的是什么？
*p 输出的是什么？
*p = 20 为什么能改变 a？
“解引用”是什么意思？
```

---

## 练习 2：交换两个数

基于 `02_reference_swap.cpp`，你要能解释：

```text
swap_by_pointer 为什么要传 &x、&y？
swap_by_reference 为什么直接传 x、y？
指针和引用都能改外部变量，区别在哪里？
```

---

## 练习 3：const 指针三兄弟

基于 `03_const_pointer.cpp`，你要测试这三个：

```text
const int* p1
int* const p2
const int* const p3
```

要求：

```text
每次只取消一个非法语句的注释
编译
看懂报错
再注释回去
```

---

## 练习 4：const 引用传参

基于 `04_const_ref_param.cpp`，你要解释：

```text
std::string s
const std::string& s
std::string& s
```

三个参数形式的区别。

---

# 第九部分：你的笔记写什么

笔记你可以放在自己的 note 系统里，不强制放 Ubuntu。

建议你至少写这些：

```markdown
# Day2 Notes

## 指针
- 指针是什么：
- 指针变量是什么：
- 指针类型是什么：
- &a 是什么：
- *p 是什么：
- 解引用是什么：
- nullptr 是什么：
- 指针什么时候适合用：

## 引用
- 引用是什么：
- 引用变量是什么：
- 引用和指针的区别：
- 引用能不能重新绑定：
- 引用什么时候适合用：

## const
- const 是什么：
- const int* 的术语和含义：
- int* const 的术语和含义：
- const int* const 的术语和含义：

## const 引用传参
- const std::string& 叫什么：
- 为什么常用 const std::string&：
- 什么时候值传递：
- 什么时候 const 引用传递：
- 什么时候普通引用传递：
```

不用写得很长，但必须用你自己的话。

---

# 第十部分：Day2 验收问题

你做完后，把这些问题回答给我：

```text
1. 指针和引用的区别是什么？
2. 引用能不能重新绑定？
3. 指针能不能是 nullptr？
4. nullptr 有什么用？
5. &a、p、*p 分别是什么意思？
6. 解引用是什么意思？
7. const int* 常见叫法是什么？含义是什么？
8. int* const 常见叫法是什么？含义是什么？
9. const int* const 含义是什么？
10. 为什么函数参数常用 const std::string&？
11. 什么时候应该值传递？
12. 什么时候应该 const 引用传递？
13. 什么时候应该普通引用传递？
14. 什么时候更适合用指针？
```

过关标准：

```text
不用背定义，能拿代码例子解释。
```

---

# 第十一部分：Git 提交

回到仓库根目录：

```bash
cd ~/code/system-learning
git status
git add .
git commit -m "week1 day2 pointer reference const"
```

如果你需要推到 GitHub：

```bash
git push
```

---

# 今天先不要碰

今天不要开这些坑：

```text
new/delete
RAII
智能指针
类构造析构
STL 源码
epoll
线程池
```

这些后面都会学。  
Day2 就把 **指针、引用、const** 打牢。

---

# Day2 完成标准

当你能做到：

```text
4 个小代码能编译运行
能解释每个小代码的关键输出
笔记写完
能回答 Day2 验收问题
完成一次 git commit
```

Day2 就结束。

下一步 Day3：

> **类、构造函数、析构函数：理解对象是怎么出生和死亡的。**
