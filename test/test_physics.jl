@testset "Physics Setup" begin
    cfg = load_config(joinpath(@__DIR__, "..", "configs", "default.toml"))
    pc = cfg.physics
    grid = build_grid(cfg.grid)

    @testset "buoyancy and gravity vector" begin
        buoyancy, zhat = setup_buoyancy(pc)

        @test zhat[1] ≈ sind(pc.theta_deg)
        @test zhat[2] ≈ 0.0
        @test zhat[3] ≈ cosd(pc.theta_deg)

        # Gravity unit vector should have unit magnitude
        @test norm(zhat) ≈ 1.0 atol=1e-10
    end

    @testset "coriolis" begin
        _, zhat = setup_buoyancy(pc)
        coriolis = setup_coriolis(pc, zhat)
        @test coriolis.f == pc.f
    end

    @testset "drag functions" begin
        cD = 0.01
        V_inf = 0.1
        p = (; cD, V_inf)

        # When u = 0, drag in u direction should be zero
        @test drag_u(0, 0, 0, 0.0, 0.0, p) == 0.0

        # Drag should oppose the flow direction
        du = drag_u(0, 0, 0, 1.0, 0.0, p)
        @test du < 0.0  # opposing positive u

        dv = drag_v(0, 0, 0, 0.0, 0.0, p)
        @test dv < 0.0  # opposing V_inf (positive)
    end

    @testset "background stratification" begin
        _, zhat = setup_buoyancy(pc)
        p = (; zhat, N2 = pc.N2)

        # At origin, stratification should be zero
        @test constant_stratification(0, 0, 0, 0, p) == 0.0

        # Buoyancy should increase with height (positive z contribution)
        b_above = constant_stratification(0, 0, 10.0, 0, p)
        b_below = constant_stratification(0, 0, -10.0, 0, p)
        @test b_above > b_below
    end

    @testset "closure" begin
        closure = setup_closure(pc)
        @test closure.ν == pc.nu
        @test closure.κ == pc.kappa
    end
end
