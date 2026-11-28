-- Minimal test framework, no dependencies.
-- Test files register cases with T.test / T.xfail; tests/run.lua runs them.

local T = { cases = {} }

-- register a test that must pass
function T.test ( name, fn )
  T.cases[#T.cases+1] = { name = name, fn = fn }
end

-- register a test documenting a KNOWN BUG: it is expected to fail.
-- If it starts passing, the run fails so the marker gets removed.
function T.xfail ( name, reason, fn )
  T.cases[#T.cases+1] = { name = name, fn = fn, xfail = reason }
end

local function fmt ( v )
  if type(v) == 'table' then
    local s = {}
    for i = 1, #v do s[i] = tostring(v[i]) end
    return '{' .. table.concat(s, ', ') .. '}'
  end
  return tostring(v)
end
T.fmt = fmt

local function fail ( msg, level )
  error(msg, (level or 1) + 2)
end

function T.ok ( cond, msg )
  if not cond then fail(msg or 'expected true') end
end

function T.eq ( got, expected, msg )
  if got ~= expected then
    fail(string.format('%sexpected %s, got %s', msg and (msg..': ') or '', fmt(expected), fmt(got)))
  end
end

local function is_finite ( x )
  return type(x) == 'number' and x == x and x ~= math.huge and x ~= -math.huge
end
T.is_finite = is_finite

function T.near ( got, expected, tol, msg )
  tol = tol or 1e-9
  if not (is_finite(got) and math.abs(got - expected) <= tol) then
    fail(string.format('%sexpected %s ± %g, got %s', msg and (msg..': ') or '', fmt(expected), tol, fmt(got)))
  end
end

-- relative tolerance, for quantities of arbitrary magnitude
function T.rnear ( got, expected, rtol, msg )
  rtol = rtol or 1e-9
  local tol = rtol * math.max(math.abs(expected), 1e-300)
  if not (is_finite(got) and math.abs(got - expected) <= tol) then
    fail(string.format('%sexpected %s (rel ± %g), got %s', msg and (msg..': ') or '', fmt(expected), rtol, fmt(got)))
  end
end

-- component-wise comparison of vectors, quaternions, matrices (n = #expected)
function T.vnear ( got, expected, tol, msg )
  tol = tol or 1e-9
  for i = 1, #expected do
    if not (is_finite(got[i]) and math.abs(got[i] - expected[i]) <= tol) then
      fail(string.format('%sexpected %s ± %g, got %s', msg and (msg..': ') or '', fmt(expected), tol, fmt(got)))
    end
  end
end

-- quaternions q and -q are the same rotation
function T.qnear ( got, expected, tol, msg )
  tol = tol or 1e-9
  local same, flipped = true, true
  for i = 1, 4 do
    if not (math.abs(got[i] - expected[i]) <= tol) then same = false end
    if not (math.abs(got[i] + expected[i]) <= tol) then flipped = false end
  end
  if not (same or flipped) then
    fail(string.format('%sexpected ±%s ± %g, got %s', msg and (msg..': ') or '', fmt(expected), tol, fmt(got)))
  end
end

function T.finite ( v, msg )
  if type(v) == 'number' then v = { v } end
  for i = 1, #v do
    if not is_finite(v[i]) then
      fail(string.format('%snon-finite value in %s', msg and (msg..': ') or '', fmt(v)))
    end
  end
end

function T.raises ( fn, pattern, msg )
  local ok, err = pcall(fn)
  if ok then fail((msg and (msg..': ') or '') .. 'expected an error') end
  if pattern and not tostring(err):find(pattern) then
    fail(string.format('%serror %q does not match %q', msg and (msg..': ') or '', tostring(err), pattern))
  end
end

-- run fn with print() silenced (the loader is chatty)
function T.quiet ( fn, ... )
  local saved = print
  print = function() end
  local res = table.pack(pcall(fn, ...))
  print = saved
  if not res[1] then error(res[2], 0) end
  return table.unpack(res, 2, res.n)
end

-- forget project modules so the next require() gets fresh copies (forces
-- built outside a world share the default fsim.medium)
function T.reset_modules ()
  for name in pairs(package.loaded) do
    if name:match('^fsim%.') or name == 'loader' then
      package.loaded[name] = nil
    end
  end
end

-- run fn on freshly loaded project modules with some math functions
-- removed, as in Lua 5.4+ built without compatibility (and Lua 5.5)
function T.without_math ( names, fn )
  local saved = {}
  for _, n in ipairs(names) do saved[n] = math[n]; math[n] = nil end
  T.reset_modules()
  local ok, err = pcall(fn)
  for _, n in ipairs(names) do math[n] = saved[n] end
  T.reset_modules()
  if not ok then error(err, 0) end
end

return T
