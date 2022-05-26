# Differential Equations Solution

`Differential Equations Solution` uses `DifferentialEquations.jl` to solve the Problems. Build the problem and call `generateDEcodes`, work done!

```@docs
generateDEcodes
```

**Overview of `generateDEcodes` and `generateJuMPcodes`**

`generateDEcodes` and `generateJuMPcodes` using the same way to build problem, and they both can solve *Fixed Value(Example1)* and *Free End(Example2)*. But `generateDEcodes` cannot deal with *End constraint* and *Add variable limit*. Meanwhile, `generateDEcodes`have lower accuracy than `generateJuMPcodes`. Maybe accuracy can be improved by pass different solver parameters. You can have a try.

| Example | generateJuMPcodes  | generateDEcodes | 
|--------------------------|:------------------------:|:------------------------:|
| **1.** Fixed Value |✅ | ✅ |
| **2.** Free Value |✅ | ✅ |
| **3.** Constraint |✅ | ❌ |
| **4.** Multiple `x` and `u` |✅ | ✅ |
| **5.** variable limit |✅ | ❌ |

✅ = supported

❌ = not supported





## Example 1: Fixed value

To solve:

```math
min \int_{0}^{2} u^2dt \newline s.t. ~~~~~ \dot{\boldsymbol{x}} =\begin{bmatrix}0&1 \newline 0&0\end{bmatrix}\boldsymbol{x}+ \begin{bmatrix}0 \newline 1 \end{bmatrix}u \newline \boldsymbol{x}(0) = \begin{bmatrix} 1 \newline 1 \end{bmatrix}, \boldsymbol{x}(2)=\begin{bmatrix} 0 \newline 0 \end{bmatrix}
```

Just define variables and build functions. Call `generateDEcodes` and get the results.

The analytical solution of $x_1$ is

$$x_1(t) = 0.5*t^3-1.75*t^2+t+1$$

and we can campare the difference between them by using *Mean Square Error(MSE)*.

```@example
using OptControl, Statistics
@variables t u x[1:2]
f = [0 1; 0 0] * x + [0, 1] * u
L = 0.5 * u^2
t0 = [1.0, 1.0]
tf = [0.0, 0.0]
tspan = (0.0, 2.0)
sol = generateDEcodes(L, f, x, u, tspan, t0, tf)
nu = [sol.u[i][1] for i in 1:length(sol.u)]
xs = collect(range(tspan[1], tspan[2], length=length(sol.u)))
an = @.(0.5 * xs^3 - 1.75 * xs^2 + xs + 1)
mean((an - nu).^2)
```

## Example 2: Free End

To solve:

```math
min \int_{0}^{2} u^2dt \newline s.t. ~~~~~ \dot{\boldsymbol{x}} =\begin{bmatrix}0&1 \newline 0&0\end{bmatrix}\boldsymbol{x}+ \begin{bmatrix}0 \newline 1 \end{bmatrix}u \newline \boldsymbol{x}(0) = \begin{bmatrix} 1 \newline 1 \end{bmatrix}, \boldsymbol{x}(1)=\begin{bmatrix} 0 \newline free \end{bmatrix}
```

**If variable is free, use `nothing`.**

The analytical solution of $x_1$ is

$$x_1(t) = t^3-3.0*t^2+t+1$$

and get *MSE*.

```@example
using OptControl, Statistics
@variables t u x[1:2]
f = [0 1; 0 0] * x + [0, 1] * u
L = 0.5 * u^2
t0 = [1.0, 1.0]
tf = [0.0, nothing]
tspan = (0.0, 1.0)
N = 100
sol = generateDEcodes(L, f, x, u, tspan, t0, tf)
nu = [sol.u[i][1] for i in 1:length(sol.u)]
xs = collect(range(tspan[1], tspan[2], length=length(sol.u)))
an = @.(xs^3 - 3.0 * xs^2 + xs + 1)
mean((an - nu).^2)
```

## Example 3: Multiple `x` and `u`

To solve:

```math
min \int_{0}^{2} u^2dt \newline s.t. ~~~~~ \dot{\boldsymbol{x}} =\begin{bmatrix}0&1 \newline 0&0\end{bmatrix}\boldsymbol{x}+ \begin{bmatrix}1&0 \newline 0&1 \end{bmatrix}\boldsymbol{u} \newline \boldsymbol{x}(0) = \begin{bmatrix} 1 \newline 1 \end{bmatrix}, \boldsymbol{x}(2)=\begin{bmatrix} 0.0 \newline free \end{bmatrix}

```

The analytical solution of $u_1,u_2$ is

```math
\begin{matrix}
u_1=-\frac{9}{14}\\u_2=\frac{9}{14}*t-\frac{9}{7}
\end{matrix}

```

and get *MSE*.

```@example
using OptControl, Statistics
@variables t u[1:2] x[1:2]
f = [0 1; 0 0] * x + [1 0; 0 1] * u
L = 0.5 * (u[1]^2 + u[2]^2)
t0 = [1.0, 1.0]
tf = [0.0, nothing]
tspan = (0.0, 2.0)
sol = generateDEcodes(L, f, x, u, tspan, t0, tf)
nu1 = [sol.u[i][5] for i in 1:length(sol.u)]
nu2 = [sol.u[i][6] for i in 1:length(sol.u)]
xs = collect(range(tspan[1], tspan[2], length=length(sol.u)))
an_u2 = @.(9 / 14 * xs - 9 / 7)
res1 = mean((-9 / 14 .- nu1).^2)
res2 = mean((an_u2 - nu2).^2)
(res1,res2)
```
