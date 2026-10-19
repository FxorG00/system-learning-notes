认真了！

# 基础

## 1. 变量与对象的分离

在 Python 中，变量和对象（数据）是分离的。

- 变量只是一个名字、标签，类似 C++ 中的引用。
- 对象是存储在堆内存中的实际数据，比如 1，2，3，4，这些值，还有 `[1,2,3],(1,2,5)` 这些的。

## 2. 小整数池

Python将 `[-5, 256]` 的整数维护在小整数对象池中。这些整数提前创建好且不会被垃圾回收，避免了为整数频繁申请和销毁内存空间。不管在程序的什么位置，**使用的位于这个范围内的整数都是同一个对象**。

**只要用的数是小整数池里有的，那就是指向小整数池里对应的对象。**

![image](https://img2024.cnblogs.com/blog/1910062/202604/1910062-20260411164905424-1284899717.png)

```python
num1=10
# num1 指向值为 10，在小整数池的对象
num2=10
# num2 同理
print(id(num1))
print(id(num2))
print(num1 is num2)
```

## 3. bool 类型

![image](https://img2024.cnblogs.com/blog/1910062/202604/1910062-20260411170825856-1582812668.png)

`Python3` 中，`bool` 是 `int` 的子类，`True` 和 `False` 可以和数字相加。

`True` 跟 `False` 这两个 `bool` 对象在底层实际上是映射到 `1 和 0`，可以看成 `key and value`。

然后映射到的 `1`，其实就是小整数池里的 1。

`is` 运算符用于比较两个对象的身份（即它们是否是同一个对象，**是否在内存中占据相同的位置**），而不是比较它们的值。

但是虽然 `True==1` 成立，因为值相等；但是 `True is 1` 不成立，因为不是同一个对象，很显然，对象类型都不一样。

## 4. str 类型

- intern机制
每个（字符串），不夹杂空格或者特殊符号，默认开启intern机制，共享内存，靠引用计数决定是否销毁。**相同的字符串默认只保留一份，当创建一个字符串，它会先检查内存里有没有这个字符串，如果有就不再创建新的了**。
单个字母，长度为1的 ASCII 字符会被 interned，包括空字符。
	```python
	str1="hello"
	str2="hello"
	print(id(str1))
	print(id(str2))
	print(str1 is str2)
	```
	```
	out
	2094542361568
	2094542361568
	True
	```
## 5. 海象运算符
海象运算符，在表达式中，赋值，然后再返回赋值的值；而单独 `num=2` 返回的是 `None`，所以要直接输出的话可以这样。
```python
num=1
print(num:=2)
print(num)
```
## 6. 位运算

![image](https://img2024.cnblogs.com/blog/1910062/202604/1910062-20260413210555482-290616402.png)


- Q：我看不懂这里，为啥 -12 补码 >>3，然后左边会出来 3 个 1，为啥？明明本来不就 8 位二进制吗？那你怎么知道移动后一定出来3个1

	原理：对有符号整数进行右移的时候，最高位要以符号位 0/1 进行填充。这里，-12 的符号位为 1，所以最高位用 1 填充，所以会出来连续的 3 个 1。那你比如 +12，向右移动 3 位，那么就是用 0 去填充。

## 7. list

### 内存分析
```python
list1=[100,200,300,400,500]
```

我们考虑这样创建一个 list，我们先看等号右边，是在创建一个 list 对象，然后创建完让 list1 指向（引用）这个 list 对象而已。接着我们看这个 list 对象的创建，里面存放的其实是对某个对象的引用，比如下标为 0 的地方存放一个指向小整数池中的值为 100 的 int 对象的引用。所以还是要理解这个**变量本质上是引用，数据是对象；变量与数据是分开的**，那么 [100,200,300,400,500] 这个数据显然就是一个对象，然后其中的 100 这个数据也是一个对象，所谓的 list1 这个带名字的，不过就是一个引用，list1[0] 这个名字的，也是。

![image](https://img2024.cnblogs.com/blog/1910062/202604/1910062-20260414142859201-1276591025.png)

接着，我们考虑创建一个 list1。

![image](https://img2024.cnblogs.com/blog/1910062/202604/1910062-20260414145302070-1468237128.png)

如果让 `list2=list1`，那么本质上就是这两个变量引用同一个对象，那你对 `list2` 修改的话，是修改到真真实实的那个对象的，所以在用 list1 去访问这个对象的时候，内容就会改变。

![image](https://img2024.cnblogs.com/blog/1910062/202604/1910062-20260414145405034-1709344490.png)

但如果 `list2=list1[:]`，等号右边相等于创建了一个新 list 对象，然后是由 list1 指向的对象切片过来的，再让 list2 指向这个新对象。

![image](https://img2024.cnblogs.com/blog/1910062/202604/1910062-20260414145512483-675230688.png)
### 列表推导式
列表推导式的核心语法是：`[表达式 for 变量 in 可迭代对象 if 条件]`

`even_squares = [x**2 for x in range(10) if x % 2 == 0]结果：[0, 4, 16, 36, 64]`
## 8. tuple

```python
tup1=(1,2,3)
tup2=(4,5,6)
print(id(tup1),id(tup2))
tup1=tup1+tup2
print(id(tup1))
```

一开始，创建了两个 tuple 对象没毛病。然后考虑 `tup1+tup2`，本质上是创建了一个新的 tuple 对象，这个对象的值是 tup1 与 tup2 拼接而成而已，再看等号左边，也就是让 tup1 引用这个新创建的对象。搞清楚，对象跟变量（引用）就好了！

![image](https://img2024.cnblogs.com/blog/1910062/202604/1910062-20260414145844734-421570214.png)
![image](https://img2024.cnblogs.com/blog/1910062/202604/1910062-20260414150030963-1058756285.png)

## 9. 函数

### 1. 函数形参实参与内存

![image](https://img2024.cnblogs.com/blog/1910062/202604/1910062-20260414154036126-959792009.png)

核心：**一切皆对象，函数也是对象。变量就是引用而已。**

1. 黄色：小整数池（Python 优化机制）
	Python 提前把 -5 ~ 256 的整数缓存好，永远不重复创建
	数字 2 → 固定地址 0x2222
	数字 3 → 固定地址 0x3333
	所有代码用到 2、3，都直接复用这个地址，省内存。

2. 橙色：堆内存（永久存对象）
	所有真正的「数据 / 对象」，全存在堆里
	模块对象（整个 py 文件）
	自带全局命名空间（__dict__ 就是字典）
	**存：print_star → 指向函数对象地址 0x1234，就是在把名字（函数名字，变量名字）与实际对象内存地址形成一个映射。**
	函数对象 **（def 定义时创建）**
	地址 0x1234，存着函数的代码、自己的局部命名空间
	✅ **重点：def 只做一件事：在堆里创建函数对象，不执行代码！**
3. 红色：栈内存（临时执行区）
	当执行 print_star(2, 3) 时：
	1. 栈里创建一个栈帧（函数专属临时空间），搭建起一个舞台（栈帧）
	2. 形参绑定地址：
	rows → 指向小整数池 0x2222（就是数字 2）
	cols → 指向小整数池 0x3333（就是数字 3）
	3. 执行循环、打印代码，按照剧本（函数对象）演出！
	4. 函数结束 → 栈帧直接删除（局部变量全消失），舞台被拆了！

4. 命名空间（__dict__）= 变量字典
	就是一张表：变量名 : 对象地址
	全局命名空间（模块）：存 print_star
	局部命名空间（函数）：存 rows、cols
	作用域规则：函数内优先用自己的局部变量，找不到才去全局找

![image](https://img2024.cnblogs.com/blog/1910062/202604/1910062-20260414154025312-1674436950.png)

### 2. 函数的参数传递

其实你理解了，这个形参只是一个名字，然后你在调用函数的时候，要让函数对象进栈，并且将形参跟实际的传入的对象进行一个 k-v 映射，就没问题了。
#### 传不可变类型
```python
def changeInt(a) :
    print("函数体中未改变前a的内存地址",id(a))
    a = 10
    print("函数体中改变后a的内存地址",id(a))

b = 2
changeInt(b)
print(b)
print("函数外b的内存地址",id(b))
```

比如，传入一个不可变类型，那么一开始肯定，就是 a 这个形参指向 b 引用的对象，也就是指向 0x2222 这个地址；那么你看，`a=10` 的本质是啥？a 不过是个变量呀，所以就是让 a 指向 10 这个 int 对象而已了。你看，这样 a 与 b 指向的不就是不同的对象了吗？

![image](https://img2024.cnblogs.com/blog/1910062/202604/1910062-20260414164218335-733555316.png)

#### 传可变类型
![image](https://img2024.cnblogs.com/blog/1910062/202604/1910062-20260414164611410-766076509.png)

ok，一开始 list0 指向的是这个 0x2345 这个 list 对象；那么传入参数后，list1 也是指向这个对象。对于 list1[2]=20，就是在操作这个 list 对象呀！那当然可以操作！！！然后，你也可以让 `list1=其他的 list 对象`。

![image](https://img2024.cnblogs.com/blog/1910062/202604/1910062-20260414164544453-1994292019.png)

### 3. var1 *= 2与var1 = var1 * 2的区别：

- var1 *= 2 是对原先的对象进行原地操作，也就是说，如果 var1 指向 0x1111 这个对象，那么它会去让 0x1111 这个对象原地拼接以下，然后 var1 还是指向 0x1111 这个对象。
- var1 = var1 * 2，看等号右边，创建了一个新的对象（比如地址 0x2222），是 var1 拼接得到，那么再让 var1 指向 0x2222。

### 4. 参数原则

看过就好了。

1. 位置参数在关键字参数前面。（就是按位置的在 `var=111` 这样的前面）

2. 没有默认值的参数在有默认值的参数前面。

### 5. 浅拷贝


```python
# 为了防止在函数里面修改到函数外面的 list0
def change_list(list1) :
    list1[3].append(40)
# list0[3] 这个变量 指向 [10,20,30] 这个对象
list0=[1,2,3,[10,20,30]]
list00=list0.copy()
print(f"调用前的list0:{list0}")
print(f"调用前的list00:{list00}")
change_list(list00)
print(f"调用后的list0:{list0}")
print(f"调用后的list00:{list00}")
Out:
调用前的list0:[1, 2, 3, [10, 20, 30]]
调用前的list00:[1, 2, 3, [10, 20, 30]]
调用后的list0:[1, 2, 3, [10, 20, 30, 40]]
调用后的list00:[1, 2, 3, [10, 20, 30, 40]]
```

`list.copy()` 和 `list[:]` 都是浅拷贝（shallow copy）。它们创建一个新的列表对象，但是新列表中的元素是对原列表中元素的引用。你 `list00[i] 与 list0[i]` 指向的都是同个对象！！！那你看 `list00[3] 与 list0[3]` 指向同一个 list 对象，那你自然操作的时候就炸了！

![image](https://img2024.cnblogs.com/blog/1910062/202604/1910062-20260414175805907-1023046437.png)

### 6. 深拷贝

```python
import copy

def change_list(list1) :
    list1[3].append(40)
# list0[3] 这个变量 指向 [10,20,30] 这个对象
list0=[1,2,3,[10,20,30]]
list00=copy.deepcopy(list0)
# list00=copy.deepcopy(list0)
print(f"调用前的list0:{list0}")
print(f"调用前的list00:{list00}")
change_list(list00)
print(f"调用后的list0:{list0}")
print(f"调用后的list00:{list00}")
Out:
调用前的list0:[1, 2, 3, [10, 20, 30]]
调用前的list00:[1, 2, 3, [10, 20, 30]]
调用后的list0:[1, 2, 3, [10, 20, 30]]
调用后的list00:[1, 2, 3, [10, 20, 30, 40]]
```

`copy.deepcopy()` 是深拷贝（deep copy）。它不仅创建一个新的列表，会把原列表的每个元素指向的对象创建一个新的副本对象，再让新列表的元素都指向这些新的副本对象！这样一来，原列表跟新列表半毛钱关系也没有了！！显然，小整数池那就还是那样！不会有个新的副本对象出来！这样，你让 `list00[3].append(4)`，就是在操作 `0x5678` 这个地址的 list 对象了！

![image](https://img2024.cnblogs.com/blog/1910062/202604/1910062-20260414180058151-1446651621.png)

### 7. 函数嵌套调用

![image](https://img2024.cnblogs.com/blog/1910062/202604/1910062-20260414182017316-1994238758.png)

**让函数对象进栈这个说法是错误的，正确的应该是创建一个栈帧，然后执行这个函数。** 不过能理解即可

调用 func_a，那么 func_a 这个函数对象进栈，接着执行 func_a 的代码，调用了 func_b，那么 func_b 这个函数对象进栈，执行完了 func_b 的代码后，func_b 这个函数对象立马出栈，回到 func_a，func_a 执行完后也出栈了。

![image](https://img2024.cnblogs.com/blog/1910062/202604/1910062-20260414182004304-980540098.png)

### 8. 闭包

#### 为什么要有闭包？

**闭包的需求：在一个函数里面访问另一个函数中定义的变量。**

```python
def outer() :
    a=10
def inner() :
    print(a)
```

现在想要在 `inner` 里面访问 `a`，咋办呢！

一种是利用函数参数传递。

```python
def outer() :
    a=10
    inner(a)
def inner(a) :
    print(a)
outer()
```
但是太麻烦了！所以有了闭包

#### 具体原理

```python
def outer():
    a = 10        # 外层变量
    def inner():  # 内层函数
        print(a)  # 引用外层变量
    return inner  # 把内层函数返回

f = outer()  # 调用外层，得到内层函数
f()          # 执行内层函数
```

```
┌─────────────────────────────┐    ┌─────────────────────────────────────────┐    ┌─────────────────┐
│        🔴栈内存(临时)       │    │           🟠堆内存(永久对象)            │    │  🟡小整数池     │
│  函数执行栈帧，用完即删     │    │  所有函数/闭包/变量本体都在这          │    │ [-5~256]        │
│                             │    │  ┌─────────────────────────────────┐    │    │                 │
│  1. outer()执行时：         │    │  │  模块对象 全局__dict__          │    │    │  0x5555 == 10  │
│  ┌─────────────────────┐   │    │  │  outer → 0x1111                 │    │    └─────────────────┘
│  │ outer栈帧(临时)     │   │    │  │  inner → 0x2222                 │    │
│  │ a → 0x5555(10)     │   │    │  │  f     → 0x2222                 │    │
│  │ inner→0x2222        │   │    │  └─────────────────────────────────┘    │
│  └─────────────────────┘   │    │                                         │
│                             │    │  ┌─────────────────────────────────┐    │
│  2. outer执行结束 ✅栈帧删除│    │  │ outer函数对象 0x1111            │    │
│  （重点：a没被删！）       │    │  └─────────────────────────────────┘    │
│                             │    │                                         │
│  3. f()执行时：             │    │  ┌─────────────────────────────────┐    │
│  ┌─────────────────────┐   │    │  │ inner函数对象 0x2222【闭包】    │    │
│  │ inner栈帧(临时)     │   │    │  │ 【闭包单元格__closure__】       │    │
│  │ 无局部变量           │   │    │  │ a → 0x5555 (永久绑定10)        │    │
│  └─────────────────────┘   │    │  └─────────────────────────────────┘    │
└─────────────────────────────┘    └─────────────────────────────────────────┘
```

还是要抓住 **一切皆对象** 的思想。

逐行执行 + 内存变化（核心！）

**加载到 def 的时候，就在堆里创建函数对象，然后调用函数的时候是创建了一个栈帧，执行这个函数。**

**这也是为什么每次调用 outer() 都会返回一个新的 inner 函数对象的原因。是因为每次调用 outer 每次执行到 def inner 这一行的时候，一看到是 def，然后就直接在堆区中创建一个新对象了嘛？Yes！**

**函数对象的命名空间（__dict__) 位于堆内存，是永久的，但是从来不存放什么局部变量！！！** **而函数执行时的局部命名空间（栈帧）**，是当**调用函数的时候才诞生，并且专门用来存放局部变量的**，一旦函数**结束，这个空间就销毁了**，自然局部变量也销毁了。

- 函数定义 = 造了一个空盒子（堆里的__dict__），不放变量
- 函数调用 = 临时搭一个工作台（栈帧），变量全放工作台上
- 函数结束 = 工作台直接砸烂，变量全没

1. 定义函数 def outer
堆内存：在整个 .py 模块加载的时候，看到最外层的，def outer，会创建 outer(0x1111) 函数对象。
全局命名空间：绑定 outer → 0x1111
**注意，此时 `inner` 函数对象在堆区中并没有！因为在最外面看不到 `def inner`！**
✅ 无栈操作（只定义不执行），**只有调用函数才会入栈。**
2. 执行 f = outer() 【闭包关键步骤】
🔴栈：调用了 outer 这个函数，**所以创建 outer 栈帧**，存在栈帧中的局部变量 a 指向小整数池的 10(0x5555)
🟠堆：**执行到 `def inner` 的时候，会在堆中创建 `inner` 函数对象 (0x2222)。并且inner 函数偷偷绑定 a，生成闭包单元格**
outer 返回 inner 地址，全局变量 f → 0x2222
🔴栈：outer 栈帧直接删除，此时存在栈帧中的局部变量 a 销毁了！
**闭包灵魂考点（和普通函数最大区别）**
普通函数：栈帧删了 → 局部变量a直接消失
闭包函数：**a 永久存活在堆区的 inner 函数对象的闭包单元格里了！**inner抱着a的引用存在堆里 → a 永久存活
3. 执行 f()
🔴栈：创建 inner 栈帧
自己没有a → 去堆里的闭包单元格找 a=10
打印 10，执行结束 → 栈帧删除
🟠堆：inner和a 依然存在，下次调用还能用

### 9. 变量的作用域

```python
a = int(2.9)  # 内建作用域 (Python本身提供的,在所有位置都可以访问)
b = 0  # 全局作用域
def outer():
    c = 1  # 嵌套作用域
    def inner():
        d = 2  #局部作用域
        print(d,c,b,a)
    return inner
in_func=outer()
in_func()
```

这里的 `a = int(2.9)`，哪里有 `int()` 这个函数呢？在内建作用域里，是 Python 给我们提供的。

找变量按照这个顺序去找！其实靠感觉也 ok 啦！
`局部作用域 Local -> 嵌套 Enclosing -> 全局 Global -> 内建 Built-in`

### 10. 全局变量和局部变量

#### 赋值与修改
- 局部变量：定义在函数体内
- 全局变量：定义在函数体外

其实注意抓清楚，他们的作用域就好了。

当你在函数内部对一个变量进行**赋值**操作时，Python 默认会把这个变量当作局部变量。
**注意：只是赋值操作！你要访问的时候，该咋找咋找！**
```python
var1=20
def func() :
     var1=100 # 这是一个赋值操作，在函数体内部，所以会当成这是一个局部变量，创建一个新的局部变量
    # var1+=10 这个也是一个赋值操作，也是当成局部变量，但是找不到定义
    print(var1)
func()
print(var1) # 仍为20
100
20
```

但是，如果说是执行**修改**操作，那么 Python 就会去找这个变量在哪，而不是默认当成局部变量。

- 赋值：变量指向的对象发生改变，也就是变量指向的内存地址改变
- 修改：变量指向的内存地址不变，但是指向的对象本身发生改变

```python
list0=[1,2,3]
def func() :
    list0[0]=100 # 这是一个修改操作，所以不会默认当成局部变量
    print(list0)
func()
print(list0)
[100, 2, 3]
[100, 2, 3]
```
#### global
如果，我们想要让 Python 知道，我们使用的这个变量是全局变量，那么可以用 `global` 去声明全局变量。

```python
def function_a():
    global var1
    var1 = 200
    print("var1:", var1)
var1 = 100
print(var1)  # 100
function_a()  # var1: 200
print(var1)  # 200
```
#### nonlocal
如果，想要使用的变量不在全局作用域，而是在嵌套作用域，那就用 `nonlocal`。
这里看 `inner` 里的 `var1`，它的外部作用域是嵌套作用域，它如果想赋值外面的 `var1`，就要用 `nonlocal` 来声明。
```python
def function_outer():
    var1 = 1
    print(var1)
    def function_inner():
        nonlocal var1
        var1 = 200
    function_inner()
    print(var1)
function_outer()  # var1: 1 -> 200
```

### 11. lambda（匿名函数）
lambda函数拥有自己的命名空间，且不能访问**自己参数列表之外或全局命名空间里的参数**。
```python
def cal(x,y,op) :
    return op(x,y)
ans=cal(1,5,lambda x,y: x+y)
# lambda 参数: 返回的表达式
print(ans)
```

## 10. 文件

### 基础用法

```python
"""# 打开文件，获取 file 对象
f=open("test.txt","w")
# 写入数据
f.write("hello\n")
f.write("I'm back\n")
# 关闭文件
f.close()"""
file=open("test.txt","r")

"""
print(file.read()) # 读入所有
print(file.read(3)) # 读 3 个字节

print(file.readline(),end="") # 读一行数据，换行也读了
print(file.readline(),end="")
"""
# print(file.readlines()) # 读取所有行，搞成个列表
print(type(file.read())) # type: str

file.close()
```

### 文件拷贝案例

```python
"""
E 盘有一个 doubao.png
我要把它在 D 盘也复制一份
"""

def copy(source_path,dest_path) :
    source_file=open(source_path,"rb")
    dest_file=open(dest_path,"wb")
    content=source_file.read()
    dest_file.write(content)
    dest_file.close()
    source_file.close()

copy("E:/doubao.png","D:/doubao.png")
```

## 11. 面向对象之类与对象

### 1. 类与对象

#### 类

类是啥？比如人类，闹钟，狗，这些，你知道这些是小明、小红、小白、这些对象的创建模板，比如人类有他的属性：身高、体重，那对于小明小红来说，他们也有身高体重。因此，可以把类看成是大量对象共性的抽象。

#### 对象

"Everything is Object!" 万物皆对象！

任何事物都是对象，小明是对象，小红是对象，宿舍里的 TCL 空调也是一个对象！

一个对象有属性（有啥）、方法（能干啥）

### 2， 基础例子

创建实例对象的时候，会调用 `__init__` 方法。

```python
class Person :
    """这是人的类""" # 类说明文档 doc
    home="earth" # 类属性，就是 Person 这个类自带的属性，因为类也是对象！
    def __init__(self,age):
        print("调用了 __init__ 方法！")
        self.age=age # 实例属性，就是小明、小红这些实例的年龄
    def say(self):
        print(f"hello my age is{self.age}")
xiaoming=Person(15) # 创建实例
xiaoming.say()
print(Person.home)
```
```
调用了 __init__ 方法！
hello my age is15
earth
```

### 3. 内存分析

**变量（名字）是 key，对象（数据）是 value！，加载到名字的时候，就扔到对应命名空间的 key 中；加载到对象的时候，就在堆区中创建一个对应的对象！**

一开始，整体读一遍，只读全局，最外围（也就是缩进为 0）的那些名字，然后扔到函数的命名空间的 key。接下来，整体读，看看哪些加载到了，就是创建对象！比如，读到 `def`，那就是在堆区中创建一个函数对象！然后把名字和对象绑定，也就是在`__dict__`里填。

然后比如缩进为 `1 tab` 的那些，比如在函数体内有个 `def`，那么等到调用这个函数，读到那一行的时候，才会去创建这个函数对象。

```python
class Student:
    # 类属性
    school = "atguigu"

    def __init__(self, name, age):
        # 实例属性
        self.name = name
        self.age = age

    def 站着听(self):
        print(f"年龄是{self.age}的小伙{self.name}正在站着听课")

xjq = Student("xjq", 20)
print(xjq.name)
print(xjq.age)
xjq.站着听()
```

1. 加载模块对象，就是整个 `.py` 文件。发现有个 `Student` 这个名字，还有个 `xjq` 这个名字，都扔到模块对象的命名空间的 `key` 里面，然后创建一个类对象（`0x1111`），对应 `value` 填进去。然后创建这个类对象的时候去读，发现有个 `school`，还有个 `init`，站着听，都是名字！扔到对应命名空间的 `key` 里面，并且创建他们对应的数据的对象（`0x2222`,`0x3333`,`0x4444`)，然后形成 `key&value` 的映射！。

2. 创建 `xjq` 实例对象，怎么样创建？其实是先调用这个类对象的 `new` 方法创建了一个对象（`0x7777`），但是**此时学生对象的命名空间为空**。然后调用 `init` 函数，并且把创建的对象传入到 `self` 里面。这部分其实对应 `new`，`init` 这两个方法都会在创建其对应的栈帧。

3. 调用 `init` 函数，你发现传参还有 `"xjq",20`，所以这两部分也会创建个对象，其中 20 是在小整数池中的对象。传参的时候其实就是一个 `key&value` 的映射。

4. 执行 `self.name=name`，是在实例对象（`0x7777`）的命名空间中添加个 `name`，并且跟 `name` 传入的 `"xjq"` 这个字符串进行一个对应！所以你能看到 `0x7777` 里面的 `name` 指向的是 `0x5555`。

5. 调用站着听这个方法，其实站着听这个方法在类命名空间里的，所以 `xjq.站着听()` 其实是调用类命名空间里的这个方法，并且把 `xjq` 这个实例对象传到 `self` 里面。

![image](https://img2024.cnblogs.com/blog/1910062/202604/1910062-20260418160230029-1009788812.png)

### 4. 封装，私有化

进行私有化有利于我们去加一些校验跟拦截，比如让 `age` 这个属性永葆 18 岁！

#### 一个 simple 的想法

```python
class Person:
    # 加 __ 就可以私有化属性/方法
    # 相当于底层把 __名字 改写成了 _类名__名字
    def __init__(self,name,age):
        self.name=name
        self.__age=age # 把 age 私有化了！
    def get_age(self):
        if self.__age>18: # 进行一个拦截
            return 18
        return self.__age
    def set_age(self,age):
        self.__age=age
p1=Person("小明",60)
print(p1.get_age()) # 永远 18 岁
# 这个就是封装，把 __age 私有化，只暴露 set 跟 get 方法
```

#### 利用 property（属性）

语法糖而已，利用 `property` 将原先调用 `p1.get_age()` 这个方法可以省略个 `()`，但是本质还是调用这个方法。经过两个装饰器后，这个 `age` 被我们调用起来就像属性一样了！

```python
class Person:
    # 加 __ 就可以私有化属性/方法
    # 相当于底层把 __名字 改写成了 _类名__名字
    def __init__(self,name,age):
        self.name=name
        self.__age=age # 把 age 私有化了！
    @property
    def age(self):
        if self.__age>18: # 进行一个拦截
            return 18
        return self.__age
    @age.setter
    def age(self,age):
        self.__age=age
p1=Person("小明",60)
print(p1.age)
p1.age=15
print(p1.age)
```
### 5. 继承

继承就是有个子类和有个父类，子类继承于父类，能够获取父类的属性和方法，然后子类可以新增自己的属性和方法，也可以对父类中的方法进行重写。

子类不能继承父类的私有属性和方法（底层是作了名称改写，当作规定即可）

#### 单继承

```python
class 类名(父类):
    类体
```

#### 多继承
调用方法时先在子类中查找，若不存在则从左到右依次查找父类中是否包含方法。

把层次图画出来，从下到上依次找，同层从左到右找！

找命名空间里有没有这个 key，有就调用 value 对应的函数对象。
```python
class 类名(父类1, 父类2, ...):
    类体
```
#### 复用父类方法

子类中可以用以下两种方式调用父类中的方法！

```python
super().方法名
父类名.方法名()
```
#### 方法重写

重写不过是子类中有个跟父类中同名的方法，子类中的那个函数对象在子类的命名空间中就跟这个名字（key）对应上了！**这样本来找的话，先找子类命名空间，子类命名空间没有这个 key，那么上父类；现在子类中就有这个 key 了！**

然后如果说一个类中有两个名字相同的方法，那么加载的时候，看到第一个，就先在这个类的命名空间 key 跟第一个的函数对象对应；到第二个的时候也是，所以会后来的覆盖掉前面的！！

```python
class Person:

    home = "earth"

    def __init__(self, name):
        self.name = name

    def eat(self):
        print("eating...")

class Chinese(Person):

    color = "yellow"

    # 重写父类方法
    def eat(self):
        print("用筷子吃")

y1 = Chinese("张三")
y1.eat()
```
#### 综合案例

```python
class Father1:
    def __init__(self,val1,**kwargs):
        # kwargs 是一个字典，那你传参的时候肯定是
        # val1=val1,val2=val2 而不是传一个 {"val1",val1} 这样的字典
        # 所以需要解包
        self.val1=val1
        super().__init__(**kwargs)
class Father2:
    def __init__(self,val2,**kwargs):
        self.val2=val2
        super().__init__(**kwargs)
class Son(Father1,Father2) :
    def __init__(self,val1,val2): # 相当于对 init 方法进行重写
        # 直接写
        # self.val1=val1
        # self.val2=val2

        # 直接调用父类命名空间的 init 方法
        # Father1.__init__(self,val1)
        # Father2.__init__(self,val2)

        # 利用 super() 实际上是在 mro 中找上一个的性质
        super().__init__(val1=val1,val2=val2)
p1=Son(15,20)
print(Son.__mro__)
print(p1.val1,p1.val2)
```

### 6. 多态

同一事物在不同场景下呈现不同状态。
父类类型的参数可以传子类对象！返回值也是一样！
其实就是重写父类方法！父类提供一个接口！

```python
class Animal:
    def go(self):
        pass

class Dog(Animal):
    def go(self):
        print("跑")

class Fish(Animal):
    def go(self):
        print("游")

class Bird(Animal):
    def go(self):
        print("飞")

def go(animal):
    animal.go()  # 将不同的实例传入，执行不同的方法

dog = Dog()
fish = Fish()
bird = Bird()
go(dog)
go(fish)
go(bird)
```

## 12. 生成器

### 推导式创建生成器
```python
from collections.abc import Iterator
generator=(x for x in range(5) if x%2==0)
print(isinstance(generator,Iterator)) # 生成器是迭代器
print(generator)
# print(next(generator))
# print(next(generator))
# print(next(generator))
# print(next(generator))
# print(next(generator))
for i in generator:
    print(i)
```

### 函数创建生成器
yield 会返回数据作为新生成的结果，并且暂停函数执行；下一次调用 `next` 的时候，会按下开始键，接着执行函数，然后你又遇到 yield 了！

```python
def fibo():
    a,b=0,1
    print("进来了！")
    while True:
        print("一次循环开始了！")
        yield b
        a,b=b,a+b
        print("一次循环结束了！")
f=fibo() # 没有执行这个 fibo() 函数
print(f)
# 第一次调用 next 的时候，才会去执行这个函数
print(next(f))
print("~~~~~~~~~~~~~~~~~")
print(next(f))
print("~~~~~~~~~~~~~~~~~")
print(next(f))
```
### send
```python
"""
    实现切换 gen 是在生成 0,1,2,3,4 or A,B,C,D,..
    利用 send 方法，send 发送的值会作为 yield 整个表达式的结果！
    并且接着执行！
    所以可以用 send 来控制 task_id
"""
def gen():
    task_id=0
    int_value=0
    char_value="A"
    print("我启动了！！")
    while True:
        if task_id==0:
            task_id=(yield int_value)
            # 先执行 yield int_value，返回 int_value
            # 等待 send 的结果后，赋值给 task_id
            int_value+=1
        elif task_id==1:
            task_id=(yield char_value)
            char_value=chr(ord(char_value)+1)
            # 先转 ascii，再转 unicode
g=gen()
print("~~~~~~~")
print(g.send(None)) # send(None) 来启动生成器
print("~~~~~~~")
print(g.send(0))
print(g.send(1))
print(g.send(1))
print(g.send(1))
print(g.send(1))
```

## 13. 装饰器

```python
from math import sqrt

def func(x):
    """开根号"""
    return sqrt(x)

def decorator(f):
    def inner(x):
        x = abs(x)  # 求x的绝对值
        return f(x)

    return inner

func = decorator(func)
print(func(-4))  # 2.0
```

一开始，整个模块对象加载，创建 `func,decorator` 两个函数对象；接着，调用 `decorator(func)`，会去执行这个函数，并且加载 `inner`，会在堆区创建这个函数对象，并且最后返回这个 `0x3333`，这样在模块命名空间中，`func` 这个名字指向的就是 `0x3333` 这个函数对象了！

![image](https://img2024.cnblogs.com/blog/1910062/202604/1910062-20260426175903829-1762323455.png)

## 14. 进程与线程

https://xiaolincoding.com/os/4_process/process_base.html#%E8%B0%83%E5%BA%A6%E7%AE%97%E6%B3%95

简单概括：进程就是一个分配到资源的地方（可看成车间），然后线程是 CPU 调度的单位（车间工人）。一个进程在运行，本质上是这个进程里的某个线程在运行。

### 同时读写文件案例

```python
import time
import multiprocessing

def write_file():
    count=0
    with open("test.txt","a") as f:
        while True:
            count+=1
            f.write(f"{count} hello world\n")
            f.flush()
            time.sleep(0.1)

def read_file():
    with open("test.txt","r") as f:
        while True:
            time.sleep(0.1)
            print(f.readline())

if __name__ == '__main__':
    p1=multiprocessing.Process(target=write_file)
    # 创建一个进程
    p2=multiprocessing.Process(target=read_file)
    # 创建一个进程
    p1.start()
    p2.start()
```

为啥需要 `main` 的这个东西，因为主进程时 python 解释器在读到 `p1.start()` 的时候，会创建这个 `p1` 进程，这个进程又会再读一次代码，如果没有 `main` 的话，那么 `p1` 这个进程读到 `p1=...` 的时候，又会去创建新的子进程了，这样无限递归。

### 自定义 Process 子类来创建进程

```python
import os
import multiprocessing
import time

class MyProcess(multiprocessing.Process):
    # 从这个 Process 继承过来
    # 这样相比与 target=函数名，能够去 work 更复杂的任务
    # 调用 start 方法去启动进程，创建一个新进程，新进程调用 run
    # 并且这个新进程的父亲就是当前第一次执行这个 .py 的主进程
    # 因为新进程是在主进程执行到那行代码的时候创建的
    def run(self):
        print(f"当前进程id:{os.getpid()}，父进程 {os.getppid()}")

if __name__ == '__main__':
    for i in range(5):
        p=MyProcess()
        p.start()
```

## 15. 正则表达式

跳过了 `python` 里的网络编程，这部分将在 go 那里再学。
