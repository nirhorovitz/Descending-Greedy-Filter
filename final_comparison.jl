using Pkg
Pkg.activate(joinpath(@__DIR__, "..", "SpannerComparison"))

using SpannerComparison
using SpannerComparison.CoreTypes
using SpannerComparison.Algorithms
using SpannerComparison.Generators
using SpannerComparison.Analysis
using SpannerComparison.Visualization
using SpannerComparison.IOUtils

using Dates
using Printf
using Plots
using LinearAlgebra
using Graphs
using SimpleWeightedGraphs
using JLD2

# =============================================================================
# DGF (Descending Greedy Filter) with recursive binary search
# Port of faster_dgf.py
# =============================================================================

function compute_dist_matrix(points::Vector{Point2D})
    n = length(points)
    D = Matrix{Float64}(undef, n, n)
    for i in 1:n
        D[i, i] = 0.0
        for j in (i+1):n
            d = norm(points[i] - points[j])
            D[i, j] = d
            D[j, i] = d
        end
    end
    return D
end

mutable struct DGFContext
    const adj::Matrix{Float64}            # n×n, Inf = no edge
    const t_dist::Matrix{Float64}         # precomputed t .* dist_matrix
    const n::Int
    const nbrs::Vector{Vector{Int}}       # adjacency lists for fast Dijkstra
    const thread_dists::Vector{Vector{Float64}}
    const thread_heaps::Vector{Vector{Tuple{Float64,Int}}}
end

function DGFContext(n::Int, dist_matrix::Matrix{Float64}, t::Float64)
    adj = fill(Inf, n, n)
    for i in 1:n; adj[i, i] = 0.0; end
    t_dist = t .* dist_matrix
    nbrs = [Int[] for _ in 1:n]
    nt = max(Threads.nthreads(), Threads.maxthreadid())
    thread_dists = [Vector{Float64}(undef, n) for _ in 1:nt]
    thread_heaps = [Tuple{Float64,Int}[] for _ in 1:nt]
    return DGFContext(adj, t_dist, n, nbrs, thread_dists, thread_heaps)
end

function dgf_add_edge!(ctx::DGFContext, u::Int, v::Int, w::Float64)
    @inbounds ctx.adj[u, v] = w
    @inbounds ctx.adj[v, u] = w
    push!(ctx.nbrs[u], v)
    push!(ctx.nbrs[v], u)
end

function dgf_rem_edge!(ctx::DGFContext, u::Int, v::Int)
    @inbounds ctx.adj[u, v] = Inf
    @inbounds ctx.adj[v, u] = Inf
    # Remove from neighbor lists (swap-remove for O(1))
    nbrs_u = ctx.nbrs[u]
    for i in eachindex(nbrs_u)
        if nbrs_u[i] == v
            nbrs_u[i] = nbrs_u[end]
            pop!(nbrs_u)
            break
        end
    end
    nbrs_v = ctx.nbrs[v]
    for i in eachindex(nbrs_v)
        if nbrs_v[i] == u
            nbrs_v[i] = nbrs_v[end]
            pop!(nbrs_v)
            break
        end
    end
end

"""
Heap-based Dijkstra from `src` with inline violation checking.
Returns true if a violation was found.
"""
function dijkstra_violation_check!(ctx::DGFContext, src::Int, violated::Threads.Atomic{Bool})
    tid = Threads.threadid()
    dist = ctx.thread_dists[tid]
    n = ctx.n
    adj = ctx.adj
    t_dist = ctx.t_dist

    @inbounds for i in 1:n
        dist[i] = Inf
    end
    dist[src] = 0.0

    # Use a simple binary min-heap (pre-allocated vector)
    heap = ctx.thread_heaps[tid]
    empty!(heap)
    push!(heap, (0.0, src))

    settled = 0
    while !isempty(heap)
        violated[] && return false

        # Pop min (manual heap pop for speed)
        d_u, u = heap[1]
        heap[1] = heap[end]
        pop!(heap)
        _siftdown!(heap, 1)

        @inbounds d_u > dist[u] && continue  # stale entry
        settled += 1

        # Inline violation check
        if u != src
            @inbounds if d_u > t_dist[src, u] + 1e-9
                Threads.atomic_xchg!(violated, true)
                return true
            end
        end

        # Relax neighbors
        @inbounds for v in ctx.nbrs[u]
            new_d = d_u + adj[u, v]
            if new_d < dist[v]
                dist[v] = new_d
                push!(heap, (new_d, v))
                _siftup!(heap, length(heap))
            end
        end
    end

    # Check unreachable vertices
    @inbounds for j in 1:n
        if j != src && dist[j] > t_dist[src, j] + 1e-9
            Threads.atomic_xchg!(violated, true)
            return true
        end
    end

    return false
end

# Minimal binary heap helpers (inlined for performance)
@inline function _siftdown!(heap::Vector{Tuple{Float64,Int}}, i::Int)
    n = length(heap)
    @inbounds while true
        smallest = i
        l = 2i
        r = 2i + 1
        if l <= n && heap[l][1] < heap[smallest][1]
            smallest = l
        end
        if r <= n && heap[r][1] < heap[smallest][1]
            smallest = r
        end
        smallest == i && break
        heap[i], heap[smallest] = heap[smallest], heap[i]
        i = smallest
    end
end

@inline function _siftup!(heap::Vector{Tuple{Float64,Int}}, i::Int)
    @inbounds while i > 1
        p = i >> 1
        heap[i][1] >= heap[p][1] && break
        heap[i], heap[p] = heap[p], heap[i]
        i = p
    end
end

"""
Single-pair Dijkstra: returns shortest path distance from src to dst.
Stops early once dst is settled.
"""
function single_pair_distance(ctx::DGFContext, src::Int, dst::Int)
    tid = Threads.threadid()
    dist = ctx.thread_dists[tid]
    n = ctx.n
    adj = ctx.adj

    @inbounds for i in 1:n
        dist[i] = Inf
    end
    dist[src] = 0.0

    heap = ctx.thread_heaps[tid]
    empty!(heap)
    push!(heap, (0.0, src))

    while !isempty(heap)
        d_u, u = heap[1]
        heap[1] = heap[end]
        pop!(heap)
        _siftdown!(heap, 1)

        @inbounds d_u > dist[u] && continue

        u == dst && return d_u

        @inbounds for v in ctx.nbrs[u]
            new_d = d_u + adj[u, v]
            if new_d < dist[v]
                dist[v] = new_d
                push!(heap, (new_d, v))
                _siftup!(heap, length(heap))
            end
        end
    end

    return Inf
end

"""
Fast pre-check: test a few removed edges' own pairs for violations.
Returns true if a violation was found (avoiding full APSP).
"""
function quick_violation_check(ctx::DGFContext, edge_list::Vector{Tuple{Int,Int,Float64}})
    n_check = min(length(edge_list), 8)
    for i in 1:n_check
        u, v, _ = edge_list[i]
        d_uv = single_pair_distance(ctx, u, v)
        @inbounds if d_uv > ctx.t_dist[u, v] + 1e-9
            return true
        end
    end
    return false
end

"""
Check if any pair violates the t-spanner property.
"""
function any_violation(ctx::DGFContext)
    ctx.n <= 1 && return false
    violated = Threads.Atomic{Bool}(false)
    Threads.@threads :static for src in 1:ctx.n
        violated[] && continue
        dijkstra_violation_check!(ctx, src, violated)
    end
    return violated[]
end

"""
Recursive binary search on `edge_list` (sorted descending by weight).
All edges in `edge_list` are already removed from ctx.
Returns number of edges removed.
"""
mutable struct DGFStats
    apsp_count::Int
    apsp_total_ms::Float64
    quick_hits::Int
    quick_misses::Int
end
DGFStats() = DGFStats(0, 0.0, 0, 0)

"""
Process `edge_list` one edge at a time. Assumes all edges are currently removed.
Restores them all, then for each edge tries removing it; if a violation arises,
restores it. This is the classic greedy filter loop, used as a fallback once
the binary search has cleared the bulk of the edges.
"""
function dgf_process_one_by_one!(ctx::DGFContext, edge_list::Vector{Tuple{Int,Int,Float64}},
                                  cleared::Ref{Int}, decided::Ref{Int}, total::Int,
                                  stats::DGFStats, depth::Int)
    # All edges in edge_list are currently removed; restore them first
    for (u, v, w) in edge_list
        dgf_add_edge!(ctx, u, v, w)
    end

    pct_start = round(100.0 * decided[] / total, digits=1)
    println("    [dgf] depth=$depth: switching to one-by-one for $(length(edge_list)) remaining edges (decided=$(decided[])/$total = $(pct_start)%, cleared=$(cleared[]))")

    removed = 0
    log_every = max(1, length(edge_list) ÷ 20)
    for (idx, (u, v, w)) in enumerate(edge_list)
        dgf_rem_edge!(ctx, u, v)

        # Quick check: only the (u,v) own pair needs to be verified for a single-edge removal
        d_uv = single_pair_distance(ctx, u, v)
        if d_uv > ctx.t_dist[u, v] + 1e-9
            has_violation = true
            stats.quick_hits += 1
        else
            stats.quick_misses += 1
            t_apsp = time_ns()
            has_violation = any_violation(ctx)
            apsp_ms = (time_ns() - t_apsp) / 1e6
            stats.apsp_count += 1
            stats.apsp_total_ms += apsp_ms
        end

        if has_violation
            dgf_add_edge!(ctx, u, v, w)
        else
            removed += 1
            cleared[] += 1
        end
        decided[] += 1

        if idx % log_every == 0 || idx == length(edge_list)
            pct = round(100.0 * decided[] / total, digits=1)
            println("    [dgf-1by1] processed $idx/$(length(edge_list)) (removed=$removed), total decided $(decided[])/$total ($(pct)%)")
        end
    end
    return removed
end

function dgf_bisect!(ctx::DGFContext, edge_list::Vector{Tuple{Int,Int,Float64}},
                      cleared::Ref{Int}, decided::Ref{Int}, total::Int,
                      stats::DGFStats, depth::Int=0)
    if isempty(edge_list)
        return 0
    end

    # Once 70% of edges have been decided (cleared or restored as necessary),
    # switch from binary search to one-by-one processing.
    if total > 0 && decided[] >= 0.7 * total
        return dgf_process_one_by_one!(ctx, edge_list, cleared, decided, total, stats, depth)
    end

    # Fast pre-check: test removed edges' own pairs before full APSP
    has_violation = quick_violation_check(ctx, edge_list)
    if has_violation
        stats.quick_hits += 1
    else
        stats.quick_misses += 1
        t_apsp = time_ns()
        has_violation = any_violation(ctx)
        apsp_ms = (time_ns() - t_apsp) / 1e6
        stats.apsp_count += 1
        stats.apsp_total_ms += apsp_ms
    end
    if !has_violation
        # All edges in this batch are removable
        cleared[] += length(edge_list)
        decided[] += length(edge_list)
        if length(edge_list) >= 4
            pct = round(100.0 * decided[] / total, digits=1)
            avg_ms = stats.apsp_count > 0 ? round(stats.apsp_total_ms / stats.apsp_count, digits=1) : 0.0
            println("    [dgf] depth=$depth: cleared $(length(edge_list)) edges, total decided $(decided[])/$total ($(pct)%, cleared=$(cleared[])) [apsp=$(stats.apsp_count), avg=$(avg_ms)ms, quick_hits=$(stats.quick_hits)]")
        end
        return length(edge_list)
    end

    # Single edge with violation -> it is necessary, restore it
    if length(edge_list) == 1
        u, v, w = edge_list[1]
        dgf_add_edge!(ctx, u, v, w)
        decided[] += 1
        return 0
    end

    # Restore all edges, then split and recurse
    for (u, v, w) in edge_list
        dgf_add_edge!(ctx, u, v, w)
    end

    mid = length(edge_list) ÷ 2
    first_half = edge_list[1:mid]       # longer edges
    second_half = edge_list[mid+1:end]  # shorter edges

    # Process first half (longer edges first)
    for (u, v, _) in first_half
        dgf_rem_edge!(ctx, u, v)
    end
    r1 = dgf_bisect!(ctx, first_half, cleared, decided, total, stats, depth + 1)

    # Process second half
    for (u, v, _) in second_half
        dgf_rem_edge!(ctx, u, v)
    end
    r2 = dgf_bisect!(ctx, second_half, cleared, decided, total, stats, depth + 1)

    return r1 + r2
end

"""
Apply DGF to graph `g` in-place. Returns number of edges removed.
"""
function apply_dgf!(g::SimpleWeightedGraph, dist_matrix::Matrix{Float64}, t::Float64)
    n = nv(g)
    ctx = DGFContext(n, dist_matrix, t)

    edge_list = Tuple{Int,Int,Float64}[]
    for e in edges(g)
        u, v, w = src(e), dst(e), weight(e)
        push!(edge_list, (u, v, w))
        dgf_add_edge!(ctx, u, v, w)
    end
    sort!(edge_list, by=x -> x[3], rev=true)  # descending

    n_before = length(edge_list)
    println("    [dgf] starting: $(n_before) edges, n=$n, t=$t, threads=$(Threads.nthreads())")

    # Remove all edges
    for (u, v, _) in edge_list
        dgf_rem_edge!(ctx, u, v)
    end

    cleared = Ref(0)
    decided = Ref(0)
    stats = DGFStats()
    removed = dgf_bisect!(ctx, edge_list, cleared, decided, n_before, stats)
    avg_ms = stats.apsp_count > 0 ? round(stats.apsp_total_ms / stats.apsp_count, digits=1) : 0.0
    println("    [dgf] done: removed=$removed, remaining=$(n_before - removed)")
    println("    [dgf-profile] apsp_count=$(stats.apsp_count), apsp_total=$(round(stats.apsp_total_ms / 1000, digits=1))s, avg=$(avg_ms)ms/apsp, quick_hits=$(stats.quick_hits), quick_misses=$(stats.quick_misses)")

    # Rebuild SimpleWeightedGraph from ctx.adj for downstream compatibility
    for e in collect(edges(g))
        rem_edge!(g, src(e), dst(e))
    end
    @inbounds for i in 1:n
        for j in (i+1):n
            if ctx.adj[i, j] < Inf
                add_edge!(g, i, j, ctx.adj[i, j])
            end
        end
    end

    return removed
end

# =============================================================================
# Greedy on a given subset of candidate edges
# =============================================================================

function greedy_on_edges(points::Vector{Point2D}, t::Float64,
                          candidate_edges::Vector{Tuple{Int,Int,Float64}})
    n = length(points)
    sorted_edges = sort(candidate_edges, by=x -> x[3])  # ascending by distance
    g = SimpleWeightedGraph(n)
    for (u, v, dist) in sorted_edges
        limit = t * dist
        d_g = Algorithms.get_graph_distance(g, u, v, points, limit)
        if d_g > limit
            add_edge!(g, u, v, dist)
        end
    end
    return g
end

# =============================================================================
# Edge list helpers
# =============================================================================

function extract_edge_list(g::SimpleWeightedGraph)
    el = Tuple{Int,Int,Float64}[]
    for e in edges(g)
        push!(el, (src(e), dst(e), weight(e)))
    end
    return el
end

# =============================================================================
# Algorithm wrappers
# =============================================================================

function run_greedy(instance::SpannerInstance)
    println("  -> Running Greedy...")
    start_time = time()
    res = Algorithms.run_algorithm(Algorithms.GreedySpanner(), instance)
    runtime = time() - start_time
    return SpannerResult("Greedy", res.graph, runtime, Dict{Symbol,Any}())
end

function run_sqrt_greedy_dgf(instance::SpannerInstance, dist_matrix::Matrix{Float64})
    t = instance.t
    sqrt_t = sqrt(t)
    println("  -> Running sqrt(t)-Greedy + DGF  [sqrt(t)=$(round(sqrt_t, digits=4))]...")
    start_time = time()

    sqrt_instance = SpannerInstance(instance.points, instance.w_func, sqrt_t)
    greedy_res = Algorithms.run_algorithm(Algorithms.GreedySpanner(), sqrt_instance)
    g = deepcopy(greedy_res.graph)
    edges_after_greedy = ne(g)

    removed = apply_dgf!(g, dist_matrix, t)

    runtime = time() - start_time
    stats = Dict{Symbol,Any}(:sqrt_t => sqrt_t,
                              :edges_after_greedy => edges_after_greedy,
                              :dgf_removed => removed)
    return SpannerResult("sqrt(t)-Greedy+DGF", g, runtime, stats)
end

function run_yao(instance::SpannerInstance)
    println("  -> Running Yao...")
    start_time = time()
    res = Algorithms.run_algorithm(Algorithms.YaoGraph(), instance)
    runtime = time() - start_time
    return SpannerResult("Yao", res.graph, runtime,
                          Dict{Symbol,Any}(:k => get(res.stats, :k, 0)))
end

function run_yao_dgf(instance::SpannerInstance, dist_matrix::Matrix{Float64})
    println("  -> Running Yao + DGF...")
    start_time = time()

    yao_res = Algorithms.run_algorithm(Algorithms.YaoGraph(), instance)
    g = deepcopy(yao_res.graph)
    edges_after_yao = ne(g)

    removed = apply_dgf!(g, dist_matrix, instance.t)

    runtime = time() - start_time
    stats = Dict{Symbol,Any}(:k => get(yao_res.stats, :k, 0),
                              :edges_after_yao => edges_after_yao,
                              :dgf_removed => removed)
    return SpannerResult("Yao+DGF", g, runtime, stats)
end

function run_dgf(instance::SpannerInstance, dist_matrix::Matrix{Float64})
    println("  -> Running DGF (complete graph)...")
    start_time = time()

    n = length(instance.points)
    g = SimpleWeightedGraph(n)
    for i in 1:n
        for j in (i+1):n
            add_edge!(g, i, j, dist_matrix[i, j])
        end
    end
    n_complete = ne(g)

    removed = apply_dgf!(g, dist_matrix, instance.t)

    runtime = time() - start_time
    stats = Dict{Symbol,Any}(:edges_complete => n_complete,
                              :dgf_removed => removed)
    return SpannerResult("DGF", g, runtime, stats)
end

function run_sqrt_yao_sqrt_greedy(instance::SpannerInstance)
    t = instance.t
    sqrt_t = sqrt(t)
    println("  -> Running sqrt(t)-Yao + sqrt(t)-Greedy  [sqrt(t)=$(round(sqrt_t, digits=4))]...")
    start_time = time()

    # Step 1: Yao with sqrt(t)
    sqrt_instance = SpannerInstance(instance.points, instance.w_func, sqrt_t)
    yao_res = Algorithms.run_algorithm(Algorithms.YaoGraph(), sqrt_instance)
    yao_edges = extract_edge_list(yao_res.graph)
    edges_after_yao = length(yao_edges)

    # Step 2: Greedy with sqrt(t) on Yao edges only
    g = greedy_on_edges(instance.points, sqrt_t, yao_edges)

    runtime = time() - start_time
    stats = Dict{Symbol,Any}(:sqrt_t => sqrt_t,
                              :k => get(yao_res.stats, :k, 0),
                              :edges_after_yao => edges_after_yao)
    return SpannerResult("sqrt(t)-Yao+sqrt(t)-Greedy", g, runtime, stats)
end

# =============================================================================
# Table drawing (unchanged)
# =============================================================================

function draw_table_image(results, N, T, seed, filepath)
    headers = ["Algorithm", "Edges", "Weight", "WtRatio", "MaxDeg", "AvgDeg", "MaxStrch", "Valid", "Time(s)"]
    data = Matrix{String}(undef, length(results), length(headers))

    for (i, res) in enumerate(results)
        s = res.stats
        data[i, 1] = res.algorithm_name
        data[i, 2] = string(get(s, :num_edges, ""))
        data[i, 3] = @sprintf("%.2f", get(s, :total_weight, NaN))
        data[i, 4] = @sprintf("%.2f", get(s, :weight_ratio, NaN))
        data[i, 5] = string(get(s, :max_degree, ""))
        data[i, 6] = @sprintf("%.2f", get(s, :avg_degree, NaN))
        data[i, 7] = @sprintf("%.4f", get(s, :max_stretch_found, NaN))
        data[i, 8] = string(get(s, :is_valid_spanner, "N/A"))
        data[i, 9] = @sprintf("%.4f", res.runtime_seconds)
    end

    col_widths = [2.5, 1.2, 1.5, 1.2, 1.2, 1.2, 1.6, 1.0, 1.5]
    total_width = sum(col_widths)

    x_centers = Float64[]
    current_x = 0.0
    for w in col_widths
        push!(x_centers, current_x + w / 2)
        current_x += w
    end

    n_rows = length(results)
    f_title = font(16, :bold, "Helvetica")
    f_head = font(12, :bold, "Helvetica")
    f_cell = font(12, "Helvetica")

    plot_height = 150 + n_rows * 35
    p = plot(
        axis = false,
        grid = false,
        ticks = false,
        border = :none,
        size = (1400, plot_height),
        xlim = (0, total_width),
        ylim = (-n_rows - 1.5, 1),
    )

    title_str = "N=$N | t=$T | seed=$seed"
    annotate!(p, total_width / 2, 0.5, text(title_str, f_title, :black, :center))

    for j in 1:length(headers)
        annotate!(p, x_centers[j], -0.5, text(headers[j], f_head, :black, :center))
    end

    for i in 1:n_rows
        for j in 1:length(headers)
            if j == 1
                x_pos = x_centers[j] - col_widths[j] / 2 + 0.2
                annotate!(p, x_pos, -0.5 - i, text(data[i, j], f_cell, :black, :left))
            else
                annotate!(p, x_centers[j], -0.5 - i, text(data[i, j], f_cell, :black, :center))
            end
        end
    end

    savefig(p, filepath)
end

# =============================================================================
# Arg parsing (unchanged)
# =============================================================================

function parse_t_values(args)
    default_ts = [1.05, 1.1, 1.2, 1.25, 1.4, 1.5, 1.75, 2.0]
    if length(args) < 2
        return default_ts
    end
    t_arg = args[2]
    if occursin(",", t_arg)
        return [parse(Float64, strip(x)) for x in split(t_arg, ",")]
    else
        return [parse(Float64, t_arg)]
    end
end

# =============================================================================
# Main
# =============================================================================

function main()
    ENV["GKS_ENCODING"] = "utf8"
    default(fontfamily="Helvetica")
    gr()

    run_dgf_algo = !("--no-dgf" in ARGS)
    pos_args = filter(a -> !startswith(a, "--"), ARGS)

    N = 300
    seed = 42
    t_values = parse_t_values(pos_args)

    if length(pos_args) >= 1
        N = parse(Int, pos_args[1])
    end
    if length(pos_args) >= 3
        seed = parse(Int, pos_args[3])
    end

    println("Running algorithm comparison with N=$N, t set=$(t_values), seed=$seed, dgf=$(run_dgf_algo)")

    # Generate points (use generate_random_instance for point layout, then discard weights)
    base_instance = generate_random_instance(N, t_values[1]; seed=seed)
    points = base_instance.points
    ones_w = MatrixWFunc(ones(N, N))

    println("Precomputing distance matrix...")
    dist_matrix = compute_dist_matrix(points)

    base_dir = joinpath(@__DIR__, "results")
    root_output_dir = joinpath(base_dir, "n=$(N)_t=$(t_values[1])")
    mkpath(root_output_dir)

    for T in t_values
        println("\n=== Running t=$T ===")
        instance = SpannerInstance(points, ones_w, T)

        results = SpannerResult[]

        push!(results, run_greedy(instance))
        push!(results, run_sqrt_greedy_dgf(instance, dist_matrix))
        push!(results, run_yao(instance))
        push!(results, run_yao_dgf(instance, dist_matrix))
        push!(results, run_sqrt_yao_sqrt_greedy(instance))
        if run_dgf_algo
            push!(results, run_dgf(instance, dist_matrix))
        end

        # Compute stats for all
        for i in eachindex(results)
            results[i] = Analysis.compute_stats(instance, results[i])
            res = results[i]
            println("     $(res.algorithm_name): edges=$(res.stats[:num_edges]), " *
                    "weight=$(round(res.stats[:total_weight], digits=3)), " *
                    "valid=$(res.stats[:is_valid_spanner]), " *
                    "time=$(round(res.runtime_seconds, digits=3))s")
        end

        # Extract edge lists for all algorithms
        edge_lists = Dict{String, Vector{Tuple{Int,Int,Float64}}}()
        for res in results
            edge_lists[res.algorithm_name] = extract_edge_list(res.graph)
        end

        # Save
        output_dir = joinpath(root_output_dir, "t=$(T)")
        mkpath(output_dir)

        data_path = joinpath(output_dir, "spanner_data.jld2")
        JLD2.save(data_path, Dict(
            "instance" => instance,
            "results" => results,
            "edge_lists" => edge_lists
        ))

        table_path = joinpath(output_dir, "summary_table.png")
        draw_table_image(results, N, T, seed, table_path)

        # plot_path = joinpath(output_dir, "comparison_output.png")
        # comparison_plot = visualize_results(instance, results)
        # savefig(comparison_plot, plot_path)

        println("Saved outputs to $output_dir")
        println("  - data:  $data_path")
        println("  - table: $table_path")
        println("  - plot:  $plot_path")
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
