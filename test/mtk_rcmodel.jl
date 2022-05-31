using OptControl, ModelingToolkit

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
sol = OptControl.generateMTKcodes(L, sys, states(sys), [source.V], tspan, t0, tf;
    N=N)

@test isapprox.(3.0, sol[1][end, :], atol=1.0e-5) == [true]