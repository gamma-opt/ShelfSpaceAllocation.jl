using Dates, JuMP, Gurobi, Plots, Logging

push!(LOAD_PATH, dirname(@__DIR__))
using ShelfSpaceAllocation

"""Heuristic algorithm"""
function relax_and_fix(
        products, shelves, blocks, modules, P_b, S_m, G_p, H_s, L_p,
        P_ps, D_p, N_p_min, N_p_max, W_p, W_s, M_p, M_s_min, M_s_max, R_p, L_s,
        H_p, SL, block_partitions, optimizer; w_1=0.5, w_2=10.0, w_3=0.1)
    # Remember fixed blocks and values
    relaxed_blocks = block_partitions[2:end]
    # TODO: test fixing related n_ps variables too for faster runtime
    fixed_blocks = []
    z_bs = []
    x_bs = []
    b_bs = []
    model = nothing
    for block in block_partitions
        # Solve the shelf space allocation model with a subset of blocks
        model = shelf_space_allocation_model(
            products, shelves, blocks, modules, P_b, S_m, G_p, H_s, L_p, P_ps,
            D_p, N_p_min, N_p_max, W_p, W_s, M_p, M_s_min, M_s_max, R_p, L_s,
            H_p, SL; w_1=w_1, w_2=w_2, w_3=w_3)

        # Relaxed values
        for relaxed_block in relaxed_blocks
            for b in relaxed_block
                for s in shelves
                    unset_binary(model.obj_dict[:z_bs][b, s])
                    unset_binary(model.obj_dict[:z_bs_f][b, s])
                    unset_binary(model.obj_dict[:z_bs_l][b, s])
                end
            end
        end

        # Fixed values
        for (i, fixed_block) in enumerate(fixed_blocks)
            for b in fixed_block
                for s in shelves
                    unset_binary(model.obj_dict[:z_bs][b, s])
                    fix(model.obj_dict[:x_bs][b, s], x_bs[i][b, s], force=true)
                    fix(model.obj_dict[:b_bs][b, s], b_bs[i][b, s], force=true)
                    fix(model.obj_dict[:z_bs][b, s], z_bs[i][b, s], force=true)
                end
            end
        end

        optimize!(model, optimizer)

        if termination_status(model) == MOI.INFEASIBLE
            exit()
        end

        # Decrease relaxed blocks
        relaxed_blocks = relaxed_blocks[2:end]

        # TODO: move x_bs as far left as possible without overlapping
        push!(fixed_blocks, block)
        push!(x_bs, value.(model.obj_dict[:x_bs]))
        push!(b_bs, value.(model.obj_dict[:b_bs]))
        push!(z_bs, value.(model.obj_dict[:z_bs]))
    end

    return model
end

# --- Arguments ---

time_limit = 3*60 # Seconds
product_path = joinpath(@__DIR__, "data", "Anonymized space allocation data for 9900-shelf.csv")
shelf_path = joinpath(@__DIR__, "data", "scenario_9900_shelves.csv")
output_dir = joinpath(@__DIR__, "output_heuristics", string(Dates.now()))

# ---

@info "Creating output directory"
mkpath(output_dir)

io = open(joinpath(output_dir, "shelf_space_allocation.log"), "w+")
logger = SimpleLogger(io)
global_logger(logger)

@info "Arguments" time_limit product_path shelf_path output_dir

@info "Loading parameters"
parameters = load_parameters(product_path, shelf_path)
(products, shelves, blocks, modules, P_b, S_m, G_p, H_s, L_p, P_ps, D_p,
    N_p_min, N_p_max, W_p, W_s, M_p, M_s_min, M_s_max, R_p, L_s, H_p, SK_p, SL) = parameters

@info "Creating the model"
optimizer = with_optimizer(
    Gurobi.Optimizer,
    TimeLimit=time_limit,
    LogFile=joinpath(output_dir, "gurobi.log"),
    MIPFocus=3,
    MIPGap=0.01,
    # Presolve=2,
)
block_partitions = [[7, 1], [6, 8], [2, 4], [9, 3, 5]]
model = relax_and_fix(
    products, shelves, blocks, modules, P_b, S_m, G_p, H_s, L_p,
    P_ps, D_p, N_p_min, N_p_max, W_p, W_s, M_p, M_s_min, M_s_max, R_p, L_s,
    H_p, SL, block_partitions, optimizer; w_1=0.5, w_2=10.0, w_3=0.1)

@info "Saving the results"
variables = Dict(k => value.(v) for (k, v) in model.obj_dict)
# variables = extract_variables(model)
# objectives = extract_objectives(parameters, variables)
# save_results(parameters, variables, objectives; output_dir=output_dir)

n_ps = variables[:n_ps]
s_p = variables[:s_p]
o_s = variables[:o_s]
b_bs = variables[:b_bs]
x_bs = variables[:x_bs]
z_bs = variables[:z_bs]

@info "Plotting planogram"
p1 = planogram(products, shelves, blocks, P_b, H_s, H_p, W_p, W_s, SK_p, n_ps, o_s, x_bs)
savefig(p1, joinpath(output_dir, "planogram.svg"))

@info "Plotting product facings"
p2 = product_facings(products, shelves, blocks, P_b, N_p_max, n_ps)
savefig(p2, joinpath(output_dir, "product_facings.svg"))

@info "Plotting block allocation"
p3 = block_allocation(shelves, blocks, H_s, W_s, b_bs, x_bs, z_bs)
savefig(p3, joinpath(output_dir, "block_allocation.svg"))

@info "Plotting fill amount"
p4 = fill_amount(shelves, blocks, P_b, n_ps)
savefig(p4, joinpath(output_dir, "fill_amount.svg"))

@info "Plotting fill percentage"
p5 = fill_percentage(
    n_ps, products, shelves, blocks, modules, P_b, S_m, G_p, H_s, L_p, P_ps,
    D_p, N_p_min, N_p_max, W_p, W_s, M_p, M_s_min, M_s_max, R_p, L_s, H_p,
    with_optimizer(Gurobi.Optimizer, TimeLimit=60))
savefig(p5, joinpath(output_dir, "fill_percentage.svg"))

# @info "Plotting demand and sales"
# p6 = demand_and_sales(blocks, P_b, D_p, s_p)
# savefig(p6, joinpath(output_dir, "demand_and_sales.svg"))

close(io)
