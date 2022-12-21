function generate_NLfunc(F, name, state, u, xlen)
    func = generate_func(F, state, u, name, 2)
    inside_func = "_$(func)"
    str = "$(name) = function (x, u, t)\nout = Vector{Any}(nothing, $xlen)
    $(inside_func)\n_$(name)(out,append!([],x,u))\nreturn out\nend\n"
    return str
end

"""
$(TYPEDSIGNATURES)

`generateNLJuMPcodes` is used to solve Nonlinear control problem

A general form of optimal control problem:

```math
min (\\Phi(\\boldsymbol{x}(t_f),t_f)+\\int_{t_0}^{t_f} 
L[\\boldsymbol{x}(t),\\boldsymbol{u}(t),t]dt) \\\\
s.t. \\hspace{0.4cm} \\dot{\\boldsymbol{x}} =f[\\boldsymbol{x}(t),\\boldsymbol{u}(t),t]
```

args:

- `L`: above L
```math
L[\\boldsymbol{x}(t),\\boldsymbol{u}(t),t]
```
- `F`: above f
```math
f[\\boldsymbol{x}(t),\\boldsymbol{u}(t),t]
```
- `state`: states(variable) in `F`
- `u`: control variable u in `F`
- `tspan`: time field
- `t0`: initial value at `tspan[1]`, length of `t0` must be equal to length of state
- `tf`: final(end) value at `tspan[2]`, length of `tf` must be equal to length of state
- `Φ`: above Φ, default: nothing
```math
\\Phi(\\boldsymbol{x}(t_f),t_f)
```
- `tf_constraint`: special requirements for end time, default: nothing. Example:
```math
x_{1}+x_{2}=0
```
- `state_ub`: state's upper limit, length of `state_ub` must be equal to length of state, default: nothing
- `state_lb`: state's lower limit, length of `state_lb` must be equal to length of state, default: nothing
- `u_ub`: u's upper limit, length of `u_ub` must be equal to length of u, default: nothing
- `u_lb`: u's lower limit, length of `u_lb` must be equal to length of u, default: nothing
- `N`: Number of discrete, default: 1000
```math
dt = (endTime - startTime) / N
```
- `discretization`: discretization methods, default: "trapezoidal"
- `model_name`: name of JuMP model, default: "model"
- `writeFilePath`: path of generated code, default: nothing
- `tolerance`: acceptable_tol of Ipopt, default: 1.0e-6

Example:

```julia
using OptControl,ModelingToolkit
@variables t u x
f = exp(x) + u
L = 0.5 * u^2
t0 = [1.0]
tf = [0.0]
tspan = (0.0, 2.0)
N = 100
sol = generateNLJuMPcodes(L, f, x, u, tspan, t0, tf; N=N)
```
"""
function generateNLJuMPcodes(L, F, state, u, tspan, t0, tf, Φ=nothing, tf_constraint=nothing
    ; state_ub=nothing, state_lb=nothing, u_ub=nothing, u_lb=nothing,
    N=1000, discretization="trapezoidal", model_name=nothing, writeFilePath=nothing,
    tolerance=1.0E-6)

    check_system(state, u, tspan, t0, tf, state_ub, state_lb, u_ub, u_lb)

    state_name = get_name(state)
    u_name = get_name(u)
    xlen, ulen = xu_length(state, u)

    L, state, u = scalarize_data(L, state, u)
    Φ = isequal(Φ, nothing) ? Φ : scalarize(Φ)
    tf_constraint = isequal(tf_constraint, nothing) ? tf_constraint : scalarize(tf_constraint)

    stateFuncName = "F_statesFunc"
    Φ_objectiveFuncName = "Φ_objectiveFunc"
    L_objectiveFuncName = "L_objectiveFunc"
    constraintFuncName = "tf_ConstraintFunc"

    if isequal(model_name, nothing)
        model_name = "model"
    end

    codeString = initial("JuMP")

    codeString *= initial_funs("Function Parts")
    codeString *= generate_disfunc(discretization)
    codeString *= generate_func(L, state, u, L_objectiveFuncName)
    codeString *= generate_NLfunc(F, stateFuncName, state, u, xlen)
    codeString *= generate_func(Φ, state, u, Φ_objectiveFuncName)
    codeString *= generate_func(tf_constraint, state, u, constraintFuncName)

    codeString *= define_model(tolerance; name=model_name)

    codeString *= define_vars(state_name, u_name, xlen,
        ulen, N, state_ub, state_lb, u_ub, u_lb)

    codeString *= add_boundary_constraint(model_name, xlen, t0, tf)

    codeString *= isequal(tf_constraint, nothing) ? "\n" : add_tf_constraint(model_name, constraintFuncName, state_name, u_name)

    dt = (tspan[2] - tspan[1]) / N

    codeString *= add_NL_stateconstraint(model_name, discretization,
        dt, stateFuncName, state_name, u_name, N, xlen, ulen)

    codeString *= isequal(Φ, nothing) ? add_objective(model_name, nothing,
        L_objectiveFuncName, state_name, u_name, N) : add_objective(model_name, Φ_objectiveFuncName,
        L_objectiveFuncName, state_name, u_name, N)

    codeString *= add_sol(model_name, state_name, u_name)

    isequal(writeFilePath, nothing) ? nothing : write(writeFilePath, codeString)

    codeString = "quote\n$(codeString)\nend\n"
    return eval(eval(Meta.parse(codeString)))
end
