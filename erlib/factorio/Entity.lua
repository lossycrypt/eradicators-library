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
