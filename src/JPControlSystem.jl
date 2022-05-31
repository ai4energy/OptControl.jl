function check_system(state, u, tspan::Tuple, t0, tf, state_ub, state_lb, u_ub, u_lb)
    if length(tspan) != 2
        error("tspan errors: length of tspan must be 2, include start and end time")
    end
    if length(t0) != length(state)
        error("t0 errors: length of 't0' must be equal to 'state'")
    end
    if length(tf) != length(state)
        error("tf errors: length of 'tf' must be equal to 'state'")
    end

    if !isequal(state_ub, nothing)
        if length(state_ub) != length(state)
            error("state_ub errors: length of 'state_ub' must be equal to 'state'")
        end
    end

    if !isequal(state_lb, nothing)
        if length(state_lb) != length(state)
            error("state_lb errors: length of 'state_lb' must be equal to 'state'")
        end
    end

    if !isequal(u_ub, nothing)
        if length(u_ub) != length(u)
            error("u_ub errors: length of 'u_ub' must be equal to 'u'")
        end
    end

    if !isequal(u_lb, nothing)
        if length(u_lb) != length(u)
            error("u_lb errors: length of 'u_lb' must be equal to 'u'")
        end
    end

end

function initial_funs(name)
    return "\n#============" * name * "================#\n"
end

function define_model(tol; name)
    str = "\n#========== define model =============#\n"
    str *= "$(name) = Model(Ipopt.Optimizer)\n"
    str *= "set_optimizer_attribute($(name), \"print_level\", 0)\n"
    tol == 1.0E-6 ? nothing : str *= "set_optimizer_attribute($(name), \"acceptable_tol\", $(tol))\n"
    return str
end

function get_name(x)
    if length(x) > 1
        name = string(x[1])
        ind = findnext('[', name, 1)
        return name[1:ind-1]
    else
        return string(x)
    end
end

function define_vars(state::String, u::String, xlen::Int, ulen::Int, N::Int, state_ub, state_lb, u_ub, u_lb)

    str = "\n#========== define variables =============#\n"

    str *= "JuMP.@variable(model,  "
    if !isequal(state_lb, nothing)
        str *= "$(state_lb)[j] <= "
    end
    str *= (state * "[1:$(N), j=1:$(xlen)] ")
    if !isequal(state_ub, nothing)
        str *= "<= $(state_ub)[j])\n"
    else
        str *= ")\n"
    end

    str *= "JuMP.@variable(model,  "
    if !isequal(u_lb, nothing)
        str *= "$(u_lb)[j] <= "
    end
    str *= (u * "[1:$(N), j=1:$(ulen)] ")
    if !isequal(u_ub, nothing)
        str *= "<= $(u_ub)[j])\n"
    else
        str *= ")\n"
    end
    return str

end

function add_boundary_constraint(model_name::String, xlen, t0, tf)
    str = "\n#========== boundary constraint =============#\n"
    str *= "JuMP.@NLconstraint($(model_name), [j = 1:$(xlen)],x[1, j] == $(t0)[j])\n"
    str *= tf isa Vector{Nothing} ? "\n" : "JuMP.@NLconstraint($(model_name), 
    [j = [i for i in 1:$(xlen) if !isequal($(tf)[i],nothing)]],
     x[end, j] == $(tf)[j])\n"
    return str
end

function generate_func(F, x, u, name)
    if isequal(F, nothing)
        return "\n"
    else
        if typeof(F) <: Vector
            func = build_function(F, append!([], x, u))[1]
        else
            func = build_function(F, append!([], x, u))
        end
        return "$(name) = $(func)\n"
    end
end

function generate_disfunc(discretization::String)
    if discretization == "trapezoidal"
        return "discretization_$(discretization) = $(trapezoidal["code"])\n"
    else
        error("discretization method error: please choose rigth discretization methods")
    end
end

function func_index(f_name::String, index::Int, state_name::String, u_name::String)
    return "$(f_name)(append!([],$(state_name)[i+$(index),:],$(u_name)[i+$(index),:]))"
end

function discretize(discretization::String, dt::Float64, f_name::String,
    state_name::String, u_name::String)

    if discretization == "trapezoidal"
        len = 2
        start = 1
        str = "discretization_$(discretization)($(state_name)[i,:], $(dt), i, \n\t"
    end

    for i in 0:len-1
        str *= "$(func_index(f_name, start - i, state_name, u_name)),\n\t"
    end

    str *= ")"

    return str

end

function add_state_constraint(model_name::String, discretization::String, dt::Float64,
    f_name::String, state_name::String, u_name::String, N::Int, xlen::Int)

    discre = discretize(discretization, dt, f_name, state_name, u_name)

    str = "\n#========== state constraint =============#\n"

    str *= "JuMP.@NLconstraint($(model_name), [i = 1:$(N-1), j = 1:$(xlen)],
        $(state_name)[i+1,j] == $(discre)[j])\n"
    return str
end

function add_tf_constraint(model_name::String, f_name::String, state_name::String, u_name::String,)

    str = "\n#========== tf constraint =============#\n"
    str *= "_tfCons_ = $(f_name)(append!([],$(state_name)[end,:],$(u_name)[end,:]))\n"
    str *= "_tfCons_ isa Vector ? JuMP.@NLconstraint($(model_name), 
        [i = 1:length(_tfCons_)], 
        _tfCons_[i] == zeros(length(_tfCons_))[i]) : JuMP.@NLconstraint(
        $(model_name), _tfCons_ == 0.0) \n"
    return str
end

function add_objective(model_name::String, Φ_name, L_name::String,
    state_name::String, u_name::String, N::Int)

    str = "\n#========== objective =============#\n"
    Φ_parts = " Φ_parts =  $(Φ_name)(append!([],$(state_name)[end,:],$(u_name)[end,:]))\n"
    if !isequal(Φ_name, nothing)
        Φ_isadd = " Φ_parts + "
        str *= Φ_parts
    else
        Φ_isadd = " "
    end
    str *= "_sum_ = [$(L_name)(append!([],$(state_name)[i,:],$(u_name)[i,:])) for i in 1:$(N)]\n"
    str *= "JuMP.@NLobjective($(model_name), Min,$(Φ_isadd)sum(_sum_[i] for i in 1:$(N)))\n"
    return str
end

function add_sol(model_name::String, state_name::String, u_name::String)

    str = "\n#================ solve ==================#\n"

    str *= "JuMP.optimize!($(model_name))\n"
    str *= "($(state_name),$(u_name)) = (JuMP.value.($(state_name))[:,:],JuMP.value.($(u_name))[:,:])\n"
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
using OptControl
@variables t u x[1:2]
f = [0 1; 0 0] * x + [0, 1] * u
L = 0.5 * u^2
t0 = [1.0, 1.0]
tf = [0.0, 0.0]
tspan = (0.0, 2.0)
N = 100
sol = generateJuMPcodes(L, f, x, u, tspan, t0, tf; N=N)
```
"""
function generateJuMPcodes(L, F, state, u, tspan, t0, tf, Φ=nothing, tf_constraint=nothing
    ; state_ub=nothing, state_lb=nothing, u_ub=nothing, u_lb=nothing,
    N=1000, discretization="trapezoidal", model_name=nothing, writeFilePath=nothing,
    tolerance=1.0E-6)

    check_system(state, u, tspan, t0, tf, state_ub, state_lb, u_ub, u_lb)
    state_name = get_name(state)
    u_name = get_name(u)
    xlen, ulen = xu_length(state, u)

    L, F, state, u = scalarize_data(L, F, state, u)
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
    codeString *= generate_func(F, state, u, stateFuncName)
    codeString *= generate_func(Φ, state, u, Φ_objectiveFuncName)
    codeString *= generate_func(tf_constraint, state, u, constraintFuncName)

    codeString *= define_model(tolerance; name=model_name)

    codeString *= define_vars(state_name, u_name, xlen,
        ulen, N, state_ub, state_lb, u_ub, u_lb)

    codeString *= add_boundary_constraint(model_name, xlen, t0, tf)

    codeString *= isequal(tf_constraint, nothing) ? "\n" : add_tf_constraint(model_name, constraintFuncName, state_name, u_name)

    dt = (tspan[2] - tspan[1]) / N

    codeString *= add_state_constraint(model_name, discretization,
        dt, stateFuncName, state_name, u_name, N, xlen)

    codeString *= isequal(Φ, nothing) ? add_objective(model_name, nothing,
        L_objectiveFuncName, state_name, u_name, N) : add_objective(model_name, Φ_objectiveFuncName,
        L_objectiveFuncName, state_name, u_name, N)

    codeString *= add_sol(model_name, state_name, u_name)

    isequal(writeFilePath, nothing) ? nothing : write(writeFilePath, codeString)

    codeString = "quote\n$(codeString)\nend\n"
    return eval(eval(Meta.parse(codeString)))
end