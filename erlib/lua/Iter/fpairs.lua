-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable

--------------------------------------------------
-- Description
--
-- @submodule Iter
-- @usage
--  local fpairs = require('__eradicators-library__/erlib/lua/Iter/fpairs')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
-- local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
-- local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

local type,pairs,next = type,pairs,next

-- -------------------------------------------------------------------------- --
-- Eradicators Library                                                        --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
-- local stop   = elreq('erlib/lua/Error')().Stopper('fpairs')

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

----------
-- Returns only @{key->value} pairs for which f(value,key,tbl) returns true.
-- Other values in the table are simply skipped during iteration.
-- 
-- @tparam table tbl The table to be iterated.
-- @tparam function f The filter function f(value,key,table).
-- 
-- @treturn A __stateless__ iterator function.
-- 
-- @usage
--   -- For example if you've got stored LuaEntity references
--   script.on_event(defines.events.on_built_entity,function(event)
--      if event.entity.name == 'MyEntity' then
--        global.MyEntityData[event.entity.unit_number] = {entity=event.entity}
--        end
--      end)
-- 
--   -- And want to remove the invalid ones. (Ignores key+tbl arguments)
--   local filter = function(data,_,_) return not data.entity.valid end
--   
--   for unit_number,_ in pairs(global.MyEntityData,filter) do
--      global.MyEntityData[unit_number] = nil
--      end
-- 
local function fpairs(tbl,f)
  local next,_,start = pairs(tbl) --respect custom iterator
  local function _iter(tbl,k)
    local v
    repeat k,v = next(tbl,k) until (k == nil) or f(v,k,tbl)
    return k,v --will both be nil at the end of the table
    end
  return _iter, tbl, start --start is usually <nil>
  end





-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Iter.fpairs') end
return function() return fpairs end
