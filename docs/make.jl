using Documenter
using ShelfSpaceAllocation

makedocs(
    sitename = "ShelfSpaceAllocation.jl",
    format = Documenter.HTML(
        assets = ["assets/favicon.ico"]
    ),
    modules = [ShelfSpaceAllocation],
    authors = "Jaan Tollander de Balsch, Fabricio Oliveira",
    pages = [
        "Model" => "index.md",
        "plotting.md",
        "heuristics.md",
        "api.md"
    ]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
deploydocs(
    repo = "github.com/gamma-opt/ShelfSpaceAllocation.jl.git"
)
