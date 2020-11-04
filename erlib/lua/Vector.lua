-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Point-to-Point 2D Vectors.
--
-- All Vector methods manipulate the vector in-place.
-- A new instance can be created with Vector:copy().
-- 
-- Conversion to other formats via Vector.to_* will obviously not
-- return a Vector ;).
-- 
-- Vector.to_area() output contains the aliases "lt" and "rb" in
-- addition to the standard format.
--
-- @{Introduction.DevelopmentStatus|Module Status}: Work in progress.
-- @{Introduction.Compatibility|Compatibility}: Pure Lua.
--
--
-- __Naming convention:__
--
-- All outputting methods are called to_*.
--
-- All methods that take two vectors take the vector `v` that the transformation
-- will be applied to first, and the vector `w` that contains the transformation
-- is taken as a VectorSpec `"..."`.
--
-- In transformation methods that have two component or derivate names in their
-- name the first refers to `w` and the second to `v`.
-- 
-- i.e `add_offset_to_origin`
--   adds the raw offset of `w` to the raw origin of `v` (often called "shift").
--   
-- i.e. `set_origin_to_target`
--   moves the origin of `v` to the absolute coordinates of the target of `w`.
--   
--
--
-- @module Vector
-- @usage
--  local Vector = require('__eradicators-library__/erlib/factorio/Vector')()
  
  
-- -------------------------------------------------------------------------- --
-- Internal Documentation                                                     --
-- -------------------------------------------------------------------------- --

--[[ References:
  
  https://textbooks.math.gatech.edu/ila/vectors.html
  
  https://matthew-brett.github.io/teaching/rotation_2d.html
    x2 = cosβ * x1 − sinβ * y1
    y2 = sinβ * x1 + cosβ * y1

  ]]

  
--|        Vector       |      Direction    |   Radian         |     math.atan2    |    Orientation    |--
--|                     |                   |                  |                   |                   |--
--|       { 0,-1}       |      0=north      |    1π/2          |     -π and +π     |      1 and 0      |--
--| {-1, 0}     { 1, 0} | 6=west     2=east | 1π      2π and 0 | -π/2          π/2 | 0.75         0.25 |--
--|       { 0, 1}       |      4=south      |    3π/2          |         0         |        0.5        |--
--|                  　　 |　                  |                  |                   |                   |--

  

  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --

local stop       = elreq('erlib/lua/Error')().Stopper 'Vector'
-- local log           = elreq('erlib/lua/Log'  )().Logger  'Vector'


local Class      = elreq('erlib/lua/Class')()

local Closurize  = elreq('erlib/lua/Meta/Closurize')()

local Verificate = elreq('erlib/lua/Verificate')()
-- local Verify           , Verify_Or
    -- = Verificate.verify, Verificate.verify_or

-- local Tool       = elreq('erlib/lua/Tool'      )()
    
-- local Table      = elreq('erlib/lua/Table'     )()
-- local Array      = elreq('erlib/lua/Array'     )()
-- local Set        = elreq('erlib/lua/Set'       )()

-- local Compose    = elreq('erlib/lua/Meta/Compose')()
-- local L          = elreq('erlib/lua/Lambda'    )()

local Math       = elreq('erlib/lua/Math')()

local pi               = math.pi
local deg2rad, rad2deg = math.rad  , math.deg
local floor, sqrt, abs = math.floor, math.sqrt, math.abs
local atan2, cos , sin = math.atan2, math.cos , math.sin



-- -------------------------------------------------------------------------- --
-- Legacy Layer                                                               --
-- -------------------------------------------------------------------------- --

local isTable  = Verificate.isType.table
local isNumber = Verificate.isType.number



-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Vector,_Vector,_uLocale = {},{},{}
local _Vector,_VectorMeta     = {},{} --verificators (legacy)



-- -------------------------------------------------------------------------- --
-- Helper                                                                     --
-- -------------------------------------------------------------------------- --

--shortcut to internally reattach the metatable without type detection
local function revectorize(v) return setmetatable(v,Vector.class_mt) end



--------------------------------------------------------------------------------
-- Todo.
-- @section
--------------------------------------------------------------------------------

----------
-- make `:to_offset_uid('spiral')` reversible
-- @within Todo
-- @table todo1


  
--------------------------------------------------------------------------------
-- Concepts.
-- @section
--------------------------------------------------------------------------------

----------
-- A two-component Vector.
-- 
-- A Vector is a @{DenseArray} `{dx, dy, ox, oy}`, 
-- it does not have named keys or subtables.
-- 
-- __Components:__
-- 
-- __The offset:__
-- `(dx, dy)` is the _relative_ vector from the origin to the target.
--   
-- __The origin:__
-- `(ox, oy)` is the _absolute_ point on the grid where the Vector starts. Usually `(0,0)`.
--
-- __Derivates:__
--
-- __The target:__
-- `(ox+dx, oy+dy)` is the absolute point on the grid that the Vector points at.
--
-- __The center:__
-- `(ox+(dx/2), oy+(dy/2))` is the middle of the "line" between a Vectors origin and target.
-- 
-- __Other:__
--
-- __The grid origin:__
-- The origin of a grid (aka coordinate system) is always `(0,0)`.
-- 
-- @table Vector



----------
-- Data that can be transformed into a Vector.
-- 
-- Explicit or shorthand @{BoundingBox}, explicit @{Position}, @{Vector},
-- @{FAPI Concepts Vector|SimpleVector} or up-to-four component varargs
-- `number, number or nil, number or nil, number or nil`.
-- 
-- Shorthand Position and SimpleVector are equivalent.
--
-- Up-to-four component varargs defaults are:
-- `dx or 0, dy or dx or 0, ox or 0, oy or 0`.
--
-- @table VectorSpec



--------------------------------------------------------------------------------
-- Class Parent.
-- @section
--------------------------------------------------------------------------------

--[[
  Usage
    Vector(Area) :: a factorio area box {left_top={x=,y=},right_bottom={x=,y=}}
    Vector(BoundingBox) :: a factorio bounding box {{x,y},{x,y}}
    Vector(Position) :: a factorio position {x=,y=}
    Vector(Vector) :: a four component vector created by this library
    Vector(SimpleVector) :: a factorio two component vector {x,y}
    Vector(Number,Number or nil,Number or nil,Number or nil) 
      :: Numbers are dx,dy,ox,oy
      :: if nil then origin defaults to (0,0)
      :: and dy defaults to dx
      :: dx is mandatory
  ]]
_VectorMeta.__call = {
  [2] = function(x) return isType('number_or_nil')(x) or isType('non_empty_table')(x) or 'VectorSpec' end,
  [3] = 'number_or_nil',
  [4] = 'number_or_nil',
  [5] = 'number_or_nil',
  }
Vector = Class.SwitchCaseClass(
  function(dx,dy,ox,oy)
    if dx == nil then --fastest entry-point
      return 'null_vector'
    elseif isTable(dx) then
      if     dx.is_vector    then return 'vector'            -- detect in order
      elseif dx.x            then return 'position'          -- of probable usage
      elseif dx.left_top     then return 'area'              -- frequency
      elseif isTable (dx[2]) then return 'bounding_box'      --
      elseif isNumber(dx[4]) then return 'missing_metatable' -- not all sub-components are checked
      elseif isNumber(dx[2]) then return 'simple_vector'     -- so don't put in garbage!
      end
    elseif dx == 0 and dy == 0 and isTable(ox) and ox.x then
      return 'position_as_origin'
    else
      return 'values' end
    end,
  -- nil, --no fallback, default is hard failure
  { ['vector'] = function(v) return v:copy() end,
    ['values'] = function(dx,dy,ox,oy) return
      {dx or 0,dy or dx or 0,ox or 0,oy or 0} end, --@future: "oy or ox or 0"?
    ['area']   = function(a) return {
      a.right_bottom.x - a.left_top.x,
      a.right_bottom.y - a.left_top.y,
      a.left_top.x                   ,
      a.left_top.y                   ,
      } end,
    ['bounding_box'] = function(b) return {
      b[2][1],b[2][2],  b[1][1],b[1][2],
      } end,
    ['simple_vector'] = function(v)
      return {v[1],v[2],0,0} end ,
    ['position'] = function(pos) return {
      pos.x,pos.y,0,0
      -- 0,0,pos.x,pos.y --> position starts as null vector pos origin? --> inconsistent
      } end,
    ['missing_metatable'] = function(v)
      return v end, --should this be reconstructed/copied?
    ['null_vector'] = function()
      return {0,0,0,0} end,
    ['position_as_origin'] = function(_,_,pos)
      return {0,0,pos.x,pos.y} end,
    ['default'] = Closurize(stop,'Not a vector.'),
  })

  
-- -------------------------------------------------------------------------- --
-- Constants                                                                  --
-- -------------------------------------------------------------------------- --
Vector.is_vector = true


--------------------------------------------------------------------------------
-- Copy.
-- @section
--------------------------------------------------------------------------------

--- A plain copy of the vector.
--- (in case the original is still needed)
function Vector.copy(v) return revectorize{v[1],v[2],v[3],v[4]} end

--------------------------------------------------------------------------------
-- Unpacking of Vector coordinates.
-- @section
--------------------------------------------------------------------------------

function Vector.get_target(v) return v[3]+v[1], v[4]+v[2] end
function Vector.get_offset(v) return v[1],v[2]            end
function Vector.get_origin(v) return            v[3],v[4] end

--------------------------------------------------------------------------------
-- Raw coordinate manipulation.
-- @section
--------------------------------------------------------------------------------

function Vector.null_offset(v    ) v[1],v[2] = 0,0 return v end
function Vector.null_origin(v    ) v[3],v[4] = 0,0 return v end
--
function Vector.set_offset_to_offset (v,...) v[1],v[2] = Vector(...):get_offset() return v end
function Vector.set_offset_to_target (v,...) v[1],v[2] = Vector(...):get_target() return v end
function Vector.set_offset_to_origin (v,...) v[1],v[2] = Vector(...):get_origin() return v end
--
function Vector.set_origin_to_offset (v,...) v[3],v[4] = Vector(...):get_offset() return v end
function Vector.set_origin_to_target (v,...) v[3],v[4] = Vector(...):get_target() return v end
function Vector.set_origin_to_origin (v,...) v[3],v[4] = Vector(...):get_origin() return v end

--------------------------------------------------------------------------------
-- Mirror. 
-- @section
--------------------------------------------------------------------------------

function Vector.mirror_offset_x (v) v[1],v[2] =  v[1],-v[2] return v end
function Vector.mirror_offset_y (v) v[1],v[2] = -v[1], v[2] return v end
function Vector.mirror_offset_xy(v) v[1],v[2] = -v[1],-v[2] return v end
function Vector.mirror_origin_x (v) v[3],v[4] =  v[3],-v[4] return v end
function Vector.mirror_origin_y (v) v[3],v[4] = -v[3], v[4] return v end
function Vector.mirror_origin_xy(v) v[3],v[4] = -v[3],-v[4] return v end

--------------------------------------------------------------------------------
-- Retargeting.
-- @section
--------------------------------------------------------------------------------

--recalculates the vector to point to the same target from the new origin
--input vectors with non-0,0 origin will be treated as absolute positions
function Vector.set_origin_to_target_keep_target(v,...)
  local wx,wy = Vector(...):get_target()
  v[1],v[2] = v[3]+v[1]-wx,v[4]+v[2]-wy
  v[3],v[4] = wx,wy
  return v end
--shortcut for the common null operation.
function Vector.null_origin_keep_target(v)
  if v[3]~=0 or v[4]~=0 then return v:set_origin_keep_target(0,0) end
  return v end
--recalculates the offset to point at the target of @w
function Vector.set_target_to_target_keep_origin(v,...)
  local wx,wy = Vector(...):get_target()
  v[1],v[2] = wx-v[3], wy-v[4]
  return v end
--in-place replaces the old vector with a new vector (target of @v -> target of @w)
function Vector.set_target_to_target_and_set_origin_to_own_target(v,...)
  local wx,wy = Vector(...):get_target()
  v[3],v[4] = v:get_target()
  v[1],v[2] = wx-v[3], wy-v[4]
  return v end
--move the origin of @v to it's own target, and mirrors
--the offset so that the new target is the old origin.
function Vector.swap_origin_with_target(v)
  v[1],v[2],v[3],v[4] = -v[1], -v[2], v[3]+v[1], v[4]+v[2]
  return v end

--------------------------------------------------------------------------------
-- Linear Transformation.
-- @section
--------------------------------------------------------------------------------

--adds components of @w to components of @v
function Vector.add_offset_to_offset(v,...) 
  local wx,wy = Vector(...):get_offset()
  v[1],v[2] = v[1]+wx,v[2]+wy
  return v end
function Vector.add_target_to_offset(v,...)
  local wx,wy = Vector(...):get_target()
  v[1],v[2] = v[1]+wx,v[2]+wy
  return v end
function Vector.add_offset_to_origin(v,...) 
  local wx,wy = Vector(...):get_offset()
  v[3],v[4] = v[3]+wx,v[4]+wy
  return v end
function Vector.add_target_to_origin(v,...)
  local wx,wy = Vector(...):get_target()
  v[3],v[4] = v[3]+wx,v[4]+wy
  return v end
--adds the vector @w to *both* sides of the vector (i.e. twice)
function Vector.add_offset_both_ways(v,...)
  local w = Vector(...)
  return
  v:add_offset_to_offset(w:copy():scale_offset(2))
   :add_offset_to_origin(w:mirror_offset_xy()    )
  end
function Vector.add_target_both_ways(v,...)
  local w = Vector(...)
  return
  v:add_target_to_offset(w:copy():scale_offset(2))
   :add_target_to_origin(w:mirror_offset_xy()    )
  end
--multiplies the offset/origin with a fixed factor
function Vector.scale_offset(v,n)
  v[1],v[2] = n*v[1],n*v[2]
  return v end
function Vector.scale_origin(v,n)
  v[3],v[4] = n*v[3],n*v[4]
  return v end
--scales the offset length by n/2 in each direction
--useful for expanding boxes
function Vector.scale_both_ways(v,n)
  -- return v:add_offset_to_origin(v:copy():mirror_offset_xy():scale_offset(0.5*n - 0.5)):scale_offset(n)
  v[1],v[2],v[3],v[4] = 
    v[1] * n                        ,
    v[2] * n                        ,
    v[3] - ( (0.5*n-0.5) * v[1] )   ,
    v[4] - ( (0.5*n-0.5) * v[2] )   
  return v end
--moves the origin of @v so that the center of the line @v_offset -> @v_target
--is positioned on the target of @w
function Vector.set_center_to_target(v,...)
  local wx,wy = Vector(...):get_target()
  v[3],v[4] = wx - v[1]/2, wy - v[2]/2
  return v end
  
--------------------------------------------------------------------------------
-- Angle Calculation.
-- @section
--------------------------------------------------------------------------------

--[[
  This is a list of forumals that produce output in the radian range
  annotated by which direction the value increases in and where the 
  0-singularity is. True radians are right / anti-clockwise. Remember
  that in the factorio coordinate system -y is north, and +y is south,
  and all directional references here (up,down,left,right) are relative
  to how it's actually displayed on the screen.
  
  rad = ( math.atan2(-v[1], v[2]) + math.pi )  --up         clockwise (!)
  rad = ( math.atan2( v[1], v[2]) + math.pi )  --up    anti-clockwise
  rad = ( math.atan2(-v[1],-v[2]) + math.pi )  --down  anti-clockwise
  rad = ( math.atan2( v[1],-v[2]) + math.pi )  --down       clockwies
  
  rad = ( math.atan2( v[2], v[1]) + math.pi )  --left       clockwise
  rad = ( math.atan2(-v[2], v[1]) + math.pi )  --left  anti-clockwise
  rad = ( math.atan2( v[2],-v[1]) + math.pi )  --right anti-clockwise
  rad = ( math.atan2(-v[2],-v[1]) + math.pi )  --right      clockwise

  This is a list of formulas that procude vectors of length 1
  for a given radian angle theta (derived from an up / clockwise vector)
  
  x,y =  math.sin(theta),-math.cos(theta)      -- up         clockwise (!)
  x,y = -math.sin(theta),-math.cos(theta)      -- up    anti-clockwise
  x,y =  math.sin(theta), math.cos(theta)      -- down  anti-clockwise
  x,y = -math.sin(theta), math.cos(theta)      -- down       clockwise
                                               
  x,y = -math.cos(theta),-math.sin(theta)      -- left       clockwise
  x,y = -math.cos(theta), math.sin(theta)      -- left  anti-clockwise
  x,y =  math.cos(theta),-math.sin(theta)      -- right anti-clockwise
  x,y =  math.cos(theta), math.sin(theta)      -- right      clockwise
  ]]
  
--[[ This is a mapping of directions to their factorio number

  [0] = defines.direction.north     , -- is 0
  [1] = defines.direction.northeast , -- is 1
  [2] = defines.direction.east      , -- is 2
  [3] = defines.direction.southeast , -- is 3
  [4] = defines.direction.south     , -- is 4
  [5] = defines.direction.southwest , -- is 5
  [6] = defines.direction.west      , -- is 6
  [7] = defines.direction.northwest , -- is 7
  [8] = defines.direction.north     , -- is 0 -- eight equals zero
  ]]
  
function Vector.to_radians    (v) return           pi + atan2( v[2],-v[1])            end --right anti-clockwise
function Vector.to_degrees    (v) return rad2deg ( pi + atan2(-v[1], v[2]) )          end --up/clockwise
function Vector.to_orientation(v) return         ( pi + atan2(-v[1], v[2]) ) / (2*pi) end --up/clockwise
function Vector.to_direction  (v) return floor   (v:to_orientation() * 8 + 0.5) % 8   end --up/clockwise
--these return a vector of length 1 (i.e. the vector {0,-1} rotated accordingly)
_Vector.from_degrees     = { [1] = 'number', [2] = 'number_or_nil' }
_Vector.from_radians     = { [1] = 'number', [2] = 'number_or_nil' }
_Vector.from_orientation = { [1] = 'number', [2] = 'number_or_nil' }
_Vector.from_direction   = { [1] = 'number', [2] = 'number_or_nil' }
function Vector.from_degrees (theta,len) --up/clockwise
  theta = deg2rad(theta)
  return Vector(sin(theta),-cos(theta)):scale_offset(len or 1)
  end
function Vector.from_radians (theta,len) -- right anti-clockwise
  return Vector(cos(theta),-sin(theta)):scale_offset(len or 1)
  end
function Vector.from_orientation(o,len) --up/clockwise
  local theta = o * 2*math.pi
  return Vector( sin(theta),-cos(theta) ):scale_offset(len or 1)
  end
function Vector.from_direction(d,len) --up/clockwise
  return Vector.from_orientation(d/8,len)
  end

  
  
--------------------------------------------------------------------------------
-- Rotational Transformation.
-- @section
--------------------------------------------------------------------------------
_Vector.raw_rotate = {
  [1] = 'number',
  [2] = 'number',
  [3] = 'number',
  [4] = 'number',
  [5] = 'number',
  }
function Vector.raw_rotate (deg,dx,dy,ox,oy)
  deg = deg % 360
  if     deg ==   0 then return ox + dx, oy + dy -- north =   0°, dir = 0
  elseif deg ==  90 then return ox - dy, oy + dx -- east  =  90°, dir = 2
  elseif deg == 180 then return ox - dx, oy - dy -- south = 180°, dir = 4
  elseif deg == 270 then return ox + dy, oy - dx -- west  = 270°, dir = 6
  else
    deg = deg2rad(deg) ; local cos_b,sin_b = cos(deg), sin(deg)
    return ox + cos_b*dx - sin_b*dy, oy + sin_b*dx + cos_b*dy
    end  
  end  
--rotates only the /offset/ part of @v
_Vector.rotate_offset_by_degrees = {
  [1] = 'vector', [2] = 'number', }
function Vector.rotate_offset_by_degrees(v,deg)
  v[1],v[2] = Vector.raw_rotate(deg,v[1],v[2],0,0)
  return v end
--rotates the /current origin/ of @v around the given VectorSpecification
_Vector.rotate_origin_by_degrees = {
  [1] = 'vector', [2] = 'number', }
function Vector.rotate_origin_by_degrees(v,deg,...)
  local wx,wy = Vector(...):get_target()
  v[3],v[4] = Vector.raw_rotate(deg,v[3]-wx,v[4]-wy,wx,wy)
  return v end
--rotates both the origin and target of @v around @w  
function Vector.rotate_both_by_degrees (v,deg,...)
  local wx,wy = Vector(...):get_target()
  v[1],v[2] = Vector.raw_rotate(deg,v[1],v[2],0,0)
  v[3],v[4] = Vector.raw_rotate(deg,v[3]-wx,v[4]-wy,wx,wy)
  return v end
  
  
  
-- -------------------------------------------------------------------------- --
-- Rotational Transformation (Wrappers)                                       --
-- -------------------------------------------------------------------------- --

function Vector.rotate_offset_by_direction(v,dir)
  return Vector.rotate_offset_by_degrees(v,Math.dir2deg(dir)) end
function Vector.rotate_origin_by_direction(v,dir,...)
  return Vector.rotate_origin_by_degrees(v,Math.dir2deg(dir),...) end
function Vector.rotate_both_by_direction(v,dir,...)
  return Vector.rotate_both_by_degrees(v,Math.dir2deg(dir),...) end
  
function Vector.rotate_offset_by_orientation(v,ori)
  return Vector.rotate_offset_by_degrees(v,Math.ori2deg(ori)) end
function Vector.rotate_origin_by_orientation(v,ori,...)
  return Vector.rotate_origin_by_degrees(v,Math.ori2deg(ori),...) end
function Vector.rotate_both_by_orientation(v,ori,...)
  return Vector.rotate_both_by_degrees(v,Math.ori2deg(ori),...) end


  
-- -------------------------------------------------------------------------- --
-- UID / Z→N Mapping.                                                         --
-- -------------------------------------------------------------------------- --

--[[
  N = Only positive integers.
  Z = Any positive or negative integer.
  
  Because normal pairing functions are N×N→N a method to map
  negative integers into the positive range is required.
  
  > https://math.stackexchange.com/questions/521029/fast-bijective-mathbbz-times-mathbbz-rightarrow-mathbbz
  > 
  > Essentially all that is needed to turn a bijection p:N²→N
  > into a bijection Z²→Z is composition with a　bijection q:Z→N.
  > Several possible q's exist, but a particularly easy to calculate one is
  > 
  > q(n) = {  2n      n≥0
  >        { -2n-1    n<0
  > 
  > with inverse function
  > 
  > q'(n) = {      n/2    n=~=0 (mod2) ("if n%2==0")
  >         { -(n+1)/2    n=~=1 (mod2) ("if n%2==1")
  > 
  > If you let p be any of the pairing functions you've found
  > from N²→N, then q'(p(q(a),q(b)) will bijectively map Z²→Z
  > (using q to map the arguments into N, then pairing with p and going back to Z with q'.
  ]]
local function ZtoN (n) return (  n    >= 0 ) and (2*n) or (- 2*n -1) end
local function NtoZ (n) return ( (n%2) == 0 ) and (n/2) or (-(n+1)/2) end


-- -------------------------------------------------------------------------- --
-- UID / Z×Z→N Pairing Functions.                                             --
-- -------------------------------------------------------------------------- --

local pair, unpair = {}, {}

--[[
  The spiral UID maps an (x,y) position on any arbitrary(!) sized grid
  to a unique number in a clockwise spiral pattern starting at (0,0).
  It natively supports negative integer coordinates.

  24| 9|10|11|12
  --------------
  23| 8| 1| 2|13
  --------------
  22| 7| 0| 3|14
  --------------
  21| 6| 5| 4|15
  --------------
  20|19|18|17|16

  > https://math.stackexchange.com/questions/1860538/is-there-a-cantor-pairing-function-for-spirals
  > 
  > Given two integers x and y, here's a formula for the
  > position f(x,y) of the pair (x,y) in the spiral sequence.
  > 
  > First let s be whichever of x and y has greater absolute value.
  > (If x and y have the same absolute value, just set s=x.)
  > Then:
  > 
  > f(x,y)= { 4s²−x+y                     if s≥0
  >         { 4s²+(−1)^δ(s,x)*(2s+x+y)    if s<0.
  > 
  > Here δ(s,x) is the Kronecker delta, which is 1 if s=x, and 0 otherwise.
]]
function pair.spiral (x,y)
  local s = (abs(y) > abs(x)) and y or x
  if     s>=0 then return 4*s^2      -x+y
  elseif s==x then return 4*s^2 -(2*s+x+y)
  else             return 4*s^2 +(2*s+x+y)
  end end
function unpair.spiral(uid)
  stop('Not implemented. If you know how to do this please tell me!')
  end

--[[
  The Cantor UID maps (x,y) onto diagonal lines along the N plane.
  As it does not natively support Z the resulting shape after
  remapping Z→N resembles a diamond <> with somewhat erratic
  distribution of UIDs.
  
   0| 1| 3| 6|10
  --------------
   2| 4| 7|11
  -----------
   5| 8|12
  --------
   9|13
  -----
  14
  
  > http://andrewparadis.com/papers/cantor.html
  > 
  > function Tn (n) return 0.5 * (n+1) * n end    --pascals triangular number
  > function Cab (a,b) return Tn(a+b)+a end       --cantor projection
  > 
  > function iC_ab(c_ab)                          --inverse cantor projection
  >   local n = (-1 + sqrt(8*c_ab+1)) / 2
  >   local a = c_ab - 0.5 * (n+1) * n
  >   local b = n-a
  >   return a,b
]]
function pair.cantor(x,y)
  local x,y = ZtoN(x), ZtoN(y)
  return (0.5 * ((x+y)+1) * (x+y) ) +x
  end
function unpair.cantor(uid)
  local n = floor((-1 + sqrt(8*uid+1))/2)
  local x = uid - ( 0.5 * (n+1) * n )
  local y = n-x
  return NtoZ(x),NtoZ(y) end

--[[
  The "elegant" or "square" UID maps (x,y) to ever expansing
  squares. While it does only support N, the square shape
  remains after mapping Z→N even though the distribution order
  of numbers within each square isn't nicely ordered anymore.
  While not visually as nice as the spiral it keeps the UID
  numerically smaller than cantor for the same coordinate space.

   0| 2| 6|12|20
  --------------  
   1| 3| 7|13|21  
  --------------  
   4| 5| 8|14|22  
  --------------  
   9|10|11|15|23  
  --------------  
  16|17|18|19|24

  > http://szudzik.com/ElegantPairing.pdf
  ]]
function pair.square(x,y)
  local x,y = ZtoN(x), ZtoN(y)
  return (x < y) and (y^2+x) or (x^2+x+y)
  end
function unpair.square(uid)
  local x,y
  local b = floor(sqrt(uid))
  local a = (uid-b^2)
  if a < b then x,y = a,b else x,y = b,a-b end
  return NtoZ(x),NtoZ(y) end
  
  
--------------------------------------------------------------------------------
-- UID / Z×Z→N Pairing Wrappers.
-- @section
--------------------------------------------------------------------------------

_Vector.to_offset_uid       = {'vector','nil_or_string'}
_Vector.to_origin_uid       = {'vector','nil_or_string'}
_Vector.to_target_uid       = {'vector','nil_or_string'}
_Vector.set_offset_from_uid = {'vector','natural_number','nil_or_string'}
_Vector.set_origin_from_uid = {'vector','natural_number','nil_or_string'}
_Vector.from_uid            = {         'natural_number','nil_or_string'}
do-->
  local default = 'square'
  --offset → UID
  function Vector.to_offset_uid(v,mode) return pair[mode or default](v:get_offset()) end
  function Vector.to_origin_uid(v,mode) return pair[mode or default](v:get_origin()) end
  function Vector.to_target_uid(v,mode) return pair[mode or default](v:get_target()) end
  --UID → offset,origin,new
  function Vector.set_offset_from_uid(v,uid,mode) v[1],v[2] = unpair[mode or default](uid) return v end
  function Vector.set_origin_from_uid(v,uid,mode) v[1],v[2] = unpair[mode or default](uid) return v end
  function Vector.from_uid(...) return Vector():set_offset_from_uid(...) end
end--<



--------------------------------------------------------------------------------
-- Comparision of Vectors.
-- @section
--------------------------------------------------------------------------------

function Vector.is_offset_equal(v,...)
  local w = Vector(...)
  return (v[1]==w[1]) and (v[2]==w[2])
  end
function Vector.is_origin_equal(v,...)
  local w = Vector(...)
  return (v[3]==w[3]) and (v[4]==w[4])
  end
function Vector.is_target_equal(v,...)
  local wx,wy = Vector(...):get_target()
  local vx,vy = v          :get_target()
  return (vx == wx) and (vy == wy)
  end

  
  
--------------------------------------------------------------------------------
-- Conversion to other formats.
-- @section
--------------------------------------------------------------------------------

--converts a Vector to a fresh differently formatted table
do-->
  local function swap_if_gtr (a,b)
    if a < b then return a,b
    else          return b,a
      end
    end
--an undecorate box like used in data stage prototypes
function Vector.to_box(v)
  local l,r = swap_if_gtr(v[3]+v[1],v[3])
  local t,b = swap_if_gtr(v[4]+v[2],v[4])
  return {{l,t},{r,b}}
  end
  end--<
--a factorio runtime area (includes linked shortcuts)
function Vector.to_area(v)
  local b = v:to_box()
  local lt = {x=b[1][1],y=b[1][2]}
  local rb = {x=b[2][1],y=b[2][2]}
  return {left_top=lt,right_bottom=rb,lt=lt,rb=rb}
  end
--the position of the end-point of the vector
--add factorio {x=,y=} table position
function Vector.to_target_position(v)
  return {x=v[3]+v[1],y=v[4]+v[2]}
  end
--the position of the origin of the vector
function Vector.to_origin_position(v)
  return {x=v[3],y=v[4]}
  end
--an undecorated vector required by some functions like teleport()
function Vector.to_simple_vector(v)
  return {v[3]+v[1],v[4]+v[2]} 
  end
--makes the vector a point (null vector) at the position it was pointing
function Vector.to_point (v,...)
  v[3],v[4] = v[3]+v[1],v[4]+v[2] -- v:set_origin_to_target(v)
  v[1],v[2] = 0,0
  return v end

  
  
-- -------------------------------------------------------------------------- --
-- Alias                                                                      --
-- -------------------------------------------------------------------------- --
--NO! Premade shortcuts only make the code less readable.



-- -------------------------------------------------------------------------- --
-- Meta                                                                       --
-- -------------------------------------------------------------------------- --

do local mt = getmetatable(Vector) 
  mt.__add = Vector.add
  end

  
  
-- -------------------------------------------------------------------------- --
-- Strict Mode                                                                --
-- -------------------------------------------------------------------------- --

-- if STRICT_MODE then
--   --Generate standard vector checks for all non-unique functions.
--   local tbl = { [1] = 'vector' }
--   for name,_ in pairs(Vector) do
--     if not _Vector[name] then _Vector[name] = tbl end
--     end
--   Verificate.wrap_custom(Vector,_Vector,'Vector')
--   Verificate.wrap_custom(getmetatable(Vector),_VectorMeta,'Vector.__mt')
--   end
-- _Vector = nil; assert(_ENV==_LIB)



-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Vector') end
return function() return Vector,_Vector,_uLocale end
