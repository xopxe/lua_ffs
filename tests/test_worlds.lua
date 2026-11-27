-- Load the scenario files in world/ and run them headless.
-- No world.init() is called, so nothing is written to disk.
local T = require 'tests.lib'

local function load ( filename, keep_modules )
  if not keep_modules then T.reset_modules() end
  return T.quiet(require('loader').load_world, filename)
end

local function run ( w, seconds, dt )
  dt = dt or 0.005
  w.now = 0
  for _ = 1, math.floor(seconds / dt + 0.5) do
    w:step(dt)
  end
  for _, b in ipairs(w.bodies) do
    T.finite(b.position, b.name .. ' position')
    T.finite(b.velocity, b.name .. ' velocity')
  end
end

T.test('sea: boat and buoy float', function()
  local w = load('world/sea.lua')
  T.eq(#w.bodies, 2)
  T.ok(w.bodies.boatb and w.bodies.buoy, 'bodies registered by name')
  run(w, 20)
  for _, b in ipairs(w.bodies) do
    -- the powsine sea surface sits between -2*sum(A) and 0
    T.ok(b.position[3] > -1.5 and b.position[3] < 0.5, b.name .. ' z = ' .. b.position[3])
  end
end)

T.test('sea_flat: body without gravity stays put', function()
  local w = load('world/sea_flat.lua')
  run(w, 5)
  T.vnear(w.bodies.pair.position, {0, 0, 5})
end)

T.test('drop: tennis balls end up floating', function()
  local w = load('world/drop.lua')
  run(w, 30)
  for _, b in ipairs(w.bodies) do
    T.ok(b.position[3] > 0 and b.position[3] < 0.2, b.name .. ' z = ' .. b.position[3])
  end
end)

T.test('balloon: rises and drifts with the wind', function()
  local w = load('world/balloon.lua')
  run(w, 10)
  local b = w.bodies.b
  T.ok(b.position[3] > 10, 'rises: z = ' .. b.position[3])
  T.ok(b.position[1] > 0, 'drifts downwind: x = ' .. b.position[1])
end)

T.test('flight: glides', function()
  local w = load('world/flight.lua')
  run(w, 10)
  local a = w.bodies.avion
  T.ok(a.position[3] < 200 and a.position[3] > 100, 'z = ' .. a.position[3])
  T.ok(a.position[1] > 100, 'x = ' .. a.position[1])
end)

-- known bugs ---------------------------------------------------------------

T.xfail('pendulum loads', 'force class forces.world_space.get_spring does not exist', function()
  load('world/pendulum.lua')
end)

T.xfail('flight survives hitting the water', 'wing in water density, explicit integration overshoots', function()
  run(load('world/flight.lua'), 25)
end)

T.xfail('a world does not inherit state from the previous one', 'loader copies into the fsim.world and fsim.medium singletons', function()
  load('world/balloon.lua')                 -- sets a 0.5 m/s wind
  local w = load('world/drop.lua', true)    -- no wind
  T.vnear(w.medium.atmosphere.current, {0, 0, 0})
end)

T.xfail('loader.load_body', 'calls import_body{filename} with no params', function()
  T.reset_modules()
  T.quiet(require('loader').load_body, 'objects/tenis_ball.lua')
end)
