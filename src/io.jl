using CSV, JSON, DataFrames

"""Load sets, subsets and parameters from CSV files.

Each CSV file in `product_path` contains following attributes:

- `product_id`
- `category_id`
- `brand_id`
- `width`
- `height`
- `depth`
- `weight`
- `monthly_demand`
- `replenishment_interval`
- `price`
- `unit_margin`
- `blocking_field`
- `min_facing`
- `max_facing`
- `max_stack`
- `up_down_order_criteria`

Each CSV file in `shelf_path` contains following attributes:

- `module`
- `id`
- `level`
- `total_width`
- `total_height`
- `total_length`
- `product_min_unit_weight`
- `product_max_unit_weight`

Examples of input parameters can found inside `examples/instances` directory.

# Arguments
- `product_path::AbstractString`
- `shelf_path::AbstractString`
"""
function Params(product_path::AbstractString, shelf_path::AbstractString)
    # Load data from CSV files. Data is read into a DataFrame
    product_data = CSV.read(product_path) |> DataFrame
    shelf_data = CSV.read(shelf_path) |> DataFrame

    # Sets and Subsets
    products = 1:size(product_data, 1)
    shelves = 1:size(shelf_data, 1)

    # Blocks
    bfs = product_data.blocking_field
    P_b = [collect(products)[bfs .== bf] for bf in unique(bfs)]
    blocks = 1:size(P_b, 1)

    # Modules
    mds = shelf_data.module
    S_m = [collect(shelves)[mds .== md] for md in unique(mds)]
    modules = 1:size(S_m, 1)

    # Return Params struct
    Params(
        products = products,
        shelves = shelves,
        blocks = blocks,
        modules = modules,
        P_b = P_b,
        S_m = S_m,
        G_p = product_data.unit_margin,
        H_s = shelf_data.total_height,
        L_p = product_data.up_down_order_criteria,
        P_ps = transpose(shelf_data.total_length) ./ product_data.depth,
        D_p = product_data.monthly_demand,
        N_p_min = product_data.min_facing,
        N_p_max = product_data.max_facing,
        W_p = product_data.width,
        W_s = shelf_data.total_width,
        M_p = product_data.weight,
        M_s_min = shelf_data.product_min_unit_weight,
        M_s_max = shelf_data.product_max_unit_weight,
        R_p = product_data.replenishment_interval,
        L_s = shelf_data.level,
        H_p = product_data.height,
        SK_p = product_data.max_stack
    )
end

"""Save object into JSON file.

# Arguments
- `object`
- `output_path::AbstractString`: Full filepath, e.g., `path.json`.
"""
function save_json(object, filepath::AbstractString)
    open(filepath, "w") do io
        JSON.print(io, object)
    end
end

flatten(x::Array{<:Array, 1}) = Iterators.flatten(x)|> collect|> flatten
flatten(x::Array{<:Number, 1}) = x

shape(x::Array{<:Array, 1}) = vcat(shape(first(x)), [length(x)])
shape(x::Array{<:Number, 1}) = [length(x)]

mdim(x::Array{<:Array, 1}) = reshape(flatten(x), shape(x)...)
mdim(x::Array{<:Number, 1}) = x

transform(x::Array, t::Type{Array{T, N}}) where T <: Number where N = mdim(x)
transform(x::Array, t::Type{Array{T, 1}}) where T <: Array = x
transform(x::Number, t::Type{T}) where T <: Number = x

function convert_type(::Type{Array{T, N}}) where T <: Number where N
    t = T
    for i in 1:N
        t = Array{t, 1}
    end
    return t
end
convert_type(::Type{Array{T, 1}}) where T <: Array = Array{T, 1}
convert_type(t::Type{T}) where T <: Number = t

"""Load values to type from JSON file.

# Arguments
- `type`
- `filepath::AbstractString`
"""
function load_json(type, filepath::AbstractString)
    objects = JSON.parsefile(filepath)
    fields = []
    for (s, t) in zip(fieldnames(type), fieldtypes(type))
        push!(fields,
              objects[string(s)] |>
              v -> convert(convert_type(t), v) |>
              v -> transform(v, t))
    end
    type(fields...)
end
