local T = require 'tests.lib'
local vec3 = require 'fsim.vec3'

T.test('new defaults to zero', function()
  T.vnear(vec3.new(), {0, 0, 0})
end)

T.test('add, sub, add_scaled, unm', function()
  local a, b = vec3.new{1, 2, 3}, vec3.new{4, 5, 6}
  T.vnear(a:add(b, vec3.new()), {5, 7, 9})
  T.vnear(a:sub(b, vec3.new()), {-3, -3, -3})
  T.vnear(a:add_scaled(b, 2, vec3.new()), {9, 12, 15})
  T.vnear(a:unm(vec3.new()), {-1, -2, -3})
end)

T.test('scalar and component-wise mul/div', function()
  local a, b = vec3.new{1, 2, 3}, vec3.new{2, 4, 8}
  T.vnear(a:mul_scalar(2, vec3.new()), {2, 4, 6})
  T.vnear(a:div_scalar(2, vec3.new()), {0.5, 1, 1.5})
  T.vnear(a:mul_component(b, vec3.new()), {2, 8, 24})
  T.vnear(a:div_component(b, vec3.new()), {0.5, 0.5, 0.375})
end)

T.test('dot, norm, norm_sq', function()
  local a = vec3.new{3, 4, 12}
  T.near(a:dot(vec3.new{1, 1, 1}), 19)
  T.near(a:norm(), 13)
  T.near(a:norm_sq(), 169)
end)

T.test('cross product is right-handed', function()
  local x, y, z = vec3.new{1, 0, 0}, vec3.new{0, 1, 0}, vec3.new{0, 0, 1}
  T.vnear(x:cross(y), z)
  T.vnear(y:cross(z), x)
  T.vnear(z:cross(x), y)
  T.vnear(y:cross(x), {0, 0, -1})
end)

T.test('out parameter may alias an input', function()
  local a, b = vec3.new{1, 2, 3}, vec3.new{4, 5, 6}
  local expected = a:cross(b)
  a:cross(b, a)
  T.vnear(a, expected)
  local c = vec3.new{1, 1, 1}
  c:add(c, c)
  T.vnear(c, {2, 2, 2})
end)

T.test('normalize, with and without out', function()
  local a = vec3.new{0, 3, 4}
  T.vnear(a:normalize(), {0, 0.6, 0.8}, 1e-12)
  T.vnear(a, {0, 3, 4}, 0, 'normalize() without out must not modify input')
  a:normalize(a)
  T.vnear(a, {0, 0.6, 0.8}, 1e-12)
end)

T.test('angle between vectors', function()
  T.near(vec3.angle(vec3.new{1, 0, 0}, vec3.new{0, 2, 0}), math.pi/2, 1e-12)
  T.near(vec3.angle(vec3.new{1, 0, 0}, vec3.new{-3, 0, 0}), math.pi, 1e-12)
end)

T.test('operators', function()
  local a, b = vec3.new{1, 2, 3}, vec3.new{4, 5, 6}
  T.vnear(a + b, {5, 7, 9})
  T.vnear(b - a, {3, 3, 3})
  T.vnear(a * 2, {2, 4, 6})
  T.vnear(2 * a, {2, 4, 6})
  T.vnear(a * b, {4, 10, 18})
  T.vnear(b / 2, {2, 2.5, 3})
  T.vnear(-a, {-1, -2, -3})
  T.near(a ^ b, 32, 0, 'a^b is the dot product')
  T.ok(a == vec3.new{1, 2, 3})
  T.eq(tostring(vec3.new{1, 2, 3}), '(1,2,3)')
  T.eq(getmetatable(a + b), vec3, 'result keeps vec3 metatable')
end)
