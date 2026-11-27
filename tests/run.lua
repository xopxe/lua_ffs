-- Test runner. From the project root:
--   lua5.3 tests/run.lua                  -- all tests/test_*.lua
--   lua5.3 tests/run.lua tests/test_vec3.lua [...]
--   VERBOSE=1 lua5.3 tests/run.lua        -- tracebacks on failures
package.path = './?.lua;' .. package.path

local T = require 'tests.lib'
local verbose = os.getenv('VERBOSE')

local files = {}
if #arg > 0 then
  for i = 1, #arg do files[#files+1] = arg[i] end
else
  local p = assert(io.popen('ls tests'))
  for f in p:lines() do
    if f:match('^test_.*%.lua$') then files[#files+1] = 'tests/' .. f end
  end
  p:close()
  table.sort(files)
end

local counts = { pass = 0, fail = 0, xfail = 0, xpass = 0 }
local problems = {}

local function handler ( err )
  return verbose and debug.traceback(tostring(err), 2) or tostring(err)
end

for _, file in ipairs(files) do
  print(file)
  T.cases = {}
  T.reset_modules()
  math.randomseed(12345)
  local chunk, err = loadfile(file)
  local ok = chunk ~= nil
  if ok then ok, err = xpcall(chunk, handler) end
  if not ok then
    counts.fail = counts.fail + 1
    problems[#problems+1] = file .. ': failed to load: ' .. tostring(err)
    print('  FAIL   (file did not load) ' .. tostring(err))
  end

  for _, case in ipairs(T.cases) do
    local passed, cerr = xpcall(case.fn, handler)
    if case.xfail then
      if passed then
        counts.xpass = counts.xpass + 1
        problems[#problems+1] = file .. ': ' .. case.name .. ': passes now; turn it into T.test'
        print('  XPASS  ' .. case.name .. '  <- known bug seems fixed, change xfail to test')
      else
        counts.xfail = counts.xfail + 1
        print('  xfail  ' .. case.name .. '  (' .. case.xfail .. ')')
      end
    elseif passed then
      counts.pass = counts.pass + 1
      print('  ok     ' .. case.name)
    else
      counts.fail = counts.fail + 1
      problems[#problems+1] = file .. ': ' .. case.name .. ': ' .. tostring(cerr)
      print('  FAIL   ' .. case.name .. '\n         ' .. tostring(cerr):gsub('\n', '\n         '))
    end
  end
end

print(string.format('\n%d passed, %d failed, %d known failures (xfail), %d unexpected passes',
  counts.pass, counts.fail, counts.xfail, counts.xpass))
if #problems > 0 then
  print('\nProblems:')
  for _, p in ipairs(problems) do print('  ' .. p) end
  os.exit(1)
end
