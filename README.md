# Simulation Engine

A high-performance scientific simulation platform built in Julia. Designed with modular architecture, typed configuration, automated testing, and performance benchmarking.

## Project Structure

```
├── src/
│   ├── TiltedBBL.jl          # Main module
│   ├── grid.jl               # 3D grid construction with vertical stretching
│   ├── physics.jl            # Buoyancy, rotation, drag, boundary conditions
│   ├── simulation.jl         # Model setup, time stepping, output
│   └── visualization.jl      # 2D/3D visualization and animations
├── configs/
│   ├── config.jl             # Typed configuration structs
│   └── default.toml          # Default simulation parameters
├── test/
│   ├── runtests.jl           # Test runner
│   ├── test_grid.jl          # Grid construction tests
│   ├── test_physics.jl       # Physics setup tests
│   └── test_simulation.jl    # Simulation setup tests
├── benchmarks/
│   ├── run_benchmarks.jl     # Performance benchmarking suite
│   ├── type_stability.jl     # Type stability analysis
│   └── RESULTS.md            # Benchmark results and findings
├── .github/workflows/
│   └── ci.yml                # GitHub Actions CI pipeline
└── Project.toml              # Dependencies
```

## Features

- **Modular Architecture** — simulation logic split into independent, testable modules
- **Typed Configuration** — TOML-based config loaded into typed structs for compile-time type safety and optimized performance
- **Automated Testing** — unit tests for grid, physics, and simulation modules with CI via GitHub Actions
- **Performance Benchmarking** — benchmarking suite with before/after analysis of type stability optimizations
- **Flexible Parameters** — change simulation settings via config file without modifying source code

## Quick Start

```bash
git clone https://github.com/agaa483/simulation-engine.git
cd simulation-engine
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

### Run a simulation
```julia
using TiltedBBL
config = load_config("configs/default.toml")
run_simulation(config)
```

### Run tests
```bash
julia --project=. -e 'using Pkg; Pkg.test()'
```

### Run benchmarks
```bash
julia --project=. benchmarks/run_benchmarks.jl
```

## Performance Optimization

Replaced untyped dictionary-based configuration with typed structs, eliminating runtime type instabilities across all setup and physics functions. Key results:

- **4x speedup** on hot-path drag functions (called per grid point per timestep)
- **~1.5-1.9x speedup** on setup functions
- **Zero allocations** in performance-critical boundary condition functions

See [benchmarks/RESULTS.md](benchmarks/RESULTS.md) for full results.

## Tech Stack

Julia, Oceananigans.jl, BenchmarkTools.jl, GitHub Actions, TOML

