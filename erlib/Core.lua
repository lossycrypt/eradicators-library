-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--[[------------------------------------------------
  Instead of requiring each component of the library seperately you can
  require this Core file which fill automatically loads all modules.
  The Core also has some special features like installing all modules directly
  into your environment. If you only want to use a selected few modules that's
  probably a waste of RAM though.
 
  @module Core
  @usage local erlib = require('__eradicators-library__/erlib/Core')()
]]

-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
-- Outside of factorio '__eradicators-library__' is not a valid absolute path!
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Greeting                                                                   --
-- -------------------------------------------------------------------------- --
say('>>> Erlib Core Boot Sequence Started  >>>')

-- -------------------------------------------------------------------------- --
-- Log Header                                                                 --
-- -------------------------------------------------------------------------- --
if flag.IS_DEV_MODE then

  say('  Flag   → IS_DEV_MODE → '..tostring(flag.IS_DEV_MODE))

  end
-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- -------------------------------------------------------------------------- --

-- Removes stale references so they can be garbage collected.
local package_reset = function()
  for k in pairs(package.loaded) do package.loaded[k] = nil end
  end

local Stacktrace = elreq ('erlib/factorio/Stacktrace')()
local Error      = elreq ('erlib/lua/Error')()

-- -------------------------------------------------------------------------- --
-- Constants                                                                  --
-- -------------------------------------------------------------------------- --

local Const = {}
  --mod that contains this file
  Const.lib_name   = Stacktrace.get_mod_name( 1)
  Const.lib_root   = Stacktrace.get_mod_root( 1)
  --mod that required this file
  Const.mod_name   = Stacktrace.get_mod_name(-1)
  Const.mod_root   = Stacktrace.get_mod_root(-1)
  --load stage/phase
  Const.load_stage = Stacktrace.get_load_stage()
  Const.load_phase = Stacktrace.get_load_phase()

local stop = Error .Stopper 'Core' -- local to each plugin in the future


-- -------------------------------------------------------------------------- --
-- Module Init                                                                --
-- -------------------------------------------------------------------------- --

-- stage limitation (default is "always")
local startup_only = function(path) if not Const.load_stage.control then return path end end
local control_only = function(path) if     Const.load_stage.control then return path end end


local Modules = {
  --determines load order
  Verificate = 'erlib/lua/Verificate',
  Stacktrace = 'erlib/factorio/Stacktrace',
  Error      = 'erlib/lua/Error',
  Log        = 'erlib/lua/Log',
  Replicate  = 'erlib/lua/Replicate',
  Filter     = 'erlib/lua/Filter',
  Debug      = 'erlib/lua/Debug',
  Lambda     = 'erlib/lua/Lambda',
  Time       = 'erlib/lua/Time',
  String     = 'erlib/lua/String',
  Table      = 'erlib/lua/Table',
  Array      = 'erlib/lua/Array',
  Lock       = 'erlib/lua/Lock',
  Version    = 'erlib/lua/Version',
  Logic      = 'erlib/lua/Logic',
  Tool       = 'erlib/lua/Tool',
  Set        = 'erlib/lua/Set',
  Class      = 'erlib/lua/Class',
  Compare    = 'erlib/lua/Compare',
  Math       = 'erlib/lua/Math',
  
  -- groups
  Coding     = 'erlib/lua/Coding/!init',
  Iter       = 'erlib/lua/Iter/!init',
  Meta       = 'erlib/lua/Meta/!init',
    -- Memoize    = 'erlib/lua/Memoize',
    -- Compose    = 'erlib/lua/Compose',
    -- Closurize  = 'erlib/lua/Closurize',

  -- factorio
  -- (tests do their own checks)
  Cache       = control_only 'erlib/factorio/Cache',
  Entity      = control_only 'erlib/factorio/Entity',
  }
  
-- require() does not support multiple return values. So every module
-- returns a parameterless function that returns {Module,Strict,uLocale}.
for name,path in pairs(Modules) do
  say('  File   → '..path)
  Modules[name] = {elreq(path)()} --
  end

-- -------------------------------------------------------------------------- --
-- Module Assembly                                                            --
-- -------------------------------------------------------------------------- --

-- Non-strict version
-- Preliminary. Will become unsupported once all type checks have been written.
-- 
local erlib = {}; do
  for k,v in pairs(Modules) do
    erlib[k] = v[1]
    end
  end
  
  
-- Strict version
-- Checks input to supported functions before calling.
--
local erlib_strict = {}; do
  for k,v in pairs(Modules) do
    ---@todo: implement strict wrapping (Verificate.wrap?)
    -- erlib_strict[k] = UnknownMagic(v[2],v[1])
    end
  end

erlib       .Const = Const
erlib_strict.Const = Const

  
-- Pulls functions from sub-paths directly
-- into the main table.
-- @usage uplift(erlib,{'Coding','Replicate','Filter'})
--
local function uplift(target,names,setter)
  for _,name in pairs(names       ) do
  for k,v    in pairs(target[name]) do
  -- if type(v) == 'function'          then --@think: are limits needed? Coding needs tables.
    -- say('  Uplifting',name,k)
    if setter then
      setter(target,k,v)
    else
      target[k] = v
      end
    end
    end
  end



-- -------------------------------------------------------------------------- --
-- Main                                                                       --
-- -------------------------------------------------------------------------- --
say('<<< Erlib Core Boot Sequence Finished <<<')



local function EradicatorsLibraryMain(options)
----ENVIRONMENT------------------------------------------------------------------------------------
  assert(_ENV == debug.getregistry () [2],'[ER Library] Can not run with broken _ENV')
  local PublicENV = debug.getregistry () [2]

  -- EradicatorsLibrary = setmetatable({},{__index=_ENV}) --what about LOCK?
----OPTIONS----------------------------------------------------------------------------------------


-- -------------------------------------------------------------------------- --
-- Core                                                                       --
-- -------------------------------------------------------------------------- --
  
  local Core = {}; erlib .Core = Core

  
  ----------
  -- Injects some methods directly into public modules like string, table, etc.
  -- @tparam table ENV the environment in which to carry out the operation
  Core.inject_into_native_lua_modules = function(ENV)
    -- in data/settings disturbing other mods is rude
    if not Const.load_stage.control then
      stop('Public injection is not supported during startup.')
      end
    -- so only allow this in control
    ENV.string.f = ENV.string.format
    end 
  
  ----------
  -- Makes all erlib modules available directly in ENV.
  -- 
  Core.install_to_env = function(ENV,opt)
    if (not Const.load_stage.control)
    and (ENV == PublicENV)
    and flag.IS_FACTORIO
    then
      stop('Please use a private environment to install erlib.')
      end
    opt = opt or {}
    --make a new env for the caller?
    if ENV == nil then
      ENV = {} ---@todo: write lock? read lookup?
      for k,v in pairs(PublicENV) do ENV[k] = v end
      end
    ENV.PrivateEnv = ENV
    ENV.PublicENV  = PublicENV -- PrivateEnv needs access to PublicEnv
    --lock (NP++ has custom metatable)
    local setter = function(t,k,v) t[k] = v end
    if flag.IS_FACTORIO and (opt.auto_lock ~= false) then
      erlib.Lock.AutoLock(ENV,'Erlib Core-Installed Environment','GLOBAL')
      setter = function(t,k,v) t.GLOBAL(k,v) end
      end
    --install to env
    for k,v in pairs(erlib) do
      ---@todo implement strict wrapping
      setter(ENV, k, opt.strict and erlib_strict[k] or erlib[k])
      end
    --uplift
    uplift(ENV, {'Coding', 'Meta', 'Logic', 'Tool'}, setter)
    setter(ENV, {'L'} ,erlib .Lambda)
    -- @future: Tool -> CamelCase
    -- @future: Import (automatic relative-directory require)(with "!init"?)
    --extra constants
    setter(ENV, 'LOAD_STAGE', Const.load_stage)
    setter(ENV, 'LOAD_PHASE', Const.load_phase)
    return ENV
    end
  
  ----------
  -- Runs all unit tests included in erlib.
  -- Does not run in non-erlib mods.
  Core.run_tests = function()
    if flag.DO_TESTS and (flag.IS_LIBRARY_MOD or not flag.IS_FACTORIO) then
      -- print('here',erlib.Stacktrace.get_pos())
      local Tester = elreq('erlib/test/!init')()
      if not Const.load_stage.control then
        Tester()
      else
        ---@fixme on_nth_tick calls this *twice* in the same tick....why?
        local only_once; do function only_once(); only_once = (function()end)
          Tester()
          end end
        --> event manager internal event "on_debug_once_per_session"
        script.on_nth_tick(61,function()only_once()end) --must be identical function
        end
      end
    end
    


    
  return erlib
  end

if true then return EradicatorsLibraryMain end
























-- -----------------------------------------------------------------------------
-- ###########################################################################--
-- -----------------------------------------------------------------------------

local function __init__(PublicENV,options)
----ENVIRONMENT------------------------------------------------------------------------------------
  --private global space in which the library lives
  --todo: copy only official keys (not mod functions) (wube functions...?)
  local _ENV = {}; local _LIB = _ENV; for k,v in PublicENV .pairs(PublicENV) do _LIB[k]=v end
  _LIB .PublicENV   = PublicENV
  _LIB .LibraryENV  = _LIB
  _LIB ._G          = _LIB

----OPTIONS----------------------------------------------------------------------------------------
  options = options or {}
  local OVERRIDE = pcall(require,'__zz-toggle-to-enable-dev-mode__/empty')
  -- IS_DEV_BUILD      = options.is_dev_build      or false
  -- DEBUG_MODE        = options.debug_mode        or false
  IS_DEV_BUILD      = OVERRIDE --what is the use-case for toggling these on a per-mod basis?
  DEBUG_MODE        = OVERRIDE --what is the use-case for toggling these on a per-mod basis?
  LEGACY_MODE       = true --hardcoded until the library itself is fully updated
  STRICT_MODE       = options.strict_mode       or false --TODO: mod setting "better error messages"
  USE_EVENT_MANAGER = options.use_event_manager or false
  USE_PLUGINS       = options.use_event_manager or false
  COLLECT_ULOCALE   = nil --seperate this from DEBUG_MODE
  -- print('\n\n\nOPTIONS (lib line ~71) \n\n\n'.. serpent.block(options))
  

----NAME,PATH-------------------------------------------------------------------------------------
  --mod that contains this file
  _Lib_name = Stacktrace .get_mod_name(1)
  _Lib_root = Stacktrace .get_cur_dir (1) 
  --mod that required this file
  _Mod_name = Stacktrace .get_mod_name( ) or 'unknown/scenario'
  _Mod_root = Stacktrace .get_mod_root( ) or 'unknown/scenario'
  --debug.getinfo can actually see the full path to the scenario (engine bug).
  --if this ever breaks i should just scan for "/temp/currently-playing/control.lua"



----LibStop---------------------------------------------------------------------------------------
  do local preset
    --The standard error handler used for all error raising.
    --Can be called with any number of arguments and attempts to print them sufficiently nice.
    --Example: Stop('ALERT!','shit',{'is','hitting',{'the','fence!'}},{'near','the','fox'})
    Error = function(header,...)
      -- header,msg = (msg and header or _Mod_name), (msg or header)
      if type(header) ~= 'string' then header=serpent.line(header) end
      local args = {}
      --table.concat does not work on sparse arrays so nil values must be stripped
      --this is also nice becaues it removes empty args generated by Closurize()
      for i,v in pairs{...} do args[#args+1]=serpent.line(v,{nocode=true}):sub(1,100) end
      for i,l in pairs(preset) do preset[i]=l:match' *(.-) *$' end --strip whitespace
      local err = table.concat(preset,'\n'):format(
        header,table.concat(args,'\n'),Stacktrace.get_rel_pos(2),Stacktrace.get_rel_pos(1))
      error(err,0) --print without built-in level info
      end
    Stop = function(...) Error(_Mod_name,...) end --> Plugin Manager wrapping service? + Error.new('modname') -> return function
    preset = {
      "  [color=default]                                               " ,
      "  ##### [erlib : %s] #####                                      " ,
      "  I feared this might happen. Please tell me how you got here.  " ,
      "                                                                " ,
      "  [color=red]%s[/color]                                         " ,
      "                                                                " ,
      "  [color=green]%s > %s[/color]                                  " ,
      "  ############################                                  " ,
      "  [/color]                                                      " ,
      }
  end
  
----ANNOUNCE--------------------------------------------------------------------------------------- 
  if IS_DEV_BUILD then
    print(('―'):rep(100))
    if Load_phase.control then print(('―'):rep(100)) end --second line
    print(('%s : %s                     \n'..
           '     Lname="%s", Lpath="%s" \n'..
           '     Mname="%s", Mpath="%s" \n'):format
           (Load_stage.name,Load_phase.name,
           _Lib_name       ,_Lib_root      ,
           _Mod_name       ,_Mod_root      ))
    print(('     LEGACY_MODE  = %.5s, STRICT_MODE       = %.5s\n'..
           '     IS_DEV_BUILD = %.5s, USE_EVENT_MANAGER = %.5s\n'..
           '     DEBUG_MODE   = %.5s, USE_PLUGINS       = %.5s\n'):format
          (LEGACY_MODE         , STRICT_MODE                ,
           IS_DEV_BUILD        , USE_EVENT_MANAGER          ,
           DEBUG_MODE          , USE_PLUGINS                ))
    end
  
----LibImport--------------------------------------------------------------------------------------
  Import = require(_Lib_root .. '/debug/Import.lua')(_LIB)
  
----LOCK------------------------------------------------------------------------------------------
  Voodoo = {}
  Voodoo .auto_lock_table = Import(_Lib_root..'/voodoo/auto_lock_table.lua')(_LIB)
  Voodoo .auto_lock_table(_LIB,'_LIB','GLOBAL')
    
----VERIFICATE (LEGACY)----------------------------------------------------------------------------
  --Verificate + Table are the two main modules of the library.
  GLOBAL('Type',Import(_Lib_root .. '/debug/Type.lua')(_LIB))
  GLOBAL('Verificate',Import(_Lib_root .. '/debug/Verificate-3.lua')(_LIB))
  GLOBAL('Verify',Verificate.verify )
  
  GLOBAL('isType'    ,Verificate.is_type)
  GLOBAL('isNil'     ,isType'nil'       )
  GLOBAL('isBoolean' ,isType'boolean'   )
  GLOBAL('isBool'    ,isType'boolean'   )
  GLOBAL('isNumber'  ,isType'number'    )
  GLOBAL('isString'  ,isType'string'    )
  GLOBAL('isFunction',isType'function'  )
  GLOBAL('isTable'   ,isType'table'     )
  GLOBAL('isUserdata',isType'userdata'  )
  
  GLOBAL('verificate',Verificate) --legacy
  
----lib3-------------------------------------------------------------------------------------------
  --[[ (standard module header/footer)
    local _ENV; return function (_LIB); local _ENV = _LIB
    assert(_ENV==_LIB)
    return XYZ end
    ]]
  local function lib3(name) return function(path,legacy_name)
    local chunk = Import(_Lib_root .. path)(_LIB)
    if name        then _LIB.GLOBAL(name       ,chunk) end
    if legacy_name then _LIB.GLOBAL(legacy_name,chunk) end
    end end

----THIRD PARTY------------------------------------------------------------------------------------
  --crypto (until overwritten by encode/decode)
  lib3 'Sha256'  ('/thirdparty/sha2.lua'   ,'sha256' )
  lib3 'Crc32'   ('/thirdparty/crc32.lua'  ,'crc32'  )
  lib3 'Serpent' ('/thirdparty/serpent.lua','serpent')
  GLOBAL('Sblock',Serpent.block)
  GLOBAL('Sline' ,Serpent.line )
  GLOBAL('Slines',Serpent.lines)
  
----TABLE,ARRAY------------------------------------------------------------------------------------
  do
    --merge legacy "libtable" + "Table"
    GLOBAL 'Table'
    GLOBAL 'libtable'
    local libtable = Import(_Lib_root .. '/lua/Table2')(_LIB)
    local Table    = Import(_Lib_root .. '/lua/Table3')(_LIB)
    _LIB .Table = Table.mutate.append(libtable,Table)
    _LIB .libtable = _LIB .Table

    lib3 'Array' ('/lua/Array')
    GLOBAL('TMap',Table.map )
    GLOBAL('AMap',Array.map )
    GLOBAL('Nul' ,Table.none)
    end

----VOODOO-----------------------------------------------------------------------------------------
  -- GLOBAL('Voodoo',{})
  Voodoo .Iterate = Import(_Lib_root..'/voodoo/Iterate.lua')(_LIB)
  GLOBAL('fpairs',Voodoo.Iterate.fpairs) --filtered
  GLOBAL('npairs',Voodoo.Iterate.npairs) --nested
  GLOBAL('opairs',Voodoo.Iterate.opairs) --ordered
  GLOBAL('skip_nil_pairs',Voodoo.Iterate.skip_nil_pairs)
  Voodoo .ticked_cache = Import(_Lib_root..'/voodoo/ticked_cache.lua')(_LIB)
  Voodoo .auto_cache   = Import(_Lib_root..'/voodoo/auto_cache.lua'  )(_LIB)
  Voodoo .compose      = Import(_Lib_root..'/voodoo/compose.lua'     )(_LIB)
  GLOBAL ('C',Voodoo.compose)
  
  GLOBAL ('Closurize',   Import(_Lib_root..'/voodoo/closurize.lua'   )(_LIB))
  Voodoo .switch_case  = Import(_Lib_root..'/voodoo/switch_case.lua' )(_LIB)

----LOGGER-----------------------------------------------------------------------------------------
  lib3 'Log' ('/debug/Log-3.lua','elog') --IS_DEV_BUILD, libtable, libstring, Load_phase, Load_stage
  GLOBAL('say'  ,Log.say  )
  GLOBAL('tell' ,Log.tell )
  -- GLOBAL('stop' ,Log.error) --deprecated by built-in standalone Stop
  -- GLOBAL('Stop' ,Log.error) --deprecated by built-in standalone Stop
  -- GLOBAL('Error',Log.error) --deprecated by built-in standalone Stop
  GLOBAL('raw_print',Log.get_raw_print())
  _LIB .print = Log.print
  -- _LIB .Log. set_loglevel('DEV MODE') --panic: force override

----STANDALONE-------------------------------------------------------------------------------------
  --generic
  lib3 'String' ('/lua/String.lua','libstring')
  
----EVENT------------------------------------------------------------------------------------------  
  if USE_EVENT_MANAGER and Load_stage.control then
    lib3 'Event_manager' ('/managers/event-manager-8.lua','EM') --libtable, verificate, crc32, elog
    end
  
----LIBRARY----------------------------------------------------------------------------------------
  --wube
  lib3 'Wube' ('/legacy/wube.lua','wube') --sandbox, Load_stage
  
  --coding
  if options.use_event_manager then
    lib3 'Coding' ('/legacy/coding.lua','coding') --elog, crc32, sha256, EM
    -- library .base64       = library .coding .base64
    -- library .sha256       = library .coding .sha256
    -- library .crc32        = library .coding .crc32 
    -- library .json         = library .coding .json  
    -- library .zip          = library .coding .zip   
    end
  
  --debug
  lib3 'Sleep'        ('/debug/sleep.lua'         ,'sleep') --elog
  
  --generic
  lib3 'Misc'         ('/factorio/Misc.lua'       ,'misc') --<nothing yet>
  lib3 'Color'        ('/legacy/libcolor.lua'    ,'libcolor') --libtable, wube
  
  --stage aware
  lib3 'Class'        ('/legacy/class_helper.lua','class_helper') --elog, Load_stage
  lib3 'Recipe'       ('/legacy/librecipe.lua'   ,'librecipe') --class_helper, Load_stage
  lib3 'Box'          ('/legacy/libbox.lua'      ,'libbox') --stop, Load_stage
  lib3 'Position'     ('/legacy/libposition.lua' ,'libpos') --stop
  lib3 'Hotkey'       ('/legacy/libinput.lua'    ,'libinput') --stop, elog, EM, Load_phase(!), Load_stage
  lib3 'Locale'       ('/legacy/liblocale.lua'   ,'liblocale') --stop
  lib3 'Setting'      ('/legacy/libsettings.lua' ,'libsettings') --stop, elog, Load_stage, misc
  
  --stage aware (low quality)
  lib3 'Sprite'       ('/legacy/libsprite.lua'   ,'libsprite') --elog
  lib3 'Tech'         ('/legacy/libtech.lua'     ,'libtech') --load_stage
  lib3 'Data1'        ('/legacy/libdata.lua'     ,'libdata') --IS_DEV_BUILD,elog,libtable,librecipe,libsprite,class_helper
  GLOBAL('Inscribe',libdata.inscribe)
  
  --control stage
  if Load_stage.control then
    --librender is only used by death-marker, "Render" is the new library
    lib3 ()           ('/legacy/librender.lua'   ,'librender') --libposition, libcolor
    lib3 'Player'     ('/legacy/libplayer.lua'   ,'libplayer') --<nothing yet>
    end
  
----LIBRARY 3.0------------------------------------------------------------------------------------  
  GLOBAL('If'  ,function(x,y,z) if x then return y else return z end end)
  GLOBAL('Try' ,function(f,x,...) if f and x then return f(x,...) end end)
  GLOBAL('Stopper',function(...) local args = {...}
    return function (...) Stop(unpack(Table.mutate.append(args,{...}))) end end)
  
  lib3 'Set'            ('/lua/Set.lua'   )
  lib3 'Lambda'         ('/lua/Lambda.lua')
  GLOBAL('L',Lambda.Lambda)
  GLOBAL('F',Lambda.Filter)
  lib3 'Object'         ('/lua/Object.lua')
  
  lib3 'Math'           ('/factorio/Math.lua')
  
  lib3 'Vector'         ('/lua/Vector-2.lua') --Math
  lib3 'Logic'          ('/lua/Logic.lua' )
  
  
  
  if Load_stage.control then
    lib3 'Gui'          ('/factorio/Gui-4.lua')
    lib3 'Entity'       ('/factorio/Entity-1.lua')
    lib3 'Render'       ('/factorio/Render-1.lua')
  else
    lib3 'Data'         ('/lua/Data.lua')
    end
    
  
  
  if USE_EVENT_MANAGER then --savedata management doesn't work without
    lib3 'Plugin_manager' ('/managers/plugin-manager-4.lua')
    end
    
  --data only
  if Load_phase.data_final_fixes then
    lib3()('/styles/textbox.lua')
    end
    
----LIBRARY PLUGINS--------------------------------------------------------------------------------
  if USE_PLUGINS then
    local LIBPM = Plugin_manager(_LIB,_Lib_root..'/assets','library_plugins')
    local library_plugin_list = require(_Lib_root ..'/plugins.lua')()
    AMap(library_plugin_list,F('a.load_plugin(x,b)',LIBPM,_Lib_root..'/plugins'))
    if IS_DEV_BUILD and Load_phase.settings then
      Log.debug('LIBRARY','Active plugins:')
      for _,path in pairs(library_plugin_list) do raw_print(' ',path) end
      raw_print()
      end

----LOCALES 3.0------------------------------------------------------------------------------------
    if IS_DEV_BUILD and Load_stage .control then
    -- Stop(Load_stage,IS_DEV_BUILD)
      local z = '__zz-universal-locale__/remote'
      if remote.interfaces[z] then
        require(z)({_LIB.Log   .locale},'library') --Logger locale
        require(z)({_LIB.Locale.locale},'library') --Library collected locales
        require(z)(LIBPM.get_ulocales(),'library') --Plugin Manager collected locales
        end
      end

    end

----INSTALL 3.1--------------------------------------------------------------------------------------
  GLOBAL('IS_INSTALLED',false)
  GLOBAL('Install',function(_ER)
    Table .mutate .merge(_ER,_LIB) --todo: better copy the library first?
    _ER ._G  = _ER
    GLOBAL('InstalledENV',_ER) --for later setting Load_phase/stage.runtime = true
    _LIB.IS_INSTALLED = true
    return _ER
    end)
  

----FACTORIO RUNTIME FIX---------------------------------------------------------------------------
  --transparently fetch delayed global tables (must be *after* lock)
  if Load_stage .control then
    local runtime_keys = {game=true,rendering=true,global=false}
    local mt = debug.getmetatable(_LIB)
    local fi = mt.__index
    mt.__index=function(self,key)
      if runtime_keys[key] and PublicENV[key] then
        rawset(self,key,PublicENV[key])
        return PublicENV[key]
      else
        -- return fi(self,key) --if auto_lock_table __index is function
        return fi[key]      --if auto_lock_table __index is table
    end end end

----TESTS + ASSUMPTIONS----------------------------------------------------------------------------
  --some things are assumed about base game values to gain performance
  --if any of these change the library won't work.
  do local function t (path) lib3()('/tests'..path) end
    if Load_phase.settings then
      t '/assume_defines_directions.lua'
      t '/assume_defines_events_on_tick.lua'
      t '/test_Sha2.lua'
      t '/test_Table.lua'
      end
    if Load_phase.control then 
      t '/assume_game_pairs_key_is_index.lua'
      end  
    end
  
----LEGACY-----------------------------------------------------------------------------------------
  --plugin format 2.x requires indexable tables during all phases
  if rawget(_LIB,'EM'       ) == nil then _LIB.GLOBAL('EM'       ,{}) end
  if rawget(_LIB,'librender') == nil then _LIB.GLOBAL('librender',{}) end
  if rawget(_LIB,'libplayer') == nil then _LIB.GLOBAL('libplayer',{}) end

  
----END--------------------------------------------------------------------------------------------
  return _LIB
  end
  
return __init__


