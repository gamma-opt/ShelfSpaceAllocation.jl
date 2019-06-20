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

# We only consider one module in this code.
# modules = 1:1

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
# M_p = product_data.ItemNetWeightKg
# M_s_min = shelf_data.Product_Min_Unit_Weight
# M_s_max = shelf_data.Product_Max_Unit_Weight
R_p = product_data.replenishment_interval

# Model
model = Model(with_optimizer(Gurobi.Optimizer))

# Variables
@variable(model, s_p[products] ≥ 0)
@variable(model, e_p[products] ≥ 0)
@variable(model, n_ps[products, shelves] ≥ 0, Int)
@variable(model, o_s[shelves] ≥ 0)
@variable(model, b_bs[blocks, shelves] ≥ 0)
@variable(model, m_bm[blocks] ≥ 0)
@variable(model, y_p[products], Bin)
@variable(model, v_bm[blocks], Bin)
@variable(model, x_bs[blocks, shelves] ≥ 0)
@variable(model, x_bm[blocks] ≥ 0)
@variable(model, z_bs[blocks, shelves], Bin)
@variable(model, w_bb[blocks, blocks], Bin)
@variable(model, z_bs_f[blocks, shelves], Bin)
@variable(model, z_bs_l[blocks, shelves], Bin)

# Objective
@objective(model, Min,
    sum(o_s[s] for s in shelves) +
    sum(G_p[p] * e_p[p] for p in products) +
    sum(L_p[p] * H_s[s] * n_ps[p, s] for p in products for s in shelves)
)

# Constraints
# TODO: add weight constraint
# TODO: name the constraints
M = [max(maximum(30 / R_p[p] * P_ps[p, s] for s in shelves) * N_p_max[p], D_p[p]) for p in products]
@variable(model, σ[products], Bin)
@constraints(model, begin
    [p = products],
    s_p[p] ≤ sum(30 / R_p[p] * P_ps[p, s] * n_ps[p, s] for s in shelves)
    [p = products],
    s_p[p] ≥ sum(30 / R_p[p] * P_ps[p, s] * n_ps[p, s] for s in shelves) - M[p] * σ[p]
    [p = products],
    s_p[p] ≤ D_p[p]
    [p = products],
    s_p[p] ≥ D_p[p] - M[p] * (1 - σ[p])
end)
@constraint(model, [p = products],
    s_p[p] + e_p[p] == D_p[p])
@constraint(model, [p = products],
    N_p_min[p] ≤ sum(n_ps[p, s] for s in shelves) ≤ N_p_max[p])
@constraint(model, [p = products],
    sum(n_ps[p, s] for s in shelves) ≥ y_p[p])
@constraint(model, [s = shelves],
    sum(W_p[p] * n_ps[p, s] for p in products) + o_s[s] == W_s[s])
# ---
@constraint(model, [s = shelves, b = blocks, p = P_b[b]],
    W_p[p] * n_ps[p, s] ≤ b_bs[b, s])
@constraint(model, [s = shelves],
    sum(b_bs[b, s] for b in blocks) ≤ W_s[s])
@constraint(model, [b = blocks, s = shelves],
    b_bs[b, s] ≥ m_bm[b] - W_s[s] * (1 - z_bs[b, s]))
@constraint(model, [b = blocks, s = shelves],
    b_bs[b, s] ≤ m_bm[b] + W_s[s] * (1 - z_bs[b, s]))
@constraint(model, [b = blocks, s = shelves],
    b_bs[b, s] ≤ W_s[s] * z_bs[b, s])
@constraint(model, [b = blocks, s = 1:length(shelves)-1],
    z_bs_f[b, s+1] + z_bs[b, s] == z_bs[b, s+1] + z_bs_l[b, s])
@constraint(model, [b = blocks],
    sum(z_bs_f[b, s] for s in shelves) ≤ 1)
@constraint(model, [b = blocks],
    sum(z_bs_l[b, s] for s in shelves) ≤ 1)
@constraint(model, [b = blocks, s = [1]],
    z_bs_f[b, s] == z_bs[b, s])
@constraint(model, [b = blocks, s = [length(shelves)]],
    z_bs_l[b, s] == z_bs[b, s])
@constraint(model, [b = blocks, s = shelves],
    sum(n_ps[p, s] for p in products) ≥ z_bs[b, s])
@constraint(model, [b = blocks, s = shelves, p = P_b[b]],
    n_ps[p, s] ≤ N_p_max[p] * z_bs[b, s])
@constraint(model, [b = blocks, b′ = blocks, s = shelves],
    x_bs[b, s] ≥ x_bs[b′, s] + b_bs[b, s] - W_s[s] * (1 - w_bb[b, b′]))
@constraint(model, [b = blocks, b′ = blocks, s = shelves],
    x_bs[b′, s] ≥ x_bs[b, s] + b_bs[b, s] - W_s[s] * w_bb[b, b′])
@constraint(model, [b = blocks, s = shelves],
    x_bm[b] ≥ x_bs[b, s] - W_s[s] * (1 - z_bs[b, s]))
@constraint(model, [b = blocks, s = shelves],
    x_bm[b] ≤ x_bs[b, s] + W_s[s] * (1 - z_bs[b, s]))
@constraint(model, [b = blocks, s = shelves],
    x_bs[b, s] ≤ W_s[s] * z_bs[b, s])
@constraint(model, [b = blocks, s = shelves, p = P_b[b]],
    n_ps[p, s] ≤ N_p_max[p] * v_bm[b])
@constraint(model, [b = blocks],
    sum(v_bm[b]) ≤ 1)

# Optimize
optimize!(model)
