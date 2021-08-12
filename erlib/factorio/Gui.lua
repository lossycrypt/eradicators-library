-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable

--------------------------------------------------
-- Description
--
-- @{Introduction.DevelopmentStatus|Module Status}: Work in progress.
--
-- @module Gui
-- @usage
--  local Gui = require('__eradicators-library__/erlib/factorio/Gui')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Eradicators Library                                                        --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --

-- local log         = elreq('erlib/lua/Log'       )().Logger  'Gui'
local stop        = elreq('erlib/lua/Error'     )().Stopper 'Gui'

local Table       = elreq('erlib/lua/Table'        )()
local Array       = elreq('erlib/lua/Array'        )()

local Verificate  = elreq('erlib/lua/Verificate')()
local verify      = Verificate.verify

local isTable     = Verificate.isType.table

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Gui,_Gui,_uLocale = {},{},{}

-- -------
-- Nothing.
-- @within Todo
-- @field todo1

--------------------------------------------------------------------------------
-- Generic.
-- @section
--------------------------------------------------------------------------------

----------
-- Destroys a gui element or does nothing.
-- @tparam[opt] LuaGuiElement elm
function Gui.destroy(elm)
  if elm then elm.destroy() end
  end

----------
-- Recursively find a named element. Depth-first search.
-- @tparam LuaGuiElement parent The element to start searching at.
-- @tparam string name
-- @treturn nil|LuaGuiElement The first element with a matching name, if any.
--
function Gui.find_child (parent, name)
  if parent.name == name then
    return parent
    end
  for _, elm in pairs(parent.children) do
    if elm.name == name then
      return elm
    else
      local r = Gui.find_child(elm, name)
      if r then return r end
      end
    end
  end
  
----------
-- Gets all elements above an element.
-- Most useful to get the anchor element or the name of the root.
-- 
-- @tparam LuaGuiElement elm
-- @treturn DenseArray Starts at the root element (screen, relative, etc.) and
-- ends at the input element.
function Gui.get_ancestors(elm)
  local i, r = 1, {elm}
  repeat; i = i + 1
    r[i] = elm.parent
    elm = r[i]
    until not r[i]
  return Array.reverse(r) end
  
--------------------------------------------------------------------------------
-- Screen.
-- @section
--------------------------------------------------------------------------------

  
----------
-- Moves a @{FOBJ LuaGuiElement} inside @{FOBJ LuaGui.screen}.
--
-- @tparam LuaGuiElement elm
-- @tparam NaturalNumber w Width
-- @tparam NaturalNumber h Height
-- @tparam[opt=0.5] UnitInterval x Relative center position on the x axis.
-- @tparam[opt=0.5] UnitInterval y
--
-- @treturn LuaGuiElement The given element.
function Gui.move(elm, w, h, x, y)
  x,y = x or 0.5, y or 0.5 --range 0~1, how far on each axis the elm center is displaced from center
  local p     = game.players[elm.player_index]
  local res   = p.display_resolution
  local scale = p.display_scale
  local loc   = {(res.width - (w*scale)) * x, (res.height - (h*scale)) * y}
  elm.location = loc
  elm.style.width,elm.style.height = w, h
  return elm end

  
----------
-- Creates a draggable title-bar with close button.
-- Mimics vanilla style in accordance with
-- [Raiguards Style Guide](https://github.com/raiguard/Factorio-SmallMods/wiki/GUI-Style-Guide)
--
-- @tparam table opts
-- @tparam LuaGuiElement opts.anchor The LuaGuiElement that the title bar will be created in.
-- @tparam LocalisedString|string opts.caption
-- @tparam[opt] LuaGuiElement opts.drag_target
-- @tparam[opt] string opts.close_button_name 
-- @tparam[opt] string opts.minimize_button_name
-- @treturn table A table containing the created LuaGuiElements.
-- `{title_flow=, title_label=, drag_widget=, minimize_button=, close_button=}`
function Gui.create_title_bar(opts)
  -- (Originally from skin-swapper)
  local r = {}
  --title flow
  r.title_flow = assert(assert(opts).anchor).add{
    type      = 'flow',
    direction = 'horizontal',
    }
  r.title_flow.drag_target = opts.drag_target -- gui.screen only 
  r.title_label = r.title_flow.add{
    type    = 'label',
    caption = assert(opts.caption),
    style   = 'frame_title',
    }
  r.title_label.ignored_by_interaction = true -- required for dragging...wth
  r.drag_widget = r.title_flow.add{
    type  = 'empty-widget',
    style = 'draggable_space_header',
    }
  r.drag_widget.style.height = 24
  r.drag_widget.style.horizontally_stretchable = true
  r.drag_widget.style.right_margin = 4
  r.drag_widget.ignored_by_interaction = true -- required for dragging...wth
  
  if opts.minimize_button_name then
    r.minimize_button = r.title_flow.add{
      name                = opts.minimize_button_name,
      type                = 'sprite-button'        ,
      style               = 'frame_action_button'  ,
      -- sprite              = 'utility/collapse'     ,
      -- hovered_sprite      = 'utility/collapse'     ,
      -- clicked_sprite      = 'utility/collapse_dark',
      mouse_button_filter = {'left'}               ,
      }
    Gui.set_minimize_button_sprite(r.minimize_button, true)
    end
  
  r.close_button = r.title_flow.add{
    name                = opts.close_button_name,
    type                = 'sprite-button'       ,
    style               = 'frame_action_button' ,
    sprite              = 'utility/close_white' ,
    hovered_sprite      = 'utility/close_black' ,
    clicked_sprite      = 'utility/close_black' ,
    mouse_button_filter = {'left'}              ,
    }
  return r end
  
----------
-- Updates the sprite on a min-max button.
-- @tparam LuaGuiElement elm This must be a `sprite-button`!
-- @tparam boolean state True is a downwards arrow, false is a rightwards arrow.
function Gui.set_minimize_button_sprite(elm, state)
  if state then
    elm.sprite              = 'utility/collapse'     
    elm.hovered_sprite      = 'utility/collapse'     
    elm.clicked_sprite      = 'utility/collapse_dark'
  else
    elm.sprite              = 'utility/expand'     
    elm.hovered_sprite      = 'utility/expand'     
    elm.clicked_sprite      = 'utility/expand_dark'
    end
  end
  
  
--------------------------------------------------------------------------------
-- AutoStyler.
-- These functions will silently do nothing unless activated.
-- @section
-- @usage
--   -- settings.lua
--   erlib_enable_plugin('gui-auto-styler')
--------------------------------------------------------------------------------
do

  local const = require '__eradicators-library__/plugins/gui-auto-styler/const'

  ----------
  -- Automatically updates this sliders tooltip when it's value changes.
  -- 
  -- @tparam LuaGuiElement elm
  -- @tparam LocalisedString|string postfix
  -- @treturn LuaGuiElement The given element.
  function Gui.set_slider_auto_tooltip(elm, postfix)
    local tags = elm.tags
    local data = Table.sget(tags, const.path.style_data, {})
    data[const.index.style_data.slider_value_tooltip_postfix] = postfix or ''
    elm.tags = tags
    -- initialize tooltip. @future: call the real event handler
    elm.tooltip = {'', elm.slider_value, postfix} -- Not working for unknown reason.
    return elm end

  end
  
  
--------------------------------------------------------------------------------
-- Constructor.
-- @section
--------------------------------------------------------------------------------

--[[ Todo:

  + Should have a seperate function that "normalized" an
    input argument table.
    
    
  + Gui.Constructor(theme)(spec)(element)
    
  + This is really old code (2020-03) and should be reviewed @ 2021-08.

  ]]
do -- start Constructor block
    
  local DefaultTheme = {
    --if the default theme ever has table properties then it needs
    --to be copied before merging in constructor.
    ["button"            ] = {type="button"            },
    ["sprite-button"     ] = {type="sprite-button"     },
    ["choice-button"     ] = {type="choose-elem-button"},
    ["choose-elem-button"] = {type="choose-elem-button"},
    ["checkbox"          ] = {type="checkbox"          },
    ["flow"              ] = {type="flow"              },
    ["frame"             ] = {type="frame"             },
    ["label"             ] = {type="label"             },
    ["line"              ] = {type="line"              },
    ["progressbar"       ] = {type="progressbar"       },
    ["table"             ] = {type="table"             },
    ["textfield"         ] = {type="textfield"         },
    ["text-field"        ] = {type="textfield"         }, --typo protection
    ["textbox"           ] = {type="text-box"          }, --typo protection
    ["text-box"          ] = {type="text-box"          }, 
    ["radiobutton"       ] = {type="radiobutton"       },
    ["sprite"            ] = {type="sprite"            },
    ["scroll-pane"       ] = {type="scroll-pane"       },
    ["drop-down"         ] = {type="drop-down"         },
    ["list-box"          ] = {type="list-box"          },
    ["camera"            ] = {type="camera"            },
    ["slider"            ] = {type="slider"            },
    ["minimap"           ] = {type="minimap"           },
    ["entity-preview"    ] = {type="entity-preview"    },
    ["empty-widget"      ] = {type="empty-widget"      },
    ["empty"             ] = {type="empty-widget"      },
    ["tabbed-pane"       ] = {type="tabbed-pane"       },
    ["tab"               ] = {type="tab"               },
    ["switch"            ] = {type="switch"            },
    
    --some very basic shortcuts without styler
    ['vertical_flow'     ] = {type='flow' ,direction='vertical'  },
    ['horizontal_flow'   ] = {type='flow' ,direction=nil         }, --default direction! ;)
    ['vertical_frame'    ] = {type='frame',direction='vertical'  },
    ['horizontal_frame'  ] = {type='frame',direction=nil         }, --default direction! ;)
    ["vertical_line"     ] = {type="line" ,direction='vertical'  },            
    ["horizontal_line"   ] = {type="line" ,direction=nil         },      

    }
  
  --these attributes are ignored by LuaGuiElement.add()
  --and need to be applied *after* creating a new element.
  local post_creation_attributes = {
    'entity', 'word_wrap', 'locked', 'ignored_by_interaction',
    }
  
  --resolves all parent relationships in the theme so that each ThemedType
  --becomes fully specified and does not need additional lookups at runtime.
  local themed_type_remapper = Table.remapper{
    [1] = 'type',
    [2] = 'path',
    }
  local styler_remapper = Table.remapper{
    [1] = 'width' ,
     w  = 'width' ,
    [2] = 'height',
     h  = 'height',
    }
  local function merge_stylers(s1,s2)
    return Table.smerge(
      styler_remapper(Table.fcopy(s1) or {}), -- hotfix: "or {}" 2021-08-10
      styler_remapper(Table.fcopy(s2) or {})
      )
    end
  local function _normalise_theme (user_theme)
    --don't touch input table!
    -- local theme = Table.fcopy(Table.smerge({},DefaultTheme,user_theme))
    local theme = Table.normalizer(DefaultTheme)(Table.fcopy(user_theme)) -- potential change of DefaultTheme, relevant?
    --remap shortcuts
    for name,themed_type in pairs(theme) do
      theme[name] = themed_type_remapper(themed_type)
      end
    --resolve inheritance
    local done
    repeat
      done = true
      for name,themed_type in pairs(theme) do
        local parent = theme[themed_type.type]
        themed_type = Table.fcopy(themed_type)
        if parent and (parent.type ~= themed_type.type) then
          parent = Table.fcopy(parent)
          local parent_type = parent.type
          theme[name] = Table.smerge(parent,themed_type)
          theme[name].type = parent_type --keep parent type
          theme[name].styler = merge_stylers(parent.styler,themed_type.styler)
          done = false
          end
        end
      until done == true
    return theme end
  
  --hardcodes all ThemedType properties directly into the layout
  --@norm_theme: a *normalised* theme
  --@user_layout: a user supplied layout table
  local function _normalise_layout (norm_theme,user_layout)
    local normalizers = {}
    for name,themed_type in pairs(norm_theme) do
      normalizers[name] = Table.normalizer(themed_type)
      end
    local function walk(user_layout)
      verify(user_layout,'NonEmptyArray')
      local norm_layout = {}
      for i=1,#user_layout do
        local this = user_layout[i]
        assert(this[1], 'Empty table in layout')
        if isTable(this[1]) then --a group of children
          norm_layout[i] = walk(this)
        else
          --1) translate [1] -> ['type'], etc...
          this = themed_type_remapper(Table.fcopy(this)) --copy per node to make reused stylers unique
          local parent_styled_type = norm_theme[this.type]
          --2) insert ThemedType into layout
          this = normalizers[this.type or stop('Layout has unknown ThemedType',this)](this)
          --3) fix type non-inheritance
          this.type = parent_styled_type.type
          --4) translate [1] -> ['width'], etc...
          this.styler = merge_stylers(parent_styled_type.styler,this.styler)
          --5) extract extras
          this.extras = {}
          for _,name in pairs(post_creation_attributes) do
            if this[name] ~= nil then this.extras[name] = this[name]; this[name] = nil end
            end
          --6) pluralize path
          if this.path then this.path = Table.plural(this.path) end
          --7) remove empty
          this.tags   = Table.nil_if_empty(this.tags  )
          this.styler = Table.nil_if_empty(this.styler)
          this.extras = Table.nil_if_empty(this.extras)
          --8) store
          norm_layout[i] = this
          end
        end
      return norm_layout end
    return walk(user_layout) end
    
  --@norm_layout: a layout table with all themed properties pre-encoded
  --@root: LuaGuiElement. The root element that the layout will be added to.
  local Table_simple_set = Table.set
  local function _construct (norm_layout,root,return_last_first)
    if not root.valid then stop('Invalid root elemeent for gui construction') end
    local r = {}
    local last = root
    local function build (parent,layout)
      local next_parent = parent
      for i=1,#layout do
        local this = layout[i]
        if not this.type then
          build(next_parent,this)
        else
          last = parent.add(this)
          next_parent = last
          if this.path   then Table_simple_set(r,this.path,last)                     end
          if this.extra  then for k,v in pairs(this.extras) do last[k] = v           end end
          if this.tags   then last.tags = this.tags end
          -- if this.tags   then for k,v in pairs(this.tags  ) do Gui.set_tag(last,k,v) end end
          if this.styler then
            local style = last.style; for k,v in pairs(this.styler) do style[k] = v end
            end
          end
        end
      end
    build(root, norm_layout)
    if return_last_first then return last, r end
    return r end
  
  ----------
  -- Makes Guis.
  -- __Curried function__. __Unsupported draft.__
  -- @usage Gui.constructioneer(theme)(layout)(root, return_last_first)
  -- 
  -- @tparam[opt] RuntimeTheme theme
  -- @tparam GuiLayout layout
  -- @tparam LuaGuiElement root 
  -- @tparam boolean return_last_first
  -- 
  -- @treturn table 
  -- 
  -- @function Gui.constructioneer
  function Gui.constructioneer (user_theme)
    local norm_theme = _normalise_theme(user_theme)
    return function (user_layout)
      local norm_layout = _normalise_layout(norm_theme, user_layout)
      return function (root, return_last_first) -- constructor function
        return _construct(norm_layout, root, return_last_first)
        end
      end
    end
  
  ----------
  -- Constructioneer theme.
  -- @tfield string type A LuaGuiElement type.
  -- @field[opt] ... Additional @{FOBJ LuaGuiElement.add} arguments.
  -- @table RuntimeTheme

  ----------
  -- Constructioneer layout.
  -- Recursively specifies a Guis layout. Each ElementSpec creates a new
  -- relative root element for the subsequent GuiLayouts.
  -- 
  -- @tfield DenseArray ... An array of ElementSpec or GuiLayout.
  -- @table GuiLayout
  
  ----------
  -- Constructioneer Element.
  -- @tfield string 1 ThemedType
  -- @tfield string type ThemedType
  -- @tfield RuntimeStyle styler
  -- @table ElementSpec
  
  ----------
  -- Constructioneer style.
  -- A table of LuaStyle (key -> value) pairs.
  -- @table RuntimeStyle
  
  end -- end Constructor block
  
  
-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Gui') end
return function() return Gui,_Gui,_uLocale end
