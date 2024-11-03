
local length = 4
local width = 2
local height = 1
local weight = 500

inertia = {
  ---[[
  {
    class='cuboid',
    params = {
      name = 'hull',
      size = V3{length, width, height},
      mass = weight,
      --mass = (4/3)*3.14159*(diameter/2)^3 * ro + balloon_mass - payload,
      placement = V3{0.0, 0.0, 0.0},
    }
  },
  --]]
}

forces = {
  { 
    class = 'forces.floater_points',
    params = {
      name = 'flopoints',
      points = { 
        V3{ length/2,  width/2, -height/2},
        V3{ length/2, -width/2, -height/2},
        V3{0,  width/2, -height/2},
        V3{0, -width/2, -height/2},
        V3{-length/2,  width/2, -height/2},
        V3{-length/2, -width/2, -height/2},      },
      FL = height/2,
      DL = height,
      drag = 300.0,
    }
  }, 
  --[[
  {
    class = 'fluid.drag_shape.sphere',
    params = {
      name = 'd1',
      radius = width,
      placement = V3{0.75*length, 0.0, -0.5},
    }
  },
  {
    class = 'fluid.drag_shape.sphere',
    params = {
      name = 'd2',
      radius = width,
      placement = V3{-0.75*length, 0.0, -0.5},
    }
  },
  --]]
}

model = {
  class = 'cube',
  params = {
    scale = { length, width, height },
  },
}

---[[
shader = {
  class ='texture',
  --class ='uniform',
  parameters= {
    ambient = { 0.8, 0.5, 0.5 },
    diffuse = { 0.8, 0.5, 0.5 },
    specular = { 0.2, 0.1, 0.1},
    shininess = 32,
  }
}
--]]
--[[
shader = {
  class ='uniform',
  parameters= {
    ambient = { 0.0, 0.0, 0.0 },
    diffuse = { 0.02, 0.02, 0.02 },
    specular = { 0.5, 0.5, 0.5},
    shininess = 32,
  }
}
--]]

name = 'boat2'
gravity = true
position = V3{0.0, 0.0, 0.0}
velocity = V3{0.0, 0.0, 0.0}