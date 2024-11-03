--Thunder&Colt AX-8
local volume = 2550
local height = 18.8
local diameter = 17.7
local balloon_mass = 90
local sus_sea_level = 834 --at 120º air temp.
local max_to = 900
local payload = 738

local pi = 3.141519

local ro = 1.3 -- air density at sea level

local hang_length = 15


inertia = {
  ---[[
  {
    class='solid_sphere',
    params = {
      name = 'eballoon',
      radius=diameter/2,
      mass = balloon_mass,
      --mass = (4/3)*3.14159*(diameter/2)^3 * ro + balloon_mass - payload,
      placement = V3{0.0, 0.0, hang_length},
    }
  },
  --]]
  ---[[
  {
    class='solid_sphere',
    params={
      name = 'epayload',
      radius=1,
      mass = 200,
      placement = V3{0.0, 0.0, 0.0},
    }
  },
  --]]
}

forces = {
  { 
    class = 'fluid.floater.sphere',
    params = {
      name = 'fballoon',
      radius=diameter/2,
      --radius = 3.85,
      --radius = (3*sus_sea_level / (4*pi*ro))^(1/3), -- produce sus_sea_level
      ro = 1.1,
      placement = V3{0.0, 0.0, hang_length},
    }
  },
  ---[[
  {
    class = 'fluid.drag_shape.sphere',
    params = {
      name = 'dballoon',
      radius = diameter/2,
      placement = V3{0.0, 0.0, hang_length},
    }
  },
  --]]
  ---[[
  {
    class = 'fluid.drag_shape.sphere',
    params = {
      name = 'dpayload',
      radius = 1.5,
      placement = V3{0.0, 0.0, 0.0},
    }
  }
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

name = 'balloon_ax-8'
gravity = true
position = V3{0.0, 0.0, 0.0}
velocity = V3{0.0, 0.0, 0.0}

