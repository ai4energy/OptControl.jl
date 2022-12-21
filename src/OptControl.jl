module OptControl
using ModelingToolkit
using LinearAlgebra
import JuMP
using DifferentialEquations
using DocStringExtensions

jacobian = ModelingToolkit.Symbolics.jacobian
scalarize = ModelingToolkit.Symbolics.scalarize
derivative = ModelingToolkit.Symbolics.derivative
build_function = ModelingToolkit.build_function

function scalarize_data(args...)
    return (scalarize(arg) for arg in args)
end

function checkPkg(pkgName)
    if pkgName == "JuMP"
        pkgNeeds = "[\"JuMP\", \"Ipopt\", \"ModelingToolkit\"]"
    else
        pkgNeeds = "[\"DifferentialEquations\", \"ModelingToolkit\"]"
    end
    return "
    using Pkg
    pkgNeeds = $(pkgNeeds)
    alreadyGet = keys(Pkg.project().dependencies)
    toAdd = [package for package in pkgNeeds if package ∉ alreadyGet]
    isempty(toAdd) ? nothing : Pkg.add(toAdd)\n"
end

function initial(pkgName)
    jumpcode = "$(checkPkg(pkgName))\nusing ModelingToolkit,Ipopt,JuMP\n"
    decode = "$(checkPkg(pkgName))\nusing ModelingToolkit,DifferentialEquations,LinearAlgebra\n"
    if pkgName == "JuMP"
        return jumpcode
    else
        return decode
    end
end

function xu_length(state, u)
    return (length(state), length(u))
end

include("discretization.jl")
include("JPControlSystem.jl")
include("DEControlSystem.jl")
include("MtkControlSystem.jl")
include("NLJpControlSystem.jl")

export generateJuMPcodes
export generateDEcodes
export generateMTKcodes
export generateNLJuMPcodes
export scalarize

end
