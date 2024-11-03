-- Renders a 1x1x1 3D sphere in NDC.
local gl = require("moongl")

local pi, sin, cos = math.pi, math.sin, math.cos

return function( params )
  params = params or {}
  local nx = params.nx or 64
  local ny = params.ny or 64

  local vertices, indices = {}, {}

  for y=0, ny do
    local yseg = y/ny
    for x=0, nx do
      local xseg = x/nx
      local xpos = cos(2*pi*xseg)*sin(pi*yseg)
      local ypos = cos(yseg*pi)
      local zpos = sin(2*pi*xseg)*sin(pi*yseg)
      vertices[#vertices+1] = {
        xpos, ypos, zpos,  -- position
        xpos, ypos, zpos, -- normal
        --0.0, 0.0, -1.0, -- normal
        xseg, yseg}        -- uv tex coords
    end
  end

  for y=0,ny-1 do
    if y%2==0 then  -- even rows: y == 0, y == 2 and so on
      for x=0,nx do
        indices[#indices+1] = y*(nx+1)+x
        indices[#indices+1] = (y+1)*(nx+1)+x
      end
    else
      for x=nx,0,-1 do
        indices[#indices+1] = (y+1)*(nx+1)+x
        indices[#indices+1] = y*(nx+1)+x
      end
    end
  end

  local vao = gl.new_vertex_array()
  local vbo = gl.new_buffer('array')
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

  local ebo = gl.new_buffer('element array')
  gl.buffer_data('element array', gl.pack('uint', indices), 'static draw')

  local count = #indices
  gl.unbind_vertex_array()

  return setmetatable({}, {
      __index = {
        draw = function(sphere) 
          gl.bind_vertex_array(vao)
          gl.draw_elements('triangle strip', count, 'uint', 0)
          gl.unbind_vertex_array()
        end,
        delete = function(sphere)
          if not vao then return end
          gl.delete_vertex_array(vao)
          gl.delete_buffers(vbo, ebo)
          vao, vbo, ebo, count = nil, nil, nil, nil
        end,
      },
      __gc = function(sphere) sphere:delete() end,
    })
end

