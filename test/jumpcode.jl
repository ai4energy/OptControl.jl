using OptControl, ModelingToolkit
using Test, Statistics, LinearAlgebra


@variables akshdgio[1:10] oxcifvohsdn
@test OptControl.get_name(akshdgio) == "akshdgio"
@test OptControl.get_name(oxcifvohsdn) == "oxcifvohsdn"

@variables t u x
f = x + u
L = 0.5 * u^2
t0 = [1.0]
tf = [0.0]
tspan = (0.0, 1.0)
N = 100
sol = generateJuMPcodes(L, f, x, u, tspan, t0, tf; N=N,writeFilePath="test.jl")
xs = collect(range(tspan[1], tspan[2], length=N))
an = @.(exp(xs)/(1-exp(2))-exp(2)*exp(-xs)/(1 - exp(2)))
res = mean(abs.(an - sol[1][:, 1]))
println("\nres:", res, "\n")
@test res < 0.1

@variables t u x[1:2]
f = [0 1; 0 0] * x + [0, 1] * u
L = 0.5 * u^2
t0 = [1.0, 1.0]
tf = [0.0, 0.0]
tspan = (0.0, 2.0)
N = 100
sol = generateJuMPcodes(L, f, x, u, tspan, t0, tf; N=N,writeFilePath="test.jl")
xs = collect(range(tspan[1], tspan[2], length=N))
an = @.(0.5 * xs^3 - 1.75 * xs^2 + xs + 1)
res = mean(abs.(an - sol[1][:, 1]))
println("\nres:", res, "\n")
@test res < 0.1



# @variables t u x[1:2]
# f = [0 1; 0 0] * x + [0, 1] * u
# L = 0.5 * u^2
# t0 = [1.0, 1.0]
# tf = [0.0, nothing]
# tspan = (0.0, 1.0)
# N = 100
# sol = generateJuMPcodes(L, f, x, u, tspan, t0, tf; N=N)
# xs = collect(range(tspan[1], tspan[2], length=N))
# an = @.(xs^3 - 3.0 * xs^2 + xs + 1)
# res = mean(abs.(an - sol[1][:, 1]))
# println("\nres:", res, "\n")
# @test res < 0.01



@variables t u x[1:2]
f = [0 1; 0 0] * x + [0, 1] * u
L = 0.5 * u^2
t0 = [0.0, 0.0]
tf = [nothing, nothing]
tspan = (0.0, 1.0)
tf_con = x[1] + x[2] - 1.0
N = 100
sol = generateJuMPcodes(L, f, x, u, tspan, t0, tf, nothing, tf_con; N=N)
xs = collect(range(tspan[1], tspan[2], length=N))
an = @.(-1 / 14 * xs^2 * (xs - 6))
res = mean(abs.(an - sol[1][:, 1]))
println("\nres:", res, "\n")
@test res < 0.01


@variables t u x[1:2]
f = [0 1; 0 0] * x + [0, 1] * u
L = 0.5 * u^2
t0 = [1.0, 1.0]
tf = [nothing, nothing]
tspan = (0.0, 2.0)
tf_con = [x[1] + x[2], x[1] - x[2]]
N = 100
sol = generateJuMPcodes(L, f, x, u, tspan, t0, tf, nothing, tf_con; N=N)
xs = collect(range(tspan[1], tspan[2], length=N))
an = @.(0.5 * xs^3 - 1.75 * xs^2 + xs + 1)
res = mean(abs.(an - sol[1][:, 1]))
println("\nres:", res, "\n")
@test res < 0.1


@variables t u[1:2] x[1:2]
f = [0 1; 0 0] * x + [1 0; 0 1] * u
L = 0.5 * (u[1]^2 + u[2]^2)
t0 = [1.0, 1.0]
tf = [0.0, nothing]
tspan = (0.0, 2.0)
N = 100
sol = generateJuMPcodes(L, f, x, u, tspan, t0, tf; N=N)
xs = collect(range(tspan[1], tspan[2], length=N))
an_u2 = @.(9 / 14 * xs - 9 / 7)
res1 = mean(abs.(-9 / 14 .- sol[2][:, 1]))
res2 = mean(abs.(an_u2 - sol[2][:, 2]))
println("\nres1:", res1, "\n", "res2:", res2, "\n")
@test res1 < 0.05 && res2 < 0.05


@variables t u x[1:2]
f = [-1 0; 1 0] * x + [1, 0] * u
L = 0
t0 = [1.0, 0.0]
tf = [nothing, nothing]
tspan = (0.0, 1.0)
N = 100
Φ = x[2]
uub = [1.0]
ulb = [-1.0]
sol = generateJuMPcodes(L, f, x, u, tspan, t0, tf, Φ, nothing;
    N=N, u_ub=uub, u_lb=ulb)
xs = collect(range(tspan[1], tspan[2], length=N))
an = @.(2 * exp(-xs) - 1)
res = mean(abs.(an - sol[1][:, 1]))
println("\nres:", res, "\n")
@test res < 0.01


@variables t u x[1:2]
f = [0 1; -1 0] * x + [0, 1] * u
L = 0.5 * u^2
t0 = [0.0, 1.0]
tf = [0.0, 0.0]
tspan = (0.0, 2.0)
N = 100
sol = generateJuMPcodes(L, f, x, u, tspan, t0, tf; N=N
)
xs = collect(range(tspan[1], tspan[2], length=N))
an = @.(2 / (4 - sin(2)^2) * ((cos(2) * sin(2) - 2) * cos(xs) + sin(2)^2 * sin(xs)))
res = mean(abs.(an - sol[2][:, 1]))
println("\nres:", res, "\n")
@test res < 0.1





