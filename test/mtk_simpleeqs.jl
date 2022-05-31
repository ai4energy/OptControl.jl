using OptControl, ModelingToolkit
using Test

@parameters t
ps = @parameters σ = 1.0 ρ = 1.0 β = 1.0
st = ModelingToolkit.@variables x(t) y(t) z(t)
D = Differential(t)

eqs = [D(x) ~ σ * (y - x),
    D(y) ~ x * (ρ - z) - y,
    D(z) ~ x * y - β * z]

@named sys = ODESystem(eqs, t, st, ps)

L = 0.5 * (β^2 + σ^2 + ρ^2)
t0 = [1.0, 1.0, 1.0]
tf = [0.0, 0.0, 0.0]
tspan = (0.0, 2.0)
N = 100
sol = OptControl.generateMTKcodes(L, sys, states(sys), [σ, ρ, β], tspan, t0, tf;
    N=N)
@test isapprox.(0.0, sol[1][end, :], atol=1.0e-5) == [true, true, true]




@parameters t
ps = @parameters σ = 1.0 ρ = 1.0 β = 1.0
st = ModelingToolkit.@variables x(t) y(t) z(t)
D = Differential(t)

# Define a differential equation
eqs = [D(x) ~ σ * (t - 1) * (y - x),
    D(y) ~ x * (ρ - z) - y,
    D(z) ~ x * y - β * z]

@named sys = ODESystem(eqs, t, st, ps)

L = 0.5 * (β^2 + σ^2 + ρ^2)
t0 = [1.0, 1.0, 1.0]
tf = [0.0, 0.0, 0.0]
tspan = (0.0, 2.0)
N = 100
sol = OptControl.generateMTKcodes(L, sys, states(sys), [σ, ρ, β], tspan, t0, tf;
    N=N)
@test isapprox.(0.0, sol[1][end, :], atol=1.0e-5) == [true, true, true]


