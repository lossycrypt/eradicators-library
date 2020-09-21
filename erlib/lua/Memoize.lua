-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Description
--
-- @module Memoize
-- @usage
--  local Memoize = require('__eradicators-library__/erlib/factorio/Memoize')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag = table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Memoize,_Memoize,_uLocale = {},{},{}

local Memo1, MemoN

--- Simple argument splitter 1<>N
local function Memoize(n,constructor)
  if (type(n) == 'function') and (constructor==nil)then 
    n,constructor = 1,n
    end
  if n == 1 then return _Memo1(constructor)
  else           return _MemoN(constructor)
    end
  end

--- Simple one-argument Memoizer
function _Memo1(constructor)
  local mt = {}
  function mt.__index(self,key)
    local value = constructor(key)
    self[key] = value
    return value
    end
  function mt.__call(self,key)
    return self[key] --implicitly call index -> constructor
    end
  return setmetatable({},mt)
  end


  
  
  
--- N-Argument constructor
function _MemoN(n,constructor)

  -- this'll need automatic sub-table construction to *exactly* n depth.

  -- only the final index needs to know all arguments
  -- but how does it get them?
  local function make__index(depth,args)
    local _index function (self,key)
      
      end
    return
    end
  
  function _index (self,key)
    if depth == n then
      local value = constructor(unpack(keys))
      self[key] = value
      return value
    else
      return setmetatable({},{__index=_index})
      end
    end
  
  
  local function a(n)
    
    return setmetatable({},a(n-1))
    
    end
  
  
  return setmetatable({},a(n))
  
  end

  
function _MemoN(n,constructor)
  local cache_size=0
  return function(a,b,c,d,e,f,g)
    -- if it can be assumed that either the full path exists
    -- or no part of the path exists... 
    -- then can a temporary index meta return a stack of empty
    -- tables that only exists to make this not crash?
    
    --> investigate how fast or slow pcall() "if index a nil value" is.
    local test = "Console:1: attempt to index a nil value (field '?')"
    
    --> can a precise pregenerated function use an actual table-indexing approach?
    --> nil parameters must still be converted to Nil
    
    if a == nil then a = Nil end --can be auto-generated
    if b == nil then a = Nil end
    if c == nil then a = Nil end
    if d == nil then a = Nil end
    if e == nil then a = Nil end
    -- return cache[a][b][c][d][e][f][g]
    local ok,msg = pcall(function() return cache[a][b][c][d][e][f][g] end)
    if ok==true then
      return msg
    elseif msg:match"attempt to index a nil value (field '?')" then --equal compare exact message
      local value = constructor(a,b,c,d,e,f,g)
      _set(cache,{a,b,c,d,e,f,g},value,7)
      cache_size = cache_size+7
      return value
    else
      error(msg)
      end
    end
  end
  
  
  
--- N-Argument constructor DRAFT

-- a sufficiently unlikely to collide but save/load stable unique value
-- Sha256 of the empty string.
local Nil = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'
-- local Nil = '__Nil__'

-- A fixed-depth nil-key-hardened variant of Table.set
local function _set(tbl,path,value,depth)
  for i=1,depth-1 do
    local key = path[i] -- "nil"?
    if key == nil then key = Nil end
    if not tbl[key] then tbl[key] = {} end -- "false" is not a problem here
    tbl = tbl[key]
    end
  tbl[path[depth]] = value
  end

-- A fixed-depth nil-key-hardened variant of Table.get
local function _get(tbl,path,depth)
  for i=1,depth-1 do
    local key = path[i] -- "nil"?
    if key == nil then key = Nil end
    tbl = tbl[key]
    if tbl==nil then return nil end
    end
  return tbl[path[depth]]
  end


local final = {

  a = auto{
      [1] = {
          stuf = {
              data = {
                -- table doesn't even need to auto-expand 
                -- because [b][c][2][5] syntax is not desirable or transparent
                [987] = result_of_constructor_call "c(a,1,stuf,data,987)"
                }
            }
        }
    }
    
  b = {
    }

  }
  


--------------------------------------------------------------------------------
-- Section
-- @section
--------------------------------------------------------------------------------

----------
-- Foo
-- @table Foo
-- @usage

-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Memoize') end
return function() return Memoize,_Memoize,_uLocale end
