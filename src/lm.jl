"""
    residual_and_jacobian_row(xi, yi, p)

Compute the residual and Jacobian row vector for a single point

# Parameters

- `xi, yi`: Coordinates of the point
- `p`: Parameter vector [center_x, center_y, radius]

- `xi, yi`: Coordinates of the point
- `p`: Parameter vector [center_x, center_y, radius]

"""
@inline function residual_and_jacobian_row(xi::T, yi::T, 
                                           p::SVector{3,T}) where T<:Real
    xc, yc, R = p
    dx = xi - xc
    dy = yi - yc
    dist = sqrt(dx*dx + dy*dy)
    
    if dist < eps(T)
        return zero(T), SVector{3,T}(zero(T), zero(T), -one(T))
    end
    
    inv_dist = one(T) / dist
    r = dist - R
    J_row = SVector{3,T}(-dx * inv_dist, -dy * inv_dist, -one(T))
    
    return r, J_row
end

"""
    huber_weight(r, c)

Compute Huber robust weights

# Parameters

- `r`: Residual vector
- `c`: Threshold parameter

# Returns

- `Vector{Float64}`: Weight vector
"""
function huber_weight(r::AbstractVector{T}, c::Real) where T<:Real
    return @. ifelse(abs(r) <= c, one(T), T(c / abs(r)))
end

"""
    fit_circle_lm(x, y; max_iter=50, robust=true, huber_threshold=4.685, skip_validation=false) -> CircleFitResult

Fit a circle using the Levenberg-Marquardt algorithm

# Parameters

- `x, y`: Coordinate vectors of points
- `max_iter`: Maximum number of iterations (default 50)
- `robust`: Whether to use Huber robust weights (default true)
- `huber_threshold`: Huber threshold coefficient (default 4.685)
- `skip_validation`: Whether to skip input validation (default false)

# Returns

- `CircleFitResult`: Fitting result

# Algorithm

1. Use algebraic method as initial guess
2. Iteratively optimize parameters
3. Optional Huber robust weighting reduces influence of outliers

"""
function fit_circle_lm(x::AbstractVector{T}, y::AbstractVector{T}; 
                       max_iter::Int=50,  
                       robust::Bool=true,
                       huber_threshold::Real=4.685,
                       skip_validation::Bool=false,
                       kwargs...) where T<:Real
    # Validate input
    validate_input(x, y; skip_validation=skip_validation)
    
    n = length(x)
    
    # Use algebraic method as initial guess
    p = algebraic_initial_guess(x, y)

    tol = 1e-5
    λ = 1e-3
    ν = 2.0
    
    # Pre-allocate residual vector
    r = Vector{T}(undef, n)
    
    # Compute initial residuals
    for i in 1:n
        ri, _ = residual_and_jacobian_row(x[i], y[i], p)
        r[i] = ri
    end
    
    # Compute Huber threshold
    if robust
        mad = 4.685 * median(abs.(r))
        w = huber_weight(r, mad)
        r = w .* r
    end
    
    err = sum(r.^2)
    
    # LM iteration
    for iter in 1:max_iter
        H = MMatrix{3,3,T,9}(zeros(T, 3, 3))
        g = MVector{3,T}(zeros(T, 3))
        
        for i in 1:n
            ri, Ji = residual_and_jacobian_row(x[i], y[i], p)
            r[i] = ri
            H += Ji * Ji'
            g += Ji * ri
        end
        
        H_damped = H + λ * Diagonal(SVector{3,T}(diag(H)))
        Δp = - H_damped \ g
        
        p_new = p + Δp
        
        err_new = zero(T)
        for i in 1:n
            ri_new, _ = residual_and_jacobian_row(x[i], y[i], p_new)
            err_new += ri_new^2
        end
        
        if err_new < err
            λ /= ν
            p = p_new
            err = err_new
            if norm(Δp) < tol
                break
            end
        else
            λ *= ν
        end
    end
    
    xc, yc, R = p
    
    rmse = calculate_rmse(x, y, xc, yc, R)
    
    return CircleFitResult(xc, yc, R, rmse, :lm)
end
