-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- A bunch of small experimental utilities that don't clearly belong into
-- any of the other modules or do not have a good name yet.
--
-- Factorio already has "util" so this is Tool.
-- Basically a collection of functions that don't fit into any other module.
-- When a new module is added that is a good fit for one of these they
-- will be moved there on short notice so __watch the changelog carefully__.
--
-- @{Introduction.DevelopmentStatus|Module Status}: Work in progress forever.
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
-- Eradicators Library                                                        --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --

local stop = elreq('erlib/lua/Error')().Stopper('Tool')
local log  = elreq('erlib/lua/Log'  )().Logger ('Tool')

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
-- Calls a function when a value is nil.
--  
-- @tparam AnyValue value  
-- @tparam function f
-- @tparam AnyValue ...  
--  
-- @return If value was not nil it's value will be returned. Otherwise
-- the result of calling f(...) will be returned.
--  
function Tool.IfNilCall(value,f,...)
  if value == nil then return f(...) else return value end
  end
  

----------
-- Calls one of two functions depending on a condition.
--
-- @tparam AnyValue condition If this is @{truthy} calls f1, else calls f2.
-- @tparam function f1
-- @tparam function f2
-- @tparam AnyValue ... Extra arguments for the functions.
--
-- @treturn AnyValue The return value of calling f1(...) or f2(...).
function Tool.SelectCall(condition, f1, f2, ...)
  if condition then
    return f1(...)
  else
    return f2(...)
    end
  end
  
----------
-- Converts a value to a type if it is not yet of that type.
--   
-- @tparam AnyValue value The input value.
-- @tparam string typ The desired type of the input value.
-- @tparam function caster The function that converts the input value if
-- it's not of the desired type.
-- @tparam function typer The function that determines the type
-- of the input value. (_default_ @{type})
--   
-- @treturn AnyValue The input value or the result of caster(value).
--   
function Tool.CastType(value, typ, caster, typer)
  if (typer or type)(value) == typ then
    return value
  else
    return caster(value)
    end
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
-- In-line ternary decision that allows nil and false.
-- The lua idiom `(c and a or b)` doesn't work if false or nil
-- are possible values for a or b.
--
-- Not to be confused with @{select}.
--
-- @tparam AnyValue condition If this is a @{truthy} value then
-- the true\_value will be returned, else the false\_value will be returned.
--
-- @tparam AnyValue true_value
-- @tparam AnyValue false_value
--
-- @treturn AnyValue The true\_value or false\_value.
-- 
function Tool.Select(condition,true_value,false_value)
  if condition then return true_value else return false_value end
  end


----------
-- Returns the second argument given.
-- About ~5% faster than @{select}(2,...)
-- @tparam AnyValue ...
-- @treturn AnyValue
-- @function Tool.Select_second
function Tool.Select_second(_,_) return _ end


----------
-- Returns the third argument given.
-- About ~5% faster than @{select}(3,...)
-- @tparam AnyValue ...
-- @treturn AnyValue
-- @function Tool.Select_third
function Tool.Select_third(_,_,_) return _ end

 
----------
-- Converts a factorio tick to hours, minutes and seconds.
-- 
-- @tparam NaturalNumber tick
-- 
-- @treturn table A table `{h=,m=,s=}` of @{NaturalNumber}s.
-- 
function Tool.tick_to_time(tick)
  local seconds = tick / 60
  return {
    h = math.floor(seconds / (60^2)     ),
    m = math.floor(seconds % (60^2) / 60),
    s = math.floor(seconds %  60        ),
    }
  -- Test:
  -- for h = 1,3 do for m = 1,3 do for s = 1,3 do
  --   local tick = h*60*60*60+m*60*60+s*60+17
  --   printt(Tool.tick_to_time(tick), tick)
  --   end end end
  end
  

----------
-- Require()'s lua files relative to the calling file.
--
-- @tparam string relative_path Directories are seperated by "/" forward slash,
-- ".." two full stops go up one directory.
--
-- @treturn AnyValue the return value of @{require}("current\_dir/relative\_path").
--
function Tool.Import(relative_path)
  local root, ok = Stacktrace.get_directory(2)
  if ok ~= true then stop(
    'Could not find relative path for Import.\n',
    'Import does not work outside of factorio.\n',
    relative_path)
    end
  local full_path = root .. relative_path
  
  -- Factorio does not support explicit relative paths.
  -- So some basic interpretation is hardcoded.
  if flag.IS_FACTORIO then
    full_path = full_path
      :gsub('/%./'         ,'/') -- relative path same directory
      :gsub('/?[^/]+/%.%./','/') -- relative path one directory above
      :gsub('/+'           ,'/') -- erroneous multi-slash
      :gsub('^/'           ,'' ) -- erroneous starting slash (from /../ substitution)
    end
  
  log:debug('Imported "', full_path, '".')
  
  -- Make nicer error messages when something fails.
  local ok, chunk = pcall(require,full_path)
  if ok ~= true then
    -- ".lua" is automatically appended to the second part
    -- of the message but not to the first.
    local template = 'module %s not found;  no such file %s'
    if chunk:gsub('%.lua$','') == template:format(full_path,full_path):gsub('%.lua$','') then
      stop('Import failed. ', 'No such file:\n', full_path)
    else
      -- The error message is already formated. Possibly by a custom Stopper.
      error('\n[color=blue]Import failed:\n'..full_path..'\n[/color]'..chunk)
      end
    end

  return chunk
  end
 
 
--------------------------------------------------------------------------------
-- Draft.
-- @section
--------------------------------------------------------------------------------


----------
-- Does not raise an error if the file doesn't exist.
--
-- @tparam string path
--
-- @treturn boolean If the require succeeded.
-- @treturn AnyValue The return value of the required file.
function Tool.try_require(path)
  local ok, chunk = pcall(require,path)
  if ok == true then
    return true, chunk
  else
    -- Compare to exactly the file-not-found message that is expected
    -- to prevent accidentially ignoring important file-not-found errors.
    local template = 'module %s not found;  no such file %s'
    -- ".lua" is automatically appended to the second part
    -- of the message but not to the first.
    if chunk:gsub('%.lua$','') ~= template:format(path,path):gsub('%.lua$','') then
      -- Catches syntax errors, AutoLock errors, etc.
      -- The error message is already formated. Possibly by a custom Stopper.
      error(
        '\n[color=blue]An error occured during\ntry_require("'..path..'")[/color]\n'
        ..chunk
        )
    else
      -- log:debug('No such file (expected): ',path)
      -- log:debug('No such file : ',path)
      return false, nil
      end
    end
  end
 


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
