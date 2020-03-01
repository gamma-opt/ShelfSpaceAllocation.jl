# ShelfSpaceAllocation
![](docs/src/figures/results/planogram.svg)

This package contains an optimization model for solving the *shelf space allocation problem (SSAP)* in the context of retail stores, formulated as *mixed-integer linear program (MILP)*. We intended the package for both developing and running the model. It includes the model, visualization capabilities, input/output related functions, and example instances. The [documentation](http://jaantollander.com/ShelfSpaceAllocation.jl/) covers how to use the package, its functionalities, and the model in detail. Inside the `examples` directory, there are two notebooks, [example.ipynb](./examples/example.ipynb) and [heuristics.ipynb](./examples/heuristics.ipynb), which demonstrate how to use this package.

This package is a part of a research project at the Systems Analysis Laboratory at Aalto University, authored by *Fabricio Oliveira* and *Jaan Tollander de Balsch*.

## Usage
Usage example with Gurobi optimizer.

Three example cases: `small`, `medium` and `large`.

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
specs = Specs(blocking=true)
model = ShelfSpaceAllocationModel(parameters, specs)

optimizer = with_optimizer(
    Gurobi.Optimizer,
    TimeLimit=5*60,
    MIPFocus=3,
    MIPGap=0.01,
)
optimize!(model, optimizer)

variables = Variables(model)
objectives = Objectives(model)

save_json(specs, joinpath(output_dir, "specs.json"))
save_json(parameters, joinpath(output_dir, "parameters.json"))
save_json(variables, joinpath(output_dir, "variables.json"))
save_json(objectives, joinpath(output_dir, "objectives.json"))
```

## Installation
```bash
pkg> add https://github.com/jaantollander/ShelfSpaceAllocation.jl
```

## Development
```bash
git clone https://github.com/jaantollander/ShelfSpaceAllocation.jl
```

Install Julia

Install dependencies

Install Gurobi solver
