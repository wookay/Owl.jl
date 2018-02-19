using Base.Test
using Flux

W = # rand(2, 5)
[0.857747   0.291713  0.179873  0.938979  0.51022
 0.0852085  0.977716  0.246164  0.460672  0.772312]

b = # rand(2)
[0.663369
 0.132996]

predict(x) = W*x .+ b
loss(x, y) = sum((predict(x) .- y).^2)

x, y = # rand(5), rand(2)
([0.496864, 0.947507, 0.874288, 0.251528, 0.192234], [0.901991, 0.0802404])

@test loss(x, y) ≈ 3.166070569359008
