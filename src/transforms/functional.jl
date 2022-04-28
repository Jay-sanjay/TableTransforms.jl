# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    Functional(func)

The transform that applies a `func` elementwise.

    Functional(col₁ => func₁, col₂ => func₂, ..., colₙ => funcₙ)

Applies the `funcᵢ` function to the `colᵢ` column.

# Examples

```julia
Functional(cos)
Functional(sin)
Functional(:a => cos, :b => sin)
Functional("a" => cos, "b" => sin)
```
"""
struct Functional{F} <: Stateless
  func::F
end

Functional(pairs::Pair{Symbol}...) =
  Functional(Dict(pairs))

Functional(pairs::Pair{K}...) where {K<:AbstractString} =
  Functional(Dict(Symbol(k) => v for (k, v) in pairs))

Functional() = throw(ArgumentError("Cannot create a Functional object without arguments."))

# known invertible functions
inverse(::typeof(log))   = exp
inverse(::typeof(exp))   = log
inverse(::typeof(cos))   = acos
inverse(::typeof(acos))  = cos
inverse(::typeof(sin))   = asin
inverse(::typeof(asin))  = sin
inverse(::typeof(cosd))  = acosd
inverse(::typeof(acosd)) = cosd
inverse(::typeof(sind))  = asind
inverse(::typeof(asind)) = sind

# fallback to nothing
inverse(::Any) = nothing

isrevertible(transform::Functional) =
  !isnothing(inverse(transform.func))

isrevertible(transform::Functional{<:Dict}) =
  all(!isnothing, inverse.(values(transform.func)))


function applyfunc(transform::Functional, cols, nm)
  x = Tables.getcolumn(cols, nm)
  func = transform.func
  func.(x)
end

function applyfunc(transform::Functional{<:Dict}, cols, nm)
  x = Tables.getcolumn(cols, nm)
  func = get(transform.func, nm, identity)
  func.(x)
end

function apply(transform::Functional, table) 
  cols = Tables.columns(table)
  names = Tables.columnnames(table)
  ncols = tcollect(applyfunc(transform, cols, nm) for nm in names)
  𝒯 = (; zip(names, ncols)...)
  newtable = 𝒯 |> Tables.materializer(table)
  return newtable, nothing
end
