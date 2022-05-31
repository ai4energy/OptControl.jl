using OptControl
using Test, Statistics, LinearAlgebra
using Symbolics
using SafeTestsets

@safetestset "DE methods Test" begin include("decode.jl") end

@safetestset "Jump methods Test" begin include("jumpcode.jl") end

@safetestset "MTK_rcmodel Test" begin include("mtk_rcmodel.jl") end

@safetestset "MTK_Eqs Test" begin include("mtk_simpleeqs.jl") end

@safetestset "RobotControl Test" begin include("robotControl.jl") end