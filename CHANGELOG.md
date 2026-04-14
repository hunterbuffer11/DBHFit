# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-04-08

### Added

- Initial release of DBHFit.jl
- Three circle fitting algorithms:
  - Least Squares (LS) method - fast algebraic fitting
  - Levenberg-Marquardt (LM) method - robust optimization
  - RANSAC method - outlier-resistant fitting
- Unified API with `fit_dbh` function
- Automatic method selection based on data characteristics
- Core data types:
  - `CircleFitResult` - fitting result structure
  - `Point2D` - 2D point structure
  - `FitConfig` - configuration structure
- Utility functions:
  - `calculate_rmse` - RMSE calculation
  - `calculate_mae` - MAE calculation
  - `validate_input` - input validation
  - `select_method` - automatic method selection
  - `preprocess_points` - noise filtering
- Optional extensions:
  - Plots.jl integration for visualization
  - PointCloudUtils integration for point cloud processing
- Comprehensive test suite
- Example scripts:
  - `basic_usage.jl` - basic usage examples
  - `advanced.jl` - advanced usage examples
- Complete documentation with docstrings
- MIT License

### Features

- Type-stable implementations supporting generic Real types
- Performance optimizations with `@inbounds` and `StaticArrays`
- Robust fitting with Huber weights in LM method
- Configurable parameters for all fitting methods
- Support for multiple input formats (vectors, Point2D, FitConfig)

### Dependencies

- Julia 1.6+
- LinearAlgebra (stdlib)
- StaticArrays
- Statistics (stdlib)
- Random (stdlib)

### Optional Dependencies

- Plots.jl - for visualization
- PointCloudUtils - for point cloud processing
