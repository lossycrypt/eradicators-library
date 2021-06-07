-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Description
--
-- @submodule Iter
-- @usage
--  local sync_tuples = require('__eradicators-library__/erlib/lua/Iter/sync_tuples')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Eradicators Library                                                        --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
local stop   = elreq('erlib/lua/Error')().Stopper('sync_tuples')

local unpack = table.unpack

local type,pairs,ipairs = type,pairs,ipairs

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

-- local sync_tuples,_sync_tuples,_uLocale = {},{},{}

----------
-- Iterates multiple tables in paralell.
--
-- __Note:__ Standard @{next} rules apply regarding in-loop manipulation
-- of the __parent__ table.
--
-- __Note:__ If the parents has a \_\_pairs metamethod its resulting
-- keys are used for all child tables.
--
-- @tparam table parent This determines which keys are iterated.
-- @tparam table|nil ... Additional tables to be iterated.
-- @return k,v1,v2,v3,... Each iteration return the key and the value for each
-- table in the order the tables were given.
-- @usage
--   -- Keys not in the parent table won't be iterated.
--   local par = {nil, 'b', 'c', 'd', false, ['x'] = 'f'}
--   -- Other tables nil keys will just return nil.
--   local t1  = {'A', 'B', 'C', nil, 'E', ['x'] = 'F'}
--   local t2  = {nil, nil,  3 ,  4 ,  5 , ['x'] =  6 }
--   -- Empty arguments are assumed to be empty tables.
--   local t3  =  nil
--   
--   for k,vp,v1,v2,v3 in Iter.sync_tuples(par,t1,t2,t3) do
--     print(k,':',vp,v1,v2,v3)
--     end
--   
--   > 2 : b     B   nil nil
--   > 3 : c     C   3   nil
--   > 4 : d     nil 4   nil
--   > 5 : false E   5   nil
--   > x : f     F   6   nil
--   
-- @function Iter.sync_tuples

local function sync_tuples(parent,...)
  local tables,n = {parent,...}, 1 + select('#',...)
  -- keys are not cached, if the user wants key caching they can construct
  -- that themselfs by passing a Set(parent) copy as first argument.

  if type(parent) ~= 'table' then
    stop('Parent must be a table, but was:\n',parent)
    end
  
  -- allow iteration of partial nil input
  local ok = {['table']=true,['nil']=true}
  for i=1,n do
    if not ok[type(tables[i])] then
      stop('Given argument was not a table:\n',tables[i])
      end
    if tables[i] == nil then tables[i] = {} end
    end
  
  local next = (pairs(parent)) -- respect custom iterator
  
  local function _iter(_,key)
    key = next(parent,key)
    local r = {}
    for i=1,n do r[i] = tables[i][key] end
    return key, unpack(r,1,n)
    end
  
  return _iter,nil,nil --iter,tbl(parent),key
  end


-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.sync_tuples') end
return function() return sync_tuples,_sync_tuples,_uLocale end
