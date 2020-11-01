-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

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
-- An @{Integer} >= 0. Also called a PositiveInteger.
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
-- Any value that when negated twice evaluates to @{true}. In Lua this is
-- any string, @{number}, @{true}, @{table}, function or userdata. But not
-- boolean false or nil.
--
-- @name TruthyValue
-- @class field
--
-- @usage local yes = ((not not TruthyValue) == true)
-- @usage local yes = (TruthyValue and true)

----------
-- The name of a base game input. Usable with @{Data.SimpleLinkedInput}.  
-- The API calls them _input_ but in-game they're called _Controls_.
--
-- @usage
--  -- Factorio Version 1.0.0
--  -- Extracted from [control] section of \data\core\locale\en\core.cfg
--
--  'move-up'                            , 'quick-bar-button-7-secondary'       ,
--  'move-right'                         , 'quick-bar-button-8-secondary'       ,
--  'move-down'                          , 'quick-bar-button-9-secondary'       ,
--  'move-left'                          , 'quick-bar-button-10-secondary'      ,
--  'shoot-enemy'                        , 'action-bar-select-page-1'           ,
--  'shoot-selected'                     , 'action-bar-select-page-2'           ,
--  'open-character-gui'                 , 'action-bar-select-page-3'           ,
--  'open-technology-gui'                , 'action-bar-select-page-4'           ,
--  'rotate'                             , 'action-bar-select-page-5'           ,
--  'reverse-rotate'                     , 'action-bar-select-page-6'           ,
--  'pick-items'                         , 'action-bar-select-page-7'           ,
--  'close-gui'                          , 'action-bar-select-page-8'           ,
--  'cycle-blueprint-forwards'           , 'action-bar-select-page-9'           ,
--  'cycle-blueprint-backwards'          , 'action-bar-select-page-10'          ,
--  'cycle-clipboard-forwards'           , 'rotate-active-quick-bars'           ,
--  'cycle-clipboard-backwards'          , 'next-active-quick-bar'              ,
--  'zoom-in'                            , 'previous-active-quick-bar'          ,
--  'zoom-out'                           , 'toggle-filter'                      ,
--  'alt-zoom-in'                        , 'show-info'                          ,
--  'alt-zoom-out'                       , 'next-weapon'                        ,
--  'toggle-menu'                        , 'activate-tooltip'                   ,
--  'production-statistics'              , 'confirm-message'                    ,
--  'kill-statistics'                    , 'connect-train'                      ,
--  'toggle-map'                         , 'disconnect-train'                   ,
--  'toggle-driving'                     , 'editor-clone-item'                  ,
--  'clean-cursor'                       , 'editor-delete-item'                 ,
--  'smart-pipette'                      , 'editor-next-variation'              ,
--  'mine'                               , 'editor-previous-variation'          ,
--  'select-for-blueprint'               , 'editor-toggle-pause'                ,
--  'select-for-cancel-deconstruct'      , 'editor-tick-once'                   ,
--  'reverse-select'                     , 'pause-game'                         ,
--  'build'                              , 'editor-speed-up'                    ,
--  'copy-entity-settings'               , 'editor-speed-down'                  ,
--  'paste-entity-settings'              , 'editor-reset-speed'                 ,
--  'copy'                               , 'editor-set-clone-brush-source'      ,
--  'cut'                                , 'editor-set-clone-brush-destination' ,
--  'paste'                              , 'editor-switch-to-surface'           ,
--  'undo'                               , 'editor-remove-scripting-object'     ,
--  'remove-pole-cables'                 , 'open-item'                          ,
--  'build-ghost'                        , 'add-station-modifier'               ,
--  'build-with-obstacle-avoidance'      , 'temporary-station-modifier'         ,
--  'open-gui'                           , 'toggle-console'                     ,
--  'drop-cursor'                        , 'drag-map'                           ,
--  'pick-item'                          , 'place-tag'                          ,
--  'cursor-split'                       , 'place-ping'                         ,
--  'stack-transfer'                     , 'place-in-chat'                      ,
--  'stack-split'                        , 'larger-terrain-building-area'       ,
--  'inventory-transfer'                 , 'smaller-terrain-building-area'      ,
--  'fast-entity-transfer'               , 'not-set'                            ,
--  'inventory-split'                    , 'unknown'                            ,
--  'fast-entity-split'                  , 'focus-search'                       ,
--  'craft'                              , 'previous-technology'                ,
--  'craft-5'                            , 'previous-mod'                       ,
--  'craft-all'                          , 'logistic-networks'                  ,
--  'cancel-craft'                       , 'toggle-blueprint-library'           ,
--  'cancel-craft-5'                     , 'debug-toggle-atlas-gui'             ,
--  'cancel-craft-all'                   , 'debug-toggle-debug-settings'        ,
--  'quick-bar-button-1'                 , 'debug-toggle-basic'                 ,
--  'quick-bar-button-2'                 , 'debug-reset-zoom'                   ,
--  'quick-bar-button-3'                 , 'debug-reset-zoom-2x'                ,
--  'quick-bar-button-4'                 , 'toggle-tips-and-tricks'             ,
--  'quick-bar-button-5'                 , 'controller-gui-crafting-tab'        ,
--  'quick-bar-button-6'                 , 'controller-gui-logistics-tab'       ,
--  'quick-bar-button-7'                 , 'controller-gui-character-tab'       ,
--  'quick-bar-button-8'                 , 'toggle-gui-debug'                   ,
--  'quick-bar-button-9'                 , 'toggle-gui-style-view'              ,
--  'quick-bar-button-10'                , 'toggle-gui-shadows'                 ,
--  'quick-bar-button-1-secondary'       , 'toggle-gui-glows'                   ,
--  'quick-bar-button-2-secondary'       , 'open-prototypes-gui'                ,
--  'quick-bar-button-3-secondary'       , 'open-prototype-explorer-gui'        ,
--  'quick-bar-button-4-secondary'       , 'increase-ui-scale'                  ,
--  'quick-bar-button-5-secondary'       , 'decrease-ui-scale'                  ,
--  'quick-bar-button-6-secondary'       , 'reset-ui-scale'                     ,
--
-- @table InputName