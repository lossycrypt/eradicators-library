
local _ = '__00-universal-locale__/remote'; if remote.interfaces[_] then
  local const = require 'plugins/babelfish/const'
  
  
  
  require(_)('babelfish', {

  ['[mod-setting-name]'] = {
    [const.setting_name.network_rate] = {
      en = '_UL:PowerUserSetting_ Babelfish: Maximum Network Usage (KiB/s)',
      },
    [const.setting_name.string_match_type] = {
      en = 'Babelfish: Search Mode',
      },
    },

  ['[string-mod-setting]'] = {
    [const.setting_name.string_match_type..'-'..'plain'] = {
      en = 'Default',
      },
    [const.setting_name.string_match_type..'-'..'fuzzy'] = {
      en = 'Fuzzy',
      },
    [const.setting_name.string_match_type..'-'..'lua'] = {
      en = '_UL:PowerUserSetting_ Lua pattern',
      },    
    },


  ['[string-mod-setting-description]'] = {
    [const.setting_name.string_match_type..'-'..'plain'] = {
      en = 'Plain text search like in vanilla Factorio.',
      },
    [const.setting_name.string_match_type..'-'..'fuzzy'] = {
      en = 'Searches for each letter seperately. '
        .. [[Same as Factorio's "Fuzzy search" interface option.]],
      },
    [const.setting_name.string_match_type..'-'..'lua'] = {
      en = 'Raw lua pattern input. Not RegEx.'
        .. '\nFor hoopy froods who know where their towel is.',
      },    
    },
    
  ['[mod-setting-description]'] = {
    [const.setting_name.network_rate] = {
      en = 'Rough approximation of how much network bandwidth Babelfish will use while translating. '
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
    [const.setting_name.string_match_type] = {
      en = 'Changes how text you enter into the search fields of '
        .. 'supported mods is treated. All search modes are '
        .. 'case-insensitive.',
      },
    },

  ['[babelfish]'] = {

    ['status-indicator-tooltip-header'] = {
      en = 'The Babelfish is currently translating your mods.__1__',
      de = 'Der Babelfisch übersetzt gerade deine Mods.__1__',
      ja = 'バベルフィッシュさんが只今モッドの翻訳に勤しんでいます。__1__',
      },

    ['command-only-in-singleplayer'] = {
      en = 'This command can only be used in singleplayer.',
      },
      
    ['command-only-by-admin'] = {
      en = 'This command can only be used by admins.',
      },
      
    ['unknown-command'] = {
      en = 'Unknown command.',
      },
      
    ['command-confirm'] = {
      en = 'Ok!',
      },
      
    ['test-string'] = {
      en = 'This is a test. '
        .. 'Button: __CONTROL__mine__. '
        .. 'Complex Button: __ALT_CONTROL__1__build__'
        .. 'Parameters: __2__ __3__. '
        .. 'Item Name: __ITEM__iron-plate__. '
        .. 'Plural: __4__ __plural_for_parameter_4_{1=day|rest=days}__'
      },
      
    language_code = (function(r)
      for code, name in pairs(const.native_language_name) do r[code] = code end
      return r end){},
    
    native_language_name = (function(r)
      for code, name in pairs(const.native_language_name) do r[code] = name end
      return r end){},

    },

  }) end