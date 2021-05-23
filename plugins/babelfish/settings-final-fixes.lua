-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
local Data  = elreq('erlib/factorio/Data/!init')()
local const = require 'plugins/babelfish/const'

-- -------------------------------------------------------------------------- --

Data.Inscribe{
  name          = const.setting.network_rate,
  type          = 'double-setting'          ,
  setting_type  = 'runtime-global'          ,
  order         = 'babelfish-1'             ,
  default_value = 8                         ,
  minimum_value = 1                         ,
  maximum_value = 1000                      ,
  }

Data.Inscribe{
  name          = const.setting.auto_translate_categories,
  type          = 'string-setting'          ,
  setting_type  = 'runtime-global'          ,
  order         = 'babelfish-z'             ,
  hidden        = true                      ,
  allow_blank   = true                      ,
  default_value = 'recipe'                  , -- not used
  
  -- order is important!
  allowed_values = const.allowed_translation_types, -- copied by Inscribe
  }
