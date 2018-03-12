# GPU 지원

GPU 같이 하드웨어 백엔드로 하는 배열 연산의 지원은
[CuArrays](https://github.com/JuliaGPU/CuArrays.jl)와 같은 외부 패키지를 제공한다.
Flux는 배열의 타입을 정하지 않았기에(agnostic)
모델 가중치(weights)와 데이터를 GPU에 옮겨주면
Flux가 이를 다룰 수 있다.

예를 들어, `CuArrays` (`cu` 컨버터로 변환)를 사용하여
[기본 예제](models/basics.md)를 NVIDIA GPU에서 돌릴 수 있다.

```julia
using CuArrays

W = cu(rand(2, 5)) # 2×5 CuArray
b = cu(rand(2))

predict(x) = W*x .+ b
loss(x, y) = sum((predict(x) .- y).^2)

x, y = cu(rand(5)), cu(rand(2)) # 더미 데이터
loss(x, y) # ~ 3
```

파라미터 (`W`, `b`)와 데이터 세트 (`x`, `y`)를 cuda 배열로 변환하였다.
도함수(derivatives)와 훈련 값은 전과 동일하다.

`Dense` 레이어나 `Chain` 같은 조립 모델(structured model)를 정의하였으면,
내부 파라미터를 변환시켜야 한다.
Flux에서 제공하는 `mapleaves` 함수로 모델의 모든 파라미터를 한꺼번에 변경할 수 있다.

```julia
d = Dense(10, 5, σ)
d = mapleaves(cu, d)
d.W # Tracked CuArray
d(cu(rand(10))) # CuArray output

m = Chain(Dense(10, 5, σ), Dense(5, 2), softmax)
m = mapleaves(cu, m)
d(cu(rand(10)))
```

편의상 Flux는 `gpu` 함수를 제공하여 GPU가 이용 가능한 경우
모델과 데이터를 GPU로 변환하게 한다.
그냥은 암것도 안하지만
`CuArrays` 를 로딩(using CuArrays)한 경우는
데이터를 GPU에 옮겨준다.

```julia-repl
julia> using Flux, CuArrays

julia> m = Dense(10,5) |> gpu
Dense(10, 5)

julia> x = rand(10) |> gpu
10-element CuArray{Float32,1}:
 0.800225
 ⋮
 0.511655

julia> m(x)
Tracked 5-element CuArray{Float32,1}:
 -0.30535
 ⋮
 -0.618002
```

비슷한 용도로 `cpu`는 모델과 데이터를 GPU에서 그만돌리게 한다.

```julia-repl
julia> x = rand(10) |> gpu
10-element CuArray{Float32,1}:
 0.235164
 ⋮
 0.192538

julia> x |> cpu
10-element Array{Float32,1}:
 0.235164
 ⋮
 0.192538
```
