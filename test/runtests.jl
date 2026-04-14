using Test
using DBHFit
using StaticArrays
using Random

Random.seed!(1234)

@testset "DBHFit.jl" begin
    
    @testset "数据类型" begin
        @testset "CircleFitResult" begin
            result = CircleFitResult(1.0, 2.0, 3.0, 0.1, :ls)
            @test result.center_x == 1.0
            @test result.center_y == 2.0
            @test result.radius == 3.0
            @test result.dbh == 6.0  # 2 * radius
            @test result.rmse == 0.1
            @test result.method == :ls
        end
        
        @testset "Point2D" begin
            p = Point2D(1.0, 2.0)
            @test p.x == 1.0
            @test p.y == 2.0
        end
        
        @testset "FitConfig" begin
            config = FitConfig(:lm; max_iter=100)
            @test config.method == :lm
            @test config.max_iter == 100
        end
    end
    
    @testset "工具函数" begin
        @testset "输入验证" begin
            @test validate_input([1.0, 2.0, 4.0], [1.0, 3.0, 2.0]) == true
            @test validate_input([1.0, 2.0, 4.0], [1.0, 3.0, 2.0]; skip_validation=true) == true
            @test_throws ArgumentError validate_input([1.0], [1.0, 2.0])
            @test_throws ArgumentError validate_input([1.0, 2.0], [1.0])
            @test_throws ArgumentError validate_input([1.0, 2.0], [1.0])
            @test_throws ArgumentError validate_input([NaN, 2.0, 3.0], [1.0, 2.0, 3.0])
            @test_throws ArgumentError validate_input([Inf, 2.0, 3.0], [1.0, 2.0, 3.0])
        end
        
        @testset "误差计算" begin
            x = [0.0, 1.0, 0.0, -1.0]
            y = [1.0, 0.0, -1.0, 0.0]
            
            rmse = calculate_rmse(x, y, 0.0, 0.0, 1.0)
            @test rmse ≈ 0.0 atol=1e-10
            
            mae = calculate_mae(x, y, 0.0, 0.0, 1.0)
            @test mae ≈ 0.0 atol=1e-10
        end
    end
    
    @testset "拟合算法" begin
        # 生成测试数据：单位圆上的点
        θ = LinRange(0, 2π, 100)[1:end-1]
        x_perfect = cos.(θ)
        y_perfect = sin.(θ)
        
        @testset "最小二乘法" begin
            result = fit_circle_ls(x_perfect, y_perfect)
            @test result.method == :ls
            @test result.center_x ≈ 0.0 atol=1e-10
            @test result.center_y ≈ 0.0 atol=1e-10
            @test result.radius ≈ 1.0 atol=1e-10
            @test result.dbh ≈ 2.0 atol=1e-10
        end
        
        @testset "Levenberg-Marquardt" begin
            result = fit_circle_lm(x_perfect, y_perfect)
            @test result.method == :lm
            @test result.center_x ≈ 0.0 atol=1e-8
            @test result.center_y ≈ 0.0 atol=1e-8
            @test result.radius ≈ 1.0 atol=1e-8
        end
        
        @testset "RANSAC" begin
            # 生成测试数据：单位圆上的点
            θ = LinRange(0, 2π, 100)[1:end-1]
            x_perfect = cos.(θ)
            y_perfect = sin.(θ)
            
            # 添加一些离群点（确保不共线）
            x_noisy = copy(x_perfect)
            y_noisy = copy(y_perfect)
            x_noisy[1:5] = [10.0, 10.5, 11.0, 11.5, 12.0]  # 离群点
            y_noisy[1:5] = [10.0, 10.3, 10.6, 10.9, 11.2]
            
            # 必须指定 max_trials 和 min_inliers
            result = fit_circle_ransac(x_noisy, y_noisy; threshold=0.1, max_trials=100, min_inliers=50)
            @test result.method == :ransac
            @test result.radius ≈ 1.0 atol=0.1
        end
        
        @testset "RANSAC自动优化" begin
            # 测试贝叶斯优化
            x_test = x_perfect .+ 0.01 * randn(length(x_perfect))
            y_test = y_perfect .+ 0.01 * randn(length(y_perfect))
            
            @testset "贝叶斯优化" begin
                result_rmse = fit_circle_ransac(x_test, y_test; optimize=true)
                @test result_rmse.method == :ransac
                @test result_rmse.radius ≈ 1.0 atol=0.05
                
                result_mae = fit_circle_ransac(x_test, y_test; optimize=true, optimize_metric=:mae)
                @test result_mae.method == :ransac
                @test result_mae.radius ≈ 1.0 atol=0.05
            end
        end
        
        @testset "RANSAC参数验证" begin
            # 测试必须指定参数
            @test_throws ArgumentError fit_circle_ransac(x_perfect, y_perfect)
            @test_throws ArgumentError fit_circle_ransac(x_perfect, y_perfect; max_trials=100)
            @test_throws ArgumentError fit_circle_ransac(x_perfect, y_perfect; min_inliers=50)
        end
    end
    
    @testset "统一API" begin
        x = [0.0, 1.0, 0.0, -1.0]
        y = [1.0, 0.0, -1.0, 0.0]
        
        @testset "method必须指定" begin
            @test_throws ArgumentError fit_dbh(x, y)
        end
        
        @testset "指定方法" begin
            result_ls = fit_dbh(x, y; method=:ls)
            @test result_ls.method == :ls
            @test result_ls.radius ≈ 1.0 atol=1e-10
            
            result_lm = fit_dbh(x, y; method=:lm)
            @test result_lm.method == :lm
            @test result_lm.radius ≈ 1.0 atol=1e-10
            
            # RANSAC需要指定参数
            result_ransac = fit_dbh(x, y; method=:ransac, max_trials=100, min_inliers=3)
            @test result_ransac.method == :ransac
        end
        
        @testset "Point2D输入" begin
            points = [Point2D(0.0, 1.0), Point2D(1.0, 0.0), 
                     Point2D(0.0, -1.0), Point2D(-1.0, 0.0)]
            result = fit_dbh(points; method=:ls)
            @test result.radius ≈ 1.0 atol=1e-10
        end
        
        @testset "FitConfig输入" begin
            config = FitConfig(:ls)
            result = fit_dbh(x, y, config)
            @test result.method == :ls
        end
        
        @testset "错误处理" begin
            @test_throws ArgumentError fit_dbh(x, y; method=:unknown)
        end
    end
    
    @testset "skip_validation参数" begin
        x = [0.0, 1.0, 0.0, -1.0]
        y = [1.0, 0.0, -1.0, 0.0]
        
        @testset "跳过验证正常数据" begin
            result = fit_dbh(x, y; method=:ls, skip_validation=true)
            @test result.radius ≈ 1.0 atol=1e-10
        end
        
        @testset "跳过验证结果一致" begin
            result1 = fit_dbh(x, y; method=:ls, skip_validation=false)
            result2 = fit_dbh(x, y; method=:ls, skip_validation=true)
            @test result1.center_x ≈ result2.center_x atol=1e-10
            @test result1.center_y ≈ result2.center_y atol=1e-10
            @test result1.radius ≈ result2.radius atol=1e-10
        end
        
        @testset "各方法跳过验证" begin
            result_ls = fit_circle_ls(x, y; skip_validation=true)
            @test result_ls.method == :ls
            
            result_lm = fit_circle_lm(x, y; skip_validation=true)
            @test result_lm.method == :lm
            
            result_ransac = fit_circle_ransac(x, y; max_trials=100, min_inliers=3, skip_validation=true)
            @test result_ransac.method == :ransac
        end
    end
    
    @testset "边界条件" begin
        @testset "共线点" begin
            x = [0.0, 1.0, 2.0]
            y = [0.0, 1.0, 2.0]
            @test_throws ArgumentError fit_circle_ls(x, y)
            @test_throws ArgumentError fit_circle_lm(x, y)
            @test_throws ArgumentError fit_circle_ransac(x, y; max_trials=100, min_inliers=3)
        end
        
        @testset "点数不足" begin
            x = [1.0, 2.0]
            y = [1.0, 2.0]
            @test_throws ArgumentError fit_dbh(x, y; method=:ls)
        end
        
        @testset "重合点" begin
            x = [1.0, 1.0, 1.0]
            y = [1.0, 1.0, 1.0]
            @test_throws ArgumentError fit_dbh(x, y; method=:ls)
        end
        
        @testset "长度不匹配" begin
            x = [1.0, 2.0, 3.0]
            y = [1.0, 2.0]
            @test_throws ArgumentError fit_dbh(x, y; method=:ls)
        end
    end
    
    @testset "类型稳定性" begin
        @testset "Float32" begin
            x = Float32[0.0, 1.0, 0.0, -1.0]
            y = Float32[1.0, 0.0, -1.0, 0.0]
            result = fit_dbh(x, y; method=:ls)
            @test result.center_x isa Float32
        end
        
        @testset "Float64" begin
            x = Float64[0.0, 1.0, 0.0, -1.0]
            y = Float64[1.0, 0.0, -1.0, 0.0]
            result = fit_dbh(x, y; method=:ls)
            @test result.center_x isa Float64
        end
    end
    
end
