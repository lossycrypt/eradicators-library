-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Multiple handlers per event and easy future actions.
--
-- __Note:__ EventManager is incompatible with mods that directly access
-- @{FOBJ LuaBootstrap}. To ensure smooth operations it replaces `script`
-- with a wrapper that behaves like the real script as close as possible,
-- but not all functionality is available (yet). Keeping local references
-- to `script` is not supported.
--
-- __Note:__ EventManager stores it's private data in __global.event_manager__.
-- Messing with that data will break EventManager.
--
-- Quirks, Tips and Tricks:
-- 
--   * OnTick handlers can not be executed in a guaranteed order, as the order
--   depends on each handlers period, last execution and en/disable history.
--
--   * Only actions take extra queue arguments, but normal handlers can be
--   @{EventManager.call|called} with extra arguments.
--
--   * OnTicks can not be registered to multiple events.
--
--   * Actions use en/dequeue. OnTicks use en/disable.
--
--
-- @module EventManager
-- @usage
--  local EventManager = require('__eradicators-library__/erlib/factorio/EventManager/EventManager-10')()

--------------------------------------------------------------------------------
-- Todo.
-- @section
--------------------------------------------------------------------------------

----------
-- Continue integration of event-manager-8 from line 1250
--
-- @table todo0
      
----------
-- Replace event groups with stand-alone wrappers that
-- pre-filter and re-structure the event tables.
--
-- Make them "built-in events" inside this file.
--
-- How can that be compatible with event filtering?
-- As long as it does NOT use any C-side calls it should be really
-- cheap to change the table strucuture even for all events that never need it?
--
-- If the wrapper pre-fetches i.e. e.entity_name = entity.name
-- it can significantly speed up the filters after it!
--
-- @table todo1


----------
-- EventManager.new_event_uid
--
-- Possibility to register new custom events.
-- Is that still useful?
--
-- Would be nicer if EventManager stays agnostic and works automatically.
-- This might require auto-detecting valid event names.
--
-- -> get_new_event_uid()
-- Simultaenously creates a new id and makes it available via remote interface.
--
-- @table todo2
  
----------
-- Retro-gen event
-- 
-- starts a series of re-generation chunk events (tick distributed?) to which the mod can then react
-- 
-- last chunk event must carry {e.final=true}
-- 
-- must be different event than normal chunk_generated.
-- 
-- include LuaRendering debug marker? (i.e. a square on the chunk)
-- 
-- (does gui update during tick_paused? can force update one tick -> show progress bar?)
--   
-- @table todo3
  
----------  
-- EventManagerScript.on_event
-- 
-- Add bootstrap one-handler-per-event emulation. (for sudo?)
-- Should automatically work with new immediately registering structure.
-- 
-- just give it a fixed name and overwrite ordered handlers?
-- maybe cleaner with EM.remove_handler.
-- 
-- Needs to call enqueue_new_onticks
-- needs to override .enabled status.
--
-- @table todo4
  
  
----------
-- DebugOncePerLoad Event
-- -> needs EventManager.new_event_name?  .private_event_name?
-- -> needs EventManager.are_there_any_handlers_for_this_event(event_name)
--   to prevent pointlessly registering on_tick when nobody uses it 
-- @table todo5
  

----------  
-- EventManager.supress_logging_event_id(event_uid)
--
-- Selectively disable logging for certain event types?
-- on_tick, on_chunk_generated, etc?
-- @table todo6


----------
-- Change font-size of bootstrap_event_order blocks
-- @table todo7  


----------
-- enqueue should deepcopy/shallow (?) to prevent putting 
-- desync-unsafe table references into args. and prevent
-- putting bullshit like functions into args.
-- @table todo8


----------
-- "Unsafe" mode -> allowing to use new_handler at runtime
-- should be disabled by default and only enabled if explicitly requested.
-- EventManager.allow_runtime_handler_additions()
-- @table todo9
  
--------------------------------------------------------------------------------
-- Concepts.
-- @section
--------------------------------------------------------------------------------

----------
-- The unique identifier of an event.
-- 
-- An event_uid is any @{number} or @{string} that could be used to register
-- an event handler with script.on\_event(event\_uid,handler\_function).
-- 
-- That means any number from @{FAPI defines defines.events},
-- any number generated with script.generate\_event\_name(),
-- any string that is the name of a @{FOBJ LuaCustomInputPrototype},
-- or one of the literal strings
-- `"action"`, `"on_init"`, `"on_load`" and `"on_config`".
-- 
-- @table event_uid
do end

----------
-- A handler subscribed to 'action' instead of to an event.
-- 
-- Actions are event handlers that are registered for the event_uid `"action"`.
-- Actions __do not happen naturally__. Instead they are used with
-- @{EventManager.enqueue} and @{EventManager.dequeue} to manually
-- schedule __future__ script actions that do not depend on events.
-- 
-- @table Action
do end

----------
-- A handler subscribed to defines.events.on_tick.
--
-- OnTick handlers handle __only__ @{FAPI events on_tick}. They can not
-- be subscribed to any other type of event, and __can not be used as actions__.
--
-- @table OnTick
do end

----------
-- A handler subscribed to any event except on_tick.
-- 
-- Can be subscribed to any event type or custom input.
-- Can simultaenously handle multiple event types and __can be used as__
-- @{EventManager.Action|Actions}.
-- 
-- @table NonTick
do end

--------------------------------------------------------------------------------
-- Behavior.
-- See also @{FAPI Data-Lifecycle}.
-- @section
--------------------------------------------------------------------------------

----------
-- What apis are available during on\_init, on\_load and on\_config?
--
-- @usage
--   on_init   : remote commands settings rcon rendering script game
--   on_load   : remote commands settings rcon           script
--   on_config : remote commands settings rcon rendering script game
-- 
-- @table api_availability
do end


--[[------
  In what order do on\_init, on\_load and on\_config happen?

  Base game order:
    InstallMod -> StartMap                         : on_init   -       -        -         -   　
    InstallMod -> StartMap -> SaveMap    -> LoadMap:   -       -     on_load    -         -   　
    InstallMod -> StartMap -> ChangeMod  -> LoadMap:   -       -     on_load  on_config   -   　
    StartMap   -> SaveMap  -> InstallMod -> LoadMap: on_init   -       -      on_config   -   　

  EventManager additionally raises on\_load after each on\_init and on\_config event.
  This way on_load is guaranteed to be executed under all circumstances and can
  be used as a reliable post-processor.
  
  Absurdly the engine raises on\_load* *before* on\_config, running it
  on potentially outdated global data. There's nothing I can do about that
  so you have to take countermeasures yourself. EventManager will however
  skip that on\_load* event if it's own global data needs to be updated first.
  
  EventManager order:
    InstallMod -> StartMap                         : on_init+ON_LOAD   -        -         -    
    InstallMod -> StartMap -> SaveMap    -> LoadMap:   -       -     on_load    -         -    
    InstallMod -> StartMap -> UpdateMod  -> LoadMap:   -       -     on_load* on_config+ON_LOAD
    StartMap   -> SaveMap  -> InstallMod -> LoadMap: on_init+ON_LOAD   -      on_config+ON_LOAD
    
 @table boostrap_event_order
--]]
do end


--------------------------------------------------------------------------------
-- Examples.
-- @section
--------------------------------------------------------------------------------

----------
-- @usage
--   -- same basic syntax as script.on_event
--   EventManager.new_handler {
--     defines.events.on_entity_damaged,
--     function(e)
--       game.print{'', 'Entity ', e.entity.name, ' was damaged.'}
--       end
--     }
-- 
-- @usage
--   -- Low level events use string names.
--   -- Multiple events can be registered simultaenously.
--   EventManager.new_handler {
--     {'on_init',    -- script.on_init
--      'on_config'}, -- script.on_configuration_changed
--     function()
--       global.my_mod_data = global.my_mod_data or {}
--       end
--     }
--
-- 
-- 
-- @table Examples
do end
  
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
local stop = elreq('erlib/lua/Error')().Stopper 'EventManager'

local Stacktrace = elreq('erlib/factorio/Stacktrace')()

local Verificate = elreq('erlib/lua/Verificate')()
local Verify           , Verify_Or
    = Verificate.verify, Verificate.verify_or

local Tool       = elreq('erlib/lua/Tool'      )()
    
local Table      = elreq('erlib/lua/Table'     )()
local Array      = elreq('erlib/lua/Array'     )()
local Set        = elreq('erlib/lua/Set'       )()

local Crc32      = elreq('erlib/lua/Coding/Crc32')()

local Cache      = elreq('erlib/factorio/Cache')()

local L          = elreq('erlib/lua/Lambda'    )()


local LuaBootstrap = script

local Table_dcopy
    = Table.dcopy

local setmetatable, pairs, ipairs, select
    = setmetatable, pairs, ipairs, select
    
local table_insert, math_random, math_floor, table_unpack, table_remove
    = table.insert, math.random, math.floor, table.unpack, table.remove
    
local UID_INTERFACE_NAME = 'eradicators-library:custom-event-uids'


-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

-- do
--  Draft: auto fetch correct copy of manager?
-- 
--   -- local this_file_name = Stacktrace.get_file_name(1)
--   -- local this_directory = Stacktrace.get_directory(1)
--   
--   local relative_path = 
--     ( Stacktrace.get_directory(1)
--         :gsub(Stacktrace.get_mod_root(1),'')
--     ..
--       Stacktrace.get_file_name(1)
--       )
--     :gsub('/','.')
--   
--   
--   for path, chunk in pairs(package.loaded) do
--     if path:find(relative_path) then
--       error('found: '..path)
--       end
--     end
-- 
--   end



local EventManager,_EventManager,_uLocale = {},{},{}
local Private = {} -- Not exported to outside scripts.


-- -------------------------------------------------------------------------- --
-- Runtime check                                                              --
-- -------------------------------------------------------------------------- --

if not Stacktrace.get_load_stage().control then
  stop('EventManager only works in control stage.')
  end

if rawget(_ENV,'EVENT_MANAGER_ACTIVE') == nil then
  rawset(_ENV,'EVENT_MANAGER_ACTIVE',true)
else
  stop('EventManager can only be loaded once per mod.')
  end


-- Methods that require write access to global Savedata
-- must be protected from being run before on_load finishes,
-- as they might see the empty invalid global Savedata table,
-- that exists before the game loads the real Savedata
-- into this mods lua state.

-- The "global" table that exists before on_load is garbage.

-- This flag must toggled "true" at the end of 
-- on_init, on_config and on_load.
local isOnLoadFinished = false
local function VerifyIsOnLoadFinished(...)
  if not isOnLoadFinished then
    stop('This method can only be used inside event handlers.\n',...)
    end
  end

-- -------------------------------------------------------------------------- --
-- Savedata                                                                   --
-- -------------------------------------------------------------------------- --

-- Savedata is a local reference to global.event_manager.

local Savedata = nil, {
  -- Real data is linked in on_load.
  -- This is just an mockup.
  Queue          = {},
  handler_status = {},
  -- current_tick   = 0 ,

  simulation = {
    players      = { known_indexes = {} },
    forces       = { known_indexes = {} },
    surfaces     = { known_indexes = {} },
    technologies = {
      force_n_index = {
        researched_uids = {}
        }
      },
    },

  }
  
  
local SavedataMigrations = {
--[[
  Legacy migration archive:

  [1] = function(data)
    Table.clear(data) --fixes old in-dev versions
    data.current_tick          = game.tick
    data.queue                 = {}
    data.disabled_handler_uids = {}
    end,
  [2] = function(data)
    data.skip_simulation_for_these_indexes = {
      on_player_created  = {} ,
      on_force_created   = {} ,
      on_surface_created = {} ,
      }
    end,
--]]

  [3] = function(data)
    -- ErLib 3.x and previous queue uses a different uid-scheme so
    -- the old Queue is useless.
    Table.clear(data)
    data.Queue          = {}
    data.handler_status = {}
    data.simulation     = {}
    end,
  }  

-- -------------------------------------------------------------------------- --
-- Custom Shared Event UIDs                                                   --
-- -------------------------------------------------------------------------- --

Private.event_uid = require('__eradicators-library__/erlib/remote/shared_event_uids')

-- Secure the table against accidential wrong access.
EventManager.event_uid = setmetatable({},{
  __index    = function(_, key)
    return Verify(Private.event_uid[key], 'NaturalNumber', 'Invalid event name: ', key)
    end,
  __newindex = function(_, k, v)
    stop('Can not manually add event id:\n', k, ' = ', v)
    end,
  })


-- -------------------------------------------------------------------------- --
-- Misc / Logging                                                             --
-- -------------------------------------------------------------------------- --

-- {string -> number}
-- local EventNameToUid = Table.scopy(defines.events)

-- {number -> string}
local EventUidToName = setmetatable(
  -- lookup for log messages and printing
  Table.map  (defines.events, L['id,name -> name,id'], {}),
  -- if it's not a defines just return it verbatim
  {__index = function(_,key) return key end}
  )


-- lookup for log messages and printing
local EventUidToName = Table.map(defines.events, L['id,name -> name,id'], {})

-- Fetch custom uids
for name,uid in pairs(Private.event_uid) do EventUidToName[uid] = name end
  
-- if it's not a known number just return it verbatim
setmetatable(EventUidToName, {__index = function(_,key) return key end})



-- -------------------------------------------------------------------------- --
-- OrderedHandlers + script.on_event                                          --
-- -------------------------------------------------------------------------- --

--[[
  Each "Handler" is normalized by EventManager.new_handler
  to this format.
  
  OrderedHandlers has subtables for each event_name, it can thus
  contains several references to the handler table for multi-event handlers.
  
  HandlersBy* directly references each handler table.

  OrderedHandlers[event_name][registration_order] = {
      
      f               =, → function, the handler
      name            =, → non-empty string or nil, includes name_prefix
      log_name        =, → string, guaranteed to exist
      event_uids      =, → Set of {event_uid=true} mappings
      uid             =, → integer, or nil if name is nil
                           OnTick and Action require a uid to be queable
                           so name/uid is mandtory for them.
      
      default_enabled =, → boolean, if the handler is enabled when 
                           Savedata.handler_status[uid] is nil
      enabled         =, → boolean, if the handler is currently enabled
      persistent      =, → boolean, if true the handler can not be disabled
                           
      filter          =, → function or nil, must return truthy for handler to run
      probability     =, → float between 0 and 1
      
      period          =, → an integer, zero for non-ticks
      offset          =, → (OnTick only) integer, prevents that handlers with
                           equal periods run on the same tick.

      }
      
--]]

-- Used to subscribe EventManager.on_every_event to each event.
-- Because event_uids are user input they might be invalid.
function Private.on_event(event_uid,f)
  -- This is never used to deregister a handler with nil.
  -- Event_uid is verified by LuaBootstrap itself.
  Verify(f,'func','Missing handler function.')
  local ok, msg = pcall(LuaBootstrap.on_event, event_uid, f)
  log:debug('Installed event hook: ', EventUidToName[event_uid])
  return ok or stop('script.on_event error:\n\n', msg)
  end

-- Exceptions for on_tick and internal names.
local doNotRegisterTheseEventUids = Set.from_values {
  'on_init',
  'on_load',
  'on_config',
  }


-- Registration Order == Execution Order
local OrderedHandlers = setmetatable({

  -- on_tick must always be active to support actions
  -- [defines.events.on_tick] = {n=0},

  },{

  -- OrderedHandlers should behave like a normal table
  -- for iteration and index. In particular for returning
  -- nil when the index has no registered handlers.
  __index = {
  
    -- On-the-fly constructs per-event-uid subtables
    -- and registers the generic handler.

    -- Direct registration makes invalid handlers crash
    -- instantly, thus produces better error messages
    -- than conditional-registration in on_load.

    -- It also shifts the burdern of correct on_load 
    -- re-registration to the mod using the library,
    -- so no special handling is required here.
  
    sget = function(self, event_uid)
      local event_handlers = rawget(self,event_uid)
      if event_handlers == nil then
        event_handlers = Table.sget(self,{event_uid},{n=0})
        if not doNotRegisterTheseEventUids[event_uid] then
          if event_uid == 'action'
          or event_uid == defines.events.on_tick 
          then Private.on_event(
            defines.events.on_tick, Private.on_every_tick or stop('no handler?')
            )
          else Private.on_event(
            event_uid, Private.on_every_event or stop('no handler?')
            )
            end
          end
        end
      return event_handlers
      end,
    
  }})

  
-- These are filled by EventManager.new_handler.
-- No other function shall alter their structure.
local HandlersByUid   = {}
local HandlersByName  = {}


-- @future: performance optimization of on_every_event?
-- local OrderedEnabledHandlers = {}


-- Returns handler data or raises an error if
-- the name is unknown.
function Private.get_handler_data_from_name(handler_name)
  return HandlersByName[handler_name]
      or stop('Unknown handler name: ', handler_name)
  end

  
  
-- -------------------------------------------------------------------------- --
-- Queue                                                                      --
-- -------------------------------------------------------------------------- --

--[[
  
  The Queue is a mapping tick → tick_queue.
  
  A tick_queue is a DenseArray of {handler_uid,handler_args or nil}.
  
  local Queue = {
    [42] = {
      n   = 3                        , -- length of each tick_queue is stored
                                       -- to make iteration cheaper.
                                          
      [1] = {4509685,{'arg1','argN'}}, -- action with argument array
      [2] = {9458345, nil           }, -- action without arguments
      [3] = {2349069, nil           }, -- on_tick never has arguments
      }
    }
  
--]]


local Queue -- not accessible before on_load
local Queue_mt = {__index={
  -- Methods have to be meta so they are never stored in Savedata.
  
  -- All of these must be called after VerifyIsOnLoadFinished().
  -- For better performance they do not check it themselfs.
  
  -- @tparam array queued_handler {uid,{arg1,arg2,...,argN}}
  raw_enqueue = function(self,tick,queued_handler)
    -- most of the time queue for a particular tick will *not* exist yet
    local queue    = self[tick] or {n = 0}
    self[tick]     = queue
    queue.n        = queue.n + 1
    queue[queue.n] = queued_handler
    end,
    
  -- Enqueues an action for each of the given ticks
  -- @tparam array ticks
  enqueue_action = function(self,ticks,handler_data,...)
    local queued_handler = {handler_data.uid}
    local n = select('#',...)
    -- only create args-table when args are given
    if n > 0 then queued_handler[2] = {n=n,...} end
    local r, current_tick = {}, game.tick
    for i=1,#ticks do
      local tick = ticks[i] + current_tick
      r[#r+1]    = tick
      log:debug('Action enqueued: ', handler_data.name,', tick: ', tick)
      -- enqueues the same table for all requested ticks (saves space)
      self:raw_enqueue(tick, queued_handler)
      end
    return r
    end,
    
  -- Removes the handler uid action from all ticks between from_ and to_.
  -- Has to search through all ticks and tick-queues because
  -- actions do not have a known position.
  dequeue_action = function(self,handler_data,from_tick,to_tick)
    local uid = handler_data.uid
    for tick, queue in pairs(self) do
      if (tick >= from_tick) and (tick <= to_tick) then
        -- Actions can be in the queue more than once per tick.
        for i = 1, queue.n do
          if queue[i][1] == uid then
            log:debug('Action dequeued: ', handler_data.name,', tick: ', tick)
            queue[i] = nil
            queue.n = queue.n - 1
            end
          end
        Array.compress(queue,nil,nil,queue.n)
        end
      end
    end,

  -- Enqueues an OnTick on it's natural next_tick.
  enqueue_on_tick = function(self,handler_data)
    log:debug('OnTick enqueued: ', handler_data.name)
    local tick = Private.calculate_next_natural_tick(
      game.tick, handler_data.period, handler_data.offset
      )
    self:raw_enqueue(tick, {handler_data.uid})
    end,

  -- Removes an on_tick handler.
  -- Faster than dequeue_action because the position is known.
  dequeue_on_tick = function(self,handler_data)
    log:debug('OnTick dequeued: ', handler_data.name)
    local uid = handler_data.uid
    local tick = Private.calculate_next_natural_tick(
      game.tick, handler_data.period, handler_data.offset
      )
    local queue = self[tick]
    for i = 1, queue.n do
      if queue[i][1] == uid then
        table_remove(queue,i)
        queue.n = queue.n - 1
        return nil -- OnTicks are unique per tick.
        end
      end
    stop('Could not find OnTick to remove from queue: ',handler_name)
    end,

  }}


  
--------------------------------------------------------------------------------
-- Event groups.
-- @section
--------------------------------------------------------------------------------

----------
-- Event groups to easily subscribe to multiple events.  
-- __Eperimental/Legacy.__ Will be completely changed in the near future.
--
EventManager.event_uid_group = {}

----------
-- Build-related events.  
-- * on\_built\_entity  
-- * on\_robot\_built\_entity  
-- * script\_raised\_built  
-- * script\_raised\_revive  
--
-- @table event_uid_group.on_entity_created
EventManager.event_uid_group['on_entity_created'] = {
  defines.events.on_built_entity       ,
  defines.events.on_robot_built_entity ,
  defines.events.script_raised_built   ,
  defines.events.script_raised_revive  ,
  -- defines.events.on_entity_cloned         , -- completely different event content :/
  -- defines.events.on_trigger_created_entity, -- completely different event content :/
  }

----------
-- Destroy-related events.  
-- * on\_entity\_died  
-- * on\_player\_mined\_entity  
-- * on\_robot\_mined\_entity  
-- * script\_raised\_destroy  
--
-- @table event_uid_group.on_entity_removed
EventManager.event_uid_group['on_entity_removed'] = {
  defines.events.on_entity_died        ,
  defines.events.on_player_mined_entity,
  defines.events.on_robot_mined_entity ,
  defines.events.script_raised_destroy ,
  }
  
  
----------
-- Move-related events.  
--
-- * control.move-up/right/down/left  
--
-- @table event_uid_group.er:control.move-any
EventManager.event_uid_group['er:control.move-any'] = {
  'er:control.move-up'   ,
  'er:control.move-down' ,
  'er:control.move-left' ,
  'er:control.move-right',
  }
  


--------------------------------------------------------------------------------
-- LuaBootstrap (script) Intercept.
-- @section
--------------------------------------------------------------------------------

-- EventManager must intercept any calls to script.* and emulate their
-- exact behavior to prevent it from being broken by external script calls
-- and to allow easy migration of non-EventManager based mods.

-- Emulation explicitly means that EventManagerScript.on_event does not 
-- support registering multiple events, exactly like real_script.


log:info('Redirecting all factorio "script" access to EventManager.')

local EventManagerScript = setmetatable({},{__index=LuaBootstrap})
_ENV.script = EventManagerScript

-- Block all event handler related functions.
for _, method in pairs {
  'on_init'                 ,
  'on_load'                 ,
  'on_configuration_changed',
  'on_event'                ,
  'on_nth_tick'             ,
  'get_event_handler'       ,
  'set_event_filter'        ,
  'get_event_filter'        ,
  } do
    EventManagerScript[method] = function(...)
      stop(
        'Function call blocked by EventManager.\n',
        'Wrapping is not implemented for:\n\n',
        'script.', method, '()\n',
        ...
        )
      end
  end


--------------------------------------------------------------------------------
-- Registry.
-- @section
--------------------------------------------------------------------------------

-- -------------------------------------------------------------------------- --
-- NewHandler                                                                 --
-- -------------------------------------------------------------------------- --

----------
-- Add another event handler. Does not affect already registered handlers.
--
-- @param args
--
-- @tparam string|DenseArray args.1 One or multiple event uids. This
-- can be a defines.events number, a custom-input name string,
-- one of the literal strings 'action','on\_init','on\_load','on\_config'.
-- or a (nested) DenseArray.
--
-- @tparam function args.2 The handler function.
-- Actions and NonTicks will be called f(event,player), containing player only
-- for events with player\_index. OnTicks will be called f(tick_number).
--
-- @tparam[opt] string args.name The __unique__ name of the handler. Needed to
-- en/disable and en/dequeue the handler during runtime. __Mandatory for
-- OnTick handlers and actions__.
--
-- @tparam[opt] string args.name_prefix A string prefixed to the name of the
-- handler for __logging__ purposes __only__. Does not have to be unique.
-- Useful to distinguish between groups of handlers.
--
-- @tparam[opt=true] boolean args.enabled If the handler is enabled by default.
-- __Ignored__ when the handler is executed as action.
--
-- @tparam[opt=true] boolean args.persistent Persistent handlers can not be
-- en/disabled. They are always active. This is useful only for certain
-- EventManager internal events.
--
-- @tparam[opt] function args.filter A function that will be called
-- fi(event,player) before the hanler function. If it does not return
-- truthy then the main handler will not be called. Any __changes__ made to
-- the event table __will be passed on__ to the main handler. 
-- __Ignored__ when the handler is executed as action or OnTick.
-- __Filters must never invalidtate factorio objects.__ Otherwise the next
-- event might be raised with invalid userdata.
-- 
-- @tparam[opt] UnitInterval args.probability Randomly skip the handler completely.
-- __Ignored__ when the handler is executed as action or OnTick.
--
-- @tparam[opt=0] NaturalNumber args.period
-- Mandatory for @{EventManager.OnTick|OnTick}, optional for
-- @{EventManager.Action|Action}, ignored by everything else.
-- The delay between two executions of the handler. Zero means that
-- the handler is only run once and does not automatically repeat.
-- If you enqueue an Action with a period > 0 you have to manually dequeue it
-- later or it will repeat forever.
--
-- @function EventManager.new_handler

do
  -- For ease of use the internal representation 
  -- is different from the input argument format.
  local handler_data_remapper = Table.remapper{
    -- As no other function ever sees this the indexes can be hardcoded.
    [1]     = 'event_uids',
    [2]     = 'f',
    enabled = 'default_enabled'
    }
    
  local no_invalid_read_mt = {__index = function(self,key)
    stop('Handler_data read blocked, no such key!\n',
      'key= ',key,'\n',
      'handler_data= ',self
      )
    end}
    
  -- Validates the all input, generates a UID and stores
  -- references to the handlers in OrderedHandlers and HandlersBy*
  function EventManager.new_handler(handler_data)
  
    -- container table
    Verify(handler_data, 'NonEmptyTable','Missing handler_data.')
    handler_data = Table_dcopy(handler_data)
    handler_data_remapper(handler_data)

    -- handler function
    Verify(handler_data.f,'func','Missing handler function.')
    
    -- event uids (stored as Set)
    Verify_Or(handler_data.event_uids,{'str|num','NonEmptyArray'},'Missing event ids.')
    -- (There is no verification if the event uids are actually *valid*
    --  because that's complicated and script.on_event already does it later.)
    handler_data.event_uids =
      Set.from_values(Array.flatten(Table.plural(handler_data.event_uids)))
    -- Because the UnifiedQueue does not distinguish between
    -- action and OnTick they may never share the same name.
    if handler_data.event_uids[defines.events.on_tick] then
      Verify(Table.size(handler_data.event_uids) == 1,'true',
        'OnTick handlers can not be used for other event types.')
      end
      
    -- name
    if handler_data.event_uids['action']
    or handler_data.event_uids[defines.events.on_tick] then
      -- The UnifiedQueue requires a name-based uid.
      Verify(handler_data.name,'NonEmptyString','Missing handler name.')
    else
      Verify_Or(handler_data.name,{'nil','NonEmptyString'},'Empty handler name.')
      end

    -- uid
    if handler_data.name then
      -- The uid must be stable even if the handler function is updated,
      -- thus using the function itself as an rnd-seed is not possible.
      handler_data.uid = Crc32.encode(handler_data.name)
      end

    -- log_name
    -- Used only for printing to the log.
    if handler_data.name == nil then
      handler_data.log_name = '<unnamed-handler>'
    else
      handler_data.log_name = handler_data.name
      end
    -- Prefix does not have to be unique.
    Verify(handler_data.name_prefix, 'nil|str','Invalid prefix type.')
    if handler_data.name_prefix then
      handler_data.log_name = handler_data.name_prefix ..':'.. handler_data.log_name
      end
      
    -- enabled
    Verify(handler_data.default_enabled,'nil|bool','Invalid enabled type.')
    if handler_data.default_enabled == nil then
      handler_data.default_enabled = true
      end
    -- The actual "enabled" value is pulled from Savedata in on_load.
    handler_data.enabled = nil

    -- persistent
    -- This parameter is undocumented becaue 
    Verify(handler_data.persistent,'nil|bool','Invalid persistent type.')
    if handler_data.persistent == true then
      -- Can not be en/disabled and thus false makes no sense.
      -- But user must be warned about the illogical definition.
      Verify(handler_data.default_enabled,'true','Persistant handlers must be enabled.')
    else
      handler_data.persistent = false
      end

    -- filter
    Verify(handler_data.filter,'nil|func','Invalid filter type.')
    
    -- probability
    Verify_Or(handler_data.probability,{'nil','UnitInterval'},'Invalid probability type.')
    if handler_data.probability == nil then
      handler_data.probability = 1
      end
      
    -- period
    if handler_data.event_uids[defines.events.on_tick] then
      Verify(handler_data.period,'NaturalNumber','Invalid period.')
      -- OnTicks are automatically assigned a random deterministic offset.
      -- This improves performance by preventing that all handlers
      -- with equal periods are executed on the same tick.
      handler_data.offset = handler_data.uid % handler_data.period
    else
      Verify_Or(handler_data.period,{'nil','NaturalNumber'},'Invalid period.')
      if handler_data.event_uids['action'] then
        handler_data.period = handler_data.period or 0
        end
      end
    
    -- purge unwanted data
    Table.clear(handler_data,{
      'f','event_uids','name','uid','log_name',
      'default_enabled','filter','probability','period','offset',
      'persistent',
      -- "enabled" must be removed here!
      })
      
    -- store lookup
    if handler_data.name then
      Verify(HandlersByName[handler_data.name],'nil','Duplicate handler name.')
      Verify(HandlersByUid [handler_data.uid ],'nil','Duplicate handler uid (crc collision).')
      HandlersByName[handler_data.name] = handler_data
      HandlersByUid [handler_data.uid ] = handler_data
      end
    
    -- store iterable for each event
    for event_uid in pairs(handler_data.event_uids) do
      local this   = OrderedHandlers:sget(event_uid) -- auto-constructed + registered
      this.n       = this.n + 1
      this[this.n] = handler_data
      end

    -- protect against accidents
    setmetatable(handler_data,nil) -- remove "Table" module metatable
    if handler_data.uid == nil then handler_data.uid = false end --read is allowed
    if handler_data.filter == nil then handler_data.filter = false end --read is allowed
    setmetatable(handler_data,no_invalid_read_mt)
    
    end
  end


  
-- -------------------------------------------------------------------------- --
-- Enable / Disable                                                           --
-- -------------------------------------------------------------------------- --

-- Dis/enables *named* handlers.
-- @tparam string handler_name
-- @tparam boolean _enabled On/Off
function Private.set_handler_status(handler_data,_enabled)
  VerifyIsOnLoadFinished()
  if handler_data.persistent then
    stop('Persistent handlers can not be toggled.\n',handler_data)
    end
  -- Not "enabling" an already active handler is important to prevent
  -- OnTicks from being added multiple times to the Queue. There are
  -- no other protections against that.
  if handler_data.enabled ~= _enabled then
     handler_data.enabled  = _enabled
    -- fixup savedata
    -- @future: should this always store, instead of only if not default?
    Savedata.handler_status[handler_data.uid] = Tool.Select(
      handler_data.default_enabled == _enabled, nil, _enabled
      )
    -- if OnTick handle Queue
    if handler_data.event_uids[defines.events.on_tick] == true then
      if _enabled == true then
        Queue:enqueue_on_tick(handler_data)
      else 
        Queue:dequeue_on_tick(handler_data)
        end
    else
      log:debug(
        'Handler enabled status changed to: ', _enabled,
        ', Handler: ', handler_data.name
        )
      end
  else
    log:debug(
      'Handler enabled status not changed, was already ',
      _enabled, ': ', handler_data.name
      )
    end
  end


----------
-- Enables a handler.
-- Works for OnTick and all other events. Has no meaning for actions.
--
-- Enabling an on_tick handler will not run it immediately. It will be
-- be run according to it's own period as if it had never been disabled.
-- 
-- __Note:__ Can only be called from inside event handlers.
--
-- @tparam string handler_name
--
function EventManager.enable(handler_name)
  local handler_data = Private.get_handler_data_from_name(handler_name)
  Private.set_handler_status(handler_data,true)
  end


----------
-- Disables a handler.
-- Works for OnTick and all other events.
-- Has no meaning for actions.
--
-- Disabled handlers do not recieve any events.
-- 
-- __Note:__ Can only be called from inside event handlers.
-- 
-- @tparam string handler_name
--
function EventManager.disable(handler_name)
  local handler_data = Private.get_handler_data_from_name(handler_name)
  Private.set_handler_status(handler_data,false)
  end
  
  
  
-- -------------------------------------------------------------------------- --
-- Enqueue / Dequeue                                                          --
-- -------------------------------------------------------------------------- --

----------
-- Schedule an action to be called in the future.
--
-- __Note:__ Can only be called from inside event handlers.
-- 
-- @tparam NaturalNumber|DenseArray tick_delay How many ticks in the future this
-- should be executed.
-- 
-- @tparam string action_name The name used to register the handler you want
-- to call.
-- 
-- @tparam AnyValue ... Additional arguments that will be passed to the handler.
-- The exact values will be passed. In particular __table references will not
-- be protected__ against manipulation from multiple handlers.
--
-- @treturn DenseArray All ticks that the handler has been queued for. Useful
-- if you later want to dequeue it from specific ticks.
--
function EventManager.enqueue(tick_delay,action_name,...)
  -- The UnifiedQueue does not handle name collisions between 
  -- OnTick and action handlers. It is thus nessecary that only
  -- actions can be enqueued. EventManager.new_handler enforces
  -- that actions and OnTick can never have the same name.
  VerifyIsOnLoadFinished()
  
  local handler_data = Private.get_handler_data_from_name(action_name)
  Verify(handler_data.event_uids['action'], 'true', 'Can only enqueue actions.')

  local ticks = Table.plural(tick_delay)
  Verify(ticks,'NonEmptyDenseArrayOfNaturalNumber','Invalid tick_delay.')
  return Queue:enqueue_action(ticks,handler_data,...)
  end



----------
-- Remove previously made future schedules for an action.
--
-- __Note:__ Can only be called from inside event handlers.
--
-- @tparam string action_name
--
-- @tparam[opt=1] NaturalNumber from_tick
-- Do not remove the actions from ticks earlier than this.
--
-- @tparam[opt=infinity] NaturalNumber to_tick
-- Do not remove the actions from ticks later than this.
--
function EventManager.dequeue(action_name,from_tick,to_tick)
  VerifyIsOnLoadFinished()
  
  local handler_data = Private.get_handler_data_from_name(action_name)
  Verify(handler_data.event_uids['action'], 'true', 'Can only dequeue actions.')
  
  Queue:dequeue_action(
    handler_data,
    from_tick or 0,
    to_tick   or math.huge
    )
  end


----------  
-- Calls a registered handler directly.
-- 
-- @tparam string handler_name 
-- @tparam[opt] AnyValue ... Additional arguments for the handler.
-- 
-- @return The data returned by the handler.
-- 
function EventManager.call(handler_name,...)
  log:debug('Handler called: ', handler_name)
  local handler_data = Private.get_handler_data_from_name(handler_name)
  return handler_data.f(...)
  end


  
-- -------------------------------------------------------------------------- --
-- on_every_event / on_every_tick                                             --
-- -------------------------------------------------------------------------- --

do
  -- Straight table lookup for 100%, calculated on-the-fly for everything else.
  -- Must be different for each handler to prevent i.e. all 5% handlers from
  -- happening at once.
  local doesOccur = setmetatable(
    {[1]=true}, {__index=function(_,key) return key >= math_random() end}
    )

  local isLuaObject = Verificate.isType.LuaObject

  -- Handles all events except OnTick.
  function Private.on_every_event(e,filter)
    local event_uid = e.input_name or e.name
    local handlers   = OrderedHandlers[event_uid]
    
    -- @future: Allow selectively calling a subset of handlers.
    -- I.e. to simulate events only for a specific plugin.
    -- if filter then handlers = Table.filter(handlers,filter,{}) end
    
    -- pre-resolve player index
    if e.player_index then
      e.player = game.players[e.player_index]
      end
    -- array of factorio userdata
    local luaobjects, m   = {}, 0
    local isUserdataDirty = false
    for k,v in pairs(e) do 
      if isLuaObject(v) then
        m = m + 1
        luaobjects[m] = v
        end
      end
    -- for each handler seperately
    for i=1, handlers.n do
      local handler_data = handlers[i]
      if handler_data.enabled then
        -- did previous handler invalidate userdata?
        if isUserdataDirty then
          for j=1, m do if not luaobjects[j].valid then
            log:debug(
              '[tick ', e.tick, '] ',
              'Event cycle ended prematurely due to invalidated userdata.')
            return
            end end
          isUserdataDirty = false
          end
        -- probability → filter → call
        if doesOccur[handler_data.probability] then
          -- Private event table for each handler.
          -- Filter is explicitly allowed to change it.
          local _e = Table_dcopy(e)
          if (not handler_data.filter) or (handler_data.filter(_e)) then
            log:debug(
              '[tick ', e.tick, '] ',
              'Event handled  : ', EventUidToName[event_uid]
              ,', Handler: ', handler_data.log_name)
            handler_data.f(_e,_e.player)
            isUserdataDirty = true
            -- Flagging the userdata dirty only if the actual handler
            -- ran improves performance by skipping the re-checking of
            -- all factorio LuaObjects for handlers that didn't
            -- pass their filter.
            -- 
            -- But theoretically the filter itself could invalidate
            -- the LuaObjects too. So this sacrifices perfect reliability
            -- for a potentially huge performance gain. Particularly for
            -- on_entity_created type events with lots of handlers of which
            -- mostly only a single one will run.
            end
          end
        end
      end
    end
  end
  

function Private.on_every_tick (e)
  -- Most ticks will finish with a single failed table lookup!
  if Queue[e.tick] then
    -- The UnifiedQueue maps each tick to an array of 
    -- {handler_uid, handler_args}.
    local queue = Queue[e.tick]
    for i=1,queue.n do
      -- handler_data
      local queued_handler = queue[i]
      local uid, args      = queued_handler[1], queued_handler[2]
      local handler_data   = HandlersByUid[uid]
      -- get next queue
      
      -- Queue:raw_enqueue(e.tick+handler_data.period, queued_handler) --@future
      
      local next_period  = e.tick + handler_data.period -- period can be 0
      local next_queue   = Queue[next_period] or {n = 0}
      Queue[next_period] = next_queue
      -- enqueue next
      next_queue.n             = next_queue.n + 1
      next_queue[next_queue.n] = queued_handler
      -- call handler
      
      
      log:debug(
        '[tick ', e.tick, '] ',
        'Event handled  : on_tick, Handler: ', handler_data.log_name
        )
      -- if handler_data.profiler then -- @future (also read-block of handler_data)
      --   handler_data.profiler.restart()
      --   end
      if args then
        -- V1 private args copy for every call
        -- deep-copy? shallow-copy?
        -- handler_data.f(e.tick,table_unpack(Table_scopy(args),1,args.n))

        -- V2 shared data, no copy
        -- References to local upvalues shouldn't be in args? But if
        -- they were then deep-copy would destroy them.
        -- @future: there might be usecases where actions need to share data?
        handler_data.f(e.tick,table_unpack(args,1,args.n))
      else
        handler_data.f(e.tick)
        end
      -- if handler_data.profiler then -- @future
      --   handler_data.profiler.stop()
      --   handler_data.profiler_counter = handler_data.profiler_counter + 1
      --   end
      end
    -- Must be deleted at the end because handlers with period == 0
    -- will include themselfs here. But because most handlers have
    -- a period > 0 it's faster to not check "if period > 0" for everything.
    Queue[e.tick] = nil
    end
  end

  
-- -------------------------------------------------------------------------- --
-- Legacy Inherited                                                           --
-- -------------------------------------------------------------------------- --

-- Calculates the next tick that an OnTick handler should be called on.
-- For enabled handlers this is incrementally calculated in on_every_tick.
-- OnTicks are called on each "offset + N * period"'s tick, for N=0,inf
--
-- Used only in EventManager.enable and EventManager.disable for OnTicks.
--
-- Quirk:
--   The "current_tick" has already been processed, thus
--   the earliest executable tick is current_tick + 1.
--
function Private.calculate_next_natural_tick(current_tick, period, offset)
  local p = period
  local o = offset
  local t = current_tick -- game.tick
  if o > t then
    return o
  else
    return math_floor((t - o) / p) * p + o + p
    end
  end
  
  
-- -------------------------------------------------------------------------- --
-- Draft                                                                      --
-- -------------------------------------------------------------------------- --

--[[
  

  



  
  
-- Registers the generic event handlers to all events
-- that have at least one known handler.
--
-- Must be on_load copatible.
function Private.register_manager_event_handlers()
  -- on_*
  local event_uids = Set.from_keys(OrderedHandlers)
  for _,id in pairs{defines.events.on_tick,'on_init','on_config','on_load'} do
    -- ignore special events
    event_uids[id] = nil
    end
  for event_uid in pairs(event_uids) do
    Private.on_event(event_uid,Private.on_every_event)
    end
  -- OnTick
  if OrderedHandlers[defines.events.on_tick] ~= nil then
    Private.on_event(defines.events.on_tick, Private.on_every_tick)
    end
  end
  


-- The Queue and Savedata.current_tick *should* only ever
-- be used for OnTicks and Actions.
function Private.shouldOnTickBeActive()
  return (OrderedHandlers['action'              ] ~= nil)
      or (OrderedHandlers[defines.events.on_tick] ~= nil)
  end
  
--]]
-- -------------------------------------------------------------------------- --
-- Draft                                                                      --
-- -------------------------------------------------------------------------- --
  
  
-- Pulls the en/disabled flags from Savedata
-- into the local Registry.
function Private.restore_handler_status()
  for event_uid, event_handlers in pairs(OrderedHandlers) do
    for i = 1, event_handlers.n do
      local handler_data = event_handlers[i]
      handler_data.enabled = Tool.First(
        Savedata.handler_status[handler_data.uid],
        handler_data.default_enabled
        )
      end
    end
  end


-- Raises an event that is private to this mods lua state.
-- @tparam EventUid event_uid
-- @tparam table event_data extra data to be passed to all event handlers
-- @tparam table args additional arguments for THIS function (not currently used)
--
function EventManager.raise_private(event_uid, event_data, args)
  if event_uid == defines.events.on_tick then stop('Can not raise on_tick.') end
  local tick = (event_uid ~= 'on_load') and game.tick or -1
  if OrderedHandlers[event_uid] then
    log:debug(
      '[tick ', tick, '] ',
      'Event raised   : ', EventUidToName[event_uid], ' (private)'
      )
    Private.on_every_event( Table.smerge( {
      name    = event_uid,
      tick    = tick,
      private = true, --@future: usecase?
      }, event_data or nil ) )
  else
    log:debug(
      '[tick ', tick, '] ',
      'No handlers for privately raised event: ',
      EventUidToName[event_uid],' ', event_data
      )
    end
  end
  
  
-- Deletes old handler uids.
function Private.clear_outdated_savedata()
  log:debug('Clearing outdated savedata.')
  -- Queue (paranoia)
  for tick in pairs(Queue) do
    if tick < game.tick then
      log:warn('The queue contained a tick from the past: ', tick)
      Queue[tick] = nil
      end
    end
  -- Queue
  for tick, queue in pairs(Queue) do
    for i = 1, queue.n do
      if HandlersByUid[queue[i][1] ] == nil then
        queue[i] = nil
        queue.n = queue.n - 1
        end
      end
    Array.compress(queue,nil,nil,queue.n)
    end
  -- handler_status
  for uid,_ in pairs(Savedata.handler_status) do
    if HandlersByUid[uid] == nil then
      Savedata.handler_status[uid] = nil
      end
    end
--   -- current_tick
--   if not Private.shouldOnTickBeActive() then
--     -- current_tick is not usable if on_every_tick is inactive.
--     Savedata.current_tick = nil
--     end
  end


function Private.enqueue_new_onticks()
  local handlers = OrderedHandlers[defines.events.on_tick]
  -- Set of already queued handler uids
  local queued_uids = {}
  for _, queue in pairs(Queue) do
    for i = 1, queue.n do
      queued_uids[queue[i][1]] = true
      end
    end
  -- Enqueue only handlers that should be in the queue but are not.
  if handlers then
    for i = 1, handlers.n do
      local handler_data = handlers[i]
      local uid = handler_data.uid
      -- should be queued but isnt
      if Verify(handler_data.enabled,'bool') == true -- Verify returns obj
      and queued_uids[uid] == nil
      then
        Queue:enqueue_on_tick(handler_data)
        end
      -- should not be queued but is
      if handler_data.enabled == false
      and queued_uids[uid] ~= nil
      then
        Queue:dequeue_on_tick(handler_data)
        end
      end
    end
  end
  
  
-- -------------------------------------------------------------------------- --
-- Draft                                                                      --
-- -------------------------------------------------------------------------- --

function Private.isSavedataUpToDate()
  Savedata = global['event_manager']
  if Savedata == nil then return false end
  return Savedata._version == Table.array_size(SavedataMigrations)
  end


function Private.on_load()
  Savedata = global.event_manager       or stop('No savedata?')
  Queue    = global.event_manager.Queue or stop('No Queue?')
  setmetatable(Queue, Queue_mt)
  -- Private.register_manager_event_handlers()
  Private.restore_handler_status()
  -- log:tell('Full Registry at end of on_load:',OrderedHandlers)
  EventManager.raise_private('on_load', nil)
  isOnLoadFinished = true
  end

  
-- Handles both init and config to be able to load in-dev worlds
-- that originally didn't have the EventManager.  
function Private.on_confinit()
  -- apply migrations?
  if not Private.isSavedataUpToDate() then
    log:debug('Updated EventManager Savedata.')
    Table.migrate(global,'event_manager',SavedataMigrations)
    -- log:tell(global['event_manager'])
    end
  
  Savedata = global.event_manager
  Queue    = Savedata.Queue
  
  -- Savedata = Table.sget(global  , {'event_manager'}, {})
  -- Queue    = Table.sget(Savedata, {'Queue'}        , {})
  -- default values
  -- Table.sget(Savedata,{'handler_status'},{}) ;
  
  --
  Private.clear_outdated_savedata()
  --
  Private.on_load()
  --
  Private.enqueue_new_onticks() -- after restore_handler_status() in on_load
  end

  
  

-- -------------------------------------------------------------------------- --
-- LuaBootstrap / Script                                                      --
-- -------------------------------------------------------------------------- --  

LuaBootstrap.on_load(function()
  if not Private.isSavedataUpToDate() then
    -- on_load before on_config
    log:info('Skipping on_load: Savedata.event_manager missing or outdated.')
    return
    end
  log:debug('Bootstrap      : on_load')
  Private.on_load()
  end)

LuaBootstrap.on_init (function()
  log:debug('Bootstrap      : on_init')
  Verify(global.event_manager,'nil','Savedata found before on_init!?')
  Private.on_confinit()
  EventManager.raise_private('on_init')
  end)
  
LuaBootstrap.on_configuration_changed(function()
  log:debug('Bootstrap      : on_config')
  Private.on_confinit()
  EventManager.raise_private('on_config')
  end)

-- paranoia: remove all previous handlers
LuaBootstrap.on_event(defines.events,nil)

-- -------------------------------------------------------------------------- --
-- Simulation : surfaces, forces, players                                     --
-- -------------------------------------------------------------------------- --

----------
-- Enforces raising of easily missable events.
-- 
-- Because of certain quirks of the factorio engine a mod might not 
-- recieve an event even if it has a handler for that event.
--
-- Specifically a mod will not recieve __any__ events before it's own
-- on\_init handler has finished. Thus any events raised by __other mods__
-- during their on\_init will be missed. I call this __overshadowing__.
-- 
-- Simulation aims to reduce edge cases and make event handlers more reliable.
-- For this EventManager simulates __some__ of these
-- overshadowed events when it detects them in it's own on_init. 
--
-- Namely EventManager detects the creation and deletition of surfaces,
-- forces and players. And the researching and __un__researching of technologies.
--
-- All simulated events are raised with the additional event data
-- `{simulated = true}` to make them distingusishable from natural events.
--
-- Simulation also happens when the mod is first added to a map. This means
-- even __if your mod is added to an old map__ you will still recieve i.e.
-- on\_player\_created for __all__ players that already exist in the map.
-- Removing the need to manually detect which players, forces or surfaces
-- already existed before.
--
-- __Known Issue:__ Simulated on\_forces\_merged events only contains `source_index`,
-- but not `source_name` or `destination` because that information is lost for
-- overshadowed force mergers.
-- 
-- 
-- @table Simulation
-- @within Simulation


--[[

  on_force_created   -> force         :: LuaForce
  on_forces_merged   -> source_name   :: string
                        source_index  :: uint
                        destination   :: LuaForce

  on_surface_created -> surface_index :: uint
  on_surface_deleted -> surface_index :: uint

  on_player_created  -> player_index  :: uint
  on_player_removed  -> player_index  :: uint

--]]

local function CreateSimulation(
    created_event,   created_event_index_path,
  destroyed_event, destroyed_event_index_path,
  game_key,
  
  sim_create_event_key, sim_create_obj_value_path,
  sim_remove_event_key
  
  )

  local NAME_PREFIX = 'em-simulation:'..game_key
  local SAVEDATA_PATH = {'event_manager','simulation',game_key}

  local NewHandler = function(tbl)
    EventManager.new_handler(Table.smerge(tbl,{
      name_prefix = NAME_PREFIX,
      persistent  = true,
      }))
    end
  
  local Savedata
  local function remember_index (index)
    Array.insert_once(Savedata.known_indexes, index)
    end
  local function forget_index (index)
    Array.unsorted_remove_value(Savedata.known_indexes, index)
    end
  local function link_savedata()
    -- beware on_load before on_config
    Savedata = Table.get(global,SAVEDATA_PATH)
    end

  NewHandler{
    'on_load',
    link_savedata
    }
    
  -- Store indexes on naturally occuring events.
  NewHandler {
    defines.events[created_event],
    filter = function(e) return not e.simulated end,
    function(e) remember_index(Table.get(e,created_event_index_path)) end
    }
  NewHandler {
    defines.events[destroyed_event],
    filter = function(e) return not e.simulated end,
    function(e) forget_index(Table.get(e,destroyed_event_index_path)) end
    }
    
  -- Simulate indexes when other mods might have overshadowed them.
  NewHandler {
    {'on_init','on_config'},
    function(e)
    
      -- create/read savedata
      Savedata = Table.sget(global,SAVEDATA_PATH,{})
      Table.sget(Savedata,{'known_indexes'},{});
      local known = Set.from_values(Savedata.known_indexes)
      
      -- missed object removal?
      for index in pairs(known) do
        if game.players[index] == nil then
          log:debug(
            '[tick ', e.tick, '] ',
            'Event simulated: ', destroyed_event, ' → Index: ', index
            )
          forget_index(index)
          local e = {simulated = true}
          Table.set(e, sim_remove_event_key, index)
          EventManager.raise_private(defines.events[destroyed_event], e)
          end
        end
      
      -- missed new object?
      for _,obj in pairs(Table.get(game,{game_key})) do
        if not known[obj.index] then
          log:debug(
            '[tick ', e.tick, '] ',
            'Event simulated: ', created_event,
            ' → Index: ', obj.index, ', Name: "', obj.name,'"'
            )
          remember_index(obj.index)
          local e = {simulated = true}
          Table.set(e, sim_create_event_key, 
            Table.get(obj, sim_create_obj_value_path)
            )
          EventManager.raise_private(defines.events[created_event], e)
          end
        end

      end
    }
  end
  

-- Order is important! surface → force → player   

CreateSimulation(
  'on_surface_created',{'surface_index'},
  'on_surface_deleted',{'surface_index'},
  'surfaces',
  {'surface_index'}, {'index'},
  {'surface_index'}
  )
 
CreateSimulation(
  'on_force_created',{'force','index'},
  'on_forces_merged',{'source_index'},
  'forces',
  {'force'}, {}, -- empty path == object itself
  {'source_index'} -- is always index
  -- name and destination are unknown for overshadowed force removal!
  -- @future: Create a seperate event just for this?
  -- EventManager.event_uid.on_force_removed
  )

CreateSimulation(
  'on_player_created',{'player_index'},
  'on_player_removed',{'player_index'},
  'players',
  {'player_index'}, {'index'},
  {'player_index'}
  )
  
-- -------------------------------------------------------------------------- --
-- Simulation : technology                                                    --
-- -------------------------------------------------------------------------- --

-- Stores an array of Crc32(technology.name) for each force.
-- Compares the array to actual research status in on_init, on_config
-- and on_force_reset.

--[[

  on_technology_effects_reset -> force :: LuaForce, Preserves research state of technologies.
  on_force_reset              -> force :: LuaForce
  on_research_finished        -> research :: LuaTechnology
                              -> by_script :: boolean
--]]

do

  local SAVEDATA_PATH = {'event_manager','simulation','technologies'}

  local NewHandler = function(tbl)
    EventManager.new_handler(Table.smerge(tbl,{
      name_prefix = 'em-simulation:technologies',
      persistent  = true,
      }))
    end
    
  -- Maps {uid -> name} and {name -> uid}.
  local _map = Cache.AutoCache(function(r)
    for _,t in pairs(game.technology_prototypes) do
      -- Storing all technology names for every force would
      -- waste too much space. So only the crc32 is stored.
      local uid = Crc32.encode(t.name)
      if r[uid] ~= nil then
        stop('Technology name crc32 collision!\n', uid, '\n', t.name)
        end
      r[t.name], r[uid] = uid, t.name -- double lookup
      end
    end)
    
  local Savedata
  
  -- get force researched_uids
  local function get_fuids(force)
    local x = Table.sget(Savedata,{force.index,'researched_uids'},{})
    return x
    end
  
  local function store_tech_uid(force,technology)
    Array.insert_once(get_fuids(force),_map[technology.name])
    end
    
  local function forget_tech_uid(force,technology)
    Array.unsorted_remove_value(get_fuids(force),_map[technology.name])
    end
  
  -- Compares the researched_uids of a force with the current technology
  -- state and if nessecary updates savedata and raises un/research events.
  local function check_force(e,force,simulated)
    -- remove uids if the technology no longer exists
    local researched_uids_array = Array(get_fuids(force))
    for i,uid in pairs(researched_uids_array) do
      if _map[uid] == nil then
        researched_uids_array:unsorted_remove_key(i)
        end
      end
    -- iter all technologies and compare with known state
    local researched_uids = Table.map( -- Set {name -> uid}
      get_fuids(force), function(v) return v,_map[v] end, {}
      )
    for _,tech in pairs(force.technologies) do
      -- missed research?
      if tech.researched and not researched_uids[tech.name] then
        log:debug(
          '[tick ', e.tick, '] ',
          'Event simulated: on_research_finished, ',
          ' → Force: ', force.name,
          ', Technology: ', tech.name
          )
        store_tech_uid(force,tech)
        EventManager.raise_private(
          defines.events.on_research_finished,
          {
            research  = tech ,
            by_script = false,
            -- source of research is unknown
            --
            -- @future: If the mod is added to the map for the first time
            -- it could be assumed that all old techs are not by_script, 
            -- and after that it could be assumed that all overshadowed
            -- events *are* by_script.
            --
            simulated = true, -- is tautologically always simulated
            }
          )
      -- missed un-research?
      elseif (not tech.researched) and (researched_uids[tech.name]) then
        forget_tech_uid(force,tech)
        EventManager.raise_private(
          EventManager.event_uid.on_research_reset,
          {research  = tech, simulated = not not simulated}
          )
        end
      end
    end

  -- Beware on_load before on_config.
  NewHandler{
    'on_load',
    function() Savedata = Table.get(global,SAVEDATA_PATH) end
    }

  -- Remove savedata when forces are removed.
  -- Creation of new forces is handled implicitly by get_fuids().
  NewHandler {
    defines.events.on_forces_merged,
    function(e)
      Table.set(Savedata,{e.source_index},nil)
      if e.destination then check_force(e, e.destination, false) end
      end
    }

  -- Store indexes on naturally occuring events.
  NewHandler {
    defines.events.on_research_finished,
    filter = function(e) return not e.simulated end,
    function(e) store_tech_uid(e.research.force, e.research) end
    }
    
  -- Convert: "on_force_reset" -> "on_research_reset"
  NewHandler {
    defines.events.on_force_reset,
    function(e) check_force(e, e.force, false) end
    }

  -- Simulate un/research when other mods might have overshadowed it.
  NewHandler {
    {'on_init','on_config'},
    function(e)
      Savedata = Table.sget(global, SAVEDATA_PATH, {})
      for _,force in pairs(game.forces) do check_force(e, force, true) end
      end
    }
    
    
  end
  
--------------------------------------------------------------------------------
-- CustomEvents.
-- @section CustomEvents
--------------------------------------------------------------------------------
  
----------
-- dummy
-- @table dummy
  
if flag.IS_DEV_MODE then
  Tool.Import('event_test_dynamic_endisable_endequeue')(EventManager)
  end

if true then -- EventManager.enable_extra_events()?

  -- Each event must detect if there are subscriptions to it.

  -- Tool.Import('event_on_entity_created')(EventManager)
  end

  
-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.EventManager') end
return function() return EventManager,_EventManager,_uLocale end
