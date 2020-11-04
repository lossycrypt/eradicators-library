-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Description
--
-- @{Introduction.DevelopmentStatus|Module Status}: Work in progress.
--
-- @module Math
-- @usage
--  local Math = require('__eradicators-library__/erlib/lua/Math')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --

local table_unpack
    = table.unpack

local floor = math.floor
    
-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Math,_Math,_uLocale = {},{},{}

-- -------
-- Nothing.
-- @within Todo
-- @field todo1



--------------------------------------------------------------------------------
-- Calculation.
-- @section
--------------------------------------------------------------------------------
  
----------
-- The factorial n! is 1\*2\*3\*...\*n.
-- 
-- @tparam Integer n Negative input means -1\*n!.
-- 
-- @treturn Integer
-- 
function Math.factorial(n)
  -- negative factorial is undefined
  -- but it's trivial to treat it as -1*n!
  local sign = (n<0) and -1 or 1
  local r = 1 -- factorial of zero equals 1
  for i=1,n*sign do r=r*i end
  return r*sign
  end

  
  
--------------------------------------------------------------------------------
-- Misc.
-- @section
--------------------------------------------------------------------------------

----------
-- Limits an input to a given range.
-- A < n < B, or A > n > B.
--
-- @tparam number limitA
-- @tparam number number
-- @tparam number limitB
--
-- @treturn number The given number or one of the limits.
function Math.limit_range(limitA, number, limitB) 
  --@future: rename "clamp"?
  local low  = (limitA < limitB) and limitA or limitB
  local high = (limitA == low  ) and limitB or limitA
  if low  > number then return low   end --too small
  if high < number then return high  end --too large
  return number                          --just fine
  end
  
----------
-- Conditionally swaps two variables.
--
-- @tparam number a
-- @tparam number b
--
-- @treturn number The smaller number.
-- @treturn number The bigger number.
function Math .swap_if_gtr (a,b)
  if a < b then return a,b else return b,a end
  end
  
  
  
--------------------------------------------------------------------------------
-- Conversion of Rotation.
--
-- Converts between anglular units.  
-- All methods take a single number argument.  
-- All formats use 0 has up/north.  
--
-- __ori:__ FactorioOrientation. A @{UnitInterval}.  
-- __dir:__ FactorioDirection. A @{FOBJ defines direction}, an @{Integer} between 0 and 7.  
-- __deg:__ Degrees.  
-- __rad:__ Radians.  
--
-- __Note:__ Conversion _to_ FactorioDirection will be rounded to nearest direction.
--
-- @section
--------------------------------------------------------------------------------

--- @function Math.ori2dir

--- @function Math.ori2deg

--- @function Math.deg2ori

--- @function Math.deg2dir

--- @function Math.dir2ori

--- @function Math.dir2deg

--- @function Math.deg2rad

--- @function Math.rad2deg

-- Derived from Vector rotational math.
-- Convert between angle units orientation, direction, degrees, radians
Math.ori2dir = function(ori) return floor  (ori*8 + 0.5) % 8       end
Math.ori2deg = function(ori) return         ori     *360           end
Math.deg2ori = function(deg) return        (deg%360)/360           end
Math.deg2dir = function(deg) return floor(((deg%360)/360)*8+0.5)%8 end
Math.dir2ori = function(dir) return        dir/8                   end
Math.dir2deg = function(dir) return       (dir/8)   *360           end
Math.deg2rad = math.rad
Math.rad2deg = math.deg



-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Math') end
return function() return Math,_Math,_uLocale end
