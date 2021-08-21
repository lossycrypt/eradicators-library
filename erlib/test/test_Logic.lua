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

local Logic = elreq ('erlib/lua/Logic')()

-- -------------------------------------------------------------------------- --
-- Tests                                                                      --
-- -------------------------------------------------------------------------- --

local function Test()

  local A,B,C,D = 'A',{},false,nil
  
  
  assert(true  == Logic.And(A,B,A,B))
  assert(false == Logic.And(A,B,A,D))
  assert(false == Logic.And(A,B,C,D))
  
  assert(true  == Logic.Or (A,B,C,D))
  assert(false == Logic.Or (C,D,C,D))
  assert(false == Logic.Or (C      ))
  
  assert(true  == Logic.Xor(A,  C,D))
  assert(false == Logic.Xor(A,B,C  ))
  assert(false == Logic.Xor(A,B,C,D))
  
  assert(A     == Logic.Xory(D,C  ,A))
  assert(B     == Logic.Xory(D,C,B  ))
  assert(false == Logic.Xory(D,D,D,D)) -- should not return nil
  
  assert(B     == Logic.Andy(A,B,A,B))
  assert(A     == Logic.Andy(A,B,B,A))
  assert(false == Logic.Andy(A,B,B,D)) -- should not return nil
  
  assert(A     == Logic.Ory (A,B,C,D))
  assert(B     == Logic.Ory (D,C,B,A))
  assert(false == Logic.Ory (D,C,D,D)) -- should not return nil
  



  say('  TESTR  @  erlib.Logic → Ok')
  end


-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.test_Logic') end
return function() return Test, {'lua','settings','data_final_fixes','control'} end
