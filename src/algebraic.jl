"""
    1.algebraic_initial_guess(x, y) -> SVector{3}
    2.fit_circle_ls(x, y; kwargs...) -> CircleFitResult

First,Compute initial estimate of a circle using Pratt's method (more robust than Kåsa).
Second,Use the :ls method to fit the circle (algebraic least squares).
"""

#1.algebraic_initial_guess
"""
Compute initial estimate of a circle using Pratt's method.
"""
function algebraic_initial_guess(x::AbstractVector{T}, 
                                 y::AbstractVector{T}) where T<:Real
    n = length(x)
    
    # Compute moments
    Sx = sum(x)
    Sy = sum(y)
    Sxx = sum(x.^2)
    Syy = sum(y.^2)
    Sxy = sum(x .* y)
    Sxxx = sum(x.^3)
    Syyy = sum(y.^3)
    Sxxy = sum(x.^2 .* y)
    Sxyy = sum(x .* y.^2)
    Sxxxx = sum(x.^4)
    Syyyy = sum(y.^4)
    Sxxyy = sum(x.^2 .* y.^2)
    
    # Build moment matrix M (4x4)
    M = zeros(T, 4, 4)
    M[1,1] = Sxxxx + 2*Sxxyy + Syyyy
    M[1,2] = Sxxx + Sxyy
    M[1,3] = Sxxy + Syyy
    M[1,4] = Sxx + Syy
    M[2,1] = M[1,2]
    M[2,2] = Sxx
    M[2,3] = Sxy
    M[2,4] = Sx
    M[3,1] = M[1,3]
    M[3,2] = M[2,3]
    M[3,3] = Syy
    M[3,4] = Sy
    M[4,1] = M[1,4]
    M[4,2] = M[2,4]
    M[4,3] = M[3,4]
    M[4,4] = T(n)
    
    # Build constraint matrix B (4x4)
    # Constraint: A² + B² - 4C = 1
    B = zeros(T, 4, 4)
    B[2,2] = 1.0
    B[3,3] = 1.0
    B[4,4] = -4.0
    
    # Solve generalized eigenvalue problem: M*v = λ*B*v
    try
        F = eigen(Symmetric(M), Symmetric(B))
        
        # Find smallest positive eigenvalue
        min_idx = 1
        min_val = Inf
        for i in 1:4
            if F.values[i] > 0 && F.values[i] < min_val
                min_val = F.values[i]
                min_idx = i
            end
        end
        
        # Extract eigenvector
        v = F.vectors[:, min_idx]
        A_coef, B_coef, C_coef = v[2], v[3], v[4]
        
        # Extract circle parameters
        xc = -A_coef / 2
        yc = -B_coef / 2
        val = (A_coef^2 + B_coef^2) / 4 - C_coef
        
        if val > 0
            R = sqrt(val)
        else
            # Fallback
            xc = Sx / n
            yc = Sy / n
            R = sqrt(max(0, (Sxx + Syy) / n - xc^2 - yc^2))
        end
        
        return SVector{3,T}(xc, yc, R)
        
    catch
        # Fallback to centroid-based estimate
        xc = Sx / n
        yc = Sy / n
        R = sqrt(max(0, (Sxx + Syy) / n - xc^2 - yc^2))
        return SVector{3,T}(xc, yc, R)
    end
end

#2.fit_circle_ls
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
                       skip_validation::Bool=false, kwargs...) where T<:Real
    validate_input(x, y; skip_validation=skip_validation)
    
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
