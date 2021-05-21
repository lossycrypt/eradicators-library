-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable

--------------------------------------------------------------------------------
-- Native multi-handler events.
--
-- EventManagerLite mimics the @{FOBJ LuaBootstrap} api to allow mods
-- to register multiple handlers to any event with only minimal code changes.
--
-- To prevent errors EventManagerLite blocks direct access to LuaBootstrap,
-- but most functionality is available from the ManagedLuaBootstrap object.
--
-- @{Introduction.DevelopmentStatus|Module Status}: Work in progress.
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
  + Native runtime de-/-registering of event handlers.
  + Dynamic unregistering of inactive internal handlers (including on_tick)
  + Offest based load balancing for on_nth_tick handlers (vanilla incompatible).
  + Script errors happen directly when a module calls - no caching.
  
  ]]
  
--[[ Determinism:
  
  + Each module must correctly manage it's own dynamic handlers in on_load.
  
  + Because handlers can arbitrarily add or remove other handlers when executed
    the order of handlers has to be copied during each event to ensure
    a deterministic execution order.
    
  + Like navtive LuaBootstrap the event order must be determined
    by mod(ule) load order. Runtime add/remove to a naive
    array would requires Savedata to know the correct current order in on_load.

  + No other module may ever gain access to Private module functions.
    
  ]]

--[[ Annecdotes:

  + Initial rewrite from scratch took 11 hours straight
    without documentation. Bugfixing and documentation
    took another 11 hours on the next day. (2021-05-18)
  
  ]]



--------------------------------------------------------------------------------
-- Todo.
-- @section
--------------------------------------------------------------------------------

----------
-- Consider if it's worth suppporting on\_init.
-- This would require storing loaded module names in Savedata
-- to detect when modules get added / removed from a mod.
-- Additionally module aware ConfigurationChangedData might be needed.
-- This would be done as a seperate event module (inside this file?).
-- @table todo1
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
local log         = elreq('erlib/lua/Log'       )().Logger  'EventManagerLite'
local stop        = elreq('erlib/lua/Error'     )().Stopper 'EventManagerLite'

local Table       = elreq('erlib/lua/Table'     )()

local Verificate  = elreq('erlib/lua/Verificate')()
local isLuaObject = Verificate.isType.LuaObject
local verify      = Verificate.verify

local Crc32       = elreq('erlib/lua/Coding/Crc32')()

local table_unpack, math_min
    = table.unpack, math.min

-- -------------------------------------------------------------------------- --
-- Constants                                                                  --
-- -------------------------------------------------------------------------- --
local reverse_defines = setmetatable(
  (function(r) for k,v in pairs(defines.events) do r[v] = k end return r end){},
  {__index = function(_, name) return name end} -- custom input/event names
  )

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --
local Public  = { factorio_version = '1.1.32' }
local Private = {}

-- -------------------------------------------------------------------------- --
-- Disable raw script access.
-- -------------------------------------------------------------------------- --
local script = assert(_ENV.script) -- LuaObjects can not be copied!
_ENV.script = setmetatable({},{
  __index = function() stop('LuaBootstrap is disabled by EventManagerLite.') end
  })

--------------------------------------------------------------------------------
-- Public methods.
-- @section
--------------------------------------------------------------------------------
  
-- -------------------------------------------------------------------------- --
-- LuaBootstrap Wrapper
-- -------------------------------------------------------------------------- --
-- To guarantee a deterministic module order external access must
-- only be allowed via this wrapper.

local ModuleScripts  = {} --cache to allow modules to share values across files.

local ModuleIndexes  = setmetatable({
  ['event-manager'         ] = -math.huge, -- event manager before everything.
  ['event-manager-nth-tick'] =  math.huge, -- on_nth_tick *after* on_tick
  ['plugin-manager-gc'     ] =  math.huge, -- garbage collect after everything.
  },{
  __index = function(self, module_name)
    local index = table_size(self) - 3 -- must be adjusted for built-ins
    if (module_name:find     '%-updates$') then index = index + 1e10 end
    if (module_name:find'%-final%-fixes$') then index = index + 1e11 end
    self[module_name] = index
    return index end
  })
  
local function is_module_index_smaller(a,b)
  return 
      ModuleIndexes[a.module_name]
    < ModuleIndexes[b.module_name]
  end

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
  --
  if ModuleScripts[module_name] then return ModuleScripts[module_name] end
  local API = setmetatable({},{__index = script}) -- dcopy can't copy LuaObject!
  ModuleScripts[module_name] = API
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
  -- nips
  local not_implemented = function() stop('Not implemented') end
  API.get_event_handler = not_implemented
  API.set_event_filter  = not_implemented
  --
  return API end

--------------------------------------------------------------------------------
-- Private methods.
-- @section
--------------------------------------------------------------------------------
  
-- -------------------------------------------------------------------------- --
-- OrderedHandlers Registry
-- -------------------------------------------------------------------------- --
local OrderedHandlers = {--[[
  [defines.events.index] = {
    -- DenseArray ordered (not indexed) by ModuleIndex.
    [1] = {module_name = , f =},
    [2] = {module_name = , f =},
    }
  ]]}

local is_loader = {
  on_load = true,  on_init = true,
  on_configuration_changed = true,
  }
  
local function script_on_event(event_name, f)
  if is_loader[event_name] then return script[event_name](f) end
  return script.on_event(event_name, f) end

-- Removes a handler *if* it existed. If not silently does nothing.
local function remove_handler(module_name, event_name)
  local handlers = OrderedHandlers[event_name]
  if handlers then
    for i=1, #handlers do
      if handlers[i].module_name == module_name then
        log:debug('-  ', reverse_defines[event_name], ' ', module_name)
        handlers[i].valid = false -- invalidate copied references
        table.remove(handlers, i)
        if #handlers == 0 then
          log:debug('-- ', reverse_defines[event_name], ' (LuaBootstrap)')
          script_on_event(event_name, nil)
          end
        handlers.n = #handlers
        break end
      end
    end
  end

-- Adds a new handler at the end. Overwrites existing handler if any.
local function add_handler(module_name, event_name, f)
  remove_handler(module_name, event_name)
  local is_on_tick = (event_name == defines.events.on_tick)
  --
  if (f ~= nil) then
    local handlers = Table.sget(OrderedHandlers, {event_name}, {})
    if #handlers == 0 then
      log:debug('++ ', reverse_defines[event_name], ' (LuaBootstrap)')
      script_on_event(event_name,
        is_on_tick
        and Private.make_on_tick_handler (event_name)
        or  Private.make_on_event_handler(event_name)
        )
      end
    log:debug('+  ', reverse_defines[event_name], ' ', module_name)
    table.insert(handlers, {module_name = module_name, f = f, valid = true})
    handlers.n = nil -- n can't be sorted
    table.sort(handlers, is_module_index_smaller) -- deterministic!
    handlers.n = #handlers
    end
  end

function Private.on_event(module_name, event_names, f, filters)
  verify(f, 'func|nil')
  verify(filters, 'nil', 'Filters are not supported by EventManager.')
  --
  for _, event_name in pairs(Table.plural(event_names)) do
    verify(event_name, 'Integer|string') -- defines.events.on_tick is 0!
    add_handler(module_name, event_name, f)
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
-- OrderedHandlers Event Handler Makers
-- -------------------------------------------------------------------------- --

-- on_tick(f) and on_nth_tick(1,f) must be handled seperately
-- to keep vanilla behavior.
function Private.make_on_tick_handler(event_name)
  local handlers = OrderedHandlers[event_name]
  --
  return function(e)
    if handlers.n == 1 then
      handlers[1].f {tick = e.tick, name = event_name}
    else
      -- if there's more than one handler the current order has
      -- to be stored to prevent disturbance from add/remove calls.
      local n, handlers = handlers.n, {table_unpack(handlers)}
      for i=1, n do
        if handlers[i].valid then
          handlers[i].f {tick = e.tick, name = event_name}
          end
        end
      end
    end
  end

-- -------------------------------------------------------------------------- --

-- @tparam String log_name Human readable event name.
local function log_event(tick, log_name, module_name)
  return log:debug(
    '[tick ', tick, '] ',
    'Event handled  : ', log_name
    ,', Module: ', module_name
    )
  end
  
-- An event becomes invalid if a handler invalidates at
-- least one LuaObject that was valid before.
local function make_event_validator(e)
  local objects, n = {}, 0
  for _,v in pairs(e) do 
    if isLuaObject(v) then; n = n + 1
      assert(v.valid == true, 'Event contained invalid object!')
      objects[n] = v
      end
    end
  --
  return function()
    for i = 1, n do
      if (not objects[i].valid) then return false end
      end
    return true end
  end

function Private.make_on_event_handler(event_name)
  local handlers = OrderedHandlers[event_name]
  local log_name = reverse_defines[event_name]
  local dcopy    = Table.dcopy
  --
  local handle = function(handler, e)
    if handler.valid then
      log_event(e and e.tick or -1, log_name, handler.module_name)
      handler.f(e)
      return true end
    return false end
  --
  return function(e)
    assert(handlers.n > 0, 'Recieved event, but had no handlers.' )
    -- Handlers can mutate OrderedHandlers so a temporary copy is needed.
    -- next() can not be used because newly added handlers must *not*
    -- be executed for the current event.
    local n              = handlers.n
    local handlers       = (n == 1) and handlers or {table_unpack(handlers)}
    local is_event_valid = (n >  1) and make_event_validator(e)
    --
    for i=1, n-1 do
      if handle(handlers[i], dcopy(e))
      and (not is_event_valid()) then
        log:debug('Event prematurely invalidated by previous handler.')
        return end
      end
    -- final (or only) handler needs neither check nor dcopy
    handle(handlers[n], e)
    end
  end

-- -------------------------------------------------------------------------- --
-- Nth Tick Handlers Registry
-- -------------------------------------------------------------------------- --
local OrderedNthTicks = { handlers = {}, n = 0, next_nth_tick = 0 }

local function get_offset(module_name, period)
  return Crc32.encode(module_name .. period) % period
  end

local function remove_on_nth_tick(module_name, period)
  for i=1, OrderedNthTicks.n do
    local handler = OrderedNthTicks.handlers[i]
    if  (handler.module_name == module_name)
    and (handler.period      == period     )
    then
      log:debug('-  on_nth_tick ', period, ' ', module_name)
      handler.valid = false
      table.remove(OrderedNthTicks.handlers, i) -- keeps correct order
      OrderedNthTicks.n = #OrderedNthTicks.handlers
      if OrderedNthTicks.n == 0 then
        Private.on_event('event-manager-nth-tick', defines.events.on_tick, nil)
        end
      return end -- Each module can only have one handler per period.
    end
  end
  
local function add_on_nth_tick(module_name, period, f)
  remove_on_nth_tick(module_name, period)
  --
  if (f ~= nil) then
    if OrderedNthTicks.n == 0 then
      Private.on_event('event-manager-nth-tick',
        defines.events.on_tick,
        Private.on_nth_tick_handler)
      end
    log:debug('+  on_nth_tick ', period, ' ', module_name)
    --
    table.insert(OrderedNthTicks.handlers, {
      module_name = module_name,
      period = period,
      offset = get_offset(module_name, period),
      f = f,
      valid = true,
      })
    --
    table.sort(OrderedNthTicks.handlers, function(a,b) -- deterministic!
      if (a.module_name == b.module_name) then
        return a.period < b.period -- must be able to return false!
      else
        return is_module_index_smaller(a,b)
        end
      end)
    --
    -- It can not be known if adding occurs before or
    -- after on_nth_tick of the same tick. So 
    -- the next occurance has to be decided within
    -- the on_nth_tick event handler itself.
    OrderedNthTicks.n = #OrderedNthTicks.handlers
    OrderedNthTicks.next_nth_tick = 0 -- activate bootstrap next cycle!
    end
  end
  
function Private.on_nth_tick(module_name, periods, f)
  verify(f, 'func|nil')
  --
  for _, period in pairs(Table.plural(periods)) do
    verify(period, 'NaturalNumber')
    add_on_nth_tick(module_name, period, f)
    end
  return f end
  
-- -------------------------------------------------------------------------- --
-- Nth Tick Event Handler
-- -------------------------------------------------------------------------- --
  
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

-- @future: Remove sanity checks once stability is confirmed.  
function Private.on_nth_tick_handler(e)
  -- (tick >= nth) means ((tick == nth) or (0 == nth))
  if e.tick >= OrderedNthTicks.next_nth_tick then
    --
    local tick          = e.tick
    local next_nth_tick = math.huge
    -- log_event(tick, 'on_tick', 'event-manager-nth-tick')
    --
    local handlers = {table_unpack(OrderedNthTicks.handlers)} --deterministic order
    for i=1, OrderedNthTicks.n do
      local handler = handlers[i]
      if handler.valid then
        -- new handler?
        if (handler.next_tick == nil) then
          handler.next_tick = get_next_occurance(tick - 1, handler)
          end
        --
        assert(handler.next_tick >= tick) --sanity
        if tick == handler.next_tick then
          -- log_event(tick, 'on_nth_tick ' .. handler.period, handler.module_name)
          handler.f {nth_tick = handler.period, tick = tick, offset = handler.offset}
          handler.next_tick = tick + handler.period
          end
        -- unconditionally collect smallest next tick
        next_nth_tick = math_min(handler.next_tick, next_nth_tick)
        end
      end
    --
    OrderedNthTicks.next_nth_tick = next_nth_tick
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
    print('OrderedNthTicks.handlers: ', Hydra.lines(OrderedNthTicks,{indentlevel=2}))
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
-- @tparam string|Integer|table event_name Changed: Now works with non-arrays
-- and recognizes `'on_load'` and `'on_configuration_changed'`.
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
-- New: Shorthand for on\_configuration\_changed.
-- @function ManagedLuaBootstrap.on_config
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
  
  See ManagedLuaBootstrap.on\_init for why EventManagerLite 
  never raises on\_init.
  
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
-- End                                                                        --
-- -------------------------------------------------------------------------- --
-- Determinism: Never allow access to internal functions.
do (STDOUT or log or print)('  Loaded → erlib.EventManagerLite') end
return function() return Public, nil, nil end
