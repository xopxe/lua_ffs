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
local prog, vsh, fsh = gl.make_program({vertex="fvis-moongl/shaders/bbox.vert",
    fragment="fvis-moongl/shaders/bbox.frag"})
gl.delete_shaders(vsh, fsh)

-- tell opengl for each sampler to which texture unit it belongs to (only has to be done once)
gl.use_program(prog) -- don't forget to activate/use the shader before setting uniforms!

-- get the locations of the uniforms holding the transform matrices: 
local loc 

M.prepare_scene = function( world, SCR_WIDTH, SCR_HEIGHT )
  local light = assert(world.light)
  local camera = assert(world.camera)

  gl.use_program(prog)

  --gl.line_width(2)

  loc = {
    model = gl.get_uniform_location(prog, "model"),
    view  = gl.get_uniform_location(prog, "view"),
    projection = gl.get_uniform_location(prog, "projection"),
    --view_pos = gl.get_uniform_location(prog, "viewPos"),
    color = gl.get_uniform_location(prog, "color"),
  }

  -- camera/view transformation
  gl.uniform_matrix4f(loc.view, true, world.transforms.view)
  -- projection transform (in this example it may change at every frame):
  gl.uniform_matrix4f(loc.projection, true, world.transforms.projection)
  --gl.uniformf(loc.view_pos, camera.position)
end

M.prepare_model = function( model, color )
  gl.uniform_matrix4f(loc.model, true, model)

  if color then
    gl.uniform(loc.color, 'float', color[1], color[2], color[3])
  end
end

M.delete = function ()
  gl.delete_program(prog)
end

return M