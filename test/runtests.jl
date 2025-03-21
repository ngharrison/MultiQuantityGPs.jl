using MultiQuantityGPs
using Test
using Aqua
using JET
using Statistics

@testset "MultiQuantityGPs.jl" begin
    @testset "Code quality (Aqua.jl)" begin
        Aqua.test_all(MultiQuantityGPs)
    end

    @testset "Code linting (JET.jl)" begin
        JET.test_package(MultiQuantityGPs; target_defined_modules = true)
    end

    @testset "Simple functionality test" begin
        samples = [
            (x=([0.1, 0.8], 1), y=1.4),
            (x=([0.5, 0.4], 1), y=0.2),
            (x=([0.2, 0.2], 2), y=0.8),
            (x=([0.9, 0.1], 2), y=0.1),
        ]

        stds = std([s.x[1] for s in samples])
        bounds = (lower=zero(stds), upper=stds)

        mqgp = MQGP(samples; bounds, noise_value=0.0, noise_learn=true)

        @test all(mqgp(([.25, .3], 1)) .≈ (0.8100073121265535, 0.5990697034625645))
        @test all(mqgp(([.25, .3], 2)) .≈ (0.45840900620997277, 0.3484339143061906))
    end
end
