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

T.test('pendulum: anchor stays fixed, ball hangs from the spring', function()
  local w = load('world/pendulum.lua')
  T.ok(w.forces.spring1, 'spring registered by name')
  run(w, 10)
  T.vnear(w.bodies.b1.position, {0, 0, 2})
  T.ok(w.bodies.b2.position[3] < 2, 'ball below the anchor')
end)

-- data files ----------------------------------------------------------------

-- run a world's init/write/close as start.lua does, with files and
-- gnuplot stubbed out; returns the written rows and the commands run
local function capture_data ( filename )
  local w = load(filename)
  local rows, opened, ran = {}, {}, {}
  local real_open, real_execute = io.open, os.execute
  io.open = function ( path )
    opened[#opened+1] = path
    return { write = function ( _, s ) rows[#rows+1] = s end, close = function () end }
  end
  os.execute = function ( cmd ) ran[#ran+1] = cmd end
  local ok, err = pcall(function()
    if w.init then T.quiet(w.init) end
    w.now = 0
    for i = 1, 1000 do
      w:step(0.005)
      if i % 200 == 0 then w.write() end  -- once per simulated second
    end
    w.close()
  end)
  io.open, os.execute = real_open, real_execute
  if not ok then error(err, 0) end
  return rows, opened, ran
end

for _, case in ipairs{
  {'world/drop.lua', 'drop.data'},
  {'world/balloon.lua', 'balloon.data'},
  {'world/flight.lua', 'wing.data'},
  {'world/pendulum.lua', 'pendulum.data'},
} do
  local world_file, data_file = case[1], case[2]
  T.test(world_file .. ': writes ' .. data_file, function()
    local rows, opened, ran = capture_data(world_file)
    T.eq(opened[1], data_file)
    T.eq(#rows, 5)
    for k, row in ipairs(rows) do
      local cols = {}
      for x in row:gmatch('%S+') do cols[#cols+1] = tonumber(x) end
      T.eq(#cols, 6, 'numeric columns in ' .. row)
      T.near(cols[1], k, 1e-6, 'first column is the time')
    end
    T.ok(ran[1] and ran[1]:find('gnuplot'), 'close() plots the data')
  end)
end

T.test('worlds without a data file write nothing', function()
  for _, f in ipairs{'world/sea.lua', 'world/sea_flat.lua'} do
    local rows, opened = capture_data(f)
    T.eq(#rows, 0, f)
    T.eq(#opened, 0, f)
  end
end)

-- known bugs ---------------------------------------------------------------

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
