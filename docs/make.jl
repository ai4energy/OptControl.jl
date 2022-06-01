using OptControl
using Documenter
using ModelingToolkit,Test

makedocs(;
    modules=[OptControl],
    authors="yjy <522432938@qq.com> and contributors",
    sitename="OptControl.jl",
    clean = true,doctest = false,
    format=Documenter.HTML(;
        # prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://ai4energy.github.io/OptControl.jl/stable",
        # assets=["assets/logo.svg"]
    ),
    pages=[
        "Home" => "index.md",
        "Basics" => Any[
            "basics/OptimalControlInMath.md",
            "basics/JuMPsolution.md",
            "basics/NLJuMPsolution.md",
            "basics/DEsolution.md",
            "basics/mtkSupport.md",
            "basics/discretization.md"
        ]
    ]
)

deploydocs(
    repo="github.com/ai4energy/OptControl.jl.git";
    push_preview=true
)
