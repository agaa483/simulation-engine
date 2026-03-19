"""
    setup_buoyancy(pc::PhysicsConfig)

Configure the buoyancy force with a tilted gravity vector.
Returns a `BuoyancyForce` and the gravity unit vector `zhat`.
"""
function setup_buoyancy(pc::PhysicsConfig)
    zhat = (sind(pc.theta_deg), 0.0, cosd(pc.theta_deg))
    buoyancy = BuoyancyForce(BuoyancyTracer(); gravity_unit_vector = .-zhat)
    return buoyancy, zhat
end

"""
    setup_coriolis(pc::PhysicsConfig, zhat)

Configure Coriolis force aligned with the tilted rotation axis.
"""
function setup_coriolis(pc::PhysicsConfig, zhat)
    return ConstantCartesianCoriolis(f = pc.f, rotation_axis = zhat)
end

"""
    constant_stratification(x, y, z, t, p)

Background buoyancy field representing constant stratification
in the tilted coordinate frame.
"""
@inline function constant_stratification(x, y, z, t, p)
    return p.N2 * (x * p.zhat[1] + z * p.zhat[3])
end

"""
    setup_background_fields(pc::PhysicsConfig, zhat)

Create background buoyancy and velocity fields.
Returns the background buoyancy field and background velocity field.
"""
function setup_background_fields(pc::PhysicsConfig, zhat)
    B_inf = BackgroundField(constant_stratification; parameters = (; zhat, N2 = pc.N2))
    V_inf_field = BackgroundField(pc.V_inf)
    return B_inf, V_inf_field
end

"""
    setup_boundary_conditions(grid, pc::PhysicsConfig, zhat)

Configure boundary conditions for velocity and buoyancy fields:
- Bottom buoyancy gradient maintaining stratification
- Log-layer bottom drag on u and v components

Returns named tuple of boundary conditions for u, v, and b.
"""
function setup_boundary_conditions(grid, pc::PhysicsConfig, zhat)
    # Bottom buoyancy gradient
    dz_b_bottom = -pc.N2 * cosd(pc.theta_deg)
    b_bcs = FieldBoundaryConditions(bottom = GradientBoundaryCondition(dz_b_bottom))

    # Log-layer drag
    z1 = first(znodes(grid, Center()))
    cD = (pc.kappa_vk / log(z1 / pc.z0))^2

    drag_bc_u = FluxBoundaryCondition(
        drag_u; field_dependencies = (:u, :v), parameters = (; cD, V_inf = pc.V_inf)
    )
    drag_bc_v = FluxBoundaryCondition(
        drag_v; field_dependencies = (:u, :v), parameters = (; cD, V_inf = pc.V_inf)
    )

    u_bcs = FieldBoundaryConditions(bottom = drag_bc_u)
    v_bcs = FieldBoundaryConditions(bottom = drag_bc_v)

    return (; u = u_bcs, v = v_bcs, b = b_bcs)
end

"""
    drag_u(x, y, t, u, v, p)

Bottom drag stress in the across-slope (u) direction.
Uses a quadratic drag law with log-layer drag coefficient.
"""
@inline drag_u(x, y, t, u, v, p) = -p.cD * sqrt(u^2 + (v + p.V_inf)^2) * u

"""
    drag_v(x, y, t, u, v, p)

Bottom drag stress in the along-slope (v) direction.
Includes the background along-slope velocity V_inf.
"""
@inline drag_v(x, y, t, u, v, p) = -p.cD * sqrt(u^2 + (v + p.V_inf)^2) * (v + p.V_inf)

"""
    setup_closure(pc::PhysicsConfig)

Configure subgrid-scale closure (scalar diffusivity).
"""
function setup_closure(pc::PhysicsConfig)
    return ScalarDiffusivity(; ν = pc.nu, κ = pc.kappa)
end
