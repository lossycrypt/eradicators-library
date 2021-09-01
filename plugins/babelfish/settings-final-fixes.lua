-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
local Table   = elreq('erlib/lua/Table')()
local Set     = elreq('erlib/lua/Set'  )()

local Data    = elreq('erlib/factorio/Data/!init')()
local Setting = elreq('erlib/factorio/Setting')()

-- -------------------------------------------------------------------------- --
local const       = require 'plugins/babelfish/const'
local initconst   = require 'plugins/!init/const'
local SearchTypes = require 'plugins/babelfish/control/SearchTypes'

-- -------------------------------------------------------------------------- --
-- map

Setting.make{
  const.setting_name.network_rate,
  'map', 'double', {0.000001, 64, 10000000}, -- 10GiB/s
  'erlib:3-babelfish-1-1'
  }
  
Setting.make {
  const.setting_name.sp_instant_translation,
  'map', 'bool', true,
  'erlib:3-babelfish-1-2',
  hidden         = (not flag.IS_DEV_MODE),
  forced_value   = true                  , -- only loaded when hidden
  }
  
Setting.make {
  const.setting_name.enable_packaging,
  'map', 'bool', true,
  'erlib:3-babelfish-1-3',
  hidden         = (not flag.IS_DEV_MODE),
  forced_value   = true                  , -- only loaded when hidden
  }

-- -------------------------------------------------------------------------- --
-- player

Setting.make{
  const.setting_name.string_match_type,
  'player', 'string', 'plain',
  'erlib:3-babelfish-1-4',
  allowed_values= {'plain', 'fuzzy', 'lua'} ,
  }
  
-- -------------------------------------------------------------------------- --
-- search_types

local db = data.raw['string-setting'][initconst.name.setting.enabled_plugins]
local requested = Table.keys(assert(Table.pop(db, 'babelfish_search_types')))

assert(#requested > 0, 'Babelfish: At least one search type must be configured.')
for _, type in ipairs(requested) do
  assert(SearchTypes.is_supported(type), 'Babelfish: Invalid search type: '..type)
  end

SearchTypes.sort(requested) -- Important! Determines translation priority!
  
Data.Inscribe{
  name           = const.setting_name.search_types,
  type           = 'string-setting'       ,
  setting_type   = 'startup'              ,
  order          = 'ZZ9 Plural Z Alpha'   ,
  hidden         = (not flag.IS_DEV_MODE) ,
  allow_blank    = false                  ,
  default_value  = requested[1]           , -- not used
  allowed_values = requested              ,
  }

