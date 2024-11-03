local quat = require 'fsim.quaternion'
local vec3 = require 'fsim.vec3'

local rad = math.rad

local fx = vec3.new{1,0,0}
local fy = vec3.new{0,1,0}
local fz = vec3.new{0,0,1}

local rot = quat.from_axis_angle( fy, rad(10))

print('quat:', rot) 

print('aa', rot:rotate_vec(fx))
