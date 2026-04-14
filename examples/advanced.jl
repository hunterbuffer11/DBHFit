# DBHFit.jl 高级用法示例

using DBHFit
using Random
using Statistics

println("="^60)
println("DBHFit.jl 高级用法示例")
println("="^60)

# ========== 1. 性能对比 ==========
println("\n1. 三种方法的性能对比")
println("-"^60)

Random.seed!(1234)

# 生成不同规模的数据集
for n in [100, 500, 1000]
    println("\n数据规模: $n 个点")
    
    θ = LinRange(0, 2π, n)[1:end-1]
    x = cos.(θ) .+ 0.01 * randn(length(θ))
    y = sin.(θ) .+ 0.01 * randn(length(θ))
    
    # LS
    t_ls = @elapsed result_ls = fit_circle_ls(x, y)
    
    # LM
    t_lm = @elapsed result_lm = fit_circle_lm(x, y)
    
    # RANSAC
    t_ransac = @elapsed result_ransac = fit_circle_ransac(x, y)
    
    println("  LS:     时间=$(round(t_ls*1000, digits=2))ms, RMSE=$(round(result_ls.rmse, digits=6))")
    println("  LM:     时间=$(round(t_lm*1000, digits=2))ms, RMSE=$(round(result_lm.rmse, digits=6))")
    println("  RANSAC: 时间=$(round(t_ransac*1000, digits=2))ms, RMSE=$(round(result_ransac.rmse, digits=6))")
end

# ========== 2. 参数调优 ==========
println("\n2. LM方法参数调优")
println("-"^60)

Random.seed!(1234)
θ = LinRange(0, 2π, 200)[1:end-1]
x = cos.(θ) .+ 0.02 * randn(length(θ))
y = sin.(θ) .+ 0.02 * randn(length(θ))

# 测试不同的收敛容差
println("\n不同收敛容差:")
for tol in [1e-6, 1e-8, 1e-10]
    result = fit_circle_lm(x, y; tol=tol)
    println("  tol=$tol: RMSE=$(round(result.rmse, digits=8))")
end

# 测试鲁棒拟合
println("\n鲁棒拟合 vs 普通拟合:")
x_noisy = copy(x)
y_noisy = copy(y)
x_noisy[1:10] .= 3.0  # 添加离群点
y_noisy[1:10] .= 3.0

result_normal = fit_circle_lm(x_noisy, y_noisy; robust=false)
result_robust = fit_circle_lm(x_noisy, y_noisy; robust=true)

println("  普通拟合: 半径=$(round(result_normal.radius, digits=4)), RMSE=$(round(result_normal.rmse, digits=6))")
println("  鲁棒拟合: 半径=$(round(result_robust.radius, digits=4)), RMSE=$(round(result_robust.rmse, digits=6))")

# ========== 3. RANSAC参数优化 ==========
println("\n3. RANSAC参数优化")
println("-"^60)

Random.seed!(1234)
θ = LinRange(0, 2π, 300)[1:end-1]
x = cos.(θ) .+ 0.01 * randn(length(θ))
y = sin.(θ) .+ 0.01 * randn(length(θ))

# 添加离群点
x[1:30] .= rand(30) .* 3
y[1:30] .= rand(30) .* 3

println("数据包含30个离群点（共$(length(x))个点）")

# 测试不同的阈值
println("\n不同内点阈值:")
for threshold in [0.01, 0.02, 0.05]
    result = fit_circle_ransac(x, y; threshold=threshold, max_trials=500)
    println("  threshold=$threshold: 内点=$(result.inliers), 半径=$(round(result.radius, digits=4))")
end

# 测试不同的迭代次数
println("\n不同迭代次数:")
for max_trials in [100, 300, 500, 1000]
    result = fit_circle_ransac(x, y; threshold=0.02, max_trials=max_trials)
    println("  max_trials=$max_trials: 内点=$(result.inliers), 半径=$(round(result.radius, digits=4))")
end

# ========== 4. 批量处理 ==========
println("\n4. 批量处理多棵树")
println("-"^60)

Random.seed!(1234)

# 模拟多棵树的数据
num_trees = 5
results = CircleFitResult[]

for i in 1:num_trees
    # 生成随机半径的圆
    true_radius = 0.1 + 0.2 * rand()
    true_center_x = rand() * 2
    true_center_y = rand() * 2
    
    θ = LinRange(0, 2π, 150)[1:end-1]
    x = true_center_x .+ true_radius * cos.(θ) .+ 0.005 * randn(length(θ))
    y = true_center_y .+ true_radius * sin.(θ) .+ 0.005 * randn(length(θ))
    
    result = fit_dbh(x, y)
    push!(results, result)
    
    println("树 $i: 真实半径=$(round(true_radius, digits=3)), 拟合半径=$(round(result.radius, digits=3)), " *
            "误差=$(round(abs(result.radius - true_radius), digits=5))")
end

# 统计结果
radii = [r.radius for r in results]
println("\n统计结果:")
println("  平均半径: $(round(mean(radii), digits=4))")
println("  半径标准差: $(round(std(radii), digits=4))")
println("  最小半径: $(round(minimum(radii), digits=4))")
println("  最大半径: $(round(maximum(radii), digits=4))")

# ========== 5. 误差分析 ==========
println("\n5. 误差分析")
println("-"^60)

Random.seed!(1234)
θ = LinRange(0, 2π, 200)[1:end-1]

# 测试不同噪声水平
println("\n不同噪声水平下的拟合精度:")
for noise_level in [0.001, 0.005, 0.01, 0.02]
    x = cos.(θ) .+ noise_level * randn(length(θ))
    y = sin.(θ) .+ noise_level * randn(length(θ))
    
    result = fit_dbh(x, y)
    println("  噪声=$noise_level: RMSE=$(round(result.rmse, digits=6)), " *
            "半径误差=$(round(abs(result.radius - 1.0), digits=6))")
end

println("\n" * "="^60)
println("高级示例完成!")
println("="^60)
