using Documenter

project_dir = dirname(@__DIR__)
push!(LOAD_PATH, project_dir)
using ShelfSpaceAllocation

makedocs(
    sitename = "ShelfSpaceAllocation",
    format = Documenter.HTML(),
    modules = [ShelfSpaceAllocation]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "github.com/jaantollander/ShelfSpaceAllocation.jl.git"
)=#
