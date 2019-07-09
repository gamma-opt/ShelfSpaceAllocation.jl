# ShelfSpaceAllocation.jl
![](figures/planogram.svg)

A package containing an optimization model, written as *mixed-integer linear program (MILP)*, for solving the *Shelf Space Allocation Problem (SSAP)* in the context of retail stores, utilities for loading input parameters from files, utilities for saving results into files and utilities for visualizing results. The documentation covers the formulation of the optimization model in detail and how to interpret the results from the optimization.

The optimization model is written using JuMP.jl, input parameters are loaded using CSV.jl, saving the results into files is implemented using JSON.jl and the plotting is implemented using Plots.jl. The optimizer backend is not specified in the package requirements, but for large instances, a commercial solver such as Gurobi or CPLEX is recommended

This package is a part of a research project at the Systems Analysis Laboratory at Aalto University and its authors are *Jaan Tollander de Balsch* and *Fabricio Oliveira*.
