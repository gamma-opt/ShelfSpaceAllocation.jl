# IO
For input and output of numerical values, simple plain text formats CSV and JSON are used. CSV is used for representing tabular data and JSON is used for representing non-tabular, dictionary-like, data.

## Parameters
Input parameters for products and shelves are given in tabular format as CSV files, `products.csv` and `shelves.csv`.

Each `products.csv` file contains following attributes:

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

Each `shelves.csv` file contains following attributes:

- `module`
- `id`
- `level`
- `total_width`
- `total_height`
- `total_length`
- `product_min_unit_weight`
- `product_max_unit_weight`

Examples of input parameters can found inside `examples/data` directory.

## Results
Results are best stored in a non-tabular format as JSON files.

!!! note
    When certain Julia data types are written and then read from JSON they don't retain their Julia specific data type. For example, 2-dimensional arrays will be stored as nested arrays. Where the elements of the original 2-dimensional are accessed using indices `z_bs[b, s]`, the same elements of the nested array read from the JSON file are accessed using indices `z_bs[s][b]`.

Variables are stored in `variables.json` file such that variables names, as they are written in the code, are used as keys and the values are queried from solution.

Parameters are stored in `parameters.json` file using the parameter names, as they are written in the code, are used as keys and the values as they were loaded using `load_parameters` function.

Individual objective values are written into `objectives.json` file.
