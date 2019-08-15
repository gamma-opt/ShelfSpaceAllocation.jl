using Plots, JuMP, LaTeXStrings

"""Plot colors for different blocks.
source: https://github.com/JuliaPlots/ExamplePlots.jl/blob/master/notebooks/cgrad.ipynb"""
function block_colorbar(blocks)
    return cgrad(:inferno) |> g -> RGB[g[b/length(blocks)] for b in blocks]
end

"""Creates a planogram which visualizes the product placement on the shelves."""
function planogram(products, shelves, blocks, P_b, H_s, H_p, W_p, W_s, SK_p, n_ps, o_s, x_bs):: Plots.Plot
    # Initialize the plot
    plt = plot(
        legend=:none,
        background=:lightgray,
        size=(780, 400)
    )

    # Cumulative shelf heights
    y_s = vcat([0], cumsum(H_s))

    # Draw products
    rect(x, y, w, h) = Shape(x .+ [0,w,w,0], y .+ [0,0,h,h])
    block_colors = cgrad(:inferno)
    for b in blocks
        for s in shelves
            x = x_bs[b, s]
            for p in P_b[b]
                stack = max(min(div(H_s[s], H_p[p]), SK_p[p]), 1)
                for i in 1:n_ps[p, s]
                    y = 0
                    for j in 1:stack
                        plot!(plt, rect(x, y_s[s]+y, W_p[p], H_p[p]),
                              color=block_colors[b/length(blocks)])
                        y += H_p[p]
                    end
                    x += W_p[p]
                end
            end
        end
    end

    # Draw shelves
    for s in shelves
        plot!(plt, [0, W_s[s]], [y_s[s], y_s[s]],
              color=:black)
    end
    plot!(plt, [0, W_s[end]], [y_s[end], y_s[end]],
          color=:black, linestyle=:dash)

    return plt
end

"""Block starting locations and widths."""
function block_allocation(shelves, blocks, H_s, W_s, b_bs, x_bs, z_bs):: Plots.Plot
    plt = plot(
        legend=:none,
        background=:lightgray,
        size=(780, 400)
    )
    y_s = vcat([0], cumsum(H_s))

    # Draw shelves
    for s in shelves
        plot!(plt, [0, W_s[s]], [y_s[s], y_s[s]],
              color=:gray, linestyle=:dot)
    end
    plot!(plt, [0, W_s[end]], [y_s[end], y_s[end]],
          color=:gray, linestyle=:dash)

    block_colors = cgrad(:inferno)
    for b in blocks
        for s in shelves
            if z_bs[b, s] == 0
                continue
            end
            color = block_colors[b/length(blocks)]
            scatter!(
                plt, [x_bs[b, s]], [y_s[s]],
                color=color, markerstrokewidth=0, markersize = 2.5)
            plot!(
                plt, [x_bs[b, s], x_bs[b, s] + b_bs[b, s]], [y_s[s], y_s[s]],
                color=color)
        end
    end
    return plt
end

"""Creates a barchart of number of product facings per product."""
function product_facings(products, shelves, blocks, P_b, N_p_max, n_ps):: Plots.Plot
    colors = [cgrad(:inferno)[b/length(blocks)] for b in blocks for p in P_b[b]]

    # Plot maximum number of facings.
    plt = bar(
        N_p_max,
        xlabel=L"$p$",
        ylabel=L"$n_{p,s}$",
        linewidth=0,
        color=colors,
        background=:lightgray,
        legend=:none,
        alpha=0.3,
        tickfontsize=6,
        xticks=vcat([1], [last(P_b[b]) for b in blocks]),
        size=(780, 400)
    )

    # Plot number of facings placed on to the shelves.
    bar!(
        plt,
        [sum(n_ps[p, s] for s in shelves) for p in products],
        color=colors,
        linewidth=0,
        legend=:none,
        background=:lightgray
    )

    return plt
end

"""Bar chart of demand and sales per product."""
function demand_and_sales(blocks, P_b, D_p, s_p):: Plots.Plot
    colors = [cgrad(:inferno)[b/length(blocks)] for b in blocks for p in P_b[b]]

    # Plot demand of products
    plt = bar(
        D_p,
        alpha=0.3,
        linewidth=0,
        background=:lightgray,
        xlabel=L"$p$",
        ylabel=L"$D_p$ and $s_p$",
        color=colors,
        tickfontsize=6,
        xticks=vcat([1], [last(P_b[b]) for b in blocks]),
        legend=:none,
        size=(780, 400)
    )

    # Plot products sold
    bar!(
        plt,
        s_p,
        alpha=1.0,
        linewidth=0,
        color=colors
    )
    return plt
end

"""Plot the total number of allocated facings per product per block."""
function fill_amount(shelves, blocks, P_b, n_ps):: Plots.Plot
    pr = [sum(n_ps[p, s] for s in shelves for p in P_b[b]) for b in blocks]
    plt = bar(
        pr,
        color=[cgrad(:inferno)[b/length(blocks)] for b in blocks],
        xlabel=L"$b$",
        # ylabel=L"",
        xticks=1:1:size(blocks, 1),
        legend=:none,
        background=:lightgray
    )
    return plt
end

"""Function for computing maximum number of facings of products that can be
allocated on shelves."""
function max_facings(
        products, shelves, G_p, H_s, L_p, P_ps, D_p, N_p_min, N_p_max, W_p,
        W_s, M_p, M_s_min, M_s_max, R_p, L_s, H_p):: Model
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
    w_1 = 0.5
    w_2 = 10.0
    w_3 = 0.1
    @objective(model, Min,
        w_1 * sum(o_s[s] for s in shelves) +
        w_2 * sum(G_p[p] * e_p[p] for p in products)
        # + w_3 * sum(L_p[p] * L_s[s] * n_ps[p, s] for p in products for s in shelves)
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

"""Plot the percentage of allocated facings of maximum facings per block."""
function fill_percentage(
        n_ps_sol, products, shelves, blocks, modules, P_b, S_m, G_p, H_s, L_p,
        P_ps, D_p, N_p_min, N_p_max, W_p, W_s, M_p, M_s_min, M_s_max, R_p, L_s,
        H_p, optimizer):: Plots.Plot
    pr = [sum(n_ps_sol[p, s] for p in P_b[b] for s in shelves) for b in blocks]
    pr_max = []
    for b in blocks
        model = max_facings(P_b[b], shelves, G_p, H_s, L_p, P_ps, D_p,
            N_p_min, N_p_max, W_p, W_s, M_p, M_s_min, M_s_max, R_p, L_s, H_p)
        optimize!(model, optimizer)
        n_ps_max = value.(model.obj_dict[:n_ps])
        push!(pr_max, sum(n_ps_max[p, s] for p in P_b[b] for s in shelves))
    end

    plt = bar(
        pr ./ pr_max,
        color=[cgrad(:inferno)[b/length(blocks)] for b in blocks],
        ylims=(0, 1),
        xlabel=L"$b$",
        # ylabel=L"",
        xticks=1:1:size(blocks, 1),
        legend=:none,
        background=:lightgray
    )
    return plt
end
