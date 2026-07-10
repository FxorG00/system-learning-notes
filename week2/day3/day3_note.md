## 今天学了啥？

有 move constructor，自然就有 move assignment，今天就围绕后者。

## move assignment

```cpp
Buffer a(5);
    Buffer b(10);
    std::cout<<a.size()<<" "<<b.size()<<std::endl;
    b=std::move(a);
    std::cout<<a.size()<<" "<<b.size()<<std::endl;
```

这样，现在 a 要把自己的资源管理权交给 b，那么 b 原先的资源就不要了。

```cpp
Buffer& operator =(Buffer&& other) noexcept {
        // 从 other 那里接管资源
        // move assignment 也是 assignment，要考虑 self assignment
        std::cout<<"move assignment size="<<other.size_<<std::endl;
        if(this==&other) {
            return *this;
        }
        delete[] data_;
        data_=other.data_;
        size_=other.size_;
        other.data_=nullptr;
        other.size_=0;
        // std::cout<<"other.size_= "<<other.size_<<std::endl;
        return *this;
    }
```

1. 考虑 self assignment
2. 释放自己掌管的资源
3. 拿别人的资源
4. 将别人的指针置空，修改相关数据
5.  `return *this;`

## code

```cpp
#include <cstddef>
#include <iostream>
#include <utility>

class Buffer {
public:
    explicit Buffer(std::size_t size)
        : data_(new char[size]), size_(size) {
        std::cout << "construct size=" << size_ << '\n';
    }

    Buffer(const Buffer& other)
        : data_(new char[other.size_]), size_(other.size_) {
        std::cout << "copy construct size=" << size_ << '\n';
        for (std::size_t i = 0; i < size_; ++i) {
            data_[i] = other.data_[i];
        }
    }

    Buffer& operator=(const Buffer& other) {
        std::cout << "copy assignment size=" << other.size_ << '\n';
        if (this == &other) {
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

    Buffer(Buffer&& other) noexcept
        : data_(other.data_), size_(other.size_) {
        std::cout << "move construct size=" << size_ << '\n';
        other.data_ = nullptr;
        other.size_ = 0;
    }

    Buffer& operator =(Buffer&& other) noexcept {
        // 从 other 那里接管资源
        // move assignment 也是 assignment，要考虑 self assignment
        std::cout<<"move assignment size="<<other.size_<<std::endl;
        if(this==&other) {
            return *this;
        }
        delete[] data_;
        data_=other.data_;
        size_=other.size_;
        other.data_=nullptr;
        other.size_=0;
        // std::cout<<"other.size_= "<<other.size_<<std::endl;
        return *this;
    }
    ~Buffer() {
        std::cout << "destruct size=" << size_ << '\n';
        delete[] data_;
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
    char* data_;
    std::size_t size_;
};

int main() {
    Buffer a(5);
    Buffer b(10);
    std::cout<<a.size()<<" "<<b.size()<<std::endl;
    b=std::move(a);
    std::cout<<a.size()<<" "<<b.size()<<std::endl;
    return 0;
}
```

## noexcept

noexcept 表示承诺这个函数不会抛出异常。

并且，标准库容器在扩容、搬移元素的时候，如果 move constructor 是 noexcept 就更愿意用这个，否则可能用 copy constructor。

## 总结

今天也是简单。