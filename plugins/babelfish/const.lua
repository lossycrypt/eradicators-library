-- This is NOT a config file. Do not change.
-- -------------------------------------------------------------------------- --

local const = {}

const.index = {

  entry = { -- Entry data index
    -- all entries
    name    = 2,
    -- translated entries only
    word    = 1,
    -- entries waiting for translation
    dirty   = 3,
    -- raw entries only
    index   = 4,
    type    = 5,
    lstring = 6,
    request = 7,
    },

  request = { -- Request data index
    lstring = 1,
    entries = 2,
    bytes   = 3,
    uid     = 4,
    },

  }
  
const.version = {
  -- Prevents on_load for old versions.
  -- Version history:
  --  1 : eradicators-library 4.1.4 ~ 4.2.1
  --  2 : eradicators-library 4.2.2 ~ now
  --
  savedata = 2,
  }


const.setting_name = {
  -- user
  string_match_type = 'er:babelfish-string-match-type',
  
  -- map
  network_rate      = 'er:babelfish-network-rate',
  enable_packaging  = 'er:babelfish-enable-packaging',
  
  -- hidden
  search_types           = 'er:babelfish-search-types',
  sp_instant_translation = 'er:babelfish-singleplayer-instant-translation',
  }
  
const.network = {
  rerequest_delay = 1.0, -- in seconds
  transit_window  = 15/60, -- in seconds
  ticks_per_packet = 2, -- in ticks
  master_header = '金魚',
  packet_header = {
    packed_request = '箱',
    ping           = '音', -- not used yet
    },

  bytes = {
    -- https://en.wikipedia.org/wiki/Maximum_transmission_unit
    mtu             = 1452,
    packet_overhead =   18,
    -- dict:dump_statistics()
    packet_median   =   75, -- better estimate means batter bandwitdh control
    },
  }
  
const.style = {
  status_indicator_button = 'er:babelfish-status-indicator-button-style',
  }
  
const.sprite = {
  icon_default = 'er:babelfish-icon-default',
  icon_green   = 'er:babelfish-icon-green',
  icon_red     = 'er:babelfish-icon-red',
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
--
-- Type                          | Longest  | Shortest | Average  | Median   | Unk. Key
-- [item_name                 ]  |       88 |        3 |    25.14 |    24.00 |     0.43%
-- [item_description          ]  |     1277 |        4 |    78.11 |    56.00 |    76.02%
-- [fluid_name                ]  |       44 |        3 |    16.55 |    17.00 |     0.00%
-- [fluid_description         ]  |       98 |       18 |    50.05 |    46.00 |    86.05%
-- [recipe_name               ]  |       80 |        3 |    21.63 |    21.00 |     0.00%
-- [recipe_description        ]  |      230 |        4 |    60.65 |    58.00 |    96.75%
-- [technology_name           ]  |       59 |        3 |    22.35 |    21.00 |     0.00%
-- [technology_description    ]  |      408 |       10 |    92.57 |    78.00 |     0.00%
-- [equipment_name            ]  |       57 |       10 |    33.69 |    33.00 |     0.00%
-- [equipment_description     ]  |      333 |       53 |   105.84 |    75.50 |    63.79%
-- [tile_name                 ]  |       46 |        4 |    18.69 |    14.00 |     0.00%
-- [tile_description          ]  |       92 |       37 |    51.04 |    52.00 |    98.08%
-- [entity_name               ]  |       88 |        3 |    27.66 |    27.00 |     8.33%
-- [entity_description        ]  |     1068 |        9 |    70.88 |    55.00 |    49.96%
-- [virtual_signal_name       ]  |       40 |        3 |    14.94 |    14.00 |     0.00%
-- [virtual_signal_description]  |      139 |       48 |    55.42 |    51.00 |    92.31%
-- [custom_input_name         ]  |       78 |       22 |    55.96 |    57.00 |    97.78%
-- [custom_input_description  ]  |       85 |       47 |    62.93 |    64.00 |   100.00%
-- [mod_setting_name          ]  |       87 |        6 |    50.78 |    53.00 |     0.00%
-- [mod_setting_description   ]  |      686 |       21 |   250.78 |   184.00 |    10.81%
-- [achievement_name          ]  |       57 |        5 |    21.96 |    23.00 |     0.00%
-- [achievement_description   ]  |      129 |        0 |    53.58 |    53.00 |     2.13%
-- [shortcut_name             ]  |       54 |        3 |    23.11 |    19.50 |     0.00%
-- [ammo_category_name        ]  |       57 |        4 |    22.79 |    18.00 |     0.00%
-- [damage_name               ]  |       21 |        4 |    16.88 |    18.00 |     0.00%
-- [decorative_name           ]  |       55 |        4 |    28.40 |    37.00 |     0.00%
-- [item_group_name           ]  |       21 |        3 |    11.53 |    11.00 |     0.00%
-- [item_subgroup_name        ]  |        0 |        0 |     0.00 |     0.00 |   100.00%
-- [equipment_grid_name       ]  |       63 |       46 |    56.50 |    55.50 |   100.00%
-- [particle_name             ]  |       92 |       42 |    65.14 |    65.00 |   100.00%
-- [trivial_smoke_name        ]  |       71 |       39 |    53.07 |    51.50 |   100.00%
-- [autoplace_control_name    ]  |       90 |        4 |    41.87 |    36.00 |     0.00%
-- [noise_layer_name          ]  |       53 |       35 |    41.11 |    40.00 |   100.00%
-- [fuel_category_name        ]  |       49 |        4 |    20.70 |    18.00 |     0.00%
-- [resource_category_name    ]  |       55 |       41 |    49.00 |    49.00 |   100.00%
-- [module_category_name      ]  |       60 |       38 |    45.33 |    47.00 |   100.00%
-- [equipment_category_name   ]  |       74 |       44 |    57.00 |    56.00 |   100.00%
-- [recipe_category_name      ]  |       63 |       38 |    52.26 |    52.00 |   100.00%

const.type_data = {
  -- This table hardcodes the order in which prototypes will be translated
  -- *if* they're activated in settings stage.
  {type = "item_name"             , longest =   88}, -- Unk. Key
  {type = "fluid_name"            , longest =   44},             
  {type = "recipe_name"           , longest =   80},             
  {type = "technology_name"       , longest =   59},             
  {type = "item_description"      , longest = 1277}, -- 76%      
  {type = "fluid_description"     , longest =   98}, -- 86%      
  {type = "recipe_description"    , longest =  230}, -- 96%      
  {type = "technology_description", longest =  408},             
  {type = "equipment_name"        , longest =   57},             
  {type = "equipment_description" , longest =  333}, -- 63%      
  {type = "tile_name"             , longest =   46},          -- max 255
  {type = "tile_description"      , longest =   92}, -- 98%      
  {type = "entity_name"           , longest =   88}, --  8%   -- lots of garbage
  {type = "entity_description"    , longest = 1068}, -- 49%      
  {type = "virtual_signal_name"   , longest =   40},             
  --
  -- Deactivated prototype categories.
  --   This is a list of *all* prototypes with a compatible
  --   game.*_prototypes table. "_description" is not listed for brevity.
  --
  -- Type 1: Partially localised, but useless for find().
  --   If someone finds a usecase (i.e. for translate())
  --   as a non-localised string I might activate them.
  nil and {type = "virtual_signal_description", longest =  139, noicon = true},
  nil and {type = "custom_input_name"         , longest =   78, noicon = true},
  nil and {type = "custom_input_description"  , longest =   85, noicon = true},
  nil and {type = "mod_setting_name"          , longest =   87, noicon = true},
  nil and {type = "mod_setting_description"   , longest =  686, noicon = true},
  nil and {type = "achievement_name"          , longest =   57, noicon = true},
  nil and {type = "achievement_description"   , longest =  129, noicon = true},
  nil and {type = "shortcut_name"             , longest =   54, noicon = true},
  nil and {type = "ammo_category_name"        , longest =   57, noicon = true},
  nil and {type = "damage_name"               , longest =   21, noicon = true},
  nil and {type = "decorative_name"           , longest =   55, noicon = true},
  nil and {type = "item_group_name"           , longest =   21,              }, -- does not support localised_description
  --
  -- Type 2: Unlocalised. Technically supports localisation.
  nil and {type = "item_subgroup_name"        , longest =    0, noicon = true}, -- does not support localised_description
  nil and {type = "equipment_grid_name"       , longest =   63, noicon = true},
  nil and {type = "particle_name"             , longest =   92, noicon = true},
  nil and {type = "trivial_smoke_name"        , longest =   71, noicon = true},
  nil and {type = "autoplace_control_name"    , longest =   90, noicon = true},
  nil and {type = "noise_layer_name"          , longest =   53, noicon = true},
  nil and {type = "fuel_category_name"        , longest =   49, noicon = true},
  nil and {type = "resource_category_name"    , longest =   55, noicon = true},
  nil and {type = "module_category_name"      , longest =   60, noicon = true},
  nil and {type = "equipment_category_name"   , longest =   74, noicon = true},
  nil and {type = "recipe_category_name"      , longest =   63, noicon = true},
  -- Type 3: Does not support localisation.
  nil and {type = "font_name"                 , longest = 9001, noicon = true},
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