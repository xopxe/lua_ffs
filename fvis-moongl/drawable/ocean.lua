local glfw = require("moonglfw")
local gl = require("moongl")
local glmath = require("moonglmath")
local vec4 = glmath.vec4
local mat4 = glmath.mat4
local point4 = glmath.vec4

--local medium = require'fsim.medium'
local world = require'fsim.world'

local function linear_interpol(x1,y1, x2,y2, x)
  return y1+((x-x1)/(x2-x1))*(y2-y1)
end

local N = world.surface_shader.parameters.side_count

return function()

  local points = {}   --float data[N][N]; array of data heights
  local npoints 
  --for i=1, N*N do -- flat mesh
  --  points[i] = 0.0
  --end

  local function populate_vertices()
    local now = world.now

    local p = 0
    local function insert_point(x,y)
      --local z, n = medium.surface.height(x, y, now)
      points[p+1] = x
      points[p+2] = y
      points[p+3] = 0.0
      p=p+3
    end

    for i=0, N-1 do
      for j = 0, N-1 do
        local x1, y1 = i, j
        local x2, y2 = i+1, j+1
        insert_point(x1, y1)
        insert_point(x1, y2)
        insert_point(x2, y2)
        insert_point(x2, y2)
        insert_point(x2, y1)
        insert_point(x1, y1)
      end
    end
    npoints = #points
    return true
  end
  populate_vertices()

  local vao = gl.gen_vertex_arrays()
  local vbo = gl.gen_buffers()

  local gl_points = gl.pack('float', points)

  return setmetatable({}, {
      __index = {
        draw = function(wave) 
          --if not populate_vertices() then return end
          gl.bind_vertex_array(vao)
          gl.bind_buffer('array', vbo)
          gl.buffer_data('array', gl_points, 'static draw')
          -- position attribute
          gl.vertex_attrib_pointer(0, 3, 'float', false, 3*gl.sizeof('float'), 0)
          gl.enable_vertex_attrib_array(0)
          -- normal attribute
          --gl.vertex_attrib_pointer(1, 3, 'float', false, 6*gl.sizeof('float'), 3*gl.sizeof('float'))
          --gl.enable_vertex_attrib_array(1)

          gl.unbind_buffer('array')

          gl.draw_arrays("triangles", 0, npoints)

          gl.unbind_vertex_array()
        end,
        delete = function(wave)
          if not vao then return end
          gl.delete_vertex_array(vao)
          gl.delete_buffers(vbo)
          vao, vbo = nil, nil
        end,
      },
      __gc = function(wave) wave:delete() end,
    })
end

