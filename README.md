# MultiQuantityGPs

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://ngharrison.github.io/MultiQuantityGPs.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://ngharrison.github.io/MultiQuantityGPs.jl/dev/)
[![Build Status](https://github.com/ngharrison/MultiQuantityGPs.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/ngharrison/MultiQuantityGPs.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Aqua](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

This package contains code for a Multi-Quantity Gaussian Process (MQGP). As with any GP, it can be used to interpolate between data points, creating a mapping in one or more dimensions. However, it also uses a multi-quantity covariance function and mean function to represent the relationship between quantities as linear models. In effect, it can learn linear models between quantities even when their known data points are not spatially collocated. For more information and usage examples, please see the docs.

This package was extracted from and is used by [InformativeSampling](https://github.com/ngharrison/InformativeSampling).
