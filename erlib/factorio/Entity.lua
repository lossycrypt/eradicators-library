-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- [Control Stage] LuaEntity manipulation.
--
-- @module Entity
-- @usage
--  local Entity = require('__eradicators-library__/erlib/factorio/Entity')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
local pairs = pairs

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Entity,_Entity,_uLocale = {},{},{}




----------
-- Brute force searches through all surfaces to find an entity.
-- 
-- @tparam uint unit_number The LuaEntity.unit_number of the target entity.
-- @treturn LuaEntity|nil
-- 
function Entity.find_unit_number(unit_number)
  for _,surface in pairs(game.surfaces) do
  for _,entity  in pairs(surface.find_entities()) do
    if entity.unit_number == unit_number then return entity end
    end
    end
  end



--  * as of 2020-10-19 (creation of thread) i can't get this to work
--
--  * [1] https://forums.factorio.com/viewtopic.php?p=518189#p518189
--    If biters are pathing towards the player before teleport they
--    might cause a huge lag spike when the player teleports very
--    far and they try to path towards him.
--    To un-target the player Klonan suggests spawning a 9999999dmg
--    projectile towards the player so that biters assume the
--    player is already quasi-dead and target something else.
--
--  * Needed for Waypoints-8
--
--  * Generalize to spawn a quasi-immovable eternal projectile
--    towards any entity
--
--  * Possibly useful for "stealth" player equipment
--
function Entity.set_ignored_by_enemy_units(onoff) -- ignored_by_biters()

  -- if all such projectiles are spawned at a fixed coordinate (i.e. 1e6+42,1e6+42)
  -- then it's possible to generalize this approach inside the library without
  -- relying on global data.
  
  --> Because to turn it "off" it needs to destroy the projectile

  err()
  end
  
  
--------------------------------------------------------------------------------
-- Section
-- @section
--------------------------------------------------------------------------------

----------
-- Nothing.
-- @within Todo
-- @field todo1

-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Entity') end
return function() return Entity,_Entity,_uLocale end
