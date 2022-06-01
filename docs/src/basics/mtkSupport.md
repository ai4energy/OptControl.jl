# Build State Equations with ModelingToolkit.jl

`OptControl.jl` support ODESystem from ModelingToolkit.jl. ModelingToolkit.jl is very powerful and using ModelingToolkit.jl is strongly recommended. `generateMTKcodes` is the same as `generateJuMPcodes`, but `f` is form of  **ODESystem** from ModelingToolkit.jl.

```@docs
generateMTKcodes
```

## Example 1: MTK Equations

A example from [ModelingToolkit.jl document](https://mtk.sciml.ai/stable/systems/ODESystem/),

If we want to transform it to control problem, we treat $σ,ρ,β$ as control variables and $x,y,z$ as state variables( It's a math experiment, and it's meaningless in physics). We make $x,y,z$ change as we want by $σ,ρ,β$ with minimun cost $0.5 * (β^2 + σ^2 + ρ^2)$.

Control $x,y,z$ from $[1.0,1.0,1.0]$ to $[0.0,0.0,0.0]$ in 2 seconds.

```@example
using OptControl,ModelingToolkit, Test
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

@test isapprox.(0.0, sol[1][end, :], atol=1.0e-10) == [true, true, true]
```

## Example 2: RC model

This is *Acausal Component-Based Modeling the RC Circuit* from [ModelingToolkit.jl document](https://mtk.sciml.ai/stable/tutorials/acausal_components/)

After defining components, solve the give the initial value and problem.

```julia
sys = structural_simplify(rc_model)
u0 = [
      capacitor.v => 0.0
     ]
prob = ODAEProblem(sys, u0, (0, 10.0))
sol = solve(prob, Tsit5())
plot(sol)
```

To be a control problem that make $capacitor_+v$ change as we want by control variable $source_+V$, we assume parameter $source_+V$ is changeable.

```@example
using OptControl, ModelingToolkit, Test

@variables t
@connector function Pin(; name)
    sts = @variables v(t) = 1.0 i(t) = 1.0 [connect = Flow]
    ODESystem(Equation[], t, sts, []; name=name)
end

function Ground(; name)
    @named g = Pin()
    eqs = [g.v ~ 0]
    compose(ODESystem(eqs, t, [], []; name=name), g)
end

function OnePort(; name)
    @named p = Pin()
    @named n = Pin()
    sts = @variables v(t) = 1.0 i(t) = 1.0
    eqs = [
        v ~ p.v - n.v
        0 ~ p.i + n.i
        i ~ p.i
    ]
    compose(ODESystem(eqs, t, sts, []; name=name), p, n)
end

function Resistor(; name, R=1.0)
    @named oneport = OnePort()
    @unpack v, i = oneport
    ps = @parameters R = R
    eqs = [
        v ~ i * R
    ]
    extend(ODESystem(eqs, t, [], ps; name=name), oneport)
end

function Capacitor(; name, C=1.0)
    @named oneport = OnePort()
    @unpack v, i = oneport
    ps = @parameters C = C
    D = Differential(t)
    eqs = [
        D(v) ~ i / C
    ]
    extend(ODESystem(eqs, t, [], ps; name=name), oneport)
end

function ConstantVoltage(; name, V=1.0)
    @named oneport = OnePort()
    @unpack v = oneport
    ps = @parameters V = V
    eqs = [
        V ~ v
    ]
    extend(ODESystem(eqs, t, [], ps; name=name), oneport)
end

R = 1.0
C = 1.0
V = 1.0
@named resistor = Resistor(R=R)
@named capacitor = Capacitor(C=C)
@named source = ConstantVoltage(V=V)
@named ground = Ground()

rc_eqs = [
    connect(source.p, resistor.p)
    connect(resistor.n, capacitor.p)
    connect(capacitor.n, source.n)
    connect(capacitor.n, ground.g)
]

@named _rc_model = ODESystem(rc_eqs, t)
@named rc_model = compose(_rc_model,
    [resistor, capacitor, source, ground])

sys = structural_simplify(rc_model)

L = 0.5 * (source.V^2)
t0 = [1.0]
tf = [3.0]
tspan = (0.0, 1.0)
N = 100
sol = OptControl.generateMTKcodes(L, sys, states(sys), [source.V], tspan, t0, tf;N=N)

@test isapprox.(3.0, sol[1][end, :], atol=1.0e-10) == [true]
```

To solve the control problem, don't need to solve ODEs or DAEs but define some control arguments after structure simplied.

In control problem, `state`s are from state of ODESystem, and `u`s are from parameters of ODESystem. States in ODESystem must be **all** passed to `generateMTKcodes`, and some of parameters can be used as control variables just like example above. You can use [accessor functions](https://mtk.sciml.ai/stable/basics/AbstractSystem/) `states(sys)` and `parameters(sys)` to see them.
