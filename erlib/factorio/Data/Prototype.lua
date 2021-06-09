-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable

--------------------------------------------------
-- Description
--
-- @{Introduction.DevelopmentStatus|Module Status}: Work in progress.
--
-- @module Data
-- @usage
--  local Prototype = require('__eradicators-library__/erlib/factorio/Data/Prototype')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Eradicators Library                                                        --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
-- local log         = elreq('erlib/lua/Log'          )().Logger  'DataPrototype'
local stop        = elreq('erlib/lua/Error'        )().Stopper 'DataPrototype'
local assertify   = elreq('erlib/lua/Error'        )().Asserter(stop)

local Verificate  = elreq('erlib/lua/Verificate'   )()
local verify      = Verificate.verify
local isType      = Verificate.isType

local Table       = elreq('erlib/lua/Table'        )()

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Prototype,_Prototype = {},{}

-- -------
-- Nothing.
-- @within Todo
-- @field todo1

--------------------------------------------------------------------------------
-- Prototype.
-- @usage
--  local Prototype = require('__eradicators-library__/erlib/factorio/Data/Prototype')()
-- @section
--------------------------------------------------------------------------------

----------
-- Retrieves a prototype table reference from data.raw
-- Raises an error if that prototype doesn't exist.
-- 
-- @tparam string type
-- @tparam string name
-- 
-- @treturn table prototype
function Prototype.get(type, name)
  return verify(data.raw[type][name], 'table',
    'Prototype not found:', '\ntype:', type, '\nname:', name)
  end

----------
-- Retrieves enabled status of a recipe, technology or custom-input.
-- If neither normal nor expensive difficulty is explicitly defined
-- then inline data is treated as normal difficulty data.
--
-- @tparam table prototype
-- 
-- @treturn boolean If normal difficulty is enabled.
-- @treturn boolean If expensive difficulty is enabled. If the
-- prototype does not define expensive difficulty this will be the same
-- as normal difficulty.
--
function Prototype.get_enabled(prototype)
  local this = verify(prototype, 'table')
  local function f(this)
    -- As of 1.1.34 there are three types with ".enabled":
    -- recipe, technology and custom-input. All three
    -- default to "true" if (enabled == nil)
    return (type(this) == 'table')
       and (this.enabled or (this.enabled == nil))
    end
  --
  if this.normal == nil and this.expensive == nil then
    return f(this), f(this)
  else
    return 
      (this.normal    ~= false) and ( f(this.normal   ) or f(this.expensive) ),
      (this.expensive ~= false) and ( f(this.expensive) or f(this.normal   ) )
    end
  end
 
 
----------
-- Sets the enabled status on a recipe, technology or custom-input.
-- If neither normal nor expensive difficulty is explicitly defined
-- then inline data is treated as normal difficulty data.
--
-- @tparam table prototype
--
-- @tparam boolean normal_enabled 
-- @tparam boolean expensive_enabled _(default: normal\_enabled_)
-- If the prototype does not have explicit difficulty sub-tables
-- this value is ignored.
--
function Prototype.set_enabled(prototype, normal_enabled, expensive_enabled)
  local this = verify(prototype, 'table')
  verify(normal_enabled   , 'bool'    , 'normal_enabled invalid type'   )
  verify(expensive_enabled, 'bool|nil', 'expensive_enabled invalid type')
  if expensive_enabled == nil then expensive_enabled = normal_enabled end
  if this.normal == nil and this.expensive == nil then
    this.enabled = normal_enabled
  else
    this.enabled = nil
    --
    local function f(this, key, enabled)
      if type(this[key]) == 'table' then
        this[key].enabled = enabled
      elseif (enabled == false) then
        this[key] = false
      else
        this[key] = nil
        end
      end
    f(this, 'normal'   , normal_enabled   )
    f(this, 'expensive', expensive_enabled)
    end
  end

-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Prototype') end
return function() return Prototype,_Prototype end
