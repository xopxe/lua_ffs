bodies = {
  IMPORT_BODY ('objects/tenis_ball.lua', {
      name = 'b1',
      position = V3{0,0,2},
      fixed = true,
    }
  ),
  IMPORT_BODY ('objects/tenis_ball.lua', {
      name = 'b2',
      position = V3{0.5,0,2},
      gravity = true,
    }
  ),
}

---[[
forces = {
  {
    class = 'forces.world_space.get_spring',
    params = {
      name = 'spring1',
      body1 = BODY_FROM_NAME'b1',
      body2 = BODY_FROM_NAME'b2',
      point1 = V3{0.0,0.0,0},
      point2 = V3{0.0,0.0,0.5},
      --fixed1 = true,
      K = 5,
      l0 = 0.5,
      drag = 0.01,
    },
  }
}

--]]


medium = {
  surface = {
    generator = 'flat',
    params = {h0=0},
  },
}

camera = {
  class = 'camera_fps',
  pos = V3{0, -4, 0},
}

inertia_bbox_color = {1.0, 0.0, 0.0}
forces_bbox_color = {0.0, 1.0, 0.0}

-------------------------------------------------------------------
local L = L
local file
init = function()
  L.print 'initializing pendulum world'
  file = L.io.open('pendulum.data', 'w')
end

write = function()
  local b1=bodies.b1
  local b2=bodies.b2
  file:write(now..' '..
    b1.position[1]..' '..
    b1.position[3]..' '..
    b2.position[1]..' '..
    b2.position[3]..' '..
    (b1.position-b2.position):norm()..
    '\n')
end

close = function()
  if file then 
    file:close() 
    L.os.execute('gnuplot --persist pendulum.plot')
  end    
end
