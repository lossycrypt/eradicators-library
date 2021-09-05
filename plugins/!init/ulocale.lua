local _ = '__00-universal-locale__/remote' if remote.interfaces[_] then

-- local import = PluginManager.make_relative_require 'erlib-plugin-init'
-- local const  = import '/const'

local const = require('__eradicators-library__/plugins/!init/const')

-- -------------------------------------------------------------------------- --
require(_)('erlib-plugin-init', {


  ['[mod-setting-name]'] = {
    [const.name.setting.enabled_plugins] = {
      en = "_UL:DevSetting_ Enabled Plugins",
      -- de = "",
      -- ja = "",
      },
    },
    
  -- ['[mod-setting-description]'] = {
    -- },

  }) end