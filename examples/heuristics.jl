using Dates, JuMP, Gurobi, Plots, Logging

push!(LOAD_PATH, dirname(@__DIR__))
using ShelfSpaceAllocation

function shelf_space_allocation_model_no_blocks(
        products, shelves, blocks, modules, P_b, S_m, G_p, H_s, L_p, P_ps, D_p,
        N_p_min, N_p_max, W_p, W_s, M_p, M_s_min, M_s_max, R_p, L_s, H_p, SL,
        w_1, w_2, w_3)
    # Initialize the model
    model = Model()

    # --- Basic Variables ---
    @variable(model, s_p[products] ≥ 0)
    @variable(model, e_p[products] ≥ 0)
    @variable(model, o_s[shelves] ≥ 0)
    @variable(model, n_ps[products, shelves] ≥ 0, Int)
    @variable(model, y_p[products], Bin)

    # Height and weight constraints
    for p in products
        for s in shelves
            if (H_p[p] > H_s[s]) | (M_p[p] > M_s_max[s])
                fix(n_ps[p, s], 0, force=true)
            end
        end
    end

    # --- Objective ---
    @objective(model, Min,
        w_1 * sum(o_s[s] for s in shelves) +
        w_2 * sum(G_p[p] * e_p[p] for p in products) +
        w_3 * sum(L_p[p] * L_s[s] * n_ps[p, s] for p in products for s in shelves)
    )

    # --- Basic constraints ---
    @constraints(model, begin
        [p = products],
        s_p[p] ≤ sum(30 / R_p[p] * P_ps[p, s] * n_ps[p, s] for s in shelves)
        [p = products],
        s_p[p] ≤ D_p[p]
    end)
    @constraint(model, [p = products],
        s_p[p] + e_p[p] == D_p[p])
    @constraint(model, [p = products],
        sum(n_ps[p, s] for s in shelves) ≥ y_p[p])
    @constraints(model, begin
        [p = products],
        N_p_min[p] * y_p[p] ≤ sum(n_ps[p, s] for s in shelves)
        [p = products],
        sum(n_ps[p, s] for s in shelves) ≤ N_p_max[p] * y_p[p]
    end)
    @constraint(model, [s = shelves],
        sum(W_p[p] * n_ps[p, s] for p in products) + o_s[s] == W_s[s])

    return model
end

# FIXME: handle multiple modules
"""Creates a planogram which visualizes the product placement on the shelves."""
function planogram_no_blocks(products, shelves, blocks, P_b, H_s, H_p, W_p, W_s, SK_p, n_ps, o_s):: Plots.Plot
    block_colors = cgrad(:inferno)

    # Initialize the plot
    plt = plot(
        legend=:none,
        background=:lightgray,
        size=(780, 400)
    )

    # Cumulative shelf heights
    y_s = vcat([0], cumsum([H_s[s] for s in shelves]))

    # Draw products
    rect(x, y, w, h) = Shape(x .+ [0,w,w,0], y .+ [0,0,h,h])
    for s in shelves
        x = 0
        for b in blocks
            for p in P_b[b]
                stack = max(min(div(H_s[s], H_p[p]), SK_p[p]), 1)
                for i in 1:n_ps[p, s]
                    y = 0
                    for j in 1:stack
                        plot!(plt, rect(x, y_s[s]+y, W_p[p], H_p[p]),
                              color=block_colors[b/length(blocks)],
                        )
                        y += H_p[p]
                    end
                    x += W_p[p]
                end
            end
        end
    end

    # Draw shelves
    for s in shelves
        plot!(plt, [0, W_s[s]], [y_s[s-shelves[1]+1], y_s[s-shelves[1]+1]],
              color=:black)
    end
    plot!(plt, [0, W_s[shelves[end]]], [y_s[end], y_s[end]],
          color=:black, linestyle=:dash)

    return plt
end

"""Relax-and-fix heuristic."""
function relax_and_fix(
        products, shelves, blocks, modules, P_b, S_m, G_p, H_s, L_p,
        P_ps, D_p, N_p_min, N_p_max, W_p, W_s, M_p, M_s_min, M_s_max, R_p, L_s,
        H_p, SL, block_partitions, w_1, w_2, w_3, optimizer)
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
            H_p, SL, w_1, w_2, w_3)

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

"""Fix-and-optimize heuristic."""
function fix_and_optimize(
        products, shelves, blocks, modules, P_b, S_m, G_p, H_s, L_p,
        P_ps, D_p, N_p_min, N_p_max, W_p, W_s, M_p, M_s_min, M_s_max, R_p, L_s,
        H_p, SL, z_bs, w_bb, w_1, w_2, w_3)

    model = shelf_space_allocation_model(
        products, shelves, blocks, modules, P_b, S_m, G_p, H_s, L_p, P_ps,
        D_p, N_p_min, N_p_max, W_p, W_s, M_p, M_s_min, M_s_max, R_p, L_s,
        H_p, SL, w_1, w_2, w_3)

    # Fix z_bb variables
    for b in blocks
        for s in shelves
            unset_binary(model.obj_dict[:z_bs][b, s])
            fix(model.obj_dict[:z_bs][b, s], z_bs[b, s])
        end
    end

    # Fix w_bb variables
    for b in blocks
        for b′ in blocks
            unset_binary(model.obj_dict[:w_bb][b, b′])
            fix(model.obj_dict[:w_bb][b, b′], w_bb[b, b′])
        end
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

io = open(joinpath(output_dir, "shelf_space_allocation.log"), "w+")
logger = SimpleLogger(io)
global_logger(logger)

@info "Arguments" product_path shelf_path output_dir

@info "Loading parameters"
parameters = load_parameters(product_path, shelf_path)
(products, shelves, blocks, modules, P_b, S_m, G_p, H_s, L_p, P_ps, D_p,
    N_p_min, N_p_max, W_p, W_s, M_p, M_s_min, M_s_max, R_p, L_s, H_p, SK_p, SL,
    empty_space_penalty, shortage_penalty, shelf_up_down_penalty) = parameters


# --- Space allocation without blocks ---
model1 = shelf_space_allocation_model_no_blocks(
    products, shelves, blocks, modules, P_b, S_m, G_p, H_s, L_p, P_ps, D_p,
    N_p_min, N_p_max, W_p, W_s, M_p, M_s_min, M_s_max, R_p, L_s, H_p, SL,
    empty_space_penalty, shortage_penalty, shelf_up_down_penalty);

optimize!(model1, with_optimizer(
        Gurobi.Optimizer,
        TimeLimit=60,
        LogFile=joinpath(output_dir, "grb_ssa_no_blocks.log"),
        MIPGap=false));

variables = extract_variables(model1)
n_ps = variables[:n_ps]
s_p = variables[:s_p]
o_s = variables[:o_s]
p1 = planogram_no_blocks(products, shelves, blocks, P_b, H_s, H_p, W_p, W_s, SK_p, n_ps, o_s)
savefig(p1, joinpath(output_dir, "planogram_no_blocks.svg"))
p2 = fill_amount(shelves, blocks, P_b, n_ps)
savefig(p2, joinpath(output_dir, "fill_amount_no_blocks.svg"))


# --- Block partitions ---
function partition(n, array)
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

amounts = round.([sum(n_ps[p, s] for s in shelves for p in P_b[b]) for b in blocks])
block_indices = reverse(sortperm(amounts))
block_partitions = partition(partition_size, block_indices)

@info amounts block_indices block_partitions


# --- Relax-and-Fix Heuristic ---
@info "Relax-and-fix"
optimizer = with_optimizer(
    Gurobi.Optimizer,
    TimeLimit=5*60,
    LogFile=joinpath(output_dir, "grb_relax_and_fix.log"),
    MIPFocus=3,
    MIPGap=0.01)

model2 = relax_and_fix(
    products, shelves, blocks, modules, P_b, S_m, G_p, H_s, L_p,
    P_ps, D_p, N_p_min, N_p_max, W_p, W_s, M_p, M_s_min, M_s_max, R_p, L_s,
    H_p, SL, block_partitions, empty_space_penalty, shortage_penalty,
    shelf_up_down_penalty, optimizer);

variables = Dict(k => value.(v) for (k, v) in model2.obj_dict)
n_ps = variables[:n_ps]
o_s = variables[:o_s]
b_bs = variables[:b_bs]
x_bs = variables[:x_bs]
z_bs = variables[:z_bs]
p1 = planogram(products, shelves, blocks, P_b, H_s, H_p, W_p, W_s, SK_p, n_ps, o_s, x_bs)
savefig(p1, joinpath(output_dir, "planogram_relax_and_fix.svg"))
p2 = block_allocation(shelves, blocks, H_s, W_s, b_bs, x_bs, z_bs)
savefig(p2, joinpath(output_dir, "block_allocation_relax_and_fix.svg"))


# --- Fix-and-Optimize Heuristic ---
@info "Fix-and-optimize"
model3 = fix_and_optimize(
    products, shelves, blocks, modules, P_b, S_m, G_p, H_s, L_p,
    P_ps, D_p, N_p_min, N_p_max, W_p, W_s, M_p, M_s_min, M_s_max, R_p, L_s,
    H_p, SL, value.(model2.obj_dict[:z_bs]), value.(model2.obj_dict[:w_bb]),
    empty_space_penalty, shortage_penalty, shelf_up_down_penalty)
optimize!(model3, with_optimizer(
    Gurobi.Optimizer,
    TimeLimit=60,
    LogFile=joinpath(output_dir, "grb_fix_and_optimize.log"),
    MIPFocus=3,
    MIPGap=false))

@info "Saving the results"

variables = Dict(k => value.(v) for (k, v) in model3.obj_dict)
# FIXME
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

@info "Plotting block allocation"
p2 = block_allocation(shelves, blocks, H_s, W_s, b_bs, x_bs, z_bs)
savefig(p2, joinpath(output_dir, "block_allocation.svg"))

@info "Plotting product facings"
p3 = product_facings(products, shelves, blocks, P_b, N_p_max, n_ps)
savefig(p3, joinpath(output_dir, "product_facings.svg"))

# FIXME
# @info "Plotting demand and sales"
# p4 = demand_and_sales(blocks, P_b, D_p, s_p)
# savefig(p4, joinpath(output_dir, "demand_and_sales.svg"))

@info "Plotting fill amount"
p5 = fill_amount(shelves, blocks, P_b, n_ps)
savefig(p5, joinpath(output_dir, "fill_amount.svg"))

@info "Plotting fill percentage"
p6 = fill_percentage(
    n_ps, products, shelves, blocks, modules, P_b, S_m, G_p, H_s, L_p, P_ps,
    D_p, N_p_min, N_p_max, W_p, W_s, M_p, M_s_min, M_s_max, R_p, L_s, H_p,
    with_optimizer(Gurobi.Optimizer, TimeLimit=60, LogToConsole=false))
savefig(p6, joinpath(output_dir, "fill_percentage.svg"))

close(io)
