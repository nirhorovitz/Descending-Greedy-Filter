module Algorithms

using ..CoreTypes
using Graphs
using SimpleWeightedGraphs
using LinearAlgebra
using Statistics
using DataStructures
using Printf

export GreedySpanner, WGreedyWithSkeleton, RepairWithSkeleton, WAssignmentGreedy, FilteredGreedy, FilteredWGreedyWithSkeleton, DeltaGreedy, FilteredDeltaGreedy, SqrtGreedyFilter, HybridFilterWithRefinement, GreedyWithShortEdges, FilteredSqrtGreedyWithShortEdges, FullFilter, FullFilterUnweighted, YaoGraph, ThetaGraph, WSPDSpanner, FilterRemovedCheck, FilteredSqrtGreedy, run_algorithm

# -----------------------------------------------------------------------------
# Algorithm Structs
# -----------------------------------------------------------------------------

struct GreedySpanner <: AbstractSpannerAlgorithm end

struct WGreedyWithSkeleton <: AbstractSpannerAlgorithm 
    skeleton_t::Float64
end
WGreedyWithSkeleton() = WGreedyWithSkeleton(1.2)

struct RepairWithSkeleton <: AbstractSpannerAlgorithm 
    skeleton_t::Float64
end
RepairWithSkeleton() = RepairWithSkeleton(1.2)

struct WAssignmentGreedy <: AbstractSpannerAlgorithm 
    skeleton_t::Float64
end
WAssignmentGreedy() = WAssignmentGreedy(1.2)

struct FilteredGreedy <: AbstractSpannerAlgorithm end

struct FilteredWGreedyWithSkeleton <: AbstractSpannerAlgorithm
    skeleton_t::Float64
end
FilteredWGreedyWithSkeleton() = FilteredWGreedyWithSkeleton(1.2)

struct DeltaGreedy <: AbstractSpannerAlgorithm
    delta::Float64
end
DeltaGreedy() = DeltaGreedy(1.0)

struct FilteredDeltaGreedy <: AbstractSpannerAlgorithm
    delta::Float64
end
FilteredDeltaGreedy() = FilteredDeltaGreedy(1.0)

struct SqrtGreedyFilter <: AbstractSpannerAlgorithm end

struct HybridFilterWithRefinement <: AbstractSpannerAlgorithm
    epsilon::Float64
end
HybridFilterWithRefinement(; epsilon::Float64=0.5) = HybridFilterWithRefinement(epsilon)

struct GreedyWithShortEdges <: AbstractSpannerAlgorithm end

struct FilteredSqrtGreedyWithShortEdges <: AbstractSpannerAlgorithm end

struct FullFilter <: AbstractSpannerAlgorithm end

struct FullFilterUnweighted <: AbstractSpannerAlgorithm end

struct YaoGraph <: AbstractSpannerAlgorithm
    k::Int
end
YaoGraph(; k::Int=0) = YaoGraph(k)

struct ThetaGraph <: AbstractSpannerAlgorithm
    k::Int
end
ThetaGraph(; k::Int=0) = ThetaGraph(k)

struct WSPDSpanner <: AbstractSpannerAlgorithm
    s::Float64
end
WSPDSpanner(; s::Float64=0.0) = WSPDSpanner(s)

struct FilterRemovedCheck <: AbstractSpannerAlgorithm end
struct FilteredSqrtGreedy <: AbstractSpannerAlgorithm end

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

function get_all_edges(n, points)
    edges = Vector{Tuple{Int, Int, Float64}}(undef, n * (n - 1) ÷ 2)
    idx = 1
    for i in 1:n
        for j in i+1:n
            d = norm(points[i] - points[j])
            edges[idx] = (i, j, d)
            idx += 1
        end
    end
    sort!(edges, by = x -> x[3])
    return edges
end

function compute_mst_weight_local(points)
    n = length(points)
    if n == 0
        return 0.0
    end
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
        if u == -1
            break
        end
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

function cones_for_t(t::Float64; min_k::Int=8)
    if t <= 1.0
        return min_k
    end
    val = (t - 1.0) / (2.0 * t)
    val = clamp(val, 1e-6, 0.999999)
    k = ceil(Int, pi / asin(val))
    k = max(min_k, k)
    return isodd(k) ? k + 1 : k
end

function cone_index(theta::Float64, cone_width::Float64, k::Int)
    θ = mod(theta + 2pi, 2pi)
    idx = floor(Int, θ / cone_width) + 1
    return clamp(idx, 1, k)
end

struct SplitNode
    indices::Vector{Int}
    left::Union{SplitNode, Nothing}
    right::Union{SplitNode, Nothing}
    minx::Float64
    maxx::Float64
    miny::Float64
    maxy::Float64
    diameter::Float64
end

function build_split_tree(points::Vector{Point2D}, indices::Vector{Int})
    xs = [points[i][1] for i in indices]
    ys = [points[i][2] for i in indices]
    minx, maxx = minimum(xs), maximum(xs)
    miny, maxy = minimum(ys), maximum(ys)
    diameter = hypot(maxx - minx, maxy - miny)

    if length(indices) <= 1
        return SplitNode(indices, nothing, nothing, minx, maxx, miny, maxy, diameter)
    end

    if (maxx - minx) >= (maxy - miny)
        sorted = sort(indices, by = i -> points[i][1])
    else
        sorted = sort(indices, by = i -> points[i][2])
    end
    mid = length(sorted) ÷ 2
    left_idx = sorted[1:mid]
    right_idx = sorted[mid+1:end]

    left_node = build_split_tree(points, left_idx)
    right_node = build_split_tree(points, right_idx)

    return SplitNode(indices, left_node, right_node, minx, maxx, miny, maxy, diameter)
end

function box_distance(a::SplitNode, b::SplitNode)
    dx = max(0.0, max(a.minx - b.maxx, b.minx - a.maxx))
    dy = max(0.0, max(a.miny - b.maxy, b.miny - a.maxy))
    return hypot(dx, dy)
end

function well_separated(a::SplitNode, b::SplitNode, s::Float64)
    d = box_distance(a, b)
    return d >= s * max(a.diameter, b.diameter)
end

function wspd_pairs!(pairs::Vector{Tuple{Int, Int}}, a::SplitNode, b::SplitNode, s::Float64)
    if a === b
        if a.left === nothing || a.right === nothing
            return
        end
        wspd_pairs!(pairs, a.left, a.right, s)
        return
    end

    if well_separated(a, b, s)
        push!(pairs, (a.indices[1], b.indices[1]))
        return
    end

    if (a.left !== nothing || a.right !== nothing) && (a.diameter >= b.diameter || (b.left === nothing && b.right === nothing))
        if a.left !== nothing
            wspd_pairs!(pairs, a.left, b, s)
        end
        if a.right !== nothing
            wspd_pairs!(pairs, a.right, b, s)
        end
    else
        if b.left !== nothing
            wspd_pairs!(pairs, a, b.left, s)
        end
        if b.right !== nothing
            wspd_pairs!(pairs, a, b.right, s)
        end
    end
end

function get_graph_distance(g::AbstractGraph, u::Int, v::Int, points::Vector{Point2D}, limit::Float64)
    p_end = points[v]
    h(x) = norm(points[x] - p_end)
    
    if h(u) > limit
        return Inf
    end
    
    open_set = PriorityQueue{Int, Float64}()
    enqueue!(open_set, u, h(u))
    
    g_scores = fill(Inf, nv(g))
    g_scores[u] = 0.0
    
    while !isempty(open_set)
        curr = dequeue!(open_set)
        
        if curr == v
            return g_scores[v]
        end
        
        d_curr = g_scores[curr]
        if d_curr + h(curr) > limit
            continue
        end
        
        for nbr in neighbors(g, curr)
            w = weights(g)[curr, nbr]
            tentative_g = d_curr + w
            
            if tentative_g < g_scores[nbr]
                g_scores[nbr] = tentative_g
                f_score = tentative_g + h(nbr)
                if f_score <= limit
                    open_set[nbr] = f_score
                end
            end
        end
    end
    return Inf
end

function apply_filtering!(g::SimpleWeightedGraph, instance::SpannerInstance)
    n = nv(g)
    
    # Sort E from longest to shortest
    current_edges = []
    for e in Graphs.edges(g)
        u, v = src(e), dst(e)
        d = weights(g)[u, v]
        push!(current_edges, (u, v, d))
    end
    sort!(current_edges, by = x -> x[3], rev=true)
    
    # Loop
    for (u, v, dist_uv) in current_edges
        rem_edge!(g, u, v)
        
        # Check 1: w(p,q) * delta(p,q) > t * |pq|
        w_pq = instance.w_func(u, v)
        limit_pq = (instance.t * dist_uv) / w_pq
        d_g = get_graph_distance(g, u, v, instance.points, limit_pq)
        
        if d_g > limit_pq
            add_edge!(g, u, v, dist_uv)
        else
            # Else Check 2: For r in S, For s in S: if violation -> break
            valid_flag = Threads.Atomic{Bool}(true)
            
            Threads.@threads for r in 1:n
                if !valid_flag[]; continue; end
                
                # Dijkstra from r
                dists = dijkstra_shortest_paths(g, r).dists
                
                for s in 1:n
                    if r == s; continue; end
                    d_rs = dists[s]
                    
                    if d_rs == Inf
                        Threads.atomic_xchg!(valid_flag, false)
                        break
                    end
                    
                    d_euclid = norm(instance.points[r] - instance.points[s])
                    if d_euclid > 1e-10
                         w_rs = instance.w_func(r, s)
                         limit = (instance.t * d_euclid) / w_rs
                         if d_rs > limit + 1e-9
                             Threads.atomic_xchg!(valid_flag, false)
                             break
                         end
                    end
                end
            end
            
            if !valid_flag[]
                add_edge!(g, u, v, dist_uv)
            end
        end
    end
end

function apply_filtering_unweighted!(g::SimpleWeightedGraph, points::Vector{Point2D}, t::Float64)
    n = nv(g)

    # Sort E from longest to shortest
    current_edges = []
    for e in Graphs.edges(g)
        u, v = src(e), dst(e)
        d = weights(g)[u, v]
        push!(current_edges, (u, v, d))
    end
    sort!(current_edges, by = x -> x[3], rev=true)

    # Loop
    for (u, v, dist_uv) in current_edges
        rem_edge!(g, u, v)

        # Check 1: delta(p,q) > t * |pq|
        limit_pq = t * dist_uv
        d_g = get_graph_distance(g, u, v, points, limit_pq)

        if d_g > limit_pq
            add_edge!(g, u, v, dist_uv)
        else
            # Else Check 2: For all pairs ensure stretch <= t
            valid_flag = Threads.Atomic{Bool}(true)

            Threads.@threads for r in 1:n
                if !valid_flag[]; continue; end

                dists = dijkstra_shortest_paths(g, r).dists
                for s in 1:n
                    if r == s; continue; end
                    d_rs = dists[s]

                    if d_rs == Inf
                        Threads.atomic_xchg!(valid_flag, false)
                        break
                    end

                    d_euclid = norm(points[r] - points[s])
                    if d_euclid > 1e-10
                        limit = t * d_euclid
                        if d_rs > limit + 1e-9
                            Threads.atomic_xchg!(valid_flag, false)
                            break
                        end
                    end
                end
            end

            if !valid_flag[]
                add_edge!(g, u, v, dist_uv)
            end
        end
    end
end

# Angle utilities used by Delta-Greedy
const TWO_PI = 2*pi

ang_diff(a, b) = begin
    diff = abs(a - b)
    diff > pi ? (TWO_PI - diff) : diff
end

function is_cone_covered(cones::Vector{Float64}, direction::Float64, cone_width::Float64)
    half_width = cone_width / 2
    for center in cones
        if ang_diff(center, direction) <= half_width + 1e-9
            return true
        end
    end
    return false
end

add_cone!(cones::Vector{Float64}, direction::Float64) = push!(cones, direction)

# -----------------------------------------------------------------------------
# Implementations
# -----------------------------------------------------------------------------

# 1. Greedy
function run_algorithm(algo::GreedySpanner, instance::SpannerInstance)
    start_time = time()
    n = length(instance.points)
    edges = get_all_edges(n, instance.points)
    
    g = SimpleWeightedGraph(n)
    for (u, v, dist) in edges
        limit = instance.t * dist
        d_g = get_graph_distance(g, u, v, instance.points, limit)
        if d_g > limit
            add_edge!(g, u, v, dist)
        end
    end
    
    runtime = time() - start_time
    return SpannerResult("GreedySpanner", g, runtime, Dict{Symbol, Any}())
end

# 2. w_greedy_with_skelaton
function run_algorithm(algo::WGreedyWithSkeleton, instance::SpannerInstance)
    start_time = time()
    n = length(instance.points)
    
    # 1. E <- Greedy(S, t=skeleton_t)
    edges = get_all_edges(n, instance.points) 
    g = SimpleWeightedGraph(n)
    skeleton_t = algo.skeleton_t
    for (u, v, dist) in edges
        limit = skeleton_t * dist
        d_g = get_graph_distance(g, u, v, instance.points, limit)
        if d_g > limit
            add_edge!(g, u, v, dist)
        end
    end
    
    # 2. Sort all pairs (p,q) in non-decreasing order (already in `edges`)
    # 3. For each (p,q): If w(p,q) * delta_E(p,q) > t * |pq| -> E <- E U {(p,q)}
    
    for (u, v, dist) in edges
        w_uv = instance.w_func(u, v)
        limit = (instance.t * dist) / w_uv
        
        d_g = get_graph_distance(g, u, v, instance.points, limit)
        
        if d_g > limit
            add_edge!(g, u, v, dist)
        end
    end
    
    runtime = time() - start_time
    return SpannerResult("WGreedyWithSkeleton", g, runtime, Dict{Symbol, Any}())
end


# 3. repair_with_skelaton
function run_algorithm(algo::RepairWithSkeleton, instance::SpannerInstance)
    start_time = time()
    n = length(instance.points)
    
    # 1. E <- Greedy(S, t=skeleton_t)
    edges = get_all_edges(n, instance.points)
    g = SimpleWeightedGraph(n)
    skeleton_t = algo.skeleton_t
    for (u, v, dist) in edges
        limit = skeleton_t * dist
        d_g = get_graph_distance(g, u, v, instance.points, limit)
        if d_g > limit
            add_edge!(g, u, v, dist)
        end
    end
    
    # 2. Add light edges: wt(e) <= wt(MST(S))/n
    mst_weight = 0.0
    ds = IntDisjointSets(n)
    edges_count = 0
    for (u, v, dist) in edges
        if !in_same_set(ds, u, v)
            union!(ds, u, v)
            mst_weight += dist
            edges_count += 1
            if edges_count == n - 1; break; end
        end
    end
    threshold = mst_weight / n
    
    for (u, v, dist) in edges
        if dist <= threshold
             add_edge!(g, u, v, dist)
        end
    end
    
    # 3. Sort points by distance to centroid
    center = mean(instance.points)
    perm = sortperm(1:n, by = i -> norm(instance.points[i] - center))
    
    # 4. While loop until valid
    max_iters = 100 
    iter = 0
    
    while true
        iter += 1
        
        added_in_this_pass = false
        
        for p_idx in 1:n
            p = perm[p_idx]
            for q_idx in 1:n
                q = perm[q_idx]
                if p == q; continue; end
                
                curr_q = q
                
                while curr_q != p
                    path_edges = a_star(g, curr_q, p) 
                    
                    if isempty(path_edges)
                        break 
                    end
                    
                    V = Vector{Int}()
                    push!(V, src(path_edges[1])) 
                    for e in path_edges
                        push!(V, dst(e))
                    end
                    
                    path_weight = 0.0
                    restarted = false
                    
                    for i in 2:length(V)
                        u_node = V[i-1]
                        v_node = V[i]
                        d_edge = weights(g)[u_node, v_node]
                        path_weight += d_edge
                        
                        v_1 = V[1]
                        v_i = V[i]
                        
                        w_val = instance.w_func(v_1, v_i)
                        d_euclid = norm(instance.points[v_1] - instance.points[v_i])
                        
                        if w_val * path_weight > instance.t * d_euclid
                            # Violation found!
                            dist_new = d_euclid 
                            add_edge!(g, v_1, v_i, dist_new)
                            
                            curr_q = v_i
                            added_in_this_pass = true
                            restarted = true
                            break 
                        end
                    end
                    
                    if !restarted
                        break 
                    end
                end
            end
        end
        
        if !added_in_this_pass
            break
        end
        if iter > max_iters
            println("RepairWithSkeleton: Max iterations reached")
            break
        end
    end
    
    runtime = time() - start_time
    return SpannerResult("RepairWithSkeleton", g, runtime, Dict{Symbol, Any}())
end

# 4. w_assignment_greedy
function run_algorithm(algo::WAssignmentGreedy, instance::SpannerInstance)
    start_time = time()
    n = length(instance.points)
    
    # 1. E <- Greedy(S, t=skeleton_t)
    # Using existing helper to build greedy skeleton
    # Note: Pseudocode specifies 1.5, we use algo.skeleton_t (default 1.25) as configured.
    edges_all = get_all_edges(n, instance.points) 
    g_skel = SimpleWeightedGraph(n)
    skeleton_t = algo.skeleton_t
    
    for (u, v, dist) in edges_all
        limit = skeleton_t * dist
        d_g = get_graph_distance(g_skel, u, v, instance.points, limit)
        if d_g > limit
            add_edge!(g_skel, u, v, dist)
        end
    end
    
    # Prepare skeleton edges for iteration
    skel_edges = Vector{Tuple{Int, Int, Float64}}()
    for e in edges(g_skel)
        push!(skel_edges, (src(e), dst(e), weight(e)))
    end
    
    # 2. E_all <- S x S (Sorted non-ascending)
    # edges_all is sorted ascending by distance.
    # We will iterate backwards.
    
    # 3. Propagate weights
    W = zeros(Float64, n, n)
    for i in 1:n, j in 1:n
        if i != j; W[i, j] = instance.w_func(i, j); end
    end
    
    t_val = instance.t
    assignments_count = 0
    
    # Iterate longest edges first
    for idx in length(edges_all):-1:1
        (p, q, dist_pq) = edges_all[idx]
        w_pq = W[p, q]
        
        # Optimization: Precompute t/w_pq
        factor = t_val / w_pq
        limit_val = factor * dist_pq
        
        alpha_min = Inf
        best_s, best_r = -1, -1
        
        for (u, v, len_uv) in skel_edges
            # Check both directions for undirected edge (u,v)
            
            # Case 1: s=u, r=v
            # alpha = (t/w) * |pu| + |uv| + (t/w) * |vq|
            d_pu = norm(instance.points[p] - instance.points[u])
            d_vq = norm(instance.points[v] - instance.points[q])
            alpha1 = factor * d_pu + len_uv + factor * d_vq
            
            if alpha1 < alpha_min
                alpha_min = alpha1
                best_s, best_r = u, v
            end
            
            # Case 2: s=v, r=u
            # alpha = (t/w) * |pv| + |vu| + (t/w) * |uq|
            d_pv = norm(instance.points[p] - instance.points[v])
            d_uq = norm(instance.points[u] - instance.points[q])
            alpha2 = factor * d_pv + len_uv + factor * d_uq
            
            if alpha2 < alpha_min
                alpha_min = alpha2
                best_s, best_r = v, u
            end
        end
        
        if alpha_min <= limit_val
            # Update weights: W[p,s] and W[r,q]
            s, r = best_s, best_r
            
            # W[p,s] <- max(W[p,s], W[p,q])
            if p != s
                curr_w = W[p, s]
                if w_pq > curr_w
                    W[p, s] = w_pq
                    W[s, p] = w_pq
                    assignments_count += 1
                end
            end
            
            # W[s,p] <- max(W[s,p], W[p,q]) -- Covered above
            
            # W[r,q] <- max(W[r,q], W[p,q])
            if r != q
                curr_w = W[r, q]
                if w_pq > curr_w
                    W[r, q] = w_pq
                    W[q, r] = w_pq
                    assignments_count += 1
                end
            end
            
            # W[q,r] <- max(W[q,r], W[p,q]) -- Covered above
        end
    end
    
    # 4. Return Weighted_Greedy_With_Skeleton(S, t, w_new)
    # Re-run greedy augmentation on the skeleton using new weights
    g_final = deepcopy(g_skel) 
    
    for (u, v, dist) in edges_all
        w_uv = W[u, v]
        limit = (t_val * dist) / w_uv
        d_g = get_graph_distance(g_final, u, v, instance.points, limit)
        if d_g > limit
            add_edge!(g_final, u, v, dist)
        end
    end
    
    runtime = time() - start_time
    stats = Dict{Symbol, Any}(:assignments_count => assignments_count)
    return SpannerResult("WAssignmentGreedy", g_final, runtime, stats)
end

# 5. filtered_greedy
function run_algorithm(algo::FilteredGreedy, instance::SpannerInstance)
    start_time = time()
    n = length(instance.points)
    
    # 1. E <- Greedy(S, t)
    edges = get_all_edges(n, instance.points)
    g = SimpleWeightedGraph(n)
    for (u, v, dist) in edges
        limit = instance.t * dist
        d_g = get_graph_distance(g, u, v, instance.points, limit)
        if d_g > limit
            add_edge!(g, u, v, dist)
        end
    end
    
    # 2. Filtering
    apply_filtering!(g, instance)
    
    runtime = time() - start_time
    return SpannerResult("FilteredGreedy", g, runtime, Dict{Symbol, Any}())
end

# 6. filtered_w_greedy_with_skeleton
function run_algorithm(algo::FilteredWGreedyWithSkeleton, instance::SpannerInstance)
    start_time = time()
    
    # 1. Start with WGreedyWithSkeleton
    base_algo = WGreedyWithSkeleton(algo.skeleton_t)
    base_res = run_algorithm(base_algo, instance)
    g = base_res.graph
    
    # 2. Filtering
    apply_filtering!(g, instance)
    
    runtime = time() - start_time
    return SpannerResult("FilteredWGreedyWithSkeleton", g, runtime, Dict{Symbol, Any}())
end

# 7. delta_greedy
function run_algorithm(algo::DeltaGreedy, instance::SpannerInstance)
    delta = algo.delta
    if delta < 1.0
        error("DeltaGreedy requires delta >= 1.0")
    end
    start_time = time()
    points = instance.points
    t = instance.t
    n = length(points)
    edges = get_all_edges(n, points)
    g = SimpleWeightedGraph(n)

    cone_width = 2 * asin(1 / (2 * delta))
    cone_sets = [Float64[] for _ in 1:n]

    for (u, v, dist_uv) in edges
        theta_uv = atan(points[v][2] - points[u][2], points[v][1] - points[u][1])
        theta_vu = atan(points[u][2] - points[v][2], points[u][1] - points[v][1])

        covered_u = is_cone_covered(cone_sets[u], theta_uv, cone_width)
        covered_v = is_cone_covered(cone_sets[v], theta_vu, cone_width)

        # δ-Greedy skips the expensive query only when both directions are already covered
        if covered_u && covered_v
            continue
        end

        limit_t = t * dist_uv
        d_g = get_graph_distance(g, u, v, points, limit_t)

        if d_g > limit_t
            add_edge!(g, u, v, dist_uv)
            add_cone!(cone_sets[u], theta_uv)
            add_cone!(cone_sets[v], theta_vu)
        elseif d_g <= delta * dist_uv
            # Path is short enough to mark the cone as covered even without adding the edge
            add_cone!(cone_sets[u], theta_uv)
            add_cone!(cone_sets[v], theta_vu)
        end
    end

    runtime = time() - start_time
    stats = Dict{Symbol, Any}(:delta => delta, :cone_width => cone_width)
    return SpannerResult("DeltaGreedy", g, runtime, stats)
end

# 8. filtered_delta_greedy
function run_algorithm(algo::FilteredDeltaGreedy, instance::SpannerInstance)
    # Build delta-greedy graph
    base_res = run_algorithm(DeltaGreedy(algo.delta), instance)
    g = base_res.graph

    # Filter with respect to the provided t
    filter_start = time()
    apply_filtering!(g, instance)
    filter_time = time() - filter_start

    stats = copy(base_res.stats)
    runtime = base_res.runtime_seconds + filter_time
    return SpannerResult("FilteredDeltaGreedy", g, runtime, stats)
end

# 9. sqrt(t)-greedy + filter (Algorithm A)
function run_algorithm(::SqrtGreedyFilter, instance::SpannerInstance)
    start_time = time()
    points = instance.points
    w_func = instance.w_func
    t_target = instance.t

    t_sqrt = sqrt(t_target)
    greedy_instance = SpannerInstance(points, w_func, t_sqrt)
    greedy_res = run_algorithm(GreedySpanner(), greedy_instance)
    g = greedy_res.graph

    filter_instance = SpannerInstance(points, w_func, t_target)
    apply_filtering!(g, filter_instance)

    runtime = time() - start_time
    stats = Dict{Symbol, Any}(
        :t_sqrt => t_sqrt,
        :greedy_stage_time => greedy_res.runtime_seconds
    )
    return SpannerResult("AlgoA_SqrtGreedyFilter", g, runtime, stats)
end

# 10. multi-stage filter with refinement (Algorithm B)
function run_algorithm(algo::HybridFilterWithRefinement, instance::SpannerInstance)
    if algo.epsilon <= 0.0 || algo.epsilon >= 1.0
        error("HybridFilterWithRefinement requires 0 < epsilon < 1")
    end

    start_time = time()
    points = instance.points
    w_func = instance.w_func
    t_target = instance.t
    t_quarter = t_target ^ 0.25
    t_prime = t_target ^ (1 - algo.epsilon)
    t_ratio = t_target / t_prime  # equals t_target^epsilon

    # Step 1: t^0.25 greedy
    quarter_instance = SpannerInstance(points, w_func, t_quarter)
    quarter_res = run_algorithm(GreedySpanner(), quarter_instance)
    g = quarter_res.graph

    # Step 2: filter with t'
    filter_instance = SpannerInstance(points, w_func, t_prime)
    apply_filtering!(g, filter_instance)

    # Step 3: greedy augmentation with t/t'
    edges = get_all_edges(length(points), points)
    for (u, v, dist_uv) in edges
        limit = t_ratio * dist_uv
        d_g = get_graph_distance(g, u, v, points, limit)
        if d_g > limit
            add_edge!(g, u, v, dist_uv)
        end
    end

    runtime = time() - start_time
    stats = Dict{Symbol, Any}(
        :epsilon => algo.epsilon,
        :t_quarter => t_quarter,
        :t_prime => t_prime,
        :t_ratio => t_ratio,
        :quarter_stage_time => quarter_res.runtime_seconds
    )
    algo_name = @sprintf("AlgoB_eps=%.2f", algo.epsilon)
    return SpannerResult(algo_name, g, runtime, stats)
end

# 11. greedy with short-edge seeding
function run_algorithm(::GreedyWithShortEdges, instance::SpannerInstance)
    start_time = time()
    points = instance.points
    t_target = instance.t
    n = length(points)
    edges = get_all_edges(n, points)

    mst_w = compute_mst_weight_local(points)
    threshold = mst_w / n

    g = SimpleWeightedGraph(n)

    # Seed short edges
    for (u, v, dist) in edges
        if dist <= threshold
            add_edge!(g, u, v, dist)
        end
    end

    # Greedy augmentation at target t
    for (u, v, dist) in edges
        if dist <= threshold
            continue
        end
        limit = t_target * dist
        d_g = get_graph_distance(g, u, v, points, limit)
        if d_g > limit
            add_edge!(g, u, v, dist)
        end
    end

    runtime = time() - start_time
    stats = Dict{Symbol, Any}(:seed_threshold => threshold, :mst_weight => mst_w)
    return SpannerResult("GreedyWithShortEdges", g, runtime, stats)
end

# 12. filtered sqrt-greedy with short-edge seeding
function run_algorithm(::FilteredSqrtGreedyWithShortEdges, instance::SpannerInstance)
    start_time = time()
    points = instance.points
    w_func = instance.w_func
    t_target = instance.t
    n = length(points)
    edges = get_all_edges(n, points)

    mst_w = compute_mst_weight_local(points)
    threshold = mst_w / n

    g = SimpleWeightedGraph(n)

    # Seed short edges
    for (u, v, dist) in edges
        if dist <= threshold
            add_edge!(g, u, v, dist)
        end
    end

    # Greedy with sqrt(t)
    t_sqrt = sqrt(t_target)
    for (u, v, dist) in edges
        if dist <= threshold
            continue
        end
        limit = t_sqrt * dist
        d_g = get_graph_distance(g, u, v, points, limit)
        if d_g > limit
            add_edge!(g, u, v, dist)
        end
    end

    # Filter at target t
    filter_instance = SpannerInstance(points, w_func, t_target)
    apply_filtering!(g, filter_instance)

    runtime = time() - start_time
    stats = Dict{Symbol, Any}(
        :seed_threshold => threshold,
        :mst_weight => mst_w,
        :t_sqrt => t_sqrt
    )
    return SpannerResult("FilteredSqrtGreedyWithShortEdges", g, runtime, stats)
end

# 13. Filter starting from complete graph
function run_algorithm(::FullFilter, instance::SpannerInstance)
    start_time = time()
    n = length(instance.points)
    g = SimpleWeightedGraph(n)
    for i in 1:n-1
        for j in i+1:n
            d = norm(instance.points[i] - instance.points[j])
            add_edge!(g, i, j, d)
        end
    end
    apply_filtering!(g, instance)
    runtime = time() - start_time
    return SpannerResult("FullFilter", g, runtime, Dict{Symbol, Any}())
end

# 13b. Filter starting from complete graph (unweighted)
function run_algorithm(::FullFilterUnweighted, instance::SpannerInstance)
    start_time = time()
    n = length(instance.points)
    g = SimpleWeightedGraph(n)
    for i in 1:n-1
        for j in i+1:n
            d = norm(instance.points[i] - instance.points[j])
            add_edge!(g, i, j, d)
        end
    end
    apply_filtering_unweighted!(g, instance.points, instance.t)
    runtime = time() - start_time
    return SpannerResult("FullFilterUnweighted", g, runtime, Dict{Symbol, Any}())
end

# 14. Yao Graph
function run_algorithm(algo::YaoGraph, instance::SpannerInstance)
    start_time = time()
    points = instance.points
    n = length(points)
    k = algo.k > 0 ? algo.k : cones_for_t(instance.t)
    cone_width = 2pi / k

    g = SimpleWeightedGraph(n)
    for u in 1:n
        best_dist = fill(Inf, k)
        best_v = fill(0, k)
        for v in 1:n
            v == u && continue
            theta = atan(points[v][2] - points[u][2], points[v][1] - points[u][1])
            idx = cone_index(theta, cone_width, k)
            dist = norm(points[v] - points[u])
            if dist < best_dist[idx]
                best_dist[idx] = dist
                best_v[idx] = v
            end
        end
        for i in 1:k
            v = best_v[i]
            v == 0 && continue
            add_edge!(g, u, v, best_dist[i])
        end
    end

    runtime = time() - start_time
    return SpannerResult("YaoGraph_k=$k", g, runtime, Dict{Symbol, Any}(:k => k))
end

# 15. Theta Graph
function run_algorithm(algo::ThetaGraph, instance::SpannerInstance)
    start_time = time()
    points = instance.points
    n = length(points)
    k = algo.k > 0 ? algo.k : cones_for_t(instance.t)
    cone_width = 2pi / k

    g = SimpleWeightedGraph(n)
    for u in 1:n
        best_proj = fill(Inf, k)
        best_v = fill(0, k)
        best_dist = fill(Inf, k)
        for v in 1:n
            v == u && continue
            dx = points[v][1] - points[u][1]
            dy = points[v][2] - points[u][2]
            theta = atan(dy, dx)
            idx = cone_index(theta, cone_width, k)
            bisector = (idx - 0.5) * cone_width
            proj = dx * cos(bisector) + dy * sin(bisector)
            dist = norm(points[v] - points[u])
            if proj < best_proj[idx]
                best_proj[idx] = proj
                best_v[idx] = v
                best_dist[idx] = dist
            end
        end
        for i in 1:k
            v = best_v[i]
            v == 0 && continue
            add_edge!(g, u, v, best_dist[i])
        end
    end

    runtime = time() - start_time
    return SpannerResult("ThetaGraph_k=$k", g, runtime, Dict{Symbol, Any}(:k => k))
end

# 16. WSPD Spanner
function run_algorithm(algo::WSPDSpanner, instance::SpannerInstance)
    start_time = time()
    points = instance.points
    n = length(points)
    s = algo.s > 0 ? algo.s : (instance.t > 1.0 ? 4.0 * (instance.t + 1.0) / (instance.t - 1.0) : 4.0)

    root = build_split_tree(points, collect(1:n))
    pairs = Tuple{Int, Int}[]
    wspd_pairs!(pairs, root, root, s)

    g = SimpleWeightedGraph(n)
    for (u, v) in pairs
        dist = norm(points[u] - points[v])
        add_edge!(g, u, v, dist)
    end

    runtime = time() - start_time
    return SpannerResult(@sprintf("WSPD_s=%.2f", s), g, runtime, Dict{Symbol, Any}(:s => s, :pairs => length(pairs)))
end

function apply_filtering_removed_only!(g::SimpleWeightedGraph, instance::SpannerInstance)
    n = nv(g)
    
    # Sort E from longest to shortest
    current_edges = []
    for e in Graphs.edges(g)
        u, v = src(e), dst(e)
        d = weights(g)[u, v]
        push!(current_edges, (u, v, d))
    end
    sort!(current_edges, by = x -> x[3], rev=true)
    
    removed_edges = Vector{Tuple{Int, Int, Float64}}()
    
    # Loop
    for (u, v, dist_uv) in current_edges
        rem_edge!(g, u, v)
        
        # Check 1: w(p,q) * delta(p,q) > t * |pq|
        w_pq = instance.w_func(u, v)
        limit_pq = (instance.t * dist_uv) / w_pq
        d_g = get_graph_distance(g, u, v, instance.points, limit_pq)
        
        if d_g > limit_pq
            add_edge!(g, u, v, dist_uv)
        else
            # Check 2: Check removed edges
            valid_flag = Threads.Atomic{Bool}(true)
            
            Threads.@threads for i in 1:length(removed_edges)
                if !valid_flag[]; continue; end
                (ru, rv, rdist) = removed_edges[i]
                
                w_r = instance.w_func(ru, rv)
                limit_r = (instance.t * rdist) / w_r
                
                d_r = get_graph_distance(g, ru, rv, instance.points, limit_r)
                if d_r > limit_r
                    Threads.atomic_xchg!(valid_flag, false)
                end
            end
            
            if valid_flag[]
                push!(removed_edges, (u, v, dist_uv))
            else
                add_edge!(g, u, v, dist_uv)
            end
        end
    end
end

# 17. Filter (Removed Check)
function run_algorithm(::FilterRemovedCheck, instance::SpannerInstance)
    start_time = time()
    n = length(instance.points)
    g = SimpleWeightedGraph(n)
    for i in 1:n-1
        for j in i+1:n
            d = norm(instance.points[i] - instance.points[j])
            add_edge!(g, i, j, d)
        end
    end
    apply_filtering_removed_only!(g, instance)
    runtime = time() - start_time
    return SpannerResult("FilterRemovedCheck", g, runtime, Dict{Symbol, Any}())
end

# 18. Filtered Sqrt Greedy (Check All Pairs)
function run_algorithm(::FilteredSqrtGreedy, instance::SpannerInstance)
    start_time = time()
    n = length(instance.points)
    
    # 1. E <- Greedy(S, sqrt(t))
    t_sqrt = sqrt(instance.t)
    greedy_instance = SpannerInstance(instance.points, instance.w_func, t_sqrt)
    greedy_res = run_algorithm(GreedySpanner(), greedy_instance)
    g = greedy_res.graph
    
    # 2. Filtering (Check All Pairs)
    # Re-use existing apply_filtering! which implements the P*P check
    apply_filtering!(g, instance)
    
    runtime = time() - start_time
    return SpannerResult("FilteredSqrtGreedy", g, runtime, Dict{Symbol, Any}(:t_sqrt => t_sqrt))
end

end
