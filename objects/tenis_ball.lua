local radius, mass = 0.2, 10 --0.066/2, 0.058  -- tennis ball

inertia = {
  {
    class = 'solid_sphere',
    params = {
      name = 'e1',
      radius=radius, mass=mass,
      placement = V3{0.0, 0.0, 0.0},
    }
  },
}

forces = {
  { 
    class = 'fluid.floater.sphere',
    params = {
      name = 'f1',
      radius = radius,
      ro = mass / ((4/3)*3.14159*radius^3),
      placement = V3{0.0, 0.0, 0.0},
    }
  }, 
---[[
  {
    class = 'fluid.drag_shape.sphere',
    params = {
      name = 'd1',
      radius = radius,
      placement = V3{0.0, 0.0, 0.0},
    }
  }
--]]
}

model = {
  class = 'sphere',
  params = {
    scale = {radius},
    --texture = '',
  }
}

--[[
  shader = {
    class ='texture',
  }
--]]
---[[
shader = {
  class ='uniform',
  parameters= {
    ambient = { 223/255, 1.0, 79/255 },
    diffuse = { 223/255, 1.0, 79/255 },
    specular = { 0.0, 0.0, 0.0},
    shininess = 32.0,
  }
}
--]]

name = 'tennis_ball'
gravity = true
position = V3{0.0, 0.0, 0.0}
velocity = V3{0.0, 0.0, 0.0}


