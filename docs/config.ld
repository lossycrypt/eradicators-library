-- --------------------------------------------------------------------------- --
-- config                                                                      --
-- --------------------------------------------------------------------------- --


-- file = '.'
title = 'Erlib Documentation'
description = "Eradicator's Library."
full_description = ([[
  My library contains the reusable functions I use in many of my mods.
  This version of the library is built for Factorio %s.

  The official repository is on [GitHub](https://github.com/lossycrypt/eradicators-library).
  Latest builds are on the [ModPortal](https://mods.factorio.com/mod/eradicators-library).
  
  The [Factorio Api Documentation %s](./api/index.html) and the 
  [Lua 5.2 Reference Manual](./lua-5.2/doc/contents.html) are included
  for convenient offline reading.
  ]]):format( (function(_) return _,_ end)('1.1.32')  ) -- Factorio Version * 2!
  
format = 'markdown'
  

local root = '..'

-- dir=".\\..\\docs"
dir  = root..'/docs'
style = root..'/docs/template'


-- stdlib/flib stylesheets
-- template = root..'/docs/template'
-- template_escape = '>'

file = {

  --includes
  root..'/erlib',
  
  
  --includes each sub-dir
  -- root..'/erlib/factorio',
  -- root..'/erlib/lua',
  -- root..'/erlib/doc',
  
  
  --excludes
  exclude = {
    root..'/erlib/lua/Coding/LibDeflate.lua', -- LDoc compatible but not exposed in release
    root..'/erlib/lua/Coding/Sha2.lua', -- not LDoc compatible
    root..'/erlib/test/_DocTest.lua' ,
    
    -- template copies
    root..'/erlib/test/_TemplateModule.lua',
    root..'/erlib/lua/_TemplateModule.lua',
    root..'/erlib/factorio/_TemplateModule.lua',
    
    root..'/erlib/test/_TemplateTest.lua',
    
    root..'/erlib/factorio/EventManager/_TemplateEvent.lua',
    },
  
  }
  

-- no_lua_ref = true
-- not_luadoc = true

-- Why does manual_url not work? doesn't seem to have any effect at all.
-- Local links are not implemented via custom_see_handler.
-- manual_url = './lua-5.2/doc/manual.html'


--Sort entries within sections alphabetically? (or @set sort=true per module)
-- sort=true
sort=false

--Include local functions in the documentation? (can't be set per module?)
all=true

--Merge identically named modules
--Prevents weird unchangeable section names that occur when using @submodule
merge=true


no_space_before_args = true --no space between function and ()

one=true --one column? i see no change
--readme = 'readme.md'

-- no_summary = true


-- -------------------------------------------------------------------------- --
-- shorthands                                                                 --
-- -------------------------------------------------------------------------- --
--[1] https://stevedonovan.github.io/ldoc/manual/doc.md.html#Adding_new_Tags

alias("arg","tparam") -- creates an @arg tag that means the same as @tparam



-- -------------------------------------------------------------------------- --
-- @see handler urls                                                          --
-- -------------------------------------------------------------------------- --
-- Learned by looking at STDLIB's config.
-- [1] https://stevedonovan.github.io/ldoc/
-- [2] https://github.com/Afforess/Factorio-Stdlib/blob/master/doc/config.ld    
-- Quirks: Keywords and string methods are the only usable functions in config.ld!
--         Public functions like next, pairs, print, etc are not available!

local url = {
  --NamedSection
  local_modules = '../modules/%s.html#%s', -- Eradicators Library
  local_api     = '../api/%s.html#%s'    , -- Factorio API Documentation @{FAPI Libraries table_size}
  local_api_obj = '../api/%s.html#%s.%s' , -- Factorio API LuaObject @{FOBJ LuaEntity.valid}
  local_lua_doc = '../lua-5.2/doc/%s.html#pdf-%s', -- Lua functions @{module.method}
  
  --NamedPage
  local_lua_man = '../lua-5.2/doc/manual.html#%s', -- Lua Manual "x.y.z" Numbers " @{Chapter Title}
  --FixedPage
  remote_lua    = 'https://www.lua.org/pil/%s.html%s',
  --CustomUrlHandler
  wikipedia     = 'https://en.wikipedia.org/wiki/%s', -- @{wiki <page_name>|Title}
  --KewordPage
  keyword = {
    local_lua_method = '../lua-5.2/doc/manual.html#pdf-%s', -- @{LMAN ...}
    }
  }
  
-- -------------------------------------------------------------------------- --
-- @see handler factories                                                     --
-- -------------------------------------------------------------------------- --

-- custom_see_handler(Pattern,Function)
-- LDoc evaluates the Pattern and calls
-- Function with the matched groups if any.
-- If the pattern didn't match then Function
-- is not called at all.


--@tparam string n the first match of the RegEx

-- local function FixedPage(url) 
  -- return function (page,section)
    -- return function(n) return n,url:format(page,section) end
    -- end
  -- end
  
  
-- A pattern that always points at the same url regardless of what it matched.
-- @usage FixedPage('^(pattern) (.*)','https://page.html#%s'
local function FixedPage(pattern,url,a,b,c,d)
  url = url:format(a,b,c,d)
  custom_see_handler(pattern,function(name) return name,url end)
  end

-- A pattern whichs match results become part of the url.
-- @usage NamedSection('https://%s.html#%s','SectionName')('^(pattern) (.*)')
local function NamedSection(url,page)
  local f = function(n) return n, url:format(page,n) end
  return function(pattern) custom_see_handler(pattern,f) end
  end


-- A pattern of the form @{KEYWORD custom values}.
--
-- @param main_pattern Detects the keyword. The capture will be used as
-- the input for name and url patterns.
--
-- @param url_template Will be formatted with the result of url_pattern.
-- @param name_template Will be formatted with the result of name_pattern.
--
-- @param url_pattern Extracts url data from the output of main_pattern.
-- @param name_pattern Extracts name data from the output of main_pattern
--
local function KeywordPage(
  main_pattern, url_template, url_pattern, name_template, name_pattern
  )
  name_template = name_template or '%s'
  name_pattern  = name_pattern  or '.*'
  local f = function(main_result)
    local name = name_template:format(main_result:match(name_pattern))
    return
      (name ~= '') and name or 'Name was empty string!'
      ,url_template:format(main_result:match(url_pattern))
    end
  custom_see_handler(main_pattern, f)
  end
  

  
-- -------------------------------------------------------------------------- --
-- custom @see handlers                                                       --
-- -------------------------------------------------------------------------- --

-- Wikipedia (English)
local function Wiki(page)
  --remove whitespace
  page = page:gsub(' ','_')
  --automatically remove the disambiguation brackets from the name
  --example: "Set_(mathematics)" -> "Set"
  local name = (page:match('^(.*)(_%(.*%))$')) or page
  return name:gsub('_',' '),url.wikipedia:format(page)
  end
custom_see_handler('^wiki (.+)', Wiki)

--[[ FOBJ + FAPI reimplemented with KeywordPage

-- Simple Factorio Api urls "Page.html#section"
local function FactApi(page,section)
  return (section ~= '') and section or page, url.local_api:format(page,section)
  end
custom_see_handler('^FAPI ([^ ]+) ?([^ ]*)',FactApi) -- @{FAPI PageFileName section_name}

-- -- Factorio Api "LuaObject.html#LuaObject.section"
-- local function FactObj(obj,section)
--   return obj..'.'..section,url.local_api_obj:format(obj,obj,section)
--   end
-- custom_see_handler('^FOBJ (.-)%.(.*)',FactObj) -- @{FOBJ LuaEntity.valid}

-- Factorio Api "LuaObject.html#LuaObject.section"
local function FactObj(obj,section)
  if section ~= '' then
    return obj..'.'..section,url.local_api_obj:format(obj,obj,section)
  else
    return obj,url.local_api:format(obj,'')
    end
  end
-- Pattern: Object name with or without method name
custom_see_handler('^FOBJ ([%w_]+)%.?([%w_]*)$',FactObj) -- @{FOBJ LuaEntity.valid}

--]]

--Erlib "Concepts.html#section"
local function ErlibConcepts(name)
  return name, url.local_modules:format('Concepts',name)
  end
custom_see_handler('^erlib (.*)',ErlibConcepts)


  
-- -------------------------------------------------------------------------- --
-- Keywords                                                                   --
-- -------------------------------------------------------------------------- --

-- Common format is @{KEYWORD word word tail } 
-- The tail allows including descriptions without altering the link.
-- Removes up to ONE SPACE between the last word and the tail.
-- Thus you can use TWO SPACES to force everything afterwards to be the tail.


-- Keyword: LMAN
-- Page   : manual.html#module.method
-- Name   : module.method
KeywordPage(
  '^LMAN (.*)$'
  ,'../lua-5.2/doc/manual.html#pdf-%s', '^([%w_]+%.?[%w_]*) ?'
  ,'%s%s', '^([%w_]+%.?[%w_]*) ?(.-)$' -- remove UP TO ONE space
  )


-- Keyword: FOBJ
-- Page   : LuaObject.html#LuaObject.method
-- Name   : LuaObject.method
KeywordPage(
  '^FOBJ (.*)$'
  -- enforcing a . colon into the url makes non-method links go to the top of the page
  ,'../api/%s.html#%s.%s','^(([%w_]+))[%. ]?([%w_]*) ?'
  ,'%s%s%s%s', '^([%w_]+)([%. ]?)([%w_]*) ?(.-)$'
  )


-- Keyword: FAPI
-- Page   : Page.html#Section
-- Name   : Section
-- Example: @{FAPI Libraries table_size}

-- KeywordPage(
--   '^FAPI (.*)$'
--   ,'../api/%s.html#%s','^([%w_]+)[%. ]?([%w_]*) ?'
--   ,'%s%s', '^[%w_]+[%. ]?([%w_]*) ?(.-)$'
--   ) 

-- 2021-05-19: Stümperfix "%-" für "Data-lifecycle"? Macht das was kaputt?
-- Ergebnis von mehreren Stunden Trial+Error: Keine Ahnung wie man das fixt.
KeywordPage(
  '^FAPI (.*)$'
  ,'../api/%s.html#%s','^([%w%-_]+)[%. ]?([%w_]*) ?'
  ,'%s%s', '^[%w_]+[%. ]?([%w_]*) ?(.-)$'
  ) 
  
  
  
-- -- Keyword: Lua.*Prototype
-- -- Page   : Lua.*Prototype.html
-- -- Name   : Lua.*Prototype
-- KeywordPage(
--   '^(Lua%a+Prototype)$',
--   '../api/%s.html', '.*'
--   )
  

-- Keyword: LuaCamelCase
-- Page   : LuaCamelCase.html
-- Name   : LuaCamelCase
-- (To work with @tparam this can't use spaces or custom keywords.)
KeywordPage(
  '^(Lua%u%a+)$',
  '../api/%s.html', '.*'
  )
  


  
  
-- -------------------------------------------------------------------------- --
-- Translators                                                                --
-- -------------------------------------------------------------------------- --

-- Translates "key" + arror + "value" with trailing text.
-- @{key -> value pair}
-- @{(key -> value) mappings}
local key_value_formats = {
  ['->'] = '→', ['<->'] = '↔', ['<-'] = '←',
  }
local nbsp = " " -- non breaking space in Lua 5.3+: print('"'..utf8.char(160)..'"')

-- @param full capture, arrow capture, tail capture
local function KeyValuePair(_,key_value_spec, tail)
  local arrow = key_value_formats[key_value_spec] or key_value_spec
  local url  = url.local_modules:format('Types','KeyValuePair')
  return '(key '..arrow..' value)'..tail, url -- non-breaking space!
  end
custom_see_handler('^(%(?key%s*([^%s]+)%s*value%)?)(.*)$',KeyValuePair)


-- -------------------------------------------------------------------------- --
-- Hardlinks                                                                  --
-- -------------------------------------------------------------------------- --
custom_see_handler('Factorio',function() return 'Factorio','https://factorio.com/' end)

-- -------------------------------------------------------------------------- --
-- bulk @see handlers                                                         --
-- required for return value linking                                          --
-- -------------------------------------------------------------------------- --

-- Types (Eradicator's Library)
local ErlibTypes = NamedSection(url.local_modules,'Types')

-- Table
-- ErlibTypes('^(table)$'         ) --
-- ErlibTypes('^(set)$'           ) -- 
-- ErlibTypes('^(array)$'         ) -- breaks module links
ErlibTypes('^(SparseArray)$'   )

-- (are these automatically generated because Types is parsed early?)
-- ErlibTypes('^(PseudoSet)$'         )
-- ErlibTypes('^(DenseArray)$'        )
-- ErlibTypes('^(EmptyArray)$'        )
-- ErlibTypes('^(MixedTable)$'        )
-- ErlibTypes('^(KeyValuePair)$'   )

-- Number
ErlibTypes('^(Number)$'        )
ErlibTypes('^(Float)$'         )
ErlibTypes('^(Integer)$'       )
ErlibTypes('^(NaturalNumber)$' )

-- String
ErlibTypes('^(Pattern)$'       ) -- replace with direct lua doc link later?

-- Boolean
ErlibTypes('^(true)$'          )
ErlibTypes('^(false)$'         )

-- Misc
ErlibTypes('^(NotNil)$'        )
ErlibTypes('^(AnyValue)$'      )
ErlibTypes('^(TruthyValue)$'   )


local ErlibModuleSpecificTypes = function(mod, pattern)
  NamedSection(url.local_modules, mod)(pattern)
  end
  
ErlibModuleSpecificTypes('EventManager', 'EventUID')
ErlibModuleSpecificTypes('Color', 'ColorSpecification')
ErlibModuleSpecificTypes('Color', 'NormalizedColor')
ErlibModuleSpecificTypes('Table', 'TablePath')
ErlibModuleSpecificTypes('Table', 'TablePatch')
ErlibModuleSpecificTypes('Table', 'TablePatchValue')



local ErlibError = NamedSection(url.local_modules,'Error')
ErlibError('^(ErrorRaiser)$')

-- Builtin-Types (Factorio)
local FactorioBuiltinTypes = NamedSection(url.local_api,'Builtin-Types')
FactorioBuiltinTypes('^(boolean)$')
FactorioBuiltinTypes('^(int)$'    )
FactorioBuiltinTypes('^(uint)$'   )
FactorioBuiltinTypes('^(uint8)$'  )
FactorioBuiltinTypes('^(uint64)$' )
FactorioBuiltinTypes('^(string)$' )
FactorioBuiltinTypes('^(float)$'  )
FactorioBuiltinTypes('^(double)$' )



local factorio_types = {
  "ProgrammableSpeakerCircuitParameters","VehicleAutomaticTargetingParameters",
  "ProgrammableSpeakerAlertParameters","ArithmeticCombinatorParameters","Offer",
  "ProgrammableSpeakerParameters","ProgrammableSpeakerInstrument","TriggerItem",
  "CircuitConditionSpecification","EntityPrototypeSpecification","TilePosition",
  "ConstantCombinatorParameters","ModConfigurationChangedData","TileProperties",
  "DeciderCombinatorParameters","AchievementPrototypeFilters","TriggerDelivery",
  "TechnologyPrototypeFilters","PersonalLogisticParameters","TriggerTargetMask",
  "ModSettingPrototypeFilters","ItemPrototypeSpecification","TriggerEffectItem",
  "DecorativePrototypeFilters","EquipmentPrototypeFilters","SelectionModeFlags",
  "ConfigurationChangedData","TechnologySpecification","RecipePrototypeFilters",
  "InfinityInventoryFilter","ItemStackSpecification","EntityPrototypeFilters",
  "CollisionMaskWithFlags","CliffPlacementSettings","AutoplaceSpecification",
  "MapExchangeStringData","GuiArrowSpecification","FluidPrototypeFilters","Any",
  "TilePrototypeFilters","SurfaceSpecification","RaiseEventParameters","Vector",
  "ItemPrototypeFilters","EntityPrototypeFlags","ChunkPositionAndArea","Signal",
  "TrainScheduleRecord","PlayerSpecification","CursorBoxRenderType","SoundPath",
  "ScriptRenderTarget","OldTileAndPosition","ItemPrototypeFlags","NthTickEvent",
  "InfinityPipeFilter","ForceSpecification","FluidSpecification","SmokeSource",
  "FluidBoxConnection","DifficultySettings","CollisionMaskLayer","RidingState",
  "PlaceAsTileResult","ItemStackLocation","DisplayResolution","SimpleItemStack",
  "AutoplaceSettings","MouseButtonFlags","GameViewSettings","ComparatorString",
  "CliffOrientation","CircuitCondition","AttackParameters","NoiseExpression",
  "MapViewSettings","LocalisedString","ScriptPosition","MapGenSettings","Fluid",
  "LogisticFilter","ForceCondition","WaitCondition","UpgradeFilter","Alignment",
  "TrainSchedule","PathfindFlags","PathFindFlags","ColorModifier","Resistances",
  "CollisionMask","ChunkPosition","CapsuleAction","RenderLayer","MapSettings",
  "HeatSetting","GuiLocation","EffectValue","BoundingBox","SpritePath","Filter",
  "ScriptArea","ModSetting","MapGenSize","Ingredient","BeamTarget","SignalID",
  "Position","Modifier","AmmoType","Trigger","Product","Effects","Command",
  "Color","Tags","Loot",
  }
local FactorioTypes = NamedSection(url.local_api, 'Concepts')
for i=1, #factorio_types do
  FactorioTypes('^('..factorio_types[i]..')$')
  end



-- @future: Deprecate and replace by @{LMAN ...}
--
-- Lua Manual (cos LDoc manual_url option ain't werki'n! wtf!)
local keywords = {
  "package.searchpath","debug.setuservalue","debug.setmetatable","table.unpack",
  "debug.getuservalue","debug.getmetatable","package.searchers","string.gmatch",
  "debug.upvaluejoin","debug.getregistry","debug.setupvalue","debug.getupvalue",
  "package.preload","package.loadlib","math.randomseed","debug.upvalueid",
  "debug.traceback","string.reverse","package.loaded","package.config","xpcall",
  "debug.setlocal","debug.getlocal","collectgarbage","string.format","tostring",
  "package.cpath","debug.sethook","debug.getinfo","debug.gethook","string.gsub",
  "bit32.rrotate","bit32.replace","bit32.lrotate","bit32.extract","string.find",
  "bit32.arshift","table.remove","table.insert","table.concat","string.upper",
  "string.match","string.lower","setmetatable","package.path","getmetatable",
  "bit32.rshift","bit32.lshift","string.dump","string.char","string.byte",
  "math.random","debug.debug","bit32.btest","table.sort","table.pack","require",
  "string.sub","string.rep","string.len","math.ldexp","math.frexp","math.floor",
  "math.atan2","bit32.bxor","bit32.bnot","bit32.band","math.tanh","math.sqrt",
  "math.sinh","math.modf","math.huge","math.fmod","math.cosh","math.ceil",
  "math.atan","math.asin","math.acos","bit32.bor","tonumber","rawequal","table",
  "math.tan","math.sin","math.rad","math.pow","math.min","math.max","math.log",
  "math.exp","math.deg","math.cos","math.abs","loadfile","package","math.pi",
  "string","select","rawset","rawlen","rawget","ipairs","dofile","assert",
  "print","pcall","pairs","error","debug","bit32","type","next","math","load",
  }
local LuaManual = NamedSection(url.local_lua_doc,'manual')
for i=1,#keywords do LuaManual('^('..keywords[i]..')$') end





local LuaManualSections = {
  -- Takes a list of strings copied from the table of content of the manual:
  -- 
  -- '3.3.6 – Function Calls as Statements',
  --
  --  for k,v in ipairs(data) do
  --    local n,s = v:match('^%s*([^?]*) ? ([^?]-)%s*$')
  --    print(('{"%-6s", "%s"%'..(43-#s)..'s},'):format(n,s,''))
  --    end
  --
  {"1     ", "Introduction"                               },
  {"2     ", "Basic Concepts"                             },
  {"2.1   ", "Values and Types"                           },
  {"2.2   ", "Environments and the Global Environment"    },
  {"2.3   ", "Error Handling"                             },
  {"2.4   ", "Metatables and Metamethods"                 },
  {"2.5   ", "Garbage Collection"                         },
  {"2.5.1 ", "Garbage-Collection Metamethods"             },
  {"2.5.2 ", "Weak Tables"                                },
  {"2.6   ", "Coroutines"                                 },
  {"3     ", "The Language"                               },
  {"3.1   ", "Lexical Conventions"                        },
  {"3.2   ", "Variables"                                  },
  {"3.3   ", "Statements"                                 },
  {"3.3.1 ", "Blocks"                                     },
  {"3.3.2 ", "Chunks"                                     },
  {"3.3.3 ", "Assignment"                                 },
  {"3.3.4 ", "Control Structures"                         },
  {"3.3.5 ", "For Statement"                              },
  {"3.3.6 ", "Function Calls as Statements"               },
  {"3.3.7 ", "Local Declarations"                         },
  {"3.4   ", "Expressions"                                },
  {"3.4.1 ", "Arithmetic Operators"                       },
  {"3.4.2 ", "Coercion"                                   },
  {"3.4.3 ", "Relational Operators"                       },
  {"3.4.4 ", "Logical Operators"                          },
  {"3.4.5 ", "Concatenation"                              },
  {"3.4.6 ", "The Length Operator"                        },
  {"3.4.7 ", "Precedence"                                 },
  {"3.4.8 ", "Table Constructors"                         },
  {"3.4.9 ", "Function Calls"                             },
  {"3.4.10", "Function Definitions"                       },
  {"3.5   ", "Visibility Rules"                           },
  {"4     ", "The Application Program Interface"          },
  {"4.1   ", "The Stack"                                  },
  {"4.2   ", "Stack Size"                                 },
  {"4.3   ", "Valid and Acceptable Indices"               },
  {"4.4   ", "C Closures"                                 },
  {"4.5   ", "Registry"                                   },
  {"4.6   ", "Error Handling in C"                        },
  {"4.7   ", "Handling Yields in C"                       },
  {"4.8   ", "Functions and Types"                        },
  {"4.9   ", "The Debug Interface"                        },
  {"5     ", "The Auxiliary Library"                      },
  {"5.1   ", "Functions and Types"                        },
  {"6     ", "Standard Libraries"                         },
  {"6.1   ", "Basic Functions"                            },
  {"6.2   ", "Coroutine Manipulation"                     },
  {"6.3   ", "Modules"                                    },
  {"6.4   ", "String Manipulation"                        },
  {"6.4.1 ", "Patterns"                                   },
  {"6.5   ", "Table Manipulation"                         },
  {"6.6   ", "Mathematical Functions"                     },
  {"6.7   ", "Bitwise Operations"                         },
  {"6.8   ", "Input and Output Facilities"                },
  {"6.9   ", "Operating System Facilities"                },
  {"6.10  ", "The Debug Library"                          },
  {"7     ", "Lua Standalone"                             },
  {"8     ", "Incompatibilities with the Previous Version"},
  {"8.1   ", "Changes in the Language"                    },
  {"8.2   ", "Changes in the Libraries"                   },
  {"8.3   ", "Changes in the API"                         },
  {"9     ", "The Complete Syntax of Lua"                 },
  }

-- Lua Manul Text Sections
for i=1,#LuaManualSections do
  local this = LuaManualSections[i]
  FixedPage('^('..this[2]..')$',url.local_lua_man,this[1])  
  end


-- Generic Lua Types (Thank's for the links Stdlib!)
FixedPage("^(nil)$"     , url.remote_lua, "2.1" , ""             )
FixedPage("^(number)$"  , url.remote_lua, "2.3" , ""             )
-- FixedPage("^(table)$"   , url.remote_lua, "2.5" , ""             )
FixedPage("^(function)$", url.remote_lua, "2.6" , ""             )
FixedPage("^(userdata)$", url.remote_lua, "2.7" , ""             )
FixedPage("^(thread)$"  , url.remote_lua, "9"   , "#CoroutineSec")
-- FixedPage("^(array)$"   , url.remote_lua, "11.1", ""             )
FixedPage("^(sort)$"    , url.remote_lua, "19.3", ""             )
-- FixedPage("^(pattern)$" , url.remote_lua, "20.2", ""             )


--[[
  -- Already solved better above
  -- @{FOBJ LuaPlayer}

local FactorioObjects = {
  'LuaAISettings'                          ,
  'LuaAccumulatorControlBehavior'          ,
  'LuaAchievementPrototype'                ,
  'LuaAmmoCategoryPrototype'               ,
  'LuaArithmeticCombinatorControlBehavior' ,
  'LuaAutoplaceControlPrototype'           ,
  'LuaBootstrap'                           ,
  'LuaBurner'                              ,
  'LuaBurnerPrototype'                     ,
  'LuaChunkIterator'                       ,
  'LuaCircuitNetwork'                      ,
  'LuaCombinatorControlBehavior'           ,
  'LuaCommandProcessor'                    ,
  'LuaConstantCombinatorControlBehavior'   ,
  'LuaContainerControlBehavior'            ,
  'LuaControl'                             ,
  'LuaControlBehavior'                     ,
  'LuaCustomChartTag'                      ,
  'LuaCustomInputPrototype'                ,
  'LuaCustomTable'                         ,
  'LuaDamagePrototype'                     ,
  'LuaDeciderCombinatorControlBehavior'    ,
  'LuaDecorativePrototype'                 ,
  'LuaElectricEnergySourcePrototype'       ,
  'LuaEntity'                              ,
  'LuaEntityPrototype'                     ,
  'LuaEquipment'                           ,
  'LuaEquipmentCategoryPrototype'          ,
  'LuaEquipmentGrid'                       ,
  'LuaEquipmentGridPrototype'              ,
  'LuaEquipmentPrototype'                  ,
  'LuaFlowStatistics'                      ,
  'LuaFluidBox'                            ,
  'LuaFluidBoxPrototype'                   ,
  'LuaFluidEnergySourcePrototype'          ,
  'LuaFluidPrototype'                      ,
  'LuaForce'                               ,
  'LuaFuelCategoryPrototype'               ,
  'LuaGameScript'                          ,
  'LuaGenericOnOffControlBehavior'         ,
  'LuaGroup'                               ,
  'LuaGui'                                 ,
  'LuaGuiElement'                          ,
  'LuaHeatEnergySourcePrototype'           ,
  'LuaInserterControlBehavior'             ,
  'LuaInventory'                           ,
  'LuaItemPrototype'                       ,
  'LuaItemStack'                           ,
  'LuaLampControlBehavior'                 ,
  'LuaLazyLoadedValue'                     ,
  'LuaLogisticCell'                        ,
  'LuaLogisticContainerControlBehavior'    ,
  'LuaLogisticNetwork'                     ,
  'LuaLogisticPoint'                       ,
  'LuaMiningDrillControlBehavior'          ,
  'LuaModSettingPrototype'                 ,
  'LuaModuleCategoryPrototype'             ,
  'LuaNamedNoiseExpression'                ,
  'LuaNoiseLayerPrototype'                 ,
  'LuaParticlePrototype'                   ,
  'LuaPermissionGroup'                     ,
  'LuaPermissionGroups'                    ,
  'LuaPlayer'                              ,
  'LuaProfiler'                            ,
  'LuaProgrammableSpeakerControlBehavior'  ,
  'LuaRCON'                                ,
  'LuaRailChainSignalControlBehavior'      ,
  'LuaRailPath'                            ,
  'LuaRailSignalControlBehavior'           ,
  'LuaRandomGenerator'                     ,
  'LuaRecipe'                              ,
  'LuaRecipeCategoryPrototype'             ,
  'LuaRecipePrototype'                     ,
  'LuaRemote'                              ,
  'LuaRendering'                           ,
  'LuaResourceCategoryPrototype'           ,
  'LuaRoboportControlBehavior'             ,
  'LuaSettings'                            ,
  'LuaShortcutPrototype'                   ,
  'LuaStorageTankControlBehavior'          ,
  'LuaStyle'                               ,
  'LuaSurface'                             ,
  'LuaTechnology'                          ,
  'LuaTechnologyPrototype'                 ,
  'LuaTile'                                ,
  'LuaTilePrototype'                       ,
  'LuaTrain'                               ,
  'LuaTrainStopControlBehavior'            ,
  'LuaTransportBeltControlBehavior'        ,
  'LuaTransportLine'                       ,
  'LuaTrivialSmokePrototype'               ,
  'LuaUnitGroup'                           ,
  'LuaVirtualSignalPrototype'              ,
  'LuaVoidEnergySourcePrototype'           ,
  'LuaWallControlBehavior'                 ,
  }
  
-- Lua Manul Text Sections
for i=1,#FactorioObjects do
  local this = FactorioObjects[i]
  FixedPage('^('..this..')$',url.local_api,this,'')
  end
  
  --]]