"""
    fit_circle_three_points(x1, y1, x2, y2, x3, y3)

通过三点确定圆。

# 参数

- `x1, y1, x2, y2, x3, y3`: 三个点的坐标

# 返回

- `Tuple{Float64, Float64, Float64}`: (center_x, center_y, radius)
- 如果三点共线，返回 (0.0, 0.0, -1.0)
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

找出圆的内点。

# 参数

- `x, y`: 点的坐标
- `cx, cy, r`: 圆的参数
- `threshold`: 距离阈值

# 返回

- `Tuple{Int, Vector{Int}}`: (内点数量, 内点索引)
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

使用贝叶斯优化（BOHB）自动选择RANSAC参数。
参数范围根据点云数量自动设定。

# 参数

- `x, y`: 点的坐标向量
- `optimize_metric`: 优化指标 (:rmse 或 :mae)
- `n_iterations`: 优化迭代次数

# 返回

- `NamedTuple`: (max_trials, min_inliers, score)
"""
function _optimize_ransac_params_bayesian(x::AbstractVector{T}, y::AbstractVector{T};
                                          optimize_metric::Symbol=:rmse,
                                          n_iterations::Int=100) where T<:Real
    n = length(x)
    
    # 根据点云数量设定参数范围
    max_trials_range = (50, 500)
    min_samples_range = (max(3, ceil(Int, 0.05*n)), max(3, ceil(Int, 0.15*n)))
    
    # 定义损失函数
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
                error("未知的优化指标: $(optimize_metric)")
            end
        catch
            return Inf
        end
    end
    
    # 使用Hyperopt进行贝叶斯优化
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

RANSAC核心算法，不含参数验证和优化逻辑。
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

"""
    fit_circle_ransac(x, y; max_trials=nothing, threshold=0.01, min_inliers=nothing, optimize=false, optimize_metric=:rmse, skip_validation=false) -> CircleFitResult

使用RANSAC算法拟合圆。

# 参数

- `x, y`: 点的坐标向量
- `max_trials`: 最大迭代次数（必须指定或开启optimize）
- `threshold`: 内点判定阈值（默认0.01）
- `min_inliers`: 最小内点数（必须指定或开启optimize）
- `optimize`: 是否自动优化参数（默认false）
- `optimize_metric`: 优化指标（默认:rmse，可选:mae）
- `skip_validation`: 是否跳过输入验证（默认false）

# 返回

- `CircleFitResult`: 拟合结果

# 注意

必须满足以下条件之一：
1. 同时指定 `max_trials` 和 `min_inliers`
2. 设置 `optimize=true` 自动优化参数

# 示例

```julia
# 方式1：手动指定参数
result = fit_circle_ransac(x, y; max_trials=200, min_inliers=50)

# 方式2：自动优化参数
result = fit_circle_ransac(x, y; optimize=true, optimize_metric=:rmse)
```
"""
function fit_circle_ransac(x::AbstractVector{T}, y::AbstractVector{T}; 
                           max_trials::Union{Int,Nothing}=nothing, 
                           threshold::Real=0.01, 
                           min_inliers::Union{Int,Nothing}=nothing,
                           optimize::Bool=false,
                           optimize_metric::Symbol=:rmse,
                           skip_validation::Bool=false,
                           kwargs...) where T<:Real
    # 验证输入
    validate_input(x, y; skip_validation=skip_validation)
    
    n = length(x)
    
    # 参数验证：必须指定参数或开启优化
    if !optimize
        if max_trials === nothing || min_inliers === nothing
            throw(ArgumentError("必须指定 max_trials 和 min_inliers 参数，或设置 optimize=true 自动优化"))
        end
    else
        # 自动优化参数
        opt_params = _optimize_ransac_params_bayesian(x, y; optimize_metric=optimize_metric)
        max_trials = opt_params.max_trials
        min_inliers = opt_params.min_inliers
    end
    
    # 执行RANSAC
    result = _ransac_core(x, y; max_trials=max_trials, threshold=threshold, min_inliers=min_inliers)
    
    if result === nothing
        throw(ErrorException("RANSAC未能找到足够的内点（需要$(min_inliers)个）"))
    end
    
    return result
end
