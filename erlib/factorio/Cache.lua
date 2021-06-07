-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Useful cache constructors. For when you don't want to spam
-- global savedata with lots of outdated junk.
--
-- __Warning:__ Incorrect usage of Cache functions will cause desyncs.
-- Read the instructions very carefully.
--
-- @{Introduction.DevelopmentStatus|Module Status}: Experimental 2020-10-31.
--
-- @module Cache
-- @usage
--  local Cache = require('__eradicators-library__/erlib/factorio/Cache')()

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

local Cache,_Cache,_uLocale = {},{},{}

local Error = elreq('erlib/lua/Error')()
local Table = elreq('erlib/lua/Table')()

local table_size = Table.size -- factorio C-side if available
local table_insert, table_remove = table.insert, table.remove


--------------------------------------------------------------------------------
-- AutoCache.
-- @section
--------------------------------------------------------------------------------

----------
-- Creates a new AutoCache.
-- 
-- A __read-only__ table that fills itself on first access. This is intended to 
-- store pre-processed prototype data at runtime without cluttering global
-- savedata with tons of garbage. Less garbage means faster save/load. It also
-- removes the need to migrate old data.
-- 
-- The engine limits access to prototype data to inside events for no good
-- reason. AutoCache provides a comfortable way to transparently fetch the data
-- in the first event you need it.
-- 
-- __Warning:__ Because the constructor is called in a non-deterministic
-- way it will cause desyncs if you try to do anything else except reading
-- startup settings or game.*_prototypes.
-- 
-- @tparam function constructor This is called exactly once with an empty table
-- as the only argument. Is must then fill that table with the desired values.
-- @treturn table the AutoCache'ed table.
--
-- @function Cache.AutoCache
--
-- @usage
--    -- First you need a data collector.
--    local function get_entity_types (data)
--      for k,v in pairs(game.prototypes) do
--        data[v.name] = v.type -- You must store your data in the given table.
--        end
--      return nil -- The return value is not used.
--      end
--
--    -- Then you tell AutoCache to handle the collection for you.
--    local MyData = AutoCache(get_entity_types)
--    
--    -- The collected data can only be used in events.
--    script.on_event(defines.events.on_stuff_happend,function(event)
--      if MyData[event.entity.name] == 'assembling-machine' then
--        DoStuff()
--        end
--      end)
do
  local Stop = Error.Stopper('AutoCache')

  local function read_only_error()
    Stop('Auto Cache','all auto-caches are read-only')
    end
    
  local function fill(self,constructor)
    if not game then Stop('Auto Cache',' not available outside events.\nThis is a bug in YOUR code.') end
    setmetatable(self,nil)
    -- The data has to be stored directly into self by the constructor
    -- to not invalidate external references to the cache table.
    constructor(self)
    -- allowing to read nil can make the cache significantly smaller
    -- respect metatable set by the constructor
    local mt = (debug.getmetatable(self) or {})
    debug.setmetatable(self,mt)
    if not mt.__newindex then mt.__newindex = read_only_error end
    end

--v4.0
Cache.AutoCache = function(constructor)
  if type(constructor) ~= 'function' then
    Stop('Auto Cache',' invalid constructor')
    end
  return setmetatable({},{
    -- This metatable is deleted when *either* __index or __pairs
    -- are called for the first time. Thus *if* either is called
    -- it is guaranteed that the cache is still empty.

    __index = function(self,key)
      fill(self,constructor)
      return self[key]
      end,

    -- Must block all writes before the cache is filled.
    __newindex = read_only_error,
    
    __pairs = function(self)
      fill(self,constructor)
      return pairs(self)
      end,

    __ipairs = function(self)
      fill(self,constructor)
      return ipairs(self)
      end,
      
      --@future: allow clearing the cache to be refilled
      -- on next write. Usecase: rebuilding the cache after data
      -- changes such as on_research_finished for caching a
      -- forces allowed recipes.
      --> requires not deleting the metatable on fill
      --> requires somehow circumventing __pairs.
    -- clear = function(self)
      -- for k in pairs(self) do self[k] = nil end
      -- end,
      
    })
  end
  end


--------------------------------------------------------------------------------
-- TickedCache.
-- @section
--------------------------------------------------------------------------------

--[[------
  A tick-volatile cache. Only contains values that were written during
  the same tick. The main use-case for this is to correlate
  data between events that happen sequentially in the same tick. This is
  __desync safe__ because it has no influence across tick boundaries.
  
  A TickedCache table emulates normal Lua @{table} behavior as best as it can
  but there are a few __important differences__.
 
  1. Lua @{table}, ErLib @{Table} or @{FAPI Libraries table_size} methods are not
     supported. You must use the equivalent methods mentioned on this page.

  *  Lua @{next} is not supported, use standard for-loop @{pairs} or @{ipairs}
     instead.
    
  @function Cache.TickedCache
  @treturn TickedCache an empty ticked cache.
  ]]



----------
-- @{The Length Operator|The Length Operator #} works as it always does.
-- @function TickedCache.__len
-- @treturn int The length of the array part.

----------
-- Standard table methods do not work for ticked caches, use this instead.
-- Behaves the same as @{table.insert}.
-- @tparam[opt] uint64 pos
-- @tparam AnyValue value
-- @function TickedCache:insert

----------
-- Standard table methods do not work for ticked caches, use this instead.
-- Behaves the same as @{table.remove}.
-- @tparam[opt] uint64 pos
-- @function TickedCache:remove

----------
-- Standard table methods do not work for ticked caches, use this instead.
-- The cache is altered *in-place*.
-- Behaves the same as @{Table.map}.
-- @tparam function func
-- @function TickedCache:map

----------
-- Standard table methods do not work for ticked caches, use this instead.
-- @function TickedCache:size
-- @treturn uint64 the total number of NotNil keys in the cache.

----------
-- Standard table methods do not work for ticked caches, use this instead.    
-- Equivalent to `(TC:size() == 0)`.
-- @function TickedCache:is_empty
-- @treturn boolean



----------
-- @type end

----------

  do 
    --todo-> replace by Table:map(mt.cache)

    
  -- Lua next():
  -- The behavior of next is undefined if, during the traversal, you assign any
  -- value to a non-existent field in the table. You may however modify existing
  -- fields. In particular, you may clear existing fields. 
    
  
  -- In-place table map
  -- Old {key -> value} -> New {(f(value,key,table) -> {new_value <- (new_key|key)}}
  local function _map (self,f)
    local r = {}
    if not self then return r end
    -- Behavior of next means it's not possible to add new keys
    -- during iteration. So the keys are first cached.
    local keys = {}
    for k in pairs(self) do
      keys[#keys+1] = k
      end
    -- Undefined behavior if k2 was already in self. Depending on iteration
    -- order it may be overwritten before being processed - or it may not.
    for i=1,#keys do
      local k1 = keys[i]
      local v1 = self[k1]
      if v1 ~= nil then -- might have been deleted in previous k2 assignment
        local v2,k2 = f(v1,k1,self)
        if k2 == nil then
          r[k1] = v2
        else
          r[k1] = nil
          r[k2] = v2
          end
        end
      end
    return r
    end
    
    
  -- Clears/Initializes the cache if it is outdated.
  local function check(mt)
    if mt.tick ~= game.tick then
      mt.cache = {}
      mt.tick  = game.tick
      end
    end

Cache.TickedCache = function()
  local mt = {}
  mt .__index     = function(_,key      ) check(mt); return mt.cache[key]    end
  mt .__newindex  = function(_,key,value) check(mt); mt.cache[key] = value   end
  mt .__pairs     = function(           ) check(mt); return pairs(mt.cache)  end
  mt .__ipairs    = function(           ) check(mt); return ipairs(mt.cache) end
  mt .__len       = function(           ) check(mt); return #mt.cache        end
  mt .__metatable = false
  
  return setmetatable({
    size     = function(       ) check(mt); return table_size(mt.cache)       end,
    is_empty = function(       ) check(mt); return table_size(mt.cache) == 0  end,
    insert   = function(_,...  ) check(mt); return table_insert(mt.cache,...) end,
    remove   = function(_,...  ) check(mt); return table_remove(mt.cache,...) end,
    
    -- bulk-changing the cache any other way is impossible
    -- so this has to work in-place. For creating a new map
    -- Table.map works just fine.
    map      = function(_,f    ) check(mt); mt.cache = _map(mt.cache,f)      end,

    },mt)
  end
  end



-- -----------------------------------------------------------------------------
-- ???.
-- -----------------------------------------------------------------------------


----------
-- Use Table.map instead of custom local implementation for TickedCache.
-- @within Todo
-- @field todo1

-- -------
-- Nothing.
-- @within Todo
-- @field todo1

-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Cache') end
return function() return Cache,_Cache,_uLocale end
