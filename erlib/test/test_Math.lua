-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable


-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Eradicators Library                                                        --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
local Stacktrace = elreq('erlib/factorio/Stacktrace')()
local stage,phase= Stacktrace.get_load_stage(), Stacktrace.get_load_phase()

local Table = elreq('erlib/lua/Table')()

local Math = elreq('erlib/lua/Math')()

-- -------------------------------------------------------------------------- --
-- Tests                                                                      --
-- -------------------------------------------------------------------------- --

local function Test()

  local equ = Table.is_equal
  
  assert( 1 == Math.factorial(0))
  assert( 1 == Math.factorial(1))
  assert( 2 == Math.factorial(2))
  assert( 6 == Math.factorial(3))
  assert(24 == Math.factorial(4))
  
  

  say('  TESTR  @  erlib.Math → Ok')
  end


-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.test_Math') end
return function() return Test, {'lua','settings','data_final_fixes','control'} end
