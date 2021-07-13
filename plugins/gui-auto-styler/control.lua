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
local Table       = elreq('erlib/lua/Table'        )()

-- -------------------------------------------------------------------------- --
-- Constants                                                                  --
-- -------------------------------------------------------------------------- --
local script = EventManager .get_managed_script    'gui-auto-styler'
local import = PluginManager.make_relative_require 'gui-auto-styler'
local const  = import '/const'

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