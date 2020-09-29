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

local Array = elreq('erlib/lua/Array')()

-- -------------------------------------------------------------------------- --
-- Tests                                                                      --
-- -------------------------------------------------------------------------- --

local function Test()

  --                                     1   2   3   4   5   6   7   8   9   10  11  12  13
  local function make_dense  () return {'a','b','c','d','e','f','g','h','i','j','k','l','m'} end
  local function make_sparse () return {nil,nil,nil,nil,nil,'f','g','h','i',nil,'k','l','m'} end
  
  -- Are two arrays equal?
  local function equ(a,b)
    for i=1,13 do -- hardcoded range for this test
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

  -- Array.try_unique_insert
  do
    local test1 = Array.compress(make_dense(),{},1,6)
    local test2 = Array.compress(make_dense(),{},1,7)
    
    local arr,changed = Array.try_unique_insert(test1,'g')
    assert(test1 == arr)
    assert(equ(test1,test2))
    assert(changed == true)
    assert(7 == Array.size(test1))
    
    local arr,changed = Array.try_unique_insert(test1,'g')
    assert(test1 == arr)
    assert(equ(test1,test2))
    assert(changed == false)
    assert(7 == Array.size(test1))
    assert(7 == #test1)
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
    local dense = make_dense()
    Array(dense):unsorted_remove_key(4):unsorted_remove_key(7)
    -- correct swapping
    assert(equ({'a','b','c',"m",'e','f',"l",'h','i','j','k'},dense))
    -- return value + don't remove after the end
    assert(equ({'a','b','c',"m",'e','f',"l",'h','i','j','k'},Array(dense):unsorted_remove_key(14)))
    end
  
  -- Array.scopy
  do
    local dense = make_dense()
    local copy  = Array(dense):scopy()
    assert(dense ~= copy)
    assert(equ(dense,copy))
    assert(13 == copy:size())
    end
  
    
  say('  TESTR  @  erlib.Array → Ok')
  end


-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.test_Array') end
return function() return Test, {'lua','settings','data_final_fixes','control'} end
