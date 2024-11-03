local M = {}

local vec3 = require 'fsim.vec3'

M.__index = M

M.new = function ( m )
  m = m or {0,0,0,0,0,0,0,0,0}
  return setmetatable( m, M)
end

M.set = function( m,m11,m12,m13,m21,m22,m23,m31,m32,m33 )
  if m33 then -- set(a,b,c,...,h,i)
    m[1],m[2],m[3],m[4],m[5],m[6],m[7],m[8],m[9] = 
    m11,m12,m13,m21,m22,m23,m31,m32,m33
  elseif m11==0 and not m12 then -- set(0) : zero
    m[1],m[2],m[3],m[4],m[5],m[6],m[7],m[8],m[9] = 0,0,0,0,0,0,0,0,0
  elseif m11==1 and not m12 then -- set(1) : unity
    m[1],m[2],m[3],m[4],m[5],m[6],m[7],m[8],m[9] = 1,0,0,0,1,0,0,0,1
  elseif type(m11)=='table' then
    if type(m11[1])=='table' then -- set( {{},{},{}} )
      m[1],m[2],m[3] = m11[1][1],m11[1][2],m11[1][3]
      m[4],m[5],m[6] = m11[2][1],m11[2][2],m11[2][3]
      m[7],m[8],m[9] = m11[3][1],m11[3][2],m11[3][3]
    else -- set( {},{},{} )
      m[1],m[2],m[3] = m11[1],m11[2],m11[3]
      m[4],m[5],m[6] = m12[1],m12[2],m12[3]
      m[7],m[8],m[9] = m13[1],m13[2],m13[3]
    end
  else
    error ('not supported parameters in mat3.set')
  end

  return m
end

M.clone = function ( m, out )
  out = out or M.new ()
  return M.set( out, 
    m[1], m[2], m[3], 
    m[4], m[5], m[6], 
    m[7], m[8], m[9] 
  )
end

M.get_ij = function ( m, i, j )
  return m[(3*(i-1) + j)] 
end
M.set_ij = function ( m, i, j, v )
  m[(3*(i-1) + j)] = v
  return m
end

M.diag = function ( m )
  return vec3.new{m[1], m[5], m[9]}
end

M.row = function (m,i)
  return vec3.new{m[i], m[i+3], m[i+6]}
end

M.transpose = function ( m, out )
  out = out or M.new ()
  return M.set(out, m[1],m[4],m[7],m[2],m[5],m[8],m[3],m[6],m[9])
end

M.add = function ( a, b, out )
  out = out or M.new()
  return M.set( out,
    a[1]+b[1], a[2]+b[2], a[3]+b[3],
    a[4]+b[4], a[5]+b[5], a[6]+b[6],
    a[7]+b[7], a[8]+b[8], a[9]+b[9]
  )
end

M.sub = function ( a, b, out )
  out = out or M.new()
  return M.set( out,
    a[1]-b[1], a[2]-b[2], a[3]-b[3],
    a[4]-b[4], a[5]-b[5], a[6]-b[6],
    a[7]-b[7], a[8]-b[8], a[9]-b[9]
  )
end

M.eq = function ( a, b )
  return (a[1]==b[1]) and (a[2]==b[2]) and (a[3]==b[3])
  and (a[4]==b[4]) and (a[5]==b[5]) and (a[6]==b[6])
  and (a[7]==b[7]) and (a[8]==b[8]) and (a[9]==b[9])
end


-- unitary minus  (e.g in the expression f(-p))
M.unm = function ( p, out )
  out = out or M.new()
  return M.set( out, -p[1],-p[2],-p[3],-p[4],-p[5],-p[6],-p[7],-p[8],-p[9] )
end

M.mul_scalar = function ( p, s, out )
  out = out or M.new()
  return M.set( out, s*p[1],s*p[2],s*p[3],s*p[4],s*p[5],s*p[6],s*p[7],s*p[8],s*p[9] )
end

M.mul_component = function ( a, b, out )
  out = out or M.new()
  return M.set( out,     
    a[1]*b[1], a[2]*b[2], a[3]*b[3],
    a[4]*b[4], a[5]*b[5], a[6]*b[6],
    a[7]*b[7], a[8]*b[8], a[9]*b[9]
  )
end

M.div_scalar = function ( p, s, out )
  out = out or M.new()
  s=1/s
  return M.set( out, 
    s*p[1], s*p[2], s*p[3],
    s*p[4], s*p[5], s*p[6],
    s*p[7], s*p[8], s*p[9] 
  )
end

M.div_component = function ( a, b, out )
  out = out or M.new()
  return M.set( out,     
    a[1]*b[1], a[2]*b[2], a[3]*b[3],
    a[4]*b[4], a[5]*b[5], a[6]*b[6],
    a[7]*b[7], a[8]*b[8], a[9]*b[9]
  )
end

-- dot product is '^'
M.dot_vec = function ( m, v, out )
  out = out or M.new()
  local v1,v2,v3 = v[1],v[2],v[3]
  return vec3.set( out, 
    m[1]*v1+m[2]*v2+m[3]*v3, 
    m[4]*v1+m[5]*v2+m[6]*v3, 
    m[7]*v1+m[8]*v2+m[9]*v3
  )
end
M.dot_mat = function ( m, n, out )
  out = out or M.new()
  local m11, m12, m13 = m[1], m[2], m[3]
  local m21, m22, m23 = m[4], m[5], m[6]
  local m31, m32, m33 = m[7], m[8], m[9]

  local n11, n12, n13 = n[1], n[2], n[3]
  local n21, n22, n23 = n[4], n[5], n[6]
  local n31, n32, n33 = n[7], n[8], n[9]

  return M.set( out, 
    m11*n11+m12*n21+m13*n31, m11*n12+m12*n22+m13*n32, m11*n13+m12*n23+m13*n33,
    m21*n11+m22*n21+m23*n31, m21*n12+m22*n22+m23*n32, m21*n13+m22*n23+m23*n33,
    m31*n11+m32*n21+m33*n31, m31*n12+m32*n22+m33*n32, m31*n13+m32*n23+m33*n33
  )
end

M.inverse = function ( m, out )
  out = out or M.new()

  local m11, m12, m13 = m[1], m[2], m[3]
  local m21, m22, m23 = m[4], m[5], m[6]
  local m31, m32, m33 = m[7], m[8], m[9]

  local b12 =  m33*m22 - m23*m32
  local b22 = -m33*m21 + m23*m31
  local b32 =  m32*m21 - m22*m31

  -- Calculate the determinant
  local det = m11*b12 + m12*b22 + m13*b32

  if det == 0 then
    return M.set( out, 0)
  end
  det = 1 / det

  M.set( out,
    b12*det, (-m33*m12 + m13*m32)*det, (m23*m12 - m13*m22)*det,
    b22*det, (m33*m11 - m13*m31)*det, (-m23*m11 + m13*m21)*det,
    b32*det, (-m32*m11 + m12*m31)*det, (m22*m11 - m12*m21)*det
  )
  return out
end


M.new_identity = function() return M.new{1,0,0, 0, 1, 0, 0, 0, 1} end

M.__tostring = function ( p )
  local v1='('..p[1]..','..p[2]..','..p[3]..')'
  local v2='('..p[4]..','..p[5]..','..p[6]..')'
  local v3='('..p[7]..','..p[8]..','..p[9]..')'
  return "["..v1..v2..v3.."]"
end
M.__concat = function ( a, b )
  return tostring(a)..tostring(b)
end

M.__add = M.add
M.__sub = M.sub
M.__mul = function(a, b) 
  if type(b)=='number' then
    return M.mul_scalar(a, b) 
  elseif type(a)=='number' then
    return M.mul_scalar(b, a) 
  else
    return M.mul_component(a, b)
  end
end
M.__div = function(a, b) 
  if type(b)=='number' then
    return M.div_scalar(a, b) 
  else
    return M.div_component(a, b)
  end
end
M.__pow = function (a, b)
  if b[9] then
    return M.dot_mat(a, b)
  else
    return M.dot_vec(a, b)
  end
end
M.__eq = M.eq
M.__unm = M.unm

return M