# Optimization Solution

`Optimization solution` uses `JuMP.jl` to solve the Problems. Build the problem and call `generateJuMPcodes`, work done!

```@docs
generateJuMPcodes
```

Let's see some examples. If you are not familar with Symbolics.jl, you can see the [document](https://symbolics.juliasymbolics.org/dev/) and try some tests about symbolic computation

```@example
using OptControl
@variables x[1:2] y[1:2]
print(scalarize(rand(1:10,2,2)*x+rand(1:10,2,2)*y))
```

**If you need, pass a name to  `writeFilePath`  and do some changes in script**.

## Example 1: Fixed value

To solve:

```math
min \int_{0}^{2} u^2dt \newline s.t. ~~~~~ \dot{\boldsymbol{x}} =\begin{bmatrix}0&1 \newline 0&0\end{bmatrix}\boldsymbol{x}+ \begin{bmatrix}0 \newline 1 \end{bmatrix}u \newline \boldsymbol{x}(0) = \begin{bmatrix} 1 \newline 1 \end{bmatrix}, \boldsymbol{x}(2)=\begin{bmatrix} 0 \newline 0 \end{bmatrix}
```

Just define variables and build functions. Call `generateJuMPcodes` and get the results.

The analytical solution of $x_1$ is

$$x_1(t) = 0.5*t^3-1.75*t^2+t+1$$

and we can campare the difference between them by using *Mean Square Error(MSE)*.

```@example
using OptControl, Statistics, ModelingToolkit
@variables t u x[1:2]
f = [0 1; 0 0] * x + [0, 1] * u
L = 0.5 * u^2
t0 = [1.0, 1.0]
tf = [0.0, 0.0]
tspan = (0.0, 2.0)
N = 100
sol = generateJuMPcodes(L, f, x, u, tspan, t0, tf; N=N)
xs = collect(range(tspan[1], tspan[2], length=N))
an = @.(0.5 * xs^3 - 1.75 * xs^2 + xs + 1)
mean((an - sol[1][:, 1]).^2)
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
using OptControl, Statistics, ModelingToolkit, ModelingToolkit
@variables t u x[1:2]
f = [0 1; 0 0] * x + [0, 1] * u
L = 0.5 * u^2
t0 = [1.0, 1.0]
tf = [0.0, nothing]
tspan = (0.0, 1.0)
N = 100
sol = generateJuMPcodes(L, f, x, u, tspan, t0, tf; N=N)
xs = collect(range(tspan[1], tspan[2], length=N))
an = @.(xs^3 - 3.0 * xs^2 + xs + 1)
mean((an - sol[1][:, 1]).^2)
```

## Example 3: End Constraint

To solve:

```math
min \int_{0}^{2} u^2dt \newline s.t. ~~~~~ \dot{\boldsymbol{x}} =\begin{bmatrix}0&1 \newline 0&0\end{bmatrix}\boldsymbol{x}+ \begin{bmatrix}0 \newline 1 \end{bmatrix}u \newline \boldsymbol{x}(0) = \begin{bmatrix} 1 \newline 1 \end{bmatrix}, \boldsymbol{x}(1)=\begin{bmatrix} free \newline free \end{bmatrix} \\ x_1(1)+x_2(1)=0
```

**Passing special end constraint to parameter `tf_constraint`.**

The analytical solution of $x_1$ is

$$x_1(t) = -1/14*t^2*(t - 6)$$

and get *MSE*.

```@example
using OptControl, Statistics, ModelingToolkit
@variables t u x[1:2]
f = [0 1; 0 0] * x + [0, 1] * u
L = 0.5 * u^2
t0 = [0.0, 0.0]
tf = [nothing, nothing]
tspan = (0.0, 1.0)
tf_con = x[1] + x[2] - 1.0
N = 100
sol = generateJuMPcodes(L, f, x, u, tspan, t0, tf, nothing, tf_con; N=N)
xs = collect(range(tspan[1], tspan[2], length=N))
an = @.(-1 / 14 * xs^2 * (xs - 6))
mean((an - sol[1][:, 1]).^2)
```

PS:`x[1] + x[2] - 1.0` above is $x_1+x_2-1.0$. There nothing to do with independent variable $t$, because `tf_constraint` means constraint at the end time.

## Example 4: Multiple End Constraint

To solve:

```math
min \int_{0}^{2} u^2dt \newline s.t. ~~~~~ \dot{\boldsymbol{x}} =\begin{bmatrix}0&1 \newline 0&0\end{bmatrix}\boldsymbol{x}+ \begin{bmatrix}0 \newline 1 \end{bmatrix}u \newline \boldsymbol{x}(0) = \begin{bmatrix} 1 \newline 1 \end{bmatrix}, \boldsymbol{x}(2)=\begin{bmatrix} free \newline free \end{bmatrix} \\ x_1(2)+x_2(2)=0\\ x_1(2)-x_2(2)=0

```

Actually, solution of those two constraint equations are $$x_1=0,x_2=0$$Essentially, it's the same as `Example 1`.

The analytical solution of $x_1$ is

$$x_1(t) = 0.5*t^3-1.75*t^2+t+1$$

and get *MSE*.

```@example
using OptControl, Statistics, ModelingToolkit
@variables t u x[1:2]
f = [0 1; 0 0] * x + [0, 1] * u
L = 0.5 * u^2
t0 = [1.0, 1.0]
tf = [nothing, nothing]
tspan = (0.0, 2.0)
tf_con = [x[1] + x[2], x[1] - x[2]]
N = 100
sol = generateJuMPcodes(L, f, x, u, tspan, t0, tf, nothing, tf_con; N=N)
xs = collect(range(tspan[1], tspan[2], length=N))
an = @.(0.5 * xs^3 - 1.75 * xs^2 + xs + 1)
mean((an - sol[1][:, 1]).^2)
```

## Example 5: Multiple `x` and `u`

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
using OptControl, Statistics, ModelingToolkit
@variables t u[1:2] x[1:2]
f = [0 1; 0 0] * x + [1 0; 0 1] * u
L = 0.5 * (u[1]^2 + u[2]^2)
t0 = [1.0, 1.0]
tf = [0.0, nothing]
tspan = (0.0, 2.0)
N = 100
sol = generateJuMPcodes(L, f, x, u, tspan, t0, tf; N=N)
xs = collect(range(tspan[1], tspan[2], length=N))
an_u2 = @.(9 / 14 * xs - 9 / 7)
res1 = mean((-9 / 14 .- sol[2][:, 1]).^2)
res2 = mean((an_u2 - sol[2][:, 2]).^2)
(res1,res2)
```

## Example 6: Add variable limit

To solve:

```math
min ~~x_2(1) \newline s.t. ~~~~~ \dot{\boldsymbol{x}} =\begin{bmatrix}-1&0 \newline 1&0\end{bmatrix}\boldsymbol{x}+ \begin{bmatrix}1 \newline 0 \end{bmatrix}u \newline \boldsymbol{x}(0) = \begin{bmatrix} 1 \newline 1 \end{bmatrix}, \boldsymbol{x}(1)=\begin{bmatrix} free \newline free \end{bmatrix} \\ -1.0
\leqslant\boldsymbol{u}\leqslant1.0
```

The analytical solution of $x_1$ is

```math
x_1(t) = 2*e^{-t} - 1
```

and get *MSE*.

```@example
using OptControl, Statistics, ModelingToolkit
@variables t u x[1:2]
f = [-1 0; 1 0] * x + [1, 0] * u
L = 0
t0 = [1.0, 0.0]
tf = [nothing, nothing]
tspan = (0.0, 1.0)
N = 100
Φ = x[2]
uub = [1.0]
ulb = [-1.0]
sol = generateJuMPcodes(L, f, x, u, tspan, t0, tf, Φ, nothing;N=N, u_ub=uub, u_lb=ulb)
xs = collect(range(tspan[1], tspan[2], length=N))
an = @.(2 * exp(-xs) - 1)
mean((an - sol[1][:, 1]).^2)
```

In this example, give `L` a value 0. Because `L` has nothing to do with optimization objective.  
