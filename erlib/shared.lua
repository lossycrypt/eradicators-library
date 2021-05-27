-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable
-- a minimalistic boot-strap script

--[[
  Todo:
    + say should accept varargs and enforce them into a nice-string
      and remove newlines msg:gsub('\n','')
      > does that mean it needs to be a fully fledged serializer?
        or is it ok to load Hydra/Log?
        
    + Why is shared log-spamming when used instead of empty for the path test?
      is pcall interfering with registering the package after load?
  ]]

  
  
-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- -------------------------------------------------------------------------- --
  
-- This is the first thing the library will say.
-- do (STDOUT or log or print)('ErLib is booting now.') end

-- Outside of factorio '__eradicators-library__' is not a valid absolute path!
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'

--@treturn boolean
local does_file_exist = function(path) return (pcall(require,path)) end

-- A sufficiently unlikely to collide but save/load stable unique value.
-- Used to represent nil in table values and keys where Lua can not.
-- local sha = '' for i=1,5 do sha = erlib.Coding.Sha256(sha) print(sha) end
local NIL  = '2a132dbfe4784627b86aa3807cd19cfeff487aab3dd7a60d0ab119a72e736936'
local SKIP = function()end



-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --

-- this array must be correctly ordered for unpack in modules to work!
local shared = {
  --say
  [1] = function(msg ) return (STDOUT or log or print)(msg) end, --log can't vararg
  --warn
  [2] = function(msg ) return (STDOUT or log or print)(msg) end, --log can't vararg
  --err
  [3] = function(msg ) return (STDERR or error       )(msg) end,
  --elreq
  [4] = function(path) return require(elroot..path)         end,
  --flag
  [5] = {},
  --ercfg
  [6] = {
    NIL  = NIL ,
    SKIP = SKIP,
    --@future: include LOAD_PHASE/STAGE? too much code?
    }
  }
  
  
  
-- -------------------------------------------------------------------------- --
-- Flags                                                                      --
-- -------------------------------------------------------------------------- --

local flag = shared[5]

  flag.IS_FACTORIO = -- is this a non-factorio lua environment?
    not (_ENV.os and _ENV.io)

  flag.IS_DEV_MODE = -- spam the log with garbage, etcpp
    does_file_exist('__00-toggle-to-enable-dev-mode__/empty')
    or (not flag.IS_FACTORIO)

  flag.VERBOSE_LOGGING = --todo: decided how/what to do with this
    flag.IS_DEV_MODE
  
  flag.DO_TESTS = -- run unit tests 
    does_file_exist('__00-toggle-to-enable-tests__/empty')
    or (not flag.IS_FACTORIO)
  
  flag.IS_LIBRARY_MOD = -- am i running inside the original factorio mod?
    (flag.IS_FACTORIO   -- or is this a cross require from another mod?
    and
    -- filename of bottom of manual stacktrace
    (function(i,dgi) while dgi(i) do i=i+1 end return not not dgi(i-1)
     .short_src:match'^__eradicators%-library__' end)(1,debug.getinfo)
     and
    -- last line of automatic stacktrace
    (not not (debug.traceback():gsub('^.*\n%s*',''))
     :match'^__eradicators%-library__')
    )

  flag.IS_FACTORIO_CONTROL =
    (flag.IS_FACTORIO
    and
    (nil ~= (debug.traceback():match('^.*\n%s*.*/(control%.lua):')))
    )


    
-- -------------------------------------------------------------------------- --
-- Log Level                                                                  --
-- (@todo implement this properly...)
-- -------------------------------------------------------------------------- --

  -- Mute low-level logging
  STDOUT = flag.IS_DEV_MODE and print or SKIP
  STDERR = error
 
  -- This is the first thing the library will say.
  if flag.IS_DEV_MODE then
    print(('―'):rep(100)..'\nshared.lua\n' )
  else
    -- log('ErLib is booting now.') -- Just don't. Not Warn or Error -> not important.
    end

    
  
return shared
