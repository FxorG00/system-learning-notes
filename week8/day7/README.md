```text
项目做什么
向 ThreadPool 提交若干 task，每个 task 计算一个结果，并且向 AsyncLogger log 一份 task id。

主要 components
ThreadPool,AsyncLogger

怎样 build/run
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build -j
./build/component_demo
```

