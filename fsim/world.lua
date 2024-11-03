local M = {}

M.__index = M

M.step = function ( w, dt ) -- FIXME t and dt parameters from env?
  local now = w.now

  -- apply forces
  for i = 1, #w.forces do
    w.forces[i].apply( now )
  end
  for i = 1, #w.bodies do
    local body = w.bodies[i]
    for j=1, #body.forces do
      body.forces[j].apply( now )
    end
  end

  -- advance body phisiscs
  for i = 1, #w.bodies do
    local body = w.bodies[i]
    body:update( dt )
  end

  w.now = now+dt
end

M.now = 0
M.forces = {}
M.bodies = {}

--[[
M.new = function ( w )
  assert(w.bodies)
  assert(w.medium)
  
  w.now = 0

  w.forces = w.forces or {}
  w.bodies = w.bodies or {}
  
  w.init()
  
  setmetatable( w, M )
  return w
end
--]]


return M