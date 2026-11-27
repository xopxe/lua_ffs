local T = require 'tests.lib'
local quat = require 'fsim.quaternion'
local vec3 = require 'fsim.vec3'
local mat3 = require 'fsim.mat3'

local rad, deg = math.rad, math.deg
local X, Y, Z = vec3.new{1, 0, 0}, vec3.new{0, 1, 0}, vec3.new{0, 0, 1}

local function axis_angle ( axis, angle ) return quat.from_axis_angle(axis, angle) end
-- roll about x, then pitch about y, then yaw about z (as to_euler decomposes)
local function rpy ( r, p, y )
  return axis_angle(Z, rad(y)) * axis_angle(Y, rad(p)) * axis_angle(X, rad(r))
end
local function random_vec () return vec3.new{math.random()*2-1, math.random()*2-1, math.random()*2-1} end

T.test('new is the identity rotation', function()
  T.vnear(quat.new():rotate_vec(vec3.new{1, 2, 3}, vec3.new()), {1, 2, 3})
end)

T.test('from_axis_angle: 90 deg about z takes x to y', function()
  local q = axis_angle(Z, math.pi/2)
  T.vnear(q:rotate_vec(X, vec3.new()), {0, 1, 0}, 1e-12)
  T.vnear(q:rotate_vec(Y, vec3.new()), {-1, 0, 0}, 1e-12)
  T.near(q:norm(), 1, 1e-12)
end)

T.test('from_axis_angle normalizes the axis', function()
  T.vnear(axis_angle(vec3.new{0, 0, 5}, 1.0), axis_angle(Z, 1.0), 1e-12)
end)

T.test('rotate_vec agrees with to_mat3', function()
  for _ = 1, 20 do
    local q, v = quat.random(), random_vec()
    T.vnear(q:rotate_vec(v, vec3.new()), q:to_mat3():dot_vec(v, vec3.new()), 1e-12)
  end
end)

T.test('mul composes rotations: (a*b)v = a(b(v))', function()
  for _ = 1, 20 do
    local a, b, v = quat.random(), quat.random(), random_vec()
    local expected = a:rotate_vec(b:rotate_vec(v, vec3.new()), vec3.new())
    T.vnear((a*b):rotate_vec(v, vec3.new()), expected, 1e-12)
  end
end)

T.test('inverse and div', function()
  for _ = 1, 20 do
    local a, b = quat.random(), quat.random()
    T.qnear(a * a:inverse(), quat.new(), 1e-12)
    T.qnear((a / b) * b, a, 1e-12)
  end
end)

T.test('normalize', function()
  T.near(quat.new{1, 2, 3, 4}:normalize(quat.new()):norm(), 1, 1e-12)
end)

T.test('random quaternions are unit length', function()
  for _ = 1, 20 do T.near(quat.random():norm(), 1, 1e-12) end
end)

T.test('from_between_vectors', function()
  for _ = 1, 20 do
    local u, v = random_vec(), random_vec()
    local q = quat.from_between_vectors(u, v)
    T.vnear(q:rotate_vec(u:normalize(), vec3.new()), v:normalize(), 1e-9)
  end
  T.qnear(quat.from_between_vectors(X, X * 3), quat.new(), 1e-12, 'parallel')
  T.vnear(quat.from_between_vectors(X, -X):rotate_vec(X, vec3.new()), {-1, 0, 0}, 1e-12, 'antiparallel')
end)

T.test('from_matrix inverts to_mat3', function()
  for _ = 1, 20 do
    local q = quat.random()
    T.qnear(quat.from_matrix(q:to_mat3()), q, 1e-9)
  end
  -- also exercise the non-positive-trace branches
  T.qnear(quat.from_matrix(axis_angle(X, rad(179)):to_mat3()), axis_angle(X, rad(179)), 1e-9)
  T.qnear(quat.from_matrix(axis_angle(Y, rad(179)):to_mat3()), axis_angle(Y, rad(179)), 1e-9)
  T.qnear(quat.from_matrix(axis_angle(Z, rad(179)):to_mat3()), axis_angle(Z, rad(179)), 1e-9)
end)

T.test('to_euler recovers roll, pitch, yaw', function()
  for _, a in ipairs{ {10, 20, 30}, {-45, 10, 170}, {80, -60, -20}, {0, 0, 0} } do
    local e = rpy(a[1], a[2], a[3]):to_euler()
    T.vnear({deg(e[1]), deg(e[2]), deg(e[3])}, a, 1e-9)
  end
end)

T.test('slerp interpolates along the great arc', function()
  local f = quat.slerp(quat.new(), axis_angle(Z, rad(90)))
  T.qnear(f(0), quat.new(), 1e-12)
  T.qnear(f(0.5), axis_angle(Z, rad(45)), 1e-12)
  T.qnear(f(1), axis_angle(Z, rad(90)), 1e-12)
end)

T.test('operators', function()
  local a = axis_angle(Z, 0.3)
  T.qnear(a + quat.new_zero(), a)
  T.qnear(a - a, quat.new_zero())
  T.qnear(-a, a, 0, '-q is the same rotation')
  T.ok(quat.new() == quat.new_one())
end)

-- known bugs ---------------------------------------------------------------

T.xfail('conjugate', 'passes -q[1] as the output table', function()
  T.vnear(quat.conjugate(quat.new{1, 2, 3, 4}, quat.new()), {-1, -2, -3, 4})
end)

T.xfail('mul_scalar scales all four components', 'drops w', function()
  T.vnear(quat.mul_scalar(quat.new{1, 2, 3, 4}, 2, quat.new()), {2, 4, 6, 8})
end)

T.xfail('q * number', '__mul indexes the number', function()
  T.vnear(quat.new{1, 2, 3, 4} * 2, {2, 4, 6, 8})
end)

T.xfail('slerp of nearly equal quaternions', 'near-parallel branch shuffles x,y,z', function()
  local q = axis_angle(vec3.new{1, 2, 3}, 0.5)
  T.qnear(quat.slerp(q, q)(0.5), q, 1e-9)
end)

T.xfail('eq_approx rejects different quaternions', 'no abs() in comparison', function()
  T.ok(not quat.eq_approx(quat.new_zero(), quat.new{5, 5, 5, 5}))
end)

T.xfail('log does not modify its input', 'writes the result into q instead of out', function()
  local q = quat.new{0.5, 0, 0, 0.5}
  quat.log(q, quat.new())
  T.vnear(q, {0.5, 0, 0, 0.5})
end)

T.xfail('to_euler at pitch +90 keeps yaw sign', 'gimbal branch uses +2*atan2, should be -2*atan2', function()
  local e = rpy(0, 90, 30):to_euler()
  T.vnear({deg(e[1]), deg(e[2]), deg(e[3])}, {0, 90, 30}, 1e-6)
end)

T.xfail('from_euler RPY round-trips through to_euler', 'from_euler builds Rx*Ry*Rz, to_euler expects Rz*Ry*Rx', function()
  local e = quat.from_euler(rad(10), rad(20), rad(30), 'RPY'):to_euler()
  T.vnear({deg(e[1]), deg(e[2]), deg(e[3])}, {10, 20, 30}, 1e-9)
end)
