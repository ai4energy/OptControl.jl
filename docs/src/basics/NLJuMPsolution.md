# Nonlinear Optimization Solution

`Nonlinear Optimization solution` uses `generateNLJuMPcodes` to solve the Problems. The arguments are the same as `generateJuMPcodes`

```@docs
generateNLJuMPcodes
```

Let's see some examples. If you are not familar with ModelingToolkit.jl, you can see the [Symbolics.jl  document](https://symbolics.juliasymbolics.org/dev/) (which ModelingToolkit.jl based on) and try some tests about symbolic computation

```@example
using OptControl,ModelingToolkit
@variables x[1:2] y[1:2]
print(scalarize(rand(1:10,2,2)*x+rand(1:10,2,2)*y))
```

PS: scalarize is from Symbolics.jl

**If you need, pass a name to  `writeFilePath`  and do some changes in script**.

## Example 1

To solve:

```math
min \int_{0}^{2} u^2dt \newline s.t. ~~~~~ \dot{x} =e^x+ u \newline x(0) = 1, x(2)=0
```

Just define variables and build functions. Call `generateNLJuMPcodes` and get the results.

```@example
using OptControl, ModelingToolkit, Test
@variables t u x
f = exp(x) + u
L = u^2
t0 = [1.0]
tf = [0.0]
tspan = (0.0, 2.0)
N = 100
sol = generateNLJuMPcodes(L, f, x, u, tspan, t0, tf; N=N)

@test isapprox.(0.0, sol[1][end, :], atol=1.0e-5) == [true for i in 1:length(sol[1][end, :])]

```

## Example 2

To solve:

```math
min \int_{0}^{2} u^2dt \newline s.t. ~~~~~ \dot{\boldsymbol{x}} =\begin{bmatrix}exp&cos \newline sin&1\end{bmatrix}\boldsymbol{x}+ \begin{bmatrix}0 \newline 1 \end{bmatrix}u \newline \boldsymbol{x}(0) = \begin{bmatrix} 1 \newline 1 \end{bmatrix}, \boldsymbol{x}(1)=\begin{bmatrix} 0 \newline free \end{bmatrix}
```

```@example
using OptControl, ModelingToolkit, Test
@variables t u x[1:2]
f = [exp(x[1]) + cos(x[2]), sin(x[1]) + x[2]] + [1, 0] * u
L = u^2
t0 = [1.0, 1.0]
tf = [0.0, 0.0]
tspan = (0.0, 2.0)
N = 100
sol = generateNLJuMPcodes(L, f, x, u, tspan, t0, tf; N=N)
@test isapprox.(0.0, sol[1][end, :], atol=1.0e-5) == [true for i in 1:length(sol[1][end, :])]
```
