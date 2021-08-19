-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable


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

local Table   = elreq('erlib/lua/Table')()
local Set     = elreq('erlib/lua/Set'  )()
local Compare = elreq('erlib/lua/Compare')()
local L       = elreq('erlib/lua/Lambda')()

-- -------------------------------------------------------------------------- --
-- Tests                                                                      --
-- -------------------------------------------------------------------------- --

local function Test()

  local equ = Table.is_equal
  
  local function tbl1 ()
    return {'a','b','c','d','e',a=1,b=2,c=3,d=4,e=5}
    end
  
  -- Table.is_equal (nessecary for most other tests)
  do
    local a = {1,2,nil,3,4}
    local b = {5,6,7,8}
    local c = {'a',nil,'b','c',nil,'d'}
    c[5]    = c
    c[2^32] = function()end
    c[a] = {b,c} -- primitively equal table key must work
    local test1 = {a=a,b={b=b,c={c=c}}}
    local test2 = {a=a,b={b=b,c={c=c}}}
    assert(false == (test1 == test2))
    assert(true  == equ(test1,test2))
    test1[17] = 'bar'
    test2[17] = 'BAR'
    assert(false  == equ(test1,test2))
    test1[17] = nil
    test2[17] = nil
    assert(true  == equ(test1,test2))
    test1[{}] = 'foo'
    test2[{}] = 'foo' -- table-as-key is not supported 
    assert(false  == equ(test1,test2))
    end
  
  -- Table.array_size
  do
    assert(5 == Table.array_size{nil,nil,nil,nil,'',nil,test=42})
    assert(5 == Table.array_size{1,2,3,4,5})
    assert(0 == Table.array_size{[0]=true})
    end
    
  -- Table.range
  do
    assert(equ(Table.range(10),{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}))
    assert(equ(Table.range(5,10),          {5, 6, 7, 8, 9, 10}))
    assert(equ(Table.range(2,44,4),{2, 6, 10, 14, 18, 22, 26, 30, 34, 38, 42}))
    end
  
  -- Table.values, Table.keys
  do
    local vals = Table.values(tbl1()) -- order of return is undefined behavior (pairs)
    local keys = Table.keys  (tbl1()) -- so they have to be compared as Set.
    assert(equ(Set.from_values(tbl1()),Set.from_values{'a','b','c','d','e',1,2,3,4,5}))
    assert(equ(Set.from_values(tbl1()),Set.from_values{'a','b','c','d','e',1,2,3,4,5}))
    end

  -- Table.flip
  do
    local t1 = Table{'a','b','c','d','e'}
    local t2 = Table(t1:flip())
    assert(5 == t1:size      ())
    assert(5 == t2:size      ())
    assert(5 == t1:array_size())
    assert(0 == t2:array_size())
    assert(false == t1:is_equal{a = 1, b = 2, c = 3, d = 4, e = 5})
    assert(true  == t2:is_equal{a = 1, b = 2, c = 3, d = 4, e = 5})
    end
    
  -- Table.plural
  do
    assert(equ(Table.plural{{1,2,3}},{{1,2,3}}))
    assert(equ(Table.plural(1),{1}))
    end
    
  -- Table.is_empty
  do
    assert(true  == Table.is_empty{})
    assert(false == Table.is_empty{[{}]=0})
    end
    
  -- Table.nil_if_empty
  do
    local a = {1}
    assert(a   == Table(a):nil_if_empty())
    assert(nil == Table{ }:nil_if_empty())
    end
    
  -- Table.rep
  do
    local result = {
      {"button", caption =  1 , path = {"buttons",  1 }},
      {"button", caption =  2 , path = {"buttons",  2 }},
      {"button", caption =  3 , path = {"buttons",  3 }},
      {"button", caption = "+", path = {"buttons", "+"}},
      {"button", caption = "-", path = {"buttons", "-"}},
      {"button", caption =  4 , path = {"buttons",  4 }},
      {"button", caption =  5 , path = {"buttons",  5 }},
      {"button", caption =  6 , path = {"buttons",  6 }},
      {"button", caption = "*", path = {"buttons", "*"}},
      {"button", caption = "/", path = {"buttons", "/"}},
      {"button", caption =  7 , path = {"buttons",  7 }},
      {"button", caption =  8 , path = {"buttons",  8 }},
      {"button", caption =  9 , path = {"buttons",  9 }},
      {"button", caption = "(", path = {"buttons", "("}},
      {"button", caption = ")", path = {"buttons", ")"}},
      {"button", caption =  0 , path = {"buttons",  0 }},
      {"button", caption = ".", path = {"buttons", "."}},
      {"button", caption = "←", path = {"buttons", "←"}},
      {"button", caption = "C", path = {"buttons", "C"}}
      }
    local buttons = {
      1 , 2 , 3 ,'+','-',
      4 , 5 , 6 ,'*','/',
      7 , 8 , 9 ,'(',')',
      0 ,'.','←','C',
      }
    local layout = Table.rep(
      {'button'}, nil, -- automatic length deduction from #caption
      {caption=buttons,path = Table.rep({'buttons'},#buttons,{[2]=buttons})}
      )
    assert(equ(layout,result))
    end
    
  -- Table.to_array
  do
    local t0 = {'a','b','c'}
    local t1 = {'a','b','c',[5.1] = 'd',[-1] = 'e'}
  
    -- copy mode
    local a1 = Table.to_array(t1,{})
    assert(t1 ~= a1)
    assert(equ(t0,a1))
    
    -- in-place mode
    Table.to_array(t1)
    assert(equ(t0,t1))
    end
    
    
  -- Table.find_largest
  do
    local t1 = {4,3,5,2,7,3}
    local v,k = Table.find_largest(t1)
    assert((v==7) and (k==5))
    
    local t2 = {'a','b','e','d','c'}
    local v,k = Table.find_largest(t2)
    assert((v=='e') and (k==3))
    
    local t3 = {'a','b','e','d','c'}
    local v,k = Table.find_largest(t3,function(a,b) return a<b end)
    assert((v=='a') and (k==1))
    end
    
  -- Table.find_value
  do
    local t1 = tbl1()
    assert(true  == not not Table.find(t1,'a'))
    assert(true  == not not Table.find(t1, 5 ))
    assert(false == not not Table.find(t1,'z'))
    assert(false == not not Table.find(t1, 42))
    end
  
  -- Table.next_value, Table.first_value
  do
    local t1 = {'a'}
    -- uncertain testability of (t1,start_key) due to undefined pairs order
    assert('a' == Table.next_value (t1,nil))
    assert('a' == Table.first_value(t1    ))
    end
    
  -- Table.set, Table.get, Table.sget
  do
    local t1 = {}
    local t2 = {}
    local p1 = {'a','b','c'}
    local p2 = {'e','f','g'}
    local val = {}
    
    --set
    Table.set(t1,p1,42)
    assert(equ(t1,{a={b={c=42}}})) -- set constructs subtables
    --sget
    Table.sget(t2,p2,42)
    assert(equ(t2,{e={f={g=42}}}))
    --get
    assert(42 == Table.get(t1,p1))
    --return/delete
    assert(val == Table.set(t1,p1,val)) --set returns value
    assert(nil == Table.set(t1,p1,nil)) --set can delete
    assert(nil == Table.get(t1,p2    )) --non-existant path is nil
    assert(55  == Table.get(t1,p2,55 )) --nil means default
    
    assert(equ(t1,{a={b={}}})) 
    
    assert(nil == Table. get(t1,p2    ))
    assert(val == Table.sget(t1,p2,val)) --sget sets empty
    assert(val == Table. get(t1,p2,val))
    assert(val == Table.sget(t1,p2,' ')) --sget does not overwrite existing
    
    assert(nil == Table. set(t1,p2,Table.NIL)) -- NIL is nil
    assert(nil == Table. get(t1,p2    ))
    end
    
  -- Table.patch
  do
    local test = {one = 1}
    Table(test)
      :patch({{'two',value=2}})
    assert(test:to_string() == '{one = 1, two = 2}')
    test:patch({
      {'deeper','one',value={self=true,copy=true,'one'}},
      {'deeper','two',value={self=true,copy=true,'two'}},
      })
    assert(test:to_string() == '{deeper = {one = 1, two = 2}, one = 1, two = 2}')
    
    local test2 = Table({a = test})
    test2:patch{ {'b',value={self=true,copy=true,'a'} } }
    assert(test2.a ~= test2.b) -- copy
    assert(equ(test2.a,test2.b))
    test2:patch{ {'b',value={self=true,copy=false,'a'} } }
    assert(test2.a == test2.b) --reference
    assert(equ(test2.a,test2.b))
    end
    
  -- Table.map
  do    
    local t1 = {1,2,3}
    local t2 = Table.map(t1,L['v,k->2*v,2*k'],{})
    assert(t1 ~= t2) -- copy with new keys
    assert(equ(t2,{[2]=2,[4]=4,[6]=6}))
    
    assert(equ(Table.map(t1,L['x->2*x']),{2,4,6})) -- in-place
    assert(equ(Table.map(t1,L['x->2*x'],{}),{4,8,12})) -- copy with old keys
    assert(equ(t1,{2,4,6}))
    end
    
  -- Table.filter
  do
    local t1 = {1,2,3,4}
    assert(equ(Table.filter(t1,L['x->x%2==0'],{}),{nil,2,nil,4}))
    assert(equ(Table.filter(t1,L['x->x   <3'],{}),{1,2,nil,nil}))
    assert(equ(Table.filter(t1,L['x->x  >=3'],{}),{nil,nil,3,4}))
    assert(equ(t1,{1,2,3,4})) -- copy mode did not change table
    assert(Table(t1):filter(L'-> nil'):is_empty())
    end
    
  -- Table.smerge
  do
    local t1 = {'a',nil,'b'}
    local t2 = {nil,'b','c'}
    -- assert(Table.smerge(t1,t2):is_equal{'a','b','c'})
    assert(Table(t1):smerge(t2):is_equal{'a','b','c'})
    end
    
  -- Table.insert_once
  do
    local t1 = {}
    assert(t1 == Table.insert_once(t1,'foo','bar'))
    assert(t1.foo == 'bar')
    assert(Table(t1):insert_once('notfoo','bar'):is_equal{foo='bar'})
    end
  
  -- Table.clear  
  do
    assert(false == Table(tbl1())        :is_empty())
    assert(true  == Table(tbl1()):clear():is_empty())
    local t3 = {'a','b','c','d','e'}
    local t4 = {a=1,b=2,c=3,d=4,e=5}
    assert(equ(t3, Table.clear(tbl1(), {1,2,3,4,5}, nil  ))) -- whitelist
    assert(equ(t3, Table.clear(tbl1(), {1,2,3,4,5}, true ))) -- whitelist
    assert(equ(t4, Table.clear(tbl1(), {1,2,3,4,5}, false))) -- blacklist
    end
    
  -- Table.overwrite
  do
    local t1 = {1,2,3}
    local t2 = {'a','b','c'}
    assert(Table(t1):overwrite(t2):is_equal{'a','b','c'})
    assert(t1 ~= t2)
    assert(equ(t1,{'a','b','c'}))
    end
    
  -- Table.migrate
  do
    local my_data = {
      ['Peter'] = {  
        name = 'Peter',  
        },  
      ['Paula'] = {  
        _version = 1,  
        value = 12,  
        givenname = 'Paula',  
        }  
      }  
        
    local my_migrations = {  
      [1] = function(data)  
        data.givenname = data.name  
        data.name      = nil   
        data.value     = 1
        data._version  = 42 -- this has no effect  
        end,  
      [2] = function(data,index,tbl,bonus,superbonus)  
        tbl[index] = {  
          gnam = data.givenname or index,  
          val  = data.value + bonus + (superbonus or 0)  
          }  
        end,  
      }  
    
    for k,_ in pairs(my_data) do  
      Table.migrate(my_data,k,my_migrations,30)  
      end  
    Table.migrate(my_data,'Alex',my_migrations,0,9000)
    assert(equ(my_data,{
      Paula = {_version = 2, gnam = "Paula", val = 42},
      Peter = {_version = 2, gnam = "Peter", val = 31},
      Alex  = {_version = 2, gnam = "Alex", val = 9001}, -- plus 1 from migration [1]
      }))
    end
    
  -- Table.scopy, Table.dcopy, Table.fcopy
  do
    local t1 = {a = {z = 42}}
    local t2 = {b = t1, c = t1, d = t1}
    
    local s = Table.scopy(t2)
    local d = Table.dcopy(t2)
    local f = Table.fcopy(t2)
    
    -- can copy non-tables
    assert('five' == Table.scopy('five'))
    assert('five' == Table.dcopy('five'))
    assert('five' == Table.fcopy('five'))
    
    -- scopy preserves identity
    assert(t1 == s.b)
    assert(t1 == s.c)
    assert(t1 == s.d)
    
    -- dcopy destroys identity but preserves internal structure
    assert(t1  ~= d.b)
    assert(t1  ~= d.c)
    assert(t1  ~= d.d)
    assert(d.b == d.c)
    assert(d.b == d.d)
    
    -- fcopy preserves nothing
    assert(t1  ~= f.b)
    assert(t1  ~= f.c)
    assert(t1  ~= f.d)
    assert(d.b ~= f.c)
    assert(d.b ~= f.d)
    
    -- does not copy factorio objects
    if flag.IS_FACTORIO and _ENV.game then
      
      local t3 = {a={b={c=game}}}
      
      assert(t3.a.b.c == Table.scopy(t3).a.b.c)
      assert(t3.a.b.c == Table.dcopy(t3).a.b.c)
      assert(t3.a.b.c == Table.fcopy(t3).a.b.c)
    
      assert(game == Table.scopy(game))
      assert(game == Table.fcopy(game))
      assert(game == Table.dcopy(game))

      say('  TESTR  @  erlib.Table → Ok (s/d/f copy of factorio objects)')
      end
    
  
    end
    
  -- Table.set_metamethod, Table.get_metamethod
  do
    local fni  = function(self,k,v) rawset(self,k,'new1') end
    local fni2 = function(self,k,v) rawset(self,k,'new2') end
    local fi   = function() return 'empty' end
    
    local t1 = {}
    -- no table is nil
    assert(nil == Table.get_metamethod(t1,'__index'))
    -- table return
    assert(t1 == Table.set_metamethod(t1,'__index',fi))
    assert(t1 == Table.set_metamethod(t1,'__newindex',fni))
    -- overwriting methods
    assert(fni  == Table.get_metamethod(t1,'__newindex'))
    assert(t1   == Table.set_metamethod(t1,'__newindex',fni2))
    assert(fni2 == Table.get_metamethod(t1,'__newindex'))
    -- methods themselfs are correctly attached
    t1.a = 5
    assert(t1.a == 'new2')
    assert(t1.b == 'empty')
    end
    
  -- Table.deep_clear_metatables
  do
    local test = setmetatable({},{
      __index = function() return 1 end,
      })
    -- recursive
    test.test = test
    -- different
    test.foo  = setmetatable({},{
      __index = function() return 2 end,
      })
    
    local x = test['asdf']
    assert(x == 1)
    local x = test.foo['asdf']
    assert(x == 2)
    
    Table.deep_clear_metatables(test)

    local x = test[1]
    assert(x == nil)
    local x = test.test[1]
    assert(x == nil)
    local x = test.foo[1]
    assert(x == nil)
    end
    
  -- Table.normalizer, Table.remapper
  do
  
    local my_norm = Table.normalizer{name='no name',value=0}
    assert('{name = "testrr", value = 0}' == Table(my_norm{name='testrr'}):to_string())
        
    local my_remapper1 = Table.remapper {name='surname',value={'cur','act'}}
    local test_person1 = {name='Adicator',value=42}
    assert(equ(my_remapper1(test_person1),{act = 42, cur = 42, surname = "Adicator"}))

    -- with tables as keys
    local my_remapper2 = Table.remapper({name='surname',value={'cur','act'}},true)
    local test_person2 = {name='Bdicator',value=42}
    
    -- tables-as-keys are difficult to compare, and pairs order is undefined...
    for k,v in pairs(my_remapper2(test_person2)) do
      if k == 'surname' then 
        assert(v == "Bdicator")
      else
        assert(v == 42)
        assert(k[1] == 'cur')
        assert(k[2] == 'act')
        end
      end
      
    end
  
    
  say('  TESTR  @  erlib.Table → Ok')
  end


-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.test_Table') end
return function() return Test, {'lua','settings','data_final_fixes','control'} end
