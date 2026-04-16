"""
    residual_and_jacobian_row(xi, yi, p)

Compute the residual and Jacobian row vector for a single point.

# Parameters
- `xi, yi`: Coordinates of the point
- `p`: Parameter vector [center_x, center_y, radius]

# Returns
- `r`: Residual value
- `J_row`: Jacobian row vector
"""
@inline function residual_and_jacobian_row(xi::T, yi::T, 
                                           p::SVector{3,T}) where T<:Real
    xc, yc, R = p
    dx = xi - xc
    dy = yi - yc
    dist_sq = dx*dx + dy*dy
    dist = sqrt(dist_sq)

    r = dist - R
    threshold = sqrt(eps(T))
    
    if dist < threshold
        return -R, SVector{3,T}(zero(T), zero(T), -one(T))
    end
    
    inv_dist = one(T) / dist
    J_row = SVector{3,T}(-dx * inv_dist, -dy * inv_dist, -one(T))
    
    return r, J_row
end

"""
    huber_weight(r, c)

Compute Huber robust weights.

# Parameters
- `r`: Residual vector
- `c`: Threshold parameter

# Returns
- Weight vector
"""
function huber_weight(r::AbstractVector{T}, c::Real) where T<:Real
    return @. ifelse(abs(r) <= c, one(T), T(c / abs(r)))
end

"""
    fit_circle_lm(x, y; max_iter=50, robust=false, huber_threshold=4.685, skip_validation=false) -> CircleFitResult

Fit a circle using the Levenberg-Marquardt algorithm.

# Parameters
- `x, y`: Coordinate vectors of points
- `max_iter`: Maximum number of iterations (default 50)
- `robust`: Whether to use Huber robust weights (default false, changed from true)
- `huber_threshold`: Huber threshold coefficient (default 4.685)
- `skip_validation`: Whether to skip input validation (default false)

# Returns
- `CircleFitResult`: Fitting result

# Algorithm
1. Use algebraic method as initial guess
2. Iteratively optimize parameters
3. Optional Huber robust weighting reduces influence of outliers

# Note
For high-quality point cloud data (typical for DBH measurements), 
it is recommended to use `robust=false` (default) for better accuracy.
Use `robust=true` only when there are significant outliers in the data.
"""
function fit_circle_lm(x::AbstractVector{T}, y::AbstractVector{T}; 
                       max_iter::Int=50,  
                       robust::Bool=false,
                       huber_threshold::Real=4.685,
                       skip_validation::Bool=false,
                       kwargs...) where T<:Real
    validate_input(x, y; skip_validation=skip_validation)
    
    n = length(x)
    
    p = algebraic_initial_guess(x, y)

    tol = 1e-5
    λ = 1e-3
    ν = 2.0
    
    r = Vector{T}(undef, n)
    w = ones(T, n)
    err = typemax(T)
    
    for iter in 1:max_iter
        # Step 1: Compute residuals
        for i in 1:n
            ri, _ = residual_and_jacobian_row(x[i], y[i], p)
            r[i] = ri
        end
        
        # Step 2: Update weights (before computing Hessian)
        if robust
            mad = median(abs.(r))
            threshold = huber_threshold * mad
            w = huber_weight(r, threshold)
        end
        
        # Step 3: Compute weighted Hessian and gradient
        H = MMatrix{3,3,T,9}(zeros(T, 3, 3))
        g = MVector{3,T}(zeros(T, 3))
        
        for i in 1:n
            ri, Ji = residual_and_jacobian_row(x[i], y[i], p)
            
            sqrt_w = sqrt(w[i])
            Ji_w = sqrt_w * Ji
            ri_w = sqrt_w * ri
            
            H += Ji_w * Ji_w'
            g += Ji_w * ri_w
        end
        
        # Step 4: Solve for parameter update
        H_damped = H + λ * Diagonal(SVector{3,T}(diag(H)))
        Δp = - H_damped \ g
        
        p_new = p + Δp
        
        # Step 5: Compute new error
        err_new = zero(T)
        for i in 1:n
            ri_new, _ = residual_and_jacobian_row(x[i], y[i], p_new)
            err_new += w[i] * ri_new^2
        end
        
        # Step 6: Accept or reject update
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
