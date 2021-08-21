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

-- -------------------------------------------------------------------------- --
-- Tests                                                                      --
-- -------------------------------------------------------------------------- --

local function Test()
  
  
  local stack = Stacktrace.get_all_info()
  
  local ok = {data=true,settings=true,control=true}
  
  local function _equ(A,B)
    return 
     (A.lastlinedefined == B.lastlinedefined) and
     (A.linedefined     == B.linedefined    ) and
     (A.short_src       == B.short_src      ) and
     (A.source          == B.source         ) and
     (A.what            == B.what           )
    end

  -- say('  TESTR  erlib.Stacktrace -> testing...')
  
  -- for i=1,#stack do say(i,serpent.line(stack[i])) end
  
  assert(_equ(Stacktrace.get_info( 1),stack[1]     ))
  assert(_equ(Stacktrace.get_info(-1),stack[#stack]))
  
  assert(Stacktrace.get_pos     ( 1) == 'test_Stacktrace.lua:43' ) --do not move this line!
  
  if flag.IS_FACTORIO then
    assert(Stacktrace.get_mod_name(-1) == 'eradicators-library'    )
    assert(Stacktrace.get_mod_root(-1) == '__eradicators-library__/')
    assert(Stacktrace.get_directory ( 1) == '__eradicators-library__/erlib/test/')
    
    assert(Stacktrace.path2name(Stacktrace.get_directory(-1)) == 'eradicators-library')
    assert(Stacktrace.name2root(Stacktrace.get_mod_name ( 0)) == Stacktrace.get_mod_root(0))
  
    end
  say('  TESTR  @  erlib.Stacktrace → Ok')
  end


-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.test_Stacktrace') end
return function() return Test, {'lua','settings','data_final_fixes','control'} end
