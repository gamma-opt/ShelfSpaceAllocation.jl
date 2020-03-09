using Parameters, JuMP

"""ShelfSpaceAllocationModel type as JuMP.Model"""
const ShelfSpaceAllocationModel = Model

"""Specs"""
@with_kw struct Specs
    blocking::Bool
end

"""Parameters"""
@with_kw struct Params
    # --- Sets and Subsets ---
    products::Array{Integer, 1}
    shelves::Array{Integer, 1}
    blocks::Array{Integer, 1}
    modules::Array{Integer, 1}
    P_b::Array{Array{Integer, 1}, 1}
    S_m::Array{Array{Integer, 1}, 1}
    # --- Parameters ---
    # Products
    N_p_min::Array{AbstractFloat, 1}
    N_p_max::Array{AbstractFloat, 1}
    G_p::Array{AbstractFloat, 1}
    R_p::Array{AbstractFloat, 1}
    D_p::Array{AbstractFloat, 1}
    L_p::Array{AbstractFloat, 1}
    W_p::Array{AbstractFloat, 1}
    H_p::Array{AbstractFloat, 1}
    M_p::Array{AbstractFloat, 1}
    SK_p::Array{AbstractFloat, 1}
    # Shelves
    M_s_min::Array{AbstractFloat, 1}
    M_s_max::Array{AbstractFloat, 1}
    W_s::Array{AbstractFloat, 1}
    H_s::Array{AbstractFloat, 1}
    L_s::Array{Integer, 1}
    # Product-shelves
    P_ps::Array{AbstractFloat, 2}
    # Constants
    SL::AbstractFloat = 0.0
    w1::AbstractFloat = 0.5
    w2::AbstractFloat = 10.0
    w3::AbstractFloat = 0.1
end

"""Variables"""
@with_kw struct Variables
    # --- Basic Variables ---
    s_p::Array{AbstractFloat, 1}
    e_p::Array{AbstractFloat, 1}
    o_s::Array{AbstractFloat, 1}
    n_ps::Array{Integer, 2}
    y_p::Array{Integer, 1}
    # --- Blocking Variables ---
    b_bs::Array{AbstractFloat, 2}
    m_bm::Array{AbstractFloat, 2}
    z_bs::Array{Integer, 2}
    z_bs_f::Array{Integer, 2}
    z_bs_l::Array{Integer, 2}
    x_bs::Array{AbstractFloat, 2}
    x_bm::Array{AbstractFloat, 2}
    w_bb::Array{Integer, 2}
    v_bm::Array{Integer, 2}
end

"""Objectives"""
@with_kw struct Objectives
    empty_shelf_space::AbstractFloat
    profit_loss::AbstractFloat
    height_placement_penalty::AbstractFloat
end

data(a::Number) = a
data(a::JuMP.Containers.DenseAxisArray) = a.data

"""Variable values from model.

# Arguments
- `model::ShelfSpaceAllocationModel`
"""
function Variables(model::ShelfSpaceAllocationModel)
    tup = Tuple(value.(model[i]) |> data for i in fieldnames(Variables))
    Variables(tup...)
end

"""Objetive values from model.

# Arguments
- `model::ShelfSpaceAllocationModel`
"""
function Objectives(model::ShelfSpaceAllocationModel)
    tup = Tuple(value.(model[i]) |> data for i in fieldnames(Objectives))
    Objectives(tup...)
end

"""Mixed Integer Linear Program (MILP) formulation of the Shelf Space Allocation
Problem (SSAP).

# Arguments
- `parameters::Params`
- `specs::Specs`
"""
function ShelfSpaceAllocationModel(parameters::Params, specs::Specs)
    # Unpack parameters values
    @unpack products, shelves, blocks, modules, P_b, S_m, G_p,
            H_s, L_p, P_ps, D_p, N_p_min, N_p_max, W_p, W_s, M_p,
            M_s_min, M_s_max, R_p, L_s, H_p, SL, w1, w2, w3 =
            parameters

    # Initialize the model
    model = ShelfSpaceAllocationModel()

    # --- Basic Variables ---
    @variable(model, s_p[products] ≥ 0)
    @variable(model, e_p[products] ≥ 0)
    @variable(model, o_s[shelves] ≥ 0)
    @variable(model, n_ps[products, shelves] ≥ 0, Int)
    @variable(model, y_p[products], Bin)

    # --- Block Variables ---
    @variable(model, b_bs[blocks, shelves] ≥ 0)
    @variable(model, m_bm[blocks, modules] ≥ 0)
    @variable(model, z_bs[blocks, shelves], Bin)
    @variable(model, z_bs_f[blocks, shelves], Bin)
    @variable(model, z_bs_l[blocks, shelves], Bin)
    @variable(model, x_bs[blocks, shelves] ≥ 0)
    @variable(model, x_bm[blocks, modules] ≥ 0)
    @variable(model, w_bb[blocks, blocks], Bin)
    @variable(model, v_bm[blocks, modules], Bin)

    # --- Height and weight constraints ---
    for p in products
        for s in shelves
            if (H_p[p] > H_s[s]) | (M_p[p] > M_s_max[s])
                fix(n_ps[p, s], 0, force=true)
            end
        end
    end

    # --- Objective ---
    @expression(model, empty_shelf_space,
        sum(o_s[s] for s in shelves))
    @expression(model, profit_loss,
        sum(G_p[p] * e_p[p] for p in products))
    @expression(model, height_placement_penalty,
        sum(L_p[p] * L_s[s] * n_ps[p, s] for p in products for s in shelves))
    @objective(model, Min,
        w1 * empty_shelf_space +
        w2 * profit_loss +
        w3 * height_placement_penalty
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

    # --- Block constraints ---
    if specs.blocking
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
            sum(n_ps[p, s] for p in P_b[b]) ≥ z_bs[b, s])
        @constraint(model, [b = blocks, s = shelves, p = P_b[b]],
            n_ps[p, s] ≤ N_p_max[p] * z_bs[b, s])
        # ---
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
        @constraint(model, [b = blocks, m = modules, s = S_m[m], p = P_b[b]],
            n_ps[p, s] ≤ N_p_max[p] * v_bm[b, m])
        @constraint(model, [b = blocks],
            sum(v_bm[b, m] for m in modules) ≤ 1)
    end

    return model
end
