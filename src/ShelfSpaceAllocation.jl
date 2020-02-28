module ShelfSpaceAllocation

include("model.jl")
export shelf_space_allocation_model, load_parameters, save_results, extract_variables, extract_objectives

include("plotting.jl")
export planogram, product_facings, block_allocation, demand_and_sales, fill_amount, fill_percentage

end # module
