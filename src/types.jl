module TSMLTypes

using DataFrames

export 	fit!,transform!,fit_transform!
export 	Transformer,TSLearner

abstract type Transformer end
abstract type TSLearner <: Transformer end


"""
    fit!(tr::Transformer, instances::T, labels::Vector) where {T<:Union{Vector,Matrix,DataFrame}}

Generic `fit!` function to be redefined using multidispatch in  different subtypes of `Transformer`.
"""
function fit!(tr::Transformer, instances::DataFrame, labels::Vector{<:Any}) 
	error(typeof(tr)," not implemented yet: fit!")
end

"""
    transform!(tr::Transformer, instances::T) where {T<:Union{Vector,Matrix,DataFrame}}

Generic `transform!` function to be redefined using multidispatch in  different subtypes of `Transformer`.
"""
function transform!(tr::Transformer, instances::DataFrame) 
	error(typeof(tr)," not implemented yet: transform!")
end

# dynamic dispatch based Machine subtypes
function fit_transform!(tf::Transformer, input::DataFrame, output::Vector=Vector())
	fit!(tf,input,output)
	transform!(tf,input)
end

end
