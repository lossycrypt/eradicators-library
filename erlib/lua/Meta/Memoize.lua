-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable

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
--
-- @treturn table a function-like indexable MemoTable.
--
-- @treturn function A parameterless function that can be called
-- to clear the cached results. In case you want to free up memory.
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
--
-- @function Memoize
--

-- Simple one-argument Memoizer (V2)
function _Memo1(f)

  local cache = {}
  
  local mt = {
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
    }
    
  local function f_clear()
    setmetatable(cache, nil)
    Table.clear(cache)
    setmetatable(cache, mt)
    end
    
  return setmetatable(cache, mt), f_clear end

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
  

-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Memoize') end
return function() return Memoize,_Memoize,_uLocale end
