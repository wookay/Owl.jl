module test_flux_basic

using Test
using Flux.Tracker

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

W = param(W)
b = param(b)
l = loss(x, y)

@test W isa TrackedArray
@test b isa TrackedArray
@test l isa Tracker.TrackedReal
@test l.tracker.grad == 0

@test W.grad == [0.0  0.0  0.0  0.0  0.0
                 0.0  0.0  0.0  0.0  0.0]

back!(l)
@test W.grad ≈ [0.949491  1.81065  1.67074  0.480662  0.367353
                1.49163   2.84449  2.62468  0.755107  0.577102] atol=0.00001

W.data .-= 0.1(W.grad)
@test W.data ≈ [0.762798   0.110648   0.0127994  0.890913  0.473485
               -0.0639541  0.693267  -0.0163043  0.385161  0.714602] atol=0.00001

end # module test_flux_basic
