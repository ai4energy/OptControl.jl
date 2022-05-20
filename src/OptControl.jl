module OptControl
using Symbolics
using LinearAlgebra
using DifferentialEquations

scalarize = Symbolics.scalarize

include("SimpleControlSystem.jl")
include("DEControlSystem.jl")

export SimpleControlSystem
export DEControlSystem
export generate_funcs,Solve,scalarize

end
