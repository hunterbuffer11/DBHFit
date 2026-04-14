"""
    validate_input(x, y; skip_validatio=false)

验证输入数据的有效性。

# 参数

- `x, y`: 坐标向量
- `skip_validation`: 是否跳过验证（默认false）

# 异常

- `ArgumentError`: 当输入无效时抛出

# 检查项

1. 长度是否相同
2. 至少3个点
3. 是否包含NaN
4. 是否包含Inf
5. 是否所有点共线
6. 是否所有点重合
"""
function validate_input(x::AbstractVector, y::AbstractVector; skip_validation::Bool=false)
    if skip_validation
        return true
    end
    
    # 检查长度
    if length(x) != length(y)
        throw(ArgumentError("x和y的长度必须相同（x: $(length(x)), y: $(length(y)))"))
    end
    
    # 检查点数
    if length(x) < 3
        throw(ArgumentError("至少需要3个点才能拟合圆（当前: $(length(x))个点）"))
    end
    
    # 检查NaN
    nan_x = count(isnan, x)
    nan_y = count(isnan, y)
    if nan_x > 0 || nan_y > 0
        throw(ArgumentError("输入数据包含NaN值（x: $(nan_x)个, y: $(nan_y)个）"))
    end
    
    # 检查Inf
    inf_x = count(isinf, x)
    inf_y = count(isinf, y)
    if inf_x > 0 || inf_y > 0
        throw(ArgumentError("输入数据包含Inf值（x: $(inf_x)个, y: $(inf_y)个）"))
    end
    
    # 检查是否所有点重合
    if all(x .≈ x[1]) && all(y .≈ y[1])
        throw(ArgumentError("所有点重合，无法拟合圆"))
    end
    
    # 检查是否所有点共线
    if _are_collinear(x, y)
        throw(ArgumentError("所有点共线，无法拟合圆"))
    end
    
    return true
end

"""
    _are_collinear(x, y)

检查点是否共线。
"""
function _are_collinear(x::AbstractVector, y::AbstractVector)
    n = length(x)
    if n < 3
        return false
    end
    
    # 使用前三个点计算共线性
    x1, y1 = x[1], y[1]
    x2, y2 = x[2], y[2]
    
    for i in 3:n
        x3, y3 = x[i], y[i]
        # 计算三角形面积（叉积）
        area = abs((x2-x1)*(y3-y1) - (x3-x1)*(y2-y1))
        # 使用相对阈值，避免数值精度问题
        scale = max(abs(x2-x1) + abs(y2-y1), abs(x3-x1) + abs(y3-y1), 1e-10)
        if area / scale > 1e-8
            return false
        end
    end
    
    return true
end

"""
    calculate_rmse(x, y, center_x, center_y, radius)

计算拟合的均方根误差。

# 参数

- `x, y`: 点的坐标
- `center_x, center_y, radius`: 圆的参数

# 返回

- `Float64`: RMSE值
"""
function calculate_rmse(x::AbstractVector{T}, y::AbstractVector{T}, 
                        center_x::Real, center_y::Real, radius::Real) where T<:Real
    n = length(x)
    sum_sq = zero(T)
    @inbounds for i in 1:n
        dist = sqrt((x[i] - center_x)^2 + (y[i] - center_y)^2)
        sum_sq += (dist - radius)^2
    end
    return sqrt(sum_sq / n)
end

"""
    calculate_mae(x, y, center_x, center_y, radius)

计算拟合的平均绝对误差。

# 参数

- `x, y`: 点的坐标
- `center_x, center_y, radius`: 圆的参数

# 返回

- `Float64`: MAE值
"""
function calculate_mae(x::AbstractVector{T}, y::AbstractVector{T}, 
                       center_x::Real, center_y::Real, radius::Real) where T<:Real
    n = length(x)
    sum_abs = zero(T)
    @inbounds for i in 1:n
        dist = sqrt((x[i] - center_x)^2 + (y[i] - center_y)^2)
        sum_abs += abs(dist - radius)
    end
    return sum_abs / n
end
