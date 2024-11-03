local M = {}

local vec3 = require 'fsim.vec3'
local inertia = require 'fsim.inertia'
local rbody = require 'fsim.rigid_body'
local world = require 'fsim.world'

local object_name_store

local function clone_table ( def, skipset )
  local p = {}
  for k, v in pairs(def) do
    if not (skipset and skipset[k]) then
      p[k] = v
    end
  end
  return p
end

local function parse_path ( s )
  local p = {}
  for w in string.gmatch(s, "([^%.]+)") do
    p[#p+1] = w
  end
  return p
end

M.parse_loadworld = function ( wrld )
  --local forces = {}
  --local medium = {}
  
  if wrld.randomseed then
    print ('randomseed:', wrld.randomseed)
    math.randomseed(wrld.randomseed)
  end

  local skiplist = {'IMPORT_BODY', 'BODY_FROM_NAME', 'V3', 'L', 'print'}
  for _, s in ipairs(skiplist) do wrld[s] = nil end

  -- link names if available
  for i=1, #wrld.bodies do
    local name = wrld.bodies[i].name
    if name then
      assert(not wrld.bodies[name], 'duplicated name: '..tostring(name))
      wrld.bodies[name] = wrld.bodies[i]
    end
  end

  for fidx, fdef in ipairs( wrld.forces or {} ) do
    local class = fdef.class
    local params = fdef.params
    local name = params.name
    print ('world force class', class, 'under name', name)

    local path = parse_path(fdef.class)
    local current = assert( require('fsim.'..path[1]) )
    for i=2, #path-1 do
      current = current[path[i]]
    end
    local f = current[path[#path]](params)      
    wrld.forces[fidx] = f
    if name then 
      assert(not wrld.forces[name], 'duplicated name: '..tostring(name))
      wrld.forces[name] = f 
    end
  end

  do
    local medium = require 'fsim.medium'
    wrld.medium = wrld.medium or {}

    --surface
    local surface = wrld.medium.surface or {generator='flat', params={h0=0}}
    --[[
    local surface_generator = surface.generator
    local surface_params = surface.params
    medium.surface = require'fsim.surface'[surface_generator](surface_params)
    --]]
    medium.surface = require'fsim.surface'.wavetrain_generate(surface.generator,surface.params)

    --atmosphere
    for k, v in pairs(wrld.medium.atmosphere or {}) do
      medium.atmosphere[k] = v
    end

    --ocean
    for k, v in pairs(wrld.medium.ocean or {}) do
      medium.ocean[k] = v
    end

    wrld.medium = medium
  end


  --wrld = world.new ( wrld )
  for k, v in pairs(wrld) do
    if world[k] then print ('Overwriting world.'..k) end
    world[k] = v
  end


  --return wrld
  return world
end

M.parse_loadbody = function ( bdy )
  local inertia_element
  local forces

  do
    local inertia_elements = {}
    for iidx, idef in ipairs( bdy.inertia or {} ) do
      local class = idef.class
      local params = idef.params
      local name = params.name

      local e = inertia.element.from_shape(class, params)
      inertia_elements[iidx] = e
      if name then 
        assert(not inertia_elements[name], 'duplicated name: '..tostring(name))
        inertia_elements[name] = e 
      end
    end
    if #inertia_elements==1 then 
      inertia_element = inertia_elements[1]
    else
      inertia_element = inertia.element.from_elements(inertia_elements)
    end
  end

  do
    bdy.inertia = assert(inertia_element)
    forces = bdy.forces or {} --store forces away for setting them after body creadion
    bdy.forces = nil
    bdy = rbody.new(bdy)
  end

  do
    for fidx, fdef in ipairs( forces ) do
      local class = fdef.class
      local params = fdef.params
      local name = params.name

      params.body = bdy --!!!!!!!! implies one&only one exists

      local path = parse_path(fdef.class)
      local current = assert( require('fsim.'..path[1]) )
      for i=2, #path-1 do
        current = current[path[i]]
      end
      local f = current[path[#path]](params)      
      forces[fidx] = f
      if name then 
        assert(not forces[name], 'duplicated name: '..tostring(name))
        forces[name] = f 
      end
    end
    bdy.forces = forces
  end

  return bdy
end


local create_vector = function (v)
  return vec3.new(v)
end

local import_body = function (filename, params)
  local loadobject = {V3=create_vector}
  local name = params.name
  print( "importing body from", filename, 'as', name)
  local cmd = assert( loadfile(filename, 'bt', loadobject) )
  cmd()
  -- overwrite fields from file object 
  for k, v in pairs(params) do
    loadobject[k] = v
  end
  local b = M.parse_loadbody(loadobject)
  assert(not object_name_store[name], 'duplicated name: '..tostring(name))
  object_name_store[name] = b
  return b
end

local body_from_name = function ( name )
  return assert(object_name_store[name], 'unknown name: '..tostring(name))
end

M.load_body = function ( filename )
  return import_body{ filename }
end

M.load_world = function ( filename )
  local loadobject = { 
    IMPORT_BODY=import_body, 
    BODY_FROM_NAME=body_from_name, 
    V3=create_vector, 
    L=assert(_G),
    print=print,
  } -- check skiplist above
  print( "loading world from", filename )
  local cmd = assert( loadfile(filename, 'bt', loadobject) )
  object_name_store = {}
  cmd()
  object_name_store = {}
  local w = M.parse_loadworld(loadobject)
  return w
end

return M
