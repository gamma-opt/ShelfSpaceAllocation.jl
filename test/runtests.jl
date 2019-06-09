using JuMP, Gurobi

function test_milp_gurobi()
    model = Model(with_optimizer(Gurobi.Optimizer))
    @variable(model, 0 ≤ x ≤ 1)
    @variable(model, 0 ≤ y ≤ 1)
    @variable(model, 0 ≤ z ≤ 1)
    @objective(model, Max, x + y + 2z)
    @constraint(model, con1, x + 2y + 3z ≤ 4)
    @constraint(model, con2, x + y ≥ 1)
    optimize!(model)
end

test_milp_gurobi()
