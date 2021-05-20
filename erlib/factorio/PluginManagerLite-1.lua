-- (c) eradicator a.k.a lossycrypt, 2021, not seperately licensable

--------------------------------------------------------------------------------
-- Helper for developing mod-like plugins and softmods.
-- 
-- PluginManagerLite Requires unrestricted exclusive access to
-- `global.plugin_manager`. Do not touch it.
-- 
-- __Dependency:__ Implicitly loads @{EventManagerLite}.
-- 
-- @{Introduction.DevelopmentStatus|Module Status}: Work in progress.
--
-- @module PluginManagerLite
-- @usage
--  local PluginManager = require('__eradicators-library__/erlib/factorio/PluginManagerLite-1')()

--[[ Notes:

  
  ]]

-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
local log         = elreq('erlib/lua/Log'       )().Logger  'PluginManagerLite'
local stop        = elreq('erlib/lua/Error'     )().Stopper 'PluginManagerLite'

local Stacktrace  = elreq('erlib/factorio/Stacktrace')()

local Table       = elreq('erlib/lua/Table'     )()

local Verificate  = elreq('erlib/lua/Verificate')()
local verify      = Verificate.verify


-- -------------------------------------------------------------------------- --
-- Constants                                                                  --
-- -------------------------------------------------------------------------- --


-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --
local Public  = {}
local Private = {}



--------------------------------------------------------------------------------
-- Public methods.
-- @section
--------------------------------------------------------------------------------


-- -------------------------------------------------------------------------- --
-- Startup: Assets

----------
-- A function to convert relative asset paths into absolute file paths.
--
-- f('/file-name.png') -> '__mod-name__/assets/plugin-name/file-name.png'
function Public.make_asset_getter(plugin_name, mod_name)
  -- if mod_name == 'local' then mod_name = erlib.Const.mod_name end
  if mod_name == nil then mod_name = Stacktrace.get_mod_name(2) end
  local root = '__' .. mod_name .. '__' .. '/assets/' .. plugin_name
  return function(path) return root .. path end
  end

----------
-- Creates a require function that works relative to a plugins directory.
function Public.make_relative_require(plugin_name, mod_name)
  local root =
    (mod_name and ('__'..mod_name..'__/') or '') ..'plugins/' ..plugin_name
  local require = _ENV. require
  return function (path) return require(root .. path) end
  end
  
-- -------------------------------------------------------------------------- --
-- Runtime: Savedata Re-Linking
  
----------
function Public.enable_savedata_manager()
    
  local EventManager= elreq('erlib/factorio/EventManagerLite-1')()
  local script      = EventManager.get_managed_script('plugin-manager')

  local ManagedPluginSavedata = {}
    
    
  ----------
  -- Automatically creates local references to global.
  -- @tparam string plugin_name
  -- @tparam function setter Will be called setter(Savedata).
  --
  -- @usage
  --   local Savedata; PM.manage_savedata('my-plugin', function(_) Savedata = _ end)
  --
  function Public.manage_savedata(plugin_name, setter)
    -- Multiple setters can exist for each plugin_name.
    local this  = Table.sget(ManagedPluginSavedata, {plugin_name}, {})
    this.path   = {'plugin_manager', 'plugins', plugin_name}
    table.insert(Table.sget(this, {'setters'}, {}), setter)
    end

  ----------
  -- Automatically adds meta methods to Savedata.
  function Public.classify_savedata(plugin_name, methods)
    -- Each plugin shares a single metatable.
    local this = assert(Table.get(ManagedPluginSavedata, {plugin_name}))
    this.mt    = {__index = methods}
    end

  --
  local function relink_savedatas()
    -- Writing to _ENV.global is not allowed during on_load.
    local is_on_load = not ((rawget(_ENV, 'game') or {}).object_name)
    local method     = (not is_on_load) and 'sget' or 'get'
    for plugin_name, this in pairs(ManagedPluginSavedata) do
      local default  = (not is_on_load) and    {plugin_name=plugin_name}  or  nil
      local Savedata = Table[method](_ENV.global, this.path, default)
      -- print(plugin_name, serpent.block(Savedata))
      if (Savedata ~= nil) then -- can be nil in on_load
        setmetatable(Savedata, this.mt)
        for i=1, #this.setters do this.setters[i](Savedata) end
        end
      end
    -- print(serpent.block(_ENV.global))
    end


    
  script.on_load(function()
    -- print('PM on_load')
    relink_savedatas()
    end)

  script.on_config(function(e)
    -- print('PM on_init')
    -- print('PM on_config')
    relink_savedatas()
    end)

    
  -- ------------------------------------------------------------------------ --
  -- Runtime: Savedata Garbage Collection

  ----------
  -- Must be called after all plugins have called manage_savedata.
  -- 
  -- Assumes Savedata contains subtables players, surfaces and/or forces,
  -- using the respective objects "index" as keys.
  -- 
  -- Automatically deletes related subtable when the object is removed from the game.
  -- Because it's really easy to forget about this.
  -- 
  -- Can only be uesd after @{PluginManagerLite.enable_savedata_manager}.
  -- 
  function Public.enable_savedata_garbage_collector()

    local script = EventManager.get_managed_script('plugin-manager-gc')

    local function _gc(data_key, event_key) return function(e)
      -- Removes associated savedata when objects are deleted.
      for plugin_name, this in pairs(ManagedPluginSavedata) do
      -- for _, path in pairs(SavedataSetters) do
        local Savedata = assert(Table.get(_ENV.global, this.path))
        if Savedata[data_key] then
          Savedata[data_key][e[event_key]] = nil
          end
        end
      end end
      
    script.on_event(defines.events.on_player_removed , _gc('players' , 'player_index' ))
    script.on_event(defines.events.on_surface_deleted, _gc('surfaces', 'surface_index'))
    script.on_event(defines.events.on_forces_merged  , _gc('forces'  , 'source_index' ))

    end
    
  end
  
-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded Å® erlib.PluginManagerLite') end
return function() return Public, nil, nil end
