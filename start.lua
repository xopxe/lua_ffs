--local profiler = require 'ELProfiler'

local view = require 'fvis-moongl.visualize'
local get_time = view.get_time

if profiler then profiler.setClock(get_time) end

local loader = require 'loader'

local w = loader.load_world('world/sea.lua')
--local w = loader.load_world('world/sea_flat.lua')
--local w = loader.load_world('world/pendulum.lua')
--local w = loader.load_world('world/drop.lua')
--local w = loader.load_world('world/balloon.lua')
--local w = loader.load_world('world/flight.lua')

if w.init then w.init() end -- e.g. opens the world's data file

view.init{
  window_title= 'simulate!',
  world = w,
}


local function time_call ( f, ... )
  local ts = get_time()
  f(...)
  return get_time()-ts
end

local total_run_time = 60 --math.huge --600
local fsim_step, fsim_run_time, fsim_run_cycles = 0.001, 0, 0
-- when the simulation falls further behind the clock than this (a stall, or
-- steps that cost more than fsim_step), it slows down rather than catching up
local fsim_max_lag = 0.1
local fsim_time_lost = 0.0  -- clock time the simulation could not keep up with
local fvis_step, fvis_run_time, fvis_run_cycles = 1/30, 0, 0
-- the loop sleeps between frames, so the simulation lags by up to a frame
assert(fvis_step < fsim_max_lag, 'fsim_max_lag must be longer than a frame')
local fsim_write_step = total_run_time/200

-- simulated time starts at 0 and runs in fixed steps of fsim_step, whatever
-- the frame rate, so runs are reproducible; the clock only says how far to go.
-- Stopping and writing count steps, as w.now accumulates rounding errors.
local fsim_total_steps = math.floor(total_run_time/fsim_step + 0.5)
local fsim_write_every = fsim_write_step and math.max(1, math.floor(fsim_write_step/fsim_step + 0.5))

local function fsim_write ()
  if fsim_write_every and fsim_run_cycles % fsim_write_every == 0 then
    print(w.now)
    w.write()
  end
end

w.now = 0
fsim_write()  -- initial state

local now = get_time()
local clock_start = now  -- clock time at which simulated time was 0
local t_view = now

if profiler then profiler.start(0.01, 3) end
repeat

  local sim_target = now - clock_start
  if sim_target - w.now > fsim_max_lag then
    local lost = sim_target - w.now - fsim_max_lag
    fsim_time_lost = fsim_time_lost + lost
    clock_start = clock_start + lost
    sim_target = w.now + fsim_max_lag
  end
  -- step for at most a frame's worth of clock time, so the window keeps
  -- drawing even when steps cost more than the time they simulate
  local step_deadline = now + fvis_step
  while fsim_run_cycles < fsim_total_steps and w.now + fsim_step <= sim_target do
    fsim_run_time = fsim_run_time + time_call(w.step, w, fsim_step)
    fsim_run_cycles = fsim_run_cycles + 1
    fsim_write()
    if get_time() > step_deadline then break end
  end

  if now>=t_view then
    t_view = t_view + fvis_step
    fvis_run_time = fvis_run_time + time_call(view.display, w)
    fvis_run_cycles = fvis_run_cycles + 1
    
    view.poll()
  end
  
  now = get_time()
  -- sleep until the next frame rather than spin; the steps that come due
  -- meanwhile run in one go just before it is drawn
  if now < t_view then
    view.wait(t_view - now)
    now = get_time()
  end

until fsim_run_cycles >= fsim_total_steps or view.should_close()
if profiler then print( profiler.format( profiler.stop() ) ) end

print ('closing world at t', w.now)
w.close()

print ('fsim runtime', fsim_run_time, 'steps', fsim_run_cycles,
  'steptime', fsim_run_time/fsim_run_cycles, 'stepsize', fsim_step)
print ('fsim fell behind the clock by', fsim_time_lost, 's')
print ('fvis steptime', fvis_run_time/fvis_run_cycles)
