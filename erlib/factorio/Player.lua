-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- LuaPlayer methods.
--
-- @{Introduction.DevelopmentStatus|Module Status}: Work in progress.
-- @{Introduction.Compatibility|Compatibility}: Factorio Runtime.
--
--
-- @module Player
-- @usage
--  local Player = require('__eradicators-library__/erlib/factorio/Player')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Eradicators Library                                                        --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --

local stop        = elreq('erlib/lua/Error'     )().Stopper 'Player'

-- local Stacktrace = elreq('erlib/factorio/Stacktrace')()

local Verificate = elreq('erlib/lua/Verificate')()
-- local Verify           , Verify_Or
    -- = Verificate.verify, Verificate.verify_or

-- local Tool       = elreq('erlib/lua/Tool'      )()
    
-- local Table      = elreq('erlib/lua/Table'     )()
-- local Array      = elreq('erlib/lua/Array'     )()
-- local Set        = elreq('erlib/lua/Set'       )()

-- local Compose    = elreq('erlib/lua/Meta/Compose')()
-- local L          = elreq('erlib/lua/Lambda'    )()


-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Player,_Player,_uLocale = {},{},{}

-- -------
-- Nothing.
-- @within Todo
-- @field todo1

--------------------------------------------------------------------------------
-- Methods.
-- @section
--------------------------------------------------------------------------------

----------
-- Calls @{FOBJ LuaControl.can_reach_entity} and automatically
-- creates a local flying text at the entity position if not.
--
-- @tparam LuaPlayer p
-- @tparam LuaEntity entity
-- @tparam LocalisedString text (_default:_ `{"cant-reach"}`)
--
-- @treturn boolean 
function Player.try_reach_entity(p, entity, text)
  return p.can_reach_entity(entity)
      or (Player.notify(p, {'cant-reach'}, entity.position) and false)
  end

  
----------
-- Creates a localized flying text for a player.
--
-- @tparam LuaPlayer p
-- @tparam LocalisedString text
-- @tparam Position position
--
function Player.notify(p, text, position)
  return p.create_local_flying_text {
    text     = text    ,
    position = position, --@future: default to selected or player itself?
    }
  end


----------
-- Gets a LuaPlayer object.
--
-- @tparam PlayerSpecification spec It is an error if that player doesn't exist.
-- @treturn LuaPlayer
--
function Player.get_player(spec)
  if Verificate.isType.LuaObject(spec)
  and spec.object_name == 'LuaPlayer'
  then
    if not spec.valid then stop('Given LuaPlayer object was invalid.') end
    return spec
    end
  return assert(game.players[spec]) end

  
----------
-- Sets a shortcut to the opposite state it is in now.
--
-- @tparam LuaPlayer p
-- @tparam string name @{FOBJ LuaShortcutPrototype.name}
--
-- @treturn boolean The new state.
--
function Player.toggle_shortcut (p, name)
  local state = not p.is_shortcut_toggled(name)
  p.set_shortcut_toggled(name,state)
  return state end

  
-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Player') end
return function() return Player,_Player,_uLocale end
