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

local Version = elreq('erlib/lua/Version')()

-- -------------------------------------------------------------------------- --
-- Tests                                                                      --
-- -------------------------------------------------------------------------- --

local function Test()
  local a,b = '1.2.2','5.66.77'
  local ops = {'>','>=','==','!=','<=','<'}
  local correct = {
    false,true ,false,false, false,true ,true,true, false,false,true ,true , 
    true ,true ,false,false, true ,false,true,true, true ,false,false,false,
    }
  local i = 0
  for _,op in pairs(ops) do
    if not (
      (correct[i+1] == Version.compare(a,op,b)) and
      (correct[i+2] == Version.compare(b,op,a)) and
      (correct[i+3] == Version.compare(a,op,a)) and
      (correct[i+4] == Version.compare(b,op,b))
      ) then
      assert(false,'Version Module Test failed at "'..op..'"')
      end
    i = i+4
    end
    
  assert(Version.compare('7'    ,'==','7.0.0'))
  assert(Version.compare('7.7'  ,'==','7.7.0'))
  assert(Version.compare('7.7.7','==','7.7.7'))
    
  say('  TESTR  @  erlib.Version → Ok')
  end


-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.test_Version') end
return function() return Test, {'lua','settings','data_final_fixes','control'} end
