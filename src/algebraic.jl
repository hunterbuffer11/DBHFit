"""
    fit_circle_ls(x, y; kwargs...) -> CircleFitResult
Use the :ls method to fit the circle (algebraic least squares).
"""

#1.fit_circle_ls
"""
    fit_circle_ls(x, y; skip_validation=false) -> CircleFitResult

Fit a circle using the least squares method.

# Parameters
- `x, y`: Coordinate vectors of points
- `skip_validation`: Whether to skip input validation (default false)

# Returns
- `CircleFitResult`: Fitting result
"""
function fit_circle_ls(x::AbstractVector{T}, y::AbstractVector{T}; 
                        kwargs...) where T<:Real
    n = length(x)
    
    Sx = Sy = Sxx = Sxy = Syy = Sxz = Syz = Sz = zero(T)
    
    @inbounds for i in 1:n
        xi = x[i]
        yi = y[i]
        xi2 = xi * xi
        yi2 = yi * yi
        Sx  += xi
        Sy  += yi
        Sxx += xi2
        Sxy += xi * yi
        Syy += yi2
        zi  = xi2 + yi2
        Sxz += xi * zi
        Syz += yi * zi
        Sz  += zi
    end
    
    # Build normal equations
    AtA = zeros(MMatrix{3,3,T,9})
    Atz = zeros(MVector{3,T})
    
    AtA[1,1] = 4*Sxx
    AtA[1,2] = 4*Sxy
    AtA[1,3] = 2*Sx
    AtA[2,2] = 4*Syy
    AtA[2,3] = 2*Sy
    AtA[3,3] = n
    
    Atz[1] = 2*Sxz
    Atz[2] = 2*Syz
    Atz[3] = Sz
    
    # Fill symmetrically
    AtA[2,1] = AtA[1,2]
    AtA[3,1] = AtA[1,3]
    AtA[3,2] = AtA[2,3]
    
    # Solve
    a, b, c = AtA \ Atz
    
    # Calculate the radius
    val = c + a*a + b*b
    R = val > 0 ? sqrt(val) : zero(T)
    
    # Compute error
    rmse = calculate_rmse(x, y, a, b, R)
    
    return CircleFitResult(a, b, R, rmse, :ls)
end
