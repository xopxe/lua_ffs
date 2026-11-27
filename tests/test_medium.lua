local T = require 'tests.lib'
local medium = require 'fsim.medium'
local vec3 = require 'fsim.vec3'

local function at ( z ) return vec3.new{0, 0, z} end

T.test('atmosphere at sea level', function()
  local ro, P, Temp = medium.atmosphere.density_pressure_temperature(at(0))
  T.near(ro, 1.225, 1e-12)
  T.near(P, 101325, 1e-9)
  T.near(Temp, 288.16, 1e-12)
  T.near((medium.atmosphere.density_pressure_temperature()), 1.225, 1e-12, 'no position means sea level')
end)

T.test('atmosphere at 1000 m matches the standard atmosphere', function()
  local ro, P, Temp = medium.atmosphere.density_pressure_temperature(at(1000))
  T.rnear(ro, 1.1117, 1e-3)
  T.rnear(P, 89875, 1e-3)
  T.near(Temp, 288.16 - 6.5, 1e-9)
end)

T.test('atmosphere thins with altitude', function()
  local last = math.huge
  for z = 0, 10000, 1000 do
    local ro = medium.atmosphere.density_pressure_temperature(at(z))
    T.ok(ro < last, 'density at ' .. z)
    last = ro
  end
end)

T.test('ocean: hydrostatic pressure', function()
  local ro, P = medium.ocean.density_pressure_temperature(at(-10))
  T.eq(ro, 1025)
  T.near(P, 101325 + 1025 * 9.8 * 10, 1e-9)
end)

T.test('default surface is flat at 0', function()
  local h, n = medium.surface.height(12, -3, 5)
  T.eq(h, 0)
  T.vnear(n, {0, 0, 1})
end)
