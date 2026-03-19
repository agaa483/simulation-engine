@testset "Grid Construction" begin
    cfg = load_config(joinpath(@__DIR__, "..", "configs", "default.toml"))
    gc = cfg.grid

    grid = build_grid(gc)

    @testset "dimensions" begin
        @test size(grid) == (gc.Nx, gc.Ny, gc.Nz)
    end

    @testset "domain extents" begin
        @test grid.Lx == gc.Lx
        @test grid.Ly == gc.Ly
        @test grid.Lz == gc.Lz
    end

    @testset "vertical stretching" begin
        z_nodes = znodes(grid, Center())
        # Z nodes should be monotonically increasing (bottom to top)
        for i in 2:length(z_nodes)
            @test z_nodes[i] > z_nodes[i-1]
        end

        # All z nodes should be within the domain
        z_faces = znodes(grid, Face())
        @test minimum(z_faces) >= -gc.Lz
        @test maximum(z_faces) <= 0.0
    end

    @testset "topology" begin
        @test topology(grid) == (Periodic, Periodic, Bounded)
    end
end
