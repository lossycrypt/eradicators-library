-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable

--------------------------------------------------
-- Description
--
-- @submodule Iter
-- @usage
--  local ntuples = require('__eradicators-library__/erlib/lua/Iter/ntuples')()
  
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

-- local stop       = elreq('erlib/lua/Error')().Stopper('ntuples')

local Verificate   = elreq('erlib/lua/Verificate')()
local isPlainTable = Verificate.isType.PlainTable
local verify       = Verificate.verify

local SKIP         = ercfg.SKIP

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

----------
-- Iterates n-nested sub-tables in a single for-loop.
--
-- Returns every possible path of length n-1 and its value. This might
-- lead to __unexpected results__ when the input table is __recursive__
-- or has multiple references to the same sub-table.  
-- See also @{Iter.dpairs}.
--
-- Internally uses @{LMAN pairs ()} to get each
-- sub-table's __pairs metamethod or @{LMAN next ()}.  
-- See also @{Metatables and Metamethods}.
--
-- Every sub-table must be at least of depth `n-1` or 
-- the loop will crash. Completely empty sub-tables are
-- the only exception and will instead be ignored.
--
-- @tparam NaturalNumber n The length of the desired tuple. The returned tuple
-- is of the form `("Key 1", "Key 2", ..., "Key n-1", "Value")`, thus the value is
-- included in the length of the touple.
-- @tparam[opt] table tbl The parent table to iterate into.
--
-- @treturn function There are three cases:
--
-- When tbl == nil returns @{Filter.SKIP}.  
-- When n <= 2 returns the three values returned by @{LMAN pairs (tbl)}.  
-- When n >  2 returns a stateful ntuples-iterator function and nothing else.  
--
-- @usage
--   local players = {
--     yurie = {
--       items = {'iron-plate', 'copper-plate'},
--       ammo  = {'piercing'  , 'uranium'     },
--       }, 
--     tarou = {
--       items = {'iron-gear' , 'copper-gear' },
--       ammo  = {}, -- empty table is ignored because it's not deep enough.
--       },
--     akira = {
--       items = {},
--       ammo  = {'exploding' , 'magic'       },
--       },
--     }
--  
--   for nickname, type, item_index, item_name in Iter.ntuples(4, players) do
--     print(nickname, type, item_index, item_name)
--     end
--  
--   > yurie items 1 iron-plate
--   > yurie items 2 copper-plate
--   > yurie ammo  1 piercing
--   > yurie ammo  2 uranium
--   > tarou items 1 iron-gear
--   > tarou items 2 copper-gear
--   > akira ammo  1 exploding
--   > akira ammo  2 magic
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
  local i, max_i = 1, n-1 -- i is depth
  local next, tbl, key = pairs(tbl)
  local next, tbl, key = {next}, {tbl}, {key}
  
  -- V1: with table check.
  -- return function(); repeat
  --   key[i], key[n] = next[i](tbl[i], key[i]) -- key[n] == value
  --   if key[n] == nil then; i = i - 1
  --   elseif i < max_i then; i = i + 1
  --     if not isPlainTable(key[n]) then; i = i - 1 -- the road is blocked!
  --     else next[i], tbl[i], key[i] = pairs(key[n]) end
  --   else return table_unpack(key) end
  --   until i == 0 end
  
  -- V2: faster without table check.
  return function(); repeat
    key[i], key[n] = next[i](tbl[i], key[i]) -- key[n] == value
    if key[n] == nil then; i = i - 1 -- end-of-array check
    elseif i < max_i then; i = i + 1
      -- Let it crash here if key[n] is not a table.
      -- Table check was too expensive.
      next[i], tbl[i], key[i] = pairs(key[n])
    else return table_unpack(key) end
    until i == 0 end
  end

 
-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.ntuples') end
return function() return ntuples,nil,nil end
