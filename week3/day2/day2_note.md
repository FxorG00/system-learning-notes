## 练习一：

```text
为什么 push_back 前先填满 capacity
为了下面的一次 push_back 后就扩容。

为什么这次 push_back 一定需要更多存储
因为 size=capacity了。

为什么只保存旧地址的整数值用于比较
用于观察。

为什么扩容后不再解引用 old_it
old_it 已经失效了。

为什么 erase 返回的迭代器指向 30
erase 删除了 20，然后会返回删除位置后的那个元素迭代器，所以指向30。
```

## 练习二：

```text
1. 为什么先 reserve(3)？
便于调试，不然输出一堆扩容相关的 log。

2. push_back(first) 为什么 copy？
first 是左值，不让 push_back 影响 first，所以 copy 出一个副本 push_back 进去。

3. push_back(Item(2)) 为什么 move？
因为 Item(2) 是右值，直接 move 了也没事，况且你这个 Item(2) 本来就要析构了。

4. emplace_back(3) 少了哪个临时对象步骤？
看不懂你问的啥意思？他这个是在 vector 尾部调用构造函数，然后把 3 当成参数去初始化。

5. emplace_back 是否能避免已有元素在扩容时搬迁？
不能。

6. 为什么 erase 后不能继续 ++ 原 it？
原 it 已经失效。

7. it = erase(it) 得到的是什么？
it 为删除的对象后面那个对象的迭代器。
```

---

## 7. push_back 的三种常见情况

假设元素类型是 `Item`。

### 传入左值

```cpp
Item item(1);
items.push_back(item);
```

`item` 仍然要保留自己的状态，所以通常调用 copy constructor。

相当于拷贝个副本，搞到 vector 那个小格子上。

### 传入右值

```cpp
items.push_back(Item(2));
```

先构造临时 `Item(2)`，再把它 move 到 vector 的元素位置。

相当于把 `Item(2)` 直接 move 到小格子上。

### 直接在尾部构造

```cpp
items.emplace_back(3);
```

用参数 `3` 直接在 vector 的尾部存储位置调用 `Item(int)`。

在小格子上直接调用构造函数创建对象，把 3 作为参数传进去。

---