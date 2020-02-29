using Dates, Logging

push!(LOAD_PATH, dirname(@__DIR__))
using ShelfSpaceAllocation

# --- Arguments ---

time_limit = 3*60 # Seconds
mip_gap = 0.01
case = "medium"
product_path = joinpath(@__DIR__, "instances", case, "products.csv")
shelf_path = joinpath(@__DIR__, "instances", case, "shelves.csv")
output_dir = joinpath(@__DIR__, "output", case, string(Dates.now()))

# ---

@info "Creating output directory"
mkpath(output_dir)

io = open(joinpath(output_dir, "shelf_space_allocation.log"), "w+")
logger = SimpleLogger(io)
global_logger(logger)

@info "Arguments" time_limit product_path shelf_path output_dir

@info "Loading parameters"
parameters = Params(product_path, shelf_path)
specs = Specs(blocking=true)

@info "Creating the model"
model = ShelfSpaceAllocationModel(parameters, specs)

# # Fix the block width
# @constraint(model, [b = blocks, s = shelves],
#     model[:b_bs][b, s] == W_s[s]/2 * model[:z_bs][b, s]);

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

@info "Variables and Objectives"
variables = Variables(model)
objectives = Objectives(model)

@info "Saving the results"
save_results(parameters, variables, objectives, output_dir)

# @info "Plotting"
# using Plots, Parameters
# @unpack n_ps, s_p, o_s, b_bs, x_bs, z_bs = variables
#
# @info "Plotting planogram"
# p1 = planogram(products, shelves, blocks, S_m, P_b, H_s, H_p, W_p, W_s, SK_p, n_ps, o_s, x_bs)
# for (i, p) in enumerate(p1)
#     savefig(p, joinpath(output_dir, "planogram_$i.svg"))
# end
#
# @info "Plotting block allocation"
# p2 = block_allocation(shelves, blocks, S_m, H_s, W_s, b_bs, x_bs, z_bs)
# for (i, p) in enumerate(p2)
#     savefig(p, joinpath(output_dir, "block_allocation_$i.svg"))
# end
#
# @info "Plotting product facings"
# p3 = product_facings(products, shelves, blocks, P_b, N_p_max, n_ps)
# savefig(p3, joinpath(output_dir, "product_facings.svg"))
#
# @info "Plotting demand and sales"
# p4 = demand_and_sales(blocks, P_b, D_p, s_p)
# savefig(p4, joinpath(output_dir, "demand_and_sales.svg"))
#
# @info "Plotting fill amount"
# p5 = fill_amount(shelves, blocks, P_b, n_ps)
# savefig(p5, joinpath(output_dir, "fill_amount.svg"))
#
# @info "Plotting fill percentage"
# p6 = fill_percentage(
#     n_ps, products, shelves, blocks, modules, P_b, S_m, G_p, H_s, L_p, P_ps,
#     D_p, N_p_min, N_p_max, W_p, W_s, M_p, M_s_min, M_s_max, R_p, L_s, H_p,
#     with_optimizer(Gurobi.Optimizer, TimeLimit=60))
# savefig(p6, joinpath(output_dir, "fill_percentage.svg"))

close(io)
