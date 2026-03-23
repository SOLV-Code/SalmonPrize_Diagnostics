using Lux
using Zygote
using Random
using ComponentArrays
using LinearAlgebra
using Optimization
using OptimizationPolyalgorithms
using OptimizationOptimisers: Adam
using CSV, DataFrames
using StatsBase

includet(joinpath(@__DIR__, "../src/SalmonModel.jl"))

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


function x_from_stock(stock)
    [stock.X_fresh; stock.X_ocean][:, 2:end]
end

function y_from_stock(stock)
    r = reshape(stock.returns, :, size(stock.returns, 3))
    # return sum(r, dims=1)
    return r[:, 1:end-1]
end

function SalmonLSTM(in_dims, hidden_dims, out_dims)
    lstm_cell = LSTMCell(in_dims => hidden_dims)
    returns_cell = Dense(hidden_dims => out_dims, relu)
    return @compact(; lstm_cell, returns_cell) do x::AbstractArray{T,2} where {T}
        x = reshape(x, size(x)..., 1)
        x_init, x_rest = Iterators.peel(LuxOps.eachslice(x, Val(2)))
        y, carry = lstm_cell(x_init)
        output = [vec(returns_cell(y))]
        for x in x_rest
            y, carry = lstm_cell((x, carry))
            output = vcat(output, [vec(returns_cell(y))])
        end
        @return reduce(hcat, output)
    end
end

struct LSTMStockProbelm{T1,T2,T3,T4,T5,T6,T7}
    stock_name::T1
    x::T2
    y::T3
    model::T4
    ps::T5
    nlatent::T6
    A::T7
end

function build_lstm(rng, stock, nlatent)
    x = x_from_stock(stock)
    y = y_from_stock(stock)
    i_spawn = findall(>(0), vec(sum(y, dims=2)))
    A = I(size(y, 1))[:, i_spawn]
    model_initial = SalmonLSTM(size(x, 1), nlatent, length(i_spawn))
    ps, st = Lux.setup(rng, model_initial)
    model = Lux.StatefulLuxLayer{true}(model_initial, nothing, st)
    return LSTMStockProbelm(stock.stock_name, x, y, model, ps, nlatent, A)
end
build_lstm(stock, nlatent) = build_lstm(Random.MersenneTwister(1234), stock, nlatent)

initial_u(prob::LSTMStockProbelm) = ComponentArray(prob.ps) * 1.0

ss(y, x) = sum(abs2, y .- x)
mse(y, x) = mean(abs2, y .- x)
rmse(y, x) = sqrt(mean(abs2, y .- x))
sabs(y, x) = sum(abs, y .- x)
log_ss(y, x) = sum(abs2, log.(y .+ 1e-6) .- log.(x .+ 1e-6))

function predict(u, lstm_prob::LSTMStockProbelm)
    output = Lux.apply(lstm_prob.model, lstm_prob.x, u)
    return lstm_prob.A * output
end

function objective(u, lstm_prob, cost=ss)
    y_pred = predict(u, lstm_prob)
    cost(y_pred, lstm_prob.y) 
end

cost_ss(u, lstm_prob) = objective(u, lstm_prob, ss)
cost_sabs(u, lstm_prob) = objective(u, lstm_prob, sabs)
cost_log_ss(u, lstm_prob) = objective(u, lstm_prob, log_ss)

stock_name = "Quesnel"
stock = SalmonStock(returns_long, fresh, ocean, stock_name, ncovs=3)
lstm_prob = build_lstm(stock, 4)
u0 = initial_u(lstm_prob)
length(u0)
objective(u0, lstm_prob)


opt_func = Optimization.OptimizationFunction(cost_ss, Optimization.AutoZygote())
opt_prob = Optimization.OptimizationProblem(opt_func, u0, lstm_prob)
opt_sol = Optimization.solve(opt_prob, PolyOpt(), maxiters=2_000, callback=callback)

Npred = predict(opt_sol.u, lstm_prob)
Nobs = reshape(stock.returns, :, size(stock.returns, 3))
plot(
    heatmap(Npred),
    heatmap(Nobs),
    clim=(0, 6), layout=(2,1)
)

plot([sum(Npred, dims=1)', sum(Nobs, dims=1)'], label=["Pred" "Obs"])
scatter(sum(Npred, dims=1)', sum(Nobs, dims=1)')

function evaluation_lstm(n_pred, opt, lstm_prob, t)
    (
        stock_name = lstm_prob.stock_name,
        dynamics = "LSTM",
        nlatent = lstm_prob.nlatent,
        year = t,
        returns_pred = sum(n_pred[:, end]),
        returns_obs = sum(lstm_prob.y[:, end]),
        training_objective = opt.objective,
        nparams = length(opt.u)
    )
end


function train_test_lstm(stock_name, nlatent, cost, year_train, returns_long, fresh, ocean;
        ncovs=5, algorithm=PolyOpt(), maxiters=2_000, maxiters_update=round(Int, maxiters/2))

    returns_train = filter(:return_year => <=(year_train), returns_long)
    stock = SalmonStock(returns_train, fresh, ocean, stock_name, ncovs=ncovs)
    lstm_prob = build_lstm(stock, nlatent)
    u0 = initial_u(lstm_prob)

    println("Training through $year_train...")
    opt_func = Optimization.OptimizationFunction(cost, Optimization.AutoZygote())
    opt_prob = Optimization.OptimizationProblem(opt_func, u0, lstm_prob)
    opt_sol = Optimization.solve(opt_prob, algorithm, maxiters=maxiters, callback=callback)
    
    tmax = maximum(returns_long.return_year)
    results = []
    for t in year_train+1:tmax
        println()
        println(t) 

        n_pred = predict(opt_sol.u, lstm_prob)[:, end]    
        returns_train = filter(:return_year => <=(t), returns_long)
        stock = SalmonStock(returns_train, fresh, ocean, stock_name, ncovs=ncovs)

        lstm_prob = build_lstm(stock, nlatent)

        push!(results, evaluation_lstm(n_pred, opt_sol, lstm_prob, t))
        
        u0 = updated_u(opt_sol.u, lstm_prob)
        opt_prob = remake(opt_prob, u0=u0, p=lstm_prob)
        opt_sol = solve(opt_prob, algorithm, maxiters=maxiters_update, callback=callback)
    end
    println()

    n_pred = predict(opt_sol.u, lstm_prob)[:, end]    
    r = last(results)
    forecast_row = (; r...,
        year = tmax + 1,
        returns_pred = sum(n_pred[:, end]),
        returns_obs = missing
    )
    push!(results, forecast_row)
    return DataFrame(results)
end

tt_eg = train_test_lstm("Kvichak", 20, cost_ss, 2010, returns_long, fresh, ocean,
    ncovs=2, maxiters=3000)
scatter(tt_eg.returns_pred, tt_eg.returns_obs);
plot!(x -> x, 0, maximum(tt_eg.returns_pred))
plot([tt_eg.returns_pred, tt_eg.returns_obs])

tt_eg = train_test_lstm("Quesnel", 6, cost_ss, 2018, returns_long, fresh, ocean,
    maxiters=5000)

year_train = 2010
maxiters = 3000
for stock_name in unique(returns_long.stock)[7:end]#["Egegik", "Kvichak", "Bonneville Lock & Dam", "Quesnel"]
    println(stock_name)
    train_test_results = []
    for cost in [cost_ss]#, cost_log_ss]
        for nlatent in [2, 4, 6]#2:7
            println("$(stock_name), $(cost), nlatent=$(nlatent)")
            res = train_test_lstm(stock_name, nlatent, cost, year_train, returns_long,
                fresh, ocean, maxiters=maxiters, maxiters_update=maxiters)
            res.cost .= string(cost)
            push!(train_test_results, res)
        end
    end
    CSV.write(joinpath(@__DIR__, "train_test_lstm_$(stock_name).csv"),
        vcat(train_test_results...))
end


using TidierData
# using TidierPlots
using AlgebraOfGraphics
using ColorSchemes


tt_files = filter(contains("train_test_lstm"), readdir(@__DIR__, join=true))
tt = map(tt_files) do f
    df = CSV.read(f, DataFrame)
end
tt = vcat(tt...)

data(tt) * mapping(:returns_pred, :returns_obs, color=:nlatent, marker=:stock_name) *
    visual(CairoMakie.Scatter) |> draw()

aic_df = @chain tt begin
    @filter(year == 2019)
    @mutate(aic = 2nparams + 2training_objective) # cost is alredy ~negative likelihood
    @mutate(delta = aic - minimum(aic))
    @mutate(nlatent = float(nlatent))
    @group_by(cost, nlatent, stock_name)
    @summarize(aic = mean(aic))
    @ungroup()
end

p = data(aic_df) * mapping(:nlatent, :aic, color=:stock_name, layout=:cost) *
    (visual(CairoMakie.Scatter) + visual(CairoMakie.Lines))
draw(p)


pred_err = @chain tt begin
    @mutate(resid = returns_pred - returns_obs)
    @group_by(stock_name, nlatent, cost)
    @summarize(
        r2 = 1 - var(resid) / var(returns_obs),
        rmse = sqrt(mean(abs2.(resid))),
        mean = mean(returns_obs)
    )
    @ungroup()
    @mutate(cv = rmse / mean)
    @arrange(r2)
end
@filter(pred_err, r2 > -10)

p = data(pred_err) * mapping(:nlatent, :cv, color=:stock_name, marker=:cost) *
    visual(CairoMakie.Scatter)
draw(p)

p = ggplot(pred_err, @aes(x=nlatent, y=cv, color=stock_name)) + 
    geom_point() + geom_line() + scale_color_discrete(palette=:Paired_9) +
    facet_wrap(:cost)
draw_ggplot(p, (1000, 500))
ggsave(p, "plots/cv_ltsm.png", width=1000, height=500)