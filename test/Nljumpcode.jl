using OptControl, ModelingToolkit
using Test, LinearAlgebra

@variables t u x
f = exp(x) + u
L = u^2
t0 = [1.0]
tf = [0.0]
tspan = (0.0, 2.0)
N = 100
sol = generateNLJuMPcodes(L, f, x, u, tspan, t0, tf; N=N)

@test isapprox.(0.0, sol[1][end, :], atol=1.0e-5) == [true for i in 1:length(sol[1][end, :])]

@variables t u x[1:2]
f = [exp(x[1]) + cos(x[2]), sin(x[1]) + x[2]] + [0, 1] * u
L = u^2
t0 = [1.0, 1.0]
tf = [0.0, 0.0]
tspan = (0.0, 2.0)
N = 100
sol = generateNLJuMPcodes(L, f, x, u, tspan, t0, tf; N=N)

@test isapprox.(0.0, sol[1][end, :], atol=1.0e-5) == [true for i in 1:length(sol[1][end, :])]

@variables t u x[1:2]
f = [0, x[1]^2] + [u, u^2]
L = 0
t0 = [1.0, 0.0]
tf = [nothing, nothing]
tspan = (0.0, 1.0)
Φ = x[2]
N = 10
sol = generateNLJuMPcodes(L, f, x, u, tspan, t0, tf, Φ, nothing; N=N)
@test true
