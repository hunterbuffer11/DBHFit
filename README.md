# DBHFit.jl

[![Build Status](https://github.com/yourusername/DBHFit.jl/workflows/CI/badge.svg)](https://github.com/yourusername/DBHFit.jl/actions)
[![Coverage](https://codecov.io/gh/yourusername/DBHFit.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/yourusername/DBHFit.jl)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

专业的胸径(DBH)拟合Julia包，提供多种圆拟合算法用于林业点云数据处理。

## 功能特性

- **三种拟合算法**:
  - 最小二乘法 (LS) - 快速，适合初值估计
  - Levenberg-Marquardt (LM) - 鲁棒，精度高
  - RANSAC - 抗离群点，适合噪声数据

- **统一API**: `fit_dbh` 函数提供统一接口
- **自动方法选择**: 根据数据特征自动选择最优算法
- **可选可视化**: 支持Plots.jl可视化结果
- **扩展支持**: 可选集成PointCloudUtils包

## 安装

```julia
using Pkg
Pkg.add("DBHFit")
```

或从GitHub安装开发版本：

```julia
using Pkg
Pkg.add(url="https://github.com/yourusername/DBHFit.jl")
```

## 快速开始

### 基础用法

```julia
using DBHFit

# 准备数据
x = [0.0, 1.0, 0.0, -1.0]
y = [1.0, 0.0, -1.0, 0.0]

# 自动选择方法拟合
result = fit_dbh(x, y)

# 查看结果
println("圆心: ($(result.center_x), $(result.center_y))")
println("半径: $(result.radius)")
println("胸径: $(result.dbh)")
println("误差: $(result.rmse)")
```

### 指定拟合方法

```julia
# 最小二乘法
result_ls = fit_dbh(x, y; method=:ls)

# Levenberg-Marquardt
result_lm = fit_dbh(x, y; method=:lm, max_iter=100, robust=true)

# RANSAC
result_ransac = fit_dbh(x, y; method=:ransac, threshold=0.02)
```

### 使用Point2D数据结构

```julia
points = [Point2D(0.0, 1.0), Point2D(1.0, 0.0), 
         Point2D(0.0, -1.0), Point2D(-1.0, 0.0)]
result = fit_dbh(points)
```

### 使用配置对象

```julia
config = FitConfig(method=:lm, max_iter=100, robust=true)
result = fit_dbh(x, y, config)
```

## API参考

### 主要函数

#### `fit_dbh(x, y; method=:auto, kwargs...)`

统一的胸径拟合入口函数。

**参数:**
- `x, y`: 点的坐标向量
- `method`: 拟合方法 (`:ls`, `:lm`, `:ransac`, `:auto`)
- `kwargs...`: 传递给具体方法的参数

**返回:**
- `CircleFitResult`: 拟合结果

#### `fit_circle_ls(x, y; preprocess=false)`

最小二乘法拟合。

#### `fit_circle_lm(x, y; max_iter=50, tol=1e-8, robust=true, huber_threshold=4.685)`

Levenberg-Marquardt优化拟合。

**参数:**
- `max_iter`: 最大迭代次数
- `tol`: 收敛容差
- `robust`: 是否使用Huber鲁棒权重
- `huber_threshold`: Huber阈值系数（默认4.685）

#### `fit_circle_ransac(x, y; max_trials=100, threshold=0.01, min_inliers=nothing, optimize=false, optimize_metric=:rmse) -> CircleFitResult`

RANSAC拟合。

**参数:**
- `max_trials`: 最大迭代次数
- `threshold`: 内点判定阈值
- `min_inliers`: 最小内点数
- `optimize`: 是否自动优化参数（默认false，需要Hyperopt）
- `optimize_metric`: 优化指标（默认:rmse，可选:mae）

**示例:**
```julia
# 手动指定参数
result = fit_circle_ransac(x, y; threshold=0.02, max_trials=200)

# 自动优化参数（需要安装Hyperopt）
using Pkg
Pkg.add("Hyperopt")
using DBHFit, Hyperopt
result = fit_circle_ransac(x, y; optimize=true)

# 自动优化参数 - MAE指标
result = fit_circle_ransac(x, y; optimize=true, optimize_metric=:mae)
```

### 数据类型

#### `CircleFitResult`

拟合结果结构体。

**字段:**
- `center_x, center_y`: 圆心坐标
- `radius`: 半径
- `dbh`: 胸径（直径）
- `rmse`: 拟合误差
- `inliers`: 内点数量
- `method`: 拟合方法

#### `Point2D`

二维点数据结构。

#### `FitConfig`

拟合配置参数。

### 工具函数

#### `calculate_rmse(x, y, center_x, center_y, radius)`

计算均方根误差。

#### `calculate_mae(x, y, center_x, center_y, radius)`

计算平均绝对误差。

## 可选扩展

### 可视化支持

安装Plots.jl后可使用可视化功能：

```julia
using Pkg
Pkg.add("Plots")

using DBHFit
using Plots

result = fit_dbh(x, y)
plot_fit(x, y, result)
```

### PointCloudUtils集成

安装PointCloudUtils后可直接处理点云数据：

```julia
using Pkg
Pkg.add("PointCloudUtils")

using DBHFit
using PointCloudUtils

# 加载点云
pc = load_pointcloud("tree.csv")

# 提取DBH区域并拟合
result = fit_dbh(pc; height_range=(1.2, 1.4))
```

## 数据验证

DBHFit.jl 提供了严格的数据验证，确保输入数据的有效性：

**自动检查项：**
1. ✅ 长度是否相同
2. ✅ 至少3个点
3. ✅ 是否包含NaN值
4. ✅ 是否包含Inf值
5. ✅ 是否所有点重合
6. ✅ 是否所有点共线

**错误提示示例：**
```julia
# 长度不匹配
julia> fit_dbh([1.0, 2.0], [1.0])
ERROR: ArgumentError: x和y的长度必须相同（x: 2, y: 1）

# 点数不足
julia> fit_dbh([1.0, 2.0], [1.0, 2.0])
ERROR: ArgumentError: 至少需要3个点才能拟合圆（当前: 2个点）

# 所有点共线
julia> fit_dbh([0.0, 1.0, 2.0], [0.0, 1.0, 2.0])
ERROR: ArgumentError: 所有点共线，无法拟合圆
```

## 性能优化

- 使用 `@inbounds` 优化循环
- 使用 `StaticArrays` 优化小矩阵运算
- 类型稳定，支持泛型
- LM方法使用栈分配减少内存开销

## 算法说明

### 最小二乘法 (LS)

使用Kåsa代数方法，通过最小化代数距离求解圆参数。速度快，但对噪声敏感，适合作为初值或对精度要求不高的场景。

### Levenberg-Marquardt (LM)

使用LM算法优化几何距离，精度高，收敛快。支持Huber鲁棒权重，可减少离群点影响。

### RANSAC

随机采样一致性算法，通过随机采样和内点检测拟合圆。对离群点鲁棒，适合噪声较大的数据。

## 示例

查看 `examples/` 目录获取更多示例：

- `basic_usage.jl` - 基础使用示例
- `advanced.jl` - 高级用法示例

## 开发

### 运行测试

```julia
using Pkg
Pkg.test("DBHFit")
```

### 代码格式化

```julia
using JuliaFormatter
format("src/")
```

## 贡献

欢迎提交Issue和Pull Request！

1. Fork本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启Pull Request

## 许可证

本项目采用MIT许可证 - 详见 [LICENSE](LICENSE) 文件

## 作者

Hunter

## 致谢

感谢Julia社区和所有贡献者！
