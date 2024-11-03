-- derived from https://github.com/infusion/Quaternion.js/blob/master/quaternion.js

-- XY surface
--   X: east, right
--   Y: north, away
--   Z: up
-- Roll: X axis
-- Pitch: Y Axis
-- Yaw: Z axis

local M = {}

local vec3 = require 'fsim.vec3'
local mat3 = require 'fsim.mat3'

local sin 	= math.sin
local cos 	= math.cos
local acos 	= math.acos
local asin 	= math.asin
local sqrt 	= math.sqrt
local atan2 = math.atan2
local abs	= math.abs
local exp = math.exp
local log = math.log

local LOG_2 = log(2)
local PI = math.pi
local PI2 = PI*2
local PI_2 = PI/2
local EPS =  1e-8 --1e-16;

M.__index = M

-- x, y, z, w
M.new = function ( q )
  q = q or { 0.0, 0.0, 0.0, 1.0 } -- identity quaternion
  return setmetatable( q, M )
end

M.set = function ( q, x, y, z, w)
  q[1], q[2], q[3], q[4] = x, y, z, w
  return q
end

M.clone = function ( q, out )
  if out==nil then 
    return M.new{ q[1], q[2], q[3], q[4] } 
  else
    return M.set( out, q[1], q[2], q[3], q[4] )
  end  
end

M.eq = function ( a, b )
  return (a[1]==b[1]) and (a[2]==b[2]) and (a[3]==b[3]) and (a[4]==b[4])
end

M.eq_approx = function ( a, b )
  ---[[
  return (a[1]-b[1]<EPS) 
  and (a[2]-b[2]<EPS) 
  and (a[3]-b[3]<EPS) 
  and (a[4]-b[4]<EPS)
  --]]
  --return M.dot(a, a) > 1-EPS
end

M.add = function ( a, b, out )
  return M.set( out, a[1]+b[1], a[2]+b[2], a[3]+b[3], a[4]+b[4] )
end

M.add_scaled = function ( a, b, s, out )
  return M.set( out, a[1]+s*b[1], a[2]+s*b[2], a[3]+s*b[3], a[4]+s*b[4] )
end

M.sub = function ( a, b, out )
  return M.set( out, a[1]-b[1], a[2]-b[2], a[3]-b[3], a[4]-b[4] )
end

-- unitary minus  (e.g in the expression f(-p))
M.unm = function ( q, out )
  return M.set( out, -q[1], -q[2], -q[3], -q[4] )
end

M.norm = function ( q )
  return sqrt(q[1]*q[1] + q[2]*q[2] + q[3]*q[3] + q[4]*q[4])
end
M.norm_sq = function ( q )
  return q[1]*q[1] + q[2]*q[2] + q[3]*q[3] + q[4]*q[4]
end

M.normalize = function ( q, out )
  local l = 1/sqrt(q[1]*q[1] + q[2]*q[2] + q[3]*q[3] + q[4]*q[4])
  return M.set( out, q[1]*l, q[2]*l, q[3]*l, q[4]*l )
end

M.mul = function ( a, b, out )
  local x1, y1, z1, w1 = a[1], a[2], a[3], a[4]
  local x2, y2, z2, w2 = b[1], b[2], b[3], b[4]

  return M.set( out, 
    w1*x2 + x1*w2 + y1*z2 - z1*y2,
    w1*y2 + y1*w2 + z1*x2 - x1*z2,
    w1*z2 + z1*w2 + x1*y2 - y1*x2,
    w1*w2 - x1*x2 - y1*y2 - z1*z2
  )
end

M.dot = function ( a, b )
  return a[1]*b[1] + a[2]*b[2] + a[3]*b[3] + a[4]*b[4]
end

M.mul_scalar = function ( q, s, out )
  return M.set( out, s*q[1], s*q[2], s*q[3] )
end

M.inverse = function ( q, out )
  out = out or M.new()
  local x, y, z, w = q[1], q[2], q[3], q[4]
  local ls = 1/(x*x+y*y+z*z+w*w)
  return M.set( out, -x*ls, -y*ls, -z*ls, w*ls )
end

M.div = function ( a, b, out )
  local x1, y1, z1, w1 = a[1], a[2], a[3], a[4]
  local x2, y2, z2, w2 = b[1], b[2], b[3], b[4]

  local ls = 1/(x2*x2+y2*y2+z2*z2+w2*w2)

  return M.set( out,
    (x1*w2 - w1*x2 - y1*z2 + z1*y2) * ls,
    (y1*w2 - w1*y2 - z1*x2 + x1*z2) * ls,
    (z1*w2 - w1*z2 - x1*y2 + y1*x2) * ls,
    (w1*w2 + x1*x2 + y1*y2 + z1*z2) * ls
  )
end

M.conjugate = function ( q, out )
  --if out==nil then
  --  return M.new{ -q[1], -q[2], -q[3], q[4] }
  --else
    return M.set( -q[1], -q[2], -q[3], q[4] )
  --end
end

M.exp = function ( q, out )
  --out = out or M.new()

  local x, y, z, w = q[1], q[2], q[3], q[4]
  local vnorm = sqrt(x*x+y*y+z*z)
  local wexp = exp(w)
  local scale = wexp / vnorm * sin(vnorm)
  return M.set(out, q[1]*scale, q[2]*scale, q[3]*scale, wexp*cos(vnorm) )
end

local function log_hypot ( a, b )
  local _a, _b = abs(a), abs(b)
  if a==0 then 
    return log(_b)
  end
  if b==0 then 
    return log(_a)
  end
  if _a<3000 and _b<3000 then
    return 0.5*log(a*a+b*b)
  end
  a, b = a/2, b/2
  return 0.5*log(a*a+b*b) + LOG_2
end

M.log =function ( q, out )
  out = out or M.new()

  local x, y, z, w = q[1], q[2], q[3], q[4]
  if y==0 and z==0 then
    return q:set( atan2(x, w), 0, 0, log_hypot(w, x) )
  end
  local qnorm2 = x*x+y*y+z*z+w*w
  local vnorm = sqrt(x*x+y*y+z*z)
  local scale = atan2(vnorm, w) / vnorm

  return M.set(out, x*scale, y*scale, z*scale, log(qnorm2)*0.5 )  
end

-- TODO
M.pow_real = function (  )
  error('NYI')
end

M.to_mat3 = function ( q, out )
  out = out or mat3.new()

  local x, y, z, w = q[1], q[2], q[3], q[4]
  local wx, wy, wz = w*x, w*y, w*z
  local xx, xy, xz = x*x, x*y, x*z
  local yy, yz, zz = y*y, y*z, z*z

  return mat3.set(out,
    1 - 2*(yy + zz), 2*(xy - wz), 2*(xz + wy),
    2*(xy + wz), 1 - 2*(xx + zz), 2*(yz - wx),
    2*(xz - wy), 2*(yz + wx), 1 - 2*(xx + yy)
  )
end

--roll,pitch,yaw 
M.to_euler = function ( q, out )
  --https://irrlicht.sourceforge.io/docu/quaternion_8h_source.html
  out = out or vec3.new()

  local x, y, z, w = q[1], q[2], q[3], q[4]
  local t = 2*(y*w - x*z)

  if t>1-EPS then
    out[1] = 0
    out[2] = PI_2
    out[3] = 2.0*atan2(x, w)
  elseif t<-1+EPS then
    out[1] = 0
    out[2] = -PI_2
    out[3] = 2.0*atan2(x, w)
  else
    local xx, yy, zz, ww = x*x, y*y, z*z, w*w
    out[1] = atan2( 2.0*(y*z + x*w), -xx-yy+zz+ww ) 
    if t<=-1 then 
      out[2] = -PI_2
    elseif t>=1 then 
      out[2] = PI_2
    else 
      out[2] = asin(t) 
    end
    out[3] = atan2( 2.0*(x*y + z*w), xx-yy-zz+ww )
  end

  return out
end

M.rotate_vec = function ( q, v, out )
  local qx, qy, qz, qw = q[1], q[2], q[3], q[4]
  local vx, vy, vz = v[1], v[2], v[3]

  local tx = 2*(qy*vz - qz*vy)
  local ty = 2*(qz*vx - qx*vz)
  local tz = 2*(qx*vy - qy*vx)

  return vec3.set( out, 
    vx + qw*tx + qy*tz - qz*ty,
    vy + qw*ty + qz*tx - qx*tz,
    vz + qw*tz + qx*ty - qy*tx
  )
end

M.slerp = function ( a, b )
  local x1, y1, z1, w1 = a[1], a[2], a[3], a[4]
  local x2, y2, z2, w2 = b[1], b[2], b[3], b[4]

  local costheta0 = w1*w2 + x1*x2 + y1*y2 + z1*z2

  if costheta0<0 then
    w1 = -w1
    x1 = -x1
    y1 = -y1
    z1 = -z1
    costheta0 = -costheta0
  end

  if costheta0>= 1-EPS then
    return function ( pct, out )
      out = out or M.new()
      M.set( out, z1+pct*(z2-z1), x1+pct*(x2-x1),y1+pct*(y2-y1),w1+pct*(w2-w1) )
      M.normalize(out, out)
      return out
    end
  end

  local theta0 = acos(costheta0);
  local sintheta0 = sin(theta0);

  return function ( pct, out )
    out = out or M.new()
    local theta = theta0*pct
    local sintheta, costheta = sin(theta), cos(theta)
    local s0 = costheta - costheta0*sintheta/sintheta0
    local s1 = sintheta/sintheta0

    out:set(s0*x1 + s1*x2, s0*y1 + s1*y2, s0*z1 + s1*z2, s0*w1 + s1*w2 )
    return out
  end
end

-- angle in right hand rule
M.from_axis_angle = function ( axis, angle, out )
  out = out or M.new()
  local halfangle = angle*0.5
  local x, y, z = axis[1], axis[2], axis[3]
  local sin_2, cos_2 = sin(halfangle), cos(halfangle)
  local sin_norm = sin_2 / sqrt(x*x + y*y + z*z);

  return M.set( out, x*sin_norm, y*sin_norm, z*sin_norm, cos_2 )
end

M.from_between_vectors = function ( u, v, out )
  out = out or M.new()

  local ux, uy, uz = u[1], u[2], u[3]
  local vx, vy, vz = v[1], v[2], v[3]

  local ulen = sqrt(ux*ux + uy*uy + uz*uz)
  local vlen = sqrt(vx*vx + vy*vy + vz*vz)

  if ulen > 0 then 
    ux, uy, uz = ux/ulen, uy/ulen, uz/ulen 
  end
  if vlen > 0 then 
    vx, vy, vz = vx/vlen, vy/vlen, vz/vlen 
  end
  local dot = ux*vx + uy*vy + uz*vz;

  -- Parallel check when dot > 0.999999
  if dot >= 1 - EPS then
    return M.set( out, 0, 0, 0, 1 )
  end
  -- Close to PI when dot < -0.999999
  if 1 + dot <= EPS then
    -- Rotate 180° around any orthogonal vector
    if abs(ux) > abs(uz) then
      return M.from_axis_angle({-uy, ux, 0}, PI, out)
    else
      return M.from_axis_angle({0, -uz, uy}, PI, out)
    end
  end

  M.set( out, uy*vz - uz*vy, uz*vx - ux*vz, ux*vy - uy*vx, 1 + dot )
  M.normalize(out, out)

  return out
end

M.random = function ( out )
  out = out or M.new()

  local u1 = math.random();
  local u2 = math.random();
  local u3 = math.random();

  local s = sqrt(1 - u1);
  local t = sqrt(u1);

  return M.set( out, 
    s*sin( PI2*u2 ),
    s*cos( PI2*u2 ),
    t*sin( PI2*u3 ),
    t*cos( PI2*u3 )
  )
end

M.from_euler = function ( phi, theta, psi, order, out) 
  out = out or M.new()

  local _x = phi * 0.5;
  local _y = theta * 0.5;
  local _z = psi * 0.5;

  local cx = cos(_x)
  local cy = cos(_y)
  local cz = cos(_z)

  local sx = sin(_x)
  local sy = sin(_y)
  local sz = sin(_z)

  if not order or order == 'ZXY' then
    return M.set( out, 
      cx*cz*sy - cy*sx*sz,
      cx*cy*sz + cz*sx*sy,
      cy*cz*sx + cx*sy*sz,
      cx*cy*cz - sx*sy*sz)
  end
  if order == 'XYZ' or order == 'RPY' then
    return M.set( out, 
      cy*cz*sx + cx*sy*sz,
      cx*cz*sy - cy*sx*sz,
      cx*cy*sz + cz*sx*sy,
      cx*cy*cz - sx*sy*sz)
  end
  if order == 'YXZ' then
    return M.set( out, 
      cx*cz*sy + cy*sx*sz,
      cy*cz*sx - cx*sy*sz,
      cx*cy*sz - cz*sx*sy,
      cx*cy*cz + sx*sy*sz)
  end
  if order == 'ZYX' or order == 'YPR' then
    return M.set( out, 
      cx*cy*sz - cz*sx*sy,
      cx*cz*sy + cy*sx*sz,
      cy*cz*sx - cx*sy*sz, 
      cx*cy*cz + sx*sy*sz)
  end
  if order == 'YZX' then
    return M.set( out, 
      cx*cy*sz + cz*sx*sy,
      cy*cz*sx + cx*sy*sz,
      cx*cz*sy - cy*sx*sz,
      cx*cy*cz - sx*sy*sz)
  end
  if order == 'XZY' then
    return M.set( out, 
      cy*cz*sx - cx*sy*sz,
      cx*cy*sz - cz*sx*sy,
      cx*cz*sy + cy*sx*sz,
      cx*cy*cz + sx*sy*sz)
  end
  error('unsuported order in quaternion.from_euler')
end

M.from_matrix = function ( m, out )
  out = out or M.new()

  local m00, m01, m02 = m[1], m[2], m[3]
  local m10, m11, m12 = m[4], m[5], m[6]
  local m20, m21, m22 = m[7], m[8], m[9]
  local tr = m00 + m11 + m22

  if tr > 0 then
    local s = sqrt(tr + 1.0)*2
    return M.set( out, (m21 - m12)/s, (m02 - m20)/s, (m10 - m01)/s, 0.25*s)
  elseif m00>m11 and m00>m22 then
    local s = sqrt(1.0 + m00 - m11 - m22)*2
    return M.set( out, 0.25*s, (m01 + m10)/s, (m02 + m20)/s,(m21 - m12)/s)
  elseif m11>m22 then
    local s = sqrt(1.0 + m11 - m00 - m22)*2
    return M.set( out, (m01 + m10)/s, 0.25*s, (m12 + m21)/s, (m02 - m20)/s)
  else
    local s = sqrt(1.0 + m22 - m00 - m11)*2
    return M.set( out, (m02 + m20)/s, (m12 + m21)/s, 0.25*s, (m10 - m01)/s)
  end
end

M.new_zero = function () return M.new{ 0, 0, 0, 0 } end
M.new_one  = function () return M.new{ 0, 0, 0, 1 } end
M.new_i    = function () return M.new{ 1, 0, 0, 0 } end
M.new_j    = function () return M.new{ 0, 1, 0, 0 } end
M.new_k    = function () return M.new{ 0, 0, 1, 0 } end

M.__tostring = function( q )
  return "["..q[1]..","..q[2]..","..q[3]..";"..q[4].."]"
end
M.__concat = function ( a, b )
  return tostring(a)..tostring(b)
end

M.__add = function(a, b) 
  local out = M.new()
  return M.add(a, b, out)
end
M.__sub = function(a, b) 
  local out = M.new()
  return M.sub(a, b, out)
end
M.__div = function(a, b) 
  local out = M.new()
  return M.div(a, b, out)
end
M.__mul = function(a, b) 
  local out = M.new()
  if a[4] and b[4] then -- quat*quat
    return M.mul(a, b, out) 
  elseif b[3] then      -- quat*vec
    return M.rotate_vec(a, b, out)
  elseif a[4] then      -- quat*number
    return M.mul_scalar(a, b, out)
  else                  -- number*quat
    return M.mul_scalar(b, a, out)
  end 
end
M.__eq = M.eq
M.__unm = function (p)
  local out = M.new()
  return M.unm(p, out)
end

return M