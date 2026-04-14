<div align="center">

# DBHFit.jl

**Professional Julia Package for DBH Fitting**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Julia](https://img.shields.io/badge/Julia-1.6+-purple.svg)](https://julialang.org/)

English | [中文文档](README_zh-CN.md)

Multiple circle fitting algorithms for forestry point cloud data processing

</div>

---

## ✨ Features

- 🎯 **Three Algorithms** - Least Squares (LS), Levenberg-Marquardt (LM), RANSAC
- 🔧 **Unified API** - Single `fit_dbh` function interface
- 🤖 **Smart Optimization** - Auto-tune RANSAC parameters with Hyperopt.jl
- 🛡️ **Robust Fitting** - Huber weights for outlier resistance
- 📊 **Visualization** - Plots.jl visualization support

## 📦 Installation

```julia
using Pkg
Pkg.add(url="https://github.com/hunterbuffer11/DBHFit.jl")
```

## 🚀 Quick Start

```julia
using DBHFit

# Sample data
x = [0.0, 1.0, 0.0, -1.0]
y = [1.0, 0.0, -1.0, 0.0]

# Fit using least squares
result = fit_dbh(x, y; method=:ls)

println("Center: ($(result.center_x), $(result.center_y))")
println("Radius: $(result.radius)")
println("DBH: $(result.dbh)")
```

## 📖 Usage

### Fitting Methods

#### Least Squares (LS)
```julia
result = fit_dbh(x, y; method=:ls)
```
Fast algebraic method, suitable for initial estimation and high-quality data.

#### Levenberg-Marquardt (LM)
```julia
result = fit_dbh(x, y; method=:lm, max_iter=50, robust=true)
```
High precision with Huber robust weights, ideal for general scenarios.

#### RANSAC
```julia
# Manual parameters
result = fit_dbh(x, y; method=:ransac, max_trials=200, 
                 min_inliers=50, threshold=0.01)

# Auto optimization
result = fit_dbh(x, y; method=:ransac, optimize=true)
```
Robust to outliers, ideal for noisy data.

### Result Type

```julia
struct CircleFitResult
    center_x::T    # Circle center X
    center_y::T    # Circle center Y
    radius::T      # Radius
    dbh::T         # Diameter (2 * radius)
    rmse::T        # Root Mean Square Error
    method::Symbol # Fitting method
end
```

### Advanced Usage

```julia
# Point2D input
points = [Point2D(0.0, 1.0), Point2D(1.0, 0.0), 
         Point2D(0.0, -1.0), Point2D(-1.0, 0.0)]
result = fit_dbh(points; method=:ls)

# Configuration object
config = FitConfig(:lm; max_iter=100, robust=true)
result = fit_dbh(x, y, config)

# Visualization
using Plots
result = fit_dbh(x, y; method=:lm)
p = plot_fit(x, y, result)
savefig(p, "fitting_result.png")
```

## ⚙️ Performance

- `@inbounds` optimized loops
- `StaticArrays` for small matrix operations
- Type-stable implementation
- Stack allocation in LM method

## ✅ Validation

Automatic input validation:
- Equal length vectors
- Minimum 3 points
- No NaN/Inf values
- Non-collinear points
- Non-coincident points

## 🔧 Development

```julia
# Run tests
using Pkg
Pkg.activate(".")
Pkg.test()

# Format code
using JuliaFormatter
format("src/")
```

## 📄 License

MIT License - see [LICENSE](LICENSE) file

## 👤 Author

Hunter

## 🙏 Acknowledgments

Thanks to the Julia community and all contributors!
