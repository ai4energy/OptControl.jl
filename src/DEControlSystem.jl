struct funcs
    DEfuncs
    BCfuncs
    guess
    tspan
    dt
end

function check_system(state, tspan, t0, tf)
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

function get_data(Φ, L, F, state, u)
    return (scalarize(Φ),
        scalarize(L),
        scalarize(F),
        scalarize(state),
        scalarize(u))
end

function xu_length(state, u)
    return (length(state), length(u))
end

function get_λ(len)
    Symbolics.@variables λ[1:len]
    return scalarize(λ)
end

function get_Hamilton(L, F, λ)
    return L + λ' * F
end

function get_dλ(H, state)
    return -Symbolics.jacobian([H], state)
end

function get_dHdu(H, u)
    if typeof(u) <: Vector
        return Symbolics.jacobian([H], u)
    else
        return Symbolics.jacobian([H], [u])
    end
end

function generate_DEfunc(F, dλ, dHdu, x, λ, u)
    func = Symbolics.build_function(append!([], F, dλ, dHdu), append!([], x, λ, u))[2]
    func.args[1] = :(($(func.args[1].args...), p, t))
    return eval(func)
end

function generate_BCfunc(Φ, t0, tf, state, λ, xlen=length(state))

    function generate_BoundaryCondition(Φ, t0, tf, state, λ, xlen=length(state))
        func_t0 = [state[i] - t0[i] for i in 1:xlen]
        func_tf = []
        for i in 1:xlen
            if isequal(tf[i], nothing)
                append!(func_tf, λ[i] - Symbolics.derivative(Φ, state[i]))
            else
                append!(func_tf, state[i] - tf[i])
            end
        end
        func_t0 = Symbolics.build_function(func_t0, state)[1]
        func_tf = Symbolics.build_function(func_tf, append!([], state, λ))[1]
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
    str *= "end"
    return eval(Meta.parse(str))
    
end


function get_ODEFunction(f, xlen, ulen)
    M = diagm(xlen * 2 + ulen, xlen * 2 + ulen, [1.0 for i in 1:2*xlen])
    return ODEFunction(f, mass_matrix=M)
end

function get_Guess(xlen, ulen)
    return ones(2 * xlen + ulen)
end

function generate_funcs(Φ, L, F, state, u, tspan, t0, tf, dt=0.1, guess=nothing)
    check_system(state, tspan, t0, tf)
    Φ, L, F, state, u = get_data(Φ, L, F, state, u)
    xlen, ulen = xu_length(state, u)
    λ = get_λ(xlen)
    H = get_Hamilton(L, F, λ)
    dλ = get_dλ(H, state)
    dHdu = get_dHdu(H, u)
    f = generate_DEfunc(F, dλ, dHdu, state, λ, u)
    bc = generate_BCfunc(Φ, t0, tf, state, λ, xlen)
    f = get_ODEFunction(f, xlen, ulen)
    if isequal(guess, nothing)
        guess = get_Guess(xlen, ulen)
    end
    return funcs(f, bc, guess, tspan, dt)
end

function Solve(fun::funcs)
    bvp1 = BVProblem(fun.DEfuncs, fun.BCfuncs, fun.guess, fun.tspan, [])
    return DifferentialEquations.solve(bvp1, GeneralMIRK4(), dt=fun.dt)
end


