
local _ = '__00-universal-locale__/remote'; if remote.interfaces[_] then
  local const = require 'plugins/babelfish/const'
  
  
  
  require(_)('babelfish', {

  ['[mod-setting-name]'] = {
    [const.setting.network_rate] = {
      en = '_UL:PowerUserSetting_ Babelfish Network Usage (KiB/s)',
      },
    },

  ['[mod-setting-description]'] = {
    [const.setting.network_rate] = {
      en = 'Approximately how much network bandwidth Babelfish will use while translating. '
        .. 'Has no effect in Singleplayer. '
        .. 'No bandwidth is used once translation is done. '
        .. '\\n\\n'
        .. 'While Babelfish is working you can hover the small icon in the upper '
        .. 'right corner to see more detailed status info. '
        .. '\\n\\n'
        .. 'If a player has slow internet AND uses a language that is not yet '
        .. 'translated on the server, then they might be dropped or unable to '
        .. 'join a server if this setting is too high. In that case '
        .. 'temporarily lower the setting until translation is done. ',
      },
    },

  ['[babelfish]'] = {
  
    ['translation-progress'] = {
      en = 'Translation is currently __1__% done.',
      },
  
    language_code = (function(r)
      for code, name in pairs(const.native_language_name) do r[code] = code end
      return r end){},
    
    native_language_name = (function(r)
      for code, name in pairs(const.native_language_name) do r[code] = name end
      return r end){},

    },

  }) end