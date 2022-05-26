using OptControl
using Documenter

DocMeta.setdocmeta!(OptControl, :DocTestSetup, :(using OptControl); recursive=true)

makedocs(;
    modules=[OptControl],
    authors="yjy <522432938@qq.com> and contributors",
    repo="https://github.com/jake484/OptControl.jl/blob/{commit}{path}#{line}",
    sitename="OptControl.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://jake484.github.io/OptControl.jl",
        # assets="assets/logo.svg",
    ),
    pages=[
        "Home" => "index.md",
        "Basics" => Any[
            "basics/OptimalControlInMath.md",
            "basics/DEsolution.md",
            "basics/JuMPsolution.md",
            "basics/base.md"
        ]
    ],
)

deploydocs(;
    repo="github.com/jake484/OptControl.jl",
    push_preview=true,
)