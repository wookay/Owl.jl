🦉  [https://github.com/MikeInnes/MacroTools.jl](https://github.com/MikeInnes/MacroTools.jl) README.md 번역


# MacroTools.jl

This library provides helpful tools for writing macros, notably a very simple
but powerful templating system and some functions that have proven useful to me (see
[utils.jl](https://github.com/MikeInnes/MacroTools.jl/blob/master/src/utils.jl).)

## Template Matching

Template matching enables macro writers to deconstruct Julia
expressions in a more declarative way, and without having to know in
great detail how syntax is represented internally. For example, say you
have a type definition:

```julia-repl
julia> ex = quote
         struct Foo
           x::Int
           y
         end
       end
quote  # REPL[1], line 2:
    struct Foo # REPL[1], line 3:
        x::Int # REPL[1], line 4:
        y
    end
end
```

If you know what you're doing, you can pull out the name and fields via:

```julia-repl
julia> (ex.args[2].args[2], ex.args[2].args[3].args)
(:Foo, Any[:( # REPL[2], line 3:), :(x::Int), :( # REPL[2], line 4:), :y])
```

But this is hard to write – since you have to deconstruct the `type`
expression by hand – and hard to read, since you can't tell at a glance
what's being achieved. On top of that, there's a bunch of messy stuff to
deal with like pesky `begin` blocks which wrap a single expression, line
numbers, etc. etc.

Enter MacroTools:

```julia-repl
julia> using MacroTools

julia> @capture ex  struct T_ fields__ end
true

julia> T, fields
(:Foo, Any[:(x::Int), :y])
```

Symbols like `T_` underscore are treated as catchalls which match any
expression, and the expression they match is bound to the
(underscore-less) variable, as above.

Because `@capture` doubles as a test as well as extracting values, you can
easily handle unexpected input (try writing this by hand):

```julia-repl
julia> @capture(ex, f_{T_}(xs__) = body_) ||
         error("expected a function with a single type parameter")
ERROR: expected a function with a single type parameter
Stacktrace:
 [1] error(::String) at ./error.jl:21
```

Symbols like `f__` (double underscored) are similar, but slurp a sequence of
arguments into an array. For example:

```julia-repl
julia> @capture :[1, 2, 3, 4, 5, 6, 7]  [1, a_, 3, b__, c_]
true

julia> a, b, c
(2, Any[4, 5, 6], 7)
```

Slurps don't have to be at the end of an expression, but like the
Highlander there can only be one (per expression).

### Matching on expression type

`@capture` can match expressions by their type, which is either the `head` of `Expr`
objects or the `typeof` atomic stuff like `Symbol`s and `Int`s. For example:

```julia-repl
julia> @capture :(foo(""))  foo(x_String_string)
true

julia> @capture :(foo("$(a)"))  foo(x_String_string)
true
```

This will match a call to the `foo` function which has a single argument, which
may either be a `String` object or a `Expr(:string, ...)`
(e.g. `@capture(:(foo("$(a)")), foo(x_String_string))`). Julia string literals
may be parsed into either type of object, so this is a handy way to catch both.

Another common use case is to catch symbol literals, e.g.

```julia-repl
julia> @capture ex  struct T_Symbol fields__ end
true

julia> T, fields
(:Foo, Any[:(x::Int), :y])
```

which will match e.g. `struct Foo ...` but not `struct Foo{V} ...`

```julia-repl
julia> @capture :(struct Foo{V} a end)  struct T_ fields__ end
true

julia> T
:(Foo{V})

julia> @capture :(struct Foo{V} a end)  struct T_Symbol fields__ end
false
```

### Unions

`@capture` can also try to match the expression against one pattern or another,
for example:

```julia-repl
julia> @capture :(g() = 0)           (f_(args__) = body_) | function f_(args__) body_ end
true

julia> @capture :(function g() end)  (f_(args__) = body_) | function f_(args__) body_ end
true
```

will match both kinds of function syntax (though it's easier to use
`shortdef` to normalise definitions). You can also do this within
expressions, e.g.

```julia-repl
julia> @capture :(g() = 0)             f_(args__) | f_(args__) where T_ = body_
true

julia> T

julia> @capture :(g(::T) where T = 0)  f_(args__) | f_(args__) where T_ = body_
true

julia> T
:T
```

matches a function definition, with a single type parameter bound to `T` if possible.
If not, `T = nothing`.

## Expression Walking

If you've ever written any more interesting macros, you've probably found
yourself writing recursive functions to work with nested `Expr` trees.
MacroTools' `prewalk` and `postwalk` functions factor out the recursion, making
macro code much more concise and robust.

These expression-walking functions essentially provide a kind of
find-and-replace for expression trees. For example:

```julia-repl
julia> using MacroTools: prewalk, postwalk

julia> postwalk(x -> x isa Integer ? x + 1 : x, :(2+3))
:(3 + 4)
```

In other words, look at each item in the tree; if it's an integer, add one, if not, leave it alone.

We can do more complex things if we combine this with `@capture`. For example, say we want to insert an extra argument into all function calls:

```julia-repl
julia> ex = quote
           x = f(y, g(z))
           return h(x)
       end
quote  # REPL[137], line 2:
    x = f(y, g(z)) # REPL[137], line 3:
    return h(x)
end

julia> postwalk(x -> @capture(x, f_(xs__)) ? :($f(5, $(xs...))) : x, ex)
quote  # REPL[137], line 2:
    x = f(5, y, g(5, z)) # REPL[137], line 3:
    return h(5, x)
end
```

Most of the time, you can use `postwalk` without worrying about it, but we also
provide `prewalk`. The difference is the order in which you see sub-expressions;
`postwalk` sees the leaves of the `Expr` tree first and the whole expression
last, while `prewalk` is the opposite.

```julia-repl
julia> postwalk(x -> @show(x) isa Integer ? x + 1 : x, :(2+3*4));
x = :+
x = 2
x = :*
x = 3
x = 4
x = :(4 * 5)
x = :(3 + 4 * 5)

julia> prewalk(x -> @show(x) isa Integer ? x + 1 : x, :(2+3*4));
x = :(2 + 3 * 4)
x = :+
x = 2
x = :(3 * 4)
x = :*
x = 3
x = 4
```

A significant difference is that `prewalk` will walk into whatever expression
you return.

```julia-repl
julia> postwalk(x -> @show(x) isa Integer ? :(a+b) : x, 2)
x = 2
:(a + b)

julia> prewalk(x -> @show(x) isa Integer ? :(a+b) : x, 2)
x = 2
x = :+
x = :a
x = :b
:(a + b)
```

This makes it somewhat more prone to infinite loops; for example, if we returned
`:(1+b)` instead of `:(a+b)`, `prewalk` would hang trying to expand all of the
`1`s in the expression.

With these tools in hand, a useful general pattern for macros is:

```julia-repl
julia> macro foo(ex)
           postwalk(ex) do x
               @capture(x, a_*b_) || return x
               return (a, b)
           end
       end
@foo (macro with 1 method)

julia> @foo 2
2

julia> @foo 2x
(2, :x)

julia> @foo 2x * 3
((2, :x), 3)
```

## Function definitions

`splitdef(def)` matches a function definition of the form

```julia
function name{params}(args; kwargs)::rtype where {whereparams}
   body
end
```

and returns `Dict(:name=>..., :args=>..., etc.)`. The definition can be rebuilt by
calling `MacroTools.combinedef(dict)`, or explicitly with

```julia-repl
julia> dict = splitdef(:(f() = 0))
Dict{Symbol,Any} with 5 entries:
  :name        => :f
  :args        => Any[]
  :kwargs      => Any[]
  :body        => quote …
  :whereparams => ()

julia> rtype = get(dict, :rtype, :Any)
:Any

julia> all_params = [get(dict, :params, [])..., get(dict, :whereparams, [])...]
0-element Array{Any,1}

julia> :(function $(dict[:name]){$(all_params...)}($(dict[:args]...);
                                                   $(dict[:kwargs]...))::$rtype
             $(dict[:body])
         end)
:(function f{}(; )::Any # REPL[83], line 3:
        begin
            0
        end
    end)
```

`splitarg(arg)` matches function arguments (whether from a definition or a function call)
such as `x::Int=2` and returns `(arg_name, arg_type, default)`. `default` is `nothing`
when there is none. For example:

```julia
julia> map(splitarg, (:(f(a=2, x::Int=nothing, y))).args[2:end])
3-element Array{Tuple{Symbol,Symbol,Bool,Any},1}:
 (:a, :Any, false, 2)
 (:x, :Int, false, :nothing)
 (:y, :Any, false, nothing)
```
