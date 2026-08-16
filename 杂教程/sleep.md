C++ 里优先用 `std::this_thread::sleep_for`：

```cpp
#include <chrono>
#include <thread>

std::this_thread::sleep_for(std::chrono::milliseconds(100));
std::this_thread::sleep_for(std::chrono::seconds(2));
```

需要的库是：

```cpp
#include <thread>
#include <chrono>
```

它会让“当前 C++ 线程”暂停指定时间。

Linux 也有 `sleep(2)`，来自：

```cpp
#include <unistd.h>
```

但它是 POSIX 接口，C++ 练习里通常优先写 `std::this_thread::sleep_for`。