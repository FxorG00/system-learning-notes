## R1

```text
向 ThreadPool 提交若干 task，每个 task 计算一个结果，并且向 logger log 一份 task id。

然后我们先关闭 ThreadPool，确保所有的 task 都已经执行结束。这样不会有再对 logger 提交 record 的行为。

接下来再 shutdown logger，把 records 都 output 到 file 里面。

validate: 
每个任务的返回值都必须正确，future.get()
我去读取文件，要求每个 task id 的 log 都要出现恰好一次。
```

```text
component_demo.cpp:36-37 先构造 pool、后构造 logger。异常退出时析构顺序相反，logger 会先销毁，可能留下 tasks 的 dangling borrow。应改成 logger first，pool second。
```

