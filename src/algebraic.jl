"""
    algebraic_initial_guess(x, y) -> SVector{3}

Compute initial estimate of a circle using the algebraic method (Kåsa method)
:lm method will use the function to calculate the initial guess of circle parameters.

# Parameters

- `x, y`: Coordinate vectors of points

# Returns

- `SVector{3}`: [center_x, center_y, radius]

# Algorithm

Uses the Kåsa algebraic method to solve for circle parameters by minimizing the algebraic distance.
"""
function algebraic_initial_guess(x::AbstractVector{T}, 
                                 y::AbstractVector{T}) where T<:Real
    n = length(x)
    
    # Calculate centroid
    mx = sum(x) / n
    my = sum(y) / n
    
    # Centered coordinates
    u = x .- mx
    v = y .- my
    
    # Calculate sums for the linear system
    Suu = sum(u.^2)
    Svv = sum(v.^2)
    Suv = sum(u .* v)
    Suuu = sum(u.^3)
    Svvv = sum(v.^3)
    Suvv = sum(u .* v.^2)
    Svuu = sum(v .* u.^2)
    
    # Construct a system of linear equations
    A = SMatrix{2,2,T}(Suu, Suv, Suv, Svv)
    b = SVector{2,T}(0.5 * (Suuu + Suvv), 0.5 * (Svvv + Svuu))
    
    # solve the linear system
    uc, vc = A \ b
    
    xc = uc + mx
    yc = vc + my
    r = sqrt(uc^2 + vc^2 + (Suu + Svv) / n)
    
    return SVector{3,T}(xc, yc, r)
end

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
    # Validate input
    validate_input(x, y; skip_validation=skip_validation)
    
    n = length(x)
    
    # Validate input
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
