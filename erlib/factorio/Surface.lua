-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable

--------------------------------------------------
-- Methods for @{FOBJ LuaSurface}.
--
-- @{Introduction.DevelopmentStatus|Module Status}: Work in progress.
--
-- @module Surface
-- @usage
--  local Surface = require('__eradicators-library__/erlib/factorio/Surface')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Eradicators Library                                                        --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Surface, _Surface = {}, {}

-- -------
-- Nothing.
-- @within Todo
-- @field todo1

--------------------------------------------------------------------------------
-- Methods.
-- @section
--------------------------------------------------------------------------------

----------
-- Finds and destroys entities
--
-- @tparam LuaSurface surface
-- @tparam[opt] table parameters Arguments for @{FOBJ LuaSurface.find_entities_filtered}.
--
function Surface.destroy_entities_filtered(surface, parameters)
  local arr = surface.find_entities_filtered(parameters or {})
  for i=1, #arr do arr[i].destroy() end
  end


-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Surface') end
return function() return Surface, _Surface end
