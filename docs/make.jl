using MultiQuantityGPs
using Documenter

DocMeta.setdocmeta!(MultiQuantityGPs, :DocTestSetup, :(using MultiQuantityGPs); recursive=true)

makedocs(;
    modules=[MultiQuantityGPs],
    authors="Nicholas Harrison",
    sitename="MultiQuantityGPs.jl",
    format=Documenter.HTML(;
        canonical="https://ngharrison.github.io/MultiQuantityGPs.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/ngharrison/MultiQuantityGPs.jl",
    devbranch="main",
)
