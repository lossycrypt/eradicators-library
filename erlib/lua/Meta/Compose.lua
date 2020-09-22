-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Compose function chains.
--
-- @submodule Meta
-- @usage
--  local Compose = require('__eradicators-library__/erlib/lua/Meta/Compose')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
local unpack = table.unpack

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

-- local Compose,_Compose,_uLocale = {},{},{}


--------------------------------------------------------------------------------
-- Compose
-- @section
--------------------------------------------------------------------------------

----------
-- Generates a closurized function chain.
--
-- Takes any number of functions and binds them into
-- a single function that applies all functions in
-- reverse order given.
--
-- Functions are applied "from right to left".
-- Compose(a,b,c)(x) == a(b(c(x)))
--
-- @tparam function ... the functions you want to apply in reverse order.
-- @treturn AnyValue the result of the final function call
--
-- @usage
--   local a  = function(x) return 2+x end
--   local b  = function(x) return 2*x end
--   local c  = function(x) return 2/x end
--   local fc = Compose(a,b,c)
--   print(fc(10)) -- a(b(c(x)))
--   > 2.4
--
-- @usage
--   -- each function recieves all return values of the previous function
--   local d  = function(z,y,x) return 2+x,z,y,x end
--   local e  = function(  y,x) return 2*x,  y,x end
--   local f  = function(    x) return 2/x,    x end
--   local fc = Compose(d,e,f)
--   local r,z,y,x = fc(10) -- d(e(f(x)))
--   print(x,y,z,r) 
--   > 10  0.2  20  12
--
local function Compose(...)
  local funcs,n = {...}, select('#',...)
  return function(...)
    local r = {...}
    for i=n,1,-1 do r = {funcs[i](unpack(r))} end
    return unpack(r) 
    end
  end
  
  

-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Compose') end
return function() return Compose,_Compose,_uLocale end
