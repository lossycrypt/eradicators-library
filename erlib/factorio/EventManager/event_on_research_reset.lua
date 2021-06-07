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
-- Eradicators Library                                                        --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --

-- local log  = elreq('erlib/lua/Log'  )().Logger  'EventManager'
-- local stop = elreq('erlib/lua/Error')().Stopper 'EventManager'

-- local Verificate = elreq('erlib/lua/Verificate')()
-- local Verify           , Verify_Or
--     = Verificate.verify, Verificate.verify_or

-- local Tool       = elreq('erlib/lua/Tool'      )()

-- local Table      = elreq('erlib/lua/Table'     )()
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
  -- Template                                                                  --
  -- ------------------------------------------------------------------------ --

  -- -------
  -- Custom Event Description
  --
  -- @table Template
  
  
  EventManager.new_handler {
    '',
    function (e)
      end
    }
  
  ----------
  -- Raised when the researched state of a technology has changed from true to
  -- false. For example because another mod called @{FOBJ LuaForce.reset}.
  -- 
  -- @tfield LuaTechnology research
  --
  -- @table on_research_reset
  --
  new_uid 'on_research_reset'

-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → event.Template') end
end

