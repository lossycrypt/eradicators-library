-- (c) eradicator a.k.a lossycrypt, 2021, not seperately licensable

--------------------------------------------------------------------------------
-- Helper for developing mod-like plugins and softmods.
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

local join_path   = elreq('erlib/factorio/Data/!init')().Path.join

local require     = _ENV. require -- keep a proper reference

-- -------------------------------------------------------------------------- --
-- Constants                                                                  --
-- -------------------------------------------------------------------------- --

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --
local Public  = {}
local Private = {}

--------------------------------------------------------------------------------
-- Startup methods.
-- @section
--------------------------------------------------------------------------------

----------
-- A function to convert relative asset paths into absolute file paths.
--
-- @usage
--   local f = PluginManager.make_asset_getter('my-plugin-name', 'my-mod-name')
--   print(f('/my-file-name.png'))
--   > "__my-mod-name__/assets/my-plugin-name/my-file-name.png"
--   
-- @tparam string plugin_name
-- @tparam[opt] string mod_name Defaults to the name of the mod that called this function.
--
-- @treturn function f(path)
--
function Public.make_asset_getter(plugin_name, mod_name)
  -- if mod_name == 'local' then mod_name = erlib.Const.mod_name end
  if mod_name == nil then mod_name = Stacktrace.get_mod_name(2) end
  -- local root = '__' .. mod_name .. '__' .. '/assets/' .. plugin_name
  local root = join_path('__'..mod_name..'__', '/assets/', plugin_name)
  return function(path) return root .. path end
  end

  
--------------------------------------------------------------------------------
-- Generic methods.
-- @section
--------------------------------------------------------------------------------
  
----------
-- Creates a require function that works relative to a plugins directory.
--
-- @tparam string plugin_name
-- @tparam[opt] string mod_name Defaults to the name of the mod that called this function.
--
-- @usage
--   local import = PluginManager.make_relative_require('my-plugin-name', 'my-mod-name')
--   local my_module = import('/my-module-name.lua')
--
-- @treturn function f(path)
--   The function will call @{LMAN require} like this:  
--   `require("__my-mod-name__/plugins/my-plugin-name/"..path)`.
--
function Public.make_relative_require(plugin_name, mod_name)
  -- local root =
    -- (mod_name and ('__'..mod_name..'__/') or '') ..'plugins/' ..plugin_name
  local root = join_path(
    (mod_name and ('__'..mod_name..'__/') or nil), 'plugins/', plugin_name
    )
  return function (path) return require(root .. path) end
  end


--------------------------------------------------------------------------------
-- Savedata management.
-- @section
--------------------------------------------------------------------------------
  
----------
-- The save-load-cycle persistant data of a plugin.
-- 
-- A sub-table of the global table called @{FAPI global global}, 
-- that contains all data created and stored by a single plugin.
-- 
-- @table Savedata
do end
  
  
----------
-- Starts the savedata management engine.
-- 
-- This requires unrestricted exclusive access to
-- `global.plugin_manager`. Do not touch it.
--
-- __Note:__ Implicitly loads @{EventManagerLite}. Can not be used without.  
-- __Note:__ The other savedata management methods do not exist before calling this.
--
-- @function PluginManagerLite.enable_savedata_manager
function Public.enable_savedata_manager()
    
  local EventManager= elreq('erlib/factorio/EventManagerLite-1')()
  local script      = EventManager.get_managed_script('plugin-manager')

  local ManagedPlugins = {--[[
    [plugin_name] = {
      path    = {'plugin_manager', 'plugins', plugin_name}
      setter  = function() end
      want_gc = nil or true
      mt      = {__index = methods}
      }
    ]]}
    
  ----------
  -- Automatically loads global Savedata and assigns local references.
  --
  -- Multiple setters can be associated with the same plugin_name.
  -- This allows using local Savedata references in all files used by a plugin.
  --
  -- 
  --
  -- Can only be uesd after @{PluginManagerLite.enable_savedata_manager}.
  --
  -- @tparam string plugin_name
  -- @tparam function setter Will be called setter(Savedata) in on\_load and on\_config.
  -- (See @{EventManagerLite.boostrap_event_order} regarding on_init.)
  --
  -- @usage
  --   local Savedata; PM.manage_savedata('my-plugin', function(_) Savedata = _ end)
  --
  -- @function PluginManagerLite.manage_savedata
  function Public.manage_savedata(plugin_name, setter)
    -- Multiple setters can exist for each plugin_name.
    local this  = Table.sget(ManagedPlugins, {plugin_name}, {})
    this.path   = {'plugin_manager', 'plugins', plugin_name}
    table.insert(Table.sget(this, {'setters'}, {}), setter)
    end

  ----------
  -- Automatically adds meta-methods to Savedata in on\_load and on\_config.
  -- 
  -- This only has to be called once per plugin_name as it affects all setters.
  -- 
  -- Can only be uesd after @{PluginManagerLite.enable_savedata_manager}.
  -- 
  -- @tparam string plugin_name
  -- @tparam table methods This table will be assigned as the __index metatable
  -- for the Savedata table.
  -- 
  -- @function PluginManagerLite.classify_savedata
  function Public.classify_savedata(plugin_name, methods)
    local this = assert(ManagedPlugins[plugin_name], 'Unknown plugin name.')
    this.mt    = {__index = methods}
    end

  --
  local function relink_savedatas()
    -- Writing to _ENV.global is not allowed during on_load.
    local is_on_load = not ((rawget(_ENV, 'game') or {}).object_name)
    local method     = (not is_on_load) and 'sget' or 'get'
    for plugin_name, this in pairs(ManagedPlugins) do
      -- local default  = (not is_on_load) and    {plugin_name=plugin_name}  or  nil
      local default  = (not is_on_load) and {} or nil
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

    
  ----------
  -- Automatically deletes player, force and surface related
  -- Savedata when it becomes invalid.
  -- 
  -- Assumes Savedata contains subtables "players", "surfaces" and/or "forces",
  -- using the respective objects "index" as keys.
  -- 
  -- Because it's easy to forget to always subscribe to 
  -- @{FAPI events.on_player_removed},
  -- @{FAPI events.on_forces_merged} and
  -- @{FAPI events.on_surface_deleted}.
  -- 
  -- Garbage collection is called after all other EventManagerLite event
  -- handlers have finished processing the respective event.
  -- __Note:__ Be careful when you subscribe to one of the above events
  -- youself. If you create new data with the old index it will still be
  -- deleted at the end of the event.
  -- 
  -- Can only be uesd after @{PluginManagerLite.enable_savedata_manager}.
  -- 
  -- @tparam string plugin_name
  -- 
  -- @function PluginManagerLite.manage_garbage
  function Public.manage_garbage(plugin_name)
    assert(ManagedPlugins[plugin_name], 'Unknown plugin name.').want_gc = true
    end
    
  local script = EventManager.get_managed_script('plugin-manager-gc')

  
  local function _gc(data_key, event_key) -- makes collectors
    return function(e)
      -- Removes associated savedata when objects are deleted.
      for plugin_name, this in pairs(ManagedPlugins) do
        if this.want_gc then
          local Savedata = assert(Table.get(_ENV.global, this.path))
          if Savedata[data_key] then
            Savedata[data_key][e[event_key]] = nil
            end
          end
        end
      end
    end
    
  script.on_event(defines.events.on_player_removed , _gc('players' , 'player_index' ))
  script.on_event(defines.events.on_forces_merged  , _gc('forces'  , 'source_index' ))
  script.on_event(defines.events.on_surface_deleted, _gc('surfaces', 'surface_index'))
    
  end


-- -------------------------------------------------------------------------- --
-- Documentation                                                                        --
-- -------------------------------------------------------------------------- --

  
-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded Å® erlib.PluginManagerLite') end
return function() return Public, nil, nil end



