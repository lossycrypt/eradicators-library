-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable

--------------------------------------------------
-- Description
--
-- @submodule Iter
-- @usage
--  local sync_tuples = require('__eradicators-library__/erlib/lua/Iter/ntuples')()
  
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
-- Locals / Init                                                              --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --

-- local stop       = elreq('erlib/lua/Error')().Stopper('ntuples')

local Verificate = elreq('erlib/lua/Verificate')()
local verify     = Verificate.verify

local SKIP       = ercfg.SKIP

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

----------
-- Iterates n-nested sub-tables in a single for-loop.
--
-- Internally uses @{LMAN pairs ()} to get each
-- sub-table's __pairs metamethod or @{LMAN next ()}.
--
-- If a sub-table does not contain enough sub-tables to reach
-- depth n it will be ignored. Likewise any non-table values
-- at depth < n will also be ignored.
-- 
-- Returns every possible path of length n. This might
-- lead to __unexpected results__ when the input table is __recursive__
-- or has multiple references to the same sub-table.
--
-- See also @{Metatables and Metamethods}.
--
-- @tparam NaturalNumber n The length of the desired tuple. Values 1 and 2
-- return pairs(tbl) instead.
-- @tparam[opt] table tbl 
--
-- @treturn function|nil There are three cases:
--
-- When tbl == nil returns @{Filter.SKIP}.  
-- When n <= 2 returns the three result values of calling pairs(tbl).  
-- When n >  2 returns a stateful iterator function and nothing else.  
--
-- @usage
--   local players = {
--     yurie = {
--       items = {'iron-plate', 'copper-plate'},
--       ammo  = {'piercing'  , 'uranium'     },
--       play_time = 9001, -- ignored because it's not a table.
--       }, 
--     tarou = {
--       items = {'iron-gear', 'copper-gear'},
--       ammo  = {}, -- ignored because it's not deep enough.
--       play_time = 42,
--       },
--     akira = {
--       items = {},
--       ammo  = {'exploding', 'magic'      },
--       play_time = 7,
--       },
--     }
--  
--   for nickname, type, item_index, item_name in Iter.ntuples(4, players) do
--     print(nickname, type, item_index, item_name)
--     end
--  
--   > akira  ammo   1  exploding
--   > akira  ammo   2  magic
--   > yurie  ammo   1  piercing
--   > yurie  ammo   2  uranium
--   > yurie  items  1  iron-plate
--   > yurie  items  2  copper-plate
--   > tarou  items  1  iron-gear
--   > tarou  items  2  copper-gear
--
local function ntuples(n, tbl)
  -- Keep it simple and fast. This function shall never
  -- have additional options or recursive table handling.
  verify(n, 'NaturalNumber', 'Invalid tuple count.')
  if tbl == nil then return SKIP end
  if n   <=   2 then return pairs(tbl) end
  --
  local pairs, type, table_unpack
      = pairs, type, table.unpack
  --
  local i, max_i = 1, n-1
  local next, tbl, key = pairs(tbl)
  local next, tbl, key = {next}, {tbl}, {key}
  --
  return function(); repeat
    key[i], key[n] = next[i](tbl[i], key[i]) -- key[n] == value
    if key[n] == nil then; i = i - 1
    elseif i < max_i then; i = i + 1
      if type(key[n]) ~= 'table' then; i = i - 1 -- the road is blocked!
      else next[i], tbl[i], key[i] = pairs(key[n]) end
    else return table_unpack(key) end
    until i == 0 end
  end
 
 
-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.ntuples') end
return function() return ntuples,nil,nil end
