"""
    DBHFit

Professional DBH (Diameter at Breast Height) fitting Julia package, providing multiple circle fitting algorithms for forestry point cloud data processing.

# Main Features

- Three fitting algorithms: Linear Least Squares (LS), Nonlinear Least Squares[Levenberg-Marquardt (LM)], RANSAC
- Unified API: `fit_dbh` function provides a unified interface
- Optional visualization: Supports Plots.jl for visualizing results

"""
module DBHFit

using LinearAlgebra
using StaticArrays
using Statistics
using Random
using Hyperopt

# Export public API
"""
    plot_fit(x, y, result; kwargs...)
Plot visualization graphics of the fitting result.
"""
function plot_fit end

# Export public API
export CircleFitResult, Point2D
export fit_dbh, fit_circle_ls, fit_circle_lm, fit_circle_ransac
export plot_fit
export calculate_rmse, calculate_mae
export validate_input

# Include source files
include("types.jl")
include("utils.jl")
include("algebraic.jl")
include("lm.jl")
include("ransac.jl")

"""
Unified entry function for DBH fitting.
    fit_dbh(x::AbstractVector, y::AbstractVector; method, skip_validation=false, kwargs...) -> CircleFitResult
    fit_dbh(points::AbstractVector{<:Point2D}; method, skip_validation=false, kwargs...) -> CircleFitResult

# Parameters

- x, y: Coordinate vectors of points

- points: Vector of Point2D

- method: Fitting method, must be specified, options: :ls, :lm, :ransac

- skip_validation: Whether to skip input validation (default false, set to true to increase processing speed)

- kwargs...: Arguments passed to the specific fitting method

# Returns
- CircleFitResult: Structure containing center, radius, DBH and other information
"""
function fit_dbh(x::AbstractVector{T}, y::AbstractVector{T}; 
                 method::Union{Symbol,Nothing}=nothing,
                 skip_validation::Bool=false,
                 kwargs...) where T<:Real
    # Validate input
    validate_input(x, y; skip_validation=skip_validation)
    
    # method must be specified
    if method === nothing
        throw(ArgumentError("The method parameter must be specified. Options: :ls, :lm, :ransac"))
    end
    
    # Call the specific fitting method
    if method == :ls
        return fit_circle_ls(x, y; kwargs...)
    elseif method == :lm
        return fit_circle_lm(x, y; kwargs...)
    elseif method == :ransac
        return fit_circle_ransac(x, y; kwargs...)
    else
        throw(ArgumentError("Unknown fitting method: $(method). Options: :ls, :lm, :ransac"))
    end
end

end # module
