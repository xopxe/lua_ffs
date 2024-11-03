local M = {}

local rad = math.rad
local deg = math.deg
local floor = math.floor

local PI = math.pi
local PIx2 = PI*2

local data = {}
-- [series] = {AoA, Cl, Cd [,Cm]}

-- AirfoilPrep_v2.02.03.xls
data.AIRFOIL_PREP = {
  {-180,0.0000,0.1770,0.0000}, {-170,0.2299,0.2132,0.4000}, {-160,0.4597,0.3173,0.2431},
  {-150,0.4907,0.4758,0.2568}, {-140,0.5053,0.6686,0.2865}, {-130,0.4805,0.8708,0.3185},
  {-120,0.4102,1.0560,0.3458}, {-110,0.2985,1.1996,0.3632}, {-100,0.1565,1.2818,0.3672},
  {-90,0.0000,1.2900,0.3559}, {-80,-0.1565,1.2818,0.3443}, {-70,-0.2985,1.1996,0.3182},
  {-60,-0.4102,1.0560,0.2808}, {-50,-0.4805,0.8708,0.2362}, {-40,-0.5053,0.6686,0.1886},
  {-30,-0.4907,0.4758,0.1414}, {-20,-0.4637,0.3158,0.0942}, {-10.1,-0.6300,0.0390,-0.0044},
  {-8.2,-0.5600,0.0233,-0.0051}, {-6.1,-0.6400,0.0131,0.0018}, {-4.1,-0.4200,0.0134,-0.0216},
  {-2.1,-0.2100,0.0119,-0.0282}, {0.1,0.0500,0.0122,-0.0346}, {2,0.3000,0.0116,-0.0405},
  {4.1,0.5400,0.0144,-0.0455}, {6.2,0.7900,0.0146,-0.0507}, {8.1,0.9000,0.0162,-0.0404},
  {10.2,0.9300,0.0274,-0.0321}, {11.3,0.9200,0.0303,-0.0281}, {12.1,0.9500,0.0369,-0.0284},
  {13.2,0.9900,0.0509,-0.0322}, {14.2,1.0100,0.0648,-0.0361}, {15.3,1.0200,0.0776,-0.0363},
  {16.3,1.0000,0.0917,-0.0393}, {17.1,0.9400,0.0994,-0.0398}, {18.1,0.8500,0.2306,-0.0983},
  {19.1,0.7000,0.3142,-0.1242}, {20.1,0.6600,0.3186,-0.1155}, {30,0.7010,0.4758,-0.1710},
  {40,0.7219,0.6686,-0.2202}, {50,0.6864,0.8708,-0.2637}, {60,0.5860,1.0560,-0.3002},
  {70,0.4264,1.1996,-0.3284}, {80,0.2235,1.2818,-0.3471}, {90,0.0000,1.2900,-0.3559},
  {100,-0.1565,1.2818,-0.3672}, {110,-0.2985,1.1996,-0.3632}, {120,-0.4102,1.0560,-0.3458},
  {130,-0.4805,0.8708,-0.3185}, {140,-0.5053,0.6686,-0.2865}, {150,-0.4907,0.4758,-0.2568},
  {160,-0.4597,0.3173,-0.2431}, {170,-0.2299,0.2132,-0.5000}, {180,0.0000,0.1770,0.0000},
}
-- convert aoa to radians
for i=1, #data.AIRFOIL_PREP do
  data.AIRFOIL_PREP[i][1] = rad(data.AIRFOIL_PREP[i][1])
end


local function binsearch(a, value, low, high)
  low = low or 1
  high = high or #a
  local mid
  while low <= high do
    --mid = (low + high) // 2
    mid = floor((low + high) / 2)
    if a[mid][1] > value then
      high = mid - 1
    elseif a[mid][1] < value then
      low = mid + 1
    else
      return mid
    end
  end
  return nil, low, high
end

local function linear_interpol(x1,y1, x2,y2, x)
  return y1+((x-x1)/(x2-x1))*(y2-y1)
end

M.get_aerodata = function ( series )
  series = series or 'AIRFOIL_PREP'
  local ret = { series = series }

  ret.data = {} --clone the polar
  for k, v in pairs(data[series]) do
    ret.data[k]=v
  end

  ret.sample = function ( aoa )
    while aoa>PI do aoa = aoa-PIx2 end
    while aoa<-PI do aoa = aoa+PIx2 end

    local data = ret.data

    local i, low, high = binsearch(data, aoa)
    if i then
      return data[i][2], data[i][3], data[i][4]
    else
      local cl = linear_interpol(data[low][1], data[low][2], data[high][1], data[high][2], aoa)
      local cd = linear_interpol(data[low][1], data[low][3], data[high][1], data[high][3], aoa)
      local cm = linear_interpol(data[low][1], data[low][4], data[high][1], data[high][4], aoa)
      return cl, cd, cm
    end
  end

  return ret
end

--[[
local aero = M.get_aerodata('AIRFOIL_PREP')
for aoa=-PI, PI, PIx2/20 do
  print ( deg(aoa), aero(aoa) )
end
--]]

return M