# DBHFit PointCloudUtils扩展
# 当加载PointCloudUtils时自动启用点云处理功能

module DBHFitPointCloudUtilsExt

using DBHFit
using PointCloudUtils

"""
    DBHFit.fit_dbh(pc::PointCloud; kwargs...)

直接处理PointCloud类型的点云数据。
"""
function DBHFit.fit_dbh(pc::PointCloud{T}; 
                        height_range::Union{Tuple{Real,Real},Nothing}=nothing,
                        kwargs...) where T<:Real
    # 如果指定了高度范围，先提取DBH区域
    if height_range !== nothing
        pc = PointCloudUtils.extract_dbh(pc, height_range[1], height_range[2])
    end
    
    # 调用基础拟合函数
    return DBHFit.fit_dbh(pc.x, pc.y; kwargs...)
end

end # module
