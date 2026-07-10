# Day6：复盘 + 小型 Buffer/StringLike 练习

> Day6 目标：不急着冲新概念，把 Day4 / Day5 的资源管理真正写熟。  
> 你已经学过：
>
> ```text
> Day4：new / delete、new[] / delete[]、RAII
> Day5：拷贝构造、拷贝赋值、浅拷贝、深拷贝、Rule of Three
> ```
>
> 今天要做的不是“再学一堆新术语”，而是用两个小类把这套东西写成肌肉记忆。

今天的核心问题：

```text
如果一个类自己拥有一块堆内存，它应该怎么构造、析构、拷贝、赋值？
```

---

## 0. 今天你要拿下什么

做完 Day6，你应该能做到：

```text
1. 不看答案写出一个 RAII Buffer
2. 能禁止拷贝，解释为什么禁止
3. 能写出深拷贝版本
4. 能写出 copy assignment
5. 能处理 self-assignment
6. 能用 AddressSanitizer 检查内存错误
7. 能解释 Rule of Three 为什么是资源管理类的底线
8. 能把代码组织得比前几天更像工程代码
```

今天不是学新花活，而是把这条线打牢：

```text
裸资源
→ 构造获取资源
→ 析构释放资源
→ 默认拷贝危险
→ 深拷贝
→ 拷贝赋值
→ 自赋值
→ Rule of Three
```

---

## 1. 今天代码放哪里

```bash
cd ~/code/system-learning/cpp/week1
mkdir -p day6
cd day6
```

建议今天写 4 个文件：

```text
day6/
├── 01_buffer_no_copy.cpp
├── 02_buffer_deep_copy.cpp
├── 03_string_like.cpp
└── 04_review_questions.md
```

编译统一用：

```bash
g++ -std=c++17 -Wall -Wextra -g 文件名.cpp -o 输出名
```

建议都用 AddressSanitizer 再跑一遍：

```bash
g++ -std=c++17 -Wall -Wextra -g -fsanitize=address 文件名.cpp -o 输出名
```

今天的目标不是“写得很高级”，而是：

```text
写对
能跑
能解释
没有 double free
没有明显 memory leak
```

---

# 第一部分：先口头复盘 Day4 / Day5

## 2. 你先自己回答这 10 个问题

不用写长篇，每个问题 1~3 句话即可。

```text
1. new 做了哪两件事？
2. delete 做了哪两件事？
3. new[] 和 delete[] 为什么要配对？
4. RAII 的核心思想是什么？
5. 为什么裸 owning pointer 很危险？
6. 默认拷贝通常做什么？
7. 浅拷贝为什么会 double delete？
8. 深拷贝怎么解决问题？
9. 拷贝构造和拷贝赋值有什么区别？
10. Rule of Three 是什么？
```

你可以把答案写在：

```bash
touch 04_review_questions.md
```

这是 Day6 的第一个验收点。

---

# 第二部分：Buffer V1：只允许使用，不允许拷贝

## 3. 先写一个禁止拷贝的 Buffer

这个版本和 Day4 的 `IntBuffer` 很像，但今天你要尽量自己写，不要复制。

目标：

```text
Buffer 管理一块 char 数组
构造函数申请内存
析构函数释放内存
提供 set / get / size
禁止拷贝构造
禁止拷贝赋值
```

创建文件：

```bash
touch 01_buffer_no_copy.cpp
```

你先自己写。写不出来再参考下面版本。

参考实现：

```cpp
#include <cstddef>
#include <iostream>

class Buffer {
public:
    explicit Buffer(std::size_t size)
        : size_(size), data_(new char[size]) {
        std::cout << "Buffer construct, size = " << size_
                  << ", data = " << static_cast<void*>(data_) << std::endl;

        for (std::size_t i = 0; i < size_; ++i) {
            data_[i] = '\0';
        }
    }

    ~Buffer() {
        std::cout << "Buffer destruct, size = " << size_
                  << ", data = " << static_cast<void*>(data_) << std::endl;
        delete[] data_;
    }

    void set(std::size_t index, char value) {
        if (index < size_) {
            data_[index] = value;
        }
    }

    char get(std::size_t index) const {
        if (index < size_) {
            return data_[index];
        }
        return '\0';
    }

    std::size_t size() const {
        return size_;
    }

    Buffer(const Buffer&) = delete;
    Buffer& operator=(const Buffer&) = delete;

private:
    std::size_t size_;
    char* data_;
};

int main() {
    Buffer buf(5);

    buf.set(0, 'A');
    buf.set(1, 'B');

    std::cout << "buf[0] = " << buf.get(0) << std::endl;
    std::cout << "buf[1] = " << buf.get(1) << std::endl;

    return 0;
}
```

编译运行：

```bash
g++ -std=c++17 -Wall -Wextra -g 01_buffer_no_copy.cpp -o 01_buffer_no_copy
./01_buffer_no_copy
```

再用 ASan 跑：

```bash
g++ -std=c++17 -Wall -Wextra -g -fsanitize=address 01_buffer_no_copy.cpp -o 01_buffer_no_copy_asan
./01_buffer_no_copy_asan
```

你要观察：

```text
构造一次
析构一次
没有内存错误
```

---

## 4. 这一节你要能回答

```text
1. 为什么 Buffer 要禁止拷贝？
2. 如果不禁止拷贝，默认拷贝会复制什么？
3. char* data_ 是资源本身吗，还是资源的地址？
4. 析构函数里为什么要 delete[] data_？
5. delete[] data_ 以后 data_ 指向的数组还活着吗？
```

这里的重点是第 3 题：

```text
data_ 不是资源本身。
data_ 是保存资源地址的指针。
真正的资源是堆上的 char 数组。
```

---

# 第三部分：Buffer V2：允许深拷贝

## 5. 写一个支持深拷贝的 Buffer

现在把 V1 改成可以拷贝。

目标：

```text
Buffer a(5);
Buffer b = a;
```

之后应该满足：

```text
a 和 b 的 data_ 地址不同
a 和 b 的内容一样
改 b 不影响 a
析构时各删各的，不 double delete
```

创建文件：

```bash
touch 02_buffer_deep_copy.cpp
```

先自己写，重点是：

```cpp
Buffer(const Buffer& other)
```

参考实现：

```cpp
#include <cstddef>
#include <iostream>

class Buffer {
public:
    explicit Buffer(std::size_t size)
        : size_(size), data_(new char[size]) {
        std::cout << "construct, size = " << size_
                  << ", data = " << static_cast<void*>(data_) << std::endl;

        for (std::size_t i = 0; i < size_; ++i) {
            data_[i] = '\0';
        }
    }

    Buffer(const Buffer& other)
        : size_(other.size_), data_(new char[other.size_]) {
        std::cout << "copy construct, from "
                  << static_cast<void*>(other.data_)
                  << " to "
                  << static_cast<void*>(data_) << std::endl;

        for (std::size_t i = 0; i < size_; ++i) {
            data_[i] = other.data_[i];
        }
    }

    Buffer& operator=(const Buffer& other) {
        std::cout << "copy assignment" << std::endl;

        if (this == &other) {
            std::cout << "self assignment" << std::endl;
            return *this;
        }

        char* new_data = new char[other.size_];

        for (std::size_t i = 0; i < other.size_; ++i) {
            new_data[i] = other.data_[i];
        }

        delete[] data_;

        data_ = new_data;
        size_ = other.size_;

        return *this;
    }

    ~Buffer() {
        std::cout << "destruct, size = " << size_
                  << ", data = " << static_cast<void*>(data_) << std::endl;
        delete[] data_;
    }

    void set(std::size_t index, char value) {
        if (index < size_) {
            data_[index] = value;
        }
    }

    char get(std::size_t index) const {
        if (index < size_) {
            return data_[index];
        }
        return '\0';
    }

    std::size_t size() const {
        return size_;
    }

private:
    std::size_t size_;
    char* data_;
};

int main() {
    Buffer a(3);
    a.set(0, 'A');
    a.set(1, 'B');

    std::cout << "copy construct b from a" << std::endl;
    Buffer b = a;

    b.set(0, 'X');

    std::cout << "a[0] = " << a.get(0) << std::endl;
    std::cout << "b[0] = " << b.get(0) << std::endl;

    std::cout << "copy assignment c = a" << std::endl;
    Buffer c(1);
    c = a;

    std::cout << "c[0] = " << c.get(0) << std::endl;

    std::cout << "self assignment a = a" << std::endl;
    a = a;

    return 0;
}
```

编译运行：

```bash
g++ -std=c++17 -Wall -Wextra -g 02_buffer_deep_copy.cpp -o 02_buffer_deep_copy
./02_buffer_deep_copy
```

ASan：

```bash
g++ -std=c++17 -Wall -Wextra -g -fsanitize=address 02_buffer_deep_copy.cpp -o 02_buffer_deep_copy_asan
./02_buffer_deep_copy_asan
```

你要观察：

```text
copy construct 时 from 和 to 地址不同
a[0] 还是 A
b[0] 变成 X
copy assignment 正常执行
self assignment 被识别
ASan 不报错
```

---

## 6. 拷贝赋值的顺序再强调一次

不要优先写这种：

```cpp
delete[] data_;
data_ = new char[other.size_];
```

更好的写法是：

```cpp
char* new_data = new char[other.size_];

// 先复制到新资源
for (...) {
    new_data[i] = other.data_[i];
}

// 新资源准备好了，再释放旧资源
delete[] data_;

data_ = new_data;
size_ = other.size_;
```

直觉：

```text
先造好新船，再拆旧船。
不要先把旧船砸了，再发现新船造不出来。
```

这就是异常安全的影子。  
今天不系统学异常安全，但这个顺序要有意识。

---

# 第四部分：StringLike：第一次写一点像 std::string 的东西

## 7. 为什么要写 StringLike

`Buffer` 只是数组。  
`StringLike` 更接近真实 C++ 里的 `std::string`。

今天的 StringLike 只做最小功能：

```text
从 const char* 构造
析构释放内存
拷贝构造深拷贝
拷贝赋值深拷贝
c_str() 返回内部字符串
size() 返回长度
```

注意：这不是让你造工业级 string。  
只是用字符串例子再练一次资源管理。

---

## 8. 需要的 C 字符串函数

今天会用：

```cpp
#include <cstring>
```

里面有：

```cpp
std::strlen(s)
std::memcpy(dst, src, n)
```

作用：

```text
strlen：计算 C 字符串长度，不包含结尾 '\0'
memcpy：按字节复制内存
```

例如：

```cpp
const char* s = "hello";
std::strlen(s); // 5
```

但真正存储时要多申请一个字符：

```text
'h' 'e' 'l' 'l' 'o' '\0'
```

所以：

```cpp
size_ = std::strlen(s);
data_ = new char[size_ + 1];
```

最后的 `+1` 是给 `\0` 的。

---

## 9. 写 StringLike

创建文件：

```bash
touch 03_string_like.cpp
```

参考实现：

```cpp
#include <cstddef>
#include <cstring>
#include <iostream>

class StringLike {
public:
    explicit StringLike(const char* s)
        : size_(std::strlen(s)), data_(new char[size_ + 1]) {
        std::memcpy(data_, s, size_ + 1);

        std::cout << "construct: " << data_
                  << ", data = " << static_cast<void*>(data_) << std::endl;
    }

    StringLike(const StringLike& other)
        : size_(other.size_), data_(new char[other.size_ + 1]) {
        std::memcpy(data_, other.data_, size_ + 1);

        std::cout << "copy construct: " << data_
                  << ", data = " << static_cast<void*>(data_) << std::endl;
    }

    StringLike& operator=(const StringLike& other) {
        std::cout << "copy assignment" << std::endl;

        if (this == &other) {
            std::cout << "self assignment" << std::endl;
            return *this;
        }

        char* new_data = new char[other.size_ + 1];
        std::memcpy(new_data, other.data_, other.size_ + 1);

        delete[] data_;

        data_ = new_data;
        size_ = other.size_;

        return *this;
    }

    ~StringLike() {
        std::cout << "destruct: " << data_
                  << ", data = " << static_cast<void*>(data_) << std::endl;
        delete[] data_;
    }

    const char* c_str() const {
        return data_;
    }

    std::size_t size() const {
        return size_;
    }

private:
    std::size_t size_;
    char* data_;
};

int main() {
    StringLike a("hello");

    StringLike b = a;

    std::cout << "a = " << a.c_str() << std::endl;
    std::cout << "b = " << b.c_str() << std::endl;

    StringLike c("world");
    c = a;

    std::cout << "c = " << c.c_str() << std::endl;

    a = a;

    return 0;
}
```

编译运行：

```bash
g++ -std=c++17 -Wall -Wextra -g 03_string_like.cpp -o 03_string_like
./03_string_like
```

ASan：

```bash
g++ -std=c++17 -Wall -Wextra -g -fsanitize=address 03_string_like.cpp -o 03_string_like_asan
./03_string_like_asan
```

你要观察：

```text
copy construct 出现
copy assignment 出现
self assignment 出现
每个对象析构时 data 地址不同
ASan 不报错
```

---

## 10. StringLike 的关键坑

### 坑 1：忘记给 `\0` 留位置

错误写法：

```cpp
data_ = new char[size_];
std::memcpy(data_, s, size_);
```

这样没有拷贝 `\0`，后面 `std::cout << data_` 可能乱跑。

正确写法：

```cpp
data_ = new char[size_ + 1];
std::memcpy(data_, s, size_ + 1);
```

### 坑 2：析构函数里打印 data_

这里我们写：

```cpp
std::cout << "destruct: " << data_ << std::endl;
delete[] data_;
```

这是可以的，因为打印发生在 `delete[]` 前。

不要写：

```cpp
delete[] data_;
std::cout << data_ << std::endl; // 错
```

这就是 use-after-free。

### 坑 3：自赋值

```cpp
a = a;
```

必须能正常处理。

否则你可能先把 `a.data_` 删掉，再从 `other.data_` 拷贝。  
但 `other` 就是 `a`，所以你已经把源数据删了。

---

# 第五部分：今天的面试追问

## 11. 面试官会怎么追

这些问题以后高频：

```text
1. 一个类里有裸指针，默认拷贝会发生什么？
2. 什么是浅拷贝？
3. 什么是深拷贝？
4. 为什么浅拷贝会 double free？
5. 拷贝构造和拷贝赋值有什么区别？
6. 拷贝赋值为什么要判断 self-assignment？
7. operator= 为什么返回 T&？
8. Rule of Three 是什么？
9. 为什么 std::string / std::vector 比裸数组安全？
10. 你这个 StringLike 和 std::string 差在哪里？
```

第 10 题你可以这样答：

```text
我的 StringLike 只是为了练资源管理。
它只支持构造、析构、拷贝构造、拷贝赋值、c_str 和 size。
真实 std::string 还要处理容量、扩容、移动语义、小字符串优化、迭代器、异常安全、更多接口等。
```

别装。  
面试里承认 toy 和工业级组件的差距，反而更稳。

---

# 第六部分：今天不要提前深挖

今天先不要展开：

```text
move constructor
move assignment
std::move
Rule of Five
copy-and-swap 完整版
SSO，小字符串优化
std::allocator
placement new
智能指针详细机制
```

Day6 只做：

```text
复盘
Buffer
StringLike
Rule of Three 熟练度
ASan 初步检查
```

---

# 第七部分：今天笔记写什么

建议写：

```markdown
# Day6 Notes

## Day4 / Day5 复盘
- new 做了什么：
- delete 做了什么：
- RAII 是什么：
- 浅拷贝是什么：
- 深拷贝是什么：
- Rule of Three 是什么：

## Buffer 练习
- Buffer V1 为什么禁止拷贝：
- Buffer V2 为什么可以拷贝：
- copy constructor 里做了什么：
- copy assignment 里做了什么：
- 为什么要先申请新资源，再释放旧资源：

## StringLike 练习
- 为什么需要 size_ + 1：
- '\0' 是什么：
- c_str() 返回什么：
- StringLike 和 std::string 差在哪里：

## 今天踩坑
- 编译错误：
- 运行错误：
- ASan 有没有报错：
- 我怎么修的：
```

---

# 第八部分：Day6 验收问题

做完后，把这些问题回答给我：

```text
1. Buffer V1 为什么要禁止拷贝？
2. Buffer V2 的拷贝构造为什么是深拷贝？
3. copy assignment 里为什么要判断 this == &other？
4. copy assignment 为什么推荐先 new 新资源，再 delete 旧资源？
5. StringLike 为什么要分配 size_ + 1 个 char？
6. '\0' 在 C 字符串里有什么作用？
7. c_str() 返回的是什么？
8. StringLike 里的 data_ 是资源本身还是资源地址？
9. Rule of Three 三个函数分别是什么？
10. 你现在怎么判断一个类需不需要自己写 Rule of Three？
11. AddressSanitizer 今天帮你检查什么？
12. 你这个 StringLike 和 std::string 差在哪里？
```

过关标准：

```text
能不看答案写出 Buffer 的 Rule of Three。
能解释 StringLike 为什么要处理 '\0'。
能用 ASan 跑一次不报错。
```

---

# 第九部分：Git 提交

回到仓库根目录：

```bash
cd ~/code/system-learning
git status
git add .
git commit -m "week1 day6 buffer stringlike review"
```

如果你要推到 GitHub：

```bash
git push
```

---

# Day6 完成标准

当你做到：

```text
01_buffer_no_copy.cpp 能编译运行
02_buffer_deep_copy.cpp 能编译运行
03_string_like.cpp 能编译运行
至少一个程序用 ASan 跑过
04_review_questions.md 写完
能解释 Buffer 的 Rule of Three
能解释 StringLike 的 size_ + 1 和 '\0'
能回答 Day6 验收问题
完成一次 git commit
```

Day6 就结束。

下一步 Day7 暂定：

> **Week1 总复盘 + 小测：检查指针、引用、const、class、构造析构、new/delete、RAII、拷贝控制是否真的连起来。**
