-- Renders a 1x1 3D cube in NDC.
local gl = require("moongl")

return function()
-- set up vertex data (and buffer(s)) and configure vertex attributes ---------
  local vertices = {
    -- positions      --normal        -- texture coords
    -0.5, -0.5, -0.5, 0.0, 0.0, -1.0, 0.0, 0.0, 
    0.5, -0.5, -0.5, 0.0, 0.0, -1.0, 1.0, 0.0, 
    0.5, 0.5, -0.5, 0.0, 0.0, -1.0, 1.0, 1.0, 
    0.5, 0.5, -0.5, 0.0, 0.0, -1.0, 1.0, 1.0, 
    -0.5, 0.5, -0.5, 0.0, 0.0, -1.0, 0.0, 1.0, 
    -0.5, -0.5, -0.5, 0.0, 0.0, -1.0, 0.0, 0.0, 

    -0.5, -0.5, 0.5, 0.0, 0.0, 1.0, 0.0, 0.0, 
    0.5, -0.5, 0.5, 0.0, 0.0, 1.0, 1.0, 0.0, 
    0.5, 0.5, 0.5, 0.0, 0.0, 1.0, 1.0, 1.0, 
    0.5, 0.5, 0.5, 0.0, 0.0, 1.0, 1.0, 1.0, 
    -0.5, 0.5, 0.5, 0.0, 0.0, 1.0, 0.0, 1.0, 
    -0.5, -0.5, 0.5, 0.0, 0.0, 1.0, 0.0, 0.0, 

    -0.5, 0.5, 0.5, -1.0, 0.0, 0.0, 1.0, 0.0, 
    -0.5, 0.5, -0.5, -1.0, 0.0, 0.0, 1.0, 1.0, 
    -0.5, -0.5, -0.5, -1.0, 0.0, 0.0, 0.0, 1.0, 
    -0.5, -0.5, -0.5, -1.0, 0.0, 0.0, 0.0, 1.0, 
    -0.5, -0.5, 0.5, -1.0, 0.0, 0.0, 0.0, 0.0, 
    -0.5, 0.5, 0.5, -1.0, 0.0, 0.0, 1.0, 0.0, 

    0.5, 0.5, 0.5, 1.0, 0.0, 0.0, 1.0, 0.0, 
    0.5, 0.5, -0.5, 1.0, 0.0, 0.0, 1.0, 1.0, 
    0.5, -0.5, -0.5, 1.0, 0.0, 0.0, 0.0, 1.0, 
    0.5, -0.5, -0.5, 1.0, 0.0, 0.0, 0.0, 1.0, 
    0.5, -0.5, 0.5, 1.0, 0.0, 0.0, 0.0, 0.0, 
    0.5, 0.5, 0.5, 1.0, 0.0, 0.0, 1.0, 0.0, 

    -0.5, -0.5, -0.5, 0.0, -1.0, 0.0, 0.0, 1.0, 
    0.5, -0.5, -0.5, 0.0, -1.0, 0.0, 1.0, 1.0, 
    0.5, -0.5, 0.5, 0.0, -1.0, 0.0, 1.0, 0.0, 
    0.5, -0.5, 0.5, 0.0, -1.0, 0.0, 1.0, 0.0, 
    -0.5, -0.5, 0.5, 0.0, -1.0, 0.0, 0.0, 0.0, 
    -0.5, -0.5, -0.5, 0.0, -1.0, 0.0, 0.0, 1.0, 

    -0.5, 0.5, -0.5, 0.0, 1.0, 0.0, 0.0, 1.0, 
    0.5, 0.5, -0.5, 0.0, 1.0, 0.0, 1.0, 1.0, 
    0.5, 0.5, 0.5, 0.0, 1.0, 0.0, 1.0, 0.0, 
    0.5, 0.5, 0.5, 0.0, 1.0, 0.0, 1.0, 0.0, 
    -0.5, 0.5, 0.5, 0.0, 1.0, 0.0, 0.0, 0.0, 
    -0.5, 0.5, -0.5, 0.0, 1.0, 0.0, 0.0, 1.0, 
  }
  local vao = gl.gen_vertex_arrays()
  local vbo = gl.gen_buffers()
  gl.bind_vertex_array(vao)
  gl.bind_buffer('array', vbo)
  gl.buffer_data('array', gl.pack('float', vertices), 'static draw')
  -- position attribute
  gl.vertex_attrib_pointer(0, 3, 'float', false, 8*gl.sizeof('float'), 0)
  gl.enable_vertex_attrib_array(0)
  -- normal attribute
  gl.vertex_attrib_pointer(1, 3, 'float', false, 8*gl.sizeof('float'), 3*gl.sizeof('float'))
  gl.enable_vertex_attrib_array(1)
  -- texture coords attribute
  gl.vertex_attrib_pointer(2, 2, 'float', false, 8*gl.sizeof('float'), 6*gl.sizeof('float'))
  gl.enable_vertex_attrib_array(2)
  gl.unbind_buffer('array')
  gl.unbind_vertex_array() 

  return setmetatable({}, {
      __index = {
        draw = function(cube) 
          gl.bind_vertex_array(vao)
          gl.draw_arrays('triangles', 0, 36)
          gl.unbind_vertex_array()
        end,
        delete = function(cube)
          if not vao then return end
          gl.delete_vertex_array(vao)
          gl.delete_buffers(vbo)
          vao, vbo = nil
        end,
      },
      __gc = function(cube) cube:delete() end,
    })
end

