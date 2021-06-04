
-- This file might also be loaded into OTHER mods environments via
-- babelfish/remote.
-- -------------------------------------------------------------------------- --

local const = {}

const.setting_name = {
  -- user
  network_rate      = 'er:babelfish-network-rate',
  string_match_type = 'er:babelfish-string-match-type',
  
  -- hidden
  search_types = 'er:babelfish-search-types',
  }
  
const.network = {
  rerequest_delay = 60, -- in ticks
  transit_window  = 30, -- in ticks
  master_header = '金魚',
  packet_header = {
    packed_request = '箱',
    ping           = '音', -- not used yet
    },
  mtu_bytes = 1452,
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
  interface_name = 'babelfish',
  }
  
const.gui_name = {
  status_indicator_button = 'er:babelfish-status-indicator-button',
  }
  
const.name = {
  tip_1 = 'er:babelfish-tip-1',
  }
  
-- Collected Most Extreme Values:
-- (Outdated: Includes Internal Names, Excludes Unknown Keys)
--
-- Type                      | Longest  | Shortest | Average  | Median   | Unk. Key
-- [item_name             ]  |       76 |        2 |    24.73 |    24.00 |     0.00%
-- [item_description      ]  |     1277 |        4 |   114.31 |    98.50 |    75.94%
-- [fluid_name            ]  |       37 |        3 |    16.47 |    17.00 |     0.00%  
-- [fluid_description     ]  |       98 |       18 |    93.00 |    93.00 |    86.05%
-- [recipe_name           ]  |       76 |        2 |    23.72 |    23.00 |     0.00%
-- [recipe_description    ]  |      202 |        4 |   129.89 |   136.00 |    96.72%
-- [technology_name       ]  |       59 |        3 |    22.38 |    21.00 |     0.00%
-- [technology_description]  |      408 |       10 |    96.25 |    81.00 |     1.03%
-- [entity_name           ]  |       63 |        3 |    24.80 |    24.00 |     0.00%
-- [entity_description    ]  |      429 |        9 |   120.83 |   111.00 |    49.32%
-- [equipment_name        ]  |       57 |        9 |    33.69 |    33.00 |     0.00%
-- [equipment_description ]  |      231 |       66 |   154.86 |   137.00 |    63.79%
-- [tile_name             ]  |       42 |        4 |    18.69 |    20.00 |     0.00%
-- [tile_description      ]  |       92 |       75 |    92.00 |    92.00 |    98.08%
  
  
const.type_data = {
  -- This table hardcodes the order in which prototypes will be translated
  -- *if* they're activated in settings stage.
  {type = "item_name"             , longest =   76},
  {type = "item_description"      , longest = 1277},
  {type = "fluid_name"            , longest =   37},
  {type = "fluid_description"     , longest =   98},
  {type = "recipe_name"           , longest =   76},
  {type = "recipe_description"    , longest =  202},
  {type = "technology_name"       , longest =   63},
  {type = "technology_description", longest =  429},
  {type = "equipment_name"        , longest =   57},
  {type = "equipment_description" , longest =  231},
  {type = "tile_name"             , longest =   42}, -- max 255
  {type = "tile_description"      , longest =   92},
  {type = "entity_name"           , longest =   59}, -- lots of garbage
  {type = "entity_description"    , longest =  408},
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