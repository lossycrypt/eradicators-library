﻿
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
      en = 'How much network bandwidth Babelfish will use while translating. '
        .. 'Has no effect in Singleplayer. '
        .. 'Setting this too high may result in players being dropped from the server. '
        .. 'No bandwidth is used once translation is done. ',
      },
    },

  ['[babelfish]'] = {
  
    language_code = {
      ["af"   ] = "af"   ,
      ["ar"   ] = "ar"   ,
      ["be"   ] = "be"   ,
      ["bg"   ] = "bg"   ,
      ["ca"   ] = "ca"   ,
      ["cs"   ] = "cs"   ,
      ["da"   ] = "da"   ,
      ["de"   ] = "de"   ,
      ["el"   ] = "el"   ,
      ["en"   ] = "en"   ,
      ["eo"   ] = "eo"   ,
      ["es-ES"] = "es-ES",
      ["et"   ] = "et"   ,
      ["fi"   ] = "fi"   ,
      ["fr"   ] = "fr"   ,
      ["fy-NL"] = "fy-NL",
      ["ga-IE"] = "ga-IE",
      ["he"   ] = "he"   ,
      ["hr"   ] = "hr"   ,
      ["hu"   ] = "hu"   ,
      ["id"   ] = "id"   ,
      ["it"   ] = "it"   ,
      ["ja"   ] = "ja"   ,
      ["ko"   ] = "ko"   ,
      ["lt"   ] = "lt"   ,
      ["lv"   ] = "lv"   ,
      ["nl"   ] = "nl"   ,
      ["no"   ] = "no"   ,
      ["pl"   ] = "pl"   ,
      ["pt-BR"] = "pt-BR",
      ["pt-PT"] = "pt-PT",
      ["ro"   ] = "ro"   ,
      ["ru"   ] = "ru"   ,
      ["sk"   ] = "sk"   ,
      ["sl"   ] = "sl"   ,
      ["sq"   ] = "sq"   ,
      ["sr"   ] = "sr"   ,
      ["sv-SE"] = "sv-SE",
      ["th"   ] = "th"   ,
      ["tr"   ] = "tr"   ,
      ["uk"   ] = "uk"   ,
      ["vi"   ] = "vi"   ,
      ["zh-CN"] = "zh-CN",
      ["zh-TW"] = "zh-TW",
      },

    localised_language_name = {
      ["af"   ] = "Afrikaans"          ,
      ["ar"   ] = "العَرَبِيَّة"            ,
      ["be"   ] = "Беларуская"         ,
      ["bg"   ] = "български език"     ,
      ["ca"   ] = "Català"             ,
      ["cs"   ] = "Čeština"            ,
      ["da"   ] = "Dansk"              ,
      ["de"   ] = "Deutsch"            ,
      ["el"   ] = "Ελληνικά"           ,
      ["en"   ] = "English"            ,
      ["eo"   ] = "Esperanto"          ,
      ["es-ES"] = "Español"            ,
      ["et"   ] = "Eesti"              ,
      ["fi"   ] = "Suomi"              ,
      ["fr"   ] = "Français"           ,
      ["fy-NL"] = "Frisian"            ,
      ["ga-IE"] = "Gaeilge"            ,
      ["he"   ] = "עברית"              ,
      ["hr"   ] = "Hrvatski"           ,
      ["hu"   ] = "Magyar"             ,
      ["id"   ] = "Bahasa Indonesia"   ,
      ["it"   ] = "Italiano"           ,
      ["ja"   ] = "日本語"              ,
      ["ko"   ] = "한국어"                ,
      ["lt"   ] = "Lietuvių"           ,
      ["lv"   ] = "Latviešu"           ,
      ["nl"   ] = "Nederlands"         ,
      ["no"   ] = "Norsk"              ,
      ["pl"   ] = "Polski"             ,
      ["pt-BR"] = "Português, Brasil"  ,
      ["pt-PT"] = "Português"          ,
      ["ro"   ] = "Română"             ,
      ["ru"   ] = "Русский"            ,
      ["sk"   ] = "Slovenčina"         ,
      ["sl"   ] = "Slovenščina"        ,
      ["sq"   ] = "Shqip"              ,
      ["sr"   ] = "Српски"             ,
      ["sv-SE"] = "Svenska"            ,
      ["th"   ] = "ภาษาไทย"             ,
      ["tr"   ] = "Türkçe"             ,
      ["uk"   ] = "Українська"         ,
      ["vi"   ] = "Tiếng Việt Nam"     ,
      ["zh-CN"] = "简体中文"            ,
      ["zh-TW"] = "繁體中文"            ,
      },

    },

  }) end