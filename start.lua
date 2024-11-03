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
local fvis_step, fvis_run_time, fvis_run_cycles = 1/30, 0, 0
local fsim_write_step = total_run_time/200

local now = get_time()
w.now = now
local stop_time = now + total_run_time

local t_sim = w.now
local t_print = w.now
local t_view = w.now

local fsim_step_size, fsim_step_total = 0.0, 0.0

if profiler then profiler.start(0.01, 3) end
repeat

  if w.now+fsim_step<now then
    --if w.now<now then
    --w:step(now-w.now)
    fsim_step_size = now-w.now
    fsim_step_total = fsim_step_total + fsim_step_size
    fsim_run_time = fsim_run_time + time_call(w.step, w, fsim_step_size)
    fsim_run_cycles = fsim_run_cycles + 1
  end

  if fsim_write_step and now>=t_print then
    t_print = t_print + fsim_write_step
    print(w.now)
    w.write()
  end

  if now>=t_view then
    t_view = t_view + fvis_step
    fvis_run_time = fvis_run_time + time_call(view.display, w)
    fvis_run_cycles = fvis_run_cycles + 1
    
    view.poll()
  end
  
  --

  now = get_time()

until w.now>=stop_time or view.should_close()
if profiler then print( profiler.format( profiler.stop() ) ) end

print ('closing world at t', w.now)
w.close()

print ('fsim runtime', fsim_run_time, 'steps', fsim_run_cycles, 
  'steptime', fsim_run_time/fsim_run_cycles, 'stepsize', fsim_step_total/fsim_run_cycles)
print ('fvis steptime', fvis_run_time/fvis_run_cycles)
