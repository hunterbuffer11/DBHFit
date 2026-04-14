"""
    DBHFit

专业的胸径(DBH)拟合Julia包，提供多种圆拟合算法用于林业点云数据处理。

# 主要功能

- 三种拟合算法: 最小二乘法(LS)、Levenberg-Marquardt(LM)、RANSAC
- 统一API: fit_dbh 函数提供统一接口
- 可选可视化: 支持Plots.jl可视化结果

详细信息请查看README.md文档。
"""
module DBHFit

using LinearAlgebra
using StaticArrays
using Statistics
using Random
using Hyperopt

# 导出公共API
"""
    plot_fit(x, y, result; kwargs...)

绘制拟合结果可视化图形。

需要加载 Plots.jl 包才能使用此功能：
```julia
using Plots
using DBHFit
result = fit_dbh(x, y; method=:ls)
plot_fit(x, y, result)
```
"""
function plot_fit end

# 导出公共API
export CircleFitResult, Point2D, FitConfig
export fit_dbh, fit_circle_ls, fit_circle_lm, fit_circle_ransac
export plot_fit
export calculate_rmse, calculate_mae
export validate_input

# 包含源文件
include("types.jl")
include("utils.jl")
include("algebraic.jl")
include("lm.jl")
include("ransac.jl")

"""
    fit_dbh(x::AbstractVector, y::AbstractVector; method, skip_validation=false, kwargs...) -> CircleFitResult
    fit_dbh(points::AbstractVector{<:Point2D}; method, skip_validation=false, kwargs...) -> CircleFitResult
    fit_dbh(x, y, config::FitConfig) -> CircleFitResult

统一的胸径拟合入口函数。

# 参数

- `x, y`: 点的坐标向量
- `points`: Point2D向量
- `config`: FitConfig配置对象
- `method`: 拟合方法，**必须指定**，可选 :ls, :lm, :ransac
- `skip_validation`: 是否跳过输入验证（默认false，设为true可提高处理速度）
- `kwargs...`: 传递给具体拟合方法的参数

# 返回

- `CircleFitResult`: 包含圆心、半径、胸径等信息的结构体

# 示例

```julia
# LS方法
result = fit_dbh(x, y; method=:ls)

# LM方法
result = fit_dbh(x, y; method=:lm, robust=true)

# RANSAC方法（必须指定参数）
result = fit_dbh(x, y; method=:ransac, max_trials=200, min_inliers=50)

# 跳过验证以提高速度（数据已预处理时）
result = fit_dbh(x, y; method=:ls, skip_validation=true)
```
"""
function fit_dbh(x::AbstractVector{T}, y::AbstractVector{T}; 
                 method::Union{Symbol,Nothing}=nothing,
                 skip_validation::Bool=false,
                 kwargs...) where T<:Real
    # 验证输入
    validate_input(x, y; skip_validation=skip_validation)
    
    # method 必须指定
    if method === nothing
        throw(ArgumentError("必须指定 method 参数。可选: :ls, :lm, :ransac"))
    end
    
    # 调用具体的拟合方法（已验证，跳过子函数验证）
    if method == :ls
        return fit_circle_ls(x, y; skip_validation=true, kwargs...)
    elseif method == :lm
        return fit_circle_lm(x, y; skip_validation=true, kwargs...)
    elseif method == :ransac
        return fit_circle_ransac(x, y; skip_validation=true, kwargs...)
    else
        throw(ArgumentError("未知的拟合方法: $(method)。可选: :ls, :lm, :ransac"))
    end
end

function fit_dbh(points::AbstractVector{<:Point2D}; kwargs...)
    x = [p.x for p in points]
    y = [p.y for p in points]
    return fit_dbh(x, y; kwargs...)
end

function fit_dbh(x::AbstractVector{T}, y::AbstractVector{T}, 
                 config::FitConfig) where T<:Real
    kwargs = Dict{Symbol,Any}()
    config.robust !== nothing && (kwargs[:robust] = config.robust)
    config.max_iter !== nothing && (kwargs[:max_iter] = config.max_iter)
    config.threshold !== nothing && (kwargs[:threshold] = config.threshold)
    config.min_inliers !== nothing && (kwargs[:min_inliers] = config.min_inliers)
    config.max_trials !== nothing && (kwargs[:max_trials] = config.max_trials)
    
    return fit_dbh(x, y; method=config.method, kwargs...)
end

end # module
