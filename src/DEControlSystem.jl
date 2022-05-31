function check_system(state, tspan::Tuple, t0, tf)
    if length(tspan) != 2
        error("tspan errors: length of tspan must be 2, include start and end time")
    end
    if length(t0) != length(state)
        error("t0 errors: length of 't0' must be equal to state")
    end
    if length(tf) != length(state)
        error("tf errors: length of 'tf' must be equal to state")
    end
end

function get_λ(len)
    @variables λ[1:len]
    return scalarize(λ)
end

function get_Hamilton(L, F, λ)
    return L + λ' * F
end

function get_dλ(H, state)
    return -jacobian([H], state)
end

function get_dHdu(H, u)
    if typeof(u) <: Vector
        return jacobian([H], u)
    else
        return jacobian([H], [u])
    end
end

function generate_DEfunc(F, dλ, dHdu, x, λ, u, stateFuncName)
    func = build_function(append!([], F, dλ, dHdu), append!([], x, λ, u))[2]
    func.args[1] = :(($(func.args[1].args...), p, t))
    return string("$(stateFuncName) = $(string(func))\n")
end

function generate_BCfunc(Φ, t0, tf, state, λ, xlen, boundaryConditionFunc)

    function generate_BoundaryCondition(Φ, t0, tf, state, λ, xlen)
        func_t0 = [state[i] - t0[i] for i in 1:xlen]
        func_tf = []
        for i in 1:xlen
            if isequal(tf[i], nothing)
                append!(func_tf, λ[i] - derivative(Φ, state[i]))
            else
                append!(func_tf, state[i] - tf[i])
            end
        end
        func_t0 = build_function(func_t0, state)[1]
        func_tf = build_function(func_tf, append!([], state, λ))[1]
        return string(func_t0), string(func_tf)
    end

    t0_func, tf_func = generate_BoundaryCondition(Φ, t0, tf, state, λ, xlen)
    t0_name = "f_t0"
    tf_name = "f_tf"
    str = "function (residual, u, p, t)\n"
    str *= t0_name * " = " * t0_func * "\n"
    str *= tf_name * " = " * tf_func * "\n"
    str *= "residual[1:$(xlen)]=" * t0_name * "(u[1][1:$(xlen)])\n"
    str *= "residual[$(xlen+1):$(2*xlen)]=" * tf_name * "(u[end][1:$(2*xlen)])\n"
    str *= "end\n"
    return "$(boundaryConditionFunc) = $(str)"
end


function generate_ODEFunction(f::String, xlen, ulen, ODEfuncName)
    str = "M = diagm($(xlen) * 2 + $(ulen), $(xlen) * 2 + $(ulen), [1.0 for i in 1:2*$(xlen)])\n"
    str *= "$(ODEfuncName) = ODEFunction($(f), mass_matrix=M)"
    return " $(str)\n"
end

function get_Guess(xlen, ulen, guess)
    if isequal(guess, nothing)
        return "guess = ones(2 * $(xlen) + $(ulen))\n"
    else
        return "guess = $(guess)\n"
    end
end

function add_sol(odefuncName, boundaryConditionFuncName, tspan, dt)
    str = "bvp = BVProblem($(odefuncName), $(boundaryConditionFuncName), guess,$(tspan), [])\n"
    str *= "sol = DifferentialEquations.solve(bvp, GeneralMIRK4(), dt=$(dt), reltol=1e-8, abstol=1e-8)"
end


"""
$(TYPEDSIGNATURES)

`generateDEcodes` will generate the solution code that using `DifferentialEquations.jl` to solve problem

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
- `dt`: dt of BVProblem, default: 0.1
- `guess`: initial value of BVProblem, default: 1.0. length of guess must be equal to (2*length(state)+length(u))
- `writeFilePath`: path of generated code, default: nothing

Example:

```julia
using OptControl
@variables t u x[1:2]
f = [0 1; 0 0] * x + [0, 1] * u
L = 0.5 * u^2
t0 = [1.0, 1.0]
tf = [0.0, 0.0]
tspan = (0.0, 2.0)
sol = generateDEcodes(L, f, x, u, tspan, t0, tf)
```
"""
function generateDEcodes(L, F, state, u, tspan, t0, tf, Φ=nothing, dt=0.1;
    guess=nothing, writeFilePath=nothing)
    check_system(state, tspan, t0, tf)

    L, F, state, u = scalarize_data(L, F, state, u)
    Φ = isequal(Φ, nothing) ? 0 : scalarize(Φ)

    xlen, ulen = xu_length(state, u)
    λ = get_λ(xlen)
    H = get_Hamilton(L, F, λ)
    dλ = get_dλ(H, state)
    dHdu = get_dHdu(H, u)

    stateFuncName = "statesFunc"
    boundaryConditionFuncName = "boundaryConditionFunc"
    odefuncName = "odefunc"
    codeString = initial("DifferentialEquations")
    codeString *= initial_funs("Function Parts")
    codeString *= generate_DEfunc(F, dλ, dHdu, state, λ, u, stateFuncName)
    codeString *= generate_BCfunc(Φ, t0, tf, state, λ, xlen, boundaryConditionFuncName)
    codeString *= initial_funs("End Function Parts")

    codeString *= generate_ODEFunction(stateFuncName, xlen, ulen, odefuncName)
    codeString *= get_Guess(xlen, ulen, guess)
    codeString *= add_sol(odefuncName, boundaryConditionFuncName, tspan, dt)

    isequal(writeFilePath, nothing) ? nothing : write(writeFilePath, codeString)

    codeString = "quote\n$(codeString)\nend\n"
    return eval(eval(Meta.parse(codeString)))
end

