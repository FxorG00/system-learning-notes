## R1

```text
对于每个 connection 要保留其对应的解析状态。

input: 用于保存当前 incomplete suffix

完整 messsage: delimter 分隔开的 bytes

output: 保存已经完整的 message；需要重新加 '\n'

delimiter: '\n'

input,output 均使用 string 存放即可；这样能方便地 push_back 以及 pop。

append: 追加一些 bytes
那我就去模拟追加的过程，向 input 追加；直到追加到了 \n，则把目前 input 的 bytes 作为一条完整 message，然后放到 output，input 清空。
```

