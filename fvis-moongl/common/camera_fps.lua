-- An abstract camera object that processes input and calculates the corresponding Euler angles,
-- vectors and matrices for use in OpenGL
local glmath = require("moonglmath")

local vec3, tovec3 = glmath.vec3, glmath.tovec3
local quat = glmath.quat
local clamp = glmath.clamp
local look_at = glmath.look_at
local sin, cos, rad = math.sin, math.cos, math.rad

-- Default camera values
local YAW = 0.0 -- -90.0
local PITCH = 0.0
local SPEED = 2.5
local SENSITIVITY =  0.005
local ZOOM =  45.0
local POSITION = vec3(0.0, 0.0, 0.0)
--local UP = vec3(0.0, 1.0, 0.0)
--local FRONT = vec3(0.0, 0.0, -1.0)
local UP = vec3(0.0, 0.0, 1.0)
local FRONT = vec3(0.0, 1.0, 0.0)
local RIGHT = vec3(1.0, 0.0, 0.0)

local M = {}

local function update_vectors(camera)
-- Recomputes the camera vectors after an update of the Euler angles (yaw and pitch)
  -- Calculate the new Front vector
  local yaw, pitch = camera.yaw, camera.pitch

  --camera.front = vec3(cos(yaw)*cos(pitch), sin(pitch), sin(yaw)*cos(pitch)):normalize()
  --yaw: y axis towards x (right) axis;  pitch: y axis towards z (up)axis
  camera.front = vec3(sin(yaw)*cos(pitch), cos(yaw)*cos(pitch), sin(pitch)):normalize()

  -- Normalize the vectors, because their length gets closer to 0 the more you look
  -- up or down which results in slower movement.
  camera.right = (camera.front % camera.world_up):normalize()
  camera.up = (camera.right % camera.front):normalize()
end

function M.view(camera)
-- Returns the view matrix calculated using Euler Angles and the LookAt Matrix
  return look_at(camera.position, camera.position+camera.front, camera.up)
end

function M.process_keyboard(camera, dir, dt)
-- Processes input received from any keyboard-like input system.
-- dir = 'forward' | 'backward' | 'left' | 'right'
-- dt = delta time, in seconds
  local velocity = camera.speed * dt
  if dir=='forward' then camera.position = camera.position + camera.front*velocity
  elseif dir=='backward' then camera.position = camera.position - camera.front*velocity
  elseif dir=='left' then camera.position = camera.position - camera.right*velocity
  elseif dir=='right' then camera.position = camera.position + camera.right*velocity
  elseif dir=='up' then camera.position = camera.position + camera.world_up*velocity
  elseif dir=='down' then camera.position = camera.position - camera.world_up*velocity
  end
end

function M.process_mouse(camera, xoffset, yoffset, constrain_pitch)
-- Processes input received from a mouse input system.
-- Beware that constrain_pitch defaults to nil (=false) unlike in the original.
  camera.yaw = camera.yaw + xoffset*camera.sensitivity
  camera.pitch = camera.pitch + yoffset*camera.sensitivity
  if constrain_pitch then
    -- make sure that when pitch is out of bounds, screen doesn't get flipped
    camera.pitch = clamp(camera.pitch, rad(-89.0), rad(89.0))
  end
  -- Update Front, Right and Up Vectors using the updated Euler angles
  update_vectors(camera)
end

function M.process_scroll(camera, yoffset)
-- Processes input received from a mouse scroll-wheel event.
-- Only requires input on the vertical wheel-axis
  camera.zoom = clamp(camera.zoom-yoffset, 1.0, 45.0)
end

M.init = function(camera) 
-- Camera constructor.
  setmetatable(camera, {__index = M})
-- position and up are optional vec3
-- yaw and pitch are optional numbers (Euler angles, in degrees)
  camera.position = tovec3(camera.position or POSITION)
  camera.front = tovec3(camera.front or FRONT):normalize()
  camera.up = tovec3(camera.up or UP):normalize()
  camera.world_up = tovec3(camera.world_up or UP):normalize() --vec3(camera.up)
  camera.right = tovec3(camera.right or RIGHT):normalize()
  camera.yaw = camera.yaw or YAW
  camera.pitch = camera.pitch or PITCH
  camera.speed = camera.speed or SPEED
  camera.sensitivity = camera.sensitivity or SENSITIVITY -- mouse sensitivity
  camera.zoom = camera.zoom or ZOOM
  camera.near = camera.near or 0.1
  camera.far = camera.far or 100.0

  update_vectors(camera)
  return camera
end

return M
