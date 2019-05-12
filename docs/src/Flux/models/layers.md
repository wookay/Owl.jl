## 기본 레이어

거의 모든 신경망(neural networks)의 토대를 다음의 핵심 레이어로 구성한다.

```@docs
Chain
Dense
```

## Convolution and Pooling Layers

These layers are used to build convolutional neural networks (CNNs).

```@docs
Conv
MaxPool
MeanPool
DepthwiseConv
ConvTranspose
```

## 순환 레이어(Recurrent Layers)

위의 핵심 레이어와 함께,
시퀀스 데이터(다른 종류의 구조화된 데이터)를 처리할 때 사용할 수 있다.

```@docs
RNN
LSTM
GRU
Flux.Recur
```

## Other General Purpose Layers
These are marginally more obscure than the Basic Layers.
But in contrast to the layers described in the other sections are not readily grouped around a particular purpose (e.g. CNNs or RNNs).

```@docs
Maxout
```

## 활성 함수(Activation Functions)

모델의 레이어 중간에 비선형성(Non-linearities)을 갖을 때 사용한다.
함수의 대부분은 [NNlib](https://github.com/FluxML/NNlib.jl)에 정의되어 있고
Flux에서 기본적으로 사용할 수 있다.

특별한 언급이 없으면 활성 함수는 보통 스칼라(scalars) 값을 처리한다.
배열에 적용하려면 `σ.(xs)`, `relu.(xs)` 처럼 .으로 브로드캐스팅 해 주자.

```@docs
σ
relu
leakyrelu
elu
swish
```

## 정상화(Normalisation) & 정규화(Regularisation)

이 레이어들은 네트워크의 구조에는 영향을 주지 않으면서
훈련 시간(training times)의 개선 그리고 오버피팅(overfitting, 과적합)을 줄여 준다.

```@docs
Flux.testmode!
BatchNorm
Dropout
AlphaDropout
LayerNorm
GroupNorm
```
