﻿-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable
-- -------------------------------------------------------------------------- --

--[[ Notes:
  ]]

--[[ Annecdotes:
  ]]

--[[ Future:
  ]]
  
--[[ Todo:
  ]]
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Eradicators Library                                                        --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
-- local log         = elreq('erlib/lua/Log'          )().Logger  'template'
-- local stop        = elreq('erlib/lua/Error'        )().Stopper 'template'
-- local assertify   = elreq('erlib/lua/Error'        )().Asserter(stop)

-- local Verificate  = elreq('erlib/lua/Verificate'   )()
-- local verify      = Verificate.verify
-- local isType      = Verificate.isType

-- local Table       = elreq('erlib/lua/Table'        )()
-- local Array       = elreq('erlib/lua/Array'        )()
-- local Set         = elreq('erlib/lua/Set'          )()
-- local Filter      = elreq('erlib/lua/Filter'       )()
-- local Vector      = elreq('erlib/lua/Vector'       )()

-- local ntuples     = elreq('erlib/lua/Iter/ntuples' )()
-- local dpairs      = elreq('erlib/lua/Iter/dpairs'  )()
-- local sriapi      = elreq('erlib/lua/Iter/sriapi'  )()

local Setting     = elreq('erlib/factorio/Setting'   )()
-- local Data        = elreq('erlib/factorio/Data/!init')()

-- -------------------------------------------------------------------------- --
-- Constants                                                                  --
-- -------------------------------------------------------------------------- --
-- local import = PluginManager.make_relative_require 'template'
-- local const  = import '/const'

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

-- -------------------------------------------------------------------------- --
-- Local Library                                                              --
-- -------------------------------------------------------------------------- --
  
-- -------------------------------------------------------------------------- --
-- Settings                                                                   --
-- -------------------------------------------------------------------------- --

-- {name,scope,type,default or {default,min,max},order,...}
Setting.make {
  'name',
  
  'startup', 'string', 'default_value',
  'map', 'int', {0, 10, 1000},
  'player', 'double', {0, 0.5, 1},
  'player', 'bool', false,
  
  'er:orderstring',
  localised_name        = '',
  localised_description = '',
  allow_blank           = true,
  allowed_values        = {},
  }
