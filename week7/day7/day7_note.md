```text
worker_count=4
iterations=1000000
repeat_count=10

test C:
repeat 1: 39933 us, PASS
repeat 2: 37255 us, PASS
repeat 3: 41217 us, PASS
repeat 4: 44239 us, PASS
repeat 5: 44109 us, PASS
repeat 6: 41779 us, PASS
repeat 7: 42427 us, PASS
repeat 8: 43095 us, PASS
repeat 9: 39461 us, PASS
repeat 10: 38524 us, PASS
median: 41779 us
average: 41203.9 us

test D:
repeat 1: 5649 us, PASS
repeat 2: 6362 us, PASS
repeat 3: 5702 us, PASS
repeat 4: 5758 us, PASS
repeat 5: 5876 us, PASS
repeat 6: 5635 us, PASS
repeat 7: 5780 us, PASS
repeat 8: 5783 us, PASS
repeat 9: 5677 us, PASS
repeat 10: 6003 us, PASS
median: 5780 us
average: 5822.5 us


对比 C,D 可看出，当前环境中性能上有 6-9 倍差距。
```
