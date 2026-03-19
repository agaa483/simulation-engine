module TiltedBBL

using Oceananigans
using Oceananigans.Units
using LinearAlgebra
using GLMakie
using Printf
using NCDatasets
using Random
using TOML

include("config.jl")
include("grid.jl")
include("physics.jl")
include("simulation.jl")
include("visualization.jl")

export GridConfig, PhysicsConfig, SimulationConfig, OutputConfig,
       TiltedBBLConfig, load_config,
       build_grid,
       setup_buoyancy, setup_coriolis, setup_background_fields,
       setup_boundary_conditions, setup_closure,
       build_model, set_initial_conditions!, compute_initial_timestep,
       setup_simulation, run_simulation,
       visualize_midplane, visualize_isosurface

end
