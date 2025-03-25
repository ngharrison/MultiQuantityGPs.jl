```@meta
CurrentModule = MultiQuantityGPs
ShareDefaultModule = true
```

# MultiQuantityGPs

## Quick Intro

Following is a quick example of the main functionality of this package.

First, the package is loaded and 2D region bounds are chosen.

```@example
using MultiQuantityGPs: MQGP, quantityCovMat, quantityCorMat, MQSample

bounds = (
    lower = [0.0, 0.0],
    upper = [1.0, 1.0]
)
```

A collection of locations and quantity indices for 2 quantities is randomly generated. The 2D function to model uses a sine with an offset.

```@example
using Random: seed! # hide
seed!(0) # hide

# latin hypercube create first quantity sample positions
n = 4
pos1 = [[i,j] .+ rand(2)/n for i in 0:1/n:1-1/n for j in 0:1/n:1-1/n]

# randomly create first quantity values
f = (x1,x2) -> sin(7*x1) + 2*x2
f1 = (x1,x2) -> f(x1,x2) + 1/2*randn()
qnt1_samples = [MQSample((x=(p,1), y=f1(p...))) for p in pos1]

# latin hypercube create second quantity sample positions
n = 5
pos2 = [[i,j] .+ rand(2)/n for i in 0:1/n:1-1/n for j in 0:1/n:1-1/n]

# randomly create second quantity sample values
f2 = (x1,x2) -> -10*f(x1,x2) + 3*randn()
qnt2_samples = [MQSample((x=(p,2), y=f2(p...))) for p in pos2]

# full sample collection
samples = [qnt1_samples; qnt2_samples]
```

The MQGP is created from the samples and bounds. It's hyperparameter values are learned.

```@example
mqgp = MQGP(samples; bounds,
            noise_value=zeros(2), noise_learn=true,
            means_use=true, means_learn=true)
```

Values from the MQGP can be viewed, such as the noise hyperparameters:

```@example
mqgp.θ.σn
```

Predicted value and uncertainty for a single sample:

```@example
mqgp(([0.39, 0.28], 2))
```

Predicted value and uncertainty for multiple samples:

```@example
mqgp([([0.4, 0.5], 1), ([0.39, 0.28], 2)])
```

The quantity covariance matrix:

```@example
quantityCovMat(mqgp)
```

Or the quantity correlation matrix:

```@example
quantityCorMat(mqgp)
```

The following plots show the two quantities, the samples of those quantities, and the predicted values and uncertainties produced by the MQGP across the region.

```@example
ENV["GKSwstype"] = "100" # hide
using Plots

axs = range.(bounds..., (100, 100))
points = collect.(Iterators.product(axs...))

plots = map(1:2) do quantity
    pred_map, err_map = mqgp(tuple.(points, quantity))

    xp = first.(getfield.(filter(s -> s.x[2] == quantity, samples), :x))
    x1 = getindex.(xp, 1)
    x2 = getindex.(xp, 2)

    true_map = (f1,f2)[quantity].(axs[1],axs[2]')
    map_datas = true_map, pred_map, err_map
    titles = "ground truth", "expected value", "standard deviation"

    map(map_datas, titles) do map_data, title
        heatmap(axs..., map_data')
        scatter!(x1, x2;
            title="$title $quantity",
            legend=nothing,
            color=:green,
            markersize=4)
    end
end

plot(
    stack(plots; dims=1)...,
    layout=grid(3,2),
    size=(950,1000)
)
savefig("predictions_and_uncertainties.png"); nothing # hide
```

![](predictions_and_uncertainties.png)

## Further Info

See below for further details on each type and method.

```@index
```

```@autodocs
Modules = [MultiQuantityGPs]
```

```@autodocs
Modules = [Kernels]
```
