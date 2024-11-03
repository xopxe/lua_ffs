--https://www.jakobmaier.at/posts/flight-simulation/
local M = {}

local g_accel = -9.8 --m/sec^2
local g_index = 3 --z

local vec3 = require 'fsim.vec3'
local mat3 = require 'fsim.mat3'
local quat = require 'fsim.quaternion'
local inertia = require 'fsim.inertia'

M.__index = M

local body_coord = vec3.new{0.0,0.0,0.0} --temporal

-- transform direction from body space to world space
M.transform_direction_dw = function ( b, direction, out )
  out = out or vec3.new()
  return b.orientation:rotate_vec( direction, out )
end

-- transform direction from world space to body space
M.transform_direction_wd = function ( b, direction, out )
  out = out or vec3.new()
  return b.orientation:inverse():rotate_vec( direction, out )
end

-- get velocity of design point in world space
local velocityrotd, velocityrotw = vec3.new{0.0,0.0,0.0}, vec3.new{0.0,0.0,0.0} --temp
M.get_pointd_velocityw = function ( b, point, out )
  out = out or vec3.new()
  point:add(b.inertia.offset, body_coord)
  b.velocity:clone(out)
  b.angular_velocity:cross(body_coord, velocityrotd)
  b:transform_direction_dw( velocityrotd, velocityrotw )
  out:add( velocityrotw, out)
  return out
end

--[[
-- get velocity due to rotation of design point in world space
M.get_point_d_velocity_w = function ( b, point, out )
  out = out or vec3.new()
  b.velocity:clone(out)
  out:add( b:transform_direction_bw( b.angular_velocity:cross(point+b.inertia.offset) ), out)
  return out
end

-- get velocity due to rotation of relative point in body space
M.get_point_d_velocity_from_angular_b = function ( b, point, out )
  out = out or vec3.new()
  b.angular_velocity:cross(point+b.inertia.offset, out)
  return out
end

-- get velocity of design point in body space
M.get_point_d_velocity_b = function ( b, point, out )
  out = out or vec3.new()
  out = b:transform_direction_wd( b.velocity, out )
  out = out:add( b:get_point_d_velocity_from_angular(point+b.inertia.offset), out )
  return out
end

-- get velocity in design space
M.get_point_velocity_d = function ( b, point, out )  -- FIXME
  out = out or vec3.new()
  out = b:transform_direction_wd( b.velocity, out )
  return out
end
--]]

-- get world coordinates
M.get_pointd_positionw = function ( b, point, out )
  out = out or vec3.new()
  point:add(b.inertia.offset, body_coord)
  b:transform_direction_dw( body_coord, out ) 
  out:add(b.position, out)
  return out
end

-- force and point vectors are in design space
M.add_forced_at_pointd = function ( b, force, point )
  b.force:add( b:transform_direction_dw( force ), b.force )
  if point then 
    point:add(b.inertia.offset, body_coord)
    b.torque:add( vec3.cross( body_coord, force), b.torque )
  end
end

-- force vector in world space, point vector in design space
local forced = vec3.new{0.0,0.0,0.0} --temp
local torqued = vec3.new{0.0,0.0,0.0} --temp
M.add_forcew_at_pointd = function ( b, force, point )
  b.force:add( force, b.force )
  if point then
    point:add(b.inertia.offset, body_coord)
    b:transform_direction_wd(force, forced)
    vec3.cross( body_coord, forced, torqued)
    b.torque:add( torqued, b.torque )
  end
end

M.apply_forces = function ( b, now )
  for i=1, #b.forces do
    b.forces[i].apply( now )
  end
end

M.new = function ( b )
  assert(b.inertia)
  --b.offset = assert(b.inertia.offset)
  --b.mass = assert(b.inertia.mass)
  
  b.force = b.force or vec3.new{0.0,0.0,0.0} -- world space
  b.torque = b.torque or vec3.new{0.0,0.0,0.0} -- body space

  b.position = b.position or vec3.new{0.0,0.0,0.0} -- world space (m)
  b.orientation = b.orientation or quat.new() -- world space
  b.velocity = b.velocity or vec3.new{0.0,0.0,0.0} -- world space (m/sec)
  b.accel = b.accel or vec3.new{0.0,0.0,0.0} -- body space (m/sec^2)
  b.angular_velocity = b.angular_velocity or vec3.new{0.0,0.0,0.0} -- body space, (rad/second)

  setmetatable( b, M )
  return b
end

local rtemp = vec3.new{0.0,0.0,0.0} --temporal
M.update = function ( b, dt )
  if b.fixed then return end
  
  -- integrate position
  b.force:clone( b.accel )
  b.accel:div_scalar( b.inertia.mass, b.accel )
  if b.gravity then b.accel[g_index] = b.accel[g_index] + g_accel end

  b.velocity:add_scaled( b.accel, dt, b.velocity )
  b.position:add_scaled( b.velocity, dt, b.position )

  -- integrate orientation
  -- angvel +=  inviner* (torque - cross(angvel, iner*angvel)) * 0.5dt
  local angular_incr = b.inertia.tensor.inverse:dot_vec(
    b.torque - vec3.cross( b.angular_velocity, b.inertia.tensor:dot_vec(b.angular_velocity) )) --FIXME allocs
  b.angular_velocity:add_scaled( angular_incr, 0.5*dt, b.angular_velocity )

  -- orient += (orient * quat(angvel, 0))*0.5dt
  local q_angvel = quat.new{b.angular_velocity[1], b.angular_velocity[2], b.angular_velocity[3], 0}
  b.orientation:mul(q_angvel, rtemp)
  b.orientation:add_scaled( rtemp, 0.5*dt, b.orientation)

  b.orientation:normalize( b.orientation );

  b.force:set(0,0,0)
  b.torque:set(0,0,0)
end


return M