# Shelf Space Allocation
## Installation
1) Download [**Julia Language**](https://julialang.org/) for your platform. Make sure that Julia can be found in the path by typing `julia` in the terminal. If Julia REPL doesn't open, add the Julia binaries to the path by appending `export PATH="<path>/julia-1.0.0/bin:$PATH` to `.bashrc` file located in the home directory. Replace `<path>` with the path where the binaries are located and the version number with the version you downloaded. 

2) Obtain a license of **Gurobi** and install Gurobi solver by following the instructions on [Gurobi's website](http://www.gurobi.com/). Students can obtain an academic license for free.

3) Make sure the `GUROBI_HOME` environmental variable is set to the path of the Gurobi directory. This is part of standard installation. The Gurobi library will be searched for in `GUROBI_HOME/lib` on Unix platforms and `GUROBI_HOME\bin` on Windows. If the library is not found, check that your version is listed in `deps/build.jl`. The environmental variable can be set by appending `export GUROBI_HOME="<path>/gurobi811/linux64"` to `.bashrc` file. Replace the `<path>`, platform `linux64` and version number `811` with the values of your Gurobi installation.


## Dependencies
This package requires Julia version 1.0 or above. It also depends on the following Julia packages:

- [CSV.jl](https://juliadata.github.io/CSV.jl/stable/) -- Reading and writing input and output files in CSV format.
- [JuMP.jl](https://github.com/JuliaOpt/JuMP.jl) -- Modeling language for mathematical optimization. Used for formulating the **Mixed Integer Linear Program** (MILP).
- [Gurobi.jl](https://github.com/JuliaOpt/Gurobi.jl) -- Julia interface for Gurobi solver used for solving the MILP.

<!-- TODO: In Julia REPL run `using Pkg; Pkg.build("Gurobi")` -->


## Documentation
The project documentation is created using [Documenter.jl](https://juliadocs.github.io/Documenter.jl/stable/).

In the projects root directory, add the `ShelfSpaceAllocation` package locally from Julia REPL by running
```julia
using Pkg: Pkg.add(".")
```

In order to build the documentation, navigate inside the `docs` directory and run the command
```bash
julia make.jl
```
