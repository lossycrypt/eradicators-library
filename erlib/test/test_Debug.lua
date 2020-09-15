-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

-- -------------------------------------------------------------------------- --
-- Tests                                                                      --
-- -------------------------------------------------------------------------- --


local function Test()
  
  local Debug = require('__eradicators-library__/erlib/factorio/Debug')()
  
  local stack = Debug.get_all_info()
  
  local ok = {data=true,settings=true,control=true}
  
  local function _equ(A,B)
    return 
     (A.lastlinedefined == B.lastlinedefined) and
     (A.linedefined     == B.linedefined    ) and
     (A.short_src       == B.short_src      ) and
     (A.source          == B.source         ) and
     (A.what            == B.what           )
    end

  -- print('  TESTR  erlib.Debug -> testing...')
  
  -- for i=1,#stack do print(i,serpent.line(stack[i])) end
  
  assert(_equ(Debug.get_info( 1),stack[1]     ))
  assert(_equ(Debug.get_info(-1),stack[#stack]))
  
  assert(Debug.get_pos     ( 1) == 'test_Debug.lua:32'      ) --do not move this line!
  assert(Debug.get_mod_name(-1) == 'eradicators-library'    )
  assert(Debug.get_mod_root(-1) == '__eradicators-library__')
  assert(Debug.get_cur_dir ( 1) == '__eradicators-library__/erlib/test')
  
  assert(Debug.path2name(Debug.get_cur_dir(-1)) == 'eradicators-library')
  assert(Debug.name2root(Debug.get_mod_name(0)) == Debug.get_mod_root(0))
  
  print('  TESTR  erlib.Debug -> Ok')
  end


-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
return function() Test() return nil end
