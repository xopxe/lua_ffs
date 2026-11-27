local T = require 'tests.lib'
local surface = require 'fsim.surface'

local function waves ( generator, extra )
  local p = { h0 = 0.5, amplitude = 0.3, length = 10, dir = 0.2, ddir = 0.5, n = 4 }
  for k, v in pairs(extra or {}) do p[k] = v end
  return surface.wavetrain_generate(generator, p), p
end

local function amplitude_sum ( p )
  local s = 0
  for i = 1, #p do s = s + p[i].amplitude end
  return s
end

-- the returned normal is (-dh/dx, -dh/dy, 1), not normalized
local function check_normal ( s )
  local e = 1e-6
  for _, pt in ipairs{ {0, 0, 0}, {3.3, -1.2, 2.5}, {-7, 4, 11} } do
    local x, y, t = pt[1], pt[2], pt[3]
    local _, n = s.height(x, y, t)
    local nx, ny, nz = n[1], n[2], n[3]  -- copy: n is reused between calls
    local dhdx = (s.height(x + e, y, t) - s.height(x - e, y, t)) / (2 * e)
    local dhdy = (s.height(x, y + e, t) - s.height(x, y - e, t)) / (2 * e)
    T.vnear({nx, ny, nz}, {-dhdx, -dhdy, 1}, 1e-6)
  end
end

T.test('flat surface', function()
  local s = surface.flat{h0 = 2}
  local h, n = s.height(1, 2, 3)
  T.eq(h, 2)
  T.vnear(n, {0, 0, 1})
end)

T.test('wavetrain_generate builds n scaled waves', function()
  local _, p = waves('flat')
  T.eq(#p, 4)
  T.near(p[1].length, 10)
  T.near(p[1].amplitude, 0.3)
  for i = 2, 4 do
    T.near(p[i].length, p[i-1].length * 1.18, 1e-12)
    T.near(p[i].amplitude, p[i-1].amplitude * 0.82, 1e-12)
    T.ok(math.abs(p[i].dir - 0.2) <= 0.5, 'direction within dir +- ddir')
  end
end)

T.test('wavetrain_generate is reproducible with the same seed', function()
  math.randomseed(7); local _, a = waves('flat')
  math.randomseed(7); local _, b = waves('flat')
  for i = 1, 4 do T.eq(a[i].dir, b[i].dir) end
end)

T.test('sine_wave stays within h0 +- sum of amplitudes', function()
  local s, p = waves('sine_wave')
  local A = amplitude_sum(p)
  for i = 0, 200 do
    local h = s.height(i * 0.37, i * -0.21, i * 0.05)
    T.ok(h >= p.h0 - A - 1e-12 and h <= p.h0 + A + 1e-12, 'h = ' .. h)
  end
end)

T.test('sine_wave normal matches the height gradient', function()
  check_normal((waves('sine_wave')))
end)

T.test('sine_wave single wave is periodic in time', function()
  local s = surface.sine_wave{ h0 = 0, {amplitude = 1, length = 10, dir = 0} }
  local omega = math.sqrt(9.8 * math.pi * 2 / 10)
  local period = 2 * math.pi / omega
  for _, x in ipairs{0, 1.5, 4} do
    T.near(s.height(x, 0, 1 + period), s.height(x, 0, 1), 1e-9)
  end
end)

T.test('powsine_wave stays within [h0 - 2 sum(A), h0]', function()
  local s, p = waves('powsine_wave', {K = 2})
  local A = amplitude_sum(p)
  for i = 0, 200 do
    local h = s.height(i * 0.37, i * -0.21, i * 0.05)
    T.ok(h >= p.h0 - 2 * A - 1e-12 and h <= p.h0 + 1e-12, 'h = ' .. h)
  end
end)

T.test('powsine_wave normal matches the height gradient', function()
  check_normal((waves('powsine_wave', {K = 2.5})))
end)

-- known bugs ---------------------------------------------------------------

T.xfail('works without math.pow (Lua 5.4+ builds without compat, Lua 5.5)', 'surface.lua uses math.pow', function()
  local saved = math.pow
  math.pow = nil
  T.reset_modules()
  local ok, err = pcall(function()
    local s = require('fsim.surface').powsine_wave{ h0 = 0, K = 2, {amplitude = 1, length = 10} }
    s.height(1, 2, 3)
  end)
  math.pow = saved
  T.reset_modules()
  if not ok then error(err, 0) end
end)
