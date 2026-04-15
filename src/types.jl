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

