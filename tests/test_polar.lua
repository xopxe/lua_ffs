local T = require 'tests.lib'
local polar_db = require 'fsim.polar_db'
local polar_generator = require 'fsim.polar_generator'

local rad = math.rad

-- polar_db ------------------------------------------------------------------

local db = polar_db.get_aerodata('AIRFOIL_PREP')

T.test('polar_db: exact table points', function()
  T.vnear({db.sample(rad(90))}, {0, 1.29, -0.3559}, 1e-12)
  T.vnear({db.sample(rad(-180))}, {0, 0.177, 0}, 1e-12)
end)

T.test('polar_db: linear interpolation between points', function()
  -- halfway between 30 and 40 degrees
  T.vnear({db.sample(rad(35))}, {(0.7010 + 0.7219)/2, (0.4758 + 0.6686)/2, (-0.1710 - 0.2202)/2}, 1e-12)
end)

T.test('polar_db: angles wrap around', function()
  T.vnear({db.sample(rad(35) + 2 * math.pi)}, {db.sample(rad(35))}, 1e-12)
  T.vnear({db.sample(rad(35) - 4 * math.pi)}, {db.sample(rad(35))}, 1e-12)
end)

T.test('polar_db: continuous over the whole circle', function()
  local last = {db.sample(-math.pi)}
  for d = -179.5, 180, 0.5 do
    local cur = {db.sample(rad(d))}
    T.finite(cur, 'at ' .. d)
    T.ok(math.abs(cur[1] - last[1]) < 0.15, 'Cl jump at ' .. d)
    last = cur
  end
end)

-- polar_generator -----------------------------------------------------------

local sym = polar_generator.get_aerodata('SYMMETRICAL')

T.test('generator: symmetrical foil has no lift at 0', function()
  local Cl, Cd = sym.sample(0)
  T.near(Cl, 0, 1e-12)
  T.ok(Cd > 0 and Cd < 0.05, 'small drag')
end)

T.test('generator: symmetrical foil is odd in Cl, even in Cd', function()
  for d = 1, 179, 7 do
    local Cl1, Cd1 = sym.sample(rad(d))
    local Cl2, Cd2 = sym.sample(rad(-d))
    T.near(Cl2, -Cl1, 1e-12, 'Cl at ' .. d)
    T.near(Cd2, Cd1, 1e-12, 'Cd at ' .. d)
  end
end)

T.test('generator: lift slope near 0 is cl2 per radian', function()
  T.rnear(sym.sample(rad(5)), 5.16 * rad(5), 0.01)
end)

T.test('generator: stalls past aoa2', function()
  T.ok(sym.sample(rad(25)) < sym.sample(rad(14)))
end)

T.test('generator: cambered A320 foil lifts at 0', function()
  -- about cl1 = 0.2; the sigmoid blend with the flat-plate curve shaves a bit off
  T.near(polar_generator.get_aerodata('A320').sample(0), 0.2, 0.015)
end)

T.test('generator: params are a copy', function()
  local a = polar_generator.get_aerodata('SYMMETRICAL')
  a.params.cl2 = 0
  T.near(polar_generator.params.SYMMETRICAL.cl2, 5.16, 0)
end)

T.xfail('generator works without math.pow (Lua 5.4+ builds without compat, Lua 5.5)', 'polar_generator.lua uses math.pow', function()
  local saved = math.pow
  math.pow = nil
  T.reset_modules()
  local ok, err = pcall(function()
    require('fsim.polar_generator').get_aerodata('SYMMETRICAL').sample(0.1)
  end)
  math.pow = saved
  T.reset_modules()
  if not ok then error(err, 0) end
end)
