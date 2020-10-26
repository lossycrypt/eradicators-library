--remte interface on/off

-- runs in library space so that only one has to run if several mods use it


function start_watching_player(pindex, position to start watching at,chunk_range)

  --> stuff like the Schaufel zum Wassergräben buddlen only need very short range
      -> 

functoin stop_watching_player

no function to un-watch all players

-- hard requirement: per-mod player watch lists (otherwise the first remove would break all mods)


--> running it as a hack require raising tons of events though, 
or is it faster to manually check if other mods have fitting remote interfaces?
at least that way only mods that are known to care are informed.

How much slower is this made by having to use remove interfaces?
Should this be run in core instead?