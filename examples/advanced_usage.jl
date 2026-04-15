# ============================================================
# Advanced Usage Example - optional dependencies
# ============================================================
# This example requires:
#   - PointCloudUtils.jl (for PointCloud type support)
#   - Plots.jl (for visualization)
#
# Install with:
#   using Pkg
#   Pkg.add("PointCloudUtils")
#   Pkg.add("Plots")
# ============================================================
#   PointCloudUtils.jl is a package for point cloud processing
#   You can use the DataFrames and CSV package instead of PointCloudUtils,such as:
#   using DataFrames
#   using CSV
#   df = CSV.read("YOUR DATA.csv")
#   But for this example, we will use PointCloudUtils.jl
#   DATA: I put the point3D data in the folder "DATA.csv"
#   Note: Regardless of whether the data is in .las/.laz or CSV format, 
#   you need to pass x, y (as one-dimensional arrays) to the fit_dbh function
#   or,Use the Point2D struct(in types.jl)

# ============================================================
# Load Point Cloud Data
# ============================================================

using PointCloudUtils
using Plots
using DBHFit

# ============================================================
# Load Point Cloud Data
# ============================================================

Point1 = load_pointcloud("YOUR_DATA.csv")

# ============================================================
# Extract DBH Region (1.3m height)
# ============================================================
# Standard DBH measurement is at 1.3m above ground
# Before fitting, you need to normalize the point cloud height to MinZ=0
# Extract points in range [1.2m, 1.4m]
# Note: extract_dbh is a function in PointCloudUtils.jl
Point_1_dbh = extract_dbh(Point1, 1.2, 1.4)

# ============================================================
# Fit DBH using three methods
# ============================================================

# Method 1: Linear Least Squares (recommended for clean data)
result_ls = fit_dbh(Point_1_dbh.x, Point_1_dbh.y;
    method=:ls, 
    skip_validation=true
)

# Method 2: Levenberg-Marquardt with robust fitting
result_lm = fit_dbh(Point_1_dbh.x, Point_1_dbh.y;
    method=:lm, 
    skip_validation=true, 
    robust=true
)

# Method 3: RANSAC with auto optimization
result_ransac = fit_dbh(Point_1_dbh.x, Point_1_dbh.y; 
    method=:ransac, 
    skip_validation=true, 
    optimize=true,
    optimize_metric=:mae
)

# ============================================================
# Visualize Results
# ============================================================
p1 = plot_fit(Point_1_dbh.x, Point_1_dbh.y, result_ls; title="LS")
p2 = plot_fit(Point_1_dbh.x, Point_1_dbh.y, result_lm; title="LM")
p3 = plot_fit(Point_1_dbh.x, Point_1_dbh.y, result_ransac; title="RANSAC")

# Combine plots
p = plot(p1, p2, p3; layout=(1, 3), size=(1200, 400))
display(p)

# ============================================================
# Alternative: Direct PointCloud Input
# ============================================================
# If you have PointCloudUtils installed, you can pass
# PointCloud directly to fit_dbh

# result = fit_dbh(Points; 
#     height_range=(1.2, 1.4),  # Extract DBH region automatically
#     method=:ls
# )
