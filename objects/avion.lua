inertia = {
  {
    class = 'solid_cylinder',
    params={
      name = 'body',
      radius = 0.5,
      length = 4,
      mass = 100,
      placement = V3{0.0, 0.0, 0.0},
    }
  },
}

forces = {
  {
    class = 'fluid.drag_shape.projectile',
    params = {
      name = 'bodydrag',
      width = 0.5,
      length = 4,
      forward = V3{1.0,0.0,0.0},
      placement = V3{3.5, 0.0, 0.0},
    }
  },
  {
    class = 'fluid.foil.wing',
    params = {
      name = 'wing',
      params = {},
      
      aero_data = 'polar_generator', aero_data_params = 'SYMMETRICAL',
      --aero_data = 'polar_db', aero_data_params = 'AIRFOIL_PREP',
      
      center_of_pressure = V3{0.3, 0.0, 0.0},
      span = 20.0,
      area = 32,
    }
  },
  ---[[
  {
    class = 'fluid.foil.wing',
    params = {
      name = 'aileron',
      params = {},
      
      aero_data = 'polar_generator', aero_data_params = 'SYMMETRICAL',
      --aero_data = 'polar_db', aero_data_params = 'AIRFOIL_PREP',
      
      center_of_pressure = V3{-6, 0.0, 0.0},
      span = 3.0,
      area = 3,
    }
  },
  --]]
  --[[
  {
    class = 'forces.world_space.get_constant',
    params = {
      name = 'engine',
      point = V3{0.0,0.0,0},
      force = V3{4000.0,0.0,0},
    },
  }
  --]]

}

name = 'avion'
gravity = true
position = V3{0.0, 0.0, 0.0}
velocity = V3{0.0, 0.0, 0.0}

