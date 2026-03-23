function cost_ss(u, problem)
    Nsim = simulate(u, problem)
    predicted_returns = Nsim[:, :, 2, :]

    i_spawn = problem.stock.i_spawn
    # σ = exp.(u.log_σ)
    s = map(1:nyears(problem.stock)) do t
        pred = predicted_returns[i_spawn, t]
        obs = problem.stock.returns[i_spawn, t]
        sum(abs2, pred.- obs)
    end
    c = sum(s) + problem.priors(u)
    return isnan(c) ? Inf : c
end

function cost_sabs(u, problem)
    Nsim = simulate(u, problem)
    predicted_returns = Nsim[:, :, 2, :]

    i_spawn = problem.stock.i_spawn
    # σ = exp.(u.log_σ)
    s = map(1:nyears(problem.stock)) do t
        pred = predicted_returns[i_spawn, t]
        obs = problem.stock.returns[i_spawn, t]
        sum(abs, pred.- obs)
    end
    c = sum(s) + problem.priors(u)
    return isnan(c) ? Inf : c
end


function cost_log_ss(u, problem)
    Nsim = simulate(u, problem)
    predicted_returns = Nsim[:, :, 2, :]

    i_spawn = problem.stock.i_spawn
    # σ = exp.(u.log_σ)
    s = map(1:nyears(problem.stock)) do t
        pred = predicted_returns[i_spawn, t]
        obs = problem.stock.returns[i_spawn, t]
        sum(abs2, log.(pred .+ 1e-6) .- log.(obs .+ 1e-6))
    end
    c = sum(s) + problem.priors(u)
    return isnan(c) ? Inf : c
end

function priors_normal(u)
    d = Normal(0, 1)
    s = 0
    for env in [:ocean, :fresh]
        for k in keys(u[env])
            s -= sum(logpdf.(d, u[env][k]))
        end
    end
    return s
end

function priors_t3(u)
    d = TDist(3)
    s = 0
    for env in [:ocean, :fresh]
        for k in keys(u[env])
            s -= sum(logpdf.(d, u[env][k]))
        end
    end
    return s
end