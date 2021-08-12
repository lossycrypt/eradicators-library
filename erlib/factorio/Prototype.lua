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
local stop        = elreq('erlib/lua/Error'        )().Stopper 'Prototype'
local assertify   = elreq('erlib/lua/Error'        )().Asserter(stop)

local String      = elreq('erlib/lua/String'     )()

local Verificate  = elreq('erlib/lua/Verificate')()
local verify      = Verificate.verify

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
-- `"virtual_signal"`.
-- @tparam string name
-- @treturn string
-- @function Prototype.get_absolute_order
do
  local order = {}
  --
  local irregular = {
    group      = 'item_group'   ,
    subgroup   = 'item_subgroup',
    item_stack = 'item'         ,
    }
  --
  local function _get_category(object_name)
    assertify(object_name ~= 'LuaGroup',
      '"LuaGroup" is not unique. Please specify "(item_)group" or "(item_)subgroup".')
    local category = String.to_snake_case(object_name)
      :gsub('^lua_?',''):gsub('_?prototypes?$','')
    return irregular[category] or category end
  --
  local function _get_order(category, name)
    local prot = assert(game[category..'_prototypes'])[name]
    verify(prot, 'LuaObject', 'Unknown prototype name.',
      '\ncategory: '  , category,
      '\nname      : ', name    )
    local has_group    = (pcall(function() return prot.group    end))
    local has_subgroup = (pcall(function() return prot.subgroup end))
    local has_order    = (pcall(function() return prot.order    end))
    return table.concat{
      category,
      has_group    and prot.group.order    or '',
      has_subgroup and prot.subgroup.order or '',
      has_order    and prot.order          or '',
      prot.name
      }
    end
  --
  setmetatable(order, {__index = function(self, object_name)
    local category = _get_category(object_name)
    self[object_name]
      = rawget(self, category)
      or setmetatable({}, {__index = function(self, name)
        self[name] = _get_order(category, name)
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
