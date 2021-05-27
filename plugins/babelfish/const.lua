
-- This file might also be loaded into OTHER mods environments via
-- babelfish/remote.
-- -------------------------------------------------------------------------- --

local const = {}

const.setting_name = {
  network_rate = 'er:babelfish-network-rate',
  search_types = 'er:babelfish-search-types',
  }
  
const.network = {
  rerequest_delay = 60, -- in ticks
  }
  
const.style = {
  status_indicator_button = 'er:babelfish-status-indicator-button-style',
  }
  
const.sprite = {
  default_icon = 'er:babelfish-default-icon',
  }

const.lstring = {
  language_code        = {'babelfish.language_code'},
  native_language_name = {'babelfish.native_language_name'},
  }

const.remote = {
  interface_name = 'er:babelfish-remote-interface',
  }
  
const.gui_name = {
  status_indicator_button = 'er:babelfish-status-indicator-button',
  }
  
const.search_type_translation_order = {
  -- This is the (hardcoded) order in which prototypes will be translated
  -- *if* they're activated in settings stage.
  'recipe',
  'item',
  'fluid',
  'entity',
  'technology',
  'equipment',
  'tile',
  }
  
const.supported_search_types = {
  "recipe_name",
  "recipe_description",
  
  "item_name",
  "item_description",
  
  "fluid_name",
  "fluid_description",
  
  "entity_name",
  "entity_description",
  
  "technology_name",
  "technology_description",
  
  "equipment_name",
  "equipment_description",
  
  "tile_name",
  "tile_description"
  }


const.native_language_name = {
  internal  = 'Internal'           ,
  
  ["af"   ] = "Afrikaans"          ,
  ["ar"   ] = "العَرَبِيَّة"               ,
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
  ["he"   ] = "עברית"               ,
  ["hr"   ] = "Hrvatski"           ,
  ["hu"   ] = "Magyar"             ,
  ["id"   ] = "Bahasa Indonesia"   ,
  ["it"   ] = "Italiano"           ,
  ["ja"   ] = "日本語"              ,
  ["ko"   ] = "한국어"               ,
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
  }

return const