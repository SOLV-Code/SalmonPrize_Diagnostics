
##############################################################
# Constant transition probabilities, Ricker recruitment
##############################################################
struct ConstantRicker <: SalmonDynamics end

describe(dyn::ConstantRicker) = "Constant P, Ricker recruitment"

ConstantRicker(stock, rng=Random.default_rng()) = ConstantRicker()

function initial_u(prob::StockProblem, dynamics::ConstantRicker)
    n0 = stock_state_array(prob.stock)
    nspawn = length(prob.stock.i_spawn)
    u0 = ComponentArray(
        fresh = ones(1),
        smolt = logit.(fill(0.9, nfresh(prob.stock))),
        ocean = logit.(fill(0.9, 1, agemax_ocean(prob.stock)-1)),
        spawn = logit.(fill(0.9, nspawn)), 
        eggs = randn(2),
        log_n0 = log.(n0 .+ 0.1))
        # log_σ = log.(1))
    return u0
end

p_fresh(u, n, t, stock, dyn::ConstantRicker) = logistic.(u.fresh)
p_smolt(u, n, t, stock, dyn::ConstantRicker) = logistic.(u.smolt)
p_ocean(u, n, t, stock, dyn::ConstantRicker) = logistic.(u.ocean)
p_spawn(u, n, t, stock, dyn::ConstantRicker) = logistic.(u.spawn)

function n_eggs(u, n, t, stock, dyn::ConstantRicker)
    r = exp(u.eggs[1])
    k = exp(u.eggs[2])
    # spawners = sum(n[:,:,2])
    spawners = sum(stock.returns[:, :, t])
    return spawners * exp(r * (1 - spawners / k))
end

##############################################################
# Constant transition probabilities, Linear recruitment
##############################################################
struct ConstantLinear <: SalmonDynamics end

describe(dyn::ConstantLinear) = "Constant P, Linear recruitment"

ConstantLinear(stock, rng=Random.default_rng()) = ConstantLinear()

function initial_u(prob::StockProblem, dynamics::ConstantLinear)
    n0 = stock_state_array(prob.stock)
    nspawn = length(prob.stock.i_spawn)
    u0 = ComponentArray(
        fresh = ones(1),
        smolt = logit.(fill(0.9, nfresh(prob.stock))),
        ocean = logit.(fill(0.9, 1, agemax_ocean(prob.stock)-1)),
        spawn = logit.(fill(0.9, nspawn)), 
        eggs = randn(2),
        log_n0 = log.(n0 .+ 0.1))
        # log_σ = log.(1))
    return u0
end

p_fresh(u, n, t, stock, dyn::ConstantLinear) = logistic.(u.fresh)
p_smolt(u, n, t, stock, dyn::ConstantLinear) = logistic.(u.smolt)
p_ocean(u, n, t, stock, dyn::ConstantLinear) = logistic.(u.ocean)
p_spawn(u, n, t, stock, dyn::ConstantLinear) = logistic.(u.spawn)

function n_eggs(u, n, t, stock, dyn::ConstantLinear)
    a = exp(u.eggs[1])
    b = exp(u.eggs[2])
    # spawners = sum(n[:,:,2])
    spawners = sum(stock.returns[:, :, t])
    return a + b * spawners
end

##############################################################
# Constant transition probabilities, year-specific recruitment
##############################################################
struct ConstantFreeRecruit <: SalmonDynamics end


ConstantFreeRecruit(stock, rng=Random.default_rng()) = ConstantFreeRecruit()

describe(dyn::ConstantFreeRecruit) = "Constant P, free recruitment"

function initial_u(prob::StockProblem, dynamics::ConstantFreeRecruit)
    n0 = stock_state_array(prob.stock)
    nspawn = length(prob.stock.i_spawn)
    u0 = ComponentArray(
        fresh = ones(1),
        smolt = logit.(fill(0.9, nfresh(prob.stock))),
        ocean = logit.(fill(0.9, 1, agemax_ocean(prob.stock)-1)),
        spawn = logit.(fill(0.9, nspawn)), 
        log_eggs = fill(10, nyears(prob.stock)-1),
        log_n0 = log.(n0 .+ 0.1))
        # log_σ = log.(1))
    return u0
end

p_fresh(u, n, t, stock, dyn::ConstantFreeRecruit) = logistic.(u.fresh)
p_smolt(u, n, t, stock, dyn::ConstantFreeRecruit) = logistic.(u.smolt)
p_ocean(u, n, t, stock, dyn::ConstantFreeRecruit) = logistic.(u.ocean)
p_spawn(u, n, t, stock, dyn::ConstantFreeRecruit) = logistic.(u.spawn)

function n_eggs(u, n, t, stock, dyn::ConstantFreeRecruit)
    return exp.(u.log_eggs[t-1])
end

##############################################################
# GLM transition probabilities, Ricker recruitment
##############################################################
struct GLMRicker <: SalmonDynamics end

describe(dyn::GLMRicker) = "GLM P, Ricker recruitment"

GLMRicker(stock, rng=Random.default_rng()) = GLMRicker()

function initial_u(prob::StockProblem, dynamics::GLMRicker)
    n0 = stock_state_array(prob.stock)
    nspawn = length(prob.stock.i_spawn)
    nxfresh = size(prob.stock.X_fresh, 1)
    nxocean = size(prob.stock.X_ocean, 1)
    u0 = ComponentArray(
        fresh = ones(nxfresh + 1),
        # fresh = ComponentArray(
        #     a = fill(0.9, agemax_fresh(prob.stock)),
        #     b = fill(1.0, nxfresh)
        # ),
        smolt = logit.(fill(0.9, nfresh(prob.stock))),
        # ocean = ones(nxocean+1),
        ocean = ComponentArray(
            b0 = fill(0.9, 1, agemax_ocean(prob.stock)-1),
            b1 = fill(1.0, nxocean),
            # b2 = fill(1.0, nxocean)
        ),
        spawn = logit.(fill(0.9, nspawn)), 
        # spawn = fill(1.0, nspawn, nxocean),
        eggs = randn(2),
        log_n0 = log.(n0 .+ 0.1))
    return u0
end

function p_fresh(u, n, t, stock, dyn::GLMRicker)
    x = stock.X_fresh[:, t]
    y = dot([1; x], u.fresh)
    # y = u.fresh.a .+ dot(x, u.fresh.b)
    return logistic.(y)
end

p_smolt(u, n, t, stock, dyn::GLMRicker) = logistic.(u.smolt)

function p_ocean(u, n, t, stock, dyn::GLMRicker)
    x = stock.X_ocean[:, t]
    # y = dot([1; x], u.ocean)
    y = u.ocean.b0 .+ dot(x, u.ocean.b1) #.+ dot(x.^2, u.ocean.b1)
    return logistic.(y)
end

function p_spawn(u, n, t, stock, dyn::GLMRicker)
    return logistic.(u.spawn)
    # x = stock.X_ocean[:, t]
    # y = u.spawn * x
    # return logistic.(y)
end

function n_eggs(u, n, t, stock, dyn::GLMRicker)
    r = exp(u.eggs[1])
    k = exp(u.eggs[2])
    # spawners = sum(n[:,:,2])
    spawners = sum(stock.returns[:, :, t])
    return spawners * exp(r * (1 - spawners / k))
end

##############################################################
# NN transition probabilities, Ricker recruitment
##############################################################
using Lux
using Random


struct NeuralNetRicker{T1,T2,T3,T4,T5,T6,T7,T8} <: SalmonDynamics
    nn_fresh::T1
    ps_fresh::T2
    nn_smolt::T3
    ps_smolt::T4
    nn_ocean::T5
    ps_ocean::T6
    nn_spawn::T7
    ps_spawn::T8
end

describe(dyn::NeuralNetRicker) = "Neural P, Ricker recruitment"

function construct_nn(rng, nx, ny)
    nn_initial = Chain(Dense(nx => ny, logistic))
    ps, st = Lux.setup(rng, nn_initial)
    nn = StatefulLuxLayer{true}(nn_initial, nothing, st)
    return nn, ps
end

function NeuralNetRicker(stock, rng=Random.default_rng())
    nn_fresh, ps_fresh = construct_nn(rng, size(stock.X_fresh, 1), 1)
    nn_smolt, ps_smolt = construct_nn(rng, size(stock.X_fresh, 1), nfresh(stock))
    nn_ocean, ps_ocean = construct_nn(rng, size(stock.X_ocean, 1) + length(stock.i_spawn), 
        agemax_ocean(stock)-1)
    nn_spawn, ps_spawn = construct_nn(rng, size(stock.X_ocean, 1), length(stock.i_spawn))
    return NeuralNetRicker(
        nn_fresh, ps_fresh,
        nn_smolt, ps_smolt,
        nn_ocean, ps_ocean,
        nn_spawn, ps_spawn
    )
end

function initial_u(prob::StockProblem, dynamics::NeuralNetRicker)
    n0 = stock_state_array(prob.stock)
    nspawn = length(prob.stock.i_spawn)
    u0 = ComponentArray(
        fresh = ComponentArray(dynamics.ps_fresh),
        # smolt = ComponentArray(dynamics.ps_smolt),
        smolt = logit.(fill(0.9, nfresh(prob.stock))),
        ocean = ComponentArray(dynamics.ps_ocean),
        # spawn = ComponentArray(dynamics.ps_spawn), 
        spawn = logit.(fill(0.9, nspawn)), 
        eggs = [1.0, 2.0],#randn(2),
        log_n0 = log.(n0 .+ 0.1)
    )
    return u0
end

function p_fresh(u, n, t, stock, dyn::NeuralNetRicker)
    x = stock.X_fresh[:, t]
    Lux.apply(dyn.nn_fresh, x, u.fresh)
end

function p_smolt(u, n, t, stock, dyn::NeuralNetRicker)
    # x = stock.X_fresh[:, t]
    # Lux.apply(dyn.nn_smolt, x, u.fresh)
    logistic.(u.smolt)
end

function p_ocean(u, n, t, stock, dyn::NeuralNetRicker)
    # x = stock.X_ocean[:, t]
    x_ocean = stock.X_ocean[:, t]
    x_returns = stock.returns[stock.i_spawn, t-1]
    x = [x_ocean; x_returns]
    Lux.apply(dyn.nn_ocean, x, u.ocean)
end

function p_spawn(u, n, t, stock, dyn::NeuralNetRicker)
    # x = stock.X_ocean[:, t]
    # Lux.apply(dyn.nn_spawn, x, u.spawn)
    logistic.(u.spawn)
end

function n_eggs(u, n, t, stock, dyn::NeuralNetRicker)
    r = exp(u.eggs[1])
    k = exp(u.eggs[2])
    # spawners = sum(n[:,:,2])
    spawners = sum(stock.returns[:, :, t])
    return spawners * exp(r * (1 - spawners / k))
end



##############################################################
# NN transition probabilities, Ricker recruitment
##############################################################
using Lux
using Random


struct NeuralNet2Ricker{T1,T2,T3,T4,T5,T6,T7,T8} <: SalmonDynamics
    nn_fresh::T1
    ps_fresh::T2
    nn_smolt::T3
    ps_smolt::T4
    nn_ocean::T5
    ps_ocean::T6
    nn_spawn::T7
    ps_spawn::T8
end

describe(dyn::NeuralNet2Ricker) = "Neural P, Ricker recruitment"

function construct_nn2(rng, nx, ny)
    nn_initial = Chain(Dense(nx => 8, relu), Dense(8 => ny, logistic))
    ps, st = Lux.setup(rng, nn_initial)
    nn = StatefulLuxLayer{true}(nn_initial, nothing, st)
    return nn, ps
end

function NeuralNet2Ricker(stock, rng=Random.default_rng())
    nn_fresh, ps_fresh = construct_nn2(rng, size(stock.X_fresh, 1), 1)
    nn_smolt, ps_smolt = construct_nn2(rng, size(stock.X_fresh, 1), nfresh(stock))
    nn_ocean, ps_ocean = construct_nn2(rng, size(stock.X_ocean, 1) + length(stock.i_spawn), 
        agemax_ocean(stock)-1)
    nn_spawn, ps_spawn = construct_nn2(rng, size(stock.X_ocean, 1), length(stock.i_spawn))
    return NeuralNet2Ricker(
        nn_fresh, ps_fresh,
        nn_smolt, ps_smolt,
        nn_ocean, ps_ocean,
        nn_spawn, ps_spawn
    )
end

function initial_u(prob::StockProblem, dynamics::NeuralNet2Ricker)
    n0 = stock_state_array(prob.stock)
    nspawn = length(prob.stock.i_spawn)
    u0 = ComponentArray(
        fresh = ComponentArray(dynamics.ps_fresh),
        smolt = logit.(fill(0.9, nfresh(prob.stock))),
        ocean = ComponentArray(dynamics.ps_ocean),
        spawn = logit.(fill(0.9, nspawn)), 
        eggs = [1.0, 2.0],
        log_n0 = log.(n0 .+ 0.1)
    )
    return u0
end

function p_fresh(u, n, t, stock, dyn::NeuralNet2Ricker)
    x = stock.X_fresh[:, t]
    Lux.apply(dyn.nn_fresh, x, u.fresh)
end

function p_smolt(u, n, t, stock, dyn::NeuralNet2Ricker)
    logistic.(u.smolt)
end

function p_ocean(u, n, t, stock, dyn::NeuralNet2Ricker)
    x_ocean = stock.X_ocean[:, t]
    x_returns = stock.returns[stock.i_spawn, t-1]
    x = [x_ocean; x_returns]
    Lux.apply(dyn.nn_ocean, x, u.ocean)
end

function p_spawn(u, n, t, stock, dyn::NeuralNet2Ricker)
    logistic.(u.spawn)
end

function n_eggs(u, n, t, stock, dyn::NeuralNet2Ricker)
    r = exp(u.eggs[1])
    k = exp(u.eggs[2])
    # spawners = sum(n[:,:,2])
    spawners = sum(stock.returns[:, :, t])
    return spawners * exp(r * (1 - spawners / k))
end

