local M = {}

local vec3 = require 'fsim.vec3'
local aabb = require 'fsim.aabb'

local G = 6.674e-11
local g_accel = -9.8 --m/sec^2

local boxsize = vec3.new{0.1,0.1,0.1}*0.5

M.get_constant_w = function ( f )
  assert(f.body)
  f.point = f.point or vec3.new() -- design space
  f.force = f.force or vec3.new() -- world space
  f.bbox = aabb.new(f.point-boxsize, f.point+boxsize) -- design space
  f.apply = function()
    f.body:add_forcew_at_pointd( f.point )
  end
  return f
end

M.get_spring = function ( f )
  assert(f.body1)
  assert(f.body2)
  f.point1 = f.point1 or vec3.new() -- design space
  f.point2 = f.point2 or vec3.new() -- design space
  f.K = f.K or 1
  f.l0 = f.l0 or 1

  -- temp variables
  local p1 = vec3.new{0.0,0.0,0.0}
  local p2 = vec3.new{0.0,0.0,0.0}
  local force = vec3.new{0.0,0.0,0.0}
  local drag1, drag2 = vec3.new{0.0,0.0,0.0}, vec3.new{0.0,0.0,0.0}
  local velocityw = vec3.new{0.0,0.0,0.0}

  --XXXXXXXXXXXXXXXXXXXXXXXXXX
  f.bbox = aabb.new(p1, p2) -- world space

  f.apply = function()
    f.body1:get_pointd_positionw( f.point1, p1 )
    f.body2:get_pointd_positionw( f.point2, p2 )     
    p2:sub( p1, force )
    local l = force:norm()
    local F = f.K * (l - f.l0)
    force:mul_scalar( F / l, force )
    if not f.fixed1 then
      if f.drag and f.drag~=0.0 then 
        f.body1:get_pointd_velocityw(f.point2, velocityw)
        velocityw:mul_scalar( -f.drag, drag1 )
      end
      drag1:add(force, drag1)
      f.body1:add_forcew_at_pointd( drag1, f.point1 )
    end
    if not f.fixed2 then 
      if f.drag and f.drag~=0.0 then 
        f.body2:get_pointd_velocityw(f.point2, velocityw)
        velocityw:mul_scalar( -f.drag, drag2 )
      end
      force:unm( force )
      drag2:add(force, drag2)
      f.body2:add_forcew_at_pointd( drag2, f.point2 )
    end
  end
  return f
end

M.get_gravity = function ( f )
  assert(f.body1)
  assert(f.body2)

  -- temp variables
  local force = vec3.new()

  f.apply = function ()
    f.body2.position:sub( f.body1.position, force ) 
    local l2 = force:norm_sq()
    local F = G * (f.body1.inertia.mass^2) / l2
    force:mul_scalar( F / (math.sqrt(l2)), force )
    if not f.fixed1 then 
      f.body1:add_forcew_at_pointd( force )
    end
    force:unm( force )
    if not f.fixed2 then 
      f.body2:add_forcew_at_pointd( force )
    end
  end
  return f
end

M.get_constant_d = function ( f )
  assert(f.body)
  f.point = f.point or vec3.new() -- design space
  f.force = f.force or vec3.new() -- design space

  f.apply = function ()
    f.body:add_forced_at_pointd( f.force, f.point )
  end
  return f
end

local function linear_interpol(x1,y1, x2,y2, x)
  return y1+((x-x1)/(x2-x1))*(y2-y1)
end

M.floater_points = function ( f )
  assert(f.points)
  assert(f.body)
  assert(f.drag)

  assert(f.FL) -- float line from bottom
  assert(f.DL) -- deck height from bottom

  local medium = require('fsim.medium')

  local Wp = -g_accel * f.body.inertia.mass / #f.points

  f.bbox = aabb.new()
  for i=1, #f.points do
    f.bbox:add_point(f.points[i])
  end

  -- temp variables
  local p = vec3.new{0.0,0.0,0.0}
  local Ff = vec3.new{0.0,0.0,0.0}
  local velocityw = vec3.new{0.0,0.0,0.0}
  local drag = vec3.new{0.0,0.0,0.0}

  f.apply = function ( now )
    for i=1, #f.points do
      local pointd = f.points[i]
      f.body:get_pointd_positionw(pointd, p)
      local h = medium.surface.height(p[1], p[2], now) - p[3]
      if h>f.DL then
        Ff[3] = linear_interpol(0.0, 0.0, f.FL, Wp, f.DL)
      elseif h>0 then
        Ff[3] = linear_interpol(0.0, 0.0, f.FL, Wp, h)
      else -- h<0
        Ff[3] = 0.0
      end

      if h>0 and f.drag and f.drag~=0.0 then 
        f.body:get_pointd_velocityw(pointd, velocityw)
        --only on z axis
        --velocityw:mul_scalar( -f.drag, drag )
        drag:set(0.0, 0.0, -f.drag*velocityw[3])
      end
      Ff:add(drag, Ff)

      f.body:add_forcew_at_pointd(Ff, pointd)
    end
  end
  return f
end


return M