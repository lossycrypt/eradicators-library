-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
local Table = elreq('erlib/lua/Table')()
local Set   = elreq('erlib/lua/Set'  )()

local Data  = elreq('erlib/factorio/Data/!init')()

-- -------------------------------------------------------------------------- --
local const     = require 'plugins/babelfish/const'
local initconst = require 'plugins/!init/const'

-- -------------------------------------------------------------------------- --

Data.Inscribe{
  name          = const.setting_name.network_rate,
  type          = 'double-setting'          ,
  setting_type  = 'runtime-global'          ,
  order         = 'babelfish-1'             ,
  default_value = 32                        ,
  minimum_value = 0.000001                  ,
  maximum_value = 10000000                  , -- 10GiB/s
  }

Data.Inscribe{
  name          = const.setting_name.string_match_type,
  type          = 'string-setting'          ,
  setting_type  = 'runtime-per-user'        ,
  order         = 'babelfish-2'             ,
  default_value = 'plain'                   ,
  allowed_values= {'plain', 'fuzzy', 'lua'} ,
  }

-- -------------------------------------------------------------------------- --
-- search_types

local allowed
  = Table.map(const.type_data, function(v) return true, v.type end, {})

local db = data.raw['string-setting'][initconst.name.setting.enabled_plugins]
local requested = Table.values(assert(Table.pop(db, 'babelfish_search_types')))

assert(#requested > 0, 'Babelfish: At least one search type must be configured.')
for _, v in ipairs(requested) do
  assert(allowed[v], 'Babelfish: Invalid search type: '..v)
  end

Data.Inscribe{
  name           = const.setting_name.search_types,
  type           = 'string-setting'       ,
  setting_type   = 'startup'              ,
  order          = 'ZZ9 Plural Z Alpha'   ,
  hidden         = (not flag.IS_DEV_MODE) ,
  allow_blank    = false                  ,
  default_value  = requested[1]           , -- not used
  allowed_values = requested              , -- copied by Inscribe
  }

