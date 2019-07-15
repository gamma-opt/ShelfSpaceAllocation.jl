using Plots

"""Plot colors for different blocks.
source: https://github.com/JuliaPlots/ExamplePlots.jl/blob/master/notebooks/cgrad.ipynb"""
function block_colorbar(blocks)
    return cgrad(:inferno) |> g -> RGB[g[b/length(blocks)] for b in blocks]
end

"""Creates a planogram which visualizes the product placement on the shelves."""
function planogram(products, shelves, blocks, P_b, H_s, H_p, W_p, W_s, SK_p, n_ps, o_s, x_bs)
    # Initialize the plot
    plt = plot(legend=:none, background=:lightgray)

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

# TODO: calculate and display the number of products placed
"""Creates a barchart of number of product facings per product."""
function product_facings(products, shelves, blocks, P_b, N_p_max, n_ps)
    colors = [cgrad(:inferno)[b/length(blocks)] for b in blocks for p in P_b[b]]

    # Plot maximum number of facings.
    plt = bar(
        N_p_max,
        linewidth=0,
        color=colors,
        background=:lightgray,
        legend=:none,
        alpha=0.3,
        tickfontsize=6,
        xticks=vcat([1], [last(P_b[b]) for b in blocks])
    )

    # Plot number of facings placed on to the shelves.
    bar!(
        plt,
        [sum(n_ps[p, s] for s in shelves) for p in products],
        xlabel="Product (p)",
        ylabel="Number of facings (n_ps)",
        color=colors,
        linewidth=0,
        legend=:none,
        background=:lightgray
    )

    return plt
end

"""Block starting locations and widths."""
function block_allocation(shelves, blocks, H_s, W_s, b_bs, x_bs, z_bs)
    plt = plot(legend=:none, background=:lightgray)
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

"""Bar chart of demand and sales per product."""
function demand_and_sales(blocks, P_b, D_p, s_p)
    colors = [cgrad(:inferno)[b/length(blocks)] for b in blocks for p in P_b[b]]
    plt = bar(D_p, alpha=0.3, label="Demand (D_p)", linewidth=0,
        background=:lightgray, xlabel="Product (p)", color=colors)
    bar!(plt, s_p, alpha=1.0, label="Product sold (s_p)", linewidth=0, color=colors)
    return plt
end

"""Plot the total number of allocated facings per product per block."""
function fill_amount(shelves, blocks, P_b, n_ps)
    pr = [sum(n_ps[p, s] for s in shelves for p in P_b[b]) for b in blocks]
    plt = bar(
        pr,
        color=[cgrad(:inferno)[b/length(blocks)] for b in blocks],
        xticks=1:1:size(blocks, 1),
        legend=:none,
        background=:lightgray
    )
    return plt
end

"""Plot the percentage of allocated facings of maximum facings per block."""
function fill_percentage(shelves, blocks, P_b, N_p_max, n_ps)
    pr = round.([sum(n_ps[p, s] for s in shelves for p in P_b[b])/
                 sum(N_p_max[p] for p in P_b[b]) for b in blocks]; digits=2)
    plt = bar(
        pr,
        color=[cgrad(:inferno)[b/length(blocks)] for b in blocks],
        ylims=(0, 1),
        xticks=1:1:size(blocks, 1),
        legend=:none,
        background=:lightgray
    )
    return plt
end
