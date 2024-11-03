-- Renders a 1x1 3D cube in NDC.
local gl = require("moongl")

return function()
-- set up vertex data (and buffer(s)) and configure vertex attributes ---------
  local vertices = {
    -0.5, -0.5, -0.5, 1.0,
    0.5, -0.5, -0.5, 1.0,
    0.5,  0.5, -0.5, 1.0,
    -0.5,  0.5, -0.5, 1.0,
    -0.5, -0.5,  0.5, 1.0,
    0.5, -0.5,  0.5, 1.0,
    0.5,  0.5,  0.5, 1.0,
    -0.5,  0.5,  0.5, 1.0,
  }
  local indices = {
    0, 1, 2, 3,
    4, 5, 6, 7,
    0, 4, 1, 5, 2, 6, 3, 7
  }
  local vao = gl.new_vertex_array()
  local vbo = gl.new_buffer('array')
  gl.bind_vertex_array(vao)
  gl.bind_buffer('array', vbo)
  gl.buffer_data('array', gl.pack('float', vertices), 'static draw')
  -- position attribute
  gl.vertex_attrib_pointer(0, 4, 'float', false, 4*gl.sizeof('float'), 0)
  gl.enable_vertex_attrib_array(0)
  gl.unbind_buffer('array')
  --gl.unbind_vertex_array() 

  local ebo = gl.new_buffer('element array')
  gl.buffer_data('element array', gl.pack('uint', indices), 'static draw')

  local count = #indices
  gl.unbind_vertex_array()

  return setmetatable({}, {
      __index = {
        draw = function(cube) 
          gl.bind_vertex_array(vao)
          --gl.draw_arrays('triangles', 0, 36)
          --gl.unbind_vertex_array()
          
          --glDrawElements(GL_LINE_LOOP, 4, GL_UNSIGNED_SHORT, 0);
          gl.draw_elements('line loop', 4, 'uint', 0)
          --glDrawElements(GL_LINE_LOOP, 4, GL_UNSIGNED_SHORT, (GLvoid*)(4*sizeof(GLushort)));
          gl.draw_elements('line loop', 4, 'uint', 4*gl.sizeof('uint'))
          --glDrawElements(GL_LINES, 8, GL_UNSIGNED_SHORT, (GLvoid*)(8*sizeof(GLushort)));
          gl.draw_elements('lines', 8, 'uint', 8*gl.sizeof('uint'))

          --glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
          gl.unbind_vertex_array()

        end,
        delete = function(cube)
          if not vao then return end
          gl.delete_vertex_array(vao)
          gl.delete_buffers(vbo)
          vao, vbo, ebo = nil
        end,
      },
      __gc = function(cube) cube:delete() end,
    })
end

