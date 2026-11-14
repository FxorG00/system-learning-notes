# R1

## review 一下 api(copy file)

```cpp
#include "unique_fd.hpp"
#include <unistd.h>
#include <iostream>
#include <cerrno>  // errno 及相关错误码；perror 会解释当前 errno
#include <cstddef> // std::size_t
#include <cstdio>  // fprintf、perror、stderr
#include <fcntl.h> // open、O_RDONLY

bool write_all(int fd,char* data,std::size_t size) {
    std::size_t offset=0;
    while(offset<size) {
        const ssize_t written=::write(fd,data+offset,size-offset);
        if(written>0) {
            // 成功写入 
            offset+=static_cast<std::size_t>(written);
        } else if(written==0) {
            // 没有进展
            // 认为失败
            ::fprintf(stderr,"write: return 0 bytes\n");
            return false;
        } else if(written==-1&&errno==EINTR) {
            // 当前被信号打断，重新调用
            continue ;
        } else {
            ::perror("write");
            return false;
        }
    }
    return true;
}

bool copy_file(int source_fd,int destination_fd) {
    // 每次从 source_fd 里 read
    // 再 write_all 到 destination_fd
    // 读一段，write 一段，知道读到 EOF，count=0
    char buffer[4096];
    while(1) {
        const ssize_t count=::read(source_fd,buffer,sizeof(buffer));
        if(count>0) {
            // 表示 buffer[0,count-1] 是有效的
            if(!write_all(destination_fd,buffer,count)) {
                return false;
            }
        } else if(count==0) {
            // EOF
            return true;
        } else {
            if(errno==EINTR) {
                continue ;
            } else {
                ::perror("read");
                return false;
            }
        }
    }
    return true;
}
// ./copyfile source.txt destination.txt
// main 的返回值，0表示成功，非0表示失败。
int main(int argc,char* argv[]) {
    if(argc!=3) {
        ::fprintf(stderr,"usage: %s <source_file> <destination_file>\n",argv[0]);
        return 1;
    }
    UniqueFd source_fd=UniqueFd(::open(argv[1],O_RDONLY));
    if(!source_fd.valid()) {
        ::perror("open source ");
        return 1;
    }
    UniqueFd destination_fd=UniqueFd(::open(argv[2], O_WRONLY | O_CREAT | O_TRUNC, 0644));
    if(!destination_fd.valid()) {
        ::perror("open destination ");
        return 1;
    }
    if(!copy_file(source_fd.get(),destination_fd.get())) {
        return 1;
    }
    return 0;
} 
```

## 构造函数

```text
如果我们拿到的 fd 非法，那么需要保存 errno 并且抛出 std::system_error
```

## append

```text
append(record)
-> 借用 record 的 bytes
-> 返回前把 record.size() 个 bytes 全部交给 write()

其实就是 write_all
```

# R2

## `sync()`

```text
record 在你的程序内存
        ↓
append()：通过 write() 交给内核
        ↓
fdatasync(fd)：请求同步文件数据并等待
        ↓
fdatasync 返回成功

write() 只能保证交给内核。
所以还需要 sync() 来保证落入到存储设备了。比如落入到磁盘。
```

## strace

```text
openat(AT_FDCWD, "tmp/aof_writer_r2_test_tmp.txt", O_WRONLY|O_CREAT|O_APPEND|O_CLOEXEC, 0644) = 3
write(3, "hello china", 11)             = 11
fdatasync(3)                            = 0
close(3)                                = 0
+++ exited with 0 +++
```

# R3 让短写和错误路径真正发生

就是通过测试，去提供 write_fn_ 跟 sync_fn_，模拟 `::write` 没办法测试的边界。

比如

```text
::write 可能一次就写 28 个 bytes。

但是我想要第一次写入 6 个 bytes
第二次 EINTR 重试
第三次写入剩余的 bytes

就需要我测试提供 callable 给内部调用了。
比如我提供个 lambda，然后有个 cnt，去判断 cnt=1，那么我就拿出来前 6 个 bytes 去 write_all
cnt=2 我就 EINTR
cnt=3 我就写剩余的 bytes
```

