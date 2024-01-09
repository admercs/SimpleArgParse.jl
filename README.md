# SimpleArgParse.jl

[![DOCS][docs-img]][docs-url] [![CI][CI-img]][CI-url] [![CODECOV][codecov-img]][codecov-url]

A hackable, single-file, 320-line, single-dependency Julia package for command-line argument parsing. `SimpleArgParse` offers 95% of the functionality of  `ArgParse` using ~10% of the lines-of-code (LOC).

Does this need to be more complicated?

## Motivation

Parsing command-line arguments should not be complicated. Metaprogramming features such as macros and generators, while cool, are overkill. I wanted a simple command-line argument parsing library in the spirit of Python's [`argparse`](https://docs.python.org/3/library/argparse.html), but could not find one. The closest thing I found was [`ArgParse`](https://www.juliapackages.com/p/argparse), but I desired something even simpler. There's nothing worse than having to security audit a massive package for a simple task.

Here it is, a single, simple, 320-line file with one battle-hardened dependency (`OrderedCollections::OrderedDict`), a single nested data structure, and a few methods. Hack on it, build on it, and use it for your own projects. You can read all of the source code in around one minute.

Enjoy! :sunglasses:

## Installation

From the Julia REPL:

```julia
$ julia
julia> using Pkg
julia> Pkg.add("SimpleArgParse")
```

Or, using the Pkg REPL, activated with the `]` key from the Julia REPL:

```shell
$ julia
julia> ]
(v1.9) pkg> add SimpleArgParse
```

## Specification

We approximate the [Microsoft command-line syntax](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/command-line-syntax-key). Optional arguments are surrounded by square brackets, values are surrounded by angle brackets (chevrons), and mutually exclusive items are separated by a vertical bar. Simple!

## Usage

First, create a typical usage string just for our example. We will also automagically generate a `usage` string from our key-value store of command-line arguments. That is not complicated either.

```julia
# help message.
usage::String = raw"""
  Usage: main.jl --input <PATH> [--verbose] [--problem] [--help]

  A Julia script with command-line arguments.

  Options:
    -i, --input <PATH>    Path to the input file.
    -v, --verbose         Enable verbose message output.
    -p, --problem         Print the problem statement.
    -h, --help            Print this help message.

  Examples:
    $ julia main.jl --input dir/file.txt --verbose
    $ julia main.jl --help
  """
```

We are ready to add and parse our command-line arguments!

```julia
using SimpleArgParse: ArgumentParser, add_argument, add_example, generate_usage, help, parse_args, get_value, set_value, has_key, get_key, colorize

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
    args.usage::String = usage
    help(args, color="cyan")
    
    # use `set` to override command-line argument values
    has_key(args, "help") && set_value(args, "help", true)
    has_key(args, "help") && help(args, color="green")

    # check if SHA-256 byte key exists and print it if it does
    has_key(args, "help") && println("\nHash key: $(get_key(args, "help"))\n")

    # DO SOMETHING AMAZING

    return 0
end

main()
```

That is about as simple as it gets and closely follows Python's [`argparse`](https://docs.python.org/3/library/argparse.html). You will notice that we instead make extensive use of the visitor pattern, rather than member methods, to modify the state of the `ArgumentParser` object instance. That is because the Julia language (rather shockingly) does not support member methods. In other words, Julia does not fully support the object-oriented paradigm, but is more functional and data-oriented in design. In some ways, that is a good thing.

## Changelog

### Release 1.0.0

- Changed hashmap key from 8-bit to 16-bit to reduce collision likelihood.
- Added a usage/help message generator method.
- Added the `add_example`, `generate_usage`, `help`, `haskey`, and `getkey` methods.
- Added a single dependency, `OrderedCollections::OrderedDict`, to ensure correctness of argument parsing order.
- Squashed bugs in argument type parsing and conversion.
- Added test cases.
- Added examples.

### Release 0.1.0

- Initial launch :rocket:

## License

MIT License

[Julia]: http://julialang.org

[docs-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-url]: https://github.com/admercs/SimpleArgParse.jl

[codecov-img]: https://codecov.io/gh/admercs/SimpleArgParse.jl/branch/master/graph/badge.svg
[codecov-url]: https://codecov.io/gh/admercs/SimpleArgParse.jl

[CI-img]: https://github.com/admercs/SimpleArgParse.jl/actions/workflows/github-actions.yml/badge.svg
[CI-url]: https://github.com/admercs/SimpleArgParse.jl/actions/workflows/github-actions.yml
