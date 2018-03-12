# 모델 만들기 기초

## 기울기(Gradients, 경사) 구하기

간단한 리니어 리그레션(linear regression, 직선 모양으로 그려지는 함수)을 생각해 보자.
이것은 입력 `x`에 대한 출력 배열 `y`를 예측한다. (줄리아 REPL에서 예제를 따라해보면 좋다)

```julia-repl
julia> W = rand(2, 5)
2×5 Array{Float64,2}:
 0.857747   0.291713  0.179873  0.938979  0.51022
 0.0852085  0.977716  0.246164  0.460672  0.772312

julia> b = rand(2)
2-element Array{Float64,1}:
 0.663369
 0.132996

julia> predict(x) = W*x .+ b
predict (generic function with 1 method)

julia> loss(x, y) = sum((predict(x) .- y).^2)
loss (generic function with 1 method)

julia> x, y = rand(5), rand(2) # 더미 데이터
([0.496864, 0.947507, 0.874288, 0.251528, 0.192234], [0.901991, 0.0802404])

julia> loss(x, y) # ~ 3
3.1660692660286722
```

예측을 더 잘하기 위해 `W`와 `b`의 기울기를 구하자.
loss function(손실, 예측 실패 함수)과 gradient descent(경사 하강, 내리막 기울기)를 해보면서.
직접 손으로 기울기를 계산할 수도 있지만
Flux에서는 `W`와 `b`를 훈련시키는 *파라미터(parameters)*로 둘 수 있다.

```julia-repl
julia> using Flux.Tracker

julia> W = param(W)
Tracked 2×5 Array{Float64,2}:
 0.857747   0.291713  0.179873  0.938979  0.51022
 0.0852085  0.977716  0.246164  0.460672  0.772312

julia> b = param(b)
Tracked 2-element Array{Float64,1}:
 0.663369
 0.132996

julia> l = loss(x, y)
3.1660692660286722 (tracked)

julia> back!(l)

```

`loss(x, y)`는 방금 전과 같은 수(3.1660692660286722)를 리턴,
그런데 이제부터는 기울어지는 모양을 관찰 기록하여 값을 *추적(tracked)*  한다.
`back!`을 호출하면 `W`와 `b`의 기울기를 계산한다.
기울기가 뭔지 알아냈으니 `W`를 고쳐가면서 모델을 훈련하자.

```julia-repl
julia> W.grad
2×5 Array{Float64,2}:
 0.949491  1.81066  1.67074  0.480662  0.367352
 1.49163   2.84449  2.62468  0.755107  0.577101

julia> # 파라미터 업뎃
       W.data .-= 0.1(W.grad)
2×5 Array{Float64,2}:
  0.762798   0.110647   0.0127989  0.890913  0.473484
 -0.0639541  0.693267  -0.0163046  0.385161  0.714602

julia> loss(x, y) # ~ 2.5
1.1327711929294395 (tracked)
```

예측 실패(loss)가 조금 줄어들었다. `x` 예측이 목표 대상(target) `y`에 좀 더 가까워졌다는 것을 의미한다.
데이터가 있으면 [모델 훈련하기](../training/training.md)도 시도할 수 있다.

복잡한 딥러닝이 Flux에서는 이와 같은 예제처럼 단순해진다.
물론 모델의 파라미터 갯수가 백만개가 넘어가고 복잡한 제어 흐름을 갖게 되면 다른 모양을 갖겠지.
그리고 이러한 복잡성을 다루는 것에는 뭐가 있는지 한번 살펴보자.

## 레이어 만들기

이제부터는 리니어 리그레션 보다 복잡한 모델을 만들어 보자.
예를 들어, 두 개의 리니어 레이어 사이에
[시그모이드](https://en.wikipedia.org/wiki/Sigmoid_function) (`σ`) 처럼
비선형(nonlinearity, 커브처럼 직선이 아닌 거)를 갖는 넘이 있을때,
위의 스타일은 아래와 같이 쓸 수 있다:

```julia-repl
julia> using Flux

julia> W1 = param(rand(3, 5))
Tracked 3×5 Array{Float64,2}:
 0.540422  0.680087  0.743124  0.0216563  0.377793
 0.416939  0.51823   0.464998  0.419852   0.446143
 0.260294  0.392582  0.46784   0.549495   0.373124

julia> b1 = param(rand(3))
Tracked 3-element Array{Float64,1}:
 0.213799
 0.373862
 0.243417

julia> layer1(x) = W1 * x .+ b1
layer1 (generic function with 1 method)

julia> W2 = param(rand(2, 3))
Tracked 2×3 Array{Float64,2}:
 0.789744  0.389376  0.172613
 0.472963  0.21518   0.220236

julia> b2 = param(rand(2))
Tracked 2-element Array{Float64,1}:
 0.121207
 0.502486

julia> layer2(x) = W2 * x .+ b2
layer2 (generic function with 1 method)

julia> model(x) = layer2(σ.(layer1(x)))
model (generic function with 1 method)

julia> model(rand(5)) # => 2-엘러먼트 벡터
Tracked 2-element Array{Float64,1}:
 1.06727
 1.13835
```

작동은 하는데 중복 작업이 많아 보기에 좋지 않다 - 특히 레이어를 더 추가한다면.
리니어 레이어를 돌려주는 함수를 하나 만들어 이것들을 정리하자.

```julia-repl
julia> function linear(in, out)
         W = param(randn(out, in))
         b = param(randn(out))
         x -> W * x .+ b
       end
linear (generic function with 1 method)

julia> linear1 = linear(5, 3) # linear1.W 할 수 있닥 (익명함수 리턴)
(::#3) (generic function with 1 method)

julia> linear1.W
Tracked 3×5 Array{Float64,2}:
 -1.72011   -1.07297   0.396755  -0.117604   0.25952
 -0.16694    0.99327  -0.589717  -1.87123    0.141679
 -0.972281  -1.84836   2.55071   -0.136674  -0.147826

julia> linear2 = linear(3, 2)
(::#3) (generic function with 1 method)

julia> model(x) = linear2(σ.(linear1(x)))
model (generic function with 1 method)

julia> model(x) # => 2-엘러먼트 벡터
Tracked 2-element Array{Float64,1}:
 2.75582
 0.416809
```

다른 방법으로는 struct로 타입을 만들어서 어파인(affine) 레이어를 명시적으로 표현하는 것이 있다.

```julia-repl
julia> struct Affine
         W
         b
       end

julia> Affine(in::Integer, out::Integer) =
         Affine(param(randn(out, in)), param(randn(out)))
Affine

julia> # 오버로드 하면 객체를 함수처럼 호출할 수 있다
       (m::Affine)(x) = m.W * x .+ m.b

julia> a = Affine(10, 5)
Affine(param([0.0252182 -1.99122 … -0.191235 0.294728; 1.13559 1.50226 … -2.43917 0.56976; … ; -0.735177 0.202646 … -0.301945 -0.183598; 1.05967 0.986786 … -1.57835 -0.0893871]), param([-0.39419, -1.26818, 0.757665, 0.941398, -0.783242]))

julia> a(rand(10)) # => 5-엘러먼트 벡터
Tracked 5-element Array{Float64,1}:
 -0.945544
 -0.575674
  2.93741
  0.111253
 -0.843172
```

축하합니다! Flux에서 나오는 `Dense` 레이어 만들기 성공!
Flux는 많은 재밌는 레이어들이 있는데, 그것들을 직접 만드는 것 또한 정말 쉽다.

(`Dense`와 다른 한가지 - 편의를 위해 활성(activation) 함수를 뒤에 추가할 수도 있다. `Dense(10, 5, σ)` 요런식으로.)

## 이쁘게 쌓아보자

다음과 같은 모델을 만드는 것은 흔하다:
(layer1 이름이 겹치니 REPL을 새로 띄우자)

```julia-repl
julia> using Flux

julia> layer1 = Dense(10, 5, σ)
Dense(10, 5, NNlib.σ)

julia> # ...
       model(x) = layer3(layer2(layer1(x)))
model (generic function with 1 method)
```

기다랗게 연결(chains) 할라믄, 다음과 같이 레이어의 리스트를 만드는게 좀 더 직관적이다:

```julia-repl
julia> layers = [Dense(10, 5, σ), Dense(5, 2), softmax]
3-element Array{Any,1}:
 Dense(10, 5, NNlib.σ)
 Dense(5, 2)
 NNlib.softmax

julia> model(x) = foldl((x, m) -> m(x), x, layers)
model (generic function with 1 method)

julia> model(rand(10)) # => 2-엘러먼트 벡터
Tracked 2-element Array{Float64,1}:
 0.593021
 0.406979
```

편리하게 쓰라고 이것 역시 Flux에서 제공한다:

```julia-repl
julia> model2 = Chain(
         Dense(10, 5, σ),
         Dense(5, 2),
         softmax)
Chain(Dense(10, 5, NNlib.σ), Dense(5, 2), NNlib.softmax)

julia> model2(rand(10)) # => 2-엘러먼트 벡터
Tracked 2-element Array{Float64,1}:
 0.172085
 0.827915
```

고오급 딥러닝 라이브러리 같아 보인다; 어느만큼 간단하게 추상화 하는지 보았을 것이다.
줄리아 코드의 강력함을 놓치지 않았다.

이런 접근법의 좋은 점은 "모델"이 함수라는 것이다 (훈련가능한 파라미터와 함께),
함수 합성(∘) 또한 가능하다.

```julia-repl
julia> m = Dense(5, 2) ∘ Dense(10, 5, σ)
(::#55) (generic function with 1 method)

julia> m(rand(10))
Tracked 2-element Array{Float64,1}:
 -1.28749
 -0.202492
```

마찬가지로, `Chain`은 줄리아 함수와 이쁘게 동작한다.

```julia-repl
julia> m = Chain(x -> x^2, x -> x+1)
Chain(#3, #4)

julia> m(5) # => 26
26
```

## 레이어 도우미들

Flux는 사용자의 커스텀 레이어를 도와주는 함수를 제공한다. 다음과 같이 호출하면

```julia
julia> Flux.treelike(Affine)
adapt (generic function with 1 method)
```

`Affine` 레이어에 부가적인 유용한 기능이 추가된다, [파라미터 모으기(collecting)](../training/optimisers.md)나 [GPU에서 처리하기](../gpu.md) 같은 작업을 할 수 있다.
