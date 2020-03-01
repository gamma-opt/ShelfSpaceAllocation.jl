module ShelfSpaceAllocation

include("model.jl")
export ShelfSpaceAllocationModel,
    Specs,
    Params,
    Variables,
    Objectives,
    save_results

include("plotting.jl")
export plot_planogram,
    plot_planograms,
    plot_block_allocation,
    plot_block_allocations,
    plot_product_facings,
    plot_demand_and_sales,
    plot_fill_amount,
    plot_fill_percentage,
    plot_planogram_no_blocks

end # module
