# DBHFit.jl

[![Build Status](https://github.com/hunterbuffer11/DBHFit.jl/workflows/CI/badge.svg)](https://github.com/hunterbuffer11/DBHFit.jl/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**[中文文档](README_zh-CN.md)**

Professional Julia package for Diameter at Breast Height (DBH) fitting with multiple circle fitting algorithms for forestry point cloud data processing.

## Features

- **Three Fitting Algorithms**: LS, Levenberg-Marquardt, RANSAC
- **Unified API**: Single `fit_dbh` function interface
- **Bayesian Optimization**: Auto-tune RANSAC parameters with Hyperopt.jl
- **Robust Fitting**: Huber weights for outlier resistance
- **Optional Extensions**: Plots.jl visualization, PointCloudUtils integration

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/hunterbuffer11/DBHFit.jl")
```

## Quick Start

```julia
using DBHFit

x = [0.0, 1.0, 0.0, -1.0]
y = [1.0, 0.0, -1.0, 0.0]

# Specify method (required)
result = fit_dbh(x, y; method=:ls)

println("Center: ($(result.center_x), $(result.center_y))")
println("Radius: $(result.radius)")
println("DBH: $(result.dbh)")
```

## API Reference

### Main Function

```julia
fit_dbh(x, y; method, kwargs...) -> CircleFitResult
```

**Parameters:**
- `x, y`: Point coordinates
- `method`: Fitting method (**required**: `:ls`, `:lm`, or `:ransac`)
- `skip_validation`: Skip input validation for speed (default: `false`)

### Methods

#### Least Squares (LS)
```julia
result = fit_dbh(x, y; method=:ls)
```
Fast algebraic method, suitable for initial estimation.

#### Levenberg-Marquardt (LM)
```julia
result = fit_dbh(x, y; method=:lm, max_iter=50, robust=true, huber_threshold=4.685)
```
High precision with optional Huber robust weights.

#### RANSAC
```julia
# Manual parameters
result = fit_dbh(x, y; method=:ransac, max_trials=200, min_inliers=50, threshold=0.01)

# Auto optimization (requires Hyperopt)
result = fit_dbh(x, y; method=:ransac, optimize=true, optimize_metric=:rmse)
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
    method::Symbol # Fitting method used
end
```

## Examples

### Point2D Input
```julia
points = [Point2D(0.0, 1.0), Point2D(1.0, 0.0), 
         Point2D(0.0, -1.0), Point2D(-1.0, 0.0)]
result = fit_dbh(points; method=:ls)
```

### Configuration Object
```julia
config = FitConfig(:lm; max_iter=100, robust=true)
result = fit_dbh(x, y, config)
```

### Visualization
```julia
using Plots
using DBHFit

result = fit_dbh(x, y; method=:lm)
p = plot_fit(x, y, result)
savefig(p, "fitting_result.png")
```

## Performance

- `@inbounds` optimized loops
- `StaticArrays` for small matrix operations
- Type-stable implementation
- Stack allocation in LM method

## Validation

Automatic checks:
- ✅ Equal length vectors
- ✅ Minimum 3 points
- ✅ No NaN/Inf values
- ✅ Non-collinear points
- ✅ Non-coincident points

## Development

```julia
# Run tests
using Pkg
Pkg.activate(".")
Pkg.test()

# Format code
using JuliaFormatter
format("src/")
```

## License

MIT License - see [LICENSE](LICENSE) file.

## Author

Hunter

## Acknowledgments

Thanks to the Julia community and all contributors!
