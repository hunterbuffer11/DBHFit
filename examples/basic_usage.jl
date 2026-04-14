# DBHFit.jl 使用示例

using DBHFit
using Random

println("="^60)
println("DBHFit.jl 基础使用示例")
println("="^60)

# ========== 1. 生成测试数据 ==========
println("\n1. 生成测试数据（单位圆）")
println("-"^60)

Random.seed!(1234)
θ = LinRange(0, 2π, 100)[1:end-1]
x_perfect = cos.(θ)
y_perfect = sin.(θ)

# 添加噪声
noise = 0.01
x_noisy = x_perfect .+ noise * randn(length(x_perfect))
y_noisy = y_perfect .+ noise * randn(length(y_perfect))

println("生成了 $(length(x_noisy)) 个点")

# ========== 2. 使用不同方法拟合 ==========
println("\n2. 使用不同方法拟合")
println("-"^60)

# 最小二乘法
println("\n最小二乘法 (LS):")
result_ls = fit_circle_ls(x_noisy, y_noisy)
println("  圆心: ($(round(result_ls.center_x, digits=4)), $(round(result_ls.center_y, digits=4)))")
println("  半径: $(round(result_ls.radius, digits=4))")
println("  胸径: $(round(result_ls.dbh, digits=4))")
println("  RMSE: $(round(result_ls.rmse, digits=6))")

# Levenberg-Marquardt
println("\nLevenberg-Marquardt (LM):")
result_lm = fit_circle_lm(x_noisy, y_noisy)
println("  圆心: ($(round(result_lm.center_x, digits=4)), $(round(result_lm.center_y, digits=4)))")
println("  半径: $(round(result_lm.radius, digits=4))")
println("  胸径: $(round(result_lm.dbh, digits=4))")
println("  RMSE: $(round(result_lm.rmse, digits=6))")

# RANSAC
println("\nRANSAC:")
result_ransac = fit_circle_ransac(x_noisy, y_noisy; threshold=0.05)
println("  圆心: ($(round(result_ransac.center_x, digits=4)), $(round(result_ransac.center_y, digits=4)))")
println("  半径: $(round(result_ransac.radius, digits=4))")
println("  胸径: $(round(result_ransac.dbh, digits=4))")
println("  RMSE: $(round(result_ransac.rmse, digits=6))")
println("  内点数: $(result_ransac.inliers)")

# ========== 3. 使用统一API ==========
println("\n3. 使用统一API (自动选择方法)")
println("-"^60)

result_auto = fit_dbh(x_noisy, y_noisy)
println("自动选择的方法: $(result_auto.method)")
println("  圆心: ($(round(result_auto.center_x, digits=4)), $(round(result_auto.center_y, digits=4)))")
println("  半径: $(round(result_auto.radius, digits=4))")

# 指定方法
result_specified = fit_dbh(x_noisy, y_noisy; method=:lm, max_iter=100)
println("\n指定LM方法:")
println("  半径: $(round(result_specified.radius, digits=4))")

# ========== 4. 使用Point2D ==========
println("\n4. 使用Point2D数据结构")
println("-"^60)

points = [Point2D(x_noisy[i], y_noisy[i]) for i in 1:length(x_noisy)]
result_points = fit_dbh(points)
println("从Point2D拟合:")
println("  半径: $(round(result_points.radius, digits=4))")

# ========== 5. 使用FitConfig ==========
println("\n5. 使用FitConfig配置对象")
println("-"^60)

config = FitConfig(method=:ransac, threshold=0.05, max_trials=200)
result_config = fit_dbh(x_noisy, y_noisy, config)
println("使用配置对象拟合:")
println("  方法: $(result_config.method)")
println("  半径: $(round(result_config.radius, digits=4))")

# ========== 6. 处理含离群点的数据 ==========
println("\n6. 处理含离群点的数据")
println("-"^60)

# 添加离群点
x_outliers = copy(x_noisy)
y_outliers = copy(y_noisy)
x_outliers[1:5] .= 5.0  # 离群点
y_outliers[1:5] .= 5.0

println("添加了5个离群点")

# LS方法受离群点影响
result_ls_outlier = fit_circle_ls(x_outliers, y_outliers)
println("\nLS方法（受离群点影响）:")
println("  半径: $(round(result_ls_outlier.radius, digits=4))")
println("  RMSE: $(round(result_ls_outlier.rmse, digits=6))")

# RANSAC方法抗离群点
result_ransac_outlier = fit_circle_ransac(x_outliers, y_outliers; threshold=0.1)
println("\nRANSAC方法（抗离群点）:")
println("  半径: $(round(result_ransac_outlier.radius, digits=4))")
println("  RMSE: $(round(result_ransac_outlier.rmse, digits=6))")
println("  内点数: $(result_ransac_outlier.inliers)")

println("\n" * "="^60)
println("示例完成!")
println("="^60)
