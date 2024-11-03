local M = {}
local random, sqrt, PI, exp, log, ceil, cos, sin, atan2, acos = 
math.random, math.sqrt, math.pi, math.exp, math.log, math.ceil, math.cos, math.sin, math.atan2, math.acos


function M.avgstd(t)
  local avg, std, count = 0, 0, 0
  for _, v in pairs(t) do
    avg=avg+v
    count=count+1
  end
  avg=avg/count
  for _, v in pairs(t) do
    std=std+(v-avg)^2
  end
  std=sqrt(std/count)

  return avg, std
end

function M.avg(t)
  local avg, count = 0, 0
  for _, v in pairs(t) do
    avg=avg+v
    count=count+1
  end
  avg=avg/count

  return avg
end

function M.linear_interpol(x1,y1, x2,y2, x)
  return y1+((x-x1)/(x2-x1))*(y2-y1)
end

function M.count(t)
  local count = 0
  for _, v in pairs(t) do
    count=count+1
  end
  return count
end

function M.minmax(t)
  local min, max = math.huge, -math.huge
  for _, v in pairs(t) do
    if v<min then min=v end
    if v>max then max=v end
  end
  return min, max
end

function M.sample_exp_distribution(l)
  local u = random()
  local r = -log(u) / l
  return r
end

function M.productory (a, b, f)
  local p = 1
  if f then
    for k = a, b do
      p = p*f(k)
    end
  else
    for k = a, b do
      p = p*k
    end
  end
  return p
end

function M.sumatory( a )
  local sum = 0
  for i=1, #a do
    sum = sum+a[i]
  end
  return sum
end

function M.median ( t )
  local temp={}
  local med, low, high

  -- deep copy table so that when we sort it, the original is unchanged
  -- also weed out any non numbers
  for k,v in pairs(t) do
    if type(v) == 'number' then
      temp[#temp+1] = v
    end
  end

  table.sort( temp )

  if #temp==0 then return nil, nil, nil end

  if #temp%2 == 0 then
    med = ( temp[#temp/2] + temp[(#temp/2)+1] ) / 2
  else
    med = temp[ceil(#temp/2)]
  end

  --print ('!!1', #temp/4)
  --print ('!!2', 3*#temp/4)
  --print ('<'..#temp..'>',table.concat(temp, ' | '))

  if #temp%4 == 0 then
    low = ( temp[#temp/4] + temp[#temp/4+1] ) / 2
  else
    low = temp[ceil(#temp/4)]
  end

  if 3*#temp%4 == 0 then
    high = ( temp[3*#temp/4] + temp[3*#temp/4+1] ) / 2
  else
    high = temp[ceil(3*#temp/4)]
  end

  return med, low, high
end

-- Fisher–Yates shuffle
function M.shuffle(list)
  for i = #list, 2, -1 do
    local j = random(i)
    list[i], list[j] = list[j], list[i]
  end
end

function M.latlon_to_m_converter (latmed, lonmed)
  --[[
  local m_per_deg_lat = 111132.954 - 559.822 * math_cos( 2.0 * latmed ) 
  + 1.175 * math_cos( 4.0 * latmed);
  local m_per_deg_lon = (3.14159265359/180 ) * 6367449 * math_cos ( latmed );
  --]]
  local m_per_deg_lat = 111132.92 - 559.82 * cos(2.0 * latmed) 
  + 1.175 * cos(4.0 * latmed) - 0.0023 * cos(6.0*latmed)
  local m_per_deg_lon = 111412.84 * cos(latmed) - 93.5*cos(3.0*latmed)
  +0.118*cos(5.0*latmed)

  return function(lat, lon)
    local deltaLat = lat - latmed
    local deltaLon = lon - lonmed

    return deltaLat * m_per_deg_lat, deltaLon * m_per_deg_lon
  end
end

local PI_180 = PI/180
function M.latlon_dist_haversine(lat1, lon1, lat2, lon2)
  --https://www.movable-type.co.uk/scripts/latlong.html
  local R = 6371e3 -- metres
  local phi1 = lat1 * PI_180 -- φ, λ in radians
  local phi2 = lat2 * PI_180 
  local Dphi = (lat2-lat1) * PI_180
  local Dlambda = (lon2-lon1) * PI_180

  local sinDphi_2 = sin(Dphi/2)
  local sinDlambda_2 = sin(Dlambda/2)

  local a = sinDphi_2 * sinDphi_2 +
  cos(phi1) * cos(phi2) *
  sinDlambda_2 * sinDlambda_2
  local c = 2 * atan2(sqrt(a), sqrt(1-a))

  return c * R  -- in metres
end
function M.latlon_dist_spherical(lat1, lon1, lat2, lon2)
  --https://www.movable-type.co.uk/scripts/latlong.html
  local R = 6371e3 -- metres
  local phi1 = lat1 * PI_180
  local phi2 = lat2 * PI_180
  local Dlambda = (lon2-lon1) * PI_180
  local d = acos( sin(phi1)*sin(phi2) + cos(phi1)*cos(phi2) * cos(Dlambda) )
  return d * R  -- in metres
end

function M.latlon_dist_equirect(lat1, lon1, lat2, lon2)
  --https://www.movable-type.co.uk/scripts/latlong.html
  local R = 6371e3 -- metres
  local Dlambda = (lon2-lon1) * PI_180
  local Dphi = (lat2-lat1) * PI_180
  local x = Dlambda * cos(Dphi/2)
  local y = Dphi
  local d = sqrt(x*x + y*y)
  return d * R  -- in metres
end

function M.binsearch(a, value, low, high)
  low = low or 1
  high = high or #a
  local mid
  while low <= high do
    --mid = (low + high) // 2
    mid = math.floor((low + high) / 2)
    if a[mid] > value then
      high = mid - 1
    elseif a[mid] < value then
      low = mid + 1
    else
      return mid
    end
  end
  return nil
end

function M.binsearch_insert(a, value, low, high)
  low = low or 1
  high = high or #a
  local mid
  while low <= high do
    --mid = (low + high) // 2
    mid = math.floor((low + high) / 2)
    if a[mid] > value then
      high = mid - 1
    elseif a[mid] < value then
      low = mid + 1
    else
      return mid
    end
  end
  if low<high then return low
  else return high end
end

function M.is_prime(n)
  local divisor = 2
  local max_divisor = math.floor(math.sqrt(n) + 1)
  while divisor < max_divisor do
    if n % divisor == 0 then 
      return false
    end
    divisor = divisor + 1
  end
  return true
end

-- from https://jamesmccaffrey.wordpress.com/2020/07/27/a-full-cycle-generator-in-python/
function M.full_cycle_generator(n, seed)
  local function compute_p( n )
    local p = math.floor(n/3) + 1
    while p < n do
      if M.is_prime(p) and (n % p) ~= 0 then
        return p
      end
      p = p + 1
    end
    return -1  -- error
  end

  local p = compute_p(n) --the inc
  local curr = seed % n
  return function() --next_int(self)
    curr = (curr+p) %n
    return curr
  end
end

return M
