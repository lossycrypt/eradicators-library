-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable

--------------------------------------------------
-- Creates wrapper functions that store arguments for later use.
-- Contrary to [currying](https://en.wikipedia.org/wiki/Currying) this
-- does not generate intermediate  results.
--
-- @todo 
--
-- @submodule Meta
-- @usage
--  local Closurize = require('__eradicators-library__/erlib/lua/Meta/Closurize')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Eradicators Library                                                        --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
local unpack = table.unpack

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

-- local Closurize,_Closurize,_uLocale = {},{},{}

-- local String = elreq('erlib/lua/String')()
local Twice  = elreq('erlib/lua/Replicate')().Twice

-- Hardcoded to resolve circular dependency Meta <-> String
local String_UPPER_ARGS = 'A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z'

--------------------------------------------------------------------------------
-- Closurize
-- @section
--------------------------------------------------------------------------------

----------
-- Creates a function wrapper with partially fullfilled arguments.
-- 
-- @function Closurize
-- @tparam function f the function to be wrapped
-- @tparam AnyValue ... the first k arguments of f(...) that the created
-- closure will store.
-- @treturn function the wrapper that takes the remaining arguments before
-- calling f.
-- 
-- @usage
--   -- create a closure that will always use the same first three arguments
--   local f1 = function(a,b,c,d,e,f,g) print(a,b,c,d,e,f,g) end
--   local f2 = Closurize(f1,'clo','sur','ized')
--   
--   -- call it with the remaining 4
--   print(f2('var',nil,'iable',nil))
--   > clo sur ized var nil iable nil
--   
--   -- or call it with fewer, leaving the rest empty
--   print(f2(nil,'variable'))
--   > clo sur ized nil variable nil nil



-- Iterative implementation (slower)
-- 
-- local function Closurize_old (f,...)
--   local args1,k1 = {...},select('#',...)
--   return function(...)
--     local args2,k2 = {...},select('#',...)
--     -- Table reuse is safe because fixed index
--     -- range guarantees overwriting of previous arguments.
--     for i=1,k2 do args1[k1+i] = args2[i] end
--     return f(unpack(args1,1,k1+k2))
--     end
--   end


-- Load-string implementation
-- => simple upvalue access is cheaper
local function Closurize(f,...)
  local n = select('#',...)
  local g = ([[
    local f,%s=...
    return function(...) return f(%s,...) end
    ]])
    :format(Twice(String_UPPER_ARGS:sub(1,2*n-1)))
  return load(g,nil,'t',{})(f,...)
  end


-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Closurize') end
return function() return Closurize,nil,nil end
