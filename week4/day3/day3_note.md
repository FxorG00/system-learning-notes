## lseek

它只修改 open file description 中的 offset！！！

不只是查询，而且会修改，然后返回新的 offset！

## fd,open file description,文件对象

```text
进程中的 fd
    ↓
fd 表项
    ↓
open file description
    ↓
文件对象（inode）
    ↓
文件数据
```

注意是你去 open 后得到 fd，这个时候通常会创建一个新的 open file description，用来存放你的 offset 这些状态。

---

## 同一路径 open 两次与 dup（duplicate）的根本区别

### 同一路径 open 两次

```cpp
int fd1 = ::open("letters.txt", O_RDONLY);
int fd2 = ::open("letters.txt", O_RDONLY);
```

模型：

```text
fd 3 ─→ open file description A：offset = 0 ─┐
                                               ├→ 同一个底层文件
fd 4 ─→ open file description B：offset = 0 ─┘
```

虽然底层文件相同，但每次 `open` 通常创建新的 open file description，所以两个 offset 相互独立。

### 对一个 fd 调用 dup

`dup` 来自 **duplicate a file descriptor**。它的主语是 file descriptor，不是 file：

```text
复制一个 fd 表入口
而不是复制文件内容
```

```cpp
int fd2 = ::dup(fd1);
```

模型：

```text
fd 3 ─┐
      ├→ 同一个 open file description：offset = 0 → 底层文件
fd 4 ─┘
```

`dup` 创建一个新的 fd 表入口，但两个 fd 指向同一个 open file description，因此共享：

```text
当前文件偏移
文件状态 flags
```

如果通过 fd 3 读取 3 字节，offset 变为 3；接着通过 fd 4 读取，就会从 offset 3 开始。

### close 一个 dup 出来的 fd 会怎样

open file description 在内核中有引用关系。关闭 fd 3 只是删除一个 fd 表入口：

```text
fd 3：关闭
fd 4：仍然指向原来的 open file description，可以继续使用
```

只有最后一个引用它的 fd 被关闭后，这次打开对应的内核状态才会被释放。

---

## inode,dev

对，你可以这样拆：

```
st_dev
│  └─ dev = device，设备
└──── st = struct stat 的字段前缀
```

`st` 可以帮助记成 **status/stat**，但更准确地说，它表示“这是 `struct stat` 返回的字段”，不必把每个 `st_` 都强行当作某个正式缩写。

**inode 是什么**

`inode` 通常解释为 **index node（索引节点）**。它是文件系统中用来表示一个文件对象的数据结构。

inode 主要记录：

```
文件类型
权限
所有者
文件大小
时间信息
硬链接数量
文件数据存放位置
```

注意：**文件名通常不在 inode 里面**。目录大致保存：

```
文件名 → inode number
```

因此两个不同文件名可以指向同一个 inode，这就是硬链接。

**`st_ino`**

```
ino = inode number
st_ino = 文件在所属文件系统中的 inode 编号
```

inode 编号只保证在**同一个文件系统内部唯一**。

**`st_dev`**

```
dev = device
st_dev = device ID
```

它表示：这个文件所在的文件系统位于哪个设备上。这里的“设备”不一定要理解成一整块物理硬盘，更接近“承载该文件系统的设备标识”。

因此判断两个路径当前是否指向同一个文件，需要同时比较：

```
a.st_dev == b.st_dev && a.st_ino == b.st_ino
```

可以这样记：

```
st_dev = 哪个小区
st_ino = 小区里的门牌号
```

只有“小区 + 门牌号”都相同，才能确认是同一个文件对象。因为不同文件系统可能碰巧使用相同的 inode number。[Linux `inode(7)`](https://man7.org/linux/man-pages/man7/inode.7.html) 和 [`stat` 类型说明](https://man7.org/linux/man-pages/man3/stat.3type.html)也是这样定义这两个字段的。

## 软链接，硬链接

先把这三条命令逐字拆开：

```
printf 'same data\n' > original.txt
ln original.txt hardlink.txt
ln -s original.txt symlink.txt
```

### 第一条：创建文件

```
printf 'same data\n' > original.txt
```

这里的 `printf` 是 Shell 命令，不是 C++ 的 `printf()`。

```
printf：输出指定内容
\n：换行
>：把输出写入文件；文件存在则先清空
original.txt：目标文件
```

最终得到：

```
original.txt 内容为：

same data
```

### 第二条：创建硬链接

```
ln original.txt hardlink.txt
```

`ln` 来自 **link（链接）**。

这条命令给同一个文件对象增加了一个新名字：

```
original.txt ──┐
               ├──→ 同一个 inode、同一份文件数据
hardlink.txt ──┘
```

所以 `original.txt` 和 `hardlink.txt`：

- 文件名不同。
- inode 相同。
- 内容是同一份。
- 修改其中一个，另一个看到的内容也会改变。
- 删除其中一个名字，另一个仍然可以正常访问数据。

例如：

```
echo "changed" > hardlink.txt
cat original.txt
```

输出也是：

```
changed
```

因为它们本来就是同一个文件对象的两个名字。

可以检查 inode：

```
ls -li original.txt hardlink.txt
```

开头的 inode number 应该相同：

```
12345 ... hardlink.txt
12345 ... original.txt
```

硬链接通常不能跨文件系统，也通常不允许普通用户给目录创建硬链接。

### 第三条：创建软链接

```
ln -s original.txt symlink.txt
```

这里：

```
-s = symbolic
symlink = symbolic link
```

也就是**符号链接/软链接**。

它的关系是：

```
symlink.txt
    │
    │ 保存字符串 "original.txt"
    ↓
original.txt → 真正的文件对象
```

`symlink.txt` 自己是一个独立的特殊文件，有自己的 inode。它的内容可以理解为目标路径：

```
original.txt
```

因此：

```
cat symlink.txt
```

系统会先读取链接中的目标路径，然后访问 `original.txt`。

如果删除原文件：

```
rm original.txt
```

那么：

- `hardlink.txt` 仍然有效，因为它直接指向原来的 inode。
- `symlink.txt` 失效，因为它保存的路径 `original.txt` 已经找不到了。

失效的符号链接称为：

```
dangling symbolic link
悬空符号链接
```

## O_TRUNC 要放在身份验证后

这里说的是 `copyfile` 的一个危险边界。

`O_TRUNC` 中：

```
O = open option，open 的选项
TRUNC = truncate，截断、清空
```

例如：

```
::open(target_path, O_WRONLY | O_CREAT | O_TRUNC, 0644);
```

只要目标文件已经存在，`O_TRUNC` 就会立即把它的长度变成 `0`，相当于先清空文件。

假设执行：

```
ln original.txt hardlink.txt
./copyfile original.txt hardlink.txt
```

虽然路径不同，但它们指向同一个 inode：

```
original.txt ──┐
               ├→ 同一个文件对象
hardlink.txt ──┘
```

### 错误顺序

```
open("original.txt", O_RDONLY);

open("hardlink.txt",
     O_WRONLY | O_TRUNC);  // 这里已经清空底层文件

// 然后才比较 st_dev 和 st_ino
```

第二次 `open()` 执行时，`O_TRUNC` 已经把共同的 inode 清空了。

即使源文件的 fd 早就打开了也没用：

```
source_fd ──→ 同一个 inode ── 文件内容已经被清空
target_fd ──→ 同一个 inode
```

之后再检查并输出“源和目标是同一文件”，已经太晚了，数据没了。

### 正确思路

必须先检查：

```
stat(source_path, &source_stat);
stat(target_path, &target_stat);

if (source_stat.st_dev == target_stat.st_dev &&
    source_stat.st_ino == target_stat.st_ino) {
    // 同一个文件，拒绝复制
}
```

确认不是同一个文件之后，才允许：

```
open(target_path, O_WRONLY | O_CREAT | O_TRUNC, 0644);
```

顺序就是：

```
先检查身份
→ 确认源和目标不是同一个文件
→ 再执行 O_TRUNC 这种破坏性操作
```

一句话记忆：

```
O_TRUNC 是“先清空目标文件”。

所以必须先确认目标不是源文件，才能清空。
```

不过 `stat()` 检查和后续 `open()` 之间仍存在一小段时间窗口，路径可能被其他进程替换，这就是 Day3 提到的 `TOCTOU`。当前阶段先掌握“危险操作必须晚于身份检查”即可。

## 验收问题

```text
1. fd 数字本身为什么没有保存文件偏移？
因为 fd 本身只是一个整数，没办法保存额外的信息了。

2. open file description 至少保存哪些今天关心的状态？
offset 

3. read 成功返回 n 后，哪一层的什么状态发生变化？
open file description 的 offset

4. 对同一路径 open 两次，为什么偏移通常相互独立？
因为 open 两次生成了两个独立的 fd，open file description，然后 offset 保存在两个独立的 open file description 上。

5. dup 创建了什么，复用了什么？
dup 创建了一个新的 fd 数字。
复用了 open file description

6. duplicated fd 的整数不同，为什么仍共享偏移？
因为指向同一个 open file description

7. stat(path) 和 fstat(fd) 分别从哪里找到文件对象？
一个是用 path，路径
一个是用 fd 去找

8. 路径在 open 后被重命名，为什么原 fd 通常仍可使用？
因为 fd 仍然指向那个底层文件对象。

9. 判断同一文件为什么要同时比较 st_dev 和 st_ino？
st_dev 就是去 check 两个文件的 device_id，就是两个文件是不是在同一个文件系统。
然后 st_ino 是去check这个inode编号一不一样。
得在同一个文件系统并且 inode 一样才是同一个文件。

10. Day2 copyfile 的同文件检查为什么必须在 O_TRUNC 前完成？
因为用 O_TRUNC open file 会清空 file，如果 copyfile 的 source,destination 是同个文件，那么就会把这个文件对象的数据给清空了。


11. lseek(fd, 0, SEEK_CUR) 有什么用途？
获取当前的 offset，然后不修改任何东西。

12. 对 duplicated fd 调用 lseek，为什么 original fd 的后续 read 也受影响？
因为二者指向的 open file description 一样，然后 offset 存在这里。

13. 为什么 pipe 没有普通文件式的随机偏移？
还没学。

14. 三个 UniqueFd 分别拥有不同 fd，但其中两个共享 open file description，这会不会造成 double close？为什么？
因为 一个 fd 关闭后，这个 open file description 仍然是开启的，因为还有另一个 fd 指向它。等到两个完全 close 了之后，这个 open file description 才会释放。
```

