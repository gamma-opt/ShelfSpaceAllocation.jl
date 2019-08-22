# Guide
This section explains how to install and get started with `ShelfSpaceAllocation.jl`.


## Installation
This package depends on [Julia Language](https://julialang.org/) version 1.0.4, which can be downloaded from the download page. Make sure that Julia can be found in the path by typing `julia` in the terminal or command-line. Make sure that Julia can be found in the path by typing `julia` in the terminal. On Ubuntu, if Julia REPL doesn't open, add the Julia binaries to the path by appending `export PATH="<path>/julia-1.0.4/bin:$PATH` to `.bashrc` file located in the home directory. Replace `<path>` with the path where the binaries are located.

`ShelfSpaceAllocation.jl` can be installed from GitHub using Julia's package manager

```
pkg> add https://github.com/jaantollander/ShelfSpaceAllocation.jl
```


## Solver
The `shelf_space_allocation_model` function returns the mathematical model which is implemented using `JuMP.jl`. It's up to the user to choose a suitable solver for solving the MILP model. For small instance GLPK is sufficient but for large instances, commercial solver such as Gurobi or CPLEX is recommended.

Gurobi is a powerful commercial optimizer which provides a free academic license. Gurobi can be interfaced with Julia using [`Gurobi.jl`](https://github.com/JuliaOpt/Gurobi.jl). Here are the steps to install Julia and Gurobi to run the program:

1) Obtain a license of *Gurobi* and install Gurobi solver by following the instructions on [Gurobi's website](http://www.gurobi.com/).

2) Make sure the `GUROBI_HOME` environmental variable is set to the path of the Gurobi directory. This is part of standard installation. The Gurobi library will be searched for in `GUROBI_HOME/lib` on Unix platforms and `GUROBI_HOME\bin` on Windows. If the library is not found, check that your version is listed in `deps/build.jl`. The environmental variable can be set by appending `export GUROBI_HOME="<path>/gurobi811/linux64"` to `.bashrc` file. Replace the `<path>`, platform `linux64` and version number `811` with the values of your Gurobi installation.

3) Install `Gurobi.jl` in Julia's package manager by running commands
   ```
   pkg> add Gurobi
   pkg> build Gurobi
   ```


## Examples
Examples are located in the `examples` directory. Inside, the `script.jl` the file demonstrates how to run the optimization model on different example instances. Example instances can be found from the `examples/instances` directory. There are three instances in total, *small*, *medium* and *large*, named by their relative size. The computational complexity of solving the instances increases as the size increases.

```@example
using CSV #hide
using Latexify #hide
df = CSV.read(joinpath("tables", "examples.csv")) #hide
mdtable(df,latex=false) #hide
```

## Documentation
The project documentation is created using [Documenter.jl](https://juliadocs.github.io/Documenter.jl/stable/). To build the documentation, navigate inside the `docs` directory and run the command
```bash
julia make.jl
```
