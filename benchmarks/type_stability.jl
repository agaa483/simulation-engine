# ============================================================
# Type Stability Check for TiltedBBL
# ============================================================
# This script runs @code_warntype on all key functions to check
# for type instabilities. Any red/yellow "Any" types in the
# output indicate performance problems.
#
# Usage:
#   julia --project=.. benchmarks/type_stability.jl
# ============================================================

using TiltedBBL
using Oceananigans
using InteractiveUtils

println("=" ^ 60)
println("  TiltedBBL Type Stability Report")
println("=" ^ 60)
println()

# Load typed config
config_path = joinpath(@__DIR__, "..", "configs", "default.toml")
cfg = load_config(config_path)

# Build grid for functions that need it
grid = build_grid(cfg.grid)
_, zhat = setup_buoyancy(cfg.physics)

# --------------------------------------------------
# Check each function for type instabilities
# --------------------------------------------------

println("=" ^ 40)
println("  load_config")
println("=" ^ 40)
@code_warntype load_config(config_path)
println("\n")

println("=" ^ 40)
println("  build_grid")
println("=" ^ 40)
@code_warntype build_grid(cfg.grid)
println("\n")

println("=" ^ 40)
println("  setup_buoyancy")
println("=" ^ 40)
@code_warntype setup_buoyancy(cfg.physics)
println("\n")

println("=" ^ 40)
println("  setup_coriolis")
println("=" ^ 40)
@code_warntype setup_coriolis(cfg.physics, zhat)
println("\n")

println("=" ^ 40)
println("  setup_closure")
println("=" ^ 40)
@code_warntype setup_closure(cfg.physics)
println("\n")

println("=" ^ 40)
println("  compute_initial_timestep")
println("=" ^ 40)
@code_warntype compute_initial_timestep(grid, cfg.physics)
println("\n")

println("=" ^ 40)
println("  drag_u (hot path)")
println("=" ^ 40)
p = (; cD = 0.01, V_inf = 0.1)
@code_warntype drag_u(0.0, 0.0, 0.0, 0.5, 0.3, p)
println("\n")

println("=" ^ 40)
println("  drag_v (hot path)")
println("=" ^ 40)
@code_warntype drag_v(0.0, 0.0, 0.0, 0.5, 0.3, p)
println("\n")

println("=" ^ 40)
println("  constant_stratification (hot path)")
println("=" ^ 40)
sp = (; zhat, N2 = cfg.physics.N2)
@code_warntype constant_stratification(0.0, 0.0, 0.0, 0.0, sp)
println("\n")

println("=" ^ 60)
println("  Type Stability Check Complete")
println("  Look for 'Any' or 'Union' types above — those are problems.")
println("=" ^ 60)
