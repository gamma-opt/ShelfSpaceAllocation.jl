module ShelfSpaceAllocation

include("model.jl")
export ShelfSpaceAllocationModel,
    Specs,
    Params,
    Variables,
    Objectives,
    save_json

include("plotting.jl")
export plot_planogram,
    plot_planograms,
    plot_planogram_no_blocks,
    plot_block_allocation,
    plot_block_allocations,
    plot_product_facings,
    plot_demand_and_sales,
    plot_allocation_amount,
    plot_allocation_percentage

end # module
