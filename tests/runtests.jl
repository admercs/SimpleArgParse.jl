include("../src/SimpleArgParse.jl")
using .SimpleArgParse: ArgumentParser, add_argument, add_example, generate_usage, help, parse_args, get, set, haskey, getkey
using Test

@testset "SimpleArgParse tests" begin

    @testset "Testset empty constructor" begin
        s = SimpleArgParse()
        @test isempty(s.description)
        @test isempty(s.author)
        @test isempty(s.documentation)
        @test isempty(s.repository)
        @test isempty(s.license)
        @test isempty(s.usage)
        @test !s.add_help
    end

    @testset "Testset parameterized constructor" begin
        s = SimpleArgParse(
            description="test", author="first last", documentation="server/docs",
            repository="server/repo", license="license",
            usage="julia main.jl --arg val", add_help=true
        )
        @test "test" == s.description
        @test "first last" == s.author
        @test "server/docs" == s.documentation
        @test "server/repo" == s.repository
        @test "license" == s.license
        @test "julia main.jl --arg val" == s.usage
        @test s.add_help
    end

    @testset "Testset add_argument" begin
        s = SimpleArgParse()
        s = add_argument(s, "-f", "--foo", type=String, default="bar", description="baz")
        @test "bar" == SimpleArgParse.get(s, "--foo")
        @test "bar" == SimpleArgParse.get(s, "-f")
        @test "bar" == SimpleArgParse.get(s, "f")
        @test_throws MethodError add_argument(s)
    end

    @testset "Testset get" begin
        s = SimpleArgParse()
        s = add_argument(s, "-f", "--foo", type=String, default="bar", description="baz")
        @test isnothing(SimpleArgParse.get(s, "--missing"))
        @test "bar" == SimpleArgParse.get(s, "--foo")
        @test "bar" == SimpleArgParse.get(s, "-f")
        @test "bar" == SimpleArgParse.get(s, "f")
            @test isa(SimpleArgParse.get(s, "--foo"), String)
        @test_throws MethodError SimpleArgParse.get(s, 3)
    end
    
    @testset "Testset set" begin
        s = SimpleArgParse()
        s = add_argument(s, "-f", "--foo", type=String, default="bar")
        @test "bar" == SimpleArgParse.get(s, "--foo")
        s = SimpleArgParse.set(s, "--foo", "baz")
        @test "baz" == SimpleArgParse.get(s, "--foo")
    end

end
