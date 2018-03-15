# 훈련시키키(Training)

모델을 훈련시키려면 세 가지가 필요하다:

* *목표 함수(objective function)*, 주어진 데이터를 얼만큼 잘 평가할 것인가.
* 데이터 포인트의 묶음(A collection of data points)을 목표 함수에 넘겨줄 것이다.
* [최적화 함수](optimisers.md)로 모델 파라미터를 적절하게 업데이트 할 것이다.

그리하여 `Flux.train!`는 다음과 같이 호출한다:

```julia
Flux.train!(objective, data, opt)
```

[모델 동물원(model zoo)](https://github.com/FluxML/model-zoo)에 여러가지 예제가 있다.

## 손실 함수(Loss Functions)

목표 함수는 반드시 모델과 대상(target)의 차이를 나타내는 숫자를 돌려주어야 한다 - 모델의 *loss*.
[기초](../models/basics.md)에서 정의한 `loss` 함수가 목표(an objective)로서 작동할 것이다.
모델의 관점에서 목표를 정의할 수도 있다:

```julia-repl
julia> using Flux

julia> m = Chain(
         Dense(784, 32, σ),
         Dense(32, 10), softmax)
Chain(Dense(784, 32, NNlib.σ), Dense(32, 10), NNlib.softmax)

julia> loss(x, y) = Flux.mse(m(x), y)
loss (generic function with 1 method)

# 나중에
julia> Flux.train!(loss, data, opt)
```

목표는 항상 `m(x)`의 예측과 대상 `y`의 거리를 측정하는 *비용 함수(cost function)*의 관점에서 정의된다.
Flux는 mean squared error를 구하는 `mse`나, cross entropy loss를 구하는 `crossentropy` 같은
비용 함수를 내장하고 있다. 원한다면 직접 계산해 볼 수도 있다.

## 데이터세트(Datasets)

`data` 인자는 훈련할 데이터(보통 입력 `x`와 target 출력 `y`)의 묶음을 제공한다.
예를 들어, 딱 하나 있는 더미 데이터 세트는 다음과 같다:

```julia
x = rand(784)
y = rand(10)
data = [(x, y)]
```

`Flux.train!`은 `loss(x, y)`을 호출하고, 기울기를 계산하며,
가중치(weights)를 업데이트하고 다음 데이터 포인트로 이동한다.
같은 데이터를 세 번 훈련시킬 수 있다:

```julia
data = [(x, y), (x, y), (x, y)]
# 또는 아래와 같이
data = Iterators.repeated((x, y), 3)
```

`x`와 `y`는 별도로 읽어들어는 것이 보통이다. 이럴 경우에 `zip`을 쓸 수 있다:

```julia
xs = [rand(784), rand(784), rand(784)]
ys = [rand( 10), rand( 10), rand( 10)]
data = zip(xs, ys)
```

기본적으로 `train!`은 데이터를 오직 한번만 순회한다 (한 세대, a single "epoch").
여러 세대를 돌리는 `@epochs` 매크로를 제공하고 있으니 REPL에서 다음과 같이 해 보자.

```julia-repl
julia> using Flux: @epochs

julia> @epochs 2 println("hello")
INFO: Epoch 1
hello
INFO: Epoch 2
hello

julia> @epochs 2 Flux.train!(...)
# 두 세대에 걸쳐 훈련한다
```

## 컬백(Callbacks)

`train!`은 `cb` 인자를 추가적으로 받는데, 컬백 함수를 줘서 훈련 과정을 지켜볼 수 있다.
예를 들면:

```julia
train!(objective, data, opt, cb = () -> println("training"))
```

컬백은 훈련 데이터의 배치(batch) 마다 호출된다. 좀더 적게 호출하려면
`Flux.throttle(f, timeout)`를 주어 `f`가 매 `timeout` 초 이상 호출되는 것을 막는다.

컬백을 사용하는 전형적인 방식은 다음과 같다:

```julia
test_x, test_y = # ... 테스트 데이터의 단일 배치(single batch) 만들기 ...
evalcb() = @show(loss(test_x, test_y))

Flux.train!(objective, data, opt,
            cb = throttle(evalcb, 5))
```
