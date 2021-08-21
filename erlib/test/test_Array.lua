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

local Array = elreq('erlib/lua/Array')()
local Table = elreq('erlib/lua/Table')()
local Iter  = elreq('erlib/lua/Iter/!init' )()

-- -------------------------------------------------------------------------- --
-- Tests                                                                      --
-- -------------------------------------------------------------------------- --

local function Test()

  -- fake array to latest test which methods were never called
  -- local RealArray = Array
  -- local Array = setmetatable({},{
  --   __index=function(self,key); local f = RealArray[key]; self[key] = f; return f; end,
  --   __call =function(_   ,key); return RealArray(key) end,
  --   })

  --                                     1   2   3   4   5   6   7   8   9   10  11  12  13
  local function make_dense  () return {'a','b','c','d','e','f','g','h','i','j','k','l','m'} end
  local function make_sparse () return {nil,nil,nil,nil,nil,'f','g','h','i',nil,'k','l','m'} end
  
  -- Are two arrays equal?
  local function equ(a,b)
    for i=1,15 do -- hardcoded range for this test
      if a[i] ~= b[i] then return false end
      end
    return true
    end
    
  
  -- Array.size
  do
    local dense  = make_dense()
    local sparse = make_sparse()
    assert(13 == Array.size(sparse))
    assert(13 == Array.size(dense ))
    assert(13 == #dense)
    -- assert( 0 == #sparse) -- undefined behavior
    
    assert(0  == Array.size{})
    end
  
  -- Array.first_gap
  do
    assert(5    == Array.first_gap(make_sparse(),5))
    assert(10   == Array.first_gap(make_sparse(),6))
    assert(14   == Array.first_gap(make_dense ()  ))
    -- is end of float range precise?
    assert(nil  == ({[2^53-1] = 'a'})[2^53  ])
    assert('a'  == ({[2^53-1] = 'a'})[2^53-1])
    assert(nil  == ({[2^53-1] = 'a'})[2^53-2])
    -- is end of float range safe?
    assert(2^53 == Array.first_gap({[2^53-1] = 'a'},2^53-1)) -- end of double-precision float range.
    assert(nil  == Array.first_gap({[2^53  ] = 'a'},2^53  )) -- out of range.
    end
  
  -- Array.find, Array.find_all
  do
    local dense = make_dense()
    local test  = {'a','a','a','a','a'}
    assert(6   == Array(dense):find('f'))
    assert(13  == Array(dense):find('m'))
    assert(nil == Array(dense):find('nope'))
    
    assert(nil == Array(dense):find('m',4,9))
    assert(3   == Array(dense):find('c',2,9))
    
    assert(equ({1,2,3,4,5},Array(test):find_all('a')))
    assert(equ({3,4,5},Array(test):find_all('a',3,5)))
    assert(equ({},Array(test):find_all('b')))
    
    end
  
  -- Array.compress
  do
    local dense  = make_dense()
    local sparse = make_sparse()
    local cmp_dense = Array.compress(dense,{}) --*new* array
    local cmp_sparse = Array.compress(sparse,{})
    -- copy
    assert(dense ~= cmp_dense) -- unchanged original? (4 lines)
    assert(equ(dense,make_dense()))
    assert(sparse ~= cmp_sparse)
    assert(equ(sparse,make_sparse()))

    assert(equ(dense,cmp_dense)) -- uncompressible
    assert(equ({'f','g','h','i','k','l','m'},cmp_sparse))
    assert(13 == #cmp_dense)
    assert(13 == Array.size(cmp_dense))
    assert(7 == #cmp_sparse)
    assert(7 == Array.size(cmp_sparse))
    
    -- partial copy
    local cmp_sparse_part = Array.compress(sparse,{},4,11)
    assert(cmp_sparse_part ~= sparse)
    assert(equ(cmp_sparse_part,{nil,nil,nil,'f','g','h','i','k'}))
    
    -- in-place
    assert(dense == Array.compress(dense))
    assert(equ(dense,cmp_dense))
    assert(sparse == Array.compress(sparse))
    assert(equ(sparse,cmp_sparse))
    end
    
  -- Array.map
  do
    local dense  = make_dense()
    local sparse = make_sparse()
    local f = function(x) return x and x..x or '' end
    
    local dense_map_copy_full  = Array.map(dense ,f,{}     )
    local dense_map_copy_part  = Array.map(dense ,f,{},4,11)
    local sparse_map_copy_full = Array.map(sparse,f,{}     )
    local sparse_map_copy_part = Array.map(sparse,f,{},4,11)
    
    -- original unchanged?
    assert(dense  ~= dense_map_copy_full )
    assert(dense  ~= dense_map_copy_part )
    assert(sparse ~= sparse_map_copy_full)
    assert(sparse ~= sparse_map_copy_part)
    
    -- expected result?
    local A = {'aa','bb','cc','dd','ee','ff','gg','hh','ii','jj','kk','ll','mm'}
    local B = { nil, nil, nil,'dd','ee','ff','gg','hh','ii','jj','kk'}
    local C = {  '',  '',  '',  '',  '','ff','gg','hh','ii',  '','kk','ll','mm'}
    local D = { nil, nil, nil,  '',  '','ff','gg','hh','ii',  '','kk'}
    assert(equ(dense_map_copy_full  ,A))
    assert(equ(dense_map_copy_part  ,B))
    assert(equ(sparse_map_copy_full ,C))
    assert(equ(sparse_map_copy_part ,D))
    
    -- in-place change
    assert(dense  == Array.map(dense ,f,nil,4,11))
    assert(sparse == Array.map(sparse,f,nil,4,11))
    assert(equ(dense ,{"a", "b", "c","dd","ee","ff","gg","hh","ii","jj","kk","l","m"}))
    assert(equ(sparse,{nil, nil, nil,  "",  "","ff","gg","hh","ii",  "","kk","l","m"}))
    end

  -- Array.filter
  do
    local dense  = make_dense()
    local sparse = make_sparse()
    local f = function(x) return x and x > 'g' end
    
    local dense_filter_copy_full  = Array.filter(dense ,f,{}     )
    local dense_filter_copy_part  = Array.filter(dense ,f,{},4,11)
    local sparse_filter_copy_full = Array.filter(sparse,f,{}     )
    local sparse_filter_copy_part = Array.filter(sparse,f,{},4,11)
    
    -- original unchanged?
    assert(dense  ~= dense_filter_copy_full )
    assert(dense  ~= dense_filter_copy_part )
    assert(sparse ~= sparse_filter_copy_full)
    assert(sparse ~= sparse_filter_copy_part)

    -- expected result?
    local A = {'h','i','j','k','l','m'}
    local B = {nil,nil,nil,'h','i','j','k'}
    local C = {'h','i','k','l','m'}
    local D = {nil,nil,nil,'h','i','k'}
    assert(equ(dense_filter_copy_full  ,A))
    assert(equ(dense_filter_copy_part  ,B))
    assert(equ(sparse_filter_copy_full ,C))
    assert(equ(sparse_filter_copy_part ,D))
    
    -- in-place change
    assert(dense  == Array.filter(dense ,f,nil,4,11))
    assert(sparse == Array.filter(sparse,f,nil,4,11))
    assert(equ(dense ,{"a", "b", "c", "h", "i", "j", "k", nil, nil, nil, nil, "l", "m"}))
    assert(equ(sparse,{nil, nil, nil, "h", "i", "k", nil, nil, nil, nil, nil, "l", "m"}))
    end

  -- Array.reverse
  do
    local dense  = make_dense()
    local sparse = make_sparse()
    
    local dense_reverse_copy_full  = Array.reverse(dense ,{}     )
    local dense_reverse_copy_part  = Array.reverse(dense ,{},4,11)
    local sparse_reverse_copy_full = Array.reverse(sparse,{}     )
    local sparse_reverse_copy_part = Array.reverse(sparse,{},4,11)
    
    -- original unchanged?
    assert(dense  ~= dense_reverse_copy_full )
    assert(dense  ~= dense_reverse_copy_part )
    assert(sparse ~= sparse_reverse_copy_full)
    assert(sparse ~= sparse_reverse_copy_part)
    
    -- expected result?
    local A = {"m","l","k","j","i","h","g","f","e","d","c","b","a"}
    local B = {[4]="k",[5]="j",[6]="i",[7]="h",[8]="g",[9]="f",[10]="e",[11]="d"}
    local C = {"m","l","k",nil,"i","h","g","f"}
    local D = {[4]="k",[6]="i",[7]="h",[8]="g",[9]="f"}
    assert(equ(dense_reverse_copy_full  ,A))
    assert(equ(dense_reverse_copy_part  ,B))
    assert(equ(sparse_reverse_copy_full ,C))
    assert(equ(sparse_reverse_copy_part ,D))
    
    -- in-place change
    assert(dense  == Array.reverse(dense ,nil,4,11))
    assert(sparse == Array.reverse(sparse,nil,4,11))
    assert(equ(dense ,{'a','b','c',"k","j","i","h","g","f","e","d",'l','m'}))
    assert(equ(sparse,{nil,nil,nil,"k",nil,"i","h","g","f",nil,nil,'l','m'}))
    end

  -- Array.deduplicate
  do
    local equ = Table.is_equal
    local f1 = function() return {1,2,3,4,1,2,3,4,5} end
    local f2 = function() return {'a',nil, 'a', nil, 'b'} end
    local f3 = function() local a, b = f1(), f2() return {a, b, a, b} end
    local t1, t2, t3 = f1(), f2(), f3()
    
    -- full copy mode
    assert(equ(Array.deduplicate(t1, nil, {}), {1,2,3,4,5}))
    assert(equ(Array.deduplicate(t2, nil, {}), {'a', 'b'}))
    assert(equ(Array.deduplicate(t3, nil, {}), {t1 , t2 }))
    assert(equ(Array.deduplicate(t3, nil, {}), {f1(), f2()}))
    
    -- partial copy mode
    assert(equ(Array.deduplicate(t1, nil, {}, 4   ), {4,1,2,3,5   }))
    assert(equ(Array.deduplicate(t2, nil, {}, 1, 3), {'a'         }))
    assert(equ(Array.deduplicate(t3, nil, {}, 2, 4), {f2() , f1() }))
    
    -- did copy change original?
    assert(equ(t1, f1()))
    assert(equ(t2, f2()))
    assert(equ(t3, f3()))
    
    -- partial in-place mode
    assert(equ(Array.deduplicate(f1(), nil, nil, 2, 6 ), {1,2,3,4,1,nil,3,4,5}))
    assert(equ(Array.deduplicate(f2(), nil, nil, 2, 10), {'a','a','b'        }))
    assert(equ(Array.deduplicate(f3(), nil, nil, 2,  0), {f1(),f2(),f1(),f2()}))
    assert(equ(Array.deduplicate(f3(), nil, nil, 2    ), {f1(),f2(),f1()     }))
    
    -- full in-place mode
    Array.deduplicate(t1) assert(equ(t1, {1,2,3,4,5}))
    Array.deduplicate(t2) assert(equ(t2, {'a', 'b' }))
    Array.deduplicate(t3) assert(equ(t3, {f1() , f2()}))
    
    -- f_ident
    local a  = { {a=2}, {a=3}, {a=2}, {b=4, a=2} }
    local ar = { {a=2}, {a=3} }
    local af = function(v) return v.a end
    assert(equ(Array.deduplicate(a, af), ar)); assert(equ(a, ar)) -- in-place!
    end
    
  -- Array.insert_once
  do
    local test1 = Array.compress(make_dense(),{},1,6)
    local test2 = Array.compress(make_dense(),{},1,7)
    
    local arr,changed = Array.insert_once(test1,'g')
    assert(test1 == arr)
    assert(equ(test1,test2))
    assert(changed == true)
    assert(7 == Array.size(test1))
    
    local arr,changed = Array.insert_once(test1,'g')
    assert(test1 == arr)
    assert(equ(test1,test2))
    assert(changed == false)
    assert(7 == Array.size(test1))
    assert(7 == #test1)
    end
    
  -- Array.insert_array
  do
    local equ = Table.is_equal
  
    local r1 = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, [20] = "b"}
    local r2 = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    
    local t1,t2 = {1,5,6,7,8,9,10},{2,3,4}
    
    -- with target
    assert(equ(r1, Array.insert_array({1,5,6,7,8,9,10},{2,3,4},2,{[20]='b'}) )) -- #arr > #arr2
    assert(equ(r1, Array.insert_array({1,10},{2,3,4,5,6,7,8,9},2,{[20]='b'}) )) -- #arr < #arr2
    assert(equ(t1,{1,5,6,7,8,9,10}))
    assert(equ(t2,{2,3,4}))
    
    -- in-place
    Array.insert_array(t1,t2,2)
    assert(equ(t1,r2))
    assert(equ(t2,{2,3,4}))
    end
    
  -- Array.unsorted_remove_value
  do
    local test = {'a','b','a','b','a','b','a','b','a'}
    
    local arr,count = Array.unsorted_remove_value(test,'b')
    assert(test == arr  )
    assert(equ({'a','a','a','a','a'},test))
    assert(4    == count)
    assert(5    == Array(test):size())
    
    local arr,count = Array.unsorted_remove_value(test,'c')
    assert(test == arr  )
    assert(equ({'a','a','a','a','a'},test))
    assert(0    == count)
    assert(5    == Array(test):size())
    
    local arr,count = Array.unsorted_remove_value(test,'a')
    assert(test == arr  )
    assert(5    == count)
    assert(0    == Array(test):size())
    end
  
  -- Array.unsorted_remove_key
  do
    local dense = Array(make_dense())
    -- return value
    assert('d' == dense:shuffle_pop(4))
    assert('g' == dense:shuffle_pop(7))
    -- correct swapping
    assert(equ({'a','b','c',"m",'e','f',"l",'h','i','j','k'},dense))
    -- correct removal of last key
    local dense = Array(make_dense())
    dense:shuffle_pop(#dense)
    assert(equ({'a','b','c','d','e','f','g','h','i','j','k','l'},dense))
    for i=#dense, 1, -1  do
      assert(i   == #dense)
      assert(dense[i] == dense:shuffle_pop(i))
      assert(i-1 == #dense)
      end
    -- must produce empty table
    assert(equ({}, dense))
    end
  
  -- Array.scopy
  do
    local dense = make_dense()
    local copy  = Array(dense):scopy()
    assert(dense ~= copy)
    assert(equ(dense,copy))
    assert(13 == Array.size(copy))
    end
  
  -- Array.keys, Array.values
  do
    local sparse = make_sparse()
    
    local keys = Array(sparse):keys(nil,13)
    assert(equ(keys,{6,7,8,9,11,12,13}))
    
    local values = Array(sparse):values(3,11)
    assert(equ(values,{'f','g','h','i','k'}))

    -- any dense array is tautologically the value array of itself
    assert(equ(make_dense(),Array.values(make_dense())))
    end

  -- Array.clear
  do
    local dense = make_dense()
    local clear = Array.clear(dense)
    --full
    assert(clear == dense)
    assert(equ({},clear))
    assert(0 == Array.size(clear))
    --partial
    assert(equ({'a','b','c','d',nil,nil,nil,nil,nil,'j','k','l','m'},
      Array.clear(make_dense(),5,9)))
    end
    
  -- Array.extend
  do
    local test = Array{}
    local test2 = test
      :extend {'a','b','c'}
      :extend({'a','b','c','d','e','f','g','h','i','j','k','l','m'}, 4, 7)
      :extend({'a','b','c','d','e','f','g','h','i','j','k','l','m'}, 8,12)
      :extend({'a','b','c','d','e','f','g','h','i','j','k','l','m'},13,13)
    assert(equ(make_dense(),test2))
    assert(test,test2)
    end
    
  -- Array.splice, Array.fray
  do
    local spliced_array = Array(Array.splice({1,2,3},42,{'a','b','c'},nil,'end'))
    assert( spliced_array:to_string()
      == '{1, 42, "a", nil, "end", 2, 42, "b", nil, "end", 3, 42, "c", [15] = "end"}' )
      
    assert( Array(spliced_array:fray(5,1,15)):to_string()
      == '{{1, 2, 3}, {42, 42, 42}, {"a", "b", "c"}, {}, {"end", "end", "end"}}' )
      
    assert(equ(spliced_array, Array.splice(table.unpack(spliced_array:fray(5,1,15)))))
    end

  -- Array.flatten
  do
    local t = {{{{}}},1,2,{3,4,{5,6},{7}},8,{{{{9,{{10}}}}}}}
    Array.flatten(t)
    assert(equ(t,{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}))
    end
    
  -- Array.from_iterator
  do
    local equ = Table.is_equal
    
    local arr,n = Array.from_iterator(function()end)
    assert(n == 0)
    assert(equ(arr,{}))
    
    local arr,n = Array.from_iterator(Iter.subsets(3,{1,2,3,4,5,6}))
    assert(n == 20)
    assert(equ(arr,{
      {{1, 2, 3}},
      {{1, 2, 4}},
      {{1, 2, 5}},
      {{1, 2, 6}},
      {{1, 3, 4}},
      {{1, 3, 5}},
      {{1, 3, 6}},
      {{1, 4, 5}},
      {{1, 4, 6}},
      {{1, 5, 6}},
      {{2, 3, 4}},
      {{2, 3, 5}},
      {{2, 3, 6}},
      {{2, 4, 5}},
      {{2, 4, 6}},
      {{2, 5, 6}},
      {{3, 4, 5}},
      {{3, 4, 6}},
      {{3, 5, 6}},
      {{4, 5, 6}}
      }))
    end
    
    
    
    
    
    
    
    
    
    
  -- check which methods were not called
  -- setmetatable(Array,nil)
  -- local missing = {}
  -- for k in pairs(RealArray) do if not Array[k] then missing[#missing+1] = k end end
  -- say(('Untested methods: %s'):format(table.concat(missing,',')))
    
  say('  TESTR  @  erlib.Array → Ok')
  end


-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.test_Array') end
return function() return Test, {'lua','settings','data_final_fixes','control'} end
