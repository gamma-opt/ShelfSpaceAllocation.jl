module ShelfSpaceAllocation

include("model.jl")
export ShelfSpaceAllocationModel,
    Specs,
    Params,
    Variables,
    Objectives,
    save_results

include("plotting.jl")
export planogram,
    product_facings,
    block_allocation,
    demand_and_sales,
    fill_amount,
    fill_percentage

end # module
