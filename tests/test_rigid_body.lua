local T = require 'tests.lib'
local rbody = require 'fsim.rigid_body'
local inertia = require 'fsim.inertia'
local vec3 = require 'fsim.vec3'
local quat = require 'fsim.quaternion'

local X, Z = vec3.new{1, 0, 0}, vec3.new{0, 0, 1}

-- solid sphere with I = 1 about every axis
local function unit_body ( t )
  t = t or {}
  t.inertia = t.inertia or inertia.element.from_shape('solid_sphere', {radius = 1, mass = 2.5})
  return rbody.new(t)
end

local function steps ( b, n, dt, each )
  for _ = 1, n do
    if each then each(b) end
    b:update(dt)
  end
end

local function random_vec () return vec3.new{math.random()*2-1, math.random()*2-1, math.random()*2-1} end

T.test('new fills in state', function()
  local b = unit_body()
  T.vnear(b.position, {0, 0, 0})
  T.vnear(b.velocity, {0, 0, 0})
  T.vnear(b.angular_velocity, {0, 0, 0})
  T.vnear(b.orientation, {0, 0, 0, 1})
end)

T.test('free fall under gravity', function()
  local b = unit_body{gravity = true, position = vec3.new{0, 0, 100}}
  steps(b, 1000, 0.001)
  T.near(b.velocity[3], -9.8, 1e-9)
  T.near(b.position[3], 100 - 0.5 * 9.8, 0.01)  -- semi-implicit Euler: O(dt) error
end)

T.test('no gravity unless enabled', function()
  local b = unit_body{position = vec3.new{0, 0, 100}}
  steps(b, 100, 0.01)
  T.vnear(b.position, {0, 0, 100})
end)

T.test('constant force: F = m a', function()
  local b = unit_body()
  steps(b, 1000, 0.001, function(b) b.force:set(2.5, 0, 0) end)
  T.vnear(b.velocity, {1, 0, 0}, 1e-9)
end)

T.test('force and torque are cleared after update', function()
  local b = unit_body()
  b.force:set(1, 2, 3); b.torque:set(1, 2, 3)
  b:update(0.01)
  T.vnear(b.force, {0, 0, 0})
  T.vnear(b.torque, {0, 0, 0})
end)

T.test('fixed body does not move', function()
  local b = unit_body{fixed = true, gravity = true, velocity = vec3.new{1, 0, 0}}
  steps(b, 10, 0.1, function(b) b.force:set(5, 5, 5); b.torque:set(1, 1, 1) end)
  T.vnear(b.position, {0, 0, 0})
end)

T.test('constant torque: dw/dt = torque / I', function()
  local b = unit_body()
  steps(b, 1000, 0.001, function(b) b.torque:set(0, 0, 1) end)
  T.vnear(b.angular_velocity, {0, 0, 1}, 1e-9)
end)

T.test('orientation integrates angular velocity', function()
  local b = unit_body{angular_velocity = vec3.new{0, 0, math.pi/2}}
  steps(b, 10000, 0.0001)
  T.vnear(b.orientation:rotate_vec(X, vec3.new()), {0, 1, 0}, 1e-3, 'quarter turn about z in 1 s')
  T.near(b.orientation:norm(), 1, 1e-12)
end)

T.test('angular velocity is in body space', function()
  -- body rotated 90 deg about z: its x axis points along world y
  local b = unit_body{
    orientation = quat.from_axis_angle(Z, math.pi/2),
    angular_velocity = vec3.new{math.pi/2, 0, 0},
  }
  steps(b, 10000, 0.0001)
  -- quarter turn about body x = world y takes world z to world x
  T.vnear(b.orientation:rotate_vec(quat.from_axis_angle(Z, -math.pi/2):rotate_vec(Z, vec3.new()), vec3.new()),
    {1, 0, 0}, 1e-3)
end)

T.test('transform_direction dw and wd are inverses', function()
  local b = unit_body{orientation = quat.random()}
  for _ = 1, 10 do
    local v = random_vec()
    T.vnear(b:transform_direction_wd(b:transform_direction_dw(v)), v, 1e-12)
  end
end)

T.test('get_pointd_positionw', function()
  local b = unit_body{position = vec3.new{10, 0, 0}, orientation = quat.from_axis_angle(Z, math.pi/2)}
  T.vnear(b:get_pointd_positionw(vec3.new{1, 0, 0}), {10, 1, 0}, 1e-12)
end)

T.test('get_pointd_positionw accounts for the center of gravity', function()
  local e = inertia.element.from_elements{
    inertia.element.from_shape('solid_sphere', {radius = 0.1, mass = 1, placement = vec3.new{0, 0, 0}}),
    inertia.element.from_shape('solid_sphere', {radius = 0.1, mass = 1, placement = vec3.new{2, 0, 0}}),
  }
  -- position is the center of gravity, which is at design (1, 0, 0)
  local b = rbody.new{inertia = e, position = vec3.new{5, 5, 5}, orientation = quat.from_axis_angle(Z, math.pi)}
  T.vnear(b:get_pointd_positionw(vec3.new{1, 0, 0}), {5, 5, 5}, 1e-12, 'center of gravity')
  T.vnear(b:get_pointd_positionw(vec3.new{0, 0, 0}), {6, 5, 5}, 1e-12, 'design origin, rotated 180')
end)

T.test('get_pointd_velocityw = v + R (w x r)', function()
  local b = unit_body{velocity = vec3.new{1, 0, 0}, angular_velocity = vec3.new{0, 0, 1}}
  T.vnear(b:get_pointd_velocityw(vec3.new{1, 0, 0}), {1, 1, 0}, 1e-12)
  for _ = 1, 10 do
    b = unit_body{velocity = random_vec(), angular_velocity = random_vec(), orientation = quat.random()}
    local r = random_vec()
    local expected = b.velocity + b.orientation:rotate_vec(b.angular_velocity:cross(r), vec3.new())
    T.vnear(b:get_pointd_velocityw(r), expected, 1e-12)
  end
end)

T.test('add_forcew_at_pointd: world force, body torque', function()
  for _ = 1, 10 do
    local b = unit_body{orientation = quat.random()}
    local F, r = random_vec(), random_vec()
    b:add_forcew_at_pointd(F, r)
    T.vnear(b.force, F, 1e-12)
    -- torque in world space, then expressed in body space
    local rw = b:transform_direction_dw(r)
    T.vnear(b.torque, b:transform_direction_wd(rw:cross(F)), 1e-12)
  end
end)

T.test('add_forced_at_pointd: design force, body torque', function()
  local b = unit_body{orientation = quat.from_axis_angle(Z, math.pi/2)}
  b:add_forced_at_pointd(vec3.new{1, 0, 0}, vec3.new{0, 1, 0})
  T.vnear(b.force, {0, 1, 0}, 1e-12, 'body x is world y')
  T.vnear(b.torque, {0, 0, -1}, 1e-12, 'r x F in body space')
end)

T.test('torque-free rotation conserves world angular momentum', function()
  local e = inertia.element.from_shape('cuboid', {size = vec3.new{1, 2, 3}, mass = 1})
  local b = rbody.new{inertia = e, angular_velocity = vec3.new{0.3, 0.2, 2.0}}
  local function L ()
    return b:transform_direction_dw(e.tensor:dot_vec(b.angular_velocity, vec3.new()))
  end
  local L0 = L()
  steps(b, 20000, 0.0001)
  T.vnear(L(), L0, 0.01 * L0:norm())
end)
