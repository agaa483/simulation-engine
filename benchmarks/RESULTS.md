# Performance Optimization Results

## Summary

Replaced `Dict{String, Any}` config with typed structs (`GridConfig`, `PhysicsConfig`, etc.)
to eliminate type instabilities and enable Julia's compiler to generate optimized machine code.

## Before (Dict-based config)

| Function                    | Median Time | Allocations |
|-----------------------------|-------------|-------------|
| load_config (TOML.parsefile)| TBD         | TBD         |
| build_grid                  | TBD         | TBD         |
| setup_buoyancy              | TBD         | TBD         |
| setup_coriolis              | TBD         | TBD         |
| setup_boundary_conditions   | TBD         | TBD         |
| setup_closure               | TBD         | TBD         |
| build_model                 | TBD         | TBD         |
| compute_initial_timestep    | TBD         | TBD         |
| drag_u                      | TBD         | TBD         |
| drag_v                      | TBD         | TBD         |

## After (Typed struct config)

| Function                    | Median Time | Allocations |
|-----------------------------|-------------|-------------|
| load_config                 | TBD         | TBD         |
| build_grid                  | TBD         | TBD         |
| setup_buoyancy              | TBD         | TBD         |
| setup_coriolis              | TBD         | TBD         |
| setup_boundary_conditions   | TBD         | TBD         |
| setup_closure               | TBD         | TBD         |
| build_model                 | TBD         | TBD         |
| compute_initial_timestep    | TBD         | TBD         |
| drag_u                      | TBD         | TBD         |
| drag_v                      | TBD         | TBD         |

## Type Stability

All functions pass `@code_warntype` with no `Any` or `Union` types after
switching to typed structs.

## What Changed and Why

1. **Created typed config structs** — `GridConfig`, `PhysicsConfig`, `SimulationConfig`,
   `OutputConfig` with explicit `Float64`, `Int`, `String`, `Bool` field types.

2. **Added `load_config()` function** — converts the untyped TOML dictionary into typed
   structs at the boundary. All downstream code receives fully typed data.

3. **Updated all function signatures** — functions now accept typed structs (e.g.,
   `build_grid(gc::GridConfig)`) instead of `Dict{String, Any}`.

## Why This Matters

- Julia compiles specialized machine code for concrete types
- `Dict{String, Any}` forces runtime type checking on every access
- Typed structs let the compiler know exactly what type each field is at compile time
- The drag functions (`drag_u`, `drag_v`) are called at every grid point on the bottom
  boundary at every timestep — type stability here has the largest cumulative impact
