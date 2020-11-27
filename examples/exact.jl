using Dates, Logging
using ShelfSpaceAllocation

# --- Arguments ---

time_limit = 3*60 # Seconds
mip_gap = 0.01
case = "medium"
product_path = joinpath(@__DIR__, "instances", case, "products.csv")
shelf_path = joinpath(@__DIR__, "instances", case, "shelves.csv")
output_dir = joinpath(@__DIR__, "output_exact", case, string(Dates.now()))

# ---

@info "Creating output directory"
mkpath(output_dir)

@info "Arguments" time_limit product_path shelf_path output_dir

@info "Loading parameters"
parameters = Params(product_path, shelf_path)
specs = Specs(height_placement=false, blocking=true)

@info "Creating the model"
model = ShelfSpaceAllocationModel(parameters, specs)

# Fix the block width for medium case
# using JuMP
# @constraint(model, [b = parameters.blocks, s = parameters.shelves],
#     model[:b_bs][b, s] == parameters.W_s[s]/2 * model[:z_bs][b, s]);

@info "Starting the optimization"
using JuMP, Gurobi
optimizer = with_optimizer(
    Gurobi.Optimizer,
    TimeLimit=time_limit,
    LogFile=joinpath(output_dir, "gurobi.log"),
    MIPFocus=3,
    MIPGap=mip_gap,
)
optimize!(model, optimizer)

if termination_status(model) == MOI.INFEASIBLE
    exit()
end

@info "Variables"
variables = Variables(model)

@info "Objectives"
objectives = Objectives(model)

@info "Saving the results"
save_json(specs, joinpath(output_dir, "specs.json"))
save_json(parameters, joinpath(output_dir, "parameters.json"))
save_json(variables, joinpath(output_dir, "variables.json"))
save_json(objectives, joinpath(output_dir, "objectives.json"))

@info "Plotting"
using Plots, Parameters

ps = plot_planograms(parameters, variables)
for (i, p) in enumerate(ps)
    savefig(p, joinpath(output_dir, "planogram_$i.svg"))
end

p = plot_product_facings(parameters, variables)
savefig(p, joinpath(output_dir, "product_facings.svg"))

p = plot_demand_and_sales(parameters, variables)
savefig(p, joinpath(output_dir, "demand_and_sales.svg"))

p = plot_demand_sales_percentage(parameters, variables)
savefig(p, joinpath(output_dir, "demand_sales_percentage.svg"))

p = plot_allocation_amount(parameters, variables)
savefig(p, joinpath(output_dir, "allocation_amount.svg"))

p = plot_allocation_percentage(
    parameters, variables,
    with_optimizer(Gurobi.Optimizer, TimeLimit=60, LogToConsole=false))
savefig(p, joinpath(output_dir, "allocation_percentage.svg"))
