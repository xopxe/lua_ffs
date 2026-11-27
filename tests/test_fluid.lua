local T = require 'tests.lib'
local fluid = require 'fsim.fluid'
local medium = require 'fsim.medium'
local rbody = require 'fsim.rigid_body'
local inertia = require 'fsim.inertia'
local vec3 = require 'fsim.vec3'
local quat = require 'fsim.quaternion'

local PI, g = math.pi, 9.8
local RHO_W = 1025

-- medium.surface is the default flat sea at z = 0
local function rho_air ( z ) return (medium.atmosphere.density_pressure_temperature(vec3.new{0, 0, z})) end

local function body ( t, mass )
  t = t or {}
  t.inertia = inertia.element.from_shape('solid_sphere', {radius = 0.5, mass = mass or 1})
  return rbody.new(t)
end

-- drag_shape.sphere ---------------------------------------------------------

T.test('sphere drag in air: 1/2 rho v^2 Cd A, against the motion', function()
  local b = body{position = vec3.new{0, 0, 10}, velocity = vec3.new{10, 0, 0}}
  fluid.drag_shape.sphere{body = b, radius = 0.5}.apply(0)
  local F = 0.5 * rho_air(10) * 100 * 0.47 * PI * 0.25
  T.vnear(b.force, {-F, 0, 0}, 1e-9)
end)

T.test('sphere drag in water uses water density', function()
  local b = body{position = vec3.new{0, 0, -10}, velocity = vec3.new{0, 0, -2}}
  fluid.drag_shape.sphere{body = b, radius = 0.5}.apply(0)
  T.vnear(b.force, {0, 0, 0.5 * RHO_W * 4 * 0.47 * PI * 0.25}, 1e-9)
end)

T.test('drag is relative to the current', function()
  local saved = medium.atmosphere.current:clone()
  medium.atmosphere.current:set(3, 0, 0)
  local b = body{position = vec3.new{0, 0, 10}, velocity = vec3.new{3, 0, 0}}
  fluid.drag_shape.sphere{body = b, radius = 0.5}.apply(0)
  medium.atmosphere.current:set(saved[1], saved[2], saved[3])
  T.vnear(b.force, {0, 0, 0})
end)

T.test('sphere drag uses the velocity of its placement, damping spin', function()
  -- spinning in place at 2 rad/s about z: the shape at x=1 moves at 2 m/s along y
  local b = body{position = vec3.new{0, 0, 10}, angular_velocity = vec3.new{0, 0, 2}}
  fluid.drag_shape.sphere{body = b, radius = 0.5, placement = vec3.new{1, 0, 0}}.apply(0)
  local F = 0.5 * rho_air(10) * 4 * 0.47 * PI * 0.25
  T.vnear(b.force, {0, -F, 0}, 1e-9)
  T.vnear(b.torque, {0, 0, -F}, 1e-9, 'against the spin')
end)

-- floater.sphere ------------------------------------------------------------

local V = 4/3 * PI * 0.5^3

T.test('floater fully submerged: rho_water V g up', function()
  local b = body{position = vec3.new{0, 0, -10}}
  fluid.floater.sphere{body = b, radius = 0.5, ro = 0}.apply(0)
  T.vnear(b.force, {0, 0, RHO_W * V * g}, 1e-9)
end)

T.test('floater contents density counts as weight', function()
  local b = body{position = vec3.new{0, 0, -10}}
  fluid.floater.sphere{body = b, radius = 0.5, ro = RHO_W}.apply(0)
  T.vnear(b.force, {0, 0, 0}, 1e-9, 'filled with water: neutral')
end)

T.test('floater in air: hot air balloon lift', function()
  local b = body{position = vec3.new{0, 0, 100}}
  fluid.floater.sphere{body = b, radius = 0.5, ro = 1.0}.apply(0)
  T.near(b.force[3], (rho_air(100) - 1.0) * V * g, 1e-9)
end)

T.test('floater half submerged: half the volume in each medium', function()
  local b = body{position = vec3.new{0, 0, 0}}
  fluid.floater.sphere{body = b, radius = 0.5, ro = 0}.apply(0)
  T.rnear(b.force[3], V/2 * (RHO_W + 1.225) * g, 1e-4)
  T.vnear(b.torque, {0, 0, 0}, 1e-9)
end)

T.test('floater cutting the surface: buoyancy acts through the centre when tilted', function()
  local b = body{position = vec3.new{0, 0, 0.1}, orientation = quat.from_axis_angle(vec3.new{1, 0, 0}, math.rad(60))}
  fluid.floater.sphere{body = b, radius = 0.5, ro = 0}.apply(0)
  T.ok(b.force[3] > 0)
  T.vnear(b.torque, {0, 0, 0}, 1e-9)
end)

T.test('floater cutting the surface: lever arm of an offset sphere when tilted', function()
  -- rolled 90 deg about x, the sphere 1 m below the centre of mass in design
  -- space ends up 1 m along +y in the world, half submerged
  local b = body{orientation = quat.from_axis_angle(vec3.new{1, 0, 0}, math.rad(90))}
  fluid.floater.sphere{body = b, radius = 0.5, ro = 0, placement = vec3.new{0, 0, -1}}.apply(0)
  local F = b.force[3]
  T.rnear(F, V/2 * (RHO_W + 1.225) * g, 1e-4)
  -- vertical forces acting 1 m along y: world torque (F, 0, 0), also (F, 0, 0) in body space
  T.vnear(b.torque, {F, 0, 0}, 1e-9)
end)

-- a 10 kg ball of radius 0.2 (density ~298 kg/m^3)
local function solid_ball ( z )
  local b = rbody.new{
    inertia = inertia.element.from_shape('solid_sphere', {radius = 0.2, mass = 10}),
    position = vec3.new{0, 0, z}, gravity = true,
  }
  return b, fluid.floater.sphere{body = b, radius = 0.2, ro = 0}, fluid.drag_shape.sphere{body = b, radius = 0.2}
end

-- height where buoyancy balances weight, by bisection
local function float_height ()
  local b, floater = solid_ball(0)
  local lo, hi = -0.2, 0.2
  for _ = 1, 60 do
    local mid = (lo + hi) / 2
    b.position:set(0, 0, mid); b.force:set(0, 0, 0)
    floater.apply(0)
    if b.force[3] > 10 * g then lo = mid else hi = mid end
  end
  return lo
end

T.test('solid ball floats with submerged fraction = density ratio', function()
  local r, vol = 0.2, 4/3 * PI * 0.2^3
  local d = r - float_height()  -- submerged depth
  local submerged = PI * d * d * (3 * r - d) / 3
  local ro_ball, ro_air = 10 / vol, 1.225
  -- Archimedes, counting the air buoyancy on the dry part
  T.near(submerged / vol, (ro_ball - ro_air) / (RHO_W - ro_air), 1e-4)
end)

T.test('dropped ball bobs around its float line', function()
  local z_eq = float_height()
  local b, floater, drag = solid_ball(1)
  local lo, hi = math.huge, -math.huge
  for i = 1, 15000 do  -- 30 s
    floater.apply(0); drag.apply(0); b:update(0.002)
    if i > 10000 then lo, hi = math.min(lo, b.position[3]), math.max(hi, b.position[3]) end
  end
  -- only quadratic drag damps it, so it is still bobbing slightly
  T.near(lo, z_eq, 0.005)
  T.near(hi, z_eq, 0.005)
end)

-- foil.wing -----------------------------------------------------------------

local function wing_body ( pitch_deg, z, speed )
  -- pitch nose up by rotating about -y
  return body{
    position = vec3.new{0, 0, z or 100},
    velocity = vec3.new{speed or 20, 0, 0},
    orientation = quat.from_axis_angle(vec3.new{0, -1, 0}, math.rad(pitch_deg)),
  }
end

local function wing ( b )
  return fluid.foil.wing{body = b, params = {}, aero_data = 'polar_generator',
    aero_data_params = 'SYMMETRICAL', span = 10, area = 10}
end

T.test('wing: angle of attack equals pitch in level flight', function()
  local w = wing(wing_body(5))
  w.apply(0)
  T.near(math.deg(w.aoa), 5, 1e-9)
end)

T.test('wing: lift up and perpendicular, drag against the flow', function()
  local b = wing_body(5)
  local w = wing(b)
  w.apply(0)
  local aero = require('fsim.polar_generator').get_aerodata('SYMMETRICAL')
  local Cl, Cd = aero.sample(math.rad(5))
  local q = 0.5 * rho_air(100) * 400 * 10
  local AR = 10
  T.vnear(w.lift, {0, 0, Cl * q}, 1e-6)
  T.vnear(w.drag, {-(Cd + Cl * Cl / (PI * AR)) * q, 0, 0}, 1e-6)
  T.vnear(b.force, w.lift + w.drag, 1e-6)
end)

T.test('wing: negative angle of attack gives negative lift', function()
  local w = wing(wing_body(-5))
  w.apply(0)
  T.near(math.deg(w.aoa), -5, 1e-9)
  T.ok(w.lift[3] < 0)
end)

T.test('wing: no force without airflow', function()
  local b = wing_body(5, 100, 0)
  wing(b).apply(0)
  T.vnear(b.force, {0, 0, 0})
end)

T.test('wing: flow along the normal gives finite force', function()
  local b = body{position = vec3.new{0, 0, 100}, velocity = vec3.new{0, 0, -10}}
  wing(b).apply(0)
  T.finite(b.force)
  T.vnear({b.force[1], b.force[2]}, {0, 0}, 1e-9)
  T.ok(b.force[3] > 0, 'pure drag, upward')
  for d = 80, 100, 0.25 do
    b = wing_body(d)
    wing(b).apply(0)
    T.finite(b.force, 'pitch ' .. d)
  end
end)

T.test('wing underwater works as a hydrofoil', function()
  local air, water = wing_body(5, 100, 2), wing_body(5, -10, 2)
  wing(air).apply(0); wing(water).apply(0)
  T.rnear(water.force[3] / air.force[3], RHO_W / rho_air(100), 1e-9)
end)

-- drag_shape.projectile -----------------------------------------------------

T.test('projectile: minimum drag when aligned with the flow', function()
  local b = body{position = vec3.new{0, 0, 100}, velocity = vec3.new{10, 0, 0}}
  fluid.drag_shape.projectile{body = b, forward = vec3.new{1, 0, 0}, width = 0.5, length = 4}.apply(0)
  T.vnear(b.force, {-0.5 * rho_air(100) * 100 * 0.1 * 0.25, 0, 0}, 1e-9)
end)

T.test('projectile drag uses the velocity of its placement, damping spin', function()
  local b = body{position = vec3.new{0, 0, 100}, angular_velocity = vec3.new{0, 0, 2}}
  fluid.drag_shape.projectile{body = b, forward = vec3.new{0, 1, 0}, width = 0.5, length = 4,
    placement = vec3.new{1, 0, 0}}.apply(0)
  local F = 0.5 * rho_air(100) * 4 * 0.1 * 0.25  -- aligned with the flow: Cd_min, width^2
  T.vnear(b.force, {0, -F, 0}, 1e-9)
  T.vnear(b.torque, {0, 0, -F}, 1e-9, 'against the spin')
end)

T.xfail('projectile without forward uses the default', 'default is stored in body_forward but apply() reads forward', function()
  local b = body{position = vec3.new{0, 0, 100}, velocity = vec3.new{10, 0, 0}}
  fluid.drag_shape.projectile{body = b}.apply(0)
  T.ok(b.force[1] < 0)
end)
