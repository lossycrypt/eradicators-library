-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable


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


local Iter = elreq('erlib/lua/Iter/!init')()
-- -------------------------------------------------------------------------- --
-- Tests                                                                      --
-- -------------------------------------------------------------------------- --

local function Test()

  local t1 = {'a', 'b', 'c', 'd', {} , ['x'] = 'f'}
  local t2 = nil -- test: assume nil is an empty table
  local t3 = {'A', 'B', 'C', nil, 'E', ['x'] = 'F'}
  local t4 = {}
  local t5 = {nil, nil,  3 ,  4 ,  5 , ['x'] =  6 }
  for k,v1,v2,v3,v4,v5 in Iter.sync_tuples(t1,nil,t3,t4,t5) do
    assert(v1 == t1[k])
    assert(v2 == nil  )
    assert(v3 == t3[k])
    assert(v4 == nil  )
    assert(v5 == t5[k])
    end

  




  say('  TESTR  @  erlib.Iter.sync_tuples → Ok')
  
  
  say('  TESTR  @  erlib.Iter.deep_pairs → No test implemented.')
  end


-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.test_Iter') end
return function() return Test, {'lua','settings','data_final_fixes','control'} end
