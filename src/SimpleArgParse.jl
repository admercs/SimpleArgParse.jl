module SimpleArgParse

export ArgumentParser, add_argument!, add_example!, generate_usage, help, parse_args!, 
    get_value, set_value!, has_key, get_key, colorize, 
    colorprint, nt_args, PromptedParser, 
    keys

# using Base
# using SHA: sha256
using OrderedCollections: OrderedDict

###
### Data Structures
###

"Command-line argments."
struct Arguments
    short::String
    long::String
end

"Command-line argment values."
struct ArgumentValues
    args::Arguments
    value::Any
    type::Type
    required::Bool
    description::String
end

"Command-line argument parser with key-value stores and attributes."
mutable struct ArgumentParser
    # stores
    "key-value store: { key: ArgumentValues(value, type, required, help) }; up to 65,536 argument keys"
    kv_store::OrderedDict{UInt16,ArgumentValues}
    "key-value store: { arg: key }"
    arg_store::OrderedDict{String,UInt16}
    "number of stored args"
    lng::UInt16
    # attributes
    "file name"
    filename::String
    "description"
    description::String
    "name of author(s): First Last <first.last@email.address>"
    authors::Vector{String}
    "URL of documentations"
    documentation::String
    "URL of software repository"
    repository::String
    "name of license"
    license::String
    "usage/help message"
    usage::String
    "usage examples"
    examples::Vector{String}
    "flag to automatically generate a help message"
    add_help::Bool
    # "empty constructor"
    # ArgumentParser() = new(OrderedDict(), OrderedDict(), 0, "", "", "", "", "", "", "", "", false)
    "keyword argument constructor"
    function ArgumentParser(;
        filename="", description::String="", lng=0, authors::Vector{String}=String[],
        documentation::String="", repository::String="", license::String="",
        usage::String="", examples::Vector{String}=String[], add_help::Bool=false)
        :ArgumentParser
        new(OrderedDict(), OrderedDict(), lng, filename, description, authors, documentation,
            repository, license, usage, examples, add_help)
    end
end

###
### Functions
###

"Extract struct members to vector."
function args2vec(args::Arguments)
    :Vector
    if isempty(args.short)
        if isempty(args.long)
            return String[]
        end
        return String[args.long]
    elseif isempty(args.long)
        return String[args.short]
    else
        return String[args.short, args.long]
    end
end

"Argument to argument-store key conversion by removing hypenation from prefix."
function arg2key(arg::AbstractString)
    :String
    return lstrip(arg, '-')
end

"Add command-line argument to ArgumentParser object instance."
function add_argument!(parser::ArgumentParser, arg_short::String="", arg_long::String="";
    type::Type=Any, required::Bool=false, default::Any=nothing, description::String="")
    """
    # Arguments
    _Mandatory_
    - `parser::ArgumentParser`: ArgumentParser object instance.
    _Optional_
    - `arg_short::String=nothing`: short argument flag.
    - `arg_long::String=nothing`: long argument flag.
    _Keyword_
    - `type::Type=nothing`: argument type.
    - `default::Any=nothing`: default argument value.
    - `required::Bool=false`: whether argument is required.
    - `description::String=nothing`: argument description.
    """
    :ArgumentParser
    args::Arguments = Arguments(arg_short, arg_long)
    # prefer stripped long argument for higher entropy
    arg::String = !isempty(arg_long) ? arg_long : !isempty(arg_short) ? arg_short : ""
    isempty(arg) && error("Argument(s) missing. See usage examples.")
    parser.lng += 1
    key::UInt16 = parser.lng
    # map both argument names to the same key
    !isempty(arg_short) && (parser.arg_store[arg2key(arg_short)] = key)
    !isempty(arg_long)  && (parser.arg_store[arg2key(arg_long)]  = key)
    default = type == Any ? default : convert(type, default)
    values::ArgumentValues = ArgumentValues(args, default, type, required, description)
    parser.kv_store[key] = values
    return parser
end

"Add command-line usage example."
function add_example!(parser::ArgumentParser, example::AbstractString)
    :ArgumentParser
    push!(parser.examples, example)
    return parser
end

"Usage/help message generator."
function generate_usage(parser::ArgumentParser)
    :String
    """example:
    Usage: main.jl --input <PATH> [--verbose] [--problem] [--help]
    
    A Julia script with command-line arguments.
    
    Options:
      -i, --input <PATH>    Path to the input file.
      -v, --verbose         Enable verbose message output.
      -p, --problem         Print the problem statement.
      -h, --help            Print this help message.
    
    Examples:
      \$ julia main.jl --input dir/file.txt --verbose
      \$ julia main.jl --help
    """
    usage::String = "Usage: $(parser.filename)"
    options::String = "Options:"
    for v::ArgumentValues in values(parser.kv_store)
        args_vec::Vector{String} = args2vec(v.args)
        # example: String -> "<STRING>"
        type::String = v.type != Bool ? string(" ", join("<>", uppercase(string(v.type)))) : ""
        # example: (i,input) -> "[-i|--input <STRING>]"
        args_usage::String = string(join(hyphenate.(args_vec), "|"), type)
        !v.required && (args_usage = join("[]", args_usage))
        usage *= string(" ", args_usage)
        # example: (i,input) -> "-i, --input <STRING>"
        tabs::String = v.type != Bool ? "\t" : "\t\t"
        args_options::String = string("\n  ", join(hyphenate.(args_vec), ", "), type, tabs, v.description)
        options *= args_options
    end
    examples::String = string("Examples:", join(string.("\n  \$ ", parser.examples)))
    generated::String = """

    $(usage)

    $(parser.description)

    $(options)

    $(examples)
    """
    return generated
end

"Helper function to print usage/help message."
function help(parser::ArgumentParser; color::AbstractString="default")
    :Nothing
    println(colorize(parser.usage, color=color))
    return nothing
end

"Parse command-line arguments."
function parse_args!(parser::ArgumentParser; cli_args=ARGS)
    :ArgumentParser
    if parser.add_help
        parser = add_argument!(parser, "-h", "--help", type=Bool, default=false, description="Print the help message.")
        parser.usage = generate_usage(parser)
    end
    parser.filename = PROGRAM_FILE
    n::Int64 = length(cli_args)
    for i::Int64 in eachindex(cli_args)
        arg::String = cli_args[i]
        argkey::String = arg2key(arg)
        if startswith(arg, "-")
            !haskey(parser.arg_store, argkey) && error("Argument not found: $(arg). Call `add_argument` before parsing.")
            key::UInt16 = parser.arg_store[argkey]
            !haskey(parser.kv_store, key) && error("Key not found for argument: $(arg)")
        else
            continue
        end
        # if next iteration is at the end or is an argument, treat current argument as flag/boolean
        # otherwise, capture the value and skip iterating over it for efficiency
        if (i + 1 > n) || startswith(cli_args[i+1], "-")
            value = true
        elseif (i + 1 <= n)
            value = cli_args[i+1]
            i += 1
        else
            error("Value failed to parse for arg: $(arg)")
        end
        # extract default value and update given an argument value
        values::ArgumentValues = parser.kv_store[key]
        # type cast value into tuple index 1
        value = values.type == Any ? value : parse(values.type, value)
        parser.kv_store[key] = ArgumentValues(values.args, value, values.type, values.required, values.description)
    end
    return parser
end

"Get argument value from parser."
function get_value(parser::ArgumentParser, arg::AbstractString)
    :Any
    argkey::String = arg2key(arg)
    !haskey(parser.arg_store, argkey) && error("Argument not found: $(arg). Run `add_argument` first.")
    key::UInt16 = parser.arg_store[argkey]
    value::Any = haskey(parser.kv_store, key) ? parser.kv_store[key].value : nothing
    return value
end

"Check if argument key exists in store."
function has_key(parser::ArgumentParser, arg::AbstractString)
    :Bool
    argkey::String = arg2key(arg)
    result::Bool = haskey(parser.arg_store, argkey) ? true : false
    return result
end

Base.keys(parser::ArgumentParser) = [arg2key(v.args.long) for v in values(parser.kv_store)]

"Get argument key from parser."
function get_key(parser::ArgumentParser, arg::AbstractString)
    :Union
    argkey::String = arg2key(arg)
    key::Union{UInt16,Nothing} = haskey(parser.arg_store, argkey) ? parser.arg_store[argkey] : nothing
    return key
end

"Prepend hyphenation back onto argument after stripping it for the argument-store key."
function hyphenate(arg::AbstractString)
    :String
    argkey::String = arg2key(arg)  # supports "foo" or "--foo" argument form
    result::String = length(argkey) == 1 ? "-" * argkey : "--" * argkey
    return result
end

"Set/update value of argument in parser."
function set_value!(parser::ArgumentParser, arg::AbstractString, value::Any)
    :ArgumentParser
    argkey::String = arg2key(arg)
    !haskey(parser.arg_store, argkey) && error("Argument not found in store.")
    key::UInt16 = parser.arg_store[argkey]
    !haskey(parser.kv_store, key) && error("Key not found in store.")
    values::ArgumentValues = parser.kv_store[key]
    value = convert(values.type, value)
    parser.kv_store[key] = ArgumentValues(values.args, value, values.type, values.required, values.description)
    return parser
end

# Type conversion helper methods.
Base.parse(::Type{String},   x::Number)  = x
Base.parse(::Type{String},   x::String)  = x
Base.parse(::Type{Bool},     x::Bool)    = x
Base.parse(::Type{Number},   x::Number)  = x
Base.parse(::Type{String},   x::Bool)    = x ? "true" : "false"
Base.convert(::Type{Char},   x::Nothing) = ' '
Base.convert(::Type{String}, x::Nothing) = ""

###
### Utilities
###

"Key-value store mapping from colors to ANSI codes."
ANSICODES::Base.ImmutableDict{String,Int} = Base.ImmutableDict(
    "black"   => 30,
    "red"     => 31,
    "green"   => 32,
    "yellow"  => 33,
    "blue"    => 34,
    "magenta" => 35,
    "cyan"    => 36,
    "white"   => 37,
    "default" => 39
)

function colorize(text::AbstractString; color::AbstractString="default", background::Bool=false, bright::Bool=false)
    :String
    """
    Colorize strings or backgrounds using ANSI codes and escape sequences.
    -------------------------------------------------------------------------------
    | Color 	Example 	Text 	Background 	  Bright Text   Bright Background |
    | ----------------------------------------------------------------------------|
    | Black 	Black 	    30 	    40 	           90           100               |
    | Red 	    Red 	    31 	    41 	           91           101               |
    | Green 	Green 	    32 	    42 	           92           102               |
    | Yellow 	Yellow 	    33 	    43 	           93           103               |
    | Blue      Blue 	    34 	    44 	           94           104               |
    | Magenta 	Magenta 	35 	    45 	           95           105               |
    | Cyan      Cyan 	    36 	    46 	           96           106               |
    | White 	White 	    37 	    47 	           97           107               |
    | Default 		        39 	    49 	           99           109               |
    -------------------------------------------------------------------------------
    # Arguments
    - `text::String`: the UTF-8/ASCII text to colorize.
    - `color::String="default"`: the standard ANSI name of the color.
    - `background::Bool=false`: flag to select foreground or background color.
    - `bright::Bool=false`: flag to select normal or bright text.
    """
    code::Int8 = ANSICODES[color]
    background && (code += 10)
    bright && (code += 60)
    code_string::String = string(code)
    return "\033[" * code_string * "m" * text * "\033[0m"
end

# # # # # # # # 

function colorprint(text, color="default", newline=true; background=false, bright=false) 
    print(colorize(text; color, background, bright))
    newline && println()
end

argpair(s, args) = Symbol(s) => get_value(args, s)

function nt_args(args::ArgumentParser)
    allkeys = keys(args)
    filter!(x -> x != "help", allkeys)
    return NamedTuple(argpair(k, args) for k in allkeys)
end

@kwdef mutable struct PromptedParser
    parser::ArgumentParser = ArgumentParser()
    color::String = "default"
    introduction::String = ""
    prompt::String = "> "
end

nt_args(p::PromptedParser) = nt_args(p.parser)
set_value!(p::PromptedParser, arg, value) = set_value!(p.parser, arg, value)
add_argument!(p::PromptedParser, arg_short, arg_long; kwargs...) = add_argument!(p.parser, arg_short, arg_long; kwargs...)
parse_args!(p::PromptedParser, cli_args) = parse_args!(p.parser; cli_args)
add_example!(p::PromptedParser, example) = add_example!(p.parser, example) 

end # module SimpleArgParse
