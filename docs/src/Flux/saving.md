# 모델을 저장하고 불러오기

모델을 저장하고는 차후에 이를 불러들여 실행하고 싶은가.
가장 쉬운 방법은 [BSON.jl](https://github.com/MikeInnes/BSON.jl) 이다.

모델을 저장하자:

```julia-repl
julia> using Flux

julia> model = Chain(Dense(10,5,relu),Dense(5,2),softmax)
Chain(Dense(10, 5, NNlib.relu), Dense(5, 2), NNlib.softmax)

julia> using BSON: @save

julia> @save "mymodel.bson" model
```

불러오기:

```julia-repl
julia> using Flux

julia> using BSON: @load

julia> @load "mymodel.bson" model

julia> model
Chain(Dense(10, 5, NNlib.relu), Dense(5, 2), NNlib.softmax)
```

모델은 보통의 줄리아 타입이다. 따라서 줄리아 저장 포맷이면
어느 것이라도 사용할 수 있다.
BSON.jl은 특히 잘 지원하며 앞으로도 되도록 호환을 유지한다
(지금 저장한 모델이 Flux의 차후 버전에서도 불러들일 수 있게).

!!! note

    GPU에 모델의 가중치를 저장하였으면, GPU 지원이 안되는 경우에는
    이를 불러 들일 수 없다. 저장하기 전에 [모델을 CPU로 돌려놓기](gpu.md) 에서의
    `cpu(model)`를 해주는게 가장 좋은 방법이다.

## 모델 가중치 저장하기

어떤 경우는 저장은 모델 파라미터만 하고
코드에서 모델 아키텍처를 재구성하는게 유용한 방법일 수 있다.
`params(model)`로 모델 파라미터를 구할 수 있다.
`data.(params)`을 하면 추적 내역 데이터를 지울 수 있다.

```julia-repl
julia> using Flux

julia> model = Chain(Dense(10,5,relu),Dense(5,2),softmax)
Chain(Dense(10, 5, NNlib.relu), Dense(5, 2), NNlib.softmax)

julia> weights = Tracker.data.(params(model));

julia> using BSON: @save

julia> @save "mymodel.bson" weights
```

`Flux.loadparams!`로 쉽게 모델에 파라미터를 불러들일 수 있다.

```julia-repl
julia> using Flux

julia> model = Chain(Dense(10,5,relu),Dense(5,2),softmax)
Chain(Dense(10, 5, NNlib.relu), Dense(5, 2), NNlib.softmax)

julia> using BSON: @load

julia> @load "mymodel.bson" weights

julia> Flux.loadparams!(model, weights)
```

새로 뜬 `model`은 전에 파라미터 저장한 것과 일치한다.

## 체크포인팅

장시간 훈련에 있어 주기적으로 모델을 저장하는 것은 참 좋은 생각이다.
그러면 훈련이 중단되어도 (파워가 나가는 등등의 이유로) 다시 재개할 수 있다.
그러기 위해서는 [`train!`의 컬백 함수](training/training.md)에서 모델을 저장하면 된다.

```julia
using Flux: throttle
using BSON: @save

m = Chain(Dense(10,5,relu),Dense(5,2),softmax)

evalcb = throttle(30) do
  # loss 보기
  @save "model-checkpoint.bson" model
end
```

이러면 `"model-checkpoint.bson"` 파일을 30초마다 업데이트 한다.

훈련시키는 동안에 모델을 연달아 저장하는 까리한 방법도 있는데 예를 들면

```julia
@save "model-$(now()).bson" model
```

이렇게 하면 `"model-2018-03-06T02:57:10.41.bson"`과 같이 연달아서 모델이 저장된다.
현 테스트 세트 loss도 저장할 수 있어서,
오버피팅 시작한다 싶으면 이전 사본의 모델로 복구를 쉽게 할 수 있다.

```julia
@save "model-$(now()).bson" model loss = testloss()
```

모델의 최적화 상태까지도 저장할 수 있으니,
정확하게 중단된 지점부터 이어 훈련을 재개할 수 있다.

```julia
opt = ADAM(params(model))
@save "model-$(now()).bson" model opt
```
