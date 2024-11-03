local M = {}

local gl = require("moongl")
local glmath = require("moonglmath")

local perspective = glmath.perspective
local rotate, translate, scale = glmath.rotate, glmath.translate, glmath.scale

local rad, sin, cos, sqrt = math.rad, math.sin, math.cos, math.sqrt
local vec3 = glmath.vec3

-- build, compile, and link our shader program ---------------------------------
--local prog, vsh, fsh = gl.make_program({vertex="fvis-moongl/shaders/7.3.camera.vert",
--    fragment="fvis-moongl/shaders/7.3.camera.frag"})
local prog, vsh, fsh = gl.make_program({vertex="fvis-moongl/shaders/uniform.vert",
    fragment="fvis-moongl/shaders/uniform.frag"})
gl.delete_shaders(vsh, fsh)

-- tell opengl for each sampler to which texture unit it belongs to (only has to be done once)
gl.use_program(prog) -- don't forget to activate/use the shader before setting uniforms!

-- get the locations of the uniforms holding the transform matrices: 
local loc 

M.prepare_scene = function( world, SCR_WIDTH, SCR_HEIGHT )
  local light = assert(world.light)
  local camera = assert(world.camera)

  gl.use_program(prog)

  loc = {
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
    }
  }

  -- camera/view transformation
  gl.uniform_matrix4f(loc.view, true, world.transforms.view)
  -- projection transform (in this example it may change at every frame):
  gl.uniform_matrix4f(loc.projection, true, world.transforms.projection)
  gl.uniformf(loc.view_pos, camera.position)


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
  end
end

M.delete = function ()
  gl.delete_program(prog)
end

return M