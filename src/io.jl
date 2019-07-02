using JSON

"""Save the values of all variables into file."""
function save(model)
    # TODO: filename, datetime
    # TODO: save sets and subsets
    # TODO: parameters
    # TODO: optimized values for variables
    # TODO: handle data types
    d = Dict(k => Array(value.(v)) for (k, v) in model.obj_dict)
    open("solution.json", "w") do io
        JSON.print(io, d)
    end
end
