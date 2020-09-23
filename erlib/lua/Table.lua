-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Description
--
-- @module Table
-- @usage
--  local Table = require('__eradicators-library__/erlib/lua/Table')()
  
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

local Table,_Table,_uLocale = {},{},{}


Table.size = (
  -- factorio C-side counting is faster if available.
  (flag.IS_FACTORIO and table_size)
  and function(self) return table_size(self) end
  or  function(self) local n = 0 for _ in pairs(self) do n=n+1 end return n end
  )

----------
-- map
function Table:map(f) -- see Cache.TickedCache

  --table {key -> value} -> new_table {new_key -> (f(value,key,table) -> new_value,new_key)}
  
  -- Replacing a table with it's own map in one call is too expensive.
  -- And can be emulated by Table(tbl):clear():merge(Table(tbl):map(f))
  
  -- Also the most common usecase is to use the map seperately.

  
  local r = {}; if not self then return r end
  for k,v in pairs(self) do
    local v2,k2 = f(v,k,self)
    if k2 ~= nil then k = k2 end
    r[k] = v2
    end
  return r
  end

  

--------------------------------------------------------------------------------
-- Section
-- @section
--------------------------------------------------------------------------------

----------
-- Nothing.
-- @within Todo
-- @field todo1

-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Table') end
return function() return Table,_Table,_uLocale end
