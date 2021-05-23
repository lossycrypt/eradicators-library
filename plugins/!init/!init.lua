-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
-- Outside of factorio '__eradicators-library__' is not a valid absolute path!
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))
  
-- -------------------------------------------------------------------------- --
return function(phase) assert(phase)

  --[[
    
    If you are a mod author who wants to use library hook features, simply call
    one of these enabler functions during settings or settings-updates, erlib
    will take care of everything else.
    
    Available functions:
      erlib_enable_bablefish()
      erlib_enable_cursor_tracker() -- to be implemented...
      erlib_enable_zoom_tracker()   -- to be implemented...
      
    ]]

  -- ------------------------------------------------------------------------ --
  -- Settings                                                                 --
  -- ------------------------------------------------------------------------ --
  if phase == 'settings' then

    local Data  = elreq('erlib/factorio/Data/!init')()
    local Table = elreq('erlib/lua/Table'     )()
    
    local function make_enabler(prototype)
      return function()
        data.raw['bool-setting'][prototype.name].forced_value = true
        end
      end
      
    local dummy = {
      type          = 'bool-setting' ,
      setting_type  = 'startup'      ,
      order         = 'zz'           ,
      hidden        = true           ,
      default_value = false          ,
      forced_value  = false          , -- Only loaded if hidden = true
      }

    _ENV .erlib_enable_bablefish = make_enabler(
      Data.Inscribe(Table.smerge(dummy, {
        name  = 'erlib:enable-babelfish',
        order = 'ZZ9 Plural Z Alpha'    ,
      })))

    _ENV .erlib_enable_cursor_tracker = make_enabler(
      Data.Inscribe(Table.smerge(dummy,{
        name  = 'erlib:enable-cursor-tracker',
      })))

    _ENV .erlib_enable_zoom_tracker = make_enabler(
      Data.Inscribe(Table.smerge(dummy,{
        name  = 'erlib:enable-zoom-tracker',
      })))
      
  -- ------------------------------------------------------------------------ --
  -- Settings Final Fixes                                                     --
  -- ------------------------------------------------------------------------ --
  elseif phase == 'settings-final-fixes' then
  
    if data.raw['bool-setting']['erlib:enable-babelfish'].forced_value then
      require 'plugins/babelfish/settings-final-fixes'
      end

  -- ------------------------------------------------------------------------ --
  -- Data Final Fixes                                                         --
  -- ------------------------------------------------------------------------ --
  elseif phase == 'data-final-fixes' then

    if settings.startup['erlib:enable-cursor-tracker'].value then
      require 'plugins/cursor-tracker/data-final-fixes.lua'
      end
    
    if settings.startup['erlib:enable-babelfish'].value then
      require 'plugins/babelfish/data-final-fixes'
      end
    
  -- ------------------------------------------------------------------------ --
  -- Control                                                                  --
  -- ------------------------------------------------------------------------ --
  elseif phase == 'control' then
    
    -- ---------------------------------------------------------------------- --
    -- Universal Locale (internal condition check)                            --
    -- ---------------------------------------------------------------------- --
    require 'plugins/babelfish/ulocale'
    
    -- ---------------------------------------------------------------------- --
    -- Hooks & Nooks                                                          --
    -- ---------------------------------------------------------------------- --
    local function f(n) return _ENV.settings.startup[n].value end
    local settings = {
      enable_bablefish      = f 'erlib:enable-babelfish'     ,
      enable_cursor_tracker = f 'erlib:enable-cursor-tracker',
      enable_zoom_tracker   = f 'erlib:enable-zoom-tracker'  ,
      }
      
    -- When *at least one* plugin has been requested.
    for _, v in pairs(settings) do if v then

      _ENV. PluginManager = require ('erlib/factorio/PluginManagerLite-1')()
      _ENV. EventManager  = require ('erlib/factorio/EventManagerLite-1' )()
      require ('erlib/lua/Lock')().AutoLock(_ENV, '_ENV', 'GLOBAL')

      PluginManager.enable_savedata_management()

      if settings.enable_bablefish then require('plugins/babelfish/control.lua') end
      
      break end end
      
    end
    
  end