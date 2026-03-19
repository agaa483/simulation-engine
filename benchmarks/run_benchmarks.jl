# ============================================================
# Benchmark Suite for TiltedBBL
# ============================================================
# Run this script to measure execution time and memory
# allocations for each function in the package.
#
# Usage:
#   julia --project=.. benchmarks/run_benchmarks.jl
# ============================================================

using TiltedBBL
using BenchmarkTools
using Oceananigans
using Printf

println("=" ^ 60)
println("  TiltedBBL Benchmark Suite")
println("=" ^ 60)
println()

# Load config using typed structs
config_path = joinpath(@__DIR__, "..", "configs", "default.toml")
cfg = load_config(config_path)

# --------------------------------------------------
# Benchmark: load_config
# --------------------------------------------------
println("Benchmarking: load_config")
b_config = @benchmark load_config($config_path)
display(b_config)
println("\n")

# --------------------------------------------------
# Benchmark: build_grid
# --------------------------------------------------
println("Benchmarking: build_grid")
b_grid = @benchmark build_grid($(cfg.grid))
display(b_grid)
println("\n")

# Build grid for subsequent benchmarks
grid = build_grid(cfg.grid)

# --------------------------------------------------
# Benchmark: setup_buoyancy
# --------------------------------------------------
println("Benchmarking: setup_buoyancy")
b_buoyancy = @benchmark setup_buoyancy($(cfg.physics))
display(b_buoyancy)
println("\n")

# --------------------------------------------------
# Benchmark: setup_coriolis
# --------------------------------------------------
_, zhat = setup_buoyancy(cfg.physics)

println("Benchmarking: setup_coriolis")
b_coriolis = @benchmark setup_coriolis($(cfg.physics), $zhat)
display(b_coriolis)
println("\n")

# --------------------------------------------------
# Benchmark: setup_boundary_conditions
# --------------------------------------------------
println("Benchmarking: setup_boundary_conditions")
b_bcs = @benchmark setup_boundary_conditions($grid, $(cfg.physics), $zhat)
display(b_bcs)
println("\n")

# --------------------------------------------------
# Benchmark: setup_closure
# --------------------------------------------------
println("Benchmarking: setup_closure")
b_closure = @benchmark setup_closure($(cfg.physics))
display(b_closure)
println("\n")

# --------------------------------------------------
# Benchmark: build_model
# --------------------------------------------------
println("Benchmarking: build_model")
b_model = @benchmark build_model($grid, $cfg)
display(b_model)
println("\n")

# --------------------------------------------------
# Benchmark: compute_initial_timestep
# --------------------------------------------------
println("Benchmarking: compute_initial_timestep")
b_dt = @benchmark compute_initial_timestep($grid, $(cfg.physics))
display(b_dt)
println("\n")

# --------------------------------------------------
# Benchmark: drag_u and drag_v (hot path functions)
# --------------------------------------------------
cD = 0.01
V_inf = 0.1
p = (; cD, V_inf)

println("Benchmarking: drag_u (called thousands of times per timestep)")
b_drag_u = @benchmark drag_u(0.0, 0.0, 0.0, 0.5, 0.3, $p)
display(b_drag_u)
println("\n")

println("Benchmarking: drag_v (called thousands of times per timestep)")
b_drag_v = @benchmark drag_v(0.0, 0.0, 0.0, 0.5, 0.3, $p)
display(b_drag_v)
println("\n")

# --------------------------------------------------
# Summary table
# --------------------------------------------------
println("=" ^ 60)
println("  Summary")
println("=" ^ 60)
@printf("%-30s %12s %12s\n", "Function", "Median (ns)", "Allocs")
println("-" ^ 54)

results = [
    ("load_config",               b_config),
    ("build_grid",                b_grid),
    ("setup_buoyancy",            b_buoyancy),
    ("setup_coriolis",            b_coriolis),
    ("setup_boundary_conditions", b_bcs),
    ("setup_closure",             b_closure),
    ("build_model",               b_model),
    ("compute_initial_timestep",  b_dt),
    ("drag_u",                    b_drag_u),
    ("drag_v",                    b_drag_v),
]

for (name, bench) in results
    med = median(bench).time  # nanoseconds
    allocs = median(bench).allocs
    @printf("%-30s %12.0f %12d\n", name, med, allocs)
end
println()
