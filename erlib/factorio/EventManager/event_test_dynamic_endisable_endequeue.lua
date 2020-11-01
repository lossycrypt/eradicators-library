-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Description is ignored for submodules.
--
-- @{Introduction.DevelopmentStatus|Module Status}: Work in progress.
--
-- @module EventManager

-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --

local log  = elreq('erlib/lua/Log'  )().Logger  'EventManager'
-- local stop = elreq('erlib/lua/Error')().Stopper 'EventManager'

-- local Verificate = elreq('erlib/lua/Verificate')()
-- local Verify           , Verify_Or
--     = Verificate.verify, Verificate.verify_or

-- local Tool       = elreq('erlib/lua/Tool'      )()

local Table      = elreq('erlib/lua/Table'     )()
-- local Array      = elreq('erlib/lua/Array'     )()
-- local Set        = elreq('erlib/lua/Set'       )()



-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --
-- This file is required by EventManager itself,
-- thus loading of EventManager is not finished when
-- this file called and EventManager can not be
-- require()'ed, because that would create a circular
-- dependency.
--
-- This also ensures that the calling mod is the only
-- one require()'ing EventManager and thus avoids
-- different "path" strings causing package.loaded to
-- be unable to catch the subsequent require calls.
--
return function (EventManager)


  -- ------------------------------------------------------------------------ --
  -- test_dynamic_endisable_endequeue                                                                  --
  -- ------------------------------------------------------------------------ --

  ----------
  -- Custom Event Description
  --
  -- @within Built-in Custom Events
  -- @table test_dynamic_endisable_endequeue

  EventManager.new_handler {
    name = 'test ticker',
    defines.events.on_tick,
    period = 67,
    enabled = false,
    function(tick)
      log:say('ticked!',tick)
      end
    }
    
  EventManager.new_handler {
    name = 'build tester',
    defines.events.on_built_entity,
    function(e)
      log:say('built! ',e.created_entity,e.created_entity.name)
      
      if e.created_entity.type == 'assembling-machine' then
        EventManager.disable('test ticker')
        EventManager.enqueue(1,'test action',1,2,3,{['4']=5})
        EventManager.enqueue(2,'test action',1,2,3,{['4']=5})
        EventManager.enqueue(3,'test action',1,2,3,{['4']=5})
        EventManager.enqueue(4,'test action',1,2,3,{['4']=5})
        EventManager.enqueue(Table.range(5,9),'test action')
        
        EventManager.dequeue('test action',game.tick+2,game.tick + 10)
        EventManager.enqueue(120,'test action',1,2,3,{['4']=5})
      else
        EventManager.enable('test ticker')
        end
      end,
    }
    
  EventManager.new_handler {
    'action',
    name = 'test action',
    function(tick,...)
      log:say('delayed test action! ',...)
      end,
    }

  

-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → event.test_dynamic_endisable_endequeue') end
end

