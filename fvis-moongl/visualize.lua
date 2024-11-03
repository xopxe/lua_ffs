local M = {}

local gl = require("moongl")
local glfw = require("moonglfw")
local mi = require("moonimage")
local glmath = require("moonglmath")
local new_cube = require("fvis-moongl.drawable.cube")
local new_bbox = require("fvis-moongl.drawable.bbox")
local new_sphere = require("fvis-moongl.drawable.sphere")
local new_texture = require("fvis-moongl.common.texture")

M.get_time = glfw.get_time

-- A few shortcuts:
local vec3 = glmath.vec3
local rotate, translate, scale = glmath.rotate, glmath.translate, glmath.scale
local clamp = glmath.clamp
local perspective, look_at = glmath.perspective, glmath.look_at
local rad, sin, cos, sqrt = math.rad, math.sin, math.cos, math.sqrt

local function vec3_from_world( v )
  return vec3(v[1], v[3], -v[2])
end

local SCR_WIDTH, SCR_HEIGHT = 800, 600

-- stuff to be initted
local window 
local texture1
local last_frame_time
--local prog
--local loc
local shapes
local shaders

local world, camera

-- camera:
local last_x, last_y = SCR_WIDTH/2, SCR_HEIGHT/2 -- initially at the center
local first_mouse = true
local sensitivity = 0.1 -- change this value to your liking

M.init = function ( conf )
  M.conf = conf or {}
  M.conf.window_title = M.conf.window_title or "Lua_FSIM"
  world = assert(conf.world)

  do
    local camera_conf = world.camera or {}
    local class = camera_conf.class or 'camera_fps'

    --[[
    local pos = camera_conf.pos --or {0.0, -20.0, 0.0}
    local front = camera_conf.front
    local yaw, pitch = camera_conf.yaw, camera_conf.pitch
    local up = camera_conf.up
    if up then up = vec3(up[1], up[2], up[3]):normalize() end
    --]]

    local camera_class = require("fvis-moongl.common."..class)
    camera = camera_class.init(camera_conf) --(vec3(pos[1], pos[2], pos[3]), up, yaw, pitch)
    world.camera = camera

    world.transforms = {
      view = camera:view(),
      projection = perspective(rad(camera.zoom), SCR_WIDTH/SCR_HEIGHT, 
        camera.near, camera.far),
    }
  end

-- glfw inits and window creation ---------------------------------------------
  glfw.version_hint(3, 3, 'core')
  window = glfw.create_window(SCR_WIDTH, SCR_HEIGHT, M.conf.window_title)
  glfw.make_context_current(window)
  gl.init() -- this loads all OpenGL function pointers

  shaders = {
    texture = require('fvis-moongl.shaders.texture'),
    uniform = require('fvis-moongl.shaders.uniform'),
    bbox = require('fvis-moongl.shaders.bbox'),
    --ocean = require('fvis-moongl.shaders.ocean_'..world.medium.surface.generator),
    --ocean = require('fvis-moongl.shaders.'..world.surface_shader.class),
  }
  if world.surface_shader then
    shaders.ocean = require('fvis-moongl.shaders.'..world.surface_shader.class)
  end


  shapes = {
    cube = new_cube(),
    bbox = new_bbox(),
    sphere = new_sphere(),
    --ocean = require(world.surface_shader.drawable)(),
  }
  if world.surface_shader then
    shapes.ocean = require(world.surface_shader.drawable)()
  end

  glfw.set_framebuffer_size_callback(window, function (window, w, h)
      gl.viewport(0, 0, w, h)
      SCR_WIDTH, SCR_HEIGHT = w, h
    end)

  glfw.set_cursor_pos_callback(window, function(window, xpos, ypos)
      -- whenever the mouse moves, this callback is called
      if first_mouse then
        last_x, last_y = xpos, ypos
        first_mouse = false
      end
      local xoffset = xpos - last_x
      local yoffset = last_y - ypos -- reversed since y-coordinates go from bottom to top
      last_x, last_y = xpos, ypos
      camera:process_mouse(xoffset, yoffset, false) --true)
    end)

  glfw.set_scroll_callback(window, function(window, xoffset, yoffset)
      -- whenever the mouse scroll wheel scrolls, this callback is called
      camera:process_scroll(yoffset)
    end)

  -- tell GLFW to capture our mouse:
  glfw.set_input_mode(window, 'cursor', 'disabled')

  -- configure global opengl state
  gl.enable('depth test')
  --gl.enable('cull face')
  --gl.polygon_mode('front and back', 'line')

  gl.enable('blend')
  gl.blend_func('src alpha', 'one minus src alpha')


  last_frame_time = glfw.get_time()

end

local function keypressed(x) return glfw.get_key(window, x)=='press' end

--[[
local light = {
  light_color = {1.0,1.0,1.0},
  light_dir = {1/sqrt(3), -1/sqrt(3), 1/sqrt(3)},
  ambient_strength = 0.2,
}
--]]

M.display = function ( w )

  -- render
  gl.clear_color(0.2, 0.3, 0.3, 1.0)
  gl.clear('color', 'depth')

  --w.light.position = w.camera.position

  w.transforms.view = camera:view()
  w.transforms.projection = perspective(rad(camera.zoom), SCR_WIDTH/SCR_HEIGHT, 
    camera.near, camera.far)

  local bshaders = {}

  for ib=1, #w.bodies do
    local body = w.bodies[ib]
    if body.shader then
      local shader_class = body.shader.class
      bshaders[shader_class] = bshaders[shader_class] or {}
      bshaders[shader_class][#bshaders[shader_class]+1] = body   
    end
  end

  for shader_class, blist in pairs(bshaders) do
    shaders[shader_class].prepare_scene( w, SCR_WIDTH, SCR_HEIGHT )
    for ib=1, #blist do
      local body = blist[ib]
      if body.model then
        local pos = vec3( body.position[1], body.position[2], body.position[3]) 
        local rot = glmath.quat(body.orientation[4],
          body.orientation[1],body.orientation[2],body.orientation[3]):mat4()
        local scl = body.model.params.scale or {1.0}
        local model = translate(pos) * rot * scale(scl[1],scl[2],scl[3])

        shaders[body.shader.class].prepare_model( model, body.shader.parameters )
        shapes[body.model.class]:draw()
      end
    end
  end

  -- bounding boxes for inertia elements, in design space
  local function draw_bbox_body ( body, element, color )
    local center = element.bbox.center
    local placement = element.placement or vec3()
    local pos = vec3( 
      body.position[1]+placement[1]+center[1], 
      body.position[2]+placement[2]+center[2], 
      body.position[3]+placement[3]+center[3]
    )
    local rot = glmath.quat(body.orientation[4],
      body.orientation[1],body.orientation[2],body.orientation[3]):mat4()
    local scl = assert(element.bbox.scale)
    local model = translate(pos) * rot * scale(scl[1],scl[2],scl[3])
    shaders['bbox'].prepare_model( model, color )
    shapes['bbox']:draw()
  end
  if world.inertia_bbox_color or world.forces_bbox_color then 
    shaders['bbox'].prepare_scene(w, SCR_WIDTH, SCR_HEIGHT ) 
    --body anchored boxes
    for ib=1, #w.bodies do
      local body = w.bodies[ib]
      if world.inertia_bbox_color then
        draw_bbox_body(body, body.inertia, world.inertia_bbox_color)
        local elements = body.inertia.elements
        if elements then
          for i = 1, #elements do
            draw_bbox_body(body, elements[i], world.inertia_bbox_color)
          end
        end
      end
      if world.forces_bbox_color then 
        for fi = 1, #body.forces do
          local force = body.forces[fi]
          if force.bbox then
            draw_bbox_body(body, force, world.forces_bbox_color)
          end
        end
      end
    end
  end


-- ocean
  if w.surface_shader then
    local model = glmath.mat4()
    local class = w.surface_shader.class
    shaders['ocean'].prepare_scene(w, SCR_WIDTH, SCR_HEIGHT )   
    shaders['ocean'].prepare_model( model, w.surface_shader.parameters)
    shapes.ocean:draw()
  end


-- swap buffers and poll IO events
  glfw.swap_buffers(window)
end

M.poll = function ()
  if glfw.window_should_close(window) then return end

  glfw.poll_events()
  local t = glfw.get_time()
  local dt = t - last_frame_time
  last_frame_time = t

  -- process input
  if keypressed('escape') then glfw.set_window_should_close(window, true) end
  local cam_speed = 2.5*dt
  -- camera movement controlled either by WASD keys or arrow keys:
  if keypressed('w') or keypressed('up') then camera:process_keyboard('forward', dt) end
  if keypressed('a') or keypressed('left') then camera:process_keyboard('left', dt) end
  if keypressed('s') or keypressed('down') then camera:process_keyboard('backward', dt) end
  if keypressed('d') or keypressed('right') then camera:process_keyboard('right', dt) end
  if keypressed('q') then camera:process_keyboard('up', dt) end
  if keypressed('z') then camera:process_keyboard('down', dt) end
end

M.should_close = function ()
  return glfw.window_should_close(window)
end

M.close = function ()
  -- optional: de-allocate all resources once they've outlived their purpose:
  for _, shape in pairs(shapes) do
    shape:delete()
  end
  for _, shader in pairs(shaders) do
    shader.delete()
  end
end

return M
