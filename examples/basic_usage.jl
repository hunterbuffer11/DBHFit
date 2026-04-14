using PointCloudUtils
using Plots        
using DBHFit 

# PointCloudUtils is my package for point cloud processing.
# You can use the DataFrames package instead of PointCloudUtils

# Loading point cloud data
Point1 = load_pointcloud("YOUR DATA")

# Extract DBH region(1.3m)
Point_1_dbh = extract_dbh(Point1, 1.2, 1.4)

# Three methods to fit DBH
# Linear Least Squares

result_ls = fit_dbh(Point_1_dbh.x, Point_1_dbh.y;
                             method=:ls, skip_validation=true)

# Levenberg-Marquardt(No Linear Least Squares)
# robust is a boolean parameter to enable robust fitting
result_lm = fit_dbh(Point_1_dbh.x, Point_1_dbh.y;
                             method=:lm, skip_validation=true, robust = true)

# RANSAC
# optimize is a boolean parameter to enable optimization(Bayisan optimization)
result_ransac = fit_dbh(Point_1_dbh.x, Point_1_dbh.y; 
                            method=:ransac, skip_validation=true, 
                            optimize=true,optimize_metric = :mae )

# If have Plot package，you can use plot_fit to visualize the fitting result
p1 = plot_fit(Point_1_dbh.x, Point_1_dbh.y, result_ls; title="LS")
p2 = plot_fit(Point_1_dbh.x, Point_1_dbh.y, result_lm; title="LM")
p3 = plot_fit(Point_1_dbh.x, Point_1_dbh.y, result_ransac; title="RANSAC")

# 组合显示
p = plot(p1, p2, p3; layout=(1, 3), size=(1200, 400))
display(p)