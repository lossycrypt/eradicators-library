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
-- local Stacktrace = elreq('erlib/factorio/Stacktrace')()
-- local stage,phase= Stacktrace.get_load_stage(), Stacktrace.get_load_phase()

local Table   = elreq('erlib/lua/Table')()
local Set     = elreq('erlib/lua/Set'  )()

-- -------------------------------------------------------------------------- --
-- Tests                                                                      --
-- -------------------------------------------------------------------------- --

local function Test()

  local equ = Table.is_equal
  
  -- attach meta
  local A1 = Set({true, true, true})
  assert(getmetatable(A1).__index == Set)
  
  local A2 = A1:union{nil, nil, true, true}
  assert(equ(A2, {true, true, true, true}))
  
  local A3 = A2:intersection{nil, true, true, nil, nil, true}
  assert(equ(A3, {nil, true, true, nil}))
  
  assert(A3:contains(5) == false)
  
  local A4 = A3:difference({true, nil, nil, true}, false)
  assert(equ(A4, {true, true, true, true}))

  assert(getmetatable(A4) == nil)

  -- say('  TESTR  @  erlib.Set → No tests implemented.')
  say('  TESTR  @  erlib.Set → Ok (needs more tests)')
  -- say('  TESTR  @  erlib.Set → Ok')
  end


-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.test_Set') end
return function() return Test, {'lua','settings','data_final_fixes','control'} end
