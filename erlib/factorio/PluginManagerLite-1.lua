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
  
--[[ Todo:

  + in on_config walk through all garbage collected Savedata
    and clean up the mess caused by events not being raised 
    before on_config when other mods mess stuff up. (yet again)
    
  ]]

-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Eradicators Library                                                        --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
local log         = elreq('erlib/lua/Log'       )().Logger  'PluginManagerLite'
local stop        = elreq('erlib/lua/Error'     )().Stopper 'PluginManagerLite'

local Stacktrace  = elreq('erlib/factorio/Stacktrace')()

local Table       = elreq('erlib/lua/Table'     )()
local Set         = elreq('erlib/lua/Set'       )()

local Verificate  = elreq('erlib/lua/Verificate')()
local verify      = Verificate.verify

local join_path   = elreq('erlib/factorio/Data/!init')().Path.join

local require     = _ENV. require -- keep a proper reference

local ntuples     = elreq('erlib/lua/Iter/ntuples')()

-- -------------------------------------------------------------------------- --
-- Constants                                                                  --
-- -------------------------------------------------------------------------- --

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --
local Public  = {}
local Private = {}

setmetatable(Public, {__index=function(_,method)
  stop (('Unknown PluginManagerLite method "%s".\n'):format(method)
  ..'Forgot to call enable_savedata_management()?')
  end})

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
  assert(plugin_name ~= 'template', 'Please change the default name!')
  -- if mod_name == 'local' then mod_name = erlib.Const.mod_name end
  if mod_name == nil then mod_name = Stacktrace.get_mod_name(2) end
  -- local root = '__' .. mod_name .. '__' .. '/assets/' .. plugin_name
  local root = join_path('__'..mod_name..'__', '/assets/', plugin_name)
  return function(path) return join_path(root, path) end
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
  assert(plugin_name ~= 'template', 'Please change the default name!')
  -- local root =
    -- (mod_name and ('__'..mod_name..'__/') or '') ..'plugins/' ..plugin_name
  local root = join_path(
    (mod_name and ('__'..mod_name..'__/') or nil), 'plugins/', plugin_name
    )
  return function (path) return require(join_path(root, path)) end
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
-- @function PluginManagerLite.enable_savedata_management
function Public.enable_savedata_management()
    
  local EventManager= elreq('erlib/factorio/EventManagerLite-1')()
  local script      = EventManager.get_managed_script('plugin-manager')

  local ManagedPlugins = {--[[
    [plugin_name] = {
      path    = {'plugin_manager', 'plugins', plugin_name}
      setter  = function() end
      mt      = {__index = methods}
      manage_garbage = nil or true
      manage_version = nil or true
      }
    ]]}
    
  ----------
  -- Automatically loads global Savedata and assigns local references.
  --
  -- Multiple setters can be associated with the same plugin_name.
  -- This allows using local Savedata references in all files used by a plugin.
  --
  -- Can only be used after @{PluginManagerLite.enable_savedata_management|enable_savedata_management}.
  --
  -- @tparam string plugin_name
  -- @tparam function setter Will be called setter(Savedata) in on\_load and on\_config.
  -- (See @{EventManagerLite.boostrap_event_order} regarding on\_init.)
  -- @tparam[opt] table default The default layout for your Savedata.
  -- Use if you want certain subtables to always exist. In on_config any
  -- key that doesn't exist in the Savegame yet will be copied from this.
  -- This parameter may only be given once for each plugin\_name.
  --
  -- @usage
  --   local Savedata
  --   PluginManager.manage_savedata(
  --      'plugin_name',
  --      function(_) Savedata = _ end,
  --      {players = {}, forces = {}, surfaces = {}, map = {}}
  --      )
  --
  -- @function PluginManagerLite.manage_savedata
  function Public.manage_savedata(plugin_name, setter, default)
    assert(plugin_name ~= 'template', 'Please change the default name!')
    -- Multiple setters can exist for each plugin_name.
    log:debug('Recieved savedata setter for ', plugin_name)
    local this   = Table.sget(ManagedPlugins, {plugin_name}, {})
    this.path    = {'plugin_manager', 'plugins', plugin_name}
    if default ~= nil then
      assert(this.default == nil, 'Savedata default may only be specified once.')
      verify(default.version, 'nil|NaturalNumber', '"version" has wrong data type.')
      -- this.default = Table.dcopy(default)
      this.default = default -- direct references == less bugs? ensures there's only one authorative table
      end
    table.insert(Table.sget(this, {'setters'}, {}), setter)
    end

  ----------
  -- Retrieves the previously supplied default table.
  --
  -- @tparam string plugin_name
  --
  -- @treturn table A __reference__ to the `default` table
  -- given to @{PluginManagerLite.manage_savedata}. Changing
  -- the table __will directly affect__ the default for this plugin.
  -- It is an error if the plugin does not have a `default` table set yet.
  --
  -- @function PluginManagerLite.get_savedata_default
  function Public.get_savedata_default(plugin_name)
    local this = assert(Table.get(ManagedPlugins, {plugin_name}),
      'Invalid plugin_name')
    return assert(this.default, 'No default given for this plugin.') end
    
  ----------
  -- Automatically adds meta-methods to Savedata in on\_load and on\_config.
  -- 
  -- This only has to be called once per plugin_name as it affects all setters.
  -- 
  -- This also enables automatic creation-on-first-access of Savedata sub-tables
  -- 'players','forces','surfaces' and 'map' if the methods table
  -- has no metatable itself.
  -- 
  -- Can only be used after @{PluginManagerLite.enable_savedata_management|enable_savedata_management}.
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
  local function inject_defaults(Savedata, defaults)
    
    end
  
  local function relink_savedatas()
    -- Writing to _ENV.global is not allowed during on_load.
    local is_on_load = not ((rawget(_ENV, 'game') or {}).object_name)
    local method     = (not is_on_load) and 'sget' or 'get'
    for plugin_name, this in pairs(ManagedPlugins) do
      local default  = (not is_on_load) and (Table.dcopy(this.default) or {}) or nil
      local Savedata = Table[method](_ENV.global, this.path, default)
      if (Savedata == nil) then -- can be nil in on_load
        log:debug('No Savedata found for: ', plugin_name)
      else
        if not is_on_load then
          for k, v in ntuples(2, this.default) do
            if not Savedata[k] then
              log:debug(plugin_name, ' default Savedata: ', k, ' = ', v)
              Savedata[k] = Table.dcopy(v) -- guaranteed defaults
            else
              log:say(plugin_name, ' default Savedata: ', k, ' (already exists.)')
              end
            end
          end
        setmetatable(Savedata, this.mt)
        for i=1, #this.setters do this.setters[i](Savedata) end
        log:debug('Completed linking Savedata for: ', plugin_name)
        end
      end
    end
    
  local function ensure_savedata_root_exists()
    -- Must be created even if no plugins are registered.
    assert(Table.sget(_ENV.global, {'plugin_manager', 'plugins'}, {}))
    end

  local function delete_unused_savedatas()
    local Savedatas = Table.get(_ENV.global, {'plugin_manager', 'plugins'})
    for plugin_name, _ in pairs(Savedatas) do
      if not ManagedPlugins[plugin_name] then
        log:debug('delete unknown Savedata: ', plugin_name)
        Savedatas[plugin_name] = nil
        end
      end
    end
    
  -- manage_version
  local function delete_outdated_savedatas()
    local Savedatas = Table.get(_ENV.global, {'plugin_manager', 'plugins'})
    for plugin_name, Savedata in pairs(Savedatas) do
      local this = assert(ManagedPlugins[plugin_name])
      if this.manage_version
      then
        if (this.default.version ~= Savedata.version)
        then
          Savedatas[plugin_name] = nil
          log:debugf('Savedata version outdated + deleted (v%s => v%s for %s).'
            , Savedata.version or '<unset>.', this.default.version, plugin_name)
        else
          log:debugf('Savedata version ok. (v%s for %s).'
            , assert(Savedata.version), plugin_name)
          end
        end
      end
    end
    
    
  script.on_load(function()
    -- print('PM on_load')
    relink_savedatas()
    end)

  script.on_config(function(e)
    -- print('PM on_init')
    -- print('PM on_config')
    ensure_savedata_root_exists()
    delete_unused_savedatas()
    delete_outdated_savedatas()
    relink_savedatas()
    end)

    
  ----------
  -- Automatically deletes all Savedata when outdated.
  --
  -- When PluginManagerLite detects that during `on_config`
  -- the value of `Savedata.version` in a loaded map is not identical with the
  -- value of `default.version` then
  -- __all Savedata is unconditionally deleted__ and `default` values are restored.
  --
  -- Can only be used after @{PluginManagerLite.manage_savedata|manage_savedata}.  
  -- Can only be used after @{PluginManagerLite.enable_savedata_management|enable_savedata_management}.  
  --
  -- @tparam string plugin_name
  --
  -- @function PluginManagerLite.manage_version
  function Public.manage_version(plugin_name)
    local this = assert(ManagedPlugins[plugin_name], 'Unknown plugin name.')
    assert(this.default, 'No default data given.')
    verify(this.default.version, 'NaturalNumber', 'Invalid version')
    this.manage_version = true
    end
  
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
  -- Can only be used after @{PluginManagerLite.enable_savedata_management|enable_savedata_management}.
  -- 
  -- @tparam string plugin_name
  -- 
  -- @function PluginManagerLite.manage_garbage
  function Public.manage_garbage(plugin_name)
    assert(ManagedPlugins[plugin_name], 'Unknown plugin name.')
      .manage_garbage = true
    end
    
  local script = EventManager.get_managed_script('plugin-manager-gc')

  
  local function _gc(data_key, event_key) -- makes collectors
    return function(e)
      -- Removes associated savedata when objects are deleted.
      for plugin_name, this in pairs(ManagedPlugins) do
        if this.manage_garbage then
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
do (STDOUT or log or print)('  Loaded → erlib.PluginManagerLite') end
return function() return Public, nil, nil end



