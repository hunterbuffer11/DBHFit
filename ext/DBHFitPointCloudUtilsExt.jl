# DBHFit PointCloudUtils Ext
# I can directly process point cloud data of the PointCloud type in DBHFit
# Usually, you can ignore this module.
module DBHFitPointCloudUtilsExt

using DBHFit
using PointCloudUtils

"""
    DBHFit.fit_dbh(pc::PointCloud; kwargs...)

Directly process point cloud data of the PointCloud type.
"""
function DBHFit.fit_dbh(pc::PointCloud{T}; 
                        height_range::Union{Tuple{Real,Real},Nothing}=nothing,
                        kwargs...) where T<:Real
    # DBH range
    if height_range !== nothing
        pc = PointCloudUtils.extract_dbh(pc, height_range[1], height_range[2])
    end
    # Call the base fitting function
    return DBHFit.fit_dbh(pc.x, pc.y; kwargs...)
end

end # module
