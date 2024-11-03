local glfw = require("moonglfw")
local gl = require("moongl")
local glmath = require("moonglmath")
local vec4 = glmath.vec4
local mat4 = glmath.mat4
local point4 = glmath.vec4

local medium = require'fsim.medium'
local world = require'fsim.world'

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

    --[[
    local view = world.transforms.view
    local projection = world.transforms.projection
    local function compute_patch()
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

      --return -5, -5, 5, 5
      return minx, miny, maxx, maxy
    end
    --]]

    local p = 0
    local function insert_point(x,y)
      --local x, y = ix*10-5, iy*10-5
      local z, n = medium.surface.height(x, y, now)
      points[p+1] = x
      points[p+2] = y
      points[p+3] = z
      points[p+4] = n[1]
      points[p+5] = n[2]
      points[p+6] = n[3]
      p=p+6
    end
    
    --compute_patch()
    local px1 = world.surface_shader.parameters.area[1][1]
    local py1 = world.surface_shader.parameters.area[1][2]
    local px2 = world.surface_shader.parameters.area[2][1]
    local py2 = world.surface_shader.parameters.area[2][2]

    --[[
    if not px1 then 
      return false  -- outside view, not display
    end 
    --]]

    local pdx, pdy = px2-px1, py2-py1
    for i=0, N-1 do
      for j = 0, N-1 do
        local i1, j1 = i/N, j/N
        local i2, j2 = (i+1)/N, (j+1)/N
        local x1, y1 = px1 + pdx*i1, py1 + pdy*j1
        local x2, y2 = px1 + pdx*i2, py1 + pdy*j2
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

  return setmetatable({}, {
      __index = {
        draw = function(wave) 
          if not populate_vertices() then return end 

          gl.bind_vertex_array(vao)
          gl.bind_buffer('array', vbo)
          gl.buffer_data('array', gl.pack('float', points), 'static draw')
          -- position attribute
          gl.vertex_attrib_pointer(0, 3, 'float', false, 6*gl.sizeof('float'), 0)
          gl.enable_vertex_attrib_array(0)
          -- normal attribute
          gl.vertex_attrib_pointer(1, 3, 'float', false, 6*gl.sizeof('float'), 3*gl.sizeof('float'))
          gl.enable_vertex_attrib_array(1)

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

