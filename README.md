# ShelfSpaceAllocation
![](docs/src/figures/planogram.svg)

[![Docs Image](https://img.shields.io/badge/docs-latest-blue.svg)](https://gamma-opt.github.io/ShelfSpaceAllocation.jl/dev/)
![Runtests](https://github.com/gamma-opt/ShelfSpaceAllocation.jl/workflows/Runtests/badge.svg)

This package contains an optimization model for solving the *shelf space allocation problem (SSAP)* in the context of retail stores, formulated as *mixed-integer linear program (MILP)*. We intended the package for both developing and running the model. It includes the model, visualization capabilities, input/output related functions, and example instances. The documentation covers how to use the package, its functionalities, and the model in detail.

This package is a part of a research project at the Systems Analysis Laboratory at Aalto University, authored by *Fabricio Oliveira* and *Jaan Tollander de Balsch*.


## Examples
|Attribute|Small|Medium|Large|
|---------|-----|-------|------|
|Products |118  |221    |193   |
|Shelves  |7    |7      |10    |
|Blocks   |7    |9      |23    |
|Modules  |1    |1      |2     |

There are three example cases available: `small`, `medium` and `large` with sizes described in the table above. The example script below shows how to solve these instances with `ShelfSpaceAllocation.jl` using the Gurobi optimizer.

```julia
using Dates, JuMP, Gurobi
using ShelfSpaceAllocation

case = "small"
output_dir = "examples/output/$case/$(string(Dates.now()))"
mkpath(output_dir)

parameters = Params(
    "examples/instances/$case/products.csv",
    "examples/instances/$case/shelves.csv"
)
specs = Specs(height_placement=true, blocking=true)
model = ShelfSpaceAllocationModel(parameters, specs)

optimizer = optimizer_with_attributes(
    () -> Gurobi.Optimizer(Gurobi.Env()),
    "TimeLimit" => 5*60,
    "MIPFocus" => 3,
    "MIPGap" => 0.01,
)
set_optimizer(model, optimizer)
optimize!(model)

variables = Variables(model)
objectives = Objectives(model)
```

Saving values to JSON.
```julia
save_json(specs, joinpath(output_dir, "specs.json"))
save_json(parameters, joinpath(output_dir, "parameters.json"))
save_json(variables, joinpath(output_dir, "variables.json"))
save_json(objectives, joinpath(output_dir, "objectives.json"))
```

Loading values from JSON.
```julia
specs = load_json(Specs, joinpath(output_dir, "specs.json"))
parameters = load_json(Params, joinpath(output_dir, "parameters.json"))
variables = load_json(Variables, joinpath(output_dir, "variables.json"))
objectives = load_json(Objectives, joinpath(output_dir, "objectives.json"))
```

The [plotting](https://gamma-opt.github.io/ShelfSpaceAllocation.jl/plotting/) section of the documentation shows how to visualize the results.

Example of *relax-and-fix* and *fix-and-optimize* heuristics is available in  [`heuristics.jl`](./examples/heuristics.jl) file.

## Installation
Install the [Julia language](https://julialang.org/) and then install this package.

```bash
pkg> add https://github.com/gamma-opt/ShelfSpaceAllocation.jl
```

## Development
Clone the repository
```bash
git clone https://github.com/gamma-opt/ShelfSpaceAllocation.jl
```

Install dependencies
```
pkg> dev .
```

Install solver such as Gurobi.


## Installing Solver
It's up to the user to choose a suitable solver for solving the JuMP model. For small instance GLPK is sufficient but for large instances, commercial solver such as Gurobi or CPLEX is recommended.

Gurobi is a powerful commercial optimizer which provides a free academic license. Gurobi can be interfaced with Julia using [`Gurobi.jl`](https://github.com/JuliaOpt/Gurobi.jl). Here are the steps to install Julia and Gurobi to run the program:

1) Obtain a license of *Gurobi* and install Gurobi solver by following the instructions on [Gurobi's website](http://www.gurobi.com/).

2) Make sure the `GUROBI_HOME` environmental variable is set to the path of the Gurobi directory. This is part of standard installation. The Gurobi library will be searched for in `GUROBI_HOME/lib` on Unix platforms and `GUROBI_HOME\bin` on Windows. If the library is not found, check that your version is listed in `deps/build.jl`. The environmental variable can be set by appending `export GUROBI_HOME="<path>/gurobi811/linux64"` to `.bashrc` file. Replace the `<path>`, platform `linux64` and version number `811` with the values of your Gurobi installation.

3) Install `Gurobi.jl` in Julia's package manager by running commands
   ```
   pkg> add Gurobi
   pkg> build Gurobi
   ```


## Documentation
The project documentation is created using [Documenter.jl](https://juliadocs.github.io/Documenter.jl/stable/). To build the documentation, navigate inside the `docs` directory and run the command
```bash
julia make.jl
```
