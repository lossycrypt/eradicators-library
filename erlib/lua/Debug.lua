-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Manipulation of upvalues and locals.
--
-- @module Debug
-- @usage
--  local Debug = require('__eradicators-library__/erlib/lua/Debug')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Debug,_Debug,_uLocale = {},{},{}


--------------------------------------------------------------------------------
-- Section
-- @section
--------------------------------------------------------------------------------

----------
-- This unique empty table is used as a value by @{Debug.get_upvalue_tree} to signal
-- that the real value was not retrieved because the depth limit has been reached.
--
-- @field Debug.TOO_DEEP
-- @usage if value == Debug.TOO_DEEP then --[[ignore value]] end
Debug.TOO_DEEP = {}
  
----------
-- __!WARNING! Unfinished. Only use for testing.__
-- 
-- Recursively explores the upvalues of a @{function} or @{table}.  
--  
-- @tparam function|table obj the starting point of the exploration
-- @tparam[opt=2] NaturalNumber depth The maximum deepth to explore. Any values
-- deeper than this will instead be replaced with @{Debug.TOO_DEEP}. There is no
-- protection against infinite loops so be careful not to set it too high.
-- @tparam[opt=true] boolean include_everything Should numbers, strings etc be
-- in the output table? If false then only functions and tables will be included.
-- @treturn table|nil A table of upvalues. Any value that would be a function is
-- replaced by a table {\_\_f=TheFunction,\_\_up={The,Up,Values}}.
-- @usage 
--    local a,b,three = 'a','b',3
--    local d = {a,b}
--    local f1 = function() return a,b end
--    local f2 = function() return f1,three,d end
--    print(
--      erlib.Hydra.lines(
--        erlib.Debug.get_upvalue_tree({k1=f1,k2=f2},3,false)
--        ,{indentlevel=5}
--        )
--      )
--
--    > {
--    >   k1 = {
--    >     __f = function()end,
--    >     __up = {
--    >       a = "a",
--    >       b = "b"
--    >     }
--    >   },
--    >   k2 = {
--    >     __f = function()end,
--    >     __up = {
--    >       d = {
--    >         {}, -- Debug.TOO_DEEP
--    >         0 --[[ self.k2.__up.d[1] ]]
--    >       },
--    >       f1 = {
--    >         __f = 0 --[[ self.k1.__f ]],
--    >         __up = {
--    >           a = 0 --[[ self.k2.__up.d[1] ]],
--    >           b = 0 --[[ self.k2.__up.d[1] ]]
--    >         }
--    >       },
--    >       three = 3
--    >     }
--    >   }
--    > }
function Debug.get_upvalue_tree(obj,depth,include_everything)
  ---@fixme "seen" doesn't work, still recurses way too deep
--[[DEBUG CMD

print(
  erlib.Hydra.lines(
    erlib.Debug.get_upvalue_tree(erlib.Zip,40,true)
    ,{indentlevel=99}
    )
  )
  
]]
  
  
  local _sub,_gup
  local seen = {}

  function _sub(v,d)
    if seen[v]~=nil then return seen[v] end
    local x = _gup(v,d,{})
    if type(v)=='function' then x={__f=v,__up=x} end
    seen[v] = x
    return x
    end
    
  function _gup(o,d,r)
    --depth still ok?
    if d <= 0 then return Debug.TOO_DEEP else d=d-1 end
    if seen[o] ~= nil then return seen[o] end
    --tables 
    if type(o) == 'table' then
      for k,v in pairs(o) do
        r[k]=_sub(v,d)
        end
      seen[o] = r
      return r
    elseif type(o) == 'function' then
      -- local x = {}
      local i = 0
      while true do i=i+1
        local k,v = debug.getupvalue(o,i)
        if k==nil then break end
        r[k]=_sub(v,d)
        end
      seen[o] = r
      return r
    -- elseif not (include_everything) then
      -- return nil
    else
      seen[o] = o
      return o
      end
    end
  --ignore bullshit
  if not (type(obj)=='function' or type(obj)=='table') then
    return nil
    end
  --recurse
  return _gup(obj,(depth or 2),{})
  end
  
-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Debug') end
return function() return Debug,_Debug,_uLocale end
