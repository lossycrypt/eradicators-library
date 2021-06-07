-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable

--------------------------------------------------
-- Description
--
-- @submodule Iter
-- @usage
--  local sriapi = require('__eradicators-library__/erlib/lua/Iter/sriapi')()
  
--[[ Lua Behavior:

  + for-do-loop only gives *exactly the first* return value back
    to the iterator function on each loop.

    
  + native pairs behaves like this:
  
    local function lua_pairs(tbl)
      local mt = getmetatable(tbl)
      if mt.__pairs then
        -- first three only!
        return (function(_1,_2,_3) return _1,_2,_3 end)(mt.__pairs(tbl))
      else
        return next, tbl, nil
        end
      end
  ]]

-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Eradicators Library                                                        --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --


-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

----------
-- Inverse @{LMAN ipairs ()}.
--
-- @tparam DenseArray arr
-- @treturn function f() A __stateful__ iterator. When the iterator is called f()
-- it returns (value, index) of the next entry in the array. Note:
-- this means that __the order of the return values is also inversed__
-- compared to normal ipairs().
--
-- The `__ipairs` methamethod of arr is __ignored__ by this iterator.
--
-- @usage
--   for v,i in sriapi({'a','b','c','d','e'}) do print(('i=%s, v=%s'):format(i,v)) end
--   > i=5, v=e
--   > i=4, v=d
--   > i=3, v=c
--   > i=2, v=b
--   > i=1, v=a
--
local function sriapi(arr)
  -- No point in making this stateless. Direct array access
  -- is faster when manual index management is required.
  local i = #arr + 1
  -- For loops break when the *first* return value becomes nil,
  -- thus it's easier to return the value first and the index second.
  return function() i = i - 1 return arr[i], i end
  end

 
-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.sriapi') end
return function() return sriapi,nil,nil end
