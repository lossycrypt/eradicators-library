-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Description
--
-- @{Introduction.DevelopmentStatus|Module Status}: Deprecated, use @{PluginManagerLite}.
--
-- @module PluginManager
-- @usage
--  local PluginManager = require('__eradicators-library__/erlib/factorio/PluginManager')()
  
--[[ TODO:

    Simulate: 
      + create surface/force/player/technology event for every plugin
        that is NEWLY ADDED to a game.
      ! careful not to simulate more than once (when EM also simulates?)


--]]
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Eradicators Library                                                        --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --

local Log   = elreq('erlib/lua/Log'  )()
local Error = elreq('erlib/lua/Error')()

local log   = Log.Logger    'PluginManager'
local stop  = Error.Stopper 'PluginManager'

local Verificate = elreq('erlib/lua/Verificate')()
local Verify           , Verify_Or
    = Verificate.verify, Verificate.verify_or

-- local Tool       = elreq('erlib/lua/Tool'      )()
    
local Lock       = elreq('erlib/lua/Lock')()
    
local Table      = elreq('erlib/lua/Table'     )()
-- local Array      = elreq('erlib/lua/Array'     )()
local Set        = elreq('erlib/lua/Set'       )()

-- local Crc32      = elreq('erlib/lua/Coding/Crc32')()

-- local Cache      = elreq('erlib/factorio/Cache')()

-- local L          = elreq('erlib/lua/Lambda'    )()

-- local LuaBootstrap = script

-- local Table_dcopy
    -- = Table.dcopy

-- local setmetatable, pairs, ipairs, select
    -- = setmetatable, pairs, ipairs, select
    
-- local table_insert, math_random, math_floor, table_unpack, table_remove
    -- = table.insert, math.random, math.floor, table.unpack, table.remove



-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local PluginManager,_PluginManager,_uLocale = {},{},{}



-- -------------------------------------------------------------------------- --
-- Metatable                                                                  --
-- -------------------------------------------------------------------------- --

local _manager_mt = {__index = PluginManager}

local function try_is_manager(obj)
  return (getmetatable(obj) == _manager_mt) or stop('Not a manager:\n', obj)
  end

-- -------------------------------------------------------------------------- --
-- Named Environments                                                         --
-- -------------------------------------------------------------------------- --

local Managers = {}

-- -------------------------------------------------------------------------- --
-- Helper Functions                                                           --
-- -------------------------------------------------------------------------- --

local function make_locked_savedata_dummy (name)
  return setmetatable({},{
    __index = function() stop(
      'Savedata *read* access not available for plugin "', name, '".'
      ) end,
    __newindex = function() stop(
      'Savedata *write* access not available for plugin "', name, '".'
      ) end,
    })
  end

--@tparam PluginManager self A PM table.
local function create_manager_savedata_events (self)
  -- Savedata
    
  if not rawget(_ENV,'EventManager') then
    -- Can not require because EventManager has side-effects that
    -- the user must conciously accept.
    stop('PluginManager requires "EventManager" to be in public _ENV.')
    end
  
  log:debug('Activating Savedata management events for manager: "', self.name, '".')
    
  -- automatic object instance indexed subtables
  local function auto_subindexes(tbl, category, plugin_name)
    return setmetatable(tbl, {
      __index = function(self,key)
        if type(key) == 'number' then
          log:debug('Created new index ', category,'[', key,'] for plugin "', plugin_name, '".')
          return Table.set(self, {key}, {})
          end
        end
      })
    end

  -- automatic category subtables
  local auto_keys = Set.from_values{'players', 'surfaces', 'forces', 'map'}
  local function auto_subtables(tbl, plugin_name)
    setmetatable(tbl, {
      __index = function(self, key)
        if auto_keys[key] then
          log:debug('Created new subtable ', key,' for plugin "', plugin_name, '".')
          -- return Table.set(self, {key}, {})
          return Table.set(self, {key}, auto_subindexes({}, key, plugin_name) )
          end
        end
      })
    end
    
  local function apply_savedata_meta(Savedata, plugin_name)
    -- log:tell('Before apply_savedata_meta', Savedata)
    if Savedata then
      setmetatable(Savedata, nil) -- on_load before on_config, aaargg...
      for category in pairs(auto_keys) do
        if Savedata[category] then
    -- log:tell('Before apply_savedata_meta', Savedata,auto_keys,category)
          -- log:debug('type',type(Savedata[category]))
          auto_subindexes(Savedata[category], category, plugin_name);
          end
        end
      auto_subtables(Savedata, plugin_name)
      end
    end
  

  
  EventManager.new_handler {
    EventManager.event_uid.on_load,
    name_prefix = self.name..'-plugin-manager',
    function()
      for plugin_name, env in pairs(self.plugin_envs) do
        local Savedata = Table.get(_ENV.global, {'plugin_manager','plugins', plugin_name})
        if Savedata then 
          env.Savedata = Savedata
          apply_savedata_meta(Savedata, plugin_name)
        else
          env.Savedata = make_locked_savedata_dummy(plugin_name)
          end
        
        end
      -- log:tell('GLOBAL after on_load', global)
      end
    }
    
  EventManager.new_handler {
    {EventManager.event_uid.on_init  ,
     EventManager.event_uid.on_config},
    name_prefix = self.name..'-plugin-manager',
    function()
      for plugin_name, env in pairs(self.plugin_envs) do
        env.Savedata = Table.sget(_ENV.global, {'plugin_manager','plugins', plugin_name}, {})
        apply_savedata_meta(env.Savedata, plugin_name)
        end
      end
    }
  
  --@future: subscribe to removal events
  
  
  end

--------------------------------------------------------------------------------
-- Creation.
-- @section
--------------------------------------------------------------------------------


----------
-- Creates a new PluginManager object.
-- 
-- @tparam table config
-- @tparam string config.name The name for the new manager object.
-- @tparam table config.main_env The default environment for all plugins that
-- this manager manages.
-- @tparam table config.extra_shared_env Extra data for the shared environment.
-- @tparam[opt] string config.asset_root The default root path used for
-- @{PluginManager.plugasset|plugasset}.
-- 
-- @treturn PluginManager A manager instance.
-- 
function PluginManager.new_manager(config)
  -- user input
  Verify(config.name        ,'NonEmptyString')
  Verify(config.main_env    ,'NonEmptyTable')
  Verify(config.asset_root  ,'nil|NonEmptyString')
  -- Verify(config.plugin_root ,'nil|NonEmptyString')
  Verify(config.extra_shared_env,'nil|tbl')
  local manager = Table.clear(config,{
    'main_env','plugin_root','asset_root','name','extra_shared_env'
    })
  Verify(Managers[manager.name],'nil','Duplicate manager name.')
  -- internal config
  manager.plugin_env_mt = {__index = manager.main_env}
  manager.plugin_envs = {}
  -- registry
  Managers[manager.name] = manager
  setmetatable(manager,_manager_mt);
  -- shared environment
  local shared_env = manager:make_env {
    PLUGIN_NAME       = 'SharedEnvironment',
    PLUGIN_LUA_ROOT   = manager.plugin_root,
    PLUGIN_ASSET_ROOT = manager.asset_root ,
    }
    
  -- Savedata must be per-plugin. Block shared.
  shared_env.Savedata = Lock.AutoLock({},'SharedEnvironment Savedata')
  
  manager.shared_env = shared_env
    
  if config.extra_shared_env then
    for k,v in pairs(config.extra_shared_env) do
      -- error(k)
      shared_env[k] = v
      end
    end
    
  if flag.IS_FACTORIO_CONTROL then
    create_manager_savedata_events(manager)
    end
    
    
  return manager
  end

  
----------
-- Fetches a previously created PluginManager object.
--
-- @tparam string manager_name
--
-- @treturn PluginManager A manager instance.
--
function PluginManager.get_manager(manager_name)
  return Managers[manager_name] or stop('Invalid manager name')
  end
  

--------------------------------------------------------------------------------
-- Usage.
-- @type PluginManager
--------------------------------------------------------------------------------

  
----------
-- Creates a new plugin environment.
-- 
-- @tparam table plugin_config
-- @tparam string plugin_config.PLUGIN_NAME A unique name for this
-- environment.
-- @tparam nil|string plugin_config.PLUGIN_LUA_ROOT 
-- @tparam nil|string plugin_config.PLUGIN_ASSET_ROOT
-- 
-- @treturn ManagedEnvironment
-- 
function PluginManager:make_env(plugin_config)
  try_is_manager(self)
  
  local plugin_name =
  Verify(plugin_config.PLUGIN_NAME      ,    'NonEmptyString','Invalid plugin name.'      )
  Verify(plugin_config.PLUGIN_LUA_ROOT  ,'nil|NonEmptyString','Invalid plugin lua root.'  )
  Verify(plugin_config.PLUGIN_ASSET_ROOT,'nil|NonEmptyString','Invalid plugin asset root.')
  Verify(self.plugin_envs[plugin_name]  ,'nil','Duplicate plugin name:',plugin_name)
  
  log:debug('New plugin environment "', plugin_name, '" for manager "', self.name, '".')
  
  plugin_config = Table.scopy(plugin_config):clear{
    'PLUGIN_LUA_ROOT','PLUGIN_NAME','PLUGIN_ASSET_ROOT'
    }
  
  -- copy main_env + store
  -- local env = Table.set(
    -- self.plugin_envs, {plugin_name},
    -- Table.scopy(self.main_env)
    -- )
  
  -- copy main_env + store
  local env = Table.scopy(self.main_env)
  if plugin_name ~= 'SharedEnvironment' then
    self.plugin_envs[plugin_name] = env
    end
  
  -- link to main_env
  env.MainEnv = self.main_env
  env.PublicEnv = _ENV
  
  
  -- include config constants in _ENV
  env:smerge(plugin_config)
  
  -- prepare customized functions
  env.plugreq =
    -- @future: use Stacktrace to get calling directory
    --> which makes it usable everywhere and it can be a
    -- global function Import() or RelReq() or... just Require() Tool.Require
    (env.PLUGIN_LUA_ROOT ~= nil)
    and function(path) return require(env.PLUGIN_LUA_ROOT .. path) end
    or  function(path) stop('No plugin lua root given.') end
    
  env.plugasset = 
    (env.PLUGIN_ASSET_ROOT ~= nil)
    and function(path) return env.PLUGIN_ASSET_ROOT .. path end
    or  function(path) stop('No plugin asset root given.') end
  
  if plugin_name == 'SharedEnvironment' then
    -- has to block in on_load and after!
    -- env.Savedata = Lock.AutoLock({},'Pre-OnLoad Savedata')
    env.Savedata = make_locked_savedata_dummy(plugin_name)

    env.log   = Log.Logger    (self.name..' (SharedEnv)')
    env.stop  = Error.Stopper (self.name..' (SharedEnv)')    
  else
    env.log   = Log.Logger    (plugin_name)
    env.stop  = Error.Stopper (plugin_name)
    end
  
  -- Cleanup
  
  -- Prevent leaking of empty pre-on-load "global" table.
  -- Otherwise plugins can't see the real global.
  env.global = nil
  
  return setmetatable(env, self.plugin_env_mt)
  end


----------
-- Fetches a previously created plugin environment.
-- It is an error if no environment with that name exists.
-- 
-- @tparam string plugin_name The literal string
-- `'SharedEnvironment'` will return this managers shared environment.
-- 
-- @treturn ManagedEnvironment|SharedEnvironment
-- 
function PluginManager:get_env(plugin_name)
  try_is_manager(self)
  Verify(plugin_name,'NonEmptyString')
  
  if plugin_name == 'SharedEnvironment' then
    return self.shared_env
    end
  
  return self.plugin_envs[plugin_name]
      or stop('No such plugin environment: ', plugin_name)
  end
  
  

--------------------------------------------------------------------------------
-- Managed Environment.
-- @section
--------------------------------------------------------------------------------

----------
-- Expands a relative path to a full path inside the managers asset_root.
--
-- @tparam string file_path
-- @function plugasset
do end

----------
-- Automatic global savedata management.
-- __Not implemented.__
-- @table Savedata
do end

--------------------------------------------------------------------------------
-- Shared Environment.
-- @section
--------------------------------------------------------------------------------

----------
-- Every manager also has a built-in anonymous shared environment
-- for plugins that do not need a full managed environment.
--
-- The shared environment only supports plugasset() and the default
-- manager environment.
--
-- @table SharedEnvironment
do end
  
-- -------
-- Nothing.
-- @within Todo
-- @field todo1

-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.PluginManager') end
return function() return PluginManager,_PluginManager,_uLocale end
