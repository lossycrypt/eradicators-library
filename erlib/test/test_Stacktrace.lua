-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

-- -------------------------------------------------------------------------- --
-- Tests                                                                      --
-- -------------------------------------------------------------------------- --


local function Test()
  
  local Stacktrace = require('__eradicators-library__/erlib/factorio/Stacktrace')()
  
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

  -- print('  TESTR  erlib.Stacktrace -> testing...')
  
  -- for i=1,#stack do print(i,serpent.line(stack[i])) end
  
  assert(_equ(Stacktrace.get_info( 1),stack[1]     ))
  assert(_equ(Stacktrace.get_info(-1),stack[#stack]))
  
  assert(Stacktrace.get_pos     ( 1) == 'test_Stacktrace.lua:32'      ) --do not move this line!
  assert(Stacktrace.get_mod_name(-1) == 'eradicators-library'    )
  assert(Stacktrace.get_mod_root(-1) == '__eradicators-library__')
  assert(Stacktrace.get_cur_dir ( 1) == '__eradicators-library__/erlib/test')
  
  assert(Stacktrace.path2name(Stacktrace.get_cur_dir(-1)) == 'eradicators-library')
  assert(Stacktrace.name2root(Stacktrace.get_mod_name(0)) == Stacktrace.get_mod_root(0))
  
  print('  TESTR  erlib.Stacktrace -> Ok')
  end


-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
return function() Test() return nil end
