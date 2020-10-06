-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Performance optimized multi- and complex-type detection and comparison.
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
-- Locals / Init                                                              --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --

local type, pairs
    = type, pairs
    
local table_concat
    = table.concat
    
    
local stop = elreq('erlib/lua/Error')().Stopper('Verificate')
    
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
-- __Every isType function takes exactly one argument.__
--
-- For the @{type|8 primary lua types} it offers functions to check any
-- __combination of up to three types__ at once by concatenateing the names 
-- with a | pipe. For these combinations you can also use the short names:
-- nil, num, str, bool, tbl, func, udat instead of the full type name.
-- 
-- __Note:__ To keep the documentation concise paramters for type functions are
-- not documented per function.
-- 
-- __Performance Note:__ Combinations starting with nil, i.e.
-- "nil", "nil|string", "nil|number|string" are optimized for situations where
-- the object to be checked is expected to be nil most
-- of the time. If you expect the object to be @{NotNil} most of the time then
-- you should put nil at the end of the combination, i.e. "str|nil", "num|str|nil".
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
  __index=function(_,typ) err(('isType: unknown type "%s".'):format(typ)) end,
  
  -- Call is nice syntactic suger when the user wants to cache data locally
  -- but it is always slower and might lead to accidential slowdowns in
  -- situations where table lookup should be used instead. Thus it is better
  -- to not offer it in the first place.
  -- __call =function(self,key) return self[key]      end,
  
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
  function isType.LuaObject(obj)
    return type(obj) == 'table'
       and type(obj.__self) == 'userdata'
    end


  ----------
  -- Procedurally generated checkers for all factorio classes.
  -- 
  -- This module generates a checker function for
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
  -- @table isType.LuaAnyObjectName
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

--- @function isType.false  
isType['false'] = function (obj)
  return obj == false
  end
    

--------------------------------------------------------------------------------
-- isType → String.
-- @section
--------------------------------------------------------------------------------


--- @function isType.NonEmptyString
function isType.NonEmptyString (obj)
  return type(obj) == 'string'
     and obj ~= ''
  end

--- @function isType.EmptyString
function isType.EmptyString (obj)
  return obj == ''
  end
 

--------------------------------------------------------------------------------
-- isType → Collections.
-- @section
--------------------------------------------------------------------------------


--- @function isType.NonEmptyArrayOfStrings
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
--- @function isType.Position
function isType.Position (obj)
  if type(obj) ~= 'table' then return false end
  return
    (type(obj[1]) == 'number' or type(obj.x) == 'number') and
    (type(obj[2]) == 'number' or type(obj.y) == 'number')
  end
  
--- Float 0 <= n <= 1.
--- @function isType.Probability
function isType.Probability (obj)
  if type(obj) ~= 'number' then return false end
  end


--- @function isType.TablePath
function isType.TablePath (obj)
  if type(obj) ~= 'table' then return false end
  if obj[1] == nil then return false end
  -- Path keys could be anything, so this is all that can be checked.
  return not empty
  end



--------------------------------------------------------------------------------
-- isType → or nil.
-- @section
--------------------------------------------------------------------------------

local function isTypeOrNil(name)
  local f = isType[name]
  local f_nil = function(obj)
    if obj == nil then return true end
    return f(obj)
    end
  isType['nil|'..name] = f_nil
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

-- Desired internal syntax


----------
-- assert() like checker with custom complex-type support.
-- Raises an error if the input object is not of the expected type.
-- 
-- @tparam AnyValue obj
-- @tparam string typ An isType compatible string.
-- @tparam[opt] AnyValue ... Anything you want to show up in the error message.
--
-- @treturn true|error If the check succeeds this returns true, if not 
-- a hard error is raised. Therefore it never returns false.
--
-- @raise VerificationError with a standard error message plus anything you
-- specified in addition.
--
-- @usage
--    local function my_adder(x)
--      Verificate.Verify(x,'number|nil',"Your","Error","Message.")
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
function Verificate.Verify (obj,typ,...)
  -- @todo: readd meta typoprotection after all funcs generated
  return isType[typ](obj) or stop(
    'Verification failed!',
    'expected : '.. typ,
    'received : '.. obj,
    '',
    ...
    )
  end


----------
-- Provides function input-checking wrappers.
-- When a wrapped function is called then first the checker function is called
-- with all arguments. Only if the checker function returns
-- @{Concepts.truthy|truthy} is the real function called.
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
function Verificate.Wrap (functions,checkers)
  
  -- function + checker function + error name
  local function wrap(f,f_check,name)
    return function(...)
      if f_check(...) then return f(...) end
      stop('Wrapped function failed without error message.',name)
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
