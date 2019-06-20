using Plots


function planogram(products, shelves, blocks, P_b, H_s, W_p, W_s, n_ps, o_s, b_bs, x_bs)
    # Cumulative shelf heights
    y_s = vcat([0], cumsum(H_s))

    # Initialize the plot
    plt = plot(legend=false)

    # Draw products
    rect(x, y, w, h) = Shape(x .+ [0,w,w,0], y .+ [0,0,h,h])
    block_colors = cgrad(:viridis)
    # TODO: product labels
    # TODO: product stack
    # TODO: empty space
    for b in blocks
        for s in shelves
            x = x_bs[b, s]
            for p in P_b[b]
                for i in 1:n_ps[p, s]
                    plot!(plt, rect(x, y_s[s], W_p[p], H_p[p]),
                          color=block_colors[b])
                    x += W_p[p]
                end
            end
        end
    end

    # Draw shelves
    for s in shelves
        # Draw a line from (0, y[s]) to (W_s[s], y[s])
        plot!(plt, [0, W_s[s]], [y_s[s], y_s[s]],
              color = :black, label="s_$s")
    end
    plot!(plt, [0, W_s[end]], [y_s[end], y_s[end]],
          color = :black, linestyle = :dash, label="bound")

    return plt
end
