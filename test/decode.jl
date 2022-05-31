using OptControl
using Test, Statistics, LinearAlgebra
using Symbolics
using Statistics


@variables t u x[1:2]
f = [0 1; 0 0] * x + [0, 1] * u
L = 0.5 * u^2
t0 = [1.0, 1.0]
tf = [0.0, 0.0]
tspan = (0.0, 2.0)
sol = generateDEcodes(L, f, x, u, tspan, t0, tf)
nu = [sol.u[i][1] for i in 1:length(sol.u)]
xs = collect(range(tspan[1], tspan[2], length=length(sol.u)))
an = @.(0.5 * xs^3 - 1.75 * xs^2 + xs + 1)
res = mean(abs.(an - nu))
println("\nres:", res, "\n")
@test res < 0.1


@variables t u x[1:2]
f = [0 1; 0 0] * x + [0, 1] * u
L = 0.5 * u^2
t0 = [1.0, 1.0]
tf = [0.0, nothing]
tspan = (0.0, 1.0)
sol = generateDEcodes(L, f, x, u, tspan, t0, tf)
nu = [sol.u[i][1] for i in 1:length(sol.u)]
xs = collect(range(tspan[1], tspan[2], length=length(sol.u)))
an = @.(xs^3 - 3.0 * xs^2 + xs + 1)
res = mean(abs.(an - nu))
println("\nres:", res, "\n")
@test res < 0.2


@variables t u[1:2] x[1:2]
f = [0 1; 0 0] * x + [1 0; 0 1] * u
L = 0.5 * (u[1]^2 + u[2]^2)
t0 = [1.0, 1.0]
tf = [0.0, nothing]
tspan = (0.0, 2.0)
N = 100
sol = generateDEcodes(L, f, x, u, tspan, t0, tf)
nu1 = [sol.u[i][5] for i in 1:length(sol.u)]
nu2 = [sol.u[i][6] for i in 1:length(sol.u)]
xs = collect(range(tspan[1], tspan[2], length=length(sol.u)))
an_u2 = @.(9 / 14 * xs - 9 / 7)
res1 = mean((-9 / 14 .- nu1).^2)
res2 = mean((an_u2 - nu2).^2)
println("\nres1:", res1, "\n", "res2:", res2, "\n")
@test res1 < 0.2 && res2 < 0.2
