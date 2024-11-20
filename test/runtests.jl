using MultiQuantityGPs
using Test
using Aqua
using JET

@testset "MultiQuantityGPs.jl" begin
    @testset "Code quality (Aqua.jl)" begin
        Aqua.test_all(MultiQuantityGPs)
    end
    @testset "Code linting (JET.jl)" begin
        JET.test_package(MultiQuantityGPs; target_defined_modules = true)
    end
    # Write your tests here.
end
