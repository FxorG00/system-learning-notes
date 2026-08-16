## practice

```text
实现一个 producer_work
capacity 都是只读的
用 queue<int>q; 即可

for i=0 to N-1
	拿锁，为了下面检测 predicate（需要去判断 queue 的属性）
	我 push 只能在 queue not full 的情况下 push
	not_full_cv.wait(lock,not_full_predicate);
	对应的 predicate 就是 queue not full is true
	
	到这里的时候，我已经获得 mutex 并且 predicate 为 true 了
	q.push(i);
	lock.unlock();
	not_empty_cv.notify_one();
	先释放 mutex，再 notify_one，这样可能可以减少 waiter 的等待，因为 notify 前 mutex 已经释放；而不会出现先 notify 再 unlock 导致 waiter 被 notify 后在等待 mutex
	
consumer_work
for i=0 to N-1
	完成恰好 N 次 pop
	拿到 queue mutex
	not_empty_cv.wait(lock,not_empty_predicate)
	现在 predicate 为 true 且拿到 mutex
	int value=q.front(); q.pop();
	lock.unlock();
	not_full_cv.notify_one();
	consumed_vector.pb(value);
```

