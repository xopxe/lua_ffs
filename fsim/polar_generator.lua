--http://walter.bislins.ch/bloge/index.asp?page=Airplane+Lift+and+Drag+Coefficients+for+the+whole+Range+of+AoA
local M = {}

local PI = math.pi
local PI_2 = PI/2
local exp = math.exp
local pow = math.pow
local rad = math.rad
local cos = math.cos
local sin = math.sin

M.__index = M

local function Down ( f, x, pos ) 
  -- ramp down from 0 to 1 at pos
  return 1 / (1 + exp( f.q * (x - pos)))
end

local function CDP ( f, aoa ) 
  -- drag coefficient for flat wing
  return 1 - cos( 2 * aoa );
end

local function Up ( f, x, pos ) 
  -- ramp up from 0 to 1 at pos
  return 1 / (1 + exp( -f.q * (x - pos)))
end

local CLP = function( f, aoa )
  -- lift coefficient for flat wing
  local result = sin( 2*aoa ) + f.clpOffset
  return result
end

local function CL ( f, aoa )
  -- lift coefficient for wing profile
  return f.cl1 + f.cl2 * aoa
end

local function CD ( f, aoa )
  -- drag coefficient for wing profile
  --var result = this.cd1 + this.cd2 * Math.pow( this.CL(aoa), 2 );
  return f.cd1 + f.cd2 * pow( CL( f, aoa), 2 );
end

local function  Win ( f, x, pos1, pos2 )
  -- ramp up from 0 to 1 at pos1 and down again at pos 2
  return Up( f, x, pos1 ) * Down( f, x, pos2 );
end

local function CLT( f, aoa ) 
  -- lift coefficient for whole range of AoA
  -- aoa in rad
  if aoa > PI_2 then aoa = aoa - PI end
  if aoa < -PI_2 then aoa = aoa + PI end
  local aoa1 = f.aoa1
  local aoa2 = f.aoa2
  local result = Down( f, aoa, aoa1)*CLP( f, aoa )
  + Win( f, aoa, aoa1, aoa2 )*CL( f, aoa )
  + Up( f, aoa, aoa2)*CLP( f, aoa )
  return result
end

local function CDT ( f, aoa ) 
  -- drag coefficient for whole range of AoA
  -- aoa in rad
  if aoa > PI_2 then aoa = aoa - PI end
  if aoa < -PI_2 then aoa = aoa + PI end
  local aoa1 = f.aoa1
  local aoa2 = f.aoa2
  local result = Down( f, aoa, aoa1 )*CDP( f, aoa ) 
  + Win( f, aoa, aoa1, aoa2 )*CD( f, aoa ) 
  + Up( f, aoa, aoa2)*CDP( f, aoa )
  return result
end

M.params = {
  -- The standard values are for an A320 with a CL / CD = 18 ratio
  A320 = {
    q = 25,
    aoa1 = rad(-5),
    aoa2 = rad(18),
    cl1 = 0.2,
    cl2 = 5.16,
    cd1 = 0.02,
    cd2 = 0.026,
    clpOffset = 0.1,
  },

  -- simple symmetrical foil
  SYMMETRICAL = {
    q = 25,
    aoa1 = rad(-15),
    aoa2 = rad(15),
    cl1 = 0.0,
    cl2 = 5.16,
    cd1 = 0.02,
    cd2 = 0.026,
    clpOffset = 0.0,
  }
}

M.get_aerodata = function ( profile )
  profile = profile or 'SYMMETRICAL'
  local ret = { profile = profile }

  ret.params = {} -- will return clone
  for k, v in pairs(M.params[profile]) do
    ret.params[k]=v
  end

  ret.sample = function (aoa)
    return CLT(ret.params, aoa), CDT(ret.params, aoa), 0
  end
  
  return ret
end


return M

--[[
function rad(x) { return x * Math.PI / 180; }

var ClModel = {

  aoa1: -5,
  aoa2: 18,
  cl1: 0.2,
  cl2: 5.16,
  cd1: 0.02,
  cd2: 0.026,
  clpOffset: 0.1,
  q: 25,
  graph: null,

  Init: function( g ) {
    this.graph = g;
  },

  CL: function( aoa ) {
    // lift coefficient for wing profile
    var result = this.cl1 + this.cl2 * aoa;
    return result;
  },

  CD: function( aoa ) {
    // drag coefficient for wing profile
    var result = this.cd1 + this.cd2 * Math.pow( this.CL(aoa), 2 );
    return result;
  },

  CLP: function( aoa ) {
    // lift coefficient for flat wing
    var result = Math.sin( 2 * aoa ) + this.clpOffset;
    return result;
  },

  CDP: function( aoa ) {
    // drag coefficient for flat wing
    var result = 1 - Math.cos( 2 * aoa );
    return result;
  },

  Up: function( x, pos ) {
    // ramp up from 0 to 1 at pos
    var result = 1 / (1 + Math.exp( -this.q * (x - pos)));
    return result;
  },

  Down: function( x, pos ) {
    // ramp down from 0 to 1 at pos
    var result = 1 / (1 + Math.exp( this.q * (x - pos)));
    return result;
  },

  Win: function( x, pos1, pos2 ) {
    // ramp up from 0 to 1 at pos1 and down again at pos 2
    var result = this.Up( x, pos1 ) * this.Down( x, pos2 );
    return result;
  },

  // public

  CLT: function( aoa ) {
    // lift coefficient for whole range of AoA
    // aoa in rad
    if (aoa >  Math.PI/2) aoa -= Math.PI;
    if (aoa < -Math.PI/2) aoa += Math.PI;
    var aoa1 = rad(this.aoa1);
    var aoa2 = rad(this.aoa2);
    var result = 
      this.Down( aoa, aoa1 )       * this.CLP( aoa ) + 
      this.Win(  aoa, aoa1, aoa2 ) * this.CL(  aoa ) + 
      this.Up(   aoa, aoa2)        * this.CLP( aoa );
    return result;
  },

  CLT_deg: function( aoaDeg ) {
    // lift coefficient for whole range of AoA
    return this.CLT( rad(aoaDeg) );
  },

  CDT: function( aoa ) {
    // drag coefficient for whole range of AoA
    // aoa in rad
    if (aoa >  Math.PI/2) aoa -= Math.PI;
    if (aoa < -Math.PI/2) aoa += Math.PI;
    var aoa1 = rad(this.aoa1);
    var aoa2 = rad(this.aoa2);
    var result = 
      this.Down( aoa, aoa1 )       * this.CDP( aoa ) + 
      this.Win(  aoa, aoa1, aoa2 ) * this.CD(  aoa ) + 
      this.Up(   aoa, aoa2)        * this.CDP( aoa );
    return result;
  },

  CDT_deg: function( aoaDeg ) {
    return this.CDT( rad(aoaDeg) );
  },

  Update: function( field ) {
    ControlPanels.Update();
    this.Draw( this.graph );
  },

  Draw: function( g ) {
    g.Reset();
    g.SetWindowWH( -180, -2.5, 360, 5 );

    g.SetLineAttr( 'lightgray', 1 );
    g.Grid( 15, 0.2, true, false );

    g.SetLineAttr( 'black', 1 ); 
    g.Axes( 0, 0, 'Arrow1', 10 );
    g.TicsX( 0, 15, 3, 3, true, true );
    g.TicLabelsX( 0, 15, -4, 1, 0, true, true, '°' );
    g.TicsY( 0, 0.2, 3, 3, true, true );
    g.TicLabelsY( 0, 0.2, -4, 1, 1, true, true );

    g.SetLineAttr( 'blue', 2 );
    g.NewPoly();
    var deltaAoa = 360 / 360;
    var lastAoa = 180 + deltaAoa;
    for (aoa = -180; aoa <= lastAoa; aoa += deltaAoa) {
      g.AddPointToPoly( aoa, this.CLT_deg(aoa) );
    }
    g.DrawPoly( 1 );

    g.SetLineAttr( 'red', 2 );
    g.NewPoly();
    var deltaAoa = 360 / 360;
    var lastAoa = 180 + deltaAoa;
    for (aoa = -180; aoa <= lastAoa; aoa += deltaAoa) {
      g.AddPointToPoly( aoa, this.CDT_deg(aoa) );
    }
    g.DrawPoly( 1 );
  },

};

var graph = NewGraph2D( {
  Id: 'JsGraph1',
  Width: '100%',
  Height: '75%',
  DrawFunc: function(g){ ClModel.Draw(g); },
  AutoReset: true,
  AutoClear: false,
  AutoScalePix: false,
} );

ClModel.Init( graph );

xOnLoad( function() { ClModel.Update(); } );
--]]