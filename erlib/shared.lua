-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable
-- a minimalistic boot-strap script

--[[
  Todo:
    + say should accept varargs and enforce them into a nice-string
      and remove newlines msg:gsub('\n','')
      > does that mean it needs to be a fully fledged serializer?
        or is it ok to load Hydra?
        
    + Why is shared log-spamming when used instead of empty for the path test?
      is it because of pcall?
  ]]

-- do (STDOUT or log or print)('  Loaded → erlib.shared') end
do (STDOUT or log or print)('ErLib is booting now.') end

-- Outside of factorio '__eradicators-library__' is not a valid absolute path!
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'

--@treturn boolean
local does_file_exist = function(path) return (pcall(require,path)) end

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
  }
  
local flag = shared[5]

  flag.IS_FACTORIO =
    not (_ENV.os and _ENV.io)

  flag.IS_DEV_MODE =
    does_file_exist('__zz-toggle-to-enable-dev-mode__/empty')
    or (not flag.IS_FACTORIO)

  flag.VERBOSE_LOGGING = --todo: decided how/what to do with this
    flag.IS_DEV_MODE
  
  flag.DO_TESTS = 
    flag.IS_DEV_MODE
  
return shared
