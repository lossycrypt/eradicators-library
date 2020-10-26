-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- A bunch of small utilities. Factorio already has "util" so this is Tool.
-- Basically a collection of functions that don't fit into any other module.
-- When a new module is added that is a good fit for one of these they
-- will be moved there on short notice so watch the changelog carefully.
--
-- @module Tool
-- @usage
--  local Tool = require('__eradicators-library__/erlib/factorio/Tool')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --

local stop = elreq('erlib/lua/Error')().Stopper('Tool')

local Stacktrace = elreq ('erlib/factorio/Stacktrace')()

local table_unpack
    = table.unpack

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Tool,_Tool,_uLocale = {},{},{}



--------------------------------------------------------------------------------
-- Section
-- @section
--------------------------------------------------------------------------------


----------
-- In-line call a function but return the arguments first.
--
-- @usage
--   print(Tool.KeepArgsCall(function(a,b,c) return a+b+c end, 1, 2, 3))
--   > 1 2 3 6
--
-- @usage local arg1, prototype = Tool.KeepArgsCall(SimpleHotkey,{'some','values'})
--
-- @tparam function f
-- @tparam AnyValue ...
-- 
-- @treturn AnyValue ...
-- @treturn AnyValue f(...)
-- 
function Tool.KeepArgsCall(f,...)
  local n = select('#',...)
  local r = {[n+1] = f(...), ...}
  return table_unpack(r,1,n+1)
  end

 
----------
-- Get the first non-nil value.
-- For when you can't use `return a or b` because false is a valid return value.
--
-- @tparam AnyValue ... It is an error if not at least one value given is @{NotNil}.
-- @treturn NotNil The first value that was not nil. Can return boolean false
-- if that was the first applicable value.
function Tool.First(...)
  local args,n = {...},select('#',...)
  for i=1,n do
    if args[i] ~= nil then return args[i] end
    end
  stop('Tool.first\n','All given values were nil!') -- really useful?
  end

  
----------
-- Get the last non-nil value.
--
-- @tparam AnyValue ... It is an error if not at least one value given is @{NotNil}.
-- @treturn NotNil The last value that was not nil. Can return boolean false
-- if that was the last applicable value.  
function Tool.Last(...)
  local args,n = {...},select('#',...)
  for i=n,1,-1 do
    if args[i] ~= nil then return args[i] end
    end
  stop('Tool.Last\n','All given values were nil!') -- really useful?
  end
 
 
----------
-- In-line trinary decision that allows nil and false.
-- The lua idiom `(c and a or b)` doesn't work if false or nil
-- are possible values for a or b.
--
-- @tparam AnyValue condition If this is a @{Concepts.truthy|truty} value then
-- the then\_value will be returned, else the else\_value will be returned.
--
-- @tparam[opt] AnyValue then_value
-- @tparam[opt] AnyValue else_value
--
-- @treturn AnyValue The then\_value or else\_value.
--
function Tool.IfThenElse(condition,then_value,else_value)
  if condition then
    return then_value
  else
    return else_value
    end
  end
  
----------
-- Require()'s lua files relative to the calling file.
--
-- @tparam string relative_path
--
-- @treturn AnyValue the return values of @{require}(current\_dir..relative\_path).
--
function Tool.Import(relative_path)
  local root, ok = Stacktrace.get_cur_dir(2)
  if ok ~= true then
    stop(
      'Could not find relative path for Import.',
      'Import does not work outside of factorio.',
      relative_path)
    end
  local seperator = (relative_path:find('/') ~= nil) and '/' or '.'
  return require(root .. seperator .. relative_path)
  end
 
--------------------------------------------------------------------------------
-- Draft.
-- @section
--------------------------------------------------------------------------------


-- Python-style "try-except-finally"?

-- try{
  -- function()end -- pcall'ed
  
  -- except = function(err) end
  
  -- finally = function() end
  
  -- }
  
  -- function Tool.TryExceptFinally(ft,fe,ff) end
 
 
-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Tool') end
return function() return Tool,_Tool,_uLocale end
