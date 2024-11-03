--Thunder&Colt AX-8
local volume = 2550
local height = 18.8
local diameter = 17.7
local balloon_mass = 90
inertia = {
  ---[[
  {
    class='solid_sphere',
    params = {
      name = 'b1',
      radius=1.0,
      mass = 1.0,
      --mass = (4/3)*3.14159*(diameter/2)^3 * ro + balloon_mass - payload,
      placement = V3{0.0, 0.0, 1.5},
    }
  },
  --]]
  ---[[
  {
    class='solid_sphere',
    params={
      name = 'b2',
      radius=1.0,
      mass = 1.0,
      placement = V3{0.0, 0.0, -1.5},
    }
  },
  --]]
    ---[[
  {
    class='solid_sphere',
    params={
      name = 'c',
      radius=0.1,
      mass = 1.0,
      placement = V3{0.0, 0.0, 0.0},
    }
  },
  --]]
}

--[[
model = {
  class = 'sphere',
  params = {
    scale = { diameter/2, diameter/2, diameter/2 },
  }
}

shader = {
  class ='uniform',
  parameters= {
    ambient = { 0.0, 0.1, 0.06},
    diffuse = { 0.0, 0.50980392, 0.50980392 },
    specular = { 0.50196078, 0.50196078, 0.50196078},
    shininess = 32.0,
  }
}
--]]

name = 'pair'
gravity = true
position = V3{0.0, 0.0, 0.0}
velocity = V3{0.0, 0.0, 0.0}

