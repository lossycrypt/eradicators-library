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

local Cache = elreq('erlib/factorio/Cache')()
local Lambda = elreq('erlib/lua/Lambda')()

-- -------------------------------------------------------------------------- --
-- Tests                                                                      --
-- -------------------------------------------------------------------------- --

local function Test()

  --TickedCache
  if (flag.IS_FACTORIO and phase.control) then
    say('  TESTR  @  erlib.Cache.TickedCache → Skipped. (not at runtime)')
  else
  
    _ENV.game = {tick = 1} -- fake tick
    local content = {'one','two','three',name='foo',type='bar'}
    local TC = Cache.TickedCache()
    
    -- __newindex
    for k,v in pairs(content) do TC[k] = v end
    
    -- __pairs, __index
    for k,v in pairs(TC) do
      assert(TC[k] == content[k])
      assert(   v  == content[k])
      end
    
    -- delete
    TC.type = nil
    assert(TC.type == nil)
    
    -- __len, size
    assert(#TC == 3)
    assert(TC:size() == 4)
    assert(TC:is_empty() == false)
    
    -- decaying
    _ENV.game.tick = 2
    assert(TC:is_empty() == true)
    
    -- inverse content
    for k,v in pairs(content) do TC[v] = k end
    
    -- table.insert
    TC:insert(1,'Eins')
    assert(TC[1] == 'Eins')
    TC:insert('Zwei')
    assert(TC[2] == 'Zwei')
    
    -- table.remove
    assert(TC:remove(1) == 'Eins')
    assert(TC[1] == 'Zwei')
    assert(TC:remove() == 'Zwei')
    assert(#TC == 0)
    assert(TC:size() == 5)
    
    -- map
    TC:map(Lambda'v,k->k,v') -- undo inversion
    for k,v in pairs(TC) do
      assert(TC[k] == content[k])
      assert(   v  == content[k])
      end
    
    _ENV.game = nil
    say('  TESTR  @  erlib.Cache.TickedCache → Ok.')
    end
    
    

  
  
  say('  TESTR  @  erlib.Cache.AutoCache → not implemented')
  end


-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.test_Cache') end
return function() return Test, {'lua','settings','data_final_fixes','control'} end
