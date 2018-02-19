# Flux: 줄리아 머신 러닝 라이브러리

Flux는 머신러닝을 위한 라이브러리.
"배터리-포함(batteries-included, 제품의 완전한 유용성을 위해 필요한 모든 부품을 함께 제공한다는 소프트웨어쪽 용어)" 많은 유용한 도구를 제공.
줄리아 언어를 풀파워(full power)로 사용할 수 있다. 전체 스택을 줄리아 코드로 구현함.
[GPU 커널](https://github.com/FluxML/CuArrays.jl)도 가능하고, 개별 파트를 개인 취향에 맞게 조작할 수 있다.

# 설치

[줄리아 0.6.0 이상](https://julialang.org/downloads/)을 아직 안깔았으면 설치.

```julia
Pkg.add("Flux")
# 선택인데 추천
Pkg.update() # 패키지를 최신 버전으로 업뎃
Pkg.test("Flux") # 설치 똑바로 된건가 확인해 봄
```

[기본적인 것](models/basics.md) 부터 시작하자.
[동물원 모델(model zoo)](https://github.com/FluxML/model-zoo/)은 여러가지 공통 모델을 다루는데 그걸로 시작해도 좋다.
