-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable
-- -------------------------------------------------------------------------- --

--[[ Notes:
  
  This is a simple GUI to demonstrate Babelfish.find_prototype_names().
  Open it with "/babelfish demo" after activating babelfish.

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
-- local log         = elreq('erlib/lua/Log'          )().Logger  'BabelfishDemo'
-- local stop        = elreq('erlib/lua/Error'        )().Stopper 'BabelfishDemo'

local Table       = elreq('erlib/lua/Table'        )()
local Set         = elreq('erlib/lua/Set'          )()

local Class       = elreq('erlib/lua/Class'        )()
local ntuples     = elreq('erlib/lua/Iter/ntuples' )()

local Remote      = elreq('erlib/factorio/Remote'  )()
local Gui         = elreq('erlib/factorio/Gui'     )()

-- rawset(_ENV, 'No_Profiler_Commands', true)
-- local Profiler = require('__00-profiler-fork__/profiler.lua')

-- -------------------------------------------------------------------------- --
-- Constants                                                                  --
-- -------------------------------------------------------------------------- --
local script = EventManager .get_managed_script    'babelfish-demo'
local import = PluginManager.make_relative_require 'babelfish/demo'
local const  = import '/const'
local Name   = const.name
local W, H   = const.gui.width, const.gui.height

local babelconst = require('plugins/babelfish/const')
local Babelfish = Remote.get_interface(babelconst.remote.interface_name)

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Demo = Class.SimpleClass(
  -- initializer
  function(p)
    local self = {
      p = p,
      }  
    return self end
  )

-- -------------------------------------------------------------------------- --
-- Command                                                                    --
-- -------------------------------------------------------------------------- --

function Demo:get_anchor()
  if self.anchor and self.anchor.valid then return self.anchor end
  self.anchor = self.p.gui.screen[Name.gui.anchor]
  if self.anchor and self.anchor.valid then return self.anchor end
  return self.anchor end

function Demo:sget_anchor()
  if self:get_anchor() then return self.anchor end
  self.anchor = self.p.gui.screen.add{
    type      = 'frame',
    name      = Name.gui.anchor,
    caption   = 'Babelfish Demo Gui (type /babelfish demo again to close.)',
    direction = 'vertical',
    }
  return Gui.move(self.anchor, W, H) end

function Demo:toggle_gui()
  local anchor = self:get_anchor()
  if anchor then anchor.destroy() return end
  anchor = self:sget_anchor()
  self.p.opened = anchor
  --
  Gui.move(anchor.add {
    type = 'textfield',
    name = Name.gui.input1,
    }, W-32, 24).focus()
  --
  if flag.IS_DEV_MODE then
    anchor.add {
      type = 'label',
      caption = '[color=red]WARNING: In development mode the localised string '
        ..'is returned for each search result instead of <true>.[/color]',
      }
    end
  Gui.move(anchor.add {
    type = 'label',
    name = Name.gui.profiler_label,
    }, W-32, 24 )
  --
  Gui.move(anchor.add {
    type = 'text-box',
    name = Name.gui.output_serpent,
    -- enabled = false,
    }, W-32, (H-128)/2 )
  --
  Gui.move(anchor.add {
    type = 'scroll-pane',
    name = Name.gui.output_table_pane,
    }, W-32, (H-128)/2 )
  
  end
  
script.on_event(defines.events.on_gui_closed, function(e)
  if e.element and e.element.name == Name.gui.anchor then
    Demo(game.players[e.player_index]):toggle_gui()
    end
  end)
  
script.on_event(defines.events.on_gui_text_changed, function(e)
  if e.element.name == Name.gui.input1 then
  
    -- For demonstration this grabs ALL types that have been
    -- requested by at least one mod. Your mod should NOT do this
    -- and instead only use the types you actually want.
    local types =
      game.mod_setting_prototypes[babelconst.setting_name.search_types]
      .allowed_values
  
    local prfS = game.create_profiler()
    local status, result = Babelfish.find_prototype_names(
      e.player_index,
      types         , -- {'item_name', ...}
      e.text          -- player input
      )
    prfS.stop()
    local prfG = game.create_profiler()
  
    local anchor = e.element.parent
      
    -- Show the literal result.
    anchor[Name.gui.output_serpent].text = 
      ('Status: %s \nResult: %s'):format
      (status, serpent.block(result))
  
    -- Show a nice result gui.
    local pane = anchor[Name.gui.output_table_pane]
    pane.clear()

    local last_type, type, tbl, args, add
    for full_type, name in ntuples(3, status and result or nil) do
      if last_type ~= full_type then
        last_type = full_type
        pane.add {type = 'label', caption = full_type }
        tbl = pane.add {type = 'table', column_count = math.floor((W-64)/40)}
        tbl.style.horizontal_spacing = 0
        tbl.style.vertical_spacing = 0
        --
        type = full_type:gsub('_[^_]+$','')
        add  = tbl.add
        args = {
          type      = 'choose-elem-button',
          style     = 'slot_button',
          elem_type = type,
          }
        if type == 'virtual_signal' then
          args.elem_type = 'signal'
          args.signal = {type = 'virtual'}
          end
        end
      if type == 'virtual_signal' then
        -- VirtualSignal uses "SignalID" table instead of name string.
        args.signal.name = name
      else
        args[type] = name
        end
      add(args).locked = true
      end
      
    anchor[Name.gui.profiler_label].caption = 
      {'', 'Search took: ', prfS, ', ', 'Gui update took: ', prfG}
      
    
    -- Compare total translated size to de-duplicated translated size.
    local arr = {}
    for full_type, name, word in ntuples(3, status and result or nil) do
      arr[#arr+1] = word
      end
    print('Full  length: ', #table.concat(arr))
    print('Dedup length: ', #table.concat(Table.keys(Set.from_values(arr))))
      
    end
  end)
  
return Demo