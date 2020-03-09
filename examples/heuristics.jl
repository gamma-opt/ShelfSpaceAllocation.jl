using Parameters, Dates, JuMP, Gurobi, Plots, Logging

push!(LOAD_PATH, dirname(@__DIR__))
using ShelfSpaceAllocation


"""Partition array into subarrays of size n."""
function partition(n::Integer, array::Array{T}):: Array{Array{T}} where T
    r = []
    i = 0
    m = div(length(array), n)
    for _ in 1:(m-1)
        push!(r, [array[j+i] for j in 1:n])
        i += n
    end
    push!(r, array[(i+1):end])
    return r
end

"""Relax-and-fix heuristic."""
function relax_and_fix(parameters::Params, block_partitions, optimizer)
    # Remember fixed blocks and values
    relaxed_blocks = block_partitions[2:end]
    # TODO: test fixing related n_ps variables too for faster runtime
    fixed_blocks = []
    z_bs = []
    x_bs = []
    b_bs = []
    model = ShelfSpaceAllocationModel()
    for block in block_partitions
        # Solve the shelf space allocation model with a subset of blocks
        model = ShelfSpaceAllocationModel(parameters, Specs(blocking=true))

        # Relaxed values
        for relaxed_block in relaxed_blocks
            for b in relaxed_block, s in parameters.shelves
                unset_binary(model[:z_bs][b, s])
                unset_binary(model[:z_bs_f][b, s])
                unset_binary(model[:z_bs_l][b, s])
            end
        end

        # Fixed values
        for (i, fixed_block) in enumerate(fixed_blocks)
            for b in fixed_block, s in parameters.shelves
                unset_binary(model[:z_bs][b, s])
                fix(model[:x_bs][b, s], x_bs[i][b, s], force=true)
                fix(model[:b_bs][b, s], b_bs[i][b, s], force=true)
                fix(model[:z_bs][b, s], z_bs[i][b, s], force=true)
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
        push!(x_bs, value.(model[:x_bs]))
        push!(b_bs, value.(model[:b_bs]))
        push!(z_bs, value.(model[:z_bs]))
    end

    return model
end

"""Fix-and-optimize heuristic."""
function fix_and_optimize(parameters::Params, z_bs, w_bb)
    @unpack blocks, shelves = parameters
    model = ShelfSpaceAllocationModel(parameters, Specs(blocking=true))

    # Fix z_bb variables
    for b in blocks, s in shelves
        unset_binary(model[:z_bs][b, s])
        fix(model[:z_bs][b, s], z_bs[b, s])
    end

    # Fix w_bb variables
    for b in blocks, b′ in blocks
        unset_binary(model[:w_bb][b, b′])
        fix(model[:w_bb][b, b′], w_bb[b, b′])
    end

    return model
end


# --- Arguments ---
case = "small"
partition_size = 3
product_path = joinpath(@__DIR__, "instances", case, "products.csv")
shelf_path = joinpath(@__DIR__, "instances", case, "shelves.csv")
output_dir = joinpath(@__DIR__, "output_heuristics", case, string(Dates.now()))

@info "Creating output directory"
mkpath(output_dir)

# io = open(joinpath(output_dir, "shelf_space_allocation.log"), "w+")
# logger = SimpleLogger(io)
# global_logger(logger)

@info "Arguments" product_path shelf_path output_dir

@info "Loading parameters"
parameters = Params(product_path, shelf_path)
save_json(parameters, joinpath(output_dir, "parameters.json"))

# We need the raw values later.
@unpack products, shelves, blocks, modules, P_b, S_m, N_p_min, N_p_max,
        G_p, R_p, D_p, L_p, W_p, H_p, M_p, SK_p, M_s_min, M_s_max, W_s,
        H_s, L_s, P_ps, SL, w1, w2, w3 = parameters


# --- Space allocation without blocks ---
@info "Space allocation without blocks"
model1 = ShelfSpaceAllocationModel(parameters, Specs(blocking=false))

optimizer1 = with_optimizer(
    Gurobi.Optimizer,
    TimeLimit=60,
    LogFile=joinpath(output_dir, "grb_ssa_no_blocks.log"),
    MIPGap=false
)
optimize!(model1, optimizer1);

variables1 = Variables(model1)
objectives1 = Objectives(model1)
save_json(variables1, joinpath(output_dir, "variables1.json"))
save_json(objectives1, joinpath(output_dir, "objectives1.json"))


# --- Block partitions ---
@info "Define block partitions"
n_ps = value.(model1[:n_ps])

# Amount of products allocated per block.
amounts = round.(
    [sum(n_ps[p, s] for s in shelves for p in P_b[b]) for b in blocks])

# Blocks from highest to lowest amount of product allocated per block.
block_indices = reverse(sortperm(amounts))

# Partition the blocks into arrays of partition size
block_partitions = partition(partition_size, block_indices)

@info amounts block_indices block_partitions


# --- Relax-and-Fix Heuristic ---
@info "Relax-and-fix"
optimizer2 = with_optimizer(
    Gurobi.Optimizer,
    TimeLimit=5*60,
    LogFile=joinpath(output_dir, "grb_relax_and_fix.log"),
    MIPFocus=3,
    MIPGap=0.01
)
model2 = relax_and_fix(parameters, block_partitions, optimizer2)

variables2 = Variables(model2)
objectives2 = Objectives(model2)
save_json(variables2, joinpath(output_dir, "variables2.json"))
save_json(objectives2, joinpath(output_dir, "objectives2.json"))


# --- Fix-and-Optimize Heuristic ---
@info "Fix-and-optimize"
model3 = fix_and_optimize(
    parameters, value.(model2[:z_bs]), value.(model2[:w_bb]))

optimizer3 = with_optimizer(
    Gurobi.Optimizer,
    TimeLimit=60,
    LogFile=joinpath(output_dir, "grb_fix_and_optimize.log"),
    MIPFocus=3,
    MIPGap=false
)
optimize!(model3, optimizer3)

variables3 = Variables(model3)
objectives3 = Objectives(model3)
save_json(variables3, joinpath(output_dir, "variables3.json"))
save_json(objectives3, joinpath(output_dir, "objectives3.json"))


# --- Plotting 1 ---
@unpack n_ps, o_s = variables1

# TODO: handle modules
p1 = plot_planogram_no_blocks(products, shelves, blocks, P_b, H_s, H_p, W_p, W_s, SK_p, n_ps, o_s)
savefig(p1, joinpath(output_dir, "planogram_no_blocks.svg"))

p2 = plot_allocation_amount(shelves, blocks, P_b, n_ps)
savefig(p2, joinpath(output_dir, "allocation_amount_no_blocks.svg"))


# --- Plotting 2 ---
@unpack n_ps, o_s, b_bs, x_bs, z_bs = variables2

p1 = plot_planogram(products, shelves, blocks, P_b, H_s, H_p, W_p, W_s, SK_p, n_ps, o_s, x_bs)
savefig(p1, joinpath(output_dir, "planogram_relax_and_fix.svg"))

p2 = plot_block_allocation(shelves, blocks, H_s, W_s, b_bs, x_bs, z_bs)
savefig(p2, joinpath(output_dir, "block_allocation_relax_and_fix.svg"))


# --- Plotting 3 ---
@unpack n_ps, o_s, x_bs, z_bs, s_p = variables3

@info "Plotting planogram"
p1 = plot_planogram(products, shelves, blocks, P_b, H_s, H_p, W_p, W_s, SK_p, n_ps, o_s, x_bs)
savefig(p1, joinpath(output_dir, "planogram.svg"))

@info "Plotting block allocation"
p2 = plot_block_allocation(shelves, blocks, H_s, W_s, b_bs, x_bs, z_bs)
savefig(p2, joinpath(output_dir, "block_allocation.svg"))

@info "Plotting product facings"
p3 = plot_product_facings(products, shelves, blocks, P_b, N_p_max, n_ps)
savefig(p3, joinpath(output_dir, "product_facings.svg"))

@info "Plotting demand and sales"
p4 = plot_demand_and_sales(blocks, P_b, D_p, s_p)
savefig(p4, joinpath(output_dir, "demand_and_sales.svg"))

@info "Plotting allocation amount"
p5 = plot_allocation_amount(shelves, blocks, P_b, n_ps)
savefig(p5, joinpath(output_dir, "allocation_amount.svg"))

@info "Plotting allocation percentage"
p6 = plot_allocation_percentage(
    parameters, n_ps,
    with_optimizer(Gurobi.Optimizer, TimeLimit=60, LogToConsole=false))
savefig(p6, joinpath(output_dir, "allocation_percentage.svg"))

# close(io)
