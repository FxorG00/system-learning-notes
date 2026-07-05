## 一

这一块我比较会啊，都学过。

```text
1. p 里面存的是 a 的值，还是 a 的地址？
A: p 存 a 的地址

2. *p 代表 p 本身，还是 p 指向的对象？
A: *p 是 p 指向的对象

3. “解引用”是什么意思？
A: 顺着地址，去找到在这个地址上的数据

4. 为什么 *p = 20 会让 a 变成 20？
A: 因为此时是在操作 p 值得那块地址上的数据。
```

## 三：引用

引用在定义的时候就要初始化，绑定到哪个变量上，永久去作为这个变量的别名。

## 四：引用与指针

```text
1. 引用能不能重新绑定？
不行。

2. int& r = a; 之后 r = b; 是重新绑定吗？
不是，引用不能重新绑定。此时 r 就是 a 的别名，所以 r=b 就是 a=b，就是把 b 的值赋给 a。

3. 指针能不能是 nullptr？
可以，就是空指针。不过不能对 nullptr 解引用。

4. 为什么 swap_by_pointer 调用时要传 &x、&y？
指针变量接收地址，所以通过取址符。

5. 为什么 swap_by_reference 调用时直接传 x、y？
因为引用接收变量，而不是接收地址。直接传变量过去，就相当于绑定住了。
```

## 五：const

`const int* p1 = &a;`  p1 is a pointer to const int

`int* const p2 = &a;` p2 is a const pointer to int

`const int* const p3 = &a;` p3 is a const pointer to const int



```text
1. const int* p 的常见术语是什么？
常量指针

2. int* const p 的常见术语是什么？
指针常量

3. const int* p 中，不能改的是 p 还是 *p？
p is a pointer to const int，所以不能改的是 *p

4. int* const p 中，不能改的是 p 还是 *p？
是 p。

5. const int* const p 中，哪个不能改？
p，跟 *p 都不能改。

6. 为什么说 const int* p 不是说 a 本身一定是常量？
因为 p is a pointer to const int，只是说我认为他指向一个 const int，我不能通过 *p 去修改他，但是这跟他本身能不能被修改没关系。
```

## 七：const 引用传参

`const std::string& name = s;` name is a reference to const string 顾名思义，name 是一个引用，引用自一个 string 常量，所以你没办法去修改常量的值，自然不能通过 `name=xx` 去赋值，注意这里是我认为引用自一个常量，但是实际上是不是也不一定。

当我们利用 `void foo(const std::string& s);` 作为参数的时候，避免按值传递时的 copy 一份，以及没办法通过 `s` 去修改其引用的对象。

```text
std::string s
这个作为参数的时候，是拷贝一个副本传过去的，也就是你在函数内部再怎么对 s 修改也没办法影响它的本体。

const std::string& s
s is a reference to const string
是一个引用。所以我们传引用，避免拷贝一份。并且在函数内部不能修改 s。

std::string& s
传引用。函数内部可以修改 s。
```

## 十：验收问题

```text
1. 指针和引用的区别是什么？
int* p 是指针，p 本身存的是地址。然后 int& r 是引用，r 是某个变量的别名。你可以通过 r=xx 直接修改，但是对指针来说是就要解引用。

2. 引用能不能重新绑定？
不能。定义时永久绑定了。

3. 指针能不能是 nullptr？
可以

4. nullptr 有什么用？
比如说，你在数组里要找某个数，但是没找到，你的函数可以返回 nullptr，然后你在外层就可以判断做处理。

5. &a、p、*p 分别是什么意思？
&a，a 的地址。p 就是 p 的值。*p 对 p 解引用，找 p 的值对应地址上的数据。

6. 解引用是什么意思？
找 p 的值对应地址上的数据

7. const int* 常见叫法是什么？含义是什么？
8. int* const 常见叫法是什么？含义是什么？
9. const int* const 含义是什么？
789笔记里有。

10. 为什么函数参数常用 const 
std::string&？
避免拷贝一份，浪费时间空间。以及在函数内部无法修改。

11. 什么时候应该值传递？
一些小一点的数据类型。

12. 什么时候应该 const 引用传递？
大一点的数据类型。并且不希望在函数内部去修改。

13. 什么时候应该普通引用传递？
大一点的数据类型。希望在函数内部修改。

14. 什么时候更适合用指针？
我觉得比如你跟地址相关的，需要用到 ++p,--p，那指针的移动对比引用时更便利的，看你传进来的是个啥。
```





