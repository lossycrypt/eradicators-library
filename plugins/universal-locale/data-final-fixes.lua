-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable
-- -------------------------------------------------------------------------- --

--[[ Notes:
  ]]

--[[ Annecdotes:
  ]]

--[[ Future:
  ]]
  
--[[ Todo:
  ]]
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Eradicators Library                                                        --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
-- local log         = elreq('erlib/lua/Log'          )().Logger  'universal-locale-additions'
-- local stop        = elreq('erlib/lua/Error'        )().Stopper 'universal-locale-additions'
-- local assertify   = elreq('erlib/lua/Error'        )().Asserter(stop)

-- local Verificate  = elreq('erlib/lua/Verificate'   )()
-- local verify      = Verificate.verify
-- local isType      = Verificate.isType

local Table       = elreq('erlib/lua/Table'        )()
-- local Array       = elreq('erlib/lua/Array'        )()
-- local Set         = elreq('erlib/lua/Set'          )()
-- local Filter      = elreq('erlib/lua/Filter'       )()
-- local Vector      = elreq('erlib/lua/Vector'       )()
local Color       = elreq('erlib/lua/Color'        )()

-- local ntuples     = elreq('erlib/lua/Iter/ntuples' )()
-- local dpairs      = elreq('erlib/lua/Iter/dpairs'  )()
-- local sriapi      = elreq('erlib/lua/Iter/sriapi'  )()

-- local Setting     = elreq('erlib/factorio/Setting'   )()
-- local Data        = elreq('erlib/factorio/Data/!init')()

-- -------------------------------------------------------------------------- --
-- Constants                                                                  --
-- -------------------------------------------------------------------------- --
local asset  = PluginManager.make_asset_getter('universal-locale', 'eradicators-library')
-- local import = PluginManager.make_relative_require 'universal-locale-additions'
-- local const  = import '/const'

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

-- -------------------------------------------------------------------------- --
-- Local Library                                                              --
-- -------------------------------------------------------------------------- --
  
-- -------------------------------------------------------------------------- --
-- Data                                                                       --
-- -------------------------------------------------------------------------- --

-- Data.SimpleLinkedInput('build','rotate',...)

local player_colors = data.raw['utility-constants']['default'].player_colors

table.insert(player_colors,{
  name = 'rouge',
  player_color = Color('#981400ff'),
  chat_color   = Color('#981400ff'),
  })

local tints = (function(r)
  for _, c in pairs(Table.dcopy(player_colors)) do
    r[c.name] = c.player_color
    r[c.name].a = 1
    end
  return r end){}

-- error(serpent.block(tints))

for name, tint in pairs(tints) do 
  
  data:extend{
    {
      type = "sprite",
      name = "ul:info-" .. name,
      filename = asset '/info-mask.png',
      priority = "extra-high-no-scale",
      width  = 16,
      height = 40,
      mipmap_count = 2,
      flags = {"gui-icon"},
      scale = 0.5,
      tint = tint,
      },
      
    -- The visual difference between
    -- "i" and "!" is insufficient.
    
    -- {
      -- type = "sprite",
      -- name = "ul:exclamation-" .. name,
      -- filename = asset '/exclamation-mask.png', 
      -- priority = "extra-high-no-scale",
      -- width = 64,
      -- height = 160,
      -- flags = {"gui-icon"},
      -- mipmap_count = 4,
      -- scale = 0.5 * 1/4,
      -- tint = tint,
      -- },

    }
    
  end
  