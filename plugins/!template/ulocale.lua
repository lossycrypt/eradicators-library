local _ = '__00-universal-locale__/remote' if remote.interfaces[_] then

-- local import = PluginManager.make_relative_require 'template'
-- local const  = import '/const'
-- local hotkey = Locale.format_hotkey_tooltip

-- -------------------------------------------------------------------------- --
require(_)('template', {

  ['[header]'] = {
    ['key'] = { 
      en = "",
      de = "",
      ja = "",
      }
    },

  ['[mod-setting-name]'] = {  
    },
  ['[mod-setting-description]'] = {
    },


  }) end