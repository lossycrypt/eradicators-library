-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable

--------------------------------------------------
-- A general overview over the (custom) data types used throughout this documentation.
--
-- @module Types
-- @set all=true
-- @set sort=false


--------------------------------------------------------------------------------
-- Table.
-- @section
--------------------------------------------------------------------------------


----------
-- Every Lua table maps @{NotNil} keys to NotNil values.
-- Every specialized table can also be used as a standard Table.
--
-- @field key @{NotNil}
-- @table table
--
-- @usage
--   local table = {key = value}

  
----------
-- A @{wiki Set_(mathematics)} is a table in which all values are @{true} and
-- the keys are the actual values. This is useful to quickly test if a given key
-- is in a Set or not.
--
-- @field key @{true}
-- @table set
--
-- @usage
--   local set = {}
--   for _,value in pairs(Table) do
--     set[value] = true
--     end
-- @usage if set[key] then f() end
-- @usage for value,_ in pairs(set) do print(value) end


----------
-- Different from a strict @{set} a PseudoSet considers all keys with
-- @{NotNil} values as elements of itself. Thus every Lua @{table} can be
-- treated as a PseudoSet.
-- @field key @{NotNil}
-- @table PseudoSet


----------
-- See @{array} below.
-- @table DenseArray


----------
-- An array - sometimes also called a DenseArray - is a table
-- in which all keys are non-zero @{NaturalNumber}s. Additionally
-- the sequence of numbers must be uninterrupted - for every
-- key n in the array there must also be a key n-1, except for n=1 which
-- must be the first key (or the array is empty).
--
-- Arrays are the ONLY type of Table for which the Lua length operator #
-- reports the correct number of elements. For all other types of Table
-- @{FAPI Libraries table_size}() must be used.
--
-- @field 1 @{NotNil}
-- @field 2 @{NotNil}
-- @field 3 @{NotNil}
-- @table array
--
-- @usage
--   for i=1,#array do print(array[i]) end
--
-- @usage
--   local A = {'a','b','c','d','e'}
--   print(#A)
--   > 5


----------
-- A SparseArray is also a @{Table} in which all keys are @{NaturalNumber}s.
-- Contrary to an @{Array} the sequence of keys may be discontinuous.
--
-- Tautologically any function that expects a SparseArray can also take a 
-- DenseArray.
--
-- These are often used to store entities indexed by their unit_number.
--
-- @field 1  @{NotNil}
-- @field 5  @{NotNil}
-- @field 42 @{NotNil}
-- @table SparseArray
--
-- @usage
--  local entities = {[entity.unit_number] = entity}

----------
-- An array that contains no key→value mappings. Remember that Lua tables have
-- identity and thus empty tables are not primitively equal.
-- @usage local empty = {}
-- @usage
--   if {} ~= {} then print("Similar but not the same!") end
--   > Similar but not the same!
-- @table EmptyArray

----------
-- A table that contains both numeric and string keys.
-- 
-- @field 1 @{NotNil}
-- @field one @{NotNil}
-- @table MixedTable
--
-- @usage
--  local my_table = {'val1','val2','val3',description='MyMixedTable'}

  
----------
-- The concept of a key in a table referencing one specific value.
-- 
-- When any lua table contains a value that value can be accessed only by it's key.
-- 
-- Any lua table is thus said to be a mapping of multiple keys to one value each.
-- Each key is said to map a value. Each key and it's value form a KeyValuePair.
-- 
-- In lua both keys and values must be @{NotNil} to be considered "in" the table
-- for example for iteration with @{pairs}. All keys that are not "in" the
-- table map to @{nil}. Only keys "in" the table contribute to the size of a table.
-- 
-- @usage local my_table = {[key] = value} -- a table with one KeyValuePair
-- 
-- @table KeyValuePair
  
--------------------------------------------------------------------------------
-- Number.
-- @section
--------------------------------------------------------------------------------


----------
-- The basic Lua type for numbers. It can be any @{Integer} or @{float}.
--
-- @name Number
-- @class field


----------
-- A @{number} that has a non-zero decimal fraction.
--
-- @name float
-- @class field
--
-- @usage local float = 3.14159


----------
-- A @{number} that does not have a decimal fraction.
--
-- @name Integer
-- @class field
--
-- @usage local Integer = 42
  
  
----------
-- An @{Integer} > 0. Also called a PositiveInteger.
--
-- @name NaturalNumber
-- @class field


----------
-- An @{Integer} < 0.
--
-- @name NegativeInteger
-- @class field


----------
-- A @{float} 0 ≤ x ≤ 1. Often used for probability values.
-- See also @{wiki Unit interval}.
--
-- @name UnitInterval
-- @class field 



--------------------------------------------------------------------------------
-- String.
-- @section
--------------------------------------------------------------------------------

----------
-- A @{string} containing a Lua @{Patterns|Pattern}. __Not__ to be confused
-- with Regular Expessions.
--
-- @name Pattern
-- @class field

----------
-- A @{string} of length 0 that has no content.
--
-- @name EmptyString
-- @class field


--------------------------------------------------------------------------------
-- Boolean.
-- @section
--------------------------------------------------------------------------------

----------
-- The @{boolean} value true.
--
-- @name true
-- @class field

----------
-- The @{boolean} value false.
--
-- @name false
-- @class field


----------
-- In contexts where an @{AnyValue} is treated as a @{boolean} it is said
-- to be truthy if it evaluates to true, and falsy if it evaluates to false.
-- This means that doubly-negating the value will convert it to @{true}.
-- In Lua this applies to any string, @{number}, @{true}, @{table}, function or
-- userdata. But not @{false} or nil.
-- 
-- @name truthy
-- @class field
--
-- @usage if (0 and '' and {}) then print('truthy!') end
--   > truthy!
--
-- @usage if not nil then print('negation of falsy is true!') end
--   > negation of falsy is true!
--
-- @usage print( (not not TruthyValue) == true )
--   > true

----------
-- The opposite of @{truthy}
-- @name falsy
-- @class field

--------------------------------------------------------------------------------
-- Misc.
-- @section
--------------------------------------------------------------------------------


----------
-- Any string, @{number}, boolean, @{table}, function or userdata.
--
-- @name NotNil
-- @class field

----------
-- Any string, @{number}, boolean, @{table}, function, userdata or nil.
--
-- @name AnyValue
-- @class field

----------
-- Any value that when negated twice evaluates to @{true}. 
-- @see truthy
--
-- @name TruthyValue
-- @class field

----------
-- The name of a base game input. Usable with @{Data.SimpleLinkedInput}.  
-- Depending on context they're either called _input_ or _control_.
--
-- @usage
--  -- Factorio Version 1.1.32
--  -- Extracted from [controls] section of \data\core\locale\en\core.cfg
--
--  There are currently 149 different controls.
--
--  'move-up'                            , 'move-right'                         ,
--  'move-down'                          , 'move-left'                          ,
--  'shoot-enemy'                        , 'shoot-selected'                     ,
--  'open-character-gui'                 , 'open-technology-gui'                ,
--  'rotate'                             , 'reverse-rotate'                     ,
--  'flip-blueprint-horizontal'          , 'flip-blueprint-vertical'            ,
--  'pick-items'                         , 'confirm-gui'                        ,
--  'cycle-blueprint-forwards'           , 'cycle-blueprint-backwards'          ,
--  'cycle-clipboard-forwards'           , 'cycle-clipboard-backwards'          ,
--  'zoom-in'                            , 'zoom-out'                           ,
--  'alt-zoom-in'                        , 'alt-zoom-out'                       ,
--  'toggle-menu'                        , 'production-statistics'              ,
--  'kill-statistics'                    , 'toggle-map'                         ,
--  'toggle-driving'                     , 'clear-cursor'                       ,
--  'smart-pipette'                      , 'mine'                               ,
--  'select-for-blueprint'               , 'select-for-cancel-deconstruct'      ,
--  'reverse-select'                     , 'build'                              ,
--  'copy-entity-settings'               , 'paste-entity-settings'              ,
--  'copy'                               , 'cut'                                ,
--  'paste'                              , 'undo'                               ,
--  'remove-pole-cables'                 , 'build-ghost'                        ,
--  'build-with-obstacle-avoidance'      , 'open-gui'                           ,
--  'drop-cursor'                        , 'pick-item'                          ,
--  'cursor-split'                       , 'stack-transfer'                     ,
--  'stack-split'                        , 'inventory-transfer'                 ,
--  'fast-entity-transfer'               , 'inventory-split'                    ,
--  'fast-entity-split'                  , 'craft'                              ,
--  'craft-5'                            , 'craft-all'                          ,
--  'cancel-craft'                       , 'cancel-craft-5'                     ,
--  'cancel-craft-all'                   , 'quick-bar-button-1'                 ,
--  'quick-bar-button-2'                 , 'quick-bar-button-3'                 ,
--  'quick-bar-button-4'                 , 'quick-bar-button-5'                 ,
--  'quick-bar-button-6'                 , 'quick-bar-button-7'                 ,
--  'quick-bar-button-8'                 , 'quick-bar-button-9'                 ,
--  'quick-bar-button-10'                , 'quick-bar-button-1-secondary'       ,
--  'quick-bar-button-2-secondary'       , 'quick-bar-button-3-secondary'       ,
--  'quick-bar-button-4-secondary'       , 'quick-bar-button-5-secondary'       ,
--  'quick-bar-button-6-secondary'       , 'quick-bar-button-7-secondary'       ,
--  'quick-bar-button-8-secondary'       , 'quick-bar-button-9-secondary'       ,
--  'quick-bar-button-10-secondary'      , 'action-bar-select-page-1'           ,
--  'action-bar-select-page-2'           , 'action-bar-select-page-3'           ,
--  'action-bar-select-page-4'           , 'action-bar-select-page-5'           ,
--  'action-bar-select-page-6'           , 'action-bar-select-page-7'           ,
--  'action-bar-select-page-8'           , 'action-bar-select-page-9'           ,
--  'action-bar-select-page-10'          , 'rotate-active-quick-bars'           ,
--  'next-active-quick-bar'              , 'previous-active-quick-bar'          ,
--  'toggle-filter'                      , 'show-info'                          ,
--  'next-weapon'                        , 'activate-tooltip'                   ,
--  'confirm-message'                    , 'connect-train'                      ,
--  'disconnect-train'                   , 'editor-clone-item'                  ,
--  'editor-delete-item'                 , 'editor-next-variation'              ,
--  'editor-previous-variation'          , 'editor-toggle-pause'                ,
--  'editor-tick-once'                   , 'pause-game'                         ,
--  'editor-speed-up'                    , 'editor-speed-down'                  ,
--  'editor-reset-speed'                 , 'editor-set-clone-brush-source'      ,
--  'editor-set-clone-brush-destination' , 'editor-switch-to-surface'           ,
--  'editor-remove-scripting-object'     , 'open-item'                          ,
--  'add-station'                        , 'add-temporary-station'              ,
--  'toggle-console'                     , 'drag-map'                           ,
--  'place-ping'                         , 'place-in-chat'                      ,
--  'larger-terrain-building-area'       , 'smaller-terrain-building-area'      ,
--  'not-set'                            , 'unknown'                            ,
--  'focus-search'                       , 'previous-technology'                ,
--  'previous-mod'                       , 'logistic-networks'                  ,
--  'toggle-blueprint-library'           , 'open-trains-gui'                    ,
--  'debug-toggle-atlas-gui'             , 'debug-toggle-debug-settings'        ,
--  'debug-toggle-basic'                 , 'debug-reset-zoom'                   ,
--  'debug-reset-zoom-2x'                , 'controller-gui-crafting-tab'        ,
--  'controller-gui-logistics-tab'       , 'controller-gui-character-tab'       ,
--  'toggle-gui-debug'                   , 'toggle-gui-style-view'              ,
--  'toggle-gui-shadows'                 , 'toggle-gui-glows'                   ,
--  'open-prototypes-gui'                , 'open-prototype-explorer-gui'        ,
--  'increase-ui-scale'                  , 'decrease-ui-scale'                  ,
--  'reset-ui-scale'                     , 'next-player-in-replay'              ,
--  'order-to-follow'                    ,                                      ,
--
-- @table InputName


do -- Don't forget to also update Verificate.isType.InputName()!

  local path = 'H:/factorio/instances/[shared-read]/latest/data/core/locale/en/core.cfg'

  local function read_whole_file(path)
    local file = io.open(path)
    local data = file:read('*a')
    file:close()
    return data
    end

  local function format_controls(controls)
    -- Formats the above list of possible controls.
    -- Input is a string of the whole [controls] block
    -- without the header, but including the translations.
    local r = {}
    for s in controls:gmatch('(.-)=.-\n') do r[#r+1] = "'"..s.."'" end
    local r2 = {('--  There are currently %d different controls.\n--'):format(#r)}
    for i=1, #r, 2 do
      r2[#r2+1] = ("\n--  %-37s, %-37s,"):format(r[i],r[i+1] or '')
      end
    return table.concat(r2)
    end

  local function write_to_windows_clipboard(str)
    -- uses a pipe to the build-in "clip.exe"
    io.popen('clip','w'):write(str):close()
    end
    
  write_to_windows_clipboard(
    format_controls(
      read_whole_file(path):match('\n%[controls%]\n(.-)\n%[')
      )
    )
  end