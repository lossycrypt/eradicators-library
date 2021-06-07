-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Description
--
-- @{Introduction.DevelopmentStatus|Module Status}: Work in progress.
--
-- @module Force
-- @usage
--  local Force = require('__eradicators-library__/erlib/factorio/Force')()
  
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

local Force,_Force,_uLocale = {},{},{}

-- -------
-- Nothing.
-- @within Todo
-- @field todo1

--------------------------------------------------------------------------------
-- Section.
-- @section
--------------------------------------------------------------------------------


----------
-- Creates a local flying text for every player in the force.
--
-- @tparam LuaForce force
-- @tparam table args Same as @{FOBJ LuaPlayer.create_local_flying_text}, except
-- that `args.position` defaults to each players current @{Position}.
--
function Force.create_local_flying_text (force, args)
  for _,p in pairs(force.players) do
    if p.connected then
      args.position = args.position or p.position
      p.create_local_flying_text(args)
      end
    end
  end





-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Force') end
return function() return Force,_Force,_uLocale end
