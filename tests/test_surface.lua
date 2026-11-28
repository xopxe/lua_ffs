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
  local omega = math.sqrt(9.8 * 2 * math.pi / 10)  -- deep water: omega^2 = g k
  local period = 2 * math.pi / omega
  for _, x in ipairs{0, 1.5, 4} do
    T.near(s.height(x, 0, 1 + period), s.height(x, 0, 1), 1e-9)
  end
end)

-- one wave along x, 10 m long
local function single ( generator, K )
  return surface[generator]{ h0 = 0.5, K = K, {amplitude = 0.3, length = 10, dir = 0} }
end

for _, generator in ipairs{'sine_wave', 'powsine_wave'} do
  T.test(generator .. ': a wave repeats every length metres', function()
    local s = single(generator, 2)
    for _, x in ipairs{0, 1.5, 4} do
      T.near(s.height(x + 10, 0, 1), s.height(x, 0, 1), 1e-9, 'x = ' .. x)
    end
  end)

  T.test(generator .. ': a wave travels at the deep water speed sqrt(g L / 2 pi)', function()
    local s = single(generator, 2)
    local c, dt = math.sqrt(9.8 * 10 / (2 * math.pi)), 0.7
    for _, x in ipairs{0, 1.5, 4} do
      -- the phase is k (dir . x) + omega t, so the crests move towards -dir
      T.near(s.height(x - c * dt, 0, 1 + dt), s.height(x, 0, 1), 1e-9, 'x = ' .. x)
    end
  end)
end

T.test('powsine_wave: h0 is the mean sea level', function()
  for _, K in ipairs{1.5, 2, 2.5, 3} do
    local s = single('powsine_wave', K)
    local N, sum = 997, 0
    for i = 0, N - 1 do sum = sum + s.height(10 * i / N, 0, 1) end
    T.near(sum / N, 0.5, 1e-9, 'K = ' .. K)
  end
end)

T.test('powsine_wave stays within [h0 - 2 m sum(A), h0 + 2 (1 - m) sum(A)]', function()
  local s, p = waves('powsine_wave', {K = 2})
  local A = amplitude_sum(p)
  local m = 0.375  -- mean of ((sin + 1) / 2)^2 over a period
  T.near(s.shape_mean, m, 1e-12)
  for i = 0, 200 do
    local h = s.height(i * 0.37, i * -0.21, i * 0.05)
    T.ok(h >= p.h0 - 2 * m * A - 1e-12 and h <= p.h0 + 2 * (1 - m) * A + 1e-12, 'h = ' .. h)
  end
end)

T.test('powsine_wave normal matches the height gradient', function()
  check_normal((waves('powsine_wave', {K = 2.5})))
end)

T.test('works without math.pow (Lua 5.4+ without compat, Lua 5.5)', function()
  T.without_math({'pow'}, function()
    local s = require('fsim.surface').powsine_wave{ h0 = 0, K = 2, {amplitude = 1, length = 10} }
    T.finite(s.height(1, 2, 3))
  end)
end)
