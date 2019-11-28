@reexport module Normalizers

using StatsBase
using Dates
using DataFrames
using Statistics
using MultivariateStats
using Random

using TSML.Utils
using TSML.TSMLTypes
import TSML.TSMLTypes.fit! # to overload
import TSML.TSMLTypes.transform! # to overload

export fit!,transform!
export Normalizer
export testnormalizer


"""
    Normalizer(Dict(
       :method => :zscore
    ))


Transforms continuous features into normalized form such as zscore, unitrange, square-root, log, pca, ppca
with parameter: 

- `:method` => `:zscore` or `:unitrange` or `:sqrt` or `:log` or `pca` or `ppca` or `fa`

Example:

Implements: `fit!`, `transform!`
"""
mutable struct Normalizer <: Transformer
  model
  args

  function Normalizer(args=Dict())
    default_args = Dict(
        :method => :zscore
    )
    new(nothing, mergedict(default_args, args))
  end
end

"""
    fit!(st::Statifier, features::T, labels::Vector=[]) where {T<:Union{Vector,Matrix,DataFrame}}

Validate argument to make sure it's a 2-column format.
"""
function fit!(norm::Normalizer, features::T, labels::Vector=[]) where {T<:Union{Vector,Matrix,DataFrame}}
  typeof(features) <: DataFrame || error("Normalizer.fit!: data should be a dataframe: Date,Val ")
  # check features are in correct format and no categorical values
  (eltype(features[:,1]) <: DateTime && eltype(Matrix(features[:,2:end])) <: Real) || (eltype(Matrix(features)) <: Real) || error("Normalizer.fit: make sure features are purely float values or float values with Date on first column")
  norm.model = norm.args
end

"""
    transform!(norm::Normalizer, features::T) where {T<:Union{Vector,Matrix,DataFrame}}

Compute statistics.
"""
function transform!(norm::Normalizer, features::T) where {T<:Union{Vector,Matrix,DataFrame}}
  features != [] || return DataFrame()
  res = Array{Float64,2}(undef,0,0)
  if (eltype(features[:,1]) <: DateTime && eltype(Matrix(features[:,2:end])) <: Real)
    res = processnumeric(norm,Matrix(features[:,2:end]))
  elseif eltype(features) <: Real
    res = processnumeric(norm,Matrix(features))
  else
    error("Normalizer.fit: make sure features are purely float values or float values with Date on first column")
  end
end

function processnumeric(norm::Normalizer,features::Matrix)
  if norm.args[:method] == :zscore
    ztransform(features)
  elseif norm.args[:method] == :unitrange
    unitrtransform(features)
  elseif norm.args[:method] == :pca
    pca(features)
  elseif norm.args[:method] == :ppca
    ppca(features)
  elseif norm.args[:method] == :fa
    fa(features)
  else
    error("arg's :method is mapped to unknown keyword")
  end
end

# apply square-root transform
function ztransform(X)
    fit(ZScoreTransform, X'; center=true, scale=true) |> dt -> StatsBase.transform(dt,X')' |> collect
end

# unit-range
function unitrtransform(X)
    fit(UnitRangeTransform, X') |> dt -> StatsBase.transform(dt,X')' |> collect
end

# pca
function pca(X)
  xp = X'
  m = fit(PCA,xp)
  transform(m,xp)' |> collect
end


# ppca
function ppca(X)
  xp = X'
  m = fit(PPCA,xp)
  transform(m,xp)' |> collect
end

# fa
function fa(X)
  xp = X'
  m = fit(FactorAnalysis,xp)
  transform(m,xp)' |> collect
end

function generatedf()
    Random.seed!(123)
    gdate = DateTime(2014,1,1):Dates.Minute(15):DateTime(2016,1,1)
    gval1 = rand(length(gdate))
    gval2 = rand(length(gdate))
    gval3 = rand(length(gdate))
    X = DataFrame(Date=gdate,Value1=gval1,Value2=gval2,Value3=gval3)
    X
end

function testnormalizer()
  X = generatedf()
  norm = Normalizer(Dict(:method => :zscore))
  fit!(norm,X)
  res=transform!(norm,X)
  @assert isapprox(mean(res[:,1]),0.0,atol=1e-8)
  @assert isapprox(mean(res[:,2]),0.0,atol=1e-8)
  @assert isapprox(std(res[:,1]),1.0,atol=1e-8)
  @assert isapprox(std(res[:,2]),1.0,atol=1e-8)
  norm = Normalizer(Dict(:method => :unitrange))
  fit!(norm,X)
  res=transform!(norm,X)
  @assert isapprox(minimum(res[:,1]),0.0,atol=1e-8)
  @assert isapprox(minimum(res[:,2]),0.0,atol=1e-8)
  @assert isapprox(maximum(res[:,1]),1.0,atol=1e-8)
  @assert isapprox(maximum(res[:,2]),1.0,atol=1e-8)
  norm = Normalizer(Dict(:method => :pca))
  fit!(norm,X)
  res=transform!(norm,X)
  @assert isapprox(std(res[:,1]),0.28996,atol=1e-2)
  norm = Normalizer(Dict(:method => :fa))
  fit!(norm,X)
  res = transform!(norm,X)
  @assert isapprox(std(res[:,1]),0.81670,atol=1e-2)
  norm = Normalizer(Dict(:method => :ppca))
  fit!(norm,X)
  res = transform!(norm,X)
  @assert isapprox(std(res[:,1]),0.00408,atol=1e-2)
end

end
