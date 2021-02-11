using Documenter
using BioGraph

makedocs(
    sitename="BioGraph",
    format=Documenter.HTML(),
    modules=[BioGraph],
    pages=[
        "Home" => "index.md",
        "Function" => "function.md"
    ],
    authors="Nguyet Dang, Tuan Do, Francois Sabot and other contributors."
)

deploydocs(
    repo="https://github.com/nguyetdang/BioGraph.jl"
)
