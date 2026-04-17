using LsqFit
using Statistics

"""
    circle_model(xdata, p)

Circle fitting model for LsqFit.
"""
function circle_model(xdata, p)
    xc, yc, R = p
    x = @view xdata[1, :]
    y = @view xdata[2, :]
    n = length(x)
    result = zeros(n)
    @inbounds for i in 1:n
        result[i] = hypot(x[i] - xc, y[i] - yc) - R
    end
    return result
end

"""
    circle_jacobian(xdata, p)

Jacobian for circle model.
"""
function circle_jacobian(xdata, p)
    xc, yc, R = p
    x = @view xdata[1, :]
    y = @view xdata[2, :]
    n = length(x)
    J = zeros(n, 3)
    @inbounds for i in 1:n
        dx = x[i] - xc
        dy = y[i] - yc
        dist = hypot(dx, dy)
        if dist < 1e-15
            J[i, :] .= 0.0
        else
            J[i, 1] = -dx / dist
            J[i, 2] = -dy / dist
            J[i, 3] = -1.0
        end
    end
    return J
end

"""
    huber_weight(r, c)

Compute Huber robust weights.
"""
function huber_weight(r::AbstractVector{T}, c::Real) where T<:Real
    return @. ifelse(abs(r) <= c, one(T), T(c / abs(r)))
end

"""
    fit_circle_lm(x, y; max_iter=50, robust=false, huber_threshold=4.685) -> CircleFitResult

Fit a circle using Levenberg-Marquardt algorithm via LsqFit.jl.

# Parameters
- `x, y`: Coordinate vectors of points
- `max_iter`: Maximum number of iterations (default 50)
- `robust`: Whether to use Huber robust weights (default false)
- `huber_threshold`: Huber threshold coefficient (default 4.685)

# Returns
- `CircleFitResult`: Fitting result
"""
function fit_circle_lm(x::AbstractVector{T}, y::AbstractVector{T}; 
                       max_iter::Int=50,  
                       robust::Bool=false,
                       huber_threshold::Real=4.685,
                       kwargs...) where T<:Real
    n = length(x)
    
    p0 = Vector{T}(algebraic_initial_guess(x, y))
    
    w = ones(T, n)
    
    xdata = hcat(x, y)'
    ydata = zeros(T, n)
    
    fit = nothing
    
    if robust
        for iter in 1:max_iter
            fit = curve_fit(circle_model, circle_jacobian, xdata, ydata, p0, w;
                           maxIter=max_iter)
            p0 = fit.param
            
            residuals = fit.resid
            mad_val = max(median(abs.(residuals)), 1e-8)
            if mad_val < 1e-10
                break
            end
            threshold = huber_threshold * mad_val
            w = huber_weight(residuals, threshold)
            w = clamp.(w, 0.0, 1e6)
        end
    else
        fit = curve_fit(circle_model, circle_jacobian, xdata, ydata, p0;
                       maxIter=max_iter)
    end
    
    if fit === nothing
        error("LM fitting failed: fit object is not initialized")
    end
    
    xc, yc, R = fit.param
    rmse = sqrt(sum(abs2, fit.resid) / n)
    
    return CircleFitResult(T(xc), T(yc), T(R), T(rmse), :lm)
end
