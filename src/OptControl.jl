module OptControl
using Symbolics
using LinearAlgebra
using JuMP, DifferentialEquations

scalarize = Symbolics.scalarize

function scalarize_data(args...)
    return (scalarize(arg) for arg in args)
end

function checkPkg(pkgName)
    if pkgName == "JuMP"
        pkgNeeds = "[\"JuMP\", \"Ipopt\", \"Symbolics\"]"
    else
        pkgNeeds = "[\"DifferentialEquations\", \"Symbolics\"]"
    end
    return "begin
    using Pkg
    pkgNeeds = $(pkgNeeds)
    alreadyGet = keys(Pkg.project().dependencies)
    toAdd = [package for package in pkgNeeds if package ∉ alreadyGet]
    isempty(toAdd) ? nothing : Pkg.add(toAdd)\nend"
end

function initial(pkgName)
    jumpcode = "$(checkPkg(pkgName))\nusing Symbolics,Ipopt,JuMP\n"
    decode = "$(checkPkg(pkgName))\nusing Symbolics,DifferentialEquations,LinearAlgebra\n"
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

export generateJuMPcodes, generateDEcodes, scalarize

end
