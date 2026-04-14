# DBHFit.jl

[![Build Status](https://github.com/hunterbuffer11/DBHFit.jl/workflows/CI/badge.svg)](https://github.com/hunterbuffer11/DBHFit.jl/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**[English Documentation](README.md)**

专业的胸径(DBH)拟合Julia包，提供多种圆拟合算法用于林业点云数据处理。

## 功能特性

- **三种拟合算法**: 最小二乘法(LS)、Levenberg-Marquardt(LM)、RANSAC
- **统一API**: 单一 `fit_dbh` 函数接口
- **贝叶斯优化**: 使用 Hyperopt.jl 自动优化 RANSAC 参数
- **鲁棒拟合**: Huber 权重抵抗离群点
- **可选扩展**: Plots.jl 可视化、PointCloudUtils 集成

## 安装

```julia
using Pkg
Pkg.add(url="https://github.com/hunterbuffer11/DBHFit.jl")
```

## 快速开始

```julia
using DBHFit

x = [0.0, 1.0, 0.0, -1.0]
y = [1.0, 0.0, -1.0, 0.0]

# 必须指定方法
result = fit_dbh(x, y; method=:ls)

println("圆心: ($(result.center_x), $(result.center_y))")
println("半径: $(result.radius)")
println("胸径: $(result.dbh)")
```

## API 参考

### 主函数

```julia
fit_dbh(x, y; method, kwargs...) -> CircleFitResult
```

**参数:**
- `x, y`: 点坐标
- `method`: 拟合方法 (**必须指定**: `:ls`、`:lm` 或 `:ransac`)
- `skip_validation`: 跳过输入验证以提高速度 (默认: `false`)

### 拟合方法

#### 最小二乘法 (LS)
```julia
result = fit_dbh(x, y; method=:ls)
```
快速代数方法，适合初值估计。

#### Levenberg-Marquardt (LM)
```julia
result = fit_dbh(x, y; method=:lm, max_iter=50, robust=true, huber_threshold=4.685)
```
高精度拟合，支持 Huber 鲁棒权重。

#### RANSAC
```julia
# 手动指定参数
result = fit_dbh(x, y; method=:ransac, max_trials=200, min_inliers=50, threshold=0.01)

# 自动优化参数 (需要 Hyperopt)
result = fit_dbh(x, y; method=:ransac, optimize=true, optimize_metric=:rmse)
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
    method::Symbol # 使用的拟合方法
end
```

## 示例

### Point2D 输入
```julia
points = [Point2D(0.0, 1.0), Point2D(1.0, 0.0), 
         Point2D(0.0, -1.0), Point2D(-1.0, 0.0)]
result = fit_dbh(points; method=:ls)
```

### 配置对象
```julia
config = FitConfig(:lm; max_iter=100, robust=true)
result = fit_dbh(x, y, config)
```

### 可视化
```julia
using Plots
using DBHFit

result = fit_dbh(x, y; method=:lm)
p = plot_fit(x, y, result)
savefig(p, "fitting_result.png")
```

## 性能优化

- `@inbounds` 优化循环
- `StaticArrays` 优化小矩阵运算
- 类型稳定实现
- LM 方法使用栈分配减少内存开销

## 数据验证

自动检查:
- ✅ 向量长度相等
- ✅ 至少 3 个点
- ✅ 无 NaN/Inf 值
- ✅ 点不共线
- ✅ 点不重合

## 开发

```julia
# 运行测试
using Pkg
Pkg.activate(".")
Pkg.test()

# 格式化代码
using JuliaFormatter
format("src/")
```

## 许可证

MIT 许可证 - 详见 [LICENSE](LICENSE) 文件。

## 作者

Hunter

## 致谢

感谢 Julia 社区和所有贡献者！
