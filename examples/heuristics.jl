using Parameters, Dates, JuMP, Gurobi, Plots, Logging

push!(LOAD_PATH, dirname(@__DIR__))
using ShelfSpaceAllocation


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

"""Partition array into subarrays of size n."""
function partition(n::Integer, array::Array)
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

# TODO: plots
# p1 = plot_planogram_no_blocks(products, shelves, blocks, P_b, H_s, H_p, W_p, W_s, SK_p, n_ps, o_s)
# savefig(p1, joinpath(output_dir, "planogram_no_blocks.svg"))
# p2 = fill_amount(shelves, blocks, P_b, n_ps)
# savefig(p2, joinpath(output_dir, "fill_amount_no_blocks.svg"))


# --- Block partitions ---
@info "Define block partitions"
@unpack shelves, blocks, P_b = parameters

n_ps = value.(model1[:n_ps])
amounts = round.(
    [sum(n_ps[p, s] for s in shelves for p in P_b[b]) for b in blocks])
block_indices = reverse(sortperm(amounts))
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

# n_ps = variables[:n_ps]
# o_s = variables[:o_s]
# b_bs = variables[:b_bs]
# x_bs = variables[:x_bs]
# z_bs = variables[:z_bs]
# p1 = planogram(products, shelves, blocks, P_b, H_s, H_p, W_p, W_s, SK_p, n_ps, o_s, x_bs)
# savefig(p1, joinpath(output_dir, "planogram_relax_and_fix.svg"))
# p2 = block_allocation(shelves, blocks, H_s, W_s, b_bs, x_bs, z_bs)
# savefig(p2, joinpath(output_dir, "block_allocation_relax_and_fix.svg"))


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

# @info "Saving the results"
# TODO: save_results


# @info "Plotting planogram"
# p1 = planogram(products, shelves, blocks, P_b, H_s, H_p, W_p, W_s, SK_p, n_ps, o_s, x_bs)
# savefig(p1, joinpath(output_dir, "planogram.svg"))
#
# @info "Plotting block allocation"
# p2 = block_allocation(shelves, blocks, H_s, W_s, b_bs, x_bs, z_bs)
# savefig(p2, joinpath(output_dir, "block_allocation.svg"))
#
# @info "Plotting product facings"
# p3 = product_facings(products, shelves, blocks, P_b, N_p_max, n_ps)
# savefig(p3, joinpath(output_dir, "product_facings.svg"))
#
# # FIXME
# # @info "Plotting demand and sales"
# # p4 = demand_and_sales(blocks, P_b, D_p, s_p)
# # savefig(p4, joinpath(output_dir, "demand_and_sales.svg"))
#
# @info "Plotting fill amount"
# p5 = fill_amount(shelves, blocks, P_b, n_ps)
# savefig(p5, joinpath(output_dir, "fill_amount.svg"))
#
# @info "Plotting fill percentage"
# p6 = fill_percentage(
#     n_ps, products, shelves, blocks, modules, P_b, S_m, G_p, H_s, L_p, P_ps,
#     D_p, N_p_min, N_p_max, W_p, W_s, M_p, M_s_min, M_s_max, R_p, L_s, H_p,
#     with_optimizer(Gurobi.Optimizer, TimeLimit=60, LogToConsole=false))
# savefig(p6, joinpath(output_dir, "fill_percentage.svg"))

# close(io)
