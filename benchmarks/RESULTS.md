# Benchmark Results — TiltedBBL

## Environment
- Julia 1.10
- Oceananigans v0.92
- Grid: 64×32×64

## Before (Dict{String, Any} config)

Function                    | Time        | Allocations | Memory
----------------------------|-------------|-------------|--------
build_grid                  | 4.8 ms      | 1200        | 620 KB
setup_buoyancy              | 380 μs      | 45          | 8 KB
setup_coriolis              | 290 μs      | 38          | 6 KB
setup_boundary_conditions   | 1.1 ms      | 210         | 64 KB
setup_closure               | 195 μs      | 22          | 3 KB
build_model                 | 18.5 ms     | 3400        | 1.8 MB
compute_initial_timestep    | 160 μs      | 18          | 2 KB
drag_u (per call)           | 48 ns       | 2           | 64 B
drag_v (per call)           | 48 ns       | 2           | 64 B

## After (Typed structs)

Function                    | Time        | Allocations | Memory
----------------------------|-------------|-------------|--------
build_grid                  | 3.1 ms      | 850         | 510 KB
setup_buoyancy              | 210 μs      | 18          | 3 KB
setup_coriolis              | 155 μs      | 12          | 2 KB
setup_boundary_conditions   | 680 μs      | 120         | 38 KB
setup_closure               | 110 μs      | 8           | 1 KB
build_model                 | 12.2 ms     | 2100        | 1.2 MB
compute_initial_timestep    | 85 μs       | 6           | 512 B
drag_u (per call)           | 12 ns       | 0           | 0 B
drag_v (per call)           | 12 ns       | 0           | 0 B

## Summary

| Function                  | Speedup | Allocation Reduction |
|---------------------------|---------|---------------------|
| build_grid                | 1.5x    | 29%                 |
| setup_buoyancy            | 1.8x    | 60%                 |
| setup_coriolis            | 1.9x    | 68%                 |
| setup_boundary_conditions | 1.6x    | 43%                 |
| setup_closure             | 1.8x    | 64%                 |
| build_model               | 1.5x    | 38%                 |
| compute_initial_timestep  | 1.9x    | 67%                 |
| drag_u                    | 4.0x    | 100%                |
| drag_v                    | 4.0x    | 100%                |

## Key Findings

- drag_u and drag_v saw the biggest improvement (4x) because
  they are called at every bottom grid point at every timestep.
  Eliminating the 2 allocations per call removes thousands of
  allocations over a full simulation run.
- Setup functions saw 1.5-1.9x improvement from removing
  dictionary lookups with Any types.
- build_grid and build_model improvements were smaller because
  most of the time is spent inside Oceananigans internals, which
  were already type-stable.

## Type Stability

All 9 functions confirmed type-stable via @code_warntype after
struct conversion. Zero type warnings.
