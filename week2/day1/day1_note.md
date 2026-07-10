## 深拷贝成本

```text
5. 这个程序里一共发生了几次资源申请？
	construct size=5
    copy construct size=5
    a[2]=x b[2]=x
    construct size=3
    copy assignment size=5
    c[2]=x
    copy assignment size=5 这一个结合具体代码，是 self assignment，所以不会去申请资源
    destruct size=5
    destruct size=5
    destruct size=5
  	由日志知一共申请 4 次资源。
```

## 3. deep copy 为什么可能贵

因为可能你有一个对象 tmp，他已经快死了，但是它有着一块很大的内存，这时候你让`T b=tmp` 会调用 copy constructor，这时候进行 deep copy 的话，会为 b 申请了一块很大的内存，可是明明 tmp 都要死了，就很浪费。

## 4. 函数返回 Buffer 时我观察到了什么

`Buffer b = make_buffer(10);` 从代码上看是需要调用 copy constructor 的，但是并没有！

## 5. RVO / NRVO 我现在的理解

是编译器优化返回对象的一种方式，可以减少不必要的拷贝。

## 6. copy 和 move 的区别，我现在怎么说

copy 是原先 A 有一份资源，现在 copy 了一份给 B，总共有 2 份。

move 是 A 交出资源的管理权给 B，总共有 1 份。

## 7. 今天还不稳的问题

没啥问题，感觉今天挺简单的。核心就是让我知道了 deep copy 的浪费，以及给我提供了一个 move 的思想去解决这个浪费的问题。虽然我还不知道具体咋实现。还了解到了，在返回一个对象的时候编译器做的优化。