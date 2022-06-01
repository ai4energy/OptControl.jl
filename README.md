# OptControl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://ai4energy.github.io/OptControl.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://ai4energy.github.io/OptControl.jl/dev)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/ai4energy/OptControl.jl?svg=true)](https://ci.appveyor.com/project/ai4energy/OptControl-jl)

OptControl.jl is a interface that use symbols to build optimal control problem based on [ModelingToolkit.jl](https://mtk.sciml.ai/stable/), and then transforms optimal control problem to:

* Differential Equations Problems(DEP)
* Optimzation Problems(OP)

DEP can be solved by [DifferentialEquations.jl](https://diffeq.sciml.ai/dev/) and OP can be solved by [JuMP.jl](https://jump.dev/JuMP.jl/stable/)

An example of optimal control problem:

$$
\begin{matrix}
min \int_{0}^{2} u^2dt \newline s.t. ~~~~~ \dot{\boldsymbol{x}} =\begin{bmatrix}0&1 \newline 0&0\end{bmatrix}\boldsymbol{x}+ \begin{bmatrix}0 \newline 1 \end{bmatrix}u \newline \boldsymbol{x}(0) = \begin{bmatrix} 1 \newline 1 \end{bmatrix}, \boldsymbol{x}(2)=\begin{bmatrix} 0 \newline 0 \end{bmatrix}
\end{matrix}
$$

And use `OptControl.jl` to transform it to `JuMP` code to solve it.

```julia
using ModelingToolkit,OptControl
@variables t u x[1:2]
f = [0 1; 0 0] * x + [0, 1] * u
L = 0.5 * u^2
t0 = [1.0, 1.0]
tf = [0.0, 0.0]
tspan = (0.0, 2.0)
N = 100
sol = generateJuMPcodes(L, f, x, u, tspan, t0, tf; N=N)
```

See [document](https://ai4energy.github.io/OptControl.jl/dev) for more information.

