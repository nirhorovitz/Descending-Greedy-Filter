# `final_comparison.jl` — Spanner Algorithm Comparison

Benchmarks several geometric `t`-spanner construction algorithms on a random
point set and writes per-algorithm results, a summary table, and cached
intermediate data to disk.

The algorithms compared are:

- **Greedy** — classical greedy `t`-spanner with periodic APSP early-stop.
- **sqrt(t)-Greedy + DGF** — greedy with stretch √t, then Descending Greedy Filter (DGF) down to `t`.
- **Yao** — Yao graph.
- **Yao + DGF** — Yao graph filtered down to `t` with DGF.
- **sqrt(t)-Yao + sqrt(t)-Greedy** — Yao at √t, then greedy at √t restricted to those edges.
- **DGF** — DGF applied to the complete graph (skipped with `--no-dgf`).

## Prerequisites

- **Julia** ≥ 1.10 (the script targets `1.11`/`1.12` — see `SpannerComparison/Project.toml`).
- The `SpannerComparison` package is vendored in this repo at `./SpannerComparison`.
  The scripts automatically activate it via
  `Pkg.activate(joinpath(@__DIR__, "SpannerComparison"))`.
- First-time setup (run once, from this `final/` directory):

```bash
julia --project=SpannerComparison -e 'using Pkg; Pkg.instantiate()'
```

This installs the exact dependency versions pinned in
`SpannerComparison/Manifest.toml`.

## Running

From this `final/` directory:

```bash
julia --threads=auto final_comparison.jl [N] [t_values] [seed] [--no-dgf]
```

### Positional arguments

| Arg | Meaning | Default |
| --- | --- | --- |
| `N` | Number of random points in the unit square. | `300` |
| `t_values` | Single stretch `t` (e.g. `1.1`) or comma-separated list (e.g. `1.05,1.1,1.2`). Each value runs all algorithms. | `1.05,1.1,1.2,1.25,1.4,1.5,1.75,2.0` |
| `seed` | RNG seed for the point set. | `42` |

### Flags

- `--no-dgf` — skip the full **DGF** (complete-graph) algorithm. Recommended for
  large `N` where building/filtering the complete graph dominates runtime.

### Threading

Always launch with `--threads=auto` (or `--threads=N`). The DGF inner loop and
the spanner-validity check use `Threads.@threads`; running single-threaded will
be substantially slower.

### Examples

```bash
julia --threads=auto final_comparison.jl 300 1.1
julia --threads=auto final_comparison.jl 1000 1.1,1.2,1.5 42
julia --threads=auto final_comparison.jl 5000 1.5 42 --no-dgf
```

A few preset runs are bundled in the `experiments` shell script:

```bash
./experiments
```

## Output layout

Results are written under `results/n=<N>_t=<first_t>/`:

```
results/n=<N>_t=<first_t>/
├── points.jld2                  # cached point set (tied to N + seed)
└── t=<T>/
    ├── algorithms/<slug>.jld2   # per-algorithm cached SpannerResult
    ├── spanner_data.jld2        # instance + all results + edge lists
    └── summary_table.png        # rendered comparison table
```

## Resuming a run

Both the **point set** (`points.jld2`) and **each algorithm's result**
(`algorithms/<slug>.jld2`) are cached. Re-running with the same `N`, `t`, and
`seed` will skip any algorithm whose cache file already exists and only
recompute the missing ones. To force a re-run, delete the corresponding
`<slug>.jld2` file (or the whole `t=<T>/` directory).

If you change `N` or `seed` for an existing output directory, the script will
abort with an error pointing at the conflicting `points.jld2` — delete that
file or pick a different output root.
