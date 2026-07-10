## 几个术语

owning pointer: 就是自己是个指针，指向一个对象，并且还负责释放资源（就是要 delete）

non-owning pointer: 自己是个指针，指向一个对象，但是不负责释放资源，就是借用一下那块内存观察而已。

## unique_ptr

### 为啥用这个：

我们之前在类里面写 `char* data_` 太麻烦了！我们要考虑析构时的释放资源、move、copy、assignment 等等问题，手动写 new，delete，这样太复杂了！！！

如果我们只是想表达一个对象独占一块资源，并且生命结束资源自动释放，那就可以用 `std::unique_ptr`。

### 咋用的：

`std::unique_ptr<int> p = std::make_unique<int>(42);`

此时，p 就是一个 unique_ptr，指向一块内存，这块内存上存放着 int 类型的数据，值为 42。

unique_ptr 只能 move，不能 copy，因为 copy 的话就不是独占了，而且两个 ptr 都以为自己独占，可能会 double delete。

总结，unqiue_ptr 告诉了你啥：

```text
p 是一个指针
p 指向的资源是自己独占的
p 会自动释放资源（这一点很给力，我们就不用手动去 delete 了，而且它在 move 的时候也会给你自动释放资源）
p 只能 move
p 不能 copy
```

管理数组：

```cpp
auto data = std::make_unique<char[]>(size);
```

### 做一个替换：

把原先的 char* 换成 std::unique_ptr<char[]>

```cpp
class Buffer {
public:
    explicit Buffer(std::size_t size)
        : data_(std::make_unique<char[]>(size)), size_(size) {}

private:
    std::unique_ptr<char[]> data_;
    std::size_t size_;
};
```

### unique_ptr 不能完全替代裸指针

如果我们只是想用 non-owning pointer 这个意思，我们用一个裸指针(raw pointer) 借用一下，观察一下就好了，反正又不负责释放资源。

```cpp
void print_value(const int* p) {
    if (p != nullptr) {
        std::cout << *p << '\n';
    }
}
```

可以从 unique_ptr 拿裸指针。

```cpp
auto p = std::make_unique<int>(42);
int* raw = p.get();
```

## 可以直接调用 std::move，去 move 我们的 unique_ptr

这个就比你之前手动写 delete,nullptr 之类的方便多了！而且它帮你实现了原指针的置空！

**但如果类里还有 size_ 这类普通成员，整个类的 move 后状态仍然要你设计。**

```cpp
#include <iostream>
#include <memory>
#include <utility>

int main() {
    auto p1 = std::make_unique<int>(42);
    auto p2 = std::move(p1);

    if (p1 == nullptr) {
        std::cout << "p1 is null\n";
    }

    if (p2 != nullptr) {
        std::cout << "p2 value=" << *p2 << '\n';
    }

    return 0;
}
```

## my code

```cpp
// unique_ptr no copy, only move
#include <cstddef>
#include <iostream>
#include <utility>
#include <memory>

class Buffer {
public:
    explicit Buffer(std::size_t size): size_(size),data_(std::make_unique<char[]>(size)) {
        std::cout<<"this is constructor\n";
    }

    // move constructor
    // 从别人接管资源，并让别人的指针置空
    // 但是我们不需要手动 new,delete了！
    // 省下了，让 other.data_ 置空的过程
    Buffer(Buffer&& other)noexcept: size_(other.size_),data_(std::move(other.data_)) {
        std::cout<<"this is move constructor"<<std::endl;
        other.size_=0;
    }

    Buffer& operator =(Buffer&& other) noexcept {
        std::cout<<"this is move assignment"<<std::endl;
        if(this==&other) {
            return *this;
        }
        size_=other.size_;
        other.size_=0;
        data_=std::move(other.data_);
        return *this;
    }

    const char* data() const {
        return data_.get();
    }

    std::size_t size() const {
        return size_;
    }
private:
    std::size_t size_;
    std::unique_ptr<char[]> data_;
};

int main() {
    Buffer a(5);
    Buffer b=std::move(a);
    std::cout<<a.size()<<" "<<b.size()<<std::endl;
    return 0;
}
```

## day4.md 中的 bug

由于没跟我一样手动写 move constructor/assignment，导致你 move 了之后其实 size 是不对的，比如 day4.md 里下面代码，应该输出的是 5 5，但是根据 move 的定义，你交出来资源的管理权了，那你自己管理的资源的 size 肯定为空了。

```cpp
#include <cstddef>
#include <iostream>
#include <memory>
#include <utility>

class Buffer {
public:
    explicit Buffer(std::size_t size)
        : data_(std::make_unique<char[]>(size)), size_(size) {
        std::cout << "Buffer construct size=" << size_ << '\n';
    }

    void set(std::size_t index, char value) {
        if (index >= size_) {
            return;
        }
        data_[index] = value;
    }

    char get(std::size_t index) const {
        if (index >= size_) {
            return ' ';
        }
        return data_[index];
    }

    std::size_t size() const {
        return size_;
    }

private:
    std::unique_ptr<char[]> data_;
    std::size_t size_;
};

int main() {
    Buffer a(5);
    Buffer c = std::move(a);  // 可以 move
    std::cout << a.size()<<" "<<c.size()<<std::endl;

    return 0;
}
```

