using CSV, DataFrames
using Statistics, StatsBase
using StatsFuns
using LinearAlgebra
using ComponentArrays
using Optimization
using OptimizationPolyalgorithms
using OptimizationOptimisers: Adam
using OptimizationOptimJL: BFGS, LBFGS
using ReverseDiff
using StatsPlots

includet(joinpath("../src/", "SalmonModel.jl"))
includet(joinpath("../src/", "model_dynamics.jl"))
includet(joinpath(@__DIR__, "../src/cost_functions.jl"))

returns_long = CSV.read(joinpath(@__DIR__, "../data/sockeye.csv"), DataFrame)
# rescale so objectives aren't so huge
returns_long.returns ./= 1e6


center(x) = (x .- mean(x)) ./ std(x)
ocean = CSV.read(joinpath(@__DIR__, "../data/ocean/sst_pca_loadings_annual.csv"), DataFrame)
for i in 1:ncol(ocean)-1
    ocean[:, i] = center(ocean[:, i])
end
rename!(ocean, Dict(:salmon_year => :year))

fresh = CSV.read(joinpath(@__DIR__, "../data/freshwater/bristol_annual_pca.csv"), DataFrame)
fresh = fresh[:, 2:end]
for i in 2:ncol(fresh)
    fresh[:, i] = center(fresh[:, i])
end

stock_name = "Quesnel"
stock = SalmonStock(returns_long, fresh, ocean, stock_name, ncovs=5)
# dynamics = NeuralNetRicker(stock)
dynamics = GLMRicker(stock)

prob = StockProblem(stock, dynamics, priors_normal)
u0 = initial_u(prob)
length(u0)
cost_ss(u0, prob)

f_opt = OptimizationFunction(cost_ss, AutoReverseDiff(true))
p_opt = OptimizationProblem(f_opt, u0, prob)
sol1 = solve(p_opt, PolyOpt(), maxiters=10_000, callback=callback)

ts_plots(sol1.u, prob)
heatmap_plots(sol1.u, prob)

#################################################################################

res = train_test("Quesnel", NeuralNetRicker, cost_ss, 2010, returns_long, fresh, ocean,
    maxiters=9_0, priors=priors_normal, ncovs=3)
plot_train_test(res)

year_train = 2010
maxiters = 10_000
for stock_name in unique(returns_long.stock)[10:end]#["Egegik", "Kvichak", "Bonneville Lock & Dam", "Quesnel"]
    println(stock_name)
    train_test_results = []
    for cost in [cost_ss]# cost_log_ss]
        println(cost)

        # println("$(stock_name), $(cost), ", ConstantLinear)
        # res_cl = train_test(stock_name, ConstantLinear, cost, year_train,
        #     returns_long, fresh, ocean, maxiters=10_000)
        # res_cl.cost .= string(cost)

        println("$(stock_name), $(cost), ", ConstantRicker)
        res_cr = train_test(stock_name, ConstantRicker, cost, year_train,
            returns_long, fresh, ocean, maxiters=maxiters)
        res_cr.cost .= string(cost)

        println("$(stock_name), $(cost), ", ConstantFreeRecruit)
        res_cfr = train_test(stock_name, ConstantFreeRecruit, cost, year_train,
            returns_long, fresh, ocean, maxiters=maxiters)
        res_cfr.cost .= string(cost)

        println("$(stock_name), $(cost), ", GLMRicker)
        res_glm = train_test(stock_name, GLMRicker, cost, year_train,
            returns_long, fresh, ocean, maxiters=maxiters, priors=priors_normal,
            ncovs=5)
        res_glm.cost .= string(cost)

        println("$(stock_name), $(cost), ", NeuralNetRicker, ", Normal prior")
        res_nnr_norm = train_test(stock_name, NeuralNetRicker, cost, year_train,
            returns_long, fresh, ocean, maxiters=maxiters, priors=priors_normal,
            ncovs=5)
        res_nnr_norm.cost .= string(cost)

        # println("$(stock_name), $(cost), ", NeuralNetRicker, ", T prior")
        # res_nnr_t = train_test(stock_name, NeuralNetRicker, cost, year_train,
        #     returns_long, fresh, ocean, maxiters=20_000,
        #     priors=priors_t3)
        # res_nnr_t.cost .= string(cost)

        println("$(stock_name), $(cost), ", NeuralNet2Ricker, " Normal prior")
        res_nnr2_norm = train_test(stock_name, NeuralNet2Ricker, cost, year_train,
            returns_long, fresh, ocean, maxiters=maxiters,  priors=priors_normal,
            ncovs=5)
        res_nnr2_norm.cost .= string(cost)

        # println("$(stock_name), $(cost), ", NeuralNet2Ricker, ", T prior")
        # res_nnr2_t = train_test(stock_name, NeuralNet2Ricker, cost, year_train,
        #     returns_long, fresh, ocean, maxiters=20_000,
        #     priors=priors_t3)
        # res_nnr2_t.cost .= string(cost)

        # res = [res_cr; res_cfr; res_nnr_norm; res_nnr_t; res_nnr2_norm; res_nnr2_t]
        res = [res_cr; res_cfr; res_glm; res_nnr_norm; res_nnr2_norm]
        push!(train_test_results, res)
    end
    CSV.write(joinpath(@__DIR__, "train_test_nn_$(stock_name).csv"),
        vcat(train_test_results...))
end


using DataFramesMeta
using AlgebraOfGraphics
import CairoMakie


tt_files = filter(contains("train_test_nn"), readdir(@__DIR__, join=true))
tt = map(tt_files) do f
    df = CSV.read(f, DataFrame)
end
tt = vcat(tt...)
tt.dynamics = first.(split.(tt.dynamics, "{"))

data(tt) * mapping(:returns_pred, :returns_obs, color=:dynamics, marker=:cost, layout=:stock_name) * 
    visual(CairoMakie.Scatter) |> draw(facet=(linkxaxes=:none, linkyaxes=:none))

aic_df = @chain tt begin
    # @filter(year == 2019)
    @mutate(aic = 2nparams + 2training_objective) # cost is alredy ~negative likelihood
    @mutate(delta = aic-minimum(aic))
    # @group_by(cost, dynamics, stock_name)
    # @summarize(aic = mean(aic))
    # @ungroup()
end

p = data(aic_df) * 
    mapping(:dynamics, :aic, color=:priors, dodge=:priors, row=:stock_name, col=:cost) *
    visual(CairoMakie.BoxPlot)
draw(p, facet=(linkyaxes=:none,))


pred_err = @chain tt begin
    @mutate(resid = returns_pred - returns_obs)
    @group_by(stock_name, dynamics, priors, cost)
    @summarize(
        r2 = 1 - var(resid) / var(returns_obs),
        rmse = sqrt(mean(abs2.(resid))),
    )
    @ungroup()
    @arrange(r2)
end
@filter(pred_err, r2 > 0)


p = data(@filter(pred_err, r2>-10)) * mapping(:r2, :dynamics, color=:priors, marker=:cost) *
    visual(CairoMakie.Scatter)
draw(p, facet=(; linkyaxes=:none))

using StatsBase

pred_avg = @chain aic_df begin
    @filter(returns_pred < 50)
    @group_by(stock_name, year)
    @summarize(
        returns_pred = sum(returns_pred / delta) / sum(1/delta),
        # returns_pred = mean(returns_pred),
        returns_obs = mean(returns_obs))
    @ungroup()
end
data(pred_avg) * mapping(:returns_pred, :returns_obs, color=:stock_name) * 
    visual(CairoMakie.Scatter) |> draw()

#################################################################################
stocks = map(unique(@filter(returns_long, system=="Bristol Bay").stock)) do stock_name
    stock = SalmonStock(returns_long, ocean, fresh, stock_name)
end
# stock_problems = [StockProblem(stock, dynamics) for stock in stocks]

stock_problems = Dict(
    stock.stock_name => StockProblem(stock, dynamics_const_ricker) for stock in stocks
)

