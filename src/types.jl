"""
    CircleFitResult{T<:Real}

圆拟合结果，包含圆心、半径和拟合质量信息。

# 字段

- `center_x::T`: 圆心X坐标
- `center_y::T`: 圆心Y坐标
- `radius::T`: 圆的半径
- `dbh::T`: 胸径（直径，等于2*radius）
- `rmse::T`: 拟合误差（均方根误差）
- `method::Symbol`: 拟合方法（:ls, :lm, :ransac）
"""
struct CircleFitResult{T<:Real}
    center_x::T
    center_y::T
    radius::T
    dbh::T
    rmse::T
    method::Symbol
end

"""
    CircleFitResult(center_x, center_y, radius, rmse, inliers, method)

构造CircleFitResult，自动计算dbh。
"""
function CircleFitResult(center_x::T, center_y::T, radius::T, 
                         rmse::T, method::Symbol) where T<:Real
    return CircleFitResult{T}(center_x, center_y, radius, 2*radius, rmse, method)
end

"""
    Point2D{T<:Real}

二维点数据结构。

# 字段

- `x::T`: X坐标
- `y::T`: Y坐标
"""
struct Point2D{T<:Real}
    x::T
    y::T
end

"""
    FitConfig

拟合配置参数。

# 字段

- `method::Symbol`: 拟合方法（:ls, :lm, :ransac）**必须指定**
- `robust::Union{Bool,Nothing}`: 是否使用鲁棒拟合
- `max_iter::Union{Int,Nothing}`: 最大迭代次数
- `threshold::Union{Float64,Nothing}`: RANSAC阈值
- `min_inliers::Union{Int,Nothing}`: 最小内点数
- `max_trials::Union{Int,Nothing}`: RANSAC最大迭代次数
"""
struct FitConfig
    method::Symbol
    robust::Union{Bool,Nothing}
    max_iter::Union{Int,Nothing}
    threshold::Union{Float64,Nothing}
    min_inliers::Union{Int,Nothing}
    max_trials::Union{Int,Nothing}
end

"""
    FitConfig(method; robust=nothing, max_iter=nothing, threshold=nothing, 
              min_inliers=nothing, max_trials=nothing)

构造FitConfig，method参数必须指定。
"""
function FitConfig(method::Symbol; 
                    robust::Union{Bool,Nothing}=nothing,
                    max_iter::Union{Int,Nothing}=nothing,
                    threshold::Union{Float64,Nothing}=nothing,
                    min_inliers::Union{Int,Nothing}=nothing,
                    max_trials::Union{Int,Nothing}=nothing)
    return FitConfig(method, robust, max_iter, threshold, min_inliers, max_trials)
end
