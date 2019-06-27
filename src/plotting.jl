using Plots

"""Creates a planogram which visualizes the product placement on the shelves."""
function planogram(products, shelves, blocks, P_b, H_s, W_p, W_s, n_ps, o_s, b_bs, x_bs)
    # Cumulative shelf heights
    y_s = vcat([0], cumsum(H_s))

    # Initialize the plot
    plt = plot(legend=:none)

    # Draw products
    rect(x, y, w, h) = Shape(x .+ [0,w,w,0], y .+ [0,0,h,h])
    block_colors = cgrad(:inferno)
    for b in blocks
        for s in shelves
            x = x_bs[b, s]
            for p in P_b[b]
                stack = max(min(div(H_s[s], H_p[p]), product_data.max_stack[p]), 1)
                for i in 1:n_ps[p, s]
                    y = 0
                    for j in 1:stack
                        plot!(plt, rect(x, y_s[s]+y, W_p[p], H_p[p]),
                              color=block_colors[b/length(blocks)])
                        y += W_p[p]
                    end
                    x += W_p[p]
                end
            end
        end
    end

    # Draw shelves - A line from (0, y[s]) to (W_s[s], y[s])
    for s in shelves
        plot!(plt, [0, W_s[s]], [y_s[s], y_s[s]],
              color=:black, label="s_$s")
    end
    plot!(plt, [0, W_s[end]], [y_s[end], y_s[end]],
          color=:black, linestyle=:dash)

    return plt
end

"""Creates a barchart of number of product facings per product."""
function barchart(blocks, shelves, P_b, N_p_max, n_ps)
    colors = [cgrad(:inferno)[b/length(blocks)] for b in blocks for _ in P_b[b]]

    # Max facings
    plt = bar(
        N_p_max,
        linewidth=0,
        color=colors,
        background=:lightgray,
        legend=:none,
        alpha=0.2)

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
