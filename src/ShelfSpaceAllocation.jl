module ShelfSpaceAllocation

using JuMP, Gurobi, CSV
using Base.Filesystem 


# Load data from CSV files. Data is read into a DataFrame.
project_dir = dirname(@__DIR__)
product_data = CSV.read(joinpath(project_dir, "data", "Anonymized space allocation data for 9900-shelf.csv"))
shelf_data = CSV.read(joinpath(project_dir, "data", "scenario_9900_shelves.csv"))


# Sets and Subsets
# TODO: compute from loaded data
products = 1:10  # p
shelves = 1:10   # s
blocks = 1:10    # b


# Parameters
# TODO: replace nothings
G_p = product_data.price
H_s = nothing
L_p = nothing
P_ps = nothing  # compute from other values
D_p = product_data.monthly_demand
N_p_max = nothing
N_p_min = nothing
W_p = product_data.width
W_s = nothing
M_p = product_data.ItemNetWeightKg
M_s_min = nothing
M_s_max = nothing
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


# Optimize
# optimize!(model)

end # module
