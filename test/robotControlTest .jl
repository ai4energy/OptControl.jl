using OptControl
using Test, Statistics, LinearAlgebra
using Symbolics
using Statistics

@testset "JuMPSolutionCodes:x[1:6],u[1:3]" begin
    function initPara()
        J1 = 1.0 / 12 * collect(I(3))
        C1 = 0.5 * [1 2 2; 0 1 2; 0 0 2]
        D1 = 0.5 * [1 0 0; 2 1 0; 4 2 1]
        J = J1 + C1 * D1
        K = 0.5 * [5 0 0; 0 3 0; 0 0 1]
        B = [1 -1 0; 0 1 -1; 0 0 1]
        A = inv(J) * K
        B = inv(J) * B
        return A, B
    end
    A, B = initPara()
    zs = fill(0.0, 3, 3)
    A = vcat(hcat(zs, 1.0 * collect(I(3))), hcat(A, zs))
    B = vcat(zs, B)

    @variables u[1:3] x[1:6]
    f = A * x + B * u
    L = Symbolics.scalarize(sum(x -> x^2, u))
    t0 = ones(6)
    tf = zeros(6)
    tspan = (0.0, 1.0)
    sol = generateJuMPcodes(L, f, x, u, tspan, t0, tf)
    @test true
end

# @testset "JuMPSolutionCodes:x[1:6],u[1:3],ub" begin
#     function initPara()
#         J1 = 1.0 / 12 * collect(I(3))
#         C1 = 0.5 * [1 2 2; 0 1 2; 0 0 2]
#         D1 = 0.5 * [1 0 0; 2 1 0; 4 2 1]
#         J = J1 + C1 * D1
#         K = 0.5 * [5 0 0; 0 3 0; 0 0 1]
#         B = [1 -1 0; 0 1 -1; 0 0 1]
#         A = inv(J) * K
#         B = inv(J) * B
#         return A, B
#     end
#     A, B = initPara()
#     zs = fill(0.0, 3, 3)
#     A = vcat(hcat(zs, 1.0 * collect(I(3))), hcat(A, zs))
#     B = vcat(zs, B)

#     @variables u[1:3] x[1:6]
#     f = A * x + B * u
#     L = Symbolics.scalarize(sum(x -> x^2, u))
#     t0 = [π / 3, -π / 4, π / 2, 0, 0, 0]
#     tf = zeros(6)
#     tspan = (0.0, 4.0)
#     sub = [pi / 2, pi / 2, pi / 2, Inf, Inf, Inf]
#     slb = -sub
#     uub = 10.0 * ones(3)
#     ulb = -uub
#     generateJuMPcodes(L, f, x, u, tspan, t0, tf, N=100,
#         state_ub=sub, state_lb=slb, u_ub=uub, u_lb=ulb)
#     @test true
# end


# @testset "DESolutionCodes:x[1:6],u[1:3]" begin
#     function initPara()
#         J1 = 1.0 / 12 * collect(I(3))
#         C1 = 0.5 * [1 2 2; 0 1 2; 0 0 2]
#         D1 = 0.5 * [1 0 0; 2 1 0; 4 2 1]
#         J = J1 + C1 * D1
#         K = 0.5 * [5 0 0; 0 3 0; 0 0 1]
#         B = [1 -1 0; 0 1 -1; 0 0 1]
#         A = inv(J) * K
#         B = inv(J) * B
#         return A, B
#     end
#     A, B = initPara()
#     zs = fill(0.0, 3, 3)
#     A = vcat(hcat(zs, 1.0 * collect(I(3))), hcat(A, zs))
#     B = vcat(zs, B)

#     @variables u[1:3] x[1:6]
#     f = A * x + B * u
#     L = Symbolics.scalarize(sum(x -> x^2, u))
#     t0 = [60, -45, 90, 0, 0, 0]
#     tf = zeros(6)
#     tspan = (0.0, 1.0)
#     generateDEcodes(L, f, x, u, tspan, t0, tf)
#     @test true
# end

