"""
    validate_input(x, y; skip_validatio=false)

Validate input data.

# Parameters
- `x, y`: Coordinate vectors
- `skip_validation`: Whether to skip validation (default false)

# Exceptions
- `ArgumentError`: Thrown when input is invalid
"""
function validate_input(x::AbstractVector, y::AbstractVector; skip_validation::Bool=false)
    if skip_validation
        return true
    end
    
    if length(x) != length(y)
        throw(ArgumentError("x and y must have same length (x: $(length(x)), y: $(length(y)))"))
    end
    
    if length(x) < 3
        throw(ArgumentError("At least 3 points required for circle fitting (current: $(length(x)) points)"))
    end
    
    nan_x = count(isnan, x)
    nan_y = count(isnan, y)
    if nan_x > 0 || nan_y > 0
        throw(ArgumentError("Input contains NaN values (x: $(nan_x), y: $(nan_y))"))
    end
    
    inf_x = count(isinf, x)
    inf_y = count(isinf, y)
    if inf_x > 0 || inf_y > 0
        throw(ArgumentError("Input contains Inf values (x: $(inf_x), y: $(inf_y))"))
    end
    
    if all(x .≈ x[1]) && all(y .≈ y[1])
        throw(ArgumentError("All points coincide, cannot fit circle"))
    end
    
    if _are_collinear(x, y)
        throw(ArgumentError("All points are collinear, cannot fit circle"))
    end
    
    return true
end

"""
    _are_collinear(x, y)

Check if points are collinear.
"""
function _are_collinear(x::AbstractVector, y::AbstractVector)
    n = length(x)
    if n < 3
        return false
    end
    
    x1, y1 = x[1], y[1]
    x2, y2 = x[2], y[2]
    
    for i in 3:n
        x3, y3 = x[i], y[i]
        area = abs((x2-x1)*(y3-y1) - (x3-x1)*(y2-y1))
        scale = max(abs(x2-x1) + abs(y2-y1), abs(x3-x1) + abs(y3-y1), 1e-10)
        if area / scale > 1e-8
            return false
        end
    end
    
    return true
end

"""
    calculate_rmse(x, y, center_x, center_y, radius)

Calculate Root Mean Square Error of fitting.

# Parameters
- `x, y`: Point coordinates
- `center_x, center_y, radius`: Circle parameters

# Returns
- `Float64`: RMSE value
"""
function calculate_rmse(x::AbstractVector{T}, y::AbstractVector{T}, 
                        center_x::Real, center_y::Real, radius::Real) where T<:Real
    n = length(x)
    sum_sq = zero(T)
    @inbounds for i in 1:n
        dist = sqrt((x[i] - center_x)^2 + (y[i] - center_y)^2)
        sum_sq += (dist - radius)^2
    end
    return sqrt(sum_sq / n)
end

"""
    calculate_mae(x, y, center_x, center_y, radius)

Calculate Mean Absolute Error of fitting.

# Parameters
- `x, y`: Point coordinates
- `center_x, center_y, radius`: Circle parameters

# Returns
- `Float64`: MAE value
"""
function calculate_mae(x::AbstractVector{T}, y::AbstractVector{T}, 
                       center_x::Real, center_y::Real, radius::Real) where T<:Real
    n = length(x)
    sum_abs = zero(T)
    @inbounds for i in 1:n
        dist = sqrt((x[i] - center_x)^2 + (y[i] - center_y)^2)
        sum_abs += abs(dist - radius)
    end
    return sum_abs / n
end
