bodies = {
  --[[
  IMPORT_BODY ('objects/boat2.lua', {
      name = 'boata',
      position = V3{0.0,0.0,1.5},
      gravity = true,
    }
  ),
  --]]
  ---[[
  IMPORT_BODY ('objects/boat2.lua', {
      name = 'boatb',
      position = V3{2.0,4.0,0.5},
      gravity = true,
    }
  ),
  --]]

  ---[[
  IMPORT_BODY ('objects/tenis_ball.lua', {
      name = 'buoy',
      position = V3{2.0,2.0,1.0},
      gravity = true,
    }
  ),
  --]]
  --[[
  IMPORT_BODY ('objects/pair.lua', {
      name = 'pair',
      position = V3{0.0,0.0,0.0},
      gravity = false,
    }
  ),
  --]]
  --[[
  IMPORT_BODY ('objects/balloon_ax-8.lua', {
      name = 'balloon',
      position = V3{0.0,0.0,10.0},
      gravity = false,
    }
  ),
  --]]
}

medium = {
  surface = {
    generator = 'powsine_wave',
    params = {
      h0=0.0,
      amplitude=0.15, 
      length=10.0, 
      dir = 0.2,
      ddir = 0.5,
      K=2.0, --1<K<3.0
      --{amplitude=0.2, length=10.0, dir = 0.4, K=3.0}, --1<K<2.5
      -- {amplitude=0.05, length=2.0, shallowness=1.6, dir = 0.1},
    },
  },
}

---[[
surface_shader = {
  parameters= {
    --waves = medium.surface.params,
    ambient = { 0.0, 0.01, 0.01},
    diffuse = { 0.1, 0.5, 0.6 },
    specular = { 0.8, 0.8, 0.8},
    shininess = 128, --64.0,
    alpha = 0.5,
    
    --area_mode = 'frustum',
    area = {{-100, -100}, {100, 100}},
    side_count = 256,
  },
  
  drawable = 'fvis-moongl.drawable.ocean',
  class ='ocean_'..medium.surface.generator,
}
--]]

--[[
surface_shader = {
  parameters= {
    ambient = { 0.0, 0.2, 0.2},
    diffuse = { 0.0, 0.2, 0.2 },
    specular = { 0.3, 0.3, 0.3},
    shininess = 64.0,
    alpha = 0.8,

    --area_mode = 'frustum',
    area = {{-10, -10}, {10, 10}},
    side_count = 32,
  },
  drawable = 'fvis-moongl.drawable.ocean_cpu',
  class ='uniform',
}
--]]

camera = {
  class = 'camera_fps',
  --class = 'camera_quat',
  --position = V3{0, -10, 2},
  position = V3{0, -50, 2},
  pitch = L.math.rad(-5),
  near = 0.1,
  far = 1000.0,
}

light = {
  --position = {0.0, 0.0, 100.0},
  direction = {0.0, 10, 2.0},
  diffuse = {1.0, 1.0, 1.0},
  ambient = {0.3, 0.3, 0.3},
  specular = {1.0, 1.0, 1.0},
}

randomseed = 0

inertia_bbox_color = {1.0, 0.0, 0.0}
forces_bbox_color = {0.0, 1.0, 0.0}

-------------------------------------------------------------------
local L = L
local file
init = function()
  L.print 'initializing sea world'
  --file = L.io.open('drop.data', 'w')
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
