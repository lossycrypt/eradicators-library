# Style Guide

  Eradicators Library and most other mods I wrote adhere to these
  self-imposed rules to improve code readability accross all files.

## Reserved Variable names

  Some variable names are reserved and may _never_ be used for
  anything else to improve code readability.
  
  "e" (small letter e): The event table for the event currently being handled.
  "p" (small letter p): A reference to the LuaPlayer object of the player of the current event.
  
  "pdata": A reference to the global Savedata associated with the player of the current event.
  "pindex": The LuaPlayer.index of the player of the current event.

## CamelCase and snake_case

  CamelCase is used for (library) classes and ErLib module names,
  while snake_case is used for class object instances and all other
  temporary local variables, table names etc.
  
## Global

  Global variables are to be avoided at almost all costs. Library
  modules are to be locally loaded with the exception of EventManager
  and PluginManager. Plugins that need to communicate within a mod
  must store their methods in a plugin-named sub-table of a global table
  called "Plugins".

## Short Names
  
  A limited number of erlib modules sometimes use short names,
  all other modules always use their full name.
  
  "EM": EventManagerLite
  "PM": PluginManagerLite
  
  

  