# Week8 Day4：怎样证明 ThreadPool 不只是 happy path 能跑

> 今日定位：不再给 ThreadPool 堆新功能，而是把 Day2、Day3 写下的 contract 变成会真实失败的 executable tests。
>
> 今日继续复用同一份 `include/thread_pool.hpp` 和 `tests/thread_pool_test.cpp`，不复制新的 ThreadPool 实现。

---

# Part 1：前情提要与必要术语

## 1. 从 Day3 接到今天

到 Day3 为止，ThreadPool 计划具备以下能力：

```text
fixed-size workers
bounded task queue
generic submit(function, args...)
future<R> result channel
callable return value / exception propagation
graceful shutdown
accepted tasks drain
workers join
post-shutdown submission rejection
```

但“代码看起来覆盖了这些分支”和“我们已经有证据证明这些 contract”不是一回事。

例如下面的程序会打印 `PASS`：

```cpp
#include <iostream>

int main() {
    const int actual = 41;
    const int expected = 42;

    if (actual != expected) {
        std::cout << "FAIL: expected 42, got " << actual << '\n';
    }

    std::cout << "PASS\n";
    return 0;
}
```

它实际上失败了，却仍然：

```text
打印 PASS
return 0
让 shell / CI 认为 executable 成功
```

所以今天不是“把测试输出写得更漂亮”，而是建立一条可靠链：

```text
written contract
-> controlled scenario
-> observable outcome
-> assertion
-> test case pass/fail
-> test binary exit code
-> CTest / shell 能判断整个验证是否成功
```

---

## 2. 今日最终产出是干什么的

今天有三个产出：

```text
tests/thread_pool_test.cpp
    把 ThreadPool contract 写成 GoogleTest test cases

CMakeLists.txt
    描述怎样构建 test executable、链接 GoogleTest、注册 CTest tests

day4_note.md
    记录 normal / repeat / TSan 三类证据和真实问题
```

输入、输出和执行主体：

```text
输入：ThreadPool public API、test scenario、expected behavior
执行：GoogleTest test binary 创建和使用真实 ThreadPool objects
输出：每个 test 的 assertion result、整个 executable 的 exit code
额外工具：CTest 组织 tests；TSan 检查已执行路径上的 data race
```

今天成功的含义不是“所有 concurrency bugs 从此被数学证明不存在”，而是：

```text
每条核心 contract 都有针对性测试
错误能让 test fail
关键 lifecycle scenario 被确定性地建立
重复运行扩大 scheduling interleavings
TSan 检查已执行路径上的 data race
不同证据的能力边界被写清楚
```

---

## 3. 必要术语

### 3.1 contract

`contract`：契约。

它描述 component 对 caller 承诺的行为，以及 caller 必须遵守的使用边界。

例如：

```text
worker_count == 0 -> constructor throws invalid_argument
submit accepted -> returned future eventually becomes ready
shutdown -> accepted tasks drain, workers join
submit after shutdown -> throws runtime_error
```

contract 不是 implementation 的逐行复述。测试应该从 public behavior 验证 contract，而不是依赖 private member 的具体排列。

---

### 3.2 executable test

`executable`：可执行的。

`executable test` 指可以真正编译运行、自动判断 expected 与 actual 是否一致的测试。

它不是：

```text
注释里写“这里应该等于 42”
手工看一眼终端输出
程序永远 return 0
只打印 ok 但没有 assertion
```

---

### 3.3 test framework

`framework`：框架。

`test framework` 提供 test registration、assertion、结果汇总、失败诊断和 exit code 管理等公共能力。

今天使用 `GoogleTest`，常写作 `GTest`。

GoogleTest 不替你设计 scenario，也不自动知道 ThreadPool 的正确 contract。它只负责运行你注册的 tests，并根据 assertions 汇总结果。

---

### 3.4 test binary

`binary`：这里指编译链接得到的可执行文件。

`thread_pool_test` 是 test binary：

```text
包含多个 TEST definitions
链接 GoogleTest 与 gtest_main
运行时执行 tests
有任意失败时返回 non-zero exit code
```

test binary 不是某一个 `TEST(...)`。一个 binary 中可以注册很多 tests。

---

### 3.5 test suite / test case

`test suite`：测试套件，用于组织一组相关 tests。

`test case`：一个具体 scenario 的测试。

GoogleTest 写法：

```cpp
TEST(ThreadPoolTest, ReturnsSubmittedValue) {
    // one test case
}
```

这里：

```text
ThreadPoolTest：test suite name
ReturnsSubmittedValue：test name
ThreadPoolTest.ReturnsSubmittedValue：完整 test identity
```

GoogleTest 官方文档在自己的术语中会把 `TEST()` 定义出来的单项称为 test；不要因为不同资料对 “test case” 的称呼略有差异而卡住。今天只要保证一个 test name 对应一个清晰 scenario。

---

### 3.6 assertion

`assertion`：断言。

它把 expected behavior 写成自动检查：

```cpp
EXPECT_EQ(actual, 42);
```

若条件不满足，GoogleTest 会记录 file、line、expected/actual 等诊断，并让该 test 失败。

assertion 不是 C++ `assert()` 宏的同义替代。GoogleTest assertions 属于 test framework，能汇总多个 tests；今天不使用 `NDEBUG` 可能关闭的普通 `assert()` 作为主要 test oracle。

---

### 3.7 test oracle

`oracle` 原义是“能给出答案的判定来源”。

`test oracle` 指：测试用什么规则判断 actual behavior 是否正确。

例如 exactly-once test 的 oracle 不能只是：

```text
最终 sum 看起来差不多
```

更强的 oracle 是：

```text
每个 accepted task 都有 unique ID
每个 ID 的 execution count 恰好为 1
没有 missing ID
没有 duplicate ID
没有 unexpected ID
```

---

### 3.8 deterministic test

`deterministic`：确定性的。

今天说 deterministic test，重点不是要求 OS scheduler 每次顺序完全相同，而是：

```text
测试的正确性判断不依赖猜测时间
目标状态由明确 synchronization 建立
expected behavior 不因机器快慢而改变
```

例如用 future、mutex、condition variable、join 和 queue state 建立完成关系；不要只写 `sleep(100ms)` 后猜 task 应该结束了。

---

### 3.9 happy path / edge case

`happy path`：一切输入和时序都顺利的正常路径。

`edge case`：边界场景。

ThreadPool happy path：

```text
construct -> submit one normal task -> get value -> shutdown
```

本周必须覆盖的 edges 包括：

```text
zero workers
zero tasks
many tasks
task exception
pending tasks during shutdown
repeated shutdown
submit after shutdown
concurrent submitters
destructor lifecycle
```

只测 happy path，最多说明最直的一条路径能跑。

---

### 3.10 unit test / component test / integration test

`unit test`：对较小单元做隔离验证。

`integration test`：验证多个对象或模块组合后的行为。

今天的 ThreadPool tests 同时涉及：

```text
ThreadPool
BlockingQueue
std::thread workers
future shared state
shutdown lifecycle
```

严格分类时，它更接近 component/integration-level tests，而不只是一个纯函数 unit test。今天不在命名分类上消耗时间，重点是每个 public contract 都有可执行 scenario。

---

### 3.11 stress test

`stress`：施加压力。

`stress test` 通过更多 tasks、submitters、重复次数或不同 scheduling interleavings 寻找偶发错误。

它可以提高发现概率，但不能证明：

```text
运行 100 次通过 -> 第 101 次绝不失败
没有观察到 race -> 程序没有 data race
没有卡住 -> deadlock 不可能发生
```

---

### 3.12 sanitizer / instrumentation

`sanitizer`：动态错误检测工具家族。

`instrumentation`：编译器在 program 中插入额外检测逻辑。

ThreadSanitizer build 不是普通 binary 外面套一个观察器。compiler 会对 memory access 与 synchronization 插桩，runtime 根据实际执行轨迹检测 data race。

代价是运行更慢、占用更多内存，所以 TSan binary 不用于 benchmark。

---

### 3.13 ThreadSanitizer / TSan

`ThreadSanitizer`，简称 `TSan`：线程消毒器，主要用于检测 data race。

它能帮助回答：

```text
本次真正执行到的路径中
是否观察到两个 threads 对同一 memory location 的冲突访问
且缺少有效 synchronization / happens-before
```

它不能单独证明：

```text
没有 deadlock
没有 lost task
没有 duplicate execution
shutdown contract 正确
future 与 task identity 没串
业务结果正确
所有可能路径都执行过
```

---

### 3.14 data race

当前层次先记：

```text
两个或更多 threads 并发访问同一 memory location
至少一个 access 是 write
这些 accesses 之间没有正确 synchronization relationship
```

在 C++ 中，data race 会带来 undefined behavior。

注意：

```text
所有 accesses 都改成 atomic
```

可能消除某个 data race，但不自动保证整体业务逻辑正确。比如两个 atomics 的组合 invariant 仍可能被破坏。

---

### 3.15 CMake

`CMake` 是 build system generator。

今天它读取 `CMakeLists.txt`，生成当前平台实际使用的 build files，再调用 compiler/linker 构建 targets。

它不是 compiler，也不是 GoogleTest。

当前流程：

```text
CMake configure/generate
-> build tool invokes g++
-> linker links ThreadPool test + GoogleTest + pthread
-> produces thread_pool_test binary
```

---

### 3.16 target

`target`：构建目标。

例如：

```cmake
add_executable(thread_pool_test tests/thread_pool_test.cpp)
```

创建名为 `thread_pool_test` 的 executable target。

后面的 include directories、warning flags、link libraries 都应附着在这个 target 上，而不是靠全局命令到处扩散。

---

### 3.17 CTest

`CTest` 是 CMake 配套的 test runner。

它不替代 GoogleTest：

```text
GoogleTest：定义和运行 C++ test cases
CTest：注册、调用 test executable，并汇总 pass/fail/timeout
```

`gtest_discover_tests` 可以让 CTest 从编译后的 GoogleTest binary 中发现每个 test。

---

### 3.18 fixture

`fixture`：测试夹具，表示多个 tests 共享的 setup/teardown 结构。

GoogleTest 对应 `TEST_F`。

今天先不用 fixture，因为 ThreadPool lifecycle 本身就应在每个 test 中清晰可见。等重复 setup 真正造成维护成本时再抽象，避免一开始把 ownership 藏进复杂 base class。

---

# Part 2：教程主体

# 教程开始：把一句 contract 变成能真实失败的 test

## 4. 测试的最小因果链

以 contract：

```text
submit 一个返回 42 的 task
-> future.get() 应得到 42
```

为例，一条完整 test 包含：

```text
Arrange：构造 ThreadPool 和输入
Act：submit task，并 get result
Assert：actual result == 42
Cleanup：shutdown / destructor 回收 workers
```

常见缩写是 `AAA`：

```text
Arrange
Act
Assert
```

但 concurrency component 还必须主动考虑 cleanup，因为一个提前退出的 test 可能留下 blocked workers 或 joinable threads。

流程图：

```mermaid
flowchart TD
    A[written contract] --> B[construct controlled scenario]
    B --> C[perform public operation]
    C --> D[wait through future join or condition]
    D --> E[observe public outcome]
    E --> F[GoogleTest assertion]
    F --> G{assertion passes?}
    G -- yes --> H[test passes]
    G -- no --> I[test fails with location and values]
    H --> J[cleanup completes]
    I --> J
    J --> K[test binary aggregates result]
    K --> L[exit 0 only if all tests pass]
```

如果缺少 `Assert`，那只是运行 demo；如果失败后仍 exit 0，自动化工具也无法可靠判断。

---

## 5. 三类证据必须分开

### 5.1 deterministic GoogleTest

回答：

```text
给定明确 scenario，这条 contract 是否满足？
```

例如：

```text
submit after shutdown 是否 throw runtime_error
future 是否返回对应 value
每个 unique task ID 是否执行一次
```

### 5.2 stress repeat

回答：

```text
同一组 assertions 在更多 scheduling interleavings 下是否暴露偶发失败？
```

它仍依赖测试本身有正确 oracle。

### 5.3 TSan

回答：

```text
已执行路径中是否观察到 data race？
```

三者关系：

```mermaid
flowchart LR
    C[Contract tests] -->|checks behavior| E[Evidence set]
    S[Stress repeats] -->|explores more schedules| E
    T[TSan] -->|checks executed memory accesses| E
```

不能从其中任何一项推出另外两项的全部结论。

---

## 6. GoogleTest test binary 怎样运行

你在 source 中写：

```cpp
TEST(ThreadPoolTest, ReturnsSubmittedValue) {
    // assertions
}
```

宏会让这个 test 在 GoogleTest registry 中注册。

今天链接 `gtest_main`，因此不用自己写 `main()`。运行 binary 时：

```text
gtest_main 提供 main
-> initializes GoogleTest
-> RUN_ALL_TESTS
-> framework executes registered tests
-> assertions record pass/fail
-> framework prints summary
-> returns 0 only when test run succeeds
```

GoogleTest 不会自动扫描你磁盘上的所有 `.cpp`。只有被编译进当前 test target 的 test definitions 才会注册到这个 binary。

---

## 6.1 具体 complie 流程

`TEST(...)` 不是编译器原生认识的语法。它本质是一个 C++ 宏；你看到“没有 `main`”，是因为 `main` 来自你链接的 `gtest_main` 库。

假设你写：

```cpp
#include <gtest/gtest.h>

TEST(ThreadPoolTest, ReturnsSubmittedValue) {
    EXPECT_EQ(1 + 1, 2);
}
```

构建过程可以这样看：

```text
thread_pool_test.cpp
    |
    | 1. 预处理
    v
展开 #include <gtest/gtest.h>
展开 TEST(...) 宏
    |
    | 2. 编译
    v
thread_pool_test.o
    |
    | 3. 链接
    +--> gtest 库：GoogleTest 框架实现
    +--> gtest_main 库：普通的 main()
    v
thread_pool_tests 可执行文件
```

### 1. 预处理：把 `TEST` 变成普通 C++

预处理器会先处理：

```cpp
#include <gtest/gtest.h>
TEST(ThreadPoolTest, ReturnsSubmittedValue) { ... }
```

`TEST` 大致会展开成这些东西：

```cpp
class ThreadPoolTest_ReturnsSubmittedValue_Test : public ::testing::Test {
public:
    void TestBody();
};

// 创建一个静态注册对象：程序启动时把这个测试登记到 GoogleTest registry
static /* 某个注册对象 */ registration(...);

void ThreadPoolTest_ReturnsSubmittedValue_Test::TestBody() {
    EXPECT_EQ(1 + 1, 2);
}
```

不必记住真实生成的长名字。重点是：

```text
TEST 宏
= 定义一个“测试类 + 测试函数”
+ 创建一个静态注册对象
```

所以不是 GoogleTest 在磁盘上搜索 `TEST`；而是这份 `.cpp` 被编译进程序后，里面的静态注册代码在程序启动时运行，把测试登记进去。

### 2. 编译：每个 `.cpp` 各自变成 `.o`

编译器此时看到的已经是宏展开后的普通 C++。

```text
thread_pool_test.cpp
-> thread_pool_test.o
```

这个 `.o` 里有你的测试函数，也有“向 GoogleTest 注册测试”的代码；但它还缺少 GoogleTest 框架本身的实现，也没有 `main`。

仅仅生成 `.o` 时，暂时没有 `main` 并不报错。因为“最终程序必须有 `main`”是链接阶段才检查的事。

### 3. 链接：`gtest_main` 把 `main()` 提供出来

如果 CMake 写的是：

```cmake
target_link_libraries(thread_pool_tests
    PRIVATE
    GTest::gtest_main
)
```

可以粗略理解为链接器把这些拼成一个程序：

```text
你的 thread_pool_test.o
+ GoogleTest 框架实现
+ GoogleTest 提供的 main()
= thread_pool_tests
```

`gtest_main` 内部大致就是：

```cpp
int main(int argc, char** argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
```

因此运行你的测试二进制时，实际链路是：

```text
gtest_main 的 main()
    ->
InitGoogleTest()
    ->
RUN_ALL_TESTS()
    ->
从 registry 取出已注册的 TEST
    ->
依次执行测试函数中的断言
    ->
打印摘要并返回状态码
```

程序启动时的一个细节是：

```text
静态注册对象的构造
    ->
gtest_main::main()
    ->
RUN_ALL_TESTS()
```

也就是说，`main()` 开始前，你写的 `TEST` 已经登记好了。

最后记住这个分工就够了：

```text
#include <gtest/gtest.h>
    = 让当前 .cpp 看见 TEST / EXPECT_EQ 等声明和宏

GTest::gtest
    = GoogleTest 测试框架实现

GTest::gtest_main
    = GoogleTest 额外提供的 main()
```

如果某天你想自己写 `main()`，就链接 `GTest::gtest`，不要再链接 `GTest::gtest_main`，否则会出现两个 `main` 的链接错误。

---

## 7. 你的 Ubuntu 当前环境

本教程生成时已通过 SSH 实际检查：

```text
Ubuntu compiler：g++ 10.5.0
CMake：3.16.3
libgtest-dev：尚未安装
apt candidate：1.10.0-2
TSan smoke test：通过
```

Ubuntu Focal 当前候选 `libgtest-dev` package 经临时下载检查，包含：

```text
/usr/include/gtest/gtest.h
/usr/lib/x86_64-linux-gnu/libgtest.a
/usr/lib/x86_64-linux-gnu/libgtest_main.a
```

今天开始学习时先安装：

```bash
sudo apt update
sudo apt install libgtest-dev
```

安装后检查：

```bash
dpkg -s libgtest-dev
test -f /usr/include/gtest/gtest.h && echo header-ok
test -f /usr/lib/x86_64-linux-gnu/libgtest.a && echo library-ok
```

不要在项目仓库中复制一份 `/usr/src/gtest` 源码，也不要同时混用 apt、手工编译和 `FetchContent` 三种来源。当前环境先选择 apt package + CMake `find_package(GTest REQUIRED)`，依赖来源保持单一。

---

## 8. 第一个独立 GoogleTest demo

这段代码不测试 ThreadPool，只让你看清 `TEST`、assertion 和 test binary。

程序目的：

```text
定义 add function
注册两个 tests
一个检查 equality
一个检查 boolean condition
由 gtest_main 提供 main
```

```cpp
#include <gtest/gtest.h>

int add(int left, int right) {
    return left + right;
}

TEST(AddTest, ReturnsSumOfTwoPositiveValues) {
    EXPECT_EQ(add(20, 22), 42);
}

TEST(AddTest, ResultCanBeComparedAsBooleanCondition) {
    EXPECT_TRUE(add(1, 1) == 2);
    EXPECT_FALSE(add(1, 1) == 3);
}
```

直接编译：

```bash
g++ -std=c++17 -Wall -Wextra -g -pthread \
    add_test.cpp -lgtest -lgtest_main -o add_test

./add_test
echo $?
```

预期：

```text
2 tests passed
exit code 0
```

故意把第一个 expected 改成 `43` 再运行：

```text
assertion 显示 actual/expected 差异
test binary exit code non-zero
```

这个错误实验很重要。只看成功输出，无法证明 failure 真的能传递给 shell。

---

## 9. `TEST` 宏

header：

```cpp
#include <gtest/gtest.h>
```

使用形态：

```cpp
TEST(TestSuiteName, TestName) {
    // scenario and assertions
}
```

参数：

```text
TestSuiteName：组织相关 tests 的 suite name
TestName：当前具体 behavior/scenario name
```

返回值：没有供你接收的 runtime return value；宏定义并注册一个 test function。

命名建议：

```cpp
TEST(ThreadPoolTest, RejectsSubmissionAfterShutdown)
TEST(ThreadPoolTest, DrainsAcceptedTasksDuringShutdown)
TEST(ThreadPoolTest, PropagatesTaskExceptionThroughFuture)
```

避免：

```cpp
TEST(ThreadPoolTest, Test1)
TEST(ThreadPoolTest, Works)
TEST(ThreadPoolTest, Normal)
```

好名字应同时告诉你：

```text
什么对象
什么场景
expected behavior
```

---

## 10. `EXPECT_EQ`、`EXPECT_TRUE`、`EXPECT_FALSE`

### 10.1 `EXPECT_EQ`

使用形态：

```cpp
EXPECT_EQ(actual, expected);
```

作用：检查两边可用 `==` 比较且结果相等。

最小例子：

```cpp
const int result = 40 + 2;
EXPECT_EQ(result, 42);
```

它会分别计算参数一次。不要让 test correctness 依赖两个参数之间的 evaluation order。

对 `std::string`：

```cpp
std::string result = "thread-pool";
EXPECT_EQ(result, std::string("thread-pool"));
```

对两个 `const char*` 使用 `EXPECT_EQ` 比较的是 pointer value，不是 C string contents。今天 ThreadPool result 优先使用 `std::string`，不扩展 C string assertion。

### 10.2 `EXPECT_TRUE`

```cpp
EXPECT_TRUE(condition);
```

最小例子：

```cpp
EXPECT_TRUE(future.valid());
```

但要注意：`future.valid()` 只表示关联 shared state，不表示已经 ready。不要写出错误 oracle。

### 10.3 `EXPECT_FALSE`

```cpp
EXPECT_FALSE(condition);
```

最小例子：

```cpp
const bool duplicate_found = false;
EXPECT_FALSE(duplicate_found);
```

若存在更直接的 equality assertion，优先让诊断显示 actual value：

```cpp
EXPECT_EQ(hits[id], 1);
```

通常比：

```cpp
EXPECT_TRUE(hits[id] == 1);
```

更容易定位失败。

---

## 11. `EXPECT_*` 与 `ASSERT_*` 的区别

GoogleTest assertions 成对出现：

```text
EXPECT_*：non-fatal failure，记录失败后继续当前 test function
ASSERT_*：fatal failure，记录失败并立即结束当前 test function
```

“fatal” 在这里不是结束整个 process，也不是取消其他 tests。它主要是停止当前 test function。

### 11.1 什么时候用 `ASSERT_*`

若后续语句依赖前置条件，否则会 invalid access：

```cpp
ASSERT_FALSE(values.empty());
EXPECT_EQ(values.front(), 42);
```

如果 vector 为空还继续 `front()`，行为无效，所以前置条件失败后不应继续。

---

### 11.2 concurrency test 的 cleanup 风险

这里的 `gate` 就是测试人为设置的“闸门”，不是 C++ 特殊语法。

例如 worker 里的任务先报告“我已经启动”，然后故意卡在这里：

```cpp
gate.wait_until([] {
    return release == true;
});
```

含义是：`release` 还是 `false` 时，任务不继续执行；测试线程把它改成 `true` 后，任务才会通过闸门、结束。

这段测试本来想验证：所有 worker 都确实启动并被卡住了。

```text
测试线程提交 N 个任务
    ->
每个任务 started++
    ->
每个任务等待 release == true
    ->
测试线程断言 started == worker_count
```

危险发生在断言失败时：

```text
ASSERT_EQ(started, worker_count) 失败
    ->
ASSERT 是致命断言，当前测试函数立刻 return
    ->
后面的 release = true; 没有执行
    ->
局部 ThreadPool 开始析构
    ->
析构函数等待 worker 结束（join）
    ->
worker 仍在等待 release == true，但是让 release=true 的代码不会被执行！
    ->
没人再能打开闸门，测试卡死
```

所以这里的核心不是“断言错了”本身，而是：**任务能否结束，依赖于写在 `ASSERT` 后面的清理代码。** 一旦 `ASSERT` 提前返回，那段清理代码就消失了。

并发生命周期测试要先保证：即使中途任何断言失败，所有被测试代码里的等待者也一定能被放行。否则失败用例会把测试进程挂住，反而看不到真正的失败信息。

---

## 12. `EXPECT_THROW` / `ASSERT_THROW`

使用形态：

```cpp
EXPECT_THROW(statement, ExceptionType);
ASSERT_THROW(statement, ExceptionType);
```

它验证 `statement` 抛出指定 type 的 exception。

### 12.1 constructor boundary

```cpp
EXPECT_THROW(ThreadPool(0, 8), std::invalid_argument);
```

这里验证 zero worker contract。

### 12.2 post-shutdown submission

```cpp
ThreadPool pool(2, 8);
pool.shutdown();

EXPECT_THROW(
    pool.submit([] { return 42; }),
    std::runtime_error
);
```

这里的 exception 来自 submission stage。

### 12.3 future exception propagation

```cpp
auto result = pool.submit([]() -> int {
    throw std::runtime_error("expected failure");
});

EXPECT_THROW(result.get(), std::runtime_error);
```

这里的 exception 来自 execution stage，先被 packaged task 存进 shared state，再由 `future.get()` 重新抛出。

注意：`EXPECT_THROW` 检查的是 exception type，不自动检查 `what()` text。今天先验证 type 与 worker survival；复杂 exception matcher 不进入主线。

---

## 13. 为什么 assertions 尽量放在 test thread

不要在 pool worker task 内直接写：

```cpp
pool.submit([] {
    EXPECT_EQ(...);
});
```

今天推荐：

```text
worker task：计算 result 或更新受同步保护的 observable state
test thread：通过 future.get / join 等待 completion
test thread：执行 GoogleTest assertions
```

原因：

```text
test ownership 更清楚
assertion failure 不会和 worker lifecycle/cleanup 纠缠
跨线程 assertion 支持存在平台和用法边界
future 已经提供自然的 result/exception channel
```

例如：

```cpp
auto result = pool.submit([] {
    return 6 * 7;
});

EXPECT_EQ(result.get(), 42);
```

比让 worker 自己调用 `EXPECT_EQ` 更容易解释和维护。

---

## 14. 从 contract 写出 scenario 的固定方法

每条 test 先写四问：

```text
1. 要验证哪一句 public contract？
2. 怎样确定性建立目标 state？
3. 哪个 observable value/state 是 oracle？
4. 失败时 test binary 怎样得到 non-zero result？
```

再补 cleanup：

```text
5. assertion 失败后怎样避免 blocked worker / joinable thread？
```

不要先写一堆 threads，再回头猜它究竟验证了什么。

---

# Round 1：到这里停止阅读，先为自己的 ThreadPool 写第一版 tests

你现在已经知道 GoogleTest 的基本运行链、常用 assertions，以及怎样从 public contract 写出 scenario。先不要继续看第 15 节之后的确定性同步、exactly-once oracle 和 shutdown gate 设计。

Round1 使用这些 canonical files：

```text
include/blocking_queue.hpp      已有 component，不在今天重写
include/thread_pool.hpp         Day3 最终 component
tests/thread_pool_test.cpp      今天主要修改的 executable tests
week8/day4/day4_note.md         记录 test design 与证据缺口
```

`tests/thread_pool_test.cpp` 的程序用途不是再实现一个 pool，而是：

```text
创建真实 ThreadPool
-> 只通过 public API 建立 scenario
-> 在 test thread 观察 value / exception / lifecycle outcome
-> assertion 把错误变成 test failure
-> test binary 用 non-zero exit status 把 failure 交给外部工具
```

第一轮暂时不用先写完整 CMake。先直接得到一个能运行的 GoogleTest binary：

```bash
cd ~/code/system-learning/cpp/week8
mkdir -p build
g++ -std=c++17 -Wall -Wextra -g -pthread \
  -Iinclude tests/thread_pool_test.cpp \
  -lgtest_main -lgtest \
  -o build/thread_pool_test
./build/thread_pool_test
```

这里链接 `gtest_main`，因此 test source 不需要自己写 `main()`。若你的发行版没有预编译 library，先按第 7 节已经给出的 Ubuntu 环境步骤处理，不要靠复制未知来源的 `.a` 文件解决。

Round1 的输入和输出很明确：

```text
输入：每个 TEST 中写死的小型 controlled scenario
输出：GoogleTest pass/fail summary + process exit status
成功：所有 assertions 通过，binary exit 0
失败：任一 assertion/uncaught exception 使 binary non-zero，hang 不能算通过
```

只根据 Day3 最终 public contract，独立选择并实现第一批 tests。最低覆盖：

```text
constructor 参数边界
返回 int / void 的 task
task exception 通过 future 传播
shutdown 后 submission 被拒绝
多个 tasks 最终完成
```

每个 test 在动手前先写五行草稿：

```text
contract
Arrange
Act
Assert / oracle
Cleanup
```

这一轮不要求测试设计已经完美。你可以暂时使用自己想到的同步方法，但要在 `day4_note.md` 标出：

```text
哪一条 test 依赖 sleep 或 scheduling 运气？
哪一条只能证明总数，不能证明 exactly once？
哪一条失败时可能无法 cleanup？
```

先让 test binary 能编译、能出现真实 pass/fail，再阅读后半部分强化它。

**阅读闸门：第一版 test suite 尚未运行前，停在这里。**

---

# Round 2：用确定性、oracle 和 cleanup 审查第一版 tests

下面的内容不是让你照抄一套固定 tests，而是用来审查第一版证据哪里太弱、哪里可能自己挂住。

## 15. 完成关系优先使用 future，不使用 sleep

如果测试只需要知道某个 result task 是否完成：

```cpp
auto result = pool.submit([] {
    return 42;
});

EXPECT_EQ(result.get(), 42);
```

`get()` 建立：

```text
task 未完成 -> test thread waits
task value/exception ready -> test thread resumes
```

不需要：

```cpp
std::this_thread::sleep_for(std::chrono::milliseconds(100));
```

sleep 只表示 test thread 暂停了一段 wall-clock time，不表示 worker 一定运行到某一行。

---

## 16. exactly-once 不能只检查总和

错误例子：

```text
100 tasks，每个加 1
final counter == 100
```

如果一个 task 漏执行，另一个 task 重复执行，总数仍可能是 100。

更强设计：

```text
为每个 task 分配 unique ID：0..N-1
准备 N 个 hit counts，初始为 0
task i 在 mutex 保护下增加 hits[i]
保存每个 task 的 future
test thread get 所有 futures
最后逐项 EXPECT_EQ(hits[i], 1)
```

这能区分：

```text
hits[i] == 0：missing
hits[i] == 1：exactly once
hits[i] > 1：duplicate
```

不要使用 `std::vector<std::atomic<int>>` 只是为了显得高级。当前用一个 mutex 保护普通 vector，ownership 和 oracle 更容易解释。

---

## 17. 怎样确定性建立“shutdown 时仍有 pending tasks”

仅仅：

```text
submit 100 tasks
立刻 shutdown
```

不能证明 shutdown 开始时真的还有 pending tasks。快机器上 tasks 可能已经完成。

今天使用 gate 构造目标 state。

### 17.1 对象配置

```text
ThreadPool：1 worker，queue capacity = 1
Task A：worker 取到后等待 release gate
Task B：进入 queue，成为确定的 pending task
Task C：用来观察 close 后 submission rejection
```

### 17.2 完整流程

```mermaid
flowchart TD
    A[test submits Task A] --> B[only worker starts A]
    B --> C[A reports started then waits on gate]
    C --> D[test waits until A really started]
    D --> E[test submits Task B]
    E --> F[bounded queue now contains pending B]
    F --> G[test starts helper thread calling shutdown]
    G --> H[test attempts Task C submission]
    H --> I{has helper closed queue first?}
    I -- yes --> J[enqueue observes closed and submit throws]
    I -- no --> K[C waits because queue is full]
    G --> L[helper closes queue then waits for worker]
    L --> M[close wakes blocked push]
    K --> M
    M --> J
    J --> N[test releases A gate]
    N --> O[A finishes]
    O --> P[worker pops and executes accepted B]
    P --> Q[queue closed and empty so worker exits]
    Q --> R[shutdown joins worker and returns]
    R --> S[test joins shutdown helper]
    S --> T[assert A and B ran once C ran zero times]
```

上图中 test 启动 helper 后就调用 C，但不能假装 scheduler 一定让 helper 先完成 close。这里有两个合法 interleavings：

```text
close 先线性化
-> C 直接观察 closed 并被拒绝

C 先进入 enqueue，看到 open + full
-> C 在 not_full 上等待
-> helper close 必须 notify blocked push
-> C 醒来观察 closed 并被拒绝
```

因此 `EXPECT_THROW` 返回本身就是一个同步证据：此刻 C 已经观察到 closed，而 A 仍被 gate 挡住、B 仍 pending。然后 test 才 release A，才能严格证明“B 在 close 时 pending，随后被 drain”。

不要把 C 移到 `helper.join()` 之后：`shutdown()` 是 blocking operation，必须先 release A 才可能 join；如果 helper 在 release A 后才获得调度，B 可能在 close 前已经执行完，反而失去 pending-at-close 的证明。

这里：

```text
A waiting：确定 worker 被占用
B in queue：确定存在 accepted pending task
C rejected：证明 shutdown 已关闭 acceptance
A release 前 C 已返回：证明 close 已线性化且 B 仍 pending
A release：让 drain 能继续
B executed：证明 accepted pending task 没被丢弃
```

整个正确性不依赖固定 sleep。

### 17.3 gate 用什么实现

今天可以复用 Week7 的：

```text
mutex
condition_variable
bool started
bool release
```

Task A：

```text
lock gate mutex
started = true
notify test
wait until release == true
unlock and finish
```

test thread：

```text
wait until started == true
之后再提交 B
```

不要引入新的 `std::promise` 组合，避免与 Day3 的 future 主线混在一起。

---

## 18. multiple concurrent submitters 怎样建立 oracle

目标 contract：多个 caller threads 同时 submit 时，accepted tasks 不丢、不重复，results 不串。

推荐 identity：

```text
submitter 0 owns IDs [0, K)
submitter 1 owns IDs [K, 2K)
...
```

每个 submitted callable 返回自己的 unique ID。

每个 submitter thread：

```text
只写自己预先分配的 future container
不与其他 submitter push 同一个 vector
```

test thread：

```text
join all submitter threads
get all futures
验证每个 future 返回对应 ID
验证 ID set 没有 missing/duplicate/unexpected
```

这里至少有两层 synchronization：

```text
submitter thread join：保证 future containers 已写完
future.get：保证对应 worker task 已完成
```

不要让多个 submitter 无锁 `push_back` 同一个 `std::vector<std::future<int>>`，那会让 test code 自己产生 data race。

---

## 19. destructor lifecycle 怎样从 public behavior 验证

你不能从 test 直接访问 private `workers_` 来检查 `joinable()`，否则 test 与 implementation layout 耦合。

可以验证 public outcome：

```text
在 outer scope 声明 future
进入 inner scope 构造 pool
submit accepted task，将 future move 到 outer scope
不显式调用 shutdown
离开 inner scope，pool destructor 运行
scope 成功退出后调用 future.get
result 必须正确
```

若 destructor contract 正确：

```text
accepted task 已 drain
workers 已 join
destructor 才返回
```

这个 test 不能证明 private vector 的每一行实现，但它验证了 caller 真正依赖的 lifecycle behavior。

CTest timeout 可以让意外 hang 变成可见 failure，但 timeout 本身不是 lifecycle 正确性的证明。

---

## 20. task exception test 要证明两件事

只写：

```cpp
EXPECT_THROW(failing_future.get(), std::runtime_error);
```

证明了异常传播 type，但还没有证明 worker/pool 仍存活。

完整 scenario：

```text
submit failing task
submit later normal task
failing future.get -> runtime_error
later future.get -> expected normal value
```

这样同时验证：

```text
exception 与对应 future 关联
worker execution flow 没被 user exception 终止
pool 仍能处理后续 work
```

Day3 已说明 generic packaged task 的 user exception 通常被 shared state 保存，因此不要再要求旧的 `failed_task_count` 必然为每个 future exception 加一。

Day3 的 canonical contract 已决定删除 public `failed_task_count()`。因此迁移 Day2 tests 时必须同步删除 `failed_task_count == 0/1` assertions；Day4 用 `future.get()` 观察业务 exception，并用 later task result 证明 worker/pool 仍可继续工作。不要保留一个名称仍叫“failed task count”、实际却只统计 unexpected wrapper failure 的悬空 API。

### 20.1 empty `std::function` 是 API 演进回归场景

Day2 的 `submit(Task)` 可以在 submission stage 用 `!task` 立即拒绝 empty `std::function<void()>`。Day3 改成 generic submit 后，本教程选择的新 contract 是：

```text
empty std::function 被 queue accepted
-> worker 调用时抛 std::bad_function_call
-> packaged_task 将异常存入 shared state
-> future<void>.get() 重新抛出
-> later normal task 仍能完成
```

Day4 必须为这条显式变化保留 test，防止 API 重构后仍沿用 Day2 的 `invalid_argument` assertion，或完全漏掉该边界。

---

## 21. repeated shutdown 与 concurrent shutdown 不要混写

Week8 当前 contract 是：

```text
sequential repeated shutdown：支持且安全
multiple threads concurrently call shutdown：本阶段不承诺
shutdown called from worker task：本阶段不支持
```

所以 repeated test 应写：

```text
same owner thread calls shutdown
then calls shutdown again
both return normally
```

不要把它擅自升级成十个 threads 同时 shutdown，然后把失败归咎于 implementation 没满足从未声明的 contract。

---

## 22. ThreadPool contract 到 test name 的映射

建议最小矩阵：

| Contract | Suggested test name | Core oracle |
|---|---|---|
| zero worker rejected | `RejectsZeroWorkerCount` | `invalid_argument` |
| zero tasks can stop | `ShutsDownWithoutTasks` | returns without hang |
| one value result | `ReturnsSubmittedValue` | future result |
| void task completion | `CompletesVoidTask` | synchronized side effect |
| many tasks exactly once | `ExecutesEachAcceptedTaskExactlyOnce` | each ID hit == 1 |
| task exception | `PropagatesTaskExceptionAndKeepsPoolAlive` | throw + later result |
| empty std::function | `PropagatesBadFunctionCallAndKeepsPoolAlive` | future throws + later result |
| shutdown drains | `DrainsAcceptedPendingTaskDuringShutdown` | deterministic gate |
| repeated shutdown | `AllowsSequentialRepeatedShutdown` | both calls return |
| post-shutdown submit | `RejectsSubmissionAfterShutdown` | runtime_error |
| concurrent submitters | `AcceptsTasksFromMultipleSubmitters` | all IDs/results exact |
| destructor lifecycle | `DestructorDrainsAndJoinsWorkers` | scope exits + future result |

表格只是 test design map，不是完整 test source。每个 scenario 仍需要你自己写 Arrange / Act / Assert / Cleanup。

---

## 23. 从零开始：CMake 是干什么的

### 23.1 先亲手跑一个最小 CMake project

先不背术语。这个实验只完成一件事：让 CMake 帮你把 `hello.cpp` 变成 executable。

在 Ubuntu 中创建一个不污染 repository 的临时目录：

```bash
mkdir -p /tmp/cmake_hello_demo
cd /tmp/cmake_hello_demo
```

目录中只放两个文件：

```text
/tmp/cmake_hello_demo/
├── CMakeLists.txt
└── hello.cpp
```

`hello.cpp`：

```cpp
#include <iostream>

int main() {
    std::cout << "hello from CMake\n";
    return 0;
}
```

`CMakeLists.txt`：

```cmake
cmake_minimum_required(VERSION 3.16)

project(hello_cmake LANGUAGES CXX)

add_executable(hello hello.cpp)

target_compile_features(hello PRIVATE cxx_std_17)
target_compile_options(hello PRIVATE -Wall -Wextra -g)
```

先不用理解每行语法。现在只按这个粗略映射读：

```text
project(...)
    这是一个 C++ project

add_executable(hello hello.cpp)
    用 hello.cpp 生成一个叫 hello 的 executable target

target_compile_features(... cxx_std_17)
    hello 需要 C++17 language feature level

target_compile_options(...)
    编译 hello 时使用 -Wall -Wextra -g
```

运行三步：

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build -j
./build/hello
echo $?
```

下面是 2026-08-24 在你的 Ubuntu 上对这两个文件的真实运行结果：

```text
-- The CXX compiler identification is GNU 10.5.0
-- Check for working CXX compiler: /usr/bin/c++ -- works
-- Detecting CXX compile features - done
-- Configuring done
-- Generating done
-- Build files have been written to: /tmp/.../hello/build

[ 50%] Building CXX object CMakeFiles/hello.dir/hello.cpp.o
[100%] Linking CXX executable hello
[100%] Built target hello

hello from CMake
program_exit=0
```

路径中间部分可能与你手动实验时不同，百分比也不值得背。只看发生了什么：

```text
CMake 找到 /usr/bin/c++
-> 读取 CMakeLists.txt
-> 在 build/ 生成底层 build files
-> build 阶段把 hello.cpp 编译成 hello.cpp.o
-> link 阶段生成 hello executable
-> shell 运行 ./build/hello
```

因此，CMake 最直观的作用就是：

> 你在 `CMakeLists.txt` 中描述 target 与构建要求；CMake 替底层 build tool 生成规则，不再要求你每次手写完整 `g++` command。

先暂时忘掉 CMake，回到你刚才实际使用的命令：

```bash
g++ -std=c++17 -Wall -Wextra -g -pthread \
  -Iinclude tests/thread_pool_test.cpp \
  -lgtest_main -lgtest \
  -o build/thread_pool_test
```

这条命令把一整套 **build knowledge** 写在 shell 中：

```text
使用哪个 C++ standard
哪些 .cpp 是 source files
去哪里找 headers
打开哪些 warnings
链接哪些 libraries
最后生成哪个 executable
```

`build` 在这里不是简单的“编译”二字，而是把 source code 变成最终 artifact 的完整过程：

```text
.cpp source file
    |
    | preprocess + compile
    v
.o object file
    |
    | link with other .o files and libraries
    v
executable binary
```

术语：

```text
source file：源文件，例如 thread_pool_test.cpp
object file：目标文件，例如 thread_pool_test.o；已有 machine code，但通常还不是完整程序
link：链接，把 object files 与 libraries 组合起来并解析符号引用
executable：可执行文件，例如 build/thread_pool_test
artifact：构建产物的泛称，可以是 executable、library 等
```

当前只有一个 `.cpp` 时，手写一条 `g++` command 很自然。但项目扩大后，命令会开始承担很多重复工作：

```text
哪个 .cpp 依赖哪个 header？
只修改一个文件时，哪些 object files 需要重新编译？
test target 和 benchmark target 分别链接什么？
Linux 用 Makefiles，另一台机器用 Ninja 或 Visual Studio 时怎么办？
GoogleTest 和 Threads 去哪里找？
```

这正是 build system 要管理的问题。

### 23.2 这行 `g++` 命令是什么意思

这条命令是“一次完成预处理、编译、链接”，最后生成一个可运行的 GoogleTest 测试程序：

```bash
g++ -std=c++17 -Wall -Wextra -g -pthread \
  -Iinclude tests/thread_pool_test.cpp \
  -lgtest_main -lgtest \
  -o build/thread_pool_test
```

```text
g++
```

调用 GNU C++ 编译器驱动。因为这次没有加 `-c`，它不仅会编译 `.cpp`，还会在最后执行链接。

```text
-std=c++17
```

按 C++17 规则编译。比如 `std::optional`、`if constexpr` 等 C++17 特性才可用。

```text
-Wall -Wextra
```

开启常见警告和额外警告。它们不阻止编译，但会提醒可疑代码。

```text
-g
```

在二进制里保留调试信息，方便 `gdb` 看到源文件、行号、局部变量。不会改变程序逻辑。

```text
-pthread
```

启用 POSIX 线程支持。它不只是“链接 pthread 库”，还会让编译阶段使用正确的线程相关配置；用 `std::thread`、`mutex`、`condition_variable` 时应该加它。

```text
-Iinclude
```

添加头文件搜索目录。

因此代码里：

```cpp
#include "thread_pool.hpp"
```

编译器会去当前目录以及 `include/` 下寻找，例如：

```text
include/thread_pool.hpp
```

```text
tests/thread_pool_test.cpp
```

本次要编译的测试源文件。它经过预处理和编译后，会产生一个临时的目标文件，概念上像：

```text
tests/thread_pool_test.o
```

```text
-lgtest_main
```

链接 `libgtest_main` 库。它提供 GoogleTest 的默认 `main()`：

```cpp
int main(int argc, char** argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
```

所以你的测试源文件不需要自己写 `main`。

```text
-lgtest
```

链接 GoogleTest 框架本体：测试 registry、`EXPECT_EQ`、`ASSERT_EQ`、测试运行与报告等实现都在这里。

`-l名字` 的意思是让链接器寻找类似下面的库文件：

```text
lib名字.so
lib名字.a
```

所以：

```text
-lgtest_main -> libgtest_main.so / libgtest_main.a
-lgtest      -> libgtest.so / libgtest.a
```

```text
-o build/thread_pool_test
```

指定最终生成的可执行文件路径与名称：

```text
build/thread_pool_test
```

之后直接运行：

```bash
./build/thread_pool_test
```

最后，命令末尾每行的 `\` 是 Bash 的“续行符”，表示这条命令还没结束，下一行继续。它必须是该行最后一个字符，后面不能有空格。实际输入时用单个反斜杠：

```bash
-pthread \
```

不是两个 `\\`；你看到的双反斜杠多半只是 Markdown 转义后的显示效果。

---

### 23.2.1 新增：-l 负责 link 阶段

对，完全是 linker 阶段的事。

```text
tests/thread_pool_test.cpp
    |
    | compile
    v
tests/thread_pool_test.o
    |
    | link
    +--> -lgtest_main
    +--> -lgtest
    v
thread_pool_test 可执行文件
```

`-lgtest_main` 的意思是链接名为 `gtest_main` 的库。Linux 上 linker 会去库搜索路径中找类似：

```text
libgtest_main.so
或
libgtest_main.a
```

它主要提供默认的 `main()`：

```cpp
int main(int argc, char** argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
```

而 `-lgtest` 链接的是 GoogleTest 的核心实现库，例如：

```text
TEST 注册机制
::testing::Test
EXPECT_EQ / EXPECT_THROW 等 assertion 的实现
InitGoogleTest()
RUN_ALL_TESTS()
测试执行、失败信息汇总
```

所以关系是：

```text
thread_pool_test.o
    里面有你的 TEST(...) 展开后的测试代码
    也引用了 GoogleTest 的功能
    但没有 main()

libgtest_main
    提供 main()
    main() 又会调用 GoogleTest 核心功能

libgtest
    提供真正的 GoogleTest framework 实现
```

`g++` 在这条命令里既是编译器 driver，也是 linker driver：它会在 link 阶段替你调用真正的 linker。通常你不直接手写 `ld`。

顺序也有意义，尤其链接静态库时：

```bash
g++ tests/thread_pool_test.o -lgtest_main -lgtest -o thread_pool_test
```

前面的对象或库提出“我需要某个符号”，后面的库负责提供它。这里 `gtest_main` 的 `main()` 又需要 `gtest` 的核心实现，所以 `-lgtest_main -lgtest` 这个顺序是合理的。

---

### 23.3 build system 与 CMake 的关系

`build system`：构建系统。

它保存并执行这些规则：

```text
source files -> targets 的关系
target 之间的 dependencies
compiler/linker options
哪些文件变化后需要重新 build
```

GNU Make + Makefile、Ninja、Visual Studio project 都可以充当真正执行 build rules 的系统。

`CMake` 是 **cross-platform build-system generator**：跨平台构建系统生成器。

`generator` 原意是“生成器”。它在这里表示 CMake 可以根据同一份 `CMakeLists.txt`，为不同底层工具生成 build files：

```text
                         +--> Unix Makefiles --> make
CMakeLists.txt --> CMake +--> Ninja files -----> ninja
                         +--> VS project -------> Visual Studio build
```

因此必须分清：

```text
CMake 不是 C++ compiler
CMake 不代替 g++ 生成 machine code
CMake 也不等于 make

CMake 读取项目描述
-> 生成底层 build system 所需的文件
-> 底层 build tool 再调用 compiler 和 linker
```

在你的 Ubuntu 默认环境中，常见链路是：

```text
CMakeLists.txt
-> cmake 生成 Unix Makefiles
-> cmake --build 调用 make
-> make 根据规则调用 g++
-> g++ 编译、链接
-> thread_pool_test
```

`cmake --build` 的价值在于：你不必关心当前 generator 背后究竟是 `make` 还是 `ninja`，CMake 会调用对应的 native build tool。

---

### 23.3.1 必看：把 CMake,Makefile,make 串起来

对，你这条链基本理解对了。只需要补一个小边界：

```text
Makefile
    = 保存构建规则的文件

GNU Make / make
    = 读取并执行 Makefile 规则的程序

两者合起来
    = 一个基于 Make 的 build system
```

在你当前 Ubuntu 的 CMake 流程里，大概是：

```text
CMakeLists.txt
    |
    | cmake configure/generate
    v
Makefile + CMakeFiles/ 中的辅助规则
    |
    | cmake --build build
    v
make
    |
    | 检查哪些 target 依赖哪些 source/header
    | 判断哪些文件更新过、哪些需要重编译
    v
g++ 编译 .cpp -> .o
    |
    v
g++ 作为 linker driver 链接 .o + gtest libraries
    |
    v
thread_pool_test
```

所以你说的：

> Makefile 保存 `source files -> target`、依赖、编译选项等规则；`make` 根据它调用 `g++`

是正确的。

再精确一点，`Makefile` 主要写的是“某个 target 依赖什么、该怎么生成”；`make` 会根据文件时间戳判断是否需要执行规则。例如只改了 `tests/thread_pool_test.cpp`，它通常只会重新编译这个 `.cpp`，然后重新链接，不会无缘无故重新编译所有文件。

而 CMake 的位置是更上一层：它替你生成适合当前平台的 Makefile。换到 Ninja，仍是同一份 `CMakeLists.txt`，只是生成的底层规则文件变成 `build.ninja`，然后由 `ninja` 去调用 `g++`。

---

### 23.4 `CMakeLists.txt` 是什么

`CMakeLists.txt` 是 CMake project 的描述文件。

它不是 C++ source，也不是最终 Makefile。它表达的是较高层的关系：

```text
我要一个叫 add_test 的 executable target
它由 add_test.cpp 构成
它使用 C++17
它要链接 GoogleTest
它应该被 CTest 发现
```

CMake 再把这些关系翻译成当前机器能执行的 build rules。

### 23.5 source tree 与 build tree

`tree` 在这里指 directory tree，即“目录树”。

今天的 project root 可以先想成：

```text
week8/
├── CMakeLists.txt
├── include/
│   ├── blocking_queue.hpp
│   └── thread_pool.hpp
├── tests/
│   └── thread_pool_test.cpp
└── build/                    configure 后产生
    ├── CMakeCache.txt
    ├── Makefile
    ├── CMakeFiles/
    └── thread_pool_test      build 后产生
```

两个术语：

```text
source tree：源码目录树；包含 CMakeLists.txt、.cpp、.hpp
build tree：构建目录树；包含 CMake cache、generated build files、object files、executables
```

把 `build/` 单独放在 source tree 下面但不与源码混杂，称为 **out-of-source build**：源码目录外构建。

这里的 “out of source” 不是说 `build/` 必须跑到整个 repository 外面，而是说 generated files 不直接散落在源码文件之间。这样需要清理构建产物时，只处理 `build/`，源码仍然清楚。

### 23.6 四个阶段各是谁在工作

今天完整链路是：

```text
configure
-> generate
-> build
-> test
```

#### 1. configure：配置

CMake 读取 `CMakeLists.txt`，识别当前环境：

```text
找到哪个 C++ compiler
compiler 支持什么能力
GoogleTest / Threads 等 dependencies 能否找到
用户传入了哪些 configuration values
```

`dependency`：依赖项。当前项目需要、但不是当前 `.cpp` 自己实现的组件，例如 GoogleTest 和 pthread support。

CMake 还会在 build tree 中写入 `CMakeCache.txt`。`cache` 原意是缓存；这里保存本次 build tree 的 compiler path、package path、build type 等配置，后续重新运行 CMake 时可以复用。

#### 2. generate：生成

CMake 根据 configure 得到的信息，为当前 generator 生成 build files。例如 Unix Makefiles generator 会生成 `Makefile`。

命令：

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug
```

这一次 `cmake` invocation 通常连续完成 configure 和 generate，所以 terminal 中会看到类似：

```text
Configuring done
Generating done
```

参数逐个读：

```text
-S .
    S = source；source tree 是当前目录 .

-B build
    B = build；build tree 使用当前目录下的 build/
    build/ 不存在时，CMake 会创建它

-DNAME=value
    D = define；为 CMake cache variable 提供值

-DCMAKE_BUILD_TYPE=Debug
    把 CMAKE_BUILD_TYPE 设为 Debug
    当前 Unix Makefiles 是 single-configuration generator，因此在 configure 时选择 build type
```

`configuration` 在这里表示一组构建配置，例如：

```text
Debug：便于调试，通常保留 debug information
Release：偏向优化后的发布构建
```

这一步生成 build rules，通常还没有生成最终 executable。

#### 3. build：构建

```bash
cmake --build build -j
```

逐个读：

```text
--build build：构建已经生成在 build/ 中的 build system
-j：parallel jobs；允许底层 build tool 并行执行多个可并行的编译任务
```

此时才会真正调用底层 build tool、compiler 和 linker，最终产生 `build/thread_pool_test`。

#### 4. test：测试

从 project root 使用：

```bash
cmake -E chdir build ctest --output-on-failure
```

逐个读：

```text
cmake -E
    E = command mode；使用 CMake 提供的跨平台小工具命令

chdir build
    change directory；只让后面的 command 在 build/ 中运行

ctest
    CMake 配套的 test runner；运行注册到当前 build tree 的 tests

--output-on-failure
    test 通过时保持摘要简洁，失败时显示其 output
```

这个 command 结束后，你当前 interactive shell 的 working directory 没有永久改变。

也可以直接运行 test binary：

```bash
./build/thread_pool_test
```

二者责任不同：

```text
direct binary
    直接运行 GoogleTest program
    适合看 GoogleTest 原生 test list、filter 和详细 output

CTest
    统一运行 CMake project 中 registered tests
    负责汇总、timeout 与 external test exit status
```

把本节压缩成一句话：

> `CMakeLists.txt` 描述要构建什么，CMake 生成怎样构建的规则，底层 build tool 调用 `g++` 真正编译链接，CTest 再运行已注册的测试。

---

## 24. 从零读一份最小 `CMakeLists.txt`

在看完整文件前，先认识 CMake 中最常见的五个对象。

### 24.1 command：命令

CMake 官方通常把下面这种写法称为 `command`：

```cmake
add_executable(add_test add_test.cpp)
```

也有资料口语上称为 directive，意思都是“给 CMake 的指令”。今天统一按官方术语叫 command。

基本语法是：

```text
command_name(argument1 argument2 ...)
```

它不是 C++ function call，也不使用分号结尾。

### 24.2 variable：变量

```cmake
set(CMAKE_CXX_STANDARD 17)
```

`variable` 就是变量。这里把 CMake variable `CMAKE_CXX_STANDARD` 设置为 `17`。

`CMAKE_` 开头通常表示 CMake 自己定义或约定的变量；不要把它理解为 C++ global variable，它只在 CMake 配置项目时起作用。

### 24.3 target：构建目标

`target` 原意是目标。在 build system 中，它是一个带名字的构建节点，例如：

```text
executable target：最终生成可执行文件
library target：最终生成库，或表达一个库组件
```

```cmake
add_executable(add_test add_test.cpp)
```

这行创建名为 `add_test` 的 executable target。后续可以继续把 compile options、include directories 和 linked libraries 附着到这个 target 上。

注意区分：

```text
add_test：CMake 中的 target name
build/add_test：最终可能生成的 executable path
add_test.cpp：构成 target 的 source file
```

### 24.4 dependency：依赖关系

如果 `add_test` 使用 GoogleTest，就存在：

```text
add_test target -> depends on GoogleTest libraries
```

build system 根据 dependency 决定构建顺序，并把正确的 include/link information 交给 compiler 和 linker。

### 24.5 property 与 usage requirement

`property`：属性。例如一个 target 使用哪个 C++ standard、有哪些 compile options。

`usage requirement`：使用要求。它描述“别的 target 使用我时，还必须继承什么”。这会影响后面的 `PRIVATE / PUBLIC / INTERFACE`。

今天只需要先记住：

```text
PRIVATE
    只用于当前 target 自己
    不向依赖当前 target 的其他 target 传播
```

现在看完整最小例子。它构建独立的 `add_test.cpp` demo，不是 ThreadPool 最终答案：

```cmake
cmake_minimum_required(VERSION 3.16)

project(gtest_minimal LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

enable_testing()
find_package(GTest REQUIRED)

add_executable(add_test add_test.cpp)

target_compile_options(add_test PRIVATE
    -Wall
    -Wextra
    -g
)

# CMake 3.16 的 FindGTest imported target names。
target_link_libraries(add_test PRIVATE
    GTest::GTest
    GTest::Main
)

include(GoogleTest)
gtest_discover_tests(add_test
    PROPERTIES TIMEOUT 10
)
```

### 24.6 把 GoogleTest demo 真正交给 CMake 和 CTest

前面的 `CMakeLists.txt` 单独看仍然很抽象。现在把它与第 8 节的 C++ test source 放进同一个临时 project，完整运行一次。

目录：

```text
/tmp/cmake_gtest_demo/
├── CMakeLists.txt
└── add_test.cpp
```

`add_test.cpp`：

```cpp
#include <gtest/gtest.h>

int add(int left, int right) {
    return left + right;
}

TEST(AddTest, ReturnsSumOfTwoPositiveValues) {
    EXPECT_EQ(add(20, 22), 42);
}

TEST(AddTest, ResultCanBeComparedAsBooleanCondition) {
    EXPECT_TRUE(add(1, 1) == 2);
    EXPECT_FALSE(add(1, 1) == 3);
}
```

`CMakeLists.txt` 就使用上面的最小版本。然后运行：

```bash
cd /tmp/cmake_gtest_demo

cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build -j
```

2026-08-24 在你的 Ubuntu 上真实得到的 configure/build 关键输出是：

```text
-- The CXX compiler identification is GNU 10.5.0
-- Found GTest: /usr/lib/x86_64-linux-gnu/libgtest.a
-- Configuring done
-- Generating done
-- Build files have been written to: /tmp/.../gtest/build

[ 50%] Building CXX object CMakeFiles/add_test.dir/add_test.cpp.o
[100%] Linking CXX executable add_test
[100%] Built target add_test
```

这一步证明：

```text
find_package 找到了 Ubuntu 已安装的 GoogleTest
add_test.cpp 被编译成 object file
object file 与 GoogleTest libraries 被链接成 build/add_test
```

#### 运行方式 A：直接运行 GoogleTest binary

```bash
./build/add_test
echo $?
```

真实输出：

```text
Running main() from .../gtest_main.cc
[==========] Running 2 tests from 1 test suite.
[----------] 2 tests from AddTest
[ RUN      ] AddTest.ReturnsSumOfTwoPositiveValues
[       OK ] AddTest.ReturnsSumOfTwoPositiveValues (0 ms)
[ RUN      ] AddTest.ResultCanBeComparedAsBooleanCondition
[       OK ] AddTest.ResultCanBeComparedAsBooleanCondition (0 ms)
[----------] 2 tests from AddTest (0 ms total)
[==========] 2 tests from 1 test suite ran. (0 ms total)
[  PASSED  ] 2 tests.
direct_exit=0
```

这里真正认识 `TEST`、执行 `EXPECT_EQ`、打印 actual/expected 的是 **GoogleTest framework**。

执行主体是一个普通 process：

```text
shell
-> 启动 build/add_test executable
-> gtest_main::main()
-> RUN_ALL_TESTS()
-> 运行两个 TEST bodies
-> GoogleTest 根据 assertions 决定 binary exit status
```

#### 运行方式 B：让 CTest 调用 tests

```bash
cmake -E chdir build ctest --output-on-failure
echo $?
```

真实输出：

```text
Test project /tmp/.../gtest/build
    Start 1: AddTest.ReturnsSumOfTwoPositiveValues
1/2 Test #1: AddTest.ReturnsSumOfTwoPositiveValues ...........   Passed
    Start 2: AddTest.ResultCanBeComparedAsBooleanCondition
2/2 Test #2: AddTest.ResultCanBeComparedAsBooleanCondition ...   Passed

100% tests passed, 0 tests failed out of 2

Total Test time (real) = 0.00 sec
ctest_exit=0
```

注意这次默认没有重复显示所有 GoogleTest `[ RUN ] / [ OK ]` 细节。CTest 只显示它从外面观察到的执行与汇总结果。

### 24.7 GoogleTest、test binary、CTest 到底差在哪

先看结论表：

| 对象 | 它是什么 | 当前负责什么 | 它不知道什么 |
|---|---|---|---|
| GoogleTest | 链接进 C++ test binary 的 testing framework | 提供 `TEST`、`EXPECT_*`，执行 assertions，产生诊断和 exit status | 不负责配置整个 project，也不替你构建所有 targets |
| `build/add_test` | 真正可执行的 test program/process | 包含你的 test code、GoogleTest framework 和 `gtest_main` | 不负责统一寻找其他 test executables |
| CTest | CMake 配套的 external test runner | 启动 registered test commands，观察 exit/timeout，汇总多个 tests | 不理解 `EXPECT_EQ` 的 C++ 语义，不判断 `42` 为什么正确 |

完整调用链：

```text
CTest
    |
    | 根据 CMake 注册的信息启动 command
    v
build/add_test --gtest_filter=某个测试名
    |
    | 进程内部由 GoogleTest 工作
    v
TEST body -> EXPECT_EQ / EXPECT_TRUE
    |
    v
GoogleTest 打印 assertion diagnosis 并设置 process exit status
    |
    v
CTest 从进程外看到 Passed / Failed / Timeout，再做总汇
```

为什么 CTest 能看到两个 GoogleTest cases，而不只是一个 `add_test` executable？桥梁就是：

```cmake
include(GoogleTest)
gtest_discover_tests(add_test PROPERTIES TIMEOUT 10)
```

`gtest_discover_tests` 使用 GoogleTest binary 的 test-listing 能力取得 test names，再把每个名字注册成 CTest 能分别调用的 test。

所以准确分工是：

```text
GoogleTest 决定一个 C++ behavior 是否符合 assertion
CTest 负责从外面调度、限时并汇总这些 test executions
```

### 24.8 故意失败一次，观察两层怎样配合

把第一个 test 临时改成错误答案：

```cpp
EXPECT_EQ(add(20, 22), 43);
```

重新 build 并运行 CTest：

```bash
cmake --build build -j
cmake -E chdir build ctest --output-on-failure
echo $?
```

在你的 Ubuntu 上实测，关键输出是：

```text
Start 1: AddTest.ReturnsSumOfTwoPositiveValues
1/2 Test #1: AddTest.ReturnsSumOfTwoPositiveValues ... ***Failed

add_test.cpp:8: Failure
Expected equality of these values:
  add(20, 22)
    Which is: 42
  43
[  FAILED  ] AddTest.ReturnsSumOfTwoPositiveValues

Start 2: AddTest.ResultCanBeComparedAsBooleanCondition
2/2 Test #2: AddTest.ResultCanBeComparedAsBooleanCondition ... Passed

50% tests passed, 1 tests failed out of 2
The following tests FAILED:
    1 - AddTest.ReturnsSumOfTwoPositiveValues (Failed)
failure_ctest_exit=8
```

这里可以清楚分层：

```text
GoogleTest
    知道 add(20, 22) actual 是 42、expected 是 43
    打印具体 assertion failure
    让 test process 返回 non-zero

CTest
    不会自己计算 20 + 22
    只发现这个 registered test command 失败
    因为使用 --output-on-failure，所以把 GoogleTest 的 failure output 展示出来
    汇总为 1/2 failed，并且自己也返回 non-zero
```

`failure_ctest_exit=8` 是这次 CTest 实测的 non-zero value。今天不要背数字 `8`；contract 只是：

```text
全部 tests 通过 -> CTest exit 0
至少一个 failure/timeout -> CTest exit non-zero
```

完成错误实验后，把 expected 恢复成 `42`，重新 build/test，确保回到全绿状态。

下面按照 CMake 实际读取顺序拆开。

### 24.9 `cmake_minimum_required`

```cmake
cmake_minimum_required(VERSION 3.16)
```

逐词理解：

```text
minimum：最低
required：要求
VERSION 3.16：最低支持 CMake 3.16
```

它声明最低 CMake version，并选择对应的 policy behavior。`policy` 是 CMake 对历史行为兼容规则的称呼。

这里的 `3.16` 是 **CMake version**，不是 C++17，也不是 GCC version；它与你 Ubuntu 上的 CMake 3.16.3 对齐。

### 24.10 `project`

```cmake
project(gtest_minimal LANGUAGES CXX)
```

```text
gtest_minimal：project name
LANGUAGES：本 project 启用哪些 programming languages
CXX：C++；CMake 用 CXX 表示 C++ compiler/toolchain
```

执行到这里时，CMake 会为 C++ language 检测 compiler 等环境信息。

### 24.11 C++ standard variables

```cmake
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
```

当前含义：

```text
CMAKE_CXX_STANDARD 17
    要求 target 使用 C++17 language level

CMAKE_CXX_STANDARD_REQUIRED ON
    REQUIRED = 必须满足；不能找不到 C++17 后静默降级

CMAKE_CXX_EXTENSIONS OFF
    EXTENSIONS = 编译器扩展
    OFF 表示不要依赖 GNU-only language extensions，倾向使用 -std=c++17 而不是 -std=gnu++17
```

`ON / OFF` 是 CMake 常用 boolean values，即布尔开关。

### 24.12 `enable_testing`

```cmake
enable_testing()
```

作用：为当前 project/build tree 启用 CTest support，使后续注册的 tests 能被 `ctest` 发现。

它不会自动扫描你的 C++ `TEST(...)`，也不会自动运行 test binary。它只是打开 CMake/CTest 这条能力链。

### 24.13 `find_package`

```cmake
find_package(GTest REQUIRED)
```

逐词理解：

```text
find：查找
package：一个可被项目复用的外部软件包或依赖
GTest：要查找 GoogleTest
REQUIRED：找不到就让 configure 失败
```

为什么要在 configure 阶段失败？

```text
找不到 GoogleTest
-> 现在就给出 dependency error
-> 不要等到 compilation/linking 才出现更绕的 header 或 undefined-reference error
```

成功后，CMake 3.16 的 `FindGTest` module 会提供后面使用的 imported targets。

### 24.14 `add_executable`

```cmake
add_executable(add_test add_test.cpp)
```

含义：创建 executable target `add_test`，其 source list 目前只有 `add_test.cpp`。

这行在 configure 阶段只是建立 build graph 中的 target/source relationship，不是立刻执行：

```bash
g++ add_test.cpp -o add_test
```

真正的 compilation 发生在后面的 `cmake --build build`。

### 24.15 `target_compile_options`

```cmake
target_compile_options(add_test PRIVATE
    -Wall
    -Wextra
    -g
)
```

```text
target：把设置附着到某个 target
compile options：传给 compiler 的编译选项
add_test：被设置的 target
PRIVATE：这些 options 只属于 add_test 自己
```

CMake 生成 build rules 时，会把这些 options 放进编译 `add_test.cpp` 的 compiler command。

### 24.16 `target_link_libraries` 与 imported target

```cmake
target_link_libraries(add_test PRIVATE
    GTest::GTest
    GTest::Main
)
```

`target_link_libraries`：声明当前 target 链接或依赖哪些 library targets。

当前 CMake 3.16 `FindGTest` 提供：

```text
GTest::GTest
    GoogleTest framework library

GTest::Main
    GoogleTest 提供的 main() library
```

`GTest::GTest` 这种名字称为 **imported target**：导入目标。

```text
imported
    表示它不是当前 project 用 source files 现场构建的 target
    而是 CMake 找到的外部 dependency 所对应的 target
```

名字中的 `::` 常用来表示 namespace-like ownership：它提醒你这是 GTest package 提供的 target，而不是当前项目随手创建的普通 target。

imported target 的价值是：它不只是一个 library filename，还可以携带 include directories、library location 和其他 usage requirements。你因此不必在 `CMakeLists.txt` 中手写 `/usr/lib/.../libgtest.a` 之类的机器相关路径。

较新 CMake 资料常出现 `GTest::gtest` / `GTest::gtest_main`。这些新 names 在 CMake 3.20 才加入；你的 CMake 3.16 环境使用 `GTest::GTest` / `GTest::Main`，不要混写版本。

### 24.17 `include(GoogleTest)` 不是 C++ `#include`

```cmake
include(GoogleTest)
```

作用：让当前 `CMakeLists.txt` 加载 CMake 自带的 `GoogleTest` module，于是后面可以调用该 module 定义的 `gtest_discover_tests` command。

它和：

```cpp
#include <gtest/gtest.h>
```

不是同一阶段：

```text
CMake include(GoogleTest)
    configure 阶段加载 CMake module

C++ #include <gtest/gtest.h>
    preprocess 阶段把 C++ declarations/macros 引入 translation unit
```

### 24.18 `gtest_discover_tests`

```cmake
gtest_discover_tests(add_test
    PROPERTIES TIMEOUT 10
)
```

`discover`：发现。这个 command 会利用 build 后的 GoogleTest binary 列出其中注册的 tests，并分别注册给 CTest。

```text
add_test：要检查的 GoogleTest executable target
PROPERTIES：为 discovered CTest tests 设置属性
TIMEOUT 10：每项 test 最多运行 10 seconds
```

如果某个并发 test hang：

```text
test 没有自行结束
-> 10 seconds 到达
-> CTest 把它判为 timeout failure
-> 整次 test run 不会永久卡住
```

### 24.19 把 CMake commands 翻译回你熟悉的 `g++`

这些 CMake commands 最终共同提供原先手写给 `g++` 的信息：

```text
add_executable
    -> 哪些 source files 要编译，生成哪个 executable target

target_compile_options
    -> -Wall -Wextra -g

set(CMAKE_CXX_STANDARD 17)
    -> C++17 standard requirement

target_link_libraries
    -> 需要链接 GoogleTest framework 与 gtest_main
```

CMake 不保证最终 command text 与你手写的命令逐字符相同，但它表达的是同一类 build requirements。

### 24.20 出错时先判断在哪个阶段

```text
configure error
    常见原因：CMakeLists command/argument 错误、compiler/package 找不到

generate error
    常见原因：target relationship 无法生成，例如引用不存在的 target

build compile error
    某个 .cpp 无法编译，例如 syntax/type/header 问题

build link error
    object files 无法组成程序，例如 undefined reference 或 duplicate symbol

test failure
    executable 已经构建成功，但 assertion failure、uncaught exception、non-zero exit 或 timeout
```

先定位阶段，再读对应 error message，比把所有问题都叫“CMake 报错”更有用。

---

## 25. ThreadPool CMakeLists 需要你完成什么

今天实际 project 的 target 应该：

```text
minimum CMake 3.16
project language CXX
C++17 required
enable_testing
find GTest REQUIRED
find Threads REQUIRED
build tests/thread_pool_test.cpp as thread_pool_test
add include/ to private include path
enable -Wall -Wextra -g
link GTest::GTest, GTest::Main, Threads::Threads
discover tests
set timeout
```

你需要自己把这些 requirements 写进 project root `CMakeLists.txt`。不要直接复制成多个：

```text
CMakeLists_day4.txt
CMakeLists_final.txt
CMakeLists_new.txt
```

### 25.1 `find_package(Threads REQUIRED)`

CMake 不直接把 Linux pthread flags 写死在跨平台 target relationship 中，而是提供：

```cmake
find_package(Threads REQUIRED)
```

然后链接：

```cmake
Threads::Threads
```

在当前 Linux/g++ 环境中，它会表达 thread library 的 compile/link requirements。

### 25.2 include directory

若 test 中写：

```cpp
#include "thread_pool.hpp"
```

target 需要知道在 project `include/` 中查找：

```cmake
target_include_directories(thread_pool_test PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)
```

这不是把 header 复制到 `tests/`。

---

## 26. 怎样只运行一个 test

先列出 binary 中注册的 tests：

```bash
./build/thread_pool_test --gtest_list_tests
```

只运行一个：

```bash
./build/thread_pool_test \
    --gtest_filter=ThreadPoolTest.DrainsAcceptedPendingTaskDuringShutdown
```

参数：

```text
--gtest_list_tests：只列 names，不真正执行 test bodies
--gtest_filter=...：只执行匹配的 tests
```

这对定位 lifecycle hang 很有用。先让最小 failing scenario 稳定复现，再运行整套 suite。

---

## 27. stress repeat 怎样做

### 27.1 单 process repeat

GoogleTest 提供：

```bash
./build/thread_pool_test --gtest_repeat=50
```

它在同一个 process 中重复 test run。

### 27.2 fresh process repeat

```bash
for i in $(seq 1 50); do
    ./build/thread_pool_test || exit 1
done
```

它每轮启动 fresh process。

今天推荐至少保留第二种证据，因为：

```text
每轮 address space / process lifecycle 重新建立
任意一轮 non-zero 立即停止
命令含义容易解释
```

repeat 不是把一个没有 assertions 的 demo 运行 50 次。每轮必须真实检查 contract。

---

## 28. TSan build 为什么必须单独目录

普通 Debug 和 TSan 的 compile/link flags 不同。不要在同一个 `build/` 中反复切换，避免 cache 与 objects 混杂。

建议：

```text
build/       -> normal Debug tests
build-tsan/  -> TSan instrumented tests
```

CMake 中可以增加一个简单 option：

```cmake
option(ENABLE_TSAN "Build with ThreadSanitizer" OFF)

if(ENABLE_TSAN)
    target_compile_options(thread_pool_test PRIVATE
        -O1
        -fsanitize=thread
        -fno-omit-frame-pointer
    )
    target_link_options(thread_pool_test PRIVATE
        -fsanitize=thread
    )
endif()
```

这段只展示 sanitizer flags 怎样同时进入 compile 和 link。你需要把它放在 `thread_pool_test` target 创建之后。

构建运行：

```bash
cmake -S . -B build-tsan \
    -DCMAKE_BUILD_TYPE=Debug \
    -DENABLE_TSAN=ON

cmake --build build-tsan -j
cmake -E chdir build-tsan ctest --output-on-failure
```

也可以直接 g++ 验证：

```bash
g++ -std=c++17 -Wall -Wextra -g -O1 -pthread \
    -fsanitize=thread -fno-omit-frame-pointer \
    -Iinclude tests/thread_pool_test.cpp \
    -lgtest -lgtest_main \
    -o thread_pool_test_tsan

./thread_pool_test_tsan
```

不要拿 TSan runtime 结果与之后 `-O2` benchmark 数字比较。

---

### 28.1 上述 command 什么意思？

这段的完整意思是：给项目增加一个“是否构建 TSan 版本”的开关；开关为 `ON` 时，才把 TSan 所需参数附着到 `thread_pool_test` 这个 target。

```cmake
option(ENABLE_TSAN "Build with ThreadSanitizer" OFF)
```

`option` 的语法是：

```cmake
option(变量名 "给人看的说明文字" 默认值)
```

所以这一行逐项是：

```text
ENABLE_TSAN
    CMake boolean variable，只有 ON / OFF 这类值

"Build with ThreadSanitizer"
    help string，说明这个开关是干什么的

OFF
    默认关闭 TSan
```

因此：

```bash
cmake -S . -B build
```

等价于这次构建默认：

```text
ENABLE_TSAN = OFF
```

而：

```bash
cmake -S . -B build-tsan -DENABLE_TSAN=ON
```

则是用户显式覆盖默认值：

```text
ENABLE_TSAN = ON
```

接着：

```cmake
if(ENABLE_TSAN)
    ...
endif()
```

就是普通条件判断：

```text
如果 ENABLE_TSAN 是 ON
-> 执行中间内容
否则
-> 跳过，构建普通版本
```

这也就是为什么你之前会收到 “`ENABLE_TSAN` was not used”：你当时把变量交给了 CMake，但 `CMakeLists.txt` 没有 `if(ENABLE_TSAN)` 之类的地方读取它。现在有了这个 `if`，变量就真正影响构建了。

下面这段：

```cmake
target_compile_options(thread_pool_test PRIVATE
    -O1
    -fsanitize=thread
    -fno-omit-frame-pointer
)
```

意思是：只在**编译** `thread_pool_test` 的每个 `.cpp` 成 `.o` 时，加上这些 `g++` 参数。

```text
target_compile_options
    把 compiler options 附着到某个 target

thread_pool_test
    被设置的 target

PRIVATE
    这些参数只给 thread_pool_test 自己用
    不传播给依赖它的其他 target
```

因此概念上会生成：

```bash
g++ -O1 -fsanitize=thread -fno-omit-frame-pointer \
    ... -c tests/thread_pool_test.cpp -o ...
```

三个参数的作用：

```text
-O1
    optimization level 1，适度优化
    TSan 测试常用，避免极端优化，也不会完全不优化

-fsanitize=thread
    让 g++ 在编译时插入 ThreadSanitizer 的检测代码
    程序运行时才能报告已经执行路径上的 data race

-fno-omit-frame-pointer
    不省略 frame pointer
    有助于工具给出更可读的调用栈
```

但只在编译 `.cpp -> .o` 时插入检测还不够。最终可执行文件还需要 TSan runtime，所以还要：

```cmake
target_link_options(thread_pool_test PRIVATE
    -fsanitize=thread
)
```

它只影响**链接阶段**，概念上是：

```bash
g++ ...object files... -fsanitize=thread -o thread_pool_test
```

这里仍由 `g++` 充当 linker driver；它看到 `-fsanitize=thread` 后，会把 TSan runtime 一起纳入最终程序。不是让你手写 `-ltsan`。

完整因果链：

```text
cmake -DENABLE_TSAN=ON
    ->
option / cache 中 ENABLE_TSAN 为 ON
    ->
if(ENABLE_TSAN) 为真
    ->
compile command 增加 -fsanitize=thread
    ->
link command 也增加 -fsanitize=thread
    ->
生成真正带 TSan runtime 的 test binary
```

建议始终分两个 build tree：

```bash
cmake -S . -B build -DENABLE_TSAN=OFF
cmake -S . -B build-tsan -DENABLE_TSAN=ON
```

因为 `ENABLE_TSAN` 是构建配置的一部分，`build-tsan/` 不只是一个名字，它现在终于对应了真实不同的编译和链接参数。`option` 和 target options 的语义可对照 [CMake 3.16 `option`](https://cmake.org/cmake/help/v3.16/command/option.html) 与 [target compile options](https://cmake.org/cmake/help/v3.16/command/target_compile_options.html) 文档。

---

## 29. 怎样读一份 TSan data race report

典型报告会包含：

```text
WARNING: ThreadSanitizer: data race
Write of size ... by thread T1
    stack frame ...
Previous read/write ... by thread T2
    stack frame ...
Location is ...
Thread T1 created at ...
```

分析顺序：

```text
1. 找 Location：冲突的是哪个 object/member/memory address
2. 看 current access：哪个 thread 在 read/write，stack 到哪一行
3. 看 previous access：另一个 thread 在哪一行 read/write
4. 至少一个是否是 write
5. 原设计声称哪把 mutex/哪个 atomic/happens-before 保护它
6. 两条 stack 是否真的经过同一 synchronization protocol
7. 修 code 或 test code
8. 先重跑 targeted test，再跑 full suite 和 repeat
```

常见情况：

```text
report 指向 ThreadPool source -> component synchronization 可能错误
report 指向 test hit vector -> test 自己可能无锁并发写
report 指向 referenced object -> std::ref lifetime/synchronization 可能错误
```

不要第一反应就加 suppression。先判断是不是 test 真正暴露的 bug。

---

## 30. TSan clean 到底证明了多少

正确表述：

```text
在本次 TSan build 实际执行到的 paths 和 observed interleavings 中，
没有收到 TSan data-race report。
```

错误表述：

```text
ThreadPool 已被证明完全线程安全
shutdown 不可能 deadlock
所有 tasks 一定 exactly once
```

原因：

```text
TSan 是 dynamic analysis，只看实际执行路径
没执行到的 branch 没有证据
atomic logical bug 未必是 data race
lost wakeup/deadlock/lost task 需要其他 oracle
```

官方文档也明确把 TSan 定位为 data-race detector；它通过 compiler instrumentation 与 runtime 工作，并会带来明显性能和内存开销。

---

## 31. timeout 的作用与边界

CTest test property：

```text
TIMEOUT 10
```

表示某个 test 超过限制后由 runner 终止并标记失败。

它能把：

```text
永远 hang
```

变成：

```text
自动化可见的 timeout failure
```

但 timeout 数字不是 synchronization：

```text
test 在 9 秒内完成
```

不等于 lifecycle 正确。正常完成仍需 future、condition、join 和 assertions 建立因果链。

TSan 较慢，若 normal timeout 太紧，可以为 sanitizer build 调整 test timeout；不要因此在 test body 中增加一堆 sleep。

---

## 32. failure diagnosis 的建议顺序

若整套 tests 偶发失败：

```text
1. 记录失败 test full name
2. 用 --gtest_filter 单独运行
3. 区分 assertion failure / exception / crash / timeout
4. 读 expected 与 actual identity
5. 检查 scenario 是否真的建立目标 state
6. 检查 test 自己有无 data race / dangling reference
7. normal targeted test 重复
8. TSan targeted test
9. 修复后 full suite
10. full suite repeat
```

不要看到 concurrency failure 就随机加 sleep。sleep 可能只改变 scheduler，让 bug 暂时消失。

---

## 33. 今日完整证据链

```mermaid
flowchart TD
    A[ThreadPool written contract] --> B[GoogleTest scenario]
    B --> C[deterministic synchronization]
    C --> D[observable result or state]
    D --> E[EXPECT or ASSERT]
    E --> F[test binary exit code]
    F --> G[CTest timeout and aggregation]
    G --> H[normal suite evidence]
    H --> I[fresh-process repeat]
    I --> J[more scheduling interleavings]
    J --> K[TSan instrumented build]
    K --> L[data-race evidence for executed paths]
    L --> M[day4_note records commands and boundaries]
```

读图只抓：

> 先用 deterministic tests 证明具体 contract，再用 repeat 和 TSan 扩大动态证据；后两者不能替代前者。

---

# Part 3：收尾、练习、测试与验收

# Round 3：补齐工程证据并运行完整验证

## 34. Round3 最终 test project 复检

Round1 已经得到第一个可运行的 GoogleTest binary。这里才把它升级为完整 CMake/CTest/TSan 证据集，不要求重写已经正确的 basic tests。

### 34.1 canonical files 复检

继续使用 canonical project：

```text
include/blocking_queue.hpp
include/thread_pool.hpp
tests/thread_pool_test.cpp
CMakeLists.txt
week8/day4/day4_note.md
```

今天主要新增 tests 与 build entry。除非 test 暴露真实 bug，否则不要为了配合测试随意改 ThreadPool public behavior。

---

### 34.2 test program 最终职责复检

`tests/thread_pool_test.cpp` 要把 ThreadPool 的 public contract 变成 executable evidence：

```text
创建真实 pool objects
用真实 submit/future/shutdown/destructor API 建立场景
在 test thread 观察 values/exceptions/lifecycle outcomes
让错误通过 GoogleTest assertion 变成 test failure
让任意 test failure 变成 test binary non-zero exit code
```

它不负责：

```text
重新实现 ThreadPool
访问 private worker vector
用 sleep 猜完成顺序
用日志人工判断 PASS
做性能 benchmark
```

---

### 34.3 CMakeLists.txt 是干什么的

它要描述：

```text
使用 C++17
构建 thread_pool_test target
为 target 提供 include path
启用 warnings/debug info
链接 GoogleTest 与 Threads
让 CTest 发现每个 GoogleTest test
为 hang 设置 timeout
可选择单独构建 TSan target configuration
```

它不下载生产依赖，也不把所有 compiler flags 写成全局字符串。

---

## 35. 必做 test scenarios

你需要自己写 test bodies。本教程只给 scenario、oracle 和 cleanup boundary。

### 35.1 construct boundary

```text
Arrange：worker_count = 0，合法 capacity
Act：construct
Assert：invalid_argument
```

### 35.2 zero-task shutdown

```text
Arrange：construct pool，不 submit
Act：shutdown
Assert：call returns；第二次 sequential shutdown 也能 return
```

若 implementation hang，由 CTest timeout 让 failure 可见。

### 35.3 single value result

```text
submit callable returning int/string
future.get equals expected
```

Day3 已有多 result types 时，不需要在 Day4 重写所有语法 demo；把现有 contract 转成 GoogleTest assertions。

### 35.4 void result

```text
task 修改受正确 synchronization 保护的 state
future<void>.get returns
test thread checks side effect
```

### 35.5 many tasks exactly once

```text
unique IDs
mutex-protected hit vector
future for every task
get all futures
each hit count exactly 1
```

### 35.6 task exception and worker survival

```text
failing task future.get -> runtime_error
later normal task future.get -> expected value
```

### 35.7 empty `std::function` regression

```text
submit default-constructed std::function<void()>
future<void>.get -> std::bad_function_call
submit later normal task
later future.get -> expected value
```

这验证 Day3 明确选择的 generic-submit contract，并证明该 execution failure 不会终止 worker。

### 35.8 deterministic drain during shutdown

按第 17 节的：

```text
1 worker
capacity 1
Task A blocked at gate
Task B accepted and pending
helper calls shutdown
test submits Task C；它要么直接观察 close，要么先因 full 等待再被 close 唤醒
Task C throws 后，close 已确定线性化且 A 仍 blocked、B 仍 pending
release A
join helper
assert A/B once, C zero
```

### 35.9 submit after shutdown

```text
shutdown returns
new submit -> runtime_error
```

### 35.10 multiple concurrent submitters

```text
multiple caller threads
disjoint ID ranges
per-submitter future containers
join submitters
get and verify all results
```

### 35.11 destructor lifecycle

```text
future lives outside pool scope
pool scope ends without explicit shutdown
destructor must drain/join
future result remains observable
```

---

## 36. test source 编写边界

今天允许使用：

```text
TEST
EXPECT_EQ / EXPECT_TRUE / EXPECT_FALSE
ASSERT_EQ / ASSERT_TRUE / ASSERT_FALSE when continuation is invalid
EXPECT_THROW / ASSERT_THROW
future.get
mutex / condition_variable gates
thread join
unique task IDs
```

今天不需要：

```text
TEST_F fixture
parameterized tests
mock framework
death tests
custom matchers
private-member access hacks
random sleep-based scheduling
```

---

## 37. 建议完成顺序

```text
1. 安装并检查 libgtest-dev
2. 独立编译运行 add_test demo
3. 故意制造 assertion failure，确认 exit code non-zero
4. 写 project CMakeLists.txt
5. 先迁移 single result / exception tests
6. 补 empty std::function 的 future exception regression
7. 补 construct、zero-task、repeated shutdown
8. 补 unique-ID exactly-once
9. 补 deterministic drain gate
10. 补 concurrent submitters
11. 补 destructor lifecycle
12. normal CTest full suite
13. direct binary filter targeted tests
14. fresh-process repeat 50 次
15. separate build-tsan
16. 读 TSan output 并记录能力边界
```

若某个 test 卡住，先 filter 单项；不要让整套 suite 每次都陪它等 timeout。

---

## 38. normal build 与运行命令

从 project root：

```bash
rm -rf build
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build -j
```

检查 warning：

```text
ThreadPool source 零 warning
test source 零 warning
CMake configure 没有缺失 dependency
```

运行：

```bash
./build/thread_pool_test
cmake -E chdir build ctest --output-on-failure
```

若 binary path 因 generator 不同而变化，以 CMake build output 为准，不手工复制 executable。

---

## 39. repeat 与 TSan 命令

fresh-process repeat：

```bash
for i in $(seq 1 50); do
    ./build/thread_pool_test || exit 1
done
```

TSan：

```bash
rm -rf build-tsan
cmake -S . -B build-tsan \
    -DCMAKE_BUILD_TYPE=Debug \
    -DENABLE_TSAN=ON
cmake --build build-tsan -j
cmake -E chdir build-tsan ctest --output-on-failure
```

记录时分开写：

```text
normal CTest：多少 tests passed
repeat：多少 complete process runs passed
TSan：哪些 tests 执行；是否有 WARNING: ThreadSanitizer
```

不要只写一句“全部测试过了”。

---

## 40. 失败时先检查 test 本身

并发 test 很容易自己制造 bug：

```text
multiple threads push same vector without mutex
task captures local reference that already died
ASSERT early-return skipped gate release
helper thread 没 join
future get twice
test name says pending，但没有确定性建立 pending
只检查 sum，遗漏/重复互相抵消
```

发现 failure 时先回答：

```text
是 component 违反 contract？
还是 test scenario/oracle/synchronization 自己不正确？
```

两者都必须修，但不能把 test code 的 data race 误判成 ThreadPool bug。

---

## 41. day4_note 建议

创建：

```text
week8/day4/day4_note.md
```

建议结构：

```markdown
# Week8 Day4 Note

## 1. GoogleTest execution chain

TEST registration -> gtest_main -> assertions -> binary exit code

## 2. EXPECT 与 ASSERT 的边界

## 3. 我怎样确定性建立 pending-task shutdown

## 4. exactly-once oracle

## 5. normal test evidence

命令：
结果：

## 6. stress repeat evidence

命令：
次数：
结果：

## 7. TSan evidence

命令：
结果：
TSan 能证明什么：
TSan 不能证明什么：

## 8. 我遇到的失败与修复
```

你若已经通过 test names、代码、terminal evidence 清楚证明某个验收问题，不需要再机械抄一遍答案。

---

## 42. 今日验收问题

1. 为什么打印 `FAIL` 后仍 `return 0` 的程序不能作为可靠 automated test？
2. `EXPECT_*` 与 `ASSERT_*` 分别怎样影响当前 test function？为什么 blocked-worker test 中滥用 `ASSERT_*` 可能破坏 cleanup？
3. GoogleTest、test binary、CTest 三者分别负责什么？
4. 请串起 deterministic drain test：怎样确定 A 正在运行、B 已 pending、shutdown 已 close acceptance，以及最后怎样证明 B 被 drain？
5. 为什么 exactly-once 不能只检查 final sum？unique task ID 提供了什么更强 oracle？
6. deterministic tests、stress repeat、TSan 分别提供哪一类证据？TSan clean 为什么不能证明没有 deadlock/lost task？
7. 为什么 assertions 推荐在 test thread 做，而 worker task 只返回 result 或更新受同步保护的 observable state？

---

## 43. 今日通过标准

### 核心通过

```text
GoogleTest/CMake 环境可用
test binary failure 会产生 non-zero exit code
test names 能说清 scenario + expected behavior
核心 ThreadPool contract 均有 executable assertions
Day2 到 Day3 改变的 empty-task contract 有明确 regression test
pending-task shutdown 由 gate 确定性建立
exactly-once 使用 unique IDs，不只检查 sum
tests 不依赖固定 sleep 猜顺序
```

### 工程证据

```text
C++17 + Wall + Wextra 零 warning
normal CTest full suite PASS
fresh-process repeat 至少 50 次 PASS
TSan build 能运行且无 data-race report
CTest tests 有 timeout，hang 会成为 failure
day4_note 分开记录三类证据
```

### 不阻塞 Day4

```text
没有 fixture
没有 parameterized tests
没有 mock framework
没有 coverage report
没有 CI pipeline
没有 benchmark
没有证明所有 concurrency bugs 不存在
```

---

## 44. 今日压缩记忆

```text
contract 只有变成 scenario + observable outcome + assertion，才成为 executable evidence。

GoogleTest 判断具体 behavior；
stress repeat 扩大 scheduling interleavings；
TSan 检查已执行路径上的 data race。

三类证据互相补充，但不能互相替代。

并发测试先确定性建立目标 state，再断言；
不要用 sleep 猜顺序，也不要让测试代码自己产生 race。
```

下一天进入 AsyncLogger V1：将日志 record 的生产与 file I/O 分离。Day5 会复用今天形成的测试纪律，但不会继续扩展 GoogleTest 高级功能。

---

## 45. 今日参考资料

本教程按你的 Ubuntu `CMake 3.16.3` 环境使用对应版本文档和 target names：

- [GoogleTest Primer](https://google.github.io/googletest/primer.html)
- [GoogleTest Assertions Reference](https://google.github.io/googletest/reference/assertions.html)
- [CMake 3.16 FindGTest](https://cmake.org/cmake/help/v3.16/module/FindGTest.html)
- [CMake 3.16 GoogleTest module](https://cmake.org/cmake/help/v3.16/module/GoogleTest.html)
- [LLVM ThreadSanitizer documentation](https://clang.llvm.org/docs/ThreadSanitizer.html)
- [Ubuntu Focal libgtest-dev package](https://launchpad.net/ubuntu/focal/amd64/libgtest-dev)

这些资料用于核对 API、CMake 3.16 imported target names、test discovery 与 TSan 能力边界；今天不要求通读完整高级文档。
