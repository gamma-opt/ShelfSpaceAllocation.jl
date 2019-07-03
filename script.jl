using Base.Filesystem
using JuMP, Gurobi, Plots
push!(LOAD_PATH, pwd())
using ShelfSpaceAllocation


output_dir = "output"
rm(output_dir, recursive=true)
mkdir(output_dir)

project_dir = @__DIR__
product_path = joinpath(project_dir, "data", "Anonymized space allocation data for 9900-shelf.csv")
shelf_path = joinpath(project_dir, "data", "scenario_9900_shelves.csv")

(products, shelves, blocks, modules, P_b, S_m, G_p, H_s, L_p, P_ps, D_p,
N_p_min, N_p_max, W_p, W_s, M_p, M_s_min, M_s_max, R_p, L_s, H_p, SK_p
) = load_inputs(product_path, shelf_path)

println("Inputs are loaded.")

model = ssap_model(products, shelves, blocks, modules, P_b, S_m, G_p, H_s,
        L_p, P_ps, D_p, N_p_min, N_p_max, W_p, W_s, M_p, M_s_min, M_s_max, R_p,
        L_s, H_p; SL=0)

println("Model is ready.")

optimizer = with_optimizer(
    Gurobi.Optimizer,
    TimeLimit=10,
    LogFile=joinpath(output_dir, "gurobi.log")
)
optimize!(model, optimizer)

save_variables(model; filepath=joinpath(output_dir, "solution.json"))

n_ps = value.(model.obj_dict[:n_ps])
o_s = value.(model.obj_dict[:o_s])
b_bs = value.(model.obj_dict[:b_bs])
x_bs = value.(model.obj_dict[:x_bs])
z_bs = value.(model.obj_dict[:z_bs])

p1 = planogram(products, shelves, blocks, P_b, H_s, H_p, W_p, W_s, SK_p, n_ps, o_s, x_bs)
savefig(p1, joinpath(output_dir, "planogram.svg"))

p2 = product_facings(products, shelves, blocks, P_b, N_p_max, n_ps)
savefig(p2, joinpath(output_dir, "product_facings.svg"))

p3 = block_location_width(shelves, blocks, H_s, b_bs, x_bs, z_bs)
savefig(p3, joinpath(output_dir, "block_location_width.svg"))
