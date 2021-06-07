-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable

--------------------------------------------------
-- Description
--
-- @{Introduction.DevelopmentStatus|Module Status}: Work in progress.
--
-- @module Data
-- @usage
--  local Sprite = require('__eradicators-library__/erlib/factorio/Data/Sprite')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Eradicators Library                                                        --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
-- local log         = elreq('erlib/lua/Log'          )().Logger  'DataSprite'
local stop        = elreq('erlib/lua/Error'        )().Stopper 'DataSprite'
local assertify   = elreq('erlib/lua/Error'        )().Asserter(stop)

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Sprite,_Sprite = {},{}

-- -------
-- Nothing.
-- @within Todo
-- @field todo1

--------------------------------------------------------------------------------
-- Sprite.
-- @usage
--  local Sprite = require('__eradicators-library__/erlib/factorio/Data/Sprite')()
-- @section
--------------------------------------------------------------------------------

----------
-- Extracts icon size and mipmaps from file name.
--
-- Guesses the icon size from the __last__ number.
-- Optionally guesses the mipmap count from the __last__ number prefixed with "mip".
--
-- @usage
-- print(Hydra.lines(Data.Sprite.format_icon('__mod__/my-icon-1_64²-mip2.png')))
-- > {
-- >   icon = "__mod__/my-icon-1_64²-mip2.png",
-- >   icon_mipmaps =  2,
-- >   icon_size    = 64
-- > }
--
-- @tparam string file_path
-- @tparam table options (@{table})
-- @tparam double options.scale
-- @tparam vector options.shift
-- @tparam Color options.tint
--
-- @treturn table @{FWIKI Types IconData}
function Sprite.format_icon(file_path, options)
  options = options or {}
  return {
    icon = file_path:gsub('%.png$','')..'.png', -- supplement missing extension
    icon_size
      = assert(tonumber(file_path:match '.*[^mip]%f[%d](%d+)'), 'Missing icon size'),
    icon_mipmaps
      = tonumber(file_path:match '.*%f[mip]mip(%d*)'),
    scale = options.scale,
    shift = options.shift,
    tint  = options.tint ,
    }
  end




-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Sprite') end
return function() return Sprite,_Sprite end
