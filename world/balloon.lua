bodies = {
  IMPORT_BODY ('objects/balloon_ax-8.lua', {
      name = 'b',
      position = V3{0,0,10},
      gravity = true,
    }
  ),
}

forces = {
}


medium = {
  surface = {
    generator = 'flat',
    params = {h0=0},
  },
  atmosphere = {
    current = V3{0.5, 0.0, 0.0},
  }
}

-------------------------------------------------------------------
local L = L
local file
init = function()
  L.print 'initializing balloon world'
  file = L.io.open('balloon.data', 'w')
end

local UP = V3{0,0,1}
write = function()

  local v3a = L.ERROR_ON_V3_AUTOALLOC
  L.ERROR_ON_V3_AUTOALLOC = false

  local b=bodies.b
  file:write(now..' '..
    b.position[1]..' '..
    b.position[3]..' '..

    b.velocity[1]..' '..
    b.velocity[3]..' '..
    L.math.deg(b.orientation:rotate_vec(UP):angle(UP))..' '..
    '\n'
  )

  L.ERROR_ON_V3_AUTOALLOC = v3a
end

close = function()
  if file then 
    file:close() 
    L.os.execute('gnuplot --persist balloon.plot')
  end
end
