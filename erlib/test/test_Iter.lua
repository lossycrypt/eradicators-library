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

local Table = elreq('erlib/lua/Table')()

local Iter = elreq('erlib/lua/Iter/!init')()

local table_concat
    = table.concat

-- -------------------------------------------------------------------------- --
-- Tests                                                                      --
-- -------------------------------------------------------------------------- --

local function Test()

  local equ = Table.is_equal

  -- Iter.sync_tuples
  do
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
    end
  
  -- Iter.combinations
  do
    local i=-1
    for tbl in Iter.combinations(3,Table.range(0,9)) do
      i=i+1
      assert(i==tonumber(table_concat(tbl)))
      end
    assert(i == 999)
    say('  TESTR  @  erlib.Iter.combinations → Ok')
    end

  -- Iter.permutations
  do
    
    -- empty array should not be iterated
    for _ in Iter.permutations{} do assert(false) end
    for _ in Iter.permutations({1,2,3},3,1) do assert(false) end
    
    local r1 = {
      {"a", "b", "c"},
      {"a", "c", "b"},
      {"c", "a", "b"},
      {"c", "b", "a"},
      {"b", "c", "a"},
      {"b", "a", "c"},
      }
  
    local i = 0
    for k in Iter.permutations{'a','b','c'} do
      i = i+1
      assert(equ(k,r1[i]))
      end
    assert(i == 6)
      
  
    local r2 = {
      {1, 2, 3, 4},
      {1, 2, 4, 3},
      {1, 4, 2, 3},
      {4, 1, 2, 3},
      
      {4, 1, 3, 2},
      {1, 4, 3, 2},
      {1, 3, 4, 2},
      {1, 3, 2, 4},
      
      {3, 1, 2, 4},
      {3, 1, 4, 2},
      {3, 4, 1, 2},
      {4, 3, 1, 2},
      
      {4, 3, 2, 1},
      {3, 4, 2, 1},
      {3, 2, 4, 1},
      {3, 2, 1, 4},
      
      {2, 3, 1, 4},
      {2, 3, 4, 1},
      {2, 4, 3, 1},
      {4, 2, 3, 1},
      
      {4, 2, 1, 3},
      {2, 4, 1, 3},
      {2, 1, 4, 3},
      {2, 1, 3, 4},
      }
    
    local i = 0    
    for k in Iter.permutations({'a','b',1,2,3,4,'c','d'},3,6) do 
      i = i+1
      assert(equ(k,r2[i]))
      end
    assert(i == 24)
    
    say('  TESTR  @  erlib.Iter.permutations → Ok.')
    end

  -- Iter.subsets
  do
    
    assert(equ(nil,Iter.subsets(0,{1,2})())) -- size too small
    assert(equ(nil,Iter.subsets(3,{1,2})())) -- arr too short
    
    local r = {
      {1,2,3},
      {1,2,4},
      {1,2,5},

      {1,3,4},
      {1,3,5},

      {1,4,5},

      {2,3,4},
      {2,3,5},
      {2,4,5},

      {3,4,5},
      }
    local i = 0
    for s in Iter.subsets(3,{1,2,3,4,5}) do
      i = i+1
      assert(equ(s,r[i]))
      end
    assert(i == 10)
  
    local r2 = {
      {"a", "b", "c", "d"},
      {"a", "b", "c", "e"},
      {"a", "b", "c", "f"},
      {"a", "b", "d", "e"},
      {"a", "b", "d", "f"},
      {"a", "b", "e", "f"},
      {"a", "c", "d", "e"},
      {"a", "c", "d", "f"},
      {"a", "c", "e", "f"},
      {"a", "d", "e", "f"},
      {"b", "c", "d", "e"},
      {"b", "c", "d", "f"},
      {"b", "c", "e", "f"},
      {"b", "d", "e", "f"},
      {"c", "d", "e", "f"},
      }
  
    local i = 0
    for s in Iter.subsets(4,{'a','b','c','d','e','f'}) do 
      i = i+1
      assert(equ(s,r2[i]))
      end
    assert(i == 15)
  
  
    say('  TESTR  @  erlib.Iter.subsets → Ok.')
    end
    
    

  say('  TESTR  @  erlib.Iter.array_pairs → No test implemented.')
  say('  TESTR  @  erlib.Iter.deep_pairs → No test implemented.')
  say('  TESTR  @  erlib.Iter.filter_pairs → No test implemented.')
  end


-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.test_Iter') end
return function() return Test, {'lua','settings','data_final_fixes','control'} end
