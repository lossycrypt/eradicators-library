-- This is NOT a config file. Do not change things you don't understand 120%.
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
-- (Mods used for collection: Space Exploration, Krastorio 2, Full Pyanodon)
-- (Don't forget to include unknown description lenghts!)
-- [item_name             ]  |       76 |        3 |    24.85 |    24.00 |     0.43%
-- [item_description      ]  |     1277 |        4 |    69.33 |    56.00 |    76.15%
-- [fluid_name            ]  |       44 |        3 |    16.55 |    17.00 |     0.00%
-- [fluid_description     ]  |       98 |       18 |    50.05 |    46.00 |    86.05%
-- [recipe_name           ]  |       80 |        3 |    21.62 |    21.00 |     0.00%
-- [recipe_description    ]  |      202 |        4 |    60.19 |    58.00 |    96.70%
-- [technology_name       ]  |       59 |        3 |    22.40 |    21.00 |     0.00%
-- [technology_description]  |      408 |       10 |    92.32 |    78.00 |     0.52%
-- [equipment_name        ]  |       57 |       10 |    33.69 |    33.00 |     0.00%
-- [equipment_description ]  |      231 |       53 |    97.90 |    75.50 |    63.79%
-- [tile_name             ]  |       46 |        4 |    18.69 |    14.00 |     0.00%
-- [tile_description      ]  |       92 |       37 |    50.99 |    52.00 |    98.08%
-- [entity_name           ]  |       81 |        3 |    27.66 |    27.00 |     7.73%
-- [entity_description    ]  |      429 |        9 |    63.85 |    54.00 |    49.76%

const.type_data = {
  -- This table hardcodes the order in which prototypes will be translated
  -- *if* they're activated in settings stage.
  {type = "item_name"             , longest =   76},
  {type = "item_description"      , longest = 1277},
  {type = "fluid_name"            , longest =   44},
  {type = "fluid_description"     , longest =   98},
  {type = "recipe_name"           , longest =   80},
  {type = "recipe_description"    , longest =  202},
  {type = "technology_name"       , longest =   59},
  {type = "technology_description", longest =  408},
  {type = "equipment_name"        , longest =   57},
  {type = "equipment_description" , longest =  231},
  {type = "tile_name"             , longest =   46}, -- max 255
  {type = "tile_description"      , longest =   92},
  {type = "entity_name"           , longest =   81}, -- lots of garbage
  {type = "entity_description"    , longest =  429},
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