local T = require 'tests.lib'
local inertia = require 'fsim.inertia'
local vec3 = require 'fsim.vec3'

local shape = inertia.element.from_shape
local from_elements = inertia.element.from_elements
local I3 = {1, 0, 0, 0, 1, 0, 0, 0, 1}

T.test('solid_sphere: 2/5 m r^2', function()
  local e = shape('solid_sphere', {radius = 2, mass = 5})
  T.vnear(e.moment, {8, 8, 8}, 1e-12)
  T.eq(e.mass, 5)
  T.vnear(e.bbox.min, {-2, -2, -2})
  T.vnear(e.bbox.max, {2, 2, 2})
end)

T.test('hollow_sphere: 2/3 m r^2', function()
  T.vnear(shape('hollow_sphere', {radius = 1, mass = 3}).moment, {2, 2, 2}, 1e-12)
end)

T.test('shell_sphere: 2/5 m (r^5-ri^5)/(r^3-ri^3)', function()
  local expected = 0.4 * (1 - 0.5^5) / (1 - 0.5^3)
  T.near(shape('shell_sphere', {radius = 1, radius_int = 0.5, mass = 1}).moment[1], expected, 1e-12)
  -- with no cavity it is a solid sphere
  T.near(shape('shell_sphere', {radius = 1, radius_int = 0, mass = 1}).moment[1], 0.4, 1e-12)
end)

T.test('cube: 1/6 m s^2', function()
  local e = shape('cube', {size = 2, mass = 3})
  T.vnear(e.moment, {2, 2, 2}, 1e-12)
  T.vnear(e.bbox.max, {1, 1, 1})
end)

T.test('cuboid: 1/12 m (b^2+c^2), ...', function()
  local e = shape('cuboid', {size = vec3.new{4, 2, 1}, mass = 12})
  T.vnear(e.moment, {5, 17, 20}, 1e-12)
  T.vnear(e.bbox.min, {-2, -1, -0.5})
  T.vnear(e.bbox.max, {2, 1, 0.5})
end)

T.test('solid_cylinder: axis along x', function()
  local e = shape('solid_cylinder', {radius = 1, length = 2, mass = 1})
  T.vnear(e.moment, {0.5, 7/12, 7/12}, 1e-12)
  T.vnear(e.bbox.min, {-1, -1, -1})
  local long = shape('solid_cylinder', {radius = 0.5, length = 4, mass = 1})
  T.vnear(long.bbox.min, {-2, -0.5, -0.5}, 0, 'bbox length along x')
  T.vnear(long.bbox.max, {2, 0.5, 0.5})
end)

T.test('hollow_cylinder: thin wall, m r^2 about the axis', function()
  T.vnear(shape('hollow_cylinder', {radius = 1, length = 2, mass = 1}).moment, {1, 10/12, 10/12}, 1e-12)
end)

T.test('ellipsoid: m/5 (b^2+c^2), ...', function()
  T.vnear(shape('ellipsoid', {a = 1, b = 2, c = 3, mass = 5}).moment, {13, 10, 5}, 1e-12)
  -- a sphere is a special case
  T.vnear(shape('ellipsoid', {a = 2, b = 2, c = 2, mass = 5}).moment, {8, 8, 8}, 1e-12)
end)

T.test('rod: about m l^2 / 12, along y, invertible', function()
  local e = shape('rod', {l = 1, mass = 12})
  T.near(e.moment[1], 1, 1e-3)
  T.near(e.moment[3], 1, 1e-3)
  T.ok(e.moment[2] > 0 and e.moment[2] < 1e-3, 'small but non-zero moment about the rod axis')
  T.vnear(e.bbox.min, {-0.01, -0.5, -0.01}, 1e-12)
  T.vnear(e.tensor:dot_mat(e.tensor.inverse), I3, 1e-9)
end)

T.test('placement shifts the bounding box', function()
  local e = shape('cube', {size = 2, mass = 1, placement = vec3.new{10, 0, 0}})
  T.vnear(e.bbox.min, {9, -1, -1})
  T.vnear(e.bbox.max, {11, 1, 1})
end)

T.test('tensor carries its inverse', function()
  local e = shape('cuboid', {size = vec3.new{4, 2, 1}, mass = 12})
  T.vnear(e.tensor:dot_mat(e.tensor.inverse), I3, 1e-12)
end)

T.test('single element: center of gravity at placement', function()
  local e = shape('solid_sphere', {radius = 1, mass = 1, placement = vec3.new{0, 0, 5}})
  T.vnear(e.offset, {0, 0, -5})
end)

T.test('single element matches from_elements of one', function()
  local p = vec3.new{1, 2, 3}
  local single = shape('cuboid', {size = vec3.new{4, 2, 1}, mass = 12, placement = p})
  local multi = from_elements{ shape('cuboid', {size = vec3.new{4, 2, 1}, mass = 12, placement = p}) }
  T.vnear(single.offset, multi.offset, 1e-12)
  T.vnear(single.tensor, multi.tensor, 1e-12)
  T.eq(single.mass, multi.mass)
end)

T.test('from_elements: mass and center of gravity', function()
  local e = from_elements{
    shape('solid_sphere', {radius = 0.1, mass = 1, placement = vec3.new{0, 0, 0}}),
    shape('solid_sphere', {radius = 0.1, mass = 3, placement = vec3.new{4, 0, 0}}),
  }
  T.eq(e.mass, 4)
  T.vnear(e.offset, {-3, 0, 0}, 1e-12, 'offset is minus the center of gravity')
end)

T.test('from_elements: parallel axis theorem', function()
  local r, m, d = 0.1, 1, 1
  local e = from_elements{
    shape('solid_sphere', {radius = r, mass = m, placement = vec3.new{0, 0, d}}),
    shape('solid_sphere', {radius = r, mass = m, placement = vec3.new{0, 0, -d}}),
  }
  local own = 0.4 * m * r * r
  T.near(e.tensor[1], 2 * (own + m * d * d), 1e-12, 'Ixx')
  T.near(e.tensor[5], 2 * (own + m * d * d), 1e-12, 'Iyy')
  T.near(e.tensor[9], 2 * own, 1e-12, 'Izz')
  T.vnear({e.tensor[2], e.tensor[3], e.tensor[6]}, {0, 0, 0}, 1e-12, 'no products of inertia')
end)

T.test('from_elements: products of inertia are negative sums', function()
  local e = from_elements{
    shape('solid_sphere', {radius = 0.01, mass = 1, placement = vec3.new{1, 1, 0}}),
    shape('solid_sphere', {radius = 0.01, mass = 1, placement = vec3.new{-1, -1, 0}}),
  }
  T.near(e.tensor[2], -2, 1e-12, 'Ixy = -sum(m x y)')
  T.near(e.tensor[4], -2, 1e-12, 'symmetric')
  T.vnear(e.tensor:dot_mat(e.tensor.inverse), I3, 1e-9)
end)

T.test('from_elements: bounding box covers all elements', function()
  local e = from_elements{
    shape('cube', {size = 2, mass = 1, placement = vec3.new{-5, 0, 0}}),
    shape('cube', {size = 2, mass = 1, placement = vec3.new{5, 0, 3}}),
  }
  T.vnear(e.bbox.min, {-6, -1, -1})
  T.vnear(e.bbox.max, {6, 1, 4})
end)
