using SimpleArgParse: ArgumentParser, add_argument, add_example, generate_usage, help, parse_args, get_value, set_value, has_key, get_key
using Test

@testset "SimpleArgParse tests" begin

    @testset "Testset empty constructor" begin
        p = ArgumentParser()
        @test isempty(p.description)
        @test isempty(p.author)
        @test isempty(p.documentation)
        @test isempty(p.repository)
        @test isempty(p.license)
        @test isempty(p.usage)
        @test !p.add_help
    end

    @testset "Testset parameterized constructor" begin
        p = ArgumentParser(
            description="test",
            authors=["first last <first.last@foo.bar>"],
            documentation="server/docs",
            repository="server/repo",
            license="license",
            usage="julia main.jl --arg val",
            add_help=true
        )
        @test "test" == p.description
        @test "first last" == p.author
        @test "server/docs" == p.documentation
        @test "server/repo" == p.repository
        @test "license" == p.license
        @test "julia main.jl --arg val" == p.usage
        @test p.add_help
    end

    @testset "Testset add_argument" begin
        p = ArgumentParser()
        p = add_argument(p, "-f", "--foo", type=String, default="bar", description="baz")
        @test "bar" == get_value(p, "--foo")
        @test "bar" == get_value(p, "-f")
        @test "bar" == get_value(p, "f")
        @test_throws MethodError add_argument(p)
    end

    @testset "Testset get" begin
        p = ArgumentParser()
        p = add_argument(p, "-f", "--foo", type=String, default="bar", description="baz")
        @test isnothing(get_value(p, "--missing"))
        @test "bar" == get_value(p, "--foo")
        @test "bar" == get_value(p, "-f")
        @test "bar" == get_value(p, "f")
            @test isa(get_value(p, "--foo"), String)
        @test_throws MethodError SimpleArgParse.get_value(p, 3)
    end
    
    @testset "Testset set" begin
        p = ArgumentParser()
        p = add_argument(p, "-f", "--foo", type=String, default="bar")
        @test "bar" == get_value(p, "--foo")
        p = SimpleArgParse.set(p, "--foo", "baz")
        @test "baz" == get_value(p, "--foo")
    end

end
