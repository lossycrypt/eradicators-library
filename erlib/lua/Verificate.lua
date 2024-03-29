-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable

--------------------------------------------------
-- Performance optimized multi- and complex-type detection and comparison.
-- See @{Verificate.isType|isType} for details.
--
-- @{Introduction.DevelopmentStatus|Module Status}: Polishing.
--
-- @module Verificate
-- @usage
--  local Verificate = require('__eradicators-library__/erlib/lua/Verificate')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Eradicators Library                                                        --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --

local type, pairs, rawget
    = type, pairs, rawget
    
local table_concat
    = table.concat
    
    
local stop = elreq('erlib/lua/Error')().Stopper('Verificate')
local log  = elreq('erlib/lua/Log'  )().Logger ('Verificate')
    
-- local Iter_combinations = elreq('erlib/lua/Iter/combinations')()
local Iter_permutations = elreq('erlib/lua/Iter/permutations')()
local Iter_subsets      = elreq('erlib/lua/Iter/subsets')()
    
-- naive scopy
local function scopy(tbl) local r={} for k,v in pairs(tbl) do r[k]=v end return r end


-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Verificate,_Verificate,_uLocale = {},{},{}

-- -------
-- Nothing.
-- @within Todo
-- @field todo1



--------------------------------------------------------------------------------
-- Test Results.
-- @section
--------------------------------------------------------------------------------

--[[

  Extensive performance testing has been done for this module.
  See "type_comparison_fastest_possible.lua" for details.

  Conclusion:

    Single Type:
      * Simple <if type(obj) == 'typestring'> is 20% faster than table lookup.
      * The typestring must be a plain string and not an upvalue.

    Nil or Type or ...:
      * Doing an extra nil-check "if obj==nil or ok[ type(obj) ]" 
        is ~90% faster when obj is nil, and ~5-10% slower when it is not.
      * To give the user a choice all permutations starting with "nil|..."
        shall include the nil-check, while all other permutations do not.

    Type or Type or ...:
      * Table lookup is constant time regardless of how many types
        are being tested for. It thus beats native type(obj) comparison
        even if the result of such an operation is cached.
      * Including ALL false possibilities is faster. Probably because
        it prevents lua from trying to search for metamethods.

  ]]



--------------------------------------------------------------------------------
-- isType.
-- @section
--------------------------------------------------------------------------------

----------
-- This table contains all type checking functions offered by this module.  
--
-- For the @{type|8 primary lua types} it offers functions to check any
-- __combination of up to three types__ at once by concatenateing the names 
-- with a | pipe. For these combinations you can also use the short names:
-- nil, num, str, bool, tbl, func, udat instead of the full type name.
-- 
-- __Note:__ This module also automatically generates a "nil|" variant
-- for non-primary type methods. I.e. isType['nil|LuaPlayer'], etc..
-- 
-- __Note:__ To keep the documentation concise paramters for type functions are
-- not documented per function. __Every function takes exactly one argument - the
-- object to type-check - and returns a boolean__.
-- 
-- __Performance Tip:__ Combinations starting with nil, i.e.
-- "nil", "nil|string", "nil|number|string" are optimized for situations where
-- the object to be checked is expected to be nil most of the time (~90% faster
-- if obj is nil, but 10% slower if obj is not nil).
-- If you expect the object to be @{NotNil} most of the time then
-- you should put nil at the end of the combination, i.e. "str|nil", "num|str|nil".
-- 
-- __Experimental:__ You can now use the "|" pipe syntax for __any combination__
-- of types. A combined function will be transparently generated the
-- first time you use a combination. You should always use the exact same string
-- for each combination if you do not want multiple functions to be generated.
--
-- 
-- @usage
--   local isNumStr = Verificate.isType['number|string']
--
--   if isNumStr(42) then print('Yes!') end
--   > Yes!
--
--   if isNumStr('word') then print('Yes!') end
--   > Yes!
-- 
--   if not isNumStr(nil) then print('Not!') end
--   > Not!
--
--   if Verificate.isType['nil|str|tbl']( {'empty table'} ) then print('Yes!') end
--   > Yes!
--
--
-- @table isType
local isType = {}

Verificate.isType = isType


local _mt_isType = {

  -- Typo protection.
  -- __index=function(_,typ) err(('isType: unknown type "%s".'):format(typ)) end,
  
  -- Call is nice syntactic suger when the user wants to cache data locally
  -- but it is always slower and might lead to accidential slowdowns in
  -- situations where table lookup should be used instead. Thus it is better
  -- to not offer it in the first place.
  -- __call =function(self,key) return self[key]      end,
  
  -- Typo protection + Generate arbitrary type combinations.
  __index = function(self,types)
    log:say('  Generated new isType: "'.. types.. '".')
    -- split string by "|" pipe
    local r, n = {}, 0
    local _types = types:gsub('[^|]+', function(typ)
      local f = rawget(self,typ)
      if f then
        n = n + 1
        r[n] = f
        return '' -- remove found names
        end
      end)
    -- String must be fully consumed and contain at least TWO types.
    -- If it was just one type then __index should never have been called.
    if (n < 2) or (_types:gsub('|','') ~= '') then 
      err(('isType: unknown type "%s".'):format(types))
      end
    -- Memoize.
    isType[types] = function(obj)
      for i=1,n do if r[i](obj) then return true end end
      return false
      end
    return isType[types]
    end,
  
  }

setmetatable(isType,_mt_isType)
  

--------------------------------------------------------------------------------
-- isType → Primary Permutations.
-- @section
--------------------------------------------------------------------------------

  
-- Generates all functions and aliases for all permutations of length max_size
-- for all 8 primary lua types.
-- 
-- __Note:__ Names are generated with short AND long variants for now. But
-- long name support might be removed in the future.
-- 
-- @tparam NaturalNumber max_size The maximum subset size, i.e. 3 → "nil|num|str"
-- @tparam table __isType The table into which all functions are stored.
-- 
local function make_primary_istype_checkers(max_size,__isType)

  local primary_types_name_order = {
    -- nil MUST be the FIRST value! to guarantee correct subset order
    'nil','number','string','boolean',
    'table','function','userdata',
    -- 'thread'
    }
   
  local primary_types_short_name_mapping = {
    ['nil'     ] = 'nil'   ,
    ['number'  ] = 'num'   ,
    ['string'  ] = 'str'   ,
    ['boolean' ] = 'bool'  ,
    ['table'   ] = 'tbl'   ,
    ['function'] = 'func'  ,
    ['userdata'] = 'udat'  ,
    -- ['thread'  ] = 'thread',
    }

  -- Template for guaranteed type check tables.
  local primary_types_false_set = {
    ['nil'     ] = false,
    ['number'  ] = false,
    ['string'  ] = false,
    ['boolean' ] = false,
    ['table'   ] = false,
    ['function'] = false,
    ['userdata'] = false,
    -- ['thread'  ] = false,
    }
    
  -- Factorio does not have threads.
  -- Excluding it reduces number of aliases by ~40%.
  if not flag.IS_FACTORIO then
    table.insert(primary_types_name_order,'thread')
    primary_types_short_name_mapping ['thread'] = 'thread'
    primary_types_false_set          ['thread'] =  false
    end

    
  -- Generates a function that checks an objects type against ONE hardcoded string.
  --
  -- @tparam string func_string The function template.
  -- @tparam type_string The output of type() for the desired type.
  -- 
  -- @treturn function The checking function. Has local upvalue to lua type().
  --
  local function make_hardcoded_string_compare_function(func_string,type_string)
    -- Hardcoded string comparison is only possible with load.
    return load(('local type = ... ; return ')..func_string:format(type_string))(type)
    end


  for size = 1,max_size do

    -- "nil", "nil|num", "nil|num|str", ...
    for s in Iter_subsets(size,primary_types_name_order) do
      
      local f,f_nil,ok -- scope
      
      -- ok
      -- Shares the same table for f and f_nil to save memory.
      if size > 1 then
        -- It's faster to lookup "false" than to lookup "nil".
        ok = scopy(primary_types_false_set)
        for i=1,#s do ok[ s[i] ] = true end
        end
      
      -- f
      do
        -- T is fastest with string comparison.
        if size == 1 then
          f = make_hardcoded_string_compare_function(
            'function(obj) return type(obj) == "%s" end'
            ,s[1]
            )
            
        -- TxT and above without nil is fastest with guaranteed table lookup.
        elseif size >= 2 then
          f = function(obj) return ok[ type(obj) ] end
          end

        end
        
      -- f_nil
      -- Performance optimized for values that are expected to be nil most of the time.
      -- Used only for permutations that start with "nil|".
      -- Does not need to be created for type-subsets that will never use it.
      if s[1] == 'nil' then
      
        -- nil
        if size == 1 then
          f_nil = function(obj) return obj == nil end
          
        -- TxT starting with nil is check nil then string compare.
        elseif size == 2 then
          f_nil = make_hardcoded_string_compare_function(
            'function(obj) return obj == nil or type(obj) == "%s" end'
            , s[2]
            )

        -- TxTxT and above starting with nil is check nil then guaranteed table lookup.
        elseif size >= 3 then
          f_nil = function(obj) return obj == nil or ok[ type(obj) ] end
          end
        
        end

      -- All permutations of the same subset share the same
      -- functions to save memory.
      for arr in Iter_permutations(s) do
        -- Generates all name permutations (short+long) for a given array of type names.
        -- @tparam function f The default function.
        -- @tparam function f_nil The function used for permutations starting with nil.
        local _f = (arr[1] == 'nil') and f_nil or f
        if not _f then err('Missing function') end
        -- long name
        __isType[ table_concat(arr,'|') ] = _f
-- printl('long',(arr[1] == 'nil'),table_concat(arr,'|'))
        -- short name (possibly the same if there were no short names
        for i=1,#arr do arr[i] = primary_types_short_name_mapping[ arr[i] ] end
        __isType[ table_concat(arr,'|') ] = _f
-- printl('shrt',(arr[1] == 'nil'),table_concat(arr,'|'))
        end
      
      end
    end
  end

  
-- Split off generated primary-functions to make them easily distinguishable.
-- Used to exclude them from automatic "not|" variant generation later.
local isTypePrimaryCheckers = {}
make_primary_istype_checkers(3,isTypePrimaryCheckers)
for k,v in pairs(isTypePrimaryCheckers) do
  isType[k] = v
  end

  
  
--------------------------------------------------------------------------------
-- isType → Factorio.
-- @section
--------------------------------------------------------------------------------

do
  
  -- @2020-10-06: Factorio Version 1.0.0
  -- @future: Integrate into isType.__index auto-generation function
  -- via string pattern "Lua%u%a+"? (at least one upper case character)
  local FactorioTypes = {
    -- from index.html#Classes
    'LuaAISettings','LuaAccumulatorControlBehavior','LuaAchievementPrototype',
    'LuaAmmoCategoryPrototype','LuaArithmeticCombinatorControlBehavior',
    'LuaAutoplaceControlPrototype','LuaBootstrap','LuaBurner',
    'LuaBurnerPrototype','LuaChunkIterator','LuaCircuitNetwork',
    'LuaCombinatorControlBehavior','LuaCommandProcessor',
    'LuaConstantCombinatorControlBehavior','LuaContainerControlBehavior',
    'LuaControl','LuaControlBehavior','LuaCustomChartTag',
    'LuaCustomInputPrototype','LuaCustomTable','LuaDamagePrototype',
    'LuaDeciderCombinatorControlBehavior','LuaDecorativePrototype',
    'LuaElectricEnergySourcePrototype','LuaEntity','LuaEntityPrototype',
    'LuaEquipment','LuaEquipmentCategoryPrototype','LuaEquipmentGrid',
    'LuaEquipmentGridPrototype','LuaEquipmentPrototype','LuaFlowStatistics',
    'LuaFluidBox','LuaFluidBoxPrototype','LuaFluidEnergySourcePrototype',
    'LuaFluidPrototype','LuaForce','LuaFuelCategoryPrototype','LuaGameScript',
    'LuaGenericOnOffControlBehavior','LuaGroup','LuaGui','LuaGuiElement',
    'LuaHeatEnergySourcePrototype','LuaInserterControlBehavior','LuaInventory',
    'LuaItemPrototype','LuaItemStack','LuaLampControlBehavior',
    'LuaLazyLoadedValue','LuaLogisticCell','LuaLogisticContainerControlBehavior',
    'LuaLogisticNetwork','LuaLogisticPoint','LuaMiningDrillControlBehavior',
    'LuaModSettingPrototype','LuaModuleCategoryPrototype',
    'LuaNamedNoiseExpression','LuaNoiseLayerPrototype','LuaParticlePrototype',
    'LuaPermissionGroup','LuaPermissionGroups','LuaPlayer','LuaProfiler',
    'LuaProgrammableSpeakerControlBehavior','LuaRCON',
    'LuaRailChainSignalControlBehavior','LuaRailPath',
    'LuaRailSignalControlBehavior','LuaRandomGenerator','LuaRecipe',
    'LuaRecipeCategoryPrototype','LuaRecipePrototype','LuaRemote','LuaRendering',
    'LuaResourceCategoryPrototype','LuaRoboportControlBehavior','LuaSettings',
    'LuaShortcutPrototype','LuaStorageTankControlBehavior','LuaStyle',
    'LuaSurface','LuaTechnology','LuaTechnologyPrototype','LuaTile',
    'LuaTilePrototype','LuaTrain','LuaTrainStopControlBehavior',
    'LuaTransportBeltControlBehavior','LuaTransportLine',
    'LuaTrivialSmokePrototype','LuaUnitGroup','LuaVirtualSignalPrototype',
    'LuaVoidEnergySourcePrototype','LuaWallControlBehavior'
    }
    

  ----------
  -- Is this any kind of factorio lua object? A LuaPlayer, LuaEntity, etc...?
  -- @function isType.LuaObject
  function isType.LuaObject(obj)
    return type(obj) == 'table'
       and type(obj.__self) == 'userdata'
    end


  ----------
  -- This module procedurally generates a checker function for
  -- __every__ @{FAPI index Classes|factorio class}.
  -- 
  -- @usage
  --   if Verificate.isType.LuaGameScript(game) then print('Can do this!') end
  --   > Can do this!
  -- 
  --   if Verificate.isType.LuaPlayer(game.player) then print('Can also do this!') end
  --   > Can also do this!
  -- 
  --   print(Verificate.isType.LuaPlayer(game))
  --   > false
  -- 
  -- @function isType.LuaFactorioClassName
  local isLuaObject = isType['LuaObject']
  for _,t in pairs(FactorioTypes) do
    isType[t] = function(obj)
      return isLuaObject(obj) and obj.object_name == t
      end
    end

  end

--------------------------------------------------------------------------------
-- isType → Number.
-- @section
--------------------------------------------------------------------------------

--- n > 0 and n % 1 == 0.
--- @function isType.NaturalNumber
function isType.NaturalNumber(obj)
  if type(obj) == 'number' and obj > 0 and (obj % 1 == 0) then
    return true end
  return false
  end

--- n % 1 == 0.
--- @function isType.Integer
function isType.Integer (obj)
  if type(obj) == 'number' and (obj % 1 == 0) then
    return true end
  return false  
  end
  
  
--------------------------------------------------------------------------------
-- isType → Table.
-- @section
--------------------------------------------------------------------------------

--- @function isType.NonEmptyTable
function isType.NonEmptyTable (obj)
  if type(obj) ~= 'table' then return false end
  for _ in pairs(obj) do return true end
  return false
  end
  
--- @function isType.EmptyTable
function isType.EmptyTable (obj)
  if type(obj) ~= 'table' then return false end
  for _ in pairs(obj) do return false end
  return true
  end

--- A lua table, not a factorio LuaObject.
--- @function isType.PlainTable
function isType.PlainTable (obj)
  return type(obj) == 'table'
     and type(rawget(obj,'__self')) ~= 'userdata'
  -- rawget circumvents AutoLock
  end
  
-- Detection of array-part in a table
-- is better done with Table.array_size(obj)
function isType.MixedTable (obj)
  err('Is there any usecase for this?')
  end
  
  
  
--------------------------------------------------------------------------------
-- isType → Array.
-- @section
--------------------------------------------------------------------------------

--- DenseArray or SparseArray, not MixedTable.
--- @function isType.Array
function isType.Array (obj)
  if type(obj) ~= 'table' then return false end
  for k in pairs(obj) do
    if not isType.NaturalNumber(k) then return false end
    end
  return true
  end
  

-- There shouldn't be any case where a DenseArray is acceptable
-- but a SparseArray is not. Use isType.Array() instead.
function isType.SparseArray (obj)
  err('Is there any usecase for this?')
  end
  
  
--- @function isType.DenseArray
function isType.DenseArray (obj)
  if type(obj) ~= 'table' then return false end
  local largest = 0
  for k in pairs(obj) do
    if not isType.NaturalNumber(k) then return false end
    if k > largest then largest = k end
    end
  for i=1,largest do
    if obj[i] == nil then return false end
    end
  return true
  end

  
--- DenseArray or SparseArray, not MixedTable.
--- @function isType.NonEmptyArray
function isType.NonEmptyArray (obj)
  if type(obj) ~= 'table' then return false end
  for _ in pairs(obj) do
    return isType.Array(obj)
    end
  return false
  end


--- @function isType.EmptyArray
isType.EmptyArray = isType.EmptyTable

--------------------------------------------------------------------------------
-- isType → Boolean.
-- @section
--------------------------------------------------------------------------------
  
--- @function isType.true
isType['true'] = function (obj)
  return obj == true
  end
isType[true] = isType['true']
  
--- @function isType.false  
isType['false'] = function (obj)
  return obj == false
  end
isType[false] = isType['false']

--------------------------------------------------------------------------------
-- isType → String.
-- @section
--------------------------------------------------------------------------------

--- The empty string of length 0.
function isType.EmptyString (obj)
  return obj == ''
  end

--- A string, but not the empty one.
function isType.NonEmptyString (obj)
  return type(obj) == 'string'
     and obj ~= ''
  end
 
--- Space of any length. Doesn't seem to work for non-Ascii
--- space even though the lua manual says it should.
function isType.WhiteSpaceString (obj)
  return type(obj) == 'string'
     and #obj:gsub('[%s　]+','') == 0 -- gotta manually enlist other spaces...
  end
 

--------------------------------------------------------------------------------
-- isType → Collections.
-- @section
--------------------------------------------------------------------------------


--- @function isType.NonEmptyArrayOfNonEmptyString
function isType.NonEmptyArrayOfNonEmptyString (obj)
  if type(obj) ~= 'table' then return false end
  local empty = true
  for k,v in pairs(obj) do
    empty = false
    if not isType.NaturalNumber (k) then return false end
    if not isType.NonEmptyString(v) then return false end
    end
  return not empty
  end
  
--- @function isType.NonEmptyTableOfFunction
function isType.NonEmptyTableOfFunction (obj)
  if type(obj) ~= 'table' then return false end
  local empty = true
  for k,v in pairs(obj) do
    empty = false
    if type(v) ~= 'function' then return false end
    end
  return not empty
  end
  
--- @function isType.NonEmptyDenseArrayOfNaturalNumber
function isType.NonEmptyDenseArrayOfNaturalNumber (obj)
  if type(obj) ~= 'table' then return false end
  local largest = 0
  for k,v in pairs(obj) do
    if not isType.NaturalNumber(k) then return false end
    if not isType.NaturalNumber(v) then return false end
    if k > largest then largest = k end
    end
  for i=1,largest do
    if obj[i] == nil then return false end
    end
  return true
  end
  
--------------------------------------------------------------------------------
-- isType → Custom.
-- @section
--------------------------------------------------------------------------------

--- @function isType.NotNil
function isType.NotNil (obj)
  return obj ~= nil
  end

--- A size-4 array of numbers. Ignores extra content.
--- @function isType.Vector
function isType.Vector (obj)
  if type(obj) ~= 'table' then return false end
  if #obj ~= 4 then return false end
  return
    'number' == type(obj[1]) and
    'number' == type(obj[2]) and
    'number' == type(obj[3]) and
    'number' == type(obj[4])
  end
  
--- A factorio {[1]=,[2]=} or {x=,y=} table. Ignores extra content.
--- Also accepts mixed definitions like {[1]=,y=}.
--- @function isType.Position
function isType.Position (obj)
  if type(obj) ~= 'table' then return false end
  return
    (type(obj[1]) == 'number' or type(obj.x) == 'number') and
    (type(obj[2]) == 'number' or type(obj.y) == 'number')
  end
  
--- Float 0 ≤ n ≤ 1.
--- @function isType.Probability
function isType.Probability (obj)
  if type(obj) ~= 'number' then return false end
  end

--- Float 0 ≤ n ≤ 1. @{wiki Unit interval}
--- @function isType.UnitInterval
function isType.UnitInterval (obj)
  if type(obj) ~= 'number' then return false end
  return (obj >= 0) and (obj <= 1)
  end
  
--- @{Table.TablePath}
--- @function isType.TablePath
function isType.TablePath (obj)
  if type(obj) ~= 'table' then return false end
  if obj[1] == nil then return false end
  -- Path keys could be anything, so this is all that can be checked.
  return not empty
  end

-- -------------------------------------------------------------------------- --
-- isType → List of Things.
-- -------------------------------------------------------------------------- --

--- @{InputName}
--- @function isType.InputName
do
  -- \data\core\locale\en\core.cfg
  -- Version: 1.1.32                   ,  Find   : ^([\w-]+)=.*$
  -- Section: [controls]               ,  Replace: '$1'
  --
  -- Auto-update script is included in erlib/doc/Types
  --
  local valid_input_names =
  (function(r, arr) for i=1, #arr do r[arr[i]] = true end return r end)({}, {
  'move-up'                            , 'move-right'                         ,
  'move-down'                          , 'move-left'                          ,
  'shoot-enemy'                        , 'shoot-selected'                     ,
  'open-character-gui'                 , 'open-technology-gui'                ,
  'rotate'                             , 'reverse-rotate'                     ,
  'flip-blueprint-horizontal'          , 'flip-blueprint-vertical'            ,
  'pick-items'                         , 'confirm-gui'                        ,
  'cycle-blueprint-forwards'           , 'cycle-blueprint-backwards'          ,
  'cycle-clipboard-forwards'           , 'cycle-clipboard-backwards'          ,
  'zoom-in'                            , 'zoom-out'                           ,
  'alt-zoom-in'                        , 'alt-zoom-out'                       ,
  'toggle-menu'                        , 'production-statistics'              ,
  'kill-statistics'                    , 'toggle-map'                         ,
  'toggle-driving'                     , 'clear-cursor'                       ,
  'smart-pipette'                      , 'mine'                               ,
  'select-for-blueprint'               , 'select-for-cancel-deconstruct'      ,
  'reverse-select'                     , 'build'                              ,
  'copy-entity-settings'               , 'paste-entity-settings'              ,
  'copy'                               , 'cut'                                ,
  'paste'                              , 'undo'                               ,
  'remove-pole-cables'                 , 'build-ghost'                        ,
  'build-with-obstacle-avoidance'      , 'open-gui'                           ,
  'drop-cursor'                        , 'pick-item'                          ,
  'cursor-split'                       , 'stack-transfer'                     ,
  'stack-split'                        , 'inventory-transfer'                 ,
  'fast-entity-transfer'               , 'inventory-split'                    ,
  'fast-entity-split'                  , 'craft'                              ,
  'craft-5'                            , 'craft-all'                          ,
  'cancel-craft'                       , 'cancel-craft-5'                     ,
  'cancel-craft-all'                   , 'quick-bar-button-1'                 ,
  'quick-bar-button-2'                 , 'quick-bar-button-3'                 ,
  'quick-bar-button-4'                 , 'quick-bar-button-5'                 ,
  'quick-bar-button-6'                 , 'quick-bar-button-7'                 ,
  'quick-bar-button-8'                 , 'quick-bar-button-9'                 ,
  'quick-bar-button-10'                , 'quick-bar-button-1-secondary'       ,
  'quick-bar-button-2-secondary'       , 'quick-bar-button-3-secondary'       ,
  'quick-bar-button-4-secondary'       , 'quick-bar-button-5-secondary'       ,
  'quick-bar-button-6-secondary'       , 'quick-bar-button-7-secondary'       ,
  'quick-bar-button-8-secondary'       , 'quick-bar-button-9-secondary'       ,
  'quick-bar-button-10-secondary'      , 'action-bar-select-page-1'           ,
  'action-bar-select-page-2'           , 'action-bar-select-page-3'           ,
  'action-bar-select-page-4'           , 'action-bar-select-page-5'           ,
  'action-bar-select-page-6'           , 'action-bar-select-page-7'           ,
  'action-bar-select-page-8'           , 'action-bar-select-page-9'           ,
  'action-bar-select-page-10'          , 'rotate-active-quick-bars'           ,
  'next-active-quick-bar'              , 'previous-active-quick-bar'          ,
  'toggle-filter'                      , 'show-info'                          ,
  'next-weapon'                        , 'activate-tooltip'                   ,
  'confirm-message'                    , 'connect-train'                      ,
  'disconnect-train'                   , 'editor-clone-item'                  ,
  'editor-delete-item'                 , 'editor-next-variation'              ,
  'editor-previous-variation'          , 'editor-toggle-pause'                ,
  'editor-tick-once'                   , 'pause-game'                         ,
  'editor-speed-up'                    , 'editor-speed-down'                  ,
  'editor-reset-speed'                 , 'editor-set-clone-brush-source'      ,
  'editor-set-clone-brush-destination' , 'editor-switch-to-surface'           ,
  'editor-remove-scripting-object'     , 'open-item'                          ,
  'add-station'                        , 'add-temporary-station'              ,
  'toggle-console'                     , 'drag-map'                           ,
  'place-ping'                         , 'place-in-chat'                      ,
  'larger-terrain-building-area'       , 'smaller-terrain-building-area'      ,
  'not-set'                            , 'unknown'                            ,
  'focus-search'                       , 'previous-technology'                ,
  'previous-mod'                       , 'logistic-networks'                  ,
  'toggle-blueprint-library'           , 'open-trains-gui'                    ,
  'debug-toggle-atlas-gui'             , 'debug-toggle-debug-settings'        ,
  'debug-toggle-basic'                 , 'debug-reset-zoom'                   ,
  'debug-reset-zoom-2x'                , 'controller-gui-crafting-tab'        ,
  'controller-gui-logistics-tab'       , 'controller-gui-character-tab'       ,
  'toggle-gui-debug'                   , 'toggle-gui-style-view'              ,
  'toggle-gui-shadows'                 , 'toggle-gui-glows'                   ,
  'open-prototypes-gui'                , 'open-prototype-explorer-gui'        ,
  'increase-ui-scale'                  , 'decrease-ui-scale'                  ,
  'reset-ui-scale'                     , 'next-player-in-replay'              ,
  'order-to-follow'                    ,                                      
  })
  
function isType.InputName (obj)
  return not not valid_input_names[obj]
  end
  end
  
--------------------------------------------------------------------------------
-- isType → or nil.
-- @section
--------------------------------------------------------------------------------

-- Generates a "nil|" variant for all custom type functions.
-- I.e. not for any of the primary type combinations because
-- those alrelady have nil variants.

local function isTypeOrNil(name)
  if type(name) == 'string' then -- exclude boolean true/false
    local f = isType[name]
    local f_nil = function(obj)
      if obj == nil then return true end
      return f(obj)
      end
    isType['nil|'..name] = f_nil
    end
  end

for name in pairs(

  -- Pairs does not suport adding keys *during* iteration,
  -- So the valid keys must be pre-collected.
  (function(names)
    for name in pairs(isType) do
      if not isTypePrimaryCheckers[name] then
        names[name] = true
        end
      end
    return names
    end){}

  ) do
    isTypeOrNil(name)
    end
  
  
--------------------------------------------------------------------------------
-- Verify.
-- @section
--------------------------------------------------------------------------------

-- Error message template.
local function _verification_failed(obj,typ,...)
  stop(
    'Verification failed!','\n',
    'expected : ',typ     ,'\n',
    'received : ',obj     ,'\n',
    '\n',
    ...
    )
  end

----------
-- @{assert}() like checker with support for all isType checks.
-- Raises an error if the input object is not of the expected type.
-- 
-- @tparam AnyValue obj
-- @tparam string|boolean typ An isType identifier.
-- @tparam[opt] AnyValue ... Anything you want to show up in the error message.
--
-- @treturn AnyValue|error If the check succeeds this returns obj, if not 
-- a hard error is raised.
--
-- @raise VerificationError with a standard error message plus anything you
-- specified in addition.
--
-- @usage
--    local function my_adder(x)
--      Verificate.verify(x,'number|nil',"Your","Error","Message.")
--      x = x or 0
--      return x + 1
--      end
--
--    print(my_adder(5))  
--    > 6
--
--    print(my_adder('five'))
--    > Verification failed!
--    > expected: number|nil
--    > received: five.
--    > Your Error Message.
--
function Verificate.verify (obj,typ,...)
  if isType[typ](obj) then
    return obj
  else
    _verification_failed(obj,typ,...)
    end
  end

----------
-- Performes multiple type checks in order.
--
-- @tparam AnyValue obj
-- @tparam DenseArray types The types in the order they should be verified.
-- @tparam[opt] AnyValue ... Anything you want to show up in the error message.
--
-- @treturn AnyValue|error If __at least one check__ succeeds this returns obj,
-- if not a hard error is raised.
--
function Verificate.verify_or(obj,types,...)
  for _,typ in ipairs(types) do
    if isType[typ](obj) then return obj end
    end
  _verification_failed(obj,types,...)
  end
  
----------
-- Performes multiple type checks in order.
--
-- @tparam AnyValue obj
-- @tparam DenseArray types The types in the order they should be verified.
-- @tparam[opt] AnyValue ... Anything you want to show up in the error message.
--
-- @treturn AnyValue|error If __all checks__ succeed this returns obj,
-- if not a hard error is raised.
--
function Verificate.verify_and(obj,types,...)
  local ok = true
  for _,typ in ipairs(types) do
    -- Because false is an error there is no need to optimize
    -- this loop for early break "if ok == false".
    ok = ok and isType[typ](obj)
    end
  if ok == true then
    return obj
  else
    _verification_failed(obj,types,...)
    end
  end
  
----------
-- Shorthand for @{Verificate.verify}(obj,'true',...).
-- Allows fully serialized multi-part error messages
-- with the same syntax as @{LMAN assert}.
function Verificate.assert(obj,...)
  return Verificate.verify(obj,'true',...)
  end
  
----------
-- Provides function input-checking wrappers.
-- When a wrapped function is called then first the checker function is called
-- with all arguments. Only if the checker function returns
-- @{truthy} is the real function called.
-- 
-- __Note:__ The checker is expected to raise an error if the check failed.
-- If it does not then Verificate.Wrap will raise a generic error. It is not
-- possible to continue execution after a failed check.
-- 
-- @tparam table|function functions All functions that you want wrapped. If this
-- is a single function then checkers must also be a single function.
-- @tparam table|function checkers All checking functions, indexed by the same keys
-- as the to-be-wrapped functions.
-- 
-- @treturn table A table of wrapped functions. Functions for which checkers
-- did not contain a corresponding function will be returned unwrapped.
-- 
function Verificate.wrap (functions,checkers)
  
  -- function + checker function + error name
  local function wrap(f,f_check,name)
    return function(...)
      if f_check(...) then return f(...) end
      stop('Wrapped function failed without error message.','\n',name)
      end
    end
    
  local tf,tc = type(functions), type(checkers)
  
  -- single function wrapping
  if tf == 'function' and tc == 'function' then
    return wrap(tf,tc)
    end
  
  if tf ~= 'table' or tc ~= 'table' then
    stop('Functions and checkers must be both tables or both functions.')
    end

  local r = {}
  for name,f in pairs(functions) do
    local f_check = checkers[name]
    if not f_check then
      r[name] = f
    else
      r[name] = wrap(f,f_check,name)
      end
    end
  return r
  end
  



-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
-- setmetatable(isType,_mt_isType)
-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Verificate') end
return function() return Verificate,_Verificate,_uLocale end
