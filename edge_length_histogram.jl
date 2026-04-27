#!/usr/bin/env julia
# =============================================================================
# Edge-length histogram for a single algorithm at a single (n, t).
#
# Usage:
#   julia edge_length_histogram.jl                       # n=1000, t=1.1, alg=DGF
#   julia edge_length_histogram.jl 1000 1.001            # alg defaults to DGF
#   julia edge_length_histogram.jl 1000 1.1 Greedy
#   julia edge_length_histogram.jl 1000 1.1 "sqrt(t)-Greedy+DGF"
#   julia edge_length_histogram.jl 1000 1.1 DGF --bins 60 --out my.png
#
# Available algorithm names (must match the keys saved in spanner_data.jld2):
#   Greedy
#   sqrt(t)-Greedy+DGF
#   Yao
#   Yao+DGF
#   sqrt(t)-Yao+sqrt(t)-Greedy
#   DGF
# =============================================================================

using Pkg
Pkg.activate(joinpath(@__DIR__, "..", "SpannerComparison"))

using JLD2
using Plots
using Printf
using Statistics

const DEFAULT_N    = 1000
const DEFAULT_T    = 1.1
const DEFAULT_ALG  = "DGF"
const DEFAULT_BINS = 40

# -----------------------------------------------------------------------------
# Arg parsing
# -----------------------------------------------------------------------------

function parse_args(args::Vector{String})
    n   = DEFAULT_N
    t   = DEFAULT_T
    alg = DEFAULT_ALG
    nbins = DEFAULT_BINS
    out_path = ""

    pos = String[]
    i = 1
    while i <= length(args)
        a = args[i]
        if a == "--bins"
            nbins = parse(Int, args[i+1]); i += 2
        elseif a == "--out"
            out_path = args[i+1]; i += 2
        elseif startswith(a, "--")
            error("Unknown flag: $a")
        else
            push!(pos, a); i += 1
        end
    end

    length(pos) >= 1 && (n   = parse(Int, pos[1]))
    length(pos) >= 2 && (t   = parse(Float64, pos[2]))
    length(pos) >= 3 && (alg = pos[3])

    return (; n, t, alg, nbins, out_path)
end

# -----------------------------------------------------------------------------
# Data loading
# -----------------------------------------------------------------------------

"""
Path to the JLD2 result file produced by `final_comparison.jl`.
Mirrors the directory layout: results/n=<N>_t=<T>/t=<T>/spanner_data.jld2
"""
function data_path_for(n::Int, t::Real)
    joinpath(@__DIR__, "results", "n=$(n)_t=$(t)", "t=$(t)", "spanner_data.jld2")
end

"""
Return the vector of edge lengths for `alg` from the result file at (n, t).
"""
function edge_lengths(n::Int, t::Real, alg::AbstractString)
    path = data_path_for(n, t)
    isfile(path) || error("No result file at $path")
    d = JLD2.load(path)
    edge_lists = d["edge_lists"]::Dict
    haskey(edge_lists, alg) ||
        error("Algorithm \"$alg\" not in $path. Available: $(collect(keys(edge_lists)))")
    return Float64[w for (_, _, w) in edge_lists[alg]]
end

# -----------------------------------------------------------------------------
# Plotting
# -----------------------------------------------------------------------------

function stats_text(lengths::Vector{Float64})
    isempty(lengths) && return "no edges"
    return @sprintf(
        "edges  = %d\nmin    = %.4f\nmax    = %.4f\nmean   = %.4f\nmedian = %.4f\nstd    = %.4f\nsum    = %.2f",
        length(lengths),
        minimum(lengths), maximum(lengths),
        mean(lengths),    median(lengths),
        std(lengths),     sum(lengths),
    )
end

function plot_histogram(lengths::Vector{Float64}; n::Int, t::Real,
                         alg::AbstractString, nbins::Int = DEFAULT_BINS)
    isempty(lengths) && error("No edges to plot for alg=$alg, n=$n, t=$t")

    lo, hi = extrema(lengths)
    bin_edges = range(lo, hi; length = nbins + 1)

    p = histogram(
        lengths;
        bins      = bin_edges,
        title     = "Edge-length histogram   —   $alg   (N=$n, t=$t)",
        xlabel    = "edge length",
        ylabel    = "count",
        legend    = :topright,
        label     = "edges",
        color     = :steelblue,
        linecolor = :white,
        size      = (1000, 620),
        leftmargin   = 8Plots.mm,
        bottommargin = 7Plots.mm,
        topmargin    = 4Plots.mm,
        rightmargin  = 4Plots.mm,
    )

    mu = mean(lengths)
    md = median(lengths)
    vline!(p, [mu]; color = :red,    linewidth = 2, label = @sprintf("mean = %.4f", mu))
    vline!(p, [md]; color = :orange, linewidth = 2, linestyle = :dash,
                                     label = @sprintf("median = %.4f", md))

    xr = xlims(p); yr = ylims(p)
    x_pos = xr[1] + 0.62 * (xr[2] - xr[1])
    y_pos = yr[1] + 0.95 * (yr[2] - yr[1])
    annotate!(p, x_pos, y_pos,
              text(stats_text(lengths), font(9, "Courier"), :left, :top, :black))
    return p
end

function default_out_path(n::Int, t::Real, alg::AbstractString)
    safe_alg = replace(alg, r"[^A-Za-z0-9]+" => "_") |> x -> strip(x, '_')
    out_dir = joinpath(@__DIR__, "results", "n=$(n)_t=$(t)", "t=$(t)")
    mkpath(out_dir)
    return joinpath(out_dir, "edge_length_hist_$(safe_alg).png")
end

# -----------------------------------------------------------------------------
# Public API: callable from other scripts.
# -----------------------------------------------------------------------------

"""
    make_edge_length_histogram(; n, t, alg, nbins, out_path) -> (plot, out_path)

Loads the saved spanner edge list for `alg` at (n, t), draws an edge-length
histogram with mean / median lines and a stats annotation, saves it to
`out_path`, and returns the plot handle along with the saved path.
"""
function make_edge_length_histogram(; n::Int = DEFAULT_N,
                                      t::Real = DEFAULT_T,
                                      alg::AbstractString = DEFAULT_ALG,
                                      nbins::Int = DEFAULT_BINS,
                                      out_path::AbstractString = "")

    lengths = edge_lengths(n, t, alg)
    p = plot_histogram(lengths; n, t, alg, nbins)
    out = isempty(out_path) ? default_out_path(n, t, alg) : out_path
    savefig(p, out)
    println("Saved histogram for \"$alg\"  N=$n  t=$t  ->  $out")
    println("  ", replace(stats_text(lengths), '\n' => "\n  "))
    return p, out
end

# -----------------------------------------------------------------------------
# Script entry point
# -----------------------------------------------------------------------------

function main()
    ENV["GKS_ENCODING"] = "utf8"
    default(fontfamily = "Helvetica")
    gr()

    cfg = parse_args(ARGS)
    make_edge_length_histogram(; n = cfg.n, t = cfg.t, alg = cfg.alg,
                                 nbins = cfg.nbins, out_path = cfg.out_path)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
