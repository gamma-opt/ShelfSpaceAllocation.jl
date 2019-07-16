using Dates, JuMP, Gurobi, Plots

push!(LOAD_PATH, dirname(@__DIR__))
using ShelfSpaceAllocation

# --- Arguments ---

time_limit = 10 # Seconds
product_path = joinpath(@__DIR__, "data", "Anonymized space allocation data for 9900-shelf.csv")
shelf_path = joinpath(@__DIR__, "data", "scenario_9900_shelves.csv")

# ---

t = Dates.now()
output_dir = joinpath(@__DIR__, "output", "$(t)")
mkpath(output_dir)

println("Project Directory")
println(output_dir)

parameters = load_parameters(product_path, shelf_path)
(products, shelves, blocks, modules, P_b, S_m, G_p, H_s, L_p, P_ps, D_p,
    N_p_min, N_p_max, W_p, W_s, M_p, M_s_min, M_s_max, R_p, L_s, H_p, SK_p, SL) = parameters

println("Inputs are loaded.")

model = ssap_model(products, shelves, blocks, modules, P_b, S_m, G_p, H_s,
        L_p, P_ps, D_p, N_p_min, N_p_max, W_p, W_s, M_p, M_s_min, M_s_max, R_p,
        L_s, H_p, SL)

println("Model is ready.")

optimizer = with_optimizer(
    Gurobi.Optimizer,
    TimeLimit=time_limit,
    LogFile=joinpath(output_dir, "gurobi.log"),
    MIPFocus=3,
    # Presolve=2,
)
optimize!(model, optimizer)

variables = extract_variables(model)
objectives = extract_objectives(parameters, variables)
save(parameters, variables, objectives; output_dir=output_dir)

n_ps = variables[:n_ps]
s_p = variables[:s_p]
o_s = variables[:o_s]
b_bs = variables[:b_bs]
x_bs = variables[:x_bs]
z_bs = variables[:z_bs]

p1 = planogram(products, shelves, blocks, P_b, H_s, H_p, W_p, W_s, SK_p, n_ps, o_s, x_bs)
savefig(p1, joinpath(output_dir, "planogram.svg"))

p2 = product_facings(products, shelves, blocks, P_b, N_p_max, n_ps)
savefig(p2, joinpath(output_dir, "product_facings.svg"))

p3 = block_allocation(shelves, blocks, H_s, W_s, b_bs, x_bs, z_bs)
savefig(p3, joinpath(output_dir, "block_allocation.svg"))

p4 = fill_amount(shelves, blocks, P_b, n_ps)
savefig(p4, joinpath(output_dir, "fill_amount.svg"))

p5 = fill_percentage(
    n_ps, products, shelves, blocks, modules, P_b, S_m, G_p, H_s, L_p, P_ps,
    D_p, N_p_min, N_p_max, W_p, W_s, M_p, M_s_min, M_s_max, R_p, L_s, H_p,
    with_optimizer(Gurobi.Optimizer, TimeLimit=60))
savefig(p5, joinpath(output_dir, "fill_percentage.svg"))

p6 = demand_and_sales(blocks, P_b, D_p, s_p)
savefig(p6, joinpath(output_dir, "demand_and_sales.svg"))
