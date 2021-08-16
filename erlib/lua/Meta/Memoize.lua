-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Description
--
-- @submodule Meta
-- @usage
--  local Memoize = require('__eradicators-library__/erlib/lua/Meta/Memoize')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

local NIL = ercfg.NIL

-- -------------------------------------------------------------------------- --
-- Eradicators Library                                                        --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --

-- local Verificate  = elreq('erlib/lua/Verificate'   )()
-- local verify      = Verificate.verify
-- local isType      = Verificate.isType


local Table      = elreq('erlib/lua/Table'     )()
local Filter     = elreq('erlib/lua/Filter'    )()


-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Memoize,_Memoize,_uLocale = {},{},{}

local _Memo1, _MemoN


-- -- V1
-- -- Simple argument splitter 1<>N
-- local function Memoize(constructor, n, max_cache_size)
--   assert(type(constructor) == 'function', 'Constructor must be a function.')
--   if (n or 1) == 1 then
--     -- does not check max_cache_size because it would be too expensive to
--     -- check on every call.
--     return _Memo1(constructor)
--   else
--     return _MemoN(n, constructor, max_cache_size)
--     end
--   end

-- V2  
-- Simple argument splitter 1<>N
local function Memoize(a, b, c)
  if type(a) == 'function' then
    return _Memo1(a)
  elseif type(c) == 'function' then
    return _MemoN(a, b, c)
  else
    error('No function given to Memoize().')
    end
  end

-- -------------------------------------------------------------------------- --
  

----------
-- A single-argument-function memory-table. Very fast.
--
-- __NOTE:__ if the result of calling a memoized function is a table then
-- a **reference** to the cached table is returned. You must therefore copy
-- any returned table before you alter them, or you will alter the cached
-- table, and therefore all future results.
-- 
-- @tparam function f
-- @treturn table a function-like indexable MemoTable.
-- @function Memoize
--
-- @usage
--   -- Simply call Memoize() with the function you want to memoize.
--   local doubleup = function(a) return 2*a end
--   local memodoubleup = Memoize(doubleup)
--   -- You can use the memoized function exactly as before.
--   -- But for very simple and fast operations like this example
--   -- The function call overhead would outweight the performance gains.
--   local four = memodoubleup(2)
--   -- Instead you can also access the result like a table. This is actually
--   -- a real native table lookup for every call after the first. So it
--   -- is really fast! Even for this simple 2*a example it only takes 1/3rd
--   -- of the time it would to call the un-memoized function.
--   local four = memodoubleup[2]

-- Simple one-argument Memoizer (V2)
function _Memo1(f)
  return setmetatable({}, {
    __index = function(self, key)
      local value = f(key) -- Can be nil.
      rawset(self, key, value)
      return value end,
    __call = function(self, key)
      return self[key] end,
    --
    __pairs    = function() err('Memoized function is not iterable.') end,
    __ipairs   = function() err('Memoized function is not iterable.') end,
    __newindex = function() err('Memoized function is not writable.') end,
    })
  end

-- -------------------------------------------------------------------------- --


----------
-- A multi-argument-function memoizer.
-- 
-- @tparam NaturalNumber arg_count The number of arguments that `f` takes.
-- @tparam boolean copy_result If true then calling the memoized function
-- will use @{Table.dcopy} to copy the result before returning it. This is
-- only useful if the returned value is a table. If false
-- a direct reference will be passed.
-- 
-- @tparam function f The function to memoize. The function must return
-- __exactly one__ @{NotNil} value when called.
-- 
-- @treturn function The memoized version of `f`. It must be called with
-- exactly `arg_count` arguments of type @{NotNil}. `{args} -> result`
-- loopup uses lua object identity, so be careful when passing tables.
--
-- @treturn function A parameterless function that can be called
-- to clear the cached results. In case you want to free up memory.
-- 
-- @function Memoize
  do
  local _returners = {[true] = Table.dcopy, [false] = Filter.PASS}
  local get, set = Table.get, Table.set
function _MemoN(arg_count, copy_result, f)
  --
  assert(type(arg_count) == 'number')
  assert(arg_count > 0, 'arg_count must be NaturalNumber')
  local copy = assert(_returners[copy_result], 'copy_result must be boolean')
  local cache = {}
  --
  return function(...)
    local path = {...}
    assert(#path == arg_count, 'Wrong number of arguments')
    local r = get(cache, path)
    if r == nil then
      r = set(cache, path, (f(...)))
      assert(r ~= nil, 'Function result was nil')
      end
    return copy(r) end
    ,
    function() cache = {} end
  end
  end
  
  
--[==[
-- -------------------------------------------------------------------------- --
-- Trash
  
-- -------
-- __EXPERIMENTAL__ A multi-argument function memoizing wrapper.
--
-- __NOTE:__ Argument comparison is based on standard Lua identity. All arguments
-- must be valid table keys or nil. There is 
-- no magic that checks if the content of a table given as argument machtes
-- the content of a table given in a previous function call. Therefore it is advisable
-- to only memoize functions that take number and string arguments exclusively.
--
-- __NOTE:__ If the function returns tables you should copy them before use. See
-- note above.
--
-- @tparam function constructor the function to be memoized
-- @tparam[opt=1] int argcount the maximum number of positional arguments that the function takes.
-- @tparam[opt=9000] int max_cache_size the maximum size of the set of possible argument
-- combinations to cache. If the cache grows beyond this size it will be flushed.
-- @treturn function the memoized wrapper that behaves like the original function
-- except that it does not call the function if there is a known cached result
-- for the given combination of arguments.
--
-- @function Memoize
--
-- @usage
--   local g = function(a,b,c,d,e) return a*b*c*d*e end
--   local f = Memoize(g,5)
--   print(f(1,2,3,4,5))
--   > 120

-- N-Argument Memoizer (Prototype 2)
do
  -- @future: 
  --   By removing NIL argument support and load()'ing a custom made
  --   function that simply uses pcall(load("function() return cache[a][b][c][d] end"))
  --   for the indexing operation to catch nil results it should be
  --   possible to make this significantly faster so that it becomes
  --   a realistic option even for fast functions.
  --
  --   It'll have to be seen if that ever becomes nessecary.
  --
  local _set,_get
  --closure with cache table
  function _MemoN(n,constructor,max_cache_size)
    local cache = {__size = 0}
    return function(...)
      return _get(cache,n,max_cache_size,constructor,...)
      end
    end
  --getter
  function _get(cache,n,max_cache_size,constructor,...)
    local path = {...}
    local value = cache
    for i=1,n do
      local key = path[i]
      if key == nil then key = NIL end
      value = value[key]
      if value == nil then break end
      end
    if value == nil then --not cached yet
      -- flush too large cache to safe memory
      if cache.__size >= (max_cache_size or 9000) then
        for k in pairs(cache) do cache[k] = nil end
        warn('Memoize cache flushed.')
        cache.__size = 0
        end
      cache.__size = cache.__size + 1
      return _set(cache,n,path,constructor,...) -- constructor must get real nil
    elseif value == NIL then --cached nil result
      return nil
    else
      return value --@todo: copy value? performance?
      end
    end
  --setter
  function _set(cache,n,path,constructor,...)
    local value = constructor(...)
    if value == nil then value = NIL end
    for i=1,n-1 do
      local key = path[i]
      if key == nil then key = NIL end
      if cache[key] == nil then cache[key] = {} end -- "false" is not a problem here
      cache = cache[key]
      end
    cache[path[n]] = value
    return value
    end
  end
  
--]==]
  
-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Memoize') end
return function() return Memoize,_Memoize,_uLocale end
