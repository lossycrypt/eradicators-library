local _ = '__00-universal-locale__/remote' if remote.interfaces[_] then

-- local import = PluginManager.make_relative_require 'log-level-settings'
-- local const  = import '/const'
-- local hotkey = Locale.format_hotkey_tooltip

-- _UL:DevModeSetting_
-- _UL:PowerUserSetting_

-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
local Log,_Log,const = elreq('erlib/lua/Log')()


-- -------------------------------------------------------------------------- --
require(_)('log-level-settings', {

  ['[mod-setting-name]'] = {
    [const.name.setting.prefix] = { 
      en = "Logging Level _UL:PowerUserSetting_",
      de = "Welche Logeintrage? _UL:PowerUserSetting_",
      ja = "何をログに記録しますか？ _UL:PowerUserSetting_",
      },
    [const.name.setting.hidden] = { 
      en = "Logging Level (__1__) _UL:PowerUserSetting_ _UL:DevModeSetting_",
      de = "",
      ja = "",
      },
    },
    
  ['[mod-setting-description]'] = {
    [const.name.setting.prefix] = { 
      en = 'How detailed the information in the log file will be. '
        .. 'If you encounter a bug it would help if you set the level '
        .. 'to "Everything" before posting the log.'
         ,
      de = [[Wie detailiert die Logeinträge sein sollen.]]
         ,
      ja = [[ログ記録の精度。]]
         ,
      }
    },
    
  ['[string-mod-setting]'] = {
    [const.name.setting.prefix .. '-Errors'] = {
      en = 'Errors',
      de = 'Fehler',
      ja = 'エラー',
      },
    [const.name.setting.prefix .. '-Warnings'] = {
      en = '+ Warnings',
      de = '+ Warnungen',
      ja = '＋警告も',
      },
    [const.name.setting.prefix .. '-Information'] = {
      en = '+ Information',
      de = '+ Informationen',
      ja = '＋通知も',
      },
    [const.name.setting.prefix .. '-Everything'] = {
      -- en = 'BUG REPORT',
      en = '= Everything',
      de = '= Alles',
      ja = '＝バグ報告',
      },
    },

  }) end
