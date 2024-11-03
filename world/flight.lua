bodies = {
  IMPORT_BODY ('objects/avion.lua', {
      name = 'avion',
      position = V3{0,0,200},
      velocity = V3{10,0,0},
      --gravity = false,
    }
  ),
}

--TODO
medium = {
  surface = {
    generator = 'flat',
    params = {h0=0},
  },
}


-------------------------------------------------------------------
local L = L
local file
init = function()
  L.print 'initializing wing world'
  file = L.io.open('wing.data', 'w')
end

local UP = V3{0,0,1}
write = function()
  local a=bodies.avion

  --local eu = a.orientation:to_euler()
  --print(now, L.math.deg(eu[1]),L.math.deg(eu[2]),L.math.deg(eu[3]))

  file:write(now..' '..
    a.position[1]..' '..
    a.position[3]..' '..
    a.velocity[1]..' '..
    a.velocity[3]..
    a.forces.wing.aoa..' '..
    '\n'
  )
end

close = function()
  if file then 
    file:close() 
    L.os.execute('gnuplot -p wing.plot')
  end
end
