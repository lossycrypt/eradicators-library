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
-- Eradicators Library                                                        --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
local stop  = elreq('erlib/lua/Error')().Stopper('Color')
local assertify = elreq('erlib/lua/Error')().Asserter(stop)
local Class = elreq('erlib/lua/Class')()

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --
local Color

-- -------------------------------------------------------------------------- --
-- Wube Util                                                                  --
-- -------------------------------------------------------------------------- --
-- Factorio '__core__/lualib/util.lua'
-- File can't be directly required
-- because it alters _ENV.

-- lossycrypt 2021-06-05: edited to always include alpha
local function wube_util_color(hex)  -- supports 'rrggbb', 'rgb', 'rrggbbaa', 'rgba', 'ww', 'w'
  hex = hex:gsub("#","")
  local function h(i,j)
    return j and tonumber("0x"..hex:sub(i,j)) / 255 or tonumber("0x"..hex:sub(i,i)) / 15
    end
  return
       #hex == 6 and {r = h(1,2), g = h(3,4), b = h(5,6), a = 1     }
    or #hex == 3 and {r = h(1  ), g = h(2  ), b = h(3  ), a = 1     }
    or #hex == 8 and {r = h(1,2), g = h(3,4), b = h(5,6), a = h(7,8)}
    or #hex == 4 and {r = h(1  ), g = h(2  ), b = h(3  ), a = h(4  )}
    or #hex == 2 and {r = h(1,2), g = h(1,2), b = h(1,2), a = 1     }
    or #hex == 1 and {r = h(1  ), g = h(1  ), b = h(1  ), a = 1     }
    or {r=1, g=1, b=1, a=1}
  end
  
-- -------------------------------------------------------------------------- --
-- Color Tables                                                               --
-- -------------------------------------------------------------------------- --
-- Lookup colors are NOT premultiply with alpha!

local color_table = (function(r)
  for k, v in pairs(r) do
    if type(v) == 'string' then r[k] = wube_util_color(v) end
    end
  return r end) {
  
  -- HTML Color Names                                                                                                 
  ['AliceBlue'      ]='F0F8FF', ['AntiqueWhite'     ]='FAEBD7', ['Aqua'                ]='00FFFF', ['Aquamarine'      ]='7FFFD4', 
  ['Azure'          ]='F0FFFF', ['Beige'            ]='F5F5DC', ['Bisque'              ]='FFE4C4', ['Black'           ]='000000', 
  ['BlanchedAlmond' ]='FFEBCD', ['Blue'             ]='0000FF', ['BlueViolet'          ]='8A2BE2', ['Brown'           ]='A52A2A', 
  ['BurlyWood'      ]='DEB887', ['CadetBlue'        ]='5F9EA0', ['Chartreuse'          ]='7FFF00', ['Chocolate'       ]='D2691E', 
  ['Coral'          ]='FF7F50', ['CornflowerBlue'   ]='6495ED', ['Cornsilk'            ]='FFF8DC', ['Crimson'         ]='DC143C', 
  ['Cyan'           ]='00FFFF', ['DarkBlue'         ]='00008B', ['DarkCyan'            ]='008B8B', ['DarkGoldenRod'   ]='B8860B', 
  ['DarkGray'       ]='A9A9A9', ['DarkGrey'         ]='A9A9A9', ['DarkGreen'           ]='006400', ['DarkKhaki'       ]='BDB76B', 
  ['DarkMagenta'    ]='8B008B', ['DarkOliveGreen'   ]='556B2F', ['DarkOrange'          ]='FF8C00', ['DarkOrchid'      ]='9932CC', 
  ['DarkRed'        ]='8B0000', ['DarkSalmon'       ]='E9967A', ['DarkSeaGreen'        ]='8FBC8F', ['DarkSlateBlue'   ]='483D8B', 
  ['DarkSlateGray'  ]='2F4F4F', ['DarkSlateGrey'    ]='2F4F4F', ['DarkTurquoise'       ]='00CED1', ['DarkViolet'      ]='9400D3', 
  ['DeepPink'       ]='FF1493', ['DeepSkyBlue'      ]='00BFFF', ['DimGray'             ]='696969', ['DimGrey'         ]='696969', 
  ['DodgerBlue'     ]='1E90FF', ['FireBrick'        ]='B22222', ['FloralWhite'         ]='FFFAF0', ['ForestGreen'     ]='228B22', 
  ['Fuchsia'        ]='FF00FF', ['Gainsboro'        ]='DCDCDC', ['GhostWhite'          ]='F8F8FF', ['Gold'            ]='FFD700', 
  ['GoldenRod'      ]='DAA520', ['Gray'             ]='808080', ['Grey'                ]='808080', ['Green'           ]='008000', 
  ['GreenYellow'    ]='ADFF2F', ['HoneyDew'         ]='F0FFF0', ['HotPink'             ]='FF69B4', ['IndianRed'       ]='CD5C5C', 
  ['Indigo'         ]='4B0082', ['Ivory'            ]='FFFFF0', ['Khaki'               ]='F0E68C', ['Lavender'        ]='E6E6FA', 
  ['LavenderBlush'  ]='FFF0F5', ['LawnGreen'        ]='7CFC00', ['LemonChiffon'        ]='FFFACD', ['LightBlue'       ]='ADD8E6', 
  ['LightCoral'     ]='F08080', ['LightCyan'        ]='E0FFFF', ['LightGoldenRodYellow']='FAFAD2', ['LightGray'       ]='D3D3D3', 
  ['LightGrey'      ]='D3D3D3', ['LightGreen'       ]='90EE90', ['LightPink'           ]='FFB6C1', ['LightSalmon'     ]='FFA07A', 
  ['LightSeaGreen'  ]='20B2AA', ['LightSkyBlue'     ]='87CEFA', ['LightSlateGray'      ]='778899', ['LightSlateGrey'  ]='778899', 
  ['LightSteelBlue' ]='B0C4DE', ['LightYellow'      ]='FFFFE0', ['Lime'                ]='00FF00', ['LimeGreen'       ]='32CD32', 
  ['Linen'          ]='FAF0E6', ['Magenta'          ]='FF00FF', ['Maroon'              ]='800000', ['MediumAquaMarine']='66CDAA', 
  ['MediumBlue'     ]='0000CD', ['MediumOrchid'     ]='BA55D3', ['MediumPurple'        ]='9370DB', ['MediumSeaGreen'  ]='3CB371', 
  ['MediumSlateBlue']='7B68EE', ['MediumSpringGreen']='00FA9A', ['MediumTurquoise'     ]='48D1CC', ['MediumVioletRed' ]='C71585', 
  ['MidnightBlue'   ]='191970', ['MintCream'        ]='F5FFFA', ['MistyRose'           ]='FFE4E1', ['Moccasin'        ]='FFE4B5', 
  ['NavajoWhite'    ]='FFDEAD', ['Navy'             ]='000080', ['OldLace'             ]='FDF5E6', ['Olive'           ]='808000', 
  ['OliveDrab'      ]='6B8E23', ['Orange'           ]='FFA500', ['OrangeRed'           ]='FF4500', ['Orchid'          ]='DA70D6', 
  ['PaleGoldenRod'  ]='EEE8AA', ['PaleGreen'        ]='98FB98', ['PaleTurquoise'       ]='AFEEEE', ['PaleVioletRed'   ]='DB7093', 
  ['PapayaWhip'     ]='FFEFD5', ['PeachPuff'        ]='FFDAB9', ['Peru'                ]='CD853F', ['Pink'            ]='FFC0CB', 
  ['Plum'           ]='DDA0DD', ['PowderBlue'       ]='B0E0E6', ['Purple'              ]='800080', ['RebeccaPurple'   ]='663399', 
  ['Red'            ]='FF0000', ['RosyBrown'        ]='BC8F8F', ['RoyalBlue'           ]='4169E1', ['SaddleBrown'     ]='8B4513', 
  ['Salmon'         ]='FA8072', ['SandyBrown'       ]='F4A460', ['SeaGreen'            ]='2E8B57', ['SeaShell'        ]='FFF5EE', 
  ['Sienna'         ]='A0522D', ['Silver'           ]='C0C0C0', ['SkyBlue'             ]='87CEEB', ['SlateBlue'       ]='6A5ACD', 
  ['SlateGray'      ]='708090', ['SlateGrey'        ]='708090', ['Snow'                ]='FFFAFA', ['SpringGreen'     ]='00FF7F', 
  ['SteelBlue'      ]='4682B4', ['Tan'              ]='D2B48C', ['Teal'                ]='008080', ['Thistle'         ]='D8BFD8', 
  ['Tomato'         ]='FF6347', ['Turquoise'        ]='40E0D0', ['Violet'              ]='EE82EE', ['Wheat'           ]='F5DEB3', 
  ['White'          ]='FFFFFF', ['WhiteSmoke'       ]='F5F5F5', ['Yellow'              ]='FFFF00', ['YellowGreen'     ]='9ACD32',
  
  -- Factorio Colors
  ['active-provider' ] = {r=107/255,g= 52/255,b=129/255,a= 90/255}, -- why alpha?
  ['passive-provider'] = {r=139/255,g= 50/255,b= 34/255,a= 90/255},
  ['storage'         ] = {r=192/255,g=146/255,b= 68/255,a= 90/255},
  ['buffer'          ] = {r= 98/255,g=185/255,b=111/255,a= 90/255},
  ['requester'       ] = {r= 48/255,g= 72/255,b=121/255,a= 90/255},
  ['infinity-chest'  ] = {r=147/255,g= 34/255,b= 95/255,a= 30/255},
  
  ['black'           ] = {r=  0/255,g=  0/255,b=  0/255,a=255/255},
  ['white'           ] = {r=255/255,g=255/255,b=255/255,a=255/255},
  }
  
-- 101 Shades of Gray
for i=0, 100 do
  color_table[('gray%s%%'):format(i)] = {r=i/100,g=i/100,b=i/100,a=1}
  end
  
-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

-- -------
-- Nothing.
-- @within Todo
-- @field todo1

-- -------------------------------------------------------------------------- --
-- Local Library                                                              --
-- -------------------------------------------------------------------------- --


--------------------------------------------------------------------------------
-- Concepts.
-- @section
--------------------------------------------------------------------------------

----------
-- A color specification.
-- 
-- RGB(A) @{table}:
-- `{r=1, g=1, b=1, a=1}` or `{1, 1, 1, 1}`
--
-- Hex-RGB(A) @{string}: 
-- `"#F5FFFA"`, `"#F5FFFA77"`
--
-- Html color name @{string}: 
--  `"MintCream"`, `"MistyRose"`, ...
-- 
-- Factorio logistic mode name @{string}: 
--  `"passive-provider"`, `"storage"`,...
-- 
-- Shade of gray (0-100) @{string}: 
--  `"gray42%"`
-- 
-- @table ColorSpecification


----------
-- A lua table representing an RGBA color.  
-- All values are @{UnitInterval}s.  
-- `{r=1, g=1, b=1, a=1}`
--
-- @table NormalizedColor



--------------------------------------------------------------------------------
-- Functions.  
-- @section
--------------------------------------------------------------------------------

local function copy_color(c) return {r = c.r, g = c.g, b = c.b, a = c.a} end

----------
-- Creates a color table.
--
-- @tparam ColorSpecification color_spec
--
-- @treturn NormalizedColor
--
-- @function Color
Color = Class.SwitchCaseClass(
  -- analyzer
  function(spec)
    if type(spec) == 'table' then
      return 'lua_table'
    elseif type(spec) == 'string'
    and spec:sub(1,1) == '#' then
      return 'hex_string'
    elseif type(spec) == 'string' then
      return 'color_name'
    else
      err('not implemented color spec type')
      end
    end,
  -- cases
  {
    --@future: does this have to immedeatly apply premultiply?
    -- probably not for lua_tables (user knows what they're doing)
    -- but for other specifications like hex?
    lua_table = function(c) return {
      r = c.r or c[1] or 1,
      g = c.g or c[2] or 1,
      b = c.b or c[3] or 1,
      a = c.a or c[4] or 1}
      end,
    
    --
    hex_string = function(c) return
      wube_util_color(c)
      end,
      
    --
    color_name = function(c) return
      copy_color(assertify(color_table[c], 'Invalid color name: ', c))
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
return function() return Color,nil,nil end
