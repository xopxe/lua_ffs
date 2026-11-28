local M = {}

-- every force is in a medium, its world's, given as params.medium (the
-- loader sets it)

local vec3 = require 'fsim.vec3'

local g_accel = -9.8 --m/sec^2

local sin	= math.sin
local cos	= math.cos
local abs = math.abs
local sqrt = math.sqrt
local PI = math.pi
local EPS =  1e-8 --1e-16;

local function parabolic_interpolator(y1, x2,y2)
  local p = (y2-y1)/(x2^2)
  return function (x)
    return y1+p*x*x
  end
end

local function drag_force ( ro, velocity, Cd, A, out )
  velocity:clone(out)
  local vrel_norm2 = out:norm_sq()
  if vrel_norm2 <= EPS then
    return out:set(0,0,0)
  end
  local f = -0.5 * ro * vrel_norm2 * Cd * A
  --print ('!', f, ro, vrel_norm2, Cd, A)
  out:mul_scalar( f/sqrt(vrel_norm2), out)
  return out
end

-- parasitic drag, no sustentation
M.drag_shape = {}

M.drag_shape.sphere = function ( s )
  --s = s or {}
  local medium = assert(s.medium, 'a force needs the medium it is in')
  --assert(s.surface)
  assert(s.body)
  s.radius = s.radius or 1
  s.placement = s.placement or vec3.new{0,0,0} -- in f.body design coordinates

  -- computation results
  local drag = vec3.new{0.0,0.0,0.0}
  local relvel = vec3.new{0.0,0.0,0.0}   -- relative velocity
  local pos = vec3.new{0.0,0.0,0.0}  -- in w coordinated
  local local_velocity = vec3.new{0.0,0.0,0.0}  -- of the placement point, in w coordinates

  local CD = 0.47  -- https://en.wikipedia.org/wiki/Drag_coefficient
  local area = PI * s.radius^2

  s.apply = function ( now )
    s.body:get_pointd_positionw(s.placement, pos)
    local surface_h = medium.surface.height(pos[1], pos[2], now)
    local localmedium
    if pos[3]-s.radius < surface_h then -- simplified, assume fully underwater 
      --print ('W')
      localmedium = medium.ocean
    else -- simplified, assume fully airborne 
      --print ('A')
      localmedium = medium.atmosphere
    end

    -- velocity of the shape itself, including the body's rotation
    s.body:get_pointd_velocityw(s.placement, local_velocity)
    local_velocity:sub( localmedium.current, relvel )

    local ro = localmedium.density_pressure_temperature( pos )
    drag_force( ro, relvel, CD, area, drag )
    s.body:add_forcew_at_pointd( drag, s.placement )
  end
  return s
end
M.drag_shape.projectile = function ( s ) --made up
  --s = s or {}
  local medium = assert(s.medium, 'a force needs the medium it is in')
  --assert(s.surface)
  assert(s.body)

  s.placement = s.placement or vec3.new{0,0,0} -- in design coordinates
  s.body_forward = s.body_forward or vec3.new{1,0,0} --in s.body coordinates
  --s.body_orientation = s.body_orientation or quat.new()

  s.length = s.length or 6
  s.width = s.width or 1

  s.length2 = s.length^2
  s.width2 = s.width^2

  -- computation results
  local drag = vec3.new{0.0,0.0,0.0}
  local relvel = vec3.new{0.0,0.0,0.0}
  local pos = vec3.new{0.0,0.0,0.0}  -- in w coordinated
  local forwardw = vec3.new{0.0,0.0,0.0}  -- in w coordinated
  local local_velocity = vec3.new{0.0,0.0,0.0}  -- of the placement point, in w coordinates

  local Cd_min = 0.1
  local Cd_max = 1.5
  local stall_angle = math.rad(20)
  local cuadratic_cd = parabolic_interpolator(Cd_min, stall_angle, Cd_max )

  s.apply = function ( now )
    s.body:get_pointd_positionw(s.placement, pos)
    local localmedium
    local surface_h = medium.surface.height(pos[1], pos[2], now)
    if pos[3] < surface_h then -- simplified, assume fully underwater 
      localmedium = medium.ocean
    else -- simplified, assume fully airborne 
      localmedium = medium.atmosphere
    end

    -- velocity of the shape itself, including the body's rotation
    s.body:get_pointd_velocityw(s.placement, local_velocity)
    local_velocity:sub( localmedium.current, relvel )
    if relvel:norm_sq() <= EPS then
      return
    end

    s.body:transform_direction_dw(s.forward, forwardw)
    local aoa = vec3.angle( relvel, forwardw )  -- FIXME orientation -> forward?
    --print('forward', s.body:transform_direction_bw(bforward), relvel, angle_attack)

    local Cd
    if aoa > stall_angle then
      Cd = Cd_max
    else
      -- CD=cuadratic betweem CD_min and CD_max
      Cd = cuadratic_cd( aoa )
    end

    --local A = interpolate between width^2 (at 0º) and length^2 (at 90º)
    local area = abs(cos(aoa))*s.width2 + abs(sin(aoa) * s.length2)

    local ro = localmedium.density_pressure_temperature( pos )
    drag_force( ro, relvel, Cd, area, drag )
    s.body:add_forcew_at_pointd( drag, s.placement )

  end
  return s
end

M.foil = {}

-- sustentation + induced drag
M.foil.wing = function ( f )
  local medium = assert(f.medium, 'a force needs the medium it is in')
  --assert(f.surface)
  assert(f.body)
  assert(f.series or f.params)

  f.center_of_pressure = f.center_of_pressure or vec3.new{0,0,0} -- in f.body coordinates
  f.normal = f.normal or vec3.new{0,0,1} -- in f.body coordinates
  f.area = f.area or 1
  f.span = f.span or 1
  f.chord = f.chord or f.area / f.span
  f.aspect_ratio = f.span^2 / f.area
  f.lift_multiplier   = f.lift_multiplier or 1.0
  f.drag_multiplier   = f.drag_multiplier or 1.0
  f.efficiency_factor = f.efficiency_factor or 1.0
  
  local generator = require('fsim.'..f.aero_data)
  local aero_data = generator.get_aerodata(f.aero_data_params)
  
  -- computation results
  f.aoa = 0
  f.relvel = vec3.new{0.0,0.0,0.0}
  f.normalw = vec3.new{0.0,0.0,0.0}
  f.drag = vec3.new{0.0,0.0,0.0}
  f.lift = vec3.new{0.0,0.0,0.0}
  f.F = vec3.new{0.0,0.0,0.0}
  local local_velocity = vec3.new{0.0,0.0,0.0}
  local pos = vec3.new{0.0,0.0,0.0}  -- in w coordinated

  f.apply = function ( now )
    local lift, drag, relvel = f.lift, f.drag, f.relvel

    f.body:get_pointd_positionw(f.center_of_pressure, pos)

    local surface_h = medium.surface.height(pos[1], pos[2], now)
    local localmedium
    if pos[3] < surface_h then -- simplified, assume fully underwater 
      localmedium = medium.ocean
    else -- simplified, assume fully airborne 
      localmedium = medium.atmosphere
    end

    f.body:get_pointd_velocityw(f.center_of_pressure, local_velocity)
    local_velocity:sub( localmedium.current, relvel )

    local relvel_norm_sq = relvel:norm_sq()
    if relvel_norm_sq <= EPS then
      return
    end

    -- TODO deflect normal for control surfaces here
    f.body:transform_direction_dw(f.normal, f.normalw)

    relvel:unm( drag )
    drag:div_scalar( sqrt(relvel_norm_sq), drag ) --normalize

    -- lift is always perpendicular to drag
    --lift = drag:cross(f.normal, lift):cross(f.drag, lift):normalize(lift)
    drag:cross(f.normalw, lift)
    lift:cross(drag, lift)
    local lift_norm_sq = lift:norm_sq()
    if lift_norm_sq > EPS then
      lift:div_scalar( sqrt(lift_norm_sq), lift ) --normalize
    else
      lift:set(0.0, 0.0, 0.0) -- flow along the normal: lift direction undefined
    end

    local sin_aoa = drag:dot(f.normalw)
    if sin_aoa > 1.0 then sin_aoa = 1.0 elseif sin_aoa < -1.0 then sin_aoa = -1.0 end
    f.aoa = math.asin( sin_aoa )
    local ro = localmedium.density_pressure_temperature( pos ) 

    local Cl, Cd, Cm = aero_data.sample( f.aoa )

    --TODO apply Cm

    local induced_drag = Cl*Cl / (PI*f.aspect_ratio*f.efficiency_factor)

    local dynamic_pressure = 0.5 * relvel_norm_sq * ro * f.area
    lift:mul_scalar(Cl*dynamic_pressure*f.lift_multiplier, lift)
    drag:mul_scalar((Cd+induced_drag)*dynamic_pressure*f.drag_multiplier, drag)

    --print ('#', math.deg(aoa), 'l', lift, 'd', drag)
    drag:add(lift, f.F)
    f.body:add_forcew_at_pointd( f.F, f.center_of_pressure )   
  end
  return f
end

M.viscous = {}

M.viscous.sphere_rotation = function ( f )
  error('NYI')
  f.apply = function ( now )
    --torque = -8*PI*R³ * nu * angvel 
    -- TODO apply torque in rigid_body
  end
end

M.floater = {}

M.floater.sphere = function ( f )
  local medium = assert(f.medium, 'a force needs the medium it is in')
  --assert(f.surface)
  assert(f.body)
  assert(f.radius)
  -- density of the sphere's contents whose mass is NOT already in the body's
  -- inertia (e.g. a balloon's hot air). Use 0 for a solid body.
  f.ro = f.ro or medium.atmosphere.ro0

  local vol = (4.0/3.0)*PI*f.radius^3

  f.placement = f.placement or vec3.new{0,0,0} -- in design coordinates

  -- computation results
  local pos = vec3.new{0.0,0.0,0.0} -- in w coordinated
  local flotation = vec3.new{0.0,0.0,0.0} -- in w coordinated
  -- used when cutting a surface: centre of buoyancy of the part on one side
  local offsetw = vec3.new{0.0,0.0,0.0} -- from the sphere's centre, in w coordinates
  local cgw = vec3.new{0.0,0.0,0.0} -- in w coordinates
  local cgd = vec3.new{0.0,0.0,0.0} -- in design coordinates

  -- the cut is horizontal, so the centre of buoyancy of each part lies
  -- straight above or below the sphere's centre in world space, whatever
  -- the body's orientation
  local function set_cg ( dz )
    offsetw:set(0.0, 0.0, dz)
    pos:add(offsetw, cgw)
    f.body:transform_direction_wd(offsetw, cgd)
    cgd:add(f.placement, cgd)
  end

  f.apply = function ( now )
    local function apply_buoyancy( ro_medium, vol, buoyancy_center )
      local fb = (f.ro-ro_medium) * vol * g_accel
      flotation:set(0.0, 0.0, fb)
      f.body:add_forcew_at_pointd( flotation, buoyancy_center )
    end

    f.body:get_pointd_positionw(f.placement, pos)
    local surface_h = medium.surface.height(pos[1], pos[2], now)

    if pos[3]+f.radius < surface_h then -- fully underwater
      local ro_sea = medium.ocean.density_pressure_temperature( pos )
      apply_buoyancy( ro_sea, vol, f.placement )
    elseif pos[3]-f.radius > surface_h then -- fully airborne
      local ro_atm = medium.atmosphere.density_pressure_temperature( pos )
      apply_buoyancy( ro_atm, vol, f.placement )
    else -- cuts surface
      -- https://mathworld.wolfram.com/SphericalCap.html
      -- TODO surface not horizontal
      local h = pos[3] + f.radius - surface_h -- height of the part above

      local vol_above = (1.0/3.0)*PI*h*h*(3*f.radius-h)
      set_cg( (3*(2*f.radius-h)^2)/(4*(3*f.radius-h)) )
      local ro_atm = medium.atmosphere.density_pressure_temperature( cgw )
      apply_buoyancy( ro_atm, vol_above, cgd )

      local vol_below = vol - vol_above
      -- mirrored from below
      local h2 = 2*f.radius - h
      set_cg( -(3*(2*f.radius-h2)^2)/(4*(3*f.radius-h2)) )
      local ro_sea = medium.ocean.density_pressure_temperature( cgw )
      apply_buoyancy( ro_sea, vol_below, cgd )
    end
  end

  return f
end


return M