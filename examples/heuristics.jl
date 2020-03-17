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
function relax_and_fix(parameters::Params, specs::Specs, block_partitions, optimizer)
    # Remember fixed blocks and values
    relaxed_blocks = block_partitions[2:end]
    # TODO: test fixing related n_ps variables too for faster runtime
    fixed_blocks = []
    z_bs = []
    b_bs = []
    model = ShelfSpaceAllocationModel()
    for block in block_partitions
        # Solve the shelf space allocation model with a subset of blocks
        model = ShelfSpaceAllocationModel(parameters, specs)

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

        push!(fixed_blocks, block)
        push!(b_bs, value.(model[:b_bs]))
        push!(z_bs, value.(model[:z_bs]))
    end

    return model
end

"""Fix-and-optimize heuristic."""
function fix_and_optimize(parameters::Params, specs::Specs, z_bs, w_bb)
    @unpack blocks, shelves = parameters
    model = ShelfSpaceAllocationModel(parameters, specs)

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
case = "large" # ∈ Set("small", "medium", "large")
partition_size = Dict(
    "small" => 4,
    "medium" => 2,
    "large" => 6
)[case]
block_partition_order = Dict(
    "small" => "increasing",
    "medium" => "decreasing",
    "large" => "increasing"
)[case]
product_path = joinpath(@__DIR__, "instances", case, "products.csv")
shelf_path = joinpath(@__DIR__, "instances", case, "shelves.csv")
output_dir = joinpath(@__DIR__, "output_heuristics", case, string(Dates.now()))

@info "Creating output directory"
mkpath(output_dir)

@info "Arguments" product_path shelf_path output_dir

@info "Loading parameters"
parameters = Params(product_path, shelf_path)
save_json(parameters, joinpath(output_dir, "parameters.json"))


# --- Space allocation without blocks ---
@info "Space allocation without blocks"
specs1 =Specs(height_placement=false, blocking=false)
model1 = ShelfSpaceAllocationModel(parameters, specs1)

optimizer1 = with_optimizer(
    Gurobi.Optimizer,
    TimeLimit=60,
    LogFile=joinpath(output_dir, "grb_ssa_no_blocks.log"),
    MIPGap=0.01
)
optimize!(model1, optimizer1);

variables1 = Variables(model1)
objectives1 = Objectives(model1)
save_json(variables1, joinpath(output_dir, "variables1.json"))
save_json(objectives1, joinpath(output_dir, "objectives1.json"))


# --- Block partitions ---
@info "Define block partitions"

@unpack shelves, blocks, P_b = parameters
n_ps = value.(model1[:n_ps])

# Amount of products allocated per block.
amounts = round.(
    [sum(n_ps[p, s] for s in shelves for p in P_b[b]) for b in blocks])

if block_partition_order == "decreasing"
    # Blocks from highest to lowest amount of product allocated per block.
    block_indices = reverse(sortperm(amounts))
elseif block_partition_order == "increasing"
    block_indices = sortperm(amounts)
else
    error("No block partition order: $block_partition_order")
end

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
specs2 = Specs(height_placement=false, blocking=true)
model2 = relax_and_fix(parameters, specs2, block_partitions, optimizer2)

variables2 = Variables(model2)
objectives2 = Objectives(model2)
save_json(variables2, joinpath(output_dir, "variables2.json"))
save_json(objectives2, joinpath(output_dir, "objectives2.json"))


# --- Fix-and-Optimize Heuristic ---
@info "Fix-and-optimize"
model3 = fix_and_optimize(
    parameters, specs2, value.(model2[:z_bs]), value.(model2[:w_bb]))

optimizer3 = with_optimizer(
    Gurobi.Optimizer,
    TimeLimit=2*60,
    LogFile=joinpath(output_dir, "grb_fix_and_optimize.log"),
    MIPFocus=3,
    MIPGap=0.005
)
optimize!(model3, optimizer3)

variables3 = Variables(model3)
objectives3 = Objectives(model3)
save_json(variables3, joinpath(output_dir, "variables3.json"))
save_json(objectives3, joinpath(output_dir, "objectives3.json"))


@info "Plotting"

# --- Plotting 1 ---
ps = plot_planograms_no_blocks(parameters, variables1)
for (i, p) in enumerate(ps)
    savefig(p, joinpath(output_dir, "planogram_no_blocks_$i.svg"))
end

p = plot_allocation_amount(parameters, variables1)
savefig(p, joinpath(output_dir, "allocation_amount_no_blocks.svg"))


# --- Plotting 2 ---
ps = plot_planograms(parameters, variables2)
for (i, p) in enumerate(ps)
    savefig(p, joinpath(output_dir, "planogram_relax_and_fix_$i.svg"))
end


# --- Plotting 3 ---
ps = plot_planograms(parameters, variables3)
for (i, p) in enumerate(ps)
    savefig(p, joinpath(output_dir, "planogram_$i.svg"))
end

p = plot_product_facings(parameters, variables3)
savefig(p, joinpath(output_dir, "product_facings.svg"))

p = plot_demand_and_sales(parameters, variables3)
savefig(p, joinpath(output_dir, "demand_and_sales.svg"))

p = plot_demand_sales_percentage(parameters, variables3)
savefig(p, joinpath(output_dir, "demand_sales_percentage.svg"))

p = plot_allocation_amount(parameters, variables3)
savefig(p, joinpath(output_dir, "allocation_amount.svg"))

p = plot_allocation_percentage(
    parameters, variables3,
    with_optimizer(Gurobi.Optimizer, TimeLimit=60, LogToConsole=false))
savefig(p, joinpath(output_dir, "allocation_percentage.svg"))
