-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--[[

  Tests assumptions that ErLib makes about certain behaviors of the factorio
  engine. These assumptions are mostly made for performance reasons. Obviously
  if any of them are wrong then stuff is gonna break badly.

  ]]

-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
local Stacktrace = elreq('erlib/factorio/Stacktrace')()
local stage,phase= Stacktrace.get_load_stage(), Stacktrace.get_load_phase()

local stop   = elreq('erlib/lua/Error')().Stopper('Assumptions')

-- -------------------------------------------------------------------------- --
-- Tests                                                                      --
-- -------------------------------------------------------------------------- --



local function Test()


  if not flag.IS_FACTORIO then
    return say('  TESTR  @  erlib.Assumptions → Skipped (Not Factorio)')
    end

    
  -- Assume: defines.direction is a clockwise array from 0 to 7
  assert(defines.direction.north     == 0)
  assert(defines.direction.northeast == 1)
  assert(defines.direction.east      == 2)
  assert(defines.direction.southeast == 3)
  assert(defines.direction.south     == 4)
  assert(defines.direction.southwest == 5)
  assert(defines.direction.west      == 6)
  assert(defines.direction.northwest == 7)
  local n=0 for _ in pairs(defines.direction) do n=n+1 end
  assert(n == 8)
  say('  TESTR  @  erlib.Assumptions.Direction → Ok')


  -- Assume: on_tick has event number 0
  assert(defines.events.on_tick == 0)
  say('  TESTR  @  erlib.Assumptions.on_tick → Ok')


  if not (flag.IS_FACTORIO and _ENV.game) then
    return say('  TESTR  @  erlib.Assumptions.PairsIndexIsName → Skipped (Not Runtime)')
    end

    
  -- Assume pairs() gives a meaningful index for game.x groups.
  for i,this in pairs(game.players ) do assert(i==this.index) end
  for i,this in pairs(game.forces  ) do assert(i==this.name ) end
  for i,this in pairs(game.surfaces) do assert(i==this.name ) end
  say('  TESTR  @  erlib.Assumptions.PairsIndexIsName → Ok')
  
  
  say('  TESTR  @  erlib.Assumptions → Ok')
  end


-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.test_Assumptions') end
return function() return Test, {'lua','settings','data_final_fixes','control'} end
