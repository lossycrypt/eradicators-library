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
    
  do -- Iter.ntuples
  
    for _ in Iter.ntuples(1, nil) do
      assert(false) -- should skip nil input.
      end
  
    local test = {
      [1] = {
        a = {
          [10] = {b = {c = {d = {e = {7}}}}  },
          [20] = {b = {c = {d = {e = {7}}}}  },
          [30] = {b = {c = {d = {e = {7}}}}  },
            },
          },
      [2] = {
        f = {
          g = {
            h = {
              [10] = {i = {j = {42}}  },
              [20] = {i = {j = {42}}  },
              [30] = {i = {j = {42}}  },
              [40] = {i = {j = {42}}  },
              [40] = {i = {j = {k = {l = {42}}}}  },
              [50] = {i = {19}  }, -- non-table object on the path -> no output
              [60] = {i = {}  }, -- too shallow -> no output
              }
            }
          }
          },
      }
  
    -- Iteration order of pairs/next - and thus ntuples is
    -- not deterministic. So output candidates have to be
    -- searched and removed to ensure that each candidate
    -- is used exactly once.
    local function find_equal_and_remove(tbl, candidates)
      for i, v in pairs(candidates) do
        if equ(tbl, v) then
          print('found', i)
          candidates[i] = nil
          return true end
        end
      return false end
  
    local function test_ntuples(n, candidates)
      local i = 0
      for _1,_2,_3,_4,_5,_6,_7,_8,_9,_10,_11,_12 in Iter.ntuples(n, test) do
        local r = {_1,_2,_3,_4,_5,_6,_7,_8,_9,_10,_11,_12}        
        i = i + 1
        assert(#r == n)
        assert(find_equal_and_remove(r, candidates))
        end
      assert(#candidates == 0)
      end
    
    test_ntuples(2, { -- n=1 equals n=2
      {2, test[2] },
      {1, test[1] }
      })
    test_ntuples(3, {
      {2, "f", test[2].f },
      {1, "a", test[1].a }
      })
    test_ntuples(4, {
      {2, "f", "g", test[2].f.g },
      {1, "a", 20, test[1].a[20] },
      {1, "a", 10, test[1].a[10] },
      {1, "a", 30, test[1].a[30] }
      })
    test_ntuples(5, {
      {2, "f", "g", "h", test[2].f.g.h },
      {1, "a", 20, "b", test[1].a[20].b },
      {1, "a", 10, "b", test[1].a[10].b },
      {1, "a", 30, "b", test[1].a[30].b }
      })
    test_ntuples(6, {
      {2, "f", "g", "h", 40, test[2].f.g.h[40] },
      {2, "f", "g", "h", 10, test[2].f.g.h[10] },
      {2, "f", "g", "h", 20, test[2].f.g.h[20] },
      {2, "f", "g", "h", 60, test[2].f.g.h[60] },
      {2, "f", "g", "h", 30, test[2].f.g.h[30] },
      {2, "f", "g", "h", 50, test[2].f.g.h[50] },
      {1, "a", 20, "b", "c", test[1].a[20].b.c },
      {1, "a", 10, "b", "c", test[1].a[10].b.c },
      {1, "a", 30, "b", "c", test[1].a[30].b.c }
      })
    test_ntuples(7, {
      {2, "f", "g", "h", 40, "i", test[2].f.g.h[40].i },
      {2, "f", "g", "h", 10, "i", test[2].f.g.h[10].i },
      {2, "f", "g", "h", 20, "i", test[2].f.g.h[20].i },
      {2, "f", "g", "h", 60, "i", test[2].f.g.h[60].i },
      {2, "f", "g", "h", 30, "i", test[2].f.g.h[30].i },
      {2, "f", "g", "h", 50, "i", test[2].f.g.h[50].i },
      {1, "a", 20, "b", "c", "d", test[1].a[20].b.c.d },
      {1, "a", 10, "b", "c", "d", test[1].a[10].b.c.d },
      {1, "a", 30, "b", "c", "d", test[1].a[30].b.c.d }
      })
    test_ntuples(8, {
      {2, "f", "g", "h", 40, "i", "j", test[2].f.g.h[40].i.j },
      {2, "f", "g", "h", 10, "i", "j", test[2].f.g.h[10].i.j },
      {2, "f", "g", "h", 20, "i", "j", test[2].f.g.h[20].i.j },
      {2, "f", "g", "h", 30, "i", "j", test[2].f.g.h[30].i.j },
      {2, "f", "g", "h", 50, "i", 1, 19  },
      {1, "a", 20, "b", "c", "d", "e", test[1].a[20].b.c.d.e },
      {1, "a", 10, "b", "c", "d", "e", test[1].a[10].b.c.d.e },
      {1, "a", 30, "b", "c", "d", "e", test[1].a[30].b.c.d.e }
      })
    test_ntuples(9, {
      {2, "f", "g", "h", 40, "i", "j", "k", test[2].f.g.h[40].i.j.k },
      {2, "f", "g", "h", 10, "i", "j", 1, 42  },
      {2, "f", "g", "h", 20, "i", "j", 1, 42  },
      {2, "f", "g", "h", 30, "i", "j", 1, 42  },
      {1, "a", 20, "b", "c", "d", "e", 1, 7  },
      {1, "a", 10, "b", "c", "d", "e", 1, 7  },
      {1, "a", 30, "b", "c", "d", "e", 1, 7  }
      })
    test_ntuples(10, {
      {2, "f", "g", "h", 40, "i", "j", "k", "l", test[2].f.g.h[40].i.j.k.l }
      })
    test_ntuples(11, {
      {2, "f", "g", "h", 40, "i", "j", "k", "l", 1, 42}
      })
    test_ntuples(12, {})
    
    
    say('  TESTR  @  erlib.Iter.ntuples → Ok.')
    end
    

  say('  TESTR  @  erlib.Iter.array_pairs → No test implemented.')
  say('  TESTR  @  erlib.Iter.dpairs → No test implemented.')
  say('  TESTR  @  erlib.Iter.filter_pairs → No test implemented.')
  end


-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.test_Iter') end
return function() return Test, {'lua','settings','data_final_fixes','control'} end
