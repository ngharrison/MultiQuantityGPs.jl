using MultiQuantityGPs
using MultiQuantityGPs: SQSample, MQSample, getLoc
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
            MQSample((x=([0.1, 0.8], 1), y=1.4)),
            MQSample((x=([0.5, 0.4], 1), y=0.2)),
            MQSample((x=([0.2, 0.2], 2), y=0.8)),
            MQSample((x=([0.9, 0.1], 2), y=0.1)),
        ]

        stds = std([getLoc(s) for s in samples])
        bounds = (lower=zero(stds), upper=stds)

        mqgp = MQGP(samples; bounds, noise_value=0.0, noise_learn=true)

        @test all(mqgp(([.25, .3], 1)) .≈ (0.8100073121265535, 0.5990697034625645))
        @test all(mqgp(([.25, .3], 2)) .≈ (0.45840900620997277, 0.3484339143061906))
    end

    @testset "Hierarchical sample data structure" begin
        sample_collection = [
            [
                SQSample(([0.1, 0.8], 1.4)),
                SQSample(([0.5, 0.4], 0.2)),
            ],
            [
                SQSample(([0.2, 0.2], 0.8)),
                SQSample(([0.9, 0.1], 0.1)),
            ],
        ]

        stds = std([getLoc(s) for q in sample_collection for s in q])
        bounds = (lower=zero(stds), upper=stds)

        mqgp = MQGP(sample_collection; bounds, noise_value=0.0, noise_learn=true)

        @test all(mqgp(([.25, .3], 1)) .≈ (0.8100073121265535, 0.5990697034625645))
        @test all(mqgp(([.25, .3], 2)) .≈ (0.45840900620997277, 0.3484339143061906))
    end

end
