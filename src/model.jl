using JuMP, Gurobi, CSV
using Base.Filesystem


# Load data from CSV files. Data is read into a DataFrame.
project_dir = dirname(@__DIR__)

"""
Fields:
* product_id
* width
* height
* length
* ItemNetWeightKg
* monthly_demand
* replenishment_interval
* price
* unit_margin
* blocking_field
* min_facing
* max_facing
* max_stack
* up_down_order_cr
* block_order_cr
"""
product_data = CSV.read(joinpath(project_dir, "data", "Anonymized space allocation data for 9900-shelf.csv"))

"""
Fields:
* Module
* id
* Level
* Total_Width
* Total_Height
* Total_Length
* Product_Min_Unit_Weight
* Product_Max_Unit_Weight
"""
shelf_data = CSV.read(joinpath(project_dir, "data", "scenario_9900_shelves.csv"))

# Sets and Subsets
products = 1:size(product_data, 1)
shelves = 1:size(shelf_data, 1)

# Groups product indices by blocking_field value.
bfs = product_data.blocking_field
P_b = [collect(products)[bfs .== bf] for bf in unique(bfs)]
blocks = 1:size(P_b, 1)

# Modules
mds = shelf_data.Module
S_m = [collect(shelves)[mds .== md] for md in unique(mds)]
modules = 1:size(S_m, 1)

# Parameters
G_p = product_data.unit_margin
H_s = shelf_data.Total_Height
L_p = product_data.up_down_order_cr
P_ps = transpose(shelf_data.Total_Length) ./ product_data.length
D_p = product_data.monthly_demand
N_p_min = product_data.min_facing
N_p_max = product_data.max_facing
W_p = product_data.width
W_s = shelf_data.Total_Width
M_p = product_data.ItemNetWeightKg
M_s_min = shelf_data.Product_Min_Unit_Weight
M_s_max = shelf_data.Product_Max_Unit_Weight
R_p = product_data.replenishment_interval
L_s = shelf_data.Level
H_p = product_data.height
SL = 0


# Model
model = Model()

# Variables
@variable(model, s_p[products] ≥ 0)
@variable(model, e_p[products] ≥ 0)
@variable(model, o_s[shelves] ≥ 0)
@variable(model, n_ps[products, shelves] ≥ 0, Int)

# Objective
w_1 = 0.5
w_2 = 10.0
w_3 = 0.1
@objective(model, Min,
    w_1 * sum(o_s[s] for s in shelves) +
    w_2 * sum(G_p[p] * e_p[p] for p in products) +
    w_3 * sum(L_p[p] * L_s[s] * n_ps[p, s] for p in products for s in shelves)
)

# Constraints
# M = [max(maximum(30 / R_p[p] * P_ps[p, s] for s in shelves) * N_p_max[p], D_p[p]) for p in products]
# @variable(model, σ[products], Bin)
# @constraints(model, begin
#     [p = products],
#     s_p[p] ≤ sum(30 / R_p[p] * P_ps[p, s] * n_ps[p, s] for s in shelves)
#     [p = products],
#     s_p[p] ≥ sum(30 / R_p[p] * P_ps[p, s] * n_ps[p, s] for s in shelves) - M[p] * σ[p]
#     [p = products],
#     s_p[p] ≤ D_p[p]
#     [p = products],
#     s_p[p] ≥ D_p[p] - M[p] * (1 - σ[p])
# end)
@constraints(model, begin
    [p = products],
    s_p[p] ≤ sum(30 / R_p[p] * P_ps[p, s] * n_ps[p, s] for s in shelves)
    [p = products],
    s_p[p] ≤ D_p[p]
end)
@constraint(model, [p = products],
    s_p[p] + e_p[p] == D_p[p])

@variable(model, y_p[products], Bin)
@constraint(model, [p = products],
    sum(n_ps[p, s] for s in shelves) ≥ y_p[p])
@constraints(model, begin
    [p = products], N_p_min[p] * y_p[p] ≤ sum(n_ps[p, s] for s in shelves)
    [p = products], sum(n_ps[p, s] for s in shelves) ≤ N_p_max[p] * y_p[p]
end)

@constraint(model, [s = shelves],
    sum(W_p[p] * n_ps[p, s] for p in products) + o_s[s] == W_s[s])

# Weight constraint
# @constraint(model, [s = shelves],
#     M_s_min[s] ≤ sum(M_p[p] * n_ps[p, s] for p in products) ≤ M_s_max[s])

# Height constraint
@variable(model, y_ps[products, shelves], Bin)
@constraint(model, [p = products, s = shelves],
    n_ps[p, s] ≤ N_p_max[p] * y_ps[p, s])
@constraint(model, [p = products, s = shelves],
    y_ps[p, s] * H_p[p] ≤ H_s[s])

# Block variables and constraints
@variable(model, b_bs[blocks, shelves] ≥ 0)
@variable(model, m_bm[blocks, modules] ≥ 0)
@variable(model, z_bs[blocks, shelves], Bin)
@constraint(model, [s = shelves, b = blocks],
    sum(W_p[p] * n_ps[p, s] for p in P_b[b]) ≤ b_bs[b, s])
@constraint(model, [s = shelves],
    sum(b_bs[b, s] for b in blocks) ≤ W_s[s])
@constraint(model, [b = blocks, m = modules, s = S_m[m]],
    b_bs[b, s] ≥ m_bm[b, m] - W_s[s] * (1 - z_bs[b, s]) - SL)
@constraint(model, [b = blocks, m = modules, s = S_m[m]],
    b_bs[b, s] ≤ m_bm[b, m] + W_s[s] * (1 - z_bs[b, s]) + SL)
@constraint(model, [b = blocks, s = shelves],
    b_bs[b, s] ≤ W_s[s] * z_bs[b, s])
# ---
@variable(model, z_bs_f[blocks, shelves], Bin)
@variable(model, z_bs_l[blocks, shelves], Bin)
@constraint(model, [b = blocks, s = 1:length(shelves)-1],
    z_bs_f[b, s+1] + z_bs[b, s] == z_bs[b, s+1] + z_bs_l[b, s])
@constraint(model, [b = blocks],
    sum(z_bs_f[b, s] for s in shelves) ≤ 1)
@constraint(model, [b = blocks],
    sum(z_bs_l[b, s] for s in shelves) ≤ 1)
@constraint(model, [b = blocks],
    z_bs_f[b, 1] == z_bs[b, 1])
@constraint(model, [b = blocks],
    z_bs_l[b, end] == z_bs[b, end])
# ---
@constraint(model, [b = blocks, s = shelves],
    sum(n_ps[p, s] for p in products) ≥ z_bs[b, s])
@constraint(model, [b = blocks, s = shelves, p = P_b[b]],
    n_ps[p, s] ≤ N_p_max[p] * z_bs[b, s])
# ---
@variable(model, x_bs[blocks, shelves] ≥ 0)
@variable(model, x_bm[blocks, modules] ≥ 0)
@variable(model, w_bb[blocks, blocks], Bin)
@constraint(model, [b = blocks, b′ = filter(a->a≠b, blocks), s = shelves],
    x_bs[b, s] + W_s[s] * (1 - z_bs[b, s]) ≥ x_bs[b′, s] + b_bs[b, s] - W_s[s] * (1 - w_bb[b, b′]))
@constraint(model, [b = blocks, b′ = filter(a->a≠b, blocks), s = shelves],
    x_bs[b′, s] + W_s[s] * (1 - z_bs[b′, s]) ≥ x_bs[b, s] + b_bs[b, s] - W_s[s] * w_bb[b, b′])
@constraint(model, [b = blocks, m = modules, s = S_m[m]],
    x_bm[b, m] ≥ x_bs[b, s] - W_s[s] * (1 - z_bs[b, s]) - SL)
@constraint(model, [b = blocks, m = modules, s = S_m[m]],
    x_bm[b, m] ≤ x_bs[b, s] + W_s[s] * (1 - z_bs[b, s]) + SL)
@constraint(model, [b = blocks, s = shelves],
    x_bs[b, s] ≤ W_s[s] * z_bs[b, s])
@constraint(model, [b = blocks, s = shelves],
    x_bs[b, s] + b_bs[b, s] ≤ W_s[s])
# ---
@variable(model, v_bm[blocks, modules], Bin)
@constraint(model, [b = blocks, m = modules, s = S_m[m], p = P_b[b]],
    n_ps[p, s] ≤ N_p_max[p] * v_bm[b, m])
@constraint(model, [b = blocks],
    sum(v_bm[b, m] for m in modules) ≤ 1)

println("Model is ready.")

# Optimize
optimize!(model, with_optimizer(Gurobi.Optimizer))
