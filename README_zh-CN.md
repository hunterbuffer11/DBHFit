<div align="center">

# DBHFit.jl

**专业的胸径(DBH)拟合Julia包**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Julia](https://img.shields.io/badge/Julia-1.6+-purple.svg)](https://julialang.org/)

[English](README.md) | 中文文档

提供多种圆拟合算法用于林业点云数据处理

</div>

---

## ✨ 核心特性

- 🎯 **三种拟合算法** - 最小二乘法(LS)、Levenberg-Marquardt(LM)、RANSAC
- 🔧 **统一API** - 单一 `fit_dbh` 函数接口，简单易用
- 🤖 **智能优化** - Hyperopt.jl 自动优化 RANSAC 参数
- 🛡️ **鲁棒拟合** - Huber 权重抵抗离群点
- 📊 **可视化支持** - Plots.jl 可视化扩展

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

### 拟合方法

#### 最小二乘法 (LS)
```julia
result = fit_dbh(x, y; method=:ls)
```
快速代数方法，适合初值估计和高质量数据。

#### Levenberg-Marquardt (LM)
```julia
result = fit_dbh(x, y; method=:lm, max_iter=50, robust=true)
```
高精度拟合，支持 Huber 鲁棒权重，适合一般场景。

#### RANSAC
```julia
# 手动参数
result = fit_dbh(x, y; method=:ransac, max_trials=200, 
                 min_inliers=50, threshold=0.01)

# 自动优化参数
result = fit_dbh(x, y; method=:ransac, optimize=true)
```
对离群点鲁棒，适合噪声数据。

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

### 高级用法

```julia
# Point2D 输入
points = [Point2D(0.0, 1.0), Point2D(1.0, 0.0), 
         Point2D(0.0, -1.0), Point2D(-1.0, 0.0)]
result = fit_dbh(points; method=:ls)

# 配置对象
config = FitConfig(:lm; max_iter=100, robust=true)
result = fit_dbh(x, y, config)

# 可视化
using Plots
result = fit_dbh(x, y; method=:lm)
p = plot_fit(x, y, result)
savefig(p, "fitting_result.png")
```

## ⚙️ 性能优化

- `@inbounds` 优化循环
- `StaticArrays` 优化小矩阵运算
- 类型稳定实现
- LM 方法使用栈分配减少内存开销

## ✅ 数据验证

自动检查输入数据：
- 向量长度相等
- 至少 3 个点
- 无 NaN/Inf 值
- 点不共线
- 点不重合

## 🔧 开发

```julia
# 运行测试
using Pkg
Pkg.activate(".")
Pkg.test()

# 格式化代码
using JuliaFormatter
format("src/")
```

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

## 👤 作者

Hunter

## 🙏 致谢

感谢 Julia 社区和所有贡献者！
