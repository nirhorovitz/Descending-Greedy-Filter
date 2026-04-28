#!/usr/bin/env julia
# =============================================================================
# Local search refinement of a t-spanner (exhaustive subset enumeration).
#
# Given a t-spanner E (loaded from a saved spanner_data.jld2 produced by
# `final_comparison.jl`), this script repeatedly attempts the following
# (k, s)-improving swap, starting from k = `k_min` and increasing up to
# `k_max`:
#
#     1. Sort E in non-ascending order by weight.
#     2. Let E_k be the k longest edges of E and let E' = E \ E_k.
#        Let W = wt(E_k).
#     3. Build the candidate pool C = { e ∈ E* \ E : wt(e) < W }, sorted
#        in ascending order by weight.
#     4. Enumerate every subset F ⊆ C of size at most k + s in ASCENDING
#        order of total weight wt(F), restricted to wt(F) < W. For each
#        subset, check whether E' ∪ F is a valid t-spanner.
#     5. The first F that passes is accepted (it is the cheapest valid
#        swap, since enumeration is in ascending sum order). Otherwise
#        the swap is rejected and the next k is tried.
#     6. If any k in [k_min, k_max] yields an improving swap, restart
#        from k_min; otherwise the procedure terminates.
#
# Validation optimization: after step 2 we compute, with a single APSP,
# the set V of all violating pairs in E'. Adding edges only decreases
# distances, so V(E' ∪ F) ⊆ V(E') = V. To validate E' ∪ F it suffices
# to recheck the pairs in V via single-pair Dijkstras — there is no need
# to redo a full APSP per subset.
#
# Enumeration: subsets are produced in ascending sum order via a min-heap.
# Each subset is generated exactly once. For an ordered C, every subset
# (i_1 < ... < i_k) has a unique parent in the search tree:
#   - "ADVANCE": (..., i_{k-1}, i_k + 1) replaces the last index.
#   - "EXTEND" : (..., i_k, i_k + 1)     appends i_k + 1 (only if k+1 ≤ k+s).
# Termination is bounded by `--max_states` (default 10^7).
#
# Reuses DGFContext, single_pair_distance, and any_violation from
# `final_comparison.jl`, which is `include`d below.
#
# Usage:
#   julia local_search.jl                   # n=300, t=1.1, alg=DGF, k_min=2, k_max=64, s=1
#   julia local_search.jl 100 1.1 Greedy --k_min 1 --k_max 2 --s 1
#   julia local_search.jl 300 1.1 --all     # refine every algorithm in the file
# =============================================================================

using Pkg
Pkg.activate(joinpath(@__DIR__, "SpannerComparison"))

using SpannerComparison
using SpannerComparison.CoreTypes
using SpannerComparison.Algorithms
using SpannerComparison.Analysis

using Dates
using Printf
using Plots
using LinearAlgebra
using Graphs
using SimpleWeightedGraphs
using JLD2
using DataStructures: BinaryMinHeap

# Pulls in DGFContext, dgf_add_edge!, dgf_rem_edge!, single_pair_distance,
# any_violation, is_valid_t_spanner, compute_dist_matrix, extract_edge_list,
# and draw_table_image. The `if abspath(PROGRAM_FILE) == @__FILE__` guard
# in final_comparison.jl prevents its `main()` from running on include.
include(joinpath(@__DIR__, "final_comparison.jl"))

# -----------------------------------------------------------------------------
# Defaults
# -----------------------------------------------------------------------------

const DEFAULT_N           = 300
const DEFAULT_T           = 1.1
const DEFAULT_ALG         = "DGF"
const DEFAULT_K_MIN       = 2
const DEFAULT_K_MAX       = 64
const DEFAULT_S           = 1
const DEFAULT_MAX_STATES  = 10_000_000

# -----------------------------------------------------------------------------
# Local-search core
# -----------------------------------------------------------------------------

mutable struct LSStats
    iters::Int
    accepted_swaps::Int
    rejected_attempts::Int
    aborted_attempts::Int        # rejected because state cap was hit before exhausting
    weight_saved::Float64
    apsp_calls::Int
    apsp_total_ms::Float64
    sp_dijkstra_calls::Int       # single-pair Dijkstra calls during subset validation
    states_explored::Int         # total subsets popped from the enumeration heap
    swap_log::Vector{NamedTuple{(:iter, :k, :wt_Ek, :wt_F, :saved, :n_added),
                                 Tuple{Int,Int,Float64,Float64,Float64,Int}}}
end
LSStats() = LSStats(0, 0, 0, 0, 0.0, 0, 0.0, 0, 0,
    NamedTuple{(:iter, :k, :wt_Ek, :wt_F, :saved, :n_added),
                Tuple{Int,Int,Float64,Float64,Float64,Int}}[])

"""
    compute_all_violations(ctx, dist_matrix, t; tol) -> Vector{Tuple{Int,Int}}

Run an APSP over the graph currently held in `ctx` and return every canonical
pair (a, b) with a < b for which d_ctx(a, b) > t * |ab|. Reuses the same
threaded SSSP machinery as `any_violation`.
"""
function compute_all_violations(ctx::DGFContext, dist_matrix::Matrix{Float64},
                                 t::Float64; tol::Float64 = 1e-9)
    n = ctx.n
    n <= 1 && return Tuple{Int,Int}[]
    locks = ReentrantLock()
    V = Tuple{Int,Int}[]

    Threads.@threads :static for src in 1:n
        tid = Threads.threadid()
        dist = ctx.thread_dists[tid]
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
            @inbounds for v in ctx.nbrs[u]
                new_d = d_u + ctx.adj[u, v]
                if new_d < dist[v]
                    dist[v] = new_d
                    push!(heap, (new_d, v))
                    _siftup!(heap, length(heap))
                end
            end
        end

        local_V = Tuple{Int,Int}[]
        @inbounds for dst in (src + 1):n
            if dist[dst] > t * dist_matrix[src, dst] + tol
                push!(local_V, (src, dst))
            end
        end
        if !isempty(local_V)
            lock(locks)
            try
                append!(V, local_V)
            finally
                unlock(locks)
            end
        end
    end
    return V
end

"""
    subset_fixes_all_violations(ctx, V, dist_matrix, t, stats; tol) -> Bool

Given a set V of candidate violating pairs (precomputed on E'), check whether
each one is satisfied in the current graph (E' ∪ F). Increments
`stats.sp_dijkstra_calls`. Short-circuits on the first failure.
"""
function subset_fixes_all_violations(ctx::DGFContext, V::Vector{Tuple{Int,Int}},
                                      dist_matrix::Matrix{Float64}, t::Float64,
                                      stats::LSStats; tol::Float64 = 1e-9)
    @inbounds for (a, b) in V
        d = single_pair_distance(ctx, a, b)
        stats.sp_dijkstra_calls += 1
        if d > t * dist_matrix[a, b] + tol
            return false
        end
    end
    return true
end

"""
    canon(u, v) -> (a, b)

Canonical undirected pair with a < b.
"""
@inline canon(u::Int, v::Int) = u < v ? (u, v) : (v, u)

"""
    all_pairs_ascending(n, dist_matrix) -> Vector{Tuple{Int,Int,Float64}}

Every unordered pair (i, j) with i < j, sorted ascending by Euclidean distance.
"""
function all_pairs_ascending(n::Int, dist_matrix::Matrix{Float64})
    pairs = Vector{Tuple{Int,Int,Float64}}(undef, n * (n - 1) ÷ 2)
    idx = 1
    @inbounds for i in 1:n
        for j in (i + 1):n
            pairs[idx] = (i, j, dist_matrix[i, j])
            idx += 1
        end
    end
    sort!(pairs, by = x -> x[3])
    return pairs
end

"""
    try_swap!(ctx, edge_set, edges_E, all_pairs, k, s, t, stats; max_states, tol) -> Bool

Attempt a single (k, s)-improving swap by EXHAUSTIVE enumeration of subsets
F ⊆ (E* \\ E) of size at most k + s, in ascending order of total weight,
restricted to wt(F) < wt(E_k). Accepts the first F such that E' ∪ F is a
valid t-spanner.

`edges_E` must be sorted in NON-ASCENDING order by weight (longest first).

On success: `ctx`, `edges_E`, and `edge_set` are updated in place; returns `true`.
On failure: state is fully restored; returns `false`. The flag
`stats.aborted_attempts` is incremented (instead of `stats.rejected_attempts`)
when the state-budget `max_states` is exhausted before the heap is empty.
"""
function try_swap!(ctx::DGFContext,
                   edge_set::Set{Tuple{Int,Int}},
                   edges_E::Vector{Tuple{Int,Int,Float64}},
                   all_pairs::Vector{Tuple{Int,Int,Float64}},
                   k::Int, s::Int, t::Float64,
                   stats::LSStats;
                   max_states::Int = DEFAULT_MAX_STATES,
                   tol::Float64 = 1e-9,
                   dist_matrix::Matrix{Float64})
    @assert k >= 1
    @assert k <= length(edges_E)

    wt_Ek = 0.0
    @inbounds for idx in 1:k
        wt_Ek += edges_E[idx][3]
    end

    Ek_snapshot = [(canon(edges_E[i][1], edges_E[i][2])..., edges_E[i][3]) for i in 1:k]
    for (a, b, _) in Ek_snapshot
        dgf_rem_edge!(ctx, a, b)
    end

    t_apsp = time_ns()
    V = compute_all_violations(ctx, dist_matrix, t; tol = tol)
    stats.apsp_calls += 1
    stats.apsp_total_ms += (time_ns() - t_apsp) / 1e6

    C = Tuple{Int,Int,Float64}[]
    @inbounds for (u, v, w) in all_pairs
        w >= wt_Ek - tol && break
        ab = canon(u, v)
        ab in edge_set && continue
        push!(C, (ab[1], ab[2], w))
    end
    nC = length(C)
    max_size = k + s
    found = nothing
    aborted = false

    if isempty(V)
        found = Int[]
    end

    if found === nothing && nC > 0 && max_size >= 1
        H = BinaryMinHeap{Tuple{Float64, Vector{Int}}}()
        push!(H, (C[1][3], [1]))

        while !isempty(H)
            sum_w, indices = pop!(H)
            stats.states_explored += 1
            if sum_w >= wt_Ek - tol
                break
            end

            for idx in indices
                u, v, w = C[idx]
                dgf_add_edge!(ctx, u, v, w)
            end
            ok = subset_fixes_all_violations(ctx, V, dist_matrix, t, stats; tol = tol)
            for idx in indices
                u, v, _ = C[idx]
                dgf_rem_edge!(ctx, u, v)
            end

            if ok
                found = indices
                break
            end

            last_idx = indices[end]
            if last_idx + 1 <= nC
                w_next = C[last_idx + 1][3]
                w_last = C[last_idx][3]

                new_sum_adv = sum_w - w_last + w_next
                if new_sum_adv < wt_Ek - tol
                    new_indices_adv = copy(indices)
                    new_indices_adv[end] = last_idx + 1
                    push!(H, (new_sum_adv, new_indices_adv))
                end

                if length(indices) < max_size
                    new_sum_ext = sum_w + w_next
                    if new_sum_ext < wt_Ek - tol
                        new_indices_ext = copy(indices)
                        push!(new_indices_ext, last_idx + 1)
                        push!(H, (new_sum_ext, new_indices_ext))
                    end
                end
            end

            if stats.states_explored >= max_states
                aborted = true
                break
            end
        end
    end

    if found === nothing
        for (a, b, w) in Ek_snapshot
            dgf_add_edge!(ctx, a, b, w)
        end
        if aborted
            stats.aborted_attempts += 1
        else
            stats.rejected_attempts += 1
        end
        return false
    end

    F = [C[i] for i in found]
    wt_F = isempty(F) ? 0.0 : sum(w for (_, _, w) in F)

    for (u, v, w) in F
        dgf_add_edge!(ctx, u, v, w)
    end

    saved = wt_Ek - wt_F
    n_added = length(F)
    push!(stats.swap_log,
          (iter = stats.iters, k = k, wt_Ek = wt_Ek, wt_F = wt_F,
           saved = saved, n_added = n_added))

    for (a, b, _) in Ek_snapshot
        delete!(edge_set, (a, b))
    end
    for (u, v, _) in F
        push!(edge_set, canon(u, v))
    end

    deleteat!(edges_E, 1:k)
    for f in F
        push!(edges_E, f)
    end
    sort!(edges_E, by = x -> x[3], rev = true)

    stats.accepted_swaps += 1
    stats.weight_saved += saved
    return true
end

"""
    local_search(edges_in, points, dist_matrix, t; k_min, k_max, s, max_states)
        -> (edges_out, stats)

Top-level driver: applies (k, s)-improving swaps with k ∈ [k_min, k_max]
until no improvement is found, using exhaustive enumeration of subsets in
ascending sum order (capped at `max_states` subsets per swap attempt).
"""
function local_search(edges_in::Vector{Tuple{Int,Int,Float64}},
                      points::Vector{Point2D},
                      dist_matrix::Matrix{Float64},
                      t::Float64;
                      k_min::Int = DEFAULT_K_MIN,
                      k_max::Int = DEFAULT_K_MAX,
                      s::Int = DEFAULT_S,
                      max_states::Int = DEFAULT_MAX_STATES)
    n = length(points)
    ctx = DGFContext(n, dist_matrix, t)
    edge_set = Set{Tuple{Int,Int}}()
    for (u, v, w) in edges_in
        a, b = canon(u, v)
        dgf_add_edge!(ctx, a, b, w)
        push!(edge_set, (a, b))
    end

    edges_E = [(canon(u, v)[1], canon(u, v)[2], w) for (u, v, w) in edges_in]
    sort!(edges_E, by = x -> x[3], rev = true)

    all_pairs = all_pairs_ascending(n, dist_matrix)

    stats = LSStats()
    initial_weight = sum(w for (_, _, w) in edges_E; init = 0.0)
    println("    [LS] start: |E|=$(length(edges_E)), wt(E)=$(round(initial_weight, digits=4)), " *
            "k_min=$k_min, k_max=$k_max, s=$s, max_states=$max_states, n=$n, t=$t, threads=$(Threads.nthreads())")

    while true
        stats.iters += 1
        improved = false
        klimit = min(k_max, length(edges_E))

        for k in k_min:klimit
            states_before = stats.states_explored
            ok = try_swap!(ctx, edge_set, edges_E, all_pairs, k, s, t, stats;
                            max_states = max_states, dist_matrix = dist_matrix)
            states_in_attempt = stats.states_explored - states_before
            if ok
                last = stats.swap_log[end]
                cur_w = sum(w for (_, _, w) in edges_E; init = 0.0)
                pct = initial_weight > 0 ? 100.0 * (initial_weight - cur_w) / initial_weight : 0.0
                println(@sprintf("    [LS iter=%d swap=%d] k=%d: removed %d edges (wt=%.4f) -> added %d edges (wt=%.4f), saved=%.4f, states=%d, |E|=%d, wt(E)=%.4f (-%.2f%% from start)",
                                  stats.iters, stats.accepted_swaps, k, k, last.wt_Ek,
                                  last.n_added, last.wt_F, last.saved, states_in_attempt,
                                  length(edges_E), cur_w, pct))
                improved = true
                break
            end
        end

        if !improved
            println("    [LS] no improving k in [$k_min, $klimit]; stopping after $(stats.iters) iterations.")
            break
        end
    end

    final_weight = sum(w for (_, _, w) in edges_E; init = 0.0)
    avg_apsp = stats.apsp_calls > 0 ? stats.apsp_total_ms / stats.apsp_calls : 0.0
    println(@sprintf("    [LS] done: swaps=%d, rejected=%d, aborted=%d, states=%d, sp_dij=%d, wt: %.4f -> %.4f (saved %.4f, %.2f%%), |E| %d -> %d",
                      stats.accepted_swaps, stats.rejected_attempts, stats.aborted_attempts,
                      stats.states_explored, stats.sp_dijkstra_calls,
                      initial_weight, final_weight, stats.weight_saved,
                      initial_weight > 0 ? 100.0 * stats.weight_saved / initial_weight : 0.0,
                      length(edges_in), length(edges_E)))
    println(@sprintf("    [LS-profile] apsp_calls=%d, apsp_total=%.2fs, avg=%.1fms/apsp",
                      stats.apsp_calls, stats.apsp_total_ms / 1000, avg_apsp))

    return edges_E, stats
end

# -----------------------------------------------------------------------------
# Glue: refine a single SpannerResult and produce a new SpannerResult
# -----------------------------------------------------------------------------

function build_graph(n::Int, edges::Vector{Tuple{Int,Int,Float64}})
    g = SimpleWeightedGraph(n)
    for (u, v, w) in edges
        add_edge!(g, u, v, w)
    end
    return g
end

function refine_result(orig::SpannerResult, instance::SpannerInstance,
                       dist_matrix::Matrix{Float64};
                       k_min::Int, k_max::Int, s::Int, max_states::Int)
    name = orig.algorithm_name
    println("\n  -> Local-search refining \"$name\" (orig edges=$(ne(orig.graph)))")
    edges_in = extract_edge_list(orig.graph)

    t0 = time()
    edges_out, ls_stats = local_search(edges_in, instance.points, dist_matrix, instance.t;
                                        k_min = k_min, k_max = k_max, s = s,
                                        max_states = max_states)
    runtime = time() - t0

    g_out = build_graph(length(instance.points), edges_out)

    new_stats = Dict{Symbol, Any}()
    for (kkk, vvv) in orig.stats
        new_stats[kkk] = vvv
    end
    new_stats[:ls_iters] = ls_stats.iters
    new_stats[:ls_swaps] = ls_stats.accepted_swaps
    new_stats[:ls_rejected] = ls_stats.rejected_attempts
    new_stats[:ls_aborted] = ls_stats.aborted_attempts
    new_stats[:ls_weight_saved] = ls_stats.weight_saved
    new_stats[:ls_apsp_calls] = ls_stats.apsp_calls
    new_stats[:ls_apsp_total_ms] = ls_stats.apsp_total_ms
    new_stats[:ls_states_explored] = ls_stats.states_explored
    new_stats[:ls_sp_dijkstra_calls] = ls_stats.sp_dijkstra_calls
    new_stats[:ls_runtime_seconds] = runtime
    new_stats[:base_algorithm] = name
    new_stats[:k_min] = k_min
    new_stats[:k_max] = k_max
    new_stats[:s] = s
    new_stats[:max_states] = max_states

    refined = SpannerResult(name * "+LS", g_out,
                             orig.runtime_seconds + runtime,
                             new_stats)
    return refined, ls_stats
end

# -----------------------------------------------------------------------------
# I/O
# -----------------------------------------------------------------------------

function data_path_for(n::Int, t::Real)
    joinpath(@__DIR__, "results", "n=$(n)_t=$(t)", "t=$(t)", "spanner_data.jld2")
end

function output_dir_for(n::Int, t::Real)
    out = joinpath(@__DIR__, "results", "n=$(n)_t=$(t)", "t=$(t)", "local_search")
    mkpath(out)
    return out
end

function load_experiment(n::Int, t::Real)
    path = data_path_for(n, t)
    isfile(path) || error("No saved experiment at $path. Run final_comparison.jl first.")
    println("Loading $path ...")
    d = JLD2.load(path)
    return d["instance"]::SpannerInstance, d["results"]::Vector{SpannerResult}, path
end

# -----------------------------------------------------------------------------
# Arg parsing
# -----------------------------------------------------------------------------

function parse_local_search_args(args::Vector{String})
    n           = DEFAULT_N
    t           = DEFAULT_T
    alg         = DEFAULT_ALG
    k_min       = DEFAULT_K_MIN
    k_max       = DEFAULT_K_MAX
    s           = DEFAULT_S
    max_states  = DEFAULT_MAX_STATES
    do_all      = false

    pos = String[]
    i = 1
    while i <= length(args)
        a = args[i]
        if a == "--all"
            do_all = true; i += 1
        elseif a == "--k_min"
            k_min = parse(Int, args[i + 1]); i += 2
        elseif a == "--k_max"
            k_max = parse(Int, args[i + 1]); i += 2
        elseif a == "--s"
            s = parse(Int, args[i + 1]); i += 2
        elseif a == "--max_states"
            max_states = parse(Int, args[i + 1]); i += 2
        elseif startswith(a, "--")
            error("Unknown flag: $a")
        else
            push!(pos, a); i += 1
        end
    end

    length(pos) >= 1 && (n = parse(Int, pos[1]))
    length(pos) >= 2 && (t = parse(Float64, pos[2]))
    length(pos) >= 3 && (alg = pos[3])

    return (; n, t, alg, k_min, k_max, s, max_states, do_all)
end

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

function main()
    ENV["GKS_ENCODING"] = "utf8"
    default(fontfamily = "Helvetica")
    gr()

    cfg = parse_local_search_args(ARGS)
    println("Local search refinement: n=$(cfg.n), t=$(cfg.t), " *
            (cfg.do_all ? "alg=<all>" : "alg=$(cfg.alg)") *
            ", k_min=$(cfg.k_min), k_max=$(cfg.k_max), s=$(cfg.s), max_states=$(cfg.max_states)")

    instance, orig_results, _ = load_experiment(cfg.n, cfg.t)
    points = instance.points

    println("Precomputing distance matrix...")
    dist_matrix = compute_dist_matrix(points)

    targets = if cfg.do_all
        orig_results
    else
        sel = filter(r -> r.algorithm_name == cfg.alg, orig_results)
        if isempty(sel)
            avail = join([r.algorithm_name for r in orig_results], ", ")
            error("Algorithm \"$(cfg.alg)\" not found in saved results. Available: $avail")
        end
        sel
    end

    refined_results = SpannerResult[]
    pairs_to_emit = SpannerResult[]

    for orig in targets
        refined, _ = refine_result(orig, instance, dist_matrix;
                                    k_min = cfg.k_min, k_max = cfg.k_max, s = cfg.s,
                                    max_states = cfg.max_states)
        push!(refined_results, refined)
        push!(pairs_to_emit, orig)
        push!(pairs_to_emit, refined)
    end

    println("\nValidating final spanners...")
    for r in refined_results
        valid, fs, fd = is_valid_t_spanner(r.graph, points, instance.t)
        if !valid
            @warn "Refined spanner \"$(r.algorithm_name)\" failed strict validity check (src=$fs, dst=$fd)."
        end
    end

    println("\nComputing final stats...")
    final_results = SpannerResult[]
    for r in pairs_to_emit
        push!(final_results, Analysis.compute_stats(instance, r))
    end
    for r in final_results
        s = r.stats
        ls_swaps = get(s, :ls_swaps, 0)
        ls_runtime = get(s, :ls_runtime_seconds, 0.0)
        ls_tag = haskey(s, :base_algorithm) ?
                 @sprintf(" (LS swaps=%d, +%.2fs)", ls_swaps, ls_runtime) : ""
        println(@sprintf("     %s: edges=%s, weight=%.3f, valid=%s, time=%.3fs%s",
                          r.algorithm_name, get(s, :num_edges, "?"),
                          get(s, :total_weight, NaN), get(s, :is_valid_spanner, "N/A"),
                          r.runtime_seconds, ls_tag))
    end

    out_dir = output_dir_for(cfg.n, cfg.t)
    edge_lists = Dict{String, Vector{Tuple{Int,Int,Float64}}}()
    for r in final_results
        edge_lists[r.algorithm_name] = extract_edge_list(r.graph)
    end

    data_path = joinpath(out_dir, "spanner_data.jld2")
    JLD2.save(data_path, Dict(
        "instance"   => instance,
        "results"    => final_results,
        "edge_lists" => edge_lists,
        "config"     => Dict(:k_min => cfg.k_min, :k_max => cfg.k_max,
                             :s => cfg.s, :max_states => cfg.max_states,
                             :alg => cfg.do_all ? "<all>" : cfg.alg),
    ))

    table_path = joinpath(out_dir, "summary_table.png")
    draw_table_image(final_results, cfg.n, cfg.t, "LS", table_path)

    println("\nSaved outputs to $out_dir")
    println("  - data:  $data_path")
    println("  - table: $table_path")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
