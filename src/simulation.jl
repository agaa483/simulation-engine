"""
    build_model(grid, cfg::TiltedBBLConfig)

Assemble the full `NonhydrostaticModel` from grid and configuration.
Wires together buoyancy, coriolis, closure, boundary conditions,
and background fields.
"""
function build_model(grid, cfg::TiltedBBLConfig)
    pc = cfg.physics

    buoyancy, zhat = setup_buoyancy(pc)
    coriolis = setup_coriolis(pc, zhat)
    closure = setup_closure(pc)
    bcs = setup_boundary_conditions(grid, pc, zhat)
    B_inf, V_inf_field = setup_background_fields(pc, zhat)

    model = NonhydrostaticModel(;
        grid,
        buoyancy,
        coriolis,
        closure,
        advection = UpwindBiased(order = 5),
        tracers   = :b,
        boundary_conditions = (u = bcs.u, v = bcs.v, b = bcs.b),
        background_fields   = (; b = B_inf, v = V_inf_field)
    )

    return model
end

"""
    set_initial_conditions!(model, grid)

Apply small random perturbations to u and w velocity fields
to seed turbulent development in the boundary layer.
"""
function set_initial_conditions!(model, grid)
    noise(x, y, z) = 1e-3 * randn() * exp(-(10z)^2 / grid.Lz^2)
    set!(model; u = noise, w = noise)
end

"""
    compute_initial_timestep(grid, pc::PhysicsConfig)

Compute a stable initial timestep based on the CFL condition
for both advection and diffusion.
"""
function compute_initial_timestep(grid, pc::PhysicsConfig)
    dz_min = minimum_zspacing(grid)
    return 0.5 * min(dz_min / pc.V_inf, dz_min^2 / pc.kappa)
end

"""
    setup_simulation(model, grid, cfg::TiltedBBLConfig; output_dir=".")

Create and configure a `Simulation` with:
- Adaptive time stepping
- Progress logging callback
- NetCDF output writer

`output_dir` controls where the NetCDF file is written.
"""
function setup_simulation(model, grid, cfg::TiltedBBLConfig; output_dir = ".")
    sc = cfg.simulation
    oc = cfg.output
    pc = cfg.physics

    dt0 = compute_initial_timestep(grid, pc)
    stop_time = sc.stop_time_days * 86400.0  # convert days to seconds

    simulation = Simulation(model; Δt = dt0, stop_time = stop_time)

    # Adaptive time stepping
    wizard = TimeStepWizard(max_change = sc.max_dt_change, cfl = sc.cfl)
    simulation.callbacks[:wizard] = Callback(wizard, IterationInterval(4))

    # Progress logging
    start_time = time_ns()
    progress_message(sim) =
        @printf("Iter: %04d  t: %s  Δt: %s  max|w|: %.1e m s⁻¹  wall: %s\n",
                iteration(sim), prettytime(time(sim)),
                prettytime(sim.Δt), maximum(abs, sim.model.velocities.w),
                prettytime((time_ns() - start_time) * 1e-9))
    simulation.callbacks[:progress] = Callback(
        progress_message, IterationInterval(sc.progress_interval)
    )

    # NetCDF output
    u, v, w = model.velocities
    b       = model.tracers.b
    B_inf   = model.background_fields.tracers.b

    B  = b + B_inf
    Vt = v + pc.V_inf
    wy = ∂z(u) - ∂x(w)

    outputs = (; u, V = Vt, w, B, ωy = wy)
    outfile = joinpath(output_dir, oc.filename)

    simulation.output_writers[:fields] = NetCDFWriter(
        model, outputs;
        filename = outfile,
        schedule = TimeInterval(sc.output_interval_minutes * 60.0),
        overwrite_existing = oc.overwrite_existing
    )

    return simulation
end

"""
    run_simulation(config_path; output_dir=".")

Full pipeline: load config, build grid, build model,
set initial conditions, and run the simulation.

Returns the simulation object after completion.
"""
function run_simulation(config_path; output_dir = ".")
    cfg = load_config(config_path)

    grid = build_grid(cfg.grid)
    model = build_model(grid, cfg)
    set_initial_conditions!(model, grid)
    simulation = setup_simulation(model, grid, cfg; output_dir)

    run!(simulation)

    return simulation
end
