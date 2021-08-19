-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable

--------------------------------------------------------------------------------
-- Native multi-handler events.
--
-- EventManagerLite mimics the @{FOBJ LuaBootstrap} api to allow mods
-- to register multiple handlers to any event with only minimal code changes.
--
-- To prevent errors, EventManagerLite __blocks direct access to__
-- @{FOBJ LuaBootstrap}. It's methods must instead be accessed via 
-- a ManagedLuaBootstrap object.
--
-- @{Introduction.DevelopmentStatus|Module Status}: Experimental 2021-08-19.
--
-- @module EventManagerLite
-- @usage
--  local EventManager = require('__eradicators-library__/erlib/factorio/EventManagerLite-1')()


--[[ Design Goals:
  
  ! Keep it simple.
  ! Emulate vanilla behavior as close as nessecary.
  
  + No Savedata.
  + Minimal internal event handlers.
  + Minimal sanity checking.
  + Native runtime un-/-registering of module event handlers.
  + Dynamic unregistering of inactive *internal* handlers (including on_tick)
  + Offest based load balancing for on_nth_tick handlers (vanilla incompatible).
  + Script errors happen directly when a module calls - no caching.
  
  ]]
  
--[[ Determinism:

  + Each module must correctly manage it's own dynamic handlers in on_load.

  + Because handlers can arbitrarily add or remove other handlers when executed
    the order of handlers is determined by plugin load order and not handler
    registration order.

  + No other module may ever gain access to "Private" module functions.

  ]]

--[[ Annecdotes:

  + Initial rewrite from scratch took 11 hours straight
    without documentation. Bugfixing and documentation
    took another 11 hours on the next day. (2021-05-18)
  
  ]]

--[[ Edge cases:

  + Theoretically if a plugin causes an event to be raised during on_config
    other plugins might not be ready to properly recieve that event yet.
    Savedata is created + linked before everything else so this might 
    be so edgy that it never becomes relevant.

  ]]
  
--------------------------------------------------------------------------------
-- Todo.
-- @section
--------------------------------------------------------------------------------
  
--[[ Todo:
  
  ]]

-- -------
-- Consider if it's worth suppporting on\_init.
-- This would require storing loaded module names in Savedata
-- to detect when modules get added / removed from a mod.
-- Additionally module aware ConfigurationChangedData might be needed.
-- This would be done as a seperate event module (inside this file?).
-- Sounds like waaay too complicated stuff for little benefit.
-- KISS. This is supposed to be EventManager LITE!
-- @table todo1
do end
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Eradicators Library                                                        --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
local log         = elreq('erlib/lua/Log'       )().Logger  'EventManagerLite'
local stop        = elreq('erlib/lua/Error'     )().Stopper 'EventManagerLite'
local assertify   = elreq('erlib/lua/Error'     )().Asserter(stop)

local Table       = elreq('erlib/lua/Table'     )()
local Set         = elreq('erlib/lua/Set'       )()

local Verificate  = elreq('erlib/lua/Verificate')()
local isLuaObject = Verificate.isType.LuaObject
local verify      = Verificate.verify

local Crc32       = elreq('erlib/lua/Coding/Crc32')()

local Filter      = elreq('erlib/lua/Filter')()

local Remote      = elreq('erlib/factorio/Remote')()

local table_unpack, math_min, math_huge
    = table.unpack, math.min, math.huge

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --
local Public  = {}
local Private = {}

local EventPIG
local generate_event_name

--------------------------------------------------------------------------------
-- Public methods.
-- @section
--------------------------------------------------------------------------------
 
-- -------------------------------------------------------------------------- --
-- PIG                                                                        --
-- -------------------------------------------------------------------------- --
-- Must be imported *before* disabling raw script access.

----------
-- Custom event names.
-- Erlibs equivalent to @{FOBJ defines.events} for modded event ids.
-- This is the __recommended__ way of __sharing EventNames between mods__.
-- 
-- This table contains all dynamically generated (event\_name → event\_id) mappings
-- that are contained in the @{Remote.PackedInterfaceGroup} `'erlib:managed-events'`.
-- Take care to use the correct load order and declare dependencies as needed.
--
-- Trying to read event names that have not been defined yet is an error.
-- It is possible, but discouraged to add event ids by writing them
-- directly to this table. It is recommended to use 
-- [generate\_event\_name](#ManagedLuaBootstrap.generate_event_name)
-- to generate new names.
--
-- See also @{remotes.events}.
--
-- @usage
--   -- Mod_A:
--   ManagedLuaBootstrap.generate_event_name('on_something_happend')
--  
--   -- Mod_X (can be Mod_A):
--   script.on_event(events.on_something_happend, function(e)
--     print('I just shared an event name without effort!')
--     end)
--
--   -- Mod_A:
--   script.raise_event(events.on_something_happend, {player_index = ...})
--
--   -- Mod_X (can be Mod_A):
--   > I just shared an event name without effort!
--
-- @table events
Public.events, generate_event_name, EventPIG
  = elreq('erlib/remotes/events')('EventManagerLite')

    
-- -------------------------------------------------------------------------- --
-- Disable raw script access.
-- -------------------------------------------------------------------------- --
local script = assert(_ENV.script) -- LuaObjects can not be copied!
assert(script.object_name == 'LuaBootstrap')
_ENV.script = setmetatable({
  -- secret exception for sub-modules *without* events.
  mod_name = script.mod_name,
  },{
  __index = function() stop('LuaBootstrap is disabled by EventManagerLite.') end
  })

-- -------------------------------------------------------------------------- --
-- Constants                                                                  --
-- -------------------------------------------------------------------------- --
local reverse_defines = setmetatable({}, {
  __index = function(self, id)
    local k = Table.find(defines.events, id)
    if not k then k = Table.find(EventPIG:get_all(), id) end
    self[id] = k or id
    return self[id]
    end})
 
-- -------------------------------------------------------------------------- --
-- LuaBootstrap Wrapper
-- -------------------------------------------------------------------------- --
-- To guarantee a deterministic module order external access must
-- only be allowed via this wrapper.

local ModuleScripts  = {} --cache to allow modules to share values across files.

local ModuleIndexes  = setmetatable({
  ['event-manager'         ] = -math.huge, -- event manager before everything
  ['event-manager-nth-tick'] =  math.huge, -- on_nth_tick *after* on_tick
  ['plugin-manager'        ] = -1        , -- prevent accidential wrong usage
  ['plugin-manager-gc'     ] =  math.huge, -- garbage collect after everything
  },{
  __index = function(self, module_name)
    local index = table_size(self) - 3 -- must be adjusted for built-ins
    if (module_name:find     '%-updates$') then index = index + 1e10 end
    if (module_name:find'%-final%-fixes$') then index = index + 1e11 end
    self[module_name] = index
    return index end
  })
  
----------
-- Creates a new ManagedLuaBootstrap instance or fetches an existing one of
-- the same name.
--
-- On the __first__ call to this function with a new module\_name a unique
-- module_index is generated. Subsequent calls share the same index.
--
-- @tparam string module_name The name of your module.
-- @treturn ManagedLuaBootstrap If an instance of the same name has been
-- created before you will recieve __a reference__ to, __not a copy__ of,
-- that exact same instance table.
--
-- @function get_managed_script
function Public.get_managed_script(module_name)
  verify(module_name, 'NonEmptyString', 'Invalid module name.')
  assert(not (module_name:find'event%-manager'), 'That module name is reserved.')
  assert(module_name ~= 'template', 'Please change the default module name!')
  --
  if ModuleScripts[module_name] then return ModuleScripts[module_name] end
  local API = setmetatable({},{__index = script}) -- dcopy can't copy LuaObject!
  ModuleScripts[module_name] = API
  --
  API.object_name = 'ManagedLuaBootstrap'
  -- loaders
  local function make_loader(event_names)
    return function(f) return Private.on_event(module_name, event_names, f) end
    end
  API.on_load   = make_loader {'on_load'}
  API.on_config = make_loader {'on_init', 'on_configuration_changed'}
  API.on_configuration_changed = API.on_config
  -- When a mod using EventManagerLite adds new modules
  -- to a map that previously already had the mod installed
  -- then these modules would never see on_init. To prevent
  -- bugs caused by that, on_init is not allowed at all.
  API.on_init = function()
    stop('on_init is forbidden. You must use script.on_configuration_changed instead.')
    end
  -- named events
  function API.on_event(event_names, f, filters)
    return Private.on_event(module_name, event_names, f, filters)
    end
  function API.on_nth_tick(tick, f)
    return Private.on_nth_tick(module_name, tick, f)
    end
  function API.get_event_handler(event_name)
    return Private.get_event_handler(module_name, event_name)
    end
  -- strings
  API.module_name  = module_name
  API.module_index = ModuleIndexes[module_name] -- auto-generates new index
  -- not supported
  API.get_event_filter = function() stop('Not supported.') end
  API.set_event_filter = function() stop('Not supported.') end
  --
  API.generate_event_name = generate_event_name
  -- links / shortcuts
  API.events = Public.events
  return API end

--------------------------------------------------------------------------------
-- Private methods.
-- @section
--------------------------------------------------------------------------------
  
-- -------------------------------------------------------------------------- --
-- Event Handler Storage
-- -------------------------------------------------------------------------- --
local OrderedHandlers = {--[[
  [defines.events.index] = {
    -- DenseArray ordered (not indexed) by ModuleIndex.
    [1] = {module_name = , f =},
    [2] = {module_name = , f =},
    }
  ]]}
  
local next_nth_tick   = 0

local OrderedNthTicks = {--[[
  -- DenseArray ordered (not indexed) by ModuleIndex and increasing period.
  -- [1] = {module_name = , f =, period = k    },
  -- [2] = {module_name = , f =, period = k + j},
  --]] }

-- -------------------------------------------------------------------------- --
-- Handler Registry (Internal)
-- -------------------------------------------------------------------------- --

local log_handler_change = (not flag.IS_DEV_MODE) and ercfg.SKIP or
  function(mode, event_name, module_name)
    if (module_name == '(EventManagerLite)')
    and (type(event_name) == 'string') then
      event_name = event_name:gsub('on_nth_tick_%d+', 'on_nth_tick')
      end
    log:debug(mode, reverse_defines[event_name], ' ',  module_name)
    end
    
local is_loader = {
  on_load = true,  on_init = true,
  on_configuration_changed = true,
  }
    
local function register_internal_event_handler(event_name, f)
  if is_loader[event_name] then return script[event_name](f) end
  return script.on_event(event_name, f) end
  
local function register_internal_nth_tick_handler(_, f)
  return Private.on_event('event-manager-nth-tick', defines.events.on_tick, f)
  end
  
local function get_offset(module_name, period)
  return Crc32.encode(module_name .. period) % period
  end
  
local function has_active_handlers(handlers)
  for i=1, #handlers do if handlers[i].f then return true end end
  return false end
  
local function is_handler_smaller(a, b)
  -- Can't use (x and y or z) because <false> is a valid return value.
  if a.module_name ~= b.module_name then
    return 
        ModuleIndexes[a.module_name]
      < ModuleIndexes[b.module_name]
  else
    return assert(a.period) < b.period
    end
  end
  
-- -------------------------------------------------------------------------- --
  
-- Handles everything (normal, on_tick and on_nth_tick handlers)
local function add_or_remove_handler(
    handlers, module_name, event_name, f, period --[[nth_tick only]] )
  --
  local script_on_event = (period == nil)
    and register_internal_event_handler
     or register_internal_nth_tick_handler
  --
  local i, handler
  for k, v in ipairs(handlers) do
    if  (v.module_name == module_name) 
    and (v.period      == period     ) -- nil for non-nth-tick
    then i, handler = k, v break end
    end
  -- remove
  if (f == nil) then
    if (handler == nil) then
      log_handler_change('x  ', event_name, module_name) -- didn't exist
    else
      log_handler_change('-  ', event_name, module_name) -- remove success
      handler.f = nil
      handler.next_tick = nil
      if not has_active_handlers(handlers) then
        log_handler_change('-- ', event_name, '(EventManagerLite)')
        script_on_event(event_name, nil)
        end
      end
  -- add
  else
    if not has_active_handlers(handlers) then
      if period ~= nil then
        script_on_event(nil, Private.make_on_nth_tick_handler())
      elseif event_name == defines.events.on_tick then
        script_on_event(event_name, Private.make_on_tick_handler (event_name))
      else
        script_on_event(event_name, Private.make_on_event_handler(event_name))
        end
      log_handler_change('++ ', event_name, '(EventManagerLite)')
      end
    if (handler ~= nil) then
      if handler.f == f then
        log_handler_change('== ', event_name, module_name) -- already existed
      else
        log_handler_change('+= ', event_name, module_name) -- replace f only
        handler.f = f
        end
    else
      log_handler_change('+  ', event_name, module_name) -- add new
      --
      local handler = {
        module_name = module_name  ,
        f           = f            ,
        next_tick   = nil          ,
        period      = period or nil,
        offset      = period and get_offset(module_name, period) or nil,
        }
      -- permanent fixed + linked order
      local i = 0; repeat i = i + 1
        until not (handlers[i] and is_handler_smaller(handlers[i], handler))
      table.insert(handlers, i, handler)
      if handlers[i-1] then handlers[i-1].next = handler end
      handler.next = handlers[i+1]
      end
    end
  -- log:tell(event_name, handlers)
  -- log:tell(ModuleIndexes)
  end

-- -------------------------------------------------------------------------- --
-- Handler Registry (LuaBootstrap Emulation)
-- -------------------------------------------------------------------------- --
  
-- Equivalent to LuaBootstrap.on_event
function Private.on_event(module_name, event_names, f, filters)
  verify(f, 'func|nil')
  verify(filters, 'nil', 'Filters are not supported by EventManager.')
  verify(event_names, 'Integer|string|NonEmptyTable', 'Missing event names.')
  --
  event_names = Set.from_values(Table.plural(event_names))
  if event_names['on_config'] then
    event_names['on_config'] = nil
    event_names['on_configuration_changed'] = true
    end
  if event_names['on_configuration_changed'] then
    event_names['on_init'] = true
    end
  --
  for _, event_name in pairs(Table.keys(event_names)) do
    verify(event_name, 'Integer|string') -- defines.events.on_tick is 0!
    --
    add_or_remove_handler(
      Table.sget(OrderedHandlers, {event_name}, {}),
      module_name, event_name, f)
    --
    end
  return f end

-- Equivalent to LuaBootstrap.on_nth_tick.
function Private.on_nth_tick(module_name, periods, f)
  verify(f, 'func|nil')
  verify(periods, 'NaturalNumber|table', 'Missing nth period.')
  --
  for _, period in pairs(Table.plural(periods)) do
    verify(period, 'NaturalNumber')
    --
    add_or_remove_handler(
      OrderedNthTicks,
      module_name, 'on_nth_tick_'..period, f, period)
    --
    -- It can not be known if adding occurs before or
    -- after on_nth_tick of the same tick. So
    -- the next occurance has to be decided within
    -- the on_nth_tick event handler itself.
    next_nth_tick = 0 -- activate bootstrap next cycle!
    end
  return f end
  
-- For completitions sake this is implemented too.
function Private.get_event_handler(module_name, event_name)
  for _, handler in pairs(OrderedHandlers[event_name] or {}) do
    if handler.module_name == module_name then
      return handler.f
      end
    end
  end

-- -------------------------------------------------------------------------- --
-- Make Internal Handler
-- -------------------------------------------------------------------------- --

local dontlog = {
  -- block some of the really spammy ones
  [defines.events.on_chunk_generated        ] = true,
  [defines.events.on_player_changed_position] = true,
  [defines.events.on_string_translated      ] = true,
  [defines.events.on_selected_entity_changed] = true,
  }

local function make_event_logger(event_name)
  local log_name = reverse_defines[event_name]
  return 
   ((not flag.IS_DEV_MODE) or (dontlog[event_name]))
    and ercfg.SKIP
    or  function (module_name, period)
      return log:debug(log_name, period or ' ', ' → ', module_name)
      end
  end

-- Directly calculates the next tick that an on_nth_tick handler
-- would've occured on if it had been continually queued during runtime.
--
-- Handlers should be called on each (n * period + offset) tick,
-- including (n == 0).
--
-- The earliest possible next occurace returned by this function
-- is (current_tick + 1). If a handler should be able to occur
-- *in* the current_tick then (current_tick - 1) must be given
-- as input.
-- 
local function get_next_occurance(current_tick, handler)
  local t, p, o = current_tick, handler.period, handler.offset
  return (o > t) and o or (math.floor((t - o) / p) * p + o + p)
  end
  
-- An event becomes invalid if a handler invalidates at
-- least one LuaObject that was valid before.
local function make_event_validator(e)
  if e == nil then return Filter.TRUE end --on_config, etc...
  local objects, n = {}, 0
  for _, v in pairs(e) do 
    if isLuaObject(v) then; n = n + 1
      objects[n] = v
      assert(v.valid == true, 'Event contained invalid object!')
      end
    end
  --
  return function()
    for i = 1, n do
      if (not objects[i].valid) then return false end
      end
    return true end
  end
  
-- -------------------------------------------------------------------------- --

-- on_tick(f) and on_nth_tick(1,f) must be handled seperately
-- to keep vanilla behavior.
function Private.make_on_tick_handler(event_name)
  local handlers = OrderedHandlers[event_name]
  --
  return function(e)
    local handler = assert(handlers[1])
    repeat
      if handler.f then
        handler.f {tick = e.tick, name = event_name}
        end
      handler = handler.next
      until not handler
    end
  end

function Private.make_on_event_handler(event_name)
  local handlers  = OrderedHandlers[event_name]
  local dcopy     = Table.dcopy
  local log_event = make_event_logger(event_name)
  --
  return function(e)
    local handler = assert(handlers[1])
    local is_event_valid = (handler.next) and make_event_validator(e)
    repeat
      local next = handler.next
      if handler.f then
        log_event(handler.module_name)
        handler.f((not next) and e or dcopy(e)) -- don't copy for last
        end
      handler = next
      until (not handler) or (not is_event_valid())
    if handler then
      log:debug('Event prematurely invalidated by previous handler.')
      end
    end
  end
 
function Private.make_on_nth_tick_handler()
  local handlers = OrderedNthTicks
  local log_event = make_event_logger('on_nth_tick_*')
  --
  return function(e)
    -- (tick >= nth) means ((tick == nth) or (0 == nth))
    if e.tick >= next_nth_tick then
      --
      local tick    = e.tick
      next_nth_tick = math_huge
      -- log_event('eml-nth-tick-iterator')
      --
      local handler = assert(handlers[1])
      repeat
        if handler.f then
          -- new handler?
          if (handler.next_tick == nil) then
            handler.next_tick = get_next_occurance(tick - 1, handler)
            end
          assert(handler.next_tick >= tick) --sanity
          if tick == handler.next_tick then
            -- log_event(handler.module_name, handler.period)
            handler.f {nth_tick = handler.period, tick = tick, offset = handler.offset}
            handler.next_tick = tick + handler.period
            end
          -- unconditionally collect smallest next tick
          next_nth_tick = math_min(handler.next_tick, next_nth_tick)
          end
        handler = handler.next
        until not handler
      end
    end
  end
    
  
-- -------------------------------------------------------------------------- --
-- Debug
-- -------------------------------------------------------------------------- --

if flag.IS_DEV_MODE then
  local Hydra = require('__eradicators-library__/erlib/lua/Coding/Hydra')()
  
  function Private.dump_data_to_console()
    print('ModuleIndexes: '  , Hydra.lines(ModuleIndexes))
    print('ModuleScripts: '  , Hydra.lines(ModuleScripts))
    print('OrderedHandlers: ', Hydra.lines(
      -- print with human readable event names
      (function(a,r) for k,v in pairs(a) do r[reverse_defines[k]] = v end return r end)
      (Table.dcopy(OrderedHandlers),{})
      ,{indentlevel=2}))
    print('OrderedNthTicks: ', Hydra.lines(OrderedNthTicks,{indentlevel=2}))
    end
  
  Private.on_event('event-manager',
    defines.events.on_console_command,
    function(e)
      if e.command == 'erlib' and e.parameters == 'event-manager dump' then
        Private.dump_data_to_console()
        end
      end)
  end


-- -------------------------------------------------------------------------- --
-- Documentation
-- -------------------------------------------------------------------------- --

--------------------------------------------------------------------------------
-- Concepts.
-- @section
--------------------------------------------------------------------------------

----------
-- The unique name of an event.
-- 
-- An EventName is any @{NaturalNumber} or @{string} that would normally
-- be used to register
-- an event handler with @{FOBJ LuaBootstrap.on_event|script.on_event()}.
-- 
-- That means any NaturalNumber from @{FOBJ defines.events},
-- any NaturalNumber number generated with
-- @{FOBJ LuaBootstrap.generate_event_name|script.generate_event_name}(),
-- any name string of a @{FOBJ LuaCustomInputPrototype},
-- or one of the literal strings
-- `"on_load`", `"on_config`" and `"on_configuration_changed`".
-- 
-- @within Concepts
-- @table EventName
do end

--------------------------------------------------------------------------------
-- Examples.
-- @section
--------------------------------------------------------------------------------

----------
-- @usage
--   -- same basic syntax as script.on_event
--   local script = EventManagerLite.get_managed_script('my-scripted-entity')
--   script.on_event(defines.events.on_entity_damaged,
--     function(e)
--       game.print{'', 'Entity ', e.entity.name, ' was damaged.'}
--       end
--     }
-- 
-- @usage
--   -- on_config replaces on_init and on_configuration_changed
--   local script = EventManagerLite.get_managed_script('my-scripted-entity')
--   script.on_config(function(e)
--     print('This is a shortcut to on_configuration_changed!')
--     end)
-- 
-- @table Examples
do end

--------------------------------------------------------------------------------
-- ManagedLuaBootstrap.
-- @section
--------------------------------------------------------------------------------

----------
-- The main interface of EventManagerLite. Each instance can have __one handler__
-- for every event, just like a normal factorio mod can. Differently named
-- instances act like seperate mods and do not interfer with each others events.
-- 
-- This section documents __only the changes__ compared to @{FOBJ LuaBootstrap}.
-- Everything not mentioned here works exactly the same as it normally does
-- (i.e. script.active\_mods, script.generate\_event\_name, script.raise\_event etc).
-- 
-- Changed: ManagedLuaBootstrap is not write-protected like real LuaBootstrap.
-- Changes you make will be visible in all instances with the same name.
-- 
-- @table ManagedLuaBootstrap
do end

----------
-- Register event handlers.
-- (See also @{FOBJ LuaBootstrap.on_event}.)
--
-- @usage
--    local my_handler = script.on_event(defines.events, function(e) end)
--
-- @tparam EventName|table event_name Changed: Accepts values of 
-- any type of table, not only of arrays, 
-- and recognizes the strings `'on_load'`, `'on_config'` and `'on_configuration_changed'`.
-- @tparam function|nil f Unchanged.
-- @tparam nil filters Removed. Because filtering would need to be done on the
-- lua side there would be no performance benefit.
--
-- @treturn function|nil New: Returns the given function f.
--
-- @function ManagedLuaBootstrap.on_event
do end

----------
-- Changed. To prevent lag spikes when several modules with handlers
-- for the same period all execute on the same tick, each handler
-- is assigned a random offset. The offset is deterministic and
-- always the same for a given combination of module_name and period.
-- 
-- The offset is included in the
-- event table when the handler is called.  
-- For example: `f{nth_tick = 30, offset = 9, tick = 39}`. 
-- 
-- The offset always fullfills the condition:  
-- `(tick % nth_tick) == offset`.
--
-- @tparam NaturalNumber period Unchanged.
-- @tparam function|nil f Unchanged.
--
-- @treturn function|nil New: Returns the given function f.
--
-- @function ManagedLuaBootstrap.on_nth_tick
do end

----------
-- Removed.
--
-- Because factorio only raises on_init once per mod this
-- is not reliable for adding new modules to an existing savegame.
-- To prevent any confusion it is completely disabled.
-- Use [on\_configuration\_changed](#ManagedLuaBootstrap.on_configuration_changed)
-- instead.
--
-- @function ManagedLuaBootstrap.on_init
do end

----------
-- Changed.
--
-- @tparam function|nil f Unchanged.
--
-- @treturn function|nil New: Returns the given function f.
--
-- @function ManagedLuaBootstrap.on_load
do end

----------
-- Changed. Because on\_init is not reliable, on\_configuration\_changed handlers
-- must also handle on_init in an agnostic manner.
--
-- If the handler is raised during on_init it will be raised __without parameters__.
-- __Warning:__ Do not try to outsmart yourself by using this to "detect"
-- on\_init. There is no guarantee that this will ever happen at all.
-- It's best if you just store a private "is\_initialized" flag in your
-- modules global data if you need to do heavy lifting in on_init.
-- 
-- See also
-- @{EventManagerLite.boostrap_event_order}, 
-- @{FOBJ LuaBootstrap.on_configuration_changed}
-- 
-- @tparam function|nil f Changed: Will sometimes be raised f(@{nil}) 
-- instead of f(@{FAPI Concepts ConfigurationChangedData}).
--
-- @treturn function|nil New: Returns the given function f.
--
-- @function ManagedLuaBootstrap.on_configuration_changed
do end

----------
-- New: Shorthand for on\_configuration\_changed(f).
-- @function ManagedLuaBootstrap.on_config
do end

----------
-- Changed. Now supports naming events.
-- If a name is given it's id is automatically published to the
-- @{Remote.PackedInterfaceGroup} called 'erlib:managed-events',
-- which can easily be accessed via @{EventManagerLite.events}.
-- 
-- See also @{FOBJ LuaBootstrap.generate_event_name} and 
-- @{remotes.events}.
-- 
-- @tparam[opt] string event_name Your custom name for the event.
-- 
-- @treturn NaturalNumber The @{EventManagerLite.EventName|EventName}
-- for your event. A new EventName will only be generated on the first
-- call for each `event_name`. Subsequent calls with the same `event_name`
-- will return the previously generated EventName.
-- 
-- @function ManagedLuaBootstrap.generate_event_name
do end

----------
-- New: The name that was used to create this instance.
-- Similar to @{FOBJ LuaBootstrap.mod_name} but not the same.
--
-- Read only. (Technically you can overwrite it but that won't affect anything.)
--
-- @string ManagedLuaBootstrap.module_name
do end

----------
-- New: The load order index of this instance. When an event is subscribed to by
-- multiple instances then the handlers will be executed in this order, starting
-- from lowest going to highest.
--
-- Read only. (Technically you can overwrite it but that won't affect anything.)
--
-- See also @{EventManagerLite.event_handler_order}.
--
-- @number ManagedLuaBootstrap.module_index
do end

----------
-- Changed. The name is `"ManagedLuaBootstrap"`. To distinguish from the real
-- script which is named `"LuaBootstrap"`.
--
-- Read only. (Technically you can overwrite it but that won't affect anything.)
--
-- See also @{FOBJ Common.object_name}.
--
-- @number ManagedLuaBootstrap.object_name
do end

----------
-- New: Alias for @{EventManagerLite.events}.
-- @table ManagedLuaBootstrap.events
do end

----------
-- Removed. Event filters are not supported.
-- @function ManagedLuaBootstrap.set_event_filter
do end

----------
-- Removed. Event filters are not supported.
-- @function ManagedLuaBootstrap.get_event_filter
do end

--------------------------------------------------------------------------------
-- Factorio Behavior.
-- See also @{FAPI Data-Lifecycle}.
-- @section
--------------------------------------------------------------------------------

----------
-- What apis are available during on\_init, on\_load and on\_config?
--
-- @usage
--   on_init   : remote commands settings rcon rendering script game global[R/W]
--   on_load   : remote commands settings rcon           script      global[R]
--   on_config : remote commands settings rcon rendering script game global[R/W]
-- 
-- @table api_availability
do end

--[[------
  In what order do on\_init, on\_load and on\_config happen?

  Absurdly the engine raises on\_load* *before* on\_config, at best causing
  unnesscary work, at worst running it on outdated global data. There's nothing
  I can do about that so you have to take countermeasures yourself.
  Don't forget to use migrations if nessecary.
  
  See [ManagedLuaBootstrap.on_init](#ManagedLuaBootstrap.on_init)
  for why EventManagerLite never raises on\_init.
  
  Base game order:
    InstallMod -> StartMap                         : on_init      -         -      
    InstallMod -> StartMap -> SaveMap    -> LoadMap:   -        on_load     -      
    InstallMod -> StartMap -> ChangeMod  -> LoadMap:   -        on_load*  on_config
    StartMap   -> SaveMap  -> InstallMod -> LoadMap: on_init      -       on_config
                                                                         
  EventManagerLite order:                                                
    InstallMod -> StartMap                         : on_config     -        -
    InstallMod -> StartMap -> SaveMap    -> LoadMap:   -        on_load     -      
    InstallMod -> StartMap -> UpdateMod  -> LoadMap:   -        on_load*  on_config
    StartMap   -> SaveMap  -> InstallMod -> LoadMap: on_config    -       on_config
    
 @table boostrap_event_order
--]]
do end

----------
-- In what order are handlers executed?
--
-- When two mods or two ManagedLuaBootstrap instances each have a handler
-- for the same event, then the events are executed in the order that they
-- were loaded in. For ManagedLuaBootstrap this is determined by the module\_index.
--
-- When multiple On\_nth\_tick handlers occur on the same tick then the handlers
-- are executed in order from smallest to largest period. All on\_tick handlers
-- are always executed before any on\_nth\_tick handlers.
--
--
-- @table event_handler_order
do end


-- -------------------------------------------------------------------------- --
-- ExtraEvents.
-- -------------------------------------------------------------------------- --

----------
-- Extra events must be activated in settings stage prior to usage.
-- 
-- @usage
--   -- settings-updates.lua
--   erlib_enable_plugin('on_player_changed_chunk')
--
-- @within ExtraEvents
-- @table HowToActivateExtraEvents
do end

-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
-- Determinism: Never allow access to internal functions.
do (STDOUT or log or print)('  Loaded → erlib.EventManagerLite') end
return function() return Public, nil, nil end
