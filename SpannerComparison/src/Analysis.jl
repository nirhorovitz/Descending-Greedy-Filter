module Analysis

using ..CoreTypes
using Graphs
using SimpleWeightedGraphs
using LinearAlgebra
using Statistics
using Distances

export compute_stats, verify_spanner_properties, compute_redundancy_counts, get_max_redundancy_details

"""
    get_max_redundancy_details(g_greedy::SimpleWeightedGraph, g_filter::SimpleWeightedGraph, instance::SpannerInstance)

Identifies the single edge in Greedy (but not Filter) that, if added to Filter, would allow removing the maximum number of original Filter edges.
Returns (max_count, best_edge_tuple, list_of_redundant_edges).
"""
function get_max_redundancy_details(g_greedy::SimpleWeightedGraph, g_filter::SimpleWeightedGraph, instance::SpannerInstance)
    target_edges = []
    for e in edges(g_greedy)
        if !has_edge(g_filter, src(e), dst(e))
            push!(target_edges, (src(e), dst(e), weight(e)))
        end
    end
    
    max_count = -1
    best_edge = nothing
    best_redundant_set = Tuple{Int, Int}[]
    
    if isempty(target_edges)
        return max_count, best_edge, best_redundant_set
    end
    
    filter_edges = []
    for e in edges(g_filter)
        push!(filter_edges, (src(e), dst(e), weight(e)))
    end
    
    for (u, v, w) in target_edges
        g_base = deepcopy(g_filter)
        add_edge!(g_base, u, v, w)
        
        current_redundant = Tuple{Int, Int}[]
        
        for (fu, fv, fw) in filter_edges
            rem_edge!(g_base, fu, fv)
            _, is_valid = verify_spanner_properties(instance, g_base, short_circuit=true)
            if is_valid
                push!(current_redundant, (fu, fv))
            end
            add_edge!(g_base, fu, fv, fw)
        end
        
        if length(current_redundant) > max_count
            max_count = length(current_redundant)
            best_edge = (u, v)
            best_redundant_set = current_redundant
        end
    end
    
    return max_count, best_edge, best_redundant_set
end

"""
    compute_stats(instance::SpannerInstance, result::SpannerResult)

Computes statistics for the generated graph and updates the result.stats dictionary.
Uses parallel processing for spanner verification.
"""
function compute_stats(instance::SpannerInstance, result::SpannerResult)
    g = result.graph
    points = instance.points
    n = length(points)
    
    # 1. Basic Graph Stats
    num_edges = ne(g)
    num_nodes = nv(g)
    degrees = degree(g)
    max_deg = isempty(degrees) ? 0 : maximum(degrees)
    avg_deg = isempty(degrees) ? 0.0 : mean(degrees)
    
    # 2. Total Weight
    total_weight = sum(weight(e) for e in edges(g))
    
    # 3. MST Weight
    mst_weight = compute_mst_weight(points)
    weight_multiplier = mst_weight > 0 ? total_weight / mst_weight : Inf
    
    # 4. Spanner Verification (Parallel)
    max_stretch_found, is_valid_spanner = verify_spanner_properties(instance, g)
    
    # Update stats
    result.stats[:total_weight] = total_weight
    result.stats[:mst_weight] = mst_weight
    result.stats[:weight_ratio] = weight_multiplier
    result.stats[:num_edges] = num_edges
    result.stats[:num_nodes] = num_nodes
    result.stats[:max_degree] = max_deg
    result.stats[:avg_degree] = avg_deg
    result.stats[:target_t] = instance.t
    result.stats[:max_stretch_found] = max_stretch_found
    result.stats[:is_valid_spanner] = is_valid_spanner
    
    return result
end

function verify_spanner_properties(instance::SpannerInstance, g::SimpleWeightedGraph; short_circuit::Bool=false)
    n = length(instance.points)
    points = instance.points
    w_func = instance.w_func
    t = instance.t
    
    # Shared variables with lock
    max_stretch_found = Ref(0.0)
    is_valid_spanner = Ref(true)
    lock_obj = ReentrantLock()
    
    if short_circuit
        for i in 1:n
            dists = dijkstra_shortest_paths(g, i).dists
            for j in (i+1):n
                 d_graph = dists[j]
                 d_euclid = norm(points[i] - points[j])
                 if d_euclid > 1e-10
                     w_val = w_func(i, j)
                     # Check validity directly
                     if d_graph > (t * d_euclid) / w_val + 1e-7
                         return Inf, false
                     end
                 end
            end
        end
        return 0.0, true
    else
        Threads.@threads for i in 1:n
            dists = dijkstra_shortest_paths(g, i).dists
            local_max = 0.0
            local_valid = true
            for j in (i+1):n
                d_graph = dists[j]
                d_euclid = norm(points[i] - points[j])
                if d_euclid > 1e-10
                    w_val = w_func(i, j)
                    if d_graph == Inf
                        stretch_val = Inf
                    else
                        stretch_val = (w_val * d_graph) / d_euclid
                    end
                    if stretch_val > local_max
                        local_max = stretch_val
                    end
                    if stretch_val > t + 1e-7
                        local_valid = false
                    end
                end
            end
            lock(lock_obj) do
                if local_max > max_stretch_found[]
                    max_stretch_found[] = local_max
                end
                if !local_valid
                    is_valid_spanner[] = false
                end
            end
        end
        return max_stretch_found[], is_valid_spanner[]
    end
end

"""
    compute_redundancy_counts(g_greedy::SimpleWeightedGraph, g_filter::SimpleWeightedGraph, instance::SpannerInstance)

For each edge in Greedy but not in Filter, adds it to Filter and counts how many original Filter edges could be removed.
Returns a list of redundancy counts (one integer per missing edge).
"""
function compute_redundancy_counts(g_greedy::SimpleWeightedGraph, g_filter::SimpleWeightedGraph, instance::SpannerInstance)
    counts = Int[]
    
    # Identify target edges: in Greedy but not in Filter
    target_edges = []
    for e in edges(g_greedy)
        if !has_edge(g_filter, src(e), dst(e))
            push!(target_edges, (src(e), dst(e), weight(e)))
        end
    end
    
    if isempty(target_edges)
        return counts
    end
    
    # Pre-fetch original filter edges to iterate over
    filter_edges = []
    for e in edges(g_filter)
        push!(filter_edges, (src(e), dst(e), weight(e)))
    end
    
    for (u, v, w) in target_edges
        # Create a base graph: Filter + {uv}
        g_base = deepcopy(g_filter)
        add_edge!(g_base, u, v, w)
        
        redundant_count = 0
        
        # Try to remove each original edge independently
        for (fu, fv, fw) in filter_edges
            rem_edge!(g_base, fu, fv)
            
            # Check validity
            _, is_valid = verify_spanner_properties(instance, g_base, short_circuit=true)
            
            if is_valid
                redundant_count += 1
            end
            
            # Restore
            add_edge!(g_base, fu, fv, fw)
        end
        
        push!(counts, redundant_count)
    end
    
    return counts
end

function compute_mst_weight(points)
    n = length(points)
    if n == 0 return 0.0 end
    
    min_dists = fill(Inf, n)
    in_mst = fill(false, n)
    min_dists[1] = 0.0
    total_w = 0.0
    
    for _ in 1:n
        u = -1
        min_val = Inf
        
        for i in 1:n
            if !in_mst[i] && min_dists[i] < min_val
                min_val = min_dists[i]
                u = i
            end
        end
        
        if u == -1 break end
        
        in_mst[u] = true
        total_w += min_val
        
        for v in 1:n
            if !in_mst[v]
                d = norm(points[u] - points[v])
                if d < min_dists[v]
                    min_dists[v] = d
                end
            end
        end
    end
    return total_w
end

end
