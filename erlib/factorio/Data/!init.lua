-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Description
--
-- @{Introduction.DevelopmentStatus|Module Status}: Work in progress.
--
-- @module Data
-- @usage
--  local Data = require('__eradicators-library__/erlib/factorio/Data/!init')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --

local log  = elreq('erlib/lua/Log'  )().Logger  'Data'
local stop = elreq('erlib/lua/Error')().Stopper 'Data'

-- local Stacktrace = elreq('erlib/factorio/Stacktrace')()

local Verificate = elreq('erlib/lua/Verificate')()
local Verify           , Verify_Or
    = Verificate.verify, Verificate.verify_or

local Tool       = elreq('erlib/lua/Tool'      )()
    
local Table      = elreq('erlib/lua/Table'     )()
-- local Array      = elreq('erlib/lua/Array'     )()
-- local Set        = elreq('erlib/lua/Set'       )()

-- local Crc32      = elreq('erlib/lua/Coding/Crc32')()

-- local Cache      = elreq('erlib/factorio/Cache')()

-- local Compose    = elreq('erlib/lua/Meta/Compose')()
local L          = elreq('erlib/lua/Lambda'    )()


local Color = elreq('erlib/lua/Color')()

-- local Table_dcopy
    -- = Table.dcopy

-- local setmetatable, pairs, ipairs, select
    -- = setmetatable, pairs, ipairs, select
    
-- local table_insert, math_random, math_floor, table_unpack, table_remove
    -- = table.insert, math.random, math.floor, table.unpack, table.remove
    


-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Data,_Data,_uLocale = {},{},{}



-- -------
-- Nothing.
-- @within Todo
-- @field todo1

--------------------------------------------------------------------------------
-- custom-input.
-- @section
--------------------------------------------------------------------------------

--[[

  data:extend{{
    type                = 'custom-input',
    name                = 'er:belt-router-rotate-right',
    consuming           = nil,
    key_sequence        = '',
    linked_game_control = 'rotate',
    }}

  "consuming" available options:
  
    none       : default if not defined
                 
    game-only  : The opposite of script-only: blocks game inputs using the same
                 key sequence but lets other custom inputs using the same key sequence fire.
    
  As of 0.15.24 "all" and "script-only" have been removed.
  
    all        : if this is the first input to get this key sequence
                 then no other inputs listening for this sequence are fired
                 
    script-only: if this is the first *custom* input to get this key sequence
                 then no other *custom* inputs listening for this sequence are fired.
                 Normal game inputs will still be fired even if they match this sequence.
  ]]


----------
-- Creates a custom input for use with a custom event handler.
-- 
-- __Note:__ Key sequence detection is very strict:
-- 
--   - All letters must be __capitalized__, i.e `A`, `B`, `SPACE`, `ENTER`.
--   - Except for `mouse-` keys which use lower case, i.e. `mouse-button-1`.
--   - "+" plus must be surrounded by space.
--   - Modifiers are CONTROL, SHIFT and ALT.
--   - LCTRL, RCTRL, LSHIFT, RSHIFT, LALT and RALT can only be used standalone.
--   - Numpad keys start with `KP_`, i.e. `KP_MULTIPLY`, `KP_1`.
-- 
-- @see LuaCustomInputPrototype
-- 
-- @tparam string name_prefix Each mod should use a unique prototype name prefix
-- to avoid incompatibilities with other mods.
-- @tparam string name The name of every CustomInputPrototype is also an @{EventUID}.
-- @tparam string key The _default_ key sequence. Can be changed by the player later.
-- If you want an input to use the same key as a base game control use
-- @{Data.SimpleLinkedInput} instead.
-- @tparam[opt=false] boolean consuming If true the input will block vanilla inputs with
-- the same key sequence.
-- 
-- @treturn CustomInputPrototype A table reference. You do __not__ need to call
-- `data:extend` on this as it has already been added.
--
-- @usage
--   -- in data.lua
--   Data.SimpleCustomInput('my-mod:', 'a-new-hotkey', 'CONTROL + N')
--
--   -- in control.lua
--   EventManager.new_handler {
--     'my-mod:a-new-hotkey',
--     function(e)
--       local player = game.players[e.player_index]
--       player.print('You have pressed the hotkey!')
--       end
--     }
--
function Data.SimpleCustomInput(name_prefix, name, key, consuming)
  do
    -- Check for SOME common mistakes in key sequence definitions to prevent
    -- "Unknown" key assignment. It would be trivial to just fix these
    -- errors, but it's better to teach the user to do it right.
    for str in key:gmatch'%a[%a%-]+' do
      Verify((str == str:upper()) or (not not str:find'mouse-'), 'true',
        'Key sequence keys must be written in capital letters:\n', key)
      Verify(str:upper() ~= 'CTRL','true',
        'Key sequence modifier must be CONTROL not CTRL:\n', key)
      Verify(not str:upper():find('NUMPAD'),'true',
        'Key sequence uses KP_ not NUMPAD_:\n', key)
      end
    for str in key:gmatch' ?+ ?' do Verify(str == ' + ', 'true',
      'Key sequence "+" plus sign must be surrounded by spaces:\n', key)
      end
    for str in key:gmatch'f%d' do stop(
      'Key sequence F-Key must use capital letter F:\n', key)
      end
    end
  local input = {
    type         = 'custom-input',
    -- Putting an 'on_custom_input_' prefix on the name would be redundant
    -- because only custom inputs events have *string* names in the first place,
    -- and it would make using mod based prefixes impossible.
    name         = name_prefix .. name,
    -- Does NOT support LINKED input to enforce a common naming scheme for links.
    key_sequence = key or '',
    consuming    = Tool.Select(consuming, 'game-only', 'none'),
    }
  data:extend{input}
  log:debug('Created SimpleCustomInput: ', input.name, ', ', key)
  return input
  end


----------
-- Creates a custom input that always uses the same key as a base game
-- input even if the user changes it.
-- 
-- The @{EventUID} and prototype name are prefixed with `on_linked_input_`
-- and `-` dashes are replaced with `_` underscores.
-- 
-- @tparam InputName ... Any number of input names.
--
-- @usage
--   -- in data.lua
--   Data.SimpleLinkedInput('rotate','toggle-map')
--
--   -- in control.lua
--   EventManager.new_handler {
--     'on_linked_input_rotate',
--     function(e)
--       local player = game.players[e.player_index]
--       player.print('You have pressed the rotate button!')
--       if player.selected then
--         game.print('Your mouse is hovering over:'..player.selected.name)
--         end
--       end
--     } 
--   EventManager.new_handler {
--     'on_linked_input_toggle_map',
--     function(e)
--       -- do something here
--       end
--     } 
--
function Data.SimpleLinkedInput(...)
  for _, input_name in pairs{...} do
    Verify(input_name, 'InputName')
    local name = 'on_linked_input_'..input_name:gsub('-', '_')
    log:debug('Created SimpleLinkedInput: ', name)
    data:extend{{
      type                = 'custom-input',
      name                = name          ,
      linked_game_control = input_name    ,
      key_sequence        = ''            ,
      }}
    end
  end
  

--------------------------------------------------------------------------------
-- setting.
-- @section
--------------------------------------------------------------------------------

  
--internal_name = {name,scope,type,default or {default,min,max},order,values=,...}

function Data.SimpleSetting()
  end
  
  
-- draft: didn't exist in old library
--name&control_input,toggleable,enabled_icon_file_name,disabled_icon_file_name
function Data.SimpleShortcut()
  end

  
--------------------------------------------------------------------------------
-- path.
-- @section
--------------------------------------------------------------------------------
Data.Path = {}

----------
-- Joins several partial paths into a single string.
-- 
-- @tparam string ... Any number of partial paths. They will be joined with '/'
-- and any erroneously duplicated slashes will be removed.
-- 
-- @treturn string The joined path.
-- 
function Data.Path.join(...)
  return table.concat({...},'/'):gsub('/+','/')
  end
  
  
  
--------------------------------------------------------------------------------
-- icon.
-- @section
--------------------------------------------------------------------------------
Data.Icon = {}

----------
-- Creates a basic icon table.
-- 
-- @tparam string root The path of the folder containing the image.
-- @tparam string filename The name of the image file without the path.
-- @tparam[opt] NaturalNumber size If the filename ends in a squared number
-- like `32²` then the size can be omitted.
-- @tparam[opt] ColorSpecification tint
--
-- @treturn table
--
-- @usage
--   local icon = Data.Icon.SimpleIconTable(
--     '__my-mod__/', 'my-picture-32².png', nil, {r=1}
--     )
--   print(Hydra.lines(icon))
--   > {
--   >   icon = "__my-mod__/my-picture-32².png",
--   >   icon_size = 32,
--   >   tint = {a = 1, b = 1, g = 1, r = 1}
--   > }
--
function Data.Icon.SimpleIconTable(root, filename, size, tint)
  local size = size or tonumber(filename:match'(%d+)²%.png$')
  Verify(size, 'number', 'Missing icon size.')

  return {
    icon      = Data.Path.join(root, filename),
    icon_size = size,
    tint      = (tint and Color(tint) or nil), -- Color.ColorSpecification
    }
  end

  
  
--------------------------------------------------------------------------------
-- all prototypes.
-- @section
--------------------------------------------------------------------------------

----------
-- Advanced prototype creation and forking.
--
-- Processing order:  
--   - Deep-copy the input table.  
--   - Shallow merge with parent deep-copy.  
--   - Apply `magic.post_patches`.  
--   - Apply @{Table.remove_nil}.  
--
-- @tparam table prototype A normal prototype table like you would pass to
-- `data:extend{}`.
-- 
-- @tparam[opt] table prototype.magic A table of advanced inscription instructions.
-- @tparam[opt] string prototype.magic.parent_name
-- @tparam[opt] string prototype.magic.parent_type
-- If name or type or both are given then prototype will be @{Table.smerge|merged}
-- onto a @{Table.dcopy|deep copy} of the parent before any further processing.
-- @tparam[opt] string prototype.magic.post_patches A DenseArray of @{TablePatch},
-- applied _after_ forking via @{Table.patch}.  
-- 
-- @treturn table A reference to the prototype table after it was added to data.raw.
-- 
function Data.Inscribe (prototype)
  
  local prototype = Table.dcopy (prototype)
  local magic     = Table.remove(prototype, {'magic'}) or {}
  
  --
  -- Table.patch(prototype, new.pre_patches or {}) -- was this ever used?
  
  -- fork?
  local new
  if magic.parent_name or magic.parent_type then
    local parent_name = magic.parent_name or prototype.name
    local parent_type = magic.parent_type or prototype.type
    local parent      = Table.dcopy(data.raw[parent_type][parent_name])
    new = Table.smerge(parent, prototype)
  else
    new = prototype
    end
  
  --
  Table.patch(new, magic.post_patches or {})
  Table.remove_nil(new)
  
  --
  data:extend{new}
  return new
  end
  
-- -------------------------------------------------------------------------- --
-- Draft                                                                      --
-- -------------------------------------------------------------------------- --








-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Data') end
return function() return Data,_Data,_uLocale end
