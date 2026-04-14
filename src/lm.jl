"""
    residual_and_jacobian_row(xi, yi, p)

计算单个点的残差和雅可比行向量。

# 参数

- `xi, yi`: 点的坐标
- `p`: 参数向量 [center_x, center_y, radius]

# 返回

- `Tuple{Float64, SVector{3}}`: (残差, 雅可比行向量)
"""
@inline function residual_and_jacobian_row(xi::T, yi::T, 
                                           p::SVector{3,T}) where T<:Real
    xc, yc, R = p
    dx = xi - xc
    dy = yi - yc
    dist = sqrt(dx*dx + dy*dy)
    
    if dist < eps(T)
        return zero(T), SVector{3,T}(zero(T), zero(T), -one(T))
    end
    
    inv_dist = one(T) / dist
    r = dist - R
    J_row = SVector{3,T}(-dx * inv_dist, -dy * inv_dist, -one(T))
    
    return r, J_row
end

"""
    huber_weight(r, c)

计算Huber鲁棒权重。

# 参数

- `r`: 残差向量
- `c`: 阈值参数

# 返回

- `Vector{Float64}`: 权重向量
"""
function huber_weight(r::AbstractVector{T}, c::Real) where T<:Real
    return @. ifelse(abs(r) <= c, one(T), T(c / abs(r)))
end

"""
    fit_circle_lm(x, y; max_iter=50, robust=true, huber_threshold=4.685, skip_validation=false) -> CircleFitResult

使用Levenberg-Marquardt算法拟合圆。

# 参数

- `x, y`: 点的坐标向量
- `max_iter`: 最大迭代次数（默认50）
- `robust`: 是否使用Huber鲁棒权重（默认true）
- `huber_threshold`: Huber阈值系数（默认4.685）
- `skip_validation`: 是否跳过输入验证（默认false）

# 返回

- `CircleFitResult`: 拟合结果

# 算法

1. 使用代数方法作为初值
2. 迭代优化参数
3. 可选的Huber鲁棒权重减少离群点影响
"""
function fit_circle_lm(x::AbstractVector{T}, y::AbstractVector{T}; 
                       max_iter::Int=50,  
                       robust::Bool=true,
                       huber_threshold::Real=4.685,
                       skip_validation::Bool=false,
                       kwargs...) where T<:Real
    # 验证输入
    validate_input(x, y; skip_validation=skip_validation)
    
    n = length(x)
    
    # 使用代数方法作为初值
    p = algebraic_initial_guess(x, y)

    tol = 1e-5
    λ = 1e-3
    ν = 2.0
    
    # 预分配残差向量
    r = Vector{T}(undef, n)
    
    # 计算初始残差
    for i in 1:n
        ri, _ = residual_and_jacobian_row(x[i], y[i], p)
        r[i] = ri
    end
    
    # 计算Huber阈值
    if robust
        mad = 4.685 * median(abs.(r))
        w = huber_weight(r, mad)
        r = w .* r
    end
    
    err = sum(r.^2)
    
    # LM迭代
    for iter in 1:max_iter
        # 累加Hessian和梯度
        H = MMatrix{3,3,T,9}(zeros(T, 3, 3))
        g = MVector{3,T}(zeros(T, 3))
        
        for i in 1:n
            ri, Ji = residual_and_jacobian_row(x[i], y[i], p)
            r[i] = ri
            H += Ji * Ji'
            g += Ji * ri
        end
        
        # 阻尼Hessian
        H_damped = H + λ * Diagonal(SVector{3,T}(diag(H)))
        Δp = - H_damped \ g
        
        p_new = p + Δp
        
        # 计算新误差
        err_new = zero(T)
        for i in 1:n
            ri_new, _ = residual_and_jacobian_row(x[i], y[i], p_new)
            err_new += ri_new^2
        end
        
        # 步长接受判断
        if err_new < err
            λ /= ν
            p = p_new
            err = err_new
            if norm(Δp) < tol
                break
            end
        else
            λ *= ν
        end
    end
    
    # 提取结果
    xc, yc, R = p
    
    # 计算最终误差
    rmse = calculate_rmse(x, y, xc, yc, R)
    
    return CircleFitResult(xc, yc, R, rmse, :lm)
end
