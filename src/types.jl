"""
    CircleFitResult{T<:Real}

Circle fitting result containing center, radius and fitting quality information.

# Parameters
- `center_x::T`: Circle center X coordinate
- `center_y::T`: Circle center Y coordinate
- `radius::T`: Circle radius
- `dbh::T`: Diameter at Breast Height (equals 2*radius)
- `rmse::T`: Root Mean Square Error of fitting
- `method::Symbol`: Fitting method (:ls, :lm, :ransac)
"""
struct CircleFitResult{T<:Real}
    center_x::T
    center_y::T
    radius::T
    dbh::T
    rmse::T
    method::Symbol
end

"""
    CircleFitResult(center_x, center_y, radius, rmse, method)

Construct CircleFitResult, automatically calculates dbh.
"""
function CircleFitResult(center_x::T, center_y::T, radius::T, 
                         rmse::T, method::Symbol) where T<:Real
    return CircleFitResult{T}(center_x, center_y, radius, 2*radius, rmse, method)
end

"""
    Point2D{T<:Real}

2D point data structure.

# Parameters
- `x::T`: X coordinate
- `y::T`: Y coordinate
"""
struct Point2D{T<:Real}
    x::T
    y::T
end

"""
    FitConfig

Fitting configuration parameters.

# Parameters
- `method::Symbol`: Fitting method (:ls, :lm, :ransac) **must specify**
- `robust::Union{Bool,Nothing}`: Whether to use robust fitting
- `max_iter::Union{Int,Nothing}`: Maximum number of iterations
- `threshold::Union{Float64,Nothing}`: RANSAC threshold
- `min_inliers::Union{Int,Nothing}`: Minimum number of inliers
- `max_trials::Union{Int,Nothing}`: RANSAC maximum number of trials
"""
struct FitConfig
    method::Symbol
    robust::Union{Bool,Nothing}
    max_iter::Union{Int,Nothing}
    threshold::Union{Float64,Nothing}
    min_inliers::Union{Int,Nothing}
    max_trials::Union{Int,Nothing}
end

"""
    FitConfig(method; robust=nothing, max_iter=nothing, threshold=nothing, 
              min_inliers=nothing, max_trials=nothing)

Construct FitConfig, method parameter must be specified.
"""
function FitConfig(method::Symbol; 
                    robust::Union{Bool,Nothing}=nothing,
                    max_iter::Union{Int,Nothing}=nothing,
                    threshold::Union{Float64,Nothing}=nothing,
                    min_inliers::Union{Int,Nothing}=nothing,
                    max_trials::Union{Int,Nothing}=nothing)
    return FitConfig(method, robust, max_iter, threshold, min_inliers, max_trials)
end
