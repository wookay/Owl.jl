# 모델-빌딩 기초

## 기울기(Gradients, 경사) 구하기

간단한 linear regression(선 모양으로 그려지는)을 생각해보자.
입력 `x`에 대해 출력 배열 `y` 가 어떤 모양으로 나올지 예측하는 것이다. (줄리아 REPL에서 예제를 따라해보면 좋다)

```julia
W = rand(2, 5)
b = rand(2)

predict(x) = W*x .+ b
loss(x, y) = sum((predict(x) .- y).^2)

x, y = rand(5), rand(2) # 더미 데이터
loss(x, y) # ~ 3
```

예측을 더 잘하기 위해 `W`와 `b`의 기울기를 구하자. loss function과 gradient descent를 해보면서.
직접 손으로 기울기를 계산할 수 있지만
Flux에서는 `W`와 `b`를 훈련시키는 *파라미터(parameters)*로 둘 수 있다.

```julia
using Flux.Tracker

W = param(W)
b = param(b)

l = loss(x, y)

back!(l)
```

`loss(x, y)`는 같은 수를 리턴,
그런데 이제부터는 기울어지는 모양을 관찰 기록하여 값을 *추적(tracked)* 한다.
`back!`을 호출하면 `W`와 `b`의 기울기를 계산한다.
기울기가 뭔지 알아냈고 `W`를 고쳐가면서 모델을 훈련한다.

```julia
W.grad

# 파라미터 업뎃
W.data .-= 0.1(W.grad)

loss(x, y) # ~ 2.5
```

loss가 조금 줄어들었다, 예측 `x`가 타겟 `y`에 좀 더 가까워졌다는 것을 의미한다.
데이터가 있으면 [모델 훈련하기](../training/training.md)도 시도할 수 있다.

복잡한 딥러닝이 Flux에서는 이와 같은 예제처럼 단순해진다.
물론 모델의 파라미터 갯수가 백만개가 넘어가고 복잡한 제어 흐름을 갖게 되면 다른 모양을 갖겠지.
그리고 이러한 복잡성을 다루는 법이 있다. 어떤 것인지 살펴보자.

## Building Layers

It's common to create more complex models than the linear regression above. For example, we might want to have two linear layers with a nonlinearity like [sigmoid](https://en.wikipedia.org/wiki/Sigmoid_function) (`σ`) in between them. In the above style we could write this as:

```julia
W1 = param(rand(3, 5))
b1 = param(rand(3))
layer1(x) = W1 * x .+ b1

W2 = param(rand(2, 3))
b2 = param(rand(2))
layer2(x) = W2 * x .+ b2

model(x) = layer2(σ.(layer1(x)))

model(rand(5)) # => 2-element vector
```

This works but is fairly unwieldy, with a lot of repetition – especially as we add more layers. One way to factor this out is to create a function that returns linear layers.

```julia
function linear(in, out)
  W = param(randn(out, in))
  b = param(randn(out))
  x -> W * x .+ b
end

linear1 = linear(5, 3) # we can access linear1.W etc
linear2 = linear(3, 2)

model(x) = linear2(σ.(linear1(x)))

model(x) # => 2-element vector
```

Another (equivalent) way is to create a struct that explicitly represents the affine layer.

```julia
struct Affine
  W
  b
end

Affine(in::Integer, out::Integer) =
  Affine(param(randn(out, in)), param(randn(out)))

# Overload call, so the object can be used as a function
(m::Affine)(x) = m.W * x .+ m.b

a = Affine(10, 5)

a(rand(10)) # => 5-element vector
```

Congratulations! You just built the `Dense` layer that comes with Flux. Flux has many interesting layers available, but they're all things you could have built yourself very easily.

(There is one small difference with `Dense` – for convenience it also takes an activation function, like `Dense(10, 5, σ)`.)

## Stacking It Up

It's pretty common to write models that look something like:

```julia
layer1 = Dense(10, 5, σ)
# ...
model(x) = layer3(layer2(layer1(x)))
```

For long chains, it might be a bit more intuitive to have a list of layers, like this:

```julia
using Flux

layers = [Dense(10, 5, σ), Dense(5, 2), softmax]

model(x) = foldl((x, m) -> m(x), x, layers)

model(rand(10)) # => 2-element vector
```

Handily, this is also provided for in Flux:

```julia
model2 = Chain(
  Dense(10, 5, σ),
  Dense(5, 2),
  softmax)

model2(rand(10)) # => 2-element vector
```

This quickly starts to look like a high-level deep learning library; yet you can see how it falls out of simple abstractions, and we lose none of the power of Julia code.

A nice property of this approach is that because "models" are just functions (possibly with trainable parameters), you can also see this as simple function composition.

```julia
m = Dense(5, 2) ∘ Dense(10, 5, σ)

m(rand(10))
```

Likewise, `Chain` will happily work with any Julia function.

```julia
m = Chain(x -> x^2, x -> x+1)

m(5) # => 26
```

## Layer helpers

Flux provides a set of helpers for custom layers, which you can enable by calling

```julia
Flux.treelike(Affine)
```

This enables a useful extra set of functionality for our `Affine` layer, such as [collecting its parameters](../training/optimisers.md) or [moving it to the GPU](../gpu.md).
