-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
-- Outside of factorio '__eradicators-library__' is not a valid absolute path!
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))
  
-- -------------------------------------------------------------------------- --
-- Eradicators Library                                                        --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
local Lock = elreq ('erlib/lua/Lock')()

-- -------------------------------------------------------------------------- --
-- Debug                                                                      --
-- -------------------------------------------------------------------------- --
if flag.IS_DEV_MODE then
  _ENV.Hydra = elreq('erlib/lua/Coding/Hydra')()
  end

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

-- @param log A named erlib logger instance.
-- @param mod_name A mod name (not root or path!)
return function(log, mod_name)
  assert(mod_name ~= 'eradicators-template', 'Please change the template name')

  -- V1: Explicit absolute path
  -- local mod_root = '__'..mod_name..'__/'
  -- local load = function(path) return require(mod_root .. path) end
  -- local plugin_array = load('plugins/!init/load-order')
  
  -- V2: Implicit relative path
  local plugin_array = require('plugins/!init/load-order')
  
  local Loader = {}
  local phase
  
  -- @tparam string phase
  function Loader.init(_phase) phase = assert(_phase)
    -- Debug ---------------------------------------------------------------- --
    -- if flag.IS_DEV_MODE then
      -- _ENV.Hydra = elreq('erlib/lua/Coding/Hydra')()
      -- end
    -- Lock ----------------------------------------------------------------- --
    if (phase == 'control')
    or (flag.IS_DEV_MODE and not (phase:find 'control' or phase == 'ulocale'))
    then
      Lock.auto_lock(_ENV, '_ENV', 'GLOBAL')
      end
    -- ---------------------------------------------------------------------- --
    end
    
    
  function Loader.enable_pm() assert(phase)
    -- PluginManager -------------------------------------------------------- --
    if (phase == 'control')
    or phase:find 'settings' or phase:find 'data' then
      -- Detect when another mod accidentially left PM active globally.
      assert(rawget(_ENV, 'PluginManager') == nil, 'Foreign PluginManager detected in _ENV!')
      -- At runtime only load PM once.
      rawset(_ENV, 'PluginManager', elreq ('erlib/factorio/PluginManagerLite-1')())
      end
    end
    
    
  function Loader.enable_em() assert(phase)
    -- EventManager --------------------------------------------------------- --
    if phase == 'control' then
      GLOBAL('EventManager', elreq ('erlib/factorio/EventManagerLite-1')())
      assert(PluginManager).enable_savedata_management()
      end
    end
    
    
  function Loader.cleanup() assert(phase)
    if phase:find 'settings' or phase:find 'data' then
      if flag.IS_DEV_MODE then Lock.remove_lock(_ENV) end
      _ENV. PluginManager = nil -- clean up after use
    elseif phase:find 'control' then
      GLOBAL('EventManager', nil) -- should only be used during setup
      end
    end
  

  -- @tparam[opt] TrueSet enabled_set (plugin_name -> true) 
  -- If no enabled_set is given all plugins are considered enabled.
  function Loader.load_phase(enabled_set) assert(phase)
    --
    if phase == 'ulocale' then
      if not remote.interfaces['__00-universal-locale__/remote'] then return end
      -- Some control-free plugins need PM just for ulocale (i.e. VRAM saver).
      if not rawget(_ENV, 'PluginManager') then
        rawset(_ENV, 'PluginManager', elreq ('erlib/factorio/PluginManagerLite-1')())
        end
      -- Load some modules for global ulocale usage.
      rawset(_ENV, 'Locale', elreq('erlib/factorio/Locale')())
      end
    --
    local function wants_phase(phases)
      for i=1, #phases do if phases[i] == phase then return true end end
      end
    --
    for i=1, #plugin_array do
      local plugin_name = plugin_array[i][1]
      local phases      = plugin_array[i][2]
      --
      if  ((enabled_set == nil) or phases.enabled or enabled_set[plugin_name])
      and (wants_phase(phases) and (flag.IS_DEV_MODE or not phases.dev_only))
      then
        local file_path = table.concat({'plugins', plugin_name, phase}, '/')
        log:debug('require("', file_path, '")')
        -- load(file_path)
        require(file_path)
        end
      end
    end
    
    
  return Loader end
