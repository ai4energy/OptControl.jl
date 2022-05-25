# Solution of Math Form

Generally, optimal control problem is a functional extremum problem. Sometimes analytic solution is hard to get, so numerical methods are feasible. To be solved, it can be treated as a optimization problem and differential equations problem. Therefore, `JuMP.jl` and `DifferentialEqutions.jl` are two powerful solver.

## General Form

General form of optimal control problems are:

```math
min \int_{t_0}^{t_f} L[\boldsymbol{x}(t),\boldsymbol{u}(t),t]dt \\s.t. \hspace{0.4cm} \dot{\boldsymbol{x}} =
f[\boldsymbol{x}(t),\boldsymbol{u}(t),t]
```

### Differential form Solution

Define Hamilton function $\boldsymbol{H}$ and Lagrange multiplier vector $\boldsymbol{\lambda}$,

```math
H[\boldsymbol{x}(t),\boldsymbol{u}(t),t] = L[\boldsymbol{x}(t),\boldsymbol{u}(t),t] + \boldsymbol{\lambda}^T(t)f[\boldsymbol{x}(t),\boldsymbol{u}(t),t]\\
\boldsymbol{\lambda}(t) = [\lambda_1(t),\lambda_2(t),...,\lambda_n(t)]
```

Necessary conditions for the existence of functional extremum are:

- **Adjoint Equation**:

```math
\dot{\boldsymbol{\lambda}} =- \frac{\partial H}{\partial \boldsymbol{x}} 
```

- **Coupling Equation**:
  
```math
\frac{\partial H}{\partial \boldsymbol{u}}  = 0
```

- **State Equation**

```math
\dot{\boldsymbol{x}} = -\frac{\partial H}{\partial \boldsymbol{\lambda}} =f[\boldsymbol{x}(t),\boldsymbol{u}(t),t]
```

There are several different possibilities for **Transversality conditions**:

#### Condition 1: Fixed initial and final value

*Fixed initial and final value* means:

```math
\boldsymbol{x}(t_0)=\boldsymbol{x}_0,\boldsymbol{x}(t_f)=\boldsymbol{x}_{f}
```

Complete equations to be solved are:

```math
\left\{\begin{matrix}
 \dot{\boldsymbol{\lambda}} =- \frac{\partial H}{\partial \boldsymbol{x}} \\
 \frac{\partial H}{\partial \boldsymbol{u}}  = 0\\
 \dot{\boldsymbol{x}} =f[\boldsymbol{x}(t),\boldsymbol{u}(t),t] \\
 \boldsymbol{x}(t_0)=\boldsymbol{x}_0,\boldsymbol{x}(t_f)=\boldsymbol{x}_{f}
\end{matrix}\right.
```

**For example:**

```math
min \int_{0}^{2} u^2dt \\
s.t. \hspace{0.4cm} \dot{\boldsymbol{x}} =
\begin{bmatrix} 0&1 \\ 0&0 \end{bmatrix}\boldsymbol{x} +\begin{bmatrix}0\\1\end{bmatrix}u \\
\boldsymbol{x}(0)=\begin{bmatrix}1\\1\end{bmatrix},\boldsymbol{x}(2)=\begin{bmatrix}0\\0\end{bmatrix}
```

Equations to be solved are:

```math
\left\{\begin{matrix}
 \dot{\lambda_1} = 0\\
 \dot{\lambda_2}  = -\lambda_1\\
 \dot{x_1} = x_2 \\
 \dot{x_2} = u \\
 u + \lambda_2 = 0\\
\end{matrix}\right.
```

Boundary conditions are:

$$x_1(0)=1,x_2(0)=1,x_1(2)=0,x_2(2)=0$$

This is a typical [Differential Algebraic Equations(DAE)](https://diffeq.sciml.ai/dev/tutorials/dae_example/) with [Boundary Value Problems(BVP)](https://diffeq.sciml.ai/dev/tutorials/bvp_example/). `DifferentialEqutions.jl` is a powerful solver to solve this problem.

#### Condition 2: Fixed initial value and Free final value

In this condition, consider **Bolza Type**:

```math
min (\Phi(\boldsymbol{x}(t_f),t_f)+\int_{t_0}^{t_f} L[\boldsymbol{x}(t),\boldsymbol{u}(t),t]dt)
```

the $\Phi(\boldsymbol{x}(t_f),t_f)$ are some special requirements for end time.

Complete equations to be solved are:

```math
\left\{\begin{matrix}
 \dot{\boldsymbol{\lambda}} =- \frac{\partial H}{\partial \boldsymbol{x}} \\
 \frac{\partial H}{\partial \boldsymbol{u}}  = 0\\
 \dot{\boldsymbol{x}} =f[\boldsymbol{x}(t),\boldsymbol{u}(t),t] \\
 \boldsymbol{x}(t_0)=\boldsymbol{x}_0\\\boldsymbol{\lambda}(t_f)=\frac{\partial \boldsymbol{\Phi}}{\partial \boldsymbol{x}}|_{t=t_f}
\end{matrix}\right.
```

**For example:**

```math
min \int_{0}^{2} u^2dt \\
s.t. \hspace{0.4cm} \dot{\boldsymbol{x}} =
\begin{bmatrix} 0&1 \\ 0&0 \end{bmatrix}\boldsymbol{x} +\begin{bmatrix}0\\1\end{bmatrix}u \\
\boldsymbol{x}(0)=\begin{bmatrix}1\\1\end{bmatrix},\boldsymbol{x}(2)=\begin{bmatrix}0\\free\end{bmatrix}
```

Equations to be solved are:

```math
\left\{\begin{matrix}
 \dot{\lambda_1} = 0\\
 \dot{\lambda_2}  = -\lambda_1\\
 \dot{x_1} = x_2 \\
 \dot{x_2} = u \\
 u + \lambda_2 = 0\\
\end{matrix}\right.
```

Boundary conditions are:

$$x_1(0)=1,x_2(0)=1,x_1(2)=0,\lambda_2(2)=\frac{\partial \Phi}{\partial x_2(1)}=0$$

This is also a DAE with BVP.

There still some other conditions which `DifferentialEquations` can't apply to, but JuMP can solve them with a Optimization form.

## Optimization form

Essentially, *Optimal Control Problem* is a optimization problem.Optimization methods can solve it by discretizing the continuous function.  

From

```math
min \int_{t_0}^{t_f} L[\boldsymbol{x}(t),\boldsymbol{u}(t),t]dt \\s.t. \hspace{0.4cm} \dot{\boldsymbol{x}} =
f[\boldsymbol{x}(t),\boldsymbol{u}(t),t]
```

to

```math
min \sum_{i=1}^{n} L(\boldsymbol{x}_i,\boldsymbol{u}_i,t_i) \\s.t. \hspace{0.4cm} \boldsymbol{x}_{i+1} =\boldsymbol{x}_{i}+f(\boldsymbol{x}_i,\boldsymbol{u}_i,t_i)*dt
```

Actually, discretization method above is *Euler method* or we can use *Backward Euler method*:

```math
min \sum_{i=1}^{n} L(\boldsymbol{x}_i,\boldsymbol{u}_i,t_i) \\s.t. \hspace{0.4cm} \boldsymbol{x}_{i+1} =\boldsymbol{x}_{i}+f(\boldsymbol{x}_{i+1},\boldsymbol{u}_{i+1},t_{i+1})*dt
```

There are still lots of discretization methods we can choose like *Trapezoidal Method*, *Simpson Method*, *Adams method* and so on.

For example in [Condition 1](#condition-1-fixed-initial-and-final-value), we can get:

```math
min \sum_{i=1}^{100} u_i^2dt \\
s.t. \hspace{0.4cm} \boldsymbol{x}_{i+1} = \boldsymbol{x}_i + 
(\begin{bmatrix} 0&1 \\ 0&0 \end{bmatrix}\boldsymbol{x}_i +\begin{bmatrix}0\\1\end{bmatrix}u_i) * 0.02 \\
\boldsymbol{x}_1=\begin{bmatrix}1\\1\end{bmatrix},\boldsymbol{x}_{100}=\begin{bmatrix}0\\0\end{bmatrix}
```

With the Optimization form, **Condition 3** can be solved.

### Condition 3: Fixed initial value and final value with constrain

```math
min \int_{0}^{2} u^2dt \\
s.t. \hspace{0.4cm} \dot{\boldsymbol{x}} =
\begin{bmatrix} 0&1 \\ 0&0 \end{bmatrix}\boldsymbol{x} +\begin{bmatrix}0\\1\end{bmatrix}u \\
\boldsymbol{x}(0)=\begin{bmatrix}1\\1\end{bmatrix}\\
x_1(2)+x_2(2) =0
```

With the Optimization form, we just add a different constraint:

```math
min \sum_{i=1}^{100} u_i^2dt \\
s.t. \hspace{0.4cm} \boldsymbol{x}_{i+1} = \boldsymbol{x}_i + 
(\begin{bmatrix} 0&1 \\ 0&0 \end{bmatrix}\boldsymbol{x}_i +\begin{bmatrix}0\\1\end{bmatrix}u_i) * 0.02 \\
\boldsymbol{x}_1=\begin{bmatrix}1\\1\end{bmatrix}\\
x_{1,100}+x_{2,100}=0
```

Awesome!
