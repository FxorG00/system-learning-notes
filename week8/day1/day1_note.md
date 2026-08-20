## practice

```text
1. main 创建所有 workers
2. work 就是 while(1) 从 queue 中取出任务，并且执行；直到没有任务且 queue close() 的时候结束。完成一个 task[i] 后写入到 result[i] 里面，并且 executed_count.fetch_add(1); 这是一个 atomic
3. main 向 queue 中 push 进去所有 task
4. main join all workers
5. main 验证每个 result[i] 的结果
6. 打印输出
```
