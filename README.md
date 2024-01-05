# SimpleArgParse.jl

A hackable, single-file, 160-line, zero-dependency Julia package for command-line argument parsing.

Does this need to be complicated?

## Motivation

Parsing command-line arguments should not be complicated. Metaprogramming features such as macros and generators, while cool, are overkill. I wanted a simple command-line argument parsing library in the spirit of Python's [`argparse`](https://docs.python.org/3/library/argparse.html), but could not find one. The closest thing I found was [`ArgParse`](https://www.juliapackages.com/p/argparse), but I wanted something simpler. There's nothing worse than having to security audit a massive package for a simple task.

Here it is, a simple 160-line file with zero dependencies, a single data structure, and a few methods. Hack on it, build on it, and use it for your own projects. You can read all of the source code in under one minute.

Enjoy! :sunglasses:

## Usage

First, create a simple helper function just for fun in our example. In future versions, we may automagically generate the `help()` or `usage()` method from our key-value store of command-line arguments. That does not need to be complicated either.

```julia
using SimpleArgParse: colorize

# help message.
function help()
    :Nothing

    message::String = raw"
    ./main.jl [--input] [--verbose] [--problem] [--help]

    A Julia script with command-line arguments.

    Options:
      -i, --input <PATH>    Path to the input file.
      -v, --verbose         Enable verbose message output.
      -p, --problem         Print the problem statement.
      -h, --help            Print this help message.

    Examples:
      $ julia main.jl --input dir/file.txt --verbose
      $ julia main.jl --help
    "
    println(colorize(message, "cyan"))
    return
end
```

We are ready to add and parse our command-line arguments!

```julia
using SimpleArgParse: ArgumentParser, add_argument, parse_args, exists, get, set

function main()
    :Int

    args::ArgumentParser = ArgumentParser(description="Demo")
    args = add_argument(args, "-i", "--input",   type=String, default="./filename.txt")
    args = add_argument(args, "-v", "--verbose", type=Bool,   default=false)
    args = add_argument(args, "-h", "--help",    type=Bool,   default=false)
    args = parse_args(args)

    # check booleans
    get(args, "verbose") && println("Verbose mode enabled")
    get(args, 'v')       && println("Verbose mode enabled")
    get(args, "help")    && help()

    # get an argument value; fail gracefully
    input::String = exists(args, "input") ? get(args, "input") : nothing

    # for better or worse, you can also directly access the argument key-value store
    # pro tip 1: the key is always the first non-hyphen character of the argument string
    # pro tip 2: the value is always in the first tuple index
    verbose::Bool = args.kv_store['v'][1]

    # DO SOMETHING HERE

    return 0
end

main()
```

That is about as simple as it gets and closely follows Python's [`argparse`](https://docs.python.org/3/library/argparse.html). You will notice that we instead make extensive use of the visitor pattern, rather than member methods, to modify the state of the `ArgumentParser` object instance. That is because the Julia language (rather shockingly) does not support member methods. In other words, Julia does not fully support the object-oriented paradigm, but is more functional and data-oriented in design. In some ways, that is a good thing.

Note that our `get` and `set` methods override methods of the same name in `Base`. Hence, they must be imported or referenced by their namespace, the package name.

## License

MIT
