
 🦉  [https://github.com/MikeInnes/DataFlow.jl/blob/master/docs/vertices.md](https://github.com/MikeInnes/DataFlow.jl/blob/master/docs/vertices.md) 번역


DataFlow가 하는 두가지:
- 그래프 데이터 구조(a graph data structure)
- 그래프를 기술하기 위한 공통 문법(a common syntax for describing graphs)

서로 얶매여 있지 않으니 편하게 쓰면 된다; 
예를 들어, 이 문법으로 만든 그래프를 인접 행렬(an adjacency matrix)로 변환하여 처리한다거나
DataFlow의 공통 그래프 연산 라이브러리를 활용하여 다른 방식으로 그래프를 생성할 수 있다.

DataFlow는 명시적으로 데이터 구조를 단순하게 유지하고, 다른 어떠한 의미도 덧붙이지 않는다.
그래프는 반듯한 줄리아 프로그램, 베이시안 네트워크, 또는 전기 회로와 같은 것을 표현할 수 있다.
(Flux와 같은) DataFlow를 사용하는 라이브러리는 문법을 확장하고
응용 프로그램에 적절한 코드를 생성하기 위해 그래프를 다룰 것이다.

## 데이터 구조

DataFlow는 `DVertex`와 `IVertex`라는 두 개의 데이터 구조가 있다. 
둘은 그래프의 노드(nodes)가 다른 노드와 
입력/출력(inputs/outputs)이 어디에/어디로부터(to/from) 
어떻게 될 지 나타낸다.
`IVertex`는 링크드 리스트(a linked list) 처럼 입력-연결(input-linked) 이다 - 입력으로
  사용되는 노드에 대한 참조(a reference)를 유지한다.
`DVertex`는 이중으로 연결한 것으로 더블-링크드 리스트(doubly-linked list)에 해당한다 - 입력과
이것을 입력으로 갖는 모든 노드를 참조한다.
DVertex는 기술적으론 표현력이 더 좋지만 작업하기도 더 빡세니까,
가능하다면 입력-연결(input-linked)로 바꿔서 쓰는게 최선이다 (`DataFlow.il()`로 할 수 있다).

```julia
# src/graph/graph.jl
abstract type Vertex{T} end

# src/graph/ilgraph.jl
struct IVertex{T} <: Vertex{T}
  value::T
  inputs::Vector{IVertex{T}}
  # outputs::Set{IVertex{T}} # DVertex는 요걸 추가
end
```

`IVertex`는 줄리아의 `Expr` 객체와 유사하다. 예를 들어, 다음과 같이
표현식 `x+length(xs)` 를 비슷한 방식으로서 저장한다.

```julia-repl
julia> using DataFlow

julia> x = 2
2

julia> Expr(:call, :+, x, Expr(:call, :length, :xs))
:(2 + length(xs))

julia> IVertex(:+, IVertex(:x), IVertex(:length, IVertex(:xs)))
IVertex{Symbol}(x() + length(xs()))
```

주요한 차이는 *객체 아이덴티티(object identity)*가 DataFlow 그래프에서는 중요하다는 것이다.
다음과 같이 구문 표현 트리(an expression tree)를 만들면:

```julia-repl
julia> foo = Expr(:call, :length, :xs)
:(length(xs))

julia> Expr(:call, :+, foo, foo)
:(length(xs) + length(xs))
```

`length(xs)` 표현식을 재사용 했음에도 `length(xs)+length(xs)`를 출력한다.
DataFlow의 재사용은 큰 차이가 있다:

```julia-repl
julia> g = IVertex{Any}
IVertex

julia> g(:+, g(:length, g(:xs)), g(:length, g(:xs)))
IVertex(length(xs()) + length(xs()))

julia> foo = g(:length, g(:xs))
IVertex(length(xs()))

julia> g(:+, foo, foo)
IVertex(
eland = length(xs())
eland + eland)
```

재사용 한 것이 프로그램 그래프에 인코드 되었다. 위의 데이터 구조에서는 "변수" 개념이 없는데
데이터의 흐름이 직접 표현되었기 때문이다; 대신 문법 변환에서 변수가 필요해지면 그 때 생성될 것이다.

## 알고리즘

DataFlow 그래프를 다루는 기본 접근 방식은
함수형 프로그래밍에서 트리(tree)를 다루는 테크닉과 같은 것을 사용한다.
그러니까, 재귀적으로(recursively) 이전 것을 밟아나가며 새로운 그래프를 생성하는 알고리즘을
만들도록 하자.
그래프에 있는 각 노드에 특정 함수를 적용(apply) 시키는 함수로서,
`prewalk` 와 `postwalk` 같은게 패키지에 들어 있다.

예를 보자:

```julia-repl
julia> using DataFlow: postwalk, value

julia> foo = g(:+, g(:length, g(:xs)), g(:length, g(:ys)))
IVertex(length(xs()) + length(ys()))

julia> postwalk(foo) do v
         value(v) == :length && value(v[1]) == :xs ? g(:lx) : v
       end
IVertex(lx() + length(ys()))
```

(`pre`- 와 `postwalk`의 차이는 순회(traversal)하는 순서에 있다. `@show` 를 통해서 볼 수 있다.)
이 방법으로 그래프에서 찾기(find), 바꾸기(replace) 같은 것을 하거나, 더욱 복잡한 구조 변환에 적용할 수 있다.
그럼 이제 공통 부분 표현식 제거(cse, common subexpression elimination)를 하는 기본적인 방법을
은연 중에 터득했으니 한번 구현해 보자:

```julia-repl
julia> cse(v::IVertex, cache = Dict()) =
         postwalk(x -> get!(cache, x, x), v)
cse (generic function with 2 methods)
```

(역주: `get!`은 사전(Dict)에 없는 키를 저장한다.)
```julia-repl
julia> d = Dict("a"=>1, "b"=>2, "c"=>3);

julia> get!(d, "a", 5)
1

julia> get!(d, "d", 4)
4

julia> d
Dict{String,Int64} with 4 entries:
  "c" => 3
  "b" => 2
  "a" => 1
  "d" => 4
```

그래프의 각 노드가 사전(Dict) 타입에 끌어들이고 값들은 자기 자신을 참조(refer) 한다.
이것으로 결과 그래프의 어느 값이든 `==`는 `===`와 마찬가지인게 (`===`는 identical 비교) 확실해지며, 공통 표현식은 재사용된다.

```julia-repl
julia> foo = @flow length(xs)+length(xs)
IVertex(length(xs) + length(xs))

julia> cse(foo)
IVertex(
eland = length(xs)
eland + eland)
```

일반적으로 DataFlow의 `postwalk`와 같은 고급 연산에 능숙해야 하지만,
어떤 경우에는 처음부터 재귀 알고리즘을 직접 짜야 할 때도 있다.
트리(a tree)에 적용하는 알고리즘과 같아 보이지만
주의 사항이 있는데
(1) 동일한 노드(identical nodes)가 트리에서 여러 번 도달할 수 있다.
(2) 재귀하다 그래프에서 사이클(cyle)이 발생하여 무한 루프에 빠질 수 있다.

잘못하면 악몽처럼 보이지만 사실은 일석이조인 것이;
함수를 memoize 하여 노드를 반복해서 방문하면 재귀를 끝내게 하자.
그리고 재귀하기 *전*에는 현재 호출의 결과를 꼭 캐시(cache) 하도록 한다.

```julia-repl
julia> using DataFlow: value, inputs, thread!

julia> function replace_xs(g, cache = ObjectIdDict())
         # 이 노드를 이미 처리한 경우에는 빠른 종료
         haskey(cache, g) && return cache[g]
         # 새로운 (비어있는) 노드를 만들고 캐시 해 둠
         cache[g] = g′ = typeof(g)(value(g) == :xs ? :foo : value(g))
         # 원래 노드의 입력은 처리하고 결과를 새로운 노드에 추가
         thread!(g′, (replace_xs(v, cache) for v in inputs(g))...)
       end
replace_xs (generic function with 2 methods)

julia> foo = DataFlow.cse(@flow length(xs)+length(xs))
IVertex(
alligator = length(xs)
alligator + alligator)

julia> replace_xs(foo)
IVertex(
alligator = length(xs)
alligator + alligator)
```

여기서는 캐시하는 것을 잊어도 `length(foo)+length(foo)` 하다 망하진 않는데,
다른 경우에는 도중에 멈출 수 있다.

🦉  번역 완료 2018-03-15
