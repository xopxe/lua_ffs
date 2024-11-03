local M = {}

local vec3 = require 'fsim.vec3'
local PI = math.pi

local g_accel = -9.8 --m/sec^2
M.g_accel = g_accel


M.atmosphere = {
  -- www.dtic.mil/dtic/tr/fulltext/u2/a278141.pdf
  -- https://physics.stackexchange.com/questions/299907/
  -- h < 10km
  T0    = 288.16, -- K  
  alpha = 0.0065, -- K/m
  P0    = 101325, -- Pa  
  ro0   = 1.225,  -- Kg/m^3
  n     = 5.2561,
  current = vec3.new{0.0,0.0,0.0},
}
M.atmosphere.density_pressure_temperature = function ( pos )
  local h
  if pos then h=pos[3] else h=0 end
  local T0 = M.atmosphere.T0
  local alpha = M.atmosphere.alpha
  local P0 = M.atmosphere.P0
  local ro0 = M.atmosphere.ro0
  local n = M.atmosphere.n

  local T = T0 - alpha*h
  local P = P0 * (T/T0)^n    
  local ro = ro0 * (T/T0)^(n-1)
  return ro, P, T
end


M.ocean = {
  -- https://byjus.com/water-pressure-formula/
  ro0   = 1025,   -- Kg/m^3
  T0    = 288.16, -- K  
  P0atm = 101325, --Pa
  current = vec3.new{0.0,0.0,0.0}, 
}
M.ocean.density_pressure_temperature = function ( pos ) 
  local h
  if pos then h=pos[3] else h=0 end
  local ro0 = M.ocean.ro0
  local T0 = M.ocean.T0
  local P0atm = M.ocean.P0atm
  local ro, T = ro0, T0  -- lets suppose constant (ro is actually function of T, variable) TODO
  local P = P0atm + ro * g_accel * h 
  return ro, P, T
end

M.surface = require'fsim.surface'.flat { h0=0.0 }

return M