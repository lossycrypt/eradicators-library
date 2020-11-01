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

local Filter = elreq('erlib/lua/Filter')()

-- -------------------------------------------------------------------------- --
-- Tests                                                                      --
-- -------------------------------------------------------------------------- --

local function Test()

  -- Filter.table_value
  do
    
    local F = Filter.table_value
    
    local t1 = {a={b={c='1'}},d={'2','3','4'},g='5'}
    
    -- IS long path
    assert(true == F {'a','b','c',is='1'} (t1))
    assert(true == F {'a','b',is={t1.a.b}} (t1)) -- table target value must be in array of possibilities
    assert(false == F {'a','b','c',is={-7,-8}} (t1))
    
    -- IS one-key-path / with and without value choice
    assert(true  == F{'g',is= '5' } (t1) )
    assert(true  == F{'g',is={'5'}} (t1) )
    assert(false == F{'g',is= '_h' } (t1) )
    assert(false == F{'g',is={'_h'}} (t1) )
    assert(true  == F{'g',is={'_h','5'}} (t1) )
  
    assert(false == F{'g',is={a='5'}} (t1) ) -- not a value ARRAY
    
    -- HAS
    assert(true  == F{'d',has={'or',-1,false,'4' }} (t1))
    assert(false == F{'d',has={'or',-1,false,'17'}} (t1))
    assert(true  == F{'d',has={'and','2','4'     }} (t1))
    assert(false == F{'d',has={'and','2','3','4','5'}} (t1))
    
    assert(false == F{'g',has={'and','2','3','4','5'}} (t1)) --string value can't "has" anything
    
    
    -- Check if the comparators accidentially misdetect the mode keywords
    local t2 = {a={b={'and','or','is'}}}
    assert(false == F{'a','b',is='is'}        (t2) )
    assert(false == F{'a','b',has={'or',-1}}  (t2) )
    assert(false == F{'a','b',has={'and',-1}} (t2) )
    
    end

  -- Filter.chain
  do
    assert(true  == Filter.chain{'or',function(x) return x > 5 end, function(x) return x <2 end} (1) )
    assert(true  == Filter.chain{'or',function(x) return x > 5 end, function(x) return x <2 end} (7) )
    assert(false == Filter.chain{'or',function(x) return x > 5 end, function(x) return x <2 end} (4) )

    assert(false == Filter.chain{'or', {'a',is=5}, {'and',{'b',is=7},{'c',is=7}} } (7))
    
    assert(true  == Filter.chain{'or', {'a',is=5}, {'and',{'b',is=7},{'c',has={'and',6,5}}} } ({a=5              }))
    assert(false == Filter.chain{'or', {'a',is=5}, {'and',{'b',is=7},{'c',has={'and',6,5}}} } ({a=0              }))
    
    assert(true  == Filter.chain{'or', {'a',is=5}, {'and',{'b',is=7},{'c',has={'or' ,6,5}}} } ({a=0,b=7,c={0,0,6}}))
    assert(true  == Filter.chain{'or', {'a',is=5}, {'and',{'b',is=7},{'c',has={'or' ,6,5}}} } ({a=0,b=7,c={0,5,0}}))
    assert(true  == Filter.chain{'or', {'a',is=5}, {'and',{'b',is=7},{'c',has={'and',6,5}}} } ({a=0,b=7,c={5,3,6}}))
    assert(false == Filter.chain{'or', {'a',is=5}, {'and',{'b',is=7},{'c',has={'and',6,5}}} } ({a=0,b=0,c={5,3,0}}))
    end
  



  -- say('  TESTR  @  erlib.Filter → No tests implemented.')
  say('  TESTR  @  erlib.Filter → Ok (not all methods tested)')
  end


-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.test_Filter') end
return function() return Test, {'lua','settings','data_final_fixes','control'} end
