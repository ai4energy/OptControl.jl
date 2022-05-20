# OptControl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://jake484.github.io/OptControl.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://jake484.github.io/OptControl.jl/dev)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/jake484/OptControl.jl?svg=true)](https://ci.appveyor.com/project/jake484/OptControl-jl)
[![Build Status](https://api.cirrus-ci.com/github/jake484/OptControl.jl.svg)](https://cirrus-ci.com/github/jake484/OptControl.jl)
[![Coverage](https://codecov.io/gh/jake484/OptControl.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/jake484/OptControl.jl)

OptControl.jl is a interface that transforms optimal control problem to:

* Differential Equations Problems(DEP)
* Optimzation Problems(OP)

DEP can be solved by [DifferentialEquations.jl](https://diffeq.sciml.ai/dev/) and OP can be solved by [JuMP.jl](https://jump.dev/JuMP.jl/stable/)

