# DBHFit Plots Ext

module DBHFitPlotsExt

using DBHFit
using Plots

"""
    DBHFit.plot_fit(x, y, result; kwargs...)

Plot visualization graphs of the fitting results

"""
function DBHFit.plot_fit(x::AbstractVector{T}, y::AbstractVector{T}, 
                         result::DBHFit.CircleFitResult; 
                         size::Tuple{Int,Int}=(600, 600),
                         markersize::Real=1,
                         aspect_ratio::Symbol=:equal,
                         kwargs...) where T<:Real

    # Scattering plot of points
    p = Plots.scatter(x, y; 
                      size=size, 
                      grid=true,
                      label="Points",
                      title="Circle Fit Result",
                      markersize=markersize, 
                      aspect_ratio=aspect_ratio,
                      kwargs...)
    
    # Calculate the circle based on the fitting result
    θ = LinRange(0, 2π, 100)
    circle_x = result.center_x .+ result.radius * cos.(θ)
    circle_y = result.center_y .+ result.radius * sin.(θ)
    Plots.plot!(p, circle_x, circle_y; linewidth=3, label="Fitted Circle", color=:red)
    
    # Plot the center of the circle
    Plots.scatter!(p, [result.center_x], [result.center_y]; 
                   label="Center",
                   markershape=:circle,
                   markersize=8,
                   markercolor=:blue,
                   markerstrokecolor=:white)
    
    # Plot the radius
    x_rim = result.center_x + result.radius
    y_rim = result.center_y
    Plots.plot!(p, [result.center_x, x_rim], [result.center_y, y_rim];
                linewidth=2,
                linestyle=:dash,
                linecolor=:red,
                label="Radius")
    
    # Add radius annotation
    mid_x = (result.center_x + x_rim) / 2
    mid_y = result.center_y + 0.015
    Plots.annotate!(p, mid_x, mid_y, 
                    Plots.text("R = $(round(result.radius, digits=3))", 
                              :blue, :center, 10))
    
    return p
end

end 
