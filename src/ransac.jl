"""
    fit_circle_three_points(x1, y1, x2, y2, x3, y3)

Fit a circle through three points.
"""
function fit_circle_three_points(x1::T, y1::T, x2::T, y2::T, 
                                 x3::T, y3::T) where T<:Real
    a = x1*(y2-y3) + x2*(y3-y1) + x3*(y1-y2)
    
    if abs(a) < 1e-10
        return zero(T), zero(T), -one(T)
    end
    
    b = (x1^2 + y1^2)*(y3 - y2) + (x2^2 + y2^2)*(y1 - y3) + (x3^2 + y3^2)*(y2 - y1)
    c = (x1^2 + y1^2)*(x2 - x3) + (x2^2 + y2^2)*(x3 - x1) + (x3^2 + y3^2)*(x1 - x2)
    
    cx = -b / (2*a)
    cy = -c / (2*a)
    r = sqrt((x1 - cx)^2 + (y1 - cy)^2)
    
    return cx, cy, r
end

"""
    find_inliers(x, y, cx, cy, r, threshold)

Find inliers for a circle.

# Parameters
- `x, y`: Point coordinates
- `cx, cy, r`: Circle parameters
- `threshold`: Distance threshold

# Returns
- `Tuple{Int, Vector{Int}}`: (inlier_count, inlier_indices)
"""
function find_inliers(x::AbstractVector{T}, y::AbstractVector{T}, 
                      cx::Real, cy::Real, r::Real, 
                      threshold::Real) where T<:Real
    n = length(x)
    inliers_idx = Int[]
    
    @inbounds for i in 1:n
        dist = sqrt((x[i] - cx)^2 + (y[i] - cy)^2)
        if abs(dist - r) < threshold
            push!(inliers_idx, i)
        end
    end
    
    return length(inliers_idx), inliers_idx
end

"""
    _optimize_ransac_params_bayesian(x, y; optimize_metric=:rmse, n_iterations=100)

Optimize RANSAC parameters using Bayesian optimization (BOHB).
Parameter ranges are automatically set based on point cloud size.

# Parameters
- `x, y`: Point coordinates
- `optimize_metric`: Optimization metric (:rmse or :mae)
- `n_iterations`: Number of optimization iterations

# Returns
- `NamedTuple`: (max_trials, min_inliers, score)
"""
function _optimize_ransac_params_bayesian(x::AbstractVector{T}, y::AbstractVector{T};
                                          optimize_metric::Symbol=:rmse,
                                          n_iterations::Int=100) where T<:Real
    n = length(x)
    max_trials_range = (20, 300)
    min_samples_range = (max(3, ceil(Int, 0.05*n)), max(3, ceil(Int, 0.15*n)))
    
    function loss_function(max_trials, min_samples)
        try
            result = _ransac_core(x, y; 
                                  max_trials=ceil(Int, max_trials),
                                  min_inliers=ceil(Int, min_samples))
            
            if result === nothing
                return Inf
            end
            
            if optimize_metric == :rmse
                return result.rmse
            elseif optimize_metric == :mae
                return calculate_mae(x, y, result.center_x, result.center_y, result.radius)
            else
                error("Unknown optimization metric: $(optimize_metric)")
            end
        catch
            return Inf
        end
    end
    
    ho = Hyperopt.@hyperopt for i = n_iterations, sampler = Hyperopt.BOHB(),
        max_trials = round.(Int, Hyperopt.exp10.(LinRange(log10(max_trials_range[1]), 
                                                          log10(max_trials_range[2]), 20))),
        min_samples = min_samples_range[1]:min_samples_range[2]
        loss_function(max_trials, min_samples)
    end
    
    best_max_trials = ceil(Int, ho.minimizer[1])
    best_min_samples = ceil(Int, ho.minimizer[2])
    
    return (max_trials=best_max_trials, 
            min_inliers=best_min_samples, 
            score=ho.minimum)
end

"""
    _ransac_core(x, y; max_trials, threshold, min_inliers) -> CircleFitResult or nothing

Core RANSAC algorithm without parameter validation and optimization logic.
"""
function _ransac_core(x::AbstractVector{T}, y::AbstractVector{T};
                      max_trials::Int, 
                      threshold::Real=0.01, 
                      min_inliers::Int) where T<:Real
    n = length(x)
    
    best_inliers = 0
    best_cx, best_cy, best_r = zero(T), zero(T), -one(T)
    best_idx = Int[]
    
    for _ in 1:max_trials
        j1 = rand(1:n)
        j2 = rand(1:n)
        j3 = rand(1:n)
        
        if j1 == j2 || j2 == j3 || j1 == j3
            continue
        end
        
        cx, cy, r = fit_circle_three_points(x[j1], y[j1], x[j2], y[j2], x[j3], y[j3])
        
        if r < 0
            continue
        end
        
        inlier_count, inlier_idx = find_inliers(x, y, cx, cy, r, threshold)
        
        if inlier_count > best_inliers
            best_inliers = inlier_count
            best_cx, best_cy, best_r = cx, cy, r
            best_idx = inlier_idx
        end
    end
    
    if best_inliers < min_inliers
        return nothing
    end
    
    best_x = x[best_idx]
    best_y = y[best_idx]
    
    result_ls = fit_circle_ls(best_x, best_y; skip_validation=true)
    
    rmse = calculate_rmse(x, y, result_ls.center_x, result_ls.center_y, result_ls.radius)
    
    return CircleFitResult(result_ls.center_x, result_ls.center_y, result_ls.radius, 
                          rmse, :ransac)
end

#fit_circle_ransac
"""
    fit_circle_ransac(x, y; max_trials=nothing, threshold=0.01, min_inliers=nothing, optimize=false, optimize_metric=:rmse, skip_validation=false) -> CircleFitResult

Fit a circle using RANSAC algorithm.

# Parameters
- `x, y`: Point coordinates
- `max_trials`: Maximum number of iterations (must specify or enable optimize)
- `threshold`: Inlier distance threshold (default 0.01)
- `min_inliers`: Minimum number of inliers (must specify or enable optimize)
- `optimize`: Whether to auto-optimize parameters (default false)
- `optimize_metric`: Optimization metric (default :rmse, optional :mae)
- `skip_validation`: Whether to skip input validation (default false)

# Returns
- `CircleFitResult`: Fitting result

# Notes
Must satisfy one of:
1. Specify both `max_trials` and `min_inliers`
2. Set `optimize=true` to auto-optimize parameters
"""
function fit_circle_ransac(x::AbstractVector{T}, y::AbstractVector{T}; 
                           max_trials::Union{Int,Nothing}=nothing, 
                           threshold::Real=0.01, 
                           min_inliers::Union{Int,Nothing}=nothing,
                           optimize::Bool=false,
                           optimize_metric::Symbol=:rmse,
                           kwargs...) where T<:Real
    n = length(x)
    
    if !optimize
        if max_trials === nothing || min_inliers === nothing
            throw(ArgumentError("Must specify max_trials and min_inliers, or set optimize=true"))
        end
    else
        opt_params = _optimize_ransac_params_bayesian(x, y; optimize_metric=optimize_metric)
        max_trials = opt_params.max_trials
        min_inliers = opt_params.min_inliers
    end
    
    result = _ransac_core(x, y; max_trials=max_trials, threshold=threshold, min_inliers=min_inliers)
    
    if result === nothing
        throw(ErrorException("RANSAC failed to find enough inliers (need $(min_inliers))"))
    end
    
    return result
end
