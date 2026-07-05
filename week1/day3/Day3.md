# Day3：class / struct、构造函数、析构函数、this

> Day3 目标：理解 C++ 里“对象是怎么出生、怎么活着、怎么死亡的”。  
> 你 Day2 的指针、引用、const 已经过关，所以 Day3 不再从特别浅的语法开始，而是走 **查漏补缺 + 代码验证 + 面试追问** 的版本。
>
> 今天先不碰 `new/delete` 和 RAII。  
> Day3 只研究**栈上对象**、**成员初始化**、**构造析构顺序**、**this 指针**、**const 成员函数**这些内容。  
> Day4 再正式进入 `new/delete` 和 RAII。

---

## 0. 今天你要拿下什么

做完 Day3，你应该能做到：

```text
1. 区分 class 和 struct 的默认访问权限
2. 知道什么是类、对象、成员变量、成员函数
3. 知道构造函数什么时候调用
4. 知道析构函数什么时候调用
5. 知道对象生命周期是什么
6. 能解释栈上对象的创建和销毁顺序
7. 知道为什么推荐用成员初始化列表
8. 理解 this 指针是什么
9. 理解 const 成员函数是什么意思
10. 能写一个简单类，并解释它的构造 / 析构 / 成员函数调用过程
```

今天的过关标准：

```text
你能讲清楚一个对象从创建到销毁发生了什么。
```

---

## 1. 今天代码放哪里

代码仍然放 Ubuntu：

```bash
cd ~/code/system-learning/cpp/week1
mkdir -p day3
cd day3
```

建议今天写 4 个小程序：

```text
day3/
├── 01_class_struct_access.cpp
├── 02_constructor_destructor.cpp
├── 03_init_list_this.cpp
└── 04_object_lifetime_order.cpp
```

每个文件都可以这样编译：

```bash
g++ -std=c++17 -Wall -Wextra -g 文件名.cpp -o 输出名
```

例如：

```bash
g++ -std=c++17 -Wall -Wextra -g 01_class_struct_access.cpp -o 01_class_struct_access
./01_class_struct_access
```

笔记按你的习惯存，不强制放 Ubuntu。

---

# 第一部分：类和对象

## 2. 先把术语摆正

C++ 里你经常看到这些词：

```text
class：类
struct：结构体
object：对象
member variable：成员变量
member function：成员函数
access control：访问控制
public / private / protected：访问权限
```

先用人话理解：

```text
类 class：
一种“类型设计图”。它描述这个东西有什么数据、能做什么操作。

对象 object：
根据这个设计图真正造出来的一个具体东西。

成员变量 member variable：
对象里面保存的数据。

成员函数 member function：
对象能执行的操作。
```

比如：

```cpp
class User {
public:
    void hello() const;

private:
    std::string name_;
};
```

这里：

```text
User 是类
name_ 是成员变量
hello 是成员函数
User u("fxor") 里的 u 是对象
```

---

## 3. class 和 struct 的区别

在 C++ 里，`class` 和 `struct` 都可以有成员变量、成员函数、构造函数、析构函数。

最基础、最常问的区别是：

```text
class 默认 private
struct 默认 public
```

也就是说：

```cpp
class A {
    int x;
};
```

等价于：

```cpp
class A {
private:
    int x;
};
```

而：

```cpp
struct B {
    int x;
};
```

等价于：

```cpp
struct B {
public:
    int x;
};
```

工程习惯上通常是：

```text
struct：
更偏“简单数据聚合”，比如配置、坐标、返回结果。

class：
更偏“有封装、有行为、有不变量”的对象。
```

但这是习惯，不是语法硬限制。

---

## 4. 写代码验证 class / struct 默认权限

创建文件：

```bash
touch 01_class_struct_access.cpp
```

写入：

```cpp
#include <iostream>
#include <string>

struct Point {
    int x;
    int y;
};

class User {
public:
    User(const std::string& name, int age)
        : name_(name), age_(age) {}

    void print() const {
        std::cout << "name = " << name_ << ", age = " << age_ << std::endl;
    }

private:
    std::string name_;
    int age_;
};

int main() {
    Point p{1, 2};
    std::cout << "Point: " << p.x << ", " << p.y << std::endl;

    User u("fxor", 19);
    u.print();

    // u.name_ = "gpt"; // 取消注释会编译错误，因为 name_ 是 private

    return 0;
}
```

编译运行：

```bash
g++ -std=c++17 -Wall -Wextra -g 01_class_struct_access.cpp -o 01_class_struct_access
./01_class_struct_access
```

你要观察：

```text
Point 的 x、y 可以直接访问
User 的 name_、age_ 不能在类外直接访问
只能通过 public 成员函数 print() 使用
```

---

## 5. 这一小节你要能回答

```text
1. class 和 struct 默认访问权限有什么区别？
2. private 的意义是什么？
3. 为什么成员变量一般不直接暴露 public？
4. struct 是不是不能有成员函数？
5. class 是不是一定比 struct 高级？
```

注意第 4、5 题答案都是否定的。  
`struct` 也能有成员函数；`class` 和 `struct` 能力几乎一样，主要区别是默认访问权限和工程语义。

---

# 第二部分：构造函数和析构函数

## 6. 对象也有“出生”和“死亡”

一个对象不是凭空存在的。

当你写：

```cpp
User u("fxor", 19);
```

C++ 会创建一个 `User` 对象。创建时会自动调用一个特殊函数：

```text
构造函数 constructor
```

当这个对象生命周期结束时，会自动调用另一个特殊函数：

```text
析构函数 destructor
```

构造函数负责：

```text
对象出生时，把对象初始化到可用状态。
```

析构函数负责：

```text
对象死亡前，做清理工作。
```

今天先看栈上对象。  
比如：

```cpp
int main() {
    User u("fxor", 19);
}
```

`u` 是 `main` 函数里的局部对象。  
进入作用域时构造，离开作用域时析构。

这里有一个术语：

```text
生命周期 lifetime：
对象从创建完成到销毁结束的这段时间。
```

---

## 7. 构造函数长什么样

构造函数的特点：

```text
1. 名字和类名一样
2. 没有返回类型，连 void 都没有
3. 创建对象时自动调用
```

例子：

```cpp
class User {
public:
    User(const std::string& name, int age)
        : name_(name), age_(age) {}
};
```

这里 `User(...)` 就是构造函数。

---

## 8. 析构函数长什么样

析构函数的特点：

```text
1. 名字是 ~类名
2. 没有返回类型
3. 对象销毁时自动调用
4. 一个类只能有一个析构函数
```

例子：

```cpp
class User {
public:
    ~User() {}
};
```

`~User()` 就是析构函数。

今天我们先让析构函数打印日志，用来观察对象什么时候死亡。  
后面 Day4 学 RAII 时，你会看到析构函数真正的威力：自动释放资源。

---

## 9. 写代码观察构造和析构

创建文件：

```bash
touch 02_constructor_destructor.cpp
```

写入：

```cpp
#include <iostream>
#include <string>

class Tracer {
public:
    Tracer(const std::string& name)
        : name_(name) {
        std::cout << "construct: " << name_ << std::endl;
    }

    ~Tracer() {
        std::cout << "destruct: " << name_ << std::endl;
    }

    void hello() const {
        std::cout << "hello from " << name_ << std::endl;
    }

private:
    std::string name_;
};

int main() {
    std::cout << "enter main" << std::endl;

    Tracer a("a");
    a.hello();

    {
        std::cout << "enter inner scope" << std::endl;
        Tracer b("b");
        b.hello();
        std::cout << "leave inner scope" << std::endl;
    }

    std::cout << "leave main" << std::endl;
    return 0;
}
```

编译运行：

```bash
g++ -std=c++17 -Wall -Wextra -g 02_constructor_destructor.cpp -o 02_constructor_destructor
./02_constructor_destructor
```

你应该能看到类似：

```text
enter main
construct: a
hello from a
enter inner scope
construct: b
hello from b
leave inner scope
destruct: b
leave main
destruct: a
```

关键观察：

```text
b 在内部作用域结束时析构
a 在 main 结束时析构
后创建的对象先析构
```

这就是栈上局部对象的生命周期。

---

## 10. 这一小节你要能回答

```text
1. 构造函数什么时候调用？
2. 析构函数什么时候调用？
3. 为什么 b 比 a 先析构？
4. 对象生命周期是什么意思？
5. 析构函数是不是需要你手动调用？
```

第 5 题：一般不需要你手动调用。  
栈上对象离开作用域时，编译器会自动安排析构。

---

# 第三部分：成员初始化列表

## 11. 推荐用成员初始化列表

你可能会写：

```cpp
class User {
public:
    User(const std::string& name, int age) {
        name_ = name;
        age_ = age;
    }

private:
    std::string name_;
    int age_;
};
```

这能跑，但不推荐。

更推荐：

```cpp
class User {
public:
    User(const std::string& name, int age)
        : name_(name), age_(age) {}

private:
    std::string name_;
    int age_;
};
```

冒号后面这坨：

```cpp
: name_(name), age_(age)
```

叫：

```text
成员初始化列表，member initializer list
```

它的作用是：

```text
在对象构造阶段，直接初始化成员变量。
```

而在构造函数体里写：

```cpp
name_ = name;
age_ = age;
```

更像是：

```text
成员变量先默认初始化，然后在函数体里被赋值。
```

对于 `int` 这种简单类型差别不大。  
但对于 `std::string`、`const 成员`、`引用成员`、没有默认构造函数的成员，初始化列表很重要。

先记一个工程习惯：

```text
构造函数里初始化成员变量，优先用成员初始化列表。
```

---

## 12. 初始化顺序不是列表顺序

这个点很容易被问。

成员变量真正的初始化顺序，不看初始化列表里写的顺序，而看它们在类里声明的顺序。

比如：

```cpp
class Demo {
private:
    int x_;
    int y_;
public:
    Demo() : y_(2), x_(1) {}
};
```

虽然初始化列表里写的是 `y_(2), x_(1)`，但实际初始化顺序仍然是：

```text
先 x_
再 y_
```

因为类里声明顺序是 `x_` 在前，`y_` 在后。

所以工程里建议：

```text
初始化列表顺序和成员声明顺序保持一致。
```

这样少踩坑，也少警告。

---

## 13. this 指针

在成员函数里，可以用一个特殊指针：

```cpp
this
```

`this` 是什么？

```text
this 是指向当前对象的指针。
```

比如：

```cpp
class User {
public:
    void print() const {
        std::cout << this->name_ << std::endl;
    }

private:
    std::string name_;
};
```

这里：

```cpp
this->name_
```

表示：

```text
当前这个对象的 name_ 成员。
```

平时你写：

```cpp
name_
```

其实很多时候可以理解成：

```cpp
this->name_
```

只是编译器帮你省略了。

---

## 14. this 常见用途

`this` 常用于：

```text
1. 区分成员变量和参数同名
2. 返回当前对象本身
3. 在成员函数里明确访问当前对象成员
```

比如：

```cpp
class User {
public:
    User(const std::string& name)
        : name_(name) {}

    void set_name(const std::string& name) {
        this->name_ = name;
    }

private:
    std::string name_;
};
```

这里参数叫 `name`，成员变量叫 `name_`，其实已经不冲突。  
如果成员也叫 `name`，就必须用 `this->name` 区分。

我们以后统一推荐成员变量加 `_` 后缀，比如 `name_`、`age_`，这样代码更清楚。

---

## 15. const 成员函数

你已经学过 `const std::string&`，知道 const 表示“不通过这条路修改”。

成员函数后面也可以加 const：

```cpp
void print() const;
```

比如：

```cpp
class User {
public:
    void print() const {
        std::cout << name_ << std::endl;
    }

private:
    std::string name_;
};
```

这里的 `const` 表示：

```text
这个成员函数承诺不修改当前对象。
```

更准确地说：

```text
在这个函数内部，this 的类型变成 pointer to const object。
```

先不用死抠这句话。你可以记成：

```text
void print() const：
print 这个函数不会改对象内部状态。
```

所以这种函数里不能写：

```cpp
name_ = "changed";
```

会编译错误。

工程习惯：

```text
只读成员函数尽量加 const。
```

比如：

```cpp
std::string name() const;
int age() const;
void print() const;
```

这样 const 对象也能调用它们。

---

## 16. 写代码验证初始化列表、this、const 成员函数

创建文件：

```bash
touch 03_init_list_this.cpp
```

写入：

```cpp
#include <iostream>
#include <string>

class User {
public:
    User(const std::string& name, int age)
        : name_(name), age_(age) {
        std::cout << "construct User: " << name_ << std::endl;
    }

    ~User() {
        std::cout << "destruct User: " << name_ << std::endl;
    }

    void set_name(const std::string& name) {
        this->name_ = name;
    }

    const std::string& name() const {
        return name_;
    }

    int age() const {
        return age_;
    }

    void print() const {
        std::cout << "User{name = " << name_
                  << ", age = " << age_
                  << "}" << std::endl;
    }

private:
    std::string name_;
    int age_;
};

int main() {
    User u("fxor", 19);

    u.print();

    u.set_name("gpt");
    u.print();

    const User cu("const-user", 20);
    cu.print();

    // cu.set_name("bad"); // 取消注释会编译错误，因为 cu 是 const 对象

    return 0;
}
```

编译运行：

```bash
g++ -std=c++17 -Wall -Wextra -g 03_init_list_this.cpp -o 03_init_list_this
./03_init_list_this
```

观察：

```text
User 构造时调用构造函数
离开 main 时调用析构函数
set_name 可以修改对象
print / name / age 是 const 成员函数
const User cu 只能调用 const 成员函数
```

---

## 17. 这一小节你要能回答

```text
1. 成员初始化列表是什么？
2. 为什么推荐用成员初始化列表？
3. 成员变量的初始化顺序由什么决定？
4. this 是什么？
5. this->name_ 是什么意思？
6. void print() const 里的 const 是什么意思？
7. const 对象为什么不能调用非 const 成员函数？
```

---

# 第四部分：对象创建和销毁顺序

## 18. 后创建的先销毁

栈上局部对象有一个非常重要的规律：

```text
同一作用域里，先构造的后析构，后构造的先析构。
```

像栈一样：

```text
construct a
construct b
construct c

destruct c
destruct b
destruct a
```

这个规律后面学 RAII 非常重要。  
因为 RAII 依赖析构函数自动释放资源，而释放顺序会影响程序行为。

---

## 19. 写代码观察多个对象顺序

创建文件：

```bash
touch 04_object_lifetime_order.cpp
```

写入：

```cpp
#include <iostream>
#include <string>

class Tracer {
public:
    Tracer(const std::string& name)
        : name_(name) {
        std::cout << "construct " << name_ << std::endl;
    }

    ~Tracer() {
        std::cout << "destruct " << name_ << std::endl;
    }

private:
    std::string name_;
};

void foo() {
    std::cout << "enter foo" << std::endl;

    Tracer x("x");
    Tracer y("y");

    std::cout << "leave foo" << std::endl;
}

int main() {
    std::cout << "enter main" << std::endl;

    Tracer a("a");
    Tracer b("b");

    foo();

    std::cout << "leave main" << std::endl;
    return 0;
}
```

编译运行：

```bash
g++ -std=c++17 -Wall -Wextra -g 04_object_lifetime_order.cpp -o 04_object_lifetime_order
./04_object_lifetime_order
```

你要观察：

```text
main 里的 a、b 什么时候构造？
foo 里的 x、y 什么时候构造？
foo 结束时谁先析构？
main 结束时谁先析构？
```

---

## 20. 这一小节你要能回答

```text
1. 同一作用域里，多个对象的析构顺序是什么？
2. 函数 foo 结束时，foo 里的局部对象会不会析构？
3. 为什么这个顺序像“栈”？
4. 这个知识后面和 RAII 有什么关系？
```

第 4 题先简单答：

```text
RAII 会把资源释放放进析构函数，所以对象析构顺序会影响资源释放顺序。
```

---

# 第五部分：今天不要提前深挖的东西

今天先不要展开：

```text
new/delete
拷贝构造
拷贝赋值
移动构造
智能指针
虚函数
继承
多态
模板
RAII 完整设计
```

你可能见过这些东西，但今天不展开。  
Day3 只处理：

```text
class / struct
构造函数
析构函数
成员初始化列表
this
const 成员函数
栈上对象生命周期
```

这样不会乱。

---

# 第六部分：你的笔记写什么

笔记按你的习惯存。

建议至少写这些：

```markdown
# Day3 Notes

## 类和对象
- class 是什么：
- object 是什么：
- member variable 是什么：
- member function 是什么：
- class 和 struct 默认访问权限区别：

## 构造和析构
- constructor 是什么：
- destructor 是什么：
- 构造函数什么时候调用：
- 析构函数什么时候调用：
- lifetime 是什么：

## 成员初始化列表
- member initializer list 是什么：
- 为什么推荐用初始化列表：
- 成员初始化顺序由什么决定：

## this
- this 是什么：
- this->name_ 是什么意思：

## const 成员函数
- void print() const 是什么意思：
- const 对象能不能调用非 const 成员函数：

## 对象生命周期顺序
- 同一作用域对象析构顺序：
- 为什么说后构造的先析构：
```

不用写长，但要用自己的话。

---

# 第七部分：Day3 验收问题

做完后，把这些问题回答给我：

```text
1. class 和 struct 默认访问权限有什么区别？
2. private 有什么意义？
3. 什么是对象？
4. 构造函数什么时候调用？
5. 析构函数什么时候调用？
6. 构造函数为什么没有返回类型？
7. 析构函数为什么叫 ~ClassName？
8. 栈上对象什么时候析构？
9. 同一作用域中，多个对象的析构顺序是什么？
10. 成员初始化列表是什么？
11. 为什么推荐用成员初始化列表？
12. 成员变量初始化顺序由什么决定？
13. this 指针是什么？
14. void print() const 里的 const 是什么意思？
15. const 对象为什么只能调用 const 成员函数？
```

过关标准：

```text
能拿 Tracer / User 这两个例子解释，不是背定义。
```

---

# 第八部分：Git 提交

回到仓库根目录：

```bash
cd ~/code/system-learning
git status
git add .
git commit -m "week1 day3 class constructor destructor"
```

如果你要推到 GitHub：

```bash
git push
```

---

# Day3 完成标准

当你做到：

```text
4 个小代码能编译运行
能解释构造 / 析构输出顺序
能解释 this 和 const 成员函数
笔记写完
能回答 Day3 验收问题
完成一次 git commit
```

Day3 就结束。

下一步 Day4：

> **new/delete、new[]/delete[]、RAII 初步：理解为什么 C++ 面试有那么多内存坑。**
