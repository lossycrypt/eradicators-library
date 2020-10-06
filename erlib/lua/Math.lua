-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Description
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

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Math,_Math,_uLocale = {},{},{}


--------------------------------------------------------------------------------
-- Calculation.
-- @section
--------------------------------------------------------------------------------
  

-- -------
-- Nothing.
-- @within Todo
-- @field todo1


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


  
  
-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Math') end
return function() return Math,_Math,_uLocale end
