using OptControl
using Test, Statistics, LinearAlgebra
using Symbolics

#=========== initial ====================#

@variables t u x[1:2]
A = [0 1; 0 0]
B = [0, 1]
Φ = 0
F = A * x + B * u
L = 0.5 * u^2
tspan = (0, 2)
dt = 0.2
t0 = [1, 1]
tf = [0, 0]

#=========== get_data test ===============#

begin
    (Φ, L, F, x, u) = OptControl.get_data(Φ, L, F, x, u)
    x_test = Symbolics.scalarize(x)
    u_test = Symbolics.scalarize(u)
    Φ_test = Symbolics.scalarize(Φ)
    F_test = Symbolics.scalarize(F)
    L_test = Symbolics.scalarize(L)
    @testset begin
        @test isequal(x_test, x)
        @test isequal(u_test, u)
        @test isequal(Φ_test, Φ)
        @test isequal(F_test, F)
        @test isequal(L_test, L)
    end
end


#=========== get_data test ===============#

begin
    xlen, ulen = OptControl.xu_length(x, u)
    xlen_test = length(x)
    ulen_test = length(u)
    @testset begin
        @test isequal(xlen, xlen_test)
        @test isequal(ulen, ulen_test)
    end
end


#=========== get_λ test ===============#

begin
    @variables λ[1:2]
    λ_test = Symbolics.scalarize(λ)
    @testset begin
        @test isequal(OptControl.get_λ(2), λ_test)
    end
    λ = Symbolics.scalarize(λ)
end


#=========== get_Hamilton test ===============#

begin
    H_test = L_test + λ_test' * F_test
    H = OptControl.get_Hamilton(L, F, λ)
    @testset begin
        @test isequal(H, H_test)
    end
end


#=========== get_dλ test ===============#
begin
    dλ_test = -Symbolics.jacobian([H_test], x_test)
    dλ = OptControl.get_dλ(H, x)
    @testset begin
        @test isequal(dλ, dλ_test)
    end
end


#=========== get_dHdu test ===============#
begin
    dHdu_test = Symbolics.jacobian([H_test], [u_test])
    dHdu = OptControl.get_dHdu(H, u)
    @testset begin
        @test isequal(dHdu, dHdu_test)
    end
end


@testset "Solve condition_1" begin
    @variables t u x[1:2]
    Φ = 0
    f = [0 1; 0 0] * x + [0, 1] * u
    L = 0.5 * u^2
    t0 = [1.0, 1.0]
    tf = [0.0, 0.0]
    tspan = (0, 2)
    dt = 0.2
    fun = generate_funcs(Φ, L, f , x, u, tspan, t0, tf, dt, nothing)
    sol = Solve(fun)
    nu = [sol.u[i][1] for i in 1:length(sol.u)]
    xs = collect(range(0, 2, length=length(sol.u)))
    an = @.(0.5 * xs^3 - 1.75 * xs^2 + xs + 1)
    @test abs(mean(an - nu)) < 0.1
end

@testset "Solve condition_2" begin
    @variables t u x[1:2]
    Φ = 0
    f = [0 1; 0 0] * x + [0, 1] * u
    L = 0.5 * u^2
    t0 = [1.0, 1.0]
    tf = [0.0, nothing]
    tspan = (0.0, 1.0)
    dt = 0.2
    fun = generate_funcs(Φ, L, f, x, u, tspan, t0, tf, dt, nothing)
    sol = Solve(fun)
    nu = [sol.u[i][1] for i in 1:length(sol.u)]
    xs = collect(range(tspan[1], tspan[2], length=length(sol.u)))
    an = @.(xs^3 - 3.0 * xs^2 + xs + 1)
    @test abs(mean(an - nu)) < 0.2
end

@testset "Solve condition_3" begin
    @variables t u x[1:2]
    Φ = x[2]^2
    f = [0 1; 0 0] * x + [0, 1] * u
    L = 0.5 * u^2
    t0 = [1.0, 1.0]
    tf = [0.0, nothing]
    tspan = (0.0, 1.0)
    dt = 0.2
    fun = generate_funcs(Φ, L, f, x, u, tspan, t0, tf, dt, nothing)
    sol = Solve(fun)
    @test true
end

@testset "Solve condition_4" begin
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

    @variables t u[1:3] x[1:6]
    Φ = 0
    F = A * x + B * u
    L = Symbolics.scalarize(sum(x->x^2,u))
    t0 = ones(6)
    tf = zeros(6)
    tspan = (0.0, 1.0)
    dt = 0.2
    fun = generate_funcs(Φ, L, F, x, u, tspan, t0, tf, dt, nothing)
    sol = Solve(fun)
    @test true
end

