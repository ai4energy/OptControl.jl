struct SimpleControlSystem
    Loss
    eqs
    variables::Vector{Num}
    tspan
    N::Int
    t0
    tf
    ub
    lb
end

mutable struct JumpCode
    modelname::String
    varsname::Vector{String}
    varslen::Vector{Int}
    str::String
end

function SimpleControlSystem(Loss, eqs, variables, tspan, N=1000, t0=nothing, tf=nothing)
    return SimpleControlSystem(Loss, eqs, variables, tspan, N, t0, tf, nothing, nothing)
end

function get_string_vars(jumpcode, system::SimpleControlSystem)
    vars = Symbolics.get_variables(system.eqs)
    if typeof(system.eqs) <: Num
        system.varsname = union(system.varsname,
            [string(i) for i in Symbolics.get_variables(system.eqs)])
    elseif typeof(system.eqs) <: Vector{Num}
        system.varsname = union(system.varsname,
            [string(i) for j in Symbolics.get_variables(system.eqs) for i in j])
    end

end

function add_end_constraint(jumpcode, system)

end

function add_init_constraint(jumpcode, system)

end

function add_state_constraint(jumpcode, system)

end

function add_objective(jumpcode, system)

end

function add_solution(jumpcode, system)

end

function Solve(model::String, system)

    codestring = JumpCode(model, Vector{String}([]), Vector{Int64}([]), "\n")

    loss_function = Symbolics.build_function(system.Loss)[1]
    eqs_function = Symbolics.build_function(system.eqs)[1]

end


