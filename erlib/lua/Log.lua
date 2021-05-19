-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Description
--
-- @{Introduction.DevelopmentStatus|Module Status}: Work in progress.
--
-- @module Log
-- @usage
--  local Log = require('__eradicators-library__/erlib/lua/Log')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --

local pairs,ipairs,log,print,setmetatable
    = pairs,ipairs,log,print,setmetatable

local table_concat,table_pack,string_format,debug_getinfo
    = table.concat,table.pack,string.format,debug.getinfo


local Stacktrace = elreq('erlib/factorio/Stacktrace')() -- requries nothing
local Error      = elreq('erlib/lua/Error')() -- requires Stacktrace + Hydra
local Hydra      = elreq('erlib/lua/Coding/Hydra')()
-- can't use String because it requires Verificate, which is too large
-- and Log should be light-weight.

local stop = Error.Stopper('Logger')

local SKIP       = ercfg.SKIP

local const = {

  level = {
    ['Errors'     ] =   0, -- Error.Error()
    ['Warnings'   ] =   1, -- Log.warn()
    ['Information'] =   2, -- Log.info()
    ['Everything' ] =   3, -- Log.debug()
    ['DEV_MODE'   ] =   4, -- Log.tell(), Log.say()
    },
    
  name = {
    [  0] = 'Errors'     ,
    [  1] = 'Warnings'   ,
    [  2] = 'Information',
    [  3] = 'Everything' ,
    [  4] = 'DEV_MODE'   ,
    },
    
  method_level = {
    err   = 0            ,
    warn  = 1            ,
    info  = 2            ,
    debug = 3            ,
    --
    say   = 4            ,
    tell  = 4            ,
    header= 4            , --seperator
    footer= 4            , --seperator
    },

  log_prefix = {
    [  0] = '[ERROR]'    ,
    [  1] = '[WARN ]'    ,
    [  2] = '[INFO ]'    ,
    [  3] = '[DEBUG]'    ,
    [  4] = '[PRINT]'    ,
    },

  print_prefix = {
    [  0] = '!?!ERROR'   ,
    [  1] = ' ! WARN '   ,
    [  2] = ' ? INFO '   ,
    [  3] = '>>>DEBUG'   ,
    [  4] = ' # PRINT'   ,
    },

  template = {
    startup_setting_name = 'er:startup-log-level@%s',
    runtime_setting_name = 'er:runtime-log-level@%s',
    default_setting_name = 'er:runtime-log-level@eradicators-library'
    }
    
  }

  


-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Log,_Log,_uLocale = {},{},{}

----------
-- Nothing.
-- @within Todo
-- @field todo1

--------------------------------------------------------------------------------
-- Standalone/Bootstrap Nice Table Serializer.
-- @section
--------------------------------------------------------------------------------

-- Standalone to stay light-weight. Simple logging
-- shouldn't implicitly load half the library. 

-- One-step Version of shorten(simplify(to_dense_array()))
-- chain used in Error module. Probably a bit faster too.
--
-- @tparam AnyValue ...
--
-- @treturn table All input values tostring()'ed
--
local _to_table_of_strings; do

  local hydra_options = {
    sortkeys = false, -- line: true
    comment  = false, -- line: false
    sparse   = false, -- line: false?
    nocode   = true , -- line: true?
    indent   = nil  , -- line: nil
    compact  = true , -- line: false
    }
  
  local Hydra_serialize = Hydra.serialize -- skip Hydra internal option merging.
  
  -- Copied code: String.to_string, Log._to_table_of_strings, Error.simplify
  local f_tostring = {
    --@future: Consider 'nil' -> '' depending on how often 'nil' is just spam.
    ['nil'     ] = function( ) return '<nil>'      end,
    ['number'  ] = _ENV .tostring                     ,
    ['boolean' ] = _ENV .tostring                     ,
    ['string'  ] = function(x)
      if x ~= '' then return x
      else return '<empty string>' end end,
    ['thread'  ] = function( ) return "<thread>"   end,
    ['function'] = function( ) return "<function>" end,
    ['userdata'] = function( ) return "<userdata>" end,
    ['table'   ] = function(x) return Hydra_serialize(x,hydra_options) end,
    }
    
  function _to_table_of_strings (...)
    local args = table_pack(...) -- retrieves n
    local length = 0
    for k=1,args.n do
      local v = args[k]
            v = f_tostring[type(v)](v)
      length  = length + #v
      args[k] = v
      end
    -- Try to make it a bit shorter if it gets too long
    -- but don't spend too much effort on it.
    if length > 256 then for k=1,args.n do
      args[k] = args[k]:sub(1,100)
      end end
    args.n = nil
    return args,length
    end
    
  end

--------------------------------------------------------------------------------
-- Settings.
-- @section
--------------------------------------------------------------------------------


-- @treturn value|nil
local function try_get_setting_value(mode,setting_name)
  mode = (mode == 'startup') and 'startup' or 'global'
  if settings and settings[mode] then
    local tbl = settings[mode][setting_name]
    if tbl then return tbl.value end
    end
  end

-- @treturn value|default_value
local function get_log_level_setting_value(mod_name)
  -- not factorio
  if not flag.IS_FACTORIO then return const.level.DEV_MODE end
  -- too early to read settings
  if Stacktrace.get_load_stage().settings then
    if flag.IS_DEV_MODE then
      return const.level.DEV_MODE
    else
      -- return const.level.Errors
      return const.level.Warnings
      end
    end
  -- search mod settings
  local value
  for _,mode in ipairs{'runtime','startup','default'} do
    value = try_get_setting_value(
      mode,
      const.template[mode .. '_setting_name']:format(mod_name)
      )
    if value ~= nil then break end
    end
  --
  -- print('Log level gotten:'..value)
  -- return value or const.level.Errors
  return value
      or (flag.IS_DEV_MODE and const.level.DEV_MODE or const.level.Warnings)
  -- return value or const.level.Warnings
  end


--------------------------------------------------------------------------------
-- STDOUT.
-- @section
--------------------------------------------------------------------------------

-- Grabs a few statistics about where the logging call came from,
-- then formats and prints the actual output.
--
-- @tparam function stdout The output function to use for logging.
-- Usually log or print, but could be a custom file writer etc.
--
local function _do_log_raw(stdout,self,level,msg)
  -- debug level is 2 because of tail-calls in do_log_line/block
  local info = debug_getinfo(2,'Sl')
  local msg = string_format(
    --PREFIX [modname](file:line)[header] msg
    '%s [%-19s](%-19s:%4s) [%-19s] %s',
    self.prefix[level],      
    -- Name of the mod that *created* the logger.
    -- Possibly different of mod that calls the logger.
    self.user_mod_name:sub(-19),
    -- Factorio logger only shows *this* file location when logging,
    -- so it's always nessecary to include the *executing* file:line.
    (not info) and '' or info.short_src:gsub('__[%a-_]+__/',''):gsub('%.lua$',''):sub(-19),
    (not info) and -1 or info.currentline,
    self.logger_name, -- Header (nessecary?)
    msg
    )
  return self.stdout(msg)
  end

-- Logs the message as a line. Tries to chop too long messages down.
function Log:do_log_line(level,...)
  return _do_log_raw(
    self.stdout, self, level,
    table_concat(_to_table_of_strings(...),'') -- serialize to line
    )
  end

-- Logs the message as a block. Used to bring tables with Log:tell()
function Log:do_log_block(level,...)
  return _do_log_raw(
    -- block is always print
    print, self, level,
    '\n'.. (Hydra.lines({...},{indentlevel=5}))
    -- remove the extra {} curly brackets created to access the ... varargs.
    :match'^%s*%{(.*)%}%s*$'
    )
  end


-- Log:header, Log:footer
function Log:do_log_seperator(sep, ...)
  --@future: Mod name? File name?
  if select('#', ...) > 0 then
    return print(sep.. table_concat(_to_table_of_strings(...), '').. '\n')
  else
    return print(sep)
    end
  end
  
  
--------------------------------------------------------------------------------
-- Base Class.
-- @section
--------------------------------------------------------------------------------

-- Loggers shouldn't be created at runtime and
-- they also should never alter the game-state
-- so this should be safe?
-- local known_loggers = {}


-- local _obj_mt = {__index=Log} -- needs to contain individual print/log/SKIP functions

function Log.Logger(logger_name,opts)

  if not (type(logger_name) == 'string' and logger_name ~= '') then
    stop('Missing logger_name.')
    end


  opts = opts or {}

  -- local mod_name = Stacktrace.get_mod_name(2)
  
  -- local new = setmetatable({},_obj_mt)
  local new = {}

  new .module_mod_name = Stacktrace.get_mod_name(2) -- Results in library most of the time
  new .user_mod_name = Stacktrace.get_mod_name(-1) -- The mod that *uses* the library.
  
  new .logger_name = logger_name
  
  Log.update_log_level(new) -- applies leveled metatable
  
  
  -- Extra init option instead of auto-detection by mode?
  -- Would allow me to persontally have terminal print even in lower log-levels.
  -- But makes testing non-dev-mode logging slightly more annoying.
  if opts.print_to_terminal then
    new.stdout = print
  -- else
    -- new.stdout = stdout_log
    end
  
  
  -- I want some method that allows remotely changing *all* 
  -- existing loggers at once. That way each plugin can have a seperate logger.
  -- Without them all needing to watch settings changes.
  -- Or would it be better to just have on generic logger?
  -- With custom prefix maybe?
  --
  -- Usecase: Disable all but specific plugin logging to reduce logspam.
  -- if not _ENV.game then
    -- Is excluding runtime loggers enough?
    -- known_loggers[#known_loggers+1] = new
    -- end
  
  return new
  end


  
--------------------------------------------------------------------------------
-- Log functions.
-- @section
--------------------------------------------------------------------------------
  
-- Desired syntax:

-- local Log = Log.Logger()
-- Log:warn('bla')
-- Log:say('bla')
-- Log:debug('important info')
  

function Log:err(...)
  -- Tail call removes this function from the
  -- stack, resulting in correct file:line info
  -- for the caller.
  return Error.Error('Logger',self.module_mod_name,...)
  end
  
function Log:warn  (...) return self:do_log_line (const.level['Warnings'   ],...) end 
function Log:info  (...) return self:do_log_line (const.level['Information'],...) end
function Log:debug (...) return self:do_log_line (const.level['Everything' ],...) end
function Log:say   (...) return self:do_log_line (const.level['DEV_MODE'   ],...) end
function Log:tell  (...) return self:do_log_block(const.level['DEV_MODE'   ],...) end

local _head, _foot = ('―'):rep(100)..'\n', ('.'):rep(200)..'\n'
function Log:header(...) return self:do_log_seperator(_head, ...) end
function Log:footer(...) return self:do_log_seperator(_foot, ...) end



--------------------------------------------------------------------------------
-- Methods.
-- @section
--------------------------------------------------------------------------------


-- Should log level be from module or user... or always library?
-- I thought the point was to try user first and then try library!
function Log:update_log_level()
  return Log.set_log_level(self,get_log_level_setting_value(self.module_mod_name))
  end


  
  
function Log:set_log_level(log_level)
  local index = {}
  
  if (log_level == const.level.DEV_MODE) then
    self.prefix = const.print_prefix
    self.stdout = print
  else
    self.prefix = const.log_prefix
    self.stdout = log or print -- non-factorio backup
    end
  
  return setmetatable(self,Log._get_leveled_metatable(log_level))
  end
  
  

function Log:set_stdout(f)
  -- Allowing the user to specify custom output functions
  -- risks them changing the game-state.
  end

  
--------------------------------------------------------------------------------
-- pre-constructed metatables.
-- @section
--------------------------------------------------------------------------------
  
-- MUST be LAST in this file to catch all other methods.
  
do 
  -- pre-construct metatables with skip for each level
  local leveled_index = {}
  
  for _,log_level in pairs(const.method_level) do
    local this = {
      log_level = log_level,
      }
    leveled_index[log_level] = {__index=this}
    for method_name in pairs(Log) do
      -- has to include all other methods too!
      this[method_name] = Log[method_name]
      end
    for name,level in pairs(const.method_level) do
      if log_level < level then
        this[name] = SKIP
        -- this[name] = nil --debug
        end
      end
    end 

  function Log._get_leveled_metatable(log_level)
    local mt = leveled_index[log_level]
    if mt == nil then
      err('Leveled metatable not found for level: '..log_level)
      end
    return mt
    end

  end
  
-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Log') end
return function() return Log,_Log,_uLocale end
