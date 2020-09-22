-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Useful cache constructors. For when you don't want to spam
-- global savedata with lots of outdated junk.
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
-- Locals / Init                                                              --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Cache,_Cache,_uLocale = {},{},{}

local Error = elreq('erlib/lua/Error')()

-- -----------------------------------------------------------------------------
-- TickedCache
-- -----------------------------------------------------------------------------

--[[------
  A tick-volatile cache. Only contains values that were written during
  the same tick. The main use-case for this is to correlate
  data between events that happen sequentially in the same tick. This is
  __desync safe__ because it has no influence across tick boundaries.
  
  A TickedCache table emulates normal Lua @{table} behavior as best as it can
  but there are a few __important differences__.
 
  * You can not store a TickedCache in global savedata. It will just store
    an empty table.
 
  * Storing the iterator from a pairs(TickedCache) call is not desync safe.
    You should only use standard `for k,v in pairs(TickedCache)`
    loops for iteration.
 
  * You can not use @{table} or @{Table} module functions on a TickedCache. Instead
    you can use `TC:insert(value)`, `TC:remove(value)` and `TC:map(func)`.

  * table_size(TickedCache) is always 0. Use TC:size() or TC:is_empty() instead.
    The # length operator works as usual, including the undefined behavior
    that happens when you use it on non-@{array}s.

    
  * table_size can not be directly called on a tc.
    instead use tc:size() or tc:is_empty(), the # operator
    works as usual on the array part.
  
  @function Cache.TickedCache
  @treturn TickedCache an empty ticked cache.
  ]]

----------
-- When you call `TickedCache()` you get a new TickCache object.
-- @type TickedCache

----------
-- Standard table methods do not work for ticked caches.
-- Insert at the end.
-- @tparam AnyValue value
-- @function TickedCache:insert

----------
-- Standard table methods do not work for ticked caches.
-- @tparam AnyValue key
-- @function TickedCache:remove

----------
-- Standard table methods do not work for ticked caches.
-- @tparam function func
-- @function TickedCache:map

----------
-- Standard table methods do not work for ticked caches.
-- @function TickedCache:size
-- @treturn int the total number of NotNil keys in the cache.

----------
-- Standard table methods do not work for ticked caches.
-- @function TickedCache:is_empty
-- @treturn boolean

----------
-- The length operator # works as it always does.
-- @function TickedCache.__len
-- @treturn int The length of the array part. Undefined behavior if not an @{array}.


----------
-- @type end

----------

  do 
  --table {key -> value} -> new_table {new_key -> (f(value,key,table) -> new_value,new_key)}
  local function Tmap (self,f)
    -- local backup copy while Table is being reworked.
    local r = {}; if not self then return r end
    for k,v in pairs(self) do
      local v2,k2 = f(v,k,self)
      if k2 ~= nil then k = k2 end
      r[k] = v2
      end
    return r
    end

  local function check(mt)
    if mt.tick ~= game.tick then
      mt.cache = {}
      mt.tick = game.tick
      end
    end
-- local function ticked_cache()
Cache.TickedCache = function()
  local mt = {}
  mt .__index     = function(_,key      ) check(mt); return mt.cache[key]   end
  mt .__newindex  = function(_,key,value) check(mt); mt.cache[key] = value  end
  mt .__pairs     = function()            check(mt); return pairs(mt.cache) end
  mt .__len       = function()            check(mt); return #mt.cache       end
  mt .__metatable = false
  
  return setmetatable({
    insert   = function(_,value) check(mt); mt.cache[#mt.cache+1] = value    end,
    map      = function(_,f    ) check(mt); mt.cache = TMap(mt.cache,f)      end,
    remove   = function(_,key  )          ; mt.cache[key] = nil              end,
    is_empty = function()        check(mt); return table_size(mt.cache) == 0 end, --deprecate?, trivial operation
    size     = function()        check(mt); return table_size(mt.cache)      end,
    },mt)
  end
  end



-- -----------------------------------------------------------------------------
-- AutoCache
-- -----------------------------------------------------------------------------

----------
-- Creates a new AutoCache.
-- 
-- A read-only table that fills itself on first access. This is intended to 
-- store pre-processed prototype data at runtime without cluttering global
-- savedata with tons of garbage. Less garbage means faster save/load. It also
-- removes the need to migrate old data.
-- 
-- The engine limits access to prototype data to inside events for no good
-- reason. AutoCache provides a comfortable way to transparently fetch the data
-- in the first event you need it.
-- 
-- @tparam function constructor This is called exactly once with an empty table
-- as the only argument. Is must then fill that table with the desired values.
-- @treturn table An AutoCache instance.
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
  local Stop  = Error.Stopper('AutoCache')

  local function read_only_error() Stop('Auto Cache','all auto-caches are read-only') end
    
  local function fill(self,cache_constructor)
    if not game then Stop('Auto Cache','not available outside events') end
    setmetatable(self,nil)
    -- The data has to be stored directly into self by the constructor
    -- to not invalidate external references to the cache table.
    cache_constructor(self)
    
    -- allowing to read nil can make the cache significantly smaller
    -- respect metatable set by the constructor
    local mt = (debug.getmetatable(self) or {});
    debug.setmetatable(self,mt)
    if not mt.__newindex then mt.__newindex = read_only_error end
    
    -- print(Slines(self))
    end

--v4.0
  -- local function auto_cache(cache_constructor)
Cache.AutoCache = function(cache_constructor)
  if type(cache_constructor) ~= 'function' then Stop('Auto Cache','invalid constructor') end
  return setmetatable({},{
    -- This metatable is deleted when *either* __index or __pairs
    -- are called for the first time.

    __index = function(self,key)
      fill(self,cache_constructor)
      return self[key]
      end,
    --v3.x, when would writing to the cache actually be needed? if ever?
    __newindex = read_only_error,
    
    __pairs = function(self)
      fill(self,cache_constructor)
      return pairs(self)
      end,
    
    })
  end
  end


















-- -----------------------------------------------------------------------------
-- OnLoadCache.
-- -----------------------------------------------------------------------------

----------
-- __Not implemented__. Similar to an AutoCache but self-constructs when a
-- savegame is loaded. Using `on_debug_once_per_session`.
-- @function Cache.OnLoadCache


-- -----------------------------------------------------------------------------
-- ???.
-- -----------------------------------------------------------------------------


----------
-- Rewrite TickedCache table functions to emulate exact behavior of lua.
-- I.e. TC:remove() should return the removed value, etc.
-- @within Todo
-- @field todo1


----------
-- Nothing.
-- @within Todo
-- @field todo1



-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Cache') end
return function() return Cache,_Cache,_uLocale end
