
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
    class = 'fluid.floater.sphere',
    params = {
      name = 'f_fwd',
      radius = 0.5,
      ro = 1.225, -- air density at sea level
      placement = V3{length/2, 0.0, 0.0},
    }
  }, 
  { 
    class = 'fluid.floater.sphere',
    params = {
      name = 'f_aft',
      radius = 0.5,
      ro = 1.225, -- air density at sea level
      placement = V3{-length/2, 0.0, 0.0},
    }
  }, 
  { 
    class = 'fluid.floater.sphere',
    params = {
      name = 'f_lft',
      radius = 0.5,
      ro = 1.225, -- air density at sea level
      placement = V3{0.0, width/2, 0.0},
    }
  }, 
  { 
    class = 'fluid.floater.sphere',
    params = {
      name = 'f_rgt',
      radius = 0.5,
      ro = 1.225, -- air density at sea level
      placement = V3{0.0, -width/2, 0.0},
    }
  },   {
    class = 'fluid.drag_shape.sphere',
    params = {
      name = 'd1',
      radius = 1,
      placement = V3{0.0, 0.0, 0.0},
    }
  }
}

model = {
  class = 'cube',
  params = {
    scale = {length, width, height },
    --texture = '',
  }
}

name = 'boat1'
gravity = true
position = V3{0.0, 0.0, 0.0}
velocity = V3{0.0, 0.0, 0.0}