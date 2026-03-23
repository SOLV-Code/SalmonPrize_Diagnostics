# module SalmonModel
using ComponentArrays
using DataFrames
# using AxisKeys
using OffsetArrays
using StatsFuns
using Distributions
using StatsPlots, StatsPlots.PlotMeasures
using ColorSchemes

# export transition!,
#     unstack_returns,
#     SalmonStock,
#     nfresh,
#     nocean,
#     nyears,
#     ageclasses,
#     SalmonDynamics,
#     StockProblem,
#     transition_probabilities,
#     survival_freshwater!,
#     smoltification!,
#     survival_ocean!,
#     spawning!,
#     hatching!,
#     transition!
#     simulate,
#     cost

include(joinpath(@__DIR__, "turing_utils.jl"))

function unstack_returns(returns)
    nfresh = maximum(returns.age_fresh) + 1
    nocean = maximum(returns.age_ocean)
    nyears = maximum(returns.return_year) - minimum(returns.return_year) + 1

    full_returns = allcombinations(DataFrame,
        return_year = minimum(returns.return_year):maximum(returns.return_year),
        age_fresh = 0:(nfresh-1),
        age_ocean = 1:nocean)
    full_returns = leftjoin(full_returns, returns, on=[:return_year, :age_fresh, :age_ocean])
    full_returns = sort(full_returns, [:return_year, :age_fresh, :age_ocean])
    replace!(full_returns.returns, missing => 0)
    arr = reshape(full_returns.returns, nfresh, nocean, nyears)
    arr = collect(disallowmissing(arr))
    arr = OffsetArrays.Origin(0, 1, 1)(arr)
    return arr
end

# struct SalmonStock{T1,T2,T3,T4,T5,T6,T7}
#     year::T1
#     returns::T2
#     escapement::T3
#     ii::T4
#     returns_finite::T5
#     X_fresh::T6
#     X_ocean::T7
# end


# x = zeros(50); x[20] = 1
# y = zeros(50); y[21] = 1
# bar(0:7, crosscor(x, y, 0:7))
function preselect_covariates(returns_arr, X, n=min(10, size(X, 1)), lag=7)
    returns = vec(sum(returns_arr, dims=(1, 2)))
    lags = 0:7
    ccfs = [crosscor(X[i, :], returns, lags) for i in 1:size(X, 1)]
    ccf_max = [maximum(abs.(c)) for c in ccfs]
    ii = sortperm(ccf_max, rev=true)[1:n]
    return X[ii, :]
end

function SalmonStock(returns_long, X_fresh, X_ocean, stock_name;
        select_covs=true, ncovs=10, cov_lag=7)
    dfr = returns_long[returns_long.stock .== stock_name, :]
    inyears = in(dfr.return_year)
    dfx_fresh = sort(X_fresh[inyears.(X_fresh.year), :], :year)
    dfx_ocean = sort(X_ocean[inyears.(X_ocean.year), :], :year)
    returns_arr = unstack_returns(dfr)
    ii = findall(!ismissing, returns_arr)
    returns_finite = disallowmissing(returns_arr[ii])
    i_spawn = findall(>(0), dropdims(sum(returns_arr, dims=3), dims=3))

    X_fresh = collect(Array(select(dfx_fresh, Not(:year)))')
    X_ocean = collect(Array(select(dfx_ocean, Not(:year)))')
    if select_covs
        X_fresh = preselect_covariates(returns_arr, X_fresh, ncovs, cov_lag)
        X_ocean = preselect_covariates(returns_arr, X_ocean, ncovs, cov_lag)
    end

    return (
        stock_name = stock_name,
        year = sort(unique(dfr.return_year)),
        returns = returns_arr,
        ii = ii,
        i_spawn = i_spawn,
        returns_finite = returns_finite,
        X_fresh = X_fresh,
        X_ocean = X_ocean
    )
end

nfresh(ss) = size(ss.returns, 1)
nocean(ss) = size(ss.returns, 2) + 1
nyears(ss) = size(ss.returns, 3)
agemax_fresh(ss) = nfresh(ss) - 1
agemax_ocean(ss) = nocean(ss) - 1
ageclasses(ss) = vec([(f, o) for f in 0:agemax_fresh(ss), o in 1:agemax_ocean(ss)])

function stock_state_array(T, ss)
    N = zeros(T, nfresh(ss), nocean(ss), 2)
    return OffsetArray(N, 0:agemax_fresh(ss), 0:agemax_ocean(ss), 1:2)
end
stock_state_array(ss) = stock_state_array(Float64, ss)

function simulation_array(T, ss)
    N = zeros(T, nfresh(ss), nocean(ss), 2, nyears(ss))
    return OffsetArray(N, 0:agemax_fresh(ss), 0:agemax_ocean(ss), 1:2, 1:nyears(ss))
end
simulation_array(ss) = simulation_array(Float64, ss)

abstract type SalmonDynamics end
# struct SalmonDynamics{T1,T2,T3,T4,T5}
#     f_fresh::T1
#     f_smolt::T2
#     f_ocean::T3
#     f_spawn::T4
#     f_eggs::T5
# end

struct StockProblem{T1,T2,T3}
    stock::T1
    dynamics::T2
    priors::T3
end
StockProblem(stock, dynamics) = StockProblem(stock, dynamics, u -> 0)

initial_u(problem::StockProblem) = initial_u(problem, problem.dynamics)

function survival_freshwater!(n_new, n, p)
    n_new[1:end, 0, 1] = n[0:(end-1), 0, 1] .* p.survival_fresh
end

function smoltification!(n_new, n, p)
    # smoltification (ocean age 0 -> 1)
    smolts = p.smoltification .* n[0:end, 0, 1]
    # remove smolts from freshwater column
    n_new[0:end, 0, 1] = n[0:end, 0, 1] .- smolts
    # assign them to first ocean column
    n_new[0:end, 1, 1] = smolts
end

function survival_ocean!(n_new, n, p)
    n_new[0:end, 2:end, 1] = n[0:end, 1:end-1, 1] .* p.survival_ocean
end

function spawning!(n_new, n, p, prob)
    i_spawn = prob.stock.i_spawn
    spawners = n[i_spawn, 1] .* p.spawning
    # remove spawners from growing population
    n_new[i_spawn, 1] = n[i_spawn, 1] .- spawners
    # add them to spawning segment
    n_new[i_spawn, 2] .= spawners
end

function hatching!(n_new, n, u, prob, t)
    n_new[0, 0, 1] = n_eggs(u, n, t, prob.stock, prob.dynamics)
end


function transition!(n_new, n, u, prob, t)
    p = transition_probabilities(u, n, prob, t)
    spawning!(n_new, n, p, prob)
    survival_ocean!(n_new, n, p)
    smoltification!(n_new, n, p)
    survival_freshwater!(n_new, n, p)
    hatching!(n_new, n, u, prob, t)
    return n_new
end


struct TransitionProbabilities{T1, T2, T3, T4}
    survival_fresh::T1
    smoltification::T2
    survival_ocean::T3
    spawning::T4
end

function transition_probabilities(u, n, prob, t=1)
    stock = prob.stock
    dynamics = prob.dynamics
    v = TransitionProbabilities(
        p_fresh(u, n, t, stock, dynamics),
        p_smolt(u, n, t, stock, dynamics),
        p_ocean(u, n, t, stock, dynamics),
        p_spawn(u, n, t, stock, dynamics)
    )
    return v
end

function simulate(u, prob)
    stock = prob.stock
    Nsim = simulation_array(eltype(first(u)), stock)
    n = exp.(u.log_n0)
    Nsim[:, :, :, 1] = n
    @views for t in 2:nyears(stock)
        transition!(Nsim[:,:,:,t], Nsim[:,:,:,t-1], u, prob, t) 
    end
    return Nsim
end

# function cost(u, problem)
#     Nsim = simulate(u, problem)
#     predicted_returns = Nsim[:, :, 2, :]

#     i_spawn = problem.stock.i_spawn
#     # σ = exp.(u.log_σ)
#     s = map(1:nyears(problem.stock)) do t
#         pred = predicted_returns[i_spawn, t]
#         obs = problem.stock.returns[i_spawn, t]
#         # sum(abs2, pred.- obs)
#         # sum(abs2, sqrt.(pred) .- sqrt.(obs))
#         sum(abs2, log.(pred .+ 1e-6) .- log.(obs .+ 1e-6))
        
#         # Exponential seems to be problematic, right tail too long
#         # -sum(logpdf.(Exponential.(pred .+ eps()), obs))

#         # σ1 = sqrt.(1 .+ obs) .* σ
#         # d = MvNormal(predicted_returns[i_spawn, t], σ1)
#         # -logpdf(d, problem.stock.returns[i_spawn, t])
#     end
#     c = sum(s) + problem.priors(u)
#     return isnan(c) ? Inf : c
# end

function callback(state, loss) 
    if state.iter % 100 == 0
        # println("[$(state.iter)] $(loss)")
        print("\e[2K")
        print("\e[1G") # move cursor to column 1
        print("[$(state.iter)] $(loss)")
    end
    return false
end


function forecast(u, prob, summary=:none)
    Nsim = simulate(u, prob)
    n_next = stock_state_array(prob.stock)
    t = size(Nsim, 4)
    transition!(n_next, Nsim[:, :, :, end], u, prob, t)
    return n_next
end
forecast_spawners(u, prob) = forecast(u, prob)[:, :, 2]
forecast_total(u, prob) = sum(forecast_spawners(u, prob))


function ts_plots(u, prob)
    stock = prob.stock
    Nsim = simulate(u, prob)
    Robs = stock.returns[stock.i_spawn, :] 
    Rsim = Nsim[stock.i_spawn ,2, :]

    p_ts_age = plot(stock.year, Rsim', legend=:outerright,
        palette=:glasbey_bw_minc_20_n256,
        #palette=:tab20b,
        label = reshape([string(s.I) for s in stock.i_spawn], 1, :));
    scatter!(p_ts_age, stock.year, Robs', c=[1:18;]', label="")

    p_ts_total = plot(stock.year, [sum(Robs, dims=1)', sum(Rsim, dims=1)'], marker=:o,
        legend=:outerright, label=["Observed" "Fitted"], xlabel="Year", ylabel="Total returns")
    p_scat = scatter(sum(Rsim, dims=1)', sum(Robs, dims=1)', legend=false, marker=:o,
        xlabel="Fitted", ylabel="Observed");
    plot!(p_scat, x -> x, 0, maximum(sum(Rsim, dims=1)))
    
    l = @layout [[a; b] c{0.3w}]
    plot(p_ts_age, p_ts_total, p_scat, layout=l, size=(1000, 600), 
        plot_title=prob.stock.stock_name * ": " * describe(prob.dynamics))
end

function heatmap_plots(u, prob)
    stock = prob.stock
    Nsim = simulate(u, prob)
    Robs = stock.returns[stock.i_spawn, :] 
    Rsim = Nsim[stock.i_spawn ,2, :]
    p_heatmap = plot(
        heatmap(stock.year, 1:18, Rsim, clim=(0, 1e7)),
        heatmap(stock.year, 1:18, Robs, clim=(0, 1e7)),
        yticks=(1:18, [string(s.I) for s in stock.i_spawn]),
        xlabel="Year", ylabel="Age class",
        clim = extrema(skipmissing(Robs)), layout=(2,1), size=(800, 800)
    );
    p_resid = heatmap(stock.year, 1:18, log10.(Rsim ./ Robs), cmap=:balance, clim=(-10, 10),
        yticks=(1:18, [string(s.I) for s in stock.i_spawn]),
        xlabel="Year", ylabel="Age class")
        
    Mobs = mean(prob.stock.returns, dims=3)[:, 1:end, 1].parent
    Msim = mean(Nsim[:,:,2,:], dims=3)[:, 1:end, 1].parent
    p_m = plot(
        heatmap(Mobs, title="Avg observed"),
        heatmap(Msim, title="Avg simulated"),
        yticks=(1:4, 0:3), clim=(0, 2.5),
        layout=(2, 1),
        xlabel="Ocean age", ylabel="Freshwater age"
    )
    l = @layout [a [b; c]]
    plot(p_heatmap, p_resid, p_m, layout = l)
end

function ricker_plot(u, prob)
    Nsim = simulate(u, prob)
    spawners = [sum(Nsim[:, :, 2, t]) for t in 1:size(prob.stock.returns, 3)]
    # returns = vec(sum(stock.returns, dims=(1,2)))
    recruits = Nsim[0, 0, 1, :]

    r = exp(u.eggs[1])
    k = exp(u.eggs[2])
    p = scatter(spawners, recruits)
    plot!(p, s -> s * exp(r * (1 - s / k)), 0, maximum(spawners), legend=false,
        xlabel="Modeled spawners", ylabel="Modeled fry")
    return p
end


function evaluation(n_pred, opt, new_prob, t)
    (
        stock_name = new_prob.stock.stock_name,
        dynamics = first(split(string(new_prob.dynamics), "{")),
        priors = string(new_prob.priors),
        year = t,
        returns_pred = sum(n_pred[:, :, 2]),
        returns_obs = sum(new_prob.stock.returns[:, :, end]),
        training_objective = opt.objective,
        nparams = length(opt.u)
    )
end

function updated_u(u0, prob)
    u1 = initial_u(prob)
    for k in keys(u0)
        i0 = CartesianIndices(u0[k])
        i1 = CartesianIndices(u1[k])
        i_common = intersect(i1, i0)
        i_new = setdiff(i1, i0)
        for i in i_common
            u1[k][i] = u0[k][i]
        end
        for i in i_new
            u1[k][i] = randn()
        end
        # if n1 != n0
        #     u1[k] = [u0[k]; randn(n1 - n0)]
        # else
        #     u1[k] = u0[k]
        # end
    end
    return u1
end

function train_test(stock_name, dynamics, cost, year_train, returns_long, fresh, ocean;
        algorithm=PolyOpt(), maxiters=10_000, maxiters_update=round(Int, maxiters/2),
        priors=u->0, ncovs=5)
    returns_train = filter(:return_year => <=(year_train), returns_long)
    stock = SalmonStock(returns_train, fresh, ocean, stock_name, ncovs=ncovs)
    dyn = dynamics(stock)
    prob = StockProblem(stock, dyn, priors)
    u0 = initial_u(prob, dyn)

    println("Training through $year_train...")
    f_opt = OptimizationFunction(cost, AutoReverseDiff(true))
    p_opt = OptimizationProblem(f_opt, u0, prob)
    opt = solve(p_opt, algorithm, maxiters=maxiters, callback=callback)

    tmax = maximum(returns_long.return_year)
    results = []
    for t in year_train+1:tmax
        println()
        println(t) 
        
        n_pred = forecast(opt.u, prob)
        returns_train = filter(:return_year => <=(t), returns_long)
        stock = SalmonStock(returns_train, fresh, ocean, stock_name, ncovs=ncovs)
        prob = StockProblem(stock, dynamics(stock), priors)
        push!(results, evaluation(n_pred, opt, prob, t))

        u0 = updated_u(opt.u, prob)
        p_opt = remake(p_opt, u0=u0, p=prob)
        opt = solve(p_opt, algorithm, maxiters=maxiters_update, callback=callback)
        # n_pred = forecast(opt.u, prob)
    end
    println()
    
    r = last(results)
    forecast_row = (; r...,
        year = tmax + 1,
        returns_pred = forecast_total(opt.u, prob),
        returns_obs = missing
    )
    push!(results, forecast_row)

    return DataFrame(results)
end

function plot_train_test(res)

    resid = res.returns_pred .- res.returns_obs
    r2 = 1 - var(resid) / var(res.returns_obs)
    c = cor(res.returns_pred, res.returns_obs)
    axmax = max(maximum(res.returns_obs), maximum(res.returns_pred))

    p1 = plot(res.year, [res.returns_obs, res.returns_pred], marker=:o,
        xticks = minimum(res.year):2:maximum(res.year), ylims=(0, axmax),
        label=["Observed" "Predicted"], xlabel="Year", ylabel="Total returns")
    p2 = scatter(res.returns_pred, res.returns_obs)
    plot!(p2, x -> x, 0, axmax, legend=false,
        xlabel="Predicted", ylabel="Observed")
    # annotate!(p2, (0, axmax, ("R² = $(round(r2, digits=3))", 12, :left)))
    annotate!(p2, (0, axmax, ("Cor. = $(round(c, digits=3))", 12, :left)))
    plot(p1, p2, layout=(1, 2),
        plot_title=first(res.stock_name) * ", " * first(res.dynamics),
        size=(800, 400), margin=10px)
end

# end # module