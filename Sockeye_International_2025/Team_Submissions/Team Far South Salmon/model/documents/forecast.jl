using CSV
using DataFrames
using DataFramesMeta
using StatsBase
using AlgebraOfGraphics
using CairoMakie

nn_files = filter(contains("train_test_nn"), readdir(@__DIR__, join=true))
nn = map(nn_files) do f
    df = CSV.read(f, DataFrame)
end
nn = vcat(nn...)
nn = @chain nn begin
    @select(Not(:priors, :cost))
end

rnn_files = filter(contains("train_test_lstm"), readdir(@__DIR__, join=true))
rnn = map(rnn_files) do f
    df = CSV.read(f, DataFrame)
end
rnn = vcat(rnn...)
rnn = @chain rnn begin
    @subset(
        in([2, 4, 6]).(:nlatent),
        :cost .== "cost_ss"
    )
    @transform(:dynamics = :dynamics .* string.(:nlatent))
    @select(Not(:nlatent, :cost))
end

tt = [nn; rnn]

data(tt) * mapping(:returns_pred, :returns_obs, color=:dynamics, marker=:stock_name) *
    visual(Scatter) |> draw(axis = (; limits=(0, 30, 0, 30)))

tt = @chain tt begin
    @subset(:returns_pred .< 100)
    @transform(
        :aic = 2*:nparams + 2*:training_objective,
        :resid = :returns_pred .- :returns_obs,
    )
    @groupby(:stock_name)
    @transform(:delta = :aic .- minimum(:aic))
    @transform(:w_aic = exp.(-0.5 * :delta))
end

weights = @chain tt begin
    @subset(.!ismissing.(:returns_obs))
    @by([:stock_name, :dynamics],
        :rel_err = mean(abs.(:resid) ./ :returns_obs)
    )
    @transform(:w_err = 1 ./ :rel_err)
end

hindcast = @chain tt begin
    @subset(:year .< 2025)
    leftjoin(weights, on=[:stock_name, :dynamics])
    disallowmissing()
    @by([:stock_name,  :year],
        :returns_obs = only(unique(:returns_obs)),
        :pred_aic = mean(:returns_pred, Weights(:w_aic)),
        :pred_err = mean(:returns_pred, Weights(:w_err))
    )
    @transform(:pred_tot = (:pred_err .+ :pred_aic) ./ 2)
end

data(stack(hindcast, Not(:stock_name, :year, :returns_obs))) *
    mapping(:value, :returns_obs, color=:variable) * visual(Scatter) |> draw()


fcast = @chain tt begin
    @subset(:year .== 2025)
    @select(Not(:returns_obs, :resid))
    leftjoin(weights, on=[:stock_name, :dynamics])
    disallowmissing()
    @by([:stock_name, :year],
        :pred_aic = mean(:returns_pred, Weights(:w_aic)),
        :pred_err = mean(:returns_pred, Weights(:w_err))
    )
    @transform(
        :pred_tot = (:pred_err .+ :pred_aic) ./ 2,
        :returns_obs = missing)
end

preds = @chain [hindcast; fcast]  begin
    stack(Not(:stock_name, :year))
end
data(preds) *
    mapping(:year, :value, color=:variable, layout=:stock_name) *
    visual(ScatterLines) |> draw(facet=(; linkyaxes=:none), figure=(; size=(1000, 800)))

@chain hindcast begin
    stack(Not(:stock_name, :year, :returns_obs))
    @transform(:err = abs.(:value .- :returns_obs) ./ :returns_obs)
    @by(:variable, :err = mean(:err))
end

@chain preds begin
    @subset(:variable .== "pred_err", :year .== 2025)
    @transform(:value = round.(Int, :value * 1e6))
end