module Kernels

using LinearAlgebra: eigmin
using Statistics: I, mean, var
using AbstractGPs: with_lengthscale, SqExponentialKernel, IntrinsicCoregionMOKernel, CustomMean
using ParameterHandling: fixed
using DocStringExtensions: TYPEDSIGNATURES

export singleKernel, multiKernel, slfmKernel, mtoKernel,
       fullyConnectedCovNum, fullyConnectedCovMat, manyToOneCovNum,
       manyToOneCovMat, initHyperparams, customKernel, multiMean

include("SLFMKernel.jl")
include("CustomKernel.jl")

## Mean and kernel stuff

"""
$(TYPEDSIGNATURES)

Creates a quantity-specific constant mean function from the GP hyperparameters.
"""
multiMean(θ) = CustomMean(x->θ.μ[x[2]])

"""
$(TYPEDSIGNATURES)

A simple squared exponential kernel for the GP with parameters `θ`.

This function creates the kernel function used within the GP.
"""
singleKernel(θ) = θ.σ^2 * with_lengthscale(SqExponentialKernel(), θ.ℓ^2)

"""
$(TYPEDSIGNATURES)

A multi-task GP kernel, a variety of multi-output GP kernel based on the
Intrinsic Coregionalization Model with a Squared Exponential base kernel and an
output matrix formed from a lower triangular matrix.

This function creates the kernel function used within the GP.
"""
multiKernel(θ) = IntrinsicCoregionMOKernel(kernel=with_lengthscale(SqExponentialKernel(), θ.ℓ^2),
                                           B=fullyConnectedCovMat(θ.σ))

"""
$(TYPEDSIGNATURES)

Creates a kernel function for the GP, which is similar to a [`multiKernel`](@ref) but instead uses a many-to-one quantity covariance matrix.
"""
mtoKernel(θ) = IntrinsicCoregionMOKernel(kernel=with_lengthscale(SqExponentialKernel(), θ.ℓ^2),
                                           B=manyToOneCovMat(θ.σ))

"""
$(TYPEDSIGNATURES)

Creates a semi-parametric latent factor model (SLFM) kernel function for the GP.
"""
slfmKernel(θ) = SLFMMOKernel(with_lengthscale.(SqExponentialKernel(), θ.ℓ.^2), θ.σ)

"""
$(TYPEDSIGNATURES)

Creates a custom kernel function for the GP similar to the [`slfmKernel`](@ref) but with matrices of length-scales and amplitudes.

This one does not work and is likely not theoretically valid.
"""
customKernel(θ) = CustomMOKernel(with_lengthscale.(SqExponentialKernel(), fullyConnectedCovMat(θ.ℓ)),
                                 fullyConnectedCovMat(θ.σ))

"""
$(TYPEDSIGNATURES)

Creates an output covariance matrix from an array of parameters by filling a lower
triangular matrix.

Inputs:
- `a`: parameter vector, must hold (N+1)*N/2 parameters, where N = number of
  outputs
"""
function fullyConnectedCovMat(a)

    N = floor(Int, sqrt(length(a)*2)) # (N+1)*N/2 in matrix

    # cholesky factorization technique to create a free-form covariance matrix
    # that is positive semidefinite
    L = [(v<=u ? a[u*(u-1)÷2 + v] : 0.0) for u in 1:N, v in 1:N]
    A = L*L' + √eps()*I # lower triangular times upper

    # fix for numerical inaccuracy making it non positive semidefinite
    if eigmin(A) < 0
        max_diag = maximum(A[i,i] for i in axes(A,1))
        for i in axes(A,1)
            A[i,i] += 1e-6 * max_diag
        end
    end

    return A
end

"""
$(TYPEDSIGNATURES)

Gives the number of hyperparameters for to fill the [`fullyConnectedCovMat`](@ref).
"""
fullyConnectedCovNum(num_outputs) = (num_outputs+1)*num_outputs÷2

"""
$(TYPEDSIGNATURES)

Creates an output covariance matrix from an array of parameters by filling the
first column and diagonal of a lower triangular matrix.

Inputs:
- `a`: parameter vector, must hold 2N-1 parameters, where N = number of
  outputs
"""
function manyToOneCovMat(a)

    # cholesky factorization technique to create a free-form covariance matrix
    # that is positive semidefinite
    N = (length(a)+1)÷2 # N on column + N-1 more on diagonal = 2N-1
    L = zeros(N,N) # will be lower triangular
    L[1,1] = a[1]
    for t=2:N
        L[t,1] = a[1 + t-1]
        L[t,t] = a[1 + 2*(t-1)]
    end
    A = L'*L + √eps()*I # upper triangular times lower

    # fix for numerical inaccuracy making it non positive semidefinite
    if eigmin(A) < 0
        max_diag = maximum(A[i,i] for i in axes(A,1))
        for i in axes(A,1)
            A[i,i] += 1e-6 * max_diag
        end
    end

    return A
end

"""
$(TYPEDSIGNATURES)

Gives the number of hyperparameters for to fill the [`manyToOneCovMat`](@ref).
"""
manyToOneCovNum(num_outputs) = 2*num_outputs - 1

"""
$(TYPEDSIGNATURES)

Creates the structure of hyperparameters for a MTGP and gives them initial values.
"""
function initHyperparams(X, Y_vals, bounds, N, ::typeof(multiKernel); kwargs...)
    # fill so that matrix variances match measured values
    σ = mapreduce(vcat, 1:N) do i
        arr = [y for ((l, q), y) in zip(X, Y_vals) if q==i]
        val = if length(arr) == 0
            fixed(0.5/sqrt(2))
        elseif length(arr) == 1
            0.5/sqrt(2)
        else
            sqrt(var(arr)/i)
        end
        fill(val, i)
    end
    ℓ = mean(bounds.upper .- bounds.lower)
    return (; σ, ℓ, kwargs...)
end

"""
$(TYPEDSIGNATURES)

Creates the structure of hyperparameters for a MTGP and gives them initial values.
This is for a specialized quantity covariance matrix with separation.
"""
function initHyperparams(X, Y_vals, bounds, N, ::typeof(mtoKernel); kwargs...)
    n = manyToOneCovNum(N)
    # fill so that matrix variances match measured values
    σ = zeros(n)
    arr = [y for ((l, q), y) in zip(X, Y_vals) if q==1]
    σ[2:2:2N-1] .= σ[1] = (length(arr) > 1 ? sqrt(var(arr)/N) : 0.5/sqrt(2))
    for i in 2:N
        arr = [y for ((l, q), y) in zip(X, Y_vals) if q==i]
        σ[2i-1] = (length(arr) > 1 ? sqrt(var(arr)) : 0.5/sqrt(2))
    end
    ℓ = mean(bounds.upper .- bounds.lower)
    return (; σ, ℓ, kwargs...)
end

"""
$(TYPEDSIGNATURES)

Creates the structure of hyperparameters for a SLFM and gives them initial values.
"""
function initHyperparams(X, Y_vals, bounds, N, ::typeof(slfmKernel); kwargs...)
    σ = 0.5/sqrt(2) * ones(N,N)
    ℓ = mean(bounds.upper .- bounds.lower) * ones(N)
    return (; σ, ℓ, kwargs...)
end

function initHyperparams(X, Y_vals, bounds, N, ::typeof(customKernel); kwargs...)
    n = fullyConnectedCovNum(N)
    σ = 0.5/sqrt(2) * ones(n)
    ℓ = mean(bounds.upper .- bounds.lower) * ones(n)
    return (; σ, ℓ, kwargs...)
end

end
