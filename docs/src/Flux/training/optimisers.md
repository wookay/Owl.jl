# 최적화 함수(Optimisers)

[간단한 리니어 리그레션](../models/basics.md)에서 우리는
더미 데이터를 만든 후,
손실(loss)을 계산하고 역전파(backpropagate) 하여 파라미터 `W`와 `b`의 기울기를 계산하였다.

```julia-repl
julia> using Flux

julia> W = param(rand(2, 5))
Tracked 2×5 Array{Float64,2}:
 0.215021  0.22422   0.352664  0.11115   0.040711
 0.180933  0.769257  0.361652  0.783197  0.545495

julia> b = param(rand(2))
Tracked 2-element Array{Float64,1}:
 0.205216
 0.150938

julia> predict(x) = W*x .+ b
predict (generic function with 1 method)

julia> loss(x, y) = sum((predict(x) .- y).^2)
loss (generic function with 1 method)

julia> x, y = rand(5), rand(2) # 더미 데이터
([0.153473, 0.927019, 0.40597, 0.783872, 0.392236], [0.261727, 0.00917161])

julia> l = loss(x, y) # ~ 3
3.6352060699201565 (tracked)

julia> Flux.back!(l)

```

기울기를 사용하여 파라미터를 업데이트 하고자 한다.
손실을 줄이려고 말이다.
여기서 한가지 방법은:

```julia
function update()
  η = 0.1 # 학습하는 속도(Learning Rate)
  for p in (W, b)
    p.data .-= η .* p.grad # 업데이트 적용
    p.grad .= 0            # 기울기 0으로 clear
  end
end
```

`update`를 호출하면 파라미터 `W`와 `b`는 바뀌고
손실(loss)은 내려간다.

두가지는 짚고 넘어가자: 모델에서 훈련할 파라미터의 목록 (여기서는 `[W, b]`),
그리고 업데이트 진행 속도. 여기서의 업데이트는 간단한 gradient descent(경사 하강, `x .-= η .* Δ`) 였지만,
모멘텀(momentum)을 추가하는 것처럼 보다 어려운 것도 해보고 싶을 것이다.

여기서 변수를 얻는 것은 아무것도 아니지만,
레이어를 복잡하게 쌓는다면 골치 좀 아플 것이다.

```julia-repl
julia> m = Chain(
         Dense(10, 5, σ),
         Dense(5, 2), softmax)
Chain(Dense(10, 5, NNlib.σ), Dense(5, 2), NNlib.softmax)
```

`[m[1].W, m[1].b, ...]` 이렇게 작성하는 것 대신,
Flux에서 제공하는 `params(m)` 함수를 이용해
모델의 모든 파라미터의 목록을 구할 것이다.

```julia-repl
julia> opt = SGD([W, b], 0.1) # Gradient descent(경사 하강)을 learning rate(학습 속도) 0.1 으로 한다
(::#71) (generic function with 1 method)

julia> opt() # `W`와 `b`를 변경하며 업데이트를 수행한다

```

최적화 함수는 파라미터 목록을 받아 위의 `update`와 같은 함수를 돌려준다.
`opt`나 `update`를 [훈련 루프(training loop)](training.md)에 넘겨줄 수 있는데,
매번 데이터의 미니-배치(mini-batch)를 한 후에 최적화를 수행할 것이다.

## 최적화 함수 참고

모든 최적화 함수는 넘겨받은 파라미터를 업데이트 하는 함수를 돌려준다.

```@docs
SGD
Momentum
Nesterov
ADAM
```
