# OptControl

## What is OptControl.jl?

OptControl.jl is a interface that use symbols to build optimal control problem based on [Symbolics.jl](https://symbolics.juliasymbolics.org/dev/), and then transforms optimal control problem to:

* Differential Equations Problems(DEP)
* Optimzation Problems(OP)

DEP can be solved by [DifferentialEquations.jl](https://diffeq.sciml.ai/dev/) and OP can be solved by [JuMP.jl](https://jump.dev/JuMP.jl/stable/)

Features of OptControl.jl:

* `Symbolics.jl` makes problem building very easy and user-friendly
* Script generation provides a template of `JuMP.jl` solution code or `DifferentialEquations.jl` solution code, and you can design your code based on template.
* Get results directly if you want.

## Citation

If you use OptControl in your work, please cite the this [paper](https://arxiv.org/abs/2207.13229):

```bib
@article{yang2022optcontrol,
  title={OptControl.jl: An interpreter for optimal control problem},
  author={Jingyi Yang, Yuebao Yang, Mingtao Li},
  journal={arXiv preprint arXiv:2207.13229},
  year={2022},
  primaryClass={math.OC}
}
```

## Quick Start

### Install

```julia
using Pkg
Pkg.add("OptControl")
```

### Solve Problem

To solve optimal control problem:

```math
min \int_{0}^{2} u^2dt \\s.t. \hspace{0.4cm} \dot{\boldsymbol{x}} =\begin{bmatrix}0&1 \\0&0\end{bmatrix}\boldsymbol{x}+ \begin{bmatrix}0\\1\end{bmatrix}u\\\boldsymbol{x}(0)=\begin{bmatrix}1\\1\end{bmatrix},\boldsymbol{x}(2)=\begin{bmatrix}0\\0\end{bmatrix}
```

Copy and run:

```julia
using Symbolics,OptControl
@variables t u x[1:2]
f = [0 1; 0 0] * x + [0, 1] * u
L = 0.5 * u^2
t0 = [1.0, 1.0]
tf = [0.0, 0.0]
tspan = (0.0, 2.0)
N = 100
sol = generateJuMPcodes(L, f, x, u, tspan, t0, tf; N=N, 
writeFilePath="JuMPscript.jl")
```

In Current folder, you will see

```powershell
CurrentFolder/
└──JuMPscript.jl
```

And you will see contents of `JuMPscript.jl`

```julia
begin
    using Pkg
    pkgNeeds = ["JuMP", "Ipopt", "Symbolics"]
    alreadyGet = keys(Pkg.project().dependencies)
    toAdd = [package for package in pkgNeeds if package ∉ alreadyGet]
    isempty(toAdd) ? nothing : Pkg.add(toAdd)
end
using Symbolics,Ipopt,JuMP

#============Function Parts================#
discretization_trapezoidal = function (yi, h, index, args...)
    return yi + h / 2 * (args[1] + args[2])
end
L_objectiveFunc = function (ˍ₋arg1,)
    #= C:\Users\DELL\.julia\packages\SymbolicUtils\v2ZkM\src\code.jl:349 =#
    #= C:\Users\DELL\.julia\packages\SymbolicUtils\v2ZkM\src\code.jl:350 =#
    #= C:\Users\DELL\.julia\packages\SymbolicUtils\v2ZkM\src\code.jl:351 =#
    begin
        (*)(0.5, (^)(ˍ₋arg1[3], 2))
    end
end
F_statesFunc = function (ˍ₋arg1,)
    #= C:\Users\DELL\.julia\packages\SymbolicUtils\v2ZkM\src\code.jl:349 =#
    #= C:\Users\DELL\.julia\packages\SymbolicUtils\v2ZkM\src\code.jl:350 =#
    #= C:\Users\DELL\.julia\packages\SymbolicUtils\v2ZkM\src\code.jl:351 =#
    begin
        begin
            #= C:\Users\DELL\.julia\packages\SymbolicUtils\v2ZkM\src\code.jl:444 =#
            (SymbolicUtils.Code.create_array)(typeof(ˍ₋arg1), nothing, Val{1}(), Val{(2,)}(), (getindex)(ˍ₋arg1, 2), ˍ₋arg1[3])
        end
    end
end



#========== define model =============#
model = Model(Ipopt.Optimizer)
set_optimizer_attribute(model, "print_level", 0)

#========== define variables =============#
JuMP.@variable(model,  x[1:100, j=1:2] )
JuMP.@variable(model,  u[1:100, j=1:1] )

#========== boundary constraint =============#
JuMP.@NLconstraint(model, [j = 1:2],x[1, j] == [1.0, 1.0][j])
JuMP.@NLconstraint(model, 
    [j = [i for i in 1:2 if !isequal([0.0, 0.0][i],nothing)]],
     x[end, j] == [0.0, 0.0][j])


#========== state constraint =============#
JuMP.@NLconstraint(model, [i = 1:99, j = 1:2],
        x[i+1,j] == discretization_trapezoidal(x[i,:], 0.02, i, 
	F_statesFunc(append!([],x[i+1,:],u[i+1,:])),
	F_statesFunc(append!([],x[i+0,:],u[i+0,:])),
	)[j])

#========== objective =============#
_sum_ = [L_objectiveFunc(append!([],x[i,:],u[i,:])) for i in 1:100]
JuMP.@NLobjective(model, Min, sum(_sum_[i] for i in 1:100))

#================ solve ==================#
JuMP.optimize!(model)
(x,u) = (JuMP.value.(x)[:,:],JuMP.value.(u)[:,:])

```

Actually, OptControl.jl just run the generated script automatically. If you are familiar with JuMP.jl or DifferentialEquations.jl and want to do more things, just give `writeFilePath` a value(name of Julia script).

### Solution Handle

If you don't know JuMP.jl or DifferentialEquations.jl. Don't worry, just run and get the results. Do what you want with the results.

Get state:

```julia
x = sol[1]
```

```powershell
100×2 Matrix{Float64}:
 1.0           1.0
 1.01947       0.946775
 1.0377        0.876642
 1.05455       0.807758
 1.07002       0.740124
 1.08416       0.673739
 1.09699       0.608604
 1.10852       0.544719
 1.11879       0.482083
 1.12782       0.420697
 1.13563       0.36056
 1.14225       0.301673
 1.14771       0.244036
 1.15202       0.187648
 1.15523       0.13251
 1.15734       0.0786212
 1.15838       0.0259822
 1.15839      -0.0254071
 1.15738      -0.0755468
 ⋮
 0.13861      -0.715141
 0.124606     -0.685306
 0.11121      -0.654221
 0.0984493    -0.621886
 0.0863474    -0.588302
 0.0749297    -0.553469
 0.0642211    -0.517386
 0.0542468    -0.480053
 0.0450315    -0.44147
 0.0366004    -0.401638
 0.0289785    -0.360557
 0.0221907    -0.318226
 0.0162619    -0.274645
 0.0112174    -0.229814
 0.00708187   -0.183734
 0.00388048   -0.136405
 0.00163818   -0.0878253
 0.000379965  -0.0379965
 0.0           0.0
```

Get u:

```julia
u = sol[2]
```

```powershell
100×1 Matrix{Float64}:
 -1.7845763373682157
 -3.537912486353386
 -3.475432109587295
 -3.412951732821204
 -3.3504713560551127
 -3.2879909792890216
 -3.22551060252293
 -3.163030225756839
 -3.1005498489907475
 -3.038069472224657
 -2.975589095458566
 -2.913108718692475
 -2.850628341926384
 -2.788147965160293
 -2.725667588394202
 -2.663187211628111
 -2.6007068348620197
 -2.5382264580959286
 -2.4757460813298375
  ⋮
  1.4605176549338985
  1.5229980316999896
  1.5854784084660805
  1.6479587852321715
  1.7104391619982624
  1.7729195387643535
  1.8353999155304446
  1.8978802922965357
  1.9603606690626267
  2.022841045828718
  2.085321422594809
  2.1478017993609
  2.210282176126991
  2.272762552893082
  2.3352429296591732
  2.3977233064252643
  2.4602036831913554
  2.5226840599574465
  1.276962124170246
```
