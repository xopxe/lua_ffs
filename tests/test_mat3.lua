local T = require 'tests.lib'
local mat3 = require 'fsim.mat3'
local vec3 = require 'fsim.vec3'

local I = {1, 0, 0, 0, 1, 0, 0, 0, 1}
local A = mat3.new{2, -1, 0, 1, 3, 2, 0, 1, 4}  -- invertible, det = 18

T.test('set: zero, identity, rows, nested', function()
  T.vnear(mat3.new():set(0), {0, 0, 0, 0, 0, 0, 0, 0, 0})
  T.vnear(mat3.new():set(1), I)
  T.vnear(mat3.new():set({1, 2, 3}, {4, 5, 6}, {7, 8, 9}), {1, 2, 3, 4, 5, 6, 7, 8, 9})
  T.vnear(mat3.new():set({{1, 2, 3}, {4, 5, 6}, {7, 8, 9}}), {1, 2, 3, 4, 5, 6, 7, 8, 9})
  T.raises(function() mat3.new():set('x') end, 'not supported')
end)

T.test('get_ij / set_ij are row-major', function()
  local m = mat3.new{1, 2, 3, 4, 5, 6, 7, 8, 9}
  T.eq(m:get_ij(1, 3), 3)
  T.eq(m:get_ij(3, 1), 7)
  m:set_ij(2, 3, 60)
  T.eq(m[6], 60)
end)

T.test('transpose', function()
  T.vnear(A:transpose(), {2, 1, 0, -1, 3, 1, 0, 2, 4})
  T.vnear(A:transpose():transpose(), A)
end)

T.test('dot_vec multiplies matrix by column vector', function()
  T.vnear(A:dot_vec(vec3.new{1, 2, 3}), {0, 13, 14})
end)

T.test('dot_mat multiplies matrices', function()
  T.vnear(A:dot_mat(mat3.new_identity()), A)
  T.vnear(mat3.new{1, 2, 0, 0, 1, 0, 0, 0, 1}:dot_mat(mat3.new{1, 0, 0, 3, 1, 0, 0, 0, 1}),
    {7, 2, 0, 3, 1, 0, 0, 0, 1})
end)

T.test('inverse: A * inv(A) = I', function()
  local inv = A:inverse()
  T.vnear(A:dot_mat(inv), I, 1e-12)
  T.vnear(inv:dot_mat(A), I, 1e-12)
end)

T.test('inverse of a singular matrix is the zero matrix', function()
  T.vnear(mat3.new{1, 2, 3, 2, 4, 6, 0, 0, 1}:inverse(), {0, 0, 0, 0, 0, 0, 0, 0, 0})
end)

T.test('operators', function()
  local B = mat3.new{1, 1, 1, 1, 1, 1, 1, 1, 1}
  T.vnear(A + B, {3, 0, 1, 2, 4, 3, 1, 2, 5})
  T.vnear(A - A, {0, 0, 0, 0, 0, 0, 0, 0, 0})
  T.vnear(A * 2, {4, -2, 0, 2, 6, 4, 0, 2, 8})
  T.vnear(2 * A, {4, -2, 0, 2, 6, 4, 0, 2, 8})
  T.vnear(-(A:clone()), {-2, 1, 0, -1, -3, -2, 0, -1, -4})
  T.vnear(A ^ vec3.new{1, 2, 3}, {0, 13, 14}, 0, 'A^v is matrix*vector')
  T.vnear(A ^ mat3.new_identity(), A, 0, 'A^B is matrix*matrix')
  T.ok(A == mat3.new{2, -1, 0, 1, 3, 2, 0, 1, 4})
end)

-- known bugs ---------------------------------------------------------------

T.xfail('div_component divides', 'mat3.div_component multiplies', function()
  local r = mat3.div_component(mat3.new{1, 1, 1, 1, 1, 1, 1, 1, 1}, mat3.new{2, 2, 2, 2, 2, 2, 2, 2, 2})
  T.vnear(r, {0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5})
end)

T.xfail('dot_vec returns a vec3', 'default out is mat3.new()', function()
  local r = mat3.new_identity():dot_vec(vec3.new{1, 2, 3})
  T.eq(getmetatable(r), vec3)
end)

T.xfail('-m does not modify m', '__unm = M.unm, and Lua passes the operand twice, so it is used as out', function()
  local m = A:clone()
  local _ = -m
  T.vnear(m, A)
end)

T.xfail('row(i) returns row i', 'row() returns column i', function()
  T.vnear(mat3.new{1, 2, 3, 4, 5, 6, 7, 8, 9}:row(1), {1, 2, 3})
end)
