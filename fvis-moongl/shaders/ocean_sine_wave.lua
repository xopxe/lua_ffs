local M = {}

local gl = require("moongl")
local glmath = require("moonglmath")

local world = require'fsim.world'

local perspective = glmath.perspective
local rotate, translate, scale = glmath.rotate, glmath.translate, glmath.scale
local unpack = unpack or table.unpack

local rad, sin, cos, sqrt = math.rad, math.sin, math.cos, math.sqrt
local vec3, vec4 = glmath.vec3, glmath.vec4

assert(world.medium.surface.generator == 'sine_wave', 'shader / wave generator mismatch')

-- build, compile, and link our shader program ---------------------------------
--local prog, vsh, fsh = gl.make_program({vertex="fvis-moongl/shaders/7.3.camera.vert",
--    fragment="fvis-moongl/shaders/7.3.camera.frag"})
local prog, vsh, fsh = gl.make_program({
    vertex="fvis-moongl/shaders/wavepatch_sine_wave.vert",
    fragment="fvis-moongl/shaders/wavepatch_sine_wave.frag"})
gl.delete_shaders(vsh, fsh)

-- tell opengl for each sampler to which texture unit it belongs to (only has to be done once)
gl.use_program(prog) -- don't forget to activate/use the shader before setting uniforms!

-- get the locations of the uniforms holding the transform matrices: 
local loc 

loc = {
  amplitude = gl.get_uniform_location(prog, "amplitude"),
  length = gl.get_uniform_location(prog, "length"),
  dirx = gl.get_uniform_location(prog, "dirx"),
  diry = gl.get_uniform_location(prog, "diry"),
  x_min = gl.get_uniform_location(prog, "x_min"),
  y_min = gl.get_uniform_location(prog, "y_min"),
  x_step = gl.get_uniform_location(prog, "x_step"),
  y_step = gl.get_uniform_location(prog, "y_step"),
  t = gl.get_uniform_location(prog, "t"),

  model = gl.get_uniform_location(prog, "model"),
  view  = gl.get_uniform_location(prog, "view"),
  projection = gl.get_uniform_location(prog, "projection"),
  view_pos = gl.get_uniform_location(prog, "viewPos"),
  light = {
    --position = gl.get_uniform_location(prog, "light.position"),
    direction = gl.get_uniform_location(prog, "light.direction"),
    ambient = gl.get_uniform_location(prog, "light.ambient"),
    diffuse = gl.get_uniform_location(prog, "light.diffuse"),
    specular = gl.get_uniform_location(prog, "light.specular"),
  },
  material = {
    ambient = gl.get_uniform_location(prog, "material.ambient"),
    diffuse = gl.get_uniform_location(prog, "material.diffuse"),
    specular = gl.get_uniform_location(prog, "material.specular"),
    shininess = gl.get_uniform_location(prog, "material.shininess"),
    alpha = gl.get_uniform_location(prog, "material.alpha"),
  },
}

local frustum_space = {
  vec4(1,1,-1, 1),
  vec4(1,-1,-1, 1),
  vec4(-1,-1,-1, 1),
  vec4(-1,1,-1, 1),
  vec4(1,1,1, 1),
  vec4(1,-1,1, 1),
  vec4(-1,-1,1, 1),
  vec4(-1,1,1, 1)
}
local frustum_corners = {}
local frustrum_edges = {
  {1,2},{2,3},{3,4},{4,1},
  {5,6},{6,7},{7,8},{8,5},
  {1,5},{2,6},{3,7},{4,8}
}

local function update_area_frustum( material )
  local view = world.transforms.view
  local projection = world.transforms.projection
  local unproj = (projection*view):inv()
  --local unproj = view:inv() * projection:inv()
  -- transform frusrtum to world space
  for i=1, 8 do
    frustum_corners[i] = unproj * frustum_space[i]
    frustum_corners[i] = frustum_corners[i]/frustum_corners[i][4] --regularize
  end
  --intersect frstrum edges with ground plane
  local minx, maxx, miny, maxy = math.huge, -math.huge, math.huge, -math.huge
  local count = 0

  --[[
  for i=1, 12 do
    local edge = frustrum_edges[i]
    local p1, p2 = frustum_corners[ edge[1] ], frustum_corners[ edge[2] ]

    -- on different side of ground plane
    if (p1[3]>0 and p2[3]<0) or (p1[3]<0 and p2[3]>0) then 
      count = count + 1
      local k = p1[3]/(p1[3]-p2[3])
      local x = p1[1] + k * (p2[1]-p1[1])
      local y = p1[2] + k * (p2[2]-p1[2])

      if x<minx then minx = x end
      if x>maxx then maxx = x end
      if y<miny then miny = y end
      if y>maxy then maxy = y end
    end
  end
  if count<3 then -- not enough points for a patch
    return nil
  end
  --]]
  ---[[
  for i=1, 8 do
    local x = frustum_corners[i][1]
    local y = frustum_corners[i][2]

    if x<minx then minx = x end
    if x>maxx then maxx = x end
    if y<miny then miny = y end
    if y>maxy then maxy = y end
  end
  --]]

  local area = material.area
  area[1][1], area[1][2], area[2][1], area[2][2] = minx, miny, maxx, maxy
end

M.prepare_scene = function( world, SCR_WIDTH, SCR_HEIGHT )
  local light = assert(world.light)
  local camera = assert(world.camera)

  gl.use_program(prog)

  -- camera/view transformation
  gl.uniform_matrix4f(loc.view, true, world.transforms.view)

  gl.uniform_matrix4f(loc.projection, true, world.transforms.projection)
  gl.uniformf(loc.view_pos, camera.position)
  
  -- wave model
  local amplitude = vec4()
  local length = vec4()
  local dirx = vec4()
  local diry = vec4()
  for i=1, 4 do
    local wave = world.medium.surface[i]
    amplitude[i] = wave.amplitude
    length[i] = wave.length
    dirx[i] = cos(wave.dir)
    diry[i] = sin(wave.dir)
  end
  gl.uniformf(loc.amplitude, unpack(amplitude))
  gl.uniformf(loc.length, unpack(length))
  gl.uniformf(loc.dirx, unpack(dirx))
  gl.uniformf(loc.diry, unpack(diry))

  gl.uniformf(loc.t, world.now)

  if light then
    --[[
    local position = light.position
    if position then
      gl.uniform(loc.light.position, 'float', position[1], position[2], position[3])
    end
    --]]
    local direction = light.direction
    if direction then
      gl.uniform(loc.light.direction, 'float', direction[1], direction[2], direction[3])
    end
    local diffuse = light.diffuse
    if diffuse then
      gl.uniform(loc.light.diffuse, 'float', diffuse[1], diffuse[2], diffuse[3])
    end    
    local ambient = light.ambient
    if ambient then
      gl.uniform(loc.light.ambient, 'float', ambient[1], ambient[2], ambient[3])
    end    
    local specular = light.specular
    if specular then
      gl.uniform(loc.light.specular, 'float', specular[1], specular[2], specular[3])
    end
  end
end

M.prepare_model = function( model, material )
  gl.uniform_matrix4f(loc.model, true, model)

  if material then
    local ambient = material.ambient
    if ambient then
      gl.uniform(loc.material.ambient, 'float', ambient[1], ambient[2], ambient[3])
    end
    local diffuse = material.diffuse
    if diffuse then
      gl.uniform(loc.material.diffuse, 'float', diffuse[1], diffuse[2], diffuse[3])
    end
    local specular = material.specular
    if specular then
      gl.uniform(loc.material.specular, 'float', specular[1], specular[2], specular[3])
    end
    local shininess = material.shininess
    if shininess then
      gl.uniform(loc.material.shininess, 'float', shininess)
    end
    local alpha = material.alpha or 1.0
    gl.uniform(loc.material.alpha, 'float', alpha)
    
    if material.area_mode == 'frustum' then update_area_frustum(material) end
    local area = material.area
    if area then
      gl.uniformf(loc.x_min, area[1][1])
      gl.uniformf(loc.y_min, area[1][2])
      gl.uniformf(loc.x_step, (area[2][1]-area[1][1])/material.side_count)
      gl.uniformf(loc.y_step, (area[2][2]-area[1][2])/material.side_count)
    end
  
  end
end

M.delete = function ()
  gl.delete_program(prog)
end

return M
