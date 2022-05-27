using OptControl
using Documenter

makedocs(;
    modules=[OptControl],
    authors="yjy <522432938@qq.com> and contributors",
    sitename="OptControl.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://jake484.github.io/OptControl.jl",
        # assets=["assets/logo.svg"]
    ),
    pages=[
        "Home" => "index.md",
        "Basics" => Any[
            "basics/OptimalControlInMath.md",
            "basics/JuMPsolution.md",
            "basics/DEsolution.md",
            "basics/discretization.md"
        ]
    ]
)

deploydocs(
    repo="github.com/jake484/OptControl.jl";
    push_preview=true)
