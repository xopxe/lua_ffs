local loader = require 'loader'

local w = loader.load_world('world/drop.lua')
--local w = loader.load_world('world/balloon.lua')
--local w = loader.load_world('world/flight.lua')

if w.init then w.init() end -- opens the world's data file

local t_print = w.now

local incr = 0.001
local duration = 5
local t_print_incr = duration/100

repeat
  if w.now>=t_print then
    t_print=t_print+t_print_incr
    print(w.now)
    w.write()
  end
  w:step(incr)
until w.now>=duration

w.close()
