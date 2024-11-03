--require('mobdebug').coro()

local sched = require 'lumen.sched'
local loader = require 'fsim.loader'
local view = require 'fvis-three.visualize'.init() --sets sched.get_time to socket.gettime
--local view = require 'fvis-moongl.visualize'.init()  --sets sched.get_time to sglfw.get_time

local w = loader.load_world('world/drop.lua')
--local w = loader.load_world('world/balloon.lua')
--local w = loader.load_world('world/flight.lua')

local total_run_time = 5 --math.huge --600
local fsim_step, fsim_run_time = 0.001, 0
local fvis_step, fvis_run_time = 1/10, 0
local fsim_write_step = nil --total_run_time/100

local fsim_count, fsim_over_count = 0, 0

-- physics
local function fsim_func ()
  w.now = sched.get_time()
  local next_t = w.now
  local fsim_to_now = 0
  local to_sleep = 0
  local now, now2
  while true do
    now = sched.get_time() 
    next_t = next_t + fsim_step
    if next_t<now then 
      --print ('fsim forwarding', next_t, now)
      next_t = now 
    end
    
    fsim_to_now = next_t - w.now
    w:step(fsim_to_now)
    now2 = sched.get_time() 
    fsim_run_time = fsim_run_time + now2 - now
    
    fsim_count = fsim_count+1
        
    to_sleep = next_t - now2
    if to_sleep<0 then 
      --print ('WARN: fsim overstep', to_sleep, fsim_to_now)
      fsim_over_count = fsim_over_count+1
      to_sleep=0 
    end
        
    sched.sleep(to_sleep)
  end
end

-- display
local function fvis_func ()
  local next_t, elapsed, sleep = sched.get_time(), 0, 0
  local now
  while true do
    local now = sched.get_time()
    view.display( w )
    fvis_run_time = fvis_run_time + sched.get_time() - now
    sched.sleep(fvis_step)
  end
end

-- world write
local function wwrt_func ()
  local next_t = sched.get_time()
  while true do
    w.write()
    next_t = next_t + fsim_write_step
    sched.sleep(next_t-sched.get_time())
  end
end

--clock
local function tick_func ()
  local next_t = sched.get_time()
  while true do
    print(sched.get_time())
    next_t = next_t + 1
    sched.sleep(next_t-sched.get_time())
  end
end

-- main task
sched.run( function()
    -- start tasks
    local fsim_task = sched.run( fsim_func ):set_as_attached()
    local fvis_task = sched.run( fvis_func ):set_as_attached()
    --local tick_task = sched.run( tick_func ):set_as_attached()
    local wwrt_task
    if fsim_write_step then
      wwrt_task = sched.run( wwrt_func ):set_as_attached()
    end

    -- wait for program termination
    sched.sleep(total_run_time)

    if fsim_write_step then
      wwrt_task:kill()
      w:close()
    end
    view.close()
    fsim_task:kill()
    fvis_task:kill()

    print('fsim run time',fsim_run_time, 'of', total_run_time)
    print('fsim count', fsim_count, 'over step', fsim_over_count)
    print('fview run time',fvis_run_time, 'of', total_run_time)

    sched.wait()
    for t in pairs(sched.tasks) do
      if t ~= sched.running_task then
        print ('remaining task', t, sched.running_task)
        --for k, v in pairs(t) do print ('=', k, v) end
        --t:kill()
      end
    end
    --os.exit()
  end
)

sched.loop()