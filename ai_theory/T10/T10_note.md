## R1

### nn

**`nn` 是 Neural Network（神经网络）的缩写。**

在 PyTorch 中，`torch.nn` 是提供模型组件的模块，例如：

- `nn.Linear`：线性层，计算输入的线性变换与偏置。
- `nn.ReLU`：对每个数取 `max(0, x)`。
- `nn.Module`：组织模型及其参数的基类。

写 `from torch import nn` 后，就可以直接用 `nn.Linear`，不用每次写完整的 `torch.nn.Linear`。

### nn.Linear(D,C)

nn 是 Neural Network(神经网络) 的缩写。

`nn.Linear(D,C)`创建一个持有权重和偏置的线性层对象。

给它一行D个特征，会返回C个分数。数学仍是你会的线性映射，但它把权重存成`[C,D]`，计算时转置：

$$
Z=X A^T+b,
\qquad X:[B,D],\quad A:[C,D],\quad Z:[B,C].
$$

```text
weights 的 shape 是 (C,D)

我们希望的是，(B,D)@(D,C)+(C,)

得到 (B,C) 就是每组输入，对应的 C 个类别的 logits。
```



### model

```python
import torch
from torch import nn


class TinyClassifier(nn.Module):
    def __init__(self, input_dim: int, class_count: int) -> None:
        super().__init__()
        self.linear = nn.Linear(input_dim, class_count)

    def forward(self, inputs: torch.Tensor) -> torch.Tensor:
        return self.linear(inputs)
    
    torch.manual_seed(2026)
    
input_dim, class_count = 4, 3
model = TinyClassifier(input_dim, class_count)
inputs = torch.tensor(
    [
        [1.0, 2.0, 3.0, 4.0],
        [-1.0, 0.5, 2.0, -0.5],
    ],
    dtype=torch.float32,
)
outputs = model(inputs)
assert tuple(outputs.shape) == (2, 3)
```

**正常入口写`model(inputs)`，它会进入你定义的`forward`。**

### model 里面有什么？

```text
model                         模块：TinyClassifier
└── linear                    子模块：Linear
    ├── weight [3,4]          参数Tensor
    └── bias [3]              参数Tensor

model.debug_tensor [1]        普通属性，未进入上述管理名单
```

### buffer

```text
buffer 是属于模型，但是不属于训练参数的状态。
比如我们对 input 进行的 scale。就让每个特征都 *=0.5
```

在 `__init__` 之后添加

```python
self.register_buffer(
    "input_scale", # 输入缩放系数
    torch.ones(input_dim, dtype=torch.float32),
)
```

### model 里的各个角色

- **parameter**：如linear.weight，以**训练参数**身份登记，默认允许求梯度。
- **buffer**：如input_scale，是模型需要**长期保留的固定数值**，本课不让优化器更新它。
- **本次计算的临时Tensor**：如scaled，由当前输入产生，不作为模型状态登记或保存。

### state_dict

```text
state_dict() 返回一份 名字 -> Tensor 的映射。共享 storage。返回的类型是字典。

就是这个 model.input_scale 指向 0x1234。但是 state["input_scale"] 指向 0x2345。虽然他们二者指向的对象不同，但是二者共享 storage。
```

```python
import copy

state = model.state_dict()
snapshot = copy.deepcopy(state)
model.input_scale[1] = 0.25

print(float(state["input_scale"][1]))
print(float(snapshot["input_scale"][1]))
# 0.25
# 0.5

model.input_scale[1] = 0.5
```



```python
state = model.state_dict()
for name, tensor in state.items():
    print(name, tuple(tensor.shape), tensor.dtype)
    
就是一个字典，name 是 key，tensor 是 value。
    
input_scale (4,) torch.float32
linear.weight (3, 4) torch.float32
linear.bias (3,) torch.float32
```

## R2

### dropout

随机丢弃。

```text
train() 模式下，根据置零概率，让一部分数可能置零，然后把留下的数放大。

eval() 模式下不改变。
```

```text
[2, 4, 6, 8]
p=0.5，也就是置零的概率
原输入：          [2, 4, 6, 8]
这次随机遮挡后：  [2, 0, 6, 0]
保留值再乘以2：  [4, 0, 12, 0]
```

最后一步的2来自：

$$
\frac{1}{1-p}=\frac{1}{0.5}=2
$$

为什么还要放大？拿原来等于6的那个位置看：它有一半概率变成0，一半概率变成12。重复很多次以后，这个位置输出的平均值仍是6：

$$
0.5\times 0+0.5\times 12=6
$$

```text
比如让 p=1.0
那么输入 [1.0,2.0,3.0,4.0]
train: [0.0,0.0,0.0,0.0]
eval: [1.0,2.0,3.0,4.0]
```

### with torch.inference_mode():

`with torch.inference_mode():` 只规定，在其缩进范围内的运算，不要建立 autograd 记录。

```python
w = torch.tensor(2.0, requires_grad=True)
b = torch.tensor(1.0, requires_grad=True)
x = torch.tensor(3.0)

# 普通计算：得到7，同时留下之后求梯度所需的来路
ordinary = w * x + b
print(ordinary.item())           # 7.0
print(ordinary.requires_grad)    # True

# 只算这次答案：仍得到7，但不留下求导来路
with torch.inference_mode():
    predicted = w * x + b

print(predicted.item())          # 7.0
print(predicted.requires_grad)   # False
```

### requires_grad

```text
在 with torch.inference_mode() 范围内的运算，得到的对象，因为其不会建立 autograd 记录，所以其 requires_grad=False。

requires_grad=True 表示：我之后可能要求这个Tensor的梯度，请在计算时记住它的计算来路。
```

### training, requires_grad 开关

```text
只要 model 是训练模式，也就是调用 model.train，那么 model.training 为 True

如果我们得到某个对象的计算，放到了 with torch.inference_mode(): 内，那么不会建立 autograd 记录，该对象 .requires_grad 为 False。
```

## R3

### 干啥的

> 解决：**旧进程结束，原 model 对象消失了。只靠同一份类定义、尺寸配置和 checkpoint，新进程能不能恢复出模型，使得能够产生同样的预测。**
>
> **也就是，我要从原先保存在磁盘里的文件，恢复 model 对象。**

```text
旧进程：原model算出参考结果 -> 把状态写进文件 -> 进程结束

新进程：重新创建TinyClassifier -> 读文件 -> 装回状态
                                      -> 对同一输入算出相同结果
```

### check_point

**checkpoint就是模型在某一时刻保存下来的一份状态快照，用于以后恢复。**

当前保存的是`model.state_dict()`，所以里面是那一刻的**参数和持久化buffer**，不包含模型类代码。

以后为了恢复训练，也可以把优化器状态、训练轮数等一起放进checkpoint。

### 怎么把状态写进文件，落到磁盘？

```python
checkpoint_path = "tiny_classifier.pt"
torch.save(model.state_dict(), checkpoint_path)
#本次，写给文件的是几个 Tensor: linear.weight, liner.bias, input_scale
```

### 怎么从文件中恢复模型

#### 先重新取得 名字 -> Tensor 的字典

```python
state = torch.load(
    checkpoint_path,
    map_location="cpu",
    weights_only=True,
)
# map_location="cpu" 规定本次 Tensor 先都放在 CPU 一侧。
# `weights_only=True`把可加载内容限制在Tensor、基础类型和允许的安全类型范围。这里仍只加载自己刚刚生成的可信文件。
print(sorted(state))
# ['input_scale', 'linear.bias', 'linear.weight']
# 此时 state 是个字典，是 name->Tensor。保存着我们恢复 model 需要的信息。
```

#### 创建一个有相同结构的新对象

```python
loaded_model = TinyClassifier(
    input_dim=input_dim,
    class_count=class_count,
)

assert torch.equal(
    loaded_model.input_scale,
    torch.ones(input_dim),
)
```

#### 把字典对应的映射，装回去新对象对应的位置

```python
load_result = loaded_model.load_state_dict(state, strict=True)

assert load_result.missing_keys == []
assert load_result.unexpected_keys == []
assert float(loaded_model.input_scale[1]) == 0.5
```

### 恢复完新对象后，怎么 check 得到相同结果？

```python
loaded_model.eval()
with torch.inference_mode():
    actual = loaded_model(inputs)

torch.testing.assert_close(actual, expected, rtol=1e-5, atol=1e-6)
# 逐元素，比较两个 Tensor
restored = loaded_model.state_dict()
assert set(restored) == set(state)
for name in state:
    torch.testing.assert_close(restored[name], state[name], rtol=0.0, atol=0.0)
assert float(loaded_model.input_scale[1]) == 0.5
```

### inputs 和模型状态必须使用兼容的 dtype

#### 只转换了输入，但是模型没跟上

例如模型默认是float32，而你把输入转成float64：

```python
converted = inputs.to(dtype=torch.float64)
# 这个是 Tensor.to
# 此时直接调用loaded_model(converted)，会因输入与weight的dtype不一致而失败。因为 loaded_model 的 linear.weight 的 dtype 是 float32
```

> 所以，我们要让模型接收 float64 的输入，那么 weight, bias, input_scale 这些 Tensor 都必须一起转换。

#### 让模型登记的状态一起转换

> Module.to 原地转换已经注册的 parameters 与 buffer，返回模型本身。前后的别名，仍让是指向同一个模型。我们没有得到新的模型！
>
> `assert returned_model is probe_model`

```python
probe_model = TinyClassifier(4, 3)
probe_model.debug_tensor = torch.zeros(1)
returned_model = probe_model.to(dtype=torch.float64)
assert returned_model is probe_model
assert probe_model.linear.weight.dtype == torch.float64
assert probe_model.input_scale.dtype == torch.float64
assert probe_model.debug_tensor.dtype == torch.float32

probe_model.eval()
with torch.inference_mode():
    double_scores = probe_model(converted)
assert double_scores.dtype == torch.float64
```

**Module.to原地转换已注册的参数与buffer，返回模型自身。普通debug_tensor没有登记为参数或buffer，因此没有跟着转换。**

