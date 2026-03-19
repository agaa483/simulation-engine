"""
    GridConfig

Typed configuration for grid construction.
All fields have explicit types so Julia can generate optimized code.
"""
struct GridConfig
    Lx::Float64
    Ly::Float64
    Lz::Float64
    Nx::Int
    Ny::Int
    Nz::Int
    refinement::Float64
    stretching::Float64
end

"""
    PhysicsConfig

Typed configuration for physics setup:
buoyancy, coriolis, boundary conditions, and closure.
"""
struct PhysicsConfig
    theta_deg::Float64
    N2::Float64
    V_inf::Float64
    z0::Float64
    kappa_vk::Float64
    nu::Float64
    kappa::Float64
    f::Float64
end

"""
    SimulationConfig

Typed configuration for simulation time stepping and output.
"""
struct SimulationConfig
    stop_time_days::Float64
    max_dt_change::Float64
    cfl::Float64
    progress_interval::Int
    output_interval_minutes::Float64
end

"""
    OutputConfig

Typed configuration for output file settings.
"""
struct OutputConfig
    filename::String
    overwrite_existing::Bool
end

"""
    TiltedBBLConfig

Top-level configuration holding all sub-configs.
"""
struct TiltedBBLConfig
    grid::GridConfig
    physics::PhysicsConfig
    simulation::SimulationConfig
    output::OutputConfig
end

"""
    load_config(path::String) -> TiltedBBLConfig

Load a TOML config file and pack values into typed structs.
This is the only place where we touch the untyped Dict{String, Any}.
After this function, everything is fully typed.
"""
function load_config(path::String)
    raw = TOML.parsefile(path)

    g = raw["grid"]
    grid = GridConfig(
        Float64(g["Lx"]),
        Float64(g["Ly"]),
        Float64(g["Lz"]),
        Int(g["Nx"]),
        Int(g["Ny"]),
        Int(g["Nz"]),
        Float64(g["refinement"]),
        Float64(g["stretching"]),
    )

    p = raw["physics"]
    physics = PhysicsConfig(
        Float64(p["theta_deg"]),
        Float64(p["N2"]),
        Float64(p["V_inf"]),
        Float64(p["z0"]),
        Float64(p["kappa_vk"]),
        Float64(p["nu"]),
        Float64(p["kappa"]),
        Float64(p["f"]),
    )

    s = raw["simulation"]
    sim = SimulationConfig(
        Float64(s["stop_time_days"]),
        Float64(s["max_dt_change"]),
        Float64(s["cfl"]),
        Int(s["progress_interval"]),
        Float64(s["output_interval_minutes"]),
    )

    o = raw["output"]
    out = OutputConfig(
        String(o["filename"]),
        Bool(o["overwrite_existing"]),
    )

    return TiltedBBLConfig(grid, physics, sim, out)
end
