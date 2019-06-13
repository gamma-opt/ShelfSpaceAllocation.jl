module ShelfSpaceAllocation

using JuMP, Gurobi, CSV
using Base.Filesystem 


# Load data from CSV files. Data is read into a DataFrame.
project_dir = dirname(@__DIR__) |> dirname

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
products = 1:size(product_data, 1)  # p
shelves = 1:size(shelf_data, 1)   # s
# Partitions product indices by blocking_field value.
bfs = product_data.blocking_field
blocks_indices = [collect(products)[bfs .== bf] for bf in unique(bfs)]
blocks = 1:size(blocks_indices, 1)  # b

# modules = nothing


# Parameters
G_p = product_data.price
H_s = shelf_data.Height
# TODO: Set by user?
L_p = ones(size(products))
# TODO: correctness? column vector
P_ps = tranpose(shelf_data.Total_Length) ./ product_data.length
D_p = product_data.monthly_demand
N_p_max = product_data.min_facing
N_p_min = product_data.max_facing
W_p = product_data.width
W_s = shelf_data.Width
M_p = product_data.ItemNetWeightKg
M_s_min = shelf_data.Product_Min_Unit_Weight
M_s_max = shelf_data.Product_Max_Unit_Weight
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
@variable(model, y_p[blocks], Bin)
@variable(model, v_bm[blocks], Bin)
@variable(model, x_bs[blocks, shelves] ≥ 0)
@variable(model, z_bs[blocks, shelves], Bin)


# Objective
@objective(model, Min, 
    sum(o_s) + 
    sum(G_p .* e_p) + 
    sum(sum(L_p[p] * H_s[s] * n_ps[p, s] for p in products) for s in shelves)
)


# Constraints
# TODO: name the constraints
@constraint(model, [p = products], 
    s_p[p] == min(sum(30 / R_p[p] * P_ps[p, s] * n_ps[ps] for s in shelves), D_p))
@constraint(model, [p = products], 
    s_p[p] + e_p[p] == D_p[p])
@constraint(model, [p = products], 
    N_p_min ≤ sum(n_ps[p, :]) ≤ N_p_max)
@constraint(model, [p = products], 
    sum(n_ps[p, s] ≥ y_p[p]))
@constraint(model, )

# Optimize
# optimize!(model)

end # module
