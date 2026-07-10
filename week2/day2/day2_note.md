# Week2 Day2 Note

## 1. 今天从什么问题出发

我现在不想要 deep copy了，我要去让 a 把管理权交给 b，怎么实现？`Buffer b = std::move(a);` 这句话干了啥？

## 2. std::move 我现在怎么理解

`std::move(a)` 就是把 a 转换成了可以被移动构造函数接收的参数。

## 3. 移动构造函数做了什么

1. 把 data 赋值为 other.data，size 也一样，也就是接过来管理权。
2. 将 other.data 置 nullptr 且 other.size 置 0。

## 4. copy construct 和 move construct 输出有什么区别

调用 a 的析构函数所输出的 destruct size= 一个是 0 一个是 5。

## 5. 为什么 move 后要把 other.data_ 置空

避免两个 data 指向同一个内存，后续引起 double delete。

## 6. move 后对象还能不能用

完全可以。需要注意的是，你在 move constructor 里面对这个对象会有修改，比如 data=nullptr,size=0，所以后面你这个对象这些数据已经被修改了。

## 7. 把 move constructor 删掉了会咋样？

`std::move(a)` 就是把 a 转换成了可以被移动构造函数接收的参数。

记住这个东西，那你现在 `Buffer c = std::move(a);` 会去找，优先找有没有 move constructor，发现没有，这时候会去调用 copy constructor。

## 8. 今天还不稳的问题

没有，感觉今天也挺简单的。