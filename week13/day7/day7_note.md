# R2

## 要让两种处理器共用入口，先让它们有共同的类型

```cpp
#include <iostream>
#include <string>

class Sink {
public:
    explicit Sink(int id) : id_(id) {}
    int id() const { return id_; }
    void write(const std::string&) { std::cout << "Sink\n"; }
private:
    int id_;
};

class ConsoleSink : public Sink {
public:
    ConsoleSink() : Sink(7) {}
    void write(const std::string& text) {
        std::cout << "Console: " << text << '\n';
    }
};

// Borrow the existing object through its Sink interface.
void deliver(Sink& sink, const std::string& text) {
    sink.write(text);
}

int main() {
    ConsoleSink console;
    std::cout << console.id() << '\n';
    console.write("hello");
    deliver(console, "hello");
}
```

### Sink 类型的 sink 为啥能接收

deliver 的 sink 的类型是 Sink，但是在这里是能够接收 Consolesink 的对象的。

原因在：**Consolesink 是 Sink 的派生类，所以允许外部把 console 交给接收 Sink 类型的函数**。& 表示引用。

### 为啥最后打印 Sink？

因为，参数是 `Sink&`，在这个位置使用的是 Sink 声明的操作。并且 write 是普通成员函数，所以选中 `Sink::write`。

## virtual让同一个入口执行实际对象的实现

```cpp
#include <cstddef>
#include <iostream>
#include <string>

class Sink {
public:
    virtual void write(const std::string&) { std::cout << "Sink\n"; }
};

class ConsoleSink : public Sink {
public:
    void write(const std::string& text) override {
        std::cout << "Console: " << text << '\n';
    }
};

class CountingSink : public Sink {
public:
    void write(const std::string& text) override { bytes_ += text.size(); }
    std::size_t bytes() const { return bytes_; }
private:
    std::size_t bytes_ = 0;
};

// Both calls use the same interface; no ownership is transferred.
void deliver(Sink& sink, const std::string& text) { sink.write(text); }

int main() {
    ConsoleSink console;
    CountingSink counter;
    deliver(console, "abc");
    deliver(counter, "abc");
    std::cout << "bytes=" << counter.bytes() << '\n';
}
```

**`virtual`把这个成员函数声明为虚函数：像本例这样通过基类引用调用时，使用所借对象为它提供的实现。** ConsoleSink和CountingSink各自提供write，叫对这个虚函数的**override（重写）**。

### 两次各自借到的对象不同

```text
deliver(console, "abc")
  -> sink这次借到console
  -> sink.write("abc")进入ConsoleSink的write
  -> 打印 Console: abc

deliver(counter, "abc")
  -> sink这次借到counter
  -> sink.write("abc")进入CountingSink的write
  -> counter内部的bytes_从0变成3
```

### 借到 counter，为啥不能写 sink.bytes()

因为虽然，`counter.bytes()` 合法。

但是，在 deliver 里，编译器按照参数类型的 `Sink&` 检查代码。发现 `Sink` 类型声明了 write，没有声明 bytes。所以会编译失败。

并且，你不能保证传进去的 Sink 永远是 counter 类型，可能是 console。

### 判断能不能调用某个接口

- **这行调用能不能写：** `sink.write(text)`能写，因为Sink公开声明了write。
- **合法调用最终执行谁：** **write声明为virtual，所以本次借到counter就执行CountingSink的write，借到console就执行ConsoleSink的write**。

### static type, dynamic type

#### static type

deliver 的参数声明写了 `Sink&`。编译器据此，把 `sink` 这个表达式，按照 `Sink` 的类型检查。

**这个表达式在代码中确定的类型，叫做 static type（静态类型）**

#### dynamic type

但是我们 main 中传给 sink 的实际对象，是 `Consolesink/CountingSink` 类型的。所以，对于这里引用访问的完整对象，**其实际类型叫做 dynamic type**

### 看表

| 本次调用                  | 函数体里的sink按什么类型检查 | 这次实际借到什么对象 | virtual write执行哪份实现 |
| ------------------------- | ---------------------------- | -------------------- | ------------------------- |
| `deliver(console, "abc")` | Sink                         | ConsoleSink          | ConsoleSink的write        |
| `deliver(counter, "abc")` | Sink                         | CountingSink         | CountingSink的write       |

### 多态，分派

**同一个deliver调用方式，可以表现出打印和计数两种行为，这叫polymorphism（多态）。** 对这次virtual调用选择实际执行的write，则叫**dispatch（调用分派）**。

## 明确对 override 加上 `override`

```cpp
#include <string>
struct Sink {
    virtual void write(const std::string&) {}
};
struct BrokenSink : Sink {
    void write(int) override {}
};
int main() {}
```

**override是在请编译器检查：我写的这个函数，确实接替了基类已有的某个虚函数。** 去掉override并不能把错误签名变成重写，只会失去这次**显式检查**。

去掉 override 的话，其实 BrokenSink 的 write 相当于一个普通的成员函数而已。不是对基类的虚函数的重写。

## 纯虚函数，抽象类

可以把Sink中的那一行改为`virtual void write(const std::string& text) = 0;`。这表示：**这里只规定共同操作，具体处理器必须补出实现，才能创建那种对象。** 这样的函数叫**pure virtual function（纯虚函数）**。`= 0`是声明语法，不是让函数返回0。

改完以后，`ConsoleSink console;`仍可创建，因为它已经实现write；`Sink sink;`则会编译失败，因为它还没有可用的write实现。这种仍有纯虚函数待实现、不能直接创建实例的类，叫**abstract class（抽象类）**。

`Sink&`仍有用途：它借用的是已经完整实现write的ConsoleSink。**不能直接创建Sink，与能借用一个具体对象的Sink部分，是两件事。** 

## 如果调用者，还负责保存并且销毁 sink。使用 `unique_ptr<Sink>`

> 假设现在要把处理器保存下来，并在结束时自动释放，可以复用你已经会的`unique_ptr`。

新问题在于：变量的类型统一写`unique_ptr<Sink>`，实际创建的却是ConsoleSink。我们要确认**它既能正确调用ConsoleSink的write，也能在结束时完整销毁ConsoleSink**。

```cpp
#include <iostream>
#include <memory>
#include <string>

class Sink {
public:
    virtual void write(const std::string& text) = 0;
    virtual ~Sink() { std::cout << "destroy Sink\n"; }
};

class ConsoleSink : public Sink {
public:
    void write(const std::string& text) override {
        std::cout << "Console: " << text << '\n';
    }
    ~ConsoleSink() override { std::cout << "destroy ConsoleSink\n"; }
};

int main() {
    // The owner holds the complete ConsoleSink through the common interface.
    std::unique_ptr<Sink> owner = std::make_unique<ConsoleSink>();
    owner->write("hello");
}
```

```text
输出
Console: hello
destroy ConsoleSink
destroy Sink
```

```text
main 结束，owner 会去析构 unique_ptr 指向的对象。

unique_ptr 的是 Sink 指针。

Sink 的析构是 virtual，所以会先执行 ConsoleSink 的析构。

此时，ConsoleSink 已经析构，也就是已经结束派生成员。最后结束 Sink 基类部分。也就是调用 Sink 的析构函数。
```

**本例要通过`unique_ptr<Sink>`的默认删除方式销毁ConsoleSink，所以Sink必须有公开的虚析构。** 在C++17中，若**删掉这里的virtual，再经Sink指针删除ConsoleSink，会成为未定义行为**。

## 对象还没构造完，调用虚函数的话，会怎么调用？

```cpp
#include <iostream>
struct Base {
    Base() { std::cout << "Base ctor: " << kind() << '\n'; }
    virtual const char* kind() const { return "Base"; }
    virtual ~Base() { std::cout << "Base dtor: " << kind() << '\n'; }
};
struct Derived : Base {
    Derived() { std::cout << "Derived ctor: " << kind() << '\n'; }
    const char* kind() const override { return "Derived"; }
    ~Derived() override { std::cout << "Derived dtor: " << kind() << '\n'; }
};
int main() {
    Derived object;
    Base& reference = object;
    std::cout << "ready: " << reference.kind() << '\n';
}
```

```text
Base ctor: Base
Derived ctor: Derived
ready: Derived
Derived dtor: Derived
Base dtor: Base
```

| 当前执行到哪里        | kind这次返回什么 | 为什么在这一层                                |
| --------------------- | ---------------- | --------------------------------------------- |
| Base构造函数          | Base             | 正在建立Base部分，Derived层尚未完成           |
| Derived构造函数       | Derived          | 已进入Derived这一层的构造                     |
| main通过reference调用 | Derived          | 完整Derived已构造好，回到前面普通虚调用的情形 |
| Derived析构函数       | Derived          | 当前还在执行Derived层的收尾                   |
| Base析构函数          | Base             | Derived层已结束，正在收尾Base部分             |

因此规则可以从这五行收束出来：**构造/析构期间，对当前这个对象的虚调用，按当前正在构造/析构的这一层选择实现，不继续走向更派生的层。** 本例两层都写了自己的kind，所以分别打印Base或Derived。正常使用时按完整对象选择，建立或结束过程中按当前层选择；关键是调用发生在哪个阶段。

## 为啥是先析构 Derived，再析构 Base？

> **一句话：我们在 Derived 的构造函数，可能需要用到 Base 的成员，所以要求此时 Base 必须构造好了。我们在 Derived 的析构函数，可能用到 Base 的成员，所以要求此时 Base 还存在。**
>
> 所以顺序是：
>
> 构造 Base；构造 Derived；析构 Derived；析构 Base；

对，你这个理解方向是对的。更准确地说：

在继承关系里，**构造顺序是 `Base → Derived`，析构顺序是 `Derived → Base`**。

你可以继续用“树”的感觉来理解：`Base` 像主干，`Derived` 像建立在主干之上的枝叶。要先有主干，枝叶才能建立起来，所以：

```cpp
class Base {
public:
    Base()  { cout << "Base construct\n"; }
    ~Base() { cout << "Base destruct\n"; }
};

class Derived : public Base {
public:
    Derived()  { cout << "Derived construct\n"; }
    ~Derived() { cout << "Derived destruct\n"; }
};
```

创建：

```cpp
Derived d;
```

顺序是：

```text
Base construct
Derived construct
```

因为执行 `Derived` 构造函数体的时候，程序默认认为：**它依赖的 Base 部分已经是一个完整、有效的对象了。**

而析构正好反过来：

```text
Derived destruct
Base destruct
```

这里你说的“像栈一样”也很好理解，可以想象成：

```text
构造：

Base
 ↓
Derived
 ↓
完整的 Derived 对象
```

拆的时候：

```text
完整的 Derived 对象
 ↓
Derived 先拆
 ↓
Base 再拆
```

也就是典型的 **后构造的先析构（LIFO）**。

这样设计还有一个很实际的原因。比如：

```cpp
class Base {
protected:
    int value = 10;
};

class Derived : public Base {
public:
    Derived() {
        cout << value;
    }
};
```

`Derived` 的构造函数里可能直接使用 `Base` 提供的 `value`、函数、资源等。

所以进入：

```cpp
Derived::Derived()
```

之前，`Base` 必须已经构造好了。

反过来析构的时候，`Derived` 的析构函数也可能还需要使用 `Base` 的东西，所以必须让：

```text
Derived::~Derived()
```

先执行，此时 `Base` 仍然存在。

等 `Derived` 自己清理完了以后，再执行：

```text
Base::~Base()
```

所以可以记成一句：

> **先搭地基，再盖楼；拆楼时先拆上层，再拆地基。**

其实这个规律不只适用于继承，C++ 整个对象生命周期基本都遵循这种“**构造正序，析构逆序**”的思想。

比如一个类里面还有成员：

```cpp
class Derived : public Base {
    A a;
    B b;
};
```

大致构造顺序：

```text
Base
A
B
Derived
```

析构则完全反过来：

```text
Derived
B
A
Base
```

所以你脑子里把它理解成**一层一层压栈，再一层一层退栈**，是非常好用的模型。

## 基类引用保留原对象，按值复制会创建另一个对象

> 一句话：**基类引用会实际去看看借来的对象的类型**，并且去找虚函数在 derived 的实现。
>
> 按值复制，复制出的新的基类对象，是只包含基类的内容。

```cpp
#include <iostream>
struct Base {
    int id = 7;
    virtual const char* kind() const { return "Base"; }
    virtual ~Base() = default;
};
struct Derived : Base {
    int extra = 9;
    const char* kind() const override { return "Derived"; }
};
int main() {
    Derived object;
    Base& reference = object;
    Base copy = object;
    std::cout << reference.kind() << ' ' << copy.kind() << '\n';
    std::cout << object.extra << ' ' << copy.id << '\n';
}
```

结果是`Derived Base`和`9 7`。先画出这时真正存在的对象：

```text
object：原来的Derived
  Base部分：id = 7
  自己增加的成员：extra = 9
  reference借用这里的Base部分

copy：新创建的Base
  id = 7
  没有extra成员
```

```text
reference.kind，因为借来的 reference 其实是 object，是 Derived 类型的，所以会调用 Derived::kind

copy.kind 因为 copy 是 Base 类型的，所以调用的是 Base::kind
```

**从派生对象复制出一个基类值时，新对象只包含基类那部分内容，这叫object slicing（对象切片）。** 函数参数写成`void use(Base value)`也会创建这样的值；写成`Base&`则借用原对象。

## 编译器怎么找到派生实现？

先想一个可行的实现办法：为ConsoleSink准备一份“write对应ConsoleSink::write”的函数地址信息；为CountingSink准备另一份“write对应CountingSink::write”的信息。每个对象关联到适合自己的那一份，调用时就有地方找到目标函数。

```text
基类引用借用 ConsoleSink 对象
        ↓
对象关联的虚表信息
        ↓
write 对应的入口
        ↓
ConsoleSink::write

另一个 CountingSink 对象
        ↓
另一份类型相关的入口信息
        ↓
CountingSink::write
```

图里那份保存虚函数入口的表，通常叫**vtable（虚函数表）**；对象中关联到这张表的指针，通常叫**vptr（虚表指针）**。名字是在概括刚才的“对象怎样找到对应函数地址”。

`vptr` 就是 **virtual table pointer（虚表指针）**，它通常存**放在对象内部**，用来**指向这个对象所属类型对应的虚函数表 `vtable`**。

可以想成：

```text
对象
+------------------+
| 普通成员变量     |
|                  |
| vptr ----------- | --------+
+------------------+          |
                              v
                       +--------------+
                       | vtable       |
                       +--------------+
                       | &func1       |
                       | &func2       |
                       | &func3       |
                       +--------------+
```

## 基类引用，调用普通成员函数

对，你的理解基本正确！尤其是你把 `vptr`、`vtable` 和函数调用联系起来的思路是对的。不过这里有一个关键细节需要纠正：不是程序去虚表里找不到 `label()`，而是因为 `label()` 不是虚函数，编译器根本就不需要通过虚表查找它。

我们结合你的代码，一步一步看。

### 1. 为什么最后调用的是 `Task::label()`？

你的代码：

```cpp
class Task {
public:
    void label() {
        std::cout << "Task\n";
    }
};

class FirstTask : public Task {
public:
    void label() {
        std::cout << "FirstTask\n";
    }
};

void work(Task& task) {
    task.label();
}
```

在 `main()` 里面：

```
FirstTask task;
work(task);
```

这里有两个不同的概念：

- 实际对象类型（Actual type）：`FirstTask`
- 引用的静态类型（Static type）：`Task&`

虽然传进去的实际对象是 `FirstTask`，但是 `work()` 函数里，编译器看到的 `task` 的静态类型是 `Task&`。

而 `label()` 不是虚函数，因此编译器在编译阶段就确定了调用哪个函数：

```
void work(Task& task) {
    task.label();  // 编译时确定调用 Task::label()
}
```

最终输出：

```
Task
```

### 2. 那么，虚表在这里发挥作用了吗？

没有。 你的理解可以这样调整：

#### 当前代码：非虚函数

`FirstTask` 对象

通过 Task& 引用访问

根据静态类型 `Task&`，编译时绑定

调用 `Task::label()`

不需要通过 vptr 查找 vtable。

你原本的说法是“`FirstTask` 的虚表里没有这个函数”。

更准确地说：由于这两个类都没有声明任何虚函数，按照常见的 C++ 编译器实现，它们通常根本不需要虚表和虚表指针。 所以这里并不是在虚表里找不到 `label()`，而是整个调用过程就没有使用虚表。

### 3. 如果把 `label()` 改成虚函数呢？

只需要在基类中增加一个 `virtual`：

```
class Task {
public:
    virtual void label() {
        std::cout << "Task\n";
    }
};

class FirstTask : public Task {
public:
    void label() override {
        std::cout << "FirstTask\n";
    }
};
```

其他代码保持不变：

```
void work(Task& task) {
    task.label();
}

int main() {
    FirstTask task;
    work(task);
}
```

这次输出就变成：

```
FirstTask
```

原因是：

#### 当前代码：虚函数

`FirstTask` 对象

`vptr` 指向对应的 `vtable`

找到 `FirstTask::label()` 的函数入口

调用 `FirstTask::label()`

这里的关键是：`FirstTask::label()` 覆盖（override）了基类的虚函数，因此通过 `Task&` 调用时，会根据对象的实际动态类型进行动态绑定。

### 4. 最后记住这张对比表

| 对比项                        | 非虚函数            | 虚函数                  |
| -------------------------- | --------------- | -------------------- |
| 绑定方式                       | 静态绑定            | 动态绑定                 |
| 主要依据                       | 表达式的静态类型        | 对象的动态类型              |
| 是否需要通过虚表调用                 | 不需要             | 通常需要                 |
| `Task&` 引用 `FirstTask` 对象时 | `Task::label()` | `FirstTask::label()` |

还有一个容易忽略的细节：在你原来的代码中，`FirstTask::label()` 并不是严格意义上的虚函数覆盖，而是隐藏了基类中同名的非虚函数。

所以，你可以把整个知识点浓缩成一句话：

非虚函数看静态类型，虚函数看动态类型。 这正是 C++ 中静态绑定和动态绑定的核心区别。

## 编译器怎么对待虚函数/非虚函数

对！你已经把 C++ 中静态绑定和动态绑定的整个调用逻辑串起来了。你的理解基本正确，我帮你把其中几个关键细节再捋顺一下。

### 一、编译器首先确定调用规则

当编译器遇到一个函数调用时，**它会根据函数的声明，判断这是虚函数调用还是非虚函数调用**。

#### 情况 1：非虚函数

例如：

```cpp
class Task {
public:
    void label() {
        std::cout << "Task\n";
    }
};

class FirstTask : public Task {
public:
    void label() {
        std::cout << "FirstTask\n";
    }
};

void work(Task& task) {
    task.label();
}
```

这里的 `label()` 不是虚函数。

编译器根据 `task` 的静态类型 `Task&`，就可以确定调用 `Task::label()`。

即使传进来的实际对象是 `FirstTask`，也不会因为对象的实际类型不同而自动改为调用派生类的函数。

可以理解为：

```cpp
编译阶段
   ↓
看到 task 的静态类型是 Task&
   ↓
label() 不是虚函数
   ↓
确定调用 Task::label()
```

#### 情况 2：虚函数

如果基类声明了 `virtual`：

```cpp
class Task {
public:
    virtual void label() {
        std::cout << "Task\n";
    }
};
```

那么通过 `Task&` 调用 `label()` 时，情况就不同了。

```cpp
void work(Task& task) {
    task.label();
}
```

**编译器知道这是一个虚函数调用。它需要遵循动态绑定的规则**：根据实际对象的动态类型，确定最终执行哪个版本的函数。

在常见的 C++ 实现中，执行过程可以理解为：

1\. 实际对象是 `FirstTask`

2\. 读取对象中的 `vptr`

3\. 通过 `vptr` 找到对应的 `vtable`

4\. 找到 `label()` 对应的函数入口

5\. 执行 `FirstTask::label()`

这里需要注意：**编译器在编译阶段就知道应该进行虚函数分派**，但通常要到**运行阶段，才能根据实际对象的动态类型确定最终调用的函数**。

### 二、用一句话区分两者

|      | 非虚函数         | 虚函数                     |
| ---- | ------------ | ----------------------- |
| 编译阶段 | 通常就能确定具体调用目标 | 确定采用虚函数分派规则             |
| 最终依据 | 静态类型         | 动态类型                    |
| 常见实现 | 直接调用相应函数     | 通过 `vptr` 和 `vtable` 分派 |

你可以把整个过程记成：

- 非虚函数： 编译器根据你声明时看到的类型，确定调用哪个函数。
- 虚函数： **编译器确定这是虚调用**，**运行时再根据实际对象的类型**，决定调用哪个覆盖版本。

最后补充一点：`vptr` 和 `vtable` 是常见的编译器实现机制，并不是 C++ 标准强制规定的底层结构；另外，编译器有时也能通过优化，在编译阶段直接确定虚函数的调用目标。但这不影响你现在建立的理解模型。