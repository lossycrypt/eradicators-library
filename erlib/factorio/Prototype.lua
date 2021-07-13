-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable

--------------------------------------------------
-- Description
--
-- @{Introduction.DevelopmentStatus|Module Status}: Work in progress.
--
-- @module Prototype
-- @usage
--  local Prototype = require('__eradicators-library__/erlib/factorio/Prototype')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Eradicators Library                                                        --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --

local String       = elreq('erlib/lua/String'     )()


-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Prototype,_Prototype,_uLocale = {},{},{}

-- -------
-- Nothing.
-- @within Todo
-- @field todo1

--------------------------------------------------------------------------------
-- Section.
-- @section
--------------------------------------------------------------------------------

----------
-- Merges object_name, group, subgroup, order and name.
-- Used for sorting arrays or arbitary prototype combinations.
--
-- __Memoized__: Reads each prototype only once per session. Subsequent
-- access is native lua table lookup speed.
--
-- @tparam string object_name The runtime-type of the desired prototype.
-- Valid input formats are:
-- `"LuaVirtualSignalPrototype"`, 
-- `"LuaVirtualSignal"`,
-- `"VirtualSignal"` or
-- `"virtual_signal"`. Try to stick to one format as __mixing them
--   costs additional memory__ for memoization.
-- @tparam string name
-- @treturn string
-- @function Prototype.get_absolute_order
do
  local function _get_order(object_name, name)
    local category = String.to_snake_case(object_name)
      :gsub('^lua_?',''):gsub('_?prototypes?$','')
    local prot = game[category..'_prototypes'][name]
    local has_group = (pcall(function() return prot.group    end))
    return table.concat{
      category,
      has_group and prot.group.order    or '',
      has_group and prot.subgroup.order or '',
      prot.order,
      prot.name
      }
    end
  --
  local order = setmetatable({}, {__index = function(self, object_name)
    self[object_name] = setmetatable({}, {__index = function(self, name)
      self[name] = _get_order(object_name, name)
      return self[name]
      end})
    return self[object_name]
    end})
  --
function Prototype.get_absolute_order(object_name, name)
  return order[object_name][name]
  end
  end


-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Prototype') end
return function() return Prototype,_Prototype,_uLocale end
