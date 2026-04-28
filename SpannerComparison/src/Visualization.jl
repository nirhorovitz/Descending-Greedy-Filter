module Visualization

using ..CoreTypes
using Plots
using Graphs
using SimpleWeightedGraphs

export visualize_results

"""
    visualize_results(instance::SpannerInstance, results::Vector{SpannerResult})

Plots the resulting graphs and statistics.
"""
function visualize_results(instance::SpannerInstance, results::Vector{SpannerResult}; 
                           compare_with::Union{Vector{Int}, Nothing}=nothing, 
                           point_labels::Vector{String}=String[],
                           highlight_edges::Union{Vector{Vector{Tuple{Int,Int}}}, Nothing}=nothing,
                           extra_title::String="")
    # Extract points for plotting
    xs = [p[1] for p in instance.points]
    ys = [p[2] for p in instance.points]
    
    plots = []
    
    for (i, res) in enumerate(results)
        g = res.graph
        
        # Determine comparison graph if provided
        comp_g = nothing
        if compare_with !== nothing && length(compare_with) >= i && compare_with[i] > 0
            if compare_with[i] <= length(results)
                comp_g = results[compare_with[i]].graph
            end
        end
        
        # Determine highlights
        current_highlights = Set{Tuple{Int,Int}}()
        if highlight_edges !== nothing && length(highlight_edges) >= i
            for (hu, hv) in highlight_edges[i]
                push!(current_highlights, (min(hu, hv), max(hu, hv)))
            end
        end
        
        # Build comprehensive stats text
        s = res.stats
        title_text = "$(res.algorithm_name)\n" *
                     "Time: $(round(res.runtime_seconds, digits=3))s\n" *
                     "Valid: $(get(s, :is_valid_spanner, "?")) (St=$(round(get(s, :max_stretch_found, 0.0), digits=4)))\n" *
                     "Weight: $(round(s[:total_weight], digits=1)) (x$(round(get(s, :weight_ratio, 0), digits=2)))\n" *
                     "Edges: $(s[:num_edges]) | Pts: $(s[:num_nodes])\n" *
                     "Deg: Max $(s[:max_degree]) / Avg $(round(s[:avg_degree], digits=1))"
        
        p = plot(xs, ys, seriestype=:scatter, markersize=3, legend=false, title=title_text, titlefontsize=10, aspect_ratio=:equal, markercolor=:blue)
        
        # Add labels if provided
        if !isempty(point_labels) && length(point_labels) == length(xs)
            # Offset text slightly
            annotate!(p, [(xs[j], ys[j] + 0.02, text(point_labels[j], 8, :bottom)) for j in 1:length(xs)])
        end
        
        # Draw edges
        for e in edges(g)
            u, v = src(e), dst(e)
            
            is_different = false
            if comp_g !== nothing
                if !has_edge(comp_g, u, v)
                    is_different = true
                end
            end
            
            is_highlighted = ((min(u,v), max(u,v)) in current_highlights)
            
            if is_highlighted
                col = :blue
                alp = 1.0
                wid = 2.5
            elseif is_different
                col = :red
                alp = 0.8
                wid = 2.0
            else
                col = :gray
                alp = 0.5
                wid = 1.0
            end
            
            plot!(p, [xs[u], xs[v]], [ys[u], ys[v]], color=col, alpha=alp, linewidth=wid)
        end
        
        # Draw Greedy Highlight edge if it's missing (special case for Greedy plot where we want to show the 'best edge' if it was added)
        # Actually, best_edge IS in Greedy, so the loop above covers it.
        # But if we want to show it in Filter plot (as added), we might need to draw it explicitly if it's not in Filter.
        # The user said: "color the edge that its removel coused the most replaced edges in blue in the greedy graph" -> OK (it exists in Greedy)
        # "and all the edges that can be removed because of it in blue in the filter graph" -> OK (they exist in Filter)
        
        push!(plots, p)
    end
    
    # Add super title if provided
    if !isempty(extra_title)
        # plot(plots..., plot_title=extra_title) - plot_title might not work in all backends or older Plots versions
        # We'll try to add it via layout margins or just annotation
        final_plot = plot(plots..., layout=(1, length(results)), size=(400*length(results), 650), margin=5Plots.mm, plot_title=extra_title)
    else
        final_plot = plot(plots..., layout=(1, length(results)), size=(400*length(results), 600), margin=5Plots.mm)
    end
    return final_plot
end

end

