-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
local Table = elreq('erlib/lua/Table')()
local Set   = elreq('erlib/lua/Set'  )()

-- -------------------------------------------------------------------------- --
local Data  = elreq('erlib/factorio/Data/!init')()
local const = require 'plugins/babelfish/const'

-- -------------------------------------------------------------------------- --

  Data.Inscribe{
    name          = const.setting_name.network_rate,
    type          = 'double-setting'          ,
    setting_type  = 'runtime-global'          ,
    order         = 'babelfish-1'             ,
    default_value = 8                         ,
    minimum_value = 0.0001                    ,
    maximum_value = 1000                      ,
    }

  Data.Inscribe{
    name          = const.setting_name.string_match_type,
    type          = 'string-setting'          ,
    setting_type  = 'runtime-global'          ,
    order         = 'babelfish-2'             ,
    default_value = 'plain'                   ,
    allowed_values= {'plain', 'fuzzy', 'lua'} ,
    }
  
return function(search_types)
  
  local allowed
    = Table.map(const.type_data, function(v) return true, v.type end, {})
  
  assert(#search_types > 0, 'Babelfish: At least one search type must be configured.')
  
  for _, v in ipairs(search_types) do
    assert(allowed[v], 'Babelfish: Invalid search type: '..v)
    end
  
  Data.Inscribe{
    name          = const.setting_name.search_types,
    type          = 'string-setting'          ,
    setting_type  = 'runtime-global'          ,
    order         = 'babelfish-z'             ,
    hidden        = true                      ,
    allow_blank   = true                      ,
    default_value = search_types[1]           , -- not used
    
    allowed_values = Table.keys(Set.from_values(search_types)), -- copied by Inscribe
    }

  end