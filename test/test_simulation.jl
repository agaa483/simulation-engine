@testset "Simulation Setup" begin
    cfg = load_config(joinpath(@__DIR__, "..", "configs", "default.toml"))
    grid = build_grid(cfg.grid)

    @testset "model construction" begin
        model = build_model(grid, cfg)

        @test model.grid === grid
        @test :b in keys(model.tracers)
        @test haskey(model.velocities, :u)
        @test haskey(model.velocities, :v)
        @test haskey(model.velocities, :w)
    end

    @testset "initial conditions" begin
        model = build_model(grid, cfg)
        set_initial_conditions!(model, grid)

        # After setting initial conditions, u and w should be non-zero
        @test maximum(abs, model.velocities.u) > 0
        @test maximum(abs, model.velocities.w) > 0
    end

    @testset "initial timestep" begin
        dt = compute_initial_timestep(grid, cfg.physics)

        # Timestep should be positive and finite
        @test dt > 0
        @test isfinite(dt)
    end

    @testset "simulation configuration" begin
        model = build_model(grid, cfg)
        set_initial_conditions!(model, grid)

        output_dir = mktempdir()
        simulation = setup_simulation(model, grid, cfg; output_dir)

        expected_stop = cfg.simulation.stop_time_days * 86400.0

        @test simulation.stop_time == expected_stop
        @test haskey(simulation.callbacks, :wizard)
        @test haskey(simulation.callbacks, :progress)
        @test haskey(simulation.output_writers, :fields)
    end
end
