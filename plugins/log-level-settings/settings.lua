-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable
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
-- local log         = elreq('erlib/lua/Log'          )().Logger  'log-level-settings'
-- local stop        = elreq('erlib/lua/Error'        )().Stopper 'log-level-settings'
-- local assertify   = elreq('erlib/lua/Error'        )().Asserter(stop)

-- local Verificate  = elreq('erlib/lua/Verificate'   )()
-- local verify      = Verificate.verify
-- local isType      = Verificate.isType

local Table       = elreq('erlib/lua/Table'        )()
local Array       = elreq('erlib/lua/Array'        )()
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
-- local import = PluginManager.make_relative_require 'log-level-settings'
-- local const  = import '/const'

local _,_,const = elreq('erlib/lua/Log')()

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

-- -------------------------------------------------------------------------- --
-- Local Library                                                              --
-- -------------------------------------------------------------------------- --
  
-- -------------------------------------------------------------------------- --
-- Settings                                                                   --
-- -------------------------------------------------------------------------- --

-- Global setting (always created)
do
      
  -- Logging levels
  local prot = Setting.make {
    const.name.setting.prefix,
    'startup', 'string', 'Errors',
    'erlib:1-log-level-1',
    allowed_values = Table.keys(const.level),
    }
    
  if not flag.IS_DEV_MODE then
    Array.unsorted_remove_value(prot.allowed_values, 'DEV_MODE')
    end

  end
  

-- Per-mod setting (dynamic)
if flag.IS_DEV_MODE then

  local extra = {
    ['00-universal-locale'] = true,
    }
  local ignore = {
    ['eradicators-assets'] = true
    }

  local mod_names = (function(r)
    for k in pairs(_ENV.mods) do
      if (not ignore[k]) and (extra[k] or k:find('^eradicators%-')) then
        table.insert(r, k)
        end
      end
    return r end){}
    
  for i=1, #mod_names do
    
    -- Can't be "map" because no event handlers allowed.
    Setting.make {
      const.name.setting.prefix .. const.name.setting.infix .. mod_names[i],
      'startup', 'string', 'Information',
      'erlib:9-log-level-2-' .. (10 + i),
      allowed_values = Table.keys(const.level),
      hidden         = (not flag.IS_DEV_MODE),
      localised_name        = {'mod-setting-name.'
        ..const.name.setting.hidden, mod_names[i]},
      localised_description = {'mod-setting-description.'
        ..const.name.setting.hidden},
      }
    
    end
    
  end