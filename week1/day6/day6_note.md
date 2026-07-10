## owning pointer:

拥有资源的指针，就是你的指针负责 delete 某块内存。与之对应的是我们在一个对象的析构函数去释放资源。

## V2 时的坑

```cpp
Buffer(const Buffer& other) {
        len_=other.len_;
        data_=new char[len_];
        for(size_t i=0;i<len_;i++) data_[i]=other.data_[i];
    }
```

```text
你这里不能跟 copy assignment 一样，先 delete[] data_，因为你一开始的时候 data_ 没有指向任何内存。
```

```cpp
Buffer& operator =(const Buffer& other) {
        if(this==&other) {
            return *this;
        }
        delete[] data_;
        len_=other.len_;
        data_=new char[len_];
        for(size_t i=0;i<len_;i++) data_[i]=other.data_[i];
        return *this;
    }
```

```text
copy assignment 要记得写判断是不是 self assignment！
```

## private 的Q：

```cpp
Q: 我有一个问题啊，就是你看拷贝构造函数里的 other.size_ 这个不是 private的吗，为啥能访问到呢？

A:同一个类的成员函数，可以访问这个类的任意对象的 private 成员。

private 限制的是：
类外面的代码不能访问
但是在成员函数都是类里面，所以不会被 private 限制。
StringLike(const StringLike& other) {
    char* new_data = new char[other.len_];
    data_ = new_data;
    len_ = other.len_;
    memcpy(data_, other.data_, other.len_);
}

你现在在 StringLike 类的成员函数内部。既然你已经在 StringLike 内部，那么你可以访问：
this->len_
this->data_
other.len_
other.data_
因为 other 也是一个 StringLike 对象。
```

## StringLike

```cpp
/*
需求：
    从 const char* 构造
    析构释放内存
    拷贝构造深拷贝
    拷贝赋值深拷贝
    c_str() 返回内部字符串
    size() 返回长度
使用：
    std::strlen(s)
    std::memcpy(dst, src, n)
    strlen：计算 C 字符串长度，不包含结尾 '\0'
    memcpy：按字节复制内存
Author: 
    FxorG
*/
#include <iostream>
#include <cstddef>
#include <cstring>

class StringLike {
public:
    StringLike(const char* data): len_(strlen(data)+1),data_(new char[len_]) {
        memcpy(data_,data,len_);
    }
    StringLike(const StringLike& other) {
        char* new_data=new char[other.len_];
        data_=new_data;
        len_=other.len_;
        memcpy(data_,other.data_,other.len_);
    }
    StringLike& operator =(const StringLike& other) {
        if(this==&other) {
            return *this;
        }
        char* new_data=new char[other.len_];
        memcpy(new_data,other.data_,other.len_);
        delete[] data_;
        data_=new_data;
        len_=other.len_;
        return *this;
    }
    ~StringLike() {
        delete[] data_;
    }
    std::size_t size() const {
        return len_-1;
    }
    const char* c_str() const {
        return data_;
    }
private:
    std::size_t len_;
    char* data_;
};

int main() {
    StringLike a("abc");
    StringLike b("hello world");
    a = b;
    std::cout << a.c_str() << " " << a.size() << std::endl;
    return 0;
}
```

## 验收问题

```text
1. Buffer V1 为什么要禁止拷贝？
因为默认 copy 是 shallow copy

2. Buffer V2 的拷贝构造为什么是深拷贝？
因为我 new 了一个给他。

3. copy assignment 里为什么要判断 this == &other？
避免 self assignment

4. copy assignment 为什么推荐先 new 新资源，再 delete 旧资源？
避免 new 失败，然后旧资源已经被 delete 的情况。

5. StringLike 为什么要分配 size_ + 1 个 char？
字符串还有最后一个 \0

6. '\0' 在 C 字符串里有什么作用？
表示一个字符串的结束

7. c_str() 返回的是什么？
字符串的第一个元素的指针

8. StringLike 里的 data_ 是资源本身还是资源地址？
资源地址

9. Rule of Three 三个函数分别是什么？
析构函数，copy constructor,copy assignment

10. 你现在怎么判断一个类需不需要自己写 Rule of Three？
主要看我需不需要去管理资源吧，就是RAII的感觉

11. AddressSanitizer 今天帮你检查什么？
内存错误

12. 你这个 StringLike 和 std::string 差在哪里？
我这个只是个练习用的 toy demo而已，差远了。
```

