using Parameters, Plots, JuMP, LaTeXStrings

const block_colors = cgrad(:inferno)

"""Creates a planogram which visualizes the product placement on the shelves."""
function plot_planogram(products, shelves, blocks, P_b, H_s, H_p, W_p, W_s, SK_p, n_ps, o_s, x_bs)
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
    for b in blocks
        for s in shelves
            x = x_bs[b, s]
            for p in P_b[b]
                stack = max(min(div(H_s[s], H_p[p]), SK_p[p]), 1)
                for i in 1:n_ps[p, s]
                    y = 0
                    for j in 1:stack
                        plot!(plt,
                              rect(x, y_s[s-shelves[1]+1]+y, W_p[p], H_p[p]),
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
        plot!(plt, [0, W_s[s]], [y_s[s-shelves[1]+1], y_s[s-shelves[1]+1]],
              color=:black)
    end
    plot!(plt, [0, W_s[shelves[end]]], [y_s[end], y_s[end]],
          color=:black, linestyle=:dash)

    return plt
end

"""Creates a planogram which visualizes the product placement on the shelves without blocks."""
function plot_planogram_no_blocks(products, shelves, blocks, P_b, H_s, H_p, W_p, W_s, SK_p, n_ps, o_s)
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
                        plot!(plt,
                              rect(x, y_s[s]+y, W_p[p], H_p[p]),
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
        plot!(plt, [0, W_s[s]], [y_s[s-shelves[1]+1], y_s[s-shelves[1]+1]],
              color=:black)
    end
    plot!(plt, [0, W_s[shelves[end]]], [y_s[end], y_s[end]],
          color=:black, linestyle=:dash)

    return plt
end

"""Create a planogram for each module."""
function plot_planograms(products, shelves, blocks, S_m, P_b, H_s, H_p, W_p, W_s, SK_p, n_ps, o_s, x_bs)
     return [plot_planogram(products, shelves′, blocks, P_b, H_s, H_p, W_p, W_s, SK_p, n_ps, o_s, x_bs) for shelves′ in S_m]
end

"""Create a planogram for each module without blocks."""
function plot_planograms_no_blocks(products, shelves, blocks, S_m, P_b, H_s, H_p, W_p, W_s, SK_p, n_ps, o_s)
    return [plot_planogram_no_blocks(products, shelves′, blocks, P_b, H_s, H_p, W_p, W_s, SK_p, n_ps, o_s) for shelves′ in S_m]
end

"""Block starting locations and widths."""
function plot_block_allocation(shelves, blocks, H_s, W_s, b_bs, x_bs, z_bs)
    plt = plot(
        legend=:none,
        background=:lightgray,
        size=(780, 400)
    )
    y_s = vcat([0], cumsum([H_s[s] for s in shelves]))

    # Draw shelves
    for s in shelves
        plot!(plt, [0, W_s[s]], [y_s[s-shelves[1]+1], y_s[s-shelves[1]+1]],
              color=:gray, linestyle=:dot)
    end
    plot!(plt, [0, W_s[shelves[end]]], [y_s[end], y_s[end]],
          color=:gray, linestyle=:dash)

    for b in blocks
        for s in shelves
            if z_bs[b, s] == 0
                continue
            end
            color = block_colors[b/length(blocks)]
            scatter!(
                plt, [x_bs[b, s]], [y_s[s-shelves[1]+1]],
                color=color, markerstrokewidth=0, markersize = 2.5)
            plot!(
                plt, [x_bs[b, s], x_bs[b, s] + b_bs[b, s]],
                     [y_s[s-shelves[1]+1], y_s[s-shelves[1]+1]],
                color=color)
        end
    end
    return plt
end

"""Create block_allocation for each module."""
function plot_block_allocations(shelves, blocks, S_m, H_s, W_s, b_bs, x_bs, z_bs)
    return [plot_block_allocation(shelves′, blocks, H_s, W_s, b_bs, x_bs, z_bs) for shelves′ in S_m]
end

"""Creates a barchart of number of product facings per product."""
function plot_product_facings(products, shelves, blocks, P_b, N_p_max, n_ps)
    colors = [block_colors[b/length(blocks)] for b in blocks for p in P_b[b]]

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
function plot_demand_and_sales(blocks, P_b, D_p, s_p)
    colors = [block_colors[b/length(blocks)] for b in blocks for p in P_b[b]]

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

"""Plot the total amount of allocated facings per product per block."""
function plot_allocation_amount(shelves, blocks, P_b, n_ps)
    pr = [sum(n_ps[p, s] for s in shelves for p in P_b[b]) for b in blocks]
    plt = bar(
        pr,
        color=[block_colors[b/length(blocks)] for b in blocks],
        xlabel=L"$b$",
        # ylabel=L"",
        xticks=1:1:size(blocks, 1),
        legend=:none,
        background=:lightgray
    )
    return plt
end

"""Plot the percentage of allocated facings of maximum facings per block."""
function plot_allocation_percentage(parameters::Params, n_ps, optimizer)
    @unpack products, shelves, blocks, modules, P_b, S_m, N_p_min, N_p_max,
            G_p, R_p, D_p, L_p, W_p, H_p, M_p, SK_p, M_s_min, M_s_max, W_s,
            H_s, L_s, P_ps, SL, w1, w2, w3 = parameters

    pr = [sum(n_ps[p, s] for p in P_b[b] for s in shelves) for b in blocks]
    pr_max = []
    for b in blocks
        specs = Specs(blocking=false)
        parameters2 = Params(
            P_b[b], shelves, Integer[], Integer[], [Integer[]], [Integer[]],
            N_p_min, N_p_max, G_p, R_p, D_p, L_p, W_p, H_p, M_p, SK_p, M_s_min,
            M_s_max, W_s, H_s, L_s, P_ps, SL, w1, w2, w3)
        model = ShelfSpaceAllocationModel(parameters2, specs)
        optimize!(model, optimizer)
        n_ps_max = value.(model[:n_ps])
        push!(pr_max, sum(n_ps_max[p, s] for p in P_b[b] for s in shelves))
    end

    plt = bar(
        pr ./ pr_max,
        color=[block_colors[b/length(blocks)] for b in blocks],
        ylims=(0, 1),
        xlabel=L"$b$",
        # ylabel=L"",
        xticks=1:1:size(blocks, 1),
        legend=:none,
        background=:lightgray
    )
    return plt
end
