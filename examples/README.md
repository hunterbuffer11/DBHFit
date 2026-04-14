# DBHFit.jl 示例说明

本目录包含DBHFit.jl的使用示例。

## 示例文件

### basic_usage.jl

基础使用示例，包含：

- 生成测试数据
- 使用不同方法拟合（LS, LM, RANSAC）
- 使用统一API
- 使用Point2D数据结构
- 使用FitConfig配置对象
- 处理含离群点的数据

运行方式：
```julia
include("basic_usage.jl")
```

### advanced.jl

高级用法示例，包含：

- 三种方法的性能对比
- LM方法参数调优
- RANSAC参数优化
- 批量处理多棵树
- 误差分析

运行方式：
```julia
include("advanced.jl")
```

## 运行示例

### 方法1: 在Julia REPL中运行

```julia
julia> cd("path/to/DBHFit/examples")
julia> include("basic_usage.jl")
```

### 方法2: 使用命令行

```bash
julia basic_usage.jl
```

## 示例输出

示例运行后会显示：

1. 拟合结果（圆心、半径、胸径、误差）
2. 不同方法的对比
3. 参数调优建议
4. 性能统计

## 自定义示例

您可以根据自己的数据修改示例：

```julia
using DBHFit

# 从文件读取数据
# x, y = read_your_data("your_file.csv")

# 拟合
result = fit_dbh(x, y)

# 输出结果
println("胸径: $(result.dbh) 米")
```

## 注意事项

- 确保已安装DBHFit包
- 示例使用随机生成的数据，可根据需要替换为真实数据
- 高级示例中的性能测试结果会因机器配置而异
