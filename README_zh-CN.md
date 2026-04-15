# DBHFit.jl

**专业的胸径(DBH)拟合Julia包**
[![Julia](https://img.shields.io/badge/Julia-1.6+-purple.svg)](https://julialang.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)


[English](README.md) | 中文文档

提供圆拟合算法用于林业点云中单木胸径以及树干直径的估算。


---

## ✨ 核心特性

- 🎯 **三种拟合算法** - 线性最小二乘法拟合圆(LS)、非线性最小二乘法拟合圆(Levenberg-Marquardt)、RANSAC拟合圆
- 🔧 **统一API** - 单一 `fit_dbh` 函数接口
- 🤖 **RANSAC优化** - 利用Hyperopt包实现贝叶斯优化，为RANSAC提供自动参数
- 📊 **可视化支持** - Plots 可视化扩展

## 📦 安装

```julia
using Pkg
Pkg.add(url="https://github.com/hunterbuffer11/DBHFit.jl")
```

## 🚀 快速开始

```julia
using DBHFit

# 示例数据
x = [0.0, 1.0, 0.0, -1.0]
y = [1.0, 0.0, -1.0, 0.0]

# 使用最小二乘法拟合
result = fit_dbh(x, y; method=:ls)

println("圆心: ($(result.center_x), $(result.center_y))")
println("半径: $(result.radius)")
println("胸径: $(result.dbh)")
```

## 📖 使用指南
更多示例代码请参考 [examples](/examples) 目录。
### 拟合方法

#### 线性最小二乘法 (LS)
```julia
result = fit_dbh(x, y; method=:ls)
```

#### 非线性最小二乘法 (LM)
```julia
result = fit_dbh(x, y; method=:lm, max_iter=50, robust=true)
# 支持 Huber 鲁棒权重。
```

#### RANSAC
```julia
# 手动参数
result = fit_dbh(x, y; method=:ransac, max_trials=200, 
                 min_inliers=50, threshold=0.01)

# 自动优化参数
result = fit_dbh(x, y; method=:ransac, optimize=true)
# 对离群点鲁棒，适合噪声数据。
```

### 结果类型

```julia
struct CircleFitResult
    center_x::T    # 圆心 X 坐标
    center_y::T    # 圆心 Y 坐标
    radius::T      # 半径
    dbh::T         # 胸径 (2 * radius)
    rmse::T        # 均方根误差
    method::Symbol # 拟合方法
end
```

### 其他用法

```julia
# Point2D 输入
points = [Point2D(0.0, 1.0), Point2D(1.0, 0.0), 
         Point2D(0.0, -1.0), Point2D(-1.0, 0.0)]
result = fit_dbh(points; method=:ls)

# 可视化
using Plots
result = fit_dbh(x, y; method=:lm)
p = plot_fit(x, y, result)
savefig(p, "fitting_result.png")
```

## ✅ 数据验证

自动检查输入数据：
- 向量长度是否相等
- 至少 3 个点
- 是否无 NaN/Inf 值
- 点是否共线
- 点是否大量重合

## 👍 推荐方法
- 通常情况下，胸径位置点云质量良好，推荐使用线性最小二乘法 (LS)
- 如果存在过多离群点，推荐使用RANSAC算法。RANSAC参数可以使用贝叶斯优化自动估计。由参数 `optimize=true,optimize_metric = :mae` 控制，其中推荐使用MAE参数而不是RMSE参数，可以提供更稳定的估计。


## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

## 👤 作者

Hunter 

## 🙏 致谢

感谢 Julia 社区和所有贡献者！并欢迎任何指出问题或建议。