"""
    visualize_midplane(nc_path, grid, cfg::TiltedBBLConfig; output_dir=".")

Generate a 2D mid-y slice animation showing:
- Along-slope vorticity (ωy) with buoyancy contours
- Along-slope velocity (V) with buoyancy contours

Saves a PNG snapshot and an MP4 animation.
"""
function visualize_midplane(nc_path, grid, cfg::TiltedBBLConfig; output_dir = ".")
    Lx = cfg.grid.Lx
    Lz = cfg.grid.Lz
    V_inf = cfg.physics.V_inf

    ds = NCDataset(nc_path, "r")

    x_center = collect(xnodes(grid, Center()))
    y_center = collect(ynodes(grid, Center()))
    z_center = collect(znodes(grid, Center()))
    x_face   = collect(xnodes(grid, Face()))
    z_face   = collect(znodes(grid, Face()))
    times    = collect(ds["time"])

    jmid = cld(length(y_center), 2)

    wy_all = ds["ωy"][:, jmid, :, :]
    B_all  = ds["B"][:, jmid, :, :]
    V_all  = ds["V"][:, jmid, :, :]

    fig = Figure(size = (900, 700))
    axis_kwargs = (
        xlabel = "Across-slope x (m)",
        ylabel = "Slope-normal z (m)",
        limits = ((0, Lx), (0, Lz))
    )

    ax_w = Axis(fig[2, 1]; title = "Along-slope vorticity at mid-y", axis_kwargs...)
    ax_v = Axis(fig[3, 1]; title = "Along-slope velocity at mid-y", axis_kwargs...)

    n = Observable(1)

    wy_slice = @lift wy_all[:, :, $n]
    B_slice  = @lift B_all[:, :, $n]
    V_slice  = @lift V_all[:, :, $n]

    hm_w = heatmap!(ax_w, x_face, z_face, wy_slice;
                     colorrange = (-0.015, 0.015), colormap = :balance)
    Colorbar(fig[2, 2], hm_w; label = "s⁻¹")
    contour!(ax_w, x_center, z_center, B_slice;
             levels = -1e-3:0.5e-4:1e-3, color = :black)

    hm_v = heatmap!(ax_v, x_center, z_center, V_slice;
                     colorrange = (-V_inf, V_inf), colormap = :balance)
    Colorbar(fig[3, 2], hm_v; label = "m s⁻¹")
    contour!(ax_v, x_center, z_center, B_slice;
             levels = -1e-3:0.5e-4:1e-3, color = :black)

    ttl = @lift "t = " * string(prettytime(times[$n])) * "   (mid-y slice)"
    lbl = Label(fig; text = ttl, fontsize = 20, tellwidth = false)
    fig[1, :] = lbl

    png_path = joinpath(output_dir, "tilted_bbl_3d_midY.png")
    save(png_path, fig)

    mp4_path = joinpath(output_dir, "tilted_bbl_3d_midY.mp4")
    record(fig, mp4_path, 1:length(times); framerate = 12) do i
        n[] = i
    end

    close(ds)
    return (; png = png_path, mp4 = mp4_path)
end

"""
    visualize_isosurface(nc_path, grid, cfg::TiltedBBLConfig; output_dir=".")

Generate a 3D isosurface animation of along-slope velocity,
with a slowly rotating camera.

Saves an MP4 animation.
"""
function visualize_isosurface(nc_path, grid, cfg::TiltedBBLConfig; output_dir = ".")
    Lx = cfg.grid.Lx
    Ly = cfg.grid.Ly
    Lz = cfg.grid.Lz

    ds = NCDataset(nc_path, "r")
    times = collect(ds["time"])

    fig = Figure(resolution = (1200, 800))
    ax = Axis3(fig[1, 1];
        perspectiveness = 0.9,
        xlabel = "x (m)", ylabel = "y (m)", zlabel = "z (m)",
        limits = (0, Lx, 0, Ly, -Lz, 0)
    )

    xr = 0 .. Lx
    yr = 0 .. Ly
    zr = -Lz .. 0

    niso = Observable(1)
    V3D = @lift ds["V"][:, :, :, $niso]

    levels = range(-0.06, 0.06; length = 3)
    contour!(ax, xr, yr, zr, V3D;
             levels = collect(levels), transparency = true, colormap = :balance)

    ax.azimuth[] = 1.0
    ax.elevation[] = 0.7

    ttl = @lift "t = " * string(prettytime(times[$niso]))
    Label(fig[0, 1]; text = ttl, fontsize = 20, tellwidth = false)

    mp4_path = joinpath(output_dir, "tilted_bbl_3d_isosurf.mp4")
    record(fig, mp4_path, 1:length(times); framerate = 12) do i
        niso[] = i
        ax.azimuth[] = 0.01 * i
    end

    close(ds)
    return (; mp4 = mp4_path)
end
