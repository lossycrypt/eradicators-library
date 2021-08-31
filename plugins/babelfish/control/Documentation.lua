-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable

--------------------------------------------------------------------------------
-- Babelfish.
-- @module Babelfish

    
--------------------------------------------------------------------------------
-- Concepts.
-- @section
--------------------------------------------------------------------------------
 
----------
-- Babelfish must be activated before use by calling the global function 
-- `erlib_enable_plugin` in __settings.lua__.
-- You must also activate at __at least one__ @{Babelfish.SearchType|SearchType}
-- by passing an array of search types (see the code box below).
-- Once a search type has been activated by any mod it can not be deactivated
-- again. You can call `erlib_enable_plugin` repeatedly to add more search 
-- types later.
--
--    erlib_enable_plugin('babelfish', {
--      search_types = {'item_name', 'fluid_name', 'recipe_name'}
--      })
--
-- The Demo-Gui must be activated seperately. It should only be activated
-- during development.
--
--    erlib_enable_plugin('babelfish-demo')
--
-- @table Babelfish.HowToActivateBabelfish
do end

----------
-- What to search. One of the following strings. __This is also the
-- order in which translation occurs.__ Once translation for a type
-- is complete it can be fully searched, regardless of the translation
-- status of the other types.
--
-- __Note:__ In vanilla factorio all search functions search only the name,
-- never the description. As descriptions can be very long and thus slow to
-- translate it is recommended to not activate them.
--
--    "item_name"             
--    "fluid_name"            
--    "recipe_name"           
--    "technology_name"       
--    "item_description"      
--    "fluid_description"     
--    "recipe_description"    
--    "technology_description"
--    "equipment_name"        
--    "equipment_description" 
--    "tile_name"             
--    "tile_description"      
--    "entity_name"           
--    "entity_description"    
--    "virtual_signal_name"   
--
-- @table Babelfish.SearchType
do end

-- -------
-- Identifies a language between different Babelfish function calls.
-- Storing this in your global data will likely produce unexpected results.
-- It's best to always retrieve this shortly before usage.
--
-- Only @{FOBJ LuaPlayer.connected|connected} players have a code, and
-- there is a delay of one "ping" between connection and code
-- assignment.
--
-- The special string `'internal'` can be used to ignore the locale and
-- search prototype names directly.
--
-- @table Babelfish.LanguageCode
do end


----------
-- Babelfish built-in sprites. Can be used to decorate mod guis.
-- All icons are 256x256 pixels with 4 mip-map levels.   
--
-- @{FAPI Concepts.SpritePath s}:
-- 
--     "er:babelfish-icon-default"
--     "er:babelfish-icon-green"
--     "er:babelfish-icon-red"
-- 
-- @usage
--    LuaGuiElement.add{type = "sprite-button", sprite = "er:babelfish-icon-default"}
-- 
-- @table Babelfish.Sprites
do end



--------------------------------------------------------------------------------
-- TechnicalDescription.  
-- @section
--------------------------------------------------------------------------------

  
--[[ ------
A detailed explanation of Babelfish's internal processes.

When a new player joins a game Babelfish asks the player what language they use.
This also happens in any situation in which a player might have changed
their language, or when any base or mod updates have happend. However the
factorio API does not currently offer a way to detect language changes in
Singleplayer.

When Babelfish sees a new language in a game for the first time it makes a copy
of the internal "list of strings that need translation" and sends requests to
_the first connected_ player of that language to translate these strings. To
conserve bandwidth in multiplayer only unique strings are sent. The requests
are initially sent in SearchType priority order, but due to how real networks
work the order in which translations are recieved might differ slightly.

Only one translation process can run at a time - if there are multiple
languages to be translated then they will be translated in sequential order.
There is currently no cross-language priorization of SearchTypes.

When a recieved package is the last package for that language and SearchType
Babelfish will raise the on_babelfish_translation_state_changed event for
each player of that language.

When a change in mod or base game version is detected then Babelfish will
re-start the process of translating all strings. It will also raise
on_babelfish_translation_state_changed for _all_ players regardless of
any actual changes.

Because most mod
updates only change small bits of the locale - if any at all - Babelfish keeps
all old translations. If no _new_ locale keys have been added then
all Babelfish API methods will use the old translations until the new ones
arrive and



@table InternalWorkflow
]]