bodies = {
  IMPORT_BODY ('objects/tenis_ball.lua', {
      name = 'b1',
      position = V3{-0.2,0,1},
      gravity = true,
    }
  ),
  IMPORT_BODY ('objects/tenis_ball.lua', {
      name = 'b2',
      position = V3{0.2,0,-1},
      gravity = true,
    }
  ),
}

--[[
forces = {
  {
    class = 'forces.get_spring_w',
    params = {
      name = 'spring1',
      body1 = BODY_FROM_NAME'b1',
      body2 = BODY_FROM_NAME'b2',
      point1 = V3{0.0,0.0,0},
      point2 = V3{0.0,0.0,0},
      --fixed1 = true,
      K = 0.5,
      l0 = 1,
      drag = 0.1,
    },
  }
}
--]]

medium = {
  ---[[
  surface = {
    generator = 'flat',
    params = {h0=0},
  },
  --]]
  --[[
  surface = {
    generator = 'sine_wave',
    params = {
      h0=0.0,    
      {amplitude=0.4, length=10.0, shallowness=1.0, dir = 0.4},
    },
  },
  --]]
}

camera = {
  class = 'camera_fps',
  pos = V3{0, -1, 0.5},
  pitch = L.math.rad(-20),
}

-------------------------------------------------------------------
local L = L
local file
init = function()
  L.print 'initializing drop world'
  file = L.io.open('drop.data', 'w')
end

write = function()
  if file then
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
end

close = function()
  if file then 
    file:close() 
    L.os.execute('gnuplot --persist drop.plot')
  end
end
