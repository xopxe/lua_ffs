--https://developer.nvidia.com/gpugems/gpugems/part-i-natural-effects/chapter-1-effective-water-simulation-physical-models

local M = {}

local vec3 = require'fsim.vec3'
local cos, sin, sqrt, pow = math.cos, math.sin, math.sqrt, math.pow
local random = math.random
local PI = math.pi
local PIx2 = PI*2

local g_accel = -9.8 --m/sec^2

M.wavetrain_generate = function ( generator, p )
  local scaling_amplitude = 0.82
  local scaling_length = 1.18

  p.amplitude = p.amplitude or 0.40
  p.length = p.length or 10.0
  p.dir = p.dir or 0.0
  p.ddir = p.ddir or 0.2
  p.n = p.n or 4
  p.generator = generator
  
  local stepness = p.amplitude/p.length

  local wave = {}
  wave.length = p.length
  wave.amplitude = p.amplitude
  wave.dir = p.dir
  p[1] = wave

  for i=2, p.n do
    local wave = {}
    wave.length = scaling_length * p[i-1].length
    wave.amplitude = scaling_amplitude * p[i-1].amplitude
    --wave.amplitude = wave.length*stepness
    wave.dir = p.dir + 2*random()*p.ddir - p.ddir
    p[i] = wave
  end
  return M[generator](p)
end


M.flat = function ( ws )
  ws = ws or {}
  ws.h0 = ws.h0 or 0.0

  local up = vec3.new{0.0,0.0,1.0}

  ws.height = function ( x, y, t )
    return ws.h0, up
  end
  return ws
end

M.sine_wave = function ( ws )
  ws = ws or { {} }
  ws.h0 = ws.h0 or 0.0
  for _, wave in ipairs(ws) do
    wave.amplitude = wave.amplitude or 0.1  --m
    wave.length = wave.length or 1.0 --m
    wave.dir = wave.dir or 0.0
    wave.dirx, wave.diry = wave.dirx or cos(wave.dir), wave.diry or sin(wave.dir)
    --wave.offset = random()*2*math.pi
  end

  local norm = vec3.new{0.0, 0.0, 1.0}
  local p = vec3.new{0.0, 0.0, 0.0}

  ws.height = function ( x, y, t )
    t = t+100.0 --unsync at (x,y,t)=(0,0,0)
    local h = ws.h0 or 0.0
    norm:set(0.0, 0.0, 1.0)
    for iwave = 1, #ws do
      local wave = ws[iwave]
      local dirx, diry = wave.dirx, wave.diry
      local A = wave.amplitude
      local w = 2/wave.length --frequency
      local phi = sqrt(-g_accel*PI*w) --water wave speed from length
      local phase = (dirx*x + diry*y)*w + t*phi -- + wave.offset

      h = h + A * sin(phase)

      local dh = w*A*cos(phase) 

      p[1], p[2] = -dirx*dh, -diry*dh
      norm:add(p, norm)
    end
    return h, norm  --:normalize(norm)
  end
  return ws
end

M.powsine_wave = function ( ws )
  ws = ws or { {} }
  ws.h0 = ws.h0 or 0.0
  for _, wave in ipairs(ws) do
    wave.amplitude = wave.amplitude or 0.1  --m
    wave.length = wave.length or 1.0 --m
    wave.dir = wave.dir or 0.0
    wave.dirx, wave.diry = wave.dirx or cos(wave.dir), wave.diry or sin(wave.dir)
    --wave.offset = random()*2*math.pi
  end

  local norm = vec3.new{0.0, 0.0, 1.0}
  --local p = vec3.new{0.0, 0.0, 0.0}

  local K = ws.K

  ws.height = function ( x, y, t )
    t = t+100.0 --unsync at (x,y,t)=(0,0,0)
    local h = ws.h0 or 0.0
    norm:set(0.0,0.0,1.0)
    for iwave = 1, #ws do
      local wave = ws[iwave]
      local dirx, diry = wave.dirx, wave.diry
      local A = wave.amplitude
      local w = 2/wave.length --frequency
      local phi = sqrt(-g_accel*PI*w) --water wave speed from length
      local phase = (dirx*x + diry*y)*w + t*phi -- + wave.offset

      local sin_phase = sin(phase)
      local cos_phase = cos(phase)

      h = h + 2*A*(pow(0.5*(sin_phase+1.0), K)-1.0)

      local dh = K*w*A * pow(0.5*(sin_phase+1.0), K-1) * cos_phase

      norm[1], norm[2] = norm[1]-dirx*dh, norm[2]-diry*dh
    end
    return h, norm --:normalize(norm)
  end
  return ws
end

M.gerstner_wave = function ( ws )
  ws = ws or { {} }
  ws.h0 = ws.h0 or 0.0
  for _, wave in ipairs(ws) do
    wave.amplitude = wave.amplitude or 0.1  --m
    wave.length = wave.length or 1.0 --m
    wave.dir = wave.dir or 0.0
  end

  ws.height = function ()
    error('NYI')
  end

  ws.sample = function ( x, y, t )
    local x_out, y_out, h = x, y, ws.h0
    for iwave = 1, #ws do
      local wave = ws[iwave]
      local length = wave.length/PIx2
      local xdir, ydir = cos(wave.dir), sin(wave.dir)
      local phase = (x*xdir+y*ydir)/length - t/sqrt(length)

      x_out = x_out - wave.amplitude*xdir*sin(phase)
      y_out = y_out - wave.amplitude*ydir*sin(phase)
      h = h + wave.amplitude * cos( phase )
    end
    return x_out, y_out, h
  end
  return ws
end

return M
