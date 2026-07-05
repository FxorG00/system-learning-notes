# Day4 Notes

## 栈对象和堆对象
- 栈对象什么时候构造：进入作用域
- 栈对象什么时候析构：离开作用域
- 堆对象什么时候构造：调用 new 的时候
- 堆对象什么时候析构：调用 delete
- 指针变量本身和它指向的对象可能在哪里：二者都可能在栈区 or 堆区。

## new / delete

- new 做了哪两件事：在堆区上申请内存+在这块内存上创建对象并调用构造函数
- delete 做了哪两件事：调用指针指向的对象的析构函数+释放这块堆内存
- new T 对应什么：delete
- new T[n] 对应什么：delete[] 
- 为什么 new Tracer[3] 要求 Tracer 有默认构造函数：因为你这个 new 不知道每个 Tracer 要用哪一些参数去构造，你没有手动指定，所以是调用默认构造函数。

## 内存错误
- memory leak 是什么：内存泄漏。p 是一个指针，它在栈区中，然后离开作用域，p已经死了，但是它指向的那个对象还在堆区中，没死，但是因为 p 死了，所以再也拿不到那个对象的地址了，也就没办法 delete 了。申请的资源没有释放。
- dangling pointer 是什么：悬空指针，就是它指向的那块地址其实已经被释放了。
- double delete 是什么：同一块内存释放 2 次。
- delete 后 p = nullptr 有什么用：delete nullptr 是安全的。
- p = nullptr 能不能彻底解决问题：不能。

## RAII

- RAII 全称：Resource Acquisition Is Initialization

- RAII 核心思想：就是构造函数的时候把资源申请过来；然后析构函数的时候顺便释放资源。

- 构造函数在 RAII 中负责什么：获取资源

- 析构函数在 RAII 中负责什么：释放资源

- 为什么 RAII 能减少资源泄漏：因为，一个对象在离开作用域的时候会调用析构函数，而析构函数会释放资源，这样避免了我们忘记去释放资源，导致 memory leak。

- 为什么手写资源管理类要考虑拷贝问题：如果你让 a,b 两个对象的 data 指针指向同一块内存，那么先调用 a 的析构函数后，这块内存已经释放了，但是再调用 b 的构造函数，这块内存就会被 double delete。

- ```cpp
  #include <iostream>
  #include <cstddef>
  
  class IntBuffer {
  public:
      // 禁止这个构造函数被用于隐式类型转换
      explicit IntBuffer(std::size_t size)
          : size_(size), data_(new int[size]) {
          std::cout << "IntBuffer construct, size = " << size_ << std::endl;
      }
  
      ~IntBuffer() {
          std::cout << "IntBuffer destruct, size = " << size_ << std::endl;
          delete[] data_;
      }
  
      void set(std::size_t index, int value) {
          if (index < size_) {
              data_[index] = value;
          }
      }
  
      int get(std::size_t index) const {
          if (index < size_) {
              return data_[index];
          }
          return 0;
      }
  
      std::size_t size() const {
          return size_;
      }
  
      // 今天先禁止拷贝，避免引出深拷贝 / 浅拷贝问题。
      // =delete 是明确禁止某个函数被使用
      // 禁止 IntBuffer b2=b1，利用 b1 来拷贝构造 b2
      IntBuffer(const IntBuffer&) = delete;
      // 禁止拷贝赋值，也就是 b2=b1 是被禁止的
      // 因为默认拷贝是浅拷贝，就是全都赋值成一样，这样会导致 double delete
      IntBuffer& operator=(const IntBuffer&) = delete;
  
  private:
      std::size_t size_;
      int* data_;
  };
  
  void use_buffer() {
      IntBuffer buffer(5);
  
      buffer.set(0, 100);
      buffer.set(1, 200);
  
      std::cout << "buffer[0] = " << buffer.get(0) << std::endl;
      std::cout << "buffer[1] = " << buffer.get(1) << std::endl;
  
      // 不需要手动 delete[]。
      // 函数结束时 buffer 自动析构，析构函数里会 delete[] data_。
  }
  
  int main() {
      std::cout << "enter main" << std::endl;
  
      use_buffer();
  
      std::cout << "leave main" << std::endl;
      return 0;
  }
  ```

- 