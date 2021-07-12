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
-- local log         = elreq('erlib/lua/Log'          )().Logger  'gui-auto-styler'
-- local stop        = elreq('erlib/lua/Error'        )().Stopper 'gui-auto-styler'
-- local assertify   = elreq('erlib/lua/Error'        )().Asserter(stop)

-- local Verificate  = elreq('erlib/lua/Verificate'   )()
-- local verify      = Verificate.verify
-- local isType      = Verificate.isType

local Table       = elreq('erlib/lua/Table'        )()
-- local Array       = elreq('erlib/lua/Array'        )()
-- local Set         = elreq('erlib/lua/Set'          )()
-- local Filter      = elreq('erlib/lua/Filter'       )()
-- local Vector      = elreq('erlib/lua/Vector'       )()

-- local ntuples     = elreq('erlib/lua/Iter/ntuples' )()
-- local dpairs      = elreq('erlib/lua/Iter/dpairs'  )()
-- local sriapi      = elreq('erlib/lua/Iter/sriapi'  )()

-- local Setting     = elreq('erlib/factorio/Setting'   )()
-- local Player      = elreq('erlib/factorio/Player'    )()
-- local getp        = Player.get_event_player

-- -------------------------------------------------------------------------- --
-- Constants                                                                  --
-- -------------------------------------------------------------------------- --
local script = EventManager .get_managed_script    'gui-auto-styler'
local import = PluginManager.make_relative_require 'gui-auto-styler'
local const  = import '/const'

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --
-- local This = {}

-- -------------------------------------------------------------------------- --
-- Local Library                                                              --
-- -------------------------------------------------------------------------- --
  
-- -------------------------------------------------------------------------- --
-- Events                                                                     --
-- -------------------------------------------------------------------------- --

script.on_event(defines.events.on_gui_value_changed, function(e)
  local elm = e.element
  local data = Table.get(elm.tags, const.path.style_data)
  if data then
    if elm.type == 'slider' then
      local postfix = data[const.index.style_data.slider_value_tooltip_postfix]
      if postfix then
        elm.tooltip = {'', elm.slider_value, postfix}
        end
      end
    end
  end)