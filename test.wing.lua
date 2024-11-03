local rbody = require 'fsim.rigid_body'
local inertia = require 'fsim.inertia'
local vec3 = require 'fsim.vec3'
local fluid = require 'fsim.fluid'
local medium = require 'fsim.medium'
local quat = require 'fsim.quaternion'

local deg, rad = math.deg, math.rad

--local w = loader.load_world('world/drop.lua')
--local w = loader.load_world('world/balloon.lua')
--local world = loader.load_world('world/flight.lua')

medium.atmosphere.current:set(-40, 0, 0)

local e = inertia.element.from_shape('solid_sphere', {
    radius=0.5, 
    mass=1, 
    position=vec3.new{0, 0, 0},
  }
)

local a = rbody.new{
  gravity = false,
  inertia = e,
  position = vec3.new{0,0,100},
}
a.velocity:set(0,0,0)

local w = assert(fluid.foil.wing{
    body = a,
    
    aero_data = 'polar_generator', aero_data_params = 'SYMMETRICAL',
    --aero_data = 'polar_db', aero_data_params = 'AIRFOIL_PREP',
    
    --center_of_pressure = vec3.new{0.5, 0.0, 0.0},
    span = 10.0,
    area = 10.0,
  }
)

local now = 0

local forward = vec3.new{1.0,0.0,0.0}


local axis = vec3.new{0.0,-1.0,0.0}
for d = 0, 360, 10 do
  local r = rad(d)
  a.orientation = quat.from_axis_angle(axis, r)
  w.apply(0)
  print (d, 
    'aoa:'..deg(w.aoa), 
    'relvel:'..w.relvel,
    --'fwd:'..a.orientation:rotate_vec(forward),
    'lift:'..w.lift,
    'drag:'..w.drag
    --'normal_w:'..w.normalw
  )
end
