SimpleArgParse: ArgumentParser, add_argument, add_example, generate_usage, help, parse_args, get, set, haskey, getkey, colorize

function main()
    :Int

    args::ArgumentParser = ArgumentParser(description="SimpleArgParse example.", add_help=true)
    args = add_argument(args, "-i", "--input", type=String, required=true, default="filename.txt", description="Input file.")
    args = add_argument(args, "-n", "--number", type=UInt8, default=0, description="Integer number.")
    args = add_argument(args, "-v", "--verbose", type=Bool, default=false, description="Verbose mode switch.")
    args = add_example(args, "julia main.jl --input dir/file.txt --number 10 --verbose")
    args = add_example(args, "julia main.jl --help")
    args = parse_args(args)
    
    # check boolean flags passed via command-line
    get(args, "verbose") && println("Verbose mode enabled")
    get(args, "v")       && println("Verbose mode enabled")
    get(args, "--help")  && help(args, color="yellow")

    # check values
    haskey(args, "input")  && println("Input file: ", get(args, "input"))
    haskey(args, "number") && println("The number: ", get(args, "number"))

    # we can override the usage statement with our own
    args.usage::String = "\nUsage: main.jl [--input <PATH>] [--verbose] [--problem] [--help]"
    help(args, color="cyan")
    
    # use `set` to override command-line argument values
    haskey(args, "help") && set(args, "help", true)
    haskey(args, "help") && help(args, color="green")

    # check if SHA-256 byte key exists and print it if it does
    haskey(args, "help") && println("\nHash key: $(getkey(args, "help"))\n")

    # DO SOMETHING AMAZING

    return 0
end

main()
