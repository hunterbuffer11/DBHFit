using LsqFit
using Statistics

"""
    circle_model((xi, yi), p)

Circle fitting model for LsqFit.

# Parameters
- `(xi, yi)`: Point coordinates (tuple)
- `p`: Parameter vector [center_x, center_y, radius]

# Returns
- Residual: signed distance from point to circle
"""
function circle_model((xi, yi), p)
    xc, yc, R = p
    return sqrt((xi - xc)^2 + (yi - yc)^2) - R
end

"""
    circle_jacobian((xi, yi), p)

Jacobian for circle model (optional, improves speed and accuracy).
"""
function circle_jacobian((xi, yi), p)
    xc, yc, R = p
    dx = xi - xc
    dy = yi - yc
    dist = sqrt(dx^2 + dy^2)
    if dist < 1e-12
        return [-1.0, -1.0, -1.0]
    end
    inv_dist = 1.0 / dist
    return [-dx * inv_dist, -dy * inv_dist, -1.0]
end

"""
    huber_weight(r, c)
"""
function huber_weight(r::AbstractVector{T}, c::Real) where T<:Real
    return @. ifelse(abs(r) <= c, one(T), T(c / abs(r)))
end

"""
    fit_circle_lm(x, y; max_iter=50, robust=false, huber_threshold=4.685, skip_validation=false) -> CircleFitResult

Fit a circle using Levenberg-Marquardt algorithm via LsqFit.jl.

# Parameters
- `x, y`: Coordinate vectors of points
- `max_iter`: Maximum number of iterations (default 50)
- `robust`: Whether to use Huber robust weights (default false)
- `huber_threshold`: Huber threshold coefficient (default 4.685)
- `skip_validation`: Whether to skip input validation (default false)

# Returns
- `CircleFitResult`: Fitting result
"""
function fit_circle_lm(x::AbstractVector{T}, y::AbstractVector{T}; 
                       max_iter::Int=50,  
                       robust::Bool=false,
                       huber_threshold::Real=4.685,
                       kwargs...) where T<:Real
    n = length(x)
    
    # Initial guess using Pratt's method
    p0 = Vector{T}(algebraic_initial_guess(x, y))
    
    # Initial weights (all ones for standard least squares)
    w = ones(T, n)
    
    # Prepare data for LsqFit
    xdata = (x, y)
    ydata = zeros(T, n)  # Target: residuals should be zero
    
    # Initialize fit variable
    fit = nothing
    
    # Perform LM optimization
    if robust
        # IRLS: Iteratively Reweighted Least Squares with Huber weights
        for iter in 1:max_iter
            # Weighted LM fit
            fit = curve_fit(
                circle_model, 
                xdata, 
                ydata,                 
                p0;
                weights = w,                
                jacobian = circle_jacobian,
                maxiter = max_iter
            )
            p0 = fit.param
            
            # Compute residuals
            residuals = fit.resid
            
            # Update Huber weights using MAD
            mad_val = median(abs.(residuals))
            if mad_val < 1e-10
                break
            end
            threshold = huber_threshold * mad_val
            w = huber_weight(residuals, threshold)
        end
    else
        # Standard LM fit (no robust weighting)
        fit = curve_fit(
            circle_model, 
            xdata, 
            ydata,                 
            p0;
            jacobian = circle_jacobian,
            maxiter = max_iter
        )
    end
    
    # Safety check
    if fit === nothing
        error("LM fitting failed: fit object is not initialized")
    end
    
    xc, yc, R = fit.param
    
    # Compute RMSE
    rmse = sqrt(fit.ssr / n)
    
    return CircleFitResult(T(xc), T(yc), T(R), T(rmse), :lm)
end
