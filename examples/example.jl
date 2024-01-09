SimpleArgParse: ArgumentParser, add_argument, add_example, generate_usage, help, parse_args, get_value, set_value, has_key, get_key, colorize

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
    get_value(args, "verbose") && println("Verbose mode enabled")
    get_value(args, "v")       && println("Verbose mode enabled")
    get_value(args, "--help")  && help(args, color="yellow")

    # check values
    has_key(args, "input")  && println("Input file: ", get_value(args, "input"))
    has_key(args, "number") && println("The number: ", get_value(args, "number"))

    # we can override the usage statement with our own
    args.usage::String = "\nUsage: main.jl [--input <PATH>] [--verbose] [--problem] [--help]"
    help(args, color="cyan")
    
    # use `set` to override command-line argument values
    has_key(args, "help") && set(args, "help", true)
    has_key(args, "help") && help(args, color="green")

    # check if SHA-256 byte key exists and print it if it does
    has_key(args, "help") && println("\nHash key: $(get_key(args, "help"))\n")

    # DO SOMETHING AMAZING

    return 0
end

main()
