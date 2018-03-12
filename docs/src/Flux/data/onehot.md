# 원-핫 인코딩(One-Hot Encoding)

참`true`, 거짓`false` 혹은 고양이`cat`, 강아지`dog` 와 같은
범주형 변수(categorical variables)로 인코딩 해 보자.
"one-of-k" 또는 ["one-hot"](https://en.wikipedia.org/wiki/One-hot) 형식이 되고
Flux는 `onehot` 함수로 쉽게 할 수 있다.

```julia-repl
julia> using Flux: onehot

julia> onehot(:b, [:a, :b, :c])
3-element Flux.OneHotVector:
 false
  true
 false

julia> onehot(:c, [:a, :b, :c])
3-element Flux.OneHotVector:
 false
 false
  true
```

역함수는 `argmax` (불리언 이나 일반 확률 분포(general probability distribution)를 인자로 받는다) 이다.

```julia-repl
julia> argmax(ans, [:a, :b, :c])
:c

julia> argmax([true, false, false], [:a, :b, :c])
:a

julia> argmax([0.3, 0.2, 0.5], [:a, :b, :c])
:c
```

## 배치(Batches)

`onehotbatch`는 원-핫 벡터의 배치(batch, 매트릭스)를 만들어 준다.
`argmax`는 매트릭스를 배치로 취급한다.

```julia-repl
julia> using Flux: onehotbatch

julia> onehotbatch([:b, :a, :b], [:a, :b, :c])
3×3 Flux.OneHotMatrix:
 false   true  false
  true  false   true
 false  false  false

julia> onecold(ans, [:a, :b, :c])
3-element Array{Symbol,1}:
  :b
  :a
  :b
```

위의 연산은 `Array` 대신 `OneHotVector`와 `OneHotMatrix`를 돌려준다.
`OneHotVector`는 일반적인 벡터처럼 동작하는데
정수 인덱스를 바로 사용하여 불필요한 계산 비용이 들지 않도록 처리한다.
예를 들어 매트릭스와 원-핫 벡터을 곱하는 경우,
내부적으로는 매트릭스에서 관련된 행만을 잘라내는 식으로 처리한다.
