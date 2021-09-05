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
local Filter      = elreq('erlib/lua/Filter'       )()
local ntuples     = elreq('erlib/lua/Iter/ntuples' )()

local Remote      = elreq('erlib/factorio/Remote'  )()
local Gui         = elreq('erlib/factorio/Gui'     )()

-- rawset(_ENV, 'No_Profiler_Commands', true)
-- local Profiler = require('__00-profiler-fork__/profiler.lua')

-- -------------------------------------------------------------------------- --
-- Constants                                                                  --
-- -------------------------------------------------------------------------- --
local script = EventManager .get_managed_script    'babelfish-demo'
local import = PluginManager.make_relative_require 'babelfish-demo'
local const  = import '/const'
local Name   = const.name
local W, H   = const.gui.width, const.gui.height

local babelconst  = require 'plugins/babelfish/const'
local SearchTypes = require 'plugins/babelfish/control/SearchTypes'

local Babelfish = Remote.get_interface(babelconst.remote.interface_name)

local has_icon = Table.map(babelconst.type_data, function(v)
  return not v.noicon, v.type
  end, {})
  
local is_name = Filter.string_postfix('_name')
  
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
    -- caption   = 'Babelfish Demo Gui (type /babelfish demo again to close.)',
    direction = 'horizontal',
    style = 'invisible_frame',
    }
  return Gui.move(self.anchor, W, H) end

function Demo:toggle_gui()
  local anchor = self:get_anchor()
  if anchor then anchor.destroy() return end
  anchor = self:sget_anchor()
  self.p.opened = anchor
  --
  local content = self.anchor.add{
    type      = 'frame',
    name      = Name.gui.anchor,
    caption   = 'Babelfish Demo Gui (type /babelfish demo again to close.)',
    direction = 'vertical',
    }
    content.drag_target = anchor
  Gui.move(content, W - const.gui.sidebar_width, H)
  --
  Gui.move(content.add {
    type = 'textfield',
    name = Name.gui.input1,
    }, W-32-const.gui.sidebar_width, 24).focus()
  --
  if flag.IS_DEV_MODE then
    content.add {
      type = 'label',
      caption = '[color=red]WARNING: In development mode the localised string '
        ..'is returned for each search result instead of <true>.[/color]',
      }
    end
  Gui.move(content.add {
    type = 'label',
    name = Name.gui.profiler_label,
    }, W-32-const.gui.sidebar_width, 24 )
  --
  Gui.move(content.add {
    type = 'text-box',
    name = Name.gui.output_serpent,
    -- enabled = false,
    }, W-32-const.gui.sidebar_width, (H-128)/2 )
  --
  Gui.move(content.add {
    type = 'scroll-pane',
    name = Name.gui.output_table_pane,
    }, W-32-const.gui.sidebar_width, (H-128)/2 )
  --
  self:sget_sidebar()
  self:update_sidebar()
  end
  
function Demo:get_sidebar()
  if not self:get_anchor() then return end
  if self.anchor and self.anchor.sidebar_frame then
    self.sidebar = self.anchor.sidebar_frame.sidebar
    return self.sidebar end
  
  -- if self.sidebar and self.sidebar.valid then
    -- return self.sidebar end
  -- return self.anchor.sidebar_frame.sidebar end
  end
  
  
-- local sidebar_layout = {
  -- {'scroll-pane', 'sidebar'
    -- direction = 'vertical',
    -- name 'sidebar',
    -- styler = {const.gui.sidebar_width, H},
    -- },
  -- }
  
  
function Demo:sget_sidebar()
  local sidebar = self:get_sidebar()
  -- create bar
  if not sidebar then
    -- print('making sidebar')
    
    local frame = Gui.move(self.anchor.add {
      name = 'sidebar_frame',
      type = 'frame',
      direction = 'vertical'
      }, const.gui.sidebar_width, H)
    
    sidebar = Gui.move(frame.add {
      name = 'sidebar',
      type = 'scroll-pane',
      direction = 'vertical'
      }, const.gui.sidebar_width, H)
    --
    for _, type in SearchTypes.requested_ipairs() do
      if is_name(type) then
        local this = sidebar.add {
          name = type,
          type = 'flow',
          direction = 'horizontal',
          }
        this.add {
          name = 'checkbox',
          type = 'checkbox',
          state = true,
          tags = {[const.tags.is_sidebar] = true}
          }
        this.add {
          name = 'label',
          type = 'label',
          caption = type,
          tags = {[const.tags.is_sidebar] = true}
          }
        end
      end
    self.sidebar = sidebar
    end
  return sidebar end
  
function Demo:update_sidebar()
  local sidebar = self:get_sidebar()
  if not sidebar then return end
  -- update labels
  local ok = {
    ['true' ] = 'bold_green_label',
    ['false'] = 'bold_red_label'  ,
    ['nil'  ] = 'bold_red_label'  ,
    }
  for _, child in pairs(sidebar.children) do
    child.label.style
      = ok[tostring(Babelfish.can_translate(self.p.index, child.name))]
    end
  end
  
function Demo:get_types()
  local sidebar = self:sget_sidebar()
  local types = {}
  for _, child in pairs(sidebar.children) do
    if child.checkbox.state then
      table.insert(types, child.name)
      end
    end
  return types end
  
script.on_event(defines.events.on_gui_click, function(e)
  if e.element.tags[const.tags.is_sidebar] then
    Demo(game.players[e.player_index]):update_sidebar()
    end
  end)
  
script.on_event(EventManager.events.on_babelfish_translation_state_changed, function(e)
  Demo(game.players[e.player_index]):update_sidebar()
  end)
  
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
    local types = Demo(game.players[e.player_index]):get_types()
    
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
    for full_type, _ in ntuples(2, status and result or nil) do
      if has_icon[full_type] then
        for name in pairs(_) do
          if last_type ~= full_type then
            last_type = full_type
            pane.add {type = 'label', caption = full_type }
            -- tbl = pane.add {type = 'table', column_count = math.floor((W-64)/40)}
            tbl = pane.add {type = 'table', column_count = math.floor((W-32-const.gui.sidebar_width)/40)}
            tbl.style.horizontal_spacing = 0
            tbl.style.vertical_spacing = 0
            --
            type = full_type:gsub('_[^_]+$','')
            type = type:gsub('_','-') -- fix for "item_group" sprite path
            add  = tbl.add
            args = {
              type      = 'choose-elem-button',
              style     = 'slot_button',
              elem_type = type,
              }
            if type == 'virtual-signal' then
              args.elem_type = 'signal'
              args.signal = {type = 'virtual'}
              end
            end
          if type == 'virtual-signal' then
            -- VirtualSignal uses "SignalID" table instead of name string.
            args.signal.name = name
          else
            args[type] = name
            end
          add(args).locked = true
          end
        end
      end
      
    anchor[Name.gui.profiler_label].caption = 
      {'', 'Search took: ', prfS, ', ', 'Gui update took: ', prfG}
      
    
    if flag.IS_DEV_MODE and false then
      -- Compare total translated size to de-duplicated translated size.
      local arr = {}
      for full_type, name, word in ntuples(3, status and result or nil) do
        arr[#arr+1] = word
        end
      print('Full  length: ', #table.concat(arr))
      print('Dedup length: ', #table.concat(Table.keys(Set.of_values(arr))))
      end
      
    end
  end)
  
return Demo