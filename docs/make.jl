using Documenter

push!(LOAD_PATH, dirname(@__DIR__))
using ShelfSpaceAllocation

makedocs(
    sitename = "ShelfSpaceAllocation",
    format = Documenter.HTML(
        assets = ["assets/favicon.ico"]
    ),
    modules = [ShelfSpaceAllocation],
    authors = "Jaan Tollander de Balsch, Fabricio Oliveira",
    pages = [
        "Home" => "index.md",
        "model.md",
        "plotting.md",
        "io.md",
        "heuristics.md",
        "api.md"
    ]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
# deploydocs(
#     repo = "github.com/jaantollander/ShelfSpaceAllocation.jl.git",
#     target = "build/"
# )
