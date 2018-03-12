# 정규화(Regularisation)

이번에는 모델 파라미터를 정규화 해 보자.
`vecnorm`과 같은 정규화를 해주는 적절한 함수를
각 모델 파라미터에 적용하여 그 결과를 모든 loss에 더하도록 하자.

예를 들어, 다음과 같은 간단한 regression을 보자.

```julia-repl
julia> using Flux

julia> m = Dense(10, 5)
Dense(10, 5)

julia> loss(x, y) = Flux.crossentropy(softmax(m(x)), y)
loss (generic function with 1 method)
```

`m.W`와 `m.b` 파라미터에 L2 norm을 취하여 정규화 해보자.

```julia-repl
julia> penalty() = vecnorm(m.W) + vecnorm(m.b)
penalty (generic function with 1 method)

julia> loss(x, y) = Flux.crossentropy(softmax(m(x)), y) + penalty()
loss (generic function with 1 method)
```

레이어를 이용하는 경우, Flux는 `params` 함수를 제공하여
모든 파라미터를 한번에 가져올 수 있다.
`sum(vecnorm, params)`를 사용하여 전체를 쉽게 적용할 수 있다.

```julia-repl
julia> params(m)
2-element Array{Any,1}:
 param([-0.61839 -0.556047 … -0.460808 -0.107646; 0.346293 -0.375076 … -0.608704 -0.181025; … ; -0.2226 -0.0992159 … 0.0707984 -0.429173; -0.331058 -0.291995 … 0.383368 0.156716])
 param([0.0, 0.0, 0.0, 0.0, 0.0])

julia> sum(vecnorm, params(m))
2.4130860599427706 (tracked)
```

좀 더 큰 규모의 예로, 멀티-레이어 퍼셉트론(perceptron)은 다음과 같다.

```julia-repl
julia> m = Chain(
         Dense(28^2, 128, relu),
         Dense(128, 32, relu),
         Dense(32, 10), softmax)
Chain(Dense(784, 128, NNlib.relu), Dense(128, 32, NNlib.relu), Dense(32, 10), NNlib.softmax)

julia> loss(x, y) = Flux.crossentropy(m(x), y) + sum(vecnorm, params(m))
loss (generic function with 1 method)

julia> loss(rand(28^2), rand(10))
39.128892409412174 (tracked)
```
