module SimpleArgParse

export ArgumentParser, add_argument, parse_args, exists, get, set, colorize

using Base

###
### Data Structures
###

# command-line argument data structure.
mutable struct ArgumentParser
    # member variables
    # key-value store: { key: (value, type, required, help) }
    kv_store::Dict{Char,Tuple{Any,Type,Bool,String}}
    description::String
    # member functions
    ArgumentParser(; description::String="") = new(Dict(), description)
end

###
### Functions
###

# add argument to parser
function add_argument(args::ArgumentParser, arg_short::String=nothing, arg_long::String=nothing; type::Type=nothing,
    default::Any=nothing, required::Bool=false, help::String="")
    :ArgumentParser
    # key is first non-hyphen character
    arg::String = !isnothing(arg_short) ? arg_short : !isnothing(arg_long) ? arg_long : nothing
    isnothing(arg) && error("Argument missing: $(arg)")
    key::Char = strip(arg, '-')[1]
    default = isnothing(type) ? default : parse(type, default)
    values::Tuple = (default, type, required, help)
    args.kv_store[key] = values
    return args
end

# parse command-line arguments
function parse_args(parser::ArgumentParser)
    :ArgumentParser
    filename::String = PROGRAM_FILE
    n::Int64 = length(ARGS)
    for i::Int64 in eachindex(ARGS)
        arg::String = ARGS[i]
        if startswith(arg, "-")
            key::Char = strip(arg, '-')[1]
        else
            continue
        end
        isnothing(key) && continue
        # if next arg is a key, treat as flag and store value as boolean
        if (i + 1 > n) || startswith(ARGS[i+1], "-")
            value = true
        elseif (i + 1 <= n)
            value = ARGS[i+1]
            i += 1
        else
            error("Value failed to parse for arg: $(arg)")
        end
        !haskey(parser.kv_store, key) && error("Key not found in store: $(key); arg: $(arg)")
        values::Tuple = parser.kv_store[key]
        # type cast value into tuple index 1
        value = isnothing(values[2]) ? value : parse(values[2], value)
        parser.kv_store[key] = (value, values[2], values[3], values[4])
    end
    get(parser, "verbose") && println("Arguments parsed: $(filename)")
    return parser
end

# argument to key conversion function
function argkey(arg::String)
    :Char
    arg = startswith(arg, "-") ? strip(arg, '-') : arg
    arg = length(arg) > 1 ? arg[1] : arg
    key::Char = only(arg)
    return key
end

# check if argument exists in parser
function exists(parser::ArgumentParser, key::Char)
    :Bool
    result::Bool = haskey(parser.kv_store, key) ? true : false
    return result
end

# check if argument exists in parser
function exists(parser::ArgumentParser, arg::String)
    :Bool
    key::Char = argkey(arg)
    result::Bool = haskey(parser.kv_store, key) ? true : false
    return result
end

# get argument from parser
function get(parser::ArgumentParser, arg::String)
    :Any
    key::Char = argkey(arg)
    value::Any = exists(parser, key) ? parser.kv_store[key][1] : nothing
    return value
end

# set argument in parser
function set(parser::ArgumentParser, arg::String, value::Any)
    :ArgumentParser
    key::Char = argkey(arg)
    !haskey(parser.kv_store, key) && error("Key not found in store.")
    values = parser.kv_store[key]
    value = isnothing(values[2]) ? value : parse(values[2], value)
    parser.kv_store[key] = (value, values[2], values[3], values[4])
    return parser
end

# type conversion helper methods
Base.parse(::Type{String}, x::String) = x
Base.parse(::Type{Bool}, x::Bool) = x
Base.parse(::Type{Number}, x::Number) = x
Base.parse(::Type{String}, x::Bool) = x ? "true" : "false"
Base.convert(::Type{Char}, x::Nothing) = ' '

###
### Utilities
###

# map of colors to ANSI codes
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

# colorize string using ANSI codes and escape sequences
# -----------------------------------------------------------------------------
# Color 	Example 	Text 	Background 	Bright Text 	Bright Background
# -----------------------------------------------------------------------------
# Black 	Black 	    30 	    40 	        90 	            100
# Red 	    Red 	    31 	    41 	        91 	            101
# Green 	Green 	    32 	    42 	        92 	            102
# Yellow 	Yellow 	    33 	    43 	        93 	            103
# Blue      Blue 	    34 	    44 	        94 	            104
# Magenta 	Magenta 	35 	    45 	        95 	            105
# Cyan      Cyan 	    36 	    46 	        96 	            106
# White 	White 	    37 	    47 	        97 	            107
# Default 		        39 	    49 	        99 	            109
# -----------------------------------------------------------------------------
function colorize(text::String, color::String="default", back::Bool=false, bright::Bool=false)::String
    code::Int8 = ANSICODES[color]
    back && (code += 10)
    bright && (code += 60)
    code_string::String = string(code)
    return "\033[" * code_string * "m" * text * "\033[0m"
end

end # module SimpleArgParse
