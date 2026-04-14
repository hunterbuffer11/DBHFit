"""
    algebraic_initial_guess(x, y) -> SVector{3}

使用代数方法（Kåsa方法）计算圆的初始估计。

# 参数

- `x, y`: 点的坐标向量

# 返回

- `SVector{3}`: [center_x, center_y, radius]

# 算法

使用Kåsa代数方法，通过最小化代数距离求解圆参数。
该方法速度快，但对噪声敏感，适合作为其他方法的初值。
"""
function algebraic_initial_guess(x::AbstractVector{T}, 
                                 y::AbstractVector{T}) where T<:Real
    n = length(x)
    
    # 计算质心
    mx = sum(x) / n
    my = sum(y) / n
    
    # 中心化坐标
    u = x .- mx
    v = y .- my
    
    # 计算累加项
    Suu = sum(u.^2)
    Svv = sum(v.^2)
    Suv = sum(u .* v)
    Suuu = sum(u.^3)
    Svvv = sum(v.^3)
    Suvv = sum(u .* v.^2)
    Svuu = sum(v .* u.^2)
    
    # 构建线性方程组
    A = SMatrix{2,2,T}(Suu, Suv, Suv, Svv)
    b = SVector{2,T}(0.5 * (Suuu + Suvv), 0.5 * (Svvv + Svuu))
    
    # 求解
    uc, vc = A \ b
    
    # 计算圆心和半径
    xc = uc + mx
    yc = vc + my
    r = sqrt(uc^2 + vc^2 + (Suu + Svv) / n)
    
    return SVector{3,T}(xc, yc, r)
end

"""
    fit_circle_ls(x, y; skip_validation=false) -> CircleFitResult

使用最小二乘法拟合圆。

# 参数

- `x, y`: 点的坐标向量
- `skip_validation`: 是否跳过输入验证（默认false）

# 返回

- `CircleFitResult`: 拟合结果

# 算法

使用Kåsa代数方法，通过最小化代数距离求解圆参数。
该方法计算速度快，适合作为初值或对精度要求不高的场景。
"""
function fit_circle_ls(x::AbstractVector{T}, y::AbstractVector{T}; 
                       skip_validation::Bool=false, kwargs...) where T<:Real
    # 验证输入
    validate_input(x, y; skip_validation=skip_validation)
    
    n = length(x)
    
    # 初始化累加器
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
    
    # 构建正规方程
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
    
    # 对称填充
    AtA[2,1] = AtA[1,2]
    AtA[3,1] = AtA[1,3]
    AtA[3,2] = AtA[2,3]
    
    # 求解
    a, b, c = AtA \ Atz
    
    # 计算半径
    val = c + a*a + b*b
    R = val > 0 ? sqrt(val) : zero(T)
    
    # 计算误差
    rmse = calculate_rmse(x, y, a, b, R)
    
    return CircleFitResult(a, b, R, rmse, :ls)
end
