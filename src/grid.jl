"""
    build_grid(gc::GridConfig)

Construct a 3D rectilinear grid with stretched vertical coordinates.

The vertical stretching concentrates resolution near the bottom boundary,
which is critical for resolving the boundary layer. Uses a combination of
linear refinement and exponential stretching.

Returns a `RectilinearGrid` with periodic horizontal boundaries and a
bounded vertical dimension.
"""
function build_grid(gc::GridConfig)
    Nz = gc.Nz
    Lz = gc.Lz
    refinement = gc.refinement
    stretching = gc.stretching

    h(k) = (Nz + 1 - k) / Nz
    zeta(k) = 1 + (h(k) - 1) / refinement
    sigma(k) = (1 - exp(-stretching * h(k))) / (1 - exp(-stretching))
    z_faces(k) = -Lz * (zeta(k) * sigma(k) - 1)

    grid = RectilinearGrid(
        topology = (Periodic, Periodic, Bounded),
        size     = (gc.Nx, gc.Ny, Nz),
        x        = (0, gc.Lx),
        y        = (0, gc.Ly),
        z        = z_faces
    )

    return grid
end
