-- Axis-Aligned Bounding Box (AABB)

--local glmath = require("moonglmath")
local inf = math.huge
local math_min = math.min
local math_max = math.max
--local vec3 = glmath.vec3
local vec3 = require 'fsim.vec3'

local M = {}
local Mt = {
  __index = M,
  __tostring = function(aabb) return "AABB "..aabb.min.." "..aabb.max end,
  __concat = function(a, b) return a.type=="aabb" and tostring(a)..b or a..tostring(b) end,
}

function M.new(p1, p2)
  local min = vec3.new{inf, inf, inf}
  local max = vec3.new{-inf, -inf, -inf}
  local aabb = setmetatable({min=min, max=max}, Mt)
  if p1 then aabb:add_point(p1) end
  if p2 then aabb:add_point(p2) end
  aabb.center = (min+max)/2
  aabb.scale = max - min
  return aabb
end

function M.diagonal(aabb)
  return aabb.max-aabb.min
end

function M.reset(aabb)
-- Resets aabb to a box with no volume
  aabb.min = vec3.new{inf, inf, inf}
  aabb.max = vec3.new{-inf, -inf, -inf}
end

function M.add_point(aabb, other)
  local min, max = aabb.min, aabb.max
  min[1] = math_min(min[1], other[1])
  min[2] = math_min(min[2], other[2])
  min[3] = math_min(min[3], other[3])
  max[1] = math_max(max[1], other[1])
  max[2] = math_max(max[2], other[2])
  max[3] = math_max(max[3], other[3])

  aabb.center = (min+max)/2
  aabb.scale = max - min
end

function M.merge(aabb, other)
  local othermin, othermax = other.min, other.max
  local min, max = aabb.min, aabb.max
  min[1] = math_min(min[1], othermin[1])
  min[2] = math_min(min[2], othermin[2])
  min[3] = math_min(min[3], othermin[3])
  max[1] = math_max(max[1], othermax[1])
  max[2] = math_max(max[2], othermax[2])
  max[3] = math_max(max[3], othermax[3])

  aabb.center = (min+max)/2
  aabb.scale = max - min
end

return M
