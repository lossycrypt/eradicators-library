-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable

--------------------------------------------------
-- Description
--
-- @submodule Iter
-- @usage
--  local dpairs = require('__eradicators-library__/erlib/lua/Iter/dpairs')()
  
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

local stop       = elreq('erlib/lua/Error')().Stopper('dpairs')

local Verificate   = elreq('erlib/lua/Verificate')()
local isPlainTable = Verificate.isType.PlainTable
local verify       = Verificate.verify

local SKIP         = ercfg.SKIP

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

--[==[----
Deep_pairs iterates all sub-tables in a single for-loop.

This is a non-fixed-path-length fork of @{Iter.ntuples}.

With default options every @{key -> value} pair is iterated exactly once.

@usage
  -- Setup the example data.
  local players = {
    yurie = {
      items = {'iron-plate', 'copper-plate'},
      ammo  = {'piercing'  , 'uranium'     },
      play_time = 9001,
      }, 
    tarou = {
      items = {'iron-gear' , 'copper-gear' },
      ammo  = {},
      play_time = 42,
      },
    akira = {
      items = {},
      ammo  = {'exploding' , 'magic'       },
      play_time = 7,
      },
    }

  -- Introduce some duplicate table references.
  players.michiru           = players.tarou
  players.akira.ammo['ref'] = players.yurie.ammo
    
  -- And an easy to read format.
  local function format_row(key, value, path, is_duplicate)
    return ('%-28s %-10s %-13s %-5s')
      :format(Hydra.line(path), key, value, is_duplicate and '(duplicate)' or '')
    end

@usage
  -- Example 1: Path. (Also notice that duplicates are ignored by default.)
        
    for key, value, tbl, path in
      Iter.dpairs(players, {include_path = true}) do
      print(format_row(key, value, path))
      end

  --[path]                       [key]      [value]            
  > {"michiru", "items", 1}      1          iron-gear          
  > {"michiru", "items", 2}      2          copper-gear        
  > {"michiru", "play_time"}     play_time  42                 
  > {"akira", "ammo", 1}         1          exploding          
  > {"akira", "ammo", 2}         2          magic              
  > {"akira", "play_time"}       play_time  7                  
  > {"yurie", "ammo", 1}         1          piercing           
  > {"yurie", "ammo", 2}         2          uranium            
  > {"yurie", "items", 1}        1          iron-plate         
  > {"yurie", "items", 2}        2          copper-plate       
  > {"yurie", "play_time"}       play_time  9001     

@usage
  -- Example 2: Duplicates.
  
  for key, value, tbl, path, is_duplicate in
    Iter.dpairs(players, {include_path = true, include_duplicates=true}) do
    print(format_row(key, value, path, is_duplicate))
    end
    
  --[path]                       [key]      [value]            
  > {"michiru", "items", 1}      1          iron-gear          
  > {"michiru", "items", 2}      2          copper-gear        
  > {"michiru", "play_time"}     play_time  42                 
  > {"akira", "ammo", 1}         1          exploding          
  > {"akira", "ammo", 2}         2          magic              
  > {"akira", "ammo", "ref", 1}  1          piercing      -- notice pairs-based
  > {"akira", "ammo", "ref", 2}  2          uranium       -- random order
  > {"akira", "play_time"}       play_time  7                  
  > {"yurie", "ammo", 1}         1          piercing      (duplicate)
  > {"yurie", "ammo", 2}         2          uranium       (duplicate)
  > {"yurie", "items", 1}        1          iron-plate         
  > {"yurie", "items", 2}        2          copper-plate       
  > {"yurie", "play_time"}       play_time  9001               
  > {"tarou", "items", 1}        1          iron-gear     (duplicate)
  > {"tarou", "items", 2}        2          copper-gear   (duplicate)
  > {"tarou", "play_time"}       play_time  42            (duplicate)
    
@usage
  -- Example 3: Recursion.
  
  -- Let's introduce a loop...
  players.tarou.loop = players
  
  -- and try the same command as in Example 2...
  for key, value, tbl, path, is_duplicate in
    Iter.dpairs(players, {include_path = true, include_duplicates=true}) do
    print(format_row(key, value, path, is_duplicate))
    end
  
  > Error!
  > Table recursion detected but now allowed.
  > path: {"michiru", "loop"}
  
  -- Notice that "michiru" and "tarou" reference the same sub-table.
  -- The error message reports whichever path it found first.
  
  -- Now let't try again with irgnore mode...
  for key, value, tbl, path, is_duplicate in
    Iter.dpairs(players, {
      include_path = true, include_duplicates=true, ignore_recursion = true
      })
    do
    print(format_row(key, value, path, is_duplicate))
    end
    
  > --[[This produces output identical to Example 2.]]
  
@tparam[opt] table tbl The input table.
@tparam[opt] table opt (@{table}) Options (_optional_).
@tparam[opt=false] boolean opt.include_path Activates the fourth return value.
@tparam[opt=false] boolean opt.include_duplicates When this is false and @tbl
has multiple references to the same sub-table, then only the first reference
to each sub-table will be iterated and all futher reference skipped. When
this is true all references will be iterated normally and the fifth return
value will be true for all iterations except the first.
@tparam[opt=false] boolean opt.ignore_recursion Silently skip recursive
sub-tables instead of raising an error.

@treturn NotNil `key`
@treturn NotNil `value`
@treturn table `table ` This is the sub-table that contains the returned @{key -> value} pair.
@treturn Table.TablePath|nil `path` This is the full path to the value
inside the input table @tbl.
@treturn boolean|nil `is_duplicate`
]==]
local function dpairs(tbl, opt)
  -- This function is a slightly modified version of Iter.ntuples
  verify(tbl, 'tbl|nil', 'Input was not table.')
  verify(opt, 'nil|tbl', 'Options was not table.')
  if tbl == nil then return SKIP end
  local include_path       = ((true == (opt or {}).include_path) or nil)
  local include_duplicates =  (true == (opt or {}).include_duplicates)
  local ignore_recursion   =  (true == (opt or {}).ignore_recursion)
  --
  local pairs, type, table_unpack
      = pairs, type, table.unpack
  --
  local i = 1
  local next, tbl, key = pairs(tbl)
  local next, tbl, key = {next}, {tbl}, {key}
  local seen, is_seen = {[tbl[i]] = true}, false
  local value
  --
  local function is_loop()
    for j=1, i-1 do if tbl[j] == value then
      if (not ignore_recursion) then
        stop('Table recursion detected but now allowed.\npath: ', key)
      end
    return true end end end
  --
  return function(); repeat
    key[i], value = next[i](tbl[i], key[i])
    if value == nil then; i = i - 1
    else; i = i + 1
      if not isPlainTable(value) then; i = i - 1
        return key[i], value, tbl[i]
        , include_path and {table_unpack(key, 1, i)}, is_seen
      elseif seen[value]
      and ((not include_duplicates) or is_loop()) then
        i = i - 1
      else
        is_seen = not not seen[value] -- unchanged till next subtable
        next[i],  tbl[i],  key[i] = pairs(value)
        seen[tbl[i]], seen[value] = true, true
        end
      end
    until i == 0 end
  end

 
-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.dpairs') end
return function() return dpairs,nil,nil end
