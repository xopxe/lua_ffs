local T = require 'tests.lib'
local forces = require 'fsim.forces'
local medium = require 'fsim.medium'
local rbody = require 'fsim.rigid_body'
local inertia = require 'fsim.inertia'
local vec3 = require 'fsim.vec3'
local quat = require 'fsim.quaternion'

local Z = vec3.new{0, 0, 1}
local G = 6.674e-11
local g = 9.8

local function ball ( t, mass )
  t = t or {}
  t.inertia = inertia.element.from_shape('solid_sphere', {radius = 0.1, mass = mass or 1})
  return rbody.new(t)
end

T.test('get_constant_w applies a world force at a design point', function()
  local b = ball{orientation = quat.from_axis_angle(Z, math.pi/2)}
  local f = forces.get_constant_w{medium = medium, body = b, force = vec3.new{1, 0, 0}, point = vec3.new{1, 0, 0}}
  f.apply(0)
  T.vnear(b.force, {1, 0, 0}, 1e-12)
  T.vnear(b.torque, {0, 0, -1}, 1e-12)
end)

T.test('get_constant_d applies a design force', function()
  local b = ball{orientation = quat.from_axis_angle(Z, math.pi/2)}
  local f = forces.get_constant_d{medium = medium, body = b, force = vec3.new{1, 0, 0}, point = vec3.new{0, 1, 0}}
  f.apply(0)
  T.vnear(b.force, {0, 1, 0}, 1e-12, 'rotated into world space')
  T.vnear(b.torque, {0, 0, -1}, 1e-12)
end)

-- spring --------------------------------------------------------------------

T.test('spring: Hooke force along the line, equal and opposite', function()
  local b1, b2 = ball(), ball{position = vec3.new{3, 0, 0}}
  local s = forces.get_spring{medium = medium, body1 = b1, body2 = b2, K = 2, l0 = 1}
  s.apply(0)
  T.vnear(b1.force, {4, 0, 0}, 1e-12, 'pulled toward body2')
  T.vnear(b2.force, {-4, 0, 0}, 1e-12, 'pulled toward body1')
end)

local function oscillate ( drag, seconds )
  local b1 = ball{fixed = true}
  local b2 = ball{position = vec3.new{1.1, 0, 0}}
  local s = forces.get_spring{medium = medium, body1 = b1, body2 = b2, K = 1, l0 = 1, drag = drag}
  local dt = 0.001
  local lo, hi, crossings, first, last = math.huge, -math.huge, 0, nil, nil
  local prev = b2.position[1] - 1
  for i = 1, math.floor(seconds / dt) do
    s.apply(0); b1:update(dt); b2:update(dt)
    local x = b2.position[1] - 1
    lo, hi = math.min(lo, x), math.max(hi, x)
    if prev > 0 and x <= 0 then  -- downward zero crossing
      crossings = crossings + 1
      first = first or i * dt
      last = i * dt
    end
    prev = x
  end
  return lo, hi, crossings, first, last, b2
end

T.test('spring without drag: bounded oscillation with period 2 pi sqrt(m/K)', function()
  local lo, hi, crossings, first, last = oscillate(nil, 40)
  T.near(lo, -0.1, 1e-3)
  T.near(hi, 0.1, 1e-3)
  T.near((last - first) / (crossings - 1), 2 * math.pi, 0.01)
end)

T.test('spring with drag: oscillation decays', function()
  local _, _, _, _, _, b2 = oscillate(0.5, 40)
  T.near(b2.position[1], 1, 1e-3)
end)

T.test('spring drag uses each body\'s own point velocity', function()
  -- body1 spins, so its attachment point moves; no spring force (K = 0)
  local b1 = ball{angular_velocity = vec3.new{0, 0, 1}}
  local b2 = ball{position = vec3.new{5, 0, 0}, fixed = true}
  local s = forces.get_spring{medium = medium, body1 = b1, body2 = b2, point1 = vec3.new{1, 0, 0}, K = 0, drag = 1}
  s.apply(0)
  T.vnear(b1.force, {0, -1, 0}, 1e-12)
end)

-- gravity -------------------------------------------------------------------

T.test('get_gravity: G m1 m2 / d^2, attractive', function()
  local b1 = ball(nil, 1)
  local b2 = ball({position = vec3.new{2, 0, 0}}, 1e6)
  forces.get_gravity{medium = medium, body1 = b1, body2 = b2}.apply(0)
  local F = G * 1 * 1e6 / 4
  T.vnear(b1.force, {F, 0, 0}, 1e-20)
  T.vnear(b2.force, {-F, 0, 0}, 1e-20)
end)

-- floater_points ------------------------------------------------------------

local function boat ( z, vz )
  local b = rbody.new{
    inertia = inertia.element.from_shape('cuboid', {size = vec3.new{4, 2, 1}, mass = 600}),
    position = vec3.new{0, 0, z},
    velocity = vec3.new{0, 0, vz or 0},
  }
  local points = {}
  for _, x in ipairs{-2, 2} do
    for _, y in ipairs{-1, 1} do points[#points+1] = vec3.new{x, y, -0.5} end
  end
  local f = forces.floater_points{medium = medium, body = b, points = points, FL = 0.5, DL = 1, drag = 100}
  return b, f
end

T.test('floater_points: weight supported at the float line', function()
  local b, f = boat(0)  -- points 0.5 m deep = FL
  f.apply(0)
  T.vnear(b.force, {0, 0, 600 * g}, 1e-9)
  T.vnear(b.torque, {0, 0, 0}, 1e-9)
end)

T.test('floater_points: buoyancy proportional to depth, capped at the deck', function()
  local b, f = boat(0.25)  -- points 0.25 m deep
  f.apply(0)
  T.near(b.force[3], 300 * g, 1e-9)
  b, f = boat(-5)  -- fully under
  f.apply(0)
  T.near(b.force[3], 1200 * g, 1e-9, 'capped at DL/FL times the weight')
end)

T.test('floater_points: no force out of the water', function()
  local b, f = boat(10, -1)
  f.apply(0)
  T.vnear(b.force, {0, 0, 0})
end)

T.test('floater_points: drag only on submerged points', function()
  local b, f = boat(0, -1)
  -- lift the last two points out of the water (they come after submerged
  -- ones, so stale drag from those would leak into them)
  f.points[3][3], f.points[4][3] = 5, 5
  f.apply(0)
  -- 2 submerged points: 2 * (Wp + drag); out-of-water points add nothing
  T.near(b.force[3], 2 * (600 * g / 4 + 100), 1e-9)
end)

T.test('a force without a medium is refused', function()
  for _, name in ipairs{'get_constant_w', 'get_constant_d', 'get_spring', 'get_gravity', 'floater_points'} do
    T.raises(function() forces[name]{} end, 'medium', name)
  end
end)
