using Plots


function planogram(products, shelves, blocks, P_b, H_s, W_p, W_s, n_ps, o_s, b_bs, x_bs)
    # Cumulative shelf heights
    y_s = vcat([0], cumsum(H_s))

    # Initialize the plot
    plt = plot(legend=false)

    # Draw products
    rect(x, y, w, h) = Shape(x .+ [0,w,w,0], y .+ [0,0,h,h])
    # TODO: disctinct unique colors for all blocks
    block_colors = cgrad(:viridis)
    # TODO: block labels
    # TODO: product labels
    # TODO: disribute empty space equally
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
    # TODO: shelf labels
    for s in shelves
        plot!(plt, [0, W_s[s]], [y_s[s], y_s[s]],
              color=:black, label="s_$s")
    end
    plot!(plt, [0, W_s[end]], [y_s[end], y_s[end]],
          color=:black, linestyle=:dash)

    return plt
end
