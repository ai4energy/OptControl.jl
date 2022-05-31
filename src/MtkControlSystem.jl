function generate_ODEfunc(F, name, paras, us, xlen)
    u_vect = "["
    for para in paras
        u_index = findfirst(isequal.(para, us))
        if isequal(u_index, nothing)
            u_vect *= (string(getmetadata(para, Symbolics.VariableDefaultValue)) * ",")
        else
            u_vect *= "u[$(u_index)],"
        end
    end
    u_vect *= "]"
    func = generate_function(F)[2]
    inside_func = "_$(name) = $(func)"
    str = "$(name) = function (x, u, t)\nout = Vector{Any}(nothing, $xlen)
    $(inside_func)\n_$(name)(out,x,$(u_vect),t)\nreturn out\nend"
    return str
end

function check_defaults(paras)
    for para in paras
        if !hasmetadata(para, Symbolics.VariableDefaultValue)
            error("default error: $(para) don't have a default value")
        end
    end
end

function ode_func_index(f_name::String, index::Int, state_name::String, u_name::String, dt)
    return "$(f_name)($(state_name)[i+$(index),:],$(u_name)[i+$(index),:],(i-1+$(index))*$(dt))"
end

function NL_discretize(dt::Float64, state_name::String, u_name::String, len::Int, start::Int)

    str = "_args = append!([], x[i, :], $dt, i,\n"
    for i in 0:len-1
        str *= "$(state_name)[i+$(start-i),:],$(u_name)[i+$(start-i),:],(i-1+$(start-i))*$(dt),\n"
    end
    str *= ")\n"

    return str

end

function add_func_foo(f_name::String, discretization::String, xlen::Int, ulen::Int, discre_N::Int)
    str = "function foo(args...)\n"
    str *= "return discretization_$discretization(append!([],args[1:$xlen]), args[$(xlen+1)], args[$(xlen+2)],\n"
    su = xlen + 2
    for i in 1:discre_N
        str *= "$f_name(args[$(su+1):$(su+xlen)], args[$(su+xlen+1):$(su+xlen+ulen)], args[$(su+xlen+ulen+1)]),\n"
        su += (xlen + ulen + 1)
    end
    str *= ")\nend\n"
    return str
end

# function add_func_memoize(xlen::Int)
#     str = "function memoize(foo::Function, n_outputs::Int)
#     last_x, last_f = nothing, nothing
#     function foo_i(i, x...)
#         if x != last_x
#             last_x, last_f = x, foo(x...)
#         end
#         return last_f[i]
#     end
#     return [(x...) -> foo_i(i, x...) for i = 1:n_outputs]
# end
# memoized_foo = memoize(foo, $xlen)\n"
#     return str
# end

function add_func_memoize(xlen::Int)
    str = "\n"
    for i in 1:xlen
        str *= "foo_$i(args...) = foo(args...)[$i]\n"
    end
    return str
end

function add_func_register(model_name::String, xlen::Int, ulen::Int, discre_N::Int)
    str = "\n"
    dim = discre_N * (xlen + ulen + 1) + xlen + 2
    for i in 1:xlen
        str *= "register($model_name, :foo_$i, $dim, foo_$i; autodiff=true)\n"
        #str *= "register($model_name, :foo_$i, $dim, memoized_foo[$i]; autodiff=true)\n"
    end
    return str
end

function add_register_part(model_name::String, discretization::String, f_name::String,
    xlen::Int, ulen::Int, discre_N::Int)

    str = "\n#========== register NLfunction ===============#\n"
    str *= add_func_foo(f_name, discretization, xlen, ulen, discre_N)
    str *= add_func_memoize(xlen)
    str *= add_func_register(model_name, xlen, ulen, discre_N)

end


function add_NL_stateconstraint(model_name::String, discretization::String, dt::Float64,
    f_name::String, state_name::String, u_name::String, N::Int, xlen::Int, ulen::Int)

    discre = eval(Symbol(discretization))

    str = add_register_part(model_name, discretization, f_name, xlen, ulen, discre["len"])

    str *= "\n#========== state constraint =============#\n"
    str *= "for i in 1:$(N-1)\n"
    str *= NL_discretize(dt, state_name, u_name,
        discre["len"], discre["start"])
    for i in 1:xlen
        str *= "JuMP.@NLconstraint($model_name, x[i+1, $i] == foo_$i(_args...))\n"
    end

    str *= "end\n"

    return str
end

"""
$(TYPEDSIGNATURES)

`generateJuMPcodes` will generate the solution code that using `JuMP.jl` to solve problem

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
- `F`: above f, in the form of `ModelingToolkit.AbstractSystem`
```math
f[\\boldsymbol{x}(t),\\boldsymbol{u}(t),t]
```
- `state`: states(variable) in `F`, from states of `ModelingToolkit.ODESystem`
- `u`: control variable u in `F`, from parameters of `ModelingToolkit.ODESystem`
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
- `u_ub`: u's upper limit, length of `state_ub` must be equal to length of u, default: nothing
- `u_lb`: u's lower limit, length of `state_lb` must be equal to length of u, default: nothing
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
@parameters t
ps = @parameters σ = 1.0 ρ = 1.0 β = 1.0
st = @variables x(t) y(t) z(t)
D = Differential(t)

# Define a differential equation
eqs = [D(x) ~ σ * (y - x),
    D(y) ~ x * (ρ - z) - y,
    D(z) ~ x * y - β * z]

@named sys = ODESystem(eqs, t, st, ps)
# toexpr(eqs)
sys = structural_simplify(sys)
L = 0.5 * (x^2 + y^2 + β^2)
t0 = [1.0, 1.0, 1.0]
tf = [0.0, 0.0, 0.0]
tspan = (0.0, 2.0)
N = 100
sol = OptControl.generateMTKcodes(L, sys, states(sys), [β], tspan, t0, tf;
    N=N, writeFilePath="test.jl")
```
"""
function generateMTKcodes(L, F::ModelingToolkit.AbstractSystem, state, u, tspan, t0, tf, Φ=nothing, tf_constraint=nothing
    ; state_ub=nothing, state_lb=nothing, u_ub=nothing, u_lb=nothing,
    N=1000, discretization="trapezoidal", model_name=nothing, writeFilePath=nothing,
    tolerance=1.0E-6)

    check_system(state, u, tspan, t0, tf, state_ub, state_lb, u_ub, u_lb)
    paras = parameters(F)
    check_defaults(paras)

    state_name = "x"
    u_name = "u"
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
    codeString *= generate_ODEfunc(F, stateFuncName, paras, u, xlen)
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
