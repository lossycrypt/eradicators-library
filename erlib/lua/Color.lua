-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Description
--
-- @{Introduction.DevelopmentStatus|Module Status}: Work in progress.
--
-- @module Color
-- @usage
--  local Color = require('__eradicators-library__/erlib/factorio/Color')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --

local stop = elreq('erlib/lua/Error')().Stopper('Color')
-- local log  = 

local Class = elreq('erlib/lua/Class')()


-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Color,_Color,_uLocale = {},{},{}


-- -------
-- Nothing.
-- @within Todo
-- @field todo1

--------------------------------------------------------------------------------
-- Concepts.
-- @section
--------------------------------------------------------------------------------

----------
-- __DRAFT.__ A color specification.
-- 
-- There are several formats:
-- 
-- Hex-RGB(A):  
-- Html-Color Name:  
-- 
-- LuaTable-RGB(A):
-- `{r=1, g=1, b=1, a=1}`
-- 
-- 
-- @table ColorSpecification


----------
-- A lua table representing an RGBA color.  
-- All values are @{UnitInterval}s.  
-- `{r=1, g=1, b=1, a=1}`
--
-- @table NormalizedColor



--------------------------------------------------------------------------------
-- Alpha.  
-- @section
--------------------------------------------------------------------------------

----------
-- __DRAFT.__ Creates a color table.
--
-- @tparam ColorSpecification color_spec
--
-- @treturn NormalizedColor
--
-- @function Color
local Color; Color = Class.SwitchCaseClass(
  -- analyzer
  function(spec)
    if type(spec) == 'table' then
      return 'lua_table'
    else
      err('not implemented color spec type')
      end
    end,
  -- cases
  {
   lua_table = function(c)
    --@future: does this have to immedeatly apply premultiply?
    -- probably not for lua_tables (user knows what they're doing)
    -- but for other specifications like hex?
    return {r = c.r or 1, g = c.g or 1, b = c.b or 1, a = c.a or 1}
    end,
  
  })
  
  
----------
-- Multiplies all channels of a color table with alpha.
-- Factorio expects color in this format most of the time.
--
-- @tparam NormalizedColor rgba_color
-- @tparam[opt] UnitInterval alpha Will be used instead of `color.a` if given.
--
-- @treturn NormalizedColor A new color table.
--
function Color.premultiply_alpha(rgba_color, alpha)
  local c = rgba_color
  alpha = alpha or c.a or stop('Missing alpha')
  return {
    r = c.r * alpha,
    g = c.g * alpha,
    b = c.b * alpha,
    a = alpha,
    }
  end




-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Color') end
return function() return Color,_Color,_uLocale end
