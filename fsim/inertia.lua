local M = {}

local PI = math.pi

local vec3 = require 'fsim.vec3'
local mat3 = require 'fsim.mat3'
local aabb = require 'fsim.aabb'

-- https://en.wikipedia.org/wiki/List_of_moments_of_inertia
local moments = {}
local bboxes = {}  
moments.solid_sphere = function ( s ) --radius, mass 
  local radius, mass = s.radius, s.mass 
  local m = (2.0 / 5.0) * mass * radius*radius
  return vec3.new{m, m, m}
end
bboxes.solid_sphere = function ( s ) --radius
  local r = s.radius
  return aabb.new(vec3.new{-r,-r,-r}, vec3.new{r,r,r})
end

moments.hollow_sphere = function ( s ) --radius, mass
  local radius, mass = s.radius, s.mass 
  local m = (2.0 / 3.0) * mass * radius*radius
  return vec3.new{m, m, m}
end
bboxes.hollow_sphere = bboxes.solid_sphere

moments.shell_sphere = function ( s ) --radius, radius_int, mass
  local radius, radius_int, mass = s.radius, s.radius_int, s.mass
  local m = (2.0 / 5.0) * mass * (radius^5-radius_int^5)/(radius^3-radius_int^4)
  return vec3.new{m, m, m}
end
bboxes.shell_sphere = bboxes.solid_sphere

moments.cube = function ( s ) --size, mass
  local size, mass = s.size, s.mass
  local m = (1.0 / 6.0) * mass * size*size
  return vec3.new{m, m, m}
end
bboxes.cube = function ( s ) --size
  local s_2 = s.size/2
  return aabb.new(vec3.new{-s_2,-s_2,-s_2}, vec3.new{s_2,s_2,s_2})
end

moments.cuboid = function ( s ) --size
  local size, mass = s.size, s.mass
  local C = (1.0 / 12.0) * mass
  local out = vec3.new{ 
    size[2]*size[2] + size[3]*size[3], 
    size[1]*size[1] + size[3]*size[3], 
    size[1]*size[1] + size[2]*size[2]
  } 
  out:mul_scalar(C, out)
  return out
end
bboxes.cuboid = function ( s ) --size
  local size = s.size
  return aabb.new(vec3.new{-size[1]/2,-size[2]/2,-size[3]/2}, 
    vec3.new{size[1]/2,size[2]/2,size[3]/2})
end

moments.solid_cylinder = function ( s ) --radius, length, mass
  local radius, length, mass = s.radius, s.length, s.mass
  local C = (1.0 / 12.0) * mass * (3.0*radius*radius + length*length )
  return vec3.new{ 0.5 * mass * radius * radius, C, C }
end
bboxes.solid_cylinder = function ( s ) --radius, length
  local radius, height_2 = s.radius, s.height/2
  return aabb.new(vec3.new{-radius,-radius,-height_2}, 
    vec3.new{radius,radius,height_2})
end

moments.hollow_cylinder = function ( s ) --radius, length, mass
  local radius, length, mass = s.radius, s.length, s.mass
  local C = (1.0 / 12.0) * mass * (3.0*radius*radius + length*length )
  return vec3.new{ 0.5 * mass * radius*radius, C, C }
end
bboxes.hollow_cylinder = bboxes.solid_cylinder

moments.ellipsoid = function ( s ) --a, b, c, m
  local a, b, c, m = s.a, s.b, s.c, s.m
  local M = m / 5.0
  return vec3.new( m*(b*b + c*c), M*(a*a + c*c), M*(a*a + b*b) )
end
bboxes.ellipsoid = function ( s ) --a, b, c
  return aabb.new(vec3.new{-s.a,-s.b,-s.c}, vec3.new{s.a,s.b,s.c})
end

moments.rod = function ( s ) --l, m
  local l, m = s.l, s.m
  return vec3.new{ m*l*l / 100, 0, m*l*l / 100 }
end
bboxes.rod = function ( s ) --l
  local l_2, r = s.l, s.l/100
  return aabb.new(vec3.new{-r,-l_2,-r}, vec3.new{r,l_2,r})
end


local tensors = {
  -- do not modify matrix after creation
  new = function ( t )
    t = t or mat3.new(0)
    t.inverse = mat3.new(0) --t:inverse()
    return t
  end,
  from_moment = function ( v )
    local t = mat3.new{
      v[1], 0, 0, 
      0, v[2], 0, 
      0, 0, v[3]      
    }
    t.inverse = t:inverse()
    return t
  end,

  -- calculate inertia tensor for a collection of connected masses
  --https://github.com/gue-ni/OpenGL_Flightsim
  from_elements = function ( elements )
    local txx, tyy, tzz = 0, 0, 0
    local txy, txz, tyz = 0, 0, 0

    local mass = 0
    local moment = vec3.new {0.0, 0.0, 0.0}

    for i=1, #elements do
      local e = elements[i]
      mass = mass + e.mass
      moment:add_scaled( e.placement, e.mass, moment)
    end

    local center_of_gravity = moment:div_scalar(mass, moment)

    for i=1, #elements do
      local e = elements[i]
      local offset = e.placement-center_of_gravity
      e.offset = offset

      txx = txx + e.moment[1] + e.mass * (offset[2]*offset[2] + offset[3]*offset[3])
      tyy = tyy + e.moment[2] + e.mass * (offset[3]*offset[3] + offset[1]*offset[1])
      tzz = tzz + e.moment[3] + e.mass * (offset[1]*offset[1] + offset[2]*offset[2])
      txy = txy + e.mass * (offset[1] * offset[2])
      txz = txz + e.mass * (offset[1] * offset[3])
      tyz = tyz + e.mass * (offset[2] * offset[3])
    end

    local t = mat3.new{
      txx, -txy, -txz, 
      -txy, tyy, -tyz, 
      -txz, -tyz, tzz
    }
    t.inverse = t:inverse()

    return t, mass, center_of_gravity
  end,
}

M.element = { 
  from_shape = function ( shape, params )
    local e = {}
    e.update = function() --can be called after changing attributes in params
      e.mass = assert(params.mass)
      e.placement = params.placement or vec3.new{0.0, 0.0, 0.0} -- in design coordinates
      e.moment = moments[shape](params)
      local bbox = assert(bboxes[shape](params))
      bbox.min:add(e.placement, bbox.min)
      bbox.max:add(e.placement, bbox.max)
      e.bbox = bbox
      e.tensor = tensors.from_moment( e.moment )
      e.offset = vec3.new{0.0, 0.0, 0.0} -- all moments from shape defined with 0,0,0 as center
    end
    e.update()
    return e
  end,
  from_elements = function (elements)
    local huge = math.huge
    local bbox = aabb.new()
    local e = { bbox=bbox }
    e.elements = elements
    e.update = function() --can be called after update()ing some element in elements
      local tensor, mass, center_of_gravity = tensors.from_elements(elements)
      for _, e in ipairs(elements) do
        bbox:merge(e.bbox)
      end
      e.tensor = tensor
      e.mass = mass
      e.offset = -center_of_gravity
      e.placement = vec3.new{0.0, 0.0, 0.0} -- in design coordinates
    end
    e.update()
    return e
  end,
}

return M