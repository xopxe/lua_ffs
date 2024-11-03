local M = {}

local sqrt = math.sqrt
local acos = math.acos

M.__index = M

M.new = function ( p )
  p = p or {0,0,0}
  return setmetatable( p, M)
end

M.set = function ( p, x, y, z)
  if not p then 
    print '!'
  end
  p[1], p[2], p[3] = x, y, z
  return p
end

M.clone = function ( p, out )
  if out==nil then 
    return M.new{ p[1], p[2], p[3] }
  else
    return M.set( out, p[1], p[2], p[3] )
  end
end

M.eq = function ( a, b )
  return (a[1]==b[1]) and (a[2]==b[2]) and (a[3]==b[3])
end

M.add = function ( a, b, out )
  return M.set( out, a[1]+b[1], a[2]+b[2], a[3]+b[3] )
end

M.add_scaled = function ( a, b, s, out )
  return M.set( out, a[1]+s*b[1], a[2]+s*b[2], a[3]+s*b[3] )
end

M.sub = function ( a, b, out )
  return M.set( out, a[1]-b[1], a[2]-b[2], a[3]-b[3] )
end

-- unitary minus  (e.g in the expression f(-p))
M.unm = function ( p, out )
  return M.set( out, -p[1], -p[2], -p[3] )
end

-- scalar and component-wise multiplication and division
M.mul_scalar = function ( p, s, out )
  return M.set( out, s*p[1], s*p[2], s*p[3] )
end

M.mul_component = function ( a, b, out )
  return M.set( out, a[1]*b[1], a[2]*b[2], a[3]*b[3] )
end

M.div_scalar = function ( p, s, out )
  s = 1/s
  return M.set( out, p[1]*s, p[2]*s, p[3]*s )
end

M.div_component = function ( a, b, out )
  return M.set( out, a[1]/b[1], a[2]/b[2], a[3]/b[3] )
end

M.dot = function ( a, b )
  return a[1]*b[1] + a[2]*b[2] + a[3]*b[3]
end

M.cross = function ( a, b, out )
  out = out or M.new{}
  return M.set( out, 
    a[2]*b[3] - a[3]*b[2], 
    a[3]*b[1] - a[1]*b[3], 
    a[1]*b[2] - a[2]*b[1] 
  )
end

M.norm = function ( p )
  return sqrt(p[1]*p[1] + p[2]*p[2] + p[3]*p[3])
end
M.norm_sq = function ( p )
  return p[1]*p[1] + p[2]*p[2] + p[3]*p[3]
end

M.normalize = function ( p, out )
  local l = 1/sqrt(p[1]*p[1] + p[2]*p[2] + p[3]*p[3])
  if out==nil then
    return M.new{ p[1]*l, p[2]*l, p[3]*l }
  else
    return M.set( out, p[1]*l, p[2]*l, p[3]*l )
  end
end

M.angle = function ( a, b )
  return acos( M.dot(a, b) / (a:norm()*b:norm()) )
end

--[[
M.new_up 		= function() return M.new{0,1,0} end
M.new_down 	= function() return M.new{0,-1,0} end
M.new_right	= function() return M.new{1,0,0} end
M.new_left	= function() return M.new{-1,0,0} end
M.new_forward = function() return M.new{0,0,1} end
M.new_back	= function() return M.new{0,0,-1} end
M.new_zero	= function() return M.new{0,0,0} end
M.new_one		= function() return M.new{1,1,1} end
--]]

M.__add = function(a, b) 
  local out = M.new()
  return M.add(a, b, out)
end
M.__sub = function(a, b) 
  local out = M.new()
  return M.sub(a, b, out)
end
M.__mul = function(a, b) 
  local out = M.new()
  if type(b)=='number' then
    return M.mul_scalar(a, b, out) 
  elseif type(a)=='number' then
    return M.mul_scalar(b, a, out) 
  else
    return M.mul_component(a, b, out)
  end
end
M.__div = function(a, b) 
  local out = M.new()
  if type(b)=='number' then
    return M.div_scalar(a, b, out) 
  else
    return M.div_component(a, b, out)
  end
end
M.__pow = function(a, b) 
  return M.dot(a, b)
end
M.__eq = M.eq
M.__unm = function (p)
  local out = M.new()
  return M.unm(p, out)
end
M.__tostring = function ( p )
  return '('..p[1]..','..p[2]..','..p[3]..')'
end
M.__concat = function ( a, b )
  return tostring(a)..tostring(b)
end
return M