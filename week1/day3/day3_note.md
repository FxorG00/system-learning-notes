# Day3 Notes

## 类和对象

- class 和 struct 默认访问权限区别：class 默认 private，struct 默认 public。

## 构造和析构

- constructor 是什么：构造函数

- destructor 是什么：析构函数

- 构造函数什么时候调用：对象出生的时候

- 析构函数什么时候调用：对象死亡前

- lifetime 是什么：对象从创建到死亡的时间

- 学到了一个 block scope，作用域块，就是直接给你套一个 {}，用于认为制造一个更小的作用域。

  ```cpp
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
- ```text
  1. 构造函数什么时候调用？
  一个对象出生的时候
  
  2. 析构函数什么时候调用？
  一个对象死亡前
  
  3. 为什么 b 比 a 先析构？
  因为 b 在 inner scope 里面，然后这个代码块跑完了，结束了，那么 b 是只存活在这个代码块的，所以跑完了，就销毁了。而 a 的作用域是在 main 函数，要等到 main 执行完后再销毁。所以 b 比 a 先析构。
  
  4. 对象生命周期是什么意思？
  一个对象从创建到销毁的时间。
  
  5. 析构函数是不是需要你手动调用？
  不需要
- 

## 成员初始化列表
- member initializer list 是什么：成员初始化列表
- 为什么推荐用初始化列表：不用的话，成员变量会先默认初始化，但是如果一个类型没有默认构造函数的话，那就不行了！所以直接用这个，避免去默认初始化。
- 成员初始化顺序由什么决定：在类里面声明的顺序。

## this
- this 是什么：指向当前对象的指针。
- this->name_ 是什么意思：当前对象的 name 这个成员变量。

## const 成员函数
- void print() const 是什么意思：print 这个函数不修改 *this 这个对象。
- const 对象能不能调用非 const 成员函数：不行。参考以下代码。
    ```cpp
    #include <iostream>
    #include <string>
    using namespace std;
    
    class User {
    public:
        User(const string& name): name_(name) {
    
        }
        void print() {
            cout<<"in print() "<<this->name_<<'\n';
        }
        void print_const() const {
            cout<<"in print_const() "<<this->name_<<'\n';
        }
    private:
        string name_;
    };
    
    int main() {
        User u1("FxorG");
        u1.print();
        return 0;
    }
    ```
- ```text
    1. 成员初始化列表是什么？
    2. 为什么推荐用成员初始化列表？
    3. 成员变量的初始化顺序由什么决定？
    4. this 是什么？
    5. this->name_ 是什么意思？
    6. void print() const 里的 const 是什么意思？
    上面都有
    
    7. const 对象为什么不能调用非 const 成员函数？
    我的理解是，非 const 成员函数没有承诺函数内部不修改当前对象，所以你 const 对象调用的话，有被修改的风险。
## 对象生命周期顺序

- 同一作用域对象析构顺序：先进来的后销毁，类似于栈。
- 为什么说后构造的先析构：我感觉是，你创建的时候，把对象都压入栈中，析构的时候，弹出来，然后析构。所以就有这个顺序。



```text
1. class 和 struct 默认访问权限有什么区别？
上面有

2. private 有什么意义？
封装对象内部状态，防止外部随意破坏对象的不变量。
比如我们不希望 User 类的手机号这个成员变量被外面的函数访问，那我们可以 private。但是我们可以提供一个 set_phone_number 的接口。

3. 什么是对象？
object，就是一个类的实体，比如 User 是一个类，那小明，小红这些用户都是对象。

4. 构造函数什么时候调用？
5. 析构函数什么时候调用？
上面有

6. 构造函数为什么没有返回类型？
构造函数的任务只是初始化要创建的对象，不需要返回值。

7. 析构函数为什么叫 ~ClassName？
语法规定。与构造函数呼应。

8. 栈上对象什么时候析构？
作用域结束的时候析构。

9. 同一作用域中，多个对象的析构顺序是什么？
10. 成员初始化列表是什么？
11. 为什么推荐用成员初始化列表？
12. 成员变量初始化顺序由什么决定？
13. this 指针是什么？
14. void print() const 里的 const 是什么意思？
15. const 对象为什么只能调用 const 成员函数？
略，上面都有
```

